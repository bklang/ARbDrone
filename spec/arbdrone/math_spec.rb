require 'arbdrone/math'

class MathTest
  include ARbDrone::Math
end

describe ARbDrone::Math do
  before :all do
    @tester = MathTest.new
  end

  describe '#minmax' do
    it 'should properly limit inputs' do
      @tester.minmax(0, 1, -1, -0.5, 0, 0.5, 1, 1.5, 1000).should == [0, 0, 0, 0.5, 1, 1, 1]
    end
  end

  describe '#int2float' do
    it 'should properly convert the input' do
      pending "The calculated values are not exactly inverse."
      # Example: int2float(float2int(0.1)) # => 0.10000000149011612
      @tester.int2float(0).should == 0
      @tester.int2float(1036831949).should == 0.1
      @tester.int2float(1056964608).should == 0.5
      @tester.int2float(1069547520).should == 1.5
      @tester.int2float(1112145920).should == 50.50
      @tester.int2float(-1110651699).should == -0.1
      @tester.int2float(-1090519040).should == -0.5
      @tester.int2float(-1077936128).should == -1.5
    end
  end

  describe '#float2int' do
    it 'should properly convert the input' do
      @tester.float2int(0).should == 0
      @tester.float2int(0.1).should == 1036831949
      @tester.float2int(0.5).should == 1056964608
      @tester.float2int(1.5).should == 1069547520
      @tester.float2int(50.50).should == 1112145920
      @tester.float2int(-0.1).should == -1110651699
      @tester.float2int(-0.5).should == -1090519040
      @tester.float2int(-1.5).should == -1077936128
    end
  end
end
