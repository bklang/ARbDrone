require 'eventmachine'
require 'ipaddr'
require 'arbdrone/control'
require 'arbdrone/tcp_control'
require 'arbdrone/nav_data'

class ARbDrone
  attr_accessor :control, :control_config, :navdata

  def initialize(options = {})
    @drone_ip               = options.delete(:drone_ip)               || '192.168.1.1'
    @drone_firmware_port    = options.delete(:drone_firmware_port)    || 5551
    @drone_navdata_port     = options.delete(:drone_navdata_port)     || 5554
    @drone_video_port       = options.delete(:drone_video_port)       || 5555
    @drone_control_port     = options.delete(:drone_control_port)     || 5556
    @drone_raw_capture_port = options.delete(:drone_raw_capture_port) || 5557 # unused? tcp?
    @drone_tcp_console_port = options.delete(:drone_tcp_console_port) || 5558 # unused?
    @drone_tcp_control_port = options.delete(:drone_tcp_control_port) || 5559
    @listen_ip              = options.delete(:listen_ip)              || '0.0.0.0'
  end

  def run
    EventMachine.run do
      @control        = run_control
      @control_config = run_control_config
      @navdata        = run_navdata
    end
  end

  def run_control
    connection = EventMachine.open_datagram_socket @listen_ip, @drone_control_port, Control
    connection.setup @drone_ip, @drone_control_port

    # Send messages every 20ms to ensure we stay connected to the Drone
    @control_timer = EventMachine.add_periodic_timer 0.02 do
      connection.send_queued_messages
    end
    connection
  end

  def run_control_config
    connection = EventMachine.connect @drone_ip, @drone_tcp_control_port, TcpControl
    connection.control_channel = @control
    connection
  end

  def stop_control
    @control.land
    @control_timer.cancel
  end

  def run_navdata
    # We have to bind the socket to 0.0.0.0 so we can receive multicast packets
    connection = EventMachine.open_datagram_socket '0.0.0.0', @drone_navdata_port, NavData
    connection.setup @drone_ip, @drone_navdata_port
    ip = IPAddr.new('224.1.1.1').hton + IPAddr.new(@listen_ip).hton
    connection.set_sock_opt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip)
    connection.send_initial_message
    connection
  end
end
