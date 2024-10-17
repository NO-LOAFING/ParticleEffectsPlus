//Grip point entity, used by ent_partctrl's position cpoints when they're not attached to another entity
//This is essentially just a copy of prop_effect, but without the attached entity

AddCSLuaFile()

ENT.PrintName			= "Particle Grip Point"

ENT.Type			= "anim"
ENT.Spawnable			= false
//ENT.RenderGroup		= RENDERGROUP_TRANSLUCENT //tries to make it draw on top of particles, doesn't always work




function ENT:Initialize()

	local Radius = 6
	local mins = Vector(1,1,1) * Radius * -0.5
	local maxs = Vector(1,1,1) * Radius * 0.5

	if SERVER then

		self:SetModel("models/props_junk/watermelon01.mdl")

		//Don't use the model's physics - create a box instead
		//TODO: do we want it to be this large, or do we want something smaller, to accomodate effects that want to be flat on the ground?
		self:PhysicsInitBox(mins, maxs)
		self:SetSolid(SOLID_VPHYSICS)

		//Set up our physics object here
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableGravity(false)
			phys:EnableDrag(false)
		end

		self:DrawShadow(false)
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	else

		//Prevent fx with Collision via traces (i.e. particles/flamethrowertest.pcf flamethrower) from colliding with the grip point
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

		AllPartCtrlGripEnts = AllPartCtrlGripEnts or {}
		AllPartCtrlGripEnts[self] = true
		self.LastDrawn = 0

	end

	//compress the model down to a single point so that model-covering effects like tf2 burningplayer aren't suspiciously melon-shaped, 
	//but maintain melon-sized hitboxes for traces like the context menu to hit
	self:ManipulateBoneScale(0, vector_origin)
	self:SetCollisionBounds(mins, maxs)

end

if CLIENT then
	function ENT:OnRemove()
		AllPartCtrlGripEnts[self] = nil
	end
end




local GripMaterial = Material("sprites/grip")
local GripMaterialHover = Material("sprites/grip_hover")
local GripMaterialSelected = Material("gui/faceposer_indicator") //TODO: make a better one, color the default grip tan/cream to match the tool's selection halo

function ENT:Draw()

	if halo.RenderedEntity() == self then
		return
	end

	//Instead of drawing the grip sprite ourselves, we tell a PostDrawTranslucentRenderables hook in ent_partctrl to do it, so that it always renders above particle effects
	self.LastDrawn = CurTime()

end

function ENT:DrawGripSprite(selected)

	if selected then
		render.SetMaterial(GripMaterialSelected)
	elseif self:BeingLookedAtByLocalPlayer() then
		render.SetMaterial(GripMaterialHover)
	else
		render.SetMaterial(GripMaterial)
	end

	render.DrawSprite(self:GetPos(), 16, 16, color_white)

end




-- Copied from base_gmodentity.lua
ENT.MaxWorldTipDistance = 256
function ENT:BeingLookedAtByLocalPlayer()
	local ply = LocalPlayer()
	if ( !IsValid( ply ) ) then return false end

	local view = ply:GetViewEntity()
	local dist = self.MaxWorldTipDistance
	dist = dist * dist

	-- If we're spectating a player, perform an eye trace
	if ( view:IsPlayer() ) then
		//return view:EyePos():DistToSqr( self:GetPos() ) <= dist && view:GetEyeTrace().Entity == self
		//This doesn't work because we need to set MASK_ALL to hit an entity using COLLISION_GROUP_DEBRIS.
		//Instead, emulate player:GetEyeTrace/util.GetPlayerTrace. (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/gamemode/obj_player_extend.lua#L172-L192), (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/util.lua#L32-L49)
		local pos = view:EyePos()
		if ( pos:DistToSqr( self:GetPos() ) <= dist ) then
			local framenum = FrameNumber()
			if ( view.PartCtrl_LastPlayerTraceAll == framenum ) then
				return view.PartCtrl_PlayerTraceAll.Entity == self
			end
			view.PartCtrl_LastPlayerTraceAll = framenum

			view.PartCtrl_PlayerTraceAll = util.TraceLine({
				start = pos,
				endpos = pos + ( view:GetAimVector() * dist ),
				filter = view,
				mask = MASK_ALL //needed to hit COLLISION_GROUP_DEBRIS
			})
			return view.PartCtrl_PlayerTraceAll.Entity == self
		end
	end

	-- If we're not spectating a player, perform a manual trace from the entity's position
	local pos = view:GetPos()

	if ( pos:DistToSqr( self:GetPos() ) <= dist ) then
		return util.TraceLine( {
			start = pos,
			endpos = pos + ( view:GetAngles():Forward() * dist ),
			filter = view,
			mask = MASK_ALL //needed to hit COLLISION_GROUP_DEBRIS
		} ).Entity == self
	end

	return false
end




function ENT:PhysicsUpdate(physobj)

	if CLIENT then return end

	//Don't do anything if the player isn't holding us
	if !self:IsPlayerHolding() then
		local isconstrained = false
		local consts = constraint.GetTable(self)
		for k, v in pairs (consts) do
			if v.Type and v.Type != "PartCtrl_Ent" then
				isconstrained = true
				break
			end
		end
		if !isconstrained then
			physobj:SetVelocity(vector_origin)
			physobj:Sleep()
		end
	end

end




local badproperties = {
	makeanimprop = true, //don't convert our stupid invisible placeholder model into an animated prop
	rb655_make_animatable = true, //also the one from easy animation tool since it's the only other model-related property i had while testing
}

function ENT:CanProperty(ply, property)

	if badproperties[property] then return false end
	return true

end




//Need to register this, or for some reason, our constraints will break when duped and refer back to the original entity
//(i.e. spawn a beam particle, duplicate it, now right-click either pair with the duplicator and it'll copy both of them as if they were constrained together)
duplicator.RegisterEntityClass("ent_partctrl_grip", function(ply, data)

	local ent = ents.Create("ent_partctrl_grip")
	if !ent:IsValid() then return false end

	//duplicator.GenericDuplicatorFunction(ply, data)
	duplicator.DoGeneric(ent, data)
	duplicator.DoGenericPhysics(ent, ply, data)

	ent:Spawn()

	//If this ent was duplicated but doesn't have an associated particle entity (i.e. duped in multiplayer, and the particle ent was prevented from spawning) then delete it
	timer.Simple(0, function()
		if !IsValid(ent) then return end
		if !istable(constraint.FindConstraint(ent, "PartCtrl_Ent")) then ent:Remove() end
	end)

	return ent

end, "Data")