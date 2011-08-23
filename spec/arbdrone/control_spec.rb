require 'spec_helper'
require 'arbdrone/control'

class Drone
  include ARbDrone::Control
end

describe ARbDrone::Control do
  before :each do
    @drone  = Drone.new
  end

  after :each do
    @drone  = nil
  end

  describe '#next_seq' do
    it 'should default the sequence number to 1' do
      drone = Drone.new
      drone.next_seq.should == 1
    end

    it 'should increment the sequence number on subsequent calls' do
      drone = Drone.new
      drone.next_seq.should == 1
      seq = drone.next_seq
      seq.should > 1
      seq_again = drone.next_seq
      seq_again.should > seq
    end
  end

  describe '#format_cmd' do
    before :each do
      @drone.seq = nil
    end

    it 'should append a sequence number and newline after each statement' do
      @drone.format_cmd('AT*FAKE').should == "AT*FAKE=1,\n"
    end

    it 'should format a data argument correctly' do
      @drone.format_cmd('AT*FAKE', '"name","value"').should == "AT*FAKE=1,\"name\",\"value\"\n"
    end

    it 'should properly increment the sequence number' do
      @drone.format_cmd('AT*FAKE', '"name","value"').should == "AT*FAKE=1,\"name\",\"value\"\n"
      @drone.format_cmd('AT*FAKE', '1,2,3').should == "AT*FAKE=2,1,2,3\n"
      @drone.format_cmd('AT*FAKE', '"name","value"').should == "AT*FAKE=3,\"name\",\"value\"\n"
    end
  end

  describe '#ref' do
    before :each do
      @flags  = 1 << 18
      @flags |= 1 << 20
      @flags |= 1 << 22
      @flags |= 1 << 24
      @flags |= 1 << 28

      # Reset the sequence number on each iteration.
      @drone.seq = nil
    end

    it 'should set the constant bits in the input' do
      @drone.ref(0).should == ['AT*REF', @flags]
    end

    it 'should preserve input bits' do
      input = 1 << 8
      flags = @flags | input
      @drone.ref(input).should == ['AT*REF', flags]
    end

    it 'should increment the sequence number on subsequent calls' do
      @drone.ref(0).should == ['AT*REF', @flags]
      @drone.ref(0).should == ['AT*REF', @flags]
      @drone.ref(0).should == ['AT*REF', @flags]
    end
  end

  describe "#pcmd" do
    before :each do
      # Reset the sequence number on each iteration.
      @drone.seq = nil
    end

    it 'should format the arguments' do
      @drone.pcmd(1, -0.9, -0.5, 0.2, 0.7).should == ['AT*PCMD', '1,-1083808154,-1090519040,1045220557,1060320051']
    end

    it 'should limit inputs that exceed the min/max' do
      @drone.pcmd(1, -1.9, -1.5, 1.2, 1.7).should == ['AT*PCMD', '1,-1082130432,-1082130432,1065353216,1065353216']
    end
  end

  describe '#minmax' do
    it 'should appropriately cap minimum values' do
      @drone.minmax(-1.0, 0, -1.5).should == [-1.0]
    end

    it 'should appropriately cap maximum values' do
      @drone.minmax(0, 1.0, 1.5).should == [1.0]

    end

    it 'should preserve valid values' do
      @drone.minmax(-1.0, 1.0, 0.5).should == [0.5]
    end

    it 'should process multiple values' do
      @drone.minmax(-1.0, 1.0, -1.5, -0.5, 1.5).should == [-1.0, -0.5, 1.0]
    end
  end

  describe '#takeoff' do
    before :each do
      # Reset the sequence number on each iteration.
      @drone.seq = nil
    end

    it 'should generate the correct command' do
      @drone.takeoff.should == "AT*REF=1,290718208\n"
    end
  end

  describe '#land' do
    before :each do
      @drone.seq = nil
    end

    it 'should generate the correct command' do
      @drone.land.should == "AT*REF=1,290717696\n"
    end
  end

  describe '#steer' do
    it 'should generate the correct command' do
      flexmock(@drone).should_receive(:pcmd).once.with(1, 0.5, 0.2, -0.1, -0.3).and_return ['AT*PCMD', '1,0,0,0,0']
      @drone.steer 0.5, 0.2, -0.1, -0.3
    end
  end

  describe '#hover' do
    it 'should generate the correct command' do
      @drone.hover.should == "AT*PCMD=1,0,0,0,0,0\n"
    end
  end

  describe '#reset_trim' do
    it 'should generate the correct command' do
      @drone.reset_trim.should == "AT*FTRIM=1,\n"
    end
  end

  describe '#heartbeat' do
    it 'should generate the correct command' do
      @drone.heartbeat.should == "AT*COMWDG=1,\n"
    end
  end

  describe '#blink' do
    it 'should generate the correct command' do
      @drone.blink(2,3,4).should == "AT*LED=1,2,3,4\n"
    end
  end

  describe '#dance' do
    it 'should generate the correct command' do
      @drone.dance(2,3).should == "AT*ANIM=1,2,3\n"
    end
  end

  describe '#set_option' do
    it 'should enclose variable names and values in double-quotes' do
      @drone.set_option('name', 'value').should == "AT*CONFIG=1,\"name\",\"value\"\n"
    end
  end
end
