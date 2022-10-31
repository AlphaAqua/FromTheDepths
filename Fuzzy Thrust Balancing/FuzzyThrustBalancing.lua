
 ITERRATE = 40

 --Controller Gain

 SmallCorrection = 10  --Time it takes to ramp to full command in seconds for small correction
 LargeCorrection = 1   --Time it takes to ramp to full command in seconds for large correction
 CorrectionThreshold = 0.1  --Fraction of error range before we use LargeCorrection

 --Default Standard Position
 DesiredPitch = 0
 DesiredRoll = 0
 DesiredAltitude = 300

 firstpass = true


 function Update(I)
   if firstpass then
     for i=0, I:Component_GetCount(9) -1 do
       I:Component_SetFloatLogic(9,i,0.1)
     end

     CommandAltitude = 0
     CommandRoll = 0
     CommandPitch = 0


     LargeCorrection = 1/ (ITERRATE * LargeCorrection)
     SmallCorrection = 1/ (ITERRATE * SmallCorrection)

     --Propulsion Table
     Propulsion = {}

     firstpass = false
     I:ClearLogs()
     I:Log("Starting...")
   end

   --Request all propulsion to start. Need that all propultion manually set to "Main"
   I:RequestControl(0, 8, 5)
   I:RequestControl(1, 8, 5)
   I:RequestControl(2, 8, 5)

   Propulsion = UpdatePropulsionArray(I)

   CommandAltitude = UpdateCommandAltitude(I, DesiredAltitude, CommandAltitude)
   CommandPitch = UpdateCommandPitch(I, DesiredPitch, CommandPitch)


   I:Log("CommandAltitude: " .. CommandAltitude .. " CommandPitch: " .. CommandPitch)

   EffectiveCommandAltitude = CommandAltitude
   EffectiveCommandRoll = CommandRoll
   EffectiveCommandPitch = CommandPitch
   UpdatePropulsion(I, Propulsion, EffectiveCommandAltitude, EffectiveCommandRoll, EffectiveCommandPitch)

 end

 function UpdatePropulsion(I, Propulsion, CommandAltitude, CommandRoll, CommandPitch)


   --Reset All Propulsion
   NbPropulsion = I:Component_GetCount(9)
   for i=0, NbPropulsion-1 do
     I:Component_SetFloatLogic(9,i,0)

     --Apply AltitudeUp Command
     if CommandAltitude > 0 and Propulsion[i+1].AltitudeUp then
       I:Component_SetFloatLogic(9, i, CommandAltitude)
     end

     --Apply AltitudeDown Command
     if CommandAltitude < 0 and Propulsion[i+1].AltitudeDown then
       I:Component_SetFloatLogic(9, i, -CommandAltitude)
     end

     --Apply PitchUp Command
     if CommandPitch > 0 and Propulsion[i+1].PitchUp then
       I:Component_SetFloatLogic(9, i, I:Component_GetFloatLogic(9, i) + CommandPitch)
     end

     --Apply PitchDown Command
     if CommandPitch < 0 and Propulsion[i+1].PitchDown then
       I:Component_SetFloatLogic(9, i, I:Component_GetFloatLogic(9, i) - CommandPitch)
     end

   end

 end

 function UpdateCommandAltitude(I, DesiredAltitude, CommandAltitude)
   ErrorAltitude = (DesiredAltitude - I:GetConstructCenterOfMass().y) / 500
   if ErrorAltitude < -CorrectionThreshold then CommandAltitude = CommandAltitude-LargeCorrection end
   if ErrorAltitude > -CorrectionThreshold and ErrorAltitude < 0 then CommandAltitude = CommandAltitude-SmallCorrection end
   if ErrorAltitude > CorrectionThreshold then CommandAltitude = CommandAltitude+LargeCorrection end
   if ErrorAltitude < CorrectionThreshold and ErrorAltitude > 0 then CommandAltitude = CommandAltitude+SmallCorrection end
   return math.max(math.min(CommandAltitude, 1), -1)
 end

 function UpdateCommandRoll(I, DesiredRoll, CommandRoll)
   ErrorRoll = GetAngleDelta(DesiredRoll, I:GetConstructRoll()) / 180
   if ErrorRoll < -CorrectionThreshold then CommandRoll = CommandRoll-LargeCorrection end
   if ErrorRoll > -CorrectionThreshold and ErrorRoll < 0 then CommandRoll = CommandRoll-SmallCorrection end
   if ErrorRoll > CorrectionThreshold then CommandRoll = CommandRoll+LargeCorrection end
   if ErrorRoll < CorrectionThreshold and ErrorRoll > 0 then CommandRoll = CommandRoll+SmallCorrection end
   return math.max(math.min(CommandRoll, 1), -1)
 end

 function UpdateCommandPitch(I, DesiredPitch, CommandPitch)
   ErrorPitch = GetAngleDelta(DesiredPitch, I:GetConstructPitch()) / 180
   if math.abs(ErrorPitch) < 0.001 then
     ErrorPitch = 0
     DesiredSpeed = 0
   else
     if ErrorPitch > 0 then DesiredSpeed = 0.1 else DesiredSpeed = -0.1 end
   end
   I:Log(DesiredSpeed .. "    " .. I:GetLocalAngularVelocity().x)
   if I:GetLocalAngularVelocity().x < DesiredSpeed then CommandPitch = CommandPitch + SmallCorrection end
   if I:GetLocalAngularVelocity().x > DesiredSpeed then CommandPitch = CommandPitch - SmallCorrection end
   return math.max(math.min(CommandPitch, 1), -1)
 end

 function UpdatePropulsionArray(I)
   Propulsion = {}
   NbPropulsion = I:Component_GetCount(9)

   for i=0, NbPropulsion-1 do
     Propulsion[i+1] = {}
     binfo = I:Component_GetBlockInfo(9,i)

     --PitchDown
     if (binfo.LocalPositionRelativeToCom .z > 0.5 and binfo.LocalForwards.y > 0.9) or
        (binfo.LocalPositionRelativeToCom.z < -0.5 and binfo.LocalForwards.y < -0.9) then
       Propulsion[i+1].PitchDown = true
     end

     --PitchUp
     if (binfo.LocalPositionRelativeToCom .z > 0.5 and binfo.LocalForwards.y < -0.9) or
        (binfo.LocalPositionRelativeToCom .z < -0.5 and binfo.LocalForwards.y > 0.9) then
       Propulsion[i+1].PitchUp = true
     end
     --AltitudeUp
     if (binfo.LocalForwards.y > 0.9) then
       Propulsion[i+1].AltitudeUp = true
     end
     --AltitudeDown
     if (binfo.LocalForwards.y < -0.9) then
       Propulsion[i+1].AltitudeDown = true
     end
     --RollLeft
     if (binfo.LocalPositionRelativeToCom .x > 0.5 and binfo.LocalForwards.y < -0.9) or
        (binfo.LocalPositionRelativeToCom .x < -0.5 and binfo.LocalForwards.y > 0.9) then
       Propulsion[i+1].RollLeft = true
     end
     --RollRight
     if (binfo.LocalPositionRelativeToCom .x < -0.5 and binfo.LocalForwards.y < -0.9) or
        (binfo.LocalPositionRelativeToCom .x > 0.5 and binfo.LocalForwards.y > 0.9) then
       Propulsion[i+1].RollRight = true
     end
   end

   return Propulsion
 end

 function GetAngleDelta(a, b)
   if a > 180 then a = a - 360 end
   if b > 180 then b = b - 360 end
   return (a - b)
 end
