ITERRATE = 40

--Preference
CruiseAltitude = 200

--Tuning
AltitudeGain = 1
Predictor = 0
PitchGain = 0.01
PitchDerivate = 0
PitchIntegrator = 0
YawGain = 0.001
YawDerivate = 5
YawIntegrator = 0.001
PitchDamper = 0.95
MaxPitch = 75

--Internal Variable
DesiredAltitude = CruiseAltitude
DesiredPitch = 0
DesiredYaw = 0
PitchErrorSum = 0
YawErrorSum = 0
PitchErrorPrevious = 0
YawErrorPrevious = 0
firstpass = true
HoldPosition = Vector3(I:GetConstructCenterOfMass().x, 0, I:GetConstructCenterOfMass().z)

function Update(I)
  if firstpass then
    I:RequestControl(2, 8, 1)
    HoldPosition = Vector3(I:GetConstructCenterOfMass().x, 0, I:GetConstructCenterOfMass().z)
  end

  if (I:GetNumberOfTargets(0) > 0) then
    if (I:GetTargetPositionInfo(0, 0).GroundDistance < 2 * CruiseAltitude) then
      DesiredAltitude = I:GetTargetPositionInfo(0, 0).AltitudeAboveSeaLevel
    end

    --DesiredYaw = I:GetTargetPositionInfo(0, 0).Azimuth
  end

  DesiredPitch = PitchDamper*DesiredPitch + (1-PitchDamper)*math.max(math.min(AltitudeGain*(DesiredAltitude - I:GetConstructCenterOfMass().y),MaxPitch),-MaxPitch)
  PredictedPitch = -I:GetConstructPitch() + I:GetAngularVelocity().x * Predictor
  PitchError = GetAngleDelta(DesiredPitch, PredictedPitch)
  PitchErrorSum  = PitchErrorSum + PitchError
  PitchRotation = math.max(math.min(PID(PitchError, PitchErrorPrevious, PitchErrorSum, PitchGain, PitchIntegrator, PitchDerivate),1),-1)

  PitchErrorPrevious = PitchError

  CurrentPosition = I:GetConstructCenterOfMass()
  CurentLandPosition = Vector3(I:GetConstructCenterOfMass().x, 0, I:GetConstructCenterOfMass().z)
  DistanceToHoldPosition = Vector3.Distance(HoldPosition, CurentLandPosition)

  PredictedYaw = I:GetConstructYaw() + I:GetAngularVelocity().y * Predictor
  YawError = GetAngleDelta(DesiredYaw, PredictedYaw)
  YawErrorSum  = YawErrorSum + YawError
  YawRotation = math.max(math.min(PID(YawError, YawErrorPrevious, YawErrorSum, YawGain, YawIntegrator, YawDerivate),1),-1)

  YawErrorPrevious = YawError

I:Log(111) 

  if (PitchRotation > 0) then
    I:RequestControl(2,4,PitchRotation)
  else
    I:RequestControl(2,5,-PitchRotation)
  end 

  if (YawRotation > 0) then
    I:RequestControl(2,0,YawRotation)
  else
    I:RequestControl(2,1,-YawRotation)
  end 

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
