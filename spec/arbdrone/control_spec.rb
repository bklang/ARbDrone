require 'spec_helper'
require 'arbdrone/control'

class ControlDrone
  attr_accessor :seq, :send_queue

  include ARbDrone::Control
end

describe ARbDrone::Control do
  before :each do
    @drone  = ControlDrone.new
    @drone.setup(0,0)
    @drone.send_queue = []
    @drone.seq = nil
  end

  describe '#format_cmd' do
    before :each do
      @drone.seq = nil
    end

    it 'should append a sequence number and newline after each statement' do
      @drone.format_cmd('AT*FAKE').should == "AT*FAKE=1,\r"
    end

    it 'should format a data argument correctly' do
      @drone.format_cmd('AT*FAKE', '"name","value"').should == "AT*FAKE=1,\"name\",\"value\"\r"
    end

    it 'should properly increment the sequence number' do
      @drone.format_cmd('AT*FAKE', '"name","value"').should == "AT*FAKE=1,\"name\",\"value\"\r"
      @drone.format_cmd('AT*FAKE', '1,2,3').should == "AT*FAKE=2,1,2,3\r"
      @drone.format_cmd('AT*FAKE', '"name","value"').should == "AT*FAKE=3,\"name\",\"value\"\r"
    end
  end

  describe '#next_seq' do
    it 'should default the sequence number to 1' do
      drone = ControlDrone.new
      drone.next_seq.should == 1
    end

    it 'should increment the sequence number on subsequent calls' do
      drone = ControlDrone.new
      drone.next_seq.should == 1
      seq = drone.next_seq
      seq.should > 1
      seq_again = drone.next_seq
      seq_again.should > seq
    end
  end

  describe '#takeoff' do
    it 'should change the drone state to the number representing "flying"' do
      @drone.takeoff
      @drone.instance_variable_get(:@drone_state).should == 1 << 9
    end
  end

  describe '#land' do
    it 'should change the drone state to the number representing "landed"' do
      @drone.land
      @drone.instance_variable_get(:@drone_state).should == 0
    end
  end

  describe '#set_option' do
    it 'should enclose variable names and values in double-quotes' do
      @drone.set_option('name', 'value')
      @drone.send_queue.include?("AT*CONFIG=1,\"name\",\"value\"\r").should be true
    end
  end

  describe '#dance' do
    it 'should generate the correct command' do
      @drone.dance(2,3)
      @drone.send_queue.include?("AT*ANIM=1,2,3\r").should be true
    end
  end

  describe '#blink' do
    it 'should generate the correct command' do
      @drone.blink(2,3,4)
      @drone.send_queue.include?("AT*LED=1,2,1077936128,4\r").should be true
    end
  end

  describe '#reset_trim' do
    it 'should generate the correct command' do
      @drone.reset_trim
      @drone.send_queue.include?("AT*FTRIM=1,\r").should be true
    end
  end

  describe '#hover' do
    it 'should generate the correct command' do
      @drone.hover
      @drone.send_queue.include?("AT*PCMD=1,0,0,0,0,0\r").should be true
    end
  end

  describe '#steer' do
    it 'should generate the correct command' do
      # FIXME: Remove this mock?
      @drone.should_receive(:pcmd).once.with(1, 0.5, 0.2, -0.1, -0.3).and_return ['AT*PCMD', '1,0,0,0,0']
      @drone.steer 0.5, 0.2, -0.1, -0.3
    end
  end

  describe '#state_msg' do
    before :each do
      @drone.seq = nil
    end

    it 'should generate the correct message when landed' do
      @drone.instance_variable_set(:@drone_state, 0)
      @drone.state_msg.should == "AT*REF=1,290717696\r"
    end

    it 'should generate the correct message when flying' do
      flight = 1 << 9
      @drone.instance_variable_set(:@drone_state, flight)
      @drone.state_msg.should == "AT*REF=1,290718208\r"
    end
  end

end
