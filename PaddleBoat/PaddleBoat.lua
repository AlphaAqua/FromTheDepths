 --Basic Paddle boat Logic by Dainsleif
 --Thanks for sharing!
 --Code comes from my usual script modified for paddle boat.

 --Parameters, you can modify theses
 AttackType = "AttackRun"
 HoldRadius = 300
 BroadsideRadius = 400
 AttackRunDistanceMax = 500
 AttackRunDistanceMin = 200

 --Update this to fine tune performance
 ControlerGain = 5
 MaxSpinnerSpeed = 5


 --Internal variable, do not touch
 YawCommand = 0

 --------------------------
 function Update(I)
   Propulsion = {}
   Propulsion = UpdatePropulsionArray(I)

   UpdateNavigation(I)

   UpdateCommand(I)

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
  
     if NavMode == "Hold" then
       HoldPosition = Vector3(I:GetConstructCenterOfMass().x, 0, I:GetConstructCenterOfMass().z)
       for i = 0, I:Component_GetCount(7)-1 do
         I:Component_SetBoolLogic(7,i, true)
       end

     end
   end
   NavModePrev = NavMode

   if NavMode == "Hold"      then UpdateNavigationHoldingPatern(I) end
   if NavMode == "AttackRun" then UpdateNavigationAttackRun(I) end
   if NavMode == "Broadside" then UpdateNavigationBroadside(I) end

 end

 --------------------------
 function UpdateNavigationAttackRun(I)
   CurrentPosition = I:GetConstructCenterOfMass()
   TargetPositionInfo = I:GetTargetPositionInfo(0, 0)
   I:Log(TargetPositionInfo.Range)

   DesiredYaw = I:GetConstructYaw() - TargetPositionInfo.Azimuth
   if DesiredYaw > 360 then DesiredYaw = DesiredYaw - 360 end

   if DesiredSpeed > 0 and TargetPositionInfo.Range < AttackRunDistanceMin then
     DesiredSpeed = -1
   elseif DesiredSpeed < 0 and TargetPositionInfo.Range > AttackRunDistanceMax then
     DesiredSpeed = 1
   end

 end

 --------------------------
 function UpdateNavigationBroadside(I)
     CurrentPosition = I:GetConstructCenterOfMass()
     CurentLandPosition = Vector3(I:GetConstructCenterOfMass().x, 0, I:GetConstructCenterOfMass().z)
     TargetLandPosition = Vector3(I:GetTargetInfo(0, 0).Position.x, 0, I:GetTargetInfo(0, 0).Position.z)
     DistanceToTarget = Vector3.Distance(TargetLandPosition, CurentLandPosition)
     DesiredYawRelativeToTarget = math.max(math.min(DistanceToTarget/BroadsideRadius*90,180),0)
     AngleWithTarget = 90 - 180/3.1416* math.atan2(CurentLandPosition.z - TargetLandPosition.z, CurentLandPosition.x - TargetLandPosition.x)
     DesiredYaw = DesiredYawRelativeToTarget + AngleWithTarget
     if DesiredYaw > 360 then DesiredYaw = DesiredYaw-360 end
     DesiredSpeed = 1
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

     DesiredSpeed = 1
 end
 --------------------------

 function UpdateCommand(I)
   YawCommand = ControlerGain * GetAngleDelta(DesiredYaw, I:GetConstructYaw()) / 180
 end

 --------------------------
 function UpdatePropulsion(I, Propulsion)
   NbPropulsion = I:GetSpinnerCount()


   for i=0, NbPropulsion-1 do
     CommandSpeed = DesiredSpeed * MaxSpinnerSpeed
     if Propulsion[i+1].Starboard then
       I:SetSpinnerContinuousSpeed(i, math.min(math.max(CommandSpeed-YawCommand,-MaxSpinnerSpeed), MaxSpinnerSpeed))
     elseif Propulsion[i+1].PortSide then
       I:SetSpinnerContinuousSpeed(i, math.min(math.max(-CommandSpeed-YawCommand,-MaxSpinnerSpeed), MaxSpinnerSpeed))
     end
   end
  
 end

 ----------------------
 function UpdatePropulsionArray(I)
   Propulsion = {}
   NbPropulsion = I:GetSpinnerCount()

   for i=0, NbPropulsion-1 do
     Propulsion[i+1] = {}
     binfo = I:GetSpinnerInfo(i)
     --Portside
     if binfo.LocalPositionRelativeToCom.x < -0.5  then
       Propulsion[i+1].PortSide = true
     end

     --Starboard
     if binfo.LocalPositionRelativeToCom.x > 0.5  then
       Propulsion[i+1].Starboard = true
     end
   end

   return Propulsion
 end

 ----------------------
 function GetAngleDelta(a, b)
   result = a - b
   if result > 180 then result= result - 360 end
   if result < -180 then result = result + 360 end
   return result
 end

