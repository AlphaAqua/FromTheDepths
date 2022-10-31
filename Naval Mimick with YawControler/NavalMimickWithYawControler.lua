
 --Common Lua Command Definition
 WATERMODE = 0
 AIRMODE = 1

 DRIVELEFT = 0
 DRIVERIGHT = 1
 DRIVEMAIN = 8

 --Feedback Controller
 P = 10

 --Local Command
 MinimumRange = 200
 MaximumRange = 300
 AcceptReverse = false
 DesiredAngle = 90

 --Static variable
 firstpass = true
 turning = ""
 debug = false

 function ActionYaw(azimutherror)

    yawcommand = P * azimutherror
    yawcommand = math.max(math.min(yawcommand, 100), -100)

    if (yawcommand > 0) then
      if yawcommand > math.random(100) then
        I:RequestControl(WATERMODE,DRIVELEFT,1)
        turning = "right"
      else
        I:RequestControl(WATERMODE,DRIVERIGHT,0)
        I:RequestControl(WATERMODE,DRIVELEFT,0)
        turning = "none"
      end
    else
      if yawcommand < -math.random(100) then
        I:RequestControl(WATERMODE,DRIVERIGHT,1)
        turning = "left"
      else
        I:RequestControl(WATERMODE,DRIVERIGHT,0)
        I:RequestControl(WATERMODE,DRIVELEFT,0)
        turning = "none"
      end
    end
 end

 function MyUpdateFunction()
   if (firstpass) then
     firstpass = false
     math.randomseed(os.time())
   end

   if (I:GetNumberOfMainframes() > 0 and I:GetNumberOfTargets(0) > 0) then
     targetposition = I:GetTargetPositionInfo(0,0)

     if (targetposition.Range < MinimumRange and not AcceptReverse) then
       desiredazimuth = 180
       reverse = false
     elseif (targetposition.Range < MinimumRange and AcceptReverse) then
       desiredazimuth = 0
       reverse = true
     elseif (targetposition.Range > MaximumRange) then
       desiredazimuth = 0
       reverse = false
     elseif (targetposition.Azimuth > 0) then
       desiredazimuth = DesiredAngle
       reverse = false
     else
       desiredazimuth = -DesiredAngle
       reverse = false
     end

     targetpositionazimuth = targetposition.Azimuth
     if targetpositionazimuth < 0 then
       targetpositionazimuth = targetpositionazimuth + 360
     end

     azimutherror = targetpositionazimuth - desiredazimuth
     if azimutherror > 180 then
       azimutherror = azimutherror - 360
     end

     ActionYaw(azimutherror)

     if (reverse) then
        I:RequestControl(WATERMODE,DRIVEMAIN,-5)
     else
        I:RequestControl(WATERMODE,DRIVEMAIN,5)
     end
   else
     I:LogToHud("No target or no AI, stopping")
     I:RequestControl(WATERMODE,DRIVEMAIN,0)
   end

   if debug then
     I:Log("Turning " .. turning ..", AzimuthError: " .. azimutherror)
   end

 end

 I:BindUpdateFunction(MyUpdateFunction)