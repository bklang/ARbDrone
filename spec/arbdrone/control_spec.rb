require 'spec_helper'
require 'arbdrone/control'

describe ARbDrone::Control do
  before :each do
    @drone = ARbDrone::Control.new
  end

  after :each do
    @drone = nil
  end

  it 'should set the correct default drone IP and port' do
    sock = UDPSocket.new
    flexmock(UDPSocket).should_receive(:new).once.and_return(sock)
    flexmock(sock).should_receive(:connect).once.with('192.168.0.1', 5556)
    ARbDrone::Control.new
  end

  describe '#ref' do
    before :each do
      @flags  = 1 << 18
      @flags |= 1 << 20
      @flags |= 1 << 22
      @flags |= 1 << 24
      @flags |= 1 << 28

      # Reset the sequence number on each iteration.  We are not testing seq.
      @drone.seq = nil
    end

    it 'should set the constant bits in the input' do
      @drone.ref(0).should == "AT*REF=1,#{@flags}"
    end

    it 'should preserve input bits' do
      input = 1 << 8
      flags = @flags | input
      @drone.ref(input).should == "AT*REF=1,#{flags}"
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
end
