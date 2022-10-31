
 ITERRATE = 40

 --Controller Gain

 StdDev = 0.1
 GainAltitude = 1
 GainPitch = 1
 GainRoll = 1
 LagGain = 1

 --Default Standard Position
 DesiredPitch = 0
 DesiredRoll = 0
 DesiredAltitude = 200

 firstpass = true


 function Update(I)
   if firstpass then
     for i=0, I:Component_GetCount(9)
 -1 do
       I:Component_SetFloatLogic(9,i,0.1)
     end

     CommandAltitude = 0
     CommandRoll = 0
     CommandPitch = 0

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

   CommandAltitude = UpdateCommandAltitude(I, DesiredAltitude)
   CommandPitch = UpdateCommandPitch(I, DesiredPitch)
   CommandRoll = UpdateCommandRoll(I, DesiredRoll)

   I:Log("CommandAltitude: " .. CommandAltitude .. " CommandPitch: " .. CommandPitch .. " CommandRoll: " .. CommandRoll)

   UpdatePropulsion(I, Propulsion, CommandAltitude, CommandRoll, CommandPitch)

 end


 function UpdatePropulsion(I, Propulsion, CommandAltitude, CommandRoll, CommandPitch)


   --Reset All Propulsion
   NbPropulsion = I:Component_GetCount(9)
   for i=0, NbPropulsion-1 do
     --Reset all command
     LastCommand = I:Component_GetFloatLogic(9,i)
     I:Component_SetFloatLogic(9,i,0)

     LocalAltitudeCommand = StdDev * internal_rand_normal()
 + CommandAltitude
     --Apply AltitudeUp Command
     if LocalAltitudeCommand > 0 and Propulsion[i+1].AltitudeUp then
       I:Component_SetFloatLogic(9, i, math.max(LocalAltitudeCommand, I:Component_GetFloatLogic(9, i)))
     end
     --Apply AltitudeDown Command
     if LocalAltitudeCommand < 0 and Propulsion[i+1].AltitudeDown then
       I:Component_SetFloatLogic(9, i, math.max(-LocalAltitudeCommand, I:Component_GetFloatLogic(9, i)))
     end

     LocalPitchCommand = StdDev * internal_rand_normal()
 + CommandPitch
     --Apply PitchUp Command
     if LocalPitchCommand > 0 and Propulsion[i+1].PitchUp then
       I:Component_SetFloatLogic(9, i, math.max(LocalPitchCommand, I:Component_GetFloatLogic(9, i)))
     end
     --Apply PitchDown Command
     if LocalPitchCommand < 0 and Propulsion[i+1].PitchDown then
       I:Component_SetFloatLogic(9, i, math.max(-LocalPitchCommand, I:Component_GetFloatLogic(9, i)))
     end

     LocalRollCommand = StdDev * internal_rand_normal()
 + CommandRoll
     --Apply RollRight Command
     if LocalRollCommand > 0 and Propulsion[i+1].RollRight then
       I:Component_SetFloatLogic(9, i, math.max(LocalRollCommand, I:Component_GetFloatLogic(9, i)))
     end
     --Apply RollLeft Command
     if LocalRollCommand < 0 and Propulsion[i+1].RollLeft then
       I:Component_SetFloatLogic(9, i, math.max(-LocalRollCommand, I:Component_GetFloatLogic(9, i)))
     end

     I:Component_SetFloatLogic(9, i, LastCommand + LagGain * (I:Component_GetFloatLogic(9, i) - LastCommand))
   end

 end

 function UpdateCommandAltitude(I, DesiredAltitude)
   ErrorAltitude = (DesiredAltitude - I:GetConstructCenterOfMass().y) / 500
   return math.max(math.min(ErrorAltitude * GainAltitude, 1), -1)
 end

 function UpdateCommandRoll(I, DesiredRoll)
   ErrorRoll = GetAngleDelta(DesiredRoll, I:GetConstructRoll()) / 180
   return math.max(math.min(ErrorRoll * GainRoll, 1), -1)
 end

 function UpdateCommandPitch(I, DesiredPitch, CommandPitch)
   ErrorPitch = GetAngleDelta(DesiredPitch, I:GetConstructPitch()) / 180
   return math.max(math.min(ErrorPitch * GainPitch, 1), -1)
 end

 function UpdatePropulsionArray(I)
   Propulsion = {}
   NbPropulsion = I:Component_GetCount(9)

   for i=0, NbPropulsion-1 do
     Propulsion[i+1] = {}
     binfo = I:Component_GetBlockInfo(9,i)

     --PitchDown
     if (binfo.LocalPositionRelativeToCom
 .z > 0.5 and binfo.LocalForwards.y > 0.9) or
        (binfo.LocalPositionRelativeToCom.z < -0.5 and binfo.LocalForwards.y < -0.9) then
       Propulsion[i+1].PitchDown = true
     end

     --PitchUp
     if (binfo.LocalPositionRelativeToCom
 .z > 0.5 and binfo.LocalForwards.y < -0.9) or
        (binfo.LocalPositionRelativeToCom
 .z < -0.5 and binfo.LocalForwards.y > 0.9) then
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
     if (binfo.LocalPositionRelativeToCom
 .x > 0.5 and binfo.LocalForwards.y < -0.9) or
        (binfo.LocalPositionRelativeToCom
 .x < -0.5 and binfo.LocalForwards.y > 0.9) then
       Propulsion[i+1].RollLeft = true
     end
     --RollRight
     if (binfo.LocalPositionRelativeToCom
 .x < -0.5 and binfo.LocalForwards.y < -0.9) or
        (binfo.LocalPositionRelativeToCom
 .x > 0.5 and binfo.LocalForwards.y > 0.9) then
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

 function internal_rand_normal()
   local x1, x2, w, y1, y2
   repeat
      x1 = 2 * math.random() - 1
      x2 = 2 * math.random() - 1
      w = x1*x1+x2*x2
   until (w < 1)

   w = math.sqrt((-2*math.log(w))/w)
   y1 = x1*w
   y2 = x2*w
   return y1,y2
 end