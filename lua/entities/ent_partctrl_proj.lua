//Entity used for ent_partctrl_sfx_proj serverside projectiles; calls StartParticle once initialized on clients

AddCSLuaFile()

//ENT.Base			= "base_gmodentity"
ENT.PrintName			= "Special Effect Projectile"

ENT.Type			= "anim"
ENT.Spawnable			= false 
ENT.DoNotDuplicate		= true //which of these actually works? doesn't matter, use them both
ENT.DisableDuplicator		= true

if CLIENT then
	language.Add("ent_partctrl_proj", "Physics Object")  //for killfeed notices
end




function ENT:SetupDataTables()

	self:NetworkVar("Entity", 0, "OwnerEntity")

end




function ENT:Initialize()

	if CLIENT then
		local owner = self:GetOwnerEntity()
		if IsValid(owner) then
			owner:StartParticle(self)
		end
	else
		timer.Simple(self.lifetime_prehit, function() 
			if IsValid(self) then
				self:DoExpire()
			end
		end)
	end

end




if SERVER then

	function ENT:PhysicsCollide(data)

		if self.HasHitSomething then return end //there's no reason to call this more than once
		self.HasHitSomething = true

		timer.Simple(self.lifetime_posthit, function() //even if lifetime_posthit is 0, we still need to use a timer, because directly removing the ent in a PhysicsCollide callback crashes the game
			if IsValid(self) then
				if self.lifetime_posthit == 0 then
					self:DoExpire(data.HitPos, -data.HitNormal:Angle())
				else
					self:DoExpire()
				end
			end
		end)

	end

	util.AddNetworkString("PartCtrl_ProjEffectExpire_SendToCl")

	function ENT:DoExpire(pos, ang)

		net.Start("PartCtrl_ProjEffectExpire_SendToCl", true)
			net.WriteEntity(self:GetOwnerEntity())
			net.WriteVector(pos or self:GetPos())
			net.WriteAngle(ang or self:GetAngles())
		net.Broadcast()

		self:Remove()

	end

else
	
	net.Receive("PartCtrl_ProjEffectExpire_SendToCl", function(_, ply)

		local sfx = net.ReadEntity()
		local pos = net.ReadVector()
		local ang = net.ReadAngle()

		if !IsValid(sfx) or !sfx.PartCtrl_SpecialEffect or !sfx:GetClass() == "ent_partctrl_sfx_proj" then return end
		sfx:StartParticle(nil, pos, ang)

	end)

end