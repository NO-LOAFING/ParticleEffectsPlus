AddCSLuaFile()

ENT.Base 			= "ent_partctrl_sfx"
ENT.PrintName			= "Projectile Effect"
ENT.Category			= "Particle Effects"
ENT.Information			= "TODO"

ENT.Spawnable			= true

ENT.PartCtrl_ShortName		= "Projectile"
ENT.SpecialEffectRoles		= {
	[0] = "Start point",
	[1] = "Projectile model",
	[2] = "Hit point",
}
ENT.DisableChildAutoplay	= true

ENT.DefaultLoopTime = 0.8




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

	self:NetworkVar("Bool", 5, "ProjServerside")
	self:NetworkVar("Float", 1, "ProjSpread")
	self:NetworkVar("Int", 2, "ProjCount")
	self:NetworkVar("Int", 3, "ProjDir")

end




function ENT:SetNWVarDefaults()

	self:SetAttachmentID(0) //all special fx must have this one

	self:SetLoop(true) 
	self:SetLoopDelay(self.DefaultLoopTime)
	self:SetLoopSafety(false)

	self:SetNumpad(0)
	self:SetNumpadToggle(true)
	self:SetNumpadStartOn(true)

	self:SetProjServerside(false)
	self:SetProjSpread(0)
	self:SetProjCount(1)
	self:SetProjDir(0)

	self:SetModel("models/weapons/w_models/w_rocket.mdl") //do this here too //TODO: use an hl2 model as default eventually

end




function ENT:SpecialEffectDefaultRoles(cpoints)

	//Attach cpoints to the projectile model by default; there's no good way to guess if something is meant to be an effect on the projectile 
	//or an explosion or what have you, so just attach it somewhere it'll be immediately visible and demonstrating the effect.
	local results = {}
	for k, cpoint in pairs (cpoints) do
		results[cpoint] = 1
	end
	return results

end




if CLIENT then

	//TODO: currently this is just a clone of the bullet effect settings; once this effect is done it'll have a LOT more settings than the
	//others, so we'll probably want to organize this into multiple categories

	function ENT:SpecialEffectAddControls(window, container)

		local ent = self
		local padding = window.padding
		local betweenitems = window.betweenitems

		local cat = vgui.Create("DCollapsibleCategory", container)
		cat:SetLabel("Projectile Settings")
		cat:DockMargin(3,1,-2,3) //-2 right for divider
		cat:Dock(FILL)
		container:AddItem(cat)

		local rpnl = vgui.Create("DSizeToContents", cat) //call this one rpnl and not pnl, just so we don't have to rewrite the numpad stuff copied from animprop that already has a panel with that name
		rpnl:Dock(FILL)
		cat:SetContents(rpnl)
		rpnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
		rpnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
		rpnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents


		local check = vgui.Create( "DCheckBoxLabel", rpnl)
		check:SetText("Serverside projectiles")
		check:SetDark(true)
		check:SetHeight(15)
		check:Dock(TOP)
		check:DockMargin(padding,padding,0,0)

		check:SetValue(ent:GetProjServerside())
		check.OnChange = function(_, val)
			ent:DoInput("proj_serverside", val)
		end


		local slider = vgui.Create("DNumSlider", rpnl)
		slider:SetText("Projectile Spread (in degrees)")
		slider:SetMinMax(0, 360)
		slider:SetDefaultValue(0)
		slider:SetDark(true)
		slider:SetHeight(18)
		slider:Dock(TOP)
		slider:DockMargin(padding,betweenitems-5,0,3) //less up and extra down on sliders because we want to base the "top" off the text, not the knob, but also want 16px between sliders' text

		slider:SetValue(ent:GetProjSpread() or 0.00)
		function slider.OnValueChanged(_, val)
			ent:DoInput("proj_spread", val)
		end


		local slider = vgui.Create("DNumSlider", rpnl)
		slider:SetText("Projectile Count")
		slider:SetDecimals(0)
		slider:SetMinMax(1, 8)
		slider:SetDefaultValue(1)
		slider:SetDark(true)
		slider:SetHeight(18)
		slider:Dock(TOP)
		slider:DockMargin(padding,betweenitems-5,0,3) //less up and extra down on sliders because we want to base the "top" off the text, not the knob, but also want 16px between sliders' text

		local val = ent:GetProjCount() or 0
		slider:SetValue(val)
		slider.Val = val
		function slider.OnValueChanged(_, val) //only send updates on whole numbers
			val = math.Round(val)
			if val != slider.Val then
				slider.Val = val
				ent:DoInput("proj_count", val)
			end
		end


		local drop = vgui.Create("Panel", rpnl)
		
		drop.Label = vgui.Create("DLabel", drop)
		drop.Label:SetDark(true)
		drop.Label:SetText("Projectile Direction")
		drop.Label:Dock(LEFT)

		drop.Combo = vgui.Create("DComboBox", drop)
		drop.Combo:SetHeight(25)
		drop.Combo:Dock(FILL)

		local dir0 = "Forward"
		local dir1 = "Right"
		local dir2 = "Up"
		local val = ent:GetProjDir() or 0
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
			ent:DoInput("proj_dir", data)
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




function ENT:SpecialEffectInitialize()

	if SERVER then
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
	else
		self.SpecialEffectChildrenSorted = self.SpecialEffectChildrenSorted or {[true] = {}, [false] = {}}
	end

	//list of projectile entities we've created; we use this to clean them up
	self.ProjectileEnts = {}

end




function ENT:SpecialEffectThink()

	//if CLIENT and (PartCtrl_AddParticles_CrashCheck_PreventingCrash or !self.SpecialEffectChildren or table.Count(self.SpecialEffectChildren) == 0) then return end

	//TODO: we'll probably want to implement loop safety differently for proj fx, because we have to clean up projectiles too
	--[[local max = nil
	if self:GetLoopSafety() then
		max = math.max(0, self:GetTracerCount() - 1)
	end]]

	local numpadisdisabling = self:GetNumpadState()
	if !self:GetNumpadStartOn() then
		numpadisdisabling = !numpadisdisabling
	end
	if !numpadisdisabling then
		local svproj = self:GetProjServerside()
		if (!svproj and CLIENT) or (svproj and SERVER) then
			local loop = self:GetLoop()
			local time = CurTime()
			if loop or self.LastLoop == nil then //loop mode 2: repeat every X seconds
				if self.LastLoop == nil or (self.LastLoop + math.max(0.0001, self:GetLoopDelay())) <= time then //don't let the loop delay actually be 0 here, otherwise it'll make a new effect every frame while paused
					local wait = false
					if CLIENT then
						for child, _ in pairs (self.SpecialEffectChildren) do
							//child.MaxOldParticlesOverride = max
							if !child.ParticleInfo then
								wait = true
								break
							end
						end
					end
					if !wait then
						self:CreateProjectile()
						self.LastLoop = time
						//MsgN(time, ": set last loop to ", self.LastLoop)
					end
				end
			end
		end
	elseif CLIENT then
		//if max != nil then max = 0 end
		for child, _ in pairs (self.SpecialEffectChildren) do
			if child.particle and child.particle != partctrl_wait then
				//child.MaxOldParticlesOverride = max
				if child.particle.IsValid and child.particle:IsValid() then
					//Stop any existing particles and throw them into the OldParticles table to get cleaned up
					//child.particle:StopEmission() //doesn't interact well with tracer count; because all the tracers except the last one are already in OldParticles, only the last one gets cut off while the rest keep playing, which looks odd
					table.insert(child.OldParticles, child.particle)
				end
				child.particle = partctrl_wait
			end
		end
		self.LastLoop = nil //reset loop time, so it restarts the timer as soon as we reenable
	end

	//Limit the number of spawned projectiles, just like ent_partctrl does with particles
	local max = 32 //TODO: set this up with loop safety once we implement that
	while #self.ProjectileEnts > max do
		local v = self.ProjectileEnts[1]
		if IsValid(v) then v:Remove() end
		table.remove(self.ProjectileEnts, 1)
	end

	//If loop mode is set to minimum, ensure we run next frame (for consistency with standard fx)
	if self:GetLoop() and (self:GetLoopDelay() == 0 or SERVER) then
		self:NextThink(CurTime())
		return true
	end

end




function ENT:CreateProjectile()

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
	local dir = self:GetProjDir()
	if dir == 1 then
		ang = ang:Right():Angle()
	elseif dir == 2 then
		ang = ang:Up():Angle()
	end

	for i = 1, self:GetProjCount() do

		//emulation of valve spread code https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/basecombatweapon_shared.h#L103, https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/shot_manipulator.h#L59
		//this doesn't go beyond 90 degrees unfortunately
		//local spread = math.sin(math.rad(self:GetTracerSpread()*2)/2)
		//local fwd = ang:Forward() + (math.Rand(-0.5,0.5)+math.Rand(-0.5,0.5)) * spread * ang:Right() + (math.Rand(-0.5,0.5)+math.Rand(-0.5,0.5)) * spread * ang:Up()
	
		//old adv particle controller spread code - this is nonsense but it does everything we need it to do
		local spread = self:GetProjSpread()/90
		local fwd = Angle(ang)
		local randang = AngleRand()
		fwd:RotateAroundAxis(fwd:Forward(), randang.r)
		fwd:RotateAroundAxis(fwd:Right(), randang.p * (spread / 2))
		fwd:RotateAroundAxis(fwd:Up(), randang.y * (spread / 4))
		//now de-randomize the roll so the prop still spawns upright
		fwd:RotateAroundAxis(fwd:Forward(), -randang.r)

		local proj
		if CLIENT then
			proj = ClientsideModel(self:GetModel()) //TODO: make setting
		else
			proj = ents.Create("ent_partctrl_proj")
			proj:SetModel(self:GetModel())
			proj:SetOwnerEntity(self) //reference to the effect ent on the projectile; it uses this to run StartParticles on clients
		end
		proj:SetOwner(ent) //don't collide with the prop that the effect ent is parented to
		proj:SetPos(pos)
		proj:SetAngles(fwd)

		proj:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS) //don't collide with other projectiles
		if !util.IsValidProp(proj:GetModel()) then
			proj:PhysicsInitBox(proj:GetModelBounds())
		else
			proj:PhysicsInit(SOLID_VPHYSICS)
		end

		//TODO: projectile visuals

		proj:Spawn()
		table.insert(self.ProjectileEnts, proj)
		if CLIENT then
			self:StartParticle(proj, true)
		end

		local phys = proj:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetVelocity(fwd:Forward() * 800) //TODO: make setting
			phys:EnableGravity(false) //TODO: make setting
			phys:SetMaterial("gmod_silent")
		end

		//TODO: expire code

	end
end




if CLIENT then

	function ENT:StartParticle(proj, first)

		//test: make client and server projectiles clearly distinguishable
		if proj:GetClass() == "ent_partctrl_proj" then
			proj:SetColor(Color(0,128,255,255))
		else
			proj:SetColor(Color(255,128,0,255))
		end

		local ent = self:GetSpecialEffectParent()
		if !IsValid(ent) then return end

		local hit
		if !first then
			//TODO: expire effect; creates the hit target
		end

		for child, _ in pairs (self.SpecialEffectChildrenSorted[first]) do
			if child.PartCtrl_Ent then
				local cpointtab = PartCtrl_ProcessedPCFs[child:GetPCF()][child:GetParticleName()].cpoints
				local addtotarget = false
				for k, v in pairs (child.ParticleInfo) do
					if cpointtab[k].mode == PARTCTRL_CPOINT_MODE_POSITION then
						if v.sfx_role == 0 then
							child.ParticleInfo[k].ent = ent
							child.ParticleInfo[k].attach = self:GetAttachmentID()
						elseif v.sfx_role == 1 then
							child.ParticleInfo[k].ent = proj
							//child.ParticleInfo[k].attach should already be set
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

	if CLIENT then
		if self.SpecialEffectChildren then
			self.SpecialEffectChildrenSorted = {[true] = {}, [false] = {}}

			for child, _ in pairs (self.SpecialEffectChildren) do
				child:BeginNewParticle()

				//Sort our particle effects by when they should play; do this here because we have to be sure the client has received the particleinfo for the fx first
				if child.ParticleInfo then
					local attach_to_proj = false
					local attach_to_expire = false
					local cpointtab = PartCtrl_ProcessedPCFs[child:GetPCF()][child:GetParticleName()].cpoints
					for k, v in pairs (child.ParticleInfo) do
						if cpointtab[k].mode == PARTCTRL_CPOINT_MODE_POSITION then
							if v.sfx_role == 1 then
								attach_to_proj = true
							elseif v.sfx_role == 2 then
								attach_to_expire = true
							end	
						end
					end
					//If the particle doesn't attach to the projectile OR the expire effect (i.e. muzzleflashes),
					//or the particle attaches to the projectile but not the expire effect,
					//then play it when the projectile initializes.
					if (!attach_to_proj and !attach_to_expire) or (attach_to_proj and !attach_to_expire) then
						self.SpecialEffectChildrenSorted[true][child] = true
					//If the particle doesn't attach to the projectile, but instead the expire effect,
					//then play it when the projectile expires.
					elseif (!attach_to_proj and attach_to_expire) then
						self.SpecialEffectChildrenSorted[false][child] = true
					end
					//If a particle wants to attach to both the projectile AND the expire effect,
					//then don't play it, because those two roles can't exist at the same time.
				end
			end
		end
	end

	//reset projectile ents and numpad on both server and client
	for _, proj in pairs (self.ProjectileEnts) do
		if IsValid(proj) then proj:Remove() end
	end
	self.ProjectileEnts = {}
	self.LastLoop = nil

end




function ENT:SpecialEffectOnRemove()
	for _, proj in pairs (self.ProjectileEnts) do
		if IsValid(proj) then proj:Remove() end
	end
	self.ProjectileEnts = {}
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
	"proj_serverside",
	"proj_spread",
	"proj_count",
	"proj_dir",
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

		elseif input == "proj_serverside" then
			
			net.WriteBool(args[1])

		elseif input == "proj_spread" then
			
			net.WriteFloat(args[1]) //new spread

		elseif input == "proj_count" then 

			net.WriteUInt(args[1], 5) //new count; generous max of 31

		elseif input == "proj_dir" then
			
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

		elseif input == "proj_serverside" then
			
			self:SetProjServerside(net.ReadBool())
			refreshtable = true

		elseif input == "proj_spread" then

			self:SetProjSpread(net.ReadFloat())
			refreshtable = true

		elseif input == "proj_count" then

			self:SetProjCount(net.ReadUInt(5))
			refreshtable = true

		elseif input == "proj_dir" then
			
			local new = math.min(net.ReadUInt(2), 2)
			self:SetProjDir(new)
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

		//Don't store this either
		data.ProjectileEnts = nil

	end

end




duplicator.RegisterEntityClass("ent_partctrl_sfx_proj", function(ply, data)

	local ent = ents.Create("ent_partctrl_sfx_proj")
	if !ent:IsValid() then return false end

	//duplicator.GenericDuplicatorFunction(ply, data)
	duplicator.DoGeneric(ent, data)
	duplicator.DoGenericPhysics(ent, ply, data)

	ent.DoneFirstSpawn = data.DoneFirstSpawn //all special fx need this; don't set nwvar defaults or make a parent grip point if the dupe is already taking care of those
	ent:SetPlayer(ply) //NOTE: this still works if ply doesn't exist

	ent:Spawn()

	ent:SetModel(data.Model) //override the model set in initialize with our duplicated model

	return ent

end, "Data")