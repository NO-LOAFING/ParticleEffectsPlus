AddCSLuaFile()

if CLIENT then

	pepluswindows = {}

	function OpenPEPlusEditor(ent)
		chat.AddText("ent.CPPICanTool = ", tostring(ent.CPPICanTool == nil))
		
		local ent_owner = ent:CPPIGetOwner()

		if IsValid(ent_owner) then 
			local local_player = LocalPlayer()
			if ent_owner ~= local_player then
				if not ent:CPPICanTool(ent_owner) then
					return 
				end
			end
		end

		if IsValid(ent.PEPlusWindow) then return end

		local width = 367 //width of 367 nicely fits color picker
		local height = 400
		if ent.PEPlus_SpecialEffect then
			width = width + 16 //special fx controls have some extra width because of the tab layout
			height = 500 //special fx also just have more controls in general, so make it higher by default
		end

		local window = g_ContextMenu:Add("DFrame")
		window:SetSize(width, height) 
		window:Center()
		window:SetSizable(true)
		//window:SetMinHeight(h_min)
		//window:SetMinWidth(w_min)

		//When opening multiple edit windows, move the default position slightly for each window open so they don't get completely hidden by each other until the player moves them
		local x, y = window:GetPos()
		local xmax, ymax = g_ContextMenu:GetSize()
		window:SetPos(math.min(x + (#pepluswindows * 25), xmax - 25), math.min(y + (#pepluswindows * 25), ymax - 25))

		local control = window:Add("PEPlusEditor")
		window.Control = control
		control:SetEntity(ent)
		control:Dock(FILL)

		table.insert(pepluswindows, window)

		control.OnEntityLost = function()
			window:Remove()
		end

		window.OnRemove = function()
			table.remove(pepluswindows, table.KeyFromValue(pepluswindows, window))
		end

		//Fix: If the control window is created while the context menu is closed (by opening a control window with the attacher tool while holding Q) then it'll be unclickable
		//and get stuck on the screen until the entity is removed, so we have to manually enable mouse input here to stop that from happening
		window:SetMouseInputEnabled(true)
		control:SetMouseInputEnabled(true)

	end

end

//Make these funcs global so advbonemerge tool dropdown can use them too

PEPlus_EditProperty_Filter = function(self, ent, ply)

	if !IsValid(ent) then return false end
	if !gamemode.Call("CanProperty", ply, "editpeplus", ent) then return false end

	if !istable(ent.PEPlus_ParticleEnts) then return false end
	local count = table.Count(ent.PEPlus_ParticleEnts) 
	if count < 1 then return false end
	if count == 1 then
		for k, _ in pairs (ent.PEPlus_ParticleEnts) do
			if !(IsValid(k) and ((k.PEPlus_Ent and k.GetPCF) or k.PEPlus_SpecialEffect)) then
				return false
			end
		end
	end

	return true

end

PEPlus_EditProperty_MenuOpen = function(self, option, ent)

	//If the entity has one particle effect, then this property is an option to open a window for it; 
	//if it has multiple particle effects, then this property is a dropdown containing options for each one

	if table.Count(ent.PEPlus_ParticleEnts) == 1 then

		for k, _ in pairs (ent.PEPlus_ParticleEnts) do
			local str = k.PrintName
			if k.GetParticleName then
				local pcf = PEPlus_GetGamePCF(k:GetPCF(), k:GetPath())
				if PEPlus_ProcessedPCFs[pcf] and PEPlus_ProcessedPCFs[pcf][k:GetParticleName()] then
					str = PEPlus_ProcessedPCFs[pcf][k:GetParticleName()].nicename
				end
			end
			option:SetText("Edit Particle Effect (" .. str .. ")")
			option.DoClick = function() OpenPEPlusEditor(k) end
		end

	else
		
		local submenu = option:AddSubMenu()
		for k, _ in pairs (ent.PEPlus_ParticleEnts) do
			if IsValid(k) and ((k.PEPlus_Ent and k.GetPCF) or k.PEPlus_SpecialEffect) then
				local str = k.PrintName
				if k.GetParticleName then
					local pcf = PEPlus_GetGamePCF(k:GetPCF(), k:GetPath())
					if PEPlus_ProcessedPCFs[pcf] and PEPlus_ProcessedPCFs[pcf][k:GetParticleName()] then
						str = PEPlus_ProcessedPCFs[pcf][k:GetParticleName()].nicename
					end
				end
				local opt = submenu:AddOption(str)
				opt.DoClick = function() OpenPEPlusEditor(k) end
			end
		end

	end

end

properties.Add("editpeplus", {
	MenuLabel = "Edit Particle Effects..",
	Order = 90000, //for reference, edit properties is 90001 and edit animprop is 90002
	PrependSpacer = true,
	MenuIcon = "icon16/fire.png",
	
	Filter = PEPlus_EditProperty_Filter,

	MenuOpen = PEPlus_EditProperty_MenuOpen,

	Action = function(self, ent)
	
		//Nothing, set by MenuOpen

	end
})

//Developer properties for table dumps to console

properties.Add("peplus_dev_printpcfdata", {
	MenuLabel = "Print raw PCF data for this effect",
	Order = 90000.51, //this works, incredible
	PrependSpacer = false,
	MenuIcon = nil,
	
	Filter = function(self, ent, ply)

		if GetConVarNumber("developer") < 1 then return false end
		if !IsValid(ent) then return false end
		if !istable(ent.PEPlus_ParticleEnts) or table.Count(ent.PEPlus_ParticleEnts) != 1 then return false end

		return true

	end,

	Action = function(self, ent)
	
		for k, _ in pairs (ent.PEPlus_ParticleEnts) do
			if IsValid(k) then
				if k.PEPlus_SpecialEffect then MsgN("Can't get raw pcf data for special effect " .. k.PrintName) return end
				if k:GetPCF() == "UtilFx" then MsgN("UtilFx isn't a real pcf, doofus!") return end
				local pcf = PEPlus_GetGamePCF(k:GetPCF(), k:GetPath())
				local name = k:GetParticleName()
				MsgN("PEPlus_ReadPCF(\"" .. pcf .. "\")[\"" .. name .. "\"]:")
				PrintTable(PEPlus_ReadPCF(pcf)[name])
				MsgN()
			end
		end

	end
})

properties.Add("peplus_dev_printpcfdata_nodefs", {
	MenuLabel = "Print raw PCF data for this effect (no defaults)",
	Order = 90000.515,
	PrependSpacer = false,
	MenuIcon = nil,
	
	Filter = function(self, ent, ply)

		if GetConVarNumber("developer") < 1 then return false end
		if !IsValid(ent) then return false end
		if !istable(ent.PEPlus_ParticleEnts) or table.Count(ent.PEPlus_ParticleEnts) != 1 then return false end

		return true

	end,

	Action = function(self, ent)
	
		for k, _ in pairs (ent.PEPlus_ParticleEnts) do
			if IsValid(k) then
				if k.PEPlus_SpecialEffect then MsgN("Can't get raw pcf data for special effect " .. k.PrintName) return end
				if k:GetPCF() == "UtilFx" then MsgN("UtilFx isn't a real pcf, doofus!") return end
				local pcf = PEPlus_GetGamePCF(k:GetPCF(), k:GetPath())
				local name = k:GetParticleName()
				MsgN("PEPlus_NoDefPCFs[\"" .. pcf .. "\"][\"" .. name .. "\"]:")
				PrintTable(PEPlus_NoDefPCFs[pcf][name])
				MsgN()
			end
		end

	end
})

properties.Add("peplus_dev_printprocessed", {
	MenuLabel = "Print processed PCF data for this effect",
	Order = 90000.52,
	PrependSpacer = false,
	MenuIcon = nil,
	
	Filter = function(self, ent, ply)

		if GetConVarNumber("developer") < 1 then return false end
		if !IsValid(ent) then return false end
		if !istable(ent.PEPlus_ParticleEnts) or table.Count(ent.PEPlus_ParticleEnts) != 1 then return false end

		return true

	end,

	Action = function(self, ent)
	
		for k, _ in pairs (ent.PEPlus_ParticleEnts) do
			if IsValid(k) then
				if k.PEPlus_SpecialEffect then MsgN("Can't get processed pcf data for special effect " .. k.PrintName) return end
				local pcf = PEPlus_GetGamePCF(k:GetPCF(), k:GetPath())
				local name = k:GetParticleName()
				MsgN("PEPlus_ProcessedPCFs[\"" .. pcf .. "\"][\"" .. name .. "\"]:")
				local tab = table.Copy(PEPlus_ProcessedPCFs[pcf][name])
				//translate cpoint modes back into human-readable enum names
				if tab.cpoints then
					for k, v in pairs (tab.cpoints) do
						if v.mode != nil then
							tab.cpoints[k].mode = PEPLUS_CPOINT_MODES[v.mode]
						end
					end
				end
				PrintTable(tab)
				MsgN()
			end
		end

	end
})

properties.Add("peplus_dev_printparticleinfo", {
	MenuLabel = "Print ParticleInfo (settings on this entity)",
	Order = 90000.53,
	PrependSpacer = false,
	MenuIcon = nil,
	
	Filter = function(self, ent, ply)

		if GetConVarNumber("developer") < 1 then return false end
		if !IsValid(ent) then return false end
		if !istable(ent.PEPlus_ParticleEnts) or table.Count(ent.PEPlus_ParticleEnts) != 1 then return false end

		return true

	end,

	Action = function(self, ent)
	
		for k, _ in pairs (ent.PEPlus_ParticleEnts) do
			if IsValid(k) then
				if k.PEPlus_SpecialEffect then MsgN("Can't get ParticleInfo data for special effect " .. k.PrintName) return end
				local pcf = PEPlus_GetGamePCF(k:GetPCF(), k:GetPath())
				MsgN(k, ".ParticleInfo (", pcf, "/", k:GetParticleName(), "): ")
				PrintTable(k.ParticleInfo)
				MsgN()
			end
		end

	end
})




//Backwards compatibility - commands to update fx from the old addon to the new addon

local OldGameFx = {
	["particles/achievement_cstrike.pcf"] = {pcf = "particles/achievement.pcf", path = "cstrike", badprefix = "cstrike_"},
	["particles/fire_01_portal.pcf"] = {pcf = "particles/fire_02.pcf", path = "portal", badprefix = "portal_"},
	["particles/blood_impact_tf2.pcf"] = {pcf = "particles/blood_impact.pcf", path = "tf", badprefix = "tf2_"},
	["particles/explosion_ep2.pcf"] = {pcf = "particles/explosion.pcf", path = "hl2", badprefix = "ep2_", exceptions = {smoke_blackbillow = "particles/vistasmokev1.pcf"}}
}
local function FindPCFFromEffect(name)
	if CLIENT then return end
	local pcf, path, utilfx
	if string.StartsWith(name, "!UTILEFFECT!") then
		name = string.TrimLeft(name, "!UTILEFFECT!")
		pcf = "UtilFx"
		utilfx = {Flags = 0, Color = 0}
		for i = 1, 9 do
			if string.find(name, "!FLAG" .. i .. "!") then
				name = string.Replace(name, "!FLAG" .. i .. "!", "")
				utilfx.Flags = utilfx.Flags + i
			end
			if string.find(name, "!COLOR" .. i .. "!") then
				name = string.Replace(name, "!COLOR" .. i .. "!", "")
				utilfx.Color = utilfx.Color + i
			end
		end
	else
		//Get the first pcf containing this particle name; don't overthink it, the old addon had no concept of multiple fx sharing a name
		if PEPlus_PCFsByParticleName[string.lower(name)] then
			for k, v in pairs (PEPlus_PCFsByParticleName[string.lower(name)]) do
				pcf = v
				break
			end
			local old = OldGameFx[pcf]
			if old then
				//The old addon handled conflicting pcf and effect names by including custom-made pcfs with different file names
				//and, when necessary, different effect names. Redirect these to use the correct game pcf instead.
				name = string.TrimLeft(name, old.badprefix)
				if old.exceptions and old.exceptions[name] then
					pcf = old.exceptions[name]
				else
					pcf = old.pcf
				end
				path = old.path
			else
				if !PEPlus_AllDataPCFs[pcf] then
					path = PEPlus_GamePCFs_DefaultPaths[pcf] //optional, can be nil
				else
					path = PEPlus_AllDataPCFs[pcf].path
					pcf = PEPlus_AllDataPCFs[pcf].original_filename
				end
			end
		else
			MsgN("Particle Effects+ FindPCFFromEffect: ", name, " couldn't find PEPlus_PCFsByParticleName")
		end
	end
	return string.lower(name), pcf, path, utilfx
end

//All this stuff gets reused in every conversion func, so make a separate function for it
local function UpdateColorAndUtilFx(p, c, utilfx, info, cpointtab, name)
	if IsColor(c) then
		if !(c.r == 0 and c.g == 0 and c.b == 0) then
			if c.a == 1 then
				c = Vector(c.r / 255, c.g / 255, c.b / 255)
			else
				c = Vector(c.r, c.g, c.b)
			end
		else
			c = nil
		end
	elseif c == Vector(0,0,0) then
		c = nil
	end

	if utilfx then
		if info then
			utilfx.Scale = info.x
			utilfx.Magnitude = info.y
			utilfx.Radius = info.z
		end
		if string.find(name, "tracer") then utilfx.Scale = 5000 end //hard-coded scale/mag values from old effect func
		if string.find(name, "shakeropes") then utilfx.Magnitude = utilfx.Magnitude * 20 end
		if string.find(name, "thumperdust") then utilfx.Scale = utilfx.Scale * 50 end
		if string.find(name, "bloodspray") then utilfx.Scale = utilfx.Scale * 4  end
		if string.find(name, "muzzleflash") and utilfx.Flags == 3 then utilfx.Flags = 4 end //3 is identical to 4, and is commented out in the new addon
	end

	for k, v in pairs (cpointtab) do
		if v.mode == PEPLUS_CPOINT_MODE_AXIS then
			if c then
				for i = 0, 2 do
					if v["axis_" .. i] and v["axis_" .. i].colorpicker then
						p.ParticleInfo[k].val = Vector(c)
						break
					end
				end
			end
			if utilfx then
				for k2, v2 in pairs (v.axis) do
					for utilk, utilv in pairs (utilfx) do
						//Find an axis control with a matching name (not label) and apply the value.
						//I definitely knew all these overly specific name values would be good for something eventually!
						if string.find(v2.name, utilk) then
							p.ParticleInfo[k].val[v2.axis+1] = utilv
						end
					end
				end
			end
		end
	end
end

local function UpdateOldEffect(ent)
	if CLIENT then return end
	if !IsValid(ent) then return nil end
	local class = ent:GetClass()
	if class == "particlecontroller_normal" then
		local ply = ent:GetPlayer()
		local name, pcf, path, utilfx
		name = ent:GetEffectName()
		name, pcf, path, utilfx = FindPCFFromEffect(name)
		//MsgN(name, ", ", pcf, ", ", path, ", ", ply)
		local p = PEPlus_SpawnParticle(ply, ent:GetPos(), name, pcf, path)
		if IsValid(p) then
			local t1 = ent:GetTargetEnt()
			local t2 = ent:GetTargetEnt2()
			if !IsValid(t2) then t2 = nil end

			local cpointtab = PEPlus_ProcessedPCFs[PEPlus_GetGamePCF(pcf, path)][name].cpoints
			local done_first = false
			for k, v in pairs (cpointtab) do
				if v.mode == PEPLUS_CPOINT_MODE_POSITION then
					if !done_first or !t2 then
						p:AttachToEntity(t1, k, ent:GetAttachNum(), ply, false)
						done_first = true
					else
						p:AttachToEntity(t2, k, ent:GetAttachNum2(), ply, false)
					end
				end
			end
			UpdateColorAndUtilFx(p, ent:GetColor(), utilfx, ent:GetUtilEffectInfo(), cpointtab, name)

			local safety = ent:GetRepeatSafety()
			local rate = ent:GetRepeatRate()
			if rate == 0 then
				//Effects set to not loop should be fine to carry over either way
				p:SetLoopMode(0)
				p:SetLoopDelay(0)
				p:SetLoopSafety(safety)
			elseif !safety or utilfx then
				//Because of the changes to how repeat safety works between the new and old addon (old addon only 
				//disables the old effect every repeat, while new addon also completely cleans up the old effect), 
				//we can't carry over the repeat rate 1-to-1 when repeat safety is enabled, or we'll break every 
				//single continuous effect that was unknowingly set to have a repeat rate. It seems better to make 
				//players fix the few fx they set to some deliberate repeat rate than it does to make them fix 
				//*every single continuous effect*, so this is what we're going with.
				p:SetLoopMode(2)
				p:SetLoopDelay(rate)
				p:SetLoopSafety(safety)
			end

			local key = ent:GetNumpadKey()
			p:SetNumpad(key)
			p:SetNumpadStartOn(ent:GetActive())
			p:SetNumpadToggle(ent:GetToggle())
			//Update numpad funcs
			numpad.Remove(p.NumDown)
			numpad.Remove(p.NumUp)
			p.NumDown = numpad.OnDown(ply, key, "PEPlus_Numpad", p, true)
			p.NumUp = numpad.OnUp(ply, key, "PEPlus_Numpad", p, false)
		end
		ent:Remove()
		return IsValid(p)
	elseif class == "particlecontroller_tracer" then
		local ply = ent:GetPlayer()
		if !gamemode.Call("PlayerSpawnSENT", ply, "ent_peplus_sfx_tracer") then return false end
		local s = ents.Create("ent_peplus_sfx_tracer")
		if IsValid(s) then
			s:SetPos(ent:GetPos())
			s.IsBlank = true
			s.SetCreator(ply)
			s:Spawn()
			s:AttachToEntity(ent:GetTargetEnt(), k, ent:GetAttachNum(), ply, false)

			//Tracer effect
			local name, pcf, path, utilfx
			name = ent:GetEffectName()
			name, pcf, path, utilfx = FindPCFFromEffect(name)
			//MsgN(name, ", ", pcf, ", ", path, ", ", ply)
			local p = PEPlus_SpawnParticle(ply, ent:GetPos(), name, pcf, path)
			if IsValid(p) then
				p:AttachToSpecialEffect(s, ply, false)
				local cpointtab = PEPlus_ProcessedPCFs[PEPlus_GetGamePCF(pcf, path)][name].cpoints
				local done_first = false
				for k, v in pairs (cpointtab) do
					if v.mode == PEPLUS_CPOINT_MODE_POSITION then
						if !done_first then
							p.ParticleInfo[k].sfx_role = 0 //start
							done_first = true
						else
							p.ParticleInfo[k].sfx_role = 1 //end
						end
					end
				end
				UpdateColorAndUtilFx(p, ent:GetColor(), utilfx, nil, cpointtab, name) //old ent doesn't actually support any utilfx controls for this effect other than tracers getting the hard-coded 5000 scale, but that's because no compatible fx in the spawnlist used them
			end

			//Impact effect
			local name, pcf, path, utilfx
			name = ent:GetImpact_EffectName()
			if name != "" then
				name, pcf, path, utilfx = FindPCFFromEffect(name)
				//MsgN(name, ", ", pcf, ", ", path, ", ", ply)
				local p = PEPlus_SpawnParticle(ply, ent:GetPos(), name, pcf, path)
				if IsValid(p) then
					p:AttachToSpecialEffect(s, ply, false)
					local cpointtab = PEPlus_ProcessedPCFs[PEPlus_GetGamePCF(pcf, path)][name].cpoints
					local done_first = false
					for k, v in pairs (cpointtab) do
						if v.mode == PEPLUS_CPOINT_MODE_POSITION then
							p.ParticleInfo[k].sfx_role = 1 //end
						end
					end
					UpdateColorAndUtilFx(p, ent:GetImpact_ColorInfo(), utilfx, ent:GetImpact_UtilEffectInfo(), cpointtab, name)
				end
			end

			if ent:GetLeaveBulletHoles() then
				local p = PEPlus_SpawnParticle(ply, ent:GetPos(), "Impact_GMOD", "UtilFx")
				if IsValid(p) then
					p.ParticleInfo[2].val = Vector() //by default, this value is set to disable sounds; clear it to match impacts on old addon's tracer fx, which have sounds enabled
					p:AttachToSpecialEffect(s, ply, false)
				end
			end

			local rate = ent:GetRepeatRate()
			if rate == 0 then
				s:SetLoop(false)
			else
				s:SetLoopDelay(rate)
			end
			s:SetTracerSpread(ent:GetTracerSpread()*90)
			s:SetTracerCount(ent:GetTracerCount())
			//old ent's "EffectLifetime" value has no analog on new ent; this was a crude standin for repeat safety to prevent an infinite number of fx from piling up, but the new ent has different safeguards against that

			local key = ent:GetNumpadKey()
			s:SetNumpad(key)
			s:SetNumpadStartOn(ent:GetActive())
			s:SetNumpadToggle(ent:GetToggle())
			//Update numpad funcs
			numpad.Remove(s.NumDown)
			numpad.Remove(s.NumUp)
			s.NumDown = numpad.OnDown(ply, key, "PEPlus_Numpad", s, true)
			s.NumUp = numpad.OnUp(ply, key, "PEPlus_Numpad", s, false)

			//Other generic stuff from SENT spawn func; do this last so this undo is on top of the stack (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/commands.lua#L896C1-L909C32)
			if IsValid(ply) then
				gamemode.Call("PlayerSpawnedSENT", ply, s)
				undo.Create("SENT")
					undo.SetPlayer(ply)
					undo.AddEntity(s)
					undo.SetCustomUndoText("Undone " .. s.PrintName)
				undo.Finish("#undo.generic.entity (" .. s.PrintName .. ")")
				ply:AddCleanup("sents", s)
				s:SetVar("Player", ply)
			end
		end
		ent:Remove()
		return IsValid(s)
	elseif class == "particlecontroller_proj" then
		local ply = ent:GetPlayer()
		if !gamemode.Call("PlayerSpawnSENT", ply, "ent_peplus_sfx_proj") then return false end
		local s = ents.Create("ent_peplus_sfx_proj")
		if IsValid(s) then
			s:SetPos(ent:GetPos())
			s.IsBlank = true
			s.SetCreator(ply)
			s:Spawn()
			s:AttachToEntity(ent:GetParent(), k, ent:GetAttachNum(), ply, false) //use GetParent instead of GetTargetEnt, because the old ent sets its targetent to itself for... reasons?

			//Projectile effect
			local name, pcf, path, utilfx
			name = ent:GetProjFX_EffectName()
			if name != "" then
				name, pcf, path, utilfx = FindPCFFromEffect(name)
				//MsgN(name, ", ", pcf, ", ", path, ", ", ply)
				local p = PEPlus_SpawnParticle(ply, ent:GetPos(), name, pcf, path)
				if IsValid(p) then
					p:AttachToSpecialEffect(s, ply, false)
					local cpointtab = PEPlus_ProcessedPCFs[PEPlus_GetGamePCF(pcf, path)][name].cpoints
					local done_first = false
					for k, v in pairs (cpointtab) do
						if v.mode == PEPLUS_CPOINT_MODE_POSITION then
							p.ParticleInfo[k].attach = ent:GetProjModel_AttachNum()
							p.ParticleInfo[k].sfx_role = 1 //projectile model
						end
					end
					UpdateColorAndUtilFx(p, ent:GetProjFX_ColorInfo(), utilfx, ent:GetProjFX_UtilEffectInfo(), cpointtab, name)
				end
			end

			//Impact effect
			local name, pcf, path, utilfx
			name = ent:GetImpactFX_EffectName()
			if name != "" then
				name, pcf, path, utilfx = FindPCFFromEffect(name)
				//MsgN(name, ", ", pcf, ", ", path, ", ", ply)
				local p = PEPlus_SpawnParticle(ply, ent:GetPos(), name, pcf, path)
				if IsValid(p) then
					p:AttachToSpecialEffect(s, ply, false)
					local cpointtab = PEPlus_ProcessedPCFs[PEPlus_GetGamePCF(pcf, path)][name].cpoints
					local done_first = false
					for k, v in pairs (cpointtab) do
						if v.mode == PEPLUS_CPOINT_MODE_POSITION then
							p.ParticleInfo[k].sfx_role = 2 //hit point
						end
					end
					UpdateColorAndUtilFx(p, ent:GetImpactFX_ColorInfo(), utilfx, ent:GetImpactFX_UtilEffectInfo(), cpointtab, name)
				end
			end

			local rate = ent:GetRepeatRate()
			if rate == 0 then
				s:SetLoop(false)
			else
				s:SetLoopDelay(rate)
			end
			s:SetProjSpread(ent:GetProjEnt_Spread()*90)
			//old ent's "ImpactFX_EffectLifetime" value has no analog on new ent; this was a crude standin for repeat safety to prevent an infinite number of fx from piling up, but the new ent has different safeguards against that
			s:SetProjVelocity(ent:GetProjEnt_Velocity())
			s:SetProjGravity(ent:GetProjEnt_Gravity())
			local angs = {
				[0] = 0, //forward
				[5] = 1, //back
				[1] = 2, //left
				[2] = 3, //right
				[3] = 4, //up
				[4] = 5, //down
			}
			s:SetProjAngle(angs[ent:GetProjEnt_Angle()])
			local spin = ent:GetProjEnt_Spin()
			if spin == 1 then //pitch
				s:SetProjSpin(2)
				s:SetProjSpinVelocity(350)
			elseif spin == 2 then //labeled "yaw" in old tool, actually roll
				s:SetProjSpin(4)
				s:SetProjSpinVelocity(350)
			elseif spin == 3 then //labeled "roll" in old tool, actually yaw
				s:SetProjSpin(3)
				s:SetProjSpinVelocity(-350)
			elseif spin == 4 then //random
				s:SetProjSpin(1)
				s:SetProjSpinVelocity(350)
			end
			if ent:GetProjEnt_DemomanFix() then s:SetProjDir(3) end //right
			s:SetProjLifetimePre(ent:GetProjEnt_Lifetime_PreHit())
			s:SetProjLifetimePost(ent:GetProjEnt_Lifetime_PostHit())
			s:SetProjServerside(ent:GetProjEnt_Serverside())
			s:SetProjDrag(true) //matches old ent behavior

			s:SetModel(ent:GetProjModel())
			s:SetSkin(ent:GetSkin())
			if ent:GetMaterial() != "" and !(!game.SinglePlayer() && !list.Contains("OverrideMaterials", ent:GetMaterial()) && ent:GetMaterial() != "") then
				s:SetMaterial(ent:GetMaterial())
				duplicator.StoreEntityModifier(s, "material", {MaterialOverride = ent:GetMaterial()})
			end
			if ent:GetProjModel_Invis() then
				s:SetColor(Color(255,255,255,0))
				duplicator.StoreEntityModifier(s, "colour", {Color = Color(255,255,255,0)})
			end

			local key = ent:GetNumpadKey()
			s:SetNumpad(key)
			s:SetNumpadStartOn(ent:GetActive())
			s:SetNumpadToggle(ent:GetToggle())
			//Update numpad funcs
			numpad.Remove(s.NumDown)
			numpad.Remove(s.NumUp)
			s.NumDown = numpad.OnDown(ply, key, "PEPlus_Numpad", s, true)
			s.NumUp = numpad.OnUp(ply, key, "PEPlus_Numpad", s, false)

			//Other generic stuff from SENT spawn func; do this last so this undo is on top of the stack (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/commands.lua#L896C1-L909C32)
			if IsValid(ply) then
				gamemode.Call("PlayerSpawnedSENT", ply, s)
				undo.Create("SENT")
					undo.SetPlayer(ply)
					undo.AddEntity(s)
					undo.SetCustomUndoText("Undone " .. s.PrintName)
				undo.Finish("#undo.generic.entity (" .. s.PrintName .. ")")
				ply:AddCleanup("sents", s)
				s:SetVar("Player", ply)
			end
		end
		ent:Remove()
		return IsValid(s)
	end
end

properties.Add("peplus_backcomp", {
	MenuLabel = "Convert Adv. Particle Control effects to Particle Effects+",
	Order = 89999,
	PrependSpacer = false,
	MenuIcon = "icon16/fire.png",
	
	Filter = function(self, ent, ply)

		if !IsValid(ent) then return false end
		if !gamemode.Call("CanProperty", ply, "peplus_backcomp", ent) then return false end

		local function CheckForChildFx(ent2)
			if ent2.ParticleControl_FxForBackcomp then
				for k, _ in pairs (ent2.ParticleControl_FxForBackcomp) do
					if k.GetTargetEnt2 and k:GetTargetEnt2() == ent2 then return true end
				end
			end
			for _, v in pairs (ent2:GetChildren()) do
				local class = v:GetClass()
				if class == "particlecontroller_normal" or class == "particlecontroller_proj" or class == "particlecontroller_tracer" then
					return true
				else
					local val = CheckForChildFx(v)
					if val then return val end
				end
			end
		end
		return CheckForChildFx(ent)

	end,

	Action = function(self, ent)

		self:MsgStart()
			net.WriteEntity(ent)
		self:MsgEnd()

	end,

	Receive = function(self, length, ply)

		local ent = net.ReadEntity()
		if !IsValid(ent) or !IsValid(ply) or !properties.CanBeTargeted(ent, ply) or !self:Filter(ent, ply) then return end

		local results = {}
		local function CheckForChildFx(ent2)
			if ent2.ParticleControl_FxForBackcomp then
				for k, _ in pairs (ent2.ParticleControl_FxForBackcomp) do
					if k.GetTargetEnt2 and k:GetTargetEnt2() == ent2 and k:GetTargetEnt() != k:GetTargetEnt2() then //if both targets are this ent, then it'll be handled below; doing this here anyway just spawns the effect twice
						local result = UpdateOldEffect(k)
						if isbool(result) then
							results[result] = (results[result] or 0) + 1
						end
					end
				end
			end
			for _, v in pairs (ent2:GetChildren()) do
				local result = UpdateOldEffect(v)
				if isbool(result) then
					results[result] = (results[result] or 0) + 1
				else
					CheckForChildFx(v)
				end
			end
			constraint.RemoveConstraints(ent2, "AttachParticleControllerBeam")
			duplicator.ClearEntityModifier(ent2, "DupeParticleControllerNormal")
			duplicator.ClearEntityModifier(ent2, "DupeParticleControllerTracer")
			duplicator.ClearEntityModifier(ent2, "DupeParticleControllerProj")
		end
		CheckForChildFx(ent)
		//Show on-screen notifications for all fx we converted or failed to convert
		ply:SendLua("surface.PlaySound('common/wpn_select.wav')")
		if results[true] then
			MsgN("Successfully converted " .. results[true] .. " effect(s)!")
			ply:SendLua("GAMEMODE:AddNotify('Successfully converted " .. results[true] .. " effect(s)!', NOTIFY_GENERIC, 4)")
			ply:SendLua("surface.PlaySound('ambient/water/drip" .. math.random(1, 4) .. ".wav')")
		end
		if results[false] then
			MsgN("Failed to convert " .. results[false] .. " effect(s)!")
			ply:SendLua("GAMEMODE:AddNotify('Failed to convert " .. results[false] .. " effect(s)!', NOTIFY_ERROR, 4)")
			ply:SendLua("surface.PlaySound('buttons/button11.wav')")
		end

	end
})

if SERVER then
	concommand.Add("sv_peplus_backcomp_convert_all", function(ply, cmd, args)
		//Only let server owners run this command because it converts everyone's spawned ents
		if !game.SinglePlayer() and IsValid(ply) and !ply:IsListenServerHost() and !ply:IsSuperAdmin() then
			return false
		end
		local results = {}
		for _, ent in pairs (ents.GetAll()) do
			local result = UpdateOldEffect(ent)
			if isbool(result) then
				results[result] = (results[result] or 0) + 1
			end
			constraint.RemoveConstraints(ent, "AttachParticleControllerBeam")
			duplicator.ClearEntityModifier(ent, "DupeParticleControllerNormal")
			duplicator.ClearEntityModifier(ent, "DupeParticleControllerTracer")
			duplicator.ClearEntityModifier(ent, "DupeParticleControllerProj")
		end
		//Show on-screen notifications for all fx we converted or failed to convert
		ply:SendLua("surface.PlaySound('common/wpn_select.wav')")
		if results[true] then
			MsgN("Successfully converted " .. results[true] .. " effect(s)!")
			ply:SendLua("GAMEMODE:AddNotify('Successfully converted " .. results[true] .. " effect(s)!', NOTIFY_GENERIC, 4)")
			ply:SendLua("surface.PlaySound('ambient/water/drip" .. math.random(1, 4) .. ".wav')")
		end
		if results[false] then
			MsgN("Failed to convert " .. results[false] .. " effect(s)!")
			ply:SendLua("GAMEMODE:AddNotify('Failed to convert " .. results[false] .. " effect(s)!', NOTIFY_ERROR, 4)")
			ply:SendLua("surface.PlaySound('buttons/button11.wav')")
		end
	end, nil, "Update all Advanced Particle Controller effects on the map to Particle Effects+ entities")
end