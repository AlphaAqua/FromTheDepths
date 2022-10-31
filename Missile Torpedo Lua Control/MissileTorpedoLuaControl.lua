--Parameters
MaxMissileRange = 3000
IsATorpedo = false
LuaControledFire = true
AirRadius = 300
TorpedoDepth = 50

EstimatedMissileAirSpeed = 100

--Internal Variables, do not touch

function Update(I)

  if I:GetNumberOfMainframes() > 0 and I:GetNumberOfTargets(0) > 0 then
    if LuaControledFire == true then
      if I:GetTargetPositionInfo(0, 0).Range < MaxMissileRange then
        if IsATorpedo == false or I:GetTerrainAltitudeForLocalPosition(0,0,0) < 0 then
          for i=0,I:GetWeaponCount()-1 do
            if I:GetWeaponInfo(i).WeaponType == 5 then
              I:AimWeaponInDirection(i, I:GetTargetPositionInfo(0, 0).Direction.x,I:GetTargetPositionInfo(0, 0).Direction.y,I:GetTargetPositionInfo(0, 0).Direction.z, 0)
              if I:GetLuaControlledMissileCount(i) == 0 then I:FireWeapon(i, 0)
              end
              --I:FireWeapon(i, 0)
            end
          end
        end
      end
    end

    --I:Log("Controlling " .. I:GetLuaTransceiverCount() .. " launchpad with " .. I:GetLuaControlledMissileCount(0) .. " missiles on the first.")

    for i=0, I:GetLuaTransceiverCount()-1 do
      for ii=0, I:GetLuaControlledMissileCount(i)-1 do
        LineOfSightVector = Vector3.Normalize(I:GetLuaControlledMissileInfo(i,ii).Position - I:GetTargetInfo(0, 0).AimPointPosition)

        TargetRange = Vector3.Magnitude(I:GetLuaControlledMissileInfo(i,ii).Position - I:GetTargetInfo(0, 0).Position)
        TargetGroundRange = Vector3.Magnitude(Vector3(I:GetLuaControlledMissileInfo(i,ii).Position.x, 0, I:GetLuaControlledMissileInfo(i,ii).Position.z) -
                                              Vector3(I:GetTargetInfo(0, 0).Position.x,0,I:GetTargetInfo(0, 0).Position.z))
        RelativeSpeedWRTLoS = Vector3.Dot((I:GetLuaControlledMissileInfo(i,ii).Velocity - I:GetTargetInfo(0, 0).Velocity), LineOfSightVector )
        TimeToSurface = math.max(math.max(TargetGroundRange-AirRadius,0)+math.max(TorpedoDepth,math.abs(I:GetLuaControlledMissileInfo(i,ii).Position.y)),0) / math.max(0.001, RelativeSpeedWRTLoS)
        EstimatedTargetPositionAtSurface = I:GetTargetInfo(0, 0).AimPointPosition +I:GetTargetInfo(0, 0).Velocity * TimeToSurface
        if I:GetLuaControlledMissileInfo(i,ii).Position.y > -1 then TimeToSurface = 0 end

        TimeOfFlight = Vector3.Magnitude(EstimatedTargetPositionAtSurface-I:GetTargetInfo(0, 0).AimPointPosition) / math.max(0.001, EstimatedMissileAirSpeed)
        EstimatedTargetPositionAtImpact = I:GetTargetInfo(0, 0).AimPointPosition +I:GetTargetInfo(0, 0).Velocity * (TimeToTarget+TimeOfFlight)
        EstimatedTargetPositionInfo = I:GetTargetPositionInfoForPosition(0,EstimatedTargetPositionAtImpact.x,EstimatedTargetPositionAtImpact.y,EstimatedTargetPositionAtImpact.z)

        I:Log(RelativeSpeedWRTLoS .. " : " .. TimeToSurface .. " : " .. TimeOfFlight)

        if TargetGroundRange > (AirRadius+TorpedoDepth) then
          --Close in from underwater
          I:SetLuaControlledMissileAimPoint(i,ii,EstimatedTargetPositionAtImpact.x,TorpedoDepth,EstimatedTargetPositionAtImpact.z)
        elseif I:GetLuaControlledMissileInfo(i,ii).Position.y < 0 then
          --Withing air range but under water, rise up
          I:SetLuaControlledMissileAimPoint(i,ii,EstimatedTargetPositionAtImpact.x,math.min(EstimatedTargetPositionAtImpact.y,TargetGroundRange),EstimatedTargetPositionAtImpact.z)
        else
          --Final approach
          I:SetLuaControlledMissileAimPoint(i,ii,EstimatedTargetPositionAtImpact.x,EstimatedTargetPositionAtImpact.y,EstimatedTargetPositionAtImpact.z)
        end
      end
    end

  end
end