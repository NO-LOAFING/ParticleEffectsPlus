AddCSLuaFile()

local PANEL = {}




function PANEL:SetEntity(ent)
	if self.m_Entity == ent then return end

	self.m_Entity = ent
	self:RebuildControls()
end



//Function overrides for sliders to unclamp them
local function SliderValueChangedUnclamped(self, val)
	//don't clamp this
	//val = math.Clamp( tonumber( val ) || 0, self:GetMin(), self:GetMax() )

	self.Slider:SetSlideX( self.Scratch:GetFraction( val ) )

	if ( self.TextArea != vgui.GetKeyboardFocus() ) then
		self.TextArea:SetValue( self.Scratch:GetTextValue() )
	end

	self:OnValueChanged( val )
end

local function SliderSetValueUnclamped(self, val)
	//don't clamp this
	//val = math.Clamp( tonumber( val ) || 0, self:GetMin(), self:GetMax() )
	
	if ( self:GetValue() == val ) then return end

	self.Scratch:SetValue( val )

	self:ValueChanged( self:GetValue() )
end

local function SliderValueChangedUnclampedMin(self, val)
	//don't clamp the min value
	//val = math.Clamp( tonumber( val ) || 0, self:GetMin(), self:GetMax() )
	val = math.min(tonumber(val) or 0, self:GetMax())

	self.Slider:SetSlideX( self.Scratch:GetFraction( val ) )

	if ( self.TextArea != vgui.GetKeyboardFocus() ) then
		self.TextArea:SetValue( self.Scratch:GetTextValue() )
	end

	self:OnValueChanged( val )
end

local function SliderSetValueUnclampedMin(self, val)
	//don't clamp the min value
	//val = math.Clamp( tonumber( val ) || 0, self:GetMin(), self:GetMax() )
	val = math.min(tonumber(val) or 0, self:GetMax())
	
	if ( self:GetValue() == val ) then return end

	self.Scratch:SetValue( val )

	self:ValueChanged( self:GetValue() )
end

local function SliderValueChangedUnclampedMax(self, val)
	//don't clamp the max value
	//val = math.Clamp( tonumber( val ) || 0, self:GetMin(), self:GetMax() )
	val = math.max(tonumber(val) or 0, self:GetMin())

	self.Slider:SetSlideX( self.Scratch:GetFraction( val ) )

	if ( self.TextArea != vgui.GetKeyboardFocus() ) then
		self.TextArea:SetValue( self.Scratch:GetTextValue() )
	end

	self:OnValueChanged( val )
end

local function SliderSetValueUnclampedMax(self, val)
	//don't clamp the max value
	//val = math.Clamp( tonumber( val ) || 0, self:GetMin(), self:GetMax() )
	val = math.max(tonumber(val) or 0, self:GetMin())
	
	if ( self:GetValue() == val ) then return end

	self.Scratch:SetValue( val )

	self:ValueChanged( self:GetValue() )
end


local function GetParticleName(ent)
	if ent.PartCtrl_Ent then
		//return "Particle Controller [" .. tostring(ent:EntIndex()) .. "]: " .. ent:GetParticleName() .. " (" .. ent:GetPCF() .. ")")
		if !ent.utilfx then
			return ent:GetParticleName() .. " (" .. PartCtrl_GetDataPCFNiceName(PartCtrl_GetGamePCF(ent:GetPCF(), ent:GetPath())) .. ")"
		else
			return ent:GetParticleName() .. " (Scripted Effect)"
		end
	else
		return ent.PrintName
	end
end


function PANEL:RebuildControls()

	self:Clear()
	local ent = self.m_Entity
	if !IsValid(ent) then self:EntityLost() return end
	self:GetParent():SetTitle(GetParticleName(ent))

	//Make sure mouse input is enabled - this can get set to false if the window is created while the context menu is closed
	self:SetMouseInputEnabled(true)


	//Formatting values ripped from animpropeditor, TODO: see how many of these we actually end up using

	//Give our help strings a slightly darker color than normal so they're easier to read against the gray background
	local color_helpdark = table.Copy(self:GetSkin().Colours.Tree.Hover)
	color_helpdark.r = math.max(0, color_helpdark.r - 40)
	color_helpdark.g = math.max(0, color_helpdark.g - 40)
	color_helpdark.b = math.max(0, color_helpdark.b - 40)
	self.color_helpdark = color_helpdark //make this accessible by external funcs

	local padding = 14 //space between the edges of lists and their contents
	local betweenitems = 8 //space between items in lists
	local betweencategories = 28 //space between categories in lists
	self.padding = padding
	self.betweenitems = betweenitems
	self.betweencategories = betweencategories

	local padding_help = 22 //bigger padding for help text
	local betweenitems_help = 5 //smaller betweenitems for help text
	local betweenitems_help2 = 3 //even smaller betweenitems for second help text paragraphs
	self.padding_help = padding_help
	self.betweenitems_help = betweenitems_help

	local icon_info = Material("icon16/information.png")
	local icon_invalid = Material("icon16/cancel.png")

	//make this other stuff externally accessible too
	self.SliderValueChangedUnclampedMax = SliderValueChangedUnclampedMax
	self.SliderSetValueUnclampedMax = SliderSetValueUnclampedMax



	self.CPointCategories = {} //make these externally accessible so that the entity can change them upon receiving inputs from the server

	local function BuildParticleEntControls(ent2, container)

		local pcf = PartCtrl_GetGamePCF(ent2:GetPCF(), ent2:GetPath())
		local name = ent2:GetParticleName()

		//don't throw a lua error if a special effect contains an invalid particle effect
		//(i.e. we're a client connected to a server, and the server has the effect but we don't)
		if !istable(PartCtrl_ProcessedPCFs[pcf]) or !istable(PartCtrl_ProcessedPCFs[pcf][name]) then
			local pnl = vgui.Create("DSizeToContents", container)
			pnl:SetSizeX(false)
			pnl:Dock(FILL)
			container:AddItem(pnl)
			pnl.Paint = function(self, w, h) 
				draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
				//draw info icon
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(icon_invalid)
				//surface.DrawTexturedRect(padding,betweenitems,16,16)
				surface.DrawTexturedRect(padding,(h/2)-8,16,16)
			end
			pnl:DockPadding(16+padding,0,0,padding) //extra left to make room for the info icon; DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
			pnl:DockMargin(3,3,3,3-2) //-2 bottom because there's too much space between this and the next category otherwise
	
			local text = vgui.Create("DLabel", pnl)
			text:SetDark(true)
			text:SetWrap(true)
			text:SetTextInset(0, 0)
			text:SetText("Invalid particle effect (from game/addon that isn't mounted?)") //TODO: this error text is outdated, whoops; use the different ones from the spawnicon code
			text:SetContentAlignment(5)
			text:SetAutoStretchVertical(true)
			text:DockMargin(padding,padding-1,padding,0) //padding-1 for top is trial and error, results in nice 16px spacing on both top and bottom of text
			text:Dock(TOP)

			return
		end
	
		--[[//category for general settings
		local cat = vgui.Create("DCollapsibleCategory", container)
		cat:SetLabel("General")
		cat:DockMargin(3,3,3,3)
		cat:Dock(FILL)
		container:AddItem(cat)
		cat:SetExpanded(true)
	
		local pnl = vgui.Create("DSizeToContents", cat)
		pnl:Dock(FILL)
		cat:SetContents(pnl)
		pnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
		pnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
		pnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents
	
				//filler to ensure pnl is stretched to full width
				local filler = vgui.Create("Panel", pnl)
				filler:Dock(TOP)
				filler:SetHeight(0)
	
				local text = vgui.Create("DLabel", pnl)
				text:SetDark(true)
				text:SetWrap(true)
				text:SetTextInset(0, 0)
				text:SetText("cause this is filler, filler night!!")
				text:SetContentAlignment(5)
				text:SetAutoStretchVertical(true)
				text:DockMargin(padding,betweenitems,padding,0)
				text:Dock(TOP)]]
	
	
		//category for info; no header for this one
		local info = PartCtrl_ProcessedPCFs[pcf][name].info
		local info2 = PartCtrl_ProcessedPCFs[pcf][name].info_sfx
		if ent != ent2 and info2 then info = info2 end //use alt info text for special effect children, if applicable
		if info then
	
			local pnl = vgui.Create("DSizeToContents", container)
			pnl:SetSizeX(false)
			pnl:Dock(FILL)
			container:AddItem(pnl)
			pnl.Paint = function(self, w, h) 
				draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
				//draw info icon
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(icon_info)
				//surface.DrawTexturedRect(padding,betweenitems,16,16)
				surface.DrawTexturedRect(padding,(h/2)-8,16,16)
			end
			pnl:DockPadding(16+padding,0,0,padding) //extra left to make room for the info icon; DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
			pnl:DockMargin(3,3,3,3-2) //-2 bottom because there's too much space between this and the next category otherwise
	
			local text = vgui.Create("DLabel", pnl)
			text:SetDark(true)
			text:SetWrap(true)
			text:SetTextInset(0, 0)
			text:SetText(table.concat(info, "/n"))
			text:SetContentAlignment(5)
			text:SetAutoStretchVertical(true)
			text:DockMargin(padding,padding-1,padding,0) //padding-1 for top is trial and error, results in nice 16px spacing on both top and bottom of text
			text:Dock(TOP)
	
		end
	

		local first = true

		if !ent.DisableChildAutoplay then //don't add these controls if the effect won't use them

			//category for key
			local cat = vgui.Create("DCollapsibleCategory", container)
			cat:SetLabel("Key Settings")
			cat:DockMargin(3,3,3,3)
			first = false
			cat:Dock(FILL)
			container:AddItem(cat)
		
			//expand if any contained options are non-default 
			cat:SetExpanded(
				((ent2:GetNumpadMode() or 0) != 0)
				or ((ent2:GetNumpad() or 0) != 0)
				or (ent2:GetNumpadToggle() != true)
				or (ent2:GetNumpadStartOn() != true)
				//considered also adding a check here to make sure the effect isn't disabled, but i don't think that's possible without a numpad key set
			)
		
			local rpnl = vgui.Create("DSizeToContents", cat) //call this one rpnl and not pnl, just so we don't have to rewrite the numpad stuff copied from animprop that already has a panel with that name
			rpnl:Dock(FILL)
			cat:SetContents(rpnl)
			rpnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
			rpnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
			rpnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents
		
				local drop = vgui.Create("Panel", rpnl)

				drop.Label = vgui.Create("DLabel", drop)
				drop.Label:SetDark(true)
				drop.Label:SetText("Key Function")
				drop.Label:Dock(LEFT)

				drop.Combo = vgui.Create("DComboBox", drop)
				drop.Combo:SetHeight(25)
				drop.Combo:Dock(FILL)

				local numpadmode0 = "Disable/enable effect"
				local numpadmode1 = "Pause/unpause effect"
				local numpadmode2 = "Restart effect"
				local val = ent2:GetNumpadMode() or 0
				if val == 0 then
					drop.Combo:SetValue(numpadmode0)
				elseif val == 1 then
					drop.Combo:SetValue(numpadmode1)
				elseif val == 2 then
					drop.Combo:SetValue(numpadmode2)
				end
				drop.Combo:AddChoice(numpadmode0, 0)
				if !ent2.utilfx and ent == ent2 then drop.Combo:AddChoice(numpadmode1, 1) end //utilfx don't support pausing, and special fx handle pausing on their own
				drop.Combo:AddChoice(numpadmode2, 2)
				function drop.Combo.OnSelect(_, index, value, data)
					ent2:DoInput("numpad_mode", data)

					//"toggle" option is grayed out for numpad mode 2 (restart effect); make sure it's always true to prevent unintended behavior 
					//("restart effect" with toggle off makes the effect restart on both key in and key out, instead of just key in)
					if data > 1 then
						container.NumpadToggleCheckbox:SetValue(true)
					end
					//"start on" option is grayed out for numpad mode 1 (pause/unpause) and numpad mode 2 (restart effect); make sure it's true to prevent unintended behavior
					if data > 0 then
						container.NumpadStartOnCheckbox:SetValue(true)
					end
				end
			
				drop:SetHeight(25)
				drop:Dock(TOP)
				drop:DockMargin(padding,padding-9,padding,0) //-9 to base the "top" off the text, not the box
				function drop.PerformLayout(_, w, h)
					drop.Label:SetWide(w / 2.4)
				end

				local pnl = vgui.Create("Panel", rpnl)
		
				local numpadpnl = vgui.Create("DPanel", pnl)
				numpadpnl:SetPaintBackground(false)
		
				numpadpnl.numpad = vgui.Create("DBinder", numpadpnl)
				//container.Numpad = numpadpnl.numpad
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
				//pnl:DockMargin(padding,padding-3,0,0) //numpad label is 3px too tall, compensate for it here
				pnl:DockMargin(padding,betweenitems-3,0,0) //numpad label is 3px too tall, compensate for it here
				pnl:SetHeight(70)
				//function pnl.Paint(_, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(255,0,0,70)) end //for testing the full size of this panel
		
				local anotherpnl = vgui.Create("Panel", pnl)
				anotherpnl:Dock(LEFT)
				anotherpnl:SetWidth(90)
		
				local check = vgui.Create("DCheckBoxLabel", anotherpnl)
				container.NumpadToggleCheckbox = check
				check:SetText("Toggle")
				check:SetDark(true)
				check:SetHeight(15)
				check:Dock(TOP)
				check:DockMargin(8,28,0,0)
		
				check:SetValue(ent2:GetNumpadToggle())
				check.OnChange = function(_, val)
					ent2:DoInput("numpad_toggle", val)
				end
				check.Think = function()
					if !IsValid(ent2) then return end

					if ent2:GetNumpadMode() > 1 then
						check:SetDisabled(true)
						//check:SetTooltip("Option not available for restart mode") //never mind, tooltips don't work on disabled checkboxes
					else
						check:SetDisabled(false)
						//check:SetTooltip("") //TODO: use this if we're creating tooltips for everything
					end
				end
		
				local check = vgui.Create("DCheckBoxLabel", anotherpnl)
				container.NumpadStartOnCheckbox = check
				check:SetText("Start on")
				check:SetDark(true)
				check:SetHeight(15)
				check:Dock(BOTTOM)
				check:DockMargin(8,0,0,8)
		
				check:SetValue(ent2:GetNumpadStartOn())
				check.OnChange = function(_, val)
					ent2:DoInput("numpad_starton", val)
				end
				check.Think = function()
					if !IsValid(ent2) then return end

					if ent2:GetNumpadMode() > 0 then
						check:SetDisabled(true)
						//check:SetTooltip("Option only available for enable/disable mode - use pause button below") //never mind, tooltips don't work on disabled checkboxes
					else
						check:SetDisabled(false)
						//check:SetTooltip("") //TODO: use this if we're creating tooltips for everything
					end
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
			local cat = vgui.Create("DCollapsibleCategory", container)
			cat:SetLabel("Repeat Settings")
			cat:DockMargin(3,1,3,3)
			cat:Dock(FILL)
			container:AddItem(cat)

			local default_looptime = PartCtrl_ProcessedPCFs[pcf][name].default_time or 0
			local default_loopmode = 1
			if ent2.utilfx then
				if default_looptime < 0 then
					//-1 sets no loop by default
					default_loopmode = 0
				else
					default_loopmode = 2
				end
			end
			default_looptime = math.max(0, default_looptime)
			//MsgN("default time ", default_looptime, ", currently ", ent2:GetLoopDelay())
			//MsgN("default mode ", default_loopmode, ", currently ", ent2:GetLoopMode())
		
			//expand if any contained options are non-default
			cat:SetExpanded(
				((ent2:GetLoopMode() or 1) != default_loopmode)
				or ((math.Round(ent2:GetLoopDelay(), 6) or 0) != default_looptime)
				or (ent2:GetLoopSafety() != false)
			)
		
			local rpnl = vgui.Create("DSizeToContents", cat) //again, call this one rpnl and not pnl, just so we don't have to rewrite the repeat stuff copied from animprop
			rpnl:Dock(FILL)
			cat:SetContents(rpnl)
			rpnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
			rpnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
			rpnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents
		
				local drop = vgui.Create("Panel", rpnl)
		
				drop.Label = vgui.Create("DLabel", drop)
				drop.Label:SetDark(true)
				drop.Label:SetText("Repeat Type")
				drop.Label:Dock(LEFT)
		
				drop.Combo = vgui.Create("DComboBox", drop)
				drop.Combo:SetHeight(25)
				drop.Combo:Dock(FILL)
		
				local loopmode0 = "Don't repeat"
				local loopmode1 = "Repeat X seconds after ending"
				local loopmode2 = "Repeat every X seconds"
				local val = ent2:GetLoopMode() or 1
				if val == 0 then
					drop.Combo:SetValue(loopmode0)
				elseif val == 1 then
					drop.Combo:SetValue(loopmode1)
				elseif val == 2 then
					drop.Combo:SetValue(loopmode2)
				end
				drop.Combo:AddChoice(loopmode0, 0)
				if !ent2.utilfx then drop.Combo:AddChoice(loopmode1, 1) end //utilfx don't support this mode because we don't have a way to detect when they've ended
				drop.Combo:AddChoice(loopmode2, 2)
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
				//container.LoopDelaySlider = slider
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
					if ent2:GetLoopMode() == 0 then
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
					check:SetText("Clean up particles when repeated or disabled")
					check:SetDark(true)
					check:SetHeight(15)
					check:Dock(TOP)
					check:DockMargin(padding,betweenitems,0,0)
		
					check:SetValue(ent2:GetLoopSafety())
					check.OnChange = function(_, val)
						ent2:DoInput("loop_safety", val)
					end
		
					local help = vgui.Create("DLabel", rpnl)
					help:SetDark(true)
					help:SetWrap(true)
					help:SetTextInset(0, 0)
					help:SetText("If checked, all existing particles are removed when the effect repeats, or when it's disabled by pressing the key.")
					//help:SetContentAlignment(5)
					help:SetAutoStretchVertical(true)
					//help:DockMargin(32,0,32,8)
					help:DockMargin(padding_help,betweenitems_help,padding_help,0)
					help:Dock(TOP)
					help:SetTextColor(color_helpdark)

				end

		end
	
	
		//categories for each cpoint
		self.CPointCategories[ent2] = {}
		for k, v in SortedPairs (ent2.ParticleInfo) do
	
			local cat = vgui.Create("DCollapsibleCategory", container)
			cat:SetLabel("Control Point #" .. tostring(k))
			if first then
				cat:DockMargin(3,3,3,3)
				first = false
			else
				cat:DockMargin(3,1,3,3)
			end
			cat:Dock(FILL)
			container:AddItem(cat)
			cat:SetExpanded(true)
		
			local pnl = vgui.Create("DSizeToContents", cat)
			pnl:Dock(FILL)
			cat:SetContents(pnl)
			pnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
			pnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
			pnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents
	
			//Rebuild the contents of this category whenever the player changes the cpoint entity
			function pnl.RebuildContents(v2)
	
				pnl:Clear()
	
				//filler to ensure pnl is stretched to full width
				local filler = vgui.Create("Panel", pnl)
				filler:Dock(TOP)
				filler:SetHeight(0)
	
				//Add mode-specific options
				local mode = PartCtrl_ProcessedPCFs[pcf][name].cpoints[k].mode
				if mode == PARTCTRL_CPOINT_MODE_POSITION then
					if ent == ent2 then
						local modelent = v2.ent
						if IsValid(modelent) then
							if IsValid(modelent.AttachedEntity) then modelent = modelent.AttachedEntity end

							local button = vgui.Create("DButton", pnl)
							//button:SetWidth(button:GetWide() + 14) //+ 4)
							button:SetHeight(30)
							button:Dock(TOP)
							//button:DockMargin(0,0,0,0)
							button:DockMargin(padding,padding,padding,0)
		
							if modelent.PartCtrl_Grip then
								button:SetText("Attach to model")
								button:SizeToContents()
								button.DoClick = function()
									surface.PlaySound("ui/buttonclickrelease.wav")
									ent2:DoInput("cpoint_position_ent_setwithtool", k)
								end
							else
								if modelent:GetNWBool("PartCtrl_MergedGrip") and IsValid(modelent:GetParent()) then
									button:SetText("Unmerge from model (" .. string.GetFileFromFilename(modelent:GetParent():GetModel()) .. ")")
								else
									button:SetText("Detach from model (" .. string.GetFileFromFilename(modelent:GetModel()) .. ")")
								end
								button:SizeToContents()
								button.DoClick = function()
									ent2:DoInput("cpoint_position_ent_detach", k)
								end
		
								local attachcount = 0
								local tab = modelent:GetAttachments()
								if istable(tab) then attachcount = table.Count(tab) end
		
								if attachcount > 0 then
									local slider = vgui.Create("DNumSlider", pnl)
									slider:SetText("Attachment")
									slider:SetDecimals(0)
									slider:SetMinMax(0, attachcount)
									slider:SetDefaultValue(0)
									slider:SetDark(true)
									slider:SetHeight(18)
									slider:Dock(TOP)
									slider:DockMargin(padding,betweenitems,0,3)
							
									slider:SetValue(v2.attach)
									function slider.OnValueChanged(_, val)
										val = math.Round(val)
										if val != slider.PartCtrl_AttachSlider.attach then //only send updates on whole numbers
											surface.PlaySound("weapons/pistol/pistol_empty.wav")
											slider.PartCtrl_AttachSlider.attach = val
											ent2:DoInput("cpoint_position_attach", k, val)
										end
									end
		
									//Let the HUDPaint hook in autorun detect that the player is hovering over this slider
									slider.PartCtrl_AttachSlider = {ent = modelent, attach = v2.attach}
									slider.Slider.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider
									slider.Slider.Knob.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
									slider.TextArea.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
									slider.Label.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
									slider.Scratch.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
								end
							end
						end
					else
						//This is a child of a special effect, so show special effect options instead

						local drop = vgui.Create("Panel", pnl)
	
						drop.Label = vgui.Create("DLabel", drop)
						drop.Label:SetDark(true)
						drop.Label:SetText("Position")
						drop.Label:Dock(LEFT)
				
						drop.Combo = vgui.Create("DComboBox", drop)
						drop.Combo:SetHeight(25)
						drop.Combo:Dock(FILL)

						for k, v in pairs (ent.SpecialEffectRoles) do
							drop.Combo:AddChoice(k .. ": " .. v, k)
						end
						drop.Combo:SetValue(v2.sfx_role .. ": " .. ent.SpecialEffectRoles[v2.sfx_role])
						function drop.Combo.OnSelect(_, index, value, data)
							ent2:DoInput("cpoint_position_sfx_role", k, data)
						end
				
						drop:SetHeight(25)
						drop:Dock(TOP)
						drop:DockMargin(padding,padding,padding,0)
						//drop:DockMargin(padding,padding-9,padding,0) //-9 to base the "top" off the text, not the box
						function drop.PerformLayout(_, w, h)
							drop.Label:SetWide(w / 2.4)
						end

						if ent.SpecialEffectAddRoleControls then ent:SpecialEffectAddRoleControls(self, pnl, k, v2, ent2) end
					end
				elseif mode == PARTCTRL_CPOINT_MODE_VECTOR then
					local tab1 = PartCtrl_ProcessedPCFs[pcf][name].cpoints[k]
					local tab = tab1.vector[tab1.which]
					if istable(tab) then
						//Roll sets the angle of the particle, with the putput measured in radians (pi radians = 180 degrees). Output maximum/minimum sets how many radians it can be rotated up to, 
						//with values past pi just rotating it past 180 degrees. With a standard render_animated_sprites, only the x value does anything, regardless of orientation type. With render 
						//models, this is broken and spawns models at random rotations regardless of the cpoint value.
						//Position sets the position of the particle, with the output measured in hammer units i think?
						//Color sets the color of the particle, with the output measured in 0 0 0 = black and 1 1 1 = white. Output values under 0 or over 1 don't seem to do anything different, so
						//no additive color or negative color wackiness here.
	
						if tab.colorpicker then
							local col = vgui.Create("DColorMixer", pnl)
							col:SetAlphaBar(false)
							col:Dock(TOP)
							col:DockMargin(padding,betweenitems,padding,0)
							col:SetLabel(tab.label)
	
							function col.PerformLayout(self, x, y)
								//Modified version of CtrlColor:PerformLayout (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/spawnmenu/controls/ctrlcolor.lua#L13)
								//Only does palette button sizes, doesn't clamp their sizes and resizes them more smoothly
								local ColorRows = #self.Palette:GetChildren() / 3
								self.Palette:SetButtonSize(self:GetWide() / ColorRows)
							end

							local vec = Vector(v2.val)
							vec.x = math.Remap(vec.x, tab.inMin.x, tab.inMax.x, tab.outMin2.x, tab.outMax2.x)
							vec.y = math.Remap(vec.y, tab.inMin.y, tab.inMax.y, tab.outMin2.y, tab.outMax2.y)
							vec.z = math.Remap(vec.z, tab.inMin.z, tab.inMax.z, tab.outMin2.z, tab.outMax2.z)
							col:SetVector(vec)
							function col.ValueChanged(_, val)
								local vec = Vector()
								vec.x = math.Remap(val.r/255, tab.outMin2.x, tab.outMax2.x, tab.inMin.x, tab.inMax.x)
								vec.y = math.Remap(val.g/255, tab.outMin2.y, tab.outMax2.y, tab.inMin.y, tab.inMax.y)
								vec.z = math.Remap(val.b/255, tab.outMin2.z, tab.outMax2.z, tab.inMin.z, tab.inMax.z)
								ent2:DoInput("cpoint_vector_val_all", k, vec)
							end

							//TODO: how should we handle an axis being overwritten by output_axis?
						elseif tab.textentry then
							local done_first = false
							for i = 1, 3 do
								if tab1["which_" .. i-1] != -1 then //don't create an entry for an axis that's being overwritten by output_axis
									local entrypnl = vgui.Create("Panel", pnl)
									entrypnl:SetHeight(20)
									entrypnl:Dock(TOP)
									if !done_first then
										entrypnl:DockMargin(padding,padding,padding,3)
										done_first = true
									else
										entrypnl:DockMargin(padding,0,padding,3) //no top padding, squish these 3 together
									end
							
									local label = vgui.Create("DLabel", entrypnl)
									label:SetDark(true)
									if i == 1 then
										label:SetText(tab.label .. " X")
									elseif i == 2 then
										label:SetText(tab.label .. " Y")
									else
										label:SetText(tab.label .. " Z")
									end
									label:Dock(LEFT)
							
									local entry = vgui.Create("DTextEntry", entrypnl)
									entry:SetNumeric(true)
									entry:SetHeight(20)
									entry:Dock(FILL)
									local val = math.Remap(v2.val[i], tab.inMin[i], tab.inMax[i], tab.outMin[i], tab.outMax[i])
									if tab.decimals != nil then val = math.Round(val, tab.decimals) end
									entry:SetText(val)
							
									entry.OnEnter = function()
										//Set the displayed text to the actual number value we're using
										local val = math.Clamp(tonumber(entry:GetText()) or 0, tab.outMin[i], tab.outMax[i])
										if tab.decimals != nil then val = math.Round(val, tab.decimals) end
										entry:SetText(val)

										//Then send it to the server
										val = math.Remap(val, tab.outMin[i], tab.outMax[i], tab.inMin[i], tab.inMax[i])
										ent2:DoInput("cpoint_vector_val_axis", k, i, val)
									end
									entry.OnFocusChanged = function(_, b) 
										if !b then entry:OnEnter() end
									end

									function entrypnl.PerformLayout(_, w, h)
										local w2, h2 = label:GetTextSize()
										label:SetWide(w2 + padding*2)
									end
								end
							end
							if tab.textentry.info then
								local text = vgui.Create("DLabel", pnl)
								text:SetDark(true)
								text:SetWrap(true)
								text:SetTextInset(0, 0)
								text:SetText(tab.textentry.info)
								text:SetContentAlignment(5)
								text:SetAutoStretchVertical(true)
								text:DockMargin(padding,betweenitems,padding,0)
								text:Dock(TOP)
							end
						else
							local done_first = false
							for i = 1, 3 do
								if tab1["which_" .. i-1] != -1 then //don't create a slider for an axis that's being overwritten by output_axis
									local slider = vgui.Create("DNumSlider", pnl)
									if tab.label == "Roll" then
										if i == 1 then
											slider:SetText("Pitch")
										elseif i == 2 then
											slider:SetText("Yaw")
										else
											slider:SetText("Roll")
										end
										slider:SetMinMax(-180, 180)
									else
										if tab.label == "Velocity" or "Velocity Direction" then
											if i == 1 then
												slider:SetText(tab.label .. " Back/Fwd")
											elseif i == 2 then
												slider:SetText(tab.label .. " Right/Left")
											else
												slider:SetText(tab.label .. " Down/Up")
											end
										else
											if i == 1 then
												slider:SetText(tab.label .. " X")
											elseif i == 2 then
												slider:SetText(tab.label .. " Y")
											else
												slider:SetText(tab.label .. " Z")
											end
										end
										slider:SetMinMax(tab.outMin[i], tab.outMax[i])
									end
									if tab.default != nil then
										slider:SetDefaultValue(math.Remap(tab.default[i], tab.inMin[i], tab.inMax[i], tab.outMin[i], tab.outMax[i]))
									else
										slider:SetDefaultValue(0)
									end
									slider:SetDark(true)
									slider:SetHeight(18)
									slider:Dock(TOP)
									if !done_first then
										slider:DockMargin(padding,betweenitems,0,3)
										done_first = true
									else
										slider:DockMargin(padding,0,0,3) //no top padding, squish these 3 together
									end
		
									//Go ahead and unclamp these; for pos, they won't do anything anyway, and for roll, they just keep rotating
									slider.ValueChanged = SliderValueChangedUnclamped
									slider.SetValue = SliderSetValueUnclamped
			
									if tab.label == "Roll" then
										slider:SetValue(math.Remap(math.deg(v2.val[i]), tab.inMin[i], tab.inMax[i], tab.outMin[i], tab.outMax[i]))
									else
										slider:SetValue(math.Remap(v2.val[i], tab.inMin[i], tab.inMax[i], tab.outMin[i], tab.outMax[i]))
									end
									function slider.OnValueChanged(_, val)
										if tab.label == "Roll" then
											val = math.Remap(math.rad(val), tab.outMin[i], tab.outMax[i], tab.inMin[i], tab.inMax[i])
										else
											val = math.Remap(val, tab.outMin[i], tab.outMax[i], tab.inMin[i], tab.inMax[i])
										end
										ent2:DoInput("cpoint_vector_val_axis", k, i, val)
									end
								end
							end
						end
					end
				elseif mode == PARTCTRL_CPOINT_MODE_AXIS then
					local slidercount = 0
					for i = 1, 3 do
						local tab = PartCtrl_ProcessedPCFs[pcf][name].cpoints[k]
						tab = tab.axis[tab["which_" .. i-1]]
						if istable(tab) then
							//For axis controls, min/max are optional. If a value isn't supplied, then use an arbitrary value and unclamp the slider in that direction.
							local unclampMin = (tab.inMin == nil and tab.outMin == nil)
							local unclampMax = (tab.inMax == nil and tab.outMax == nil)
							local inMin = tab.inMin or -10
							local inMax = tab.inMax or 10
							local outMin = tab.outMin or -10
							local outMax = tab.outMax or 10
	
							if tab.dropdown then
								local drop = vgui.Create("Panel", pnl)
	
								drop.Label = vgui.Create("DLabel", drop)
								drop.Label:SetDark(true)
								drop.Label:SetText(tab.label)
								drop.Label:Dock(LEFT)
						
								drop.Combo = vgui.Create("DComboBox", drop)
								drop.Combo:SetHeight(25)
								drop.Combo:Dock(FILL)
	
								if tab.dropdown[v2.val[i]] then
									drop.Combo:SetValue(v2.val[i] .. ": " .. tab.dropdown[v2.val[i]])
								end
								for k, v in pairs (tab.dropdown) do
									drop.Combo:AddChoice(k .. ": " .. v, k)
								end
								function drop.Combo.OnSelect(_, index, value, data)
									ent2:DoInput("cpoint_axis_val", k, i, data)
								end
						
								drop:SetHeight(25)
								drop:Dock(TOP)
								drop:DockMargin(padding,betweenitems,padding,0)
								//drop:DockMargin(padding,padding-9,padding,0) //-9 to base the "top" off the text, not the box
								function drop.PerformLayout(_, w, h)
									drop.Label:SetWide(w / 2.4)
								end
							elseif tab.checkboxes then
								local checkboxes = {}
								for checkk, checkv in SortedPairs (tab.checkboxes) do
									local check = vgui.Create( "DCheckBoxLabel", pnl)
									check:SetText(checkv)
									check:SetDark(true)
									check:SetHeight(15)
									check:Dock(TOP)
									check:DockMargin(padding,betweenitems,0,0)
									checkboxes[checkk] = check
						
									check:SetValue(bit.band(checkk, v2.val[i]) == checkk)
									check.OnChange = function(_, val)
										local total = 0
										for checkk2, checkv2 in pairs (checkboxes) do
											if checkv2:GetChecked() then total = total + checkk2 end
										end
										ent2:DoInput("cpoint_axis_val", k, i, total)
									end
								end
							else
								local slider = vgui.Create("DNumSlider", pnl)
								slider:SetText(tab.label)
								if outMax < outMin then
									//tf2 speech_mediccall has a silly outmax of 0 and outmin of 1, presumably because the player's health percentage is used as the input. stop it from breaking the slider.
									slider:SetMinMax(outMax, outMin)
								else
									slider:SetMinMax(outMin, outMax)
								end
								if tab.default != nil then
									slider:SetDefaultValue(math.Remap(tab.default, inMin, inMax, outMin, outMax))
								else
									slider:SetDefaultValue(0)
								end
								if tab.decimals != nil then slider:SetDecimals(tab.decimals) end //don't "or" this because then it won't work if it's set to 0
								slider:SetDark(true)
								slider:SetHeight(18)
								slider:Dock(TOP)
								slidercount = slidercount + 1
								if slidercount == 1 then
									slider:DockMargin(padding,betweenitems,0,3)
								else
									slider:DockMargin(padding,0,0,3) //no top padding, squish these 3 together
								end
	
								//Only unclamp these if they're using a fallback value, otherwise they'll either A: do nothing, or B: in case of "Emission Count Scale" going below 0, crash
								if unclampMin and unclampMax then
									slider.ValueChanged = SliderValueChangedUnclamped
									slider.SetValue = SliderSetValueUnclamped
								elseif unclampMin then
									slider.ValueChanged = SliderValueChangedUnclampedMin
									slider.SetValue = SliderSetValueUnclampedMin
								elseif unclampMax then
									slider.ValueChanged = SliderValueChangedUnclampedMax
									slider.SetValue = SliderSetValueUnclampedMax
								end
	
								slider:SetValue(math.Remap(v2.val[i], inMin, inMax, outMin, outMax))
								slider.val = slider:GetValue()
								function slider.OnValueChanged(_, val)
									if tab.decimals != nil then
										val = math.Round(val, tab.decimals)
										if val == slider.val then return end //don't send updates if the number didn't actually change
										slider.val = val
									end
									val = math.Remap(val, outMin, outMax, inMin, inMax)
									ent2:DoInput("cpoint_axis_val", k, i, val)
								end
							end
						end
					end
				end
			end
			pnl.RebuildContents(v)
			self.CPointCategories[ent2][k] = pnl
	
		end

	end


	//Container for all panels
	local back = vgui.Create("DPanel", self)
	back.Paint = function(self, w, h)
		derma.SkinHook("Paint", "CategoryList", self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
		return false
	end
	back:Dock(FILL)


	//Add lower bar for pause and reset controls; both particles and special fx have this
	local trackpnl = vgui.Create("Panel", back)
	trackpnl:Dock(BOTTOM)
	trackpnl:DockMargin(5,5,5,5)

	local pause = vgui.Create("DImageButton", trackpnl)
	pause:SetImage("icon16/control_pause_blue.png")
	pause:SetStretchToFit(false)
	pause:SetDrawBackground(true)
	pause:SetIsToggle(true)
	pause:SetToggle(false)
	pause:Dock(LEFT)
	pause:SetWide(32)
	pause:SetTooltip("Pause particle effect\n\nIf the effect is modified, restarted, disabled-then-reenabled, or duplicated,\nthen it will play up to and then re-pause at the same point in time.")

	function pause.Think()
		//NOTE: This can be changed without clicking on the button by using the numpad key to pause/unpause
		if ent and ent.GetPauseTime then //don't cause an error when the ent is removed
			pause:SetToggle(ent:GetPauseTime() >= 0)
		end
	end
	function pause.OnToggled(val)
		ent:DoInput("effect_pause")
	end
	if ent.utilfx then
		pause:SetDisabled(true)
		pause:SetImage("icon16/control_pause.png") //gray icon
		pause:SetTooltip("Pausing not available for scripted effects")
	end

	local text = vgui.Create("DLabel", trackpnl)
	text:SetDark(true)
	text:DockMargin(5,0,0,0)
	text:Dock(FILL)

	function text.Think()
		if ent and ent.GetPauseTime then //don't cause an error when the ent is removed
			local pausetime = ent:GetPauseTime()
			local newtext = ""
			if pausetime >= 0 and ent.ParticleStartTime != nil then
				if pausetime <= (CurTime() - ent.ParticleStartTime) then
					newtext = "Paused at " .. tostring(math.Round(pausetime, 2)) .. " secs"
				else
					newtext = "Pausing at " .. tostring(math.Round(pausetime, 2)) .. " secs (in " .. tostring(-math.Round(CurTime() - ent.ParticleStartTime - pausetime, 2)) .. " secs)"
				end
			end
			if newtext != text:GetText() then
				text:SetText(newtext)
			end
		end
	end

	local restart = vgui.Create("DImageButton", trackpnl)
	restart:SetImage("icon16/control_repeat_blue.png")
	restart:SetStretchToFit(false)
	restart:SetDrawBackground(true)
	restart:Dock(RIGHT)
	restart:SetWide(32)
	if !ent.utilfx then
		restart:SetTooltip("Restart particle effect, and clean up all particles")
	else
		restart:SetTooltip("Restart particle effect")
	end

	function restart.DoClick()
		ent:DoInput("effect_restart")
	end


	if ent.PartCtrl_Ent then
		
		local container = vgui.Create("DCategoryList", back)
		container.Paint = function(self, w, h)
			return false
		end
		container:Dock(FILL)
		
		BuildParticleEntControls(ent, container)

	elseif ent.PartCtrl_SpecialEffect then

		//Special effect controls have two columns - left column is for options on the special effect itself, right column is for child fx

		local lcontainer = vgui.Create("DCategoryList", back)
		lcontainer.Paint = function(self, w, h)
			return false
		end
		lcontainer:DockMargin(0,0,0,0)

		local rcontainer = vgui.Create("DCategoryList", back)
		rcontainer.Paint = function(self, w, h)
			return false
		end
		rcontainer:DockMargin(0,0,0,0)

		local divider = vgui.Create("DHorizontalDivider", back)
		divider:Dock(FILL)
		divider:SetLeft(lcontainer)
		divider:SetRight(rcontainer)
		divider:SetDividerWidth(4)//(8)
		//divider:SetLeftMin()
		//divider:SetRightMin()
		//stupid hack: bullet sfx controls are exactly the right size to make the divider confused as to whether it should add a slider or not,
		//so resolve this by making it wider at first to settle it down and resolve it.
		divider:SetLeftWidth(360)
		timer.Simple(math.max(0.06, FrameTime()*2), function()
			if IsValid(divider) then
				divider:SetLeftWidth(352)
			end
		end)


		//category for info; no header for this one
		local info = ent.Information
		if info then
	
			local pnl = vgui.Create("DSizeToContents", lcontainer)
			pnl:SetSizeX(false)
			pnl:Dock(FILL)
			lcontainer:AddItem(pnl)
			pnl.Paint = function(self, w, h) 
				draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
				//draw info icon
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(icon_info)
				//surface.DrawTexturedRect(padding,betweenitems,16,16)
				surface.DrawTexturedRect(padding,(h/2)-8,16,16)
			end
			pnl:DockPadding(16+padding,0,0,padding) //extra left to make room for the info icon; DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
			pnl:DockMargin(3,3,-2,3-2) //-2 bottom because there's too much space between this and the next category otherwise; -2 right for divider
	
			local text = vgui.Create("DLabel", pnl)
			text:SetDark(true)
			text:SetWrap(true)
			text:SetTextInset(0, 0)
			text:SetText(info)
			text:SetContentAlignment(5)
			text:SetAutoStretchVertical(true)
			text:DockMargin(padding,padding-1,padding,0) //padding-1 for top is trial and error, results in nice 16px spacing on both top and bottom of text
			text:Dock(TOP)
	
		end


		//Category for attaching this effect
		local cat = vgui.Create("DCollapsibleCategory", lcontainer)
		cat:SetLabel("Attachment Settings")
		cat:DockMargin(3,3,-2,3) //-2 right for divider
		cat:Dock(FILL)
		lcontainer:AddItem(cat)
		cat:SetExpanded(true)

		local pnl = vgui.Create("DSizeToContents", cat)
		pnl:Dock(FILL)
		cat:SetContents(pnl)
		pnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
		pnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents
		self.SpecialEffect_AttachOptions = pnl //make this externally accessible so other funcs can rebuild it

		//Rebuild the contents of this category whenever the parent entity is changed
		function pnl.RebuildContents()

			pnl:Clear()

			//filler to ensure pnl is stretched to full width
			local filler = vgui.Create("Panel", pnl)
			filler:Dock(TOP)
			filler:SetHeight(0)

			local modelent = ent:GetSpecialEffectParent()
			if IsValid(modelent) then
				if IsValid(modelent.AttachedEntity) then modelent = modelent.AttachedEntity end

				local button = vgui.Create("DButton", pnl)
				//button:SetWidth(button:GetWide() + 14) //+ 4)
				button:SetHeight(30)
				button:Dock(TOP)
				//button:DockMargin(0,0,0,0)
				button:DockMargin(padding,padding,padding,0)

				pnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item

				if modelent.PartCtrl_Grip then
					button:SetText("Attach to model")
					button:SizeToContents()
					button.DoClick = function()
						surface.PlaySound("ui/buttonclickrelease.wav")
						ent:DoInput("attachment_ent_setwithtool")
					end
				else
					if modelent:GetNWBool("PartCtrl_MergedGrip") and IsValid(modelent:GetParent()) then
						button:SetText("Unmerge from model (" .. string.GetFileFromFilename(modelent:GetParent():GetModel()) .. ")")
					else
						button:SetText("Detach from model (" .. string.GetFileFromFilename(modelent:GetModel()) .. ")")
					end
					button:SizeToContents()
					button.DoClick = function()
						ent:DoInput("attachment_ent_detach")
					end

					local attachcount = 0
					local tab = modelent:GetAttachments()
					if istable(tab) then attachcount = table.Count(tab) end

					if attachcount > 0 then
						local slider = vgui.Create("DNumSlider", pnl)
						slider:SetText("Attachment")
						slider:SetDecimals(0)
						slider:SetMinMax(0, attachcount)
						slider:SetDefaultValue(0)
						slider:SetDark(true)
						slider:SetHeight(18)
						slider:Dock(TOP)
						slider:DockMargin(padding,betweenitems,0,3)
				
						slider:SetValue(ent:GetAttachmentID())
						function slider.OnValueChanged(_, val)
							val = math.Round(val)
							if val != slider.PartCtrl_AttachSlider.attach then //only send updates on whole numbers
								surface.PlaySound("weapons/pistol/pistol_empty.wav")
								slider.PartCtrl_AttachSlider.attach = val
								ent:DoInput("attachment_attach", val)
							end
						end

						//Let the HUDPaint hook in autorun detect that the player is hovering over this slider
						slider.PartCtrl_AttachSlider = {ent = modelent, attach = ent:GetAttachmentID()}
						slider.Slider.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider
						slider.Slider.Knob.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
						slider.TextArea.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
						slider.Label.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
						slider.Scratch.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
					end
				end

			end

		end

		pnl.RebuildContents()

		
		//Add numpad + loop controls for special fx if applicable; do this here so we have just a bit less duplicate code
		if ent.GetNumpad and ent.GetNumpadToggle and ent.GetNumpadStartOn and ent.GetLoop and ent.GetLoopDelay and ent.GetLoopSafety then
			
			//category for key
			local cat = vgui.Create("DCollapsibleCategory", lcontainer)
			cat:SetLabel("Key Settings")
			cat:DockMargin(3,1,-2,3) //-2 right for divider
			cat:Dock(FILL)
			lcontainer:AddItem(cat)
		
			//expand if any contained options are non-default 
			cat:SetExpanded(
				((ent:GetNumpadMode() or 0) != 0)
				or ((ent:GetNumpad() or 0) != 0)
				or (ent:GetNumpadToggle() != true)
				or (ent:GetNumpadStartOn() != true)
				//considered also adding a check here to make sure the effect isn't disabled, but i don't think that's possible without a numpad key set
			)
		
			local rpnl = vgui.Create("DSizeToContents", cat) //call this one rpnl and not pnl, just so we don't have to rewrite the numpad stuff copied from animprop that already has a panel with that name
			rpnl:Dock(FILL)
			cat:SetContents(rpnl)
			rpnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
			rpnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
			rpnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents

				local drop = vgui.Create("Panel", rpnl)

				drop.Label = vgui.Create("DLabel", drop)
				drop.Label:SetDark(true)
				drop.Label:SetText("Key Function")
				drop.Label:Dock(LEFT)

				drop.Combo = vgui.Create("DComboBox", drop)
				drop.Combo:SetHeight(25)
				drop.Combo:Dock(FILL)

				local numpadmode0 = "Disable/enable effect"
				local numpadmode1 = "Pause/unpause effect"
				local numpadmode2 = "Restart effect"
				local val = ent:GetNumpadMode() or 0
				if val == 0 then
					drop.Combo:SetValue(numpadmode0)
				elseif val == 1 then
					drop.Combo:SetValue(numpadmode1)
				elseif val == 2 then
					drop.Combo:SetValue(numpadmode2)
				end
				drop.Combo:AddChoice(numpadmode0, 0)
				drop.Combo:AddChoice(numpadmode1, 1)
				drop.Combo:AddChoice(numpadmode2, 2)
				function drop.Combo.OnSelect(_, index, value, data)
					ent:DoInput("numpad_mode", data)

					//"toggle" option is grayed out for numpad mode 2 (restart effect); make sure it's always true to prevent unintended behavior 
					//("restart effect" with toggle off makes the effect restart on both key in and key out, instead of just key in)
					if data > 1 then
						back.NumpadToggleCheckbox:SetValue(true)
					end
					//"start on" option is grayed out for numpad mode 1 (pause/unpause) and numpad mode 2 (restart effect); make sure it's true to prevent unintended behavior
					if data > 0 then
						back.NumpadStartOnCheckbox:SetValue(true)
					end
				end
			
				drop:SetHeight(25)
				drop:Dock(TOP)
				drop:DockMargin(padding,padding-9,padding,0) //-9 to base the "top" off the text, not the box
				function drop.PerformLayout(_, w, h)
					drop.Label:SetWide(w / 2.4)
				end

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
		
				numpadpnl.numpad:SetSelectedNumber(ent:GetNumpad() or 0)
				function numpadpnl.numpad.SetValue(_, val)
					numpadpnl.numpad:SetSelectedNumber(val)
					ent:DoInput("numpad_num", val)
				end
		
				pnl:Dock(TOP)
				//pnl:DockMargin(padding,betweenitems-3,0,padding) //numpad label is 3px too tall, compensate for it here
				//pnl:DockMargin(padding,padding-3,0,padding) //numpad label is 3px too tall, compensate for it here
				//pnl:DockMargin(padding,padding-3,0,0) //numpad label is 3px too tall, compensate for it here
				pnl:DockMargin(padding,betweenitems-3,0,0) //numpad label is 3px too tall, compensate for it here
				pnl:SetHeight(70)
				//function pnl.Paint(_, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(255,0,0,70)) end //for testing the full size of this panel
		
				local anotherpnl = vgui.Create("Panel", pnl)
				anotherpnl:Dock(LEFT)
				anotherpnl:SetWidth(90)
		
				local check = vgui.Create("DCheckBoxLabel", anotherpnl)
				back.NumpadToggleCheckbox = check
				check:SetText("Toggle")
				check:SetDark(true)
				check:SetHeight(15)
				check:Dock(TOP)
				check:DockMargin(8,28,0,0)
		
				check:SetValue(ent:GetNumpadToggle())
				check.OnChange = function(_, val)
					ent:DoInput("numpad_toggle", val)
				end
				check.Think = function()
					if !IsValid(ent) then return end

					if ent:GetNumpadMode() > 1 then
						check:SetDisabled(true)
						//check:SetTooltip("Option not available for restart mode") //never mind, tooltips don't work on disabled checkboxes
					else
						check:SetDisabled(false)
						//check:SetTooltip("") //TODO: use this if we're creating tooltips for everything
					end
				end
		
				local check = vgui.Create("DCheckBoxLabel", anotherpnl)
				back.NumpadStartOnCheckbox = check
				check:SetText("Start on")
				check:SetDark(true)
				check:SetHeight(15)
				check:Dock(BOTTOM)
				check:DockMargin(8,0,0,8)
		
				check:SetValue(ent:GetNumpadStartOn())
				check.OnChange = function(_, val)
					ent:DoInput("numpad_starton", val)
				end
				check.Think = function()
					if !IsValid(ent) then return end

					if ent:GetNumpadMode() > 0 then
						check:SetDisabled(true)
						//check:SetTooltip("Option only available for enable/disable mode - use pause button below") //never mind, tooltips don't work on disabled checkboxes
					else
						check:SetDisabled(false)
						//check:SetTooltip("") //TODO: use this if we're creating tooltips for everything
					end
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
					if !IsValid(ent) then return end
		
					local numpadisdisabling = ent:GetNumpadState()
					local starton = ent:GetNumpadStartOn()
					if !starton then
						numpadisdisabling = !numpadisdisabling
					end
		
					if numpadisdisabling then
						pnldisabled:SetAlpha(255)
		
						local newtext = nil
						if ent:GetNumpadToggle() then
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
			local cat = vgui.Create("DCollapsibleCategory", lcontainer)
			cat:SetLabel("Repeat Settings")
			cat:DockMargin(3,1,-2,3) //-2 right for divider
			cat:Dock(FILL)
			lcontainer:AddItem(cat)
		
			local default_looptime = ent.DefaultLoopTime
			local default_loopmode = true
		
			//expand if any contained options are non-default 
			cat:SetExpanded(
				((ent:GetLoop() or true) != default_loopmode)
				or ((math.Round(ent:GetLoopDelay(), 6) or 0) != default_looptime)
				or (ent:GetLoopSafety() != false)
			)
		
			local rpnl = vgui.Create("DSizeToContents", cat) //call this one rpnl and not pnl, just so we don't have to rewrite the numpad stuff copied from animprop that already has a panel with that name
			rpnl:Dock(FILL)
			cat:SetContents(rpnl)
			rpnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
			rpnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
			rpnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents
		
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
				local val = ent:GetLoop()
				if !val then
					drop.Combo:SetValue(loopmode0)
				else
					drop.Combo:SetValue(loopmode2)
				end
				drop.Combo:AddChoice(loopmode0, false)
				drop.Combo:AddChoice(loopmode2, true)
				function drop.Combo.OnSelect(_, index, value, data)
					ent:DoInput("loop_mode", data)
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
					if !IsValid(ent) then return end
		
					//Disable the slider if set to "do not repeat"
					if !ent:GetLoop() then
						slider:SetMouseInputEnabled(false)
						slider:SetAlpha(75)
					else
						slider:SetMouseInputEnabled(true)
						slider:SetAlpha(255)
					end
				end
		
				slider.ValueChanged = SliderValueChangedUnclampedMax
				slider.SetValue = SliderSetValueUnclampedMax
		
				slider:SetValue(ent:GetLoopDelay() or 0.00)
				function slider.OnValueChanged(_, val)
					ent:DoInput("loop_delay", val)
				end
		
				local check = vgui.Create( "DCheckBoxLabel", rpnl)
				check:SetText("Clean up particles when disabled or repeated")
				check:SetDark(true)
				check:SetHeight(15)
				check:Dock(TOP)
				check:DockMargin(padding,betweenitems,0,0)
	
				check:SetValue(ent:GetLoopSafety())
				check.OnChange = function(_, val)
					ent:DoInput("loop_safety", val)
				end

				local help = vgui.Create("DLabel", rpnl)
				help:SetDark(true)
				help:SetWrap(true)
				help:SetTextInset(0, 0)
				help:SetText("If checked, all existing particles are removed when the effect repeats, or when it's disabled by pressing the key.")
				//help:SetContentAlignment(5)
				help:SetAutoStretchVertical(true)
				//help:DockMargin(32,0,32,8)
				help:DockMargin(padding_help,betweenitems_help,padding_help,0)
				help:Dock(TOP)
				help:SetTextColor(color_helpdark)

		end

		
		//Add special effect-specific controls
		ent:SpecialEffectAddControls(self, lcontainer)


		//Add child effect controls

		//category for "add new effect" button; no header for this one
		local pnl2 = vgui.Create("DSizeToContents", rcontainer)
		pnl2:SetSizeX(false)
		pnl2:Dock(TOP)
		rcontainer:AddItem(pnl2)
		//cat:SetContents(pnl2)
		pnl2.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70)) end
		pnl2:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
		pnl2:DockMargin(-2,3,3,3) //fix the 1px of blank white space between the header and the contents; 0 left for divider
		
		local button = vgui.Create("DButton", pnl2)
		button:DockMargin(padding,padding,padding,0)
		button:SetHeight(30)
		button:Dock(TOP)

		button:SetText("Add particle effect to " .. ent.PartCtrl_ShortName)
		button:SizeToContents()
		button.DoClick = function()
			surface.PlaySound("ui/buttonclickrelease.wav")
			ent:DoInput("child_setwithtool")
		end


		rcontainer.ChildControls = {}
		self.SpecialEffect_ChildList = rcontainer //make this externally accessible so other funcs can rebuild it

		//This is called below for each child we have when creating this panel, and also called externally when child fx are updated, to add/remove fx from this panel after the fact.
		function rcontainer.AddOrRemoveChild(child)

			if !IsValid(ent) or !ent.SpecialEffectChildren then return end

			if ent.SpecialEffectChildren[child] and child.PartCtrl_Ent then

				if !IsValid(rcontainer.ChildControls[child]) then

					//This effect is a new child, add controls for it
					local cat = vgui.Create("DCollapsibleCategory", rcontainer)
					cat:SetLabel(GetParticleName(child))
					cat.Header:SetToolTip(GetParticleName(child)) //these names can get really long, show the whole name on hover
					cat:DockMargin(-2,1,3,3) //need extra +1 on left and right to match the margins of first-level category; 0 left for divider
					cat:Dock(TOP)
					rcontainer:AddItem(cat)
					cat:SetExpanded(true)
	
					local container2 = vgui.Create("DCategoryList", cat)
					container2.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
					container2:DockPadding(-30,0,-30,0)
					container2:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents
					container2.pnlCanvas:DockPadding(2-1,2-1,2-1,2+2) //need extra -1 on left and right to match the padding of first-level category (this is stupid); also extra +2 on bottom and -1 on top as well (this is stupider)
					container2:Dock(FILL)
					cat:SetContents(container2)
					cat.container = container2

					rcontainer.ChildControls[child] = cat

					//Set the child's edit window to this one, so that info table updates and such will update these controls
					child.PartCtrlWindow = self

					BuildParticleEntControls(child, rcontainer.ChildControls[child].container)

					local button = vgui.Create("DButton", rcontainer.ChildControls[child].container)
					button:DockMargin(padding,1,padding,0) //1 on top makes it match the margins of all the collapsibles for cpoints
					//button:DockMargin(3,1,3,0) //alternate style, make it take up the same form factor as the collapsibles; looks a bit odd when compared to other buttons
					button:SetHeight(30)
					button:Dock(TOP)

					button:SetText("Detach " .. child:GetParticleName())
					button:SizeToContents()
					button.DoClick = function()
						ent:DoInput("child_detach", child)

					end

				end

			elseif IsValid(rcontainer.ChildControls[child]) then

				//This effect is no longer a child, remove its controls
				rcontainer.ChildControls[child]:Remove()
				rcontainer.ChildControls[child] = nil

			end

		end

		//Add categories for each child effect
		for child, _ in pairs (ent.SpecialEffectChildren) do
			rcontainer.AddOrRemoveChild(child)
		end

	end

end




function PANEL:Think()

	local ent = self.m_Entity
	if !IsValid(ent) then self:OnEntityLost() return end
	if ent.PartCtrlWindow != self and IsValid(ent.PartCtrlWindow) then self:OnEntityLost() return end //make sure we don't open duplicate control windows
	ent.PartCtrlWindow = self

end

function PANEL:EntityLost()

	self:Clear()
	self:OnEntityLost()

end

function PANEL:OnEntityLost()
	-- For override
end




vgui.Register("PartCtrlEditor", PANEL, "Panel")