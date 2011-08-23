module ARbDrone
  class NavData
    attr_accessor :drone_state

    def receive_data(msg)
      ptr = 0
      header = msg[ptr,4].unpack('VVVV')
      ptr += 4
      options = []
      while ptr < msg.length
        option_id = msg[ptr].unpack('v')
        ptr += 1
        length = msg[ptr].unpack('v')
        ptr += 1
        data = msg[ptr, length]
        ptr += length
        options.push {:id => option_id, :length => length, :data => data}
      end
      # Checksum is always the last option sent
      checksum = options.last
      # FIXME: Verify message checksum
    end
  end

end
