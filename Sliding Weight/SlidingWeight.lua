ITERRATE = 40

--Controller Gain

GainAltitude = 0.1
GainPitch = 0.1
GainRoll = 0.1
Alpha = 0.025
StabilityThreshold = 0.02
ErrorThreshold = 0.01

--Default Standard Position
DesiredPitch = 0
DesiredRoll = 0
DesiredAltitude = 200

--Internal label, do not modify
AvgErrorAltitude = 0
AvgErrorRoll = 0
AvgErrorPitch = 0
CommandAltitude = 0
CommandRoll = 0
CommandPitch = 0
WeightPitch = 1
WeightRoll = 1
WeightAltitude = 1
LastAltitudeCommand = 0
LastRollCommand = 0
LastPitchCommand = 0

firstpass = true


----------------------------------
function Update(I)
  if firstpass then
    for i=0, I:Component_GetCount(9)-1 do
      I:Component_SetFloatLogic(9,i,0.1)
    end

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

  UpdateCommandAltitude(I)
  UpdateCommandPitch(I)
  UpdateCommandRoll(I)
  CommandAltitude = CommandAltitude/1.5

  I:Log("CommandAltitude: " .. CommandAltitude .. " CommandPitch: " .. CommandPitch .. " CommandRoll: " .. CommandRoll)
  I:Log("WeightAltitude: " .. WeightAltitude .. " WeightPitch: " .. WeightPitch .. " WeightRoll: " .. WeightRoll)

  UpdatePropulsion(I, Propulsion, CommandAltitude, CommandRoll, CommandPitch)

end


--------------------------
function UpdatePropulsion(I, Propulsion, CommandAltitude, CommandRoll, CommandPitch)


  --Reset All Propulsion
  NbPropulsion = I:Component_GetCount(9)
  for i=0, NbPropulsion-1 do
    --Reset all command
    I:Component_SetFloatLogic(9,i,0)

    LocalAltitudeCommand = CommandAltitude
    --Apply AltitudeUp Command
    if LocalAltitudeCommand > 0 and Propulsion[i+1].AltitudeUp then
      I:Component_SetFloatLogic(9, i, math.max(LocalAltitudeCommand, I:Component_GetFloatLogic(9, i)))
    end
    --Apply AltitudeDown Command
    if LocalAltitudeCommand < 0 and Propulsion[i+1].AltitudeDown then
      I:Component_SetFloatLogic(9, i, math.max(-LocalAltitudeCommand, I:Component_GetFloatLogic(9, i)))
    end

    LocalPitchCommand = CommandPitch
    --Apply PitchUp Command
    if LocalPitchCommand > 0 and Propulsion[i+1].PitchUp then
      I:Component_SetFloatLogic(9, i, math.max(LocalPitchCommand, I:Component_GetFloatLogic(9, i)))
    end
    --Apply PitchDown Command
    if LocalPitchCommand < 0 and Propulsion[i+1].PitchDown then
      I:Component_SetFloatLogic(9, i, math.max(-LocalPitchCommand, I:Component_GetFloatLogic(9, i)))
    end

    LocalRollCommand = CommandRoll
    --Apply RollRight Command
    if LocalRollCommand > 0 and Propulsion[i+1].RollRight then
      I:Component_SetFloatLogic(9, i, math.max(LocalRollCommand, I:Component_GetFloatLogic(9, i)))
    end
    --Apply RollLeft Command
    if LocalRollCommand < 0 and Propulsion[i+1].RollLeft then
      I:Component_SetFloatLogic(9, i, math.max(-LocalRollCommand, I:Component_GetFloatLogic(9, i)))
    end

  end

end

----------------------
function UpdateCommandAltitude(I)
  ErrorAltitude = (DesiredAltitude - I:GetConstructCenterOfMass().y) / 500
  AvgErrorAltitude = Alpha * ErrorAltitude + (1-Alpha) * AvgErrorAltitude

  if ErrorAltitude > ErrorThreshold then
    CommandAltitude = WeightAltitude
  elseif ErrorAltitude < -ErrorThreshold then
    CommandAltitude = -WeightAltitude
  end

  if math.abs(AvgErrorAltitude) < StabilityThreshold then
   --Stable error, lower weight
   WeightAltitude = math.max(WeightAltitude - GainAltitude / ITERRATE, 0.000001)
  else
   --Unstable error, increase weight
   WeightAltitude = math.min(WeightAltitude + GainAltitude / ITERRATE, 1)
  end

  LastAltitudeCommand = CommandAltitude
end

----------------------
function UpdateCommandRoll(I)
  ErrorRoll = GetAngleDelta(DesiredRoll, I:GetConstructRoll()) / 180
  AvgErrorRoll = Alpha * ErrorRoll + (1-Alpha) * AvgErrorRoll
I:Log(AvgErrorRoll)
  if ErrorRoll > ErrorThreshold then
    CommandRoll = WeightRoll
  elseif ErrorRoll < -ErrorThreshold then
    CommandRoll = -WeightRoll
  end

  if math.abs(AvgErrorRoll) < StabilityThreshold then
   --Stable error, lower weight
   WeightRoll = math.max(WeightRoll - GainRoll / ITERRATE, 0.000001)
  else
   --Unstable error, increase weight
   WeightRoll = math.min(WeightRoll + GainRoll / ITERRATE, 1)
  end

  LastRollCommand = CommandRoll
end

----------------------
function UpdateCommandPitch(I)
  ErrorPitch = GetAngleDelta(DesiredPitch, I:GetConstructPitch()) / 180
  AvgErrorPitch = Alpha * ErrorPitch + (1-Alpha) * AvgErrorPitch

  if ErrorPitch > ErrorThreshold then
    CommandPitch = WeightPitch
  elseif ErrorPitch < -ErrorThreshold then
    CommandPitch = -WeightPitch
  end

  if math.abs(AvgErrorPitch) < StabilityThreshold then
   --Stable error, lower weight
   WeightPitch = math.max(WeightPitch - GainPitch / ITERRATE, 0.000001)
  else
   --Unstable error, increase weight
   WeightPitch = math.min(WeightPitch + GainPitch / ITERRATE, 1)
  end

  LastPitchCommand = CommandPitch
end

----------------------
function UpdatePropulsionArray(I)
  Propulsion = {}
  NbPropulsion = I:Component_GetCount(9)

  for i=0, NbPropulsion-1 do
    Propulsion[i+1] = {}
    binfo = I:Component_GetBlockInfo(9,i)

    --PitchDown
    if (binfo.LocalPositionRelativeToCom.z > 0.5 and binfo.LocalForwards.y > 0.9) or
       (binfo.LocalPositionRelativeToCom.z < -0.5 and binfo.LocalForwards.y < -0.9) then
      Propulsion[i+1].PitchDown = true
    end

    --PitchUp
    if (binfo.LocalPositionRelativeToCom.z > 0.5 and binfo.LocalForwards.y < -0.9) or
       (binfo.LocalPositionRelativeToCom.z < -0.5 and binfo.LocalForwards.y > 0.9) then
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
    if (binfo.LocalPositionRelativeToCom.x > 0.5 and binfo.LocalForwards.y < -0.9) or
       (binfo.LocalPositionRelativeToCom.x < -0.5 and binfo.LocalForwards.y > 0.9) then
      Propulsion[i+1].RollLeft = true
    end
    --RollRight
    if (binfo.LocalPositionRelativeToCom.x < -0.5 and binfo.LocalForwards.y < -0.9) or
       (binfo.LocalPositionRelativeToCom.x > 0.5 and binfo.LocalForwards.y > 0.9) then
      Propulsion[i+1].RollRight = true
    end
  end

  return Propulsion
end


-------------------------
-------------------------
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