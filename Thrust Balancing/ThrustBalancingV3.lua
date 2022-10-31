ITERRATE = 40

--Controller Gain

GainAltitude = 10
GainPitch = 1
GainRoll = 0.3
Alpha = 0.05 --Keep average of last seconds (exponatial running avg with time constant = 5 * 1/40)
StabilityThreshold = 0.001
ErrorDeadband = 0.01
GainOffset = 0.01

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
OffsetPitch = 0
OffsetRoll = 0
OffsetAltitude = 0

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
  CommandAltitude = CommandAltitude/2

  I:Log("CommandAltitude: " .. CommandAltitude .. " CommandPitch: " .. CommandPitch .. " CommandRoll: " .. CommandRoll)
  I:Log("OffsetAltitude: " .. OffsetAltitude .. " OffsetPitch: " .. OffsetPitch .. " OffsetRoll: " .. OffsetRoll)

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
  CommandAltitude = math.max(math.min((ErrorAltitude+OffsetAltitude) * GainAltitude, 1), -1)
  I:Log("ErrorAltitude: " .. ErrorAltitude)

  if math.abs(AvgErrorAltitude - ErrorAltitude) < StabilityThreshold then
    if ErrorAltitude > ErrorDeadband then
      OffsetAltitude = OffsetAltitude + GainAltitude * GainOffset
    elseif ErrorAltitude < -ErrorDeadband then
      OffsetAltitude = OffsetAltitude - GainAltitude * GainOffset
    end
  end
end

----------------------
function UpdateCommandRoll(I)
  ErrorRoll = GetAngleDelta(DesiredRoll, I:GetConstructRoll()) / 180
  AvgErrorRoll = Alpha * ErrorRoll + (1-Alpha) * AvgErrorRoll
  CommandRoll = math.max(math.min((ErrorRoll+OffsetRoll) * GainRoll, 1), -1)
  I:Log("ErrorRoll: " .. ErrorRoll)

  if math.abs(AvgErrorRoll - ErrorRoll) < StabilityThreshold then
    if ErrorRoll > ErrorDeadband then
      OffsetRoll = OffsetRoll + GainRoll * GainOffset
    elseif ErrorRoll < -ErrorDeadband then
      OffsetRoll = OffsetRoll - GainRoll * GainOffset
    end
  end
end

----------------------
function UpdateCommandPitch(I)
  ErrorPitch = GetAngleDelta(DesiredPitch, I:GetConstructPitch()) / 180
  AvgErrorPitch = Alpha * ErrorPitch + (1-Alpha) * AvgErrorPitch
  CommandPitch = math.max(math.min((ErrorPitch+OffsetPitch) * GainPitch, 1), -1)
  I:Log("ErrorPitch: " .. ErrorPitch)

  if math.abs(AvgErrorPitch - ErrorPitch) < StabilityThreshold then
    if ErrorPitch > ErrorDeadband then
      OffsetPitch = OffsetPitch + GainPitch * GainOffset
    elseif ErrorPitch < -ErrorDeadband then
      OffsetPitch = OffsetPitch - GainPitch * GainOffset
    end
  end
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