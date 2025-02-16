AddCSLuaFile()

ENT.Base 			= "ent_partctrl_sfx"
ENT.PrintName			= "Tracer Effect"
ENT.Category			= "Particle Controller" //TODO: this name sucks, improve it eventually

ENT.Spawnable			= true

ENT.PartCtrl_ShortName		= "Tracer"
ENT.SpecialEffectRoles		= {
	[0] = "Start",
	[1] = "End",
}




function ENT:SetupDataTables()

	self:NetworkVar("Int", 0, "AttachmentID") //all special fx must have this one

end




function ENT:SetNWVarDefaults()

	self:SetAttachmentID(0) //all special fx must have this one

end




function ENT:SpecialEffectDefaultRoles(cpoints)
	//First half of the cpoints default to the start, second half of the cpoints start at the end
	//This means fx with 2 cpoints will automatically connect the first to the start, and the second to the end
	local results = {}
	for k, cpoint in pairs (cpoints) do
		if k > (#cpoints/2) then
			results[cpoint] = 1
		else
			results[cpoint] = 0
		end
	end
	return results
end




function ENT:SpecialEffectThink()
end




//Networking for edit menu inputs
local EditMenuInputs = {
	//All special fx must have these ones
	[0] = "self_parent_setwithtool",
	"self_parent_detach",
	"self_attach",
	"child_setwithtool",
	"child_detach",
	//Entity-specific inputs
	//TODO
}
ENT.EditMenuInputs_bits = 4 //max 15
ENT.EditMenuInputs = table.Flip(EditMenuInputs)

if CLIENT then
	
	//TODO: entity-specific input sending

else
	
	//TODO: entity-specific input receiving

end




duplicator.RegisterEntityClass("ent_partctrl_sfx_tracer", function(ply, data)

	local ent = ents.Create("ent_partctrl_sfx_tracer")
	if !ent:IsValid() then return false end

	//duplicator.GenericDuplicatorFunction(ply, data)
	duplicator.DoGeneric(ent, data)
	duplicator.DoGenericPhysics(ent, ply, data)

	ent.DoneFirstSpawn = data.DoneFirstSpawn //all special fx need this; don't set nwvar defaults or make a parent grip point if the dupe is already taking care of those
	ent:SetPlayer(ply) //NOTE: this still works if ply doesn't exist

	ent:Spawn()

	return ent

end, "Data")