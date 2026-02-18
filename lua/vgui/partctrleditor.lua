AddCSLuaFile()

local PANEL = {}

local svproj_enabled = GetConVar("sv_peplus_allowserverprojectiles")




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
	if ent.PEPlus_Ent then
		//return "Particle Effects+ Entity [" .. tostring(ent:EntIndex()) .. "]: " .. ent:GetParticleName() .. " (" .. ent:GetPCF() .. ")")
		local pcf = PEPlus_GetGamePCF(ent:GetPCF(), ent:GetPath())
		return PEPlus_ProcessedPCFs[pcf][ent:GetParticleName()].nicename .. " (" .. PEPlus_GetDataPCFNiceName(pcf) .. ")"
	else
		return ent.PrintName .. " [" .. tostring(ent:EntIndex()) .. "]"
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

		local pcf = PEPlus_GetGamePCF(ent2:GetPCF(), ent2:GetPath())
		local name = ent2:GetParticleName()
	
	
		//category for info; no header for this one
		local info = PEPlus_ProcessedPCFs[pcf][name].info
		local info2 = PEPlus_ProcessedPCFs[pcf][name].info_sfx
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
			text:SetText(table.concat(info, "\n"))
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

			local default_looptime = PEPlus_ProcessedPCFs[pcf][name].default_time or 0
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
				local mode = PEPlus_ProcessedPCFs[pcf][name].cpoints[k].mode
				if mode == PEPLUS_CPOINT_MODE_POSITION then
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
		
							if modelent.PEPlus_Grip then
								button:SetText("Attach to model")
								button:SizeToContents()
								button.DoClick = function()
									surface.PlaySound("ui/buttonclickrelease.wav")
									ent2:DoInput("cpoint_position_ent_setwithtool", k)
								end
							else
								if (modelent.GetPEPlus_MergedGrip and modelent:GetPEPlus_MergedGrip()) and IsValid(modelent:GetParent()) then
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
										if val != slider.PEPlus_AttachSlider.attach then //only send updates on whole numbers
											surface.PlaySound("weapons/pistol/pistol_empty.wav")
											slider.PEPlus_AttachSlider.attach = val
											ent2:DoInput("cpoint_position_attach", k, val)
										end
									end
		
									//Let the HUDPaint hook in autorun detect that the player is hovering over this slider
									slider.PEPlus_AttachSlider = {ent = modelent, attach = v2.attach}
									slider.Slider.PEPlus_AttachSlider = slider.PEPlus_AttachSlider
									slider.Slider.Knob.PEPlus_AttachSlider = slider.PEPlus_AttachSlider 
									slider.TextArea.PEPlus_AttachSlider = slider.PEPlus_AttachSlider 
									slider.Label.PEPlus_AttachSlider = slider.PEPlus_AttachSlider 
									slider.Scratch.PEPlus_AttachSlider = slider.PEPlus_AttachSlider 
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
				elseif mode == PEPLUS_CPOINT_MODE_AXIS then
					local tab = {
						[1] = PEPlus_ProcessedPCFs[pcf][name].cpoints[k].axis_0,
						[2] = PEPlus_ProcessedPCFs[pcf][name].cpoints[k].axis_1,
						[3] = PEPlus_ProcessedPCFs[pcf][name].cpoints[k].axis_2
					}
					if istable(tab[1]) and istable(tab[2]) and istable(tab[3]) and tab[1].colorpicker then
						local col = vgui.Create("DColorMixer", pnl)
						col:SetAlphaBar(false)
						col:Dock(TOP)
						col:DockMargin(padding,betweenitems,padding,0)
						col:SetLabel(string.Replace(tab[1].label, ", ", "\n")) //replace commas with newlines, to try to reduce window stretching
						//adjust the label's height to accomodate multiline labels
						col.label:SizeToContents()
						col.label:SetTall(col.label:GetTall() + 7) //matches default height of 20 for one line

						function col.PerformLayout(self, x, y)
							//Modified version of CtrlColor:PerformLayout (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/spawnmenu/controls/ctrlcolor.lua#L13)
							//Only does palette button sizes, doesn't clamp their sizes and resizes them more smoothly
							local ColorRows = #self.Palette:GetChildren() / 3
							self.Palette:SetButtonSize(self:GetWide() / ColorRows)
						end

						local vec = Vector(v2.val)
						vec.x = math.Remap(vec.x, tab[1].inMin, tab[1].inMax, tab[1].outMin2, tab[1].outMax2)
						vec.y = math.Remap(vec.y, tab[2].inMin, tab[2].inMax, tab[2].outMin2, tab[2].outMax2)
						vec.z = math.Remap(vec.z, tab[3].inMin, tab[3].inMax, tab[3].outMin2, tab[3].outMax2)
						col:SetVector(vec)
						function col.ValueChanged(_, val)
							local vec = Vector()
							vec.x = math.Remap(val.r/255, tab[1].outMin2, tab[1].outMax2, tab[1].inMin, tab[1].inMax)
							vec.y = math.Remap(val.g/255, tab[2].outMin2, tab[2].outMax2, tab[2].inMin, tab[2].inMax)
							vec.z = math.Remap(val.b/255, tab[3].outMin2, tab[3].outMax2, tab[3].inMin, tab[3].inMax)
							ent2:DoInput("cpoint_axis_val_all", k, vec)
						end

						//TODO: currently, if an axis is being overwritten by output_axis, 
						//	we don't do the colorpicker at all. is there a better way?
					else
						local done_first = false
						for i = 1, 3 do
							local tab = tab[i]
							if istable(tab) and !tab.hidden then
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
									drop.Combo:SetSortItems(false) //disable alphabetical sorting, this doesn't work with numbers
		
									if tab.dropdown[v2.val[i]] then
										drop.Combo:SetValue(v2.val[i] .. ": " .. tab.dropdown[v2.val[i]])
									end
									for k, v in SortedPairs (tab.dropdown) do
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
									done_first = true
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
									done_first = true
								elseif tab.textentry then
									if tab.textentry.info and !done_first then
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

									local entrypnl = vgui.Create("Panel", pnl)
									entrypnl:SetHeight(20)
									entrypnl:Dock(TOP)
									if !done_first then
										entrypnl:DockMargin(padding,betweenitems,padding,3)
										done_first = true
									else
										entrypnl:DockMargin(padding,0,padding,3) //no top padding, squish these 3 together
									end
							
									local label = vgui.Create("DLabel", entrypnl)
									label:SetDark(true)
									label:SetText(tab.label)
									label:Dock(LEFT)
							
									local entry = vgui.Create("DTextEntry", entrypnl)
									entry:SetNumeric(true)
									entry:SetHeight(20)
									entry:Dock(FILL)
									local val = math.Remap(v2.val[i], tab.inMin, tab.inMax, tab.outMin, tab.outMax)
									if tab.decimals != nil then val = math.Round(val, tab.decimals) end
									entry:SetText(val)
							
									entry.OnEnter = function()
										//Set the displayed text to the actual number value we're using
										local val = math.Clamp(tonumber(entry:GetText()) or 0, tab.outMin, tab.outMax)
										if tab.decimals != nil then val = math.Round(val, tab.decimals) end
										entry:SetText(val)

										//Then send it to the server
										val = math.Remap(val, tab.outMin, tab.outMax, tab.inMin, tab.inMax)
										ent2:DoInput("cpoint_axis_val", k, i, val)
									end
									entry.OnFocusChanged = function(_, b) 
										if !b then entry:OnEnter() end
									end

									function entrypnl.PerformLayout(_, w, h)
										local w2, h2 = label:GetTextSize()
										label:SetWide(w2 + padding*2)
									end
								else
									local slider = vgui.Create("DNumSlider", pnl)
									slider:SetText(string.Replace(tab.label, ", ", "\n")) //replace commas with newlines, to try to reduce window stretching
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
									//adjust the slider's height to accomodate multiline labels
									slider.Label:SizeToContents()
									slider:SetHeight(slider.Label:GetTall() + 5) //matches old height of 18 for one line
									slider:Dock(TOP)
									if !done_first then
										slider:DockMargin(padding,betweenitems,0,3)
										done_first = true
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
						//if all controls are hidden, then don't show this cpoint
						if !done_first then
							cat:DockMargin(0,0,0,0)
							cat:Hide()
						end
					end
				end
			end
			pnl.RebuildContents(v)
			self.CPointCategories[ent2][k] = pnl
	
		end

	end


	local trackpnl_parent

	if ent.PEPlus_Ent then

		local back = vgui.Create("DPanel", self)
		back.Paint = function(self, w, h)
			derma.SkinHook("Paint", "CategoryList", self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
			return false
		end
		back:Dock(FILL)
			
		local container = vgui.Create("DCategoryList", back)
		container.Paint = function(self, w, h)
			return false
		end
		container:Dock(FILL)
		
		BuildParticleEntControls(ent, container)

		trackpnl_parent = back

	elseif ent.PEPlus_SpecialEffect then

		//Special effect controls have two separate tabs - first is for options on the special effect itself, second is for child fx
		local tabs = vgui.Create("DPropertySheet", self)
		self.TabPanel = tabs
		tabs:Dock(FILL)

		
		local back = vgui.Create("DPanel", tabs) //this is a contrivance to add some extra space under the DCategoryList, to "contain" the trackpnl
		back.Paint = function(self, w, h)
			derma.SkinHook("Paint", "CategoryList", self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
			return false
		end

		local container = vgui.Create("DCategoryList", back)
		container.Paint = function(self, w, h)
			return false
		end
		container:Dock(FILL)
		back.container = container

		//category for info; no header for this one
		local info = ent.Information
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
			text:SetText(info)
			text:SetContentAlignment(5)
			text:SetAutoStretchVertical(true)
			text:DockMargin(padding,padding-1,padding,0) //padding-1 for top is trial and error, results in nice 16px spacing on both top and bottom of text
			text:Dock(TOP)
	
		end


		//Category for attaching this effect
		local cat = vgui.Create("DCollapsibleCategory", container)
		cat:SetLabel("Attachment Settings")
		cat:DockMargin(3,3,3,3)
		cat:Dock(FILL)
		container:AddItem(cat)
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

				if modelent.PEPlus_Grip then
					button:SetText("Attach to model")
					button:SizeToContents()
					button.DoClick = function()
						surface.PlaySound("ui/buttonclickrelease.wav")
						ent:DoInput("attachment_ent_setwithtool")
					end
				else
					if (modelent.GetPEPlus_MergedGrip and modelent:GetPEPlus_MergedGrip()) and IsValid(modelent:GetParent()) then
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
							if val != slider.PEPlus_AttachSlider.attach then //only send updates on whole numbers
								surface.PlaySound("weapons/pistol/pistol_empty.wav")
								slider.PEPlus_AttachSlider.attach = val
								ent:DoInput("attachment_attach", val)
							end
						end

						//Let the HUDPaint hook in autorun detect that the player is hovering over this slider
						slider.PEPlus_AttachSlider = {ent = modelent, attach = ent:GetAttachmentID()}
						slider.Slider.PEPlus_AttachSlider = slider.PEPlus_AttachSlider
						slider.Slider.Knob.PEPlus_AttachSlider = slider.PEPlus_AttachSlider 
						slider.TextArea.PEPlus_AttachSlider = slider.PEPlus_AttachSlider 
						slider.Label.PEPlus_AttachSlider = slider.PEPlus_AttachSlider 
						slider.Scratch.PEPlus_AttachSlider = slider.PEPlus_AttachSlider 
					end
				end

			end

		end

		pnl.RebuildContents()

		
		//Add numpad + loop controls for special fx if applicable; do this here so we have just a bit less duplicate code
		if ent.GetNumpad and ent.GetNumpadToggle and ent.GetNumpadStartOn and ent.GetLoop and ent.GetLoopDelay and ent.GetLoopSafety then
			
			//category for key
			local cat = vgui.Create("DCollapsibleCategory", container)
			cat:SetLabel("Key Settings")
			cat:DockMargin(3,1,3,3)
			cat:Dock(FILL)
			container:AddItem(cat)
		
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
				container.NumpadToggleCheckbox = check
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
				container.NumpadStartOnCheckbox = check
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
			local cat = vgui.Create("DCollapsibleCategory", container)
			cat:SetLabel("Repeat Settings")
			cat:DockMargin(3,1,3,3)
			cat:Dock(FILL)
			container:AddItem(cat)
		
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
				//container.LoopDelaySlider = slider
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
		ent:SpecialEffectAddControls(self, container)

		tabs:AddSheet(ent.PrintName, back, "icon16/pencil.png")


		//Add child effect controls

		local back = vgui.Create("DPanel", tabs)
		back.Paint = function(self, w, h)
			derma.SkinHook("Paint", "CategoryList", self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
			return false
		end

		local container = vgui.Create("DCategoryList", back)
		container.Paint = function(self, w, h)
			return false
		end
		container:Dock(FILL)
		back.container = container

		//category for "add new effect" button; no header for this one
		local pnl2 = vgui.Create("DSizeToContents", container)
		pnl2:SetSizeX(false)
		pnl2:Dock(TOP)
		container:AddItem(pnl2)
		//cat:SetContents(pnl2)
		pnl2.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70)) end
		pnl2:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
		pnl2:DockMargin(3,3,3,3) //fix the 1px of blank white space between the header and the contents
		
		local button = vgui.Create("DButton", pnl2)
		button:DockMargin(padding,padding,padding,0)
		button:SetHeight(30)
		button:Dock(TOP)

		button:SetText("Add particle effect to " .. ent.PEPlus_ShortName)
		button:SizeToContents()
		button.DoClick = function()
			surface.PlaySound("ui/buttonclickrelease.wav")
			ent:DoInput("child_setwithtool")
		end


		container.ChildControls = {}
		self.SpecialEffect_ChildList = container //make this externally accessible so other funcs can rebuild it

		//This is called below for each child we have when creating this panel, and also called externally when child fx are updated, to add/remove fx from this panel after the fact.
		function container.AddOrRemoveChild(child)

			if !IsValid(ent) or !ent.SpecialEffectChildren then return end

			if ent.SpecialEffectChildren[child] and child.PEPlus_Ent then

				if !IsValid(container.ChildControls[child]) then

					//This effect is a new child, add controls for it
					local cat = vgui.Create("DCollapsibleCategory", container)
					cat:SetLabel(GetParticleName(child))
					cat.Header:SetToolTip(GetParticleName(child)) //these names can get really long, show the whole name on hover
					cat:DockMargin(3,1,3,3) //need extra +1 on left and right to match the margins of first-level category
					cat:Dock(TOP)
					container:AddItem(cat)
					cat:SetExpanded(true)
	
					local container2 = vgui.Create("DCategoryList", cat)
					container2.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
					container2:DockPadding(-30,0,-30,0)
					container2:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents
					container2.pnlCanvas:DockPadding(2-1,2-1,2-1,2+2) //need extra -1 on left and right to match the padding of first-level category (this is stupid); also extra +2 on bottom and -1 on top as well (this is stupider)
					container2:Dock(FILL)
					cat:SetContents(container2)
					cat.container = container2

					container.ChildControls[child] = cat

					//Set the child's edit window to this one, so that info table updates and such will update these controls
					child.PEPlusWindow = self

					BuildParticleEntControls(child, container.ChildControls[child].container)

					local button = vgui.Create("DButton", container.ChildControls[child].container)
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

			elseif IsValid(container.ChildControls[child]) then

				//This effect is no longer a child, remove its controls
				container.ChildControls[child]:Remove()
				container.ChildControls[child] = nil

			end

			container.ChildControlsTab:SetText("Attached Particle Effects (" .. table.Count(container.ChildControls) .. ")")
			if self.UpdatePauseTooltip then self.UpdatePauseTooltip() end

		end

		container.ChildControlsTab = tabs:AddSheet("Attached Particle Effects (0)", back, "icon16/fire.png").Tab

		//Add categories for each child effect
		for child, _ in pairs (ent.SpecialEffectChildren) do
			container.AddOrRemoveChild(child)
		end

		
		trackpnl_parent = tabs

	end


	//Add lower bar for pause and reset controls; both particles and special fx have this
	local trackpnl = vgui.Create("Panel", trackpnl_parent)
	trackpnl:Dock(BOTTOM)
	trackpnl:DockMargin(5,4,5,5) //-1 for top because the other sides include a 1px black border

	local restart = vgui.Create("DImageButton", trackpnl)
	restart:SetImage("icon16/control_repeat_blue.png")
	restart:SetStretchToFit(false)
	restart:SetDrawBackground(true)
	restart:Dock(LEFT)
	restart:SetWide(32)
	if !ent.utilfx then
		restart:SetTooltip("Restart particle effect, and clean up all particles")
	else
		restart:SetTooltip("Restart particle effect\n(cleanup not available for scripted effects)")
	end

	function restart.DoClick()
		ent:DoInput("effect_restart")
	end

	local pause = vgui.Create("DImageButton", trackpnl)
	pause:SetImage("icon16/control_pause_blue.png")
	pause:SetStretchToFit(false)
	pause:SetDrawBackground(true)
	pause:SetIsToggle(true)
	pause:SetToggle(false)
	pause:Dock(LEFT)
	pause:DockMargin(4,0,0,0)
	pause:SetWide(32)
	pause:SetTooltip("Pause particle effect\n\nIf the effect is modified, restarted, disabled then re-enabled,\nor loaded from a save or dupe, then it will play up to and\nre-pause at the same point in time.")

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
	text:DockMargin(8,0,0,0)
	text:Dock(FILL)

	function text.Think()
		if ent and ent.GetPauseTime then //don't cause an error when the ent is removed
			local pausetime = ent:GetPauseTime()
			local starttime = ent.ParticleStartTime
			if ent.GetParticleStartTime and ent.GetProjServerside and (ent:GetProjServerside() and svproj_enabled:GetBool()) then 
				starttime = ent:GetParticleStartTime() //for proj sfx's goofy serverside particlestarttime
			end
			local newtext = ""
			if pausetime >= 0 and starttime != nil and starttime > 0 then
				if pausetime <= (CurTime() - starttime) then
					newtext = "Paused at " .. tostring(math.Round(pausetime, 2)) .. " secs"
				else
					newtext = "Pausing at " .. tostring(math.Round(pausetime, 2)) .. " secs (in " .. tostring(-math.Round(CurTime() - starttime - pausetime, 2)) .. " secs)"
				end
			end
			if newtext != text:GetText() then
				text:SetText(newtext)
			end
		end
	end

	if self.TabPanel then
		//shift around the contents of both tabs, so that the trackpnl appears to be contained at the bottom of each one
		for _, v in pairs (self.TabPanel:GetItems()) do
			v.Panel.container:DockMargin(0,0,0,trackpnl:GetTall()+9)
		end
		trackpnl:DockMargin(13,12,13,13) //-1 for top because the other sides include a 1px black border
		trackpnl:SetZPos(200)
	end

	//If some child fx aren't pausable, then add warning to tooltip
	if ent.SpecialEffectChildren then
		self.UpdatePauseTooltip = function()
			local unpausable_fx
			local some_fx_pausable
			for child, _ in pairs (ent.SpecialEffectChildren) do
				if child.utilfx then
					unpausable_fx = (unpausable_fx or "") .. "\n" .. GetParticleName(child)
				else
					some_fx_pausable = true
				end
			end
			pause.tooltiptext = pause.tooltiptext or pause:GetTooltip()
			restart.tooltiptext = restart.tooltiptext or restart:GetTooltip()
			local disable
			if unpausable_fx then
				if some_fx_pausable or ent.ScriptedFxDontDisablePause then
					pause:SetTooltip(pause.tooltiptext .. "\n\nPausing not available for scripted effects:" .. unpausable_fx)
					restart:SetTooltip(restart.tooltiptext .. "\n\nCleanup not available for scripted effects:" .. unpausable_fx)
				else
					//If none of the effects are pausable, then just disable the option until that changes
					//(this is selectively disabled by projectile fx, because pausing still works for their projectile ents)
					disable = true
				end
			else
				pause:SetTooltip(pause.tooltiptext)
				restart:SetTooltip(restart.tooltiptext)
			end
			if disable then
				pause:SetDisabled(true)
				pause:SetImage("icon16/control_pause.png") //gray icon
				pause:SetTooltip("Pausing not available for scripted effects:" .. unpausable_fx)
				restart:SetTooltip("Restart particle effect\n\nCleanup not available for scripted effects:" .. unpausable_fx)
				//unpause the effect if it's paused, so it doesn't get stuck that way
				if ent:GetPauseTime() >= 0 then
					ent:DoInput("effect_pause")
				end
			else
				pause:SetDisabled(false)
				pause:SetImage("icon16/control_pause_blue.png")
			end
		end
		self.UpdatePauseTooltip()
	end

end




function PANEL:Think()

	local ent = self.m_Entity
	if !IsValid(ent) then self:OnEntityLost() return end
	if ent.PEPlusWindow != self and IsValid(ent.PEPlusWindow) then self:OnEntityLost() return end //make sure we don't open duplicate control windows
	ent.PEPlusWindow = self

end

function PANEL:EntityLost()

	self:Clear()
	self:OnEntityLost()

end

function PANEL:OnEntityLost()
	-- For override
end




vgui.Register("PEPlusEditor", PANEL, "Panel")