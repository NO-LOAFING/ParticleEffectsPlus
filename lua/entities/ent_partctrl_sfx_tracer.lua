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
	self:SetLoopDelay(0.1)
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

		//category for key
		local cat = vgui.Create("DCollapsibleCategory", container)
		cat:SetLabel("Key & Repeat Settings")
		cat:DockMargin(3,1,-2,3) //-2 right for divider
		cat:Dock(FILL)
		container:AddItem(cat)
	
		local default_looptime = 0.1
		local default_loopmode = true
	
		//expand if any contained options are non-default 
		cat:SetExpanded(
			((ent2:GetNumpad() or 0) != 0)
			or (ent2:GetNumpadToggle() != true)
			or (ent2:GetNumpadStartOn() != true)
			//considered also adding a check here to make sure the effect isn't disabled, but i don't think that's possible without a numpad key set
			or ((ent2:GetLoop() or true) != default_loopmode)
			or ((math.Round(ent2:GetLoopDelay(), 6) or 0) != default_looptime)
		)
	
		local rpnl = vgui.Create("DSizeToContents", cat) //call this one rpnl and not pnl, just so we don't have to rewrite the numpad stuff copied from animprop that already has a panel with that name
		rpnl:Dock(FILL)
		cat:SetContents(rpnl)
		rpnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
		rpnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
		rpnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents
	
			local pnl = vgui.Create("Panel", rpnl)
	
			local numpadpnl = vgui.Create("DPanel", pnl)
			numpadpnl:SetPaintBackground(false)
	
			numpadpnl.numpad = vgui.Create("DBinder", numpadpnl)
			//back.Numpad = numpadpnl.numpad
			numpadpnl.label = vgui.Create("DLabel", numpadpnl)
			numpadpnl.label:SetText("Effect Key")
			numpadpnl.label:SetDark(true)
	
			function numpadpnl:PerformLayout()
				self:SetWide(100)
				self:SetTall(70)
	
				self.numpad:InvalidateLayout(true)
				self.numpad:SetSize(100, 50)
	
				self.label:SizeToContents()
	
				self.numpad:Center()
				self.numpad:AlignTop(20)
	
				self.label:CenterHorizontal()
				self.label:AlignTop(0)
	
				local wide = self.label:GetWide()
				if wide > 100 then self:SetWide(wide) end
			end
			numpadpnl:Dock(LEFT)
	
			numpadpnl.numpad:SetSelectedNumber(ent2:GetNumpad() or 0)
			function numpadpnl.numpad.SetValue(_, val)
				numpadpnl.numpad:SetSelectedNumber(val)
				ent2:DoInput("numpad_num", val)
			end
	
			pnl:Dock(TOP)
			//pnl:DockMargin(padding,betweenitems-3,0,padding) //numpad label is 3px too tall, compensate for it here
			//pnl:DockMargin(padding,padding-3,0,padding) //numpad label is 3px too tall, compensate for it here
			pnl:DockMargin(padding,padding-3,0,0) //numpad label is 3px too tall, compensate for it here
			pnl:SetHeight(70)
			//function pnl.Paint(_, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(255,0,0,70)) end //for testing the full size of this panel
	
			local anotherpnl = vgui.Create("Panel", pnl)
			anotherpnl:Dock(LEFT)
			anotherpnl:SetWidth(90)
	
			local check = vgui.Create("DCheckBoxLabel", anotherpnl)
			//back.NumpadToggleCheckbox = check
			check:SetText("Toggle")
			check:SetDark(true)
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(8,28,0,0)
	
			check:SetValue(ent2:GetNumpadToggle())
			check.OnChange = function(_, val)
				ent2:DoInput("numpad_toggle", val)
			end
	
			local check = vgui.Create("DCheckBoxLabel", anotherpnl)
			//back.NumpadStartOnCheckbox = check
			check:SetText("Start on")
			check:SetDark(true)
			check:SetHeight(15)
			check:Dock(BOTTOM)
			check:DockMargin(8,0,0,8)
	
			check:SetValue(ent2:GetNumpadStartOn())
			check.OnChange = function(_, val)
				ent2:DoInput("numpad_starton", val)
			end
	
			local pnldisabled = vgui.Create("Panel", pnl)
			//pnldisabled:Dock(RIGHT)
			//pnldisabled:DockMargin(0,3,padding,0) //+3 to top to align the top of this panel with the top of the numpad label text
			pnldisabled:Dock(FILL)
			pnldisabled:DockMargin(-12,3,padding,0) //+3 to top to align the top of this panel with the top of the numpad label text, -12 to left to get it 8px away from checkbox text
			//pnldisabled:SetWidth(115)
	
			local text = vgui.Create("DLabel", pnldisabled)
			text:SetFont("DermaDefaultBold")
			text:SetColor(Color(255,0,0,255))
			text:SetText("DISABLED")
			text:SizeToContents()
			text:CenterHorizontal()
			text:AlignTop(9)
	
			local text2 = vgui.Create("DLabel", pnldisabled)
			text2:SetColor(Color(255,0,0,255))
			text2:SetText("(press effect")
			text2:SizeToContents()
			text2:CenterHorizontal()
			text2:AlignTop(17 + text:GetTall())
	
			local text3 = vgui.Create("DLabel", pnldisabled)
			text3:SetColor(Color(255,0,0,255))
			text3:SetText("key to enable)")
			text3:SizeToContents()
			text3:CenterHorizontal()
			text3:AlignTop(17 + text:GetTall() + text2:GetTall())
	
			function pnldisabled.Paint(_, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(255,0,0,70))
				//text:SizeToContents()
				text:CenterHorizontal()
				//text2:SizeToContents()
				text2:CenterHorizontal()
				//text3:SizeToContents()
				text3:CenterHorizontal()
			end
	
			function pnldisabled.Think()
				if !IsValid(ent2) then return end
	
				local numpadisdisabling = ent2:GetNumpadState()
				local starton = ent2:GetNumpadStartOn()
				if !starton then
					numpadisdisabling = !numpadisdisabling
				end
	
				if numpadisdisabling then
					pnldisabled:SetAlpha(255)
	
					local newtext = nil
					if ent2:GetNumpadToggle() then
						newtext = "(press effect"
					else
						if starton then
							newtext = "(release effect"
						else
							newtext = "(hold effect"
						end
					end
					if newtext != text2:GetText() then
						text2:SetText(newtext)
						text2:SizeToContents()
					end
				else
					pnldisabled:SetAlpha(0)
				end
			end
	
	
		//category for repeats
		--[[local cat = vgui.Create("DCollapsibleCategory", container)
		cat:SetLabel("Repeat Settings")
		cat:DockMargin(3,3,3,3)
		cat:Dock(FILL)
		container:AddItem(cat)
	
		//expand if any contained options are non-default
		cat:SetExpanded(
			((ent2:GetLoopMode() or 1) != 1)
			or ((ent2:GetLoopDelay() or 0) != 0)
		)
	
		local rpnl = vgui.Create("DSizeToContents", cat) //again, call this one rpnl and not pnl, just so we don't have to rewrite the repeat stuff copied from animprop
		rpnl:Dock(FILL)
		cat:SetContents(rpnl)
		rpnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
		rpnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
		rpnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents]]
	
			local drop = vgui.Create("Panel", rpnl)
	
			drop.Label = vgui.Create("DLabel", drop)
			drop.Label:SetDark(true)
			drop.Label:SetText("Repeat Type")
			drop.Label:Dock(LEFT)
	
			drop.Combo = vgui.Create("DComboBox", drop)
			drop.Combo:SetHeight(25)
			drop.Combo:Dock(FILL)
	
			local loopmode0 = "Don't repeat"
			//local loopmode1 = "Repeat X seconds after ending"
			local loopmode2 = "Repeat every X seconds"
			local val = ent2:GetLoop()
			if !val then
				drop.Combo:SetValue(loopmode0)
			else
				drop.Combo:SetValue(loopmode2)
			end
			drop.Combo:AddChoice(loopmode0, false)
			drop.Combo:AddChoice(loopmode2, true)
			function drop.Combo.OnSelect(_, index, value, data)
				ent2:DoInput("loop_mode", data)
			end
	
			drop:SetHeight(25)
			drop:Dock(TOP)
			drop:DockMargin(padding,betweenitems,padding,0)
			//drop:DockMargin(padding,padding-9,padding,0) //-9 to base the "top" off the text, not the box
			function drop.PerformLayout(_, w, h)
				drop.Label:SetWide(w / 2.4)
			end
	
			local slider = vgui.Create("DNumSlider", rpnl)
			//back.LoopDelaySlider = slider
			slider:SetText("Seconds between repeats")
			slider:SetMinMax(0, 5)
			slider:SetDefaultValue(default_looptime)
			slider:SetDark(true)
			slider:SetHeight(18)
			slider:Dock(TOP)
			slider:DockMargin(padding,betweenitems-5,0,3) //less up and extra down on sliders because we want to base the "top" off the text, not the knob, but also want 16px between sliders' text
	
			function slider:Think()
				if !IsValid(ent2) then return end
	
				//Disable the slider if set to "do not repeat"
				if !ent2:GetLoop() then
					slider:SetMouseInputEnabled(false)
					slider:SetAlpha(75)
				else
					slider:SetMouseInputEnabled(true)
					slider:SetAlpha(255)
				end
			end
	
			slider.ValueChanged = SliderValueChangedUnclampedMax
			slider.SetValue = SliderSetValueUnclampedMax
	
			slider:SetValue(ent2:GetLoopDelay() or 0.00)
			function slider.OnValueChanged(_, val)
				ent2:DoInput("loop_delay", val)
			end
	
			if !IsValid(ent2) or !ent2.utilfx then //this option doesn't do anything for utilfx, so don't show it
				local check = vgui.Create( "DCheckBoxLabel", rpnl)
				check:SetText("Clean up particles when disabled or repeated")
				check:SetDark(true)
				check:SetHeight(15)
				check:Dock(TOP)
				check:DockMargin(padding,betweenitems,0,0)
	
				check:SetValue(ent2:GetLoopSafety())
				check.OnChange = function(_, val)
					ent2:DoInput("loop_safety", val)
				end
				--[[check.Think = function()
					if !IsValid(ent2) then return end
					if ent2.utilfx then
						check:SetDisabled(true)
						check:SetTooltip("Option not available for scripted effects") //never mind, tooltips don't work on disabled checkboxes
					else
						check:SetDisabled(false)
						//check:SetTooltip("")
					end
				end]]
			end

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