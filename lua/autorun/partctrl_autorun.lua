CreateConVar("sv_peplus_particlesperent", 32, FCVAR_REPLICATED, "Max number of effect instances (or projectiles) that a single particle effect entity can have active at once.", 1)
//Assume that most servers won't want serverside projectile fx or screenspace fx because they're too easy to grief with.
//Update 1/1/25: before this date, we also disabled ReadPCF caching in MP because we can't assume each connecting client 
//will load this addon more than once, but recent optimizations made the extra load time marginal, so leave it enabled.
//Is this right? No idea, I don't run a server.
local int_sp
if game.SinglePlayer() then
	int_sp = 1
else
	int_sp = 0
end
CreateConVar("sv_peplus_allowserverprojectiles", int_sp, FCVAR_REPLICATED, "If 0, disables the serverside projectiles option on projectile effects.", 0, 1)
CreateConVar("sv_peplus_cachereadpcf", 1, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "If 1, the results of PEPlus_ReadPCF are cached to the data folder (approx. 15-30MB), to make subsequent reads much faster.\nIn singleplayer, this is always faster, even on the first load, because the addon has to read PCF files twice on startup (once serverside, once clientside).\nIn multiplayer, however, clients only have to read PCF files once, and if a player only ever loads into a server with this addon one time, they'll spend 5-10 extra secs caching files for no benefit.", 0, 1)
CreateConVar("sv_peplus_blacklist_screenspace", 1-int_sp, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "If 1, effects with the var \"screen space effect\" are blacklisted from being loaded.\nNote: Changing this value will reload *all* PCF files, temporarily freezing the game for all clients. Be careful!", 0, 1)
if SERVER then
	cvars.AddChangeCallback("sv_peplus_blacklist_screenspace", function(cvname, old, new)
		if old != new then
			PEPlus_ReloadPCF("all")
		end
	end, "PEPlus_ReloadPCFsOnChange")
end

if CLIENT then
	//Some convars to separate child fx from others; in practice, this doesn't work well because there are 
	//A: lots of normal fx that are also used as children, and would be excluded (i.e. eye_powerup_green_lvl_3, rocket_explosion_classic, rocket_trail_classic_crit_red, many more) 
	//and B: lots of unused child fx that were removed from their parents, and so end up cluttering up the parent fx lists anyway (too many to list), 
	//so these features are disabled by default.
	CreateClientConVar("cl_peplus_childfx_in_autospawnlists", 2, false, false, "Sets how child particle effects appear in auto-generated .pcf spawnlists.\n0: Child effects are hidden\n1: Child effects are sorted into a separate category\n2: Child effects are listed alongside parent effects", 0, 2)
	CreateClientConVar("cl_peplus_childfx_in_search", 1, false, false, "If 0, prevents child particle effects from being shown in search results.", 0, 1)

	CreateClientConVar("cl_peplus_dupes_in_search", 0, false, false, "If 0, prevents duplicate effects from being shown in search results.", 0, 1)
	CreateClientConVar("cl_peplus_debug_spawnicons", 0, false, false, "If 1, show renderbounds used to calculate spawnicon camera position.\nred = particle bounds\ngreen = particle2 bounds (compensation for vector/axis controls and \"set control point to player\")\nblue = particle3 bounds (compensation for \"set control point positions\")\nwhite = final spawnicon bounds", 0, 1)
	CreateClientConVar("cl_peplus_distancescalar_helpers", 0, false, false, "If 1, display helpers (radius spheres) for control points used by operators like \"remap distance to control point to scalar\".", 0, 1)
end




//Blacklist bad effects from being loaded, and add info text for unintuitive ones; this was a lot more extensive in development, but 
//shrunk down considerably as we figured out how to handle conflicting fx better and auto-detect more things that need info text.

//The actual .pcf loading is done inside of ent_peplus.lua, because entity code always runs after autorun code -
//we want to be sure every addon that wants to add its own blacklist has the chance to do so before the .pcf files actually get read.


//Currently, the PEPlus_Pre/PostProcessPCF hooks are game path agnostic - when we use data pcfs to load multiple versions of the 
//same pcf file from different games, the hooks only receive the same original pcf file path for each one, not the internal data pcf 
//file paths, because the latter is inconsistent depending on which games were mounted this session. 

//This does have the downside of not being able to distinguish between different games' versions of the same .pcf - for example, if 
//we were to run into a situation where one particular game's fire_01.pcf has a bad effect we want to blacklist, but other games' 
//fire_01.pcf have fx with the same name that we *don't* want to blacklist, then the hook wouldn't be able to tell them apart easily.

//However, it also has the upside of not caring where the pcf came from in all other cases too - for example, if a player loads a 
//game's pcf from an addon instead of mounting the game itself, then the hook won't care and will run all the same.

	
local tf2_unusual_wep_pcfs = {
	["particles/weapon_unusual_cool.pcf"] = true,
	["particles/weapon_unusual_energyorb.pcf"] = true,
	["particles/weapon_unusual_hot.pcf"] = true,
	["particles/weapon_unusual_isotope.pcf"] = true
}
local tf2_unusual_wep_blacklist_text = "Blacklisted: _unusual_parent_ fx are all useless conflicting copies of other fx\nfrom the same file, and clog up searches for any TF2 weapon, get rid of them"

local default_comments = {
	//Team Fortress 2
	["particles/coin_spin.pcf"] = {
		coin_spin = "Only creates particles while moving" //this works by outputting a speed value to a cpoint with one operator, and then remapping that value to particle radius with another, which is too complex to auto-detect
	},
	["particles/stamp_spin.pcf"] = {
		stamp_spin = "Only creates particles while moving" //^
	},
}

hook.Add("PEPlus_PostProcessPCF", "default_blacklist_&_comments", function(filename, tab)
	if tf2_unusual_wep_pcfs[filename] then
		for k, v in pairs (tab) do
			if string.StartsWith(k, "_unusual_parent_") then
				PEPlus_AddCullReason(tab[k], tf2_unusual_wep_blacklist_text)
			end
		end
	end
	if default_comments[filename] then
		for k, v in pairs (tab) do
			if default_comments[filename][k] then
				PEPlus_AddInfoText(tab[k], default_comments[filename][k])
			end
		end
	end
end)




//Run sub-files because this addon has way too much autorun code; the order here matters

include("peplus/utilfx.lua")
include("peplus/pcf_processing.lua")
include("peplus/spawnmenu.lua")
include("peplus/properties.lua")
include("peplus/pcf_crash_prevention.lua")




//Cleanup and limit
cleanup.Register("peplus")
if SERVER then
	CreateConVar("sbox_maxpeplus", "10", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Maximum particle effects a single player can create")
end




//Show attachments when hovering over or selecting a model with the particle attacher tool, or when hovering over attachment sliders in the edit window
if CLIENT then
	local colorborder = Color(0,0,0,255)
	local colorselect = Color(0,255,0,255)
	local colorunselect = Color(255,255,255,255)

	hook.Add("HUDPaint", "PEPlus_HUDPaint_DrawAttachments", function()
		local ply = LocalPlayer()
		local ent = nil 
		local attachnum = 0

		//First, check if we're hovering over an attachment slider from our edit window
		local hov = vgui:GetHoveredPanel()
		if IsValid(hov) and istable(hov.PEPlus_AttachSlider) then
			ent = hov.PEPlus_AttachSlider.ent
			attachnum = hov.PEPlus_AttachSlider.attach
		end

		//If that didn't work, then check our attacher tool
		if !IsValid(ent) then
			local function get_active_tool(ply, tool)
				-- find toolgun
				local activeWep = ply:GetActiveWeapon()
				if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end

				return activeWep:GetToolObject(tool)
			end

			local tool = get_active_tool(ply, "peplus_attacher")
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

if GetConVarNumber("developer") >= 1 then MsgN("Particle Effects+: running autorun") end