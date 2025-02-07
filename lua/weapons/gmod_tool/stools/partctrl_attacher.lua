TOOL.Category = "Render"
TOOL.Name = "Particle Attacher"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["attachnum"] = "0"
TOOL.ClientConVar["drawhalo"] = "1"

TOOL.Information = {
	{name = "left0", stage = 0, icon = "gui/lmb.png"},
	{name = "left1", stage = 1, icon = "gui/lmb.png"},
	{name = "left2", stage = 2, icon = "gui/lmb.png"},
	{name = "leftuse0", stage = 0, icon = "gui/lmb.png", icon2 = "gui/e.png"},
	{name = "leftuse1", stage = 1, icon = "gui/lmb.png", icon2 = "gui/e.png"},
	{name = "middle012", icon = "gui/mmb.png"},
	{name = "reload1", stage = 1, icon = "gui/r.png"},
	{name = "reload2", stage = 2, icon = "gui/r.png"},
}

if CLIENT then
	language.Add("tool.partctrl_attacher.name", "Particle Attacher")
	language.Add("tool.partctrl_attacher.desc", "Attach particle effects to models")
	language.Add("tool.partctrl_attacher.help", "Particles are used for all sorts of different special effects. You can spawn them from the spawn menu, and then attach them to models with this tool.")

	language.Add("tool.partctrl_attacher.left0", "Select a particle to attach, or select a model to attach a particle to")
	language.Add("tool.partctrl_attacher.left1", "Now select a model to attach the particle to")
	language.Add("tool.partctrl_attacher.left2", "Now select a particle to attach to the model")
	language.Add("tool.partctrl_attacher.leftuse0", "Select yourself")
	language.Add("tool.partctrl_attacher.leftuse1", "Select yourself")
	language.Add("tool.partctrl_attacher.middle012", "Scroll through a model's attachments")
	language.Add("tool.partctrl_attacher.reload1", "Deselect particle and cancel")
	language.Add("tool.partctrl_attacher.reload2", "Deselect model and cancel")

	language.Add("undone_PartCtrl_Ent", "Undone Attach Particle Effect")
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
			if ent.PartCtrl_Grip then
				if CLIENT then
					local tab = ent.PartCtrl_ParticleEnts
					if istable(tab) then
						for k, _ in pairs (tab) do //a grip point entity should only have a single associated particle
							if IsValid(k) and k:GetClass() == "ent_partctrl" then
								return true
							end
						end
					end
				else
					local tab = constraint.FindConstraint(ent, "PartCtrl_Ent")
					if istable(tab) and IsValid(tab.Ent1) and tab.Ent1:GetClass() == "ent_partctrl" then
						self:GetWeapon():SetNWInt("PartCtrl_Attacher_CPoint", tab.CPoint)
						self:GetWeapon():SetNWEntity("PartCtrl_Attacher_CurEntity", tab.Ent1)
						self:SetStage(1)
						return true
					end
				end
			else
				if SERVER then
					self:GetWeapon():SetNWEntity("PartCtrl_Attacher_CurEntity", ent)
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
		if stage == 1 then //Stage 1: selected a particle, then clicked on a model
			ent = trace.Entity
			if trace.Entity.PartCtrl_Grip then return false end
			p = self:GetWeapon():GetNWEntity("PartCtrl_Attacher_CurEntity")
			k = self:GetWeapon():GetNWInt("PartCtrl_Attacher_CPoint")
		elseif stage == 2 then //Stage 2: selected a model, then clicked on a particle
			ent = self:GetWeapon():GetNWEntity("PartCtrl_Attacher_CurEntity")
			if !trace.Entity.PartCtrl_Grip then return false end
			if CLIENT then
				local tab = trace.Entity.PartCtrl_ParticleEnts
				if istable(tab) then
					for k2, _ in pairs (tab) do //a grip point entity should only have a single associated particle
						if IsValid(k2) and k2:GetClass() == "ent_partctrl" then
							p = k2
							//don't worry about k for clients
						end
					end
				end
			else
				local tab = constraint.FindConstraint(trace.Entity, "PartCtrl_Ent")
				if istable(tab) and IsValid(tab.Ent1) and tab.Ent1:GetClass() == "ent_partctrl" then
					p = tab.Ent1
					k = tab.CPoint
				else
					return false
				end
			end
		end
	
		if !IsValid(ent) or !IsValid(p) or !istable(p.ParticleInfo) or !istable(p.ParticleInfo[k]) or PartCtrl_ProcessedPCFs[p:GetPCF()][p:GetParticleName()].cpoints[k].mode != PARTCTRL_CPOINT_MODE_POSITION then return false end
		if CLIENT then return true end
	
		local oldent = p.ParticleInfo[k].ent
		local oldconst = nil
		local doparent = false
		local tab = constraint.FindConstraint(oldent, "PartCtrl_Ent")
		if istable(tab) and IsValid(tab.Ent1) and tab.Ent1:GetClass() == "ent_partctrl" then
			oldconst = tab.Constraint
			doparent = tab.DoParent
		else
			return false
		end
	
		//p.ParticleInfo[k].ent = ent //the constraint function already does this
		local attach = self:GetClientNumber("attachnum", 0)
		//don't let us set attach to an attachment that the model doesn't have
		if IsValid(ent.AttachedEntity) then
			if !istable(ent.AttachedEntity:GetAttachment(attach)) then attach = 0 end 
		else
			if !istable(ent:GetAttachment(attach)) then attach = 0 end
		end
		p.ParticleInfo[k].attach = attach
	
		oldent:DontDeleteOnRemove(p)
		p:DontDeleteOnRemove(oldent)
		oldconst:RemoveCallOnRemove("PartCtrl_Ent_UnmergeOnUndo")
		oldconst:Remove()
		oldent:Remove()
		local const = constraint.PartCtrl_Ent(p, ent, k, doparent, self:GetOwner())

		//Add an undo entry
		undo.Create("PartCtrl_Ent")
			undo.AddEntity(const)  //the constraint entity will unmerge newent upon being removed
			undo.SetPlayer(self:GetOwner())
		undo.Finish("Attach Particle Effect " .. tostring(p:GetParticleName()) .. " to "  .. tostring(ent:GetModel()))
	
		//Tell clients to retrieve the updated info table
		net.Start("PartCtrl_InfoTableUpdate_SendToCl")
			net.WriteEntity(p)
		net.Broadcast()
	
		self:GetWeapon():SetNWEntity("PartCtrl_Attacher_CurEntity", NULL)
		self:SetStage(0)
	
		return true

	end

end




function TOOL:Reload(trace)

	if IsValid(self:GetWeapon():GetNWEntity("PartCtrl_Attacher_CurEntity")) then
		if SERVER then
			self:GetWeapon():SetNWEntity("PartCtrl_Attacher_CurEntity", NULL)
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
		local sel = self:GetWeapon():GetNWEntity("PartCtrl_Attacher_CurEntity")
		self.SelectedGripPoint = nil
		//Draw a halo around the selected entity
		if self:GetStage() > 0 and self:GetClientNumber("drawhalo") == 1 then
			local haloent = sel
			if IsValid(haloent) then
				local animcolor = 189 + math.cos( RealTime() * 4 ) * 17

				if haloent:GetClass() == "ent_partctrl" then
					//If our selected entity is a particle grip point, we can't draw a halo around the grip point model because it's scaled down to 0, and can't draw a halo around
					//the grip sprite because that just draws a square around it. Instead, tell the group point entity to draw a different sprite.
					if istable(haloent.ParticleInfo) then
						self.SelectedGripPoint = haloent.ParticleInfo[self:GetWeapon():GetNWInt("PartCtrl_Attacher_CPoint")].ent
					end
				else
					if IsValid(haloent.AttachedEntity) then haloent = haloent.AttachedEntity end
					halo.Add( {haloent}, Color(255, 255, animcolor, 255), 2.3, 2.3, 1, true, false )
				end
			end
		end
		if self:GetStage() == 2 and IsValid(sel) then
			ent = sel
		end
		if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
		if IsValid(ent) and !ent.PartCtrl_Grip then
			self.HighlightedEnt = ent
			return
		end

		self.HighlightedEnt = nil
		
	end

	function TOOL:Holster()

		self.HighlightedEnt = nil
		self:GetWeapon():SetNWEntity("PartCtrl_Attacher_CurEntity", NULL)
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
				local self = get_active_tool(ply, "partctrl_attacher")
				if not self then return end
			
				return self:ScrollDown(ply:GetEyeTraceNoCursor())
			elseif bind == "invprev" then
				local self = get_active_tool(ply, "partctrl_attacher")
				if not self then return end

				return self:ScrollUp(ply:GetEyeTraceNoCursor())
			end
		end
	
		if game.SinglePlayer() then -- wtfgarry (have to have a delay in single player or the hook won't get added)
			timer.Simple(5,function() hook.Add("PlayerBindPress", "partctrl_attacher_playerbindpress", hookfunc) end)
		else
			hook.Add("PlayerBindPress", "partctrl_attacher_playerbindpress", hookfunc)
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
		RunConsoleCommand("partctrl_attacher_attachnum", tostring(attachnum))
		surface.PlaySound("weapons/pistol/pistol_empty.wav")
		return true
	end
	function TOOL:ScrollUp(trace) return self:Scroll(trace, -1) end
	function TOOL:ScrollDown(trace) return self:Scroll(trace, 1) end

end




function TOOL:Think()

	if SERVER then
	
		if self:GetStage() != 0 and !IsValid(self:GetWeapon():GetNWEntity("PartCtrl_Attacher_CurEntity")) then
			self:SetStage(0)
		end

	else

		local panel = controlpanel.Get("partctrl_attacher")
		if !panel or !panel.effectlist then return end

		local ent = self:GetWeapon():GetNWEntity("PartCtrl_Attacher_CurEntity")
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

	panel:AddControl("Header", { Description = "#tool.partctrl_attacher.help" })

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
				if !IsValid(effectent) or effectent:GetClass() != "ent_partctrl" or !effectent.GetParticleName then return end
				local line = panel.effectlist:AddLine(effectent:GetParticleName())
				line.OnSelect = function() OpenPartCtrlEditor(effectent) line:SetSelected(false) end
				addedfx = true
			end

			if ent:GetClass() == "ent_partctrl" then
				AddEffect(ent)
			else
				if istable(ent.PartCtrl_ParticleEnts) then
					for k, _ in pairs (ent.PartCtrl_ParticleEnts) do
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
		Command = "partctrl_attacher_attachnum",
	})

	panel:AddControl("Checkbox", {Label = "Draw selection halo", Command = "partctrl_attacher_drawhalo"})

end