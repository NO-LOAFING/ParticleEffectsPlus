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
	end

end




if SERVER then

	util.AddNetworkString("PartCtrl_ProjEffectExpire_SendToCl")

	function ENT:DoExpire(pos, norm)

		net.Start("PartCtrl_ProjEffectExpire_SendToCl", true)
			net.WriteEntity(self:GetOwnerEntity())
			net.WriteVector(pos or self:GetPos())
			net.WriteBool(tobool(norm))
			if norm then
				net.WriteVector(norm)
			end
		net.Broadcast()

		self:Remove()

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