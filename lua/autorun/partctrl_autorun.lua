//Blacklist bad .pcf files from being loaded by the addon (TODO: this is all totally outdated, check all these files, they should be fine actually)

//The actual .pcf loading is done inside of ent_partctrl.lua, because entity code always runs after autorun code -
//we want to be sure every addon that wants to add to the blacklist has the chance to do so before the .pcf files actually get read.

//cstrike
list.Add("ParticleController_BadPCFs", "achievement.pcf") //conflicts with tf2 effects
list.Add("ParticleController_BadPCFs", "fire_medium_01.pcf") //broken textures, overrides some perfectly good, non-broken effects from stock fire_01
//ep2
//list.Add("ParticleController_BadPCFs","blob.pcf") //non-functional, seems to be a test of what would later become portal2 fluid particles; TODO: pcf reading should detect that this doesn't have any usable effects and cull it automatically
list.Add("ParticleController_BadPCFs", "bonfire.pcf")  //broken, unused effects; effect names (bonfire, smoke) are really generic and might end up overriding something so let's skip this one
//ep2 has an explosion.pcf that conflicts with the tf2 one of the same name, TODO: make sure this isn't a problem
//list.Add("ParticleController_BadPCFs", "fire_ring.pcf")  //unused effects with broken textures
list.Add("ParticleController_BadPCFs", "fireflow.pcf")  //another broken effect, almost the same as the bonfire one from earlier
//list.Add("ParticleController_BadPCFs", "flamethrowertest.pcf")  //doesn't seem to work
list.Add("ParticleController_BadPCFs", "largefire.pcf")  //more broken fire, has a smoke_blackbillow effect that conflicts with tf2
list.Add("ParticleController_BadPCFs", "vistasmokev1.pcf")  //has a smoke_blackbillow effect that conflicts with tf2
//gmod
//list.Add("ParticleController_BadPCFs", "impact_fx.pcf") //this pcf isn't included in the manifest, and for good reason! almost all the effects use some outdated renderer and spew errors in the console when you try to use them.

//TODO: this is all extremely bad and we probably don't care about any of these, but we SHOULD still have a blacklist system of some kind because there are a few standout effects not listed here
//that we should get rid of, like the _unusual_parent_* series from the tf2 unusual weapon fx, which are just pointless dupes with conflicting names that clutter up searches.




//Add util fx
//Example:
--[[list.Add("PartCtrl_UtilFx", "EffectName", { //Name of the effect that util.Effect() will call
	title = "Garry's Mod",	//String; in the "Browse Particles" spawnlist, any game, addon, or legacy addon with this exact folder name will get a "Scripted Effects" subfolder containing this effect
	title = {"MyCoolAddon", "My Cool Addon: Workshop Edition"}, //Can also be a table of strings instead, just in case you want to, say, support both a legacy addon folder name and a workshop addon name
	
	default_time = 1,	//Float, default setting of "seconds between repeats" on newly spawned fx, should roughly correspond to how long it takes for the effect to "finish", defaults to 1 if absent
	info = "Text text text" //String, optional, adds extra info to the spawnicon and edit window
	on_model = {[0] = true}, //Table, optional, adds extra info to the spawnicon about which cpoints make the effect cover the whole model if attached
	min_length = 129,	//Float/int, optional, overrides how far apart the grip points will spawn; used by some tracer fx that don't render if the points are too close together

	DoProcess = function(tab, extras)
		//Function, used to set up the controls for the util effect by defining CONTROL POINTS, just like we do with PCF effects.
		//A control point can be:
		// A: a POSITION control, which spawns a grip point and uses its position value, and can also be attached to an entity to use its position or the position of one of its attachments
		// B: a VECTOR control, which has 3 sliders to set the X, Y, and Z value of the vector
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
	DoProcessExtras = {["scale_max"] = 50} //Table, optional; this sets the "extras" arg for the DoProcess func, so that multiple fx with different values can use the same function

	DoEffect = function(self, ed)
		//Function, used when we're playing the effect to set its EffectData values, usually by grabbing information from the control points we set up earlier.
		//"self" arg is the particle entity which has all the cpoint info, "ed" is the CEffectData object. https://wiki.facepunch.com/gmod/CEffectData

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

--[[list.Set("PartCtrl_UtilFx", "Spawnlist_Populator_Test", {
	//test: populate a game, workshop addon, and legacy addon, with and without existing particles
	title = {"Garry's Mod", "Half-Life: Source", "Hat Painter & Crit Glow Tools", "Animated Props", "ParticleControlOverhaul", "ukmodels", "NotARealGameOrAddon"},
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
	default_time = 0.2, //default repeat rate and beam count taken from ragdoll boogie and antlion (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/RagdollBoogie.cpp#L119, https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/server/hl2/npc_antlion.cpp#L2254)
	on_model = {[0] = true},
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
		//origin and angles are stored by the effect func, but not actually used; still requires an attachment instead (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/c_te_legacytempents.cpp#L1804)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetAngles(self:CPointPosAng(0).ang)

		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)

		ed:SetAttachment(self.ParticleInfo[0].attach) //not actually used, always uses attachment 1; leave this and origin/angles anyway just in case custom muzzleflash mods use them or something
		ed:SetFlags(self.ParticleInfo[1].val.x) //+ self.ParticleInfo[1].val.y)
		//npc_turret_ground and func_tank code set scale to 1, but it isn't actually used anywhere by the effect code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/npc_turret_ground.cpp#L554, https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/func_tank.cpp#L2174)
		return true
	end
})

//griefable, creates clientside models that last forever in singleplayer and 30 secs in multiplayer, which have no way to clean up - clientside ents.GetAll() can't even find them 
//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/c_stickybolt.cpp#L137-L145
--[[list.Set("PartCtrl_UtilFx", "BoltImpact", {
	title = "Garry's Mod",
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

//makes a barely noticeable yellow flash sprite and makes a loud metal sound; not a very useful effect and the sound might be griefable, but we've got other sound-playing ones too so whatever
//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/c_smoke_trail.cpp#L1127
list.Set("PartCtrl_UtilFx", "RPGShotDown", {
	title = "Garry's Mod",
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Origin")
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/c_impact_effects.cpp#L614
list.Set("PartCtrl_UtilFx", "GlassImpact", {
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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

//all this one's code is commented out, does literally nothing (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/hud_blood.cpp#L34)
--[[list.Set("PartCtrl_UtilFx", "HudBloodSplat", {
	title = "Garry's Mod",
	default_time = 1,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, -1, "placeholder")
	end,
	DoEffect = function(self, ed)
		return true
	end
})]]

//dynamic light only, hunter uses a pcf for the actual visuals (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/episodic/npc_hunter.cpp#L5965, https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/fx_hl2_tracers.cpp#L695)
list.Set("PartCtrl_UtilFx", "HunterMuzzleFlash", {
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
	default_time = 0, //needs to render every frame to look like the one on the vehicle
	info = needs_attachment,
	DoProcess = function(tab)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Entity, Attachment")
	end,
	DoEffect = function(self, ed)
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(self.ParticleInfo[0].attach)
		//airboat and func_tank code set scale 1 for this, but this isn't hooked up to anything (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/vehicle_airboat.cpp#L1556, https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/hl2/func_tank.cpp#L2966)
		return true
	end
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/fx_hl2_tracers.cpp#L403
list.Set("PartCtrl_UtilFx", "AR2Impact", {
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
tracer1.min_length = 129
list.Set("PartCtrl_UtilFx", "AR2Tracer", tracer1)
local tracer1point5 = table.Copy(tracer)
tracer1point5.min_length = 257
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
tracer5point5.min_length = 257
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
	title = "Garry's Mod",
	default_time = 1,
	info = "Control point 1 sets the model to play the impact effect on; uses the world if unattached.\nControl point 0 draws a line to 1, and plays an impact effect where the line hits the model.",
	DoProcess = function(tab, extras)
		PartCtrl_CPoint_AddToProcessed(tab, 0, "util.Effect Start")
		PartCtrl_CPoint_AddToProcessed(tab, 1, "util.Effect Origin, Entity")

		if extras.surfaceprop then
			local options = {}
			for i = 0, 127 do
				options[i] = util.GetSurfacePropName(i)
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
		//special functionality for impact fx: set effect entity to world if unattached
		if ent:GetClass() == "ent_partctrl_grip" then
			ent = game.GetWorld()
		end
		ed:SetEntity(ent)

		ed:SetSurfaceProp(self.ParticleInfo[2].val.x)
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
list.Set("PartCtrl_UtilFx", "Impact_GMOD", impact)
local impact_noflags2 = table.Copy(impact_noflags)
impact_noflags2.info = impact_noflags2.info .. "\nIdentical to Impact, except the particle effects have 2x scale."
list.Set("PartCtrl_UtilFx", "ImpactGauss", impact_noflags2)
list.Set("PartCtrl_UtilFx", "ImpactJeep", impact_noflags2)
local impact_noflags3 = table.Copy(impact_noflags)
impact_noflags3.info = impact_noflags3.info .. "\nIdentical to Impact, except the particle effects have 3x scale."
list.Set("PartCtrl_UtilFx", "ImpactGunship", impact_noflags3)
local impact_nodecals = table.Copy(impact_noflags)
impact_nodecals.DoProcessExtras.has_decals = false
impact_nodecals.info = impact_noflags3.info .. "\nNo decals; doesn't do material-specific particle effects except on metal or computer."
list.Set("PartCtrl_UtilFx", "HelicopterImpact", impact_nodecals)
local impact_nodecals_nosurfaceprop = table.Copy(impact_nodecals)
impact_nodecals_nosurfaceprop.DoProcessExtras.surfaceprop = false
impact_nodecals_nosurfaceprop.info = impact_noflags.info .. "\nNo decals, no material-specific particle effects, no sounds."
list.Set("PartCtrl_UtilFx", "AirboatGunImpact", impact_nodecals_nosurfaceprop)
--[[list.Set("PartCtrl_UtilFx", "AirboatGunImpact", {
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
			["default"] = Vector(0,0,0), //this is relative to the world, not an attachment, so the default will have to be 0
		})
		PartCtrl_CPoint_AddToProcessed(tab, 2, "util.Effect Flags", "axis", {
			["axis"] = 0, //x
			["label"] = "Shell Type",
			["default"] = 0,
			["dropdown"] = {
				[0] = "Shell",
				[1] = "Shotgun shell",
			},
		})
	end,
	DoEffect = function(self, ed)
		ed:SetOrigin(self:CPointPosAng(0).pos)
		ed:SetAngles(self:CPointPosAng(0).ang)
		ed:SetStart(self.ParticleInfo[1].val)
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
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(self.ParticleInfo[0].attach)
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
		local ent = self.ParticleInfo[0].ent
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		ed:SetEntity(ent)
		ed:SetAttachment(self.ParticleInfo[0].attach)
		ed:SetScale(self.ParticleInfo[1].val.x)
		return true
	end
})

//Can't find any code registering this effect or giving it a callback function, might be a garry creation. Is it an implmentation of this? It's the only name that matches. https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/fx.cpp#L185
//Or maybe this? https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/EffectsClient.cpp#L160
list.Set("PartCtrl_UtilFx", "MuzzleEffect", {
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
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
	title = "Garry's Mod",
	default_time = 1.5, //lifetime value from code
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

local SplashDoProcess = function(tab)
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
end
local SplashDoEffect = function(self, ed)
	ed:SetOrigin(self:CPointPosAng(0).pos)
	ed:SetScale(self.ParticleInfo[1].val.x)
	ed:SetFlags(self.ParticleInfo[1].val.y)
	return true
end

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_water.cpp#L450
list.Set("PartCtrl_UtilFx", "gunshotsplash", {
	title = "Garry's Mod",
	default_time = 2, //max lifetime from code
	DoProcess = SplashDoProcess,
	DoEffect = SplashDoEffect
})

//https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/client/fx_water.cpp#L431
//Functionally 100% identical to gunshotsplash, but i've left them both here just in case another addon replaces them with different custom fx
list.Set("PartCtrl_UtilFx", "watersplash", {
	title = "Garry's Mod",
	default_time = 2,
	DoProcess = SplashDoProcess,
	DoEffect = SplashDoEffect
})

//TODO: the rest, ShotgunShellEject onward https://wiki.facepunch.com/gmod/Default_Effects

































//////////////////////////
//.PCF FILE READING CODE//
//////////////////////////

//silly pretend enums, for more convenient networking mostly
PARTCTRL_CPOINT_MODE_NONE		= 0
PARTCTRL_CPOINT_MODE_MANUAL		= 1
PARTCTRL_CPOINT_MODE_POSITION		= 2
PARTCTRL_CPOINT_MODE_VECTOR		= 3
PARTCTRL_CPOINT_MODE_AXIS		= 4
PARTCTRL_CPOINT_MODE_POSITION_COMBINE	= 5
partctrl_cpointmodebits = 3
//another networking convenience
partctrl_cpointbits = 7 //-1 - 63

partctrl_wait = "wait" //another convenient global, used by particlesystems that can't currently be created (due to CrashCheck or a disabled particle entity) but should be created as soon as possible

//for vector/axis cpoints; names and comments from https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/public/particles/particles.h#L62
PARTCTRL_PARTICLE_ATTRIBUTE_XYZ = 0 // required
PARTCTRL_PARTICLE_ATTRIBUTE_LIFE_DURATION = 1 // particle lifetime (duration) of particle as a float.
PARTCTRL_PARTICLE_ATTRIBUTE_PREV_XYZ = 2 // prev coordinates for verlet integration
PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS = 3 // radius of particle
PARTCTRL_PARTICLE_ATTRIBUTE_ROTATION = 4 // rotation angle of particle
PARTCTRL_PARTICLE_ATTRIBUTE_ROTATION_SPEED = 5 // rotation speed of particle
PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB = 6 // tint of particle
PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA = 7 // alpha tint of particle
PARTCTRL_PARTICLE_ATTRIBUTE_CREATION_TIME = 8 // creation time stamp (relative to particle system creation)
PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER = 9 // sequnece # (which animation sequence number this particle uses )
PARTCTRL_PARTICLE_ATTRIBUTE_TRAIL_LENGTH = 10 // length of the trail 
PARTCTRL_PARTICLE_ATTRIBUTE_PARTICLE_ID = 11 // unique particle identifier
PARTCTRL_PARTICLE_ATTRIBUTE_YAW = 12 // unique rotation around up vector
PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1 = 13 // second sequnece # (which animation sequence number this particle uses )
PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_INDEX = 14 // hit box index //The lowest on the list that shows up in pet's attribute field is sequence number 1, so we *probably* don't need to waste another bit on the rest of these, but maybe custom particles could use these for goofy shenanigans so network them anyway.
PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_RELATIVE_XYZ = 15
PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA2 = 16
PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P0 = 17 // particle trace caching fields // start pnt of trace
PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P1 = 18 // end pnt of trace
PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_T = 19 // 0..1 if hit
PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL = 20 // 0 0 0 if no hit
local ParticleAttributeNames = { //names and comments from https://github.com/nillerusr/source-engine/blob/master/particles/particles.cpp#L3026
	[PARTCTRL_PARTICLE_ATTRIBUTE_XYZ] = "Position", // XYZ, 0
	[PARTCTRL_PARTICLE_ATTRIBUTE_LIFE_DURATION] = "Life Duration", // LIFE_DURATION, 1 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_PREV_XYZ] = "PARTICLE_ATTRIBUTE_PREV_XYZ (internal)", //NULL, // PREV_XYZ is for internal use only
	[PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS] = "Radius", // RADIUS, 3 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_ROTATION] = "Roll", // ROTATION, 4 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_ROTATION_SPEED] = "Roll Speed", // ROTATION_SPEED, 5 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB] = "Color", // TINT_RGB, 6 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA] = "Alpha", // ALPHA, 7 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_CREATION_TIME] = "Creation Time", // CREATION_TIME, 8 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER] = "Sequence Number", // SEQUENCE_NUMBER, 9 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_TRAIL_LENGTH] = "Trail Length", // TRAIL_LENGTH, 10 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_PARTICLE_ID] = "Particle ID", // PARTICLE_ID, 11 ); 
	[PARTCTRL_PARTICLE_ATTRIBUTE_YAW] = "Yaw", // YAW, 12 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1] = "Sequence Number 1", // SEQUENCE_NUMBER1, 13 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_INDEX] = "PARTICLE_ATTRIBUTE_HITBOX_INDEX (internal)", //NULL, // HITBOX_INDEX is for internal use only
	[PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_RELATIVE_XYZ] = "PARTICLE_ATTRIBUTE_HITBOX_RELATIVE_XY (internal)", //NULL, // HITBOX_XYZ_RELATIVE is for internal use only
	[PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA2] = "Alpha Alternate", // ALPHA2, 16
	[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P0] = "PARTICLE_ATTRIBUTE_TRACE_P0 (internal)",
	[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P1] = "PARTICLE_ATTRIBUTE_TRACE_P1 (internal)",
	[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_T] = "PARTICLE_ATTRIBUTE_TRACE_HIT_T (internal)",
	[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL] = "PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL (internal)"
}

//from the only good glua file parser code i could find on github; we use this to get strings (https://github.com/RaphaelIT7/gmod-lua-gma-writer/blob/master/gma.lua#L202)
local str_b0 = string.char(0)
local function ReadUntilNull(f) //TODO: during development of file reading, this could cause errors when it tried to grab a string from the wrong part of the file. is this still possible?
	local steps = 64 //arbitrary
	local pos = f:Tell()

	local file_str = ""
	local finished = false
	while !finished do
		local str = f:Read(steps)
		local found = string.find(str, str_b0)
		if found then
			str = string.sub(str, 0, found - 1)
			finished = true
		end

		file_str = file_str .. str
	end

	f:Seek(pos + string.len(file_str) + 1) -- + 1 for the Null byte we remove from the String.

	return file_str
end

local a = {}
table.insert(a, "ATTRIBUTE_ELEMENT")
table.insert(a, "ATTRIBUTE_INTEGER")
table.insert(a, "ATTRIBUTE_FLOAT")
table.insert(a, "ATTRIBUTE_BOOLEAN")
table.insert(a, "ATTRIBUTE_STRING")
table.insert(a, "ATTRIBUTE_BINARY")
table.insert(a, "ATTRIBUTE_TIME")
table.insert(a, "ATTRIBUTE_COLOR")
table.insert(a, "ATTRIBUTE_VECTOR2")
table.insert(a, "ATTRIBUTE_VECTOR3")
table.insert(a, "ATTRIBUTE_VECTOR4")
table.insert(a, "ATTRIBUTE_QANGLE")
table.insert(a, "ATTRIBUTE_QUATERNION")
table.insert(a, "ATTRIBUTE_MATRIX")
table.insert(a, "ATTRIBUTE_ELEMENT_ARRAY")
table.insert(a, "ATTRIBUTE_INTEGER_ARRAY")
table.insert(a, "ATTRIBUTE_FLOAT_ARRAY")
table.insert(a, "ATTRIBUTE_BOOLEAN_ARRAY")
table.insert(a, "ATTRIBUTE_STRING_ARRAY")
table.insert(a, "ATTRIBUTE_BINARY_ARRAY")
table.insert(a, "ATTRIBUTE_TIME_ARRAY")
table.insert(a, "ATTRIBUTE_COLOR_ARRAY")
table.insert(a, "ATTRIBUTE_VECTOR2_ARRAY")
table.insert(a, "ATTRIBUTE_VECTOR3_ARRAY")
table.insert(a, "ATTRIBUTE_VECTOR4_ARRAY")
table.insert(a, "ATTRIBUTE_QANGLE_ARRAY")
table.insert(a, "ATTRIBUTE_QUATERNION_ARRAY")
table.insert(a, "ATTRIBUTE_MATRIX_ARRAY")

//reference:
//https://developer.valvesoftware.com/wiki/PCF, https://developer.valvesoftware.com/w/index.php?title=DMX/Binary&oldid=176216#Version_3, https://developer.valvesoftware.com/wiki/DMX/Binary

function PartCtrl_ReadPCF(filename)

	local f = file.Open(filename, "rb", "GAME")
	if !f then MsgN(filename, " can't be found") return end


	local header = ReadUntilNull(f)
	//MsgN(header)
	if header != "<!-- dmx encoding binary 2 format pcf 1 -->\n" then MsgN(filename, " has bad pcf format ", string.TrimRight(header, "\n"), " instead of dmx encoding binary 2 format pcf 1, ignoring") return end //TODO: i don't think gmod reads any .pcf formats other than this, but test it anyway to make sure


	local nStrings = f:ReadUShort() //this is a short in DMX version 2 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
	local StringDict = {}
	//MsgN(filename, " nStrings = ", nStrings)
	for k = 0, nStrings - 1 do
		local v = ReadUntilNull(f)
		StringDict[k] = v
	end
	//PrintTable(StringDict)


	local nElements = f:ReadULong() //int, is ReadLong the right way to interpret this?
	//MsgN(filename, " nElements = ", nElements)

	local function DmeHeader()
		local tab = {}
		local type = f:ReadUShort() //string dictionary indices are shorts in DMX version 2 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
		tab.Type = StringDict[type]
		tab.Name = ReadUntilNull(f) //element names are in-line strings in DMX version 2 https://developer.valvesoftware.com/w/index.php?title=DMX/Binary&oldid=176216#Version_3
		//tab.GUID = f:Read(16) //GUID[16]
		f:Skip(16) //GUID[16], just skip this one
		return tab
	end
	local ElementIndex = {}
	for i = 1, nElements do
		ElementIndex[i-1] = DmeHeader()
	end
	//PrintTable(ElementIndex)


	local function DmAttribute()
		local tab = {}
		local name = f:ReadUShort() //string dictionary indices are shorts in DMX version 2 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
		//MsgN("name = ", StringDict[name])
		tab.Name = StringDict[name]
		if !tab.Name then return tab end //if we returned a bad attribute (i.e. reading a pcf file packed into a compressed tf2 map), bail out immediately so that we don't try to read more info from the file, because every time we try to read data from a bad file this way and it prints a "Warning! LZMA compression header is invalid! Extraction failed! particles\_.pcf ( ERR: 1 )" error in console, it causes the game to hang for a fairly substantial amount of time (pd_watergate can take over 5 minutes to load, just from the sheer number of compressed pcf errors, even with this check)
		//local at = math.BinToInt(f:Read(1)) or 0 //returns nil
		//local at = math.BinToInt(ReadUntilNull(f)) or 0
		local at = f:ReadByte()
		//MsgN("at ", at, " = ", a[at])
		at = a[at] or ""
		tab.AttributeType = at
		local function DoAttribute()
			//MsgN("at = ", at)
			if at == "ATTRIBUTE_ELEMENT" then
				return f:ReadLong()
			elseif at == "ATTRIBUTE_INTEGER" then
				return f:ReadLong()
			elseif at == "ATTRIBUTE_FLOAT" then
				return f:ReadFloat()
			elseif at == "ATTRIBUTE_BOOLEAN" then
				return f:ReadBool()
			elseif at == "ATTRIBUTE_STRING" then
				return ReadUntilNull(f)
			elseif at == "ATTRIBUTE_BINARY" then
				local count = f:ReadULong()
				return f:Read(count)
			elseif at == "ATTRIBUTE_TIME" then
				return f:ReadLong() / 10000 //according to https://developer.valvesoftware.com/wiki/PCF; TODO: should this be unsigned?
			elseif at == "ATTRIBUTE_COLOR" then
				return Color(string.byte(f:Read(1)), string.byte(f:Read(1)), string.byte(f:Read(1)), string.byte(f:Read(1)))
			elseif at == "ATTRIBUTE_VECTOR2" then
				return {f:ReadFloat(), f:ReadFloat()}
			elseif at == "ATTRIBUTE_VECTOR3" then
				return Vector(f:ReadFloat(), f:ReadFloat(), f:ReadFloat())
			elseif at == "ATTRIBUTE_VECTOR4" then
				return {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()}
			elseif at == "ATTRIBUTE_QANGLE" then
				return Vector(f:ReadFloat(), f:ReadFloat(), f:ReadFloat()) //"Same as ATTRIBUTE_VECTOR3" according to https://developer.valvesoftware.com/wiki/PCF
			elseif at == "ATTRIBUTE_QUATERNION" then
				return {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()} //"Same as ATTRIBUTE_VECTOR4" according to https://developer.valvesoftware.com/wiki/PCF
			elseif at == "ATTRIBUTE_MATRIX" then
				return Matrix({ {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()}, {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()},
						{f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()}, {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()} })
			elseif string.EndsWith(at, "_ARRAY") then
				at = string.Replace(at, "_ARRAY", "")
				local tab2 = {}
				local arraysize = f:ReadULong()
				if arraysize > 1000 then MsgN(filename, " got crazy array size ", arraysize, " - we screwed up file reading somewhere, report this bug!") return end
				for i = 1, arraysize do //int, is ReadLong the right way to interpret this?
					table.insert(tab2, DoAttribute())
				end
				return tab2
			end
			return 0
		end
		tab.Value = DoAttribute()
		return tab
	end
	local ElementBodies = {}
	//local halt = false
	for i = 1, nElements do
		//if halt then MsgN("halting") return end//break end //if DmAttribute returned bad results and stopped, then 
		//MsgN("Element ", i, " = ")
		local body = {}
		local attributecount = f:ReadULong()
		//MsgN("attributecount = ", attributecount)
		if !attributecount then MsgN(filename, " got no attribute count - we screwed up file reading somewhere, report this bug!") return end//break end
		if attributecount > 100 then MsgN(filename, " got crazy attribute count ", attributecount, " - we screwed up file reading somewhere, report this bug!") return end//break end
		for i = 1, attributecount do //int, is ReadLong the right way to interpret this?
			local attrib = DmAttribute()
			if !attrib.Name then MsgN(filename, " attribute ", i, " has no name value - we screwed up file reading somewhere, report this bug!") return end//halt = true break end
			table.insert(body, attrib)
		end
		//if halt then break end
		ElementBodies[i-1] = body
		//MsgN("nElement ", i, " body:")
		//PrintTable(body)
	end
	//test: version of the above that doesn't quit file reading upon encountering a bad attribute.
	//bad idea, we want to throw the whole file out, don't just stop reading here and use what we have if any of the checks above say we started returning bad info. this is because not all, but 
	//*some* packed pcf files that fail to read this way (i.e. pl_snowycoast_fx.pcf packed into pl_snowycoast) will cause an immediate crash if we try to spawn effects from them, 
	//even in spawnicons or from dupes. this crash won't have a chance to happen if we don't have a ProcessedPCFs entry for this pcf. (haven't narrowed down which function causes the crash, but
	//it doesn't happen when loading or spawning particles from a renamed copy of the same pcf, *only* with the one loaded directly from within the map file, so it doesn't seem to be related to
	//the conflicting particle name issue that can also cause crashes.)
	--[[for i = 1, nElements do
		//MsgN("Element ", i, " = ")
		local body = {}
		local attributecount = f:ReadULong() //int, is ReadLong the right way to interpret this?
		//MsgN("attributecount = ", attributecount)
		if !attributecount then MsgN(filename, " got no attribute count - we screwed up file reading somewhere, report this bug!")
		elseif attributecount > 100 then MsgN(filename, " got crazy attribute count ", attributecount, " - we screwed up file reading somewhere, report this bug!") end
		if attributecount and attributecount <= 100 then
			for i = 1, attributecount do 
				local attrib = DmAttribute()
				//if !attrib.Name then MsgN(filename, " attribute ", i, " has no name value - we screwed up file reading somewhere, report this bug!") end
				if attrib.Name then
					table.insert(body, attrib)
				end
			end
		end
		ElementBodies[i-1] = body
		//MsgN("nElement ", i, " body:")
		//PrintTable(body)
	end]]
	//PrintTable(ElementBodies)
	//MsgN("end of file = ", f:EndOfFile()) //actually returns false for ep2's blob.pcf, which doesn't matter since that one is unusable, but maybe other stuff too?
	f:Close()


	//smoosh the index and bodies into a single table
	//PrintTable(ElementIndex)
	//PrintTable(ElementBodies)
	local ElementsUnsorted = {}
	for i, index in pairs (ElementIndex) do
		//if istable(index) then
			local tab = {}
			//tab["k"] = index["Type"] .. " " .. index["Name"]
			tab["k"] = index

			local v = {}
			if !ElementBodies[i] then
				MsgN(filename, " element index ", i, " has no body - we screwed up file reading somewhere, report this bug!")
				break //note: in all the cases where this bug has happened (reading pcfs packed into compressed tf2 maps) every element after the first one with this bug will also be empty, so stop here
			else
				for i, attrib in pairs (ElementBodies[i]) do
					if attrib.AttributeType == "ATTRIBUTE_ELEMENT_ARRAY" then
						v[attrib.Name] = {
							["ElementTable"] = attrib.Value
						}
					elseif attrib.AttributeType == "ATTRIBUTE_ELEMENT" then
						v[attrib.Name] = {
							["ElementTable"] = {attrib.Value}
						}
					else
						v[attrib.Name] = attrib.Value
					end
				end
				tab["v"] = v
				ElementsUnsorted[i] = tab
			end
		//else
		//	ElementsUnsorted[i] = "nil index for some reason?"
		//end
	end
	//PrintTable(ElementsUnsorted)


	//Now sort that table into a conventional keyvalue structure
	--[[local nonParentedElements = {}
	for i = 0, nElements - 1 do
		nonParentedElements[i] = true
	end
	for i, kv in pairs (ElementsUnsorted) do
		for k2, v2 in pairs(kv.v) do
			if istable(v2) and v2.ElementTable then
				for _, element in pairs (v2.ElementTable) do
					nonParentedElements[element] = nil
				end
			end
		end
	end
	PrintTable(nonParentedElements)]]
	//Looks like in every pcf, 0 is the only unparented element, so start there to save time instead of iterating over the whole table again
	local Elements = {}
	if !ElementsUnsorted[0].v.particleSystemDefinitions or !ElementsUnsorted[0].v.particleSystemDefinitions.ElementTable then MsgN(filename, " element 0 doesn't contain a particleSystemDefinitions table, ignoring") return end
	for _, i in pairs (ElementsUnsorted[0].v.particleSystemDefinitions.ElementTable) do
		if !ElementsUnsorted[i] then
			MsgN(filename, " tried to get DmeParticleSystemDefinition from nil element ", i)
		elseif ElementsUnsorted[i].k.Type != "DmeParticleSystemDefinition" then
			MsgN(filename, " tried to get DmeParticleSystemDefinition element ", ElementsUnsorted[i].k.Name, ", but it was a ", ElementsUnsorted[i].k.Type, " element")
		else
			for k, v in pairs (ElementsUnsorted[i].v) do
				if istable(v) and v.ElementTable then
					local tab = {}
					for et_k, et_i in pairs (v.ElementTable) do
						if !ElementsUnsorted[et_i] then
							MsgN(filename, " attribute ", k, " tried to get nil element ", et_i)
						elseif ElementsUnsorted[et_i].k.Type == "DmeParticleChild" then
							if !ElementsUnsorted[et_i].v.child then
								MsgN(filename, " DmeParticleChild has no child value")
							else
								//store particle children as strings (names of the corresponding fx) to keep the table simple and avoid recursive nonsense
								for et2_k, et2_i in pairs (ElementsUnsorted[et_i].v.child.ElementTable) do
									if !ElementsUnsorted[et2_i] then
										MsgN(filename, " DmeParticleChild tried to get nil element ", et2_i)
									else
										table.insert(tab, ElementsUnsorted[et2_i].k.Name)
									end
								end
							end
						else
							//table.insert(tab, ElementsUnsorted[et_i])
							//discard key for DmeParticleOperators; the name is redundant and is also stored in the functionName attribute, and also there can be multiple with the same name
							table.insert(tab, ElementsUnsorted[et_i].v)
							//this doesn't handle recursive element tables but i don't think any particle operators have those
						end
					end
					ElementsUnsorted[i].v[k] = tab
					//v = tab
				end
			end
			Elements[ElementsUnsorted[i].k.Name] = ElementsUnsorted[i].v
		end
	end
	
	return Elements

end


//from https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/devtools/bin/fix_particle_operator_names.pl#L54
local fixes = {
	["alpha_fade"] = "Alpha Fade and Decay",
	["alpha_fade_in_random"] = "Alpha Fade In Random",
	["alpha_fade_out_random"] = "Alpha Fade Out Random",
	["basic_movement"] = "Movement Basic",
	["color_fade"] = "Color Fade",
	["controlpoint_light"] = "Color Light From Control Point",
	["Dampen Movement Relative to Control Point"] = "Movement Dampen Relative to Control Point",
	["Distance Between Control Points Scale"] = "Remap Distance Between Two Control Points to Scalar",
	["Distance to Control Points Scale"] = "Remap Distance to Control Point to Scalar",
	["lifespan_decay"] = "Lifespan Decay",
	["lock to bone"] =	"Movement Lock to Bone",
	["postion_lock_to_controlpoint"] = "Movement Lock to Control Point",
	["maintain position along path"] = "Movement Maintain Position Along Path",
	["Match Particle Velocities"] = "Movement Match Particle Velocities",
	["Max Velocity"] = "Movement Max Velocity",
	["noise"] = "Noise Scalar",
	["vector noise"] = "Noise Vector",
	["oscillate_scalar"] = "Oscillate Scalar",
	["oscillate_vector"] = "Oscillate Vector",
	["Orient Rotation to 2D Direction"] = "Rotation Orient to 2D Direction",
	["radius_scale"] = "Radius Scale",
	["Random Cull"] = "Cull Random",
	["remap_scalar"] = "Remap Scalar",
	["rotation_movement"] = "Rotation Basic",
	["rotation_spin"] = "Rotation Spin Roll",
	["rotation_spin yaw"] = "Rotation Spin Yaw",
	["alpha_random"] = "Alpha Random",
	["color_random"] = "Color Random",
	["create from parent particles"] = "Position From Parent Particles",
	["Create In Hierarchy"] = "Position In CP Hierarchy",
	["random position along path"] = "Position Along Path Random",
	["random position on model"] = "Position on Model Random",
	["sequential position along path"] = "Position Along Path Sequential",
	["position_offset_random"] = "Position Modify Offset Random",
	["position_warp_random"] = "Position Modify Warp Random",
	["position_within_box"] = "Position Within Box Random",
	["position_within_sphere"] = "Position Within Sphere Random",
	["Inherit Velocity"] = "Velocity Inherit from Control Point",
	["Initial Repulsion Velocity"] = "Velocity Repulse from World",
	["Initial Velocity Noise"] = "Velocity Noise",
	["Initial Scalar Noise"] = "Remap Noise to Scalar",
	["Lifespan from distance to world"] = "Lifetime from Time to Impact",
	["Pre-Age Noise"] = "Lifetime Pre-Age Noise",
	["lifetime_random"] = "Lifetime Random",
	["radius_random"] = "Radius Random",
	["random yaw"] = "Rotation Yaw Random",
	["Randomly Flip Yaw"] = "Rotation Yaw Flip Random",
	["rotation_random"] = "Rotation Random",
	["rotation_speed_random"] = "Rotation Speed Random",
	["sequence_random"] = "Sequence Random",
	["second_sequence_random"] = "Sequence Two Random",
	["trail_length_random"] = "Trail Length Random",
	["velocity_random"] = "Velocity Random",
}
local fixes2 = {}
for k, v in pairs (fixes) do
	fixes2[string.lower(k)] = string.lower(v)
end
fixes = fixes2
fixes2 = nil


//manually copied from gmod's own particle editor 5/13/24, necessary for development but not finished addon
--[[local default_attribs = {
	//Renderer
	"Render models", 
	"render_animated_sprites", 
	"render_rope", 
	"render_screen_velocity_rotate", 
	"render_sprite_trail", 
	//Operator
	"Alpha Fade and Decay", 
	"Alpha Fade In Random", 
	"Alpha Fade Out Random", 
	"Color Fade", 
	"Color Light from Control Point", 
	"Cull Random", 
	"Cull relative to model", 
	"Cull when crossing plane", 
	"Lifespan Decay", 
	"Lifespan Minimum Velocity Decay", 
	"Movement Basic", 
	"Movement Dampen Relative to Control Point", 
	"Movement Lock to Bone", 
	"Movement Lock to Control Point", 
	"Movement Maintain Position Along Path", 
	"Movement Match Particle Velocities", 
	"Movement Max Velocity", 
	"Movement Rotate Particle Around Axis", 
	"Noise Scalar", 
	"Noise Vector", 
	"Oscillate Scalar", 
	"Oscillate Vector", 
	"Radius Scale", 
	"Remap Control Point to Scalar", 
	"Remap CP Speed to CP", 
	"Remap Direction to CP to Vector", 
	"Remap Distance Between Two Control Points to Scalar", 
	"Remap Distance to Control Point to Scalar", 
	"Remap Dot Product to Scalar", 
	"Remap Scalar", 
	"Rotation Basic", 
	"Rotation Orient Relative to CP", 
	"Rotation Orient to 2D Direction", 
	"Rotation Spin Roll", 
	"Rotation Spin Yaw", 
	"Set child control points from particle positions", 
	"Set Control Point Positions", 
	"Set Control Point To Particles' Center", 
	"Set Control Point To Player", 
	//Initializer
	"Alpha Random", 
	"Color Lit Per Particle", 
	"Color Random", 
	"Lifetime From Sequence", 
	"Lifetime from Time to Impact", 
	"Lifetime Pre-Age Noise", 
	"Lifetime Random", 
	"Move Particles Between 2 Control Points", 
	"Position Along Epitrochoid", 
	"Position Along Path Random", 
	"Position Along Path Sequential", 
	"Position Along Ring", 
	"Position From Chaotic Attractor", 
	"Position from Parent Cache", 
	"Position From Parent Particles", 
	"Position In CP Hierarchy", 
	"Position Modify Offset Random", 
	"Position Modify Place On Ground", 
	"Position Modify Warp Random", 
	"Position on Model Random", 
	"Position Within Box Random", 
	"Position Within Sphere Random", 
	"Radius Random", 
	"Remap Control Point to Scalar", 
	"Remap Control Point to Vector", 
	"Remap Initial Distance to Control Point to Scalar", 
	"Remap Initial Scalar",
	"Remap Noise to Scalar", 
	"Remap Particle Count to Scalar", 
	"Remap Scalar to Vector", 
	"Rotation Random", 
	"Rotation Speed Random", 
	"Rotation Yaw Flip Random", 
	"Rotation Yaw Random", 
	"Scalar Random", 
	"Sequence Random", 
	"Sequence Two Random", 
	"Set Hitbox Position on Model", 
	"Set Hitbox to Closest Hitbox", 
	"Trail Length Random", 
	"Vector Component Random", 
	"Vector Random", 
	"Velocity Inherit from Control Point", 
	"Velocity Noise", 
	"Velocity Random", 
	"Velocity Repulse from World", 
	"Velocity Set from Control Point", 
	//Emitter
	"emit noise", 
	"emit_continuously", 
	"emit_instantaneously", 
	//ForceGenerator
	"Pull towards control point", 
	"random force", 
	"twist around axis", 
	//Constraint
	"Collision via traces", 
	"Constrain distance to control point", 
	"Constrain distance to path between two control points", 
	"Prevent passing through a plane", 
	"Prevent passing through static part of world", 
}
local default_attribs2 = {}
for _, k in pairs (default_attribs) do
	default_attribs2[string.lower(k)] = true
end
default_attribs = default_attribs2
default_attribs2 = nil
local allproperties = {
	["renderers"] = {},
	["operators"] = {},
	["initializers"] = {},
	["emitters"] = {},
	["forces"] = {}, //forcegenerator
	["constraints"] = {},
}
for _, filename in pairs (PartCtrl_AllPCFPaths) do
	local tab = PartCtrl_ReadPCF(filename)
	if tab then
		for particle, ptab in pairs (tab) do
			for category, _ in pairs (allproperties) do
				if ptab[category] then
					for _, attribute in pairs (ptab[category]) do
						local name = string.lower(attribute.functionName)
						if fixes[name] then name = fixes[name] end
						
						local result = allproperties[category][name] or { ["count"] = 0 }
						result.path = result.path or filename .. " " .. particle
						result.count = result.count + 1
						if !default_attribs[name] then result.NOT_DEFAULT_MAKE_THIS_NOTICEABLE = true end
						allproperties[category][name] = result
					end
				else
					MsgN(filename, ": ", particle, " has no attribute category ", category)
				end
			end
		end
	end
end
//PrintTable(allproperties)
for category, attribs in pairs (allproperties) do
	for k, v in pairs (attribs) do
		if default_attribs[k] then default_attribs[k] = nil end
		if !v.NOT_DEFAULT_MAKE_THIS_NOTICEABLE then allproperties[category][k] = nil end
	end
end
PrintTable(allproperties)
MsgN("unused default attribs:")
PrintTable(default_attribs)]]


//For testing purposes, lists all fx using a certain attribute, and optionally prints the attribute's values
//Example: PartCtrl_GetParticlesWithAttrib("Remap Control Point to Vector") to get all fx in all pcfs with that attribute, 
//or PartCtrl_GetParticlesWithAttrib("Remap Control Point to Vector", "particles/critglowtool_colorablefx.pcf") for just the fx in that file;
//add an extra "true" arg to the end of either of those to print the attribute's values
function PartCtrl_GetParticlesWithAttrib(desiredfunc, filename, extended)
	local function GetAttribsFromFile(desiredfunc, filename, extended)
		local tab = PartCtrl_ReadPCF(filename)
		if tab then
			for particle, ptab in SortedPairs (tab) do
				for category, attribs in pairs (ptab) do
					if istable(attribs) then
						for k, v in pairs (attribs) do
							if istable(v) and v.functionName and string.lower(v.functionName) == string.lower(desiredfunc) then
								MsgN("(", filename, ") ", particle)
								if extended then
									PrintTable(v)
									MsgN("")
								end
							end
						end
					end
				end
			end
		end
	end
	//filename arg is optional; if so, then check every file
	if !isstring(filename) then
		extended = filename
		for _, filename2 in pairs (PartCtrl_AllPCFPaths) do
			GetAttribsFromFile(desiredfunc, filename2, extended)
		end
	else
		GetAttribsFromFile(desiredfunc, filename, extended)
	end
end


//For reference:
//Orangebox particle code: https://github.com/nillerusr/source-engine/tree/master/particles
//Newer (CSGO-era?) particle code, used by some operators backported to gmod: https://github.com/nillerusr/Kisak-Strike/tree/master/particles
//https://developer.valvesoftware.com/wiki/Category:Particle_System
local badoutputattribs = {
	["operator start fadein"] = 0,
	//["operator start fadeout"] = 0, //not actually functional without start fadein
	//["operator end fadein"] = 0, //not actually functional without end fadeout
	["operator end fadeout"] = 0,
	["first particle to copy"] = 1, //see striderbuster_flechette_attached
}
function PartCtrl_CPoint_AddToProcessed(processed, k, name, processedk, processedv, attrib)
	if attrib then
		//if an output has a fadein/fadeout, then it isn't always overriding this cpoint, so we don't care about it - reject it
		if (processedk == "output" or processedk == "output_axis" or processedk == "output_children")
		and !string.StartsWith(name, "initializer") then //the operator fadein/out values exist on the only initializer output (initializer Velocity Repulse from World), but don't seem to work, so ignore them
			for bad, v in pairs (badoutputattribs) do
				if attrib[bad] != nil and attrib[bad] > v then
					//MsgN(name, " output doesn't always override cpoint because ", bad, " ", attrib[bad], " > ", v, ", rejecting") //no way to get the name of the particle with the output we're rejecting, argh
					//PrintTable(attrib)
					return
				end
			end
		end
	end
	
	if processedk == nil then
		processedk = "position" //by far the most common use, so make it the default
	end
	if processedv == nil then
		processedv = {}
	else
		//Convenience handling to convert min/max to inMin/outMin + inMax/outMax, for utilfx that don't need to define these separately
		if processedv.min then
			processedv.inMin = processedv.min
			processedv.outMin = processedv.min
			processedv.min = nil
		end
		if processedv.max then
			processedv.inMax = processedv.max
			processedv.outMax = processedv.max
			processedv.max = nil
		end
		//Convenience handling for axis dropdown and checkbox controls:
		if processedv.dropdown then
			//Creates a dropdown control in the editor instead of a slider, but still uses axis internally for networking and dupes and stuff, so fill out all the necessary axis values
			//Networking sanity check clamps values between a min and max, so make sure we set those properly
			local min
			local max
			for k, v in pairs (processedv.dropdown) do
				if min == nil then
					min = k
					max = k
				else
					min = math.min(k, min)
					max = math.max(k, max)
				end
			end
			processedv.inMin = min
			processedv.inMax = max
			processedv.outMin = min
			processedv.outMax = max
			processedv.decimals = 0
		elseif processedv.checkboxes then
			//Similar to above, create a series of checkboxes in the editor instead of a slider, but works internally by setting an axis value to the sum of the checkbox values
			local min = 0
			local max = 0
			local label //in this case, only used by the spawnicon tooltip's list of editable options, so just make this a list of checkbox names separated by newlines
			for k, v in pairs (processedv.checkboxes) do
				max = max + k
				if !label then
					label = ""
				else
					label = label .. "\n"
				end
				label = label .. v
			end
			processedv.label = label
			processedv.inMin = min
			processedv.inMax = max
			processedv.outMin = min
			processedv.outMax = max
			processedv.decimals = 0
		end
	end
	processedv["name"] = name
	processed.cpoints[k] = processed.cpoints[k] or {}
	processed.cpoints[k][processedk] = processed.cpoints[k][processedk] or {}

	table.insert(processed.cpoints[k][processedk], processedv)
end
local function cpoint_from_attrib_value(processed, attrib, value, processedk, processedv)
	if attrib[value] != nil and attrib[value] > -1 then

		local k = attrib[value]
		local name = value
		if attrib.functionName then
			name = attrib.functionName .. ": " .. name
		end
		if attrib._categoryName then
			name = attrib._categoryName .. " " .. name
		end
		PartCtrl_CPoint_AddToProcessed(processed, k, name, processedk, processedv, attrib)
	end
end
local processfuncs = {
	["renderers"] = {
		["render models"] = function(processed, attrib) processed["has_renderer"] = true end, //add this value manually for each renderer attribute, rather than doing it in _generic, so that we can catch fx that don't have a valid one, like those ep2 blob fx
		["render_rope"] = function(processed, attrib) processed["has_renderer"] = true end,
		["render_sprite_trail"] = function(processed, attrib) processed["has_renderer"] = true end,
		["render_animated_sprites"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "orientation control point", "position_combine")
			processed["has_renderer"] = true //global value on the effect, not cpoint-specfic
		end, //TODO: limit this to "orientation_type" cases where the orientation is actually used for something? this is sort of dependent on the VMT to work actually
		["_generic"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Visibility Proxy Input Control Point Number", "position_combine") end, //pet doesn't add cpoint control for this; all renderers except render_rope have this; uses this position for visiblilty testing, which can then scale particle alpha/size based on how visible the area around the point is (https://developer.valvesoftware.com/wiki/Generic_Render_Operator_Visibility_Options)
	},
	["operators"]= {
		["color light from control point"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "Light 1 Control Point", "position_combine")
			cpoint_from_attrib_value(processed, attrib, "Light 2 Control Point", "position_combine")
			cpoint_from_attrib_value(processed, attrib, "Light 3 Control Point", "position_combine")
			cpoint_from_attrib_value(processed, attrib, "Light 4 Control Point", "position_combine")
		end,
		["cull relative to model"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", nil, { //TODO: should this be a position_combine? can't actually find any fx that use this.
			["ignore_outputs"] = true, //this cpoint sets an associated model, not a position, so outputs don't override it
		}) end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Cull_relative_to_model, yeah it's on the wrong page); pet doesn't add a control for this
		["cull when crossing plane"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point for point on plane") end,
		["movement basic"] = function(processed, attrib)
			//stupid handling for one effect that has a cpoint with just a force "move towards control point", but also maximum drag on its movement basic that makes the force not work (particles/taunt_fx.pcf taunt_yeti_fistslam_whirlwind)
			local drag = attrib["drag"] or 0
			if drag >= 0.98 then
				processed["drag_does_override"] = true //global value on the effect, not cpoint-specific
			end
		end,
		["movement dampen relative to control point"] = function(processed, attrib) 
			if attrib["falloff range"] >= 5 then //don't process if this value is too small to do anything (lots of ep2 electrical fx have extra useless cpoints with only these for whatever reason)
				cpoint_from_attrib_value(processed, attrib, "control_point_number")
			end
		end,
		["movement lock to bone"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control_point_number", "position_combine", {["ignore_outputs"] = true}) //this cpoint sets an associated model, not a position, so outputs don't override it
			processed["movement_lock"] = processed["movement_lock"] or {}
			processed["movement_lock"][attrib["control_point_number"]] = true
		end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_System_Operators#Movement_Lock_to_Bone)
		["movement lock to control point"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control_point_number", "position_combine")
			processed["movement_lock"] = processed["movement_lock"] or {}
			processed["movement_lock"][attrib["control_point_number"]] = true
		end,
		["movement maintain position along path"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "start control point number", nil, {["sets_particle_pos"] = true})
			cpoint_from_attrib_value(processed, attrib, "end control point number", nil, {["sets_particle_pos"] = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
		end,
		["movement match particle velocities"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point to Broadcast Speed and Direction To", "output") end, //pet doesn't add control for this; sets all 3 axes of the cpoint's position vector to the speed, and sets the cpoint's angle to face the direction (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_ops.cpp#L3788)
		["movement rotate particle around axis"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point") end,
		["remap control point to scalar"] = function(processed, attrib)
			//controls a whole bunch of stuff (lifetime, radius, alpha, etc.) with the value of a single axis of the cpoint, definitely not a position control
			local axis = attrib["input field 0-2 X/Y/Z"] or 0
			if axis > -1 then
				//Make sure we have values for everything, just in case; use default values from pet otherwise
				local pattrib = ParticleAttributeNames[attrib["output field"]] or "nil" //PARTICLE_ATTRIBUTE_x enum
				local inMin = attrib["input minimum"] or 0
				local inMax = attrib["input maximum"] or 1
				local outMin = attrib["output minimum"] or 0
				local outMax = attrib["output maximum"] or 1
				local default = 0
				if pattrib == "Radius" then default = 16 end //special handling so we don't default to having 0 radius and being invisible
				default = math.Clamp(default, math.Remap(outMin, outMin, outMax, inMin, inMax), math.Remap(outMax, outMin, outMax, inMin, inMax)) //make sure the default value of the slider in the edit window isn't outside its range (see tf2 speech_mediccall)
				cpoint_from_attrib_value(processed, attrib, "input control point number", "axis", {
					["axis"] = axis,
					["label"] = pattrib,
					["inMin"] = inMin,
					["inMax"] = inMax,
					["outMin"] = outMin,
					["outMax"] = outMax,
					["default"] = default,
				})
			end
		end,
		["remap cp speed to cp"] = function(processed, attrib)
			local axis = attrib["Output field 0-2 X/Y/Z"] or 0
			if axis > -1 and attrib["output control point"] != -1 then
				cpoint_from_attrib_value(processed, attrib, "input control point", "position_combine") //only used if the output is defined (https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L2383)
				cpoint_from_attrib_value(processed, attrib, "output control point", "output_axis", {["axis"] = axis})
			end
		end,
		["remap direction to cp to vector"] = function(processed, attrib)
			//is this what the wiki calls "Remap Control Point Direction to Vector"? (https://developer.valvesoftware.com/wiki/Particle_System_Operators#Remap_Control_Point_Direction_to_Vector)
			//if so, then it uses the angle of the cpoint to set the particle's Position, Roll, or Color value, so i guess this should either use a position control to set the angle with,
			//or a manual angle input?
			cpoint_from_attrib_value(processed, attrib, "control point")
			//this doesn't exist in any of the hl2/episodes/tf2 pcfs, so i don't know of any existing effects we need to accomodate. i'm not even sure what this would be used for; after 
			//testing, the only potential uses i could find for this were setting the particle position to one based on the angle (output field Roll, normalize 1), or making the color 
			//change based on the angle (ourput field Color, normalize 1). neither of these seems practical, and everything with normalize 0 seems glitchy and generates random noise. 
			//i guess maybe you could design an effect to use p,y,r as a color input instead of x,y,z, but why would you do that?
			//this seems to have been added in the june 2023 gmod update (https://gmod.facepunch.com/news/june-2023-update), from a 6-16-23 commit (https://discord.com/channels/565105920414318602/788473343065587723/1119340195381256242),
			//so maybe this was backported from a newer pcf version, like portal 2 or csgo or something. TODO: check newer games' pcfs for use cases?
			//update: found code for this, still can't find any practical use for it (https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L9390)
		end,
		["remap distance between two control points to scalar"] = function(processed, attrib)
			//this uses all the same scalars as remap control point to scalar, but actually uses the distance between two positions to get the value, so use position controls
			local pattrib = ParticleAttributeNames[attrib["output field"]] or "nil" //PARTICLE_ATTRIBUTE_x enum //put this in the table so we can see what it does in the debug
			cpoint_from_attrib_value(processed, attrib, "starting control point", nil, {["label"] = pattrib})
			cpoint_from_attrib_value(processed, attrib, "ending control point", nil, {["label"] = pattrib})
		end,
		["remap distance to control point to scalar"] = function(processed, attrib)
			//like the above but uses the distance between a single cpoint's position and the particle (sprite?) itself (https://developer.valvesoftware.com/wiki/Particle_System_Operators#Remap_Distance_to_Control_Point_to_Scalar)
			local pattrib = ParticleAttributeNames[attrib["output field"]] or "nil" //PARTICLE_ATTRIBUTE_x enum //put this in the table so we can see what it does in the debug
			cpoint_from_attrib_value(processed, attrib, "control point", nil, {["label"] = pattrib})
		end,
		["remap dot product to scalar"] = function (processed, attrib)
			//like "remap control point to scalar", except it gets the angle(?) of 2 cpoints and does math with them to set the scalar. not listed in wiki.
			//every example i could find for this (it's used by a lot of "ring" child fx in dr grordbord fx) works in conjunction with another "set control point to player" operator, which 
			//uses an output to set a cpoint to the player's position. then, this operator does math with that to set output field Yaw (12) to rotate the particles, attempting to orient 
			//them to face "forward" in the direction of the first cpoint(not the player one), with mixed results. the only exceptions i could find for this were some unused effects in 
			//eyeboss.pcf, which were the same but without the player cpoint, and instead use the angle (not the position!) of the second cpoint to change the particle's yaw.
			//whatever, just make this a position control, seems it's like "remap direction to cp to vector", and should be either this or a manual angle input.
			//update: actually just combine this one, the only effects that have a position control *for this operator only* are ones that didn't set up the player yaw thing properly
			local pattrib = ParticleAttributeNames[attrib["output field"]] or "nil" //PARTICLE_ATTRIBUTE_x enum //put this in the table so we can see what it does in the debug
			cpoint_from_attrib_value(processed, attrib, "first input control point", "position_combine", {["label"] = pattrib})
			cpoint_from_attrib_value(processed, attrib, "second input control point", "position_combine", {["label"] = pattrib})
		end,
		["rotation orient relative to cp"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point") end,
		["set child control points from particle positions"] = function(processed, attrib)
			local groupid = attrib["Group ID to affect"] or 0
			local startp = attrib["First control point to set"] or 0
			local endp = startp + ((attrib["# of control points to set"] or 1) - 1)
			local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
			for i = startp, endp do
				PartCtrl_CPoint_AddToProcessed(processed, i, name, "output_children", {["groupid"] = groupid}, attrib)
			end
			//some fx (i.e. utaunt_tornado_oscillate_) emit invisible particles (no renderer) and then use them to set the position of a child control point. ordinarily, we'd cull the
			//cpoint data from fx with no renderer, because their attribs don't do anything that the player can see, but in this case, we don't want to do that, so mark as having a renderer.
			//TODO: this might be bad if the children don't have a renderer either, can we catch those?
			if #processed["children"] > 0 then processed["has_renderer"] = true end
			//processed["sets_particle_pos_on_children"] = groupid
		end,
		["set control point positions"] = function(processed, attrib)
			local inputs = {
				["First Control Point Parent"] = true, //TODO: is it really necessary to add position controls for these cpoint movement parents?
				["Second Control Point Parent"] = true,
				["Third Control Point Parent"] = true,
				["Fourth Control Point Parent"] = true
			}
			if !attrib["Set positions in world space"] then //according to code, only used if not setting in world space (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_ops.cpp#L2725)
				inputs["Control Point to offset positions from"] = true //pet doesn't add control for this
			end
			local used_cpoints = {} //fix some fx that have an output set to the same cpoint id as an input (tfc_sniper_charge_blue) - in these cases, the cpoint is not overridden
			for k, _ in pairs (inputs) do
				cpoint_from_attrib_value(processed, attrib, k, nil, {["doesnt_need_renderer_or_emitter"] = true})
				if attrib[k] != nil then
					used_cpoints[attrib[k]] = true
				end
			end

			local outputs = {
				["First Control Point Number"] = true,
				["Second Control Point Number"] = true,
				["Third Control Point Number"] = true,
				["Fourth Control Point Number"] = true
			}
			for k, _ in pairs (outputs) do
				if attrib[k] != nil and !used_cpoints[attrib[k]] then
					cpoint_from_attrib_value(processed, attrib, k, "output")
				end
			end
		end,
		["set control point to particles' center"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point Number to Set", "output") end,
		["set control point to player"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "Control Point Number", "output")
			processed["spawnicon_playerposfix"] = true //this attrib forces a cpoint to the player's position, which can break spawnicon renderbounds, so tell it to account for that
		end,
	},
	["initializers"] = {
		["color random"] = function(processed, attrib)
			if attrib["tint_perc"] != nil and attrib["tint_perc"] > 0 then //by default, the value of "tint control point" is 0, not -1, so pet adds a control for it by default, but in code, this isn't used unless tint_perc is non-zero (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L1705)
				cpoint_from_attrib_value(processed, attrib, "tint control point", "position_combine") //samples the lighting from this cpoint's position (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Color_Random)
			end
		end,
		["move particles between 2 control points"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "end control point", nil, {["sets_particle_pos"] = true}) //yes, it only defines an endpoint (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Move_Particles_Between_2_Control_Points)
		end, 
		["position along epitrochoid"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control point number", nil, {["sets_particle_pos"] = true})
			local cpoint = attrib["scale from conrol point (radius 1/radius 2/offset)"] //sic
			if cpoint != nil and cpoint > -1 then
				local function DoEpitrochoidAxis(axis, axisv)
					local doaxis = false
					if attrib[axisv] != nil and attrib[axisv] != 0 then
						doaxis = true
					end
					if doaxis then
						cpoint_from_attrib_value(processed, attrib, "scale from conrol point (radius 1/radius 2/offset)", "axis", {
							["axis"] = axis,
							["label"] = "Epitrochoid " .. axisv .. " multiplier",
							//no min/max
							["default"] = 1,
						})
					end
				end
				DoEpitrochoidAxis(0, "radius 1")
				DoEpitrochoidAxis(1, "radius 2")
				DoEpitrochoidAxis(2, "point offset")
			end
		end,
		["position along path random"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "start control point number", nil, {["sets_particle_pos"] = true})
			cpoint_from_attrib_value(processed, attrib, "end control point number", nil, {["sets_particle_pos"] = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
		end,
		["position along path sequential"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "start control point number", nil, {["sets_particle_pos"] = true})
			cpoint_from_attrib_value(processed, attrib, "end control point number", nil, {["sets_particle_pos"] = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
		end,
		["position along ring"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control point number", nil, {["sets_particle_pos"] = true})
			//"Override CP (X/Y/Z *= Radius/Thickness/Speed)" and "Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)" control those things with the values of the cpoint
			//These are all MULTIPLIERS so an axis doesn't do anything if the value is 0, ignore those
			//Unlike remap control point to vector, pitch/yaw/roll are in degrees, not radians
			local function DoRingAxis(cpoint, axis, axisv)
				if attrib[cpoint] != nil and attrib[cpoint] > -1 then
					local doaxis = false
					if axisv == "speed" then //this one uses two values so it has special handling 
						if (attrib["min initial speed"] != nil and attrib["min initial speed"] != 0) 
						or (attrib["max initial speed"] != nil and attrib["max initial speed"] != 0) then
							doaxis = true
						end
					elseif attrib[axisv] != nil and attrib[axisv] != 0 then
						doaxis = true
					end
					if axisv == "initial radius" then axisv = "radius" end //nicer name for slider label
					if doaxis then
						cpoint_from_attrib_value(processed, attrib, cpoint, "axis", {
							["axis"] = axis,
							["label"] = "Ring " .. axisv .. " multiplier",
							//no min/max
							["default"] = 1,
						})
					end
				end
			end
			DoRingAxis("Override CP (X/Y/Z *= Radius/Thickness/Speed)", 0, "initial radius")
			DoRingAxis("Override CP (X/Y/Z *= Radius/Thickness/Speed)", 1, "thickness")
			DoRingAxis("Override CP (X/Y/Z *= Radius/Thickness/Speed)", 2, "speed")
			DoRingAxis("Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)", 0, "pitch")
			DoRingAxis("Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)", 1, "yaw")
			DoRingAxis("Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)", 2, "roll")
		end,
		["position from chaotic attractor"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "Relative Control point number", nil, {["sets_particle_pos"] = true})
		end,
		["position from parent particles"] = function(processed, attrib)
			//don't cull parent fx if they don't have a valid renderer, but one of their children has this attribute (i.e. parent alien_ufo_explode_trailing_bits_alt, child alien_ufo_explode_alt_trail_smoke)
			processed["parent_force_has_renderer"] = true
			//processed["sets_particle_pos_if_child"] = true
		end,
		["position in cp hierarchy"] = function(processed, attrib)
			//this one is a bit strange. it defines a cpoint for every id between the start and end, and then moves the particle spawn point between them all.
			//the weird pet behavior where it adds controls for every cpoint between start and end seems to be designed for this initializer.
			local startp = attrib["start control point number"] or -1
			local endp = attrib["end control point number"] or -1
			if attrib["use highest supplied end point"] then //with this arg set, the particle system uses as many cpoints as you give it. any amount works.
				//endp = 63 //this is what pet does, and it's functional, but this is stupid, don't do this. no one needs 64 whole cpoints to move around.
				endp = math.min(startp + 1, 63) //TODO: give players a way to manually enable as many cpoints as they want, without dumping 64 on them by default.
			end
			local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
			for i = startp, endp do
				PartCtrl_CPoint_AddToProcessed(processed, i, name, nil, {["sets_particle_pos"] = true})
			end
		end,
		["position modify offset random"] = function(processed, attrib)
			//code only uses this cpoint if offset in local space is enabled; (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L776)
			//this cpoint's ANGLES are used to rotate the offset mins/maxs, its position is not used, so we should either use a position control or a manual angle input maybe
			if attrib["offset in local space 0/1"] then
				cpoint_from_attrib_value(processed, attrib, "control_point_number", "position_combine")
			end
		end,
		["position modify warp random"] = function(processed, attrib)
			//this can potentially be used to make the position stretch and skew with the movement of the cpoint, but only if the values are set up a specific way. (test_PositionModifyWarpRandom_2)
			//otherwise, in practice, making a separate cpoint for this doesn't do anything except move the center of the effect around, which is extraneous, so use position_combine.
			local min = attrib["warp min"] or Vector(1,1,1)
			local max = attrib["warp max"] or Vector(1,1,1)
			local time = attrib["warp transition time (treats min/max as start/end sizes)"] or 0
			if time == 0 and min != max then
				cpoint_from_attrib_value(processed, attrib, "control point number")
			else
				cpoint_from_attrib_value(processed, attrib, "control point number", "position_combine")
			end
		end,
		["position on model random"] = function(processed, attrib) 
			cpoint_from_attrib_value(processed, attrib, "control_point_number", nil, {
				["ignore_outputs"] = true, //this cpoint sets an associated model, not a position, so outputs don't override it
				["on_model"] = true,
				["sets_particle_pos"] = true,
			})
		end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_position#Position_on_Model_Random)
		["position within box random"] = function(processed, attrib)
			if attrib["control point number"] == nil then attrib["control point number"] = 0 end //a few ep2 fx don't have this value at all, it seems to default to 0
			cpoint_from_attrib_value(processed, attrib, "control point number", nil, {["overridable_by_constraint"] = true, ["sets_particle_pos"] = true})
		end,
		["position within sphere random"] = function(processed, attrib)
			if attrib["control_point_number"] == nil then attrib["control_point_number"] = 0 end //a few ep2 fx don't have this value at all, it seems to default to 0
			cpoint_from_attrib_value(processed, attrib, "control_point_number", nil, {["overridable_by_constraint"] = true, ["sets_particle_pos"] = true})
		end,
		["remap control point to scalar"] = function(processed, attrib)
			//like the operator of the same name
			//controls a whole bunch of stuff (lifetime, radius, alpha, etc.) with the value of a single axis of the cpoint, definitely not a position control
			local axis = attrib["input field 0-2 X/Y/Z"] or 0
			if axis > -1 then
				//Make sure we have values for everything, just in case; use default values from pet otherwise
				local pattrib = ParticleAttributeNames[attrib["output field"]] or "Radius" //PARTICLE_ATTRIBUTE_x enum
				local inMin = attrib["input minimum"] or 0
				local inMax = attrib["input maximum"] or 1
				local outMin = attrib["output minimum"] or 0
				local outMax = attrib["output maximum"] or 1
				local default = 0
				if pattrib == "Radius" then default = 16 end //special handling so we don't default to having 0 radius and being invisible
				default = math.Clamp(default, math.Remap(outMin, outMin, outMax, inMin, inMax), math.Remap(outMax, outMin, outMax, inMin, inMax)) //make sure the default value of the slider in the edit window isn't outside its range (see tf2 speech_mediccall)
				cpoint_from_attrib_value(processed, attrib, "input control point number", "axis", {
					["axis"] = axis,
					["label"] = pattrib,
					["inMin"] = inMin,
					["inMax"] = inMax,
					["outMin"] = outMin,
					["outMax"] = outMax,
					["default"] = default,
				})
			end
		end,
		["remap control point to vector"] = function(processed, attrib)
			//Similar to above, use all 3 axes of the cpoint to set Position, Roll, or Color
			//TF2/episodes/HL2 pcfs only have use cases for Color, so the others required some testing.
			//Make sure we have values for everything, just in case; use default values from pet otherwise
			local pattrib = ParticleAttributeNames[attrib["output field"]] or "Position" //PARTICLE_ATTRIBUTE_x enum
			local inMin = attrib["input minimum"] or Vector()
			local inMax = attrib["input maximum"] or Vector()
			local outMin = attrib["output minimum"] or Vector()
			local outMax = attrib["output maximum"] or Vector()
			//Color should default to the equivalent of 1,1,1 (white)
			local default = nil
			if attrib["output field"] == PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB then
				default = Vector(math.Remap(1, outMin.x, outMax.x, inMin.x, inMax.x), math.Remap(1, outMin.y, outMax.y, inMin.y, inMax.y), math.Remap(1, outMin.z, outMax.z, inMin.z, inMax.z))
			end
			cpoint_from_attrib_value(processed, attrib, "input control point number", "vector", {
				["label"] = pattrib,
				["inMin"] = inMin,
				["inMax"] = inMax,
				["outMin"] = outMin,
				["outMax"] = outMax,
				["default"] = default,
			})
			cpoint_from_attrib_value(processed, attrib, "local space CP", "position_combine") //uses the cpoint's angles to rotate the output in some odd way, can be used to make a position sort-of-rotate with the cpoint, or make colors change as it spins
		end,
		["remap initial distance to control point to scalar"] = function(processed, attrib)
			local pattrib = ParticleAttributeNames[attrib["output field"]] or "nil" //PARTICLE_ATTRIBUTE_x enum //put this in the table so we can see what it does in the debug
			cpoint_from_attrib_value(processed, attrib, "control point", nil, {["label"] = pattrib})
		end,
		["remap scalar to vector"] = function(processed, attrib)
			local field = attrib["output field"] or 0
			if field == 0 then //cpoint is only used by position vector (0) to make the position relative to that cpoint (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3155)
				cpoint_from_attrib_value(processed, attrib, "control_point_number", nil, {["sets_particle_pos"] = true}) //yes, this sets particle pos, see unusual_poseidon_light_ fx
			end
		end,
		["set hitbox position on model"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number") end, //presumably uses the model that the cpoint is attached to, so use position; these two are csgo(?) ports and i can't get them to do anything, don't know if they even function in gmod
		["set hitbox to closest hitbox"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number") end, //^
		["velocity inherit from control point"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control point number", "position_combine") end,
		["velocity noise"] = function(processed, attrib)
			if attrib["Apply Velocity in Local Space (0/1)"] then //cpoint is only used if this is enabled (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L1243)
				cpoint_from_attrib_value(processed, attrib, "Control Point Number", "position_combine")
			end
		end,
		["velocity random"] = function(processed, attrib)
			local lmin = attrib["speed_in_local_coordinate_system_min"] or Vector(0,0,0)
			local lmax = attrib["speed_in_local_coordinate_system_max"] or Vector(0,0,0)
			if lmin != vector_origin or lmax != vector_origin then //code uses this cpoint if bHasLocalSpeed (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L892), which is determined by this same check (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L855)
				//if !(lmin.x == lmin.y and lmin.x == lmin.z and lmin.x == -lmax.x and lmin.y == -lmax.y and lmin.z == -lmax.z) then
					cpoint_from_attrib_value(processed, attrib, "control_point_number", "position_combine")
				//end
			end
		end,
		["velocity repulse from world"] = function(processed, attrib)
			if !attrib["Per Particle World Collision Tests"] then //according to code, neither the cpoint nor broadcast-to-children are used with per-particle collision on (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3421)
				if !attrib["Inherit from Parent"] then
					cpoint_from_attrib_value(processed, attrib, "control_point_number")
					local i = attrib["control points to broadcast to children (n + 1)"] //this also isn't used if inheriting
					if i != nil and i != -1 then
						local groupid = attrib["Child Group ID to affect"] or 0
						local name = attrib._categoryName .. " " .. attrib.functionName .. ": control points to broadcast to children (n + 1)"
						PartCtrl_CPoint_AddToProcessed(processed, i, name, "output_children", {["groupid"] = groupid}, attrib)
						PartCtrl_CPoint_AddToProcessed(processed, i + 1, name, "output_children", {["groupid"] = groupid}, attrib) //this sets axis 0 to a force value, and the other two to 0 (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3586)
					end
				else
					//let players manually set the values if they spawned a child effect on its own, or for some hypothetical use case where it's intended to be supplied by code or something
					//this is silly, who's going to use this?
					cpoint_from_attrib_value(processed, attrib, "control_point_number", "vector", {
						["label"] = "Velocity Direction Normal",
						["inMin"] = Vector(-1,-1,-1),
						["inMax"] = Vector(1,1,1),
						["outMin"] = Vector(-1,-1,-1),
						["outMax"] = Vector(1,1,1),
						["default"] = Vector(0,0,0),
					})
					local cpoint = attrib["control_point_number"] or 0
					local name = attrib._categoryName .. " " .. attrib.functionName .. ": control_point_number (+ 1 for Inherit from parent)"
					PartCtrl_CPoint_AddToProcessed(processed, cpoint + 1, name, "axis", {
						["axis"] = 0,
						["label"] = "Velocity Scale",
						["inMin"] = 0,
						["inMax"] = 1,
						["outMin"] = 0, //I'd like the slider to use maximum/minimum velocity instead so it looks nicer,
						["outMax"] = 1, //but unfortunately those can be different for each axis, which doesn't work here
						["default"] = 1,
					})
					//according to code, broadcast to children doesn't run if inheriting
				end
			end
		end,
		["velocity set from control point"] = function(processed, attrib)
			//another backported effect from csgo(?), seems to use the position values of these cpoints to set a normal vector for particle velocity, so i guess it should either use position controls or manual value inputs; because it's backported there aren't any existing orangebox effects to accomodate
			//all of these cpoints are used if available (https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_initializers.cpp#L4160-L4255)
			cpoint_from_attrib_value(processed, attrib, "control point number")
			cpoint_from_attrib_value(processed, attrib, "comparison control point number")
			cpoint_from_attrib_value(processed, attrib, "local space control point number")
		end,
	},
	["emitters"] = {
		["emit noise"] = function(processed, attrib)
			local min = attrib["emission minimum"] or 0
			local max = attrib["emission maximum"] or 0
			if min > 0 or max > 0 then
				processed["has_emitter"] = true
			end
		end,
		["emit_continuously"] = function(processed, attrib)
			local max = attrib["emission_rate"] or 0
			if max > 0 then
				processed["has_emitter"] = true
			end
		end,
		//"emit noise" and "emit_continuously" have "scale emission to used control points", which wiki claims is a cpoint id, but it's actually a float that's multiplied by the number of cpoints the effect has, we don't care about this (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_emitters.cpp#L449)
		["emit_instantaneously"] = function(processed, attrib)
			local min = attrib["num_to_emit_minimum"] or 0
			local max = attrib["num_to_emit"] or 0
			if min > 0 or max > 0 then
				processed["has_emitter"] = true
			end
			local axis = attrib["emission count scale control point field"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "emission count scale control point", "axis", {
					["axis"] = axis,
					["label"] = "Emission Count Scale",
					["inMin"] = 0, //will crash if value is set to less than 0
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
		end,
	},
	["forces"] = { //ForceGenerator
		["pull towards control point"] = function(processed, attrib)
			local force = attrib["amount of force"] or 0
			local type = nil
			if math.abs(force) < 10 then //can be negative
				//a lot of effects have this attrib with miniscule force values, for whatever reason. they don't visibly appear to do anything, maybe it's part of some hacky workaround
				//that particle developers use, i don't know. either way, don't let them create their own position control in these cases, because they aren't useful.
				type = "position_combine" 
			end
			cpoint_from_attrib_value(processed, attrib, "control point number", type, {["overridable_by_constraint"] = true, ["overridable_by_drag"] = true})
		end
	},
	["constraints"] = {
		//"collision via traces" always sets cpoint 0 in pet, but this doesn't seem necessary, it functions just fine without it in a test effect using only cpoint 1, and even if we add another cpoint for 0 it doesn't actually seem to do anything; can't find any code actually using a cpoint either (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L630-L1098)
		["constrain distance to control point"] = function(processed, attrib)
			if !attrib["global center point"] then //according to code, cpoint is only used if global center point is false (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L87)
				cpoint_from_attrib_value(processed, attrib, "control point number", nil, {["sets_particle_pos"] = true}) //pet doesn't add control for this
				if attrib["maximum distance"] < 1 then
					processed["constraint_does_override"] = true //global value on the effect, not cpoint-specific
				end
			end
		end,
		["constrain distance to path between two control points"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "start control point number", nil, {["sets_particle_pos"] = true})
			cpoint_from_attrib_value(processed, attrib, "end control point number", nil, {["sets_particle_pos"] = true})
			//if there's no way for other cpoint attribs (like the ones that initialize in a box/sphere) to influence the particles because this constraint forces them onto a very specific path, then don't make position controls for those cpoints
			if attrib["maximum distance"] < 1 then
				processed["constraint_does_override"] = true //global value on the effect, not cpoint-specific
			end
		end,
		["prevent passing through a plane"] = function(processed, attrib)
			if !attrib["global origin"] or !attrib["global normal"] then
				cpoint_from_attrib_value(processed, attrib, "control point number")
			end
		end,
		//code says this one always uses cpoint 0 for some trace stuff, but when trying to test it, on every single effect i could find or make with this attribute, it just doesn't seem to work at all? particles pass through brushes, displacements, and static props just fine. (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L473)
		//TODO: test on a map that isn't gm_flatgrass, maybe it's a problem with distance from the world origin or something
		//["prevent passing through static part of world"] = function(processed, attrib) PartCtrl_CPoint_AddToProcessed(processed, 0, attrib._categoryName .. " " .. attrib.functionName .. ": always uses cpoint 0") end,
	}
}
function PartCtrl_ProcessPCF(filename)
	local t = PartCtrl_ReadPCF(filename)
	if !t then
		MsgN(filename, " couldn't be read")
	else
		local t2 = {}
		for particle, ptab in pairs (t) do
			local processed = {
				["cpoints"] = {},
				["children"] = t[particle].children,
			}
			for k, v in pairs (processfuncs) do
				if ptab[k] then
					for _, attrib in pairs (ptab[k]) do
						if !(attrib["operator start fadein"] and attrib["operator start fadein"] >= 99) and !(attrib["operator end fadein"] and attrib["operator end fadein"] >= 99) then //some fx use a superlong fadein to effectively comment out attribs, ridiculous (particles/advisor_fx.pcf Advisor_Psychic_Attach_01b operator Remap Distance to Control Point to Scalar)
							if !attrib.functionName then
								MsgN(filename, " particle ", particle, " has attribute with no function name")
							else
								attrib._categoryName = string.TrimRight(k, "s") //for name
								local name = string.lower(attrib.functionName) or ""
								if fixes[name] then name = fixes[name] end

								if v[name] then v[name](processed, attrib) end
								if v["_generic"] then v["_generic"](processed, attrib) end
							end
						end
					end
				end
			end
			//also process a couple things that are stored in the main table and not in operators
			if ptab["cull_radius"] != nil and ptab["cull_radius"] > 0 then //(https://github.com/VSES/SourceEngine2007/blob/master/src_main/particles/particles.cpp#L500-L503)
				cpoint_from_attrib_value(processed, ptab, "cull_control_point", "position_combine", {
					["ignore_outputs"] = true, //unlike the other things that ignore outputs, this one actually does set a position, but outputs still don't override it because it runs first i guess
					["dont_inherit"] = true,
				}) //this system only runs if an obscure cheat command cl_particle_retire_cost is enabled (https://developer.valvesoftware.com/wiki/Particle_System_Properties), and also only runs on the frame a particle is spawned (https://github.com/nillerusr/source-engine/blob/master/game/client/particlemgr.cpp#L1707); culls the particle by deleting it (or optionally spawning an alternative particle) if this cpoint is taking up too much of the screen
			end
			cpoint_from_attrib_value(processed, ptab, "control point to disable rendering if it is the camera", "position_combine", {
				["ignore_outputs"] = true, //this cpoint sets an associated model, not a position, so outputs don't override it
				["dont_inherit"] = true,
			}) //makes the particle not render if this cpoint is attached to the ent the camera is viewing from (i.e. the player, or a camera ent they're using)
			if ptab["preventNameBasedLookup"] then
				processed["prevent_name_based_lookup"] = true //makes the particle impossible to spawn on its own, but still usable as a child. not sure what the point of this is.
			end
			if ptab["initial_particles"] != nil and ptab["initial_particles"] > 0 then
				processed["has_emitter"] = true
			end
			t2[particle] = processed
		end
		for particle, _ in pairs (t2) do
			if !t2[particle]["has_renderer"] then
				for _, child in pairs (t2[particle].children) do
					if t2[child]["parent_force_has_renderer"] then
						t2[particle]["has_renderer"] = true 
						break
					end
				end
			end
		end
		//Inherit cpoint info from children; for spawnicons, particle entities, and control windows to make use of; cpoint defaults handle inheritance differently because of how outputs work,
		//so store all of this in a separate table for now, and don't apply it until after we're done setting cpoint defaults.
		for particle, _ in pairs (t2) do
			local cpoints = table.Copy(t2[particle].cpoints)
			local function cpoints_from_child_fx(cpoints, particle2, depth)
				depth = depth or 0
				depth = depth + 1
				if depth > 99 then
					MsgN(filename, " ", particle2, " child ", child, " cpoints_from_child_fx has crazy recursion when trying to get child fx, aborting - report this bug!") //don't even know if this is possible, but want to be safe anyway
					return cpoints
				end
				if istable(t[particle2].children) then
					for _, child in pairs (t[particle2].children) do
						if t2[child] then
							local cpoints2 = table.Copy(t2[child].cpoints)
							//make sure the child has also inherited cpoints from its own children
							if istable(t[child].children) then
								//if dodebug and #t[child].children > 0 then MsgN("children of ", child, ":") PrintTable(t[child].children) end
								for _, child2 in pairs (t[child].children) do
									if t2[child2] then
										local cpoints3 = cpoints_from_child_fx(table.Copy(t2[child2].cpoints), child2, depth)
										for i, tab in pairs (cpoints3) do
											cpoints2[i] = cpoints2[i] or {}
											for processedk, processedv in pairs (tab) do
												for k, v in pairs (processedv) do
													//mark attribs as being inherited from a child
													if v["name"] then
														processedv[k]["name"] = "child " .. child2 .. " | " .. processedv[k]["name"]
													end
												end
												if istable(cpoints2[i][processedk]) then
													table.Add(cpoints2[i][processedk], processedv)
												else
													cpoints2[i][processedk] = processedv
												end
											end
										end
									end
								end
							end
							//inherit cpoints from the child
							for i, tab in pairs (cpoints2) do
								cpoints[i] = cpoints[i] or {}
								for processedk, processedv in pairs (tab) do
									for k, v in pairs (processedv) do
										//mark attribs as being inherited from a child
										if v["name"] then
											processedv[k]["name"] = "child " .. child .. " | " .. processedv[k]["name"]
										end
									end
									if istable(cpoints[i][processedk]) then
										table.Add(cpoints[i][processedk], processedv)
									else
										cpoints[i][processedk] = processedv
									end
								end
							end
						end
					end
				end
				return cpoints
			end
			//store this separately for now, so that other particles grabbing cpoints from their children won't retrieve an already altered table and then alter it again
			t2[particle].cpoints_with_children = cpoints_from_child_fx(cpoints, particle)
		end
		for particle, _ in pairs (t2) do
			//Store the default use for each cpoint - this is used by both particle entities and spawnicons, so do it here to ensure that they match
			local defaults = {}
			local output_children = {}
			local output_axis = {}
			local on_model = nil
			local sets_particle_pos = nil
			local function SetCPointDefaults(particle2, parent)
				//MsgN("Doing SetCPointDefaults for particle ", particle2, ", parent ", parent, "\nCurrent output_children:")
				//a little heavy-handed? maybe. might result in some false positives in complex hierarchy trees. haven't found any actual examples of this causing problems,
				//and we'd have to totally rework how we handle hierarchy here to make this more accurate (currently have no way to get the parent of a parent, etc. to check if
				//it's using output_children).
				local groupid = t[particle2]["group id"]

				if parent then
					for k, v in pairs (t2[parent].cpoints) do
						if v["output_children"] then
							for k2, v2 in pairs (v["output_children"]) do
								if v2["groupid"] then
									output_children[k] = output_children[k] or {}
									output_children[k][v2["groupid"]] = true
								end
							end
						end
					end
				end
				//PrintTable(output_children)
				
				for k, v in pairs (t2[particle2].cpoints) do
					if !output_children[k] or !output_children[k][groupid] then
						if v["output_axis"] then
							for k2, v2 in pairs (v["output_axis"]) do
								if v2["axis"] then
									output_axis[k] = output_axis[k] or {}
									output_axis[k][v2["axis"]] = true
								end
							end
						end
						local did_output = false
						if v["output"] or (istable(output_axis[k]) and output_axis[k][0] and output_axis[k][1] and output_axis[k][2]) then
							//- outputs override the target cpoint on the effect itself, and on all of its children
							//- outputs on the children of an effect do NOT override the target cpoint on their parent
							//- output_axis follows the same two rules above but only overrides a single axis
							if defaults[k] == nil then
								did_output = true
								defaults[k] = PARTCTRL_CPOINT_MODE_NONE
							end
						end
						if v["position"] then
							//If we're inheriting cpoint defaults from a child, make sure it's not from an attrib that shouldn't be inherited
							local newtab = {}
							for k2, v2 in pairs (v["position"]) do
								if !(parenttab and v2["dont_inherit"]) --[[and !(t2[particle2].constraint_does_override and v2["overridable_by_constraint"])]] then
									newtab[k2] = v2
								end
							end
							//Make sure to check for the "ignore_outputs" value for attribs that aren't overridden by output
							local ignore_outputs = false
							for k2, v2 in pairs (newtab) do
								if v2["ignore_outputs"] then
									ignore_outputs = true
									break
								end
							end
							for k2, v2 in pairs (newtab) do
								if (t2[particle2].has_renderer and t2[particle2].has_emitter) or v2["doesnt_need_renderer_or_emitter"] then
									if defaults[k] == nil or defaults[k] == PARTCTRL_CPOINT_MODE_POSITION_COMBINE or (did_output and ignore_outputs) then
										if t2[particle2].constraint_does_override and v2["overridable_by_constraint"]
										or t2[particle2].drag_does_override and v2["overridable_by_drag"] then
											defaults[k] = PARTCTRL_CPOINT_MODE_POSITION_COMBINE
										else
											defaults[k] = PARTCTRL_CPOINT_MODE_POSITION
										end
										did_output = false //make sure position_combine below doesn't override this
									end
									if defaults[k] == PARTCTRL_CPOINT_MODE_POSITION and v2["on_model"] then
										//also make a list of all the cpoints that have "on_model" fx so that we can print extra info about it in spawnicons
										on_model = on_model or {}
										on_model[k] = true
									end
								end
								if v2["sets_particle_pos"] then
									sets_particle_pos = sets_particle_pos or {}
									sets_particle_pos[k] = true
								end
							end
						end
						if v["position_combine"] then
							//If we're inheriting cpoint defaults from a child, make sure it's not from an attrib that shouldn't be inherited
							local newtab = {}
							if parenttab then
								for k2, v2 in pairs (v["position_combine"]) do
									if !v2["dont_inherit"] then
										newtab[k2] = v2
									end
								end
							else
								newtab = v["position_combine"]
							end
							//Make sure to check for the "ignore_outputs" value for attribs that aren't overridden by output
							local ignore_outputs = false
							for k2, v2 in pairs (newtab) do
								if v2["ignore_outputs"] then
									ignore_outputs = true
									break
								end
							end
							for k2, v2 in pairs (newtab) do
								//combining multiple cpoints with movement lock will result in the the movement being applied additively from each one
								//(see speech_mediccall_auto, utaunt_cremation_smoke_black, utaunt_cremation_black_parent);
								//instead, only allow 1 cpoint with movement lock to be combined, while the rest are ignored.
								if t2[particle2].movement_lock and t2[particle2].movement_lock[k] and t2[particle].movement_lock_cpoint == nil then
									t2[particle].movement_lock_cpoint = k
								end
								if ((t2[particle2].has_renderer and t2[particle2].has_emitter) or v2["doesnt_need_renderer_or_emitter"]) 
								and (!t2[particle2].movement_lock or !t2[particle2].movement_lock[k] or t2[particle].movement_lock_cpoint == k) then
									if defaults[k] == nil or (did_output and ignore_outputs) then
										defaults[k] = PARTCTRL_CPOINT_MODE_POSITION_COMBINE
									end
								end
							end
						end
						if v["vector"] then
							if defaults[k] == nil then
								defaults[k] = PARTCTRL_CPOINT_MODE_VECTOR
							end
						end
						if v["axis"] then
							local doaxis = false
							if defaults[k] == nil then
								for k2, v2 in pairs (v["axis"]) do
									//handle output_axis overriding specific axes
									if !istable(output_axis[k]) or !output_axis[k][v2.axis] then
										doaxis = true
									end
								end
							end
							if doaxis then
								defaults[k] = PARTCTRL_CPOINT_MODE_AXIS
							end
						end
					end
				end
				//MsgN("Current defaults:")
				//PrintTable(defaults)
			end
			SetCPointDefaults(particle)
			//Cpoints that haven't been filled in yet should inherit from children
			local function CPointDefaultsFromChildren(particle2, depth)
				depth = depth or 0
				depth = depth + 1
				if depth > 99 then
					MsgN(filename, " ", particle2, " CPointDefaultsFromChildren has crazy recursion when trying to get child fx, aborting - report this bug!") //don't even know if this is possible, but want to be safe anyway
					return
				end

				if istable(t2[particle2].children) then
					for _, child in pairs (t2[particle2].children) do
						if !t2[child] then
							//MsgN(filename, " ", particle2, " CPointDefaultsFromChildren tried to get nonexistent child effect ", child)
						else
							SetCPointDefaults(child, particle2)
							//Now inherit from the child's children, and so on
							//TODO: the order here might not be quite right if we have multiple branching children of children, but I don't know if that actually matters in practice
							CPointDefaultsFromChildren(child, depth)
						end
					end
				end
			end
			CPointDefaultsFromChildren(particle)

			local shouldcull = !t2[particle].has_renderer or !t2[particle].has_emitter
			local needfallback = true
			for k, v in pairs (defaults) do
				if !shouldcull and !needfallback then break end
				if shouldcull and v != PARTCTRL_CPOINT_MODE_NONE then
					//Clear out empty effects (no renderer, no emitter, no cpoints even from children)
					shouldcull = false
				end
				if needfallback and v == PARTCTRL_CPOINT_MODE_POSITION then
					//Create fallback movement cpoint "-1" for effects that don't have a movement cpoint
					needfallback = false
				end
			end
			if shouldcull then
				t2[particle]["renderer_emitter_shouldcull"] = true
			end
			if needfallback then
				//PartCtrl_CPoint_AddToProcessed(t2[particle], -1, "fallback position cpoint created due to no position cpoint") //causes bizarre unnecessary cpoint -1 on utaunt_rainbow_teamcolor_red
				t2[particle].cpoints_with_children[-1] = {["position"] = {[1] = {["name"] = "fallback position cpoint created due to no position cpoint"}}}
				defaults[-1] = PARTCTRL_CPOINT_MODE_POSITION
			end
			t2[particle]["defaults"] = defaults
			t2[particle]["on_model"] = on_model
			t2[particle]["sets_particle_pos"] = sets_particle_pos

		end
		for particle, _ in pairs (t2) do
			//Cull empty effects, or effects that are stuck at the world origin because they don't have any cpoints setting their particle pos.
			//Also, now that their parents have inherited cpoint data from them, cull effects with preventNameBasedLookup, since we can't spawn them on their own.
			//If the player starts up the game in developer mode, effects aren't culled, but instead have a warning on the spawnicon telling the dev why they won't show up to players.
			if (t2[particle].prevent_name_based_lookup or t2[particle]["renderer_emitter_shouldcull"] or !t2[particle]["sets_particle_pos"]) and GetConVarNumber("developer") < 1 then
				t2[particle] = nil
			end
		end
		for particle, _ in pairs (t2) do
			//Now that we're done setting cpoint defaults, apply cpoint data from children
			t2[particle].cpoints = t2[particle].cpoints_with_children
			t2[particle].cpoints_with_children = nil
			for k, v in pairs (t2[particle].cpoints) do
				//Fill in empty default entries
				if t2[particle].defaults[k] == nil then
					t2[particle].defaults[k] = PARTCTRL_CPOINT_MODE_NONE
				end
				//Squish together vector and axis entries that have the same values except for the name
				if v["vector"] and table.Count(v["vector"]) > 1 then
					local newvectors = {}
					for k2, v2 in pairs (v["vector"]) do
						if v["vector"][k2] != nil then
							local newtab = table.Copy(v2)
							for k3, v3 in pairs (v["vector"]) do
								if k3 != k2 and v3.label == v2.label and v3.inMin == v2.inMin and v3.inMax == v2.inMax
								and v3.outMin == v2.outMin and v3.outMax == v2.outMax then
									newtab.name = newtab.name .. ",\n" .. v3.name
									v["vector"][k3] = nil
								end
							end
							v["vector"][k2] = nil
							table.insert(newvectors, newtab)
						end
					end
					v["vector"] = newvectors
				end
				if v["axis"] and table.Count(v["axis"]) > 1 then
					local newvectors = {}
					for k2, v2 in pairs (v["axis"]) do
						if v["axis"][k2] != nil then
							local newtab = table.Copy(v2)
							for k3, v3 in pairs (v["axis"]) do
								if k3 != k2 and v3.label == v2.label and v3.inMin == v2.inMin and v3.inMax == v2.inMax
								and v3.outMin == v2.outMin and v3.outMax == v2.outMax and v3.axis == v2.axis then
									newtab.name = newtab.name .. ",\n" .. v3.name
									v["axis"][k3] = nil
								end
							end
							v["axis"][k2] = nil
							table.insert(newvectors, newtab)
						end
					end
					v["axis"] = newvectors
				end
			end
			
			//Store which PCFs this particle name is defined in - this is used to detect particles that are multiply defined and display a warning in the spawnicon
			//(do this last so we don't conflict with particles that have been culled)
			PartCtrl_PCFsByParticleName[particle] = PartCtrl_PCFsByParticleName[particle] or {}
			PartCtrl_PCFsByParticleName[particle][filename] = true
		end
		
		if table.Count(t2) == 0 then
			MsgN(filename, " contains no usable effects, ignoring")
		else
			return t2
		end
	end
end

//Comprehensive output testing: 
--[[
- All "output" and "output_axis":
- operator "set control point to player"
  - with the output and the attrib it overrides on the same effect, overrides everything unless noted
    - doesn't override attribs that use the associated model's bones/hitboxes/etc, because this output doesn't change the associated model, just pos/ang (intitializer "position on model random", operator "cull relative to model", operator "movement lock to bone")
    - doesn't override main table "control point to disable rendering if it is the camera", main table "cull_control_point"
    - (TODO: is this right? test output pileups on their own later, seems inconsistent) operator "remap cp speed to cp"'s output_axis erroneously always sends max output if "set control point to player"/"set control point to particles' center" is defined after it outputting to its input cpoint; "set control point to player"/"set control point positions" still outputs the same values if either a "set control point to player"/"set control point positions" is defined after it, outputting to its input cpoint and trying to move it
  - with the output on parent and the attrib it overrides on child, same as above
    - interactions with other outputs on the same cpoint, do we care about these?
      - operator "movement match particle velocities"'s output on same cpoint gets squashed by parent's output
      - operator "remap cp speed to cp"'s input cpoint, if moved by a parent output, measures the new cp's speed instead as expected
      - operator "set control point positions"'s input cpoint, if moved by a parent output, uses the new position instead as expected
      - operators "remap cp speed to cp"/"set control point positions"/"set control point to particles' center"/"set control point to player"'s output to a cpoint on child is NOT squashed by parent's output to the same cpoint (!) instead the child uses its own output for that cpoint, while the parent uses *its* own output for *its* cpoint, resulting in multiple cpoints with the same id in different places
  - with the output on child and the attrib it overrides on parent, doesn't override anything
    - also, output operators on the parent outputting to the same cpoint do not override the child's output either
- operator "remap cp speed to cp"
  - same as "set control point positions", but for just one axis
- operator "set control point positions", operator "set control point to particles' center"
  - same as "set control point to player", except:
    - doesn't override ang for attribs that use ang, because this output doesn't change ang, just pos (renderer "render_animated_sprites"s "orientation control point", constraint "prevent passing through a plane" if !attrib["global normal"], initializer "position along epitrochoid" "control point number" ang, initializer "position along ring" "control point number" ang, initializer "position from chaotic attractor" "Relative Control point number" ang, initializer "Position Within Sphere Random" "control_point_number" ang if "bias in local system" is in use, initializer "Position Modify Offset Random" "control_point_number" ang if "offset in local space 0/1" is in use) (TODO: check initializers after "position modify offset random", and all non-initializers)
      - any path stuff with attrib "bulge control 0=random 1=orientation of start pnt 2=orientation of end point" set to an overwritten cpoint (TODO check stuff before initializer; initializer "Position Along Path Random", initializer "Position Along Path Sequential", initializer "Position In CP Hierarchy"; TODO: check initializers after "position modify offset random")
      - cstrike_achieved and that one beany effect have cpoints being overwritten by "set control point positions" outputs that can still be rotated separately to move the effect around, but this doesn't seem to be a deliberate design feature, since this output is used to composite child fx together all the time. the right course of action here seems to be to omit the overwritten cpoints anyway, instead of keeping more grip points around that only set the angle.
- operator "movement match particle velocities"
  - same as "set control point to player", except:
    - with the output and the attrib it overrides on the same effect
      - if a position control exists for the output cpoint, overridable attribs will use the cpoint's pos/ang instead of it being overridden by the output pos/ang, except for the ones listed below. (if a position control doesn't exist, the value will be overridden by the output normally.)
	- renderer generic "Visibility Proxy Input Control Point Number" always overrides properly
	- operators will be overridden properly IF they're defined AFTER "movement match particle velocities" in the operators list
	- some initializers ("position along ring", "position in cp hierarchy", "position within box random", "position within sphere random", "position modify warp random", "remap scalar to vector" position, "velocity inherit from control point", "velocity repulse from world") appear to alternate every frame or so between the position control's value, and a point halfway between the position control and the output
	- if no particles exist, child cpoint's value reverts back to the position control value instead of the output value, otherwise overrides properly
    - with the output on parent and the attrib it overrides on child, all attribs have their pos overridden properly, but ang uses the position control's ang instead if available (except initializer "remap scalar to vector")
- All "output_children":
- operator "set child control points from particle positions"
    TODO
- initializer "velocity repulse from world"
    TODO
- Misc. notes:
- can't test initializer "position within sphere random" value "create in model" because it always crashes upon spawning any particles (blood_impact.pcf/blood_antlionguard_injured_light is the only default effect with this set, and it doesn't crash because it doesn't actually emit any particles); can't test initializers "set hitbox position on model" or "set hitbox to closest hitbox" because i can't get them to work at all, these are csgo? ports anyway)
- main table "control point to disable rendering if it is the camera" or "cull_control_point" don't work on children at all
]]

local utilfx_cpointvalues = {
	["angles"] = "util.Effect EffectData:SetAngles()",
	["normal"] = "util.Effect EffectData:SetNormal()",
	["attachment"] = "util.Effect EffectData:SetAttachment()",
	["entity"] = "util.Effect EffectData:SetEntity()",
	["origin"] = "util.Effect EffectData:SetOrigin()",
	["start"] = "util.Effect EffectData:SetStart()",
}

local utilfx_axisvalues = {
	[0] = "Scale",
	[1] = "Magnitude",
	[2] = "Radius",
}

local utilfx_axisvalues2 = {
	[0] = "Color",
}

function PartCtrl_ProcessUtilFx()

	local utilfx = list.GetForEdit("PartCtrl_UtilFx", true)
	local utilfx2
	PartCtrl_UtilFxByTitle = {}

	if istable(utilfx) then
		for k, v in pairs (utilfx) do
			local t = {
				["cpoints"] = {},
				["defaults"] = {},
				["info"] = v.info,
				["utilfx"] = true,
				["default_time"] = v.default_time,
				["on_model"] = v.on_model,
				["min_length"] = v.min_length
			}

			//Use the effect's DoProcess func to set up cpoints
			v.DoProcess(t, v.DoProcessExtras)

			//Set cpoint modes
			for k, v in pairs (t.cpoints) do
				if v["position"] then
					t.defaults[k] = PARTCTRL_CPOINT_MODE_POSITION
				elseif v["vector"] then
					t.defaults[k] = PARTCTRL_CPOINT_MODE_VECTOR
				elseif v["axis"] then
					t.defaults[k] = PARTCTRL_CPOINT_MODE_AXIS
				end
			end

			//Add to table of all utilfx by "title" value (what game or addon folder they're placed in)
			local function addtotab(str)
				PartCtrl_UtilFxByTitle[str] = PartCtrl_UtilFxByTitle[str] or {}
				PartCtrl_UtilFxByTitle[str][k] = true
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
			PartCtrl_UtilFxByTitle.All[k] = true

			utilfx2 = utilfx2 or {}
			utilfx2[k] = t
		end
	end

	//PrintTable(utilfx2)
	PartCtrl_ProcessedPCFs.UtilFx = utilfx2

end


//Normally, we only need to run this function once per session, when the entity code in ent_partctrl calls it. This ensures that it runs AFTER all the autorun code has had 
//a chance to run first and populate the blacklist. However, if the player mounts/unmounts something and calls the GameContentChanged hook, we want to run this again. This 
//function is really expensive (~16 sec freezing with a few games and particle addons installed), so we don't want to run it any more than we have to.
//
//This sounds simple, but here's what makes it more complicated: when a player starts a singleplayer game for the first time in a session, the GameContentChanged hook also
//runs on startup. On subsequent games that session, the hook WON'T run on startup. On the server, the GameContentChanged hook runs just AFTER the entity code, but on the 
//client, the hook runs just BEFORE the entity code. What we need to do is somehow ensure the function only runs once on startup, without knowing whether GameContentChanged
//will run on startup or not, and without knowing if GameContentChanged or the entity code will run first, AND do all of this without clobbering unrelated instances of 
//GameContentChanged being run AFTER startup.
//
//Our solution to this is to define a brief "startup" period, during which the function is only allowed to run once, and then after which it can run all it likes. This is 
//controlled by a timer.Simple in the entity code, which sets PartCtrl_ReadAndProcessPCFs_StartupIsOver to true after all the stuff mentioned in the last paragraph has had
//time to happen already.
//
//TODO: make sure this works in multiplayer

PartCtrl_ReadAndProcessPCFs_StartupHasRun = PartCtrl_ReadAndProcessPCFs_StartupHasRun
PartCtrl_ReadAndProcessPCFs_StartupIsOver = PartCtrl_ReadAndProcessPCFs_StartupIsOver

function PartCtrl_ReadAndProcessPCFs()

	PartCtrl_AllPCFPaths = {}
	local function PartCtrl_FindAllPCFPaths(dir)
		//TODO: implement blacklist
		local files, dirs = file.Find(dir .. "*", "GAME")
		for _, filename in pairs (files) do
			if string.EndsWith(filename, ".pcf") and !string.EndsWith(filename, "_dx80.pcf") and !string.EndsWith(filename, "_dx90_slow.pcf") and !string.EndsWith(filename, "_high.pcf") then
				table.insert(PartCtrl_AllPCFPaths, dir .. filename)
			end
		end
		for _, dirname in pairs (dirs) do
			PartCtrl_FindAllPCFPaths(dir .. dirname .. "/")
		end
	end
	PartCtrl_FindAllPCFPaths("particles/")
	
	PartCtrl_PCFsByParticleName = {}
	PartCtrl_ProcessedPCFs = {}
	for _, filename in pairs (PartCtrl_AllPCFPaths) do
		PartCtrl_ProcessedPCFs[filename] = PartCtrl_ProcessPCF(filename)
	end

	for filename, _ in pairs (PartCtrl_ProcessedPCFs) do
		PartCtrl_AddParticles(filename)
	end

	//add util fx to this table as well, so that particle entities and spawnicons can use them natively
	PartCtrl_ProcessUtilFx()

	PartCtrl_ReadAndProcessPCFs_StartupHasRun = true

end






























////////////////////////////
//SPAWNLIST POPULATOR CODE//
////////////////////////////

//Populate the spawn menu with a list of all the .pcf files, sorted by the game or addon they're from

local browseAddonParticles //these need to be outside the "if CLIENT then" block because they're also used by the shared GameContentChanged hook
local browseGameParticles
local searchParticles = nil
local RefreshAddonParticles
local RefreshGameParticles
	
if CLIENT then

	local function OnParticleNodeSelected(pcf, ViewPanel, pnlContent)

		ViewPanel:Clear(true)

		if !istable(PartCtrl_ProcessedPCFs[pcf]) then
			MsgN("OnParticleNodeSelected tried to make spawnlist for invalid pcf ", pcf)
		else
			for particle, _ in SortedPairs (PartCtrl_ProcessedPCFs[pcf]) do //use SortedPairs to sort them in alphabetical order
				spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["spawnname"] = pcf, ["nicename"] = particle})
			end
		end

		pnlContent:SwitchPanel(ViewPanel)
		ViewPanel.CurrentPCF = pcf //used by developer click-to-refresh-pcf function

	end

	local function OnUtilFxNodeSelected(name, ViewPanel, pnlContent)

		ViewPanel:Clear(true)

		if !istable(PartCtrl_UtilFxByTitle[name]) then
			MsgN("OnUtilFxNodeSelected tried to make spawnlist for invalid title ", name)
		else
			for particle, _ in SortedPairs (PartCtrl_UtilFxByTitle[name]) do //use SortedPairs to sort them in alphabetical order
				spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["spawnname"] = "UtilFx", ["nicename"] = particle})
			end
		end

		pnlContent:SwitchPanel(ViewPanel)
		ViewPanel.CurrentPCF = "UtilFx" //used by developer click-to-refresh-pcf function
		ViewPanel.CurrentUtilFxName = name //^

	end

	function PartCtrl_CreateCustomSpawnlist(tab, name, icon) //globally available so we can use it to make arbitrary spawnlists for testing

		local tab2 = {}
		for k, v in pairs (tab) do
			tab2[k] = {["type"] = "partctrl", ["spawnname"] = v.pcf, ["nicename"] = v.particle}
		end

		AddPropsOfParent(g_SpawnMenu.CustomizableSpawnlistNode.SMContentPanel, g_SpawnMenu.CustomizableSpawnlistNode, 0, {[name] = {
			icon = icon or "icon16/page.png",
			id = math.random( 0, 999999 ), -- Eeehhhh
			name = name,
			parentid = 0,
			contents = tab2
		}})
	
		-- We added a new spawnlist, show the save changes button
		hook.Run("SpawnlistContentChanged")

	end

	//Most of the spawnmenu code here this is ripped off wholesale from the Enhanced Spawnmenu addon - this is lame but I've gone over all the code and there's really no reason
	//to reinvent the wheel here, it does everything we need it to do

	local function AddBrowseContentParticle(node, name, icon, path, pathid, wsid)

		local ViewPanel = node.ViewPanel
		local pnlContent = node.pnlContent

		if !string.EndsWith(path, "/") && string.len(path) > 1 then path = path .. "/" end

		local fi, fo = file.Find(path .. "particles", pathid)
		if (!fi && !fo) and !PartCtrl_UtilFxByTitle[name] then return end

		local particles = node:AddFolder(name, path .. "particles", pathid, true, false, "*.*") //unlike ES, the arg after pathid is true, which adds nodes for files as well
		particles:SetIcon(icon)

		local oldcallback = particles.FilePopulateCallback
		particles.FilePopulateCallback = function(self, files, folders, foldername, path, bAndChildren, wildcard)
			oldcallback(self, files, folders, foldername, path, bAndChildren, wildcard)
			//Create unique node for utilfx
			if !particles.utilfxnode and PartCtrl_UtilFxByTitle[name] then
				//MsgN("making utilfx node for ", name)
				particles.utilfxnode = particles:AddNode("Scripted Effects", "icon16/page_gear.png")
				particles.utilfxnode.utilfx = true
				self.Expander:SetExpanded(false) //fix icon having a - instead of a + if this is the only node it contains
				particles.utilfxnode.DoRightClick = function()
					if !IsValid(particles.utilfxnode) then return end
					local menu = DermaMenu()

					menu:AddOption("#spawnmenu.createautospawnlist", function()
						local tab = {}
						for particle, _ in SortedPairs (PartCtrl_UtilFxByTitle[name]) do //use SortedPairs to sort them in alphabetical order
							table.insert(tab, {["pcf"] = "UtilFx", ["particle"] = particle})
						end
						PartCtrl_CreateCustomSpawnlist(tab, "Scripted Effects", "icon16/page_gear.png")
					end):SetIcon("icon16/page_add.png")

					//developer control to reload a .pcf file manually; we want this for utilfx too just in case one of the list entries was edited
					if GetConVarNumber("developer") >= 1 then
						menu:AddOption("Reload PartCtrl_UtilFx", function()
							net.Start("PartCtrl_ReloadPCF_SendToSv")
								net.WriteString("UtilFx")
							net.SendToServer()
						end)
					end

					menu:Open()
				end
			end
			for _, cnode in pairs (self:GetChildNodes()) do
				if cnode.utilfx then continue end
				if cnode.utilfx then MsgN("this shouldn't hapen") end
				local cname = cnode:GetFileName()
				local badname = false
				if cname then
					//Legacy addons will have a file path starting with the addon folder instead of the particle folder, so trim that stuff out
					//(i.e. turn addons/test_onlyparticles/particles/ukmovement.pcf into particles/ukmovement.pcf)
					if !string.StartsWith(cname, "particles/") then
						local start, _, _ = string.find(cname, "/particles/", 1, true) //this will break if someone names a legacy addon literally just "particles", OH WELL
						if start == nil then
							badname = true
						else
							cname = string.sub(cname, start + 1)
							cnode:SetFileName(cname)
						end
					end
					//Clear out .txt file particle manifests and such, also clear out bad .pcf files that weren't processed
					if !istable(PartCtrl_ProcessedPCFs[cname]) then badname = true end
				end
				if badname then
					cnode:Remove()
					self:InvalidateLayout()
				else
					if cname and string.EndsWith(cname, ".pcf") then
						cnode:SetIcon("icon16/page.png")
						cnode.DoRightClick = function()
							if !IsValid(cnode) then return end
							local menu = DermaMenu()

							menu:AddOption("Copy .pcf file path to clipboard", function() SetClipboardText(cname) end):SetIcon("icon16/page_copy.png")

							menu:AddOption("#spawnmenu.createautospawnlist", function()
								local tab = {}
								for particle, _ in SortedPairs (PartCtrl_ProcessedPCFs[cname]) do //use SortedPairs to sort them in alphabetical order
									table.insert(tab, {["pcf"] = cname, ["particle"] = particle})
								end
								PartCtrl_CreateCustomSpawnlist(tab, string.GetFileFromFilename(cname))
							end):SetIcon("icon16/page_add.png")

							//developer control to reload a .pcf file manually
							if GetConVarNumber("developer") >= 1 then
								menu:AddOption("Reload .pcf file", function()
									net.Start("PartCtrl_ReloadPCF_SendToSv")
										net.WriteString(cname)
									net.SendToServer()
								end)
							end

							menu:Open()
						end
					end
					cnode.FilePopulateCallback = particles.FilePopulateCallback //TODO: once we add blacklisting, test by blacklisting a .pcf file in a subfolder
				end
			end
			//clear out folders that generate empty - checking fi/fo up above doesn't work because some games (ep1) have empty tables even though they have files(??)
			//this looks kind of bad because you can see the folders appear and then disappear, but i don't know what a better solution would be
			if name != "#spawnmenu.category.downloads" and self:GetChildNodeCount() == 0 then
				self:Remove()
				node:InvalidateLayout()
			end
		end

		particles.OnNodeSelected = function(self, node_sel)
			local name2 = node_sel:GetFileName() //returns nil if the selected node was a folder - we only want files to be selectable
			if name2 != nil and string.find(name2, ".pcf") then
				OnParticleNodeSelected(name2, ViewPanel, pnlContent)
			elseif node_sel.utilfx then
				OnUtilFxNodeSelected(name, ViewPanel, pnlContent)
			end
		end

		if wsid then
			particles.DoRightClick = function()
				local menu = DermaMenu()
				menu:AddOption("#spawnmenu.openaddononworkshop", function()
					steamworks.ViewFile(wsid)
				end):SetIcon("icon16/link_go.png")
				menu:Open()
			end
		end

	end

	language.Add("spawnmenu.category.browseparticles", "Browse Particles")

	RefreshAddonParticles = function(node)
		for _, addon in SortedPairsByMemberValue(engine.GetAddons(), "title") do
			if !addon.downloaded then continue end
			if !addon.mounted then continue end
			if !table.HasValue(select(2, file.Find("*", addon.title)), "particles") and !PartCtrl_UtilFxByTitle[addon.title] then continue end
			AddBrowseContentParticle(node, addon.title, "icon16/bricks.png", "", addon.title, addon.wsid)
		end
	end
	RefreshGameParticles = function(node)
		local games = engine.GetGames()
		table.insert(games, {
			title = "All",
			folder = "GAME",
			icon = "all",
			mounted = true
		})
		table.insert(games, {
			title = "Garry's Mod",
			folder = "garrysmod",
			mounted = true
		})
		for _, game in SortedPairsByMemberValue(games, "title") do
			if !game.mounted then continue end
			AddBrowseContentParticle(node, game.title, "games/16/" .. (game.icon or game.folder) .. ".png", "", game.folder)
		end
	end

	hook.Add("PopulateContent", "PartCtrl_PopulateContent", function(pnlContent, tree, browseNode) timer.Simple(0.5, function()

		if (!IsValid(tree) or !IsValid(pnlContent) or !istable(PartCtrl_ProcessedPCFs)) then //check to make sure PartCtrl_ProcessedPCFs exists because AddBrowseContentParticle needs it
			print("ParticleControl: Failed to initialize PopulateContent hook")
			return
		end

		local ViewPanel = vgui.Create("ContentContainer", pnlContent)
		ViewPanel:SetVisible(false)
		ViewPanel.IconList:SetReadOnly(true) //not in enhanced spawnmenu; prevents contenticons in pcf spawnlists from being deleted using dropdown
		//Make these globally accessible so the developer pcf refresh button can access them
		PartCtrl_ViewPanel = ViewPanel
		ViewPanel.pnlContent = pnlContent

		local browseParticles = tree:AddNode("#spawnmenu.category.browseparticles", "icon16/fire.png")
		browseParticles.ViewPanel = ViewPanel
		browseParticles.pnlContent = pnlContent


		browseAddonParticles = browseParticles:AddNode("#spawnmenu.category.addons", "icon16/folder_database.png")
		browseAddonParticles.ViewPanel = ViewPanel
		browseAddonParticles.pnlContent = pnlContent

		RefreshAddonParticles(browseAddonParticles)


		local addon_particles = {}
		local _, particle_folders = file.Find("addons/*", "MOD")
		for _, addon in SortedPairs(particle_folders) do
			if !file.IsDir("addons/" .. addon .. "/particles/", "MOD") and !PartCtrl_UtilFxByTitle[addon] then continue end
			table.insert(addon_particles, addon)
		end

		local browseLegacyParticles = browseParticles:AddNode("#spawnmenu.category.addonslegacy", "icon16/folder_database.png")
		browseLegacyParticles.ViewPanel = ViewPanel
		browseLegacyParticles.pnlContent = pnlContent

		for _, addon in SortedPairsByValue(addon_particles) do
			AddBrowseContentParticle(browseLegacyParticles, addon, "icon16/bricks.png", "addons/" .. addon .. "/", "MOD")
		end


		AddBrowseContentParticle(browseParticles, "#spawnmenu.category.downloads", "icon16/folder_database.png", "download/", "MOD")


		browseGameParticles = browseParticles:AddNode("#spawnmenu.category.games", "icon16/folder_database.png")
		browseGameParticles.ViewPanel = ViewPanel
		browseGameParticles.pnlContent = pnlContent

		RefreshGameParticles(browseGameParticles)


		browseParticles:SetExpanded(true)

		MsgN("partctrl test: running PopulateContent")

	end) end)

	search.AddProvider(function(str)

		if searchParticles == nil then
			searchParticles = {}
			for pcf, _ in SortedPairs (PartCtrl_ProcessedPCFs) do
				for particle, _ in SortedPairs (PartCtrl_ProcessedPCFs[pcf]) do
					table.insert(searchParticles, {["name"] = particle, ["name_lower"] = particle:lower(), ["pcf"] = pcf}) //lowercase needs to be separate, because effect names are case-sensitive when spawning them
				end
			end
		end

		local results = {}

		for k, v in ipairs (searchParticles) do
			if v.name_lower:find(str, nil, true) or v.pcf:find(str, nil, true) then
				local entry = {
					text = v.name,
					icon = spawnmenu.CreateContentIcon("partctrl", g_SpawnMenu.SearchPropPanel, {["spawnname"] = v.pcf, ["nicename"] = v.name}),
					words = {v.name}
				}
				table.insert(results, entry)
				//entry.icon.IsInSearch = true //used by spawnicon code; TODO: stops working when the search is refreshed by the model search
				//MsgN("according to addprovider, g_SpawnMenu.SearchPropPanel is ", g_SpawnMenu.SearchPropPanel, " and icon is ", entry.icon)
			end
			if #results >= GetConVarNumber("sbox_search_maxresults") / 2 then break end
		end

		return results

	end, "partctrl")

	net.Receive("PartCtrl_ReloadPCF_SendToCl", function()
		local str = net.ReadString()
		//if GetConVarNumber("developer") < 1 then return false end
		if str != "UtilFx" then
			PartCtrl_ProcessedPCFs[str] = PartCtrl_ProcessPCF(str)
		else
			PartCtrl_ProcessUtilFx()
		end
		searchParticles = nil //force search to rebuild search cache so any new fx will be found
		MsgN("Reloading ", str, " on client ", LocalPlayer())

		//refresh spawnicons
		if istable(PartCtrl_AllContentIcons) and istable(PartCtrl_AllContentIcons[str]) then
			for k, _ in pairs (PartCtrl_AllContentIcons[str]) do
				if IsValid(k) then
					if k.Setup and k.pcf and k.name then
						k:Setup(k.pcf, k.name)
					end
				else
					PartCtrl_AllContentIcons[str][k] = nil 
				end
			end
		end

		//if this pcf's auto-generated spawnlist is currently open, then rebuild it (to handle fx being added to or removed from the list)
		if IsValid(PartCtrl_ViewPanel) and IsValid(PartCtrl_ViewPanel.pnlContent) then
			if PartCtrl_ViewPanel.pnlContent.SelectedPanel == PartCtrl_ViewPanel and PartCtrl_ViewPanel.CurrentPCF == str then
				//MsgN("we doin this")
				if str != "UtilFx" then
					OnParticleNodeSelected(str, PartCtrl_ViewPanel, PartCtrl_ViewPanel.pnlContent)
				else
					OnUtilFxNodeSelected(PartCtrl_ViewPanel.CurrentUtilFxName, PartCtrl_ViewPanel, PartCtrl_ViewPanel.pnlContent)
				end
			end
		end
	end)

else

	util.AddNetworkString("PartCtrl_ReloadPCF_SendToSv")
	util.AddNetworkString("PartCtrl_ReloadPCF_SendToCl")

	net.Receive("PartCtrl_ReloadPCF_SendToSv", function(_, ply)
		local str = net.ReadString()
		if GetConVarNumber("developer") < 1 then return false end
		if str != "UtilFx" then
			PartCtrl_ProcessedPCFs[str] = PartCtrl_ProcessPCF(str)
		else
			PartCtrl_ProcessUtilFx()
		end
		searchParticles = nil //force search to rebuild search cache so any new fx will be found
		MsgN("Reloading ", str, " on server")

		//now send the update to all players
		net.Start("PartCtrl_ReloadPCF_SendToCl")
			net.WriteString(str)
		net.Broadcast()
	end)
	
end










//Used by both pcf reading and spawnlist populator, or by panels/entities

hook.Add("GameContentChanged", "PartCtrl_GameContentChanged", function()
 
	//ReadAndProcessPCFs stuff
	if PartCtrl_ReadAndProcessPCFs_StartupIsOver or !PartCtrl_ReadAndProcessPCFs_StartupHasRun then
		PartCtrl_ReadAndProcessPCFs()
	end

	if CLIENT then
		//Spawnlist stuff from enhanced spawnmenu
		if IsValid(browseAddonParticles) then
			-- TODO: Maybe be more advaced and do not delete => recreate all the nodes, only delete nodes for addons that were removed, add only the new ones?
			browseAddonParticles:Clear()
			browseAddonParticles.ViewPanel:Clear(true)

			RefreshAddonParticles(browseAddonParticles)
		end
		if IsValid(browseGameParticles) then
			-- TODO: Maybe be more advaced and do not delete => recreate all the nodes, only delete nodes for addons that were removed, add only the new ones?
			browseGameParticles:Clear()
			browseGameParticles.ViewPanel:Clear(true)

			RefreshGameParticles(browseGameParticles)
		end

		//Search stuff
		searchParticles = nil
	end

	MsgN("partctrl test: running GameContentChanged")

end)

//wrapper for game.AddParticles - this way, a lot of spawnicons or particle entities created at once can all try to run game.AddParticles at the same time,
//but won't unnecessarily run it more than once for the same .pcf file at one time
//local AddParticles_Time = 0
local AddParticles_RecentlyAdded = {}
PartCtrl_AddParticles_CrashCheck = {}
PartCtrl_AddParticles_AddedParticles = PartCtrl_AddParticles_AddedParticles or {}
PartCtrl_AddParticles_AddedParticles_Overrides = PartCtrl_AddParticles_AddedParticles_Overrides or {}

function PartCtrl_AddParticles(pcf, effectname) //optional effectname arg for spawnicons and particle entities, which usually only care about conflicts with their one effect
	if !istable(PartCtrl_ProcessedPCFs[pcf]) then return end

	--[[local time = CurTime()
	//MsgN(time, " ", AddParticles_Time)
	if time > AddParticles_Time then
		AddParticles_RecentlyAdded = {}
	end]]
	local doaddparticles = false
	if !AddParticles_RecentlyAdded[pcf] then //don't bother running this more than once per pcf per frame (i.e. if we open a pcf spawnlist, every spawnicon will try to run this at once)
		AddParticles_RecentlyAdded[pcf] = true
		//MsgN("old PartCtrl_AddParticles_AddedParticles: ")
		//PrintTable(PartCtrl_AddParticles_AddedParticles)
		//We only want to run game.AddParticles if A: we haven't loaded this pcf before, 
		//or B: since we last loaded it, another pcf has been loaded that overrode one of its effects, so we load this one again to un-override the effect
		local key = table.KeyFromValue(PartCtrl_AddParticles_AddedParticles, pcf)
		if key == nil then
			//MsgN(pcf .. " hasn't been added before, time to do AddParticles")
			doaddparticles = true
		end
		//Get a list of all the pcfs that override one of our effects
		if !istable(PartCtrl_AddParticles_AddedParticles_Overrides[pcf]) then
			local tab = {}
			for name, _ in pairs (PartCtrl_ProcessedPCFs[pcf]) do
				for k, _ in pairs (PartCtrl_PCFsByParticleName[name]) do
					tab[k] = true
				end
			end
			tab[pcf] = nil
			PartCtrl_AddParticles_AddedParticles_Overrides[pcf] = tab
			//PrintTable(tab)
		end
		if !doaddparticles then
			local tab = {}
			if effectname then
				//If this function is being called by a spawnicon or particle entity, then only check its one effect for overrides.
				//Otherwise, we don't care, and running game.AddParticles(pcf) again would just cause an unnecessary stutter.
				for k, _ in pairs (PartCtrl_PCFsByParticleName[effectname]) do
					tab[k] = true
				end
				tab[pcf] = nil
				//MsgN("tab for effect ", effectname, ":")
				//PrintTable(tab)
			else
				tab = PartCtrl_AddParticles_AddedParticles_Overrides[pcf]
			end
			for k, v in SortedPairs (PartCtrl_AddParticles_AddedParticles) do
				if k > key and tab[v] then
					//MsgN(k .. " " .. v .. " is greater than " .. key .. " " .. pcf .. ", time to do AddParticles")
					doaddparticles = true
					break
				end
			end
		end
		//Get rid of the old table entry if we're going to add a new one
		if doaddparticles and key then
			table.remove(PartCtrl_AddParticles_AddedParticles, key)
		end
	end
	if doaddparticles then
		//Crash prevention:
		//Internally, when gmod loads a new pcf from game.AddParticles, and that pcf overrides any effect names, any existing particlesystems using those effects are forcibly stopped. If too 
		//many unique effects are stopped at once by the engine this way, it can crash. If our panel/entity code recreates them too soon after the engine stops them, it can also crash. 
		//Finally, if there are too many existing particlesystems that simply share a pcf with one being overridden, then it can also crash (why? the engine doesn't even remove these ones!).
		//To get around all this, we first remove all the offending particlesystems ourselves, then call game.AddParticles a frame later, after we can be sure they're all gone.
		for v, _ in pairs (PartCtrl_AddParticles_AddedParticles_Overrides[pcf]) do //by lucky coincidence, we already have a table of all the pcfs whose effects need to be removed
			if istable(PartCtrl_AddParticles_CrashCheck[v]) then
				for k2, v2 in pairs (PartCtrl_AddParticles_CrashCheck[v]) do
					if k2 and k2:IsValid() then
						PartCtrl_AddParticles_CrashCheck_PreventingCrash = true
						k2:StopEmissionAndDestroyImmediately()
					end
					PartCtrl_AddParticles_CrashCheck[v][k2] = nil
				end

			end
		end

		table.insert(PartCtrl_AddParticles_AddedParticles, pcf)
		//MsgN("new PartCtrl_AddParticles_AddedParticles: ")
		//PrintTable(PartCtrl_AddParticles_AddedParticles)
		//AddParticles_RecentlyAdded[pcf] = true
		if PartCtrl_AddParticles_CrashCheck_PreventingCrash then
			AddParticles_RecentlyAdded[pcf] = 2 //unique identifier for pcfs we've queued to load; the ones we aren't loading are just true
			timer.Create("PartCtrl_AddParticles_CrashCheck", 0.1, 1, function()
				for k, v in pairs (AddParticles_RecentlyAdded) do
					if v == 2 then
						game.AddParticles(k)
					end
				end
				PartCtrl_AddParticles_CrashCheck_PreventingCrash = false
				AddParticles_RecentlyAdded = {}
			end)
		else
			//If we're not preventing a crash, then just load the PCF and clear RecentlyAdded next frame to prevent the same PCF from being loaded multiple times in 1 frame
			//TODO: not sure if this is totally necessary any more; what conditions will still result in a PCF being loaded multiple times in 1 frame, but not trigger CrashCheck?
			timer.Simple(0, function()
				game.AddParticles(pcf)
				AddParticles_RecentlyAdded = {}
			end)
		end
	end
	AddParticles_Time = time
end

//test, make sure our custom gm hooks work
//MsgN("in autorun, GM = ", GM, ", GAMEMODE = ", GAMEMODE)
//hook.Add("PlayerSpawnParticle", "test", function() MsgN("fart") end)
//hook.Add("PlayerSpawnedParticle", "test", function() MsgN("fart2") end)

//Cleanup and limit
cleanup.Register("partctrl")
if SERVER then
	CreateConVar("sbox_maxpartctrl", "10", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Maximum particle effects a single player can create")
end










//Properties

if CLIENT then

	function OpenPartCtrlEditor(ent)

		if IsValid(ent.PartCtrlWindow) then return end

		local window = g_ContextMenu:Add("DFrame")
		window:SetSize(367, 400) //width of 367 nicely fits color picker
		window:Center()
		window:SetSizable(true)
		//window:SetMinHeight(h_min)
		//window:SetMinWidth(w_min)

		local control = window:Add("PartCtrlEditor")
		window.Control = control
		control:SetEntity(ent)
		control:Dock(FILL)

		PartCtrlEditors = PartCtrlEditors or {}
		table.insert(PartCtrlEditors, control)

		control.OnEntityLost = function()
			window:Remove()
		end

		//Fix: If the control window is created while the context menu is closed (by opening a control window with the attacher tool while holding Q) then it'll be unclickable
		//and get stuck on the screen until the entity is removed, so we have to manually enable mouse input here to stop that from happening
		window:SetMouseInputEnabled(true)
		control:SetMouseInputEnabled(true)

	end

end

//Make these funcs global so advbonemerge tool dropdown can use them too

PartCtrl_EditProperty_Filter = function(self, ent, ply)

	if !IsValid(ent) then return false end
	if !gamemode.Call("CanProperty", ply, "editpartctrl", ent) then return false end

	if !istable(ent.PartCtrl_ParticleEnts) then return false end
	local count = table.Count(ent.PartCtrl_ParticleEnts) 
	if count < 1 then return false end
	if count == 1 then
		for k, _ in pairs (ent.PartCtrl_ParticleEnts) do
			if !(IsValid(k) and k:GetClass() == "ent_partctrl" and k.GetPCF) then
				return false
			end
		end
	end

	return true

end

PartCtrl_EditProperty_MenuOpen = function(self, option, ent)

	//If the entity has one particle effect, then this property is an option to open a window for it; 
	//if it has multiple particle effects, then this property is a dropdown containing options for each one

	if table.Count(ent.PartCtrl_ParticleEnts) == 1 then

		for k, _ in pairs (ent.PartCtrl_ParticleEnts) do
			option:SetText("Edit Particle Effect (" .. k:GetParticleName() .. ")")
			option.DoClick = function() OpenPartCtrlEditor(k) end
		end

	else
		
		local submenu = option:AddSubMenu()
		for k, _ in pairs (ent.PartCtrl_ParticleEnts) do
			if IsValid(k) and k:GetClass() == "ent_partctrl" and k.GetPCF then
				local opt = submenu:AddOption(k:GetParticleName())
				opt.DoClick = function() OpenPartCtrlEditor(k) end
			end
		end

	end

end

properties.Add("editpartctrl", {
	MenuLabel = "Edit Particle Effects..",
	Order = 90000, //for reference, edit properties is 90001 and edit animprop is 90002
	PrependSpacer = true,
	MenuIcon = "icon16/fire.png", //TODO: better icon?
	
	Filter = PartCtrl_EditProperty_Filter,

	MenuOpen = PartCtrl_EditProperty_MenuOpen,

	Action = function(self, ent)
	
		//Nothing, set by MenuOpen

	end
})

//Developer properties for table dumps to console

properties.Add("partctrl_dev_printpcfdata", {
	MenuLabel = "Print raw PCF data for this effect",
	Order = 90000.51, //this works, incredible
	PrependSpacer = false,
	MenuIcon = nil,
	
	Filter = function(self, ent, ply)

		if GetConVarNumber("developer") < 1 then return false end
		if !IsValid(ent) then return false end
		if !istable(ent.PartCtrl_ParticleEnts) or table.Count(ent.PartCtrl_ParticleEnts) != 1 then return false end

		return true

	end,

	Action = function(self, ent)
	
		for k, _ in pairs (ent.PartCtrl_ParticleEnts) do
			if IsValid(k) then
				if k:GetPCF() == "UtilFx" then MsgN("UtilFx isn't a real pcf, doofus!") return end
				MsgN("PartCtrl_ReadPCF(\"" .. k:GetPCF() .. "\")[\"" .. k:GetParticleName() .. "\"]:")
				PrintTable(PartCtrl_ReadPCF(k:GetPCF())[k:GetParticleName()])
				MsgN()
			end
		end

	end
})

properties.Add("partctrl_dev_printprocessed", {
	MenuLabel = "Print processed PCF data for this effect",
	Order = 90000.52,
	PrependSpacer = false,
	MenuIcon = nil,
	
	Filter = function(self, ent, ply)

		if GetConVarNumber("developer") < 1 then return false end
		if !IsValid(ent) then return false end
		if !istable(ent.PartCtrl_ParticleEnts) or table.Count(ent.PartCtrl_ParticleEnts) != 1 then return false end

		return true

	end,

	Action = function(self, ent)
	
		for k, _ in pairs (ent.PartCtrl_ParticleEnts) do
			if IsValid(k) then
				MsgN("PartCtrl_ProcessedPCFs[\"" .. k:GetPCF() .. "\"][\"" .. k:GetParticleName() .. "\"]:")
				PrintTable(PartCtrl_ProcessedPCFs[k:GetPCF()][k:GetParticleName()])
				MsgN()
			end
		end

	end
})

properties.Add("partctrl_dev_printparticleinfo", {
	MenuLabel = "Print ParticleInfo (settings on this entity)",
	Order = 90000.53,
	PrependSpacer = false,
	MenuIcon = nil,
	
	Filter = function(self, ent, ply)

		if GetConVarNumber("developer") < 1 then return false end
		if !IsValid(ent) then return false end
		if !istable(ent.PartCtrl_ParticleEnts) or table.Count(ent.PartCtrl_ParticleEnts) != 1 then return false end

		return true

	end,

	Action = function(self, ent)
	
		for k, _ in pairs (ent.PartCtrl_ParticleEnts) do
			if IsValid(k) then
				MsgN(k, ".ParticleInfo:")
				PrintTable(k.ParticleInfo)
				MsgN()
			end
		end

	end
})




//Show attachments when hovering over or selecting a model with the particle attacher tool, or when hovering over attachment sliders in the edit window
if CLIENT then
	local colorborder = Color(0,0,0,255)
	local colorselect = Color(0,255,0,255)
	local colorunselect = Color(255,255,255,255)

	hook.Add("HUDPaint", "PartCtrl_HUDPaint_DrawAttachments", function()
		local ply = LocalPlayer()
		local ent = nil 
		local attachnum = 0

		//First, check if we're hovering over an attachment slider from our edit window
		local hov = vgui:GetHoveredPanel()
		if IsValid(hov) and istable(hov.PartCtrl_AttachSlider) then
			ent = hov.PartCtrl_AttachSlider.ent
			attachnum = hov.PartCtrl_AttachSlider.attach
		end

		//If that didn't work, then check our attacher tool
		if !IsValid(ent) then
			local function get_active_tool(ply, tool)
				-- find toolgun
				local activeWep = ply:GetActiveWeapon()
				if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end

				return activeWep:GetToolObject(tool)
			end

			local tool = get_active_tool(ply, "partctrl_attacher")
			if tool then
				ent = tool.HighlightedEnt
				attachnum = tool:GetClientNumber("attachnum", 0)
			end
		end

		if IsValid(ent) then
			local function DrawHighlightAttachments()
				//If there aren't any attachments, then draw the model origin as selected and stop here:
				if !ent:GetAttachments() or !ent:GetAttachments()[1] then
					local _pos,_ang = ent:GetPos(), ent:GetAngles()
					local _pos = _pos:ToScreen()
					local textpos = {x = _pos.x+5,y = _pos.y-5}

					draw.RoundedBox(0,_pos.x - 3,_pos.y - 3,6,6,colorborder)
					draw.RoundedBox(0,_pos.x - 1,_pos.y - 1,2,2,colorselect)
					draw.SimpleTextOutlined("0: (origin)","Default",textpos.x,textpos.y,colorselect,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM,2,colorborder)

					return
				end

				//Draw the unselected model origin, if applicable:
				if ent:GetAttachments()[attachnum] then
					local _pos,_ang = ent:GetPos(), ent:GetAngles()
					local _pos = _pos:ToScreen()
					local textpos = {x = _pos.x+5,y = _pos.y-5}

					draw.RoundedBox(0,_pos.x - 2,_pos.y - 2,4,4,colorborder)
					draw.RoundedBox(0,_pos.x - 1,_pos.y - 1,2,2,colorunselect)
					draw.SimpleTextOutlined("0: (origin)","Default",textpos.x,textpos.y,colorunselect,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM,1,colorborder)
				end

				//Draw the unselected attachment points:
				for _, table in pairs(ent:GetAttachments()) do
					local _pos,_ang = ent:GetAttachment(table.id).Pos,ent:GetAttachment(table.id).Ang
					local _pos = _pos:ToScreen()
					local textpos = {x = _pos.x+5,y = _pos.y-5}

					if table.id != attachnum then
						draw.RoundedBox(0,_pos.x - 2,_pos.y - 2,4,4,colorborder)
						draw.RoundedBox(0,_pos.x - 1,_pos.y - 1,2,2,colorunselect)
						draw.SimpleTextOutlined(table.id ..": ".. table.name,"Default",textpos.x,textpos.y,colorunselect,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM,1,colorborder)
					end
				end
				
				//Draw the selected attachment point or model origin last, so it renders above all the others:
				if !ent:GetAttachments()[attachnum] then
					//Model origin
					local _pos,_ang = ent:GetPos(), ent:GetAngles()
					local _pos = _pos:ToScreen()
					local textpos = {x = _pos.x+5,y = _pos.y-5}

					draw.RoundedBox(0,_pos.x - 3,_pos.y - 3,6,6,colorborder)
					draw.RoundedBox(0,_pos.x - 1,_pos.y - 1,2,2,colorselect)
					draw.SimpleTextOutlined("0: (origin)","Default",textpos.x,textpos.y,colorselect,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM,2,colorborder)
				else
					//Attachment
					local _pos,_ang = ent:GetAttachment(attachnum).Pos,ent:GetAttachment(attachnum).Ang
					local _pos = _pos:ToScreen()
					local textpos = {x = _pos.x+5,y = _pos.y-5}

					draw.RoundedBox(0,_pos.x - 3,_pos.y - 3,6,6,colorborder)
					draw.RoundedBox(0,_pos.x - 1,_pos.y - 1,2,2,colorselect)
					draw.SimpleTextOutlined(attachnum ..": ".. ent:GetAttachments()[attachnum].name,"Default",textpos.x,textpos.y,colorselect,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM,2,colorborder)
				end
			end
			DrawHighlightAttachments()
		end
	end)
end

if CLIENT then
	//Stupid fix: the first time PrecacheParticleSystem is run by anything, it will cause a substantial stutter, 
	//so get it over with during map load instead of disrupting gameplay the first time the player opens a spawnlist or something.
	timer.Simple(0, function()
		PrecacheParticleSystem("")
	end)
end
MsgN("partctrl test: running autorun")