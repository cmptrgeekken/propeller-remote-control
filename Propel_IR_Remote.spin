{{
      Propel_IR_Remote,spin
      Kenneth Beck
      11 July 2011

      Propel Remote for the Gyropter Remote-Control Helicopter
      CH 0 L 0 RGHTJOYSTCK LFTJOY CH          
      Packet Structure:
        Bits 0-1: Channel # (0, 1, or 2)
        Bits 2-7: Left Joystick Position (0-63)
        Bits 8-18: Right Joystick Position
           Bit  8: Direction L/R (1 = L)
           Bits 9-15: L/R Position (High=9, 0-215, >~115=Left, <~115=Right)
           Bits 16-18: Up/Down Position  (High = 16, >4=Down, <4=Up)
        Bit 19: Always 0
        Bit 20: Light (1 = On)
        Bit 21: Always 0
        Bits 22-23: Channel # (0, 1, or 2)  
}}

CON
  _CLKMODE = XTAL1 + PLL16X        ' 80 Mhz clock
  _XINFREQ = 5_000_000

  gapMin       = 6000
  startBitMin  = 4600 ' Reference: ~5000us
  startBitMax  = 5400
  oneBitMin    = 2600
  oneBitMax    = 3400 ' Reference: ~3000us

  ' Bit Masks
  Offset_Channel           = 0
  Offset_LeftJoy           = 2
  Offset_RightJoy          = 8
    Offset_RightJoy_Horiz  = 0
    Offset_RightJoy_Vert   = 8
  Offset_Light             = 20
  Offset_Channel2          = 22
                               
  Mask_Channel             = $03
  Mask_LeftJoy             = $3F
  Mask_RightJoy            = $7FF
    Mask_RightJoy_Horiz    = $03F
    Mask_RightJoy_Vert     = $007
  Mask_Light               = $01
  
  VelocityMin = 0
  VelocityMax = 63

  HorizVelocityLeftMax  = 215
  HorizVelocityCenter   = 115
  HorizVelocityRightMax = 0

  VertVelocityUpMax     = 0
  VertVelocityCenter    = 4
  VertVelocityDownMax   = 7

VAR
  byte cog
  long stack[128]
  byte _pin, _channel
  
  ' Remote settings
  byte _lightOn
  byte _velocityPercent,_upPercent,_downPercent,_leftPercent,_rightPercent
  
  long _lastUpdateTime

PUB start(pin,channel) : okay
  stop
  _pin     := pin
  _channel := channel
  
  dira[_pin]~
  cog := cognew(ReadLoop,@stack)+ 1
  
  okay := true
  
PUB stop
{{
   stop cog if in use
}}
    if cog
      cogstop(cog~ -1)

PUB Velocity
  RETURN _velocityPercent

PUB Up
  RETURN _upPercent

PUB Down
  RETURN _downPercent

PUB Left
  RETURN _leftPercent

PUB Right
  RETURN _rightPercent

PUB Light
  RETURN _lightOn
  
PUB LastUpdated
  RETURN _lastUpdateTime

PRI ReadLoop | code, curChannel, rightJoy, horizVelocity, vertVelocity
  repeat
    code := getCode
    curChannel := getValue(code,Offset_Channel,Mask_Channel)
    
    ' Simple checksum. Packet begins and ends with the same channel number
    IFNOT curChannel == getValue(code,Offset_Channel2,Mask_Channel)
      next
    
    _velocityPercent := getPercent(getValueReverse(code,Offset_LeftJoy,Mask_LeftJoy,6),VelocityMin,VelocityMax)
    
    _lightOn := getValue(code,Offset_Light,Mask_Light) == Mask_Light
    
    rightJoy := getValue(code,Offset_RightJoy,Mask_RightJoy)

    vertVelocity := getValueReverse(rightJoy,Offset_RightJoy_Vert,Mask_RightJoy_Vert,3)
    IF vertVelocity < VertVelocityCenter
      _downPercent := 0
      _upPercent := getPercent(vertVelocity,VertVelocityCenter,VertVelocityUpMax)
    ELSE
      _upPercent := 0
      _downPercent := getPercent(vertVelocity,VertVelocityCenter,VertVelocityDownMax)

    horizVelocity := getValueReverse(rightJoy,Offset_RightJoy_Horiz,Mask_RightJoy_Horiz,8)
    IF horizVelocity < HorizVelocityCenter
      _leftPercent := 0
      _rightPercent := getPercent(horizVelocity,HorizVelocityCenter,HorizVelocityRightMax)
    ELSE
      _rightPercent := 0
      _leftPercent := getPercent(horizVelocity,HorizVelocityCenter,HorizVelocityLeftMax)
      
    _lastUpdateTime := cnt
    

PRI getPercent(val,minimum,maximum) : percent
  IF maximum > minimum
     percent := (val-minimum) * 100 / (maximum-minimum)
  ELSE
    percent := (minimum-val) * 100 / (minimum-maximum)
  IF percent > 100
    percent := 100
    
PRI getValue(code,position,mask) : value
    value := (code >> position) & mask

PRI getValueReverse(code,position,mask,bits) : value | i,tmpValue
  value := 0
  tmpValue := getValue(code,position,mask)
  repeat i from 0 to bits-1
    IFNOT (1 << i) & tmpValue == 0 
      value |= 1 << (bits-i-1)
    
PRI getCode : code | i, pulse
  ' Wait for a start code
  repeat
    pulse := getPulse(false)
  until pulse => startBitMin AND pulse =< startBitMax
  
  repeat i from 0 to 24
    pulse := getPulse(true)
    IF pulse => oneBitMin AND pulse =< oneBitMax
      code |= 1 << i
    ELSEIF pulse => gapMin
      quit

PRI getPulse(skipInitialWait) : width
{{ Returns the pulse width in microseconds }}
  frqa := 1
  ctra := (%10101 << 26) | _pin
  IFNOT skipInitialWait
    waitpne(0 << _pin, |< _pin, 0)
  phsa := 0
  waitpeq(0 << _pin, |< _pin, 0)
  waitpne(0 << _pin, |< _pin, 0)

  width := phsa  / (clkfreq / 1_000_000) + 1
  