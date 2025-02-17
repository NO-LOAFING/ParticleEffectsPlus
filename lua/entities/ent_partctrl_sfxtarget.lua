//Clientside entity used as a target for special fx; deletes itself once its associated particles and/or entity no longer exist

AddCSLuaFile()

//ENT.Base 			= "base_gmodentity"
ENT.PrintName			= "Special Effect Target"

ENT.Type			= "anim"
ENT.Spawnable			= false 

if SERVER then return end




function ENT:Initialize()
	
	//self:SetModel("models/props_junk/watermelon01.mdl") //using the melon model makes this ent reset its pos and ang when the game is paused, maddening
	//self:PhysicsInit(SOLID_NONE)
	//self:SetSolid(SOLID_NONE)
	//self:SetMoveType(MOVETYPE_NONE)
	//self:DrawShadow(false)

	//compress the model down to a single point so that model-covering effects like tf2 burningplayer aren't suspiciously melon-shaped
	self:ManipulateBoneScale(0, vector_origin)

end




function ENT:Draw()

	//Don't draw
	
end




function ENT:Think()

	//we don't need to do these checks too often
	self:SetNextClientThink(CurTime() + 1)

	if !IsValid(self.OwnerEntity) then 
		self:Remove()
		return true
	end

	if self.Particles then
		for k, v in pairs (self.Particles) do
			if !(v.IsValid and v:IsValid()) then
				self.Particles[k] = nil
			end
		end
		if #self.Particles == 0 then
			self.Particles = nil
			self:Remove()
			return true
		end
	end
	
	return true

end