MissileState = {}
MaxAltitude = 900
AirLessAltitude = 500
MissileMaxFueledTime = 50

function Update(I)

  if I:GetNumberOfMainframes() > 0 then
          for i=0,I:GetWeaponCount()-1 do
            if I:GetWeaponInfo(i).WeaponType == 4 then
              I:AimWeaponInDirection(i, I:GetConstructPosition().x+5000,I:GetConstructPosition().y+5000,I:GetConstructPosition().z, 0)
--              I:FireWeapon(i, 0)
            end
          end

    for i=0, I:GetLuaTransceiverCount()-1 do
      for ii=0, I:GetLuaControlledMissileCount(i)-1 do
        if not MissileState[I:GetLuaControlledMissileInfo(i,ii).Id] then
          MissileState[I:GetLuaControlledMissileInfo(i,ii).Id] = "Up"
        elseif I:GetLuaControlledMissileInfo(i,ii).Position.y < 0 then
          I:DetonateLuaControlledMissile(i,ii)
          I:Log("Boom")
        elseif I:GetLuaControlledMissileInfo(i,ii).Position.y > 950 then
          I:DetonateLuaControlledMissile(i,ii)
          I:Log("Lost")
        elseif MissileState[I:GetLuaControlledMissileInfo(i,ii).Id] == "Up" then
          EstimatedMaxPropeledAltitude = I:GetLuaControlledMissileInfo(i,ii).Position.y + I:GetLuaControlledMissileInfo(i,ii).Velocity.y * (MissileMaxFueledTime-I:GetLuaControlledMissileInfo(i,ii).TimeSinceLaunch)
          EstimatedGravity = math.max(I:GetGravityForAltitude(EstimatedMaxPropeledAltitude).y,0.01) / 2
          EstimatedMaxAltitude = EstimatedMaxPropeledAltitude + (0.5/EstimatedGravity) * I:GetLuaControlledMissileInfo(i,ii).Velocity.y * I:GetLuaControlledMissileInfo(i,ii).Velocity.y
          TargetAngle = math.min(math.max(100 * (MaxAltitude - EstimatedMaxAltitude) / 1000, -90), 90)
          TargetAltitude = I:GetLuaControlledMissileInfo(i,ii).Position.y + 5000 * math.sin(TargetAngle)
          I:Log("Est: " .. EstimatedMaxAltitude .. " Trgt: " .. TargetAngle)
          I:SetLuaControlledMissileAimPoint(i,ii,I:GetConstructCenterOfMass().x+5000,TargetAltitude,I:GetConstructCenterOfMass().z)
          if I:GetLuaControlledMissileInfo(i,ii).TimeSinceLaunch > MissileMaxFueledTime then
            MissileState[I:GetLuaControlledMissileInfo(i,ii).Id] = "Down"
          end
        elseif MissileState[I:GetLuaControlledMissileInfo(i,ii).Id] == "Down" then
          I:SetLuaControlledMissileAimPoint(i,ii,I:GetLuaControlledMissileInfo(i,ii).Position.x+I:GetLuaControlledMissileInfo(i,ii).Position.y,0,I:GetConstructPosition().z)
        end
        I:Log(MissileState[I:GetLuaControlledMissileInfo(i,ii).Id] .. " Altitude:" .. I:GetLuaControlledMissileInfo(i,ii).Position.y .. " Range:" .. I:GetLuaControlledMissileInfo(i,ii).Range .. " (Time: " .. I:GetLuaControlledMissileInfo(i,ii).TimeSinceLaunch .. ")")
      end
    end

  end
end