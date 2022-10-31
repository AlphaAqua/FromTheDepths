ITERRATE = 40

--Navigation Parameters
HoldRadius = 1000
CruiseAltitude = 200
CruiseSpeed = 50
AttackRunDistance = 500

UsePitchToControlAltitude = true
AttackType = "AttackRun"  --AttackRun or Kamikazee
KamikazeeDistance = 500

--Controller Gain

GainAltitude = 30
GainPitch = 10
GainRoll = 5
GainYaw = 5
GainSpeed = 1
PredictorLength = 5
TauPitch = 500
TauYaw = 500
TauRoll = 900
TauSpeed = 1000

--Default Standard Position
DesiredPitch = 0
DesiredRoll = 0
DesiredYaw = 0
DesiredAltitude = 0
DesiredSpeed = 0

--Internal label, do not modify
CommandAltitude = 0
CommandRoll = 0
CommandYaw = 0
CommandPitch = 0
CommandYaw = 0
CurrentSpeedAltitude = 0
CurrentSpeedRoll = 0
CurrentSpeedPitch = 0
CurrentSpeedYaw = 0
CurrentSpeed = 0
ErrorSumPitch = 0
ErrorSumYaw = 0
ErrorSumRoll = 0
ErrorSumSpeed = 0
KamikazeeGoAround = true
ModeNormal = true
NavMode = "Hold"
NavModePrev = ""
HoldPosition = {}
EffectiveUsePitchToControlAltitude = false
firstpass = true


----------------------------------
function Update(I)
  if firstpass then
    for i=0, I:Component_GetCount(9)-1 do
      I:Component_SetFloatLogic(9,i,0.1)
    end

    --Propulsion Table
    Propulsion = {}

    HoldPosition = Vector3(I:GetConstructCenterOfMass().x, 0, I:GetConstructCenterOfMass().z)

    EffectiveUsePitchToControlAltitude = UsePitchToControlAltitude
    DesiredSpeed = CruiseSpeed
    DesiredAltitude = CruiseAltitude

    firstpass = falsel
    I:ClearLogs()
    I:Log("Starting...")
  end

  --Request all propulsion to start. Need that all propultion manually set to "Main"
  I:RequestControl(0, 8, 5)
  I:RequestControl(1, 8, 5)
  I:RequestControl(2, 8, 5)

  Propulsion = UpdatePropulsionArray(I)

  UpdateNavigation(I)

  UpdateCommand(I)

  I:Log("CommandAltitude: " .. CommandAltitude .. " CommandPitch: " .. CommandPitch .. " CommandRoll: " .. CommandRoll .. " CommandYaw: " .. CommandYaw .. " CommandSpeed: " .. CommandSpeed)

  UpdatePropulsion(I, Propulsion)

end


--------------------------
function UpdateNavigation(I)
  if I:GetNumberOfMainframes() and I:GetNumberOfMainframes() > 0 and I:GetNumberOfTargets(0) and I:GetNumberOfTargets(0) > 0 then
    NavMode = AttackType
  else
    NavMode = "Hold"
  end

  if not (NavModePrev == NavMode) then
    I:LogToHud(NavMode)
  end
  NavModePrev = NavMode

  if NavMode == "Hold" then UpdateNavigationHoldingPatern(I) end
  if NavMode == "AttackRun" then UpdateNavigationAttackRun(I) end
  if NavMode == "Kamikazee" then UpdateNavigationKamikazee(I) end

  if (
EffectiveUsePitchToControlAltitude == true) then
    DesiredPitch = math.max(math.min(-(DesiredAltitude - I:GetConstructCenterOfMass().y)/10, 10), -10)
  end
end

--------------------------
function UpdateNavigationAttackRun(I)
  CurrentPosition = I:GetConstructCenterOfMass()
  TargetPositionInfo = I:GetTargetPositionInfo(0, 0)

  if math.abs(TargetPositionInfo.Azimuth) > 90 and TargetPositionInfo.GroundDistance < AttackRunDistance then
    --Going away from target until reacing AttackRunDistance
    DesiredYaw = I:GetConstructYaw() - TargetPositionInfo.Azimuth + 180
  else
    --Aiming Target
    DesiredYaw = I:GetConstructYaw() - TargetPositionInfo.Azimuth
  end
  if DesiredYaw > 360 then DesiredYaw = DesiredYaw - 360 end

end

--------------------------
function UpdateNavigationKamikazee(I)
  CurrentPosition = I:GetConstructCenterOfMass()
  TargetPositionInfo = I:GetTargetPositionInfo(0, 0)
  TargetInfo = I:GetTargetInfo(0, 0)

  TimeToTarget = TargetPositionInfo.Range / math.max(0.001, I:GetForwardsVelocityMagnitude())
  EstimatedTargetPositionAtImpact = TargetInfo.AimPointPosition + TargetInfo.Velocity * TimeToTarget
  EstimatedTargetPositionInfo = I:GetTargetPositionInfoForPosition(0, EstimatedTargetPositionAtImpact.x,EstimatedTargetPositionAtImpact.y,EstimatedTargetPositionAtImpact.z)

  if (I:GetConstructCenterOfMass().y < -10) then KamikazeeGoAround = true end

  if Vector3.Magnitude(TargetInfo.Velocity - I:GetVelocityVector()) < 3 and TargetPositionInfo.Range < 100 then
    --Attached
    DesiredRoll = 0
    DesiredAltitude = CruiseAltitude
    DesiredPitch = 75
    EffectiveUsePitchToControlAltitude = false
    KamikazeeGoAround = true
  elseif KamikazeeGoAround == true and TargetPositionInfo.GroundDistance < KamikazeeDistance + 100 then
    DesiredYaw = I:GetConstructYaw() - EstimatedTargetPositionInfo.Azimuth + 180
    EffectiveUsePitchToControlAltitude = UsePitchToControlAltitude
    DesiredPitch = 0
    DesiredRoll = 0
    DesiredAltitude = CruiseAltitude
  elseif TargetPositionInfo.GroundDistance > KamikazeeDistance then
    KamikazeeGoAround = false

  DesiredYaw = I:GetConstructYaw() - EstimatedTargetPositionInfo.Azimuth
    EffectiveUsePitchToControlAltitude = UsePitchToControlAltitude
    DesiredRoll = 0
    DesiredAltitude = CruiseAltitude
    DesiredPitch = 0
  else
    DesiredYaw = I:GetConstructYaw() - EstimatedTargetPositionInfo.Azimuth
    EffectiveUsePitchToControlAltitude = false
    DesiredPitch = I:GetConstructPitch()-EstimatedTargetPositionInfo.Elevation
    DesiredRoll = 0
    DesiredAltitude = I:GetConstructCenterOfMass().y
  end
end

--------------------------
function UpdateNavigationHoldingPatern(I)
    CurrentPosition = I:GetConstructCenterOfMass()
    CurentLandPosition = Vector3(I:GetConstructCenterOfMass().x, 0, I:GetConstructCenterOfMass().z)
    DistanceToHoldPosition = Vector3.Distance(HoldPosition, CurentLandPosition)

    DesiredYawRelativeToTarget = math.max(math.min(DistanceToHoldPosition/HoldRadius*90,180),0)
    AngleWithTarget = 90 - 180/3.1416* math.atan2(CurentLandPosition.z - HoldPosition.z, CurentLandPosition.x - HoldPosition.x)
    DesiredYaw = DesiredYawRelativeToTarget + AngleWithTarget
    if DesiredYaw > 360 then DesiredYaw = DesiredYaw-360 end
    DesiredSpeed = CruiseSpeed
    DesiredAltitude = CruiseAltitude
    EffectiveUsePitchToControlAltitude = UsePitchToControlAltitude
--I:Log(DistanceToHoldPosition .. " :: " .. DesiredYawRelativeToTarget .. " : " .. DesiredYaw .. " : " .. AngleWithTarget)
end
--------------------------
function UpdatePropulsion(I, Propulsion)


  --Reset All Propulsion
  NbPropulsion = I:Component_GetCount(9)

  EffectivePitchCommand = CommandPitch
  EffectiveRollCommand = CommandRoll
  EffectiveYawCommand = CommandYaw

  CrudeAltitudeLimiter = math.abs(CommandPitch) + math.abs(CommandRoll)
  if CommandAltitude < 0 then
    EffectiveAltitudeCommand = math.max(CommandAltitude
, -1+CrudeAltitudeLimiter)

  else
    EffectiveAltitudeCommand = math.min(CommandAltitude
, 1-CrudeAltitudeLimiter)
  end

  for i=0, NbPropulsion-1 do
    --Reset all command
    I:Component_SetFloatLogic(9,i,0)

    if ModeNormal and not Propulsion[i+1].Forward then
      --Apply AltitudeUp Command
      if EffectiveAltitudeCommand > 0 and Propulsion[i+1].AltitudeUp then
        I:Component_SetFloatLogic(9, i, math.max(EffectiveAltitudeCommand, I:Component_GetFloatLogic(9, i)))
      end
      --Apply AltitudeDown Command
      if EffectiveAltitudeCommand < 0 and Propulsion[i+1].AltitudeDown then
        I:Component_SetFloatLogic(9, i, math.max(-EffectiveAltitudeCommand, I:Component_GetFloatLogic(9, i)))
      end

      --Apply PitchUp Command
      if EffectivePitchCommand > 0 and Propulsion[i+1].PitchUp then
        I:Component_SetFloatLogic(9, i, math.max(EffectivePitchCommand, I:Component_GetFloatLogic(9, i)))
      end
      --Apply PitchDown Command
      if EffectivePitchCommand < 0 and Propulsion[i+1].PitchDown then
        I:Component_SetFloatLogic(9, i, math.max(-EffectivePitchCommand, I:Component_GetFloatLogic(9, i)))
      end


      --Apply YawRight Command
      if EffectiveYawCommand > 0 and Propulsion[i+1].YawRight then
        I:Component_SetFloatLogic(9, i, math.max(EffectiveYawCommand, I:Component_GetFloatLogic(9, i)))
      end
      --Apply YawLeft Command
      if EffectiveYawCommand < 0 and Propulsion[i+1].YawLeft then
        I:Component_SetFloatLogic(9, i, math.max(-EffectiveYawCommand, I:Component_GetFloatLogic(9, i)))
      end
    elseif ModeNormal and Propulsion[i+1].Forward then
      --In Normal mode Fwd engine are always used to control speed
        I:Component_SetFloatLogic(9, i, CommandSpeed)
    else
      --Degraded Mode (used when cannot keep full speed forward and keep stability)
    end

    --Roll not affected by Normal/Degraded mode
    --Apply RollLeft Command
    if EffectiveRollCommand > 0 and Propulsion[i+1].RollLeft then
      I:Component_SetFloatLogic(9, i, math.max(EffectiveRollCommand, I:Component_GetFloatLogic(9, i)))
    end
    --Apply RollRight Command
    if EffectiveRollCommand < 0 and Propulsion[i+1].RollRight then
      I:Component_SetFloatLogic(9, i, math.max(-EffectiveRollCommand, I:Component_GetFloatLogic(9, i)))
    end

  end

end

----------------------
function UpdateCommand(I)

  -- Altitude Command --
  CurrentAltitude = I:GetConstructCenterOfMass().y
  LastSpeedAltitude = CurrentSpeedAltitude
  CurrentSpeedAltitude = I:GetVelocityVector().y
  AccelerationAltitude = (LastSpeedAltitude - CurrentSpeedAltitude) / ITERRATE
  PredictedAltitude = CurrentAltitude + CurrentSpeedAltitude * PredictorLength + AccelerationAltitude * PredictorLength * PredictorLength
  ErrorAltitude = (DesiredAltitude - PredictedAltitude) / 500
  CommandAltitude = math.max(math.min(ErrorAltitude * GainAltitude,1),-1)

  -- Roll Command --
  CurrentRoll = I:GetConstructRoll()
  LastSpeedRoll = CurrentSpeedRoll
  CurrentSpeedRoll = I:GetLocalAngularVelocity().z
  AccelerationRoll = (LastSpeedRoll - CurrentSpeedRoll) / ITERRATE
  PredictedRoll = CurrentRoll + CurrentSpeedRoll * PredictorLength + AccelerationRoll * PredictorLength * PredictorLength
  ErrorRoll = GetAngleDelta(DesiredRoll, PredictedRoll) / 180
  if math.abs(ErrorRoll) > 0.1 then ErrorSumRoll = 0 else ErrorSumRoll = ErrorSumRoll + ErrorRoll end
  CommandRoll = math.max(math.min(GainRoll * (ErrorRoll + ErrorSumRoll/TauRoll),1),-1)

  -- Pitch Command --
  CurrentPitch = I:GetConstructPitch()
  LastSpeedPitch = CurrentSpeedPitch
  CurrentSpeedPitch = I:GetLocalAngularVelocity().x
  AccelerationPitch = (LastSpeedPitch - CurrentSpeedPitch) / ITERRATE
  PredictedPitch = CurrentPitch + CurrentSpeedPitch * PredictorLength + AccelerationPitch * PredictorLength * PredictorLength
  ErrorPitch = GetAngleDelta(DesiredPitch, PredictedPitch) / 180
  if math.abs(ErrorPitch) > 0.1 then ErrorSumPitch = 0 else ErrorSumPitch = ErrorSumPitch + ErrorPitch end
  CommandPitch = math.max(math.min(GainPitch * (ErrorPitch + ErrorSumPitch/TauPitch) ,1),-1)

  -- Yaw Command --
  CurrentYaw = I:GetConstructYaw()
  LastSpeedYaw = CurrentSpeedYaw
  CurrentSpeedYaw = I:GetLocalAngularVelocity().y
  AccelerationYaw = (LastSpeedYaw - CurrentSpeedYaw) / ITERRATE
  PredictedYaw = CurrentYaw + CurrentSpeedYaw * PredictorLength + AccelerationYaw * PredictorLength * PredictorLength
  ErrorYaw = GetAngleDelta(DesiredYaw, PredictedYaw) / 180
  if math.abs(ErrorYaw) > 0.1 then ErrorSumYaw = 0 else ErrorSumYaw = ErrorSumYaw + ErrorYaw end
  CommandYaw = math.max(math.min(GainYaw * (ErrorYaw + ErrorSumYaw/TauYaw),1),-1)
--I:Log(ErrorYaw .. " :: " .. CurrentYaw .. " : " .. PredictedYaw)

  -- Forward Command --
  LastSpeed = CurrentSpeed
  CurrentSpeed = I:GetForwardsVelocityMagnitude()
  Acceleration = (LastSpeed - CurrentSpeed) / ITERRATE
  PredictedSpeed =  CurrentSpeed + Acceleration * PredictorLength
  ErrorSpeed = (DesiredSpeed - PredictedSpeed) / 100
  if math.abs(ErrorSpeed) > 0.1 then ErrorSumSpeed = 0 else ErrorSumSpeed = ErrorSumSpeed + ErrorSpeed end
  CommandSpeed = math.max(math.min(GainSpeed * (ErrorSpeed + ErrorSumSpeed/TauSpeed),1),-1)
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
       (binfo.LocalPositionRelativeToCom.z < -0.5 and binfo.LocalForwards.y < -0.9) or
       (binfo.LocalPositionRelativeToCom.y > 0.5 and binfo.LocalForwards.z < -0.9) or
       (binfo.LocalPositionRelativeToCom.y < -0.5 and binfo.LocalForwards.z > 0.9) then
      Propulsion[i+1].PitchDown = true
    end
    --PitchUp
    if (binfo.LocalPositionRelativeToCom.z > 0.5 and binfo.LocalForwards.y < -0.9) or
       (binfo.LocalPositionRelativeToCom.z < -0.5 and binfo.LocalForwards.y > 0.9) or
       (binfo.LocalPositionRelativeToCom.y > 0.5 and binfo.LocalForwards.z > 0.9) or
       (binfo.LocalPositionRelativeToCom.y < -0.5 and binfo.LocalForwards.z < -0.9) then
      Propulsion[i+1].PitchUp = true
    end

    --RollLeft
    if (binfo.LocalPositionRelativeToCom.x > 0.5 and binfo.LocalForwards.y > 0.9) or
       (binfo.LocalPositionRelativeToCom.x < -0.5 and binfo.LocalForwards.y < -0.9) or
       (binfo.LocalPositionRelativeToCom.y > 0.5 and binfo.LocalForwards.x < -0.9) or
       (binfo.LocalPositionRelativeToCom.y < -0.5 and binfo.LocalForwards.x > 0.9) then
      Propulsion[i+1].RollLeft = true
    end
    --RollRight
    if (binfo.LocalPositionRelativeToCom.x > 0.5 and binfo.LocalForwards.y < -0.9) or
       (binfo.LocalPositionRelativeToCom.x < -0.5 and binfo.LocalForwards.y > 0.9) or
       (binfo.LocalPositionRelativeToCom.y > 0.5 and binfo.LocalForwards.x > 0.9) or
       (binfo.LocalPositionRelativeToCom.y < -0.5 and binfo.LocalForwards.x < -0.9) then
      Propulsion[i+1].RollRight = true
    end

    --YawLeft
    if (binfo.LocalPositionRelativeToCom.z > 0.5 and binfo.LocalForwards.x < -0.9) or
       (binfo.LocalPositionRelativeToCom.z < -0.5 and binfo.LocalForwards.x > 0.9) or
       (binfo.LocalPositionRelativeToCom.x > 0.5 and binfo.LocalForwards.z > 0.9) or
       (binfo.LocalPositionRelativeToCom.x < -0.5 and binfo.LocalForwards.z < -0.9) then
      Propulsion[i+1].YawLeft = true
    end
    --YawRight
    if (binfo.LocalPositionRelativeToCom.z > 0.5 and binfo.LocalForwards.x > 0.9) or
       (binfo.LocalPositionRelativeToCom.z < -0.5 and binfo.LocalForwards.x < -0.9) or
       (binfo.LocalPositionRelativeToCom.x > 0.5 and binfo.LocalForwards.z < -0.9) or
       (binfo.LocalPositionRelativeToCom.x < -0.5 and binfo.LocalForwards.z > 0.9) then
      Propulsion[i+1].YawRight = true
    end

    --AltitudeUp
    if (binfo.LocalForwards.y > 0.9) then
      Propulsion[i+1].AltitudeUp = true
    end
    --AltitudeDown
    if (binfo.LocalForwards.y < -0.9) then
      Propulsion[i+1].AltitudeDown = true
    end

    --StrafeLeft
    if (binfo.LocalForwards.x < -0.9) then
      Propulsion[i+1].StrafeLeft = true
    end
    --StrafeRight
    if (binfo.LocalForwards.x > 0.9) then
      Propulsion[i+1].StrafeRight = true
    end

    --Forward
    if (binfo.LocalForwards.z > 0.9) then
      Propulsion[i+1].Forward = true
    end
    --Aftward
    if (binfo.LocalForwards.x < -0.9) then
      Propulsion[i+1].Aftward = true
    end

  end

  return Propulsion
end


-------------------------
-------------------------
function GetAngleDelta(a, b)
  result = a - b
  if result > 180 then result= result - 360 end
  if result < -180 then result = result + 360 end
  return result
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