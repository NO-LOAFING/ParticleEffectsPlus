AddCSLuaFile()

ENT.Base 			= "ent_partctrl_sfx"
ENT.PrintName			= "Tracer Effect"
ENT.Category			= "Particle Effects"
ENT.Information			= "Fires out particle effects like bullet tracers, with one end where each \"bullet\" starts, and the other where it hits something."

ENT.Spawnable			= true

ENT.PartCtrl_ShortName		= "Tracer"
ENT.SpecialEffectRoles		= {
	[0] = "Start point",
	[1] = "Hit point",
}
ENT.DisableChildAutoplay	= true

ENT.DefaultLoopTime = 0.1




function ENT:SetupDataTables()

	//all special fx must have these ones
	self:NetworkVar("Int", 0, "AttachmentID")
	self:NetworkVar("Entity", 0, "SpecialEffectParent")
	if CLIENT then
		self:NetworkVarNotify("SpecialEffectParent", self.OnSpecialEffectParentChanged)
	end
	self:NetworkVar("Float", 0, "PauseTime")

	self:NetworkVar("Bool", 0, "Loop") //because special fx can't use loop mode 1 (loop when effect is finished), just make this a bool instead
	self:NetworkVar("Float", 1, "LoopDelay")
	self:NetworkVar("Bool", 1, "LoopSafety")

	self:NetworkVar("Int", 1, "Numpad")
	self:NetworkVar("Bool", 2, "NumpadToggle")
	self:NetworkVar("Bool", 3, "NumpadStartOn")
	self:NetworkVar("Bool", 4, "NumpadState")
	self:NetworkVar("Int", 2, "NumpadMode")

	self:NetworkVar("Float", 2, "TracerSpread")
	self:NetworkVar("Int", 3, "TracerCount")
	self:NetworkVar("Int", 4, "TracerDir")
	self:NetworkVar("Int", 5, "TracerHitDir")

end




function ENT:SetSpecialEffectDefaults()

	//all special fx must have these ones
	self:SetAttachmentID(0) 
	self:SetPauseTime(-1)

	self:SetLoop(true) 
	self:SetLoopDelay(self.DefaultLoopTime)
	self:SetLoopSafety(false)

	self:SetNumpad(0)
	self:SetNumpadToggle(true)
	self:SetNumpadStartOn(true)

	self:SetTracerSpread(10)
	self:SetTracerCount(1)
	self:SetTracerDir(0)
	self:SetTracerHitDir(0)

	if !self.IsBlank then
		local p = PartCtrl_SpawnParticle(self:GetPlayer(), self:GetPos(), "Tracer", "UtilFx")
		if IsValid(p) then
			p:AttachToSpecialEffect(self, self:GetPlayer(), false)
		end

		local p = PartCtrl_SpawnParticle(self:GetPlayer(), self:GetPos(), "Impact_GMOD", "UtilFx")
		if IsValid(p) then
			p:AttachToSpecialEffect(self, self:GetPlayer(), false)
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
		cat:SetLabel("Tracer Effect Settings")
		cat:DockMargin(3,1,-2,3) //-2 right for divider
		cat:Dock(FILL)
		container:AddItem(cat)

		local rpnl = vgui.Create("DSizeToContents", cat) //call this one rpnl and not pnl, just so we don't have to rewrite the numpad stuff copied from animprop that already has a panel with that name
		rpnl:Dock(FILL)
		cat:SetContents(rpnl)
		rpnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
		rpnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
		rpnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents


		local slider = vgui.Create("DNumSlider", rpnl)
		slider:SetText("Spread (degrees)")
		slider:SetMinMax(0, 360)
		slider:SetDefaultValue(10)
		slider:SetDark(true)
		slider:SetHeight(18)
		slider:Dock(TOP)
		slider:DockMargin(padding,padding-5,0,3) //less up and extra down on sliders because we want to base the "top" off the text, not the knob, but also want 16px between sliders' text

		slider:SetValue(ent:GetTracerSpread() or 0.00)
		function slider.OnValueChanged(_, val)
			ent:DoInput("tracer_spread", val)
		end


		local slider = vgui.Create("DNumSlider", rpnl)
		slider:SetText("Tracers per shot")
		slider:SetDecimals(0)
		slider:SetMinMax(1, 8)
		slider:SetDefaultValue(1)
		slider:SetDark(true)
		slider:SetHeight(18)
		slider:Dock(TOP)
		slider:DockMargin(padding,betweenitems-5,0,3) //less up and extra down on sliders because we want to base the "top" off the text, not the knob, but also want 16px between sliders' text

		local val = ent:GetTracerCount() or 0
		slider:SetValue(val)
		slider.Val = val
		function slider.OnValueChanged(_, val) //only send updates on whole numbers
			val = math.Round(val)
			if val != slider.Val then
				slider.Val = val
				ent:DoInput("tracer_count", val)
			end
		end


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
		local val = ent:GetTracerDir() or 0
		drop.Combo:SetValue(dirs[val])
		for k, v in pairs (dirs) do
			drop.Combo:AddChoice(v, k)
		end
		function drop.Combo.OnSelect(_, index, value, data)
			ent:DoInput("tracer_dir", data)
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
		help:SetText("Sets which direction to aim tracers. Useful for attachments that don't point forward.")
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
		local val = ent:GetTracerHitDir() or 0
		drop.Combo:SetValue(dirs[val])
		for k, v in pairs (dirs) do
			drop.Combo:AddChoice(v, k)
		end
		function drop.Combo.OnSelect(_, index, value, data)
			ent:DoInput("tracer_hitdir", data)
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
		help:SetText("Sets the orientation of effects attached to a hit point.")
		//help:SetContentAlignment(5)
		help:SetAutoStretchVertical(true)
		//help:DockMargin(32,0,32,8)
		help:DockMargin(padding_help,betweenitems_help,padding_help,0)
		help:Dock(TOP)
		help:SetTextColor(color_helpdark)

	end

end




if SERVER then

	function ENT:SpecialEffectInitialize()

		//do numpad stuff; just reuse the numpad funcs from the standard ent_partctrl

		self:SetNumpadState(false) //Numpad state should always start off as false
		//Different from NumpadState. This value is always true when the key is held down and false when it's not, even if the numpad state is set to toggle instead.
		//Used when changing the numpadkey or numpadtoggle vars to make sure stuff doesn't cause problems.
		self.NumpadKeyDown = false
		//Set up numpad functions
		local ply = self:GetPlayer() //NOTE: this still works if ply doesn't exist
		local key = self:GetNumpad()
		self.NumDown = numpad.OnDown(ply, key, "PartCtrl_Numpad", self, true)
		self.NumUp = numpad.OnUp(ply, key, "PartCtrl_Numpad", self, false)

	end

end




if CLIENT then

	local cv_max = GetConVar("sv_partctrl_particlesperent")

	function ENT:SpecialEffectThink()

		if !self.SpecialEffectChildren or table.Count(self.SpecialEffectChildren) == 0 then return end

		local max = nil
		if self:GetLoopSafety() then
			max = math.max(0, math.min(self:GetTracerCount(), cv_max:GetInt()) - 1)
		end
		local time = CurTime()

		//Handle pausing
		local ispaused = false
		if self.ParticleStartTime then
			local pausetime = self:GetPauseTime()
			ispaused = pausetime >= 0 and pausetime <= (time - self.ParticleStartTime)
			if ispaused then
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
						//do the same for loop time
						if self.LastLoop then
							self.LastLoop = self.LastLoop + diff
						end
						self.ParticlePauseTime = nil
					end
				end
			end
		end

		local numpadisdisabling = self:GetNumpadState()
		if !self:GetNumpadStartOn() then
			numpadisdisabling = !numpadisdisabling
		end
		if !numpadisdisabling then
			if !ispaused then
				local loop = self:GetLoop()
				if self.was_waiting then
					local wait = false
					for child, _ in pairs (self.SpecialEffectChildren) do
						child.MaxOldParticlesOverride = max
						local pcf = PartCtrl_GetGamePCF(child:GetPCF(), child:GetPath())
						if istable(PartCtrl_ProcessedPCFs[pcf]) and istable(PartCtrl_ProcessedPCFs[pcf][child:GetParticleName()]) //don't get stuck here if a child has an invalid effect, just skip it
						and !child.ParticleInfo then
							wait = true
							break
						end
					end
					if !wait then
						self.ParticleStartTime = nil //effect was either newly spawned, or disabled and enabled, so reset the timer
						self.ParticlePauseTime = nil
						self.was_waiting = nil
						self:StartParticle()
					end
				end
				if loop then //loop mode 2: repeat every X seconds
					if self.LastLoop and (self.LastLoop + math.max(0.0001, self:GetLoopDelay())) <= time then //don't let the loop delay actually be 0 here, otherwise it'll make a new effect every frame while paused
						local wait = false
						for child, _ in pairs (self.SpecialEffectChildren) do
							child.MaxOldParticlesOverride = max
							local pcf = PartCtrl_GetGamePCF(child:GetPCF(), child:GetPath())
							if istable(PartCtrl_ProcessedPCFs[pcf]) and istable(PartCtrl_ProcessedPCFs[pcf][child:GetParticleName()]) //don't get stuck here if a child has an invalid effect, just skip it
							and !child.ParticleInfo then
								wait = true
								self.was_waiting = true
								break
							end
						end
						if !wait then
							self:StartParticle()
							self.LastLoop = nil
						end
					end
					
					if self.LastLoop == nil then
						self.LastLoop = time
						//MsgN(time, ": set last loop to ", self.LastLoop)
					end
				end
			end
		else
			if max != nil then max = 0 end
			for child, _ in pairs (self.SpecialEffectChildren) do
				if child.particle and child.particle != partctrl_wait then
					child.MaxOldParticlesOverride = max
					if child.particle.IsValid and child.particle:IsValid() then
						//Stop any existing particles and throw them into the OldParticles table to get cleaned up
						//child.particle:StopEmission() //doesn't interact well with tracer count; because all the tracers except the last one are already in OldParticles, only the last one gets cut off while the rest keep playing, which looks odd
						table.insert(child.OldParticles, child.particle)
					end
					child.particle = partctrl_wait
				end
			end
			self.LastLoop = nil //reset loop time, so it restarts the timer as soon as we reenable
			self.was_waiting = true
		end

		//If loop mode is set to minimum, ensure we run next frame (for consistency with standard fx)
		if self:GetLoop() and self:GetLoopDelay() == 0 then
			self:NextThink(time)
			return true
		end

	end

	local ang_fwd = Angle(0,0,0)
	local ang_back = Angle(0,180,0)
	local ang_left = Angle(0,90,0)
	local ang_right = Angle(0,-90,0)
	local ang_up = Angle(-90,0,0)
	local ang_down = Angle(90,0,0)
	
	function ENT:StartParticle()

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
		local dir = self:GetTracerDir()
			//forward is default
		if dir == 1 then
			//back
			ang:RotateAroundAxis(ang:Up(), 180)
		elseif dir == 2 then
			//left
			ang:RotateAroundAxis(ang:Up(), 180)
			ang = ang:Right():Angle()
		elseif dir == 3 then
			//right
			ang = ang:Right():Angle()
		elseif dir == 4 then
			//up
			ang = ang:Up():Angle()
		elseif dir == 5 then
			//down
			ang:RotateAroundAxis(ang:Right(), 180)
			ang = ang:Up():Angle()
		end

		for i = 1, self:GetTracerCount() do

			//emulation of valve spread code https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/basecombatweapon_shared.h#L103, https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/shot_manipulator.h#L59
			//this doesn't go beyond 90 degrees unfortunately
			//local spread = math.sin(math.rad(self:GetTracerSpread()*2)/2)
			//local fwd = ang:Forward() + (math.Rand(-0.5,0.5)+math.Rand(-0.5,0.5)) * spread * ang:Right() + (math.Rand(-0.5,0.5)+math.Rand(-0.5,0.5)) * spread * ang:Up()
		
			//old adv particle controller spread code - this is nonsense but it does everything we need it to do
			local spread = self:GetTracerSpread()/90
			local fwd = Angle(ang)
			local randang = AngleRand()
			fwd:RotateAroundAxis(fwd:Forward(), randang.r)
			fwd:RotateAroundAxis(fwd:Right(), randang.p * (spread / 2))
			fwd:RotateAroundAxis(fwd:Up(), randang.y * (spread / 4))
			fwd = fwd:Forward()

			local tr = {}
			tr.start = pos
			tr.endpos = pos+(fwd*30000)
			tr.filter = ent
			tr = util.TraceLine(tr)

			local hit = ents.CreateClientside("ent_partctrl_sfxtarget")
			hit:SetPos(tr.HitPos)
			local hitdir = self:GetTracerHitDir()
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
				hit:SetAngles(ang_back) //immediately pointing exactly forward causes the angle to break for some reason, but this fixes it
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
			hit:Spawn()
			hit.OwnerEntity = self
			hit.Particles = {}
			//store values used by impact utilfx
			hit.PartCtrl_TraceHit = tr.Entity
			hit.PartCtrl_SurfaceProp = tr.SurfaceProps

			//Save particle creation time (used for pausing, which needs to pause at a certain point in the effect's lifetime)
			if !self.ParticleStartTime then
				self.ParticleStartTime = CurTime()
			end

			for child, _ in pairs (self.SpecialEffectChildren) do
				if child.PartCtrl_Ent then
					local pcf = PartCtrl_GetGamePCF(child:GetPCF(), child:GetPath())
					local name = child:GetParticleName()
					if !istable(PartCtrl_ProcessedPCFs[pcf]) or !istable(PartCtrl_ProcessedPCFs[pcf][name]) then continue end //skip invalid fx
					local cpointtab = PartCtrl_ProcessedPCFs[pcf][name].cpoints
					local addtotarget = false
					for k, v in pairs (child.ParticleInfo) do
						if cpointtab[k].mode == PARTCTRL_CPOINT_MODE_POSITION then
							if v.sfx_role == 0 then
								child.ParticleInfo[k].ent = ent
								child.ParticleInfo[k].attach = self:GetAttachmentID()
							else
								child.ParticleInfo[k].ent = hit
								child.ParticleInfo[k].attach = 0
								addtotarget = true
							end
							
						end
					end
					if child.particle and child.particle.IsValid and child.particle:IsValid() then
						//child.particle:StopEmission() //interacts poorly with fx that players would actually want to repeat quickly like explosions, so commented it out; unfortunately this means we get stupid effect pileups with fx that last forever like flamethrowers, but there's no legitimate reason to repeat those anyway so we'll just have to trust people here
						table.insert(child.OldParticles, child.particle)
					end
					child:StartParticle()
					if addtotarget then
						table.insert(hit.Particles, child.particle)
					end
				end
			end

		end

	end

	function ENT:SpecialEffectRefresh()

		self.ParticleStartTime = nil
		self.ParticlePauseTime = nil
		self.was_waiting = true //tells the think func to run StartParticle as soon as possible

		if self.SpecialEffectChildren then
			for child, _ in pairs (self.SpecialEffectChildren) do
				child:BeginNewParticle()
			end
		end

		self.LastLoop = nil

	end

end




if SERVER then
	
	function ENT:NumpadSetState(newstate, ply)

		local mode = self:GetNumpadMode()
		
		if mode == 0 then

			//Mode 0: Disable/enable effect
			self:SetNumpadState(newstate)
			//Everything else is handled clientside in Think once the client receives the new NumpadState value

		elseif mode == 1 then

			//Mode 1: Pause/unpause effect
			//This requires a ParticleStartTime value that only exists clientside, so tell the client to send it, using the same "effect_pause" input as the cpanel
			if IsValid(ply) and ply.IsPlayer and ply:IsPlayer() then
				net.Start("PartCtrl_DoPauseInput_SendToCl")
					net.WriteEntity(self)
				net.Send(ply)
			else
				MsgN(self, " tried to send a numpad pause input with invalid player ", ply, ". Report this!")
			end

		elseif mode == 2 then

			//Mode 2: Restart effect
			////Refresh special effect on server
			//if self.SpecialEffectRefresh then self:SpecialEffectRefresh() end
			//Tell clients to refresh the special effect
			net.Start("PartCtrl_SpecialEffect_Refresh_SendToCl")
				net.WriteEntity(self)
			net.Broadcast()

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
	"effect_pause",
	"effect_restart",
	//Entity-specific inputs
	"loop_mode",
	"loop_delay",
	"loop_safety",
	"numpad_num",
	"numpad_toggle",
	"numpad_starton",
	"numpad_mode",
	"tracer_spread",
	"tracer_count",
	"tracer_dir",
	"tracer_hitdir",
}
ENT.EditMenuInputs_bits = 5 //max 31
ENT.EditMenuInputs = table.Flip(EditMenuInputs)

if CLIENT then
	
	function ENT:SpecialEffectDoInput(input, args)

		if input == "loop_mode" then

			net.WriteBool(args[1]) //new loop mode

		elseif input == "loop_delay" then

			net.WriteFloat(args[1]) //new loop delay

		elseif input == "loop_safety" then

			net.WriteBool(args[1])

		elseif input == "numpad_num" then

			net.WriteInt(args[1], 11) //new numpad ID; copied from animprop, no idea what the max number of keys is so we'll say it's 1024 just to be safe

		elseif input == "numpad_toggle" then

			net.WriteBool(args[1])

		elseif input == "numpad_starton" then

			net.WriteBool(args[1])

		elseif input == "numpad_mode" then
	
			net.WriteUInt(args[1], 2) //numpad mode id

		elseif input == "tracer_spread" then
			
			net.WriteFloat(args[1]) //new spread

		elseif input == "tracer_count" then 

			net.WriteUInt(args[1], 5) //new count; generous max of 31

		elseif input == "tracer_dir" then
			
			net.WriteUInt(args[1], 3) //new dir (0-5)

		elseif input == "tracer_hitdir" then
			
			net.WriteUInt(args[1], 4) //new dir (0-9)

		end

	end

else
	
	function ENT:SpecialEffectDoInput(input, ply)

		local refreshtable = false

		if input == "loop_mode" then
				
			self:SetLoop(net.ReadBool())
			refreshtable = true

		elseif input == "loop_delay" then
			
			self:SetLoopDelay(net.ReadFloat())
			refreshtable = true

		elseif input == "loop_safety" then
			
			self:SetLoopSafety(net.ReadBool())

		elseif input == "numpad_num" then
			
			local ply = self:GetPlayer() //NOTE: this still works if ply doesn't exist

			local key = net.ReadInt(11)
			self:SetNumpad(key)

			numpad.Remove(self.NumDown)
			numpad.Remove(self.NumUp)

			self.NumDown = numpad.OnDown(ply, key, "PartCtrl_Numpad", self, true)
			self.NumUp = numpad.OnUp(ply, key, "PartCtrl_Numpad", self, false)

			//If the player is holding down the old key then let go of it
			if self.NumpadKeyDown then
				PartCtrlNumpadFunction(ply, self, false)
			end

		elseif input == "numpad_toggle" then

			local ply = self:GetPlayer() //NOTE: this still works if ply doesn't exist

			local toggle = net.ReadBool()
			self:SetNumpadToggle(toggle)

			//If the player switches to non-toggle mode, update the numpad state if necessary so it reflects whether or not the key is being held down 
			//(don't wait for the player to press/release the key again)
			if !toggle then
				local keydown = self.NumpadKeyDown
				if keydown != self:GetNumpadState() then
					PartCtrlNumpadFunction(ply, self, keydown)
				end
			end

		elseif input == "numpad_starton" then

			self:SetNumpadStartOn(net.ReadBool())

		elseif input == "numpad_mode" then

			local mode = net.ReadUInt(2)
			self:SetNumpadMode(mode)

			//Only mode 0 uses and updates the numpad state, so don't save numpad state between modes, and update it if switching back to mode 0
			if mode == 0 then
				if !self:GetNumpadToggle() then
					self:NumpadSetState(self.NumpadKeyDown, ply)
				else
					self:NumpadSetState(false, ply)
				end
			else
				self:SetNumpadState(false)
				//everything else should be handled clientside in Think once the client receives the new NumpadState value
			end

		elseif input == "tracer_spread" then

			self:SetTracerSpread(net.ReadFloat())
			refreshtable = true

		elseif input == "tracer_count" then

			self:SetTracerCount(net.ReadUInt(5))
			refreshtable = true

		elseif input == "tracer_dir" then
			
			self:SetTracerDir(math.min(net.ReadUInt(3), 5))
			refreshtable = true

		elseif input == "tracer_hitdir" then

			self:SetTracerHitDir(math.min(net.ReadUInt(4), 9))
			refreshtable = true

		end

		return refreshtable

	end

end




if SERVER then

	function ENT:OnEntityCopyTableFinish(data)

		//Don't store these DTvars
		if data.DT then
			data.DT.NumpadState = nil
			data.DT.SpecialEffectParent = nil
		end

	end

end




duplicator.RegisterEntityClass("ent_partctrl_sfx_tracer", function(ply, data)

	local ent = ents.Create("ent_partctrl_sfx_tracer")
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