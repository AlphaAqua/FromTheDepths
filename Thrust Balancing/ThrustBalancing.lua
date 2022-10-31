ITERRATE = 40
DEBUG = true

--Controller Gain
GpUp = 10
GpRoll = 0.2
GpPitch = 0.3
GiUp = 0.1
GiRoll = 0.1
GiPitch = 0.1
GdUp = 10
GdRoll = 10
GdPitch = 10


MaxIntegrator = 10

--Default Standard Position
DesiredPitch = 0
DesiredRoll = 0
DesiredAltitude = 100

--Array initialisation
ArrayPitchUp = {}
ArrayPitchDown = {}

ArrayUp = {}
ArrayDown = {}
ArrayRollRight = {}
ArrayRollLeft = {}
ArrayForward = {}
ArrayBackward = {}
ArrayYawRight = {}
ArrayYawLeft = {}

RollCommand = 0
PitchCommand = 0
UpCommand = 0
ErrorSumAltitude = 0
ErrorSumPitch = 0
ErrorSumRoll = 0
ErrorLastAltitude = 0
ErrorLastPitch = 0
ErrorLastRoll = 0


firstpass = true

function Update(I)
  if firstpass then
    for i=0, I:Component_GetCount(9)-1 do
      I:Component_SetFloatLogic(9,i,0.1)
    end

    firstpass = false
    I:ClearLogs()
    I:Log("Starting...")
  end

  --Request all propulsion to start. Need that all propultion manually set to "Main"
  I:RequestControl(0, 8, 5)
  I:RequestControl(1, 8, 5)
  I:RequestControl(2, 8, 5)

  UpdateArrays(I)

  if DEBUG then I:Log("PitchUp: " .. table.getn(ArrayPitchUp) .. " PitchDown: " .. table.getn(ArrayPitchDown) .. " Up: " .. table.getn(ArrayUp) .. " Down: " .. table.getn(ArrayDown) .. " RollRight: " .. table.getn(ArrayRollRight) .. " RollLeft: " .. table.getn(ArrayRollLeft) .. " Forward: " .. table.getn(ArrayForward) .. " Backward: " .. table.getn(ArrayBackward) .. " YawRight: " .. table.getn(ArrayYawRight) .. " YawLeft: " .. table.getn(ArrayYawLeft)) end

  UpdateCommand(I)
  if DEBUG then I:Log("CommandUp: " .. CommandUp .. " CommandRoll: " .. CommandRoll .. " CommandPitch: " .. CommandPitch) end

  UpdatePropulsion(I)

end

function UpdatePropulsion(I)
  CommandSum = math.max(math.abs(CommandUp) + math.abs(CommandRoll) + math.abs(CommandPitch), 1)
  EffectiveCommandUp = CommandUp / CommandSum
  EffectiveCommandRoll = CommandRoll / CommandSum
  EffectiveCommandPitch = CommandPitch / CommandSum

  --Reset All Propulsion
  NbPropulsion = I:Component_GetCount(9)
  for i=0, NbPropulsion-1 do
    I:Component_SetFloatLogic(9,i,0)
  end

  --Apply Up Command
  if EffectiveCommandUp > 0 then
    for i=1, #ArrayUp do
      I:Component_SetFloatLogic(9, ArrayUp[i], I:Component_GetFloatLogic(9, ArrayUp[i]) + EffectiveCommandUp)
    end
  end
  --Apply Down Command
  if EffectiveCommandUp < 0 then
    for i=1, #ArrayDown do
      I:Component_SetFloatLogic(9, ArrayDown[i], I:Component_GetFloatLogic(9, ArrayDown[i]) - EffectiveCommandUp)
    end
  end
  --Apply Pitch Up Command
  if EffectiveCommandPitch > 0 then
    for i=1, #ArrayPitchUp do
      I:Component_SetFloatLogic(9, ArrayPitchUp[i], I:Component_GetFloatLogic(9, ArrayPitchUp[i]) + EffectiveCommandPitch)
    end
  end
  --Apply Pitch Down Command
  if EffectiveCommandPitch < 0 then
    for i=1, #ArrayPitchDown do
      I:Component_SetFloatLogic(9, ArrayPitchDown[i], I:Component_GetFloatLogic(9, ArrayPitchDown[i]) - EffectiveCommandPitch)
    end
  end
  --Apply Roll Right Command
  if EffectiveCommandRoll > 0 then
    for i=1, #ArrayRollRight do
      I:Component_SetFloatLogic(9, ArrayRollRight[i], I:Component_GetFloatLogic(9, ArrayRollRight[i]) + EffectiveCommandRoll)
    end
  end
  --Apply RollLeft Command
  if EffectiveCommandRoll < 0 then
    for i=1, #ArrayRollLeft do
      I:Component_SetFloatLogic(9, ArrayRollLeft[i], I:Component_GetFloatLogic(9, ArrayRollLeft[i]) - EffectiveCommandRoll)
    end
  end
end

function UpdateCommand(I)
  ErrorAltitude = (DesiredAltitude - I:GetConstructCenterOfMass().y) / 1000
  ErrorSumAltitude = math.min(ErrorSumAltitude + ErrorAltitude/ITERRATE, MaxIntegrator)
  CommandUp = math.min(math.max(GpUp * ErrorAltitude + GiUp * ErrorSumAltitude + GdUp*(ErrorAltitude-ErrorLastAltitude), -1), 1)
  ErrorLastAltitude = ErrorAltitude

  ErrorRoll = GetAngleDelta(DesiredRoll, I:GetConstructRoll()) / 180
  ErrorSumRoll = math.min(ErrorSumRoll + ErrorRoll/ITERRATE, MaxIntegrator)
  CommandRoll = -math.min(math.max(GpRoll * ErrorRoll + GiRoll * ErrorSumRoll + GdRoll*(ErrorRoll-ErrorLastRoll), -1), 1)
  ErrorLastRoll = ErrorRoll

  ErrorPitch = GetAngleDelta(DesiredPitch, I:GetConstructPitch()) / 180
  ErrorSumPitch = math.min(ErrorSumPitch + ErrorPitch/ITERRATE, MaxIntegrator)
  CommandPitch = -math.min(math.max(GpPitch * ErrorPitch + GiPitch * ErrorSumPitch + GdPitch*(ErrorPitch-ErrorLastPitch), -1), 1)
  ErrorLastPitch = ErrorPitch
end

function UpdateArrays(I)
  ArrayPitchUp = {}
  ArrayPitchDown = {}

  ArrayUp = {}
  ArrayDown = {}
  ArrayRollRight = {}
  ArrayRollLeft = {}
  ArrayForward = {}
  ArrayBackward = {}
  ArrayYawRight = {}
  ArrayYawLeft = {}

  NbPropulsion = I:Component_GetCount(9)

  for i=0, NbPropulsion-1 do
    binfo = I:Component_GetBlockInfo(9,i)

    --PitchUp
    if (binfo.LocalPositionRelativeToCom.z > 0.5 and binfo.LocalForwards.y > 0.9) or
       (binfo.LocalPositionRelativeToCom.z < -0.5 and binfo.LocalForwards.y < -0.9) then
      ArrayPitchUp[#ArrayPitchUp+1] = i

    end
    --PitchDown
    if (binfo.LocalPositionRelativeToCom.z > 0.5 and binfo.LocalForwards.y < -0.9) or
       (binfo.LocalPositionRelativeToCom.z < -0.5 and binfo.LocalForwards.y > 0.9) then
      ArrayPitchDown[#ArrayPitchDown+1] = i
    end
    --Up
    if (binfo.LocalForwards.y > 0.9) then
      ArrayUp[#ArrayUp+1] = i
    end
    --Down
    if (binfo.LocalForwards.y < -0.9) then
      ArrayDown[#ArrayDown+1] = i
    end
    --RollRight
    if (binfo.LocalPositionRelativeToCom.x > 0.5 and binfo.LocalForwards.y < -0.9) or
       (binfo.LocalPositionRelativeToCom.x < -0.5 and binfo.LocalForwards.y > 0.9) then
      ArrayRollRight[#ArrayRollRight+1] = i
    end
    --RollLeft
    if (binfo.LocalPositionRelativeToCom.x < -0.5 and binfo.LocalForwards.y < -0.9) or
       (binfo.LocalPositionRelativeToCom.x > 0.5 and binfo.LocalForwards.y > 0.9) then
      ArrayRollLeft[#ArrayRollLeft+1] = i
    end
  end
end

function GetAngleDelta(a, b)
  if a > 180 then a = a - 360 end
  if b > 180 then b = b - 360 end
  return (a - b)
end
