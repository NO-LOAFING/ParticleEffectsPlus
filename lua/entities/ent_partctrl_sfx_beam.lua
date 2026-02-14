AddCSLuaFile()

ENT.Base 			= "ent_partctrl_sfx"
ENT.PrintName			= "Beam Effect"
ENT.Category			= "Particle Effects+: Special Effects"
ENT.Information			= "Makes particle effects work like a laser pointer, with one end where the \"beam\" starts, and the other end continuously moving to where it's pointing."

ENT.Spawnable			= true

ENT.PartCtrl_ShortName		= "Beam"
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
	self:NetworkVar("Float", 0, "PauseTime")

	self:NetworkVar("Int", 1, "BeamDir")
	self:NetworkVar("Int", 2, "BeamHitDir")

end




function ENT:SetSpecialEffectDefaults()

	//all special fx must have these ones
	self:SetAttachmentID(0) 
	self:SetPauseTime(-1)

	self:SetBeamDir(0)
	self:SetBeamHitDir(0)

	if !self.IsBlank then
		if IsMounted("tf") then
			local p = PartCtrl_SpawnParticle(self:GetPlayer(), self:GetPos(), "laser_sight_beam", "particles/class_fx.pcf", "tf")
			if IsValid(p) then
				p:AttachToSpecialEffect(self, self:GetPlayer(), false)
			end
		else
			//goofy recolored wrangler beam because there are no suitable default fx included with gmod at all
			local p = PartCtrl_SpawnParticle(self:GetPlayer(), self:GetPos(), "partctrl_pointer_laser", "particles/partctrl_sfx.pcf")
			if IsValid(p) then
				p:AttachToSpecialEffect(self, self:GetPlayer(), false)
			end
		end
	end

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
		local betweenitems = window.betweenitems
		local padding_help = window.padding_help
		local betweenitems_help = window.betweenitems_help
		local color_helpdark = window.color_helpdark

		local cat = vgui.Create("DCollapsibleCategory", container)
		cat:SetLabel("Beam Effect Settings")
		cat:DockMargin(3,1,3,3)
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
		drop.Label:SetText("Firing direction")
		drop.Label:Dock(LEFT)

		drop.Combo = vgui.Create("DComboBox", drop)
		drop.Combo:SetHeight(25)
		drop.Combo:Dock(FILL)

		local dirs = {
			[0] = "0: Forward",
			[1] = "1: Back",
			[2] = "2: Left",
			[3] = "3: Right",
			[4] = "4: Up",
			[5] = "5: Down"
		}
		local val = ent:GetBeamDir() or 0
		drop.Combo:SetValue(dirs[val])
		for k, v in pairs (dirs) do
			drop.Combo:AddChoice(v, k)
		end
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

		local help = vgui.Create("DLabel", rpnl)
		help:SetDark(true)
		help:SetWrap(true)
		help:SetTextInset(0, 0)
		help:SetText("Sets which direction to aim the beam. Useful for attachments that don't point forward.")
		//help:SetContentAlignment(5)
		help:SetAutoStretchVertical(true)
		//help:DockMargin(32,0,32,8)
		help:DockMargin(padding_help,betweenitems_help,padding_help,0)
		help:Dock(TOP)
		help:SetTextColor(color_helpdark)


		local drop = vgui.Create("Panel", rpnl)
		
		drop.Label = vgui.Create("DLabel", drop)
		drop.Label:SetDark(true)
		drop.Label:SetText("Hit point angle")
		drop.Label:Dock(LEFT)

		drop.Combo = vgui.Create("DComboBox", drop)
		drop.Combo:SetHeight(25)
		drop.Combo:Dock(FILL)

		local dirs = {
			[0] = "0: Away from hit surface",
			[1] = "1: Toward hit surface",
			[2] = "2: Away from start point",
			[3] = "3: Toward start point",
			[4] = "4: Forward",
			[5] = "5: Back",
			[6] = "6: Left",
			[7] = "7: Right",
			[8] = "8: Up",
			[9] = "9: Down"
		}
		local val = ent:GetBeamHitDir() or 0
		drop.Combo:SetValue(dirs[val])
		for k, v in pairs (dirs) do
			drop.Combo:AddChoice(v, k)
		end
		function drop.Combo.OnSelect(_, index, value, data)
			ent:DoInput("beam_hitdir", data)
		end

		drop:SetHeight(25)
		drop:Dock(TOP)
		drop:DockMargin(padding,betweenitems,padding,0)
		//drop:DockMargin(padding,padding-9,padding,0) //-9 to base the "top" off the text, not the box
		function drop.PerformLayout(_, w, h)
			drop.Label:SetWide(w / 2.4)
		end

		local help = vgui.Create("DLabel", rpnl)
		help:SetDark(true)
		help:SetWrap(true)
		help:SetTextInset(0, 0)
		help:SetText("Sets the orientation of effects attached to the hit point.")
		//help:SetContentAlignment(5)
		help:SetAutoStretchVertical(true)
		//help:DockMargin(32,0,32,8)
		help:DockMargin(padding_help,betweenitems_help,padding_help,0)
		help:Dock(TOP)
		help:SetTextColor(color_helpdark)

	end

	local ang_fwd = Angle(0,0,0)
	local ang_back = Angle(0,180,0)
	local ang_left = Angle(0,90,0)
	local ang_right = Angle(0,-90,0)
	local ang_up = Angle(-90,0,0)
	local ang_down = Angle(90,0,0)

	function ENT:SpecialEffectThink()

		if self.SpecialEffectChildren and table.Count(self.SpecialEffectChildren) > 0 then

			local ent = self:GetSpecialEffectParent()
			if !IsValid(ent) then return end
			local time = CurTime()

			local p = self:GetCPoint()
			local ang
			local dir = self:GetBeamDir()
			if dir == 0 then
				//forward
				ang = p.ang:Forward()
			elseif dir == 1 then
				//back
				ang = -p.ang:Forward()
			elseif dir == 2 then
				//left
				ang = -p.ang:Right()
			elseif dir == 3 then
				//right
				ang = p.ang:Right()
			elseif dir == 4 then
				//up
				ang = p.ang:Up()
			else
				//down
				ang = -p.ang:Up()
			end

			local tr = {}
			tr.start = p.pos
			tr.endpos = p.pos+(ang*30000)
			tr.filter = ent
			tr = util.TraceLine(tr)

			local hit = self.HitTarget
			if !IsValid(self.HitTarget) then
				self.HitTarget = ents.CreateClientside("ent_partctrl_sfxtarget")
				hit = self.HitTarget
				hit.OwnerEntity = self
				hit:Spawn()
				hit:SetAngles(ang_back) //immediately pointing exactly forward causes the angle to break for some reason, but this fixes it
			end
			hit:SetPos(tr.HitPos)
			local hitdir = self:GetBeamHitDir()
			if hitdir == 0 then
				//surface normal
				hit:SetAngles(tr.HitNormal:Angle())
			elseif hitdir == 1 then
				//inverted surface normal
				hit:SetAngles((-tr.HitNormal):Angle())
			elseif hitdir == 2 then
				//away from start point
				hit:SetAngles(tr.Normal:Angle())
			elseif hitdir == 3 then
				//toward start point
				hit:SetAngles((-tr.Normal):Angle())
			elseif hitdir == 4 then
				//forward
				hit:SetAngles(ang_fwd)
			elseif hitdir == 5 then
				//back
				hit:SetAngles(ang_back)
			elseif hitdir == 6 then
				//left
				hit:SetAngles(ang_left)
			elseif hitdir == 7 then
				//right
				hit:SetAngles(ang_right)
			elseif hitdir == 8 then
				//up
				hit:SetAngles(ang_up)
			else
				//down
				hit:SetAngles(ang_down)
			end
			
			//store values used by impact utilfx
			hit.PartCtrl_TraceHit = tr.Entity
			hit.PartCtrl_SurfaceProp = tr.SurfaceProps

			//Handle pausing
			if self.ParticleStartTime then
				local pausetime = self:GetPauseTime()
				if pausetime >= 0 and pausetime <= (time - self.ParticleStartTime) then
					//if not paused, but should be, then pause it
					local didpause
					for child, _ in pairs (self.SpecialEffectChildren) do
						if !child.PauseOverride then
							didpause = true
							child.PauseOverride = true
						end
					end
					if didpause then
						//MsgN("pausing")
						self.ParticlePauseTime = time
					end
				else
					//if paused, but shouldn't be, then unpause it
					local didunpause
					for child, _ in pairs (self.SpecialEffectChildren) do
						if child.PauseOverride then
							didunpause = true
							child.PauseOverride = nil
						end
					end
					if didunpause then
						//MsgN("unpausing")
						if self.ParticlePauseTime != nil then
							//change the particlestarttime to compensate for the time we spent paused, so that if we pause it 
							//again afterward, the effect's lifetime doesn't include the time it spent paused prior to that
							local diff = (time - self.ParticlePauseTime)
							self.ParticleStartTime = self.ParticleStartTime + diff
							//don't worry about adjusting LastLoop on all the particle ents, they'll handle it themselves
							self.ParticlePauseTime = nil
						end
					end
				end
			end

			//Just set the entity values on the child fx, and let them do the rest of the work themselves
			for child, _ in pairs (self.SpecialEffectChildren) do
				if child.PartCtrl_Ent and child.ParticleInfo then
					local pcf = PartCtrl_GetGamePCF(child:GetPCF(), child:GetPath())
					local cpointtab = PartCtrl_ProcessedPCFs[pcf][child:GetParticleName()].cpoints
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

		timer.Simple(0, function() //wait a frame, otherwise SpecialEffectThink will retrieve an out-of-date SpecialEffectParent on this ent
			if !IsValid(self) then return end
			self.ParticleStartTime = CurTime() //pause behavior is extra simple on this special effect because we don't disablechildautoplay
			self.ParticlePauseTime = nil
			self:SpecialEffectThink() //update the children's ParticleInfo first
			if self.SpecialEffectChildren then
				for child, _ in pairs (self.SpecialEffectChildren) do
					child:BeginNewParticle()
				end
			end
		end)

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
	"effect_pause",
	"effect_restart",
	//Entity-specific inputs
	"beam_dir",
	"beam_hitdir",
}
ENT.EditMenuInputs_bits = 4 //max 15
ENT.EditMenuInputs = table.Flip(EditMenuInputs)

if CLIENT then
	
	function ENT:SpecialEffectDoInput(input, args)

		if input == "beam_dir" then
			
			net.WriteUInt(args[1], 3) //new dir (0-5)

		elseif input == "beam_hitdir" then
			
			net.WriteUInt(args[1], 4) //new dir (0-9)

		end

	end

else
	
	function ENT:SpecialEffectDoInput(input, ply)

		local refreshtable = false

		if input == "beam_dir" then
			
			self:SetBeamDir(math.min(net.ReadUInt(3), 5))
			refreshtable = true

		elseif input == "beam_hitdir" then

			self:SetBeamHitDir(math.min(net.ReadUInt(4), 9))
			refreshtable = true

		end

		return refreshtable

	end

end




if SERVER then

	function ENT:OnEntityCopyTableFinish(data)

		//Don't store this DTvar
		if data.DT then
			data.DT.SpecialEffectParent = nil
		end

	end

end




duplicator.RegisterEntityClass("ent_partctrl_sfx_beam", function(ply, data)

	local ent = ents.Create("ent_partctrl_sfx_beam")
	if !ent:IsValid() then return false end

	//default dtvars for old dupes that don't have them
	if data.DT.PauseTime == nil then data.DT.PauseTime = -1 end

	//duplicator.GenericDuplicatorFunction(ply, data)
	duplicator.DoGeneric(ent, data)
	duplicator.DoGenericPhysics(ent, ply, data)

	ent.DoneFirstSpawn = data.DoneFirstSpawn //all special fx need this; don't set nwvar defaults or make a parent grip point if the dupe is already taking care of those
	ent:SetPlayer(ply) //NOTE: this still works if ply doesn't exist

	ent:Spawn()

	return ent

end, "Data")

PartCtrl_AddBlankSpecialEffect(ENT) //Add blank variant to spawnmenu