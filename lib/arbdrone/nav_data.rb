class ARbDrone
  module NavData
    attr_reader :drone_state

    TAGS = {
      0      => :demo,
      16     => :vision_detected,
      18     => :iphone_angles,
      0xFFFF => :checksum,
    }

    STATE = {
      :flying              => 1 << 0,  # FLY MASK : (0) mykonos is landed, (1) mykonos is flying 
      :video               => 1 << 1,  # VIDEO MASK : (0) video disable, (1) video enable 
      :vision              => 1 << 2,  # VISION MASK : (0) vision disable, (1) vision enable 
      :control             => 1 << 3,  # CONTROL ALGO : (0) euler angles control, (1) angular speed control 
      :altitude            => 1 << 4,  # ALTITUDE CONTROL ALGO : (0) altitude control inactive (1) altitude control active 
      :user_feedback_start => 1 << 5,  # USER feedback : Start button state 
      :command             => 1 << 6,  # Control command ACK : (0) None, (1) one received 
      :trim_command        => 1 << 7,  # Trim command ACK : (0) None, (1) one received 
      :trim_running        => 1 << 8,  # Trim running : (0) none, (1) running 
      :trim_result         => 1 << 9,  # Trim result : (0) failed, (1) succeeded 
      :navdata_demo        => 1 << 10, # Navdata demo : (0) All navdata, (1) only navdata demo 
      :navdata_bootstrap   => 1 << 11, # Navdata bootstrap : (0) options sent in all or demo mode, (1) no navdata options sent 
      :motors_brushed      => 1 << 12, # Motors brushed : (0) brushless, (1) brushed 
      :com_lost            => 1 << 13, # Communication Lost : (1) com problem, (0) Com is ok 
      :gyros_zero          => 1 << 14, # Bit means that there's an hardware problem with gyrometers 
      :vbat_low            => 1 << 15, # VBat low : (1) too low, (0) Ok 
      :vbat_high           => 1 << 16, # VBat high (US mad) : (1) too high, (0) Ok 
      :timer_elapsed       => 1 << 17, # Timer elapsed : (1) elapsed, (0) not elapsed 
      :not_enough_power    => 1 << 18, # Power : (0) Ok, (1) not enough to fly 
      :angles_out_of_range => 1 << 19, # Angles : (0) Ok, (1) out of range 
      :wind                => 1 << 20, # Wind : (0) Ok, (1) too much to fly 
      :ultrasound          => 1 << 21, # Ultrasonic sensor : (0) Ok, (1) deaf 
      :cutout              => 1 << 22, # Cutout system detection : (0) Not detected, (1) detected 
      :pic_version         => 1 << 23, # PIC Version number OK : (0) a bad version number, (1) version number is OK 
      :atcodec_thread_on   => 1 << 24, # ATCodec thread ON : (0) thread OFF (1) thread ON 
      :navdata_thread_on   => 1 << 25, # Navdata thread ON : (0) thread OFF (1) thread ON 
      :video_thread_on     => 1 << 26, # Video thread ON : (0) thread OFF (1) thread ON 
      :acq_thread_on       => 1 << 27, # Acquisition thread ON : (0) thread OFF (1) thread ON 
      :ctrl_watchdog       => 1 << 28, # CTRL watchdog : (1) delay in control execution (> 5ms), (0) control is well scheduled 
      :adc_watchdog        => 1 << 29, # ADC Watchdog : (1) delay in uart2 dsr (> 5ms), (0) uart2 is good 
      :com_watchdog        => 1 << 30, # Communication Watchdog : (1) com problem, (0) Com is ok 
      :emergency           => 1 << 31, # Emergency landing : (0) no emergency, (1) emergency 
    }


    def setup(drone_ip, drone_navdata_port)
      @drone_ip, @drone_navdata_port = drone_ip, drone_navdata_port
      @drone_state = 0
    end

    # Wake up the drone to start sending us navdata
    def send_initial_message
      send_datagram 1, @drone_ip, @drone_navdata_port
    end

    def receive_data(msg)
      msg.freeze
      last_state = @drone_state

      ptr = 0
      @header, @drone_state, @seq, @vision_flag = msg[ptr,16].unpack('VVVV')
      ptr += 16

      compare_states last_state, @drone_state

      options = []
      while ptr < msg.length
        option_id = msg[ptr,2].unpack('v').first
        ptr += 2

        length = msg[ptr,2].unpack('v').first
        ptr += 2

        # Length appears to be number of 16-bit ints
        data = msg[ptr, length*2]
        ptr += length*2

        unless TAGS.keys.include?(option_id)
          puts "Found invalid options id: 0x%x" % option_id.inspect
          next
        end

        unless length > 0
          puts "Found option with invalid 0 length"
          break
        end

        #puts "Decoded option #{TAGS[option_id]} with value #{data.inspect}"
        options.push :id => option_id, :length => length, :data => data
      end
      # Checksum is always the last option sent
      checksum = options.last
      # FIXME: Verify message checksum
    end

    def compare_states old_state, new_state
      unless old_state == new_state
        diff = old_state ^ new_state
        changes = []
        STATE.each {|k,v| changes << "#{k} is now #{new_state & STATE[k] > 0 ? 1 : 0}" if diff & STATE[k] > 0}
        puts "-----------\n#{changes.join("\n")}\n-----------\n"
      end
    end

    def in_bootstrap?
      @drone_state & STATE[:navdata_bootstrap] > 0
    end

    def is_flying?
      @drone_state & STATE[:flying] > 0
    end

    def communications_lost?
      @drone_state & STATE[:com_lost] > 0
    end

    def altitute_limited?
      @drone_state & STATE[:altitude] > 0
    end

    def validate_checksum(msg, checksum)
      # Calculated checksum
      calc = 0;
      # FIXME: Dunno why msg.byteslice(0, -8) returns nil
      # Only count bytes from the portion of the message excluding the checksum itself
      msg.byteslice(0, msg.bytesize - 8).each_byte { |c| calc += c }

      # Unpack the transmitted checksum
      checksum[:data] = checksum[:data].unpack('V').first

      # Simulate integer overflow
      calc %= (2**32-1)
      checksum[:data] == calc % (2**32-1)
    end
  end
end
