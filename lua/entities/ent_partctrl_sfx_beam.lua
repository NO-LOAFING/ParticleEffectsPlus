AddCSLuaFile()

ENT.Base 			= "ent_partctrl_sfx"
ENT.PrintName			= "Pointer Effect"
ENT.Category			= "Particle Effects"
ENT.Information			= "Makes particle effects work like a laser pointer, with one end where the \"beam\" starts, and the other end continuously moving to where it's pointing."

ENT.Spawnable			= true

ENT.PartCtrl_ShortName		= "Pointer"
ENT.SpecialEffectRoles		= {
	[0] = "Start point",
	[1] = "Hit point",
}
ENT.DisableChildAutoplay	= false //all this effect does is move around a single target point, so let child fx handle repeat/numpad stuff themselves




function ENT:SetupDataTables()

	//all special fx must have these ones
	self:NetworkVar("Int", 0, "AttachmentID")
	self:NetworkVar("Entity", 0, "SpecialEffectParent")
	if CLIENT then
		self:NetworkVarNotify("SpecialEffectParent", self.OnSpecialEffectParentChanged)
	end

	self:NetworkVar("Int", 1, "BeamDir")

end




function ENT:SetNWVarDefaults()

	self:SetAttachmentID(0) //all special fx must have this one

	self:SetBeamDir(0)

end




function ENT:SpecialEffectDefaultRoles(cpoints)

	//First half of the cpoints default to the start, second half of the cpoints default to the end.
	//This means fx with 2 cpoints will automatically connect the first to the start, and the second to the end,
	//and fx with only 1 cpoint will automatically connect to the end to better demonstrate the effect.
	local results = {}
	for k, cpoint in pairs (cpoints) do
		if k > (#cpoints/2) then
			results[cpoint] = 1
		else
			results[cpoint] = 0
		end
	end
	return results

end




if CLIENT then

	function ENT:SpecialEffectAddControls(window, container)

		local ent = self
		local padding = window.padding

		local cat = vgui.Create("DCollapsibleCategory", container)
		cat:SetLabel("Pointer Effect Settings")
		cat:DockMargin(3,1,-2,3) //-2 right for divider
		cat:Dock(FILL)
		container:AddItem(cat)

		local rpnl = vgui.Create("DSizeToContents", cat)
		rpnl:Dock(FILL)
		cat:SetContents(rpnl)
		rpnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
		rpnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
		rpnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents

		//filler to ensure pnl is stretched to full width
		local filler = vgui.Create("Panel", rpnl)
		filler:Dock(TOP)
		filler:SetHeight(0)


		local drop = vgui.Create("Panel", rpnl)
		
		drop.Label = vgui.Create("DLabel", drop)
		drop.Label:SetDark(true)
		drop.Label:SetText("Pointer Direction")
		drop.Label:Dock(LEFT)

		drop.Combo = vgui.Create("DComboBox", drop)
		drop.Combo:SetHeight(25)
		drop.Combo:Dock(FILL)

		local dir0 = "Forward"
		local dir1 = "Right"
		local dir2 = "Up"
		local val = ent:GetBeamDir() or 0
		if val == 0 then
			drop.Combo:SetValue(dir0)
		elseif val == 1 then
			drop.Combo:SetValue(dir1)
		elseif val == 2 then
			drop.Combo:SetValue(dir2)
		end
		drop.Combo:AddChoice(dir0, 0)
		drop.Combo:AddChoice(dir1, 1)
		drop.Combo:AddChoice(dir2, 2)
		function drop.Combo.OnSelect(_, index, value, data)
			ent:DoInput("beam_dir", data)
		end

		drop:SetHeight(25)
		drop:Dock(TOP)
		drop:DockMargin(padding,padding,padding,0)
		//drop:DockMargin(padding,padding-9,padding,0) //-9 to base the "top" off the text, not the box
		function drop.PerformLayout(_, w, h)
			drop.Label:SetWide(w / 2.4)
		end

	end

	function ENT:SpecialEffectThink()

		if self.SpecialEffectChildren and table.Count(self.SpecialEffectChildren) > 0 then

			local ent = self:GetSpecialEffectParent()
			if !IsValid(ent) then return end

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
			local dir = self:GetBeamDir()
			if dir == 0 then
				ang = ang:Forward()
			elseif dir == 1 then
				ang = ang:Right()
			elseif dir == 2 then
				ang = ang:Up()
			end

			local tr = {}
			tr.start = pos
			tr.endpos = pos+(ang*30000)
			tr.filter = ent
			tr = util.TraceLine(tr)

			local hit = self.HitTarget
			if !IsValid(self.HitTarget) then
				self.HitTarget = ents.CreateClientside("ent_partctrl_sfxtarget")
				hit = self.HitTarget
				hit.OwnerEntity = self
				hit:Spawn()
			end
			hit:SetPos(tr.HitPos)
			hit:SetAngles(tr.HitNormal:Angle())
			
			//store values used by impact utilfx
			hit.PartCtrl_TraceHit = tr.Entity
			hit.PartCtrl_SurfaceProp = tr.SurfaceProps

			//Just set the entity values on the child fx, and let them do the rest of the work themselves
			for child, _ in pairs (self.SpecialEffectChildren) do
				if child.PartCtrl_Ent and child.ParticleInfo then
					local cpointtab = PartCtrl_ProcessedPCFs[child:GetPCF()][child:GetParticleName()].cpoints
					for k, v in pairs (child.ParticleInfo) do
						if cpointtab[k].mode == PARTCTRL_CPOINT_MODE_POSITION then
							if v.sfx_role == 0 then
								child.ParticleInfo[k].ent = ent
								child.ParticleInfo[k].attach = self:GetAttachmentID()
							else
								child.ParticleInfo[k].ent = hit
								child.ParticleInfo[k].attach = 0
							end
						end
					end
				end
			end

		end

	end

	function ENT:SpecialEffectRefresh()

		self:SpecialEffectThink() //update the children's ParticleInfo first
		if self.SpecialEffectChildren then
			for child, _ in pairs (self.SpecialEffectChildren) do
				child:BeginNewParticle()
			end
		end

	end

end




//Networking for edit menu inputs
local EditMenuInputs = {
	//All special fx must have these ones
	[0] = "attachment_ent_setwithtool",
	"attachment_ent_detach",
	"attachment_attach",
	"child_setwithtool",
	"child_detach",
	//Entity-specific inputs
	"beam_dir",
}
ENT.EditMenuInputs_bits = 3 //max 7
ENT.EditMenuInputs = table.Flip(EditMenuInputs)

if CLIENT then
	
	function ENT:SpecialEffectDoInput(input, args)

		if input == "beam_dir" then
			
			net.WriteUInt(args[1], 2) //new dir (0/1/2)

		end

	end

else
	
	function ENT:SpecialEffectDoInput(input, ply)

		local refreshtable = false

		if input == "beam_dir" then
			
			self:SetBeamDir(math.min(net.ReadUInt(2), 2))
			refreshtable = true

		end

		return refreshtable

	end

end




if SERVER then

	function ENT:OnEntityCopyTableFinish(data)

		//Don't store this DTvar
		if data.DT then
			data.DT["SpecialEffectParent"] = nil
		end

	end

end




duplicator.RegisterEntityClass("ent_partctrl_sfx_beam", function(ply, data)

	local ent = ents.Create("ent_partctrl_sfx_beam")
	if !ent:IsValid() then return false end

	//duplicator.GenericDuplicatorFunction(ply, data)
	duplicator.DoGeneric(ent, data)
	duplicator.DoGenericPhysics(ent, ply, data)

	ent.DoneFirstSpawn = data.DoneFirstSpawn //all special fx need this; don't set nwvar defaults or make a parent grip point if the dupe is already taking care of those
	ent:SetPlayer(ply) //NOTE: this still works if ply doesn't exist

	ent:Spawn()

	return ent

end, "Data")