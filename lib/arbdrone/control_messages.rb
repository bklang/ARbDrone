require 'arbdrone/math'

module ARbDrone::ControlMessages
  include ARbDrone::Math

  # With SDK version 1.5, only bits 8 and 9 are used in the
  # control bit-field. Bits 18, 20, 22, 24 and 28 should be
  # set to 1. Other bits should be set to 0.
  REF_CONST = 290717696

  def ref(input)
    ['AT*REF', input.to_i | REF_CONST]
  end

  def anim(animation, duration)
    ['AT*ANIM', "#{animation},#{duration}"]
  end

  def comwdg
    ['AT*COMWDG']
  end

  def config(name, value)
    ['AT*CONFIG', "\"#{name}\",\"#{value}\""]
  end

  def configids(sess_id, user_id, app_id)
    ['AT*CONFIG_IDS', "#{sess_id},#{user_id},#{app_id}"]
  end

  def ctrl(mode, something)
    # FIXME: What is the function of "something"?
    ['AT*CTRL', "#{mode},#{something}"]
  end

  def ftrim
    ['AT*FTRIM']
  end

  def led(animation, frequency, duration)
    ['AT*LED', "#{animation},#{float2int frequency},#{duration}"]
  end

  def pcmd(flags, phi, theta, gaz, yaw)
    values = [flags]

    # Ensure the inputs do not exceed [-1.0, 1.0]
    phi, theta, gaz, yaw = minmax -1.0, 1.0, phi, theta, gaz, yaw

    # Convert the values to IEEE 754, then cast to a signed int
    values += [phi, theta, gaz, yaw].map { |v| float2int v }
    ['AT*PCMD', values.join(',')]
  end
end
