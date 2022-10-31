ITERRATE = 40

--Preference
DesiredAltitude = 200
HoldRadius = 300

--Tuning
Predictor = 5
PitchGain = 0.1
PitchDerivate = 10
PitchIntegrator = 0.0005
YawGain = 0.1
YawDerivate = 5
YawIntegrator = 0.001
PitchDamper = 0.95

--Internal Variable
DesiredPitch = 0
DesiredYaw = 0
PitchErrorSum = 0
YawErrorSum = 0
PitchErrorPrevious = 0
YawErrorPrevious = 0
firstpass = true

function Update(I)
  if firstpass then
    I:RequestControl(2, 8, 5)
    HoldPosition = Vector3(I:GetConstructCenterOfMass().x, 0, I:GetConstructCenterOfMass().z)
  end

  DesiredPitch = PitchDamper*DesiredPitch - (1-PitchDamper)*math.max(math.min(DesiredAltitude - I:GetConstructCenterOfMass().y,25),-25)
  PredictedPitch = I:GetConstructPitch() + I:GetAngularVelocity().x * Predictor
  PitchError = GetAngleDelta(DesiredPitch, PredictedPitch)
  PitchErrorSum  = PitchErrorSum + PitchError
  PitchRotation = -math.max(math.min(PID(PitchError, PitchErrorPrevious, PitchErrorSum, PitchGain, PitchIntegrator, PitchDerivate),90),-90)

  PitchErrorPrevious = PitchError

  CurrentPosition = I:GetConstructCenterOfMass()
  CurentLandPosition = Vector3(I:GetConstructCenterOfMass().x, 0, I:GetConstructCenterOfMass().z)
  DistanceToHoldPosition = Vector3.Distance(HoldPosition, CurentLandPosition)

  DesiredYawRelativeToTarget = math.max(math.min(DistanceToHoldPosition/HoldRadius*90,180),0)
  AngleWithTarget = 90 - 180/3.1416* math.atan2(CurentLandPosition.z - HoldPosition.z, CurentLandPosition.x - HoldPosition.x)
  DesiredYaw = DesiredYawRelativeToTarget + AngleWithTarget
  if DesiredYaw > 360 then DesiredYaw = DesiredYaw-360 end
  PredictedYaw = I:GetConstructYaw() + I:GetAngularVelocity().y * Predictor
  YawError = GetAngleDelta(DesiredYaw, PredictedYaw)
  YawErrorSum  = YawErrorSum + YawError
  YawRotation = -math.max(math.min(PID(YawError, YawErrorPrevious, YawErrorSum, YawGain, YawIntegrator, YawDerivate),20),-20)

  YawErrorPrevious = YawError

  ThrustDirection = Quaternion.AngleAxis(90, I:GetConstructRightVector()) * -I:GetConstructForwardVector()
  ThrustDirection = Quaternion.AngleAxis(PitchRotation, I:GetConstructRightVector()) * ThrustDirection
  ThrustDirection = Quaternion.AngleAxis(YawRotation, I:GetConstructForwardVector()) * ThrustDirection

  I:AimWeaponInDirection(0, ThrustDirection.x,ThrustDirection.y,ThrustDirection.z, 0)

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
