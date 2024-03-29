CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  
  CMD_SYNC0        =   0
  CMD_SYNC1        =   1
  CMD_SYNC2        =   2
  
  CMD_PULSE        =   0
  CMD_OPEN         =   1
  CMD_CLOSE        =   2
  CMD_POLLING      =   3
  CMD_ENABLE       =   4
  CMD_SETA         =   5
  CMD_SETV         =   6
  CMD_SETO         =   7
  CMD_MOVE         =   8
  CMD_ROTATE       =   9
  CMD_SETRV        =  10
  CMD_VEL          =  11
  CMD_HEAD         =  12
  CMD_DHEAD        =  13
  CMD_SAY          =  15
  CMD_JOYREQUEST   =  17
  CMD_CONFIG       =  18
  CMD_ENCODER      =  19
  CMD_RVEL         =  21
  CMD_DCHEAD       =  22
  CMD_SETRA        =  23
  CMD_SONAR        =  28
  CMD_STOP         =  29
  CMD_VEL2         =  32
  CMD_GRIPPER      =  33
  CMD_ADSEL        =  35
  CMD_GRIPPERVAL   =  36
  CMD_GRIPREQUEST  =  37
  CMD_IOREQUEST    =  40
  CMD_TTY2         =  42
  CMD_GETAUX       =  43
  CMD_BUMP_STALL   =  44
  CMD_TCM2         =  45
  CMD_JOYDRIVE     =  47
  CMD_SONARCYCLE   =  48
  CMD_HOSTBAUD     =  50
  CMD_AUX1BAUD     =  51
  CMD_AUX2BAUD     =  52
  CMD_AUX3BAUD     =  53
  CMD_E_STOP       =  55
  CMD_M_STALL      =  56
  CMD_GYROREQUEST  =  58
  CMD_LCDWRITE     =  59
  CMD_TTY4         =  60
  CMD_GETAUX3      =  61
  CMD_TTY3         =  66
  CMD_GETAUX2      =  67
  CMD_CHARGE       =  68
  CMD_ARM_INFO     =  70
  CMD_ARM_STATUS   =  71
  CMD_ARM_INIT     =  72
  CMD_ARM_CHECK    =  73
  CMD_ARM_POWER    =  74
  CMD_ARM_HOME     =  75
  CMD_ARM_PARK     =  76
  CMD_ARM_POS      =  77
  CMD_ARM_SPEED    =  78
  CMD_ARM_STOP     =  79
  CMD_ARM_AUTOPARK =  80
  CMD_ARM_GRIPPARK =  81  
  CMD_ROTKP        =  82
  CMD_ROTKV        =  83
  CMD_ROTKI        =  84
  CMD_TRANSKP      =  85
  CMD_TRANSKV      =  86
  CMD_TRANSKI      =  87
  CMD_REVCOUNT     =  88
  CMD_DRIFTFACTOR  =  89
  CMD_SOUNDTOG     =  92
  CMD_TICKSMM      =  93
  CMD_BATTEST      = 250
  CMD_RESET        = 253
  CMD_MAINTENANCE  = 255
  
  SIP_TYPE_STOPPED = $32
  SIP_TYPE_MOVING  = $33
  SIP_TYPE_CONFIGPAC = $20
  
  
  P2OS_CYCLETIME_USEC = 200_000
  MAX_RETRIES = 3
  
  NUM_SONARS = 8

  MAX_DRIVE_VELOCITY = 500
  MAX_TURN_VELOCITY  = 90

  MAX_THETA = 4096
  MIN_COORD = -32767
  MAX_COORD =  32768 
  
  SONAR_0_POSITION_X = 75
  SONAR_0_POSITION_Y = 130
  SONAR_0_ANGLE = 90

  SONAR_1_POSITION_X = 115
  SONAR_1_POSITION_Y = 115
  SONAR_1_ANGLE = 50

  SONAR_2_POSITION_X = 150
  SONAR_2_POSITION_Y = 80
  SONAR_2_ANGLE = 30

  SONAR_3_POSITION_X = 170
  SONAR_3_POSITION_Y = 25
  SONAR_3_ANGLE = 10
  
  SONAR_4_POSITION_X = 170
  SONAR_4_POSITION_Y = -25
  SONAR_4_ANGLE = 360-10

  SONAR_5_POSITION_X = 150
  SONAR_5_POSITION_Y = -80
  SONAR_5_ANGLE = 360-30

  SONAR_6_POSITION_X = 115
  SONAR_6_POSITION_Y = -115
  SONAR_6_ANGLE = 360-50

  SONAR_7_POSITION_X = 75
  SONAR_7_POSITION_Y = -130
  SONAR_7_ANGLE = 360-90
  
  {
    Sonar orientation:
    0 = x: 0.075, y:  0.130, theta:  90
    1 = x: 0.115, y:  0.115, theta:  50
    2 = x: 0.150, y:  0.080, theta:  30
    3 = x: 0.170, y:  0.025, theta:  10
    4 = x: 0.170, y: -0.025, theta: -10
    5 = x: 0.150, y: -0.080, theta: -30
    6 = x: 0.115, y: -0.115, theta: -50
    7 = x: 0.075, y: -0.130, theta: -90
  }
  
OBJ
  tx_packet : "p2os_packet"
  rx_packet : "p2os_packet"
VAR
  long recv_stack[256]
  long roam_stack[64]
  byte cog
  
  ' SIP Data
  ' Wheel-encoder integrated coordinates in mm
  word xPosition,yPosition
  
  ' Orientation in degrees
  word thPosition
  
  ' Wheel velocities in mm/s
  word leftVelocity,rightVelocity
  
  ' Battery charge in tenths of volts (101 = 10.1V)
  byte batteryChargeTenths
  
  byte leftWheelStalled,rightWheelStalled
  
  ' Setpoint of the server's angular position servo in degrees
  word control
  
  ' Bit 0    = Motors status
  ' Bits 1-4 = Sonar array status
  ' Bits 5,6 = STOP
  ' Bits 7,8 = Ledge-Sense IRs
  ' Bit 9    = Joystick fire button
  ' Bit 10   = Auto-charger power-good
  word flags
  
  byte motorsStatus,sonarArrayStatus[4]
  
  ' Electronic compass accessory heading in 2-degree units
  byte compass
  
  word sonar_reading[NUM_SONARS]
  
  byte gripperState
  byte analogPortNumber,analogInput
  byte digitalInput,digitalOutput
  word batteryX10
  byte chargeState
  
  ' CONFIGpac Variables
  word maxRotationVelocity,maxTranslationVelocity,maxRotationAcceleration,maxTranslationAcceleration
  word maxMotorPWM
  
  word curMaxRotationVelocity,curMaxTranslationVelocity
  word rotationAcceleration, rotationDeceleration
  word translationAcceleration, translationDeceleration

PUB start(rx_pin,tx_pin) : okay
  tx_packet.Init(0,tx_pin,9_600)
  rx_packet.Init(rx_pin,0,9_600)

  IF Sync
    ' Start up servers
    tx_packet.BuildPacket(CMD_OPEN,0,1)
    tx_packet.SendPacket   
     
    ' Enable motors
    SendInt(CMD_ENABLE,1)
  SendInt(CMD_SETV,MAX_DRIVE_VELOCITY)
  SendInt(CMD_SETRV,MAX_TURN_VELOCITY)
    
  okay := (cog := cognew(ReceiveLoop,@recv_stack)+1)

PUB stop
  IF cog
    cogstop(cog-1)
    
PUB Drive(velocity)
  SendInt(CMD_VEL,velocity)

PUB DriveMM(velocity,mm)
  SendInt(CMD_MOVE,mm)

PUB Turn(velocity)
  SendInt(CMD_ROTATE,velocity)

PUB TurnDeg(velocity,degrees)
  SendInt(CMD_DHEAD,degrees)

PUB GetSonarReading(num)
  RETURN sonar_reading[num]

PUB SetSonar(on)
  IF on
    SendInt(CMD_SONAR,1)
  ELSE
    SendInt(CMD_SONAR,0)


PUB Kill
  tx_packet.BuildPacket(CMD_CLOSE,0,0)
  tx_packet.SendPacket

PUB RequestConfig
  tx_packet.BuildPacket(CMD_CONFIG,0,0)
  tx_packet.SendPacket

PUB MaxRotVel
  return maxRotationVelocity
PUB MaxRotAccel
  return maxRotationAcceleration
PUB MaxTransVel
  return maxTranslationVelocity
PUB MaxTransAccel
  return maxTranslationAcceleration

PUB CurMaxRotVel
  return curMaxRotationVelocity
PUB CurMaxTransVel
  return curMaxTranslationVelocity

PUB RotAcc
  return rotationAcceleration
PUB RotDec
  return rotationDeceleration

PUB TransAcc
  return translationAcceleration
PUB TransDec
  return translationDeceleration

PUB XPos
  return ~~xPosition
PUB YPos
  return ~~yPosition
PUB Theta
  return thPosition * 360 / MAX_THETA 

  
PRI SendInt(cmd,value)
  tx_packet.BuildPacketInt(cmd,~~value)
  tx_packet.SendPacket

PRI Sync : okay
  okay := false
  
  tx_packet.BuildPacket(CMD_SYNC0,0,0)
  tx_packet.SendPacket
    
  usleep(P2OS_CYCLETIME_USEC)  
  rx_packet.ReceivePacket(true)
  
  IF rx_packet.GetByte(3) == CMD_SYNC0
    tx_packet.BuildPacket(CMD_SYNC1,0,1)
    tx_packet.SendPacket
    
    usleep(P2OS_CYCLETIME_USEC)
    rx_packet.ReceivePacket(true)

    IF rx_packet.GetByte(3) == CMD_SYNC1
      tx_packet.BuildPacket(CMD_SYNC2,0,2)
      tx_packet.SendPacket
      
      usleep(P2OS_CYCLETIME_USEC)
      rx_packet.ReceivePacket(true)
      ' Rest of packet contains name, class and subclass values
      IF rx_packet.GetByte(3) == CMD_SYNC2
        okay := true

PRI ReceiveLoop | lastConfigPacket, type, value, i
  repeat
    rx_packet.ReceivePacket(false)
    
    IF cnt - lastConfigPacket => clkfreq
      lastConfigPacket := cnt
      RequestConfig
    
    IF rx_packet.Type == SIP_TYPE_STOPPED OR rx_packet.Type == SIP_TYPE_MOVING
      xPosition := rx_packet.GetInt(4)
      yPosition := rx_packet.GetInt(-1)
      thPosition := rx_packet.GetInt(-1)
      leftVelocity := rx_packet.GetInt(-1)
      rightVelocity := rx_packet.GetInt(-1)
      batteryChargeTenths := rx_packet.GetByte(-1)
      
      ' Stall and Bumpers
      value := rx_packet.GetInt(-1)
      leftWheelStalled  := (value & $01 == $01)
      rightWheelStalled := (value & $10 == $10)
      
      control := rx_packet.GetInt(-1)
      flags   := rx_packet.GetInt(-1)
      compass := rx_packet.GetByte(-1)
      
      ' Repeat for each sonar
      repeat rx_packet.GetByte(-1)
        value := rx_packet.GetByte(-1) ' Sonar number
        sonar_reading[value] := rx_packet.GetInt(-1)

      gripperState := rx_packet.GetByte(-1)
      analogPortNumber := rx_packet.GetByte(-1)
      analogInput := rx_packet.GetByte(-1)
      digitalInput := rx_packet.GetByte(-1)
      digitalOutput := rx_packet.GetByte(-1)
      batteryX10 := rx_packet.GetInt(-1)
      chargeState := rx_packet.GetByte(-1)
    ELSEIF rx_packet.Type == SIP_TYPE_CONFIGPAC
      ' Robot Type (Pioneer)
      rx_packet.GetString(0,0,4,false)      
      
      ' Robot Subtype (p3dx-sh)
      rx_packet.GetString(0,0,-1,false)
      
      ' Serial Number (Serial)
      rx_packet.GetString(0,0,-1,false)

      ' 4mots
      rx_packet.GetByte(-1)
      
      maxRotationVelocity := rx_packet.GetInt(-1)
      maxTranslationVelocity := rx_packet.GetInt(-1)
      maxRotationAcceleration := rx_packet.GetInt(-1)
      maxTranslationAcceleration := rx_packet.GetInt(-1)
      maxMotorPWM := rx_packet.GetInt(-1)
      
      ' Unique Robot Name
      rx_packet.GetString(0,0,-1,false)
      rx_packet.GetByte(-1) ' SIPcycle
      rx_packet.GetByte(-1) ' Host Baud
      rx_packet.GetByte(-1) ' AUX1 Baud
      rx_packet.GetInt(-1)  ' Gripper
      rx_packet.GetInt(-1)  ' Front Sonar
      rx_packet.GetByte(-1) ' Rear Sonar
      rx_packet.GetInt(-1)  ' Low Battery
      rx_packet.GetInt(-1)  ' Rev Count
      rx_packet.GetInt(-1)  ' Watchdog
      rx_packet.GetByte(-1) ' P2mpacs
      rx_packet.GetInt(-1)  ' Stall Value
      rx_packet.GetInt(-1)  ' Stall Count
      rx_packet.GetInt(-1)  ' Joystick Translation Velocity
      rx_packet.GetInt(-1)  ' Joystick Rotation Velocity
      curMaxRotationVelocity := rx_packet.GetInt(-1)
      curMaxTranslationVelocity := rx_packet.GetInt(-1)
      rotationAcceleration := rx_packet.GetInt(-1)
      rotationDeceleration := rx_packet.GetInt(-1)
      rx_packet.GetInt(-1)  ' Proportional PID for rotation
      rx_packet.GetInt(-1)  ' Derivative PID for rotation  
      rx_packet.GetInt(-1)  ' Integral PID for rotation
      translationAcceleration := rx_packet.GetInt(-1)
      translationDeceleration := rx_packet.GetInt(-1)
      rx_packet.GetInt(-1)  ' Proportional PID for translation
      rx_packet.GetInt(-1)  ' Derivative PID for translation
      rx_packet.GetInt(-1)  ' Integral PID for translation
      rx_packet.GetByte(-1) ' # of front bumpers
      rx_packet.GetByte(-1) ' # of rear bumpers
      rx_packet.GetByte(-1) ' Charger type
      rx_packet.GetByte(-1) ' Sonar Cycle
      rx_packet.GetByte(-1) ' Auto Baud
      rx_packet.GetByte(-1) ' Has Gyro
      rx_packet.GetInt(-1)  ' Drift Factor
      rx_packet.GetByte(-1) ' Aux 2 Baud
      rx_packet.GetByte(-1) ' Aux 3 Baud
      rx_packet.GetInt(-1)  ' Encoder ticks / mm
      rx_packet.GetInt(-1)  ' Shutdown Volts
      rx_packet.GetString(0,0,-1,false) ' Major version
      rx_packet.GetString(0,0,-1,false) ' Minor Version
      rx_packet.GetInt(-1)  ' Charge Threshold
      
PRI usleep(usec)
  waitcnt(clkfreq * usec / 1_000_000 + cnt)