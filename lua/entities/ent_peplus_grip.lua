//Grip point entity, used by ent_peplus's position cpoints when they're not attached to another entity
//This is essentially just a copy of prop_effect, but without the attached entity

AddCSLuaFile()

ENT.PrintName			= "Particle Grip Point"

ENT.Type			= "anim"
ENT.Spawnable			= false
//ENT.RenderGroup		= RENDERGROUP_TRANSLUCENT //tries to make it draw on top of particles, doesn't always work

ENT.PEPlus_Grip			= true //lets us detect if an ent is an ent_peplus_grip without having to compare strings with GetClass




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

		//think func handles clientside collision group

		AllPEPlusGripEnts = AllPEPlusGripEnts or {}
		AllPEPlusGripEnts[self] = true
		self.LastDrawn = 0

	end

	//compress the model down to a single point so that model-covering effects like tf2 burningplayer aren't suspiciously melon-shaped, 
	//but maintain melon-sized hitboxes for traces like the context menu to hit
	self:ManipulateBoneScale(0, vector_origin)
	self:SetCollisionBounds(mins, maxs)

end

if CLIENT then

	function ENT:OnRemove()

		AllPEPlusGripEnts[self] = nil

	end

	function ENT:Think()

		//Stupid hack: prevent the grip from colliding with ANY particle effects using traces, even traces with COLLISION_GROUP_NONE
		//(test with particles/peplus_test.pcf test_SetCPointtoImpactPoint) by setting the collision group to one that only
		//collides with very specific things. Then, when we hover over it with the context menu, set it back to the default collision
		//group, so that the context menu's trace can hit it and right click properties show up. (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/properties.lua#L134)
		if IsValid(g_ContextMenu) and g_ContextMenu:IsVisible() and self:BeingLookedAtByLocalPlayer() then
			//using COLLISION_GROUP_DEBRIS here still prevents *most* fx with traces (i.e. tf2 particles/flamethrowertest.pcf flamethrower)
			//from colliding with the entity, but also causes an issue where the context menu trace won't hit it if there's a prop behind it
			//(caused by the context menu only checking for debris as a fallback here: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/properties.lua#L154-L162).
			//instead, use COLLISION_GROUP_NONE, even though it'll make the effect look bad when we're hovering over it.
			self:SetCollisionGroup(COLLISION_GROUP_NONE)
		else
			self:SetCollisionGroup(COLLISION_GROUP_VEHICLE_CLIP)
		end

	end




	local GripMaterial = Material("sprites/grip")
	local GripMaterialHover = Material("sprites/grip_hover")
	local GripMaterialSelected = Material("sprites/grip_peplus_selected")

	function ENT:Draw()

		if halo.RenderedEntity() == self then
			return
		end

		//Instead of drawing the grip sprite ourselves, we tell the PostDrawTranslucentRenderables hook in ent_peplus to do it, so that it always renders above particle effects
		self.LastDrawn = CurTime()

	end

	function ENT:DrawGripSprite(pos, selected)

		if selected then
			render.SetMaterial(GripMaterialSelected)
		elseif self:BeingLookedAtByLocalPlayer() then
			render.SetMaterial(GripMaterialHover)
		else
			render.SetMaterial(GripMaterial)
		end

		render.DrawSprite(pos, 16, 16, color_white)

	end




	function ENT:BeingLookedAtByLocalPlayer()

		//This is different from base_gmodentity's ENT:BeingLookedAtByLocalPlayer() because...
		//A: we need to change the collision group being used by the trace, due to the collision group wackiness in our Think func
		//B: the base BeingLookedAtByLocalPlayer doesn't get the cursor pos when viewing from an entity other than the player 
		//(i.e. sandbox cameras), which is bad because our Think func relies on this func returning true to make properties work

		local ply = LocalPlayer()
		if !IsValid(ply) then return false end

		local f = FrameNumber()
		if ply.PEPlus_LastPlayerTraceAll == f then
			return ply.PEPlus_PlayerTraceAll.Entity == self
		end
		ply.PEPlus_LastPlayerTraceAll = f

		//Emulate how properties check the point on the screen being aimed at (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/properties.lua#L212-L220, called by https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/spawnmenu/contextmenu.lua#L137-L230)
		//This ensures that we always get the correct result, whether we're viewing from the player or a camera, and whether we're in the context menu or not
		local pos = MainEyePos and MainEyePos() or EyePos()
		ply.PEPlus_PlayerTraceAll = util.TraceLine({
			start = pos,
			endpos = pos + gui.ScreenToVector(input.GetCursorPos()) * 1024,
			filter = ply:GetViewEntity(),
			collisiongroup = COLLISION_GROUP_VEHICLE //Make sure trace collides with the grip, no matter which collision group Think sets it to
		})
		return ply.PEPlus_PlayerTraceAll.Entity == self

	end

end




function ENT:PhysicsUpdate(physobj)

	if CLIENT then return end

	//Don't do anything if the player isn't holding us
	if !self:IsPlayerHolding() then
		local isconstrained = false
		local consts = constraint.GetTable(self)
		for k, v in pairs (consts) do
			if v.Type and v.Type != "PEPlus_Ent" and v.Type != "PEPlus_SpecialEffect" then
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
duplicator.RegisterEntityClass("ent_peplus_grip", function(ply, data)

	local ent = ents.Create("ent_peplus_grip")
	if !ent:IsValid() then return false end

	//duplicator.GenericDuplicatorFunction(ply, data)
	duplicator.DoGeneric(ent, data)
	duplicator.DoGenericPhysics(ent, ply, data)

	ent:Spawn()

	//If this ent was duplicated but doesn't have an associated particle entity (i.e. duped in multiplayer, and the particle ent was prevented from spawning) then delete it
	timer.Simple(0, function()
		if !IsValid(ent) then return end
		if !istable(constraint.FindConstraint(ent, "PEPlus_Ent")) and !istable(constraint.FindConstraint(ent, "PEPlus_SpecialEffect")) then ent:Remove() end
	end)

	return ent

end, "Data")