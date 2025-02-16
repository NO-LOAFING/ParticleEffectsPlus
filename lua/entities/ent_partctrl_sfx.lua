AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.PrintName			= "Particle Controller - Special Effect Base"
ENT.Author			= ""

ENT.Spawnable			= false
//ENT.RenderGroup		= RENDERGROUP_NONE

ENT.PartCtrl_SpecialEffect	= true




function ENT:Initialize()

	if SERVER then
		if !self.DoneFirstSpawn then
			local g = ents.Create("ent_partctrl_grip")
			if !IsValid(g) then return end
			g:SetPos(self:GetPos())
			g:SetAngles(self:GetAngles())
			g:Spawn()
			constraint.PartCtrl_SpecialEffect(self, g, ply)
			self:SetNWVarDefaults()
			self.DoneFirstSpawn = true
		end
	end

	//self:SetNoDraw(true)
	self:SetModel("models/props_junk/watermelon01.mdl") //dummy model to prevent addons that look for the error model from affecting this entity, should this be something smaller?
	self:DrawShadow(false) //make sure the ent's shadow doesn't render, just in case RENDERGROUP_NONE/SetNoDraw don't work and we have to rely on the blank draw function
	self:SetCollisionBounds(vector_origin,vector_origin) //stop this ent from bloating up duplicator bounds

	self.PartCtrl_SpecialEffect_ChildFX = {}
	//TODO: figure out how we want the duplicator to treat this

	//TODO: do numpad stuff once we implement the tracer effect
	--[[if SERVER then
		self:SetNumpadState(false) //Numpad state should always start off as false
		//Different from NumpadState. This value is always true when the key is held down and false when it's not, even if the numpad state is set to toggle instead.
		//Used when changing the numpadkey or numpadtoggle vars to make sure stuff doesn't cause problems.
		self.NumpadKeyDown = false
		//Set up numpad functions
		local ply = self:GetPlayer() //NOTE: this still works if ply doesn't exist
		local key = self:GetNumpad()
		self.NumDown = numpad.OnDown(ply, key, "PartCtrl_Numpad", self, true)
		self.NumUp = numpad.OnUp(ply, key, "PartCtrl_Numpad", self, false)
	end]]

	if CLIENT then
		AllPartCtrlEnts = AllPartCtrlEnts or {}
		AllPartCtrlEnts[self] = true
		self.LastDrawn = 0
	end

end




function ENT:Think()

	if CLIENT then

		//If the parent entity changed, update stuff like properties and control panels
		//(Standard ent_partctrl does this upon a client receiving a particleinfo table update, but we don't have one of those)
		local ent = self:GetParent()
		if self.LastParent != ent then
			if IsValid(self.LastParent) then
				//Remove us from the list of particles on the old ent
				if self.LastParent.PartCtrl_ParticleEnts then
					self.LastParent.PartCtrl_ParticleEnts[self] = nil
				end
			end
			//Refresh attacher tool effect list if this effect was removed from or added to the list
			local panel = controlpanel.Get("partctrl_attacher")
			if panel and panel.effectlist and (panel.CurEntity == self.LastParent or panel.CurEntity == ent) then
				panel.effectlist.PopulateEffectList(panel.CurEntity)
			end
			//TODO: window stuff
			--[[local window = IsValid(self.PartCtrlWindow) and istable(self.PartCtrlWindow.CPointCategories)
			//Refresh control window if we changed something that requires the controls to be rebuilt
			if window then
				self.PartCtrlWindow.CPointCategories[k].RebuildContents(self.ParticleInfo[k])
			end]]
			if IsValid(ent) then
				//Store us in a list on the new ent (used by properties)
				ent.PartCtrl_ParticleEnts = ent.PartCtrl_ParticleEnts or {}
				ent.PartCtrl_ParticleEnts[self] = true
				self.LastParent = ent
			end
		end

		//Do effect-specific think
		self:SpecialEffectThink()

	end

end




if CLIENT then

	function ENT:Draw()
		//Instead of drawing the cpoint helpers ourselves, we tell our PostDrawTranslucentRenderables hook to do it, so that it always renders above particle effects
		self.LastDrawn = CurTime()
	end

	function ENT:DrawCPointHelpers()

		local window = IsValid(self.PartCtrlWindow) and g_ContextMenu:IsVisible()
		local ent = self:GetParent()
		if IsValid(ent) then
			if window or ent.PartCtrl_Grip then //hide helpers when they're attached to other ents unless the window is open
				//Draw particle effect helpers (numbers showing cpoint id, arrows showing cpoint orientation)
				local pos = nil
				local ang = nil
				if IsValid(ent.AttachedEntity) then
					pos = ent.AttachedEntity:GetAttachment(self:GetAttachmentID())
				else
					pos = ent:GetAttachment(self:GetAttachmentID())
				end
				if istable(pos) then
					ang = pos.Ang
					pos = pos.Pos
				else
					ang = ent:GetAngles()
					pos = ent:GetPos() //+ self.ParticleInfo[k].pos
				end

				render.SetMaterial(partctrl_arrowmat)
				render.DrawBeam(pos, pos + (ang:Forward() * 20), 20, 1, 0, color_white)

				//TODO: this doesn't render through walls like the arrows or grips do, is there a better way than 3D2D to make text that resizes nicely like this?
				local view = LocalPlayer():GetViewEntity()
				local camang = nil
				if view:IsPlayer() then
					camang = view:EyeAngles()
				else
					camang = view:GetAngles()
				end
				camang:RotateAroundAxis( camang:Up(), -90 )
				camang:RotateAroundAxis( camang:Forward(), 90 )
				cam.Start3D2D(pos, camang, 0.125)
					draw.SimpleTextOutlined(self.PartCtrl_ShortName or self.PrintName,"PartCtrl_3D2DFont",0,-50,partctrl_colortext,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM,3,partctrl_colorborder)
				cam.End3D2D()
			end
		end

	end

	function ENT:OnRemove()

		//Remove us from the list of particles on our parent (used by properties)
		local ent = self:GetParent()
		if IsValid(ent) and istable(ent.PartCtrl_ParticleEnts) then
			ent.PartCtrl_ParticleEnts[self] = nil
			//Refresh attacher tool effect list if this effect was removed from the list
			local panel = controlpanel.Get("partctrl_attacher")
			if panel and panel.effectlist and panel.CurEntity == ent then
				panel.effectlist.PopulateEffectList(panel.CurEntity)
			end
		end

	end

end




if SERVER then

	function ENT:DetachFromEntity(ply)
	
		local ent = self:GetParent()
		if !IsValid(ent) then return end

		local oldconst = nil
		local tab = constraint.FindConstraints(ent, "PartCtrl_SpecialEffect")
		if istable(tab) then
			for k2, v2 in pairs (tab) do
				if v2.Ent1 == self then
					oldconst = v2.Constraint
				end
			end
		end
		if !IsValid(oldconst) then return end

		local g = ents.Create("ent_partctrl_grip")
		if !IsValid(g) then return end
		g:Spawn()

		local ang = nil
		local pos = nil
		if IsValid(ent.AttachedEntity) then
			pos = ent.AttachedEntity:GetAttachment(self:GetAttachmentID())
		else
			pos = ent:GetAttachment(self:GetAttachmentID())
		end
		if istable(pos) then
			ang = pos.Ang
			pos = pos.Pos
		else
			ang = ent:GetAngles()
			pos = ent:GetPos()
		end
		local _, bboxtop1 = ent:GetRotatedAABB(ent:GetCollisionBounds())
		local bboxtop2, _ = g:GetCollisionBounds()
		local height = bboxtop1.z + -bboxtop2.z + ent:GetPos().z
		g:SetPos(Vector(pos.x, pos.y, height))
		g:SetAngles(ang)

		self:SetAttachmentID(0)

		oldconst:RemoveCallOnRemove("PartCtrl_Ent_UnmergeOnUndo")
		oldconst:Remove()
		ent:DontDeleteOnRemove(self)
		constraint.PartCtrl_SpecialEffect(self, g, ply)


		return true

	end
	
	//Constraint, used to keep entities associated together between dupes/saves
	function constraint.PartCtrl_SpecialEffect(Ent1, Ent2, ply)

		if !Ent1 or !Ent2 or !Ent1.PartCtrl_SpecialEffect then return end
		
		//create a dummy ent for the constraint functions to use
		local const = ents.Create("info_target")
		const:Spawn()
		const:Activate()

		if !Ent2.PartCtrl_Ent then

			//This constraint is associating the special effect with its parent entity, so parent the former to the latter

			Ent1:SetPos(Ent2:GetPos())
			Ent1:SetAngles(Ent2:GetAngles())
			Ent1:SetParent(Ent2)

			if !Ent2.PartCtrl_Grip then
				//If the constraint is removed by an Undo, unmerge the second entity - this shouldn't do anything if the constraint's removed some other way i.e. one of the ents is removed
				timer.Simple(0.1, function()  //CallOnRemove won't do anything if we try to run it now instead of on a timer
					if const:GetTable() then  //CallOnRemove can error if this table doesn't exist - this can happen if the constraint is removed at the same time it's created for some reason
						const:CallOnRemove("PartCtrl_Ent_UnmergeOnUndo", function(const,Ent1,ply)
							//MsgN("PartCtrl_Ent_UnmergeOnUndo called by constraint ", const, ", ents ", Ent1, " ", Ent2)
							//NOTE: if we use the remover tool to get rid of ent2, it'll still be valid for a second, so we need to look for the NoDraw and MoveType that the tool sets the ent to instead.
							//this might have a few false positives, but i don't think that many people will be attaching stuff to invisible, intangible ents a whole lot anyway so it's not a huge deal
							if !IsValid(const) or !IsValid(Ent2) or Ent2:IsMarkedForDeletion() or (Ent2:GetNoDraw() == true and Ent2:GetMoveType() == MOVETYPE_NONE) or !IsValid(Ent1) or Ent1:IsMarkedForDeletion() or !IsValid(ply) or !Ent1.DetachFromEntity then return end
							Ent1:DetachFromEntity(ply)
						end, Ent1, ply)
					end
				end)
			else
				Ent1:DeleteOnRemove(Ent2)
			end
			Ent2:DeleteOnRemove(Ent1)

		else
			
			//This constraint is associating the special effect with a child ent_partctrl, so parent the latter to the former

			Ent2:SetPos(Ent1:GetPos())
			Ent2:SetAngles(Ent1:GetAngles())
			Ent2:SetParent(Ent1)

			Ent1:DeleteOnRemove(Ent2)

		end



		constraint.AddConstraintTable(Ent1, const, Ent2)
		
		local ctable = {
			Type = "PartCtrl_SpecialEffect",
			Ent1 = Ent1,
			Ent2 = Ent2,
			ply = ply,
		}
	
		const:SetTable(ctable)
	
		return const
		
	end
	duplicator.RegisterConstraint("PartCtrl_SpecialEffect", constraint.PartCtrl_SpecialEffect, "Ent1", "Ent2", "ply")

end




//Networking for edit menu inputs
//Note that each child class defines its own list of inputs
if CLIENT then

	function ENT:DoInput(input, ...)

		net.Start("PartCtrl_SpecialEffect_EditMenuInput_SendToSv")

			net.WriteEntity(self)
			local args = {...}

			net.WriteUInt(self.EditMenuInputs[input], self.EditMenuInputs_bits)

			if input == "self_parent_setwithtool" then
			//TODO: self-attachment inputs
			--[[elseif input == "self_parent_detach" then
				
			elseif input == "self_attach" then]]
			
			//elseif input == "child_setwithtool" then
			
			elseif input == "child_detach" then
	
				net.WriteEntity(args[1]) //child entity to remove
	
			end

			//TODO: handle entity-specific inputs

		net.SendToServer()

	end
	
else

	util.AddNetworkString("PartCtrl_SpecialEffect_EditMenuInput_SendToSv")

	//Respond to inputs from the clientside edit menu
	net.Receive("PartCtrl_SpecialEffect_EditMenuInput_SendToSv", function(_, ply)

		local self = net.ReadEntity()
		if !IsValid(self) or !self.PartCtrl_SpecialEffect then return end

		local input = net.ReadUInt(self.EditMenuInputs_bits)
		if !input then return end
		input = table.KeyFromValue(self.EditMenuInputs, input)

		if input == "self_parent_setwithtool" then
		//TODO: self-attachment inputs		
		--[[elseif input == "self_parent_detach" then
			
		elseif input == "self_attach" then]]
		
		elseif input == "child_setwithtool" then

			if !IsValid(ply) then return end
			if !GetConVar("toolmode_allow_partctrl_attacher"):GetBool() then return end //TODO: this was copied from advbonemerge, which also does a CanTool check with a fake trace. is that necessary here?

			local tool = ply:GetTool("partctrl_attacher")
			if !istable(tool) or !IsValid(tool:GetWeapon()) then return end

			ply:ConCommand("gmod_tool partctrl_attacher")
			//Fix: The tool's holster function clears the nwentity, and if this is already the toolgun's selected tool, it'll "holster" the tool before "deploying" it again.
			//To make this worse, it's different if the toolgun is the active weapon or not (if active, it holsters then deploys; if not active, it deploys, holsters, then deploys again)
			//so instead of having to deal with any of that, just set the entity on a delay so we're sure the tool is already done equipping.
			timer.Simple(0.1, function()
				if !IsValid(self) or !IsValid(ply) then return end
				tool:GetWeapon():SetNWEntity("PartCtrl_Attacher_CurEntity", self)
				tool:SetStage(3)
			end)
		
		elseif input == "child_detach" then

			//TODO: child detach input

		end

		//TODO: handle entity-specific inputs

	end)

end

