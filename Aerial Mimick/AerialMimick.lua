 --Common Lua Command Definition
 WATERMODE = 0
 AIRMODE = 2

 DRIVELEFT = 0
 DRIVERIGHT = 1
 DRIVEROLLLEFT = 2
 DRIVEROLLRIGHT = 3
 DRIVEUP = 4
 DRIVEDOWN = 5
 DRIVEMAIN = 8

 --Feedback Controller
 Pyaw = 1
 Proll = 1
 Ppitch = 1

 --Local Command
 MinimumRange = 200
 MaximumRange = 300
 AcceptReverse = false
 DesiredAngle = 90

 DesiredAltitude = 200

 --Static variable
 firstpass = true
 turning = ""
 turningpitch_last = ""

 function ActionPitch(I, pitcherror)

    pitchcommand = Ppitch * pitcherror

    if (pitchcommand > 0) then
      if pitchcommand > math.random(100) then
        I:RequestControl(AIRMODE,DRIVEUP,1)
        turningpitch = "PitchUp"
      else
        I:RequestControl(AIRMODE,DRIVEUP,0)
        I:RequestControl(AIRMODE,DRIVEDOWN,0)
        turningpitch = "PitchNone"
      end
    else
      if pitchcommand < -math.random(100) then
        I:RequestControl(AIRMODE,DRIVEDOWN,1)
        turningpitch = "PitchDown"
      else
        I:RequestControl(AIRMODE,DRIVEUP,0)
        I:RequestControl(AIRMODE,DRIVEDOWN,0)
        turningpitch = "PitchNone"
      end
    end

 I:Log(turningpitch .." " .. pitcherror)
    if not (turningpitch == turningpitch_last) then I:Log(turningpitch) end
    turningpitch_last = turningpitch
 end

 function ActionRoll(I, rollerror)

    rollcommand = Proll * rollerror

    if (rollcommand > 0) then
      if rollcommand > math.random(100) then
        I:RequestControl(AIRMODE,DRIVEROLLLEFT,1)
        turningroll = "RollLeft"
      else
        I:RequestControl(AIRMODE,DRIVEROLLRIGHT,0)
        I:RequestControl(AIRMODE,DRIVEROLLLEFT,0)
        turningroll = "RollNone"
      end
    else
      if rollcommand < -math.random(100) then
        I:RequestControl(AIRMODE,DRIVEROLLRIGHT,1)
        turningroll = "RollRight"
      else
        I:RequestControl(AIRMODE,DRIVEROLLRIGHT,0)
        I:RequestControl(AIRMODE,DRIVEROLLLEFT,0)
        turningroll = "RollNone"
      end
    end
 end

 function ActionYaw(I, yawerror)

    yawcommand = Pyaw * yawerror

    if (yawcommand > 0) then
      if yawcommand > math.random(100) then
        I:RequestControl(AIRMODE,DRIVELEFT,1)
        turningyaw = "YawLeft"
      else
        I:RequestControl(AIRMODE,DRIVERIGHT,0)
        I:RequestControl(AIRMODE,DRIVELEFT,0)
        turningyaw = "YawNone"
      end
    else
      if yawcommand < -math.random(100) then
        I:RequestControl(AIRMODE,DRIVERIGHT,1)
        turningyaw = "YawRight"
      else
        I:RequestControl(AIRMODE,DRIVERIGHT,0)
        I:RequestControl(AIRMODE,DRIVELEFT,0)
        turningyaw = "YawNone"
      end
    end
 end

 function Update(I)
   if (firstpass) then
     firstpass = false
     math.randomseed(I:GetTime())
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

     ActionYaw(I, azimutherror)
     ActionRoll(I, GetAngleDelta(-I:GetConstructRoll(),0))
     ActionPitch(I, GetAngleDelta(I:GetConstructPitch(), -15))


   else
     I:LogToHud("No target or no AI")
     ActionYaw(I, 0)
     ActionRoll(I, GetAngleDelta(-I:GetConstructRoll(),0))
     ActionPitch(I, GetAngleDelta(I:GetConstructPitch(),-15))

   end

   --Place AI always full speed
   I:RequestControl(WATERMODE,DRIVEMAIN,5)

   I:RequestControl(AIRMODE,DRIVEMAIN,5)

 end

 -------------------------
 function GetAngleDelta(a, b)
   result = a - b
   if result > 180 then result= result - 360 end
   if result < -180 then result = result + 360 end
   return result
 end
