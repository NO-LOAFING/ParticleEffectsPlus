//Base entity for particle "special effects" like tracer and projectile effects.
//
//To avoid duplicate code (for particle/utilfx spawning, particleinfo tables, control window inputs, crash prevention, etc.), a special effect is simply a *manager* entity that makes use of 
//ordinary ent_partctrls parented to it, and manually commands them to start particles - those particles are still handled by ent_partctrl using the code it already has.
//
//For example, a tracer effect works by 1: performing a trace, 2: creating a point entity at the endpoint, 3: setting ent_partctrl.ParticleInfo[x].ent to the endpoint where applicable, 
//and then 4: running ent_partctrl:StartParticle.

AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.PrintName			= "Particle Controller - Special Effect Base"

ENT.Spawnable			= false
//ENT.RenderGroup		= RENDERGROUP_NONE

ENT.PartCtrl_SpecialEffect	= true




function ENT:Initialize()

	//self:SetNoDraw(true)
	self:DrawShadow(false) //make sure the ent's shadow doesn't render, just in case RENDERGROUP_NONE/SetNoDraw don't work and we have to rely on the blank draw function
	self:SetCollisionBounds(vector_origin,vector_origin) //stop this ent from bloating up duplicator bounds

	if SERVER then
		self:SetModel("models/props_junk/watermelon01.mdl") //dummy model to prevent addons that look for the error model from affecting this entity, should this be something smaller? do this serverside only so that effect funcs can override it.
		if !self.DoneFirstSpawn then
			self:SetPlayer(self:GetCreator())
			local g = ents.Create("ent_partctrl_grip")
			if !IsValid(g) then return end
			g:SetPos(self:GetPos())
			g:SetAngles(self:GetAngles())
			g:Spawn()
			constraint.PartCtrl_SpecialEffect(self, g, ply)
			self:SetSpecialEffectDefaults()
			self.DoneFirstSpawn = true
		end
	end

	if CLIENT then
		//Handle special effect parenting hierarchy ourselves instead of using the standard Set/GetParent funcs, because those can start erroneously returning NULL clientside
		//if we use advbonemerge to put an entity with an attached effect a couple rungs down in a parenting hierarchy (why? advbonemerge ents don't have this problem)
		self.SpecialEffectChildren = self.SpecialEffectChildren or {} //if a child is initialized before us, it'll create this table first
		self:OnSpecialEffectParentChanged(nil, nil, self:GetSpecialEffectParent()) //nwvar callbacks don't run when the value is set immediately upon spawning, so run it manually

		//For PostDrawTranslucentRenderables hook
		AllPartCtrlEnts = AllPartCtrlEnts or {}
		AllPartCtrlEnts[self] = true
		self.LastDrawn = 0
	end

	//Do effect-specific initialize
	if self.SpecialEffectInitialize then self:SpecialEffectInitialize() end

end




function ENT:Think()

	if CLIENT then self.cpoint_posang = nil end //Reset this value every think

	//Do effect-specific think
	if self.SpecialEffectThink then return self:SpecialEffectThink() end

end




function ENT:OnSpecialEffectParentChanged(_, old, new)

	if CLIENT then

		//Both this timer and the lines below it are needed to fix an issue with advbonemerge - if we advbonemerge a model with an attached special effect, this value will change before
		//the ent_advbonemerge becomes valid on the client, meaning it'll be a null entity here and we won't be able to do anything with it, like give it a PartCtrl_ParticleEnts list.
		timer.Simple(0.1, function()
			if !IsValid(self) then return end
			if !IsValid(new) then new = self:GetSpecialEffectParent() end
			//MsgN(self, " sfx parent changed from ", old, " to ", new, self:GetSpecialEffectParent())

			//If the parent entity changed, update stuff like properties and control panels
			//(Standard ent_partctrl does this upon a client receiving a particleinfo table update, but we don't have one of those)
			if IsValid(old) then
				//Remove us from the list of particles on the old ent
				if old.PartCtrl_ParticleEnts then
					old.PartCtrl_ParticleEnts[self] = nil
				end
			end
			//Refresh attacher tool effect list if this effect was removed from or added to the list
			local panel = controlpanel.Get("partctrl_attacher")
			if panel and panel.effectlist and (panel.CurEntity == old or panel.CurEntity == new) then
				panel.effectlist.PopulateEffectList(panel.CurEntity)
			end
			//Refresh control window if we changed something that requires the controls to be rebuilt
			if IsValid(self.PartCtrlWindow) and IsValid(self.PartCtrlWindow.SpecialEffect_AttachOptions) then
				self.PartCtrlWindow.SpecialEffect_AttachOptions.RebuildContents()
			end
			if IsValid(new) then
				//Store us in a list on the new ent (used by properties)
				new.PartCtrl_ParticleEnts = new.PartCtrl_ParticleEnts or {}
				new.PartCtrl_ParticleEnts[self] = true
			end
		end)

	end

	//Restart the effect
	if self.SpecialEffectRefresh then self:SpecialEffectRefresh() end

end




//Convenience func for cpoint location
function ENT:CPointPosAng()

	if CLIENT and self.cpoint_posang then return self.cpoint_posang end //server doesn't call this often enough to be worth caching and uncaching

	local ent = self:GetSpecialEffectParent()
	if IsValid(ent) then
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
			pos = ent:GetPos()
		end
		local res = {ang = ang, pos = pos}
		if CLIENT then self.cpoint_posang = res end
		return res
	end

end




if CLIENT then

	function ENT:Draw()

		//Instead of drawing the cpoint helpers ourselves, we tell our PostDrawTranslucentRenderables hook to do it, so that it always renders above particle effects
		self.LastDrawn = CurTime()

	end

	function ENT:DrawCPointHelpers()

		local window = IsValid(self.PartCtrlWindow) and g_ContextMenu:IsVisible()
		local ent = self:GetSpecialEffectParent()
		if IsValid(ent) then
			if window or ent.PartCtrl_Grip then //hide helpers when they're attached to other ents unless the window is open
				//Draw particle effect helpers (numbers showing cpoint id, arrows showing cpoint orientation)
				local p = self:CPointPosAng()
				if istable(p) then
					render.SetMaterial(partctrl_arrowmat)
					render.DrawBeam(p.pos + (p.ang:Forward() * -3.01), p.pos + (p.ang:Forward() * (20-3.01)), 20, 1, 0, color_white)

					local view = LocalPlayer():GetViewEntity()
					local camang = nil
					if view:IsPlayer() then
						camang = view:EyeAngles()
					else
						camang = view:GetAngles()
					end
					camang:RotateAroundAxis( camang:Up(), -90 )
					camang:RotateAroundAxis( camang:Forward(), 90 )
					cam.IgnoreZ(true)
					cam.Start3D2D(p.pos, camang, 0.125)
						draw.SimpleTextOutlined(self.PartCtrl_ShortName or self.PrintName,"PartCtrl_3D2DFont",0,-50,partctrl_colortext,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM,3,partctrl_colorborder)
					cam.End3D2D()
					cam.IgnoreZ(false)
				end
			end
		end

	end

end




function ENT:OnRemove()

	if CLIENT then
		//Remove us from the list of particles on our parent (used by properties)
		local ent = self:GetSpecialEffectParent()
		if IsValid(ent) and istable(ent.PartCtrl_ParticleEnts) then
			ent.PartCtrl_ParticleEnts[self] = nil
			//Refresh attacher tool effect list if this effect was removed from the list
			local panel = controlpanel.Get("partctrl_attacher")
			if panel and panel.effectlist and panel.CurEntity == ent then
				panel.effectlist.PopulateEffectList(panel.CurEntity)
			end
		end

		//For PostDrawTranslucentRenderables hook
		if istable(AllPartCtrlEnts) then
			AllPartCtrlEnts[self] = nil
		end
	end

	if self.SpecialEffectOnRemove then self:SpecialEffectOnRemove() end

end




if SERVER then

	function ENT:UpdateTransmitState()

		return TRANSMIT_ALWAYS

	end

	function ENT:AttachToEntity(ent, k, attach, ply, addundo) //k arg does nothing, but matches ent_partctrl

		if !IsValid(ent) then return false end

		local oldent = self:GetSpecialEffectParent()
		if !IsValid(oldent) then return false end
		local oldconst = nil
		local tab = constraint.FindConstraint(oldent, "PartCtrl_SpecialEffect")
		if istable(tab) and tab.Ent1 == self then
			oldconst = tab.Constraint
		else
			return false
		end
	
		//don't let us set attach to an attachment that the model doesn't have
		if IsValid(ent.AttachedEntity) then
			if !istable(ent.AttachedEntity:GetAttachment(attach)) then attach = 0 end 
		else
			if !istable(ent:GetAttachment(attach)) then attach = 0 end
		end
		self:SetAttachmentID(attach)

	
		//Detach the corresponding cpoint of the particle effect from the grip point we clicked on, then attach that cpoint to the new parent
		oldent:DontDeleteOnRemove(self)
		self:DontDeleteOnRemove(oldent)
		oldconst:RemoveCallOnRemove("PartCtrl_Ent_UnmergeOnUndo")
		oldconst:Remove()
		oldent:Remove()
		local const = constraint.PartCtrl_SpecialEffect(self, ent, ply)

		if addundo then
			//Add an undo entry
			undo.Create("PartCtrl_Ent")
				undo.AddEntity(const)  //the constraint entity will detach us upon being removed
				undo.SetPlayer(ply)
			undo.Finish("Attach " .. self.PrintName .. " to "  .. string.GetFileFromFilename(tostring(ent:GetModel())))
		end

		//Tell clients to retrieve the updated info table
		net.Start("PartCtrl_InfoTableUpdate_SendToCl")
			net.WriteEntity(self)
		net.Broadcast()

		return const

	end

	function ENT:DetachFromEntity(ply)
	
		local ent = self:GetSpecialEffectParent()
		if !IsValid(ent) then return false end

		//If the ent is an adv bonemerged grip point, then unmerge it instead
		if (ent.GetPartCtrl_MergedGrip and ent:GetPartCtrl_MergedGrip()) then
			if ent:Unmerge(ply) then
				ply:SendLua("GAMEMODE:AddNotify('#undone_AdvBonemerge', NOTIFY_UNDO, 2)")
				ply:SendLua("surface.PlaySound('buttons/button15.wav')")
			else
				ply:SendLua("GAMEMODE:AddNotify('Cannot unmerge this entity', NOTIFY_ERROR, 5)")
				ply:SendLua("surface.PlaySound('buttons/button11.wav')")
			end
			return nil
		end

		local oldconst = nil
		local tab = constraint.FindConstraints(ent, "PartCtrl_SpecialEffect")
		if istable(tab) then
			for k2, v2 in pairs (tab) do
				if v2.Ent1 == self then
					oldconst = v2.Constraint
				end
			end
		end
		if !IsValid(oldconst) then return false end

		local g = ents.Create("ent_partctrl_grip")
		if !IsValid(g) then return false end
		g:Spawn()

		local p = self:CPointPosAng()
		local _, bboxtop1 = ent:GetRotatedAABB(ent:GetCollisionBounds())
		local bboxtop2, _ = g:GetCollisionBounds()
		local height = bboxtop1.z + -bboxtop2.z + ent:GetPos().z
		g:SetPos(Vector(p.pos.x, p.pos.y, height))
		g:SetAngles(p.ang)

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
			Ent1:SetSpecialEffectParent(Ent2)

			if !(Ent2.PartCtrl_Grip or (Ent2.GetPartCtrl_MergedGrip and Ent2:GetPartCtrl_MergedGrip())) then
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
			Ent2:SetSpecialEffectParent(Ent1)

			if Ent1.DisableChildAutoplay then
				//Clear numpad and loop settings on children of sfx that handle these settings themselves, to prevent unwanted behavior
				//(the effect's numpad still working while it's attached; the effect's loop safety setting overriding the special effect's)
				numpad.Remove(Ent2.NumDown)
				numpad.Remove(Ent2.NumUp)
				Ent2:SetNumpad(0)
				Ent2:SetNumpadToggle(true)
				Ent2:SetNumpadStartOn(true)
				Ent2:SetNumpadState(false)
				Ent2.NumpadKeyDown = false
				Ent2:SetNumpadMode(0)
				Ent2:SetLoopSafety(false)
			end
			//Always clear pause settings on children of sfx (sfx will handle pausing themselves, we don't want the child fx pausing on their own)
			Ent2:SetPauseTime(-1)
			if Ent2:GetNumpadMode() == 1 then Ent2:SetNumpadMode(0) end

			//If the constraint is removed by an Undo, unmerge the second entity - this shouldn't do anything if the constraint's removed some other way i.e. one of the ents is removed
			timer.Simple(0.1, function()  //CallOnRemove won't do anything if we try to run it now instead of on a timer
				if const:GetTable() then  //CallOnRemove can error if this table doesn't exist - this can happen if the constraint is removed at the same time it's created for some reason
					const:CallOnRemove("PartCtrl_Ent_UnmergeOnUndo", function(const,Ent2,ply)
						//MsgN("PartCtrl_Ent_UnmergeOnUndo called by constraint ", const, ", ents ", Ent1, " ", Ent2)
						//NOTE: if we use the remover tool to get rid of ent1, it'll still be valid for a second, so we need to look for the NoDraw and MoveType that the tool sets the ent to instead.
						//this might have a few false positives, but i don't think that many people will be attaching stuff to invisible, intangible ents a whole lot anyway so it's not a huge deal
						if !IsValid(const) or !IsValid(Ent1) or Ent1:IsMarkedForDeletion() or (Ent1:GetNoDraw() == true and Ent1:GetMoveType() == MOVETYPE_NONE) or !IsValid(Ent2) or Ent2:IsMarkedForDeletion() or !IsValid(ply) or !Ent2.DetachFromSpecialEffect then return end
						Ent2:DetachFromSpecialEffect(ply)
					end, Ent2, ply)
				end
			end)

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

			//if input == "attachment_ent_setwithtool" then
			
			//elseif input == "attachment_ent_detach" then
				
			if input == "attachment_attach" then

				net.WriteUInt(args[1], 8) //new attachment id; don't know what the max attachment number is, assume 255
			
			//elseif input == "child_setwithtool" then
			
			elseif input == "child_detach" then
	
				net.WriteEntity(args[1]) //child entity to remove

			elseif input == "effect_pause" and !self.CustomPauseInput then

				if self:GetPauseTime() < 0 and self.ParticleStartTime then
					//not paused, so pause it at the current time
					net.WriteFloat(CurTime() - self.ParticleStartTime)
					//pause the effect immediately, don't wait for the pausetime nwvar to be networked back to us
					self:SetPauseTime(CurTime() - self.ParticleStartTime)
				else
					//paused, so unpause it
					net.WriteFloat(-1)
					self:SetPauseTime(-1)
				end
	
			end

			if self.SpecialEffectDoInput then self:SpecialEffectDoInput(input, args) end

		net.SendToServer()

	end

	net.Receive("PartCtrl_SpecialEffect_Refresh_SendToCl", function()
		local ent = net.ReadEntity()
		if !IsValid(ent) or !ent.PartCtrl_SpecialEffect then return end

		if ent.SpecialEffectRefresh then ent:SpecialEffectRefresh() end
	end)
	
else

	util.AddNetworkString("PartCtrl_SpecialEffect_EditMenuInput_SendToSv")
	util.AddNetworkString("PartCtrl_SpecialEffect_Refresh_SendToCl")

	//Respond to inputs from the clientside edit menu
	net.Receive("PartCtrl_SpecialEffect_EditMenuInput_SendToSv", function(_, ply)

		local self = net.ReadEntity()
		if !IsValid(self) or !self.PartCtrl_SpecialEffect then return end

		local input = net.ReadUInt(self.EditMenuInputs_bits)
		if !input then return end
		input = table.KeyFromValue(self.EditMenuInputs, input)

		local refreshtable = false

		if input == "attachment_ent_setwithtool" then

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

		elseif input == "attachment_ent_detach" then

			//Send a notification to the player saying whether or not we managed to detach the particle
			local detach = self:DetachFromEntity(ply)
			if detach == true then
				ply:SendLua("GAMEMODE:AddNotify('#undone_PartCtrl_Ent', NOTIFY_UNDO, 2)")
				ply:SendLua("surface.PlaySound('buttons/button15.wav')")
			elseif detach == false then
				ply:SendLua("GAMEMODE:AddNotify('Failed to detach particle', NOTIFY_ERROR, 5)")
				ply:SendLua("surface.PlaySound('buttons/button11.wav')")
			end
			//don't refresh table, DetachFromEntity handles this
			
		elseif input == "attachment_attach" then

			local new = net.ReadUInt(8)

			self:SetAttachmentID(new)
			refreshtable = true
		
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

			local child = net.ReadEntity()
			if IsValid(child) and child.PartCtrl_Ent and child:GetSpecialEffectParent() == self then
				//Send a notification to the player saying whether or not we managed to detach the particle
				local detach = child:DetachFromSpecialEffect(ply)
				if detach == true then
					ply:SendLua("GAMEMODE:AddNotify('#undone_PartCtrl_Ent', NOTIFY_UNDO, 2)")
					ply:SendLua("surface.PlaySound('buttons/button15.wav')")
				elseif detach == false then
					ply:SendLua("GAMEMODE:AddNotify('Failed to detach particle', NOTIFY_ERROR, 5)")
					ply:SendLua("surface.PlaySound('buttons/button11.wav')")
				end
				//don't refresh table, DetachFromSpecialEffect handles this
			end

		elseif input == "effect_pause" and !self.CustomPauseInput then
			
			self:SetPauseTime(net.ReadFloat())

		elseif input == "effect_restart" then
			
			refreshtable = true

		end

		if self.SpecialEffectDoInput then 
			refreshtable = refreshtable or self:SpecialEffectDoInput(input, ply)
		end

		if refreshtable then
			//Refresh special effect on server
			if self.SpecialEffectRefresh then self:SpecialEffectRefresh() end
			//Tell clients to refresh the special effect
			net.Start("PartCtrl_SpecialEffect_Refresh_SendToCl")
				net.WriteEntity(self)
			net.Broadcast()
		end

	end)

end




//For blank variants in spawnmenu

function PartCtrl_AddBlankSpecialEffect(enttab)

	local class = string.TrimLeft(enttab.Folder, "entities/")
	if !class or class == "" then return end

	scripted_ents.Register({
		Base = class,
		Spawnable = enttab.Spawnable,
		Category = enttab.Category,
		Information = enttab.Information,
		PrintName = enttab.PrintName .. " (blank)",
		IconOverride = "entities/"..class..".png",
		IsBlank = true,
		SpawnFunction = function(self, ply, tr, ClassName)
			//spawn the same entity as the non-blank version; the only difference is that it'll have IsBlank set to true below
			return scripted_ents.GetMember(class, "SpawnFunction")(self, ply, tr, class)
		end
	}, class .. "_blank")

end

if SERVER then

	function ENT:SpawnFunction(ply, tr, ClassName)

		if (!tr.Hit) then return end

		local SpawnPos = tr.HitPos + tr.HitNormal * 10
		local SpawnAng = ply:EyeAngles()
		SpawnAng.p = 0
		SpawnAng.y = SpawnAng.y + 180

		local ent = ents.Create(ClassName)
		ent:SetCreator(ply)
		ent:SetPos(SpawnPos)
		ent:SetAngles(SpawnAng)
		ent.IsBlank = self.IsBlank //this is the only functional change from base_entity's SpawnFunction; used by blank variants
		ent:Spawn()
		ent:Activate()

		ent:DropToFloor()

	return ent

end

end