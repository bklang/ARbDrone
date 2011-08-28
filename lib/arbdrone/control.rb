require 'socket'
require 'thread'
require 'etc'

class ARbDrone
  module Control

    # With SDK version 1.5, only bits 8 and 9 are used in the
    # control bit-field. Bits 18, 20, 22, 24 and 28 should be
    # set to 1. Other bits should be set to 0.
    REF_CONST = 290717696

    CONTROL_MODES = {
      :none            => 0, # Doing nothing
      :ardone_update   => 1, # Deprecated - AR.Drone software update reception (update is done next run). After event completion, card should be powered off.
      :pic_update      => 2, # AR.Drone PIC software update reception (update is done next run)
      :get_log         => 3, # Send previous run's logs
      :get_cfg         => 4, # Send active configuration file to a client through the 'control' TCP socket
      :ack             => 5, # Reset command mask in NavData
      :custom_cfg_get  => 6, # Send list of custom configuration IDs
    }

    def setup(drone_ip, drone_control_port, options = {})
      @drone_ip, @drone_control_port = drone_ip, drone_control_port
      @send_queue = []
      @send_mutex = Mutex.new

      @application_id = options.delete(:application_id) || 'ARbDrone'
      @user_id        = options.delete(:user_id)        || Etc.getlogin
      @session_id     = options.delete(:session_id)     || "#{Socket.gethostname}:#{$$}"

      # FIXME: Do we want to send these commands? These are not well documented.
      # The following three lines are sent by the Linux example utility, ardrone_navigation
      # as the first three messages sent to the drone at initialization.
      #push format_cmd 'AT*PMODE', 2
      #push format_cmd 'AT*MISC', '2,20,2000,3000'
      #hover

      # Inform the Drone who we are
      config_ids @session_id, @user_id, @application_id

      # Invalidate all other controller sessions
      set_option 'custom:session_id', '-all'
    end

    def push(msg)
      @send_queue << msg
    end
    alias :<< :push

    def send_queued_messages
      msg = ''
      until (@send_queue.empty? || (msg.length + @send_queue.first.length) >= 1024) do
        msg << @send_queue.shift
      end
      if msg.empty?
        send_datagram state_msg, @drone_ip, @drone_control_port
      else
        # Send control input
        @send_mutex.synchronize do
          send_datagram(msg, @drone_ip, @drone_control_port) unless msg.empty?
        end
      end
    end

    def next_seq
      @seq = @seq.nil? ? 1 : @seq + 1
    end

    def format_cmd(cmd, data = nil)
      "#{cmd}=#{next_seq},#{data}\r"
    end

    def toggle_state
      push format_cmd *ref(1<<8)
    end

    def takeoff
      # Bit 9 is 1 for takeoff
      @drone_state = 1 << 9
    end

    def land
      @drone_state = 0
    end

    def hover
      # Set bit zero to zero to make the drone enter hovering mode
      flags = 0
      push format_cmd *pcmd(flags, 0, 0, 0, 0)
    end

    def steer(phi, theta, gaz, yaw)
      # Set bit zero to one to make the drone process inputs
      flags = 1 << 0
      push format_cmd *pcmd(flags, phi, theta, gaz, yaw)
    end

    def reset_trim
      push format_cmd 'AT*FTRIM'
    end

    def config_ids(sess_id, user_id, app_id)
      push format_cmd 'AT*CONFIG_IDS', "#{sess_id},#{user_id},#{app_id}"
    end

    def set_option(name, value)
      push format_cmd 'AT*CONFIG', "\"#{name}\",\"#{value}\""
    end

    def drone_control(mode, something = 0)
      # FIXME: What is the purpose of the second argument?
      push format_cmd 'AT*CTRL', "#{mode},#{something}"
    end

    def heartbeat
      push format_cmd 'AT*COMWDG'
    end

    def blink(animation, frequency, duration)
      push format_cmd 'AT*LED', "#{animation},#{float2int frequency},#{duration}"
    end

    def dance(animation, duration)
      push format_cmd 'AT*ANIM', "#{animation},#{duration}"
    end

    def ref(input)
      ['AT*REF', input |= REF_CONST]
    end

    # Used primarily to keep the control connection alive
    # The drone expects a packet at least every 50ms or it
    # triggers the watchdog.  After 2 seconds the connection
    # is considered lost.
    def state_msg
      format_cmd *ref(@drone_state)
    end

    def float2int(float)
      [float.to_f].pack('e').unpack('l').first
    end

    def pcmd(flags, phi, theta, gaz, yaw)
      values = [flags]

      # Ensure the inputs do not exceed [-1.0, 1.0]
      phi, theta, gaz, yaw = minmax -1.0, 1.0, phi, theta, gaz, yaw

      # Convert the values to IEEE 754, then cast to a signed int
      values += [phi, theta, gaz, yaw].map { |v|
        float2int v
      }
      ['AT*PCMD', values.join(',')]
    end

    def shutdown!
      @seq = nil
    end

    def minmax(min, max, *args)
      args.map {|arg| arg < min ? min : arg > max ? max : arg }
    end
  end
end
