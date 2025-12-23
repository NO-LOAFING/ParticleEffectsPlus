AddCSLuaFile()


//Blacklist bad .pcf files and effects from being loaded by the addon

//The actual .pcf loading is done inside of ent_partctrl.lua, because entity code always runs after autorun code -
//we want to be sure every addon that wants to add to the blacklist has the chance to do so before the .pcf files actually get read.

local tf2_unusual_wep_pcfs = {
	["particles/weapon_unusual_cool.pcf"] = true,
	["particles/weapon_unusual_energyorb.pcf"] = true,
	["particles/weapon_unusual_hot.pcf"] = true,
	["particles/weapon_unusual_isotope.pcf"] = true
}
local tf2_unusual_wep_blacklist_text = "Blacklisted: _unusual_parent_ fx are all conflicting duplicates of other unusual weapon fx"
--[[local default_blacklist = {
	//TF2 map particles addon
	["particles/nucleus_event_effects.pcf"] = {
		blacklist = {
			nucleus_core_steady = "Blacklisted: duplicate of nucleus_event_core_steady, except it conflicts with a stock tf2 effect" //note: only reason this doesn't override the desired effect on koth_nucleus is because the game arbitrarily reads particles/level_fx.pcf after this one, which sucks; this isn't an issue on pd_circus because it doesn't actually use this effect
		}
	},
	["particles/brine_salmann_goop.pcf"] = {
		blacklist = {
			blood_impact_green_01 = "Blacklisted: override that's actually a copy of tf2's blood_impact_red_01, for salmann skeleton reskins"
		},
	},
}]]
hook.Add("PartCtrl_PostProcessPCF", "default_blacklist", function(filename, tab)
	//These are useless and clog up searches for any TF2 weapon, get rid of them
	if tf2_unusual_wep_pcfs[filename] then
		for k, v in pairs (tab) do
			if string.StartsWith(k, "_unusual_parent_") then
				PartCtrl_AddCullReason(filename, k, tf2_unusual_wep_blacklist_text)
			end
		end
	end
	//i dont think any of this is necessary now that the way duplicate fx are handled is no longer awful
	--[[if default_blacklist[filename] then
		for k, v in pairs (tab) do
			//if blacklist is present, blacklist all listed fx
			if default_blacklist[filename].blacklist and default_blacklist[filename].blacklist[k] then
				PartCtrl_AddCullReason(filename, k, default_blacklist[filename].blacklist[k])
			end
			//if whitelist is present, blacklist all fx in the pcf *except* the ones listed
			if default_blacklist[filename].whitelist and !default_blacklist[filename].whitelist[k] then
				PartCtrl_AddCullReason(filename, k, default_blacklist[filename].whitelist_fail)
			end
		end
	end]]
end)




//Default comments for unintuitive fx; we should really be autodetecting these things

local stove_comment = "Control point 1 pushes the flame away; it's very subtle"
local tooclose_comment = "Not visible if too close to the camera"
local default_comments = {
	//Default
	["particles/fire_01.pcf"] = {
		burning_vehicle = tooclose_comment //also it doesn't render if hl2 isn't mounted, because that's where the vmt is, but that doesn't seem reasonable to check for
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
		stamp_spin = "Only creates particles while moving"
	},
	//Portal
	["particles/neurotoxins.pcf"] = {
		neurotoxins_step1 = tooclose_comment,
	},
	["particles/portals.pcf"] = {
		portal_1_vacuum = tooclose_comment,
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
hook.Add("PartCtrl_PostProcessPCF", "default_comments", function(filename, tab)
	if default_comments[filename] then
		for k, v in pairs (tab) do
			if default_comments[filename][k] then
				PartCtrl_AddInfoText(tab[k], default_comments[filename][k])
			end
		end
	end
end)