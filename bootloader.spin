OBJ
  Dbg : "FullDuplexSerial"
  Math : "Float32"

  Robot : "p2os"
  Ctrl : "Propel_IR_Remote"
  Mapper : "mapper"
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  BITMAP_WIDTH    = 800
  BITMAP_HEIGHT   = 600

  BITMAP_ROBOT_MIN_COORD = (Robot#MIN_COORD)
  BITMAP_ROBOT_MAX_COORD = (Robot#MAX_COORD)

  BITMAP_MM_PER_PIXEL = (BITMAP_ROBOT_MAX_COORD - BITMAP_ROBOT_MIN_COORD) / BITMAP_WIDTH 
  
  SONAR_CONE_DEGREES = 15

  ' Maximum readable sensor distance
  MAX_SENSOR_READ_DISTANCE = 5000

  MAX_OBJECT_DETECT_DISTANCE = 2400
  MAX_OBJECT_DETECT_DISTANCE_P = (MAX_OBJECT_DETECT_DISTANCE / BITMAP_MM_PER_PIXEL)

  ' Distances used in the probability calculations.
  PROBABILITY_DISTANCE_BAND = 100
VAR
  long mappingStack[128]
  byte mappingCog, sonarEnabled
PUB main | canMap, pixelX, pixelY, pixelColor, robotX, robotY, robotTheta, currentDriveVelocity, maxDriveVelocity, lastDriveVelocity, currentTurnVelocity, maxTurnVelocity, lastTurnVelocity, lastLight
  ' Dbg.start(31,30,0,9_600)

  Math.start
  
  ' Dbg.Str(string("Initializing...",13))
  IF Robot.start(16,17) == 0
    ' Dbg.Str(string("Failed to init.",13))
    abort
  ELSE
    ' Dbg.Str(string("Robot initialized successfully.",13))

  mappingCog := cognew(DoMap,@mappingStack) 
   

        
  ' Dbg.Str(string("Bitmap created."))
  
  Ctrl.start(18,0)
  ' Dbg.Str(string("Controller started."))

                                                      
    
  repeat
    maxDriveVelocity := Robot#MAX_DRIVE_VELOCITY * Ctrl.Velocity / 100
    maxTurnVelocity  := Robot#MAX_TURN_VELOCITY * Ctrl.Velocity / 100
    
    IF cnt - Ctrl.LastUpdated > clkfreq
      maxDriveVelocity := 0
      maxTurnVelocity := 0

    IF ctrl.Light AND NOT ctrl.Light == lastLight
      sonarEnabled := !sonarEnabled
    lastLight := ctrl.Light
    
    IF ctrl.Up > 0
      currentDriveVelocity := maxDriveVelocity * ctrl.Up / 100
    ELSE
      currentDriveVelocity := -maxDriveVelocity * ctrl.Down / 100

    IF ctrl.Left > 0
      currentTurnVelocity := maxTurnVelocity * ctrl.Left / 100
    ELSE
      currentTurnVelocity := -maxTurnVelocity * ctrl.Right / 100

    IFNOT lastDriveVelocity == currentDriveVelocity
      Robot.Drive(currentDriveVelocity)
      lastDriveVelocity := currentDriveVelocity
      
    IFNOT lastTurnVelocity == currentTurnVelocity
      Robot.Turn(currentTurnVelocity)
      lastTurnVelocity := currentTurnVelocity 

PRI DoMap | canMap, robotX, robotY, robotTheta
  canMap := Mapper.start(BITMAP_WIDTH,BITMAP_HEIGHT)
   
  IF canMap
    sonarEnabled := true
    Robot.SetSonar(true)
    waitcnt(clkfreq + cnt)
    Robot.SetSonar(false)                                     
    Mapper.New(string("Testing.bmp"))
    Robot.SetSonar(sonarEnabled)
    
  ELSE
    repeat 4
      Robot.SetSonar(true)
      waitcnt(clkfreq / 4 + cnt)
      Robot.SetSonar(false)
      waitcnt(clkfreq / 4 + cnt)
      abort
  
  REPEAT
    IF NOT sonarEnabled AND Mapper.IsOpen
      Robot.SetSonar(false)
      waitcnt(clkfreq / 10 + cnt)
      Robot.SetSonar(true)
      Mapper.Close
      Robot.SetSonar(false) 
    ELSEIF sonarEnabled AND NOT Mapper.IsOpen
      Mapper.Open
      Robot.SetSonar(true)
      
    IF sonarEnabled
      IFNOT Robot.XPos == robotX AND Robot.YPos == robotY AND Robot.Theta == robotTheta
        robotX := Robot.XPos
        robotY := Robot.YPos
        robotTheta := Robot.Theta
        
        MapSonarCone(robotX,robotY,robotTheta,Robot#SONAR_0_POSITION_X,Robot#SONAR_0_POSITION_Y,Robot#SONAR_0_ANGLE,Robot.GetSonarReading(0))
        MapSonarCone(robotX,robotY,robotTheta,Robot#SONAR_1_POSITION_X,Robot#SONAR_1_POSITION_Y,Robot#SONAR_1_ANGLE,Robot.GetSonarReading(1))
        MapSonarCone(robotX,robotY,robotTheta,Robot#SONAR_2_POSITION_X,Robot#SONAR_2_POSITION_Y,Robot#SONAR_2_ANGLE,Robot.GetSonarReading(2))
        MapSonarCone(robotX,robotY,robotTheta,Robot#SONAR_3_POSITION_X,Robot#SONAR_3_POSITION_Y,Robot#SONAR_3_ANGLE,Robot.GetSonarReading(3))
        MapSonarCone(robotX,robotY,robotTheta,Robot#SONAR_4_POSITION_X,Robot#SONAR_4_POSITION_Y,Robot#SONAR_4_ANGLE,Robot.GetSonarReading(4))
        MapSonarCone(robotX,robotY,robotTheta,Robot#SONAR_5_POSITION_X,Robot#SONAR_5_POSITION_Y,Robot#SONAR_5_ANGLE,Robot.GetSonarReading(5))
        MapSonarCone(robotX,robotY,robotTheta,Robot#SONAR_6_POSITION_X,Robot#SONAR_6_POSITION_Y,Robot#SONAR_6_ANGLE,Robot.GetSonarReading(6))
        MapSonarCone(robotX,robotY,robotTheta,Robot#SONAR_7_POSITION_X,Robot#SONAR_7_POSITION_Y,Robot#SONAR_7_ANGLE,Robot.GetSonarReading(7))
         
        ' Overlay path robot follows
        Mapper.DrawPoint(WorldCoordToScreen(robotX),WorldCoordToScreen(robotY),$A)

      
      
PRI WorldCoordToScreen(coord)
  RETURN (coord - BITMAP_ROBOT_MIN_COORD) / BITMAP_MM_PER_PIXEL          

PRI MapSonarCone(robotX,robotY,robotTheta,sonarX,sonarY,sonarTheta,sonarReading) | sonarPixelX, sonarPixelY, pixelX, pixelY, lastPixelX, lastPixelY, deltaTheta, deltaThetaRadians, theta, deltaDistance
  {{
      robot[XY]: Robot position, in world-space
      robotTheta: Robot orientation (0-360) in world-space
      sonar[XY]: Sonar position, in robot-space
      sonarTheta: Sonar orientation  (0-360) in robot-space
      sonarReading: Distance reading of the sonar
  }}
  IF sonarReading => MAX_OBJECT_DETECT_DISTANCE
    RETURN
  ' Transform sonar coordinates from robot-space to world-space
  TransformCoords(@sonarX,@sonarY,robotX,robotY,robotTheta)    

  ' Get screen coordinates for the sonar
  sonarPixelX := WorldCoordToScreen(sonarX)
  sonarPixelY := WorldCoordToScreen(sonarY)

  ' Determine theta in world-space
  theta := sonarTheta + robotTheta


  Mapper.DrawPoint(pixelX,pixelY,0)
   
  REPEAT deltaTheta FROM -SONAR_CONE_DEGREES / 2 TO SONAR_CONE_DEGREES / 2 STEP 2
    REPEAT deltaDistance FROM 0 TO MAX_OBJECT_DETECT_DISTANCE_P
      pixelX := sonarPixelX + Math.FTrunc(Math.FMul(Math.FFloat(deltaDistance),Math.Cos(Math.Radians(Math.FFloat(theta+deltaTheta)))))
      pixelY := sonarPixelY + Math.FTrunc(Math.FMul(Math.FFloat(deltaDistance),Math.Sin(Math.Radians(Math.FFloat(theta+deltaTheta)))))
      IF deltaDistance * BITMAP_MM_PER_PIXEL > sonarReading
        QUIT
      
      IFNOT pixelX == lastPixelX AND pixelY == lastPixelY
        IF pixelX > 0 AND pixelX =< BITMAP_WIDTH AND pixelY > 0 AND pixelY =< BITMAP_HEIGHT           
          IF CalculateProbability(deltaDistance * BITMAP_MM_PER_PIXEL,deltaTheta,sonarReading) == 1
            lastPixelX := pixelX
            lastPixelY := pixelY
  
            ' Dbg.Dec(pixelX)
            ' Dbg.Str(string(","))
            ' Dbg.Dec(pixelY)
            ' Dbg.Str(string(13))
            Mapper.DrawPoint(pixelX,pixelY,0)


PRI CalculateProbability(deltaDistance,deltaTheta,sonarReading) : prob | deltaDistMM, objDistMM
{{
    Determines the probability of a certain point in a sonar's cone being an object.
}}
  
  IF ||(deltaDistance - sonarReading) > PROBABILITY_DISTANCE_BAND OR sonarReading > MAX_OBJECT_DETECT_DISTANCE + PROBABILITY_DISTANCE_BAND OR deltaTheta > 3
    ' Probability that the current location is an object is zero if the current test
    ' distance falls outside of the probability distance band or the sonar reading
    ' is greater than the maximum object detection distance
    prob := 0
  ELSE
    ' Probability is dependent on the angle and distance if the current test distance
    ' falls within the probability distance band
    prob := 1 '(MAX_SONAR_READ_DISTANCE - deltaDistance) * 100 / MAX_SONAR_READ_DISTANCE     

PRI TransformCoords(relativeCoordXPtr,relativeCoordYPtr,baseCoordX,baseCoordY,baseAngle)
  IFNOT baseAngle == 0
    baseAngle := Math.Radians(baseAngle)
    long[relativeCoordXPtr] += Math.FTrunc(Math.FSub(Math.FMul(Math.Cos(baseAngle),Math.FFloat(baseCoordX)),Math.FMul(Math.Sin(baseAngle),Math.FFloat(baseCoordY))))
    long[relativeCoordYPtr] += Math.FTrunc(Math.FAdd(Math.FMul(Math.Sin(baseAngle),Math.FFloat(baseCoordX)),Math.FTrunc(Math.FMul(Math.Cos(baseAngle),Math.FFloat(baseCoordY)))))
  ELSE
    long[relativeCoordXPtr] += baseCoordX
    long[relativeCoordYPtr] += baseCoordY
  