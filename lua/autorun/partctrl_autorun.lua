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
CreateConVar("sv_partctrl_blacklist_screenspace", 1-int_sp, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "If 1, effects with the var \"screen space effect\" are blacklisted from being loaded.\nNote: Changing this value will reload *all* PCF files, temporarily freezing the game for all clients. Be careful!", 0, 1)
if SERVER then
	cvars.AddChangeCallback("sv_partctrl_blacklist_screenspace", function(cvname, old, new)
		if old != new then
			PartCtrl_ReloadPCF("all")
		end
	end, "PartCtrl_ReloadPCFsOnChange")
end

if CLIENT then
	//Some convars to separate child fx from others; in practice, this doesn't work well because there are 
	//A: lots of normal fx that are also used as children, and would be excluded (i.e. eye_powerup_green_lvl_3, rocket_explosion_classic, rocket_trail_classic_crit_red, many more) 
	//and B: lots of unused child fx that were removed from their parents, and so end up cluttering up the parent fx lists anyway (too many to list), 
	//so these features are disabled by default.
	CreateClientConVar("cl_partctrl_childfx_in_autospawnlists", 2, false, false, "Sets how child particle effects appear in auto-generated .pcf spawnlists.\n0: Child effects are hidden\n1: Child effects are sorted into a separate category\n2: Child effects are listed alongside parent effects", 0, 2)
	CreateClientConVar("cl_partctrl_childfx_in_search", 1, false, false, "If 0, prevents child particle effects from being shown in search results.", 0, 1)

	CreateClientConVar("cl_partctrl_dupes_in_search", 0, false, false, "If 0, prevents duplicate effects from being shown in search results.", 0, 1)
	CreateClientConVar("cl_partctrl_debug_spawnicons", 0, false, false, "If 1, show renderbounds used to calculate spawnicon camera position.\nred = particle bounds\ngreen = particle2 bounds (compensation for vector/axis controls and \"set control point to player\")\nblue = particle3 bounds (compensation for \"set control point positions\")\nwhite = final spawnicon bounds", 0, 1)
end




//Run sub-files because this addon has way too much autorun code; the order here matters

include("partctrl/default_lists.lua")
include("partctrl/utilfx.lua")
include("partctrl/pcf_processing.lua")
include("partctrl/spawnmenu.lua")
include("partctrl/properties.lua")




//Custom version of SortedPairs to sort by table key, but caps-agnostically (see original: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/table.lua#L539-L576)
//This is used to match how the particle editor sorts particle names, so we don't sort capitalized particles above uncapitalized ones.

function PartCtrl_SortedPairsLower(pTable)

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
			for name, _ in pairs (PartCtrl_CulledFx[pcf]) do
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

			local allfx = {}
			for k, _ in pairs (PartCtrl_ProcessedPCFs[pcf]) do
				allfx[k] = true
			end
			for k, _ in pairs (PartCtrl_CulledFx[pcf]) do
				allfx[k] = true
			end
			for effectname, _ in pairs (allfx) do
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




//Cleanup and limit
cleanup.Register("partctrl")
if SERVER then
	CreateConVar("sbox_maxpartctrl", "10", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Maximum particle effects a single player can create")
end




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