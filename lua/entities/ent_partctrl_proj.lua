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




if CLIENT then

	function ENT:Initialize()

		local owner = self:GetOwnerEntity()
		if IsValid(owner) then
			owner:StartParticle(self, true)
		end

	end

end