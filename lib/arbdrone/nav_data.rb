class ARbDrone
  module NavData
    attr_accessor :drone_state

    TAGS = {
      0      => :demo,
      16     => :vision_detected,
      18     => :iphone_angles,
      0xFFFF => :checksum,
    }

    STATE = {
      1 << 0  => FLYING              /*!< FLY MASK : (0) mykonos is landed, (1) mykonos is flying */
      1 << 1  => VIDEO               /*!< VIDEO MASK : (0) video disable, (1) video enable */
      1 << 2  => VISION              /*!< VISION MASK : (0) vision disable, (1) vision enable */
      1 << 3  => CONTROL             /*!< CONTROL ALGO : (0) euler angles control, (1) angular speed control */
      1 << 4  => ALTITUDE            /*!< ALTITUDE CONTROL ALGO : (0) altitude control inactive (1) altitude control active */
      1 << 5  => USER_FEEDBACK_START /*!< USER feedback : Start button state */
      1 << 6  => COMMAND             /*!< Control command ACK : (0) None, (1) one received */
      1 << 7  => TRIM_COMMAND        /*!< Trim command ACK : (0) None, (1) one received */
      1 << 8  => TRIM_RUNNING        /*!< Trim running : (0) none, (1) running */
      1 << 9  => TRIM_RESULT         /*!< Trim result : (0) failed, (1) succeeded */
      1 << 10 => NAVDATA_DEMO        /*!< Navdata demo : (0) All navdata, (1) only navdata demo */
      1 << 11 => NAVDATA_BOOTSTRAP   /*!< Navdata bootstrap : (0) options sent in all or demo mode, (1) no navdata options sent */
      1 << 12 => MOTORS_BRUSHED      /*!< Motors brushed : (0) brushless, (1) brushed */
      1 << 13 => COM_LOST            /*!< Communication Lost : (1) com problem, (0) Com is ok */
      1 << 14 => GYROS_ZERO          /*!< Bit means that there's an hardware problem with gyrometers */
      1 << 15 => VBAT_LOW            /*!< VBat low : (1) too low, (0) Ok */
      1 << 16 => VBAT_HIGH           /*!< VBat high (US mad) : (1) too high, (0) Ok */
      1 << 17 => TIMER_ELAPSED       /*!< Timer elapsed : (1) elapsed, (0) not elapsed */
      1 << 18 => NOT_ENOUGH_POWER    /*!< Power : (0) Ok, (1) not enough to fly */
      1 << 19 => ANGLES_OUT_OF_RANGE /*!< Angles : (0) Ok, (1) out of range */
      1 << 20 => WIND                /*!< Wind : (0) Ok, (1) too much to fly */
      1 << 21 => ULTRASOUND          /*!< Ultrasonic sensor : (0) Ok, (1) deaf */
      1 << 22 => CUTOUT              /*!< Cutout system detection : (0) Not detected, (1) detected */
      1 << 23 => PIC_VERSION         /*!< PIC Version number OK : (0) a bad version number, (1) version number is OK */
      1 << 24 => ATCODEC_THREAD_ON   /*!< ATCodec thread ON : (0) thread OFF (1) thread ON */
      1 << 25 => NAVDATA_THREAD_ON   /*!< Navdata thread ON : (0) thread OFF (1) thread ON */
      1 << 26 => VIDEO_THREAD_ON     /*!< Video thread ON : (0) thread OFF (1) thread ON */
      1 << 27 => ACQ_THREAD_ON       /*!< Acquisition thread ON : (0) thread OFF (1) thread ON */
      1 << 28 => CTRL_WATCHDOG       /*!< CTRL watchdog : (1) delay in control execution (> 5ms), (0) control is well scheduled */
      1 << 29 => ADC_WATCHDOG        /*!< ADC Watchdog : (1) delay in uart2 dsr (> 5ms), (0) uart2 is good */
      1 << 30 => COM_WATCHDOG        /*!< Communication Watchdog : (1) com problem, (0) Com is ok */
      1 << 31 => EMERGENCY           /*!< Emergency landing : (0) no emergency, (1) emergency */
    }


    def setup(drone_ip, drone_navdata_port)
      @drone_ip, @drone_navdata_port = drone_ip, drone_navdata_port
    end

    # Wake up the drone to start sending us navdata
    def send_initial_message
      send_datagram 1, @drone_ip, @drone_navdata_port
    end

    def receive_data(msg)
      ptr = 0
      header, drone_state, seq, vision_flag = msg[ptr,4].unpack('VVVV')


      ptr += 32
      options = []
      while ptr < msg.length
        option_id = msg[ptr].unpack('v').first
        ptr += 2

        unless TAGS.keys.include?(option_id)
          puts "Found invalid options id: #{option_id.inspect}"
          next
        end

        length = msg[ptr].unpack('v').first
        ptr += 2

        unless length > 0
          puts "Found option with invalid 0 length"
          next
        end

        data = msg[ptr, length]
        ptr += length

        puts "Decoded option #{TAGS[option_id]} with value #{data.inspect}"
        options.push :id => option_id, :length => length, :data => data
      end
      # Checksum is always the last option sent
      checksum = options.last
      # FIXME: Verify message checksum
    end
  end

end
