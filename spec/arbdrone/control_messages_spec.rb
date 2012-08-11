require 'arbdrone/control_messages'

class TestDrone
  include ARbDrone::ControlMessages
end

describe ARbDrone::ControlMessages do
  before :all do
    @drone = TestDrone.new
  end

  describe '#ref' do
    before :each do
      @flags  = 1 << 18
      @flags |= 1 << 20
      @flags |= 1 << 22
      @flags |= 1 << 24
      @flags |= 1 << 28
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

  describe '#anim' do
    it 'should generate the correct message' do
      @drone.anim(1,2).should == ['AT*ANIM', '1,2']
    end
  end

  describe '#config' do
    it 'should generate the correct command' do
      @drone.config('test_option_name', 'asdf').should == ['AT*CONFIG', '"test_option_name","asdf"']
    end
  end

  describe '#configids' do
    it 'should generate the correct command' do
      @drone.configids(1,2,3).should == ['AT*CONFIG_IDS', '1,2,3']
    end
  end

  describe '#ctrl' do
    it 'should generate the correct command' do
      @drone.ctrl(1,2).should == ['AT*CTRL', '1,2']
    end
  end

  describe '#led' do
    it 'should generate the correct message' do
      @drone.led(1, 0.5, 5).should == ['AT*LED', '1,1056964608,5']
    end
  end

  describe "#pcmd" do
    it 'should format the arguments' do
      @drone.pcmd(1, -0.9, -0.5, 0.2, 0.7).should == ['AT*PCMD', '1,-1083808154,-1090519040,1045220557,1060320051']
    end

    it 'should limit inputs that exceed the min/max' do
      @drone.pcmd(1, -1.9, -1.5, 1.2, 1.7).should == ['AT*PCMD', '1,-1082130432,-1082130432,1065353216,1065353216']
    end
  end

  describe '#heartbeat' do
    it 'should generate the correct command' do
      @drone.comwdg.should == ['AT*COMWDG']
    end
  end

end
