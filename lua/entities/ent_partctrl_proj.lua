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

	local owner = self:GetOwnerEntity()
	if IsValid(owner) then
		self.PhysicsSounds = owner:GetProjPhysSounds()
	end
	if !self.PhysicsSounds then
		self.PartCtrl_ProjDisableSounds = true
	end

end




if CLIENT then

	function ENT:Think()

		//Call StartParticle once the client has received the ParticleInfo tables for all the child particles
		//(if we don't check for this, the effect's first projectile launched will have no particles)
		if !self.HasDoneStart then
			local owner = self:GetOwnerEntity()
			if IsValid(owner) then
				for child, _ in pairs (owner.SpecialEffectChildren) do
					local pcf = PartCtrl_GetGamePCF(child:GetPCF(), child:GetPath())
					if istable(PartCtrl_ProcessedPCFs[pcf]) and istable(PartCtrl_ProcessedPCFs[pcf][child:GetParticleName()]) //don't get stuck here if a child has an invalid effect, just skip it
					and !child.ParticleInfo then
						wait = true
						break
					end
				end
				if !wait then
					owner:StartParticle(self)
					self.HasDoneStart = true
				end
			end
		end

	end

end




if SERVER then

	util.AddNetworkString("PartCtrl_ProjEffectExpire_SendToCl")

	//Called by PhysicsCollide function defined in ent_partctrl_sfx_proj's CreateProjectile function
	function ENT:DoExpire(pos, norm)

		net.Start("PartCtrl_ProjEffectExpire_SendToCl", true)
			net.WriteEntity(self:GetOwnerEntity())
			net.WriteVector(pos or self:GetPos())
			net.WriteBool(tobool(norm))
			if norm then
				net.WriteVector(norm)
			end
		net.Broadcast()

	end

else
	
	net.Receive("PartCtrl_ProjEffectExpire_SendToCl", function(_, ply)

		local sfx = net.ReadEntity()
		local pos = net.ReadVector()
		local norm
		if net.ReadBool() then
			norm = net.ReadVector()
		end

		if !IsValid(sfx) or !sfx.PartCtrl_SpecialEffect or !sfx:GetClass() == "ent_partctrl_sfx_proj" then return end
		sfx:StartParticle(nil, pos, norm)

	end)

end