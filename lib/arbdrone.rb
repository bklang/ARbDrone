require 'bundler/setup'
require 'eventmachine'

require 'arbdrone/control'

class ARbDrone
  def initialize(options = {})
    @drone_ip           = options.delete(:drone_ip)           || '192.168.1.1'
    @drone_navdata_port = options.delete(:drone_navdata_port) || 5554
    @drone_video_port   = options.delete(:drone_video_port)   || 5555
    @drone_control_port = options.delete(:drone_control_port) || 5556
  end

  def run
    [:run_control, :run_navdata].each do |method|
      Thread.new do
        EventMachine.run { self.send :method }
      end
    end
  end

  def run_control
    @connection = EventMachine.open_datagram_socket '0.0.0.0', 5550, Control
    @connection.setup @drone_ip, @drone_control_port
    @control_timer = EventMachine.add_periodic_timer 0.02 do
      @connection.send_queued_messages
    end
  end

  def stop_control
    @connection << @connection.land
    @control_timer.cancel
  end
end
