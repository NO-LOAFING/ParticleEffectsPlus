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
			return ent:GetParticleName() .. " (" .. ent:GetPCF() .. ")"
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

	local padding_help = 22 //bigger padding for help text
	local betweenitems_help = 5 //smaller betweenitems for help text
	local betweenitems_help2 = 3 //even smaller betweenitems for second help text paragraphs

	local icon_info = Material("icon16/information.png")

	//make this other stuff externally accessible too
	self.SliderValueChangedUnclampedMax = SliderValueChangedUnclampedMax
	self.SliderSetValueUnclampedMax = SliderSetValueUnclampedMax



	self.CPointCategories = {} //make these externally accessible so that the entity can change them upon receiving inputs from the server

	local function BuildParticleEntControls(ent2, container)
	
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
		local info = PartCtrl_ProcessedPCFs[ent2:GetPCF()][ent2:GetParticleName()].info
		if info then
	
			local pnl = vgui.Create("DSizeToContents", container)
			pnl:SetSizeX(false)
			pnl:DockMargin(3,3,3,3)
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
			pnl:DockMargin(3,3,3,3-2) //-2 because there's too much space between this and the next category otherwise
	
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
	
	
		//category for key
		local cat = vgui.Create("DCollapsibleCategory", container)
		cat:SetLabel("Key & Repeat Settings")
		cat:DockMargin(3,3,3,3)
		cat:Dock(FILL)
		container:AddItem(cat)
	
		local default_looptime = PartCtrl_ProcessedPCFs[ent2:GetPCF()][ent2:GetParticleName()].default_time or 0
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
			((ent2:GetNumpad() or 0) != 0)
			or (ent2:GetNumpadToggle() != true)
			or (ent2:GetNumpadStartOn() != true)
			//considered also adding a check here to make sure the effect isn't disabled, but i don't think that's possible without a numpad key set
			or ((ent2:GetLoopMode() or 1) != default_loopmode)
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
	
			--[[local help = vgui.Create("DLabel", rpnl)
			help:SetDark(true)
			help:SetWrap(true)
			help:SetTextInset(0, 0)
			help:SetText("If checked, cleans up all particles when the effect is disabled or repeated.")
			//help:SetContentAlignment(5)
			help:SetAutoStretchVertical(true)
			//help:DockMargin(32,0,32,8)
			help:DockMargin(padding_help,betweenitems_help,padding_help,0)
			help:Dock(TOP)
			help:SetTextColor(color_helpdark)]]
	
	
		//categories for each cpoint
		self.CPointCategories[ent2] = {}
		for k, v in SortedPairs (ent2.ParticleInfo) do
	
			local cat = vgui.Create("DCollapsibleCategory", container)
			cat:SetLabel("Control Point #" .. tostring(k))
			cat:DockMargin(3,1,3,3)
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
	
				local expand = false
	
				//Add mode-specific options
				local mode = PartCtrl_ProcessedPCFs[ent2:GetPCF()][ent2:GetParticleName()].cpoints[k].mode
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
								button:SetText("Detach from model (" .. string.GetFileFromFilename(modelent:GetModel()) .. ")")
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
											pnl.DoPosSliderHeights(val == 0)
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
		
							pnl.possliders = {}
		
							local slider = vgui.Create("DNumSlider", pnl)
							slider:SetText("Offset X")
							slider:SetMinMax(-128, 128)
							slider:SetDefaultValue(0)
							slider:SetDark(true)
							slider:Dock(TOP)
		
							slider.ValueChanged = SliderValueChangedUnclamped
							slider.SetValue = SliderSetValueUnclamped
							slider.height = 18
							slider.margin = {padding,betweenitems,0,3}
							pnl.possliders[1] = slider
					
							slider:SetValue(v2.pos[1])
							function slider.OnValueChanged(_, val)
								ent2:DoInput("cpoint_position_pos", k, 1, val)
							end
		
							local slider = vgui.Create("DNumSlider", pnl)
							slider:SetText("Offset Y")
							slider:SetMinMax(-128, 128)
							slider:SetDefaultValue(0)
							slider:SetDark(true)
							slider:Dock(TOP)
		
							slider.ValueChanged = SliderValueChangedUnclamped
							slider.SetValue = SliderSetValueUnclamped
							slider.height = 18
							slider.margin = {padding,0,0,3} //no top padding, squish these 3 together
							pnl.possliders[2] = slider
		
							slider:SetValue(v2.pos[2])
							function slider.OnValueChanged(_, val)
								ent2:DoInput("cpoint_position_pos", k, 2, val)
							end
		
							local slider = vgui.Create("DNumSlider", pnl)
							slider:SetText("Offset Z")
							slider:SetMinMax(-128, 128)
							slider:SetDefaultValue(0)
							slider:SetDark(true)
							slider:Dock(TOP)
		
							slider.ValueChanged = SliderValueChangedUnclamped
							slider.SetValue = SliderSetValueUnclamped
							slider.height = 18
							slider.margin = {padding,0,0,3} //no top padding, squish these 3 together
							pnl.possliders[3] = slider
					
							slider:SetValue(v2.pos[3])
							function slider.OnValueChanged(_, val)
								ent2:DoInput("cpoint_position_pos", k, 3, val)
							end
		
							//Only show these sliders if attachment 0 is selected, because the offset feature in all the particle functions only works if attached to model origin
							//(Dynamically resize these panels, don't run RebuildContents and recreate the whole thing, because that would interrupt dragging the attachment slider)
							function pnl.DoPosSliderHeights(show)
								for k, v in pairs (pnl.possliders) do
									if show then
										v:SetHeight(v.height)
										v:DockMargin(v.margin[1], v.margin[2], v.margin[3], v.margin[4])
									else
										v:SetHeight(0)
										v:DockMargin(0,0,0,0)
									end
								end
							end
							pnl.DoPosSliderHeights(v2.attach == 0)
		
							expand = true
						end
					else
						//This is a child effect, so show special effect options instead

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

						expand = true
					end
				elseif mode == PARTCTRL_CPOINT_MODE_VECTOR then
					local tab = PartCtrl_ProcessedPCFs[ent2:GetPCF()][ent2:GetParticleName()].cpoints[k]
					tab = tab.vector[tab.which]
					if istable(tab) then
						//Roll sets the angle of the particle, with the putput measured in radians (pi radians = 180 degrees). Output maximum/minimum sets how many radians it can be rotated up to, 
						//with values past pi just rotating it past 180 degrees. With a standard render_animated_sprites, only the x value does anything, regardless of orientation type. With render 
						//models, this is broken and spawns models at random rotations regardless of the cpoint value.
						//Position sets the position of the particle, with the output measured in hammer units i think?
						//Color sets the color of the particle, with the output measured in 0 0 0 = black and 1 1 1 = white. Output values under 0 or over 1 don't seem to do anything different, so
						//no additive color or negative color wackiness here.
	
						if tab.label == "Color" then
							local col = vgui.Create("DColorMixer", pnl)
							col:SetAlphaBar(false)
							col:Dock(TOP)
							col:DockMargin(padding,padding,padding,0)
	
							function col.PerformLayout(self, x, y)
								//Modified version of CtrlColor:PerformLayout (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/spawnmenu/controls/ctrlcolor.lua#L13)
								//Only does palette button sizes, doesn't clamp their sizes and resizes them more smoothly
								local ColorRows = #self.Palette:GetChildren() / 3
								self.Palette:SetButtonSize(self:GetWide() / ColorRows)
							end
	
							local vec = Vector(v2.val)
							vec.x = math.Remap(vec.x, tab.inMin.x, tab.inMax.x, tab.outMin.x, tab.outMax.x)
							vec.y = math.Remap(vec.y, tab.inMin.y, tab.inMax.y, tab.outMin.y, tab.outMax.y)
							vec.z = math.Remap(vec.z, tab.inMin.z, tab.inMax.z, tab.outMin.z, tab.outMax.z)
							col:SetVector(vec)
							function col.ValueChanged(_, val)
								local vec = Vector()
								vec.x = math.Remap(val.r/255, tab.outMin.x, tab.outMax.x, tab.inMin.x, tab.inMax.x)
								vec.y = math.Remap(val.g/255, tab.outMin.y, tab.outMax.y, tab.inMin.y, tab.inMax.y)
								vec.z = math.Remap(val.b/255, tab.outMin.z, tab.outMax.z, tab.inMin.z, tab.inMax.z)
								ent2:DoInput("cpoint_vector_val_all", k, vec)
							end
						else
							for i = 1, 3 do
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
									if tab.label == "Velocity Direction Normal" or tab.label == "Velocity" then
										if i == 1 then
											slider:SetText("Velocity Back/Forward")
										elseif i == 2 then
											slider:SetText("Velocity Right/Left")
										else
											slider:SetText("Velocity Down/Up")
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
								if istable(tab.default) then
									slider:SetDefaultValue(tab.default[i])
								else
									slider:SetDefaultValue(0)
								end
								slider:SetDark(true)
								slider:SetHeight(18)
								slider:Dock(TOP)
								if i == 1 then
									slider:DockMargin(padding,betweenitems,0,3)
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
	
						expand = true
					end
				elseif mode == PARTCTRL_CPOINT_MODE_AXIS then
					local slidercount = 0
					for i = 1, 3 do
						local tab = PartCtrl_ProcessedPCFs[ent2:GetPCF()][ent2:GetParticleName()].cpoints[k]
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
								slider:SetDefaultValue(tab.default or 0)
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
								function slider.OnValueChanged(_, val)
									val = math.Remap(val, outMin, outMax, inMin, inMax)
									if tab.decimals != nil then val = math.Round(val, tab.decimals) end
									ent2:DoInput("cpoint_axis_val", k, i, val)
								end
							end
	
							expand = true
						end
					end
					//TODO: handle output_axis disabling the control for a specific axis on a cpoint, and not others? no practical examples of this actually being used by anything at the moment
				end
	
				pnl:GetParent():SetExpanded(expand)
	
			end
			pnl.RebuildContents(v)
			self.CPointCategories[ent2][k] = pnl
	
		end

	end


	if ent.PartCtrl_Ent then

		local container = vgui.Create("DCategoryList", self)
		container.Paint = function(self, w, h)
			derma.SkinHook("Paint", "CategoryList", self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
			return false
		end
		container:Dock(FILL)
		
		BuildParticleEntControls(ent, container)

		//dummy category to add extra padding to bottom of list if there's a scrollbar
		local pnl = vgui.Create("DSizeToContents", container)
		//pnl:DockMargin(3,1,3,3)
		pnl:Dock(FILL)
		container:AddItem(pnl)
		//pnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70)) end
		//pnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item

	elseif ent.PartCtrl_SpecialEffect then

		//Special effect controls have two columns - left column is for options on the special effect itself, right column is for child fx
		local back = vgui.Create("DPanel", self)
		back.Paint = function(self, w, h)
			derma.SkinHook("Paint", "CategoryList", self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
	
			return false
		end
		back:Dock(FILL)

		local lcontainer = vgui.Create("DCategoryList", back)
		lcontainer.Paint = function(self, w, h)
			//derma.SkinHook("Paint", "CategoryList", self, w, h)
			//draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
			return false
		end
		lcontainer:DockMargin(0,0,0,0)

		local rcontainer = vgui.Create("DCategoryList", back)
		rcontainer.Paint = function(self, w, h)
			//derma.SkinHook("Paint", "CategoryList", self, w, h)
			//draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
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
		divider:SetLeftWidth(352)


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

			local modelent = ent:GetParent()
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
					button:SetText("Detach from model (" .. string.GetFileFromFilename(modelent:GetModel()) .. ")")
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

				//test dual scrollbars
				--[[local text = vgui.Create("DLabel", pnl)
				text:SetDark(true)
				text:SetWrap(true)
				text:SetTextInset(0, 0)
				text:SetText("cause this is filler, filler night!!")
				for i = 0, 32 do
					text:SetText(text:GetText() .. "\nAAAA")
				end
				text:SetContentAlignment(5)
				text:SetAutoStretchVertical(true)
				text:DockMargin(padding,betweenitems,padding,0)
				text:Dock(TOP)]]

			end

		end

		pnl.RebuildContents()

		
		//Add numpad + loop controls for special fx if applicable; do this here so we have just a bit less duplicate code
		if ent.GetNumpad and ent.GetNumpadToggle and ent.GetNumpadStartOn and ent.GetLoop and ent.GetLoopDelay and ent.GetLoopSafety then
			
			local cat = vgui.Create("DCollapsibleCategory", lcontainer)
			cat:SetLabel("Key & Repeat Settings")
			cat:DockMargin(3,1,-2,3) //-2 right for divider
			cat:Dock(FILL)
			lcontainer:AddItem(cat)
		
			local default_looptime = ent.DefaultLoopTime
			local default_loopmode = true
		
			//expand if any contained options are non-default 
			cat:SetExpanded(
				((ent:GetNumpad() or 0) != 0)
				or (ent:GetNumpadToggle() != true)
				or (ent:GetNumpadStartOn() != true)
				//considered also adding a check here to make sure the effect isn't disabled, but i don't think that's possible without a numpad key set
				or ((ent:GetLoop() or true) != default_loopmode)
				or ((math.Round(ent:GetLoopDelay(), 6) or 0) != default_looptime)
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
		
				numpadpnl.numpad:SetSelectedNumber(ent:GetNumpad() or 0)
				function numpadpnl.numpad.SetValue(_, val)
					numpadpnl.numpad:SetSelectedNumber(val)
					ent:DoInput("numpad_num", val)
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
		
				check:SetValue(ent:GetNumpadToggle())
				check.OnChange = function(_, val)
					ent:DoInput("numpad_toggle", val)
				end
		
				local check = vgui.Create("DCheckBoxLabel", anotherpnl)
				//back.NumpadStartOnCheckbox = check
				check:SetText("Start on")
				check:SetDark(true)
				check:SetHeight(15)
				check:Dock(BOTTOM)
				check:DockMargin(8,0,0,8)
		
				check:SetValue(ent:GetNumpadStartOn())
				check.OnChange = function(_, val)
					ent:DoInput("numpad_starton", val)
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

		end


		//Add effect-specific controls
		ent:SpecialEffectAddControls(self, lcontainer)


		//dummy category to add extra padding to bottom of list if there's a scrollbar (for lcontainer)
		local pnl = vgui.Create("DSizeToContents", lcontainer)
		//pnl:DockMargin(3,1,3,3)
		pnl:Dock(FILL)
		lcontainer:AddItem(pnl)
		//pnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70)) end
		//pnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item


		self.SpecialEffect_ChildList = rcontainer //make this externally accessible so other funcs can rebuild it

		//Rebuild the contents of this column whenever a child effect is added or removed
		function rcontainer.RebuildContents()

			rcontainer:Clear()
			if !IsValid(ent) then return end


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


			//Categories for each child effect
			for _, child in pairs (ent:GetChildren()) do
				if child.PartCtrl_Ent then
					//Set its edit window to this one, so that info table updates and such will update these controls
					child.PartCtrlWindow = self

					local cat = vgui.Create("DCollapsibleCategory", rcontainer)
					cat:SetLabel(GetParticleName(child))
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

					BuildParticleEntControls(child, container2)

					local button = vgui.Create("DButton", container2)
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
			end

			//dummy category to add extra padding to bottom of list if there's a scrollbar (for rcontainer)
			local pnl = vgui.Create("DSizeToContents", rcontainer)
			//pnl:DockMargin(3,1,3,3)
			pnl:Dock(FILL)
			rcontainer:AddItem(pnl)
			//pnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70)) end
			//pnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item

		end
		
		rcontainer.RebuildContents()

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