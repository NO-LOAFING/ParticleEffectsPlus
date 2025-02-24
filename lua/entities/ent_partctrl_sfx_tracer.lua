AddCSLuaFile()

ENT.Base 			= "ent_partctrl_sfx"
ENT.PrintName			= "Bullet Effect"
ENT.Category			= "Particle Controller" //TODO: this name sucks, improve it eventually

ENT.Spawnable			= true

ENT.PartCtrl_ShortName		= "Bullet"
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

	self:NetworkVar("Bool", 0, "Loop") //because special fx can't use loop mode 1 (loop when effect is finished), just make this a bool instead
	self:NetworkVar("Float", 0, "LoopDelay")
	self:NetworkVar("Bool", 1, "LoopSafety")

	self:NetworkVar("Int", 1, "Numpad")
	self:NetworkVar("Bool", 2, "NumpadToggle")
	self:NetworkVar("Bool", 3, "NumpadStartOn")
	self:NetworkVar("Bool", 4, "NumpadState")

	self:NetworkVar("Float", 1, "TracerSpread")
	self:NetworkVar("Int", 2, "TracerCount")
	self:NetworkVar("Int", 3, "TracerDir")

end




function ENT:SetNWVarDefaults()

	self:SetAttachmentID(0) //all special fx must have this one

	self:SetLoop(true) 
	self:SetLoopDelay(self.DefaultLoopTime)
	self:SetLoopSafety(false)

	self:SetNumpad(0)
	self:SetNumpadToggle(true)
	self:SetNumpadStartOn(true)

	self:SetTracerSpread(10)
	self:SetTracerCount(1)
	self:SetTracerDir(0)

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

		local cat = vgui.Create("DCollapsibleCategory", container)
		cat:SetLabel("Bullet Settings")
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
		slider:SetText("Bullet Spread (in degrees)")
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
		slider:SetText("Bullet Count")
		slider:SetDecimals(0)
		slider:SetMinMax(1, 10)
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
		drop.Label:SetText("Bullet Direction")
		drop.Label:Dock(LEFT)

		drop.Combo = vgui.Create("DComboBox", drop)
		drop.Combo:SetHeight(25)
		drop.Combo:Dock(FILL)

		local dir0 = "Forward"
		local dir1 = "Right"
		local dir2 = "Up"
		local val = ent:GetTracerDir() or 0
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
			ent:DoInput("tracer_dir", data)
		end

		drop:SetHeight(25)
		drop:Dock(TOP)
		drop:DockMargin(padding,betweenitems,padding,0)
		//drop:DockMargin(padding,padding-9,padding,0) //-9 to base the "top" off the text, not the box
		function drop.PerformLayout(_, w, h)
			drop.Label:SetWide(w / 2.4)
		end

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

	function ENT:SpecialEffectThink()

		if PartCtrl_AddParticles_CrashCheck_PreventingCrash or !self.SpecialEffectChildren or table.Count(self.SpecialEffectChildren) == 0 then return end

		local max = nil
		if self:GetLoopSafety() then
			max = math.max(0, self:GetTracerCount() - 1)
		end

		local numpadisdisabling = self:GetNumpadState()
		if !self:GetNumpadStartOn() then
			numpadisdisabling = !numpadisdisabling
		end
		if !numpadisdisabling then
			local loop = self:GetLoop()
			local time = CurTime()
			if loop or self.LastLoop == nil then //loop mode 2: repeat every X seconds
				if self.LastLoop == nil or (self.LastLoop + math.max(0.0001, self:GetLoopDelay())) <= time then //don't let the loop delay actually be 0 here, otherwise it'll make a new effect every frame while paused
					local wait = false
					for child, _ in pairs (self.SpecialEffectChildren) do
						child.MaxOldParticlesOverride = max
						if !child.ParticleInfo then
							wait = true
							break
						end
					end
					if !wait then
						self:StartParticle()
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
					//Create a new particle as soon as we're no longer disabled
					child.particle = partctrl_wait
				end
			end
			self.LastLoop = nil //reset loop time, so it restarts the timer as soon as we reenable
		end

		//If loop mode is set to minimum, ensure we run next frame (for consistency with standard fx)
		if self:GetLoop() and self:GetLoopDelay() == 0 then
			self:NextThink(CurTime())
			return true
		end

	end

end

if CLIENT then
	
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
		if dir == 1 then
			ang = ang:Right():Angle()
		elseif dir == 2 then
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
			hit:SetAngles(tr.HitNormal:Angle())
			hit:Spawn()
			hit.OwnerEntity = self
			hit.Particles = {}
			//store values used by impact utilfx
			hit.PartCtrl_TraceHit = tr.Entity
			hit.PartCtrl_SurfaceProp = tr.SurfaceProps

			for child, _ in pairs (self.SpecialEffectChildren) do
				if child.PartCtrl_Ent then
					local cpointtab = PartCtrl_ProcessedPCFs[child:GetPCF()][child:GetParticleName()].cpoints
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

		if self.SpecialEffectChildren then
			for child, _ in pairs (self.SpecialEffectChildren) do
				child:BeginNewParticle()
			end
		end

		self.LastLoop = nil

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
	"loop_mode",
	"loop_delay",
	"loop_safety",
	"numpad_num",
	"numpad_toggle",
	"numpad_starton",
	"tracer_spread",
	"tracer_count",
	"tracer_dir",
}
ENT.EditMenuInputs_bits = 4 //max 15
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

		elseif input == "tracer_spread" then
			
			net.WriteFloat(args[1]) //new spread

		elseif input == "tracer_count" then 

			net.WriteUInt(args[1], 5) //new count; generous max of 31

		elseif input == "tracer_dir" then
			
			net.WriteUInt(args[1], 2) //new dir (0/1/2)

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

		elseif input == "tracer_spread" then

			self:SetTracerSpread(net.ReadFloat())
			refreshtable = true

		elseif input == "tracer_count" then

			self:SetTracerCount(net.ReadUInt(5))
			refreshtable = true

		elseif input == "tracer_dir" then
			
			local new = math.min(net.ReadUInt(2), 2)
			self:SetTracerDir(new)
			refreshtable = true

		end

		return refreshtable

	end

end




if SERVER then

	function ENT:OnEntityCopyTableFinish(data)

		//Don't store these DTvars
		if data.DT then
			data.DT["NumpadState"] = nil
			data.DT["SpecialEffectParent"] = nil
		end

	end

end




duplicator.RegisterEntityClass("ent_partctrl_sfx_tracer", function(ply, data)

	local ent = ents.Create("ent_partctrl_sfx_tracer")
	if !ent:IsValid() then return false end

	//duplicator.GenericDuplicatorFunction(ply, data)
	duplicator.DoGeneric(ent, data)
	duplicator.DoGenericPhysics(ent, ply, data)

	ent.DoneFirstSpawn = data.DoneFirstSpawn //all special fx need this; don't set nwvar defaults or make a parent grip point if the dupe is already taking care of those
	ent:SetPlayer(ply) //NOTE: this still works if ply doesn't exist

	ent:Spawn()

	return ent

end, "Data")