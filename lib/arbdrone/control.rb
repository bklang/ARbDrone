require 'socket'
require 'thread'

class ARbDrone
  module Control

    # With SDK version 1.5, only bits 8 and 9 are used in the
    # control bit-field. Bits 18, 20, 22, 24 and 28 should be
    # set to 1. Other bits should be set to 0.
    REF_CONST = 290717696

    attr_accessor :seq

    def setup(drone_ip, drone_control_port)
      @drone_ip, @drone_control_port = drone_ip, drone_control_port
      @send_queue = []
      @send_mutex = Mutex.new
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
        send_datagram noop, @drone_ip, @drone_control_port
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
      "#{cmd}=#{next_seq},#{data}\n"
    end

    def toggle_state
      push format_cmd *ref
    end

    def takeoff
      # Bit 9 is 1 for takeoff
      input = 1 << 9
      push format_cmd *ref(input)
    end

    def land
      # Bit 9 is 0 for takeoff
      input = 0 << 9
      push format_cmd *ref(input)
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

    def set_option(name, value)
      push format_cmd 'AT*CONFIG', "\"#{name}\",\"#{value}\""
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
      input |= REF_CONST
      ['AT*REF', input]
    end

    def pcmd(flags, phi, theta, gaz, yaw)
      values = [flags]

      # Ensure the inputs do not exceed [-1.0, 1.0]
      phi, theta, gaz, yaw = minmax -1.0, 1.0, phi, theta, gaz, yaw

      # Convert the values to IEEE 754, then cast to a signed int
      values += [phi, theta, gaz, yaw].map { |v|
        [v].pack('e').unpack('l').first
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
