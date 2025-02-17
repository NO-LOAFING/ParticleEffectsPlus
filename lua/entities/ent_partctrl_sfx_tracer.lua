AddCSLuaFile()

ENT.Base 			= "ent_partctrl_sfx"
ENT.PrintName			= "Tracer Effect"
ENT.Category			= "Particle Controller" //TODO: this name sucks, improve it eventually

ENT.Spawnable			= true

ENT.PartCtrl_ShortName		= "Tracer"
ENT.SpecialEffectRoles		= {
	[0] = "Start",
	[1] = "End",
}

ENT.DefaultLoopTime = 0.1




function ENT:SetupDataTables()

	self:NetworkVar("Int", 0, "AttachmentID") //all special fx must have this one

	self:NetworkVar("Bool", 0, "Loop") //because special fx can't use loop mode 1 (loop when effect is finished), just make this a bool instead
	self:NetworkVar("Float", 0, "LoopDelay")
	self:NetworkVar("Bool", 1, "LoopSafety")

	self:NetworkVar("Int", 1, "Numpad")
	self:NetworkVar("Bool", 2, "NumpadToggle")
	self:NetworkVar("Bool", 3, "NumpadStartOn")
	self:NetworkVar("Bool", 4, "NumpadState")

end




function ENT:SetNWVarDefaults()

	self:SetAttachmentID(0) //all special fx must have this one

	self:SetLoop(true) 
	self:SetLoopDelay(self.DefaultLoopTime)
	self:SetLoopSafety(false)

	self:SetNumpad(0)
	self:SetNumpadToggle(true)
	self:SetNumpadStartOn(true)

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

		//duplicate code, argh
		local ent = self
		local ent2 = self
		local padding = window.padding
		local betweenitems = window.betweenitems
		local SliderValueChangedUnclampedMax = window.SliderValueChangedUnclampedMax
		local SliderSetValueUnclampedMax = window.SliderSetValueUnclampedMax



	end

end




function ENT:SpecialEffectInitialize()

	//do numpad stuff; just reuse the numpad funcs from the standard ent_partctrl
	if SERVER then
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




function ENT:SpecialEffectThink()
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

		end

	end

else
	
	function ENT:SpecialEffectDoInput(input, ply)

		if input == "loop_mode" then
				
			self:SetLoop(net.ReadBool())
			//refreshtable = true

		elseif input == "loop_delay" then
			
			self:SetLoopDelay(net.ReadFloat())
			//refreshtable = true

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

		end

	end

end




if SERVER then

	function ENT:OnEntityCopyTableFinish(data)

		//Don't store this DTvar
		if data.DT then
			data.DT["NumpadState"] = nil
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