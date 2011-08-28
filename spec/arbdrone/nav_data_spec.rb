require 'spec_helper'
require 'arbdrone/nav_data'

class NavDrone
  include ARbDrone::NavData
end

describe ARbDrone::NavData do
  describe "#receive_data" do
    before :each do
      @drone  = NavDrone.new
      @drone.setup(0,0)
  
      @bootup_packet = "\x88wfUT\b\xCA\xCF\x01\x00\x00\x00\x00\x00\x00\x00\xFF\xFF\b\x00\xB0\x03\x00\x00" 
    end

    it 'should properly update the drone state' do
      @drone.receive_data @bootup_packet
      @drone.drone_state.should_not == 0
    end

    it 'should detect the bootup flag' do
      @drone.receive_data @bootup_packet
      @drone.in_bootstrap?.should be true
    end
  end
end
