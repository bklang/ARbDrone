require 'socket'
require 'thread'
require 'etc'

class ARbDrone
  module Control

    # With SDK version 1.5, only bits 8 and 9 are used in the
    # control bit-field. Bits 18, 20, 22, 24 and 28 should be
    # set to 1. Other bits should be set to 0.
    REF_CONST = 290717696
    REF_EMERG = 1 << 8
    REF_FLYING = 1 << 9

    CONTROL_MODES = {
      :none            => 0, # Doing nothing
      :ardone_update   => 1, # Deprecated - AR.Drone software update reception (update is done next run). After event completion, card should be powered off.
      :pic_update      => 2, # AR.Drone PIC software update reception (update is done next run)
      :get_log         => 3, # Send previous run's logs
      :get_cfg         => 4, # Send active configuration file to a client through the 'control' TCP socket
      :ack             => 5, # Reset command mask in NavData
      :custom_cfg_get  => 6, # Send list of custom configuration IDs
    }

    attr_accessor :phi, :theta, :yaw, :gaz

    def setup(drone_ip, drone_control_port, options = {})
      @drone_ip, @drone_control_port = drone_ip, drone_control_port
      @send_queue = []
      @send_mutex = Mutex.new

      @application_id = options.delete(:application_id) || 'ARbDrone'
      @user_id        = options.delete(:user_id)        || Etc.getlogin
      @session_id     = options.delete(:session_id)     || "#{Socket.gethostname}:#{$$}"

      # Initialize sticky inputs to 0 (centered)
      center_sticky_inputs

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

      # Take the Drone out of bootstrap mode
      set_option 'general:navdata_demo', 'TRUE'
    end

    def center_sticky_inputs
      @phi, @theta, @yaw, @gaz = 0, 0, 0, 0
    end

    def push(msg)
      @send_queue << msg
    end
    alias :<< :push

    def send_queued_messages
      # We always want to send at least one state message
      msg = state_msg
      queue_sticky_inputs
      until (@send_queue.empty? || (msg.length + @send_queue.first.length) >= 1024) do
        msg << @send_queue.shift
      end

      # Send control input
      @send_mutex.synchronize do
        send_datagram(msg, @drone_ip, @drone_control_port) unless msg.empty?
      end
    end

    def queue_sticky_inputs
      steer(@phi, @theta, @gaz, @yaw) if [@phi, @theta, @gaz, @yaw].any? {|i| i != 0 }
    end

    # Tells the drone its maximum angle of deflection in radians, known as
    # Euler angles.  Value may be a positive floating point number between 0.1 rads
    # and 0.52 rads.  0.52 rads is approximately 30 degrees deflection while
    # 0.09 rads is approximately 5 degrees.
    def set_input_limit(rads)
      set_option 'control:euler_angle_max', rads
    end

    def next_seq
      @seq = @seq.nil? ? 1 : @seq + 1
    end

    def format_cmd(cmd, data = nil)
      "#{cmd}=#{next_seq},#{data}\r"
    end

    def toggle_state
      push format_cmd *ref(REF_EMERG)
    end

    def takeoff
      # For safety during takeoff
      center_sticky_inputs

      # Bit 9 is 1 for takeoff
      @drone_state = REF_FLYING
    end

    def land
      # For safety during landing
      center_sticky_inputs
      @drone_state = 0
    end

    def hover
      # Set bit zero to zero to make the drone enter hovering mode
      flags = 0
      push format_cmd *pcmd(flags, 0, 0, 0, 0)
    end

    # Send input commands to the drone.  These must be repeated to have any meaningful effect.
    # Negative values move the drone in the first direction listed below; positive values move
    # it in the second listed direction.
    # @param [Float]phi   Bank left/right angle. Valid inputs are between -1.0 and +1.0
    # @param [Float]theta Tilt back/forward angle. Valid inputs are between -1.0 and +1.0
    # @param [Float]gaz   Altitude decrease/increase. Valid inputs are between -1.0 and +1.0
    # @param [Float]yaw   Spin left/right. Valid inputs are between -1.0 and +1.0
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
      ['AT*REF', input.to_i | REF_CONST]
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

    def int2float(int)
      [int.to_i].pack('l').unpack('e').first
    end

    def pcmd(flags, phi, theta, gaz, yaw)
      values = [flags]

      # Ensure the inputs do not exceed [-1.0, 1.0]
      phi, theta, gaz, yaw = minmax -1.0, 1.0, phi, theta, gaz, yaw

      # Convert the values to IEEE 754, then cast to a signed int
      values += [phi, theta, gaz, yaw].map { |v| float2int v }
      ['AT*PCMD', values.join(',')]
    end

    def shutdown!
      @seq = nil
    end

    def minmax(min, max, *args)
      args.map {|arg| arg < min ? min : arg > max ? max : arg }
    end

    def decode_command(cmd)
      type, seq, data = cmd.match(/^AT\*([A-Z_]+)=(\d+),?(.*)?$/).captures rescue [nil, nil, nil]
      case type
      when "PCMD"
        flag, phi, theta, gaz, yaw = data.split(',')
        phi, theta, gaz, yaw = [phi, theta, gaz, yaw].map {|i| int2float i }
        flag = flag == 1 ? "Combined" : "Progressive"
        "Steering #{flag}: Phi: %d%% Theta: %d%% Yaw: %d%% Gaz: %d%%" % [phi * 100, theta * 100, yaw * 100, gaz * 100]

      when "REF"
        data = data.to_i & REF_CONST
        message = [(data & REF_EMERG) > 0 ? "Emergency/Reset" : nil, (data & REF_FLYING) > 0 ? "Takeoff/Land" : nil].compact.join(" and ")
        "State update: #{message}" unless message.empty?

      when "CTRL"
        mode, something = data.split ','
        # The "something is not documented and appears to be always 0
        "Control: #{CONTROL_MODES.key(mode.to_i)}#{"-- Unknown SOMETHING value?! #{something}" if something.to_i != 0}"

      when "COMWDG"
        "Communications watchdog reset"

      when "CONFIG"
        key, value = data.gsub('"', '').split ','
        "Setting #{key} to #{value}"

      when "CONFIG_IDS"
        session, user, application = data.split ','
        "Activating configuration for session #{session}, user #{user} and application #{application}"

      else
        cmd
      end
    end
  end
end
