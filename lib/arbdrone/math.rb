module ARbDrone::Math
  def minmax(min, max, *args)
    args.map {|arg| arg < min ? min : arg > max ? max : arg }
  end

  def float2int(float)
    [float.to_f].pack('e').unpack('l').first
  end

  def int2float(int)
    [int.to_i].pack('l').unpack('e').first
  end
end

