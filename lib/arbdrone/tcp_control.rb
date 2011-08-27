class ARbDrone
  module TcpControl
    attr_accessor :control_channel
    attr_reader :control_data

    def post_init
      
    end

    def receive_data(msg)
      # TODO: This data will require several packets until it is fully transmitted.
      # Looking at packet captures it looks like the end is signalled by a period
      # on a line by itself.
      @control_data ||= ''
      @control_data << msg
    end
  end
end
