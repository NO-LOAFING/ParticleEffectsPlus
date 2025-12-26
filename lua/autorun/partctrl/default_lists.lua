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
	//i dont think any of this is necessary now that we handle duplicate fx better
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

local default_comments = {
	//Team Fortress 2
	["particles/coin_spin.pcf"] = {
		coin_spin = "Only creates particles while moving"
	},
	["particles/stamp_spin.pcf"] = {
		stamp_spin = "Only creates particles while moving"
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