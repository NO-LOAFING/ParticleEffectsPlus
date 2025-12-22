AddCSLuaFile()

//Add util fx

//Example:
--[[list.Add("PartCtrl_UtilFx", "EffectName", { //Name of the effect that util.Effect() will call
	title = "Garry's Mod",	//String; in the "Browse Particles" spawnlist, any game, addon, or legacy addon with this exact folder name will get a "Scripted Effects" subfolder containing this effect
	title = {"MyCoolAddon", "My Cool Addon: Workshop Edition"}, //Can also be a table of strings instead, just in case you want to, say, support both a legacy addon folder name and a workshop addon name
	
	default_time = 1,	//Float, default setting of "seconds between repeats" on newly spawned fx, should roughly correspond to how long it takes for the effect to "finish", defaults to 1 if absent
	info = "Text text text",//String, optional, adds extra info to the spawnicon and edit window
	info_sfx = "Text text", //String, optional, alternative info text used instead of the above if attached to a special effect (tracer/beam/projectile)
	cpoint_distance_overrides = {[1] = {["min"] = 129}},	//Table, optional, overrides how far apart the grip points will spawn; used by some tracer fx that don't render if the points are too close together

	DoProcess = function(tab, extras)
		//Function, used to set up the controls for the util effect by defining CONTROL POINTS, just like we do with PCF effects.
		//A control point can be:
		// A: a POSITION control, which spawns a grip point and uses its position value, and can also be attached to an entity to use its position or the position of one of its attachments
		// B: a VECTOR control, which has 3 sliders or a color picker to set the X, Y, and Z value of the vector
		// C: an AXIS control, which can seperately define controls for any combination of its X, Y, or Z values; each axis can use a slider, dropdown, or checkboxes to set its value.
		
		//Adds a position control for cpoint 0
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Angles, Normal, Entity, Attachment") //by default, this adds a position control

		//Adds a vector control for cpoint 1
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Start", "vector", { 
			["label"] = "Start",
			["min"] = Vector(-512,-512,-512),
			["max"] = Vector(512,512,512),
			["default"] = Vector(0,0,0),
		})
		
		//Adds an axis control for cpoint 2's x axis; by default, this is a slider
		PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Scale", "axis", { 
			["axis"] = 0, //x
			["label"] = "Scale",
			["min"] = 1,
			["max"] = 10,
			["default"] = 1,
			["decimals"] = 0, //optional
		})
		//Adds an axis control for cpoint 2's y axis, with a dropdown
		PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Color", "axis", {
			["axis"] = 1, //y
			["label"] = "Color",
			["default"] = 0,
			["dropdown"] = { //for each option, the number is the what the axis gets set to, and the string is the text displayed in the dropdown for that value
				[0] = "Red",
				[1] = "Green",
				[-1] = "Beige",
				[2] = "Chartreuse",
				[3000] = "Vantablack",
			},
		})
		//Adds an axis control for cpoint 2's z axis, with checkboxes
		PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Flags", "axis", {
			["axis"] = 2, //z
			["default"] = 0,
			["checkboxes"] = { //adds a checkbox for each option; the axis gets set to the SUM of all the boxes that are checked
				[16] = "Some Flag",
				[32] = "Some Other Flag"
				[64] = "You Get The Idea"
			},
		})

		//See the effects below for more examples.
	end,
	DoProcessExtras = {["scale_max"] = 50}, //Table, optional; this sets the "extras" arg for the DoProcess func, so that multiple fx with different values can use the same function

	DoEffect = function(self, ed)
		//Function, used when we're playing the effect to set its EffectData values, usually by grabbing information from the control points we set up earlier.
		//"self" arg is the particle controller entity which has all the cpoint info, "ed" is the CEffectData object. https://wiki.facepunch.com/gmod/CEffectData

		//Sets the Origin, Angles and Normal from cpoint 0 - the particle entity has a self:CPointPosAng() func that returns the position and angle of a cpoint
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetAngles(self:CPointPosAng(0).ang)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())

		//Sets the Entity from cpoint 0's entity - this will be the grip point entity if it's unattached, or the entity it's attached to if it is attached
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end //if we're attached to a prop_effect, get its model instead of its grip point
		ed:SetEntity(ent)

		//Sets the Attachment from cpoint 0's attachment setting - this will always be 0 if it's not attached to an entity
		ed:SetAttachment(self.ParticleInfo[0].attach)

		//Sets the Start to the value from cpoint 1's vector control
		ed:SetStart(self.ParticleInfo[1].val)

		//Sets the Scale, Color and Flags to the values from cpoint 2's axis controls
		ed:SetScale(self.ParticleInfo[2].val.x)
		ed:SetColor(self.ParticleInfo[2].val.y)
		ed:SetFlags(self.ParticleInfo[2].val.z + 128) //let's say there's a flag you always want to be set, instead of making a checkbox for it. sure, you can do that.

		ed:SetMagnitude(10) //of course, you can set values manually if you don't want to add controls for them

		return true //If you don't return true, then it won't play the effect, so you can add conditions where the effect shouldn't play (i.e. fx that only play if they have a valid attachment)

		//See the effects below for more examples.
	end,
})]]

local needs_attachment = "Must be attached to a model, on a non-0 attachment"
local needs_attachment_1 = "Must be attached to a model with at least 1 attachment; always uses attachment #1"
local needs_model = "Must be attached to a model"

--[[list.Set("PartCtrl_UtilFx", "Spawnlist_Populator_Test", {
	//test: populate a game, workshop addon, and legacy addon, with and without existing particles
	title = {"Garry's Mod", "Half-Life 2: Deathmatch", "Hat Painter & Crit Glow Tools", "Animated Props", "ParticleControlOverhaul", "ukmodels", "NotARealGameOrAddon"},
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		return true
	end
})]]

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx_sparks.cpp#L1524
list.Set("PartCtrl_UtilFx", "ManhackSparks", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetAngles(self:CPointPosAng(0).ang) //func retrieves this value but doesn't actually use it for anything
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		return true
	end
})

//doesn't seem to work, see code for this effect https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx.cpp#L1327; is it because vColor doesn't seem to be defined properly
//so the effect is just black? only HL2 code that uses this effect is the prototype electrical drone helicopter, on which the effect doesn't show up either. ent_create npc_helicopter spawnflags 131072,
//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/npc_attackchopper.cpp#L2533
--[[list.Set("PartCtrl_UtilFx", "TeslaZap", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity, Attachment")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Beam Width",
			["min"] = 0,
			["max"] = 32,
			["default"] = 1,
		})
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)

		ed:SetAttachment(self.ParticleInfo[0].attach)
		ed:SetOrigin(self:CPointPosAng(1).pos)
		ed:SetScale(self.ParticleInfo[2].val.x)
		return true
	end
})]]

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx.cpp#L1285
list.Set("PartCtrl_UtilFx", "TeslaHitboxes", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.2, //default repeat rate and beam count taken from ragdoll boogie and antlion (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/RagdollBoogie.cpp#L119, https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/server/hl2/npc_antlion.cpp#L2254)
	info = "This effect will apply to a whole model if control point 0 is attached.", //on_model
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Magnitude", "axis", {
			["axis"] = 0, //x
			["label"] = "Beam Count",
			["min"] = 1,
			["max"] = 10, //don't go too crazy with this because it's uncapped, players can just add more copies if they want more beams anyway
			["default"] = 4,
			["decimals"] = 0,
		})
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)

		ed:SetMagnitude(self.ParticleInfo[1].val.x)
		//scale is supposed to be beam width but isn't actually hooked up properly; FX_BuildTeslaHitbox passes scale as the flBeamWidth arg to another func of the same name (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx.cpp#L1281)
		//but this value isn't actually used anywhere in that func (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx.cpp#L1158)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx.cpp#L812
list.Set("PartCtrl_UtilFx", "CommandPointer", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0, //needs to render every frame
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Color", "axis", {
			["axis"] = 0, //x
			["label"] = "Color",
			["default"] = 0,
			["dropdown"] = { //sets key from table "commandercolors" (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/effect_color_tables.h#L34)
				[0] = "Red",
				[1] = "Blue",
				[2] = "Green",
				[3] = "Yellow",
			},
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		//hl2 code that calls this effect sets angles and normal to zero, but these values aren't actually used in the effect code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/proto_sniper.cpp#L1875)
		ed:SetColor(self.ParticleInfo[1].val.x)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx.cpp#L794
list.Set("PartCtrl_UtilFx", "GunshipImpact", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0, //internally this is the same as commandpointer, so it needs to render every frame if it wants to stay visible, but in the unused gunship code that calls this, it's just meant to be a little extra flair upon hitting a shot, so maybe don't repeat every frame? who cares, this effect sucks anyway 
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		//like above, hl2 code that calls this effect sets angles and normal to zero, but these values aren't actually used in the effect code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/npc_combinegunship.cpp#L2790)
		return true
	end
})

//this effect has a lifetime of 100 seconds and is impossible to remove otherwise; extremely griefable, do not allow (it's just some ugly rainbow smoke anyway, nothing of value is lost) 
//https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx.cpp#L755
--[[list.Set("PartCtrl_UtilFx", "Smoke", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = -1, //whatever you do, don't repeat this
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Angles, Entity, Attachment")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetAngles(self:CPointPosAng(0).ang)

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)

		ed:SetAttachment(self.ParticleInfo[0].attach) //note: doesn't properly follow the entity unless an attachment is set
		return true
	end
})]]

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx.cpp#L490
list.Set("PartCtrl_UtilFx", "MuzzleFlash", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.1,
	info = needs_attachment_1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Angles, Entity, Attachment")
		//flag definitions from here: https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/shareddefs.h#L298
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Flags", "axis", {
			["axis"] = 0, //x
			["label"] = "Muzzleflash Type",
			["default"] = 2,
			["dropdown"] = {
				//[0] = "MUZZLEFLASH_AR2", //does nothing, prints error in console
				[1] = "MUZZLEFLASH_SHOTGUN",
				[2] = "MUZZLEFLASH_SMG1",
				//[3] = "MUZZLEFLASH_SMG2", //identical to pistol
				[4] = "MUZZLEFLASH_PISTOL", 
				[5] = "MUZZLEFLASH_COMBINE",
				[6] = "MUZZLEFLASH_357",
				[7] = "MUZZLEFLASH_RPG",
				//[8] = "MUZZLEFLASH_COMBINE_TURRET", //does nothing, prints error in console
			},
		})
		//looks bad, renders in front of everything and gets skewed wildly by the camera angle
		--[[PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Flags", "axis", {
			["axis"] = 1, //y
			["default"] = 0,
			["checkboxes"] = {
				[256] = "MUZZLEFLASH_FIRSTPERSON",
			},
		})]]
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		if !ent:GetAttachment(1) then return end //if the ent doesn't have a valid attachment 1, but we play this effect anyway, it can appear on the model being used by another utileffect, and we don't want that

		//origin and angles are stored by the effect func, but not actually used; still requires an attachment instead (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/c_te_legacytempents.cpp#L1804)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetAngles(self:CPointPosAng(0).ang)

		ed:SetAttachment(self.ParticleInfo[0].attach) //not actually used, always uses attachment 1; leave this and origin/angles anyway just in case custom muzzleflash mods use them or something
		ed:SetFlags(self.ParticleInfo[1].val.x) //+ self.ParticleInfo[1].val.y)
		//npc_turret_ground and func_tank code set scale to 1, but it isn't actually used anywhere by the effect code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/npc_turret_ground.cpp#L554, https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/func_tank.cpp#L2174)
		return true
	end
})

//griefable, creates clientside models that last forever in singleplayer and 30 secs in multiplayer, which have no way to clean up - clientside ents.GetAll() can't even find them 
//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/c_stickybolt.cpp#L137-L145
--[[list.Set("PartCtrl_UtilFx", "BoltImpact", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = -1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		return true
	end
})]]

//actually, this one seems both exploitable and very useless otherwise, so don't include it
--[[//makes a barely noticeable yellow flash sprite and makes a loud metal sound; not a very useful effect and the sound might be griefable, but we've got other sound-playing ones too so whatever
//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/c_smoke_trail.cpp#L1127
list.Set("PartCtrl_UtilFx", "RPGShotDown", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		return true
	end
})]]

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/c_impact_effects.cpp#L614
list.Set("PartCtrl_UtilFx", "GlassImpact", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/hl2mp/weapon_stunstick.cpp#L900
list.Set("PartCtrl_UtilFx", "StunstickImpact", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		return true
	end
})

//Gravity gun beam; code says it only works at all if its entity is a weapon, and even then it only seems to work on weapon_physcannon but not weapon_shotgun or SWEPs (do they use something other 
//than C_BaseCombatWeapon?), also the beam only works if the weapon is being held by the local player (i.e. pick up a gravity gun you attached it to). No one is going to use this.
//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/hl2mp/weapon_physcannon.cpp#L3683
--[[list.Set("PartCtrl_UtilFx", "PhyscannonImpact", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	info = needs_attachment_1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Origin")
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetOrigin(self:CPointPosAng(1).pos)
		return true
	end
})]]

//dynamic light only, hunter uses a pcf for the actual visuals (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/episodic/npc_hunter.cpp#L5965, https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/fx_hl2_tracers.cpp#L695)
list.Set("PartCtrl_UtilFx", "HunterMuzzleFlash", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.1, //hunter fire rate
	info = needs_attachment .. ";\nDynamic light only, no particles",
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity, Attachment")
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(self.ParticleInfo[0].attach)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/npc_combinegunship.cpp#L1760, https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/fx_hl2_tracers.cpp#L654
list.Set("PartCtrl_UtilFx", "GunshipMuzzleFlash", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.05, //gunship fire rate
	info = needs_attachment,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity, Attachment")
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(self.ParticleInfo[0].attach)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/fx_hl2_tracers.cpp#L593
list.Set("PartCtrl_UtilFx", "ChopperMuzzleFlash", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.1, //can't find the chopper fire rate but this seems close
	info = needs_attachment,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity, Attachment")
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(self.ParticleInfo[0].attach)
		//apc code sets scale 1 for this, but this isn't hooked up to anything (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/vehicle_apc.cpp#L813)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/fx_hl2_tracers.cpp#L528
list.Set("PartCtrl_UtilFx", "AirboatMuzzleFlash", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0, //needs to render every frame to look like the one on the vehicle
	info = needs_attachment,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity, Attachment")
	end,
	DoEffect = function(self, ed)
		local attach = self.ParticleInfo[0].attach
		if attach <= 0 then return end //if the ent doesn't have a valid attachment, but we play this effect anyway, it can appear on the model being used by another utileffect, and we don't want that

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(attach)
		//airboat and func_tank code set scale 1 for this, but this isn't hooked up to anything (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/vehicle_airboat.cpp#L1556, https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/func_tank.cpp#L2966)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/fx_hl2_tracers.cpp#L403
list.Set("PartCtrl_UtilFx", "AR2Impact", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.25, //lifetime value from code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/fx_hl2_tracers.cpp#L379
list.Set("PartCtrl_UtilFx", "AR2Explosion", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.75, //max lifetime value from code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Radius", "axis", {
			["axis"] = 0, //x
			["label"] = "Radius",
			["min"] = 1,
			["max"] = 1023, //has an actual maximum of 16384.999 before it overflows but let's be reasonable here
			["default"] = 175, //default is what the func_tank code uses for the HL2 suppressor (MORTAR_BLAST_RADIUS * 0.5)
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		ed:SetRadius(self.ParticleInfo[1].val.x)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/hl2/fx_hl2_tracers.cpp#L299
local tracer = {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.1,
	DoProcess = function(tab, extras)
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Start, Attachment, Entity")
		PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Velocity",
			["min"] = 1000,
			["max"] = 16384.999, //biggest value used by anything is 16000 by dropship turret so this max is actually sensible
			["default"] = extras.scale_default,
		})
		if extras.checkboxes then
			PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Flags", "axis", {
				["axis"] = 1, //y
				["default"] = 0,
				["checkboxes"] = {
					[1] = "Whiz",
					//[2] = "Use Attachment" //doesn't make any difference to this addon, because we already pass the attachment's location as the start
				},
			})
		end
	end,
	DoProcessExtras = {["scale_default"] = 8000, ["checkboxes"] = true}, //8000 is default from code
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(1).pos)
		//GetTracerOrigin https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_tracer.cpp#L63
		ed:SetStart(self:CPointPosAng(0).pos)
		ed:SetAttachment(self.ParticleInfo[0].attach)

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)

		ed:SetScale(self.ParticleInfo[2].val.x)
		ed:SetFlags(self.ParticleInfo[2].val.y) //variants without checkboxes still do this, whatever
		return true
	end
}
//this is a mess but still better than writing out a dozen mostly-identical tables
local tracer1 = table.Copy(tracer)
tracer1.cpoint_distance_overrides = {[1] = {["min"] = 129}}
list.Set("PartCtrl_UtilFx", "AR2Tracer", tracer1)
local tracer1point5 = table.Copy(tracer)
tracer1point5.cpoint_distance_overrides = {[1] = {["min"] = 257}}
list.Set("PartCtrl_UtilFx", "HelicopterTracer", tracer1point5)
local tracer2 = table.Copy(tracer)
tracer2.DoProcessExtras.scale_default = 10000
tracer2.DoProcessExtras.checkboxes = false
list.Set("PartCtrl_UtilFx", "AirboatGunTracer", tracer2)
local tracer3 = table.Copy(tracer)
tracer3.DoProcessExtras.checkboxes = false
list.Set("PartCtrl_UtilFx", "AirboatGunHeavyTracer", tracer3)
local tracer4 = table.Copy(tracer1point5)
tracer4.DoProcessExtras.checkboxes = false
tracer4.DoProcessExtras.scale_default = 6500 //https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/vehicle_jeep.cpp#L856
list.Set("PartCtrl_UtilFx", "GaussTracer", tracer4)
local tracer5 = table.Copy(tracer)
tracer5.DoProcessExtras.scale_default = 5000 //https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/episodic/npc_hunter.cpp#L5242, https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/npc_strider.cpp#L2748
list.Set("PartCtrl_UtilFx", "HunterTracer", tracer5)
local tracer5point5 = table.Copy(tracer5)
tracer5point5.cpoint_distance_overrides = {[1] = {["min"] = 257}}
list.Set("PartCtrl_UtilFx", "StriderTracer", tracer5point5)
list.Set("PartCtrl_UtilFx", "GunshipTracer", tracer1point5) //https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/npc_combinegunship.cpp#L2814
//list.Set("PartCtrl_UtilFx", "TracerSound", tracer) //only the sound, not really this addon's purpose
list.Set("PartCtrl_UtilFx", "Tracer", tracer5point5) //https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_tracer.cpp#L112
//this is an interesting one. it's basically just a convenience function to create a pcf effect in the same way as the utilfx tracers, whiz and attachment handling included. 
//uses the effectData's "HitBox" value to store the internal id number of the pcf effect. not useful in this addon, so don't include it. https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_tracer.cpp#L154
//list.Set("PartCtrl_UtilFx", "ParticleTracer", tracer)

//the impact effects; these are complicated and all share the same code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/fx_hl2_impacts.cpp#L240, https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx_impact.cpp#L431)
//Note that ImpactGauss and ImpactJeep have EXACTLY the same code, and the only difference they have from Impact is a scale value of 2 instead of 1; ImpactGunship is like those but scale 3 and doesn't 
//play impact sounds if object is destroyed.
//AirboatGunImpact and HelicopterImpact don't make decals or hit ragdolls (note: this doesn't seem to actually be true), and play their own extra fx; only difference between them, aside from Xbox stuff, is that Airboat doesn't do material-based 
//impact particles, while HelicopterImpact does on metal/computer only, and Airboat doesn't play impact sounds unless it destroyed something, which isn't applicable here
local impact = {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	info = "Control point 1 sets the model to play the impact effect on; uses the world if unattached.\nControl point 0 draws a line to 1, and plays the effect where the line hits the model.",
	info_sfx = "Control point 0 draws a line to 1, and plays the effect at the point of impact.", //special fx have functionality to override what entity the impact effect uses, so omit the part about cpoint 1 setting it.
	DoProcess = function(tab, extras)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Start")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Origin, Entity")

		if extras.surfaceprop then
			local options = {}
			for i = 0, 255 do
				local name = util.GetSurfacePropName(i)
				if name != "" then
					options[i] = name
				end
			end
			PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect SurfaceProp", "axis", {
				["axis"] = 0, //x
				["label"] = "Surface Properties",
				["default"] = 0,
				["dropdown"] = options,
			})
		end
		if extras.toggleable_decals then
			PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Flags", "axis", {
				["axis"] = 1, //y
				["default"] = 0,
				["checkboxes"] = {
					[1] = "No decals",
					//[2] = "Report ragdoll impacts" //doesn't seem to do anything, at least in the context we're using it; refers to clientside ragdolls, but the impact still hits them whether the flag is set or not
				},
			})
		end
		local options = {
			[DMG_BLAST] = "DMG_BLAST (more knockback to client ragdolls)" //https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/c_baseanimating.cpp#L395
		}
		if extras.has_decals then options[DMG_SLASH] = "DMG_SLASH (use unique decal)" end //https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/baseentity_shared.cpp#L708
		PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect DamageType", "axis", {
			["axis"] = 2, //z
			["default"] = 0,
			["checkboxes"] = options,
		})
	end,
	DoProcessExtras = {["toggleable_decals"] = true, ["has_decals"] = true, ["surfaceprop"] = true},
	DoEffect = function(self, ed)
		ed:SetStart(self:CPointPosAng(0).pos)
		ed:SetOrigin(self:CPointPosAng(1).pos)

		local ent = self.ParticleInfo[1].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		//special functionality for impact fx: set effect entity to world if unattached, or to the entity that a trace effect hit
		if ent.PartCtrl_Grip then
			ent = game.GetWorld()
		end
		ed:SetEntity(ent.PartCtrl_TraceHit or ent)

		//trace effects also use the surfaceprop that the trace hit, unless we manually change it from the default
		local sp = self.ParticleInfo[2].val.x
		if ent.PartCtrl_SurfaceProp and sp == 0 then
			sp = ent.PartCtrl_SurfaceProp
		end
		ed:SetSurfaceProp(sp)
		ed:SetFlags(self.ParticleInfo[2].val.y)
		ed:SetDamageType(self.ParticleInfo[2].val.z)
		ed:SetHitBox(0) //not necessary for us to add a selector for, but reset it to prevent bugs (this is the func that uses it: https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_impact.cpp#L101)
		return true
	end
}
local impact_noflags = table.Copy(impact)
impact_noflags.DoProcessExtras.toggleable_decals = false
list.Set("PartCtrl_UtilFx", "Impact", impact_noflags)
impact.info = impact.info .. "\nIdentical to Impact, except decals can be disabled."
impact.info_sfx = impact.info_sfx .. "\nIdentical to Impact, except decals can be disabled."
list.Set("PartCtrl_UtilFx", "Impact_GMOD", impact)
local impact_noflags2 = table.Copy(impact_noflags)
impact_noflags2.info = impact_noflags2.info .. "\nIdentical to Impact, except particles have 2x scale."
impact_noflags2.info_sfx = impact_noflags2.info_sfx .. "\nIdentical to Impact, except particles have 2x scale."
list.Set("PartCtrl_UtilFx", "ImpactGauss", impact_noflags2)
list.Set("PartCtrl_UtilFx", "ImpactJeep", impact_noflags2)
local impact_noflags3 = table.Copy(impact_noflags)
impact_noflags3.info = impact_noflags3.info .. "\nIdentical to Impact, except particles have 3x scale."
impact_noflags3.info_sfx = impact_noflags3.info_sfx .. "\nIdentical to Impact, except particles have 3x scale."
list.Set("PartCtrl_UtilFx", "ImpactGunship", impact_noflags3)
local impact_nodecals = table.Copy(impact_noflags)
impact_nodecals.DoProcessExtras.has_decals = false
impact_nodecals.info = impact_noflags3.info .. "\nNo decals; doesn't do material-specific particle effects except on metal or computer."
impact_nodecals.info_sfx = impact_noflags3.info_sfx .. "\nNo decals; doesn't do material-specific particle effects except on metal or computer."
list.Set("PartCtrl_UtilFx", "HelicopterImpact", impact_nodecals)
local impact_nodecals_nosurfaceprop = table.Copy(impact_nodecals)
impact_nodecals_nosurfaceprop.DoProcessExtras.surfaceprop = false
impact_nodecals_nosurfaceprop.info = impact_noflags.info .. "\nNo decals, no material-specific particle effects, no sounds."
impact_nodecals_nosurfaceprop.info_sfx = impact_noflags.info_sfx .. "\nNo decals, no material-specific particle effects, no sounds."
list.Set("PartCtrl_UtilFx", "AirboatGunImpact", impact_nodecals_nosurfaceprop)
--[[list.Set("PartCtrl_UtilFx", "AirboatGunImpact", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Start, Origin, Entity")
	end,
	DoEffect = function (self, ed)
		ed:SetStart(self:CPointPosAng(0).pos + (self:CPointPosAng(0).ang:Forward() * 10))
		ed:SetOrigin(self:CPointPosAng(0).pos)

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		return true
	end
})]] //test; usable this way, but worse; not angled correctly because it uses the grip's hitbox i think

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/fx_antlion.cpp#L334
list.Set("PartCtrl_UtilFx", "AntlionGib", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	//default_time = 0.75, //max effect lifetime from code
	default_time = 3, //gib lifetime from code (2) + 1 sec fadeout time
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Gib Velocity Scale",
			["min"] = 0,
			["max"] = 10, //max of 10 because these are really strong units and even 10 sends the gibs flying super far
			["default"] = 4, //default from the only code i could find that uses this effect (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/npc_vortigaunt_episodic.cpp#L921)
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		ed:SetScale(self.ParticleInfo[1].val.x)
		return true
	end
})
//This effect only creates gibs if the client has precached the models (i.e. by spawning an antlion), it does not do so on its own, so precache them here instead.
for _, model in pairs ({
	"models/gibs/antlion_gib_large_1.mdl",
	"models/gibs/antlion_gib_large_2.mdl",
	"models/gibs/antlion_gib_large_3.mdl",
	"models/gibs/antlion_gib_medium_1.mdl",
	"models/gibs/antlion_gib_medium_2.mdl",
	"models/gibs/antlion_gib_medium_3.mdl",
	"models/gibs/antlion_gib_small_1.mdl",
	"models/gibs/antlion_gib_small_2.mdl",
	"models/gibs/antlion_gib_small_3.mdl"
}) do
	util.PrecacheModel(model)
end

//https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/client/hl2/c_weapon_crossbow.cpp#L159
list.Set("PartCtrl_UtilFx", "CrossbowLoad", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	info = needs_attachment,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity, Attachment")
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(self.ParticleInfo[0].attach)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/episodic/c_vort_charge_token.cpp#L481
list.Set("PartCtrl_UtilFx", "VortDispel", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1.25, //lifetime from code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/c_thumper_dust.cpp#L170
list.Set("PartCtrl_UtilFx", "ThumperDust", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1.5, //lifetime from code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Scale",
			["min"] = 1,
			["max"] = 4096, //arbitrary cap, could theoretically go up to 16384.999 but don't want it to be too hard to pick an actually reasonable value
			["default"] = 256,
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		//effect also allows us to set an entity, but what that does is limit the effect's renderbounds to the entity's renderbounds; we don't want this
		ed:SetScale(self.ParticleInfo[1].val.x)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/c_strider.cpp#L1047
list.Set("PartCtrl_UtilFx", "StriderBlood", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1, //lifetime from code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Scale",
			["min"] = 0,
			["max"] = 16, //arbitrary cap, again, this is uncapped, but even 16 is pushing it on being reasonable, it's bigger than the flatgrass building
			["default"] = 2, //default from magnusson, the only thing that uses this (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/episodic/weapon_striderbuster.cpp#L554)
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		ed:SetScale(self.ParticleInfo[1].val.x)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/c_strider.cpp#L949
list.Set("PartCtrl_UtilFx", "StriderMuzzleFlash", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.4, //max lifetime from code
	info = needs_attachment,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity, Attachment")
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(self.ParticleInfo[0].attach)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/c_prop_combine_ball.cpp#L340
list.Set("PartCtrl_UtilFx", "cball_explode", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/c_prop_combine_ball.cpp#L326
list.Set("PartCtrl_UtilFx", "cball_bounce", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Radius", "axis", {
			["axis"] = 0, //x
			["label"] = "Radius",
			["min"] = 0,
			["max"] = 256, //arbitrary cap
			["default"] = 16, //default from the only code that uses this https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/prop_combine_ball.cpp#L1322
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		ed:SetRadius(self.ParticleInfo[1].val.x)
		return true
	end
})

if IsMounted("hl1") then //these two fx have error models or textures if hl1 is unmounted, so make them require it; the other hl1 fx work either way, so they don't need this check
	//https://github.com/nillerusr/source-engine/blob/master/game/client/hl1/hl1_fx_shelleject.cpp#L21
	list.Set("PartCtrl_UtilFx", "HL1ShellEject", {
		title = "Half-Life: Source",
		default_time = 1,
		DoProcess = function(tab)
			PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Angles")
			PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Start", "vector", {
				["label"] = "Velocity",
				["min"] = Vector(-512,-512,-512),
				["max"] = Vector(512,512,512),
				["default"] = Vector(0,-65,137.5), //average velocity from hgrunt/assassin code (https://github.com/nillerusr/source-engine/blob/master/game/server/hl1/hl1_npc_hgrunt.cpp#L1235 / https://github.com/nillerusr/source-engine/blob/master/game/server/hl1/hl1_npc_hassassin.cpp#L601), which is also fairly close to the average velocity from hl1 weapon code (https://github.com/nillerusr/source-engine/blob/master/game/shared/hl1/hl1mp_basecombatweapon_shared.cpp#L75)
			})
			PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Flags", "axis", {
				["axis"] = 0, //x
				["label"] = "Shell Type",
				["default"] = 0,
				["dropdown"] = {
					[0] = "9mm shell",
					[1] = "Shotgun shell",
				},
			})
		end,
		DoEffect = function(self, ed)
			ed:SetOrigin(self:CPointPosAng(0).pos)
			local ang = self:CPointPosAng(0).ang
			ed:SetAngles(ang)
			//the velocity value this takes is relative to the world, not an attachment, so translate it
			local val = LocalToWorld(self.ParticleInfo[1].val, angle_zero, vector_origin, ang)
			ed:SetStart(val)
			ed:SetFlags(self.ParticleInfo[2].val.x)
			return true
		end
	})

	//https://github.com/nillerusr/source-engine/blob/master/game/client/hl1/hl1_fx_gibs.cpp#L306
	list.Set("PartCtrl_UtilFx", "HL1Gib", {
		title = "Half-Life: Source",
		default_time = 10,
		DoProcess = function(tab)
			PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
			PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect MaterialIndex", "axis", {
				["axis"] = 0, //x
				["label"] = "Gib Type",
				["default"] = 1,
				["dropdown"] = {
					[1] = "Human gibs",
					[2] = "Alien gibs",
				},
			})
			PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect HitBox", "axis", {
				["axis"] = 1, //y
				["label"] = "Gib Velocity",
				["default"] = 0,
				["dropdown"] = { //https://github.com/nillerusr/source-engine/blob/master/game/client/hl1/hl1_fx_gibs.cpp#L190-L201
					[0] = "70%",
					[50] = "200%",
					[200] = "400%",
				},
			})
			PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Color", "axis", {
				["axis"] = 2, //z
				["label"] = "Particle Color",
				["default"] = 0,
				["dropdown"] = { //https://github.com/nillerusr/source-engine/blob/master/game/client/hl1/hl1_fx_gibs.cpp#L25
					[0] = "Red",
					[1] = "\"Green\"",
					[2] = "Yellow",
				},
			})
		end,
		DoEffect = function(self, ed)
			ed:SetOrigin(self:CPointPosAng(0).pos)
			ed:SetNormal(self:CPointPosAng(0).ang:Forward())
			//callback function supplies a Scale value, and the effect function itself has an arg for it, but the value isn't actually used anywhere
			ed:SetMaterialIndex(self.ParticleInfo[1].val.x)
			ed:SetHitBox(self.ParticleInfo[1].val.y)
			ed:SetColor(self.ParticleInfo[1].val.z)
			return true
		end
	})
	util.PrecacheModel("models/gibs/hghl1.mdl")
	util.PrecacheModel("models/gibs/aghl1.mdl")
end

//https://github.com/nillerusr/source-engine/blob/master/game/client/hl1/hl1_fx_gauss.cpp#L215
list.Set("PartCtrl_UtilFx", "HL1GaussWallImpact1", {
	title = "Half-Life: Source",
	default_time = 7, //sprite lifetime from code, + 1 for fadeout
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Magnitude", "axis", {
			["axis"] = 0, //x
			["label"] = "Alpha",
			["min"] = 0,
			["max"] = 255, //this uses the "damage" value of the gauss beam, which is from 1-200, but it still functions up to 255 https://github.com/nillerusr/source-engine/blob/master/game/shared/hl1/hl1mp_weapon_gauss.cpp#L521
			["default"] = 200,
			["decimals"] = 0,
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetMagnitude(self.ParticleInfo[1].val.x)
		return true
	end
})

//https://github.com/nillerusr/source-engine/blob/master/game/client/hl1/hl1_fx_gauss.cpp#L225
list.Set("PartCtrl_UtilFx", "HL1GaussWallImpact2", {
	title = "Half-Life: Source",
	default_time = 5, //rough average lifetime, can't figure out how this is determined in code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		return true
	end
})

//https://github.com/nillerusr/source-engine/blob/master/game/client/hl1/hl1_fx_gauss.cpp#L186
list.Set("PartCtrl_UtilFx", "HL1GaussWallPunchEnter", {
	title = "Half-Life: Source",
	default_time = 5, //rough average lifetime, can't figure out how this is determined in code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		return true
	end
})

//https://github.com/nillerusr/source-engine/blob/master/game/client/hl1/hl1_fx_gauss.cpp#L199
list.Set("PartCtrl_UtilFx", "HL1GaussWallPunchExit", {
	title = "Half-Life: Source",
	default_time = 7, //impact sprite lifetime from code, + 1 for fadeout
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Magnitude", "axis", {
			["axis"] = 0, //x
			["label"] = "Alpha, Spark Count Multiplier",
			["min"] = 0,
			["max"] = 255/1.2, //again, this uses the gauss damage value, but the alpha for the impact sprite uses magnitude*1.2, so we have to cap this at 255/1.2 so the alpha won't overflow and glitch out
			["default"] = 200,
			["decimals"] = 0,
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		ed:SetMagnitude(self.ParticleInfo[1].val.x)
		return true
	end
})

//https://github.com/nillerusr/source-engine/blob/master/game/client/hl1/hl1_fx_gauss.cpp#L170
list.Set("PartCtrl_UtilFx", "HL1GaussReflect", {
	title = "Half-Life: Source",
	default_time = 6, //sprite lifetime at default magnitude (see comments) + 1 for fadeout
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Magnitude", "axis", {
			["axis"] = 0, //x
			["label"] = "Alpha, Lifetime Multiplier", //still uses the damage value for alpha, but also controls the lifetime of the sprite (flMagnitude * 0.05) 
			["min"] = 0,
			["max"] = 255,
			["default"] = 100, //for this effect, gauss code scales the damage by the angle of the reflect, and the highest possible scalar for a reflect is 0.5 https://github.com/nillerusr/source-engine/blob/master/game/shared/hl1/hl1mp_weapon_gauss.cpp#L485-L506
			["decimals"] = 0,
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		ed:SetMagnitude(self.ParticleInfo[1].val.x)
		return true
	end
})

//https://github.com/nillerusr/source-engine/blob/master/game/client/hl1/hl1_fx_gauss.cpp#L117
list.Set("PartCtrl_UtilFx", "HL1GaussBeamReflect", {
	title = "Half-Life: Source",
	default_time = 0.11, //lifetime from code, plus an extra 100th of a second just to make it clear that this is a tracer and not a continuous beam
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Start")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Flags", "axis", {
			["axis"] = 0, //x
			["label"] = "Beam Type",
			["default"] = 1,
			["dropdown"] = {
				[0] = "Secondary fire",
				[1] = "Primary fire",
			},
		})
	end,
	DoEffect = function(self, ed)
		ed:SetStart(self:CPointPosAng(0).pos)
		ed:SetOrigin(self:CPointPosAng(1).pos)
		ed:SetFlags(self.ParticleInfo[2].val.x)
		return true
	end
})

//Hard-coded to only function if attached to a player, and automatically attaches to cpoint 1 of their weapon. Looks identical to HL1GaussBeamReflect except the start of the beam
//follows the attachment. I think we'll do without this one.
//https://github.com/nillerusr/source-engine/blob/master/game/client/hl1/hl1_fx_gauss.cpp#L35
--[[list.Set("PartCtrl_UtilFx", "HL1GaussBeam", {
	title = "Half-Life: Source",
	default_time = 0.11, //lifetime from code, plus an extra 100th of a second just to make it clear that this is a tracer and not a continuous beam
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Start, Entity")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Flags", "axis", {
			["axis"] = 0, //x
			["label"] = "Beam Type",
			["default"] = 1,
			["dropdown"] = {
				[0] = "Secondary fire",
				[1] = "Primary fire",
			},
		})
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		//ed:SetAttachment(self.ParticleInfo[0].attach)
		ed:SetStart(self:CPointPosAng(0).pos)
		ed:SetOrigin(self:CPointPosAng(1).pos)
		ed:SetFlags(self.ParticleInfo[2].val.x)
		return true
	end
})]]

//No code for this one; the only utileffect not listed on https://wiki.facepunch.com/gmod/Default_Effects, found it by checking the effects_list concommand
//Appears identical to HL1GaussBeamReflect, doesn't even have the special follow-the-attachment-point functionality of the regular HL1GaussBeam.
list.Set("PartCtrl_UtilFx", "HL1GaussBeam_GMOD", {
	title = "Half-Life: Source",
	default_time = 0.11, //lifetime from code, plus an extra 100th of a second just to make it clear that this is a tracer and not a continuous beam
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Start")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Flags", "axis", {
			["axis"] = 0, //x
			["label"] = "Beam Type",
			["default"] = 1,
			["dropdown"] = {
				[0] = "Secondary fire",
				[1] = "Primary fire",
			},
		})
	end,
	DoEffect = function(self, ed)
		//not documented, but setting entity or attachment doesn't appear to do anything
		--[[local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(self.ParticleInfo[0].attach)]]
		ed:SetStart(self:CPointPosAng(0).pos)
		ed:SetOrigin(self:CPointPosAng(1).pos)
		ed:SetFlags(self.ParticleInfo[2].val.x)
		return true
	end
})

//https://github.com/mastercomfig/tf2-patches/blob/master/src/game/client/cstrike/fx_cs_weaponfx.cpp#L16
local cstrikeshells = {
	title = "Counter-Strike: Source",
	default_time = 1, //arbitrary; these take 10 whole seconds to fade out which is too much
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Angles")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Flags", "axis", {
			["axis"] = 0, //x
			["label"] = "Velocity",
			["min"] = 0,
			["max"] = 1000, //past 1000 or so, they're moving too fast to be perceptible, so that's a good arbitrary stopping point
			["default"] = 100,
			["decimals"] = 0,
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetAngles(self:CPointPosAng(0).ang)
		ed:SetFlags(self.ParticleInfo[1].val.x)
		return true
	end
}
//this effect isn't called in code, but rather in model .qc files; if you search for an effect name + .qc on github, you'll see the velocity values they use are all over the place:
///EjectBrass_338Mag 70 80
//EjectBrass_762Nato 75 150 90 100 40 80
//EjectBrass_556 150 130 125 90 105 85 75 80
//EjectBrass_57 100
//EjectBrass_12Gauge 70 95 90 
//EjectBrass_9mm 100 65 75 90
list.Set("PartCtrl_UtilFx", "EjectBrass_338Mag", cstrikeshells)
list.Set("PartCtrl_UtilFx", "EjectBrass_762Nato", cstrikeshells)
list.Set("PartCtrl_UtilFx", "EjectBrass_556", cstrikeshells)
list.Set("PartCtrl_UtilFx", "EjectBrass_57", cstrikeshells)
list.Set("PartCtrl_UtilFx", "EjectBrass_12Gauge", cstrikeshells)
list.Set("PartCtrl_UtilFx", "EjectBrass_9mm", cstrikeshells)

//https://github.com/GEEKiDoS/cstrike-asw/blob/master/src/game/client/cstrike/fx_cs_muzzleflash.cpp#L95C6-L95C29
list.Set("PartCtrl_UtilFx", "CS_MuzzleFlash_X", {
	title = "Counter-Strike: Source",
	default_time = 0.08, //lifetime value from code
	info = needs_attachment,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity, Attachment")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Scale",
			["min"] = 0,
			["max"] = 38, //starts to overflow and go back to being small once you get to 40 or so, not sure what's going on here in code
			["default"] = 1.5, //this effect is called by weapon scripts, and the scales they use are all over the place, so use a rough average for default (1.6, 1.5, 1.3, 1.2) (https://github.com/search?q=CS_MuzzleFlash_X+language%3AText&type=code&l=Text)
		})
	end,
	DoEffect = function(self, ed)
		local attach = self.ParticleInfo[0].attach
		if attach <= 0 then return end //if the ent doesn't have a valid attachment, but we play this effect anyway, it can appear on the model being used by another utileffect, and we don't want that

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(attach)
		ed:SetScale(self.ParticleInfo[1].val.x)
		return true
	end
})

//https://github.com/GEEKiDoS/cstrike-asw/blob/master/src/game/client/cstrike/fx_cs_muzzleflash.cpp#L22
list.Set("PartCtrl_UtilFx", "CS_MuzzleFlash", {
	title = "Counter-Strike: Source",
	default_time = 0.08, //lifetime value from code
	info = needs_attachment,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity, Attachment")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Scale",
			["min"] = 0,
			["max"] = 85, //different max before it overflows
			["default"] = 1, //different values used by weapon scripts, so different default (1, 1.35, 1.3, 1.2, 1.1, 1.15) (https://github.com/search?q=CS_MuzzleFlash+language%3AText&type=code)
		})
	end,
	DoEffect = function(self, ed)
		local attach = self.ParticleInfo[0].attach
		if attach <= 0 then return end //if the ent doesn't have a valid attachment, but we play this effect anyway, it can appear on the model being used by another utileffect, and we don't want that

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(attach)
		ed:SetScale(self.ParticleInfo[1].val.x)
		return true
	end
})

//Can't find any code registering this effect or giving it a callback function, might be a garry creation. Is it an implmentation of this? It's the only name that matches. https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx.cpp#L185
//Or maybe this? https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/EffectsClient.cpp#L160
list.Set("PartCtrl_UtilFx", "MuzzleEffect", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.1, //lifetime from code?
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Angles")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Scale",
			["min"] = 0,
			["max"] = 16, //past this point or so, the sprites stop getting bigger and just spread out more, this max is already pushing it
			["default"] = 1,
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetAngles(self:CPointPosAng(0).ang)
		ed:SetScale(self.ParticleInfo[1].val.x)
		//without documentation of the callback func, had to try setting other values manually (flags, color, start, normal) to see if they're hooked up to something like FX_MuzzleEffect's color arg or CEffectsClient::MuzzleFlash's type arg, but none of these do anything useful
		return true
	end
})

//another one without a callback func i can find, is it this? //https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_sparks.cpp#L620
list.Set("PartCtrl_UtilFx", "MetalSpark", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.1, //lifetime from code?
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		//tested SetScale, SetMagnitude, SetRadius, they don't do anything; if that's the correct func then it seems the scale arg isn't hooked up
		return true
	end
})

//another one without a callback func, might be this (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_sparks.cpp#L300)
list.Set("PartCtrl_UtilFx", "ElectricSpark", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Trail Length",
			["min"] = 0,
			["max"] = 10, //reasonable limit of what looks good, and even this is pushing it
			["default"] = 1,
		})
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Magnitude", "axis", {
			["axis"] = 1, //y
			["label"] = "Spark Count, Lifetime Multiplier",
			["min"] = 0,
			["max"] = 4, //because this is also a lifetime multiplier (and the default lifetime of some sparks is multiple secs), if this goes too high, it can easily hit an internal limit that makes particles stop spawning entirely, so cap it at the max value used in code (combine ball). if players want more sparks, then they can spawn more effects. https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/hl2/c_prop_combine_ball.cpp#L337
			["default"] = 1,
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		ed:SetScale(self.ParticleInfo[1].val.x)
		ed:SetMagnitude(self.ParticleInfo[1].val.y)
		return true
	end
})

//another without a callback func, might be this (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_sparks.cpp#L722)
list.Set("PartCtrl_UtilFx", "Sparks", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Trail Length",
			["min"] = 0,
			["max"] = 32, //unlike ElectricSpark, this effect has a radius scalar, so it can actually still look good at higher values
			["default"] = 1,
		})
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Magnitude", "axis", {
			["axis"] = 1, //y
			["label"] = "Spark Count, Lifetime Multiplier",
			["min"] = 0,
			["max"] = 4, //see previous effect
			["default"] = 1,
		})
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Radius", "axis", {
			["axis"] = 2, //z
			["label"] = "Trail Width",
			["min"] = 0,
			["max"] = 64,
			["default"] = 6, //default from the only code i could find that uses this effect (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/hl2mp/weapon_stunstick.cpp#L897)
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		ed:SetScale(self.ParticleInfo[1].val.x)
		ed:SetMagnitude(self.ParticleInfo[1].val.y)
		ed:SetRadius(self.ParticleInfo[1].val.z)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_water.cpp#L469
list.Set("PartCtrl_UtilFx", "waterripple", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1.5, //lifetime value from code
	info = "Requires nearby water surface",
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Scale",
			["min"] = 0,
			["max"] = 256, //arbitrary max
			["default"] = 8,
		})
		--[[PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Flags", "axis", {
			["axis"] = 1, //y
			["label"] = "Fluid Type",
			["default"] = 0,
			["dropdown"] = {
				[0] = "Water",
				[1] = "Slime", //FX_WATER_IN_SLIME (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/shareddefs.h#L566)
			},
		})]]
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetScale(self.ParticleInfo[1].val.x)
		//ed:SetFlags(self.ParticleInfo[1].val.y) //some things like jeep and player code set a flag for slime instead of water, but waterripple doesn't have handling for this (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/vehicle_jeep.cpp#L670, https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/hl2_player.cpp#L3732)
		return true
	end
})

local splash = {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 2, //max lifetime from code
	info = "Ripples require nearby water surface",
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Scale",
			["min"] = 0,
			["max"] = 32, //hard-coded max for water splash (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_water.cpp#L133-L138)
			["default"] = 6, //avg default size of gunshot splash (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/ammodef.cpp#L152-L171)
		})
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Flags", "axis", {
			["axis"] = 1, //y
			["label"] = "Fluid Type",
			["default"] = 0,
			["dropdown"] = {
				[0] = "Water",
				[1] = "Slime", //FX_WATER_IN_SLIME (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/shareddefs.h#L566)
			},
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetScale(self.ParticleInfo[1].val.x)
		ed:SetFlags(self.ParticleInfo[1].val.y)
		return true
	end
}

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_water.cpp#L450
list.Set("PartCtrl_UtilFx", "gunshotsplash", splash)
//https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_water.cpp#L431
//Functionally 100% identical to gunshotsplash, but i've left them both here just in case another addon replaces them with different custom fx
list.Set("PartCtrl_UtilFx", "watersplash", splash)

local shelleject = {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 2, //max lifetime from code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/c_te_legacytempents.cpp#L1691)
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Angles, Entity")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetAngles(self:CPointPosAng(0).ang)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		return true
	end
}

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_shelleject.cpp
list.Set("PartCtrl_UtilFx", "ShotgunShellEject", shelleject)
list.Set("PartCtrl_UtilFx", "RifleShellEject", shelleject)
list.Set("PartCtrl_UtilFx", "ShellEject", shelleject)

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx_impact.cpp#L96
//Only moves client ragdolls, not really in this addon's wheelhouse
--[[list.Set("PartCtrl_UtilFx", "RagdollImpact", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1,
	info = "Draws a line between control points 0 and 1. If it hits a clientside ragdoll, pushes it.",
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Start")
		PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect DamageType", "axis", {
			["axis"] = 0, //x
			["default"] = 0,
			["checkboxes"] = {
				[DMG_BLAST] = "DMG_BLAST (more knockback to client ragdolls)" //https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/c_baseanimating.cpp#L395
			}
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(1).pos)
		ed:SetStart(self:CPointPosAng(0).pos)
		ed:SetDamageType(self.ParticleInfo[2].val.x)
		return true
	end
})]]

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx_explosion.cpp#L1418
list.Set("PartCtrl_UtilFx", "HelicopterMegaBomb", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0.4, //max lifetime value from code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx_explosion.cpp#L1314
list.Set("PartCtrl_UtilFx", "WaterSurfaceExplosion", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 2,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
		--[[PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Magnitude", "axis", {
			["axis"] = 0, //x
			["label"] = "Force",
			["min"] = 0,
			["max"] = 1280,
			["default"] = 128, //default value used by all code that creates this effect
		})
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 1, //y
			["label"] = "Scale",
			["min"] = 0,
			["max"] = 1280,
			["default"] = 128, //default value used by all code that creates this effect
		})]]
		--[[PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Flags", "axis", {
			["axis"] = 2, //z
			["default"] = 0,
			["checkboxes"] = { //https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/tempentity.h
				[tonumber("0x4")] = "No sound", //TE_EXPLFLAG_NOSOUND //works, but we always want this to be enabled
				//[tonumber("0x40")] = "No fireball", //TE_EXPLFLAG_NOFIREBALL //water explosion code looks for these, but in practice, they don't work?
				//[tonumber("0x8")] = "No particles", //TE_EXPLFLAG_NOPARTICLES //^
			}
		})]]
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 1, //y
			["default"] = 128, //default value used by all code that creates this effect
			["checkboxes"] = {
				[128] = "Water ripples",
			}
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		//ed:SetMagnitude(self.ParticleInfo[1].val.x) //magnitude and scale are hooked up, but in practice, don't seem to change the effect at all
		ed:SetScale(self.ParticleInfo[1].val.y) //only exception is that scale makes the ripple effect not show up if set to 0, so turn it into a checkbox
		//ed:SetFlags(self.ParticleInfo[1].val.z)
		ed:SetFlags(tonumber("0x4")) //TE_EXPLFLAG_NOSOUND
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx_explosion.cpp#L804
list.Set("PartCtrl_UtilFx", "Explosion", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 2,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
		--[[PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Magnitude", "axis", {
			["axis"] = 0, //x
			["label"] = "Force",
			["min"] = 0,
			["max"] = 1280,
			["default"] = 128,
		})
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 1, //y
			["label"] = "Scale",
			["min"] = 0,
			["max"] = 1280,
			["default"] = 128,
		})]]
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Flags", "axis", {
			["axis"] = 2, //z
			["default"] = 0,
			["checkboxes"] = { //https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/tempentity.h
				//[tonumber("0x1")] = "No additive", //TE_EXPLFLAG_NOADDITIVE //no visible difference
				//[tonumber("0x2")] = "No dynamic lights", //TE_EXPLFLAG_NODLIGHTS //already has no dynamic light, no effect
				//[tonumber("0x4")] = "No sound", //TE_EXPLFLAG_NOSOUND //works, but we want this to always be enabled
				[tonumber("0x8")] = "No sparks and debris", //TE_EXPLFLAG_NOPARTICLES
				//[tonumber("0x10")] = "Draw alpha", //TE_EXPLFLAG_DRAWALPHA //no visible difference
				//[tonumber("0x20")] = "Rotate", //TE_EXPLFLAG_ROTATE //no visible difference
				[tonumber("0x40")] = "No fireball", //TE_EXPLFLAG_NOFIREBALL
				[tonumber("0x80")] = "No fireball smoke", //TE_EXPLFLAG_NOFIREBALLSMOKE
			}
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		//ed:SetAngles(self:CPointPosAng(0).ang) //neither of these work, the utileffect implementation of explosions has no way to access the angle, even though internally it does have one (try firing the hl2 rpg at walls or ceilings)
		//ed:SetNormal(self:CPointPosAng(0).ang:Forward()) //^
		//test, see if we can access the explosion's angle through an associated entity; doesn't work
		--[[local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)]]
		--[[ed:SetMagnitude(self.ParticleInfo[1].val.x) //magnitude and scale are hooked up, but in practice, don't seem to change the effect at all
		ed:SetScale(self.ParticleInfo[1].val.y)]]
		ed:SetScale(1) //except the fireball stops showing up at scale 0. we already have a flag for that, so just ensure the scale is non-zero.
		ed:SetMagnitude(1) //can't consistently reproduce this, but sometimes, the explosion effect gets skewed forward (relative to the world, not rotatable) if the magnitude is high enough, so prevent that from happening
		ed:SetFlags(self.ParticleInfo[1].val.z + tonumber("0x4")) //TE_EXPLFLAG_NOSOUND
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx_blood.cpp#L591
list.Set("PartCtrl_UtilFx", "HunterDamage", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 3, //max lifetime from code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx_blood.cpp#L532
list.Set("PartCtrl_UtilFx", "BloodImpact", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = .75, //max particle lifetime in code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Color", "axis", {
			["axis"] = 0, //x
			["label"] = "Color",
			["default"] = BLOOD_COLOR_RED,
			["dropdown"] = {
				[DONT_BLEED] = "Pink",
				[BLOOD_COLOR_RED] = "Red",
				[BLOOD_COLOR_YELLOW] = "Yellow",
				[BLOOD_COLOR_GREEN] = "Green",
				[BLOOD_COLOR_MECH] = "Mech",
				[BLOOD_COLOR_ANTLION] = "Antlion",
				[BLOOD_COLOR_ZOMBIE] = "Zombie",
				[BLOOD_COLOR_ANTLION_WORKER] = "Antlion Worker",
			},
		})
		--[[PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 1, //y
			["label"] = "Scale",
			["min"] = 0,
			["max"] = 128,
			["default"] = 1, //default scale from the only code that i can find using this effect, the zombie base. that can't be right, there have to be others using this in some way. (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/npc_BaseZombie.cpp#L1169)
		})]]
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		ed:SetColor(self.ParticleInfo[1].val.x)
		//ed:SetScale(self.ParticleInfo[1].val.y) //this value is hooked up to the callback and effect funcs, but is unused
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx_blood.cpp#L490
list.Set("PartCtrl_UtilFx", "bloodspray", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1, //max particle lifetime in code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Color", "axis", {
			["axis"] = 0, //x
			["label"] = "Color",
			["default"] = BLOOD_COLOR_RED,
			["dropdown"] = {
				[DONT_BLEED] = "Pink",
				[BLOOD_COLOR_RED] = "Red",
				[BLOOD_COLOR_YELLOW] = "Yellow",
				[BLOOD_COLOR_GREEN] = "Green",
				[BLOOD_COLOR_MECH] = "Mech",
				[BLOOD_COLOR_ANTLION] = "Antlion",
				[BLOOD_COLOR_ZOMBIE] = "Zombie",
				[BLOOD_COLOR_ANTLION_WORKER] = "Antlion Worker",
			},
		})
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 1, //y
			["label"] = "Scale",
			["min"] = 0,
			["max"] = 128, //arbitrary max, this is uncapped
			["default"] = 8, //from most of the code that calls this effect (barnacle, zombie) https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/npc_barnacle.cpp#L1670, https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/npc_BaseZombie.cpp#L2281
		})
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Flags", "axis", {
			["axis"] = 2, //z
			["default"] = tonumber("0x01") + tonumber("0x02") + tonumber("0x04"),
			["checkboxes"] = { //https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/shareddefs.h#L628
				[tonumber("0x01")] = "Enable drops", //FX_BLOODSPRAY_DROPS
				[tonumber("0x02")] = "Enable gore", //FX_BLOODSPRAY_GORE
				[tonumber("0x04")] = "Enable cloud", //FX_BLOODSPRAY_CLOUD
				//there's also FX_BLOODSPRAY_ALL = 0xFF but i'm fairly sure it's just a combination of all of these, it's not mentioned in the effect code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx_blood.cpp#L76)
			}
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		ed:SetColor(self.ParticleInfo[1].val.x)
		ed:SetScale(self.ParticleInfo[1].val.y)
		ed:SetFlags(self.ParticleInfo[1].val.z)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/c_vehicle_jeep.cpp#L326
list.Set("PartCtrl_UtilFx", "WheelDust", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 0, //the code that plays this effect calls it every think; barely visible otherwise https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/fourwheelvehiclephysics.cpp#L767
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Scale",
			["min"] = 0,
			["max"] = 8, //the effect loses coherence at a scale higher than about 8, as the particles hit a size cap or something
			["default"] = 1, //in the code that calls this, this is a scale from 0-1 (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/fourwheelvehiclephysics.cpp#L699)
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())
		ed:SetScale(self.ParticleInfo[1].val.x)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/c_rope.cpp#L868
list.Set("PartCtrl_UtilFx", "ShakeRopes", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
	default_time = 1, //arbitrary
	info = "No visible particles, makes nearby ropes move",
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Radius", "axis", {
			["axis"] = 0, //x
			["label"] = "Radius",
			["min"] = 0,
			["max"] = 4096, //arbitrary
			["default"] = 1024, //1024 from chopper code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/cbasehelicopter.cpp#L361, https://github.com/ValveSoftware/source-sdk-2013/blob/masterf/mp/src/game/server/hl2/cbasehelicopter.h#L65), 1200 from strider (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/npc_strider.cpp#L4417)
		})
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Magnitude", "axis", {
			["axis"] = 1, //y
			["label"] = "Magnitude",
			["min"] = 0,
			["max"] = 1280, //arbitrary
			["default"] = 128, //128 from chopper code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/cbasehelicopter.cpp#L361), 150 from strider (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/npc_strider.cpp#L4417)
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetRadius(self.ParticleInfo[1].val.x)
		ed:SetMagnitude(self.ParticleInfo[1].val.y)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/c_particle_system.cpp#L253
//ParticleEffect is a convenience func to dispatch pcf effects through the util.Effect system, using the hitbox value to store an internal pcf effect ID; also uses some other effectdata values 
//that aren't exposed to lua like a "customcolors" table and an "offset" value. ParticleEffectStop is similar, it makes pcf effects attached to an entity stop emission.
//list.Set("PartCtrl_UtilFx", "ParticleEffect", )
//list.Set("PartCtrl_UtilFx", "ParticleEffectStop", )

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/entities/effects/dof_node.lua
//Used by gmod depth-of-field post-process - no good way to render this and then clean it up afterward, because internally this works by creating a sprite that renders forever until we run the
//DOF_Kill function and delete them all (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/postprocess/dof.lua#L40)
--[[list.Set("PartCtrl_UtilFx", "dof_node", {
	title = "Garry's Mod",
	default_time = 0,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, -1, "placeholder")
	end,
	DoEffect = function(self, ed)
		ed:SetScale(1)
		timer.Simple(0, function() DOF_Kill() end) //doesn't work, kills the effect before it has a chance to render
		return true
	end
})]]

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/entities/effects/tooltracer.lua#L4
list.Set("PartCtrl_UtilFx", "ToolTracer", {
	title = "Garry's Mod",
	default_time = 0.25, //lifetime from code
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Start, Entity, Attachment")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Origin")
	end,
	DoEffect = function(self, ed)
		ed:SetStart(self:CPointPosAng(0).pos)
		ed:SetOrigin(self:CPointPosAng(1).pos)

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(self.ParticleInfo[0].attach)
		return true
	end
})

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/effects/balloon_pop.lua
list.Set("PartCtrl_UtilFx", "balloon_pop", {
	title = "Garry's Mod",
	default_time = 3, //arbitrary; lifetime from code is 10, but this looks silly because most of the time is just spent with nearly invisible particles sitting on the ground
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Start", "vector", {
			["label"] = "Color",
			//["min"] = Vector(0,0,0),
			//["max"] = Vector(255,255,255),
			//color picker code expects outMin/Max to be 0-1
			["inMin"] = Vector(0,0,0),
			["inMax"] = Vector(255,255,255),
			["outMin"] = Vector(0,0,0),
			["outMax"] = Vector(1,1,1),
			["default"] = Vector(255,255,255), 
			["colorpicker"] = true,
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetStart(self.ParticleInfo[1].val)
		return true
	end
})

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/effects/entity_remove.lua
list.Set("PartCtrl_UtilFx", "entity_remove", {
	title = "Garry's Mod",
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity")
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		//remover tool code sets Origin as well, but remove property doesn't, and the effect code doesn't use this anywhere
		return true
	end
})

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/effects/inflator_magic.lua
list.Set("PartCtrl_UtilFx", "inflator_magic", {
	title = "Garry's Mod",
	default_time = 0, //should run continuously
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		return true
	end
})

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/effects/lasertracer.lua
list.Set("PartCtrl_UtilFx", "LaserTracer", {
	title = "Garry's Mod",
	default_time = 0.1, //arbitrary, same as hl2 tracers; like those, this effect's lifetime depends on its length
	cpoint_distance_overrides = {[1] = {["min"] = 256}},
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Start, Entity, Attachment")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Origin")
	end,
	DoEffect = function(self, ed)
		ed:SetStart(self:CPointPosAng(0).pos)
		ed:SetOrigin(self:CPointPosAng(1).pos)

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(self.ParticleInfo[0].attach)
		return true
	end
})

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/effects/phys_freeze.lua
list.Set("PartCtrl_UtilFx", "phys_freeze", {
	title = "Garry's Mod",
	default_time = 0.5,
	info = needs_model,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Entity")
	end,
	DoEffect = function(self, ed)
		//PlayerFrozeObject code sets origin, but the effect code doesn't use this, https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/init.lua#L150
		//however, we need to set it anyway, or else the effect can fail to render sometimes
		ed:SetOrigin(self:CPointPosAng(0).pos)

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		return true
	end
})

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/effects/phys_unfreeze.lua
list.Set("PartCtrl_UtilFx", "phys_unfreeze", {
	title = "Garry's Mod",
	default_time = 0.5,
	info = needs_model,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Entity")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		return true
	end
})

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/effects/propspawn.lua
list.Set("PartCtrl_UtilFx", "propspawn", {
	title = "Garry's Mod",
	default_time = 1,
	info = needs_model,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity")
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		return true
	end
})

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/effects/selection_indicator.lua
list.Set("PartCtrl_UtilFx", "selection_indicator", {
	title = "Garry's Mod",
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal, Entity")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)

		//this effect uses the Attachment value to store a physics object id for its selection_ring child to get parented to; just make this 0 (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/weapons/gmod_tool/shared.lua#L198)
		ed:SetAttachment(0)
		return true
	end
})

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/effects/selection_ring.lua
list.Set("PartCtrl_UtilFx", "selection_ring", {
	title = "Garry's Mod",
	default_time = 0.3, //max lifetime from code? or at least it's close?
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin, Normal, Entity")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetNormal(self:CPointPosAng(0).ang:Forward())

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)

		//again, this effect uses the Attachment value to store a physics object id to get parented to; just make this 0 (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/effects/selection_ring.lua#L16)
		ed:SetAttachment(0)
		return true
	end
})

//https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/effects/wheel_indicator.lua
list.Set("PartCtrl_UtilFx", "wheel_indicator", {
	title = "Garry's Mod",
	default_time = 1.25,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Scale", "axis", {
			["axis"] = 0, //x
			["label"] = "Direction",
			["default"] = 1,
			["dropdown"] = {
				[1] = "Clockwise",
				[-1] = "Counter-Clockwise"
			}
		})
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)

		ed:SetOrigin(Vector(100,0,0)) //this is the local normalized forward vector of the effect * 100; make it point forward (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/entities/gmod_wheel.lua#L176)
		ed:SetScale(self.ParticleInfo[1].val.x) //motor.Direction, which is either 1 or -1 (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/entities/gmod_wheel.lua#L169-L204)
		return true
	end
})




//Note: This function is called by PartCtrl_ReadAndProcessPCFs(), which is defined in partctrl/pcf_processing.lua

function PartCtrl_ProcessUtilFx()

	local utilfx = list.GetForEdit("PartCtrl_UtilFx", true)
	local utilfx2
	PartCtrl_UtilFxByTitle = {}

	if istable(utilfx) then
		for k, v in pairs (utilfx) do
			local name = string.lower(k) //hey, guess what, turns out utilfx are caps-agnostic internally as well!
			local t = {
				["cpoints"] = {},
				["utilfx"] = true,
				["default_time"] = v.default_time,
				["cpoint_distance_overrides"] = v.cpoint_distance_overrides,
				["nicename"] = k,
				["utilfx_doeffect"] = v.DoEffect,
			}
			if t.default_time == nil then t.default_time = 1 end
			//everything else expects the info to be a table of strings
			if v.info then t.info = {v.info} end
			if v.info_sfx then t.info_sfx = {v.info_sfx} end

			//Use the effect's DoProcess func to set up cpoints
			v.DoProcess(t, v.DoProcessExtras)

			//Set cpoint modes and "which" values
			//TODO: is there any case where we need to make these editable by modders somehow? PCFs can override these with PostProcessPCF, but that's not an option here.
			for k, v in pairs (t.cpoints) do
				if v.position then
					t.cpoints[k].mode = PARTCTRL_CPOINT_MODE_POSITION
				elseif v.vector then
					t.cpoints[k].mode = PARTCTRL_CPOINT_MODE_VECTOR
					t.cpoints[k].which = 0
					for k2, v2 in pairs (v.vector) do
						t.cpoints[k].which = k2
						break
					end
				elseif v.axis then
					t.cpoints[k].mode = PARTCTRL_CPOINT_MODE_AXIS
					for i = 0, 2 do
						t.cpoints[k]["which_" .. i] = 0
						for k2, v2 in pairs (v.axis) do
							if v2.axis == i then 
								t.cpoints[k]["which_" .. i] = k2
								break
							end
						end
					end
				end
			end

			//Add to table of all utilfx by "title" value (what game or addon folder they're placed in)
			local function addtotab(str)
				PartCtrl_UtilFxByTitle[str] = PartCtrl_UtilFxByTitle[str] or {}
				PartCtrl_UtilFxByTitle[str][name] = true
			end
			if istable(v.title) then
				for _, str in pairs (v.title) do
					addtotab(str)
				end
			elseif isstring(v.title) then
				addtotab(v.title)
			end
			//Also add it to the "All" subtable; dumb, but this is easier than cluttering up AddBrowseContentParticle to add a special case for All that loads all the subtables
			PartCtrl_UtilFxByTitle.All = PartCtrl_UtilFxByTitle.All or {}
			PartCtrl_UtilFxByTitle.All[name] = true

			utilfx2 = utilfx2 or {}
			utilfx2[name] = t
		end
	end

	//PrintTable(utilfx2)
	PartCtrl_ProcessedPCFs.UtilFx = utilfx2

end