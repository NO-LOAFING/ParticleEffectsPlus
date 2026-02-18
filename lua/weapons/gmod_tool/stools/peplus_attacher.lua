TOOL.Category = "Render"
TOOL.Name = "Particle Attacher"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar.attachnum = "0"
TOOL.ClientConVar.drawhalo = "1"

TOOL.Information = {
	{name = "left0", stage = 0, icon = "gui/lmb.png"},
	{name = "left1", stage = 1, icon = "gui/lmb.png"},
	{name = "left2", stage = 2, icon = "gui/lmb.png"},
	{name = "left3", stage = 3, icon = "gui/lmb.png"},
	{name = "leftuse0", stage = 0, icon = "gui/lmb.png", icon2 = "gui/e.png"},
	{name = "leftuse1", stage = 1, icon = "gui/lmb.png", icon2 = "gui/e.png"},
	{name = "leftuse3", stage = 3, icon = "gui/lmb.png", icon2 = "gui/e.png"},
	{name = "middle", icon = "gui/mmb.png"},
	{name = "reload1", stage = 1, icon = "gui/r.png"},
	{name = "reload2", stage = 2, icon = "gui/r.png"},
	{name = "reload3", stage = 3, icon = "gui/r.png"},
}

if CLIENT then
	language.Add("tool.peplus_attacher.name", "Particle Attacher")
	language.Add("tool.peplus_attacher.desc", "Attach particle effects to models")
	language.Add("tool.peplus_attacher.help", "Particles are used for all sorts of different visual effects. You can spawn them from the spawn menu, and then attach them to models with this tool.")

	language.Add("tool.peplus_attacher.middle", "Scroll through a model's attachments")

	language.Add("tool.peplus_attacher.left0", "Select a particle effect to attach, or select a model to attach a particle effect to")
	language.Add("tool.peplus_attacher.leftuse0", "Select yourself")

	language.Add("tool.peplus_attacher.left1", "Now select a model or special effect to attach the particle effect to")
	language.Add("tool.peplus_attacher.leftuse1", "Select yourself") //have to duplicate this one just so we don't have it for stage 2, argh
	language.Add("tool.peplus_attacher.reload1", "Deselect particle effect and cancel")

	language.Add("tool.peplus_attacher.left2", "Now select a particle effect to attach to the model")
	language.Add("tool.peplus_attacher.reload2", "Deselect model and cancel")

	language.Add("tool.peplus_attacher.left3", "Now select a model to attach the special effect to, or select a particle effect to attach to the special effect")
	language.Add("tool.peplus_attacher.leftuse3", "Select yourself") //^
	language.Add("tool.peplus_attacher.reload3", "Deselect special effect and cancel")

	language.Add("undone_PEPlus_Ent", "Undone Attach Particle Effect")
end




function TOOL:LeftClick(trace)

	//Select self by holding E
	if self:GetOwner():KeyDown(IN_USE) then 
		trace.Entity = self:GetOwner()
	end

	local stage = self:GetStage()
	
	if stage == 0 then

		//Select a thing

		local ent = trace.Entity
		if IsValid(ent) then
			if ent.PEPlus_Grip then
				if CLIENT then
					local tab = ent.PEPlus_ParticleEnts
					if istable(tab) then
						for k, _ in pairs (tab) do //a grip point entity should only have a single associated particle
							if IsValid(k) and (k.PEPlus_Ent or k.PEPlus_SpecialEffect) then
								return true
							end
						end
					end
				else
					local tab = constraint.FindConstraint(ent, "PEPlus_Ent")
					if istable(tab) and IsValid(tab.Ent1) and tab.Ent1.PEPlus_Ent then
						self:GetWeapon():SetNWInt("PEPlus_Attacher_CPoint", tab.CPoint)
						self:GetWeapon():SetNWEntity("PEPlus_Attacher_CurEntity", tab.Ent1)
						self:SetStage(1)
						return true
					else
						local tab = constraint.FindConstraint(ent, "PEPlus_SpecialEffect")
						if istable(tab) and IsValid(tab.Ent1) and tab.Ent1.PEPlus_SpecialEffect then
							self:GetWeapon():SetNWEntity("PEPlus_Attacher_CurEntity", tab.Ent1)
							self:SetStage(3)
							return true
						end
					end
				end
			else
				if SERVER then
					self:GetWeapon():SetNWEntity("PEPlus_Attacher_CurEntity", ent)
					self:SetStage(2)
				end
				return true
			end
		end

	else

		//Attach selected thing to other thing

		local ent = nil
		local p = nil
		local k = 0
		if trace.Entity.PEPlus_Grip then
			//Clicked on a particle effect - only proceed if the previously selected ent is a model or a special effect
			//or clicked on a special effect - only proceed if the previously selected ent is a model or a particle effect
			ent = self:GetWeapon():GetNWEntity("PEPlus_Attacher_CurEntity")
			if CLIENT then
				local tab = trace.Entity.PEPlus_ParticleEnts
				if istable(tab) then
					for k2, _ in pairs (tab) do //a grip point entity should only have a single associated particle
						if IsValid(k2) and (k2.PEPlus_Ent or k2.PEPlus_SpecialEffect) then
							p = k2
							if (ent.PEPlus_Ent and p.PEPlus_Ent) or (ent.PEPlus_SpecialEffect and p.PEPlus_SpecialEffect) then return false end
							//don't worry about k for clients
						end
					end
				end
			else
				local tab = constraint.FindConstraint(trace.Entity, "PEPlus_Ent")
				if !ent.PEPlus_Ent and istable(tab) and IsValid(tab.Ent1) and tab.Ent1.PEPlus_Ent then
					p = tab.Ent1
					k = tab.CPoint
				elseif !ent.PEPlus_SpecialEffect then //don't try to attach a special effect to another special effect
					local tab = constraint.FindConstraint(trace.Entity, "PEPlus_SpecialEffect")
					if istable(tab) and IsValid(tab.Ent1) and tab.Ent1.PEPlus_SpecialEffect then
						if !ent.PEPlus_Ent then
							p = tab.Ent1
						else
							//we selected a particle and then a special effect, so swap them and make ent the special effect
							p = ent
							ent = tab.Ent1
						end
					else
						return false
					end
				end
			end
		else
			//Clicked on a model - only proceed if the previously selected ent is a particle/special effect
			ent = trace.Entity
			p = self:GetWeapon():GetNWEntity("PEPlus_Attacher_CurEntity")
			if !p.PEPlus_Ent and !p.PEPlus_SpecialEffect then return false end
			k = self:GetWeapon():GetNWInt("PEPlus_Attacher_CPoint")
		end


		if !ent.PEPlus_SpecialEffect then

			//Attach a particle effect or special effect to a model
	
			if !IsValid(ent) or !IsValid(p) or (!p.PEPlus_SpecialEffect and (!istable(p.ParticleInfo) or !istable(p.ParticleInfo[k]) or PEPlus_ProcessedPCFs[PEPlus_GetGamePCF(p:GetPCF(), p:GetPath())][p:GetParticleName()].cpoints[k].mode != PEPLUS_CPOINT_MODE_POSITION)) then return false end
			if CLIENT then return true end

			local const = p:AttachToEntity(ent, k, self:GetClientNumber("attachnum", 0), self:GetOwner(), true)
			if !IsValid(const) then return false end

		else
			
			//Attach a particle effect to a special effect

			if !IsValid(ent) or !IsValid(p) or !istable(p.ParticleInfo) then return false end
			if CLIENT then return true end

			local const = p:AttachToSpecialEffect(ent, self:GetOwner(), true)
			if !IsValid(const) then return false end

		end
	
		self:GetWeapon():SetNWEntity("PEPlus_Attacher_CurEntity", NULL)
		self:SetStage(0)
	
		return true

	end

end




function TOOL:Reload(trace)

	if IsValid(self:GetWeapon():GetNWEntity("PEPlus_Attacher_CurEntity")) then
		if SERVER then
			self:GetWeapon():SetNWEntity("PEPlus_Attacher_CurEntity", NULL)
			self:SetStage(0)
		end
		return true
	end

end




if CLIENT then

	function TOOL:DrawHUD()

		local pl = LocalPlayer()
		local tr = pl:GetEyeTrace()

		local ent = tr.Entity
		local sel = self:GetWeapon():GetNWEntity("PEPlus_Attacher_CurEntity")
		self.SelectedGripPoint = nil
		//Draw a halo around the selected entity
		if self:GetStage() > 0 and self:GetClientNumber("drawhalo") == 1 then
			local haloent = sel
			if IsValid(haloent) then
				local animcolor = 189 + math.cos( RealTime() * 4 ) * 17

				if haloent.PEPlus_Ent then
					//If our selected entity is a particle grip point, we can't draw a halo around the grip point model because it's scaled down to 0, and can't draw a halo around
					//the grip sprite because that just draws a square around it. Instead, tell the group point entity to draw a different sprite.
					if istable(haloent.ParticleInfo) then
						self.SelectedGripPoint = haloent.ParticleInfo[self:GetWeapon():GetNWInt("PEPlus_Attacher_CPoint")].ent
					end
				elseif haloent.PEPlus_SpecialEffect then
					self.SelectedGripPoint = haloent:GetSpecialEffectParent()
				else
					if IsValid(haloent.AttachedEntity) then haloent = haloent.AttachedEntity end
					halo.Add({haloent}, Color(255, 255, animcolor, 255), 2.3, 2.3, 1, true, false)
				end
			end
		end
		if self:GetStage() == 2 and IsValid(sel) then
			ent = sel
		end
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		if IsValid(ent) and !ent.PEPlus_Grip then
			self.HighlightedEnt = ent
			return
		end

		self.HighlightedEnt = nil
		
	end

	function TOOL:Holster()

		self.HighlightedEnt = nil
		self:GetWeapon():SetNWEntity("PEPlus_Attacher_CurEntity", NULL)
		self.SelectedGripPoint = nil

	end




	//All credit for the toolgun scroll wheel code goes to the Wiremod devs. You guys are the best.
		local function get_active_tool(ply, tool)
			-- find toolgun
			local activeWep = ply:GetActiveWeapon()
			if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end

			return activeWep:GetToolObject(tool)
		end

		local function hookfunc(ply, bind, pressed)
			if not pressed then return end
			if bind == "invnext" then
				local self = get_active_tool(ply, "peplus_attacher")
				if not self then return end
			
				return self:ScrollDown(ply:GetEyeTraceNoCursor())
			elseif bind == "invprev" then
				local self = get_active_tool(ply, "peplus_attacher")
				if not self then return end

				return self:ScrollUp(ply:GetEyeTraceNoCursor())
			end
		end
	
		if game.SinglePlayer() then -- wtfgarry (have to have a delay in single player or the hook won't get added)
			timer.Simple(5,function() hook.Add("PlayerBindPress", "peplus_attacher_playerbindpress", hookfunc) end)
		else
			hook.Add("PlayerBindPress", "peplus_attacher_playerbindpress", hookfunc)
		end
	//End shamefully copied code here.

	function TOOL:Scroll(trace, dir)
		if !IsValid(self.HighlightedEnt) then return end

		local attachcount = 0
		local tab = self.HighlightedEnt:GetAttachments()
		if istable(tab) then attachcount = table.Count(tab) end
		local oldattachnum = self:GetClientNumber("attachnum", 0)
		if oldattachnum > attachcount then oldattachnum = 0 end
		local attachnum = oldattachnum + dir

		if attachnum < 0 then attachnum = attachcount end
		if attachnum > attachcount then attachnum = 0 end
		RunConsoleCommand("peplus_attacher_attachnum", tostring(attachnum))
		surface.PlaySound("weapons/pistol/pistol_empty.wav")
		return true
	end
	function TOOL:ScrollUp(trace) return self:Scroll(trace, -1) end
	function TOOL:ScrollDown(trace) return self:Scroll(trace, 1) end

end




function TOOL:Think()

	if SERVER then
	
		if self:GetStage() != 0 and !IsValid(self:GetWeapon():GetNWEntity("PEPlus_Attacher_CurEntity")) then
			self:SetStage(0)
		end

	else

		local panel = controlpanel.Get("peplus_attacher")
		if !panel or !panel.effectlist then return end

		local ent = self:GetWeapon():GetNWEntity("PEPlus_Attacher_CurEntity")
		//Update the effectlist in the controlpanel if CurEntity has changed
		panel.CurEntity = panel.CurEntity or nil
		if panel.CurEntity != ent then
			panel.CurEntity = ent
			panel.effectlist.PopulateEffectList(ent)
		elseif panel.CurEntity != nil and !IsValid(panel.CurEntity) then
			//clear the list if selected ent becomes invalid
			panel.CurEntity = nil
			panel.effectlist.PopulateEffectList()
		end

	end

end




function TOOL.BuildCPanel(panel)

	panel:AddControl("Header", { Description = "#tool.peplus_attacher.help" })

	panel.effectlist = panel:AddControl("ListBox", {
		Label = "Attached Effects (click to open editor in context menu)", 
		Height = 100,
	})
	panel.effectlist.OnRowSelected = function() end  //get rid of the default OnRowSelected function created by the AddControl function
	panel.effectlist.PopulateEffectList = function(ent)
		panel.effectlist:Clear()
		if IsValid(ent) then
			local addedfx = false

			local function AddEffect(effectent)
				if !IsValid(effectent) or (!effectent.PEPlus_SpecialEffect and (!effectent.PEPlus_Ent or !effectent.GetParticleName)) then return end
				local str = effectent.PrintName
				if effectent.GetParticleName then str = effectent:GetParticleName() end
				local line = panel.effectlist:AddLine(str)
				line.OnSelect = function() OpenPEPlusEditor(effectent) line:SetSelected(false) end
				addedfx = true
			end

			if ent.PEPlus_Ent or ent.PEPlus_SpecialEffect then
				AddEffect(ent)
			else
				if istable(ent.PEPlus_ParticleEnts) then
					for k, _ in pairs (ent.PEPlus_ParticleEnts) do
						AddEffect(k)
					end
				end
			end

			if !addedfx then panel.effectlist:AddLine("(no effects attached to this entity)") end
		else
			panel.effectlist:AddLine("(no entity selected)")
		end
	end
	panel.effectlist.PopulateEffectList()

	panel:AddControl("Slider", {
		Label = "Attachment",
	 	Type = "Integer",
		Min = "0",
		Max = "16",
		Command = "peplus_attacher_attachnum",
	})

	panel:AddControl("Checkbox", {Label = "Draw selection halo", Command = "peplus_attacher_drawhalo"})

end