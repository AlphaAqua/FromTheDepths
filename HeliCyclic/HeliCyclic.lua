 --Preference
 DesiredAltitude = 200
 DesiredSpeed = 3
 MaxPitch = 45

 --Tuning
 AltitudePredictor = 1
 AltitudeGain = 1
 AltitudeDerivate = 0
 AltitudeIntegrator = 0.1

 PitchGain = 0.3
 PitchDerivate = 1
 PitchIntegrator = 0.00001

 RollGain = 0.1
 RollDerivate = 1
 RollIntegrator = 0

 --Internal Variable
 ITERRATE = 40
 DesiredPitch = 0
 DesiredRoll = 0
 AltitudeErrorSum = 0
 AltitudeErrorPrevious = 0
 PitchErrorSum = 0
 PitchErrorPrevious = 0
 RollErrorSum = 0
 RollErrorPrevious = 0
 firstpass = true

 function Update(I)
   if firstpass then
      I:RequestControl(2, 8, 5)
   end

   I:SetSpinnerContinuousSpeed(0, 5)

   PredictedAltitude = I:GetConstructCenterOfMass().y + I:GetVelocityVector().y * AltitudePredictor
   AltitudeError = DesiredAltitude - PredictedAltitude
   if math.abs(AltitudeError) < I:GetConstructCenterOfMass().y/5 then
     AltitudeErrorSum = AltitudeErrorSum + AltitudeError / ITERRATE
   else
     AltitudeErrorSum = 0
   end
   DesiredPitch = -math.max(math.min(PID(AltitudeError, AltitudeErrorPrevious, AltitudeErrorSum, AltitudeGain, AltitudeIntegrator, AltitudeDerivate),-20),-80)

   PitchError = GetAngleDelta(DesiredPitch, I:GetConstructPitch())
   PitchRotation = -math.max(math.min(PID(PitchError, PitchErrorPrevious, PitchErrorSum, PitchGain, PitchIntegrator, PitchDerivate),30),-30)
   PitchErrorPrevious = PitchError

   RollError = GetAngleDelta(DesiredRoll, I:GetConstructRoll())
   RollRotation = math.max(math.min(PID(RollError, RollErrorPrevious, RollErrorSum, RollGain, RollIntegrator, RollDerivate),30),-30)
   RollRotation = 0
   RollErrorPrevious = RollError


 I:Log("Pitch: " .. DesiredPitch .. " : " .. PitchRotation)  
 I:Log("Roll: " .. DesiredRoll .. " : " .. RollRotation)  

   ThrustDirection = Quaternion.AngleAxis(RollRotation, I:GetConstructForwardVector())
                   * Quaternion.AngleAxis(-PitchRotation, I:GetConstructRightVector())
                   * I:GetConstructForwardVector()

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