//Convars:

if SERVER then
	CreateConVar("sv_partctrl_particlesperent", 32, FCVAR_REPLICATED, "Max number of effect instances (or projectiles) that a single particle effect entity can have active at once.", 1)
	//Assume that most servers won't want serverside projectile fx because they're too easy to grief with, 
	//and won't want ReadPCF caching because we can't assume connecting clients will use this addon more than once.
	//Is this right? No idea, I don't run a server.
	local int_sp
	if game.SinglePlayer() then
		int_sp = 1
	else
		int_sp = 0
	end
	CreateConVar("sv_partctrl_allowserverprojectiles", int_sp, FCVAR_REPLICATED, "If 0, disables the serverside projectiles option on projectile effects.", 0, 1)
	CreateConVar("sv_partctrl_cachereadpcf", int_sp, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "If 1, the results of PartCtrl_ReadPCF are cached to the data folder. This makes subsequent startups 2-3x faster, but the first time quite a bit slower as it saves ~50MB to the data folder.", 0, 1)
else
	//Some convars to separate child fx from others; in practice, this doesn't work well because there are 
	//A: lots of normal fx that are also used as children, and would be excluded (i.e. eye_powerup_green_lvl_3, rocket_explosion_classic, rocket_trail_classic_crit_red, many more) 
	//and B: lots of unused child fx that were removed from their parents, and so end up cluttering up the parent fx lists anyway (too many to list), 
	//so these features are disabled by default.
	CreateClientConVar("cl_partctrl_childfx_in_autospawnlists", 2, false, false, "Sets how child particle effects appear in auto-generated .pcf spawnlists.\n0: Child effects are hidden\n1: Child effects are sorted into a separate category\n2: Child effects are listed alongside parent effects", 0, 2)
	CreateClientConVar("cl_partctrl_childfx_in_search", 1, false, false, "If 0, prevents child particle effects from being shown in search results.", 0, 1)

	CreateClientConVar("cl_partctrl_dupes_in_search", 0, false, false, "If 0, prevents duplicate effects from being shown in search results.", 0, 1)
end

 








//Blacklist bad .pcf files and effects from being loaded by the addon

//The actual .pcf loading is done inside of ent_partctrl.lua, because entity code always runs after autorun code -
//we want to be sure every addon that wants to add to the blacklist has the chance to do so before the .pcf files actually get read.

local tf2_unusual_wep_pcfs = {
	["particles/weapon_unusual_cool.pcf"] = true,
	["particles/weapon_unusual_energyorb.pcf"] = true,
	["particles/weapon_unusual_hot.pcf"] = true,
	["particles/weapon_unusual_isotope.pcf"] = true
}
local tf2_unusual_wep_blacklist_text = "Blacklisted: _unusual_parent_ fx are all useless duplicates of other unusual weapon fx with conflicting names"
local crash_blacklist_text = "Blacklisted: causes crash when spawned"
local default_blacklist = {
	//Portal 2
	["particles/chicken.pcf"] = {
		blacklist = {
			feathers_large = crash_blacklist_text,
			feathers_single = crash_blacklist_text,
			feathers_small = crash_blacklist_text,
		}
	},
	//TF2 map particles addon
	["particles/nucleus_event_effects.pcf"] = {
		blacklist = {
			nucleus_core_steady = "Blacklisted: dupe of nucleus_event_core_steady, except it conflicts with a stock tf2 effect" //note: only reason this doesn't override the desired effect on koth_nucleus is because the game arbitrarily reads particles/level_fx.pcf after this one, which sucks; this isn't an issue on pd_circus because it doesn't actually use this effect
		}
	},
	["particles/brine_salmann_goop.pcf"] = {
		blacklist = {
			blood_impact_green_01 = "Blacklisted: override that's actually a copy of tf2's blood_impact_red_01, for salmann skeleton reskins"
		},
	},
}
hook.Add("PartCtrl_PostProcessPCF", "default_blacklist", function(filename, tab)
	if tf2_unusual_wep_pcfs[filename] then
		for k, v in pairs (tab) do
			if string.StartsWith(k, "_unusual_parent_") then
				tab[k].shouldcull = tf2_unusual_wep_blacklist_text
			end
		end
	end
	if default_blacklist[filename] then
		for k, v in pairs (tab) do
			//if blacklist is present, blacklist all listed fx
			if default_blacklist[filename].blacklist and default_blacklist[filename].blacklist[k] then
				tab[k].shouldcull = default_blacklist[filename].blacklist[k]
			end
			//if whitelist is present, blacklist all fx in the pcf *except* the ones listed
			if default_blacklist[filename].whitelist and !default_blacklist[filename].whitelist[k] then
				tab[k].shouldcull = default_blacklist[filename].whitelist_fail
			end
		end
	end
end)


//Default comments for unintuitive fx
local stove_comment = "Control point 1 pushes the flame away; it's very subtle"
local tooclose_comment = "Not visible if too close to the camera"
local cullplane1_comment = "Control point 1 controls max height of particles"
local cullplane1_bubble_comment = "Control point 1 controls max height of bubbles"
local cullplane1_reverse_comment = "Control point 1 controls minimum height of particles"
local default_comments = {
	//Default
	["particles/fire_01.pcf"] = {
		burning_vehicle = tooclose_comment //also it doesn't render if hl2 isn't mounted, because that's where the vmt is, but that doesn't seem reasonable to check for
	},
	["particles/water_impact.pcf"] = {
		water_bubble_trail_1 = cullplane1_bubble_comment
	},
	//Team Fortress 2
	["particles/halloween2024_unusuals.pcf"] = {
		unusual_stove_flame_point_1 = stove_comment,
		unusual_stove_flame_point_1_red = stove_comment,
		unusual_stove_flame_point_2 = stove_comment,
		unusual_stove_flame_point_2_red = stove_comment,
		unusual_stove_flame_point_3 = stove_comment,
		unusual_stove_flame_point_3_red = stove_comment,
		unusual_stove_flame_point_4 = stove_comment,
		unusual_stove_flame_point_4_red = stove_comment,
		unusual_stove_flame_point_5 = stove_comment,
		unusual_stove_flame_point_5_red = stove_comment,
		unusual_stove_flame_point_6 = stove_comment,
		unusual_stove_flame_point_6_red = stove_comment,
		unusual_stove_flame_point_7 = stove_comment,
		unusual_stove_flame_point_7_red = stove_comment,
		unusual_stove_flame_point_8 = stove_comment,
		unusual_stove_flame_point_8_red = stove_comment,
	},
	["particles/coin_spin.pcf"] = {
		coin_spin = "Only creates particles while moving"
	},
	["particles/stamp_spin.pcf"] = {
		Stamp_spin = "Only creates particles while moving"
	},
	["particles/taunt_fx.pcf"] = {
		taunt_demo_nuke_brew = cullplane1_comment,
		taunt_demo_nuke_powder = cullplane1_comment,
	},
	["particles/water.pcf"] = {
		water_playerdive = cullplane1_bubble_comment,
		water_playerdive_bubbles = cullplane1_bubble_comment,
		water_splash_croc_spawn_droplets = cullplane1_reverse_comment,
	},
	["particles/rockettrail.pcf"] = {
		rockettrail_underwater = cullplane1_bubble_comment,
		rockettrail_waterbubbles = cullplane1_bubble_comment,
	},
	//Portal
	["particles/neurotoxins.pcf"] = {
		neurotoxins_step1 = tooclose_comment,
	},
	["particles/portals.pcf"] = {
		Portal_1_vacuum = tooclose_comment,
		portal_2_vacuum = tooclose_comment,
		portal_1_particles = tooclose_comment,
		portal_2_particles = tooclose_comment,
	},
	["particles/tubes.pcf"] = {
		broken_tube_suck_b = tooclose_comment,
	},
	["particles/portal_projectile.pcf"] = {
		portal_2_overlap_ = "Control point 1 pushes particles away"
	},
	//TF2 map particles addon
	["particles/koth_probed_fx.pcf"] = {
		alien_abduction_glow2 = tooclose_comment
	},
	//Invasion mashup pack addon
	["particles/alien_fantasmos_fx2_extras.pcf"] = { 
		alien_jumppad_centerglow3 = "Control point 0 pulls particles toward itself; it's very subtle"
	},
}
function PartCtrl_AppendInfoText(effecttab, str) //global function so other addons using this hook can use it
	if !effecttab.info then
		effecttab.info = ""
	else
		effecttab.info = effecttab.info .. "\n"
	end
	effecttab.info = effecttab.info .. str
end
hook.Add("PartCtrl_PostProcessPCF", "default_comments", function(filename, tab)
	if default_comments[filename] then
		for k, v in pairs (tab) do
			if default_comments[filename][k] then
				PartCtrl_AppendInfoText(tab[k], default_comments[filename][k])
			end
		end
	end
end)










//Add util fx

//Example:
--[[list.Add("PartCtrl_UtilFx", "EffectName", { //Name of the effect that util.Effect() will call
	title = "Garry's Mod",	//String; in the "Browse Particles" spawnlist, any game, addon, or legacy addon with this exact folder name will get a "Scripted Effects" subfolder containing this effect
	title = {"MyCoolAddon", "My Cool Addon: Workshop Edition"}, //Can also be a table of strings instead, just in case you want to, say, support both a legacy addon folder name and a workshop addon name
	
	default_time = 1,	//Float, default setting of "seconds between repeats" on newly spawned fx, should roughly correspond to how long it takes for the effect to "finish", defaults to 1 if absent
	info = "Text text text",//String, optional, adds extra info to the spawnicon and edit window
	info_sfx = "Text text", //String, optional, alternative info text used instead of the above if attached to a special effect (tracer/beam/projectile)
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
	DoProcessExtras = {["scale_max"] = 50}, //Table, optional; this sets the "extras" arg for the DoProcess func, so that multiple fx with different values can use the same function

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
local needs_model = "Must be attached to a model"

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

//all this one's code is commented out, does literally nothing (https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/hl2/hud_blood.cpp#L34)
--[[list.Set("PartCtrl_UtilFx", "HudBloodSplat", {
	title = {"Garry's Mod", "Half-Life 2 & Episodes"},
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
		title = {"Garry's Mod", "Half-Life: Source"},
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
		title = {"Garry's Mod", "Half-Life: Source"},
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
	title = {"Garry's Mod", "Half-Life: Source"},
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
	title = {"Garry's Mod", "Half-Life: Source"},
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
	title = {"Garry's Mod", "Half-Life: Source"},
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
	title = {"Garry's Mod", "Half-Life: Source"},
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
	title = {"Garry's Mod", "Half-Life: Source"},
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
	title = {"Garry's Mod", "Half-Life: Source"},
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
	title = {"Garry's Mod", "Half-Life: Source"},
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
	title = {"Garry's Mod", "Half-Life: Source"},
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
	title = {"Garry's Mod", "Counter-Strike: Source"},
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
	title = {"Garry's Mod", "Counter-Strike: Source"},
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
	title = {"Garry's Mod", "Counter-Strike: Source"},
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
	info = "No visible particles, makes ropes move",
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
	min_length = 256,
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

































//////////////////////////
//.PCF FILE READING CODE//
//////////////////////////

//Custom version of SortedPairs to sort by table key, but caps-agnostically (see original: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/table.lua#L539-L576)
//This is used to match how the particle editor sorts particle names, so we don't sort capitalized particles above uncapitalized ones.
local function SortedPairsLower(pTable)

	local keys = table.GetKeys(pTable) //use the global getkeys instead of the local one used in the SortedPairs code, so we don't have to copy as much

	//if ( Desc ) then //we don't care about this
	//	table.sort( keys, function( a, b )
	//		return string.lower(a) > string.lower(b) 
	//	end )
	//else
		table.sort( keys, function( a, b )
			return string.lower(a) < string.lower(b) //this is the only functional change
		end )
	//end

	local i, key = 1, nil
	return function()
		key, i = keys[ i ], i + 1
		return key, pTable[ key ]
	end

end

//silly pretend enums
PARTCTRL_CPOINT_MODE_NONE		= 0
PARTCTRL_CPOINT_MODE_POSITION		= 1
PARTCTRL_CPOINT_MODE_VECTOR		= 2
PARTCTRL_CPOINT_MODE_AXIS		= 3
PARTCTRL_CPOINT_MODE_POSITION_COMBINE	= 4
//for networking convenience
partctrl_cpointbits = 7 //-1 - 63

partctrl_wait = "wait" //another convenient global, used by particlesystems that can't currently be created (due to CrashCheck or a disabled particle entity) but should be created as soon as possible

//for vector/axis cpoints; names and comments from https://github.com/SourceSDK2013Ports/csgo-src/blob/main/src/public/particles/particles.h#L78
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
PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_INDEX = 14 // hit box index
PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_RELATIVE_XYZ = 15
PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA2 = 16
PARTCTRL_PARTICLE_ATTRIBUTE_SCRATCH_VEC = 17 //scratch field used for storing arbitraty vec data
PARTCTRL_PARTICLE_ATTRIBUTE_SCRATCH_FLOAT = 18 //scratch field used for storing arbitraty float data	
PARTCTRL_PARTICLE_ATTRIBUTE_UNUSED = 19
PARTCTRL_PARTICLE_ATTRIBUTE_PITCH = 20
PARTCTRL_PARTICLE_ATTRIBUTE_NORMAL = 21 // 0 0 0 if none
PARTCTRL_PARTICLE_ATTRIBUTE_GLOW_RGB = 22 // glow color
PARTCTRL_PARTICLE_ATTRIBUTE_GLOW_ALPHA = 23 // glow alpha
//old attributes from pre-csgo particles https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/public/particles/particles.h#L62
//PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P0 = 17 // particle trace caching fields // start pnt of trace
//PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P1 = 18 // end pnt of trace
//PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_T = 19 // 0..1 if hit
//PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL = 20 // 0 0 0 if no hit
local ParticleAttributeNames = { //names and comments from https://github.com/SourceSDK2013Ports/csgo-src/blob/main/src/particles/particles.cpp#L3782
	[PARTCTRL_PARTICLE_ATTRIBUTE_XYZ] = "Position", // XYZ, 0
	[PARTCTRL_PARTICLE_ATTRIBUTE_LIFE_DURATION] = "Life Duration", // LIFE_DURATION, 1 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_PREV_XYZ] = "Position Previous", // PREV_XYZ 
	[PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS] = "Radius", // RADIUS, 3 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_ROTATION] = "Roll", // ROTATION, 4 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_ROTATION_SPEED] = "Roll Speed", // ROTATION_SPEED, 5 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB] = "Color", // TINT_RGB, 6 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA] = "Alpha", // ALPHA, 7 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_CREATION_TIME] = "Creation Time", // CREATION_TIME, 8 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER] = "Skin", //better display name, technically inaccurate but players are more likely to understand what this means; original: "Sequence Number", // SEQUENCE_NUMBER, 9 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_TRAIL_LENGTH] = "Trail Length", // TRAIL_LENGTH, 10 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_PARTICLE_ID] = "Particle ID", // PARTICLE_ID, 11 ); 
	[PARTCTRL_PARTICLE_ATTRIBUTE_YAW] = "Yaw", // YAW, 12 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1] = "Skin", //better display name, technically inaccurate but players are more likely to understand what this means; original: "Sequence Number 1", // SEQUENCE_NUMBER1, 13 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_INDEX] = "Hitbox Index", // HITBOX_INDEX, 14
	[PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_RELATIVE_XYZ] = "Hitbox Offset Position", // HITBOX_XYZ_RELATIVE 15
	[PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA2] = "Alpha", //better display name, there's no difference between the two alphas as far as players are concerned; original: "Alpha Alternate", // ALPHA2, 16
	[PARTCTRL_PARTICLE_ATTRIBUTE_SCRATCH_VEC] = "Scratch Vector", // SCRATCH_VEC 17
	[PARTCTRL_PARTICLE_ATTRIBUTE_SCRATCH_FLOAT] = "Scratch Float", // SCRATCH_FLOAT 18
	[PARTCTRL_PARTICLE_ATTRIBUTE_UNUSED] = "Unused Particle Attribute", //NULL,
	[PARTCTRL_PARTICLE_ATTRIBUTE_PITCH] = "Pitch", // PITCH, 20
	[PARTCTRL_PARTICLE_ATTRIBUTE_NORMAL] = "Normal", // NORMAL, 21
	[PARTCTRL_PARTICLE_ATTRIBUTE_GLOW_RGB] = "Glow RGB", //GLOW_RGB,22 //i don't think these last two are implemented in gmod, actually?
	[PARTCTRL_PARTICLE_ATTRIBUTE_GLOW_ALPHA] = "Glow Alpha", //GLOW_ALPHA,23
	//old attributes from pre-csgo particles https://github.com/nillerusr/source-engine/blob/master/particles/particles.cpp#L3026
	//[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P0] = "PARTICLE_ATTRIBUTE_TRACE_P0 (internal)",
	//[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P1] = "PARTICLE_ATTRIBUTE_TRACE_P1 (internal)",
	//[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_T] = "PARTICLE_ATTRIBUTE_TRACE_HIT_T (internal)",
	//[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL] = "PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL (internal)"
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

local cache_version = "1" //update this in case ReadPCF is updated to return a different table
local docache = GetConVar("sv_partctrl_cachereadpcf")

function PartCtrl_ReadPCF(filename, path)

	//don't print non-critical messages unless we're in developer mode; 
	//always print messages for bugs that player should report
	local dodebug = (GetConVarNumber("developer") >= 1)

	local checksum
	if docache:GetBool() then
		//If possible, load the results of this function from cache instead. This makes PartCtrl_ReadAndProcessPCFs 2-3x faster on all subsequent
		//startups (compared to without caching), but makes the very first load quite a bit slower as we save the files to the cache, and also adds
		//approx. 50MB to the data folder (because of how BIG tf2's pcfs are!).
		checksum = file.Read(filename, path or "GAME")
		if !checksum then MsgN("PartCtrl: ", filename, " (", path or "GAME", ") can't be read, report this bug!") return end
		checksum = util.SHA256(checksum) //if the pcf file is updated, then the checksum will be different; this stops us from loading outdated data
		local cached_file = file.Read("partctrl_cache_" .. cache_version ..  "/" .. filename .. "/" .. checksum .. ".txt", "DATA")
		if cached_file then
			//"true" arg below stops it from converting all table keys from strings to numbers where possible.
			//this prevents edge cases where an effect just named a number can get converted into a bad name, and doesn't 
			//*seem* to cause any issues with sequential subtables like operator lists, but keep an eye on this just in case.
			cached_file = util.JSONToTable(cached_file, false, true)
			//PrintTable(cached_file)
			if cached_file then 
				if dodebug then MsgN("PartCtrl: ", filename, " loading from cache") end
				return cached_file
			end
		end
	end

	local f = file.Open(filename, "rb", path or "GAME")
	if !f then MsgN("PartCtrl: ", filename, " (", path or "GAME", ") can't be opened, report this bug!") return end
	//path arg is only used by PartCtrl_GetPCFConflicts, don't worry about it past this point

	//If the pcf is packed into the current map, then write a copy of it into the data folder and read that instead.
	//This is necessary because performing read operations on packed files takes a very long time (only if the map file is compressed, but we don't have 
	//a way to check for that); pd_watergate's *7* packed pcfs add *10 whole minutes* to the load time if we don't cache them like this!
	if file.Exists(filename, "BSP") then
		if dodebug then MsgN("PartCtrl: ", filename, " is packed into the current BSP file, caching") end
		if file.Write("temp_partctrl_readpcfcache.txt", f:Read()) then
			f = file.Open("temp_partctrl_readpcfcache.txt", "rb", "DATA")
			if !f then MsgN("PartCtrl: ", filename, " cache was written, but can't be read; report this bug!") return end
		else
			MsgN("PartCtrl: ", filename, " was unable to be cached; report this bug!")
			return
		end
	end
	//we *could* run file.Delete("temp_partctrl_readpcfcache.txt", "DATA") after we're done with it, but that doesn't seem necessary; 
	//there's only ever one of these files at a time and they're not that big, it'd just be another write operation on the user's HD for no benefit

	local version
	local header = ReadUntilNull(f)
	//MsgN(header)
	if header == "<!-- dmx encoding binary 2 format pcf 1 -->\n" //used by all orange box pcfs
	or header == "<!-- dmx encoding binary 2 format dmx 1 -->\n" //only used by css's fire_medium_01.pcf, appears to be identical to orangebox's binary 2 format pcf 1
	or header == "<!-- dmx encoding binary 3 format pcf 1 -->\n" //only used by portal 2's clouds.pcf
	or header == "<!-- dmx encoding binary 3 format pcf 2 -->\n" //used by a few portal 2 pcfs; this and the above don't seem to have any formatting differences from binary 2
	then 
		version = 2
	elseif header == "<!-- dmx encoding binary 4 format pcf 2 -->\n" then //only used by by l4d2 pcfs?
		version = 4
	elseif header == "<!-- dmx encoding binary 5 format pcf 2 -->\n" then //used by most portal 2 pcfs and all(?) alien swarm pcfs
		version = 5
	else
		if dodebug then MsgN("PartCtrl: ", filename, " has unsupported pcf format ", string.TrimRight(header, "\n"), ", ignoring") end
		return
	end


	local nStrings
	if version <= 3 then
		nStrings = f:ReadUShort() //this is a short in DMX version 2 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
	else
		nStrings = f:ReadULong() //this is an int in both version 4 and 5 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions / https://developer.valvesoftware.com/w/index.php?title=DMX/Binary&oldid=176216#Version_3
	end
	local StringDict = {}
	//MsgN(filename, " nStrings = ", nStrings)
	for k = 0, nStrings - 1 do
		local v = ReadUntilNull(f)
		StringDict[k] = v
	end
	//PrintTable(StringDict)


	local nElements = f:ReadULong() //int
	//MsgN(filename, " nElements = ", nElements)

	local function DmeHeader()
		local tab = {}
		if version <= 3 then
			tab.Type = StringDict[f:ReadUShort()] //string dictionary indices are shorts in DMX version 2 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
			tab.Name = ReadUntilNull(f) //element names are in-line strings in DMX version 2 https://developer.valvesoftware.com/w/index.php?title=DMX/Binary&oldid=176216#Version_3
		elseif version == 4 then
			//in version 4, element names are also stored in the string dictionary, but string dictionary indices are still shorts https://developer.valvesoftware.com/wiki/PCF#Element_Dictionary / https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
			tab.Type = StringDict[f:ReadUShort()]
			tab.Name = StringDict[f:ReadUShort()]
		elseif version == 5 then
			//in version 5, string dictionary indices are now ints https://developer.valvesoftware.com/wiki/PCF#Element_Dictionary / https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
			tab.Type = StringDict[f:ReadULong()]
			tab.Name = StringDict[f:ReadULong()]
		end
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
		if version <= 4 then
			tab.Name = StringDict[f:ReadUShort()] //string dictionary indices are shorts in DMX version 2 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
		elseif version == 5 then
			tab.Name = StringDict[f:ReadULong()]
		end
		//MsgN("name = ", tab.Name)
		if !tab.Name then return tab end //if we returned a bad attribute, bail out immediately; NOTE 3/22/25: this and all the file-reading checks with error messages below were to address a bug with PCFs packed into compressed map files, which would start returning garbage with a "Warning! LZMA compression header is invalid! Extraction failed! particles\_.pcf ( ERR: 1 )" error in console after an arbitrary point; this bug was fixed by the most recent gmod update, so this may no longer be necessary
		//local at = math.BinToInt(f:Read(1)) or 0 //returns nil
		//local at = math.BinToInt(ReadUntilNull(f)) or 0
		local at = f:ReadByte()
		//MsgN("at ", at, " = ", a[at])
		at = a[at] or ""
		tab.AttributeType = at
		local function DoAttribute(is_array)
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
				if version <= 3 or is_array then //in higher versions, arrays of strings still use null-terminated strings instead of being stored in the string dictionary
					return ReadUntilNull(f)
				elseif version == 4 then
					return StringDict[f:ReadUShort()] //this is a short in version 4 (https://developer.valvesoftware.com/wiki/PCF#Element_Dictionary), which matches the headers
				elseif version == 5 then
					return StringDict[f:ReadULong()]
				end
			elseif at == "ATTRIBUTE_BINARY" then
				local count = f:ReadULong()
				return f:Read(count)
			elseif at == "ATTRIBUTE_TIME" then
				return f:ReadLong() / 10000 //according to https://developer.valvesoftware.com/wiki/PCF; TODO: should this be unsigned? can't find anything that uses this to check
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
				local arraysize = f:ReadULong() //int, is ReadULong the right way to interpret this?
				if arraysize > 1000 then MsgN("PartCtrl: ", filename, " got crazy array size ", arraysize, " - we screwed up file reading somewhere, report this bug!") return end
				for i = 1, arraysize do
					table.insert(tab2, DoAttribute(true))
				end
				return tab2
			end
			return 0
		end
		tab.Value = DoAttribute()
		return tab
	end
	local ElementBodies = {}
	for i = 1, nElements do
		//MsgN("Element ", i, " = ")
		local body = {}
		local attributecount = f:ReadULong() //int, is ReadULong the right way to interpret this?
		//MsgN("attributecount = ", attributecount)
		if !attributecount then MsgN("PartCtrl: ", filename, " got no attribute count - we screwed up file reading somewhere, report this bug!") return end
		if attributecount > 100 then MsgN("PartCtrl: ", filename, " got crazy attribute count ", attributecount, " - we screwed up file reading somewhere, report this bug!") return end
		for i = 1, attributecount do
			local attrib = DmAttribute()
			if !attrib.Name then MsgN("PartCtrl: ", filename, " attribute ", i, " has no name value - we screwed up file reading somewhere, report this bug!") return end
			table.insert(body, attrib)
		end
		ElementBodies[i-1] = body
		//MsgN("nElement ", i, " body:")
		//PrintTable(body)
	end
	f:Close()


	//smoosh the index and bodies into a single table
	//PrintTable(ElementIndex)
	//PrintTable(ElementBodies)
	local ElementsUnsorted = {}
	for i, index in pairs (ElementIndex) do
		local tab = {}
		//tab["k"] = index["Type"] .. " " .. index["Name"]
		tab["k"] = index

		local v = {}
		if !ElementBodies[i] then
			MsgN("PartCtrl: ", filename, " element index ", i, " has no body - we screwed up file reading somewhere, report this bug!")
			break //note: in all the cases where this bug has happened (reading pcfs packed into compressed tf2 maps before 3/26/25 update) every element after the first one with this bug will also be empty, so stop here
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
	if !ElementsUnsorted[0].v.particleSystemDefinitions or !ElementsUnsorted[0].v.particleSystemDefinitions.ElementTable then 
		if dodebug then MsgN("PartCtrl: ", filename, " element 0 doesn't contain a particleSystemDefinitions table, ignoring") end
		return
	end
	for _, i in pairs (ElementsUnsorted[0].v.particleSystemDefinitions.ElementTable) do
		if !ElementsUnsorted[i] then
			if dodebug then MsgN("PartCtrl: ", filename, " tried to get DmeParticleSystemDefinition from nil element ", i) end
		elseif ElementsUnsorted[i].k.Type != "DmeParticleSystemDefinition" then
			if dodebug then MsgN("PartCtrl: ", filename, " tried to get DmeParticleSystemDefinition element ", ElementsUnsorted[i].k.Name, ", but it was a ", ElementsUnsorted[i].k.Type, " element") end
		else
			for k, v in pairs (ElementsUnsorted[i].v) do
				if istable(v) and v.ElementTable then
					local tab = {}
					for et_k, et_i in pairs (v.ElementTable) do
						if !ElementsUnsorted[et_i] then
							if dodebug then MsgN("PartCtrl: ", filename, " attribute ", k, " tried to get nil element ", et_i) end
						else
							if ElementsUnsorted[et_i].k.Type == "DmeParticleChild" then
								if !ElementsUnsorted[et_i].v.child then
									if dodebug then MsgN("PartCtrl: ", filename, " DmeParticleChild has no child value") end
								else
									//store particle children as strings (names of the corresponding fx) to keep the table simple and avoid recursive nonsense
									local childName = nil
									for et2_k, et2_i in pairs (ElementsUnsorted[et_i].v.child.ElementTable) do
										if !ElementsUnsorted[et2_i] then
											if dodebug then MsgN("PartCtrl: ", filename, " DmeParticleChild tried to get nil element ", et2_i) end
										else
											//table.insert(tab, ElementsUnsorted[et2_i].k.Name)
											childName = ElementsUnsorted[et2_i].k.Name
										end
									end
									ElementsUnsorted[et_i].v.child = childName
								end
							end
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

	if docache:GetBool() then
		local str = util.TableToJSON(Elements)
		if str then
			local dirs = string.Explode("/", "partctrl_cache_" .. cache_version ..  "/" .. filename)
			local d = ""
			for k,v in ipairs(dirs) do
			d = (d..v.."/")
			if !file.IsDir(d, "DATA") then file.CreateDir(d) end
			end
			if file.Write("partctrl_cache_" .. cache_version ..  "/" .. filename .. "/" .. checksum .. ".txt", str) then
				if dodebug then MsgN("PartCtrl: ", filename, " saved to cache") end
			else
				if dodebug then MsgN("PartCtrl: ", filename, " couldn't be cached because file.Write failed?") end
			end
		else
			if dodebug then MsgN("PartCtrl: ", filename, " couldn't be cached because util.TableToJSON failed?") end
		end
	end
	
	//PrintTable(Elements)
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
local default_attribs = {
	//Renderer
	"Render models", 
	"render_animated_sprites", 
	"render_rope", 
	"render_screen_velocity_rotate", 
	"render_sprite_trail", 
	//Operator
	"Alpha Fade and Decay", 
	"Alpha Fade and Decay for Tracers", //NEW 3/26/25
	"Alpha Fade In Random", 
	"Alpha Fade In Simple", //NEW 3/26/25
	"Alpha Fade Out Random", 
	"Alpha Fade Out Simple", //NEW 3/26/25
	"Clamp Scalar", //NEW 3/26/25
	"Clamp Vector", //NEW 3/26/25
	"Color Fade", 
	"Color Light from Control Point", 
	"Cull Random", 
	"Cull relative to model", 
	"Cull when crossing plane", 
	"Cull when crossing sphere", //NEW 3/26/25
	"Inherit Attribute From Parent Particle", //NEW 3/26/25
	"Lerp EndCap Scalar", //NEW 3/26/25
	"Lerp EndCap Vector", //NEW 3/26/25
	"Lerp Initial Scalar", //NEW 3/26/25
	"Lerp Initial Vector", //NEW 3/26/25
	"Lifespan Decay", 
	"Lifespan Maintain Count Decay", //NEW 3/26/25
	"Lifespan Minimum Alpha Decay", //NEW 3/26/25
	"Lifespan Minimum Radius Decay", //NEW 3/26/25
	"Lifespan Minimum Velocity Decay", 
	"Movement Basic", 
	"Movement Dampen Relative to Control Point", 
	"Movement Lag Compensation", //NEW 3/26/25
	"Movement Lock to Bone", 
	"Movement Lock to Control Point", 
	"Movement Lock to Saved Position Along Path", //NEW 3/26/25
	"Movement Maintain Offset", //NEW 3/26/25
	"Movement Maintain Position Along Path", 
	"Movement Match Particle Velocities", 
	"Movement Max Velocity", 
	"Movement Place On Ground", //NEW 3/26/25
	"Movement Rotate Particle Around Axis", 
	"Noise Scalar", 
	"Noise Vector", 
	"Normal Lock to Control Point", //NEW 3/26/25
	"Normalize Vector", //NEW 3/26/25
	"Oscillate Scalar", 
	"Oscillate Scalar Simple", //NEW 3/26/25
	"Oscillate Vector", 
	"Oscillate Vector Simple", //NEW 3/26/25
	"Radius Scale", 
	"Ramp Scalar Linear Random", //NEW 3/26/25
	"Ramp Scalar Linear Simple", //NEW 3/26/25
	"Ramp Scalar Spline Random", //NEW 3/26/25
	"Ramp Scalar Spline Simple", //NEW 3/26/25
	"Remap Average Scalar Value to CP", //NEW 3/26/25
	"Remap Control Point Direction to Vector", //NEW 3/26/25
	"Remap Control Point to Scalar", 
	"Remap Control Point to Vector", //NEW 3/26/25
	"Remap CP Speed to CP", 
	"Remap CP Velocity to Vector", //NEW 3/26/25
	"Remap Difference of Sequential Particle Vector to Scalar", //NEW 3/26/25
	"Remap Direction to CP to Vector", 
	"Remap Distance Between Two Control Points to CP", //NEW 3/26/25
	"Remap Distance Between Two Control Points to Scalar", 
	"Remap Distance to Control Point to Scalar", 
	"Remap Dot Product to Scalar", 
	"Remap Particle BBox Volume to CP", //NEW 3/26/25
	"Remap Percentage Between Two Control Points to Scalar", //NEW 3/26/25
	"Remap Percentage Between Two Control Points to Vector", //NEW 3/26/25
	"Remap Scalar", 
	"Remap Speed to Scalar", //NEW 3/26/25
	"Remap Velocity to Vector", //NEW 3/26/25
	"Restart Effect after Duration", //NEW 3/26/25
	"Rotate Vector Random", //NEW 3/26/25
	"Rotation Basic", 
	"Rotation Orient Relative to CP", 
	"Rotation Orient to 2D Direction", 
	"Rotation Spin Roll", 
	"Rotation Spin Yaw", 
	"Set child control points from particle positions", 
	"Set Control Point Positions", 
	"Set Control Point Rotation", //NEW 3/26/25
	"Set Control Point to Impact Point", //NEW 3/26/25
	"Set Control Point To Particles' Center", 
	"Set Control Point To Player", 
	"Set control points from particle positions", //NEW 3/26/25
	"Set CP Offset to CP Percentage Between Two Control Points", //NEW 3/26/25
	"Set CP Orientation to CP Direction", //NEW 3/26/25
	"Set per child control point from particle positions", //NEW 3/26/25
	"Stop Effect after Duration", //NEW 3/26/25
	//Initializer
	"Alpha Random", 
	"Color Lit Per Particle", 
	"Color Random", 
	"Cull relative to model", //NEW 3/26/25
	"Cull relative to Ray Trace Environment", //NEW 3/26/25
	"Inherit Initial Value From Parent Particle", //NEW 3/26/25
	"Lifetime From Sequence", 
	"Lifetime from Time to Impact", 
	"Lifetime Pre-Age Noise", 
	"Lifetime Random", 
	"Move Particles Between 2 Control Points", 
	"Normal Align to CP", //NEW 3/26/25
	"Normal Modify Offset Random", //NEW 3/26/25
	"Offset Vector to Vector", //NEW 3/26/25
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
	"Remap CP Orientation to Rotation", //NEW 3/26/25
	"Remap Initial Direction to CP to Vector", //NEW 3/26/25
	"Remap Initial Distance to Control Point to Scalar", 
	"Remap Initial Scalar",
	"Remap Noise to Scalar", 
	"Remap Particle Count to Scalar", 
	"Remap Scalar to Vector", 
	"Remap Speed to Scalar", //NEW 3/26/25
	"Rotation Random", 
	"Rotation Speed Random", 
	"Rotation Yaw Flip Random", 
	"Rotation Yaw Random", 
	"Scalar Random", 
	"Sequence From Control Point", //NEW 3/26/25
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
	"emit to maintain count", //NEW 3/26/25
	"emit_continuously", 
	"emit_instantaneously", 
	//ForceGenerator
	"Create vortices from parent particles", //NEW 3/26/25
	"Force based on distance from plane", //NEW 3/26/25
	"Pull towards control point", 
	"random force", 
	"time varying force", //NEW 3/26/25
	"turbulent force", //NEW 3/26/25
	"twist around axis", 
	//Constraint
	"Collision via traces", 
	"Constrain distance to control point", 
	"Constrain distance to path between two control points", 
	"Constrain particles to a box", //NEW 3/26/25
	"Prevent passing through a plane", 
	"Prevent passing through static part of world", 
}
local default_attribs2 = {}
for _, k in pairs (default_attribs) do
	default_attribs2[string.lower(k)] = true
end
default_attribs = default_attribs2
default_attribs2 = nil

function PartCtrl_GetUnhandledOperators()
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
							
							if !default_attribs[name] then
								allproperties[category][name] = allproperties[category][name] or { ["count"] = 0, ["paths"] = {} }
								allproperties[category][name].count = allproperties[category][name].count + 1
								table.insert(allproperties[category][name].paths, filename .. " " .. particle)
							end
						end
					else
						MsgN(filename, ": ", particle, " has no attribute category ", category)
					end
				end
			end
		end
	end

	PrintTable(allproperties)
end


//For testing purposes, lists all fx using a certain attribute, and optionally prints the attribute's values
//Example: PartCtrl_GetParticlesWithAttrib("Remap Control Point to Vector") to get all fx in all pcfs with that attribute, 
//or PartCtrl_GetParticlesWithAttrib("Remap Control Point to Vector", "particles/critglowtool_colorablefx.pcf") for just the fx in that file;
//add an extra "true" arg to the end of either of those to print the attribute's values
function PartCtrl_GetParticlesWithAttrib(desiredfunc, filename, extended)
	local function GetAttribsFromFile(desiredfunc, filename, extended)
		local tab = PartCtrl_ReadPCF(filename)
		if tab then
			for particle, ptab in SortedPairsLower (tab) do
				for category, attribs in pairs (ptab) do
					if istable(attribs) then
						for k, v in pairs (attribs) do
							if istable(v) and v.functionName and string.lower(v.functionName) == string.lower(desiredfunc) then
								//MsgN("(", filename, ") ", particle)
								MsgN(particle, " ", filename) //actually do it like this so it's easier to spawn them in console
								if extended then
									MsgN(category, " ", desiredfunc)
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


//Test: Get a list of all pcfs that are defined by multiple games, and for each one, print the checksums of each copy of the file, along with the checksum
//of the one actually being loaded by the game. This lets us determine which games have unique instances of a pcf as opposed to identical copies, and also 
//tells us which ones are getting loaded vs. getting clobbered by mount order.
function PartCtrl_GetPCFConflicts(alternate)
	
	local particles = {}
	for k, v in pairs (PartCtrl_AllPCFPaths) do
		particles[v] = {}
	end
	for k, v in pairs (PartCtrl_SkippedPCFPaths) do
		particles[v] = {}
	end
	local games = engine.GetGames()
	games[0] = {depot = 1, folder = "garrysmod", mounted = true}
	for k, v in pairs (games) do
		if !v.mounted then continue end

		//make folder and depot names all the same length so it reads better
		local folder2 = v.folder
		for i = 1, (17-#(v.folder)) do //longest folder name in engine.GetGames is thestanleyparable
			folder2 = folder2 .. " "
		end
		v.depot = tostring(v.depot)
		for i = 1, (7-#(v.depot)) do //longest depot number in engine.GetGames is treason's 1786950
			v.depot = " " .. v.depot
		end

		for name, _ in pairs (particles) do
			if !alternate then
				local f = file.Read(name, v.folder)
				if f then
					particles[name][v.depot .. ": " .. folder2] = util.SHA256(f)
				end
			else
				//alternative: get checksum of the table we return from reading the file, just in case there's some false positive making
				//file.Read return a non-identical string even if nothing relevant is different (i.e. file save timestamp or something?)
				//the results of this turned out to be no different from the above, and it's much slower, so don't do this by default.
				local f = PartCtrl_ReadPCF(name, v.folder)
				if f then
					particles[name][v.depot .. ": " .. folder2] = util.SHA256(util.TableToKeyValues(f))
				end
			end
		end
	end
	for name, v in pairs (particles) do
		if table.Count(v) <= 1 then
			particles[name] = nil
		else
			if !alternate then
				local f = file.Read(name, "GAME")
				if f then
					particles[name]["      0: mounted          "] = util.SHA256(f) //top of list
				end
			else
				//see above
				local f = PartCtrl_ReadPCF(name)
				if f then
					particles[name]["      0: mounted          "] = util.SHA256(util.TableToKeyValues(f)) //top of list
				end
			end
		end
	end
	PrintTable(particles)

end


//Test: Intended for use with a fallback pcf and the pcf it overrides; prints all differences between 2 raw pcf data tables.
function PartCtrl_ComparePCFs(file1, file2, shownil)

	local checksum1 = util.SHA256(file.Read(file1, "GAME"))
	local checksum2 = util.SHA256(file.Read(file2, "GAME"))
	if checksum1 == checksum2 then
		//files are identical, stop here
		MsgN("matching checksum ", checksum1)
		return
	end
	
	local allresults = {}

	//returns if a table is a default color table
	local function bad(tab)
		if (tab.r == 255 and tab.g == 255 and tab.b == 255 and (tab.a == nil or tab.a == 255))
		or (tab.r == 0 and tab.g == 0 and tab.b == 0 and (tab.a == nil or tab.a == 0)) then
			return true
		end
	end

	local function Compare(t1, t2, isfirst, spew)
		local allkeys = {}
		for k, _ in pairs (t1) do
			allkeys[k] = true
		end
		for k, _ in pairs (t2) do
			allkeys[k] = true
		end
		local results = {}
		for k, _ in SortedPairsLower (allkeys) do
			if spew or t1[k] != t2[k] then
				if istable(t1[k]) and istable(t2[k]) then
					//They're both tables, compare their contents
					local results2 = Compare(t1[k], t2[k], false, spew)
					if #results2 > 0 or isfirst then
						local name = k
						if t1[k].functionName and t2[k].functionName then
							if t1[k].functionName == t2[k].functionName then
								name = tostring(k) .. " (" .. t1[k].functionName .. ")"
							else
								name = tostring(k) .. " (" .. t1[k].functionName .. "/" .. t2[k].functionName .. ")"
							end
						end
						if isfirst then 
							name = "\n\n\n\n@@@@@@@@@@@@@@@@@@@@@ " .. name //make effect names extra visible
						end
						table.insert(results, name)
						if #results2 > 0 then
							table.Add(results, results2)
						else
							table.insert(results, "no differences")
						end
						table.insert(results, "")
					end
				elseif shownil or (
					(
						t1[k] != nil or (istable(t2[k]) and !bad(t2[k]))
					) and 
					(
						t2[k] != nil or (istable(t1[k]) and !bad(t1[k]))
					)
				) then
					local name = k
					if istable(t1[k]) and t1[k].functionName then
						name = tostring(k) .. " (" .. t1[k].functionName .. ")"
					elseif istable(t2[k]) and t2[k].functionName then
						name = tostring(k) .. " (" .. t2[k].functionName .. ")"
					end
					local result1 = t1[k]
					local result2 = t2[k]
					if isfirst then
						name = "@@@@@@@@@@@@@@@@@@@@@ " .. name //make effect names extra visible
						//don't dump entire effect tables if they're only in 1 file
						if istable(result1) then result1 = "EFFECT ONLY IN " .. file1 end
						if istable(result2) then result2 = "EFFECT ONLY IN " .. file2 end
					end 
					if result1 == nil then result1 = "nil" end
					if result2 == nil then result2 = "nil" end
					table.Add(results, {name, result1, result2, ""})
				end
			end
		end
		return results
	end

	for _, v in pairs (Compare(PartCtrl_ReadPCF(file1), PartCtrl_ReadPCF(file2), true)) do
		if istable(v) then
			PrintTable(v)
		else
			MsgN(v)
		end
	end

end


//Test: Get all missing materials in a pcf
function PartCtrl_GetMissingPCFMats(filename)

	local function Check(filename2)
		local tab = {}
	
		for particle, ptab in pairs (PartCtrl_ReadPCF(filename2)) do
			local mat = "materials\\" .. string.StripExtension(ptab.material) .. ".vmt"
			if !file.Exists(mat, "GAME") then
				table.insert(tab, particle .. ": " .. mat)
			end
		end
		
		if table.Count(tab) > 0 then
			MsgN("Missing materials in ", filename2, ":")
			for k, v in pairs (tab) do
				local repstr = string.Replace(v, "\\", "/")
				local pos, _, _ = string.find(repstr, "materials/")
				repstr = string.Replace(repstr, "materials/effects/", "materials/effects/workshop/")
				repstr = string.sub(repstr, pos)
				//MsgN(repstr, file.Exists(repstr, "GAME"))
				if file.Exists(repstr, "GAME") then
					MsgN(v, ", should be ", repstr)
				else
					MsgN(v)
				end
			end
			MsgN("")
		end
	end

	//if filename is provided, check that file, otherwise check all files
	if filename then
		Check(filename)
	else
		for k, v in pairs (PartCtrl_AllPCFPaths) do
			Check(v)
		end
	end

end


//Test: Get all particle effects used by info_particle_system ents on the map
function PartCtrl_GetMapFx()

	for k, v in pairs (ents.FindByClass("info_particle_system")) do
		local name = v:GetInternalVariable("effect_name")
		MsgN(name)
		for _, v2 in pairs (PartCtrl_PCFsByParticleName[name]) do
			//wanted to use this to figure out which instance of this effect is currently mounted,
			//but info_particle_system ents are only serverside and this table is only clientside, argh
			//MsgN(v2, " ", table.KeyFromValue(PartCtrl_AddParticles_AddedParticles, v2))
			MsgN(v2)
		end
		MsgN("")
	end

end


//For reference:
//Orangebox particle code: https://github.com/nillerusr/source-engine/tree/master/particles
//Newer (Portal 2/Alien Swarm/CSGO-era?) particle code: https://github.com/nillerusr/Kisak-Strike/tree/master/particles
//https://developer.valvesoftware.com/wiki/Category:Particle_System
local badoutputattribs = {
	["operator start fadein"] = 0,
	//["operator start fadeout"] = 0, //not actually functional without start fadein
	//["operator end fadein"] = 0, //not actually functional without end fadeout
	["operator end fadeout"] = 0,
	["first particle to copy"] = 1, //see striderbuster_flechette_attached
}
//new operator params that seem like they *might* matter re. outputs, but in practice, the only fx i could find with them were a few l4d2 ones,
//and none of them needed to have their outputs rejected, so ignore these for now
--[[local badoutputattribs2 = {
	["time strength random scale max"] = 1,
	["operator time scale seed"] = 0,
	["operator time scale min"] = 1,
	["operator time scale max"] = 1,
	["operator time offset seed"] = 0,
	["operator time offset min"] = 0,
	["operator time offset max"] = 0,
	["operator strength scale seed"] = 0,
	["operator strength random scale min"] = 1,
	["operator strength random scale max"] = 1,
	["operator fade oscillate"] = 0,
	["operator end cap state"] = -1,
}]]
function PartCtrl_CPoint_AddToProcessed(processed, k, name, processedk, processedv, attrib)
	if attrib then
		//if an output has a fadein/fadeout, then it isn't always overriding this cpoint, so we don't care about it - reject it
		if (processedk == "output" or processedk == "output_axis" or processedk == "output_children")
		and !string.StartsWith(name, "initializer") then //the operator fadein/out values exist on the only initializer output (initializer Velocity Repulse from World), but don't seem to work, so ignore them
			for bad, v in pairs (badoutputattribs) do
				if (attrib[bad] or 0) > v then //yes, they all default to 0
					//MsgN(name, " output doesn't always override cpoint because ", bad, " ", attrib[bad], " > ", v, ", rejecting") //no way to get the name of the particle with the output we're rejecting, argh
					//PrintTable(attrib)
					return
				end
			end
			//test: which fx even have these?
			--[[for bad, v in pairs (badoutputattribs2) do
				if attrib[bad] != nil and attrib[bad] > v then
					if !processed.bad2 then
						processed.bad2 = ""
					else
						processed.bad2 = processed.bad2 .. "\n"
					end
					processed.bad2 = processed.bad2 .. name .. ": " .. bad .. " = " .. attrib[bad]
				end
			end]]
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
		elseif processedv.colorpicker then
			//the color picker only supports colors from 0-255, which correspond to vectors from 0-1.
			//this means the picker only lets us access the entire color range if outMin/outMax are 0-1, which isn't ideal for color scalars
			//with a max above 1, like the ones on a bunch of alien swarm fx. so, for the color picker, rescale it all into a new 0-1 value space.
			//cache these here because a bunch of stuff uses this (color picker, color tool setcolor, spawnicons)
			processedv.outMin2 = Vector(
				math.Remap(processedv.outMin.x, processedv.outMin.x, processedv.outMax.x, 0, 1),
				math.Remap(processedv.outMin.y, processedv.outMin.y, processedv.outMax.y, 0, 1),
				math.Remap(processedv.outMin.z, processedv.outMin.z, processedv.outMax.z, 0, 1)
			)
			processedv.outMax2 = Vector(
				math.Remap(processedv.outMax.x, processedv.outMin.x, processedv.outMax.x, 0, 1),
				math.Remap(processedv.outMax.y, processedv.outMin.y, processedv.outMax.y, 0, 1),
				math.Remap(processedv.outMax.z, processedv.outMin.z, processedv.outMax.z, 0, 1)
			)
		end
	end
	processedv["name"] = name
	processed.cpoints[k] = processed.cpoints[k] or {}
	processed.cpoints[k][processedk] = processed.cpoints[k][processedk] or {}

	table.insert(processed.cpoints[k][processedk], processedv)
end
local function cpoint_from_attrib_value(processed, attrib, value, default_k, processedk, processedv)
	local k = attrib[value] or default_k
	if k > -1 or (processedv and processedv["force_allow_-1"]) then
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
		["render_rope"] = function(processed, attrib)
			//this definitely isn't how this is intended to be used lol; GOTTA SUPPORT IT ANYWAY
			if ((attrib["scale CP start"] or -1) > -1) and ((attrib["scale CP end"] or -1) > -1) then
				local scalar = nil
				for varname, label in pairs({
					["scale texture by CP distance"] = "texture",
					["scale scroll by CP distance"] = "scroll",
					["scale offset by CP distance"] = "offset",
				}) do
					if attrib[varname] then
						if !scalar then
							scalar = "Rope " .. label
						else
							scalar = scalar .. ", " .. label
						end
					end
				end
				if scalar then
					scalar = scalar .. " scale"
					cpoint_from_attrib_value(processed, attrib, "scale CP end", -1, "axis", {
						["axis"] = 0, //arbitrary; any axis could work for this, but ent_partctrl:StartParticle checks which_0 for relative_to_cpoint
						["label"] = scalar,
						["inMin"] = 0,
						["outMin"] = 0,
						["inMax"] = 1024, //arbitrary max scale; these are really small units and are meant to rescale the beam texture to be suitable for a beam X units long
						["outMax"] = 1024,
						["default"] = 100, //arbitrary default
						["relative_to_cpoint"] = attrib["scale CP start"] or -1 //?
					})
					cpoint_from_attrib_value(processed, attrib, "scale CP start", -1, "position_combine") //this is iffy; we assume the start cpoint might be attached to something while the end point isn't
				end
			end
			processed["has_renderer"] = true
		end,
		["render_sprite_trail"] = function(processed, attrib) processed["has_renderer"] = true end,
		["render_animated_sprites"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "orientation control point", -1, "position_combine")
			processed["has_renderer"] = true //global value on the effect, not cpoint-specfic
		end, //TODO: limit this to "orientation_type" cases where the orientation is actually used for something? this is sort of dependent on the VMT to work actually
		["_generic"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Visibility Proxy Input Control Point Number", -1, "position_combine") end, //pet doesn't add cpoint control for this; all renderers except render_rope have this; uses this position for visiblilty testing, which can then scale particle alpha/size based on how visible the area around the point is (https://developer.valvesoftware.com/wiki/Generic_Render_Operator_Visibility_Options)
	},
	["operators"]= {
		["alpha fade and decay"] = function(processed, attrib)
			//only do min_length for tracers if we have one of the right decay operators; tracer fx using other things 
			//(i.e. alien swarm tracers using "alpha fade and decay for tracers") don't have a minimum length between cpoints to render
			processed["min_length_raw_hasdecay"] = true
		end,
		["color light from control point"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "Light 1 Control Point", 0, "position_combine")
			cpoint_from_attrib_value(processed, attrib, "Light 2 Control Point", 0, "position_combine")
			cpoint_from_attrib_value(processed, attrib, "Light 3 Control Point", 0, "position_combine")
			cpoint_from_attrib_value(processed, attrib, "Light 4 Control Point", 0, "position_combine")
		end,
		["cull relative to model"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, nil, { //TODO: should this be a position_combine? can't actually find any fx that use this, even in portal2/asw/l4d2
			["ignore_outputs"] = true, //this cpoint sets an associated model, not a position, so outputs don't override it
		}) end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Cull_relative_to_model, yeah it's on the wrong page); pet doesn't add a control for this
		["cull when crossing plane"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point for point on plane", 0) end,
		["cull when crossing sphere"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point", 0) end,
		["lifespan decay"] = function(processed, attrib)
			//only do min_length for tracers if we have one of the right decay operators; tracer fx using other things 
			//(i.e. alien swarm tracers using "alpha fade and decay for tracers") don't have a minimum length between cpoints to render
			processed["min_length_raw_hasdecay"] = true
		end,
		["lifespan maintain count decay"] = function(processed, attrib)
			local axis = attrib["maintain count scale control point field"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "maintain count scale control point", -1, "axis", {
					["axis"] = axis,
					["label"] = "Maintain Count Scale",
					["inMin"] = 0,
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
		end,
		["movement basic"] = function(processed, attrib)
			//stupid handling for one effect that has a cpoint with just a force "move towards control point", but also maximum drag on its movement basic that makes the force not work (particles/taunt_fx.pcf taunt_yeti_fistslam_whirlwind)
			if (attrib["drag"] or 0) >= 0.98 then
				processed["drag_does_override"] = true //global value on the effect, not cpoint-specific
			end
		end,
		--[[["movement lag compensation"] = function(processed, attrib)
			//description: "Movement Lag Compensation - Sets a speed and decelerates it based on an input lag amount (Sort of DotA specific)"
			//in practice, uses the length of (or the value of an axis of) one cpoint to set the desired speed, and then uses the value of
			//another cpoint's axis (which is meant to be a ping value?) to do some remapping math to multiply that speed by up to 3.
			https://github.com/kallinosis-dev/srcmodbase-source/blob/dev/particles/builtin_particle_ops.cpp#L8142
			//this is complicated and i can't find any existing fx using it in porta2/asw/l4d2, so it's hard to say what controls we should
			//add to support it. leave this blank until we find an effect we need to add support for.
		end,]]
		["movement dampen relative to control point"] = function(processed, attrib) 
			if attrib["falloff range"] >= 5 then //don't process if this value is too small to do anything (lots of ep2 electrical fx have extra useless cpoints with only these for whatever reason)
				cpoint_from_attrib_value(processed, attrib, "control_point_number", 0)
			end
		end,
		["movement lock to bone"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine", {["ignore_outputs"] = true}) //this cpoint sets an associated model, not a position, so outputs don't override it
			processed["movement_lock"] = processed["movement_lock"] or {}
			processed["movement_lock"][attrib["control_point_number"] or 0] = true
		end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_System_Operators#Movement_Lock_to_Bone)
		["movement lock to control point"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine")
			processed["movement_lock"] = processed["movement_lock"] or {}
			processed["movement_lock"][attrib["control_point_number"] or 0] = true
		end,
		["movement lock to saved position along path"] = function(processed, attrib)
			//this is intended to use matching cpoints with position along path sequential, but you can set them to different
			//cpoints to make wacky nonsense where those cpoints move the effect instead, which to be fair is the sort of thing
			//position_combine is for, since that's not likely to be intended.
			//only works if the saved position is set by something like initializer "Position Along Path Sequential" with "Save Offset" enabled;
			//and some fx designers include this anyway even though it doesn't work (smissmas2021_unusuals.pcf unusual_smissmas_tree_* fx),
			//so we definitely don't want to make position controls for these.
			if attrib["Use sequential CP pairs between start and end point"] then
				//uses all cpoints from start to end
				local startp = attrib["start control point number"] or 0
				local endp = attrib["end control point number"] or 1
				local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
				for i = startp, endp do
					PartCtrl_CPoint_AddToProcessed(processed, i, name, "position_combine", nil, attrib)
				end
			else
				//uses start and end cpoint only
				cpoint_from_attrib_value(processed, attrib, "start control point number", 0, "position_combine")
				cpoint_from_attrib_value(processed, attrib, "end control point number", 1, "position_combine") //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			end
		end,
		["movement maintain offset"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Local Space CP", 0, "position_combine") end, //rotates the "desired offset" value by the angles of the cpoint; follow the precedent of angle-only cpoints being combined
		["movement maintain position along path"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "start control point number", 0, nil, {["sets_particle_pos"] = true})
			cpoint_from_attrib_value(processed, attrib, "end control point number", 0, nil, {["sets_particle_pos"] = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			//if there's no way for other cpoint attribs (like the ones that initialize in a box/sphere) to influence the particles because this attrib forces them onto a very specific path, then don't make position controls for those cpoints
			//this functionality was intended for constraints, but this operator does the same thing
			if (attrib["maximum distance"] or 0) < 1 then
				processed["constraint_does_override"] = true //global value on the effect, not cpoint-specific
			end
		end,
		["movement match particle velocities"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point to Broadcast Speed and Direction To", -1, "output") end, //pet doesn't add control for this; sets all 3 axes of the cpoint's position vector to the speed, and sets the cpoint's angle to face the direction (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_ops.cpp#L3788)
		["movement max velocity"] = function(processed, attrib)
			local axis = attrib["Override CP field"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "Override Max Velocity from this CP", -1, "axis", {
					["axis"] = axis,
					["label"] = "Max Velocity",
					["inMin"] = 0,
					["outMin"] = 0,
					["inMax"] = 2500, //arbitrary max, because the default max of 10 is too low;
					["outMax"] = 2500, //no idea if this is good, because i can't find any existing fx using this
					["default"] = 1,
				})
			end
		end,
		--[[["movement place on ground"] = function(processed, attrib)
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L9390
			//uses the movement of the last two cpoints to throttle updates; if either one has moved enough from its previous pos, then update immediately.
			//also uses the movement of the first one to throttle something(?) involving interpolation the same way.
			//no existing portal2/asw/l4d2 fx use this, is this a dota thing? can't even get a custom effect to use these in any meaningful way, ignore for now.
			cpoint_from_attrib_value(processed, attrib, "interploation distance tolerance cp", -1, "position_combine") //sic
			cpoint_from_attrib_value(processed, attrib, "reference CP 1", -1, "position_combine")
			cpoint_from_attrib_value(processed, attrib, "reference CP 2", -1, "position_combine")
		end,]]
		["movement rotate particle around axis"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point", 0) end,
		["normal lock to control point"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine") end, //controls angle of Render Models fx; this is an angle control, so combine it
		["remap average scalar value to cp"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "output control point", 1, "output") end, //overrides the cpoint's position to Vector(result,0,0) (https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L2602)
		["remap control point direction to vector"] = function(processed, attrib) 
			//like remap control point to vector, but it sets the vector to the forward normal vector of the cpoint's angle.
			//can't really turn this into a set of sliders/color picker since that's not how normals work, and the only existing
			//fx that use this are some alien swarm gib fx that use it to set the particle's "normal" vector to control the gib
			//model's angle, so make this a position_combine.
			cpoint_from_attrib_value(processed, attrib, "control point number", 0, "position_combine") 
		end, 
		["remap control point to scalar"] = function(processed, attrib)
			//controls a whole bunch of stuff (lifetime, radius, alpha, etc.) with the value of a single axis of the cpoint, definitely not a position control
			local axis = attrib["input field 0-2 X/Y/Z"] or 0
			if axis > -1 then
				local field = attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS //PARTICLE_ATTRIBUTE_x enum
				local label = ParticleAttributeNames[field]
				local inMin = attrib["input minimum"] or 0
				local inMax = attrib["input maximum"] or 1
				local outMin = attrib["output minimum"] or 0
				local outMax = attrib["output maximum"] or 1
				local is_multiplier = attrib["output is scalar of initial random range"] or attrib["output is scalar of current value"]
				local default
				local decimals = nil
				if field == PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS and !is_multiplier then
					//radius scalars should default to a nice big size, not 1 pixel
					default = math.Remap(8, outMin, outMax, inMin, inMax)
				elseif field == PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA or field == PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA2 then 
					//Alpha should always default to max visibility;
					//make sure to handle wacky fx like tf2's speech_mediccall that flip the scale around on output
					if outMin <= outMax then
						default = math.max(inMin, inMax)
					else
						default = math.min(inMin, inMax)
					end
				elseif field == PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER or field == PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1 then
					//sequence number scalars should be whole numbers, and default to 0 (first sequence)
					default = math.Remap(0, outMin, outMax, inMin, inMax)
					decimals = 0
				else
					//default to 1
					default = math.Remap(1, outMin, outMax, inMin, inMax)
				end
				//make sure the default value of the control in the edit window isn't outside its range
				default = math.Clamp(default, math.Remap(outMin, outMin, outMax, inMin, inMax), math.Remap(outMax, outMin, outMax, inMin, inMax))
				if is_multiplier then
					label = label .. " Scale"
				end
				cpoint_from_attrib_value(processed, attrib, "input control point number", 0, "axis", {
					["axis"] = axis,
					["label"] = label,
					["inMin"] = inMin,
					["inMax"] = inMax,
					["outMin"] = outMin,
					["outMax"] = outMax,
					["default"] = default,
					["decimals"] = decimals,
				})
			end
		end,
		["remap control point to vector"] = function(processed, attrib)
			//Similar to above, use all 3 axes of the cpoint to set Position, Roll, or Color
			//TF2/episodes/HL2 pcfs only have use cases for Color, so the others required some testing.
			local field = attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_XYZ //PARTICLE_ATTRIBUTE_x enum //assume the default is Position because that's what shows in pet by default, just like Radius is for scalars; can't find any v5 fx to test with that omit this value
			local label = ParticleAttributeNames[field]
			local inMin = attrib["input minimum"] or Vector()
			local inMax = attrib["input maximum"] or Vector()
			local outMin = attrib["output minimum"] or Vector()
			local outMax = attrib["output maximum"] or Vector()
			local is_multiplier = attrib["output is scalar of initial random range"] or attrib["output is scalar of current value"]
			local default = nil
			local colorpicker = nil
			if field == PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB or is_multiplier then
				//Color should default to the equivalent of 1,1,1 (white),
				//and multipliers should default to 100%
				default = Vector(math.Remap(1, outMin.x, outMax.x, inMin.x, inMax.x), math.Remap(1, outMin.y, outMax.y, inMin.y, inMax.y), math.Remap(1, outMin.z, outMax.z, inMin.z, inMax.z))
				if field == PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB then
					colorpicker = true
				end
			else
				//default to 0
				default = Vector(math.Remap(0, outMin.x, outMax.x, inMin.x, inMax.x), math.Remap(0, outMin.y, outMax.y, inMin.y, inMax.y), math.Remap(0, outMin.z, outMax.z, inMin.z, inMax.z))
			end
			for i = 1, 3 do
				//make sure the default value of the control in the edit window isn't outside its range (see portal 2 portalgun_top_light_squiggles)
				default[i] = math.Clamp(default[i], math.Remap(outMin[i], outMin[i], outMax[i], inMin[i], inMax[i]), math.Remap(outMax[i], outMin[i], outMax[i], inMin[i], inMax[i]))
			end
			if is_multiplier then
				label = label .. " Scale"
			end
			cpoint_from_attrib_value(processed, attrib, "input control point number", 0, "vector", {
				["label"] = label,
				["inMin"] = inMin,
				["inMax"] = inMax,
				["outMin"] = outMin,
				["outMax"] = outMax,
				["default"] = default,
				["colorpicker"] = colorpicker,
			})
			cpoint_from_attrib_value(processed, attrib, "local space CP", -1, "position_combine") //uses the cpoint's angles to rotate the output in some odd way, can be used to make a position sort-of-rotate with the cpoint, or make colors change as it spins
		end,
		["remap cp speed to cp"] = function(processed, attrib)
			local axis = attrib["Output field 0-2 X/Y/Z"] or 0
			if axis > -1 and (attrib["output control point"] or -1) != -1 then
				cpoint_from_attrib_value(processed, attrib, "input control point", 0, "position_combine") //only used if the output is defined (https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L2383)
				cpoint_from_attrib_value(processed, attrib, "output control point", -1, "output_axis", {["axis"] = axis})
			end
		end,
		["remap cp velocity to vector"] = function(processed, attrib)
			//like remap control point to vector, but it sets the vector to the cpoint's velocity value.
			//can't really turn this into a set of sliders/color picker unless we make some custom functionality to constantly move
			//the cpoint around, and i can't find any existing fx using this to accomodate, so just position_combine it for now.
			cpoint_from_attrib_value(processed, attrib, "control point", 0, "position_combine")
		end,
		["remap direction to cp to vector"] = function(processed, attrib)
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L9390
			//uses the angle of the cpoint to set a vector value; only existing fx i could find using this are a few in  portal 2's portals.pcf,
			//which use it to set the new "normal" value; creates an extraneous cpoint that doesn't visibly do anything, so just position_combine it.
			cpoint_from_attrib_value(processed, attrib, "control point", 0, "position_combine")
		end,
		["remap distance between two control points to cp"] = function(processed, attrib)
			//i guess we could convert this into a relative_to_cp vector control just like "remap distance between two control points to scalar" below,
			//but what would we actually describe the control as? can't find any existing fx using this, so just add normal position controls and output for now.
			cpoint_from_attrib_value(processed, attrib, "starting control point", 0)
			cpoint_from_attrib_value(processed, attrib, "ending control point", 1)
			local axis = attrib["output control point field"] or 0
			if axis > -1 and (attrib["output control point"] or 2) != -1 then
				cpoint_from_attrib_value(processed, attrib, "output control point", 2, "output_axis", {["axis"] = axis})
			end
		end,
		["remap distance between two control points to scalar"] = function(processed, attrib)
			//this uses all the same scalars as remap control point to scalar, but actually uses the distance between two positions to get the value
			local field = attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS //PARTICLE_ATTRIBUTE_x enum
			local label = ParticleAttributeNames[field]
			local inMin = attrib["distance minimum"] or 0
			local inMax = attrib["distance maximum"] or 1
			local outMin = attrib["output minimum"] or 0
			local outMax = attrib["output maximum"] or 1
			local is_multiplier = attrib["output is scalar of initial random range"] or attrib["output is scalar of current value"]
			local default
			local decimals = nil
			if field == PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS and !is_multiplier then
				//radius scalars should default to a nice big size, not 1 pixel
				default = math.Remap(8, outMin, outMax, inMin, inMax)
			elseif field == PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA or field == PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA2 then 
				//Alpha should always default to max visibility;
				//make sure to handle wacky fx like tf2's speech_mediccall that flip the scale around on output
				if outMin <= outMax then
					default = math.max(inMin, inMax)
				else
					default = math.min(inMin, inMax)
				end
			elseif field == PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER or field == PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1 then
				//sequence number scalars should be whole numbers, and default to 0 (first sequence)
				default = math.Remap(0, outMin, outMax, inMin, inMax)
				decimals = 0
			else
				//default to 1
				default = math.Remap(1, outMin, outMax, inMin, inMax)
			end
			//make sure the default value of the control in the edit window isn't outside its range
			default = math.Clamp(default, math.Remap(outMin, outMin, outMax, inMin, inMax), math.Remap(outMax, outMin, outMax, inMin, inMax))
			if is_multiplier then
				label = label .. " Scale"
			end
			cpoint_from_attrib_value(processed, attrib, "ending control point", 1, "axis", {
				["axis"] = 0, //arbitrary; any axis could work for this, but ent_partctrl:StartParticle checks which_0 for relative_to_cpoint
				["label"] = label,
				["inMin"] = inMin,
				["inMax"] = inMax,
				["outMin"] = outMin,
				["outMax"] = outMax,
				["default"] = default,
				["decimals"] = decimals,
				["relative_to_cpoint"] = attrib["starting control point"] or 0 //?
			})
			cpoint_from_attrib_value(processed, attrib, "starting control point", 0, "position_combine") //this is iffy; we assume the start cpoint might be attached to something while the end point isn't, which *is* the case with all existing fx, but doesn't necessarily have to be
		end,
		["remap distance to control point to scalar"] = function(processed, attrib)
			//like the above but uses the distance between a single cpoint's position and the particle (sprite?) itself (https://developer.valvesoftware.com/wiki/Particle_System_Operators#Remap_Distance_to_Control_Point_to_Scalar)
			local label = ParticleAttributeNames[attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS] //PARTICLE_ATTRIBUTE_x enum //put this in the table so we can see what it does in the debug
			cpoint_from_attrib_value(processed, attrib, "control point", 0, nil, {["label"] = label})
		end,
		["remap dot product to scalar"] = function (processed, attrib)
			//like "remap control point to scalar", except it gets the angle(?) of 2 cpoints and does math with them to set the scalar. not listed in wiki.
			//every example i could find for this (it's used by a lot of "ring" child fx in dr grordbord fx) works in conjunction with another "set control point to player" operator, which 
			//uses an output to set a cpoint to the player's position. then, this operator does math with that to set output field Yaw (12) to rotate the particles, attempting to orient 
			//them to face "forward" in the direction of the first cpoint(not the player one), with mixed results. the only exceptions i could find for this were some unused effects in 
			//eyeboss.pcf, which were the same but without the player cpoint, and instead use the angle (not the position!) of the second cpoint to change the particle's yaw.
			//whatever, just make this a position control, seems it's like "remap direction to cp to vector", and should be either this or a manual angle input.
			//update: actually just combine this one, the only effects that have a position control *for this operator only* are ones that didn't set up the player yaw thing properly
			local label = ParticleAttributeNames[attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS] //PARTICLE_ATTRIBUTE_x enum //put this in the table so we can see what it does in the debug
			cpoint_from_attrib_value(processed, attrib, "first input control point", 0, "position_combine", {["label"] = label})
			cpoint_from_attrib_value(processed, attrib, "second input control point", 0, "position_combine", {["label"] = label})
		end,
		["remap particle bbox volume to cp"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "output control point", -1, "output") end, //sets the whole cpoint to Vector(volume,0,0) https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L2532
		["remap percentage between two control points to scalar"] = function(processed, attrib)
			//sets a scalar value on *each individual particle* based on what percentage of the distance between two cpoints it's covered
			cpoint_from_attrib_value(processed, attrib, "starting control point", 0)
			cpoint_from_attrib_value(processed, attrib, "ending control point", 1)
		end,
		["remap percentage between two control points to vector"] = function(processed, attrib)
			//sets a vector value on *each individual particle* based on what percentage of the distance between two cpoints it's covered
			cpoint_from_attrib_value(processed, attrib, "starting control point", 0)
			cpoint_from_attrib_value(processed, attrib, "ending control point", 1)
		end,
		["restart effect after duration"] = function(processed, attrib)
			local axis = attrib["Control Point Field X/Y/Z"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "Control Point to Scale Duration", -1, "axis", {
					["axis"] = axis,
					["label"] = "Duration Scale",
					["inMin"] = 0, //no point in negative scale for this one
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
		end,
		["rotation orient relative to cp"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point", 0) end,
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
			local cpoints = {
				[1] = {
					["input"] = "First Control Point Parent",
					["input_def"] = 0,
					["output"] = "First Control Point Number",
					["output_def"] = 1,
				},
				[2] = {
					["input"] = "Second Control Point Parent",
					["input_def"] = 0,
					["output"] = "Second Control Point Number",
					["output_def"] = 2,
				},
				[3] = {
					["input"] = "Third Control Point Parent",
					["input_def"] = 0,
					["output"] = "Third Control Point Number",
					["output_def"] = 3,
				},
				[4] = {
					["input"] = "Fourth Control Point Parent",
					["input_def"] = 0,
					["output"] = "Fourth Control Point Number",
					["output_def"] = 4,
				},
			}
			local used_cpoint //fix some fx that have an output set to the main cpoint they're all offset from (tfc_sniper_charge_blue) - in these cases, the cpoint is not overridden
			if !attrib["Set positions in world space"] then //according to code, only used if not setting in world space (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_ops.cpp#L2725)
				cpoint_from_attrib_value(processed, attrib, "Control Point to offset positions from", 0, nil, {["doesnt_need_renderer_or_emitter"] = true})
				used_cpoint = attrib["Control Point to offset positions from"] or 0
			end

			for k, tab in pairs (cpoints) do
				//do inputs - add position controls for the "parent" cpoints that move things around
				cpoint_from_attrib_value(processed, attrib, tab.input, tab.input_def, nil, {["doesnt_need_renderer_or_emitter"] = true, ["remove_if_other_cpoint_is_empty"] = attrib[tab.output] or tab.output_def})
				//then do outputs - remove position controls from the "child" cpoints that are having their positions overridden
				if (attrib[tab.output] or tab.output_def) != used_cpoint then
					cpoint_from_attrib_value(processed, attrib, tab.output, tab.output_def, "output")
				end
			end
		end,
		--[[["set control point rotation"] = function(processed, attrib)
			//the rotation from this cpoint gets stomped by the angle of the position control, and i don't see a way to fix this. 
			//even output isn't great because either A: the cpoint being rotated is the first cpoint, it gets assigned to fallback cpoint
			//-1 instead, and it uses the angle of *that* instead, or B: the cpoint being rotated doesn't get a position set and ends up
			//at 0,0,0. hrmph.
			//only way to fix all this would be to add special handling for cpoints using this operator, where ent_partctrl would use
			//something other than self.particle:AddControlPoint so that the cpoint angle doesn't get set. i can't find any working 
			//effects that actually use this, so that would be overengineered for now.
			cpoint_from_attrib_value(processed, attrib, "Control Point", 0, "output")
			//there's also a "Local Space Control Point" we could position_combine, but again, not useful.
		end,]]
		["set control point to impact point"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "Control Point to Trace From", 1, "position_combine")
			cpoint_from_attrib_value(processed, attrib, "Control Point to Set", 1, "output") 
			//note: if we have a control for the output cpoint (i.e. output doesn't get set because of fadein or something), 
			//then this operator's changes get squashed completely, even for the window of time where it *should* be doing something.
			//all existing fx i could find with these conditions work better with a cpoint, though, so do it this way for now.
		end,
		["set control point to particles' center"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point Number to Set", 1, "output") end,
		["set control point to player"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "Control Point Number", 1, "output")
			processed["spawnicon_playerposfix"] = true //this attrib forces a cpoint to the player's position, which can break spawnicon renderbounds, so tell it to account for that
		end,
		["set control points from particle positions"] = function(processed, attrib)
			//like "set child control points from particle positions", but it sets the effect's own cpoints instead.
			//only existing effect i could find using this was portal 2's dissolve_flashes_glow particles/spark_fx.pcf, which uses
			//it to move the renderer's "Visibility Proxy Input Control Point Number" to each particle as it's spawned, and i made
			//a test effect that uses it functionally the same way as the child one, by moving a cpoint that's only used by child fx.
			local startp = attrib["First control point to set"] or 0
			local endp = startp + ((attrib["# of control points to set"] or 1) - 1)
			local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
			for i = startp, endp do
				PartCtrl_CPoint_AddToProcessed(processed, i, name, "output", nil, attrib)
			end
		end,
		["set cp offset to cp percentage between two control points"] = function(processed, attrib)
			//this one is pretty elaborate, it gets the position of an "input" control point relative to two other "start" and
			//"ending" control points, uses it to scale a value relative to a fourth "offset" control point, and then outputs 
			//that to a fifth "output" control point.
			//no existing portal2/asw/l4d2 fx use this, what could this possibly be for? just handle the output and then do 
			//normal position controls for the rest, until we find an effect we need to accomodate.
			cpoint_from_attrib_value(processed, attrib, "starting control point", 0)
			cpoint_from_attrib_value(processed, attrib, "ending control point", 1)
			cpoint_from_attrib_value(processed, attrib, "offset control point", 2)
			cpoint_from_attrib_value(processed, attrib, "input control point", 3)
			cpoint_from_attrib_value(processed, attrib, "output control point", 4, "output") //note: this output gets clobbered if we make a position control for the same cpoint, probably interacts badly if we don't create this control due to fadein or something
		end,
		--[[["set cp orientation to cp direction"] = function(processed, attrib)
			//gets the direction the input cpoint is currently moving, and rotates the angle of the output cpoint
			//to point in that direction. no existing portal2/asw/l4d2 fx use this, what is this used for?
			//the output angle gets clobbered by the angle of the position control if it has one, so should we handle this like
			//a pos output to keep it untouched? maybe wait until there's an effect using this to see how we should accomodate it.
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L9338
			cpoint_from_attrib_value(processed, attrib, "input control point", 0)
			cpoint_from_attrib_value(processed, attrib, "output control point", 0, "output")
		end,]]
		["set per child control point from particle positions"] = function(processed, attrib)
			//sets a single control point on a limited number of child fx
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L5220
			local groupid = attrib["Group ID to affect"] or 0
			local limit = attrib["# of children to set"] or 1
			cpoint_from_attrib_value(processed, attrib, "control point to set", 0, "output_children", {["groupid"] = groupid, ["limit"] = limit})

			//again, like "set child control points from particle positions", some fx (portalgun_beam_holding_object) emit invisible particles (no renderer) 
			//and then use them to set the position of a child control point. ordinarily, we'd cull the cpoint data from fx with no renderer, because their 
			//attribs don't do anything that the player can see, but in this case, we don't want to do that, so mark as having a renderer.
			//TODO: this might be bad if the children don't have a renderer either, can we catch those?
			if #processed["children"] > 0 then processed["has_renderer"] = true end
			//processed["sets_particle_pos_on_children"] = groupid
		end,
		["stop effect after duration"] = function(processed, attrib)
			local axis = attrib["Control Point Field X/Y/Z"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "Control Point to Scale Duration", -1, "axis", {
					["axis"] = axis,
					["label"] = "Duration Scale",
					["inMin"] = 0, //no point in negative scale for this one
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
		end,
	},
	["initializers"] = {
		["color random"] = function(processed, attrib)
			if (attrib["tint_perc"] or 0) > 0 then //by default, the value of "tint control point" is 0, not -1, so pet adds a control for it by default, but in code, this isn't used unless tint_perc is non-zero (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L1705)
				cpoint_from_attrib_value(processed, attrib, "tint control point", 0, "position_combine") //samples the lighting from this cpoint's position (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Color_Random)
			end
		end,
		["cull relative to model"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, nil, { //TODO: should this be a position_combine? can't actually find any fx that use this, even in portal2/asw/l4d2
			["ignore_outputs"] = true, //this cpoint sets an associated model, not a position, so outputs don't override it
		}) end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Cull_relative_to_model)
		["move particles between 2 control points"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "end control point", 1, nil, {["sets_particle_pos"] = true}) //yes, it only defines an endpoint (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Move_Particles_Between_2_Control_Points)
			//the minimum distance between cpoints needed to render fx using this operator actually scales with FRAMERATE, ridiculous
			//TODO: not much more we can do about this since min_length is serverside, argh. i guess this could use a convar? a serverside convar for how much fps they expect clients to have? nonsense
			processed["min_length_raw"] = (math.max((attrib["maximum speed"] or 1), (attrib["minimum speed"] or 1))/58) + 1
			+ (attrib["start offset"] or 0) - (attrib["end offset"] or 0)
		end, 
		["normal align to cp"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine") end, //controls angle of Render Models fx; this is an angle control, so combine it
		["normal modify offset random"] = function(processed, attrib)
			if attrib["offset in local space 0/1"] then //cpoint is only used if this is true https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_initializers.cpp#L7267
				cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine") //controls angle of Render Models fx; this is an angle control, so combine it
			end
		end,
		["position along epitrochoid"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control point number", 0, nil, {["sets_particle_pos"] = true})
			if (attrib["scale from conrol point (radius 1/radius 2/offset)"] or -1) > -1 then //sic (conrol point)
				local function DoEpitrochoidAxis(axis, axisv, default, min)
					if (attrib[axisv] or default) != 0 then
						cpoint_from_attrib_value(processed, attrib, "scale from conrol point (radius 1/radius 2/offset)", -1, "axis", {
							["axis"] = axis,
							["label"] = "Epitrochoid " .. axisv .. " multiplier",
							["inMin"] = min,
							["outMin"] = min,
							//no max
							["default"] = 1,
						})
					end
				end
				DoEpitrochoidAxis(0, "radius 1", 40)
				DoEpitrochoidAxis(1, "radius 2", 24)
				DoEpitrochoidAxis(2, "point offset", 4, 0) //no point in negatives for this one
			end
		end,
		["position along path random"] = function(processed, attrib)
			if attrib["randomly select sequential CP pairs between start and end points"] then
				//uses all cpoints from start to end
				local startp = attrib["start control point number"] or 0
				local endp = attrib["end control point number"] or 0
				local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
				for i = startp, endp do
					PartCtrl_CPoint_AddToProcessed(processed, i, name, nil, {["sets_particle_pos"] = true}, attrib)
				end
			else
				//uses start and end cpoint only
				cpoint_from_attrib_value(processed, attrib, "start control point number", 0, nil, {["sets_particle_pos"] = true})
				cpoint_from_attrib_value(processed, attrib, "end control point number", 0, nil, {["sets_particle_pos"] = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			end
		end,
		["position along path sequential"] = function(processed, attrib)
			if attrib["Use sequential CP pairs between start and end point"] then
				//uses all cpoints from start to end
				local startp = attrib["start control point number"] or 0
				local endp = attrib["end control point number"] or 0
				local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
				for i = startp, endp do
					PartCtrl_CPoint_AddToProcessed(processed, i, name, nil, {["sets_particle_pos"] = true}, attrib)
				end
			else
				//uses start and end cpoint only
				cpoint_from_attrib_value(processed, attrib, "start control point number", 0, nil, {["sets_particle_pos"] = true})
				cpoint_from_attrib_value(processed, attrib, "end control point number", 0, nil, {["sets_particle_pos"] = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			end
		end,
		["position along ring"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control point number", 0, nil, {["sets_particle_pos"] = true})
			//"Override CP (X/Y/Z *= Radius/Thickness/Speed)" and "Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)" control those things with the values of the cpoint
			//These are all MULTIPLIERS so an axis doesn't do anything if the value is 0, ignore those
			//Unlike remap control point to vector, pitch/yaw/roll are in degrees, not radians
			local function DoRingAxis(cpoint, axis, axisv, min)
				if (attrib[cpoint] or -1) > -1 then
					local doaxis = false
					if axisv == "speed" then //this one uses two values so it has special handling 
						if (attrib["min initial speed"] or 0) != 0 
						or (attrib["max initial speed"] or 0) != 0 then
							doaxis = true
						end
					elseif (attrib[axisv] or 0) != 0 then //yes, they all default to 0
						doaxis = true
					end
					if doaxis then
						if axisv == "initial radius" then axisv = "radius" end //nicer name for slider label
						cpoint_from_attrib_value(processed, attrib, cpoint, -1, "axis", {
							["axis"] = axis,
							["label"] = "Ring " .. axisv .. " multiplier",
							["inMin"] = min,
							["outMin"] = min,
							//no max
							["default"] = 1,
						})
					end
				end
			end
			DoRingAxis("Override CP (X/Y/Z *= Radius/Thickness/Speed)", 0, "initial radius", 0) //no point in negatives for these ones
			DoRingAxis("Override CP (X/Y/Z *= Radius/Thickness/Speed)", 1, "thickness", 0)
			DoRingAxis("Override CP (X/Y/Z *= Radius/Thickness/Speed)", 2, "speed", 0)
			DoRingAxis("Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)", 0, "pitch")
			DoRingAxis("Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)", 1, "yaw")
			DoRingAxis("Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)", 2, "roll")
		end,
		["position from chaotic attractor"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "Relative Control point number", 0, nil, {["sets_particle_pos"] = true})
		end,
		["position from parent cache"] = function(processed, attrib)
			//this operator's presence overrides others that would set the particle pos (i.e. "position within sphere random") and actively makes
			//the effect unusable on its own - see l4d2's particles/firework_crate_fx.pcf firework_crate_ground_sparks_01.
			//this shouldn't even be possible, gmod's pet doesn't let you add this operator and another position one at the same time.
			processed["sets_particle_pos_forcedisable"] = true
		end,
		["position from parent particles"] = function(processed, attrib)
			//don't cull parent fx if they don't have a valid renderer, but one of their children has this attribute (i.e. parent alien_ufo_explode_trailing_bits_alt, child alien_ufo_explode_alt_trail_smoke)
			processed["parent_force_has_renderer"] = true
			//processed["sets_particle_pos_if_child"] = true
		end,
		["position in cp hierarchy"] = function(processed, attrib)
			//this one is a bit strange. it defines a cpoint for every id between the start and end, and then moves the particle spawn point between them all.
			//the weird pet behavior where it adds controls for every cpoint between start and end seems to be designed for this initializer.
			local startp = attrib["start control point number"] or 0
			local endp = attrib["end control point number"] or 1
			if attrib["use highest supplied end point"] then //with this arg set, the particle system uses as many cpoints as you give it. any amount works.
				//endp = 63 //this is what pet does, and it's functional, but this is stupid, don't do this. no one needs 64 whole cpoints to move around.
				endp = math.min(startp + 1, 63) //TODO: give players a way to manually enable as many cpoints as they want, without dumping 64 on them by default.
			end
			local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
			for i = startp, endp do
				PartCtrl_CPoint_AddToProcessed(processed, i, name, nil, {["sets_particle_pos"] = true}, attrib)
			end
		end,
		["position modify offset random"] = function(processed, attrib)
			//code only uses this cpoint if offset in local space is enabled; (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L776)
			//this cpoint's ANGLES are used to rotate the offset mins/maxs, its position is not used, so we should either use a position control or a manual angle input maybe
			if attrib["offset in local space 0/1"] then
				cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine")
			end
		end,
		["position modify warp random"] = function(processed, attrib)
			//this can potentially be used to make the position stretch and skew with the movement of the cpoint, but only if the values are set up a specific way. (test_PositionModifyWarpRandom_2)
			//otherwise, in practice, making a separate cpoint for this doesn't do anything except move the center of the effect around, which is extraneous, so use position_combine.
			local min = attrib["warp min"] or Vector(1,1,1)
			local max = attrib["warp max"] or Vector(1,1,1)
			local time = attrib["warp transition time (treats min/max as start/end sizes)"] or 0
			if time == 0 and min != max then
				cpoint_from_attrib_value(processed, attrib, "control point number", 0)
			else
				cpoint_from_attrib_value(processed, attrib, "control point number", 0, "position_combine")
			end
		end,
		["position on model random"] = function(processed, attrib) 
			cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, nil, {
				["ignore_outputs"] = true, //this cpoint sets an associated model, not a position, so outputs don't override it
				["on_model"] = true,
				["sets_particle_pos"] = true,
			})
			//if (attrib["desired hitbox"] or -1) > -1 then
				//TODO: should there be different info text handling for this? it doesn't apply to the *entire* model, 
				//but rather to a *specific part* of the model, though we don't have a way of knowing what that part is
			//end
		end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_position#Position_on_Model_Random)
		["position within box random"] = function(processed, attrib)
			if attrib["use local space"] then 
				 //if this var is set, then the cpoint controls the angle of the box, but not the position. this feels like a bug, but alright.
				cpoint_from_attrib_value(processed, attrib, "control point number", 0, "position_combine")
			else
				cpoint_from_attrib_value(processed, attrib, "control point number", 0, nil, {["overridable_by_constraint"] = true, ["sets_particle_pos"] = true})
			end
		end,
		["position within sphere random"] = function(processed, attrib)
			if !attrib["randomly distribute to highest supplied Control Point"] then
				cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, nil, {["overridable_by_constraint"] = true, ["sets_particle_pos"] = true})
			else
				local name = attrib._categoryName .. " " .. attrib.functionName .. ": randomly distribute to highest supplied Control Point"
				PartCtrl_CPoint_AddToProcessed(processed, -1, name, "position_combine", {["sets_particle_pos"] = true, ["force_allow_-1"] = true}, attrib)
				//TODO: ehh, this makes it combine with the control of the first available position control; 
				//works on all fx i could find, but could potentially result in bad cpoints on more complex fx 
			end
			if (attrib["scale cp (distance/speed/local speed)"] or -1) > -1 then
				local function DoSphereAxis(axis, label, axisvs, min)
					local doaxis = false
					for k, v in pairs (axisvs) do
						if (attrib[k] or v) != v then
							doaxis = true
							break
						end
					end
					if doaxis then
						cpoint_from_attrib_value(processed, attrib, "scale cp (distance/speed/local speed)", -1, "axis", {
							["axis"] = axis,
							["label"] = "Sphere " .. label .. " multiplier",
							["inMin"] = min,
							["outMin"] = min,
							//no max
							["default"] = 1,
						})
					end
				end
				DoSphereAxis(0, "distance", {["distance_min"] = 0, ["distance_max"] = 0}, 0) //no point in negative scale for this one
				DoSphereAxis(1, "speed", {["speed_min"] = 0, ["speed_max"] = 0})
				DoSphereAxis(2, "local speed", {["speed_in_local_coordinate_system_min"] = Vector(), ["speed_in_local_coordinate_system_max"] = Vector()})
			end
		end,
		["remap control point to scalar"] = function(processed, attrib)
			//like the operator of the same name
			//controls a whole bunch of stuff (lifetime, radius, alpha, etc.) with the value of a single axis of the cpoint, definitely not a position control
			local axis = attrib["input field 0-2 X/Y/Z"] or 0
			if axis > -1 then
				//Make sure we have values for everything, just in case; use default values from pet otherwise
				local field = attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS //PARTICLE_ATTRIBUTE_x enum
				local label = ParticleAttributeNames[field]
				local inMin = attrib["input minimum"] or 0
				local inMax = attrib["input maximum"] or 1
				local outMin = attrib["output minimum"] or 0
				local outMax = attrib["output maximum"] or 1
				local is_multiplier = attrib["output is scalar of initial random range"] //or attrib["output is scalar of current value"] //this one doesn't have this value
				local default
				local decimals = nil
				if field == PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS and !is_multiplier then
					//radius scalars should default to a nice big size, not 1 pixel
					default = math.Remap(8, outMin, outMax, inMin, inMax)
				elseif field == PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA or field == PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA2 then 
					//Alpha should always default to max visibility;
					//make sure to handle wacky fx like tf2's speech_mediccall that flip the scale around on output
					if outMin <= outMax then
						default = math.max(inMin, inMax)
					else
						default = math.min(inMin, inMax)
					end
				elseif field == PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER or field == PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1 then
					//sequence number scalars should be whole numbers, and default to 0 (first sequence)
					default = math.Remap(0, outMin, outMax, inMin, inMax)
					decimals = 0
				else
					//default to 1
					default = math.Remap(1, outMin, outMax, inMin, inMax)
				end
				//make sure the default value of the control in the edit window isn't outside its range
				default = math.Clamp(default, math.Remap(outMin, outMin, outMax, inMin, inMax), math.Remap(outMax, outMin, outMax, inMin, inMax))
				if is_multiplier then
					label = label .. " Scale"
				end
				cpoint_from_attrib_value(processed, attrib, "input control point number", 0, "axis", {
					["axis"] = axis,
					["label"] = label,
					["inMin"] = inMin,
					["inMax"] = inMax,
					["outMin"] = outMin,
					["outMax"] = outMax,
					["default"] = default,
					["decimals"] = decimals,
				})
			end
		end,
		["remap control point to vector"] = function(processed, attrib)
			//same as operator of the same name; actually, orangebox only has the initializer version of this, the operator is new from pcf v5
			//Similar to above, use all 3 axes of the cpoint to set Position, Roll, or Color
			local field = attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_XYZ //PARTICLE_ATTRIBUTE_x enum //assume the default is Position because that's what shows in pet by default, just like Radius is for scalars; can't find any v5 fx to test with that omit this value
			local label = ParticleAttributeNames[field]
			local inMin = attrib["input minimum"] or Vector()
			local inMax = attrib["input maximum"] or Vector()
			local outMin = attrib["output minimum"] or Vector()
			local outMax = attrib["output maximum"] or Vector()
			local is_multiplier = attrib["output is scalar of initial random range"] //or attrib["output is scalar of current value"] //this one doesn't have this value
			local default = nil
			local colorpicker = nil
			if field == PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB or is_multiplier then
				//Color should default to the equivalent of 1,1,1 (white),
				//and multipliers should default to 100%
				default = Vector(math.Remap(1, outMin.x, outMax.x, inMin.x, inMax.x), math.Remap(1, outMin.y, outMax.y, inMin.y, inMax.y), math.Remap(1, outMin.z, outMax.z, inMin.z, inMax.z))
				if field == PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB then
					colorpicker = true
				end
			else
				//default to 0
				default = Vector(math.Remap(0, outMin.x, outMax.x, inMin.x, inMax.x), math.Remap(0, outMin.y, outMax.y, inMin.y, inMax.y), math.Remap(0, outMin.z, outMax.z, inMin.z, inMax.z))
			end
			for i = 1, 3 do
				//make sure the default value of the control in the edit window isn't outside its range (see portal 2 portalgun_top_light_squiggles)
				default[i] = math.Clamp(default[i], math.Remap(outMin[i], outMin[i], outMax[i], inMin[i], inMax[i]), math.Remap(outMax[i], outMin[i], outMax[i], inMin[i], inMax[i]))
			end
			if is_multiplier then
				label = label .. " Scale"
			end
			cpoint_from_attrib_value(processed, attrib, "input control point number", 0, "vector", {
				["label"] = label,
				["inMin"] = inMin,
				["inMax"] = inMax,
				["outMin"] = outMin,
				["outMax"] = outMax,
				["default"] = default,
				["colorpicker"] = colorpicker,
			})
			cpoint_from_attrib_value(processed, attrib, "local space CP", -1, "position_combine") //uses the cpoint's angles to rotate the output in some odd way, can be used to make a position sort-of-rotate with the cpoint, or make colors change as it spins
		end,
		["remap cp orientation to rotation"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control point", 0, "position_combine") end, //uses the cpoint's angles to set the pitch/yaw/roll of particles; this is an angle control, so position_combine it
		["remap initial direction to cp to vector"] = function(processed, attrib)
			//like "remap direction to cp to vector" but an initializer instead of operator.
			//can't find any fx using this in portal2/asw/l4d2, and can't get it to do anything useful in a custom effect,
			//so just position_combine it like the operator version.
			cpoint_from_attrib_value(processed, attrib, "control point", 0, "position_combine")
		end,
		["remap initial distance to control point to scalar"] = function(processed, attrib)
			local label = ParticleAttributeNames[attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS] //PARTICLE_ATTRIBUTE_x enum //put this in the table so we can see what it does in the debug
			cpoint_from_attrib_value(processed, attrib, "control point", 0, nil, {["label"] = label})
		end,
		["remap scalar to vector"] = function(processed, attrib)
			if (attrib["output field"] or 0) then //cpoint is only used by position vector (0) to make the position relative to that cpoint (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3155)
				cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, nil, {["sets_particle_pos"] = true}) //yes, this sets particle pos, see unusual_poseidon_light_ fx
			end
		end,
		["remap speed to scalar"] = function(processed, attrib)
			if !attrib["per particle"] then
				//uses the speed of the cpoint to set a scalar value, just position_combine it
				cpoint_from_attrib_value(processed, attrib, "control point number (ignored if per particle)", 0, "position_combine")
			end
		end,
		["sequence from control point"] = function(processed, attrib)
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_initializers.cpp#L3172
			//this is incredibly specific and needs its own special handling with textentries.

			//every digit of the number supplied to each axis is turned into a sprite, with each digit potentially corresponding to 
			//a unique sprite, and each axis having its own set of sprites.

			//in the only working effect with this operator, particles/infested_damage.pcf damage_numbers_digits from alien swarm, 
			//axis 0 shows a minus for every 0 and a plus for every 1 or higher; axis 1 shows the corresponding number for each digit; 
			//and axis 2 shows an exclamation point for every digit. this means axis 1 just displays whichever number you give it, 
			//while the other two are less intuitive.

			//local max = Vector(99999999, 99999999, 99999999)
			local max = Vector(16384, 16384, 16384) //limit due to technical limitations of net.WriteVector (https://wiki.facepunch.com/gmod/net.WriteVector)
			local min = Vector(0,0,0)
			cpoint_from_attrib_value(processed, attrib, "control point", 1, "vector", {
				["label"] = "Sprites",
				["inMin"] = min,
				["inMax"] = max,
				["outMin"] = min,
				["outMax"] = max,
				["default"] = Vector(0,1,0),
				["decimals"] = 0,
				//info text can't be too specific, since custom fx could potentially use these for any conceivable sprites, and we would have no way of knowing about it
				["textentry"] = {["info"] = "Enter numbers into the boxes to set the effect's sprites. Each number can correspond to a different sprite, and each axis has its own set of sprites."},
			})
		end,
		["set hitbox position on model"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0) end, //presumably uses the model that the cpoint is attached to, so use position; TODO: these two are csgo(?) ports and i can't get them to do anything, don't know if they even function in gmod
		["set hitbox to closest hitbox"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0) end, //^
		["velocity inherit from control point"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control point number", 0, "position_combine") end,
		["velocity noise"] = function(processed, attrib)
			if attrib["Apply Velocity in Local Space (0/1)"] then //cpoint is only used if this is enabled (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L1243)
				cpoint_from_attrib_value(processed, attrib, "Control Point Number", 0, "position_combine")
			end
		end,
		["velocity random"] = function(processed, attrib)
			local lmin = attrib["speed_in_local_coordinate_system_min"] or Vector()
			local lmax = attrib["speed_in_local_coordinate_system_max"] or Vector()
			if lmin != vector_origin or lmax != vector_origin then //code uses this cpoint if bHasLocalSpeed (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L892), which is determined by this same check (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L855)
				//if !(lmin.x == lmin.y and lmin.x == lmin.z and lmin.x == -lmax.x and lmin.y == -lmax.y and lmin.z == -lmax.z) then
					cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine")
				//end
			end
		end,
		["velocity repulse from world"] = function(processed, attrib)
			if !attrib["Per Particle World Collision Tests"] then //according to code, neither the cpoint nor broadcast-to-children are used with per-particle collision on (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3421)
				if !attrib["Inherit from Parent"] then
					cpoint_from_attrib_value(processed, attrib, "control_point_number", 0)
					local i = attrib["control points to broadcast to children (n + 1)"] or -1 //this also isn't used if inheriting
					if i != -1 then
						local groupid = attrib["Child Group ID to affect"] or 0
						local name = attrib._categoryName .. " " .. attrib.functionName .. ": control points to broadcast to children (n + 1)"
						PartCtrl_CPoint_AddToProcessed(processed, i, name, "output_children", {["groupid"] = groupid}, attrib)
						PartCtrl_CPoint_AddToProcessed(processed, i + 1, name, "output_children", {["groupid"] = groupid}, attrib) //this sets axis 0 to a force value, and the other two to 0 (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3586)
					end
				else
					//let players manually set the values if they spawned a child effect on its own, or for some hypothetical use case where it's intended to be supplied by code or something
					//this is silly, who's going to use this?
					cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "vector", {
						["label"] = "Velocity Direction",
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
					}, attrib)
					//according to code, broadcast to children doesn't run if inheriting
				end
			end
		end,
		["velocity set from control point"] = function(processed, attrib)
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_initializers.cpp#L4160-L4255
			//"control point number"'s position sets the velocity value, local to either the map or to "comparison control point number"
			//"local space control point number"'s ANGLE rotates the velocity value; its position does not matter
			//"direction only" makes the outputted velocity a normalized vector (which is still multiplied by another param)
			cpoint_from_attrib_value(processed, attrib, "comparison control point number", -1, "position_combine")
			cpoint_from_attrib_value(processed, attrib, "local space control point number", -1, "position_combine")
			local relative_to_cpoint = attrib["comparison control point number"] or -1
			if !(relative_to_cpoint > -1) then relative_to_cpoint = nil end
			local outMax = 1024 //arbitrary
			local inMax = outMax / (attrib["velocity scale"] or 1)
			local default = 100 / (attrib["velocity scale"] or 1)
			local label = "Velocity"
			if attrib["direction only"] then
				inMax = 1
				outMax = 1
				default = 1
				label = "Velocity Direction"
			end
			cpoint_from_attrib_value(processed, attrib, "control point number", 0, "vector", {
				["label"] = label,
				["inMin"] = Vector(-inMax,-inMax,-inMax),
				["inMax"] = Vector(inMax,inMax,inMax),
				["outMin"] = Vector(-outMax,-outMax,-outMax),
				["outMax"] = Vector(outMax,outMax,outMax),
				["default"] = Vector(default,0,0),
				["relative_to_cpoint"] = relative_to_cpoint
			})
		end,
	},
	["emitters"] = {
		["emit noise"] = function(processed, attrib)
			if (attrib["emission minimum"] or 0) > 0 or (attrib["emission maximum"] or 100) > 0 then
				processed["has_emitter"] = true
			end
		end,
		["emit to maintain count"] = function(processed, attrib)
			if (attrib["count to maintain"] or 100) > 0 then
				processed["has_emitter"] = true
			end
			local axis = attrib["maintain count scale control point field"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "maintain count scale control point", -1, "axis", {
					["axis"] = axis,
					["label"] = "Maintain Count Scale",
					["inMin"] = 0,
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
		end,
		["emit_continuously"] = function(processed, attrib)
			if (attrib["emission_rate"] or 100) > 0 then
				processed["has_emitter"] = true
			end
			local axis = attrib["emission count scale control point field"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "emission count scale control point", -1, "axis", {
					["axis"] = axis,
					["label"] = "Emission Count Scale",
					["inMin"] = 0,
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
		end,
		//"emit noise" and "emit_continuously" have "scale emission to used control points", which wiki claims is a cpoint id, but it's actually a float that's multiplied by the number of cpoints the effect has, we don't care about this (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_emitters.cpp#L449)
		["emit_instantaneously"] = function(processed, attrib)
			if (attrib["num_to_emit_minimum"] or -1) > 0 or (attrib["num_to_emit"] or 100) > 0 then
				processed["has_emitter"] = true
			end
			local axis = attrib["emission count scale control point field"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "emission count scale control point", -1, "axis", {
					["axis"] = axis,
					["label"] = "Emission Count Scale",
					["inMin"] = 0,
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
		end,
	},
	["forces"] = { //ForceGenerator
		["force based on distance from plane"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control point number", 0) end, //don't know if the extra overrides on "pull toward control point" are necessary here, i don't think any existing fx need them
		["pull towards control point"] = function(processed, attrib)
			local type = nil
			if math.abs(attrib["amount of force"] or 0) < 10 then //can be negative
				//a lot of effects have this attrib with miniscule force values, for whatever reason. they don't visibly appear to do anything, maybe it's part of some hacky workaround
				//that particle developers use, i don't know. either way, don't let them create their own position control in these cases, because they aren't useful.
				type = "position_combine" 
			end
			cpoint_from_attrib_value(processed, attrib, "control point number", 0, type, {["overridable_by_constraint"] = true, ["overridable_by_drag"] = true})
		end
	},
	["constraints"] = {
		//"collision via traces" always sets cpoint 0 in pet, but this doesn't seem necessary, it functions just fine without it in a test effect using only cpoint 1, and even if we add another cpoint for 0 it doesn't actually seem to do anything; can't find any code actually using a cpoint either (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L630-L1098)
		["constrain distance to control point"] = function(processed, attrib)
			if !attrib["global center point"] then //according to code, cpoint is only used if global center point is false (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L87)
				cpoint_from_attrib_value(processed, attrib, "control point number", 0, nil, {["sets_particle_pos"] = true}) //pet doesn't add control for this
				if (attrib["maximum distance"] or 100) < 1 then
					processed["constraint_does_override"] = true //global value on the effect, not cpoint-specific
				end
			end
		end,
		["constrain distance to path between two control points"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "start control point number", 0, nil, {["sets_particle_pos"] = true})
			cpoint_from_attrib_value(processed, attrib, "end control point number", 0, nil, {["sets_particle_pos"] = true})
			//if there's no way for other cpoint attribs (like the ones that initialize in a box/sphere) to influence the particles because this constraint forces them onto a very specific path, then don't make position controls for those cpoints
			if (attrib["maximum distance"] or 100) < 1 then
				processed["constraint_does_override"] = true //global value on the effect, not cpoint-specific
			end
		end,
		//"constrain particles to a box" is in worldspace only?? why? what is this for?
		["prevent passing through a plane"] = function(processed, attrib)
			if !attrib["global origin"] or !attrib["global normal"] then
				cpoint_from_attrib_value(processed, attrib, "control point number", 0)
			end
		end,
		//code says this one always uses cpoint 0 for some trace stuff, but when trying to test it, on every single effect i could find or make with this attribute, it just doesn't seem to work at all? particles pass through brushes, displacements, and static props just fine. (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L473)
		//TODO: test on a map that isn't gm_flatgrass, maybe it's a problem with distance from the world origin or something
		//["prevent passing through static part of world"] = function(processed, attrib) PartCtrl_CPoint_AddToProcessed(processed, 0, attrib._categoryName .. " " .. attrib.functionName .. ": always uses cpoint 0", nil, nil, attrib) end,
	}
}
function PartCtrl_ProcessPCF(filename)
	if hook.Call("PartCtrl_PreProcessPCF", nil, filename) == false then return end //Let hook funcs prevent PCFs from being read by returning false

	//don't print non-critical messages unless we're in developer mode; 
	//always print messages for bugs that player should report
	local dodebug = (GetConVarNumber("developer") >= 1)

	local t = PartCtrl_ReadPCF(filename)
	if !t then
		if dodebug then MsgN("PartCtrl: ", filename, " couldn't be read") end
	else
		PartCtrl_CachedReadPCFs[filename] = t
		local t2 = {}
		for particle, ptab in pairs (t) do
			local processed = {
				["cpoints"] = {},
				["children"] = t[particle].children,
				["parents"] = {},
			}
			//Go through all of the effects's operators (initializers, operators, renderers, etc. are all called "operators" internally, it's confusing) 
			//and use the corresponding functions in processfuncs to "process" them (populate the table above with all their relevant cpoint info). 
			//This is the meat of this function, everything else is just working with this info.
			for k, v in pairs (processfuncs) do
				if ptab[k] then
					for _, attrib in pairs (ptab[k]) do
						if !((attrib["operator start fadein"] or 0) >= 99) and !((attrib["operator end fadein"] or 0) >= 99) then //some fx use a superlong fadein to effectively comment out attribs, ridiculous (particles/advisor_fx.pcf Advisor_Psychic_Attach_01b operator Remap Distance to Control Point to Scalar)
							if !attrib.functionName then
								if dodebug then MsgN("PartCtrl: ", filename, " particle ", particle, " has attribute with no function name") end
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
			if (ptab["cull_radius"] or 0) > 0 then //(https://github.com/VSES/SourceEngine2007/blob/master/src_main/particles/particles.cpp#L500-L503)
				cpoint_from_attrib_value(processed, ptab, "cull_control_point", 0, "position_combine", {
					["ignore_outputs"] = true, //unlike the other things that ignore outputs, this one actually does set a position, but outputs still don't override it because it runs first i guess
					["dont_inherit"] = true,
				}) //this system only runs if an obscure cheat command cl_particle_retire_cost is enabled (https://developer.valvesoftware.com/wiki/Particle_System_Properties), and also only runs on the frame a particle is spawned (https://github.com/nillerusr/source-engine/blob/master/game/client/particlemgr.cpp#L1707); culls the particle by deleting it (or optionally spawning an alternative particle) if this cpoint is taking up too much of the screen
			end
			cpoint_from_attrib_value(processed, ptab, "control point to disable rendering if it is the camera", -1, "position_combine", {
				["ignore_outputs"] = true, //this cpoint sets an associated model, not a position, so outputs don't override it
				["dont_inherit"] = true,
			}) //makes the particle not render if this cpoint is attached to the ent the camera is viewing from (i.e. the player, or a camera ent they're using)
			if ptab["preventNameBasedLookup"] then
				processed["prevent_name_based_lookup"] = true //makes the particle impossible to spawn on its own, but still usable as a child. not sure what the point of this is.
			end
			if (ptab["initial_particles"] or 0) > 0 then
				processed["has_emitter"] = true
			end
			t2[particle] = processed
		end
		for particle, _ in pairs (t2) do
			if !t2[particle]["has_renderer"] then
				for _, childtab in pairs (t2[particle].children) do
					if t2[childtab.child] and t2[childtab.child]["parent_force_has_renderer"] then
						t2[particle]["has_renderer"] = true 
						break
					end
				end
			end
		end
		//Inherit cpoint info from children; for spawnicons, particle entities, and control windows to make use of; cpoint modes handle inheritance differently because of how outputs work,
		//so store all of this in a separate table for now, and don't apply it until after we're done setting cpoint modes.
		for particle, _ in pairs (t2) do
			local cpoints = table.Copy(t2[particle].cpoints)
			local function cpoints_from_child_fx(cpoints, particle2, depth)
				depth = depth or 0
				depth = depth + 1
				if depth > 99 then
					MsgN("PartCtrl: ", filename, " ", particle2, " child ", child, " cpoints_from_child_fx has crazy recursion when trying to get child fx, aborting - report this bug!") //don't even know if this is possible, but want to be safe anyway
					return cpoints
				end
				for _, childtab in pairs (t[particle2].children) do
					if t2[childtab.child] then
						local cpoints2 = table.Copy(t2[childtab.child].cpoints)
						//make sure the child has also inherited cpoints from its own children
						if istable(t[childtab.child].children) then
							//if #t[childtab.child].children > 0 then MsgN("children of ", childtab.child, ":") PrintTable(t[childtab.child].children) end
							for _, childtab2 in pairs (t[childtab.child].children) do
								if t2[childtab2.child] then
									local cpoints3 = cpoints_from_child_fx(table.Copy(t2[childtab2.child].cpoints), childtab2.child, depth)
									for i, tab in pairs (cpoints3) do
										cpoints2[i] = cpoints2[i] or {}
										for processedk, processedv in pairs (tab) do
											for k, v in pairs (processedv) do
												//mark attribs as being inherited from a child
												if v["name"] then
													processedv[k]["name"] = "child " .. childtab2.child .. " | " .. processedv[k]["name"]
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
										processedv[k]["name"] = "child " .. childtab.child .. " | " .. processedv[k]["name"]
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
				return cpoints
			end
			//store this separately for now, so that other particles grabbing cpoints from their children won't retrieve an already altered table and then alter it again
			t2[particle].cpoints_with_children = cpoints_from_child_fx(cpoints, particle)
		end
		for particle, _ in pairs (t2) do
			//Store the PARTCTRL_CPOINT_MODE_ for each cpoint
			local modes = {}
			local output_children = {}
			local output_axis = {}
			local on_model = nil
			local sets_particle_pos = nil
			local remove_if_other_cpoint_is_empty = {}
			local function SetCPointModes(particle2, parent)
				//a little heavy-handed? maybe. might result in some false positives in complex hierarchy trees. haven't found any actual examples of this causing problems,
				//and we'd have to totally rework how we handle hierarchy here to make this more accurate (currently have no way to get the parent of a parent, etc. to check if
				//it's using output_children); output_children[parent] structure probably does limits wrong if a parent has multiple children of the same effect, who then
				//themselves use output_children (they'd all share the same limit), but no existing fx use a complicated structure like that.

				local groupid = t[particle2]["group id"] or 0

				if parent and !output_children[parent] then
					tab = nil
					for k, v in pairs (t2[parent].cpoints) do
						if v["output_children"] then
							for k2, v2 in pairs (v["output_children"]) do
								if v2["groupid"] then
									tab = tab or {}
									tab[k] = tab[k] or {}
									//"limit" value sets the number of children to override the target cpoint on;
									//use the largest possible limit provided, no limit provided means unlimited
									local limit = v2["limit"] or math.huge
									if tab[k][v2["groupid"]] then
										limit = math.max(limit, tab[k][v2["groupid"]])
									end
									tab[k][v2["groupid"]] = limit
								end
							end
						end
					end
					if tab then
						output_children[parent] = tab
					end
				end
				
				for k, v in pairs (t2[particle2].cpoints) do
					//this method doesn't work, argh
					//can't detect that a parent of a parent is doing output_children on a cpoint
					//if output_children[parent] and output_children[parent][k] and output_children[parent][k][groupid] and output_children[parent][k][groupid] > 0 then
					//	//if the target cpoint is being overridden by output_children, decrease the limit by 1 if applicable, and then skip to the next cpoint
					//	output_children[parent][k][groupid] = output_children[parent][k][groupid] - 1
					//else
					//dumber brute-force method, just get the first parent setting output_axis, and hope nothing complicated is using limits
					local doskip = false
					for ent, tab in pairs (output_children) do
						if tab[k] and tab[k][groupid] and tab[k][groupid] > 0 then
							//if the target cpoint is being overridden by output_children, decrease the limit by 1 if applicable, and then skip to the next cpoint
							output_children[ent][k][groupid] = output_children[ent][k][groupid] - 1
							doskip = true
							break
						end
					end
					if !doskip then
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
							if modes[k] == nil then
								did_output = true
								modes[k] = PARTCTRL_CPOINT_MODE_NONE
							end
						end
						remove_if_other_cpoint_is_empty[k] = {}
						if v["position"] then
							//If we're inheriting the cpoint mode from a child, make sure it's not from an attrib that shouldn't be inherited
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
									if modes[k] == nil or modes[k] == PARTCTRL_CPOINT_MODE_POSITION_COMBINE or (did_output and ignore_outputs) then
										if t2[particle2].constraint_does_override and v2["overridable_by_constraint"]
										or t2[particle2].drag_does_override and v2["overridable_by_drag"] then
											modes[k] = PARTCTRL_CPOINT_MODE_POSITION_COMBINE
										else
											modes[k] = PARTCTRL_CPOINT_MODE_POSITION
										end
										did_output = false //make sure position_combine below doesn't override this
									end
									if modes[k] == PARTCTRL_CPOINT_MODE_POSITION then
										//also make a list of all the cpoints that have "on_model" fx so that we can print extra info about it in spawnicons
										if v2["on_model"] then
											on_model = on_model or {}
											on_model[k] = true
										end
										//also check for "remove_if_other_cpoint_is_empty"; we only care about this if ALL position controls for this cpoint have this
										local remove = v2["remove_if_other_cpoint_is_empty"]
										if remove != nil and remove_if_other_cpoint_is_empty[k] != nil then
											remove_if_other_cpoint_is_empty[k][remove] = true
										else
											remove_if_other_cpoint_is_empty[k] = nil
										end
									end
								end
								if v2["sets_particle_pos"] and !t2[particle2].sets_particle_pos_forcedisable then
									sets_particle_pos = sets_particle_pos or {}
									sets_particle_pos[k] = true
								end
							end
						end
						if v["position_combine"] then
							//If we're inheriting the cpoint mode from a child, make sure it's not from an attrib that shouldn't be inherited
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
									if modes[k] == nil or (did_output and ignore_outputs) then
										modes[k] = PARTCTRL_CPOINT_MODE_POSITION_COMBINE
									end
								end
								if v2["sets_particle_pos"] and !t2[particle2].sets_particle_pos_forcedisable then
									sets_particle_pos = sets_particle_pos or {}
									sets_particle_pos[k] = true
								end
							end
						end
						if v["vector"] then
							if modes[k] == nil and (t2[particle2].has_renderer and t2[particle2].has_emitter) then
								modes[k] = PARTCTRL_CPOINT_MODE_VECTOR
							end
						end
						if v["axis"] then
							local doaxis = false
							if modes[k] == nil then
								for k2, v2 in pairs (v["axis"]) do
									//handle output_axis overriding specific axes
									if !istable(output_axis[k]) or !output_axis[k][v2.axis] then
										doaxis = true
									end
								end
							end
							if doaxis and (t2[particle2].has_renderer and t2[particle2].has_emitter) then
								modes[k] = PARTCTRL_CPOINT_MODE_AXIS
							end
						end
					end
				end
				//MsgN("Current modes:")
				//PrintTable(modes)

				//Also inherit min_length stuff from children here, this loop is a good place to do this
				if particle2 != particle and t2[particle2].min_length_raw_hasdecay and t2[particle2].min_length_raw then
					t2[particle].min_length_raw_child = math.max((t2[particle].min_length_raw_child or 0), t2[particle2].min_length_raw)
				end
			end
			SetCPointModes(particle)
			//Cpoints that haven't been filled in yet should inherit from children
			local function CPointModesFromChildren(particle2, depth)
				depth = depth or 0
				depth = depth + 1
				if depth > 99 then
					MsgN("PartCtrl: ", filename, " ", particle2, " CPointModesFromChildren has crazy recursion when trying to get child fx, aborting - report this bug!") //don't even know if this is possible, but want to be safe anyway
					return
				end

				if istable(t2[particle2].children) then
					for _, childtab in pairs (t2[particle2].children) do
						if !t2[childtab.child] then
							if dodebug then MsgN("PartCtrl: ", filename, " ", particle2, " CPointModesFromChildren tried to get nonexistent child effect ", child) end
						else
							SetCPointModes(childtab.child, particle2)
							//Now inherit from the child's children, and so on
							//TODO: the order here might not be quite right if we have multiple branching children of children, but I don't know if that actually matters in practice
							CPointModesFromChildren(childtab.child, depth)
						end
					end
				end
			end
			CPointModesFromChildren(particle)

			//Do remove_if_other_cpoint_is_empty thing for operator "set control point positions"; this operator has "parent" cpoints that move 
			//around "child" cpoints, but if those child cpoints don't actually do anything, then the parent cpoints are useless, so remove them.
			for k, v in pairs (remove_if_other_cpoint_is_empty) do
				if istable(v) and table.Count(v) > 0 and modes[k] == PARTCTRL_CPOINT_MODE_POSITION then
					local empty = true
					for k2, _ in pairs (v) do
						if t2[particle].cpoints_with_children[k2] and t2[particle].cpoints_with_children[k2].position then
							empty = false
							break
						end
					end
					if empty then
						//MsgN(particle, ": empty detected: cpoint ", k)
						modes[k] = PARTCTRL_CPOINT_MODE_NONE
					end
				end
			end

			local shouldcull = !t2[particle].has_renderer or !t2[particle].has_emitter
			local needfallback = -1
			for k, v in pairs (modes) do
				if !shouldcull and !needfallback then break end
				if shouldcull and v != PARTCTRL_CPOINT_MODE_NONE then
					//Clear out empty effects (no renderer, no emitter, no cpoints even from children)
					shouldcull = false
				end
				if needfallback then 
					if v == PARTCTRL_CPOINT_MODE_POSITION then
						//Create fallback position cpoint for effects that don't have any
						needfallback = nil
					end
				end
			end
			if shouldcull then
				t2[particle]["renderer_emitter_shouldcull"] = true
			end
			if needfallback then
				if !modes[0] then
					//just use cpoint 0 if it's open
					needfallback = 0
				else
					//If possible, turn the first available position_combine cpoint into a normal position cpoint
					for k, v in SortedPairs (modes) do
						if k != -1 and v == PARTCTRL_CPOINT_MODE_POSITION_COMBINE then
							needfallback = k
							break
						end
					end
				end
				//if neither of those work, then use the nonsense cpoint -1, which is probably fine since it's most likely
				//not going to be able to do anything anyway; it's just there so we have an entity to associate the effect with.

				t2[particle].cpoints_with_children[needfallback] = t2[particle].cpoints_with_children[needfallback] or {}
				t2[particle].cpoints_with_children[needfallback].position = t2[particle].cpoints_with_children[needfallback].position or {}
				table.insert(t2[particle].cpoints_with_children[needfallback].position, {["name"] = "fallback position cpoint created due to no position cpoint"})

				modes[needfallback] = PARTCTRL_CPOINT_MODE_POSITION
			end
			//Finally, store the cpoint modes
			for k, v in pairs (modes) do
				t2[particle].cpoints_with_children[k].mode = v
			end

			t2[particle]["sets_particle_pos"] = sets_particle_pos

			//Do info text for on_model
			if on_model then
				local text = ""
				text = "This effect will apply to a whole model if control point"
				if table.Count(on_model) > 1 then text = text .. "s" end
				local docomma = false
				for k, _ in pairs (on_model) do
					if docomma then text = text .. "," end
					text = text .. " " .. k
					docomma = true
				end
				if docomma then
					text = text .. " is attached."
				else
					text = text .. " are attached."
				end
				PartCtrl_AppendInfoText(t2[particle], text)
			end

			//Do min_length for tracer fx
			local raw = t2[particle].min_length_raw_child or 0
			if t2[particle].min_length_raw_hasdecay then
				raw = math.max((t2[particle].min_length_raw or 0), raw)
			end
			if raw > 100 then //don't bother if it would actually make it smaller than default
				t2[particle].min_length = raw
			end
		end
		for particle, _ in pairs (t2) do
			//Now that we're done setting cpoint modes, apply cpoint data from children
			t2[particle].cpoints = t2[particle].cpoints_with_children
			t2[particle].cpoints_with_children = nil
			for k, v in pairs (t2[particle].cpoints) do
				if v.mode == nil then
					//Fill in empty mode entries
					t2[particle].cpoints[k].mode = PARTCTRL_CPOINT_MODE_NONE
				end
				if v.vector then
					//Squish together vector entries that have the same values except for the name
					local newvectors = {}
					for k2, v2 in pairs (v.vector) do
						if v.vector[k2] != nil then
							local newtab = table.Copy(v2)
							for k3, v3 in pairs (v.vector) do
								if k3 != k2 and v3.label == v2.label and v3.inMin == v2.inMin and v3.inMax == v2.inMax
								and v3.outMin == v2.outMin and v3.outMax == v2.outMax then
									newtab.name = newtab.name .. ",\n" .. v3.name
									v.vector[k3] = nil
								end
							end
							v.vector[k2] = nil
							table.insert(newvectors, newtab)
						end
					end
					t2[particle].cpoints[k].vector = newvectors
					//set "which" value (which entry in v.vector for the particle entity, edit window, etc. to get values like inMin and label from)
					t2[particle].cpoints[k].which = 0
					for k2, v2 in pairs (newvectors) do
						t2[particle].cpoints[k].which = k2
						break
					end
				end
				if v.output_axis then
					for k2, v2 in pairs (v.output_axis) do
						t2[particle].cpoints[k]["which_" .. v2.axis] = -1 //special value for both vector and axis controls to check for, so they can remove a specific axis being overwritten
					end
				end
				if v.axis then
					//Squish together axis entries that have the same values except for the name
					local newaxes = {}
					for k2, v2 in pairs (v.axis) do
						if v.axis[k2] != nil then
							local newtab = table.Copy(v2)
							for k3, v3 in pairs (v.axis) do
								if k3 != k2 and v3.label == v2.label and v3.inMin == v2.inMin and v3.inMax == v2.inMax
								and v3.outMin == v2.outMin and v3.outMax == v2.outMax and v3.axis == v2.axis then
									newtab.name = newtab.name .. ",\n" .. v3.name
									v.axis[k3] = nil
								end
							end
							v.axis[k2] = nil
							table.insert(newaxes, newtab)
						end
					end
					t2[particle].cpoints[k].axis = newaxes
					//set "which" value for each axis (which entry in v.axis for the particle entity, edit window, etc. to get values like inMin and label from)
					for i = 0, 2 do
						if t2[particle].cpoints[k]["which_" .. i] != -1 then
							t2[particle].cpoints[k]["which_" .. i] = 0
							for k2, v2 in pairs (newaxes) do
								if v2.axis == i then 
									t2[particle].cpoints[k]["which_" .. i] = k2
									break
								end
							end
						end
					end
				end
			end

			//Flag effects for culling - we do this before calling the PostProcessPCF hook, so the hook can override it
			local shouldcull = nil
			//Cull empty effects
			if t2[particle].renderer_emitter_shouldcull then
				shouldcull = "This particle effect has no valid renderer and/or no valid emitter, and no control points\ninherited from children, which means it's probably empty or blank. If this effect was\nflagged in error (it actually has a visible component of some kind), then report this bug!"
			end
			//Cull effects that are stuck at the world origin because they don't have any cpoints setting their particle pos
			if !t2[particle].sets_particle_pos then
				if shouldcull then
					shouldcull = shouldcull .. "\n\n"
				else
					shouldcull = ""
				end
				shouldcull = shouldcull .. "This particle effect doesn't have any control point attributes setting the particles' spawn\nposition (i.e. 'Position Within Box Random'), which means it will always spawn particles\nat the world origin. This isn't useful to players 99% of the time, and would just clutter up\nspawnlists and searches with unusable effects. If this effect was flagged in error (it\nactually *does* control where particles spawn with a control point, it doesn't spawn them\nat 0,0,0), then report this bug!"
			end
			//Also, now that their parents have inherited cpoint data from them, cull effects with preventNameBasedLookup, since we can't spawn them on their own.
			if t2[particle].prevent_name_based_lookup then
				if shouldcull then
					shouldcull = shouldcull .. "\n\n"
				else
					shouldcull = ""
				end
				shouldcull = shouldcull .. "This particle effect has the value preventNameBasedLookup set to true, which prevents\nthe game from spawning it directly, though other effects can still use it as a child."
			end
			t2[particle].shouldcull = shouldcull
			//Also add info text for viewmodel effects here, because this isn't inherited
			if t[particle]["view model effect"] then
				PartCtrl_AppendInfoText(t2[particle], "Viewmodel effect: draws in front of everything, and has a distorted position unless attached to a model on a non-0 attachment.")
			end
		end
		//Now that the processed table is finished, let hook funcs modify it arbitrarily (including deciding which fx to cull)
		hook.Call("PartCtrl_PostProcessPCF", nil, filename, t2)
		for particle, _ in pairs (t2) do
			//Cull bad effects from the table.
			//If the player starts up the game in developer mode, effects aren't culled, but instead have a warning on the spawnicon telling the dev why they won't show up to players.
			if t2[particle].shouldcull and GetConVarNumber("developer") < 1 then
				t2[particle] = nil
			end
		end
		//Remove culled children and empty entries from child lists, add parents to parent lists
		for particle, _ in pairs (t2) do
			local shouldclean = false
			for k, childtab in pairs (t2[particle].children) do
				if !t2[childtab.child] then 
					t2[particle].children[k] = nil
					shouldclean = true
				else
					table.insert(t2[childtab.child].parents, particle)
				end
			end
			if shouldclean then
				t2[particle].children = table.ClearKeys(t2[particle].children)
			end
		end
		
		if table.Count(t2) == 0 then
			if dodebug then MsgN("PartCtrl: ", filename, " contains no usable effects, ignoring") end
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

function PartCtrl_ProcessUtilFx()

	local utilfx = list.GetForEdit("PartCtrl_UtilFx", true)
	local utilfx2
	PartCtrl_UtilFxByTitle = {}

	if istable(utilfx) then
		for k, v in pairs (utilfx) do
			local t = {
				["cpoints"] = {},
				["info"] = v.info,
				["info_sfx"] = v.info_sfx,
				["utilfx"] = true,
				["default_time"] = v.default_time,
				["min_length"] = v.min_length
			}
			if t.default_time == nil then t.default_time = 1 end

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

	local dodebug = (GetConVarNumber("developer") >= 1)
	local starttime = SysTime()

	PartCtrl_AllPCFPaths = {}
	PartCtrl_SkippedPCFPaths = {} //also keep a list of skipped pcfs, so that PartCtrl_GetPCFConflicts() can still check them

	//First, get a list of conflicting pcf fallback files.
	//
	//The purpose of these is to resolve conflicts where multiple mounted games have different, unique pcf files sharing the same file path.
	//For example, TF2 has an "explosion.pcf" which shares a name with a pcf from HL2, and a "blood_impact.pcf" which shares a name with a pcf
	//included in gmod by default. The former will always be overridden if HL2 is mounted, and the latter will always be overridden no matter what.
	//Both of the TF2 pcfs contain unique effects that we don't want the player to be locked out of using, so this addon includes copies of TF2's 
	//"explosion.pcf" and "blood_impact.pcf" under a different file path, which this addon then handles by seamlessly including them alongside the 
	//other pcfs actually being loaded from TF2.
	//
	//This addon *only* includes copies of pcf files, *not* their textures/materials, so we only load fallbacks for games that are mounted.
	//
	//Currently includes fallback pcfs for the following games mounted: hl2, cstrike, tf, hl2mp, hl1, portal, left4dead2, portal2, swarm; retrieved 4/13/25
	//To check all pcf file conflicts (i.e. with more games mounted, or after a game update) run PartCtrl_GetPCFConflicts().
	//
	//Omissions:
	//- portal+portal2 blood_impact.pcf: contains completely blank overrides for blood_impact_red/green/yellow_01, seemingly as a brute-force way of removing 
	//  blood fx from portal. this is problematic for players, because loading this pcf overrides these fx, but the player won't be able to tell why because 
	//  blank fx are culled from the list. only other fx are 3 orphaned children of blood_impact_red, 2 of which are visually identical to stock. 
	//  blood_impact_red_01_goop is actually unique from stock, but people aren't likely to use it anyway, and it's not worth the trouble with the blank ones.
	//- hl2+cstrike burning_fx.pcf: functionally identical to gmod's except burning_character's initializer Position on Model Random hitbox scale is 1 instead 
	//  of 2. if this makes a difference, it's so subtle i couldn't tell you what it is.
	//- swarm burningplayer.pcf: this is just tf2's burningplayer.pcf with a lot of fx missing, except burningplayer_corpse(glow) emit slightly more particles. 
	//  not worth it.
	//- portal2 cleansers.pcf: this is just portal 1's cleansers.pcf with a lot of fx missing, except for one new effect human_cleanser_cheap, which is just a 
	//  copy of human_cleanser with a few optimization params set that isn't visibly any different.
	//- left4dead2's default.pcf: functionally identical to hl2/tf's, just in a newer pcf format
	//- left4dead2's error.pcf: functionally identical to gmod's, just in a newer pcf format
	//- portal2's finale_fx.pcf: this is portal 1's finale_fx.pcf except finale_gasescape1/finale_gasescape_initial spawn more particles and have a different 
	//  texture. not worth it
	//- portal2's neurotoxins.pcf: this is portal 1's neurotoxins.pcf except neurotoxins_step2 spawns more particles, not worth it
	//- portal2's water_leaks.pcf: this is hl2's water_leaks.pcf except WaterLeak_Pipe_1_TrailDrops_1 is different (and makes parent fx look worse); not worth it
	//Notes:
	//- portal2's environmental_fx.pcf is just a few fx copied from left4dead2's environmental_fx.pcf, and one unique one called case_bubbles; this sucks but having 
	//  a fallback for it is better than having the pcf change drastically depending on what games you have installed
	local _, dirs = file.Find("particles/partctrl_fallbacks/*", "GAME")
	PartCtrl_FallbackPCFs = {}
	for _, str in pairs (dirs) do
		local games = string.Split(str, "+")
		for _, _game in pairs (games) do
			if IsMounted(_game) then
				local files, _ = file.Find("particles/partctrl_fallbacks/" .. str .. "/*", "GAME")
				for _, filename in pairs (files) do
					local f = file.Read("particles/partctrl_fallbacks/" .. str .. "/" .. filename, "GAME")
					if f then
						PartCtrl_FallbackPCFs["particles/" .. filename] = PartCtrl_FallbackPCFs["particles/" .. filename] or {}
						PartCtrl_FallbackPCFs["particles/" .. filename][_game] = {["checksum"] = util.SHA256(f)}
						if str != _game then 
							PartCtrl_FallbackPCFs["particles/" .. filename][_game].path = str
						end
						//Only add fallback pcfs for mounted games to PartCtrl_AllPCFPaths
						table.insert(PartCtrl_AllPCFPaths, "particles/partctrl_fallbacks/" .. str .. "/" .. filename)
					end
				end
			end
		end
	end

	local badendings = {
		["_dx80.pcf"] = true,
		["_dx90_slow.pcf"] = true,
		["_high.pcf"] = true,
	}

	local function PartCtrl_FindAllPCFPaths(dir)
		local files, dirs = file.Find(dir .. "*", "GAME")
		for _, filename in pairs (files) do
			if string.EndsWith(filename, ".pcf") then
				filename = dir .. filename

				//if a file has one of these suffixes, then it's probably a copy of another pcf, loaded based on dxlevel;
				//make sure this is the case by checking if a file without the suffix exists, to avoid false positives.
				local dofile = true
				for ending, _ in pairs (badendings) do
					if string.EndsWith(filename, ending) and file.Exists(string.Replace(filename, ending, ".pcf"), "GAME") then
						dofile = false
						break
					end
				end
				
				if dofile then
					//If the currently mounted instance of this pcf is identical to one of its fallback pcfs, then don't load it, only the 
					//fallback. This prevents the browse tree and searches from getting cluttered up with two identical copies of everything.
					//Making the fallback pcf's file path take priority also helps prevent the creation of bad saves (otherwise, you could make 
					//a save with an effect, then mount a game that overrides that effect's pcf, and then the effect in the save would become 
					//unusable because it's not associated with the fallback pcf's file path)
					if PartCtrl_FallbackPCFs[filename] then
						local f = file.Read(filename, "GAME")
						if f then
							local checksum = util.SHA256(f)
							local skip = false
							for k, v in pairs (PartCtrl_FallbackPCFs[filename]) do
								if checksum == v.checksum then
									if dodebug then MsgN("PartCtrl: ", filename, " identical to fallback from game ", k) end
									skip = true
									//break
								end
								//Check to make sure fallback pcfs are actually identical to the ones from the games; complain if not
								local f2 = file.Read(filename, k)
								if f2 then
									local checksum2 = util.SHA256(f2)
									if checksum2 != v.checksum then
										MsgN("PartCtrl: Fallback pcf for ", filename, " (", k, ") is mismatched (", checksum2, " != ", v.checksum, "); this probably means the fallback file needs to be updated, report this bug!")
									end
								end
							end
							//PartCtrl_FallbackPCFs[filename].mounted = checksum
							if dodebug then MsgN("PartCtrl: ", filename, " skip due to identical fallback pcf = ", skip) end
							if skip then
								table.insert(PartCtrl_SkippedPCFPaths, filename)
								continue
							end
						end
					end
					table.insert(PartCtrl_AllPCFPaths, filename)
				end
			end
		end
		for _, dirname in pairs (dirs) do
			if dirname != "partctrl_fallbacks" then //don't do fallback pcfs here, we handled those selectively earlier
				PartCtrl_FindAllPCFPaths(dir .. dirname .. "/")
			end
		end
	end
	PartCtrl_FindAllPCFPaths("particles/")
	
	PartCtrl_PCFsByParticleName_CurrentlyLoaded = {}
	PartCtrl_CachedReadPCFs = {} //cache these so that dupe detection doesn't have to waste several seconds reading all of them again

	PartCtrl_ProcessedPCFs = {}
	for _, filename in pairs (PartCtrl_AllPCFPaths) do
		PartCtrl_ProcessedPCFs[filename] = PartCtrl_ProcessPCF(filename)
	end


	//Categorize all the pcfs by searching for them in load priority order
	local allpcfs = {}
	for k, _ in pairs (PartCtrl_ProcessedPCFs) do
		allpcfs[k] = true
	end
	allpcfs.UtilFx = nil

	local function AddPCFsToSet(tab, dir, path)
		local files, dirs = file.Find(dir .. "*", path)
		if files then
			local dir_clean = dir
			//Legacy addons will have a file path starting with the addon folder instead of the particle folder, so trim that stuff out
			//(i.e. turn addons/test_onlyparticles/particles/ukmovement.pcf into particles/ukmovement.pcf)
			if !string.StartsWith(dir, "particles") then
				local start, _, _ = string.find(dir, "/particles", 1, true) //this will break if someone names a legacy addon literally just "particles", OH WELL
				if start then
					dir_clean = string.sub(dir, start + 1)
				end
			end
			for _, filename in SortedPairsByValue (files) do
				local fallbacks = PartCtrl_FallbackPCFs[dir_clean .. filename]
				if fallbacks and fallbacks[path] then
					//For a game folder, add the fallback pcf for the file if applicable, instead of the mounted file
					local path2 = fallbacks[path].path or path
					filename = "particles/partctrl_fallbacks/" .. path2 .. "/" .. filename
				else
					filename = dir_clean .. filename
				end
				if allpcfs[filename] then
					table.insert(tab, filename)
					allpcfs[filename] = nil
				end
			end
		end
		if dirs then
			for _, dirname in SortedPairsByValue (dirs) do
				if dirname == "partctrl_fallbacks" then continue end //don't check this folder, instead we add fallback pcfs by checking per game above
				AddPCFsToSet(tab, dir .. dirname .. "/", path)
			end
		end
	end

	local pcfs_sorted = {}
	for i = 1, 7 do
		pcfs_sorted[i] = {}
	end

	//1: packed into bsp
	AddPCFsToSet(pcfs_sorted[1], "particles/", "BSP")

	//2: legacy addons
	local addon_particles = {}
	local _, particle_folders = file.Find("addons/*", "MOD")
	for _, addon in SortedPairs(particle_folders) do
		if !file.IsDir("addons/" .. addon .. "/particles/", "MOD") then continue end
		table.insert(addon_particles, addon)
	end
	for _, addon in SortedPairsByValue(addon_particles) do
		AddPCFsToSet(pcfs_sorted[2], "addons/" .. addon .. "/particles/", "MOD")
	end

	//3: workshop addons
	for _, addon in SortedPairs(engine.GetAddons()) do
		if !addon.downloaded then continue end
		if !addon.mounted then continue end
		if !table.HasValue(select(2, file.Find("*", addon.title)), "particles") then continue end
		AddPCFsToSet(pcfs_sorted[3], "particles/", addon.title)
	end

	//4: garrysmod/particles/ folder
	AddPCFsToSet(pcfs_sorted[4], "particles/", "garrysmod")

	//5: mounted games
	for _, game in SortedPairs(engine.GetGames()) do
		if !game.mounted then continue end
		AddPCFsToSet(pcfs_sorted[5], "particles/", game.folder)
	end

	//6: garrysmod/download/ folder
	AddPCFsToSet(pcfs_sorted[6], "download/particles/", "MOD")

	//7: anything we missed somehow (this shouldn't happen)
	for k, _ in SortedPairs(allpcfs) do
		table.insert(pcfs_sorted[7], k)
	end
	//PrintTable(pcfs_sorted)


	//sort sets into hierarchical order for dupe detection (the more "permanent" something is, the higher priority we should assign to it for dupe 
	//detection; i.e. garrysmod/particles/ are always installed, so its fx should always be considered the "originals" in terms of dupe detection,
	//followed by mounted games, which are above addons because it would be absurd to consider a valve game to be derivative of a gmod addon; bsp 
	//particles and server downloads are at the end because they're transient and should never take priority over other sources)
	local pcfs_dupe_order = {}
	table.Add(pcfs_dupe_order, pcfs_sorted[4]) //garrysmod/particles/ folder
	table.Add(pcfs_dupe_order, pcfs_sorted[5]) //games
	table.Add(pcfs_dupe_order, pcfs_sorted[2]) //legacy addons
	table.Add(pcfs_dupe_order, pcfs_sorted[3]) //workshop addons
	table.Add(pcfs_dupe_order, pcfs_sorted[6]) //garrysmod/download/ folder
	table.Add(pcfs_dupe_order, pcfs_sorted[1]) //packed into bsp
	table.Add(pcfs_dupe_order, pcfs_sorted[7]) //other
	PartCtrl_PCFsInDupeOrder = pcfs_dupe_order //global so that PartCtrl_GetDuplicateFx can be run again later without rebuilding this table
	PartCtrl_GetDuplicateFx()


	//Run AddParticles in another particular order, so things like gmod fx take priority by default;
	//this prevents TF2's blood fx from becoming the default when you shoot an NPC, for instance
	//NOTE: had to put gmod+games above addons to prevent an issue where tf2 map particles addon's 
	//particles/brine_salmann_goop.pcf would unintentionally override the default blood fx, is this bad? 
	//could this cause issues with other addons i'm not aware of that try to override gmod or game fx?
	local pcfs_load_order = {}
	table.Add(pcfs_load_order, pcfs_sorted[1]) //packed into bsp
	table.Add(pcfs_load_order, pcfs_sorted[4]) //garrysmod/particles/ folder
	table.Add(pcfs_load_order, pcfs_sorted[5]) //games
	table.Add(pcfs_load_order, pcfs_sorted[2]) //legacy addons
	table.Add(pcfs_load_order, pcfs_sorted[3]) //workshop addons
	table.Add(pcfs_load_order, pcfs_sorted[6]) //garrysmod/download/ folder
	table.Add(pcfs_load_order, pcfs_sorted[7]) //other
	for _, filename in SortedPairs (pcfs_load_order, true) do
		//MsgN("running AddParticles for ", filename)
		if CLIENT then
			PartCtrl_AddParticles(filename)
		else
			game.AddParticles(filename)
		end
	end


	//add util fx to this table as well, so that particle entities and spawnicons can use them natively
	PartCtrl_ProcessUtilFx()

	PartCtrl_ReadAndProcessPCFs_StartupHasRun = true

	if dodebug then MsgN("PartCtrl: PartCtrl_ReadAndProcessPCFs took " , SysTime() - starttime, " secs") end

end


//Determine which fx are actually identical copies of another effect of the same name.
//This is used to prevent unnecessary AddParticles loading and bad "effect is unloaded, click to load" info in spawnicons (dupes are considered 
//equivalent to the effect they're a copy of), and also to prevent search results from getting clogged up with multiple identical effects.
function PartCtrl_GetDuplicateFx()

	PartCtrl_DuplicateFx = {}
	PartCtrl_PCFsByParticleName = {} //this is global because it's also used to detect particles that are multiply defined and display a warning in the spawnicon

	for _, filename in SortedPairs (PartCtrl_PCFsInDupeOrder) do
		PartCtrl_DuplicateFx[filename] = {}
		//local dodebug = filename == "particles/rain_fx_unused.pcf"
		local dupe_candidates = {}
		for effect, _ in SortedPairs (PartCtrl_ProcessedPCFs[filename]) do
			//local dodebug = effect == "halloween_boss_foot_fire_customcolor"
			if dodebug then MsgN(effect) end
			if dodebug and effect == "ash_eddy_b" then PrintTable(PartCtrl_PCFsByParticleName[effect]) end
			PartCtrl_PCFsByParticleName[effect] = PartCtrl_PCFsByParticleName[effect] or {}
			for _, filename2 in SortedPairs (PartCtrl_PCFsByParticleName[effect]) do
				//Compare the effect to all other fx of the same name (except the ones that we know 
				//are dupes themselves) to determine if this effect is a duplicate of one of them
				if PartCtrl_DuplicateFx[filename2][effect] then
					if dodebug then MsgN(filename .. "/" .. filename2 .. ": ", effect, " this potential candidate is a dupe of ", PartCtrl_DuplicateFx[filename2][effect], ", skipping") end
					continue
				end
				//if dupe_candidates[effect] then break end
				local is_dupe = true
				local function CompareTables(t1, t2, level, table_name_for_debug)
					if !is_dupe then return end
					local operator_tables = {
						["constraints"] = true,
						["emitters"] = true,
						["forces"] = true,
						["initializers"] = true,
						["operators"] = true,
						["renderers"] = true,
					}

					local allkeys = {}
					for k, _ in pairs (t1) do
						allkeys[k] = true
					end
					for k, _ in pairs (t2) do
						allkeys[k] = true
					end
					if level == 1 then
						for _, v in pairs ({
							//these definitely don't matter at all
							"bounding_box_max", 
							"bounding_box_min",
							//less sure about this one; there are plenty of false positives where the change in max_particles doesn't matter at all
							//since it never actually reaches the cap (particles/partctrl_fallbacks/left4dead2/fire_01.pcf's smoke_exhaust_01a/smoke_exhaust_01b), 
							//but a few where it actually does make it visibly different by cutting off particle emission (particles/mvm.pcf's mini_fireworks, 
							//particles/partctrl_fallbacks/left4dead2/fire_01.pcf's smoke_medium_02c). in the cases where it does make a difference, 
							//it's still pretty subtle, so i'm making an executive decision here to treat those as dupes anyway, to err of the side 
							//of not clogging up searches.
							"max_particles",
						}) do
							allkeys[v] = nil
						end
					end

					for k, _ in SortedPairsLower (allkeys) do
						if !is_dupe then return end
						if t1[k] and t2[k] then //if a value exists in one table but not another, then ignore it; newer pcf versions omit keys with default values, but older versions don't
							if istable(t1[k]) and istable(t2[k]) then
								if level == 1 and table.IsSequential(t1[k]) then
									//if a sequential table (list of children or operators) has a mismatched count,
									//then it's different, don't bother comparing them
									if #t1[k] != #t2[k] then
										if dodebug then MsgN(table_name_for_debug, ".", k, ": table count ", #t1[k], " != ", #t2[k]) end
										is_dupe = false
										return
									end
									//special handling for operator/child lists to order their subtables by functionName or child,
									//to catch cases where fx have the same items listed in a different order
									if operator_tables[k] then
										table.SortByMember(t1[k], "functionName", true)
										table.SortByMember(t2[k], "functionName", true)
									elseif k == "children" then
										table.SortByMember(t1[k], "child", true)
										table.SortByMember(t2[k], "child", true)
									end
								end
								local d = table_name_for_debug .. "." .. k
								if t1[k].functionName then
									d = d .. "(" .. t1[k].functionName .. ")"
								elseif t1[k].child then
									d = d .. "(" .. t1[k].child .. ")"
								end
								CompareTables(t1[k], t2[k], level + 1, d)
							else
								//catch cases where values refer to the same file path, but with mismatched slashes
								if isstring(t1[k]) then
									t1[k] = string.Replace(t1[k], "\\", "/")
								end
								if isstring(t2[k]) then
									t2[k] = string.Replace(t2[k], "\\", "/")
								end
								//if values don't match, then it's not a dupe
								if t1[k] != t2[k] then
									if dodebug then MsgN(table_name_for_debug, ".", k, ": ", t1[k], " != ", t2[k]) end
									is_dupe = false
									return
								end
							end
						end
					end
				end
				//note: this needs to use copies of the cached tables, not the originals, otherwise table.SortByMember above will modify the 
				//cached table and cause inconsistent results (i.e. operators with the same functionName no longer being in the same order) 
				//if this function is run multiple times in a session
				CompareTables(table.Copy(PartCtrl_CachedReadPCFs[filename][effect]), table.Copy(PartCtrl_CachedReadPCFs[filename2][effect]), 1, filename .. "/" .. filename2 .. ": " .. effect)
				if is_dupe then
					dupe_candidates[effect] = dupe_candidates[effect] or {}
					table.insert(dupe_candidates[effect], filename2)
					if dodebug then MsgN(filename .. "/" .. filename2 .. ": ", effect, " dupe candidate found") end
					//break
				end
			end
			table.insert(PartCtrl_PCFsByParticleName[effect], filename)
		end
		//Double check to make sure all the children of an effect are dupes as well
		if dodebug then PrintTable(dupe_candidates) end
		for effect, v in pairs (dupe_candidates) do
			children_all_dupes = true
			local function CheckIfChildrenAreDupes(effect2)
				if !children_all_dupes then return end
				--[[for _, tab in pairs (PartCtrl_ProcessedPCFs[filename][effect2].children) do
					if dupe_candidates[tab.child] != v then
						children_all_dupes = false
						if dodebug then MsgN(filename .. "/" .. v .. ": " .. effect .. ": child " .. tab.child .. " isn't a dupe of " .. v) end
						return
					else
						CheckIfChildrenAreDupes(tab.child)
					end
				end]]
				//local dodebug = effect == "fire_large_01"
				//Q: What's all this complicated nonsense for?
				//
				//A: This is for complex cases like particles/fire_01_unused.pcf's fire_large_01. This effect has multiple children:
				//
				//   Some, like smoke_large_01, are dupes of particles/partctrl_fallbacks/left4dead2/fire_01.pcf, but are DIFFERENT from
				//   the effect of the same name in particles/fire_01.pcf.
				//
				//   Others, like embers_large_01, are dupes of particles/fire_01.pcf, and the effect of the same name in the left4dead2 pcf
				//   is ALSO a dupe of fire_01.pcf, but embers_large_01 doesn't catch it as a dupe candidate, because the compare code doesn't
				//   compare it with effects we've already confirmed to be dupes - that would be redundant.
				//
				//   fire_large_01 itself has no differences on its own, and returns as a dupe of both fire_01.pcf and the left4dead2 pcf.
				//
				//   In this case, we want fire_large_01 to return as a dupe of the left4dead2 pcf, but not fire_01.pcf, because smoke_large_01
				//   is different. This requires us to keep a whole list of potential dupe candidates instead of just the first we find, and
				//   then also associate the child embers_large_01 with the left4dead2 pcf, despite that pcf not being in the child's list of
				//   dupe candidates.
				for _, tab in pairs (PartCtrl_ProcessedPCFs[filename][effect2].children) do
					if !dupe_candidates[tab.child] then
						if dodebug then MsgN(filename, ": ", effect, ": child ", tab.child, " has no dupe candidates, discarding") end
						children_all_dupes = false
						return
					else
						for k, v in pairs (dupe_candidates[effect]) do
							if !table.HasValue(dupe_candidates[tab.child], v) then
								local dupecheck = false
								//for k2, v2 in pairs (dupe_candidates[tab.child]) do
								//if tab.child == "embers_large_01" then PrintTable(PartCtrl_PCFsByParticleName[tab.child]) end
								--[[for k2, v2 in pairs (PartCtrl_PCFsByParticleName[tab.child]) do
									if dodebug and tab.child == "embers_large_01" then
										MsgN("DUPECHECK: v = ", v, ", PartCtrl_DuplicateFx = ", PartCtrl_DuplicateFx[v][tab.child], ", v2 = ", v2)
									end
									//if PartCtrl_DuplicateFx[v2][tab.child] == v then
										//if dodebug then MsgN(filename, ": ", effect, ": child ", tab.child, " dupecheck found ", v, ", should remain in candidates") end
									if PartCtrl_DuplicateFx[v][tab.child] == v2 then //this seems like nonsense but it works, argh
										if dodebug then MsgN(filename, ": ", effect, ": child ", tab.child, " dupecheck found that ", v, " is a dupe of ", v2, ", so the former should remain in candidates") end
										dupecheck = true
										break
									end
								end]]
								//and !(PartCtrl_ProcessedPCFs[v][tab.child] and !table.HasValue(dupe_candidates[tab.child], PartCtrl_DuplicateFx[v][tab.child])) then
								if dodebug --[[and tab.child == "embers_large_01"]] then PrintTable(dupe_candidates[tab.child]) end
								for k2, v2 in pairs (dupe_candidates[tab.child]) do
									if dodebug --[[and tab.child == "embers_large_01"]] then
										MsgN("DUPECHECK: v = ", v, ", PartCtrl_DuplicateFx = ", PartCtrl_DuplicateFx[v][tab.child], ", v2 = ", v2)
									end
									if PartCtrl_DuplicateFx[v][tab.child] == v2 then //this seems like nonsense but it works, argh
										if dodebug then MsgN(filename, ": ", effect, ": child ", tab.child, " dupecheck found that ", v, " is a dupe of ", v2, ", so the former should remain in candidates") end
										dupecheck = true
										break
									end
								end

								if !dupecheck then
									if dodebug then MsgN(filename, ": ", effect, ": child ", tab.child, " does not have dupe candidate ", v, ", removing from candidates") end
									table.RemoveByValue(dupe_candidates[effect], v)
								end
							end
						end
						if #dupe_candidates[effect] == 0 then
							if dodebug then MsgN(filename, ": ", effect, ": child ", tab.child, " has no dupe candidates left, discarding") end
							children_all_dupes = false
							return
						else
							CheckIfChildrenAreDupes(tab.child)
						end
					end
				end
			end

			CheckIfChildrenAreDupes(effect)
			if children_all_dupes then
				//PartCtrl_DuplicateFx[filename][effect] = v
				//if dodebug then MsgN(filename .. "/" .. v .. ": " .. effect .. ": dupe found!") end
				PartCtrl_DuplicateFx[filename][effect] = dupe_candidates[effect][1]
				if dodebug then MsgN(filename .. "/" .. dupe_candidates[effect][1] .. ": " .. effect .. ": dupe found!") end
			end
		end
	end

	//Build PartCtrl_PCFsWithConflicts for spawnicon conflicting pcf lists: if every single conflicting effect in
	//a pcf is culled or a duplicate, then there's no chance of the player reloading it, so don't bother listing it
	if CLIENT then
		PartCtrl_PCFsWithConflicts = {}
		for _, pcf in pairs (PartCtrl_PCFsInDupeOrder) do
			for name, _ in pairs (PartCtrl_ProcessedPCFs[pcf]) do
				if !PartCtrl_DuplicateFx[pcf] then MsgN(pcf, " bad") end
				if !PartCtrl_PCFsByParticleName[name] then MsgN(pcf, " bad") end
				if !PartCtrl_DuplicateFx[pcf][name] and #PartCtrl_PCFsByParticleName[name] > 1 then
					PartCtrl_PCFsWithConflicts[pcf] = true 
					break
				end
			end
		end
	end

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

	local cv_childfx_spawnlist = GetConVar("cl_partctrl_childfx_in_autospawnlists")

	local function OnParticleNodeSelected(pcf, ViewPanel, pnlContent)

		ViewPanel:Clear(true)

		if !istable(PartCtrl_ProcessedPCFs[pcf]) then
			MsgN("OnParticleNodeSelected tried to make spawnlist for invalid pcf ", pcf)
		else
			local dochildfx = cv_childfx_spawnlist:GetInt()
			if dochildfx == 0 then
				//No child fx
				for particle, _ in SortedPairsLower (PartCtrl_ProcessedPCFs[pcf]) do //sort them in alphabetical order
					if !PartCtrl_ProcessedPCFs[pcf][particle].parents or table.Count(PartCtrl_ProcessedPCFs[pcf][particle].parents) < 1 then
						spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["spawnname"] = pcf, ["nicename"] = particle})
					end
				end
			elseif dochildfx == 1 then
				local tab = {}
				//Separate child fx
				for particle, _ in SortedPairsLower (PartCtrl_ProcessedPCFs[pcf]) do //sort them in alphabetical order
					if !PartCtrl_ProcessedPCFs[pcf][particle].parents or table.Count(PartCtrl_ProcessedPCFs[pcf][particle].parents) < 1 then
						spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["spawnname"] = pcf, ["nicename"] = particle})
					else
						table.insert(tab, particle)
					end
				end
				if table.Count(tab) > 0 then
					spawnmenu.CreateContentIcon("header", ViewPanel, {["text"] = "Child effects"})
					for k, particle in pairs (tab) do
						spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["spawnname"] = pcf, ["nicename"] = particle})
					end
				end
			else
				//All fx sorted alphabetically
				for particle, _ in SortedPairsLower (PartCtrl_ProcessedPCFs[pcf]) do //sort them in alphabetical order
					spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["spawnname"] = pcf, ["nicename"] = particle})
				end
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
			for particle, _ in SortedPairsLower (PartCtrl_UtilFxByTitle[name]) do //sort them in alphabetical order
				spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["spawnname"] = "UtilFx", ["nicename"] = particle})
			end
		end

		pnlContent:SwitchPanel(ViewPanel)
		ViewPanel.CurrentPCF = "UtilFx" //used by developer click-to-refresh-pcf function
		ViewPanel.CurrentUtilFxName = name //^

	end

	function PartCtrl_CreateCustomSpawnlist(tab, name, icon) //globally available so we can use it to make arbitrary spawnlists for testing

		local tab2 = {}

		local dochildfx = cv_childfx_spawnlist:GetInt()
		if dochildfx == 0 then
			//No child fx
			for k, v in pairs (tab) do
				if !PartCtrl_ProcessedPCFs[v.pcf][v.particle].parents or table.Count(PartCtrl_ProcessedPCFs[v.pcf][v.particle].parents) < 1 then
					table.insert(tab2, {["type"] = "partctrl", ["spawnname"] = v.pcf, ["nicename"] = v.particle})
				end
			end
		elseif dochildfx == 1 then
			//Separate child fx
			local tab3 = {}
			for k, v in pairs (tab) do
				if !PartCtrl_ProcessedPCFs[v.pcf][v.particle].parents or table.Count(PartCtrl_ProcessedPCFs[v.pcf][v.particle].parents) < 1 then
					table.insert(tab2, {["type"] = "partctrl", ["spawnname"] = v.pcf, ["nicename"] = v.particle})
				else
					table.insert(tab3, {["type"] = "partctrl", ["spawnname"] = v.pcf, ["nicename"] = v.particle})
				end
			end
			if table.Count(tab3) > 0 then
				table.insert(tab2, {["type"] = "header", ["text"] = "Child effects"})
				table.Add(tab2, tab3)
			end
		else
			//All fx sorted alphabetically
			for k, v in pairs (tab) do
				tab2[k] = {["type"] = "partctrl", ["spawnname"] = v.pcf, ["nicename"] = v.particle}
			end
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

		particles.FilePopulateCallback = function(self, files, folders, foldername, path, bAndChildren, wildcard) //based on DTree_Node.FilePopulateCallback (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dtree_node.lua#L448)
			local showfiles = self:GetShowFiles()

			self.ChildNodes:InvalidateLayout(true)
		
			local FileCount = 0
		
			if folders then
				for k, File in SortedPairsByValue (folders) do
					if File == "partctrl_fallbacks" then continue end //don't show this folder, instead we add fallback pcfs to the appropriate game folders below
		
					local Node = self:AddNode(File)
					Node:MakeFolder(string.Trim( foldername .. "/" .. File, "/" ), path, showfiles, wildcard, true)
					Node.FilePopulateCallback = particles.FilePopulateCallback
					FileCount = FileCount + 1
				end
			end
		
			if showfiles then
				//Create unique node for utilfx
				if !particles.utilfxnode and PartCtrl_UtilFxByTitle[name] then
					//MsgN("making utilfx node for ", name)
					particles.utilfxnode = particles:AddNode("Scripted Effects", "icon16/page_gear.png")
					particles.utilfxnode.utilfx = true
					FileCount = FileCount + 1
					particles.utilfxnode.DoRightClick = function()
						if !IsValid(particles.utilfxnode) then return end
						local menu = DermaMenu()

						menu:AddOption("#spawnmenu.createautospawnlist", function()
							local tab = {}
							for particle, _ in SortedPairsLower (PartCtrl_UtilFxByTitle[name]) do //sort them in alphabetical order
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

				//Legacy addons will have a file path starting with the addon folder instead of the particle folder, so trim that stuff out
				//(i.e. turn addons/test_onlyparticles/particles/ukmovement.pcf into particles/ukmovement.pcf)
				if !string.StartsWith(foldername, "particles") then
					local start, _, _ = string.find(foldername, "/particles", 1, true) //this will break if someone names a legacy addon literally just "particles", OH WELL
					if start == nil then
						//if we got a nonsense folder somehow, then back out now
						showfiles = false
						self:SetShowFiles(nil)
					else
						foldername = string.sub(foldername, start + 1)
					end
				end

				if showfiles then
					local function AddFile(name, filename)
						//Clear out .txt file particle manifests and such, also clear out bad .pcf files that weren't processed
						if !istable(PartCtrl_ProcessedPCFs[filename]) then return end

						local Node = self:AddNode(name, "icon16/page.png")
						Node:SetFileName(filename)
						FileCount = FileCount + 1
						Node.DoRightClick = function()
							if !IsValid(Node) then return end
							local menu = DermaMenu()

							menu:AddOption("Copy .pcf file path to clipboard", function() SetClipboardText(filename) end):SetIcon("icon16/page_copy.png")

							menu:AddOption("#spawnmenu.createautospawnlist", function()
								local tab = {}
								for particle, _ in SortedPairsLower (PartCtrl_ProcessedPCFs[filename]) do //sort them in alphabetical order
									table.insert(tab, {["pcf"] = filename, ["particle"] = particle})
								end
								PartCtrl_CreateCustomSpawnlist(tab, name)
							end):SetIcon("icon16/page_add.png")

							//developer control to reload a .pcf file manually
							if GetConVarNumber("developer") >= 1 then
								menu:AddOption("Reload .pcf file", function()
									net.Start("PartCtrl_ReloadPCF_SendToSv")
										net.WriteString(filename)
									net.SendToServer()
								end)
							end

							menu:Open()
						end
					end
			
					for k, File in SortedPairs (files) do
						local fallbacks = PartCtrl_FallbackPCFs[foldername .. "/" .. File]
						if fallbacks and fallbacks[path] then
							//For a game folder, add the fallback pcf for the file if applicable, instead of the mounted file
							local path2 = fallbacks[path].path or path
							AddFile(File .. " (" .. path2 .. ")", "particles/partctrl_fallbacks/" .. path2 .. "/" .. File)
							continue
						end

						AddFile(File, string.Trim(foldername .. "/" .. File, "/"))

						if fallbacks and path == "GAME" then
							//For the "All" folder, add every fallback pcf for this file, in addition to the mounted file
							local fallbacks_to_add = {}
							for Game, tab in pairs (fallbacks) do
								local path2 = tab.path or Game
								//add these to a table first, to make sure we don't add duplicate nodes for fallbacks that apply to more than 1 game
								fallbacks_to_add[File .. " (" .. path2 .. ")"] = "particles/partctrl_fallbacks/" .. path2 .. "/" .. File
							end
							for k, v in pairs (fallbacks_to_add) do
								AddFile(k, v)
							end
						end
					end
				end
			end
		
			if FileCount == 0 then
				if name != "#spawnmenu.category.downloads" then
					//clear out folders that generate empty - checking fi/fo up above doesn't work because some games (ep1) have empty tables even though they have files(??)
					//this looks kind of bad because you can see the folders appear and then disappear, but i don't know what a better solution would be
					self:Remove()
				else
					//default empty folder behavior
					self.ChildNodes:Remove()
					self.ChildNodes = nil
			
					self:SetNeedsPopulating(false)
					self:SetShowFiles(nil)
					self:SetWildCard(nil)
			
					self:InvalidateLayout()
			
					self.Expander:SetExpanded(true)
		
					return
				end
			end
		
			self:InvalidateLayout()
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

		if GetConVarNumber("developer") >= 1 then MsgN("PartCtrl: running PopulateContent") end

	end) end)

	local cv_childfx_search = GetConVar("cl_partctrl_childfx_in_search")
	local cv_dupes_search = GetConVar("cl_partctrl_dupes_in_search")

	search.AddProvider(function(str)

		local searchTerms = string.Explode(" ", str)

		if searchParticles == nil then
			searchParticles = {}
			for pcf, _ in SortedPairs (PartCtrl_ProcessedPCFs) do
				for particle, _ in SortedPairsLower (PartCtrl_ProcessedPCFs[pcf]) do
					table.insert(searchParticles, {["name"] = particle, ["name_lower"] = particle:lower(), ["pcf"] = pcf}) //lowercase needs to be separate, because effect names are case-sensitive when spawning them
				end
			end
		end

		local results = {}

		for k, v in ipairs (searchParticles) do
			if (cv_childfx_search:GetBool() or !PartCtrl_ProcessedPCFs[v.pcf][v.name].parents or table.Count(PartCtrl_ProcessedPCFs[v.pcf][v.name].parents) < 1) 
			and (cv_dupes_search:GetBool() or !PartCtrl_DuplicateFx[v.pcf][v.name]) then
				for k2, v2 in ipairs (searchTerms) do
					if !(v.name_lower:find(v2, nil, true) or v.pcf:find(v2, nil, true)) then
						break
					elseif k2 == #searchTerms then
						local entry = {
							text = v.name,
							icon = spawnmenu.CreateContentIcon("partctrl", g_SpawnMenu.SearchPropPanel, {["spawnname"] = v.pcf, ["nicename"] = v.name}),
							words = {v.name}
						}
						table.insert(results, entry)
						//entry.icon.IsInSearch = true //used by spawnicon code; TODO: stops working when the search is refreshed by the model search
						//MsgN("according to addprovider, g_SpawnMenu.SearchPropPanel is ", g_SpawnMenu.SearchPropPanel, " and icon is ", entry.icon)
					end
				end
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

		if str != "UtilFx" then
			//Handle duplicate fx detection again; it's possible that an effect was updated to start/stop being a dupe, OR that an 
			//effect being updated made an effect from a lower-priority PCF start/stop being considered a dupe of this pcf's effect
			PartCtrl_GetDuplicateFx()

			//Make sure the reloaded pcf is highest priority
			//(try to prevent oddness with PartCtrl_PCFsByParticleName_CurrentlyLoaded on fx that change dupe status)
			PartCtrl_AddParticles(str)
		end

		//Refresh spawnicons (this is handled by the think hook in contenticon_partctrl.lua)
		//Do this for all spawnicons, not just the ones for the pcf we updated (i.e. in case 
		//updating one of this pcf's fx made a lower priority pcf's effect no longer a dupe of it)
		if PartCtrl_IconFx then
			for pcf, _ in pairs (PartCtrl_IconFx) do
				for name, _ in pairs (PartCtrl_IconFx[pcf]) do
					PartCtrl_IconFx[pcf][name].reset = true
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

		if str != "UtilFx" then
			//Handle duplicate fx detection again; it's possible that an effect was updated to start/stop being a dupe, OR that an 
			//effect being updated made an effect from a lower-priority PCF start/stop being considered a dupe of this pcf's effect
			PartCtrl_GetDuplicateFx()

			//Make sure the reloaded effect is highest priority
			//(not sure if this matters serverside, but better safe than sorry)
			game.AddParticles(str)
		end

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

	if GetConVarNumber("developer") >= 1 then MsgN("PartCtrl: running GameContentChanged") end

end)

if CLIENT then

	//Wrapper for game.AddParticles - this way, a lot of spawnicons or particle entities created at once can all try to run game.AddParticles at the same time,
	//but won't unnecessarily run it more than once for the same .pcf file at one time.
	//Works on a "queuing" system where each spawnicon/ent adds the relevant pcfs to a table, and then a Think hook loops through this table cleaning up 
	//all pre-existing fx that could cause crashes, then after a short delay, runs game.AddParticles for each pcf in the table.
		
	local AddParticles_Queued = {}
	local AddParticles_QueuedTime = nil
	PartCtrl_AddParticles_CrashCheck = {}
	PartCtrl_AddParticles_CrashCheck_ThrottledPCFs = {}
	PartCtrl_AddParticles_AddedParticles = PartCtrl_AddParticles_AddedParticles or {}
	PartCtrl_AddParticles_AddedParticles_Overrides = PartCtrl_AddParticles_AddedParticles_Overrides or {}

	function PartCtrl_AddParticles(pcf, effectname) //optional effectname arg for spawnicons and particle entities, which usually only care about conflicts with their one effect

		if !istable(PartCtrl_ProcessedPCFs[pcf]) then return end
		if effectname and !istable(PartCtrl_ProcessedPCFs[pcf][effectname]) then return end

		local doaddparticles = false
		local key2 = table.KeyFromValue(AddParticles_Queued, pcf)
		if key2 then
			if key2 == #AddParticles_Queued then
				//this pcf is already queued and already the most recent entry to the list, no need to do more
				return
			else
				doaddparticles = true
				table.remove(AddParticles_Queued, key2)
			end
		end

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
				for _, v in pairs (PartCtrl_PCFsByParticleName[name]) do
					tab[v] = true
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
				if !(PartCtrl_PCFsByParticleName_CurrentlyLoaded[effectname] == pcf)
				and !(PartCtrl_DuplicateFx[pcf][effectname] and PartCtrl_PCFsByParticleName_CurrentlyLoaded[effectname] == PartCtrl_DuplicateFx[pcf][effectname]) then
					for _, v in pairs (PartCtrl_PCFsByParticleName[effectname]) do
						tab[v] = true
					end
					tab[pcf] = nil
					//MsgN("tab for effect ", effectname, ":")
					//PrintTable(tab)
				end
			else
				tab = PartCtrl_AddParticles_AddedParticles_Overrides[pcf]
			end
			if table.Count(tab) > 0 then
				for k, v in SortedPairs (PartCtrl_AddParticles_AddedParticles) do
					if k > key and tab[v] then
						//MsgN(k .. " " .. v .. " is greater than " .. key .. " " .. pcf .. ", time to do AddParticles")
						doaddparticles = true
						break
					end
				end
			end
		end

		if doaddparticles then
			//Queue this pcf to be game.AddParticles'd - this is handled in the think hook below.
			//This queuing system lets every effect in a spawnlist run this function at once and queue every applicable
			//pcf, without any of those pcfs getting game.AddParticles'd multiple times at once and causing a stutter.
			if key2 then
				table.remove(AddParticles_Queued, key2) //make sure the most recently called pcf takes precedence (i.e. if swapping between multiple pcf spawnlists with conflicting fx, make sure the one we clicked on last has the right fx when we call game.AddParticles)
			end
			table.insert(AddParticles_Queued, pcf)
			//Crash prevention: throttle effects from the queued pcf, and all pcfs it conflicts with
			PartCtrl_AddParticles_CrashCheck_ThrottledPCFs[pcf] = true
			table.Merge(PartCtrl_AddParticles_CrashCheck_ThrottledPCFs, PartCtrl_AddParticles_AddedParticles_Overrides[pcf])

			//Also move the pcf to the end of the AddedParticles list
			if key then
				table.remove(PartCtrl_AddParticles_AddedParticles, key)
			end
			table.insert(PartCtrl_AddParticles_AddedParticles, pcf)

			for effectname, _ in pairs (PartCtrl_ProcessedPCFs[pcf]) do
				if PartCtrl_DuplicateFx[pcf][effectname] then
					PartCtrl_PCFsByParticleName_CurrentlyLoaded[effectname] = PartCtrl_DuplicateFx[pcf][effectname]
				else
					PartCtrl_PCFsByParticleName_CurrentlyLoaded[effectname] = pcf
				end
			end

			AddParticles_QueuedTime = CurTime()
		end

	end

	hook.Add("Think", "PartCtrl_AddParticles_Think", function()

		if #AddParticles_Queued > 0 then
			local time = CurTime()
			local delay = nil

			if !PartCtrl_DoneFirstPrecache then
				//MsgN("skipping")
				//if we're loading pcfs on startup, then don't waste time searching for old fx to clean up
				delay = 0
			else
				//MsgN("not skipping")
				delay = 0.1
				//Crash prevention:
				//Internally, when gmod loads a new pcf from game.AddParticles, and that pcf overrides any effect names, any existing particlesystems using those effects are forcibly stopped. If too 
				//many unique effects are stopped at once by the engine this way, it can crash. If our panel/entity code recreates them too soon after the engine stops them, it can also crash. 
				//Finally, if there are too many existing particlesystems that simply share a pcf with one being overridden, then it can also crash (why? the engine doesn't even remove these ones!).
				//To get around all this, we first remove all the offending particlesystems ourselves, then call game.AddParticles a frame later, after we can be sure they're all gone.
				for v, _ in pairs (PartCtrl_AddParticles_CrashCheck_ThrottledPCFs) do
					if istable(PartCtrl_AddParticles_CrashCheck[v]) then
						for k2, v2 in pairs (PartCtrl_AddParticles_CrashCheck[v]) do
							if k2 and k2:IsValid() then
								//MsgN(time, " ", k2, " removed")
								AddParticles_QueuedTime = time
								k2:StopEmissionAndDestroyImmediately()
								//surface.PlaySound("vo/ravenholm/monk_danger01.wav")
							else
								//Don't remove fx from the list until we're absolutely sure they're gone; some of them can
								//be really stubborn, try swapping between spawnlists for blood_impact.pcf and its tf2 fallback
								PartCtrl_AddParticles_CrashCheck[v][k2] = nil
							end
						end
					end
				end
			end

			if AddParticles_QueuedTime != nil and time > (AddParticles_QueuedTime + delay) then
				for _, pcf in ipairs (AddParticles_Queued) do
					//surface.PlaySound("vo/ravenholm/engage03.wav")
					//MsgN("running game.AddParticles for ", pcf)
					game.AddParticles(pcf)
				end
				AddParticles_Queued = {}
				AddParticles_QueuedTime = nil
				PartCtrl_AddParticles_CrashCheck_ThrottledPCFs = {}
				//Stupid fix: the first time PrecacheParticleSystem is run by anything, it will cause a substantial stutter, 
				//so get it over with during map load instead of disrupting gameplay the first time the player opens a spawnlist or something.
				if !PartCtrl_DoneFirstPrecache then
					PrecacheParticleSystem("")
					PartCtrl_DoneFirstPrecache = true
				end
			end
		end

	end)

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

	partctrlwindows = {}

	function OpenPartCtrlEditor(ent)

		if IsValid(ent.PartCtrlWindow) then return end

		local width = 367 //width of 367 nicely fits color picker
		if ent.PartCtrl_SpecialEffect then
			width = 718 //special fx controls have two columns; this width is precisely calibrated so that both columns have the exact same width as on normal fx
		end

		local window = g_ContextMenu:Add("DFrame")
		window:SetSize(width, 400) 
		window:Center()
		window:SetSizable(true)
		//window:SetMinHeight(h_min)
		//window:SetMinWidth(w_min)

		//When opening multiple edit windows, move the default position slightly for each window open so they don't get completely hidden by each other until the player moves them
		local x, y = window:GetPos()
		local xmax, ymax = g_ContextMenu:GetSize()
		window:SetPos(math.min(x + (#partctrlwindows * 25), xmax - 25), math.min(y + (#partctrlwindows * 25), ymax - 25))

		local control = window:Add("PartCtrlEditor")
		window.Control = control
		control:SetEntity(ent)
		control:Dock(FILL)

		table.insert(partctrlwindows, window)

		control.OnEntityLost = function()
			window:Remove()
		end

		window.OnRemove = function()
			table.remove(partctrlwindows, table.KeyFromValue(partctrlwindows, window))
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
			if !(IsValid(k) and ((k.PartCtrl_Ent and k.GetPCF) or k.PartCtrl_SpecialEffect)) then
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
			local str = k.PrintName
			if k.GetParticleName then str = k:GetParticleName() end
			option:SetText("Edit Particle Effect (" .. str .. ")")
			option.DoClick = function() OpenPartCtrlEditor(k) end
		end

	else
		
		local submenu = option:AddSubMenu()
		for k, _ in pairs (ent.PartCtrl_ParticleEnts) do
			if IsValid(k) and ((k.PartCtrl_Ent and k.GetPCF) or k.PartCtrl_SpecialEffect) then
				local str = k.PrintName
				if k.GetParticleName then str = k:GetParticleName() end
				local opt = submenu:AddOption(str)
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
				if k.PartCtrl_SpecialEffect then MsgN("Can't get raw pcf data for special effect " .. k.PrintName) return end
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
				if k.PartCtrl_SpecialEffect then MsgN("Can't get processed pcf data for special effect " .. k.PrintName) return end
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
				if k.PartCtrl_SpecialEffect then MsgN("Can't get ParticleInfo data for special effect " .. k.PrintName) return end
				MsgN(k, ".ParticleInfo (",  k:GetPCF(), "/", k:GetParticleName(), "): ")
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

if GetConVarNumber("developer") >= 1 then MsgN("PartCtrl: running autorun") end