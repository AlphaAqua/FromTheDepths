--Parameters

--Internal Variables, do not touch


--Main function
function Update(I)
    if I:GetNumberOfMainframes() > 0 and I:GetNumberOfTargets(0) > 0 then
        for i=0, I:GetLuaTransceiverCount()-1 do
            for ii=0, I:GetLuaControlledMissileCount(i)-1 do
                I:SetLuaControlledMissileAimPoint(i,ii,I:GetTargetInfo(0, 0).AimPointPosition.x,I:GetTargetInfo(0, 0).AimPointPosition.y,I:GetTargetInfo(0, 0).AimPointPosition.z)
            end
        end
    end
end
  