require 'socket'
require 'thread'

module ARbDrone
  class Control

    # With SDK version 1.5, only bits 8 and 9 are used in the
    # control bit-field. Bits 18, 20, 22, 24 and 28 should be
    # set to 1. Other bits should be set to 0.
    REF_CONST = 290717696

    attr_accessor :seq

    def initialize(drone_ip = '192.168.0.1', drone_port = 5556)
      @socket = UDPSocket.new
      @socket.connect(drone_ip, drone_port)
      @mutex = Mutex.new
      @state = :off
    end

    def next_seq
      @mutex.synchronize do
        @seq = @seq.nil? ? 1 : @seq + 1
      end
    end

    def send_cmd(cmd)
      @socket.send "#{cmd}\n"
    end

    def takeoff
      # Bit 9 is 1 for takeoff
      input = 1 << 9
      send_cmd ref(input)
    end

    def land
      # Bit 9 is 0 for takeoff
      input = 0 << 9
      send_cmd ref(input)
    end

    def hover
      # Set bit zero to zero to make the drone enter hovering mode
      flags = 0
      send_cmd pcmd(flags, 0, 0, 0, 0)
    end

    def steer(phi, theta, gaz, yaw)
      # Set bit zero to one to make the drone process inputs
      flags = 1 << 0
      send_cmd pcmd(flags, phi, theta, gaz, yaw)
    end

    def ref(input)
      input |= REF_CONST
      "AT*REF=#{next_seq},#{input}"
    end

    def pcmd(flags, phi, theta, gaz, yaw)
      phi, theta, gaz, yaw = minmax -1.0, 1.0, phi, theta, gaz, yaw 
      "AT*PCMD=#{next_seq},#{flags},#{phi},#{theta},#{gaz},#{yaw}"
    end

    def shutdown!
      @seq = nil
    end  

    def minmax(min, max, *args)
      args.map {|arg| arg < min ? -1.0 : arg > max ? 1.0 : arg }
    end
  end
end
