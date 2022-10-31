 --Common Lua Command Definition
 WATERMODE = 0
 AIRMODE = 1

 DRIVELEFT = 0
 DRIVERIGHT = 1
 DRIVEMAIN = 8

 --Local Command
 MinimumRange = 200
 MaximumRange = 400
 AcceptReverse = false
 DesiredAngle = 90

 function MyUpdateFunction()

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

     if (azimutherror < 0) then
       --Turn right
       I:RequestControl(WATERMODE,DRIVERIGHT,1)
       I:LogToHud("Turning Right!")
       turning = "Right"
     else
       --Turn left
       I:RequestControl(WATERMODE,DRIVELEFT,1)
       I:LogToHud("Turning Left!")
       turning = "Left"
     end

     if (reverse) then
        I:RequestControl(WATERMODE,DRIVEMAIN,-5)
     else
        I:RequestControl(WATERMODE,DRIVEMAIN,5)
     end
   else
     I:LogToHud("No target or no AI, stopping")
     I:RequestControl(WATERMODE,DRIVEMAIN,0)
   end

 I:Log(targetposition.Range .. "m  " .. turning .. "  DesiredAzimuth = " .. desiredazimuth .. "  TargetAzimuth = " .. targetpositionazimuth .. "  Error = " .. azimutherror)

 end

 I:BindUpdateFunction(MyUpdateFunction)