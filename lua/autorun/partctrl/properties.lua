AddCSLuaFile()

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
				local pcf = PartCtrl_GetPCFPath(k:GetPCF(), k:GetPath())
				local name = k:GetParticleName()
				MsgN("PartCtrl_ReadPCF(\"" .. pcf .. "\")[\"" .. name .. "\"]:")
				PrintTable(PartCtrl_ReadPCF(pcf)[name])
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
				local pcf = PartCtrl_GetPCFPath(k:GetPCF(), k:GetPath())
				local name = k:GetParticleName()
				MsgN("PartCtrl_ProcessedPCFs[\"" .. pcf .. "\"][\"" .. name .. "\"]:")
				PrintTable(PartCtrl_ProcessedPCFs[pcf][name])
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
				local pcf = PartCtrl_GetPCFPath(k:GetPCF(), k:GetPath())
				MsgN(k, ".ParticleInfo (", pcf, "/", k:GetParticleName(), "): ")
				PrintTable(k.ParticleInfo)
				MsgN()
			end
		end

	end
})