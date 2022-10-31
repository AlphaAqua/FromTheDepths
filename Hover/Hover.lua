ITERRATE = 40

TurretID = 2
UpID = 1
DownID = 0

--Navigation Parameters
HoldRadius = 5000
CruiseAltitude = 50
CruiseAltitudeDeviationMax = 0
BroadsideRadius = 1000

AttackType = "Hover"  --AttackRun or Broadside or Kamikazee or MineLayer or Coward

--Controller Gain
PredictorLength = 5
GainAltitude = 25
GainPitch = 9
GainRoll = 10
GainYaw = 5
GainDistance = 1
TauAltitude = 5000
TauPitch = 500
TauYaw = 1000
TauRoll = 1
TauDistance = 500
StabilizatorAltitude = 0.1
StabilizatorPitch = 1
StabilizatorRoll = .1
StabilizatorYaw = 1
StabilizatorDistance = 0.1

--Default Standard Position
DesiredPitch = 0
DesiredRoll = 0
DesiredYaw = 0
DesiredAltitude = 0

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
CurrentDistance = 0
ErrorPreviousAltitude = 0
ErrorPreviousPitch = 0
ErrorPreviousRoll = 0
ErrorPreviousYaw = 0
ErrorPreviousDistance = 0
ErrorSumAltitude = 0
ErrorSumPitch = 0
ErrorSumYaw = 0
ErrorSumRoll = 0
ErrorSumYaw = 0
ErrorSumDistance = 0
NavMode = "Hold"
NavModePrev = ""
firstpass = true


----------------------------------
function Update(I)
  if firstpass then
    math.randomseed(I:GetTime() * 1000)
    for i=0, I:Component_GetCount(9)-1 do
      I:Component_SetFloatLogic(9,i,0.1)
    end

I:Log("toto")
    for i=0, I:GetSpinnerCount()-1 do
      if I:IsSpinnerDedicatedHelispinner(i) == false then
        I:Log("TurretID: " .. i)
      else
        I:Log("otherID: " .. i)
      end
    end

    --Propulsion Table
    Propulsion = {}

    EffectiveUsePitchToControlAltitude = UsePitchToControlAltitude
    CruiseAltitude = math.random(CruiseAltitude - CruiseAltitudeDeviationMax, CruiseAltitude + CruiseAltitudeDeviationMax)
    DesiredAltitude = CruiseAltitude

    firstpass = false
    I:ClearLogs()
    I:Log("Starting...")
  end

  I:SetSpinnerContinuousSpeed(TurretID, 0)
  I:SetSpinnerContinuousSpeed(UpID, 30)
  I:SetSpinnerContinuousSpeed(DownID, -30)

  --Request all propulsion to start. Need that all propultion manually set to "Main"
  I:RequestControl(0, 8, 5)
  I:RequestControl(1, 8, 5)
  I:RequestControl(2, 8, 5)

  Propulsion = UpdatePropulsionArray(I)

  UpdateNavigation(I)

  UpdateCommand(I)

--  I:Log("CommandAltitude: " .. CommandAltitude .. " CommandPitch: " .. CommandPitch .. " CommandRoll: " .. CommandRoll .. " CommandYaw: " .. CommandYaw .. " CommandDistance: " .. CommandDistance)

  UpdatePropulsion(I, Propulsion)

end

--------------------------
function UpdateNavigationHover(I)
  CurrentPosition = I:GetConstructCenterOfMass()
  TargetPositionInfo = I:GetTargetPositionInfo(0, 0)

I:Log(TargetPositionInfo.GroundDistance)

  DesiredYaw = I:GetConstructYaw() - TargetPositionInfo.Azimuth
  if DesiredYaw > 360 then DesiredYaw = DesiredYaw - 360 end

  if TargetPositionInfo.GroundDistance > 50 then
    DesiredSpeed = CruiseSpeed
  else
    DesiredSpeed = CruiseSpeed/100

    for i=0, I:GetWeaponCount()-1 do
      WeaponPosition = I:GetWeaponInfo(i).CurrentDirection
      I:AimWeaponInDirection(i, WeaponPosition.x,WeaponPosition.y,WeaponPosition.z, 0)
      I:FireWeapon(i, 0)
    end
  end
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
 
    if NavMode == "Hold" then
      HoldPosition = Vector3(I:GetConstructCenterOfMass().x, 0, I:GetConstructCenterOfMass().z)
      for i = 0, I:Component_GetCount(7)-1 do
        I:Component_SetBoolLogic(7,i, true)
      end

    end
  end
  NavModePrev = NavMode

  if NavMode == "Hold"      then UpdateNavigationHoldingPatern(I) end
  if NavMode == "Broadside" then UpdateNavigationBroadside(I) end
  if NavMode == "Hover" then UpdateNavigationBroadside(I) end
end

--------------------------
function UpdateNavigationBroadside(I)
    DesiredDistance = BroadsideRadius

    DesiredYaw = I:GetConstructYaw() + I:GetTargetPositionInfo(0, 0).Azimuth
    if DesiredYaw > 360 then DesiredYaw = DesiredYaw-360 end
    DesiredAltitude = CruiseAltitude
end

--------------------------
function UpdateNavigationHoldingPatern(I)
    DesiredPitch = 0
    DesiredRoll = 0
    DesiredYaw = 0
    DesiredAltitude = CruiseAltitude
    DesiredDistance = 0
end

--------------------------
function UpdatePropulsion(I, Propulsion)

  I:SetSpinnerRotationAngle(TurretID, 90-CommandAltitude*90)

  NbPropulsion = I:Component_GetCount(9)

  EffectivePitchCommand = CommandPitch
  EffectiveRollCommand = CommandRoll
  EffectiveYawCommand = CommandYaw

  for i=0, NbPropulsion-1 do
    --Reset all command
    I:Component_SetFloatLogic(9,i,0)

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

    --Apply RollLeft Command
    if EffectiveRollCommand > 0 and Propulsion[i+1].RollLeft then
      I:Component_SetFloatLogic(9, i, math.max(EffectiveRollCommand, I:Component_GetFloatLogic(9, i)))
    end
    --Apply RollRight Command
    if EffectiveRollCommand < 0 and Propulsion[i+1].RollRight then
      I:Component_SetFloatLogic(9, i, math.max(-EffectiveRollCommand, I:Component_GetFloatLogic(9, i)))
    end

    --Apply Distance Command
    if CommandDistance < 0 and Propulsion[i+1].Forward then
      I:Component_SetFloatLogic(9, i, CommandDistance)
    elseif CommandDistance > 0 and Propulsion[i+1].Backward then
      I:Component_SetFloatLogic(9, i, -CommandDistance)
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
  if math.abs(ErrorAltitude) < 0.1 then
    ErrorSumAltitude = ErrorSumAltitude + ErrorAltitude / ITERRATE
  else
    ErrorSumAltitude = 0
  end

  CommandAltitude = math.max(math.min(PID(ErrorAltitude,ErrorPreviousAltitude,ErrorSumAltitude,GainAltitude,GainAltitude/TauAltitude,GainAltitude*StabilizatorAltitude),1),-1)
  ErrorPreviousAltitude = ErrorAltitude

  -- Roll Command --
  CurrentRoll = I:GetConstructRoll()
  LastSpeedRoll = CurrentSpeedRoll
  CurrentSpeedRoll = I:GetLocalAngularVelocity().z
  AccelerationRoll = (LastSpeedRoll - CurrentSpeedRoll) / ITERRATE
  PredictedRoll = CurrentRoll + CurrentSpeedRoll * PredictorLength + AccelerationRoll * PredictorLength * PredictorLength
  ErrorRoll = GetAngleDelta(DesiredRoll, PredictedRoll) / 180
  if math.abs(ErrorRoll) < 0.5 then
    ErrorSumRoll = ErrorSumRoll + ErrorRoll / ITERRATE
  else
    ErrorSumRoll = 0
  end
  CommandRoll = math.max(math.min(PID(ErrorRoll,ErrorPreviousRoll,ErrorSumRoll,GainRoll,GainRoll/TauRoll,GainRoll*StabilizatorRoll),1),-1)
  ErrorPreviousRoll = ErrorRoll

  -- Pitch Command --
  CurrentPitch = I:GetConstructPitch()
  LastSpeedPitch = CurrentSpeedPitch
  CurrentSpeedPitch = I:GetLocalAngularVelocity().x
  AccelerationPitch = (LastSpeedPitch - CurrentSpeedPitch) / ITERRATE
  PredictedPitch = CurrentPitch + CurrentSpeedPitch * PredictorLength + AccelerationPitch * PredictorLength * PredictorLength
  ErrorPitch = GetAngleDelta(DesiredPitch, PredictedPitch) / 180
  if math.abs(ErrorPitch) < 0.1 then
    ErrorSumPitch = ErrorSumPitch + ErrorPitch / ITERRATE
  else
    ErrorSumPitch = 0
  end

  CommandPitch = math.max(math.min(PID(ErrorPitch,ErrorPreviousPitch,ErrorSumPitch,GainPitch,GainPitch/TauPitch,GainPitch*StabilizatorPitch),1),-1)
  ErrorPreviousPitch = ErrorPitch

  -- Yaw Command --
  CurrentYaw = I:GetConstructYaw()
  LastSpeedYaw = CurrentSpeedYaw
  CurrentSpeedYaw = I:GetLocalAngularVelocity().y
  AccelerationYaw = (LastSpeedYaw - CurrentSpeedYaw) / ITERRATE
  PredictedYaw = CurrentYaw + CurrentSpeedYaw * PredictorLength + AccelerationYaw * PredictorLength * PredictorLength
  ErrorYaw = GetAngleDelta(DesiredYaw, PredictedYaw) / 180
  if math.abs(ErrorYaw) < 0.1 then
    ErrorSumYaw = ErrorSumYaw + ErrorYaw / ITERRATE
  else
    ErrorSumYaw = 0
  end

  CommandYaw = math.max(math.min(PID(ErrorYaw,ErrorPreviousYaw,ErrorSumYaw,GainYaw,GainYaw/TauYaw,GainYaw*StabilizatorYaw),1),-1)
  ErrorPreviousYaw = ErrorYaw

  -- Distance Command --
  LastDistance = CurrentDistance
  if I:GetNumberOfMainframes() > 0 and I:GetNumberOfTargets(0) > 0 then
    CurrentDistance = I:GetTargetPositionInfo(0, 0).GroundDistance
  else
    CurrentDistance = 0
  end
  SpeedDistance = (LastDistance - CurrentDistance) / ITERRATE
  PredictedDistance =  CurrentDistance + SpeedDistance*  PredictorLength
  ErrorDistance = (DesiredDistance - PredictedDistance) / BroadsideRadius
  if math.abs(ErrorDistance) < 0.1 then
    ErrorSumDistance = ErrorSumDistance + ErrorDistance / ITERRATE
  else
    ErrorSumDistance = 0
  end

  CommandDistance = math.max(math.min(PID(ErrorDistance,ErrorPreviousDistance,ErrorSumDistance,GainDistance,GainDistance/TauDistance,GainDistance*StabilizatorDistance),1),-1)
  ErrorPreviousDistance = ErrorDistance

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
    if (binfo.LocalForwards.z < -0.9) then
      Propulsion[i+1].Backward = true
    end

  end

  return Propulsion
end

-------------------------
function PID(error, errorPrevious, errorSum, kP, kI, kD)
  errorDerivate = (error - errorPrevious) * ITERRATE
  output = kP * error
         + kI * errorSum
         + kD * errorDerivate
  return output
end

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