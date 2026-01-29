AddCSLuaFile()

ENT.Base 			= "ent_partctrl_sfx"
ENT.PrintName			= "Projectile Effect"
ENT.Category			= "Particle Effects"
ENT.Information			= "Launches props that can have particle effects attached to them, and can play more particle effects when they expire, either on hit or on a timer."

ENT.Spawnable			= true

ENT.PartCtrl_ShortName		= "Projectile"
ENT.SpecialEffectRoles		= {
	[0] = "Start point",
	[1] = "Projectile model",
	[2] = "Hit/expire point",
}
ENT.DisableChildAutoplay	= true
ENT.CustomPauseInput		= true

ENT.DefaultLoopTime = 0.8

local svproj_enabled = GetConVar("sv_partctrl_allowserverprojectiles")




function ENT:SetupDataTables()

	//all special fx must have these ones
	self:NetworkVar("Int", 0, "AttachmentID")
	self:NetworkVar("Entity", 0, "SpecialEffectParent")
	self:NetworkVarNotify("SpecialEffectParent", self.OnSpecialEffectParentChanged)
	self:NetworkVar("Float", 0, "PauseTime")

	self:NetworkVar("Bool", 0, "Loop") //because special fx can't use loop mode 1 (loop when effect is finished), just make this a bool instead
	self:NetworkVar("Float", 1, "LoopDelay")
	self:NetworkVar("Bool", 1, "LoopSafety")

	self:NetworkVar("Int", 1, "Numpad")
	self:NetworkVar("Bool", 2, "NumpadToggle")
	self:NetworkVar("Bool", 3, "NumpadStartOn")
	self:NetworkVar("Bool", 4, "NumpadState")
	self:NetworkVar("Int", 2, "NumpadMode")

	self:NetworkVar("Float", 2, "ProjSpread")
	self:NetworkVar("Int", 3, "ProjCount")
	self:NetworkVar("Int", 4, "ProjDir")
	self:NetworkVar("Int", 5, "ProjHitDir")

	self:NetworkVar("Float", 3, "ProjVelocity")
	self:NetworkVar("Bool", 5, "ProjGravity")
	self:NetworkVar("Bool", 6, "ProjDrag")
	self:NetworkVar("Float", 4, "ProjLifetimePre")
	self:NetworkVar("Float", 5, "ProjLifetimePost")
	self:NetworkVar("Bool", 7, "ProjCollide")
	self:NetworkVar("Bool", 8, "ProjPhysSounds")
	self:NetworkVar("Bool", 9, "ProjServerside")

	self:NetworkVar("Int", 6, "ProjAngle")
	self:NetworkVar("Int", 7, "ProjSpin")
	self:NetworkVar("Float", 6, "ProjSpinVelocity")

	self:NetworkVar("Float", 7, "ParticleStartTime") //used by serverside projectile fx, to network it to clients

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

	self:SetProjSpread(0)
	self:SetProjCount(1)
	self:SetProjDir(0)
	self:SetProjHitDir(0)

	self:SetProjVelocity(1000)
	self:SetProjGravity(false)
	self:SetProjDrag(false)
	self:SetProjLifetimePre(10)
	self:SetProjLifetimePost(0)
	self:SetProjCollide(false)
	self:SetProjPhysSounds(false)
	self:SetProjServerside(false)

	
	self:SetProjAngle(0)
	self:SetProjSpin(0)
	self:SetProjSpinVelocity(0)

	if IsMounted("tf") then
		self:SetModel("models/weapons/w_models/w_rocket.mdl")

		if !self.IsBlank then
			local p = PartCtrl_SpawnParticle(self:GetPlayer(), self:GetPos(), "rockettrail", "particles/rockettrail.pcf", "tf")
			if IsValid(p) then
				p:AttachToSpecialEffect(self, self:GetPlayer(), false)
				p.ParticleInfo[0].attach = 1
				p.ParticleInfo[0].sfx_role = 1
			end

			local p = PartCtrl_SpawnParticle(self:GetPlayer(), self:GetPos(), "ExplosionCore_Wall", "particles/explosion.pcf", "tf")
			if IsValid(p) then
				p:AttachToSpecialEffect(self, self:GetPlayer(), false)
				p.ParticleInfo[0].sfx_role = 2
			end
		end
	else
		//fallback HL2 fx; these trails in particular are pretty bad but they're the best we've got
		self:SetModel("models/weapons/w_missile.mdl")

		if !self.IsBlank then
			local p = PartCtrl_SpawnParticle(self:GetPlayer(), self:GetPos(), "Rocket_Smoke", "particles/rocket_fx.pcf")
			if IsValid(p) then
				p:AttachToSpecialEffect(self, self:GetPlayer(), false)
				p.ParticleInfo[0].attach = 1
				p.ParticleInfo[0].sfx_role = 1
			end

			local p = PartCtrl_SpawnParticle(self:GetPlayer(), self:GetPos(), "Explosion", "UtilFx")
			if IsValid(p) then
				p:AttachToSpecialEffect(self, self:GetPlayer(), false)
				p.ParticleInfo[0].sfx_role = 2
			end
		end
	end

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

	function ENT:SpecialEffectAddControls(window, container)

		local ent = self
		local padding = window.padding
		local betweenitems = window.betweenitems
		local betweencategories = window.betweencategories
		local padding_help = window.padding_help
		local betweenitems_help = window.betweenitems_help
		local color_helpdark = window.color_helpdark
		local SliderValueChangedUnclampedMax = window.SliderValueChangedUnclampedMax
		local SliderSetValueUnclampedMax = window.SliderSetValueUnclampedMax

		local cat = vgui.Create("DCollapsibleCategory", container)
		cat:SetLabel("Projectile Effect Settings")
		cat:DockMargin(3,1,3,3)
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
			slider:SetDefaultValue(0)
			slider:SetDark(true)
			slider:SetHeight(18)
			slider:Dock(TOP)
			//slider:DockMargin(padding,betweenitems-5,0,3) //less up and extra down on sliders because we want to base the "top" off the text, not the knob, but also want 16px between sliders' text
			slider:DockMargin(padding,padding-5,0,3) //less up and extra down on sliders because we want to base the "top" off the text, not the knob, but also want 16px between sliders' text

			slider:SetValue(ent:GetProjSpread() or 0.00)
			function slider.OnValueChanged(_, val)
				ent:DoInput("proj_spread", val)
			end


			local slider = vgui.Create("DNumSlider", rpnl)
			slider:SetText("Projectiles per shot")
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
			local val = ent:GetProjDir() or 0
			drop.Combo:SetValue(dirs[val])
			for k, v in pairs (dirs) do
				drop.Combo:AddChoice(v, k)
			end
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

			local help = vgui.Create("DLabel", rpnl)
			help:SetDark(true)
			help:SetWrap(true)
			help:SetTextInset(0, 0)
			help:SetText("Sets which direction to fire projectiles. Useful for attachments that don't point forward.")
			//help:SetContentAlignment(5)
			help:SetAutoStretchVertical(true)
			//help:DockMargin(32,0,32,8)
			help:DockMargin(padding_help,betweenitems_help,padding_help,0)
			help:Dock(TOP)
			help:SetTextColor(color_helpdark)


			local drop = vgui.Create("Panel", rpnl)
		
			drop.Label = vgui.Create("DLabel", drop)
			drop.Label:SetDark(true)
			drop.Label:SetText("Hit/expire point angle")
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
			local val = ent:GetProjHitDir() or 0
			drop.Combo:SetValue(dirs[val])
			for k, v in pairs (dirs) do
				drop.Combo:AddChoice(v, k)
			end
			function drop.Combo.OnSelect(_, index, value, data)
				ent:DoInput("proj_hitdir", data)
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


			//should these ones be in a different category?


			local slider = vgui.Create("DNumSlider", rpnl)
			slider:SetText("Velocity")
			slider:SetMinMax(0, 3000)
			slider:SetDefaultValue(1000)
			slider:SetDark(true)
			slider:SetHeight(18)
			slider:Dock(TOP)
			slider:DockMargin(padding,betweencategories-5,0,3) //less up and extra down on sliders because we want to base the "top" off the text, not the knob, but also want 16px between sliders' text

			slider.ValueChanged = SliderValueChangedUnclampedMax
			slider.SetValue = SliderSetValueUnclampedMax

			local val = ent:GetProjVelocity() or 0
			slider:SetValue(val)
			slider.Val = val
			function slider.OnValueChanged(_, val)
				ent:DoInput("proj_velocity", val)
			end


			local check = vgui.Create( "DCheckBoxLabel", rpnl)
			check:SetText("Gravity")
			check:SetDark(true)
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(padding,betweenitems,0,0)

			check:SetValue(ent:GetProjGravity())
			check.OnChange = function(_, val)
				ent:DoInput("proj_gravity", val)
			end


			local check = vgui.Create( "DCheckBoxLabel", rpnl)
			check:SetText("Drag")
			check:SetDark(true)
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(padding,betweenitems,0,0)

			check:SetValue(ent:GetProjDrag())
			check.OnChange = function(_, val)
				ent:DoInput("proj_drag", val)
			end


			local slider = vgui.Create("DNumSlider", rpnl)
			slider:SetText("Lifetime")
			slider:SetMinMax(0, 10)
			slider:SetDefaultValue(10)
			slider:SetDark(true)
			slider:SetHeight(18)
			slider:Dock(TOP)
			slider:DockMargin(padding,betweencategories-5,0,3) //less up and extra down on sliders because we want to base the "top" off the text, not the knob, but also want 16px between sliders' text

			slider.ValueChanged = SliderValueChangedUnclampedMax
			slider.SetValue = SliderSetValueUnclampedMax

			local val = ent:GetProjLifetimePre() or 0
			slider:SetValue(val)
			slider.Val = val
			function slider.OnValueChanged(_, val)
				ent:DoInput("proj_lifetime_pre", val)
			end

			local help = vgui.Create("DLabel", rpnl)
			help:SetDark(true)
			help:SetWrap(true)
			help:SetTextInset(0, 0)
			help:SetText("How long projectiles last after being fired.")
			//help:SetContentAlignment(5)
			help:SetAutoStretchVertical(true)
			//help:DockMargin(32,0,32,8)
			help:DockMargin(padding_help,betweenitems_help,padding_help,0)
			help:Dock(TOP)
			help:SetTextColor(color_helpdark)


			local slider = vgui.Create("DNumSlider", rpnl)
			slider:SetText("Lifetime (after hit)")
			slider:SetMinMax(0, 10)
			slider:SetDefaultValue(0)
			slider:SetDark(true)
			slider:SetHeight(18)
			slider:Dock(TOP)
			//slider:DockMargin(padding,betweenitems-5,0,3) //less up and extra down on sliders because we want to base the "top" off the text, not the knob, but also want 16px between sliders' text
			slider:DockMargin(padding,betweenitems,0,3) //actually use a normal amount of up, because otherwise the help text above is too close

			slider.ValueChanged = SliderValueChangedUnclampedMax
			slider.SetValue = SliderSetValueUnclampedMax

			local val = ent:GetProjLifetimePost() or 0
			slider:SetValue(val)
			slider.Val = val
			function slider.OnValueChanged(_, val)
				ent:DoInput("proj_lifetime_post", val)
			end

			local help = vgui.Create("DLabel", rpnl)
			help:SetDark(true)
			help:SetWrap(true)
			help:SetTextInset(0, 0)
			help:SetText("How long projectiles last after hitting something. Set to 0 to expire on impact.")
			//help:SetContentAlignment(5)
			help:SetAutoStretchVertical(true)
			//help:DockMargin(32,0,32,8)
			help:DockMargin(padding_help,betweenitems_help,padding_help,0)
			help:Dock(TOP)
			help:SetTextColor(color_helpdark)


			local check = vgui.Create( "DCheckBoxLabel", rpnl)
			check:SetText("Collide with other projectiles")
			check:SetDark(true)
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(padding,betweencategories,0,0)

			check:SetValue(ent:GetProjCollide())
			check.OnChange = function(_, val)
				ent:DoInput("proj_collide", val)
			end


			local check = vgui.Create( "DCheckBoxLabel", rpnl)
			check:SetText("Play physics sounds")
			check:SetDark(true)
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(padding,betweenitems,0,0)

			check:SetValue(ent:GetProjPhysSounds())
			check.OnChange = function(_, val)
				ent:DoInput("proj_physsounds", val)
			end


			local check = vgui.Create( "DCheckBoxLabel", rpnl)
			check:SetText("Serverside projectiles")
			check:SetDark(true)
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(padding,betweenitems,0,0)

			check:SetValue(ent:GetProjServerside())
			check.OnChange = function(_, val)
				ent:DoInput("proj_serverside", val)
			end

			local help = vgui.Create("DLabel", rpnl)
			help:SetDark(true)
			help:SetWrap(true)
			help:SetTextInset(0, 0)
			//help:SetText("")
			//help:SetContentAlignment(5)
			help:SetAutoStretchVertical(true)
			//help:DockMargin(32,0,32,8)
			help:DockMargin(padding_help,betweenitems_help,padding_help,0)
			help:Dock(TOP)
			help:SetTextColor(color_helpdark)

			check.Think = function()
				help.ShouldShow = help.ShouldShow or nil
				local new_shouldshow = svproj_enabled:GetBool()
				if new_shouldshow != help.shouldshow then
					if new_shouldshow then
						check:SetDisabled(false)
						help:SetText("If checked, uses serverside props for projectiles. These will collide properly with everything instead of passing through, but they'll also put more stress on the game (especially in multiplayer), and can show up in the wrong spot if bonemerged. Only turn this on if you need it!")
					else
						check:SetDisabled(true)
						help:SetText("(disabled by sv_partctrl_allowserverprojectiles)")
					end
				end
			end

		//separate category for projectile visuals
		local cat = vgui.Create("DCollapsibleCategory", container)
		cat:SetLabel("Projectile Appearance")
		cat:DockMargin(3,1,3,3)
		cat:Dock(FILL)
		container:AddItem(cat)

		local rpnl = vgui.Create("DSizeToContents", cat) //call this one rpnl and not pnl, just so we don't have to rewrite the numpad stuff copied from animprop that already has a panel with that name
		rpnl:Dock(FILL)
		cat:SetContents(rpnl)
		rpnl.Paint = function(self, w, h) draw.RoundedBox(4, 0, -5, w, h+5, Color(0,0,0,70)) end //draw the top of the box higher up (it'll be hidden behind the header) so the upper corners are hidden and it blends smoothly into the header
		rpnl:DockPadding(0,0,0,padding) //DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
		rpnl:DockMargin(0,-1,0,0) //fix the 1px of blank white space between the header and the contents

			local entrypnl = vgui.Create("Panel", rpnl)
			entrypnl:SetHeight(20)
			entrypnl:Dock(TOP)
			entrypnl:DockMargin(padding,padding,padding,0)

			local label = vgui.Create("DLabel", entrypnl)
			label:SetDark(true)
			label:SetText("Model")
			label:Dock(LEFT)

			local entry = vgui.Create("DTextEntry", entrypnl)
			entry:SetHeight(20)
			entry:Dock(FILL)
			//entry:SetPlaceholderText("Enter a model path")
			entry:SetText(ent:GetModel())

			entry.OnEnter = function()
				ent:DoInput("projvis_model", entry:GetText())
			end
			entry.OnFocusChanged = function(_, b) 
				if !b then entry:OnEnter() end
			end

			function entrypnl.PerformLayout(_, w, h)
				local w2, h2 = label:GetTextSize()
				label:SetWide(w2 + padding*2)
			end


			//local skincount = ent:SkinCount()
			//if skincount > 1 then
				local slider = vgui.Create("DNumSlider", rpnl)
				slider:SetText("Skin")
				slider:SetDecimals(0)
				//slider:SetMinMax(0, skincount-1)
				slider:SetDefaultValue(0)
				slider:SetDark(true)
				//slider:SetHeight(18)
				slider:Dock(TOP)
				//slider:DockMargin(padding,betweenitems,0,3)
		
				local val = ent:GetSkin()
				slider:SetValue(val)
				slider.Val = val
				function slider.OnValueChanged(_, val) //only send updates on whole numbers
					val = math.Round(val)
					if val != slider.Val then
						slider.Val = val
						ent:DoInput("projvis_skin", val)
					end
				end

				function slider:Think()
					if !IsValid(ent) then return end
					//instead of adding special handling somewhere on the entity to check for a model change and recreate this panel,
					//just make the slider automatically resize itself depending on the skin count
					local skincount = ent:SkinCount()
					if slider.OldSkinCount != skincount then
						slider.OldSkinCount = skincount
						if skincount > 1 then
							slider:SetHeight(18)
							slider:DockMargin(padding,betweenitems,0,3)
							slider:SetMinMax(0, skincount-1)
						else
							slider:SetHeight(0)
							slider:DockMargin(0,0,0,0)
						end
					end
				end
			//end


			local drop = vgui.Create("Panel", rpnl)
			
			drop.Label = vgui.Create("DLabel", drop)
			drop.Label:SetDark(true)
			drop.Label:SetText("Projectile angle")
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
			local val = ent:GetProjAngle() or 0
			drop.Combo:SetValue(dirs[val])
			for k, v in pairs (dirs) do
				drop.Combo:AddChoice(v, k)
			end
			function drop.Combo.OnSelect(_, index, value, data)
				ent:DoInput("projvis_angle", data)
			end

			drop:SetHeight(25)
			drop:Dock(TOP)
			drop:DockMargin(padding,betweencategories,padding,0)
			//drop:DockMargin(padding,padding-9,padding,0) //-9 to base the "top" off the text, not the box
			function drop.PerformLayout(_, w, h)
				drop.Label:SetWide(w / 2.4)
			end


			local drop = vgui.Create("Panel", rpnl)
			
			drop.Label = vgui.Create("DLabel", drop)
			drop.Label:SetDark(true)
			drop.Label:SetText("Spin axis")
			drop.Label:Dock(LEFT)

			drop.Combo = vgui.Create("DComboBox", drop)
			drop.Combo:SetHeight(25)
			drop.Combo:Dock(FILL)

			local dirs = {
				[0] = "0: Random pitch+yaw (pill tumble)",
				[1] = "1: Random axis",
				[2] = "2: Pitch",
				[3] = "3: Yaw",
				[4] = "4: Roll",
			}
			local val = ent:GetProjSpin() or 0
			drop.Combo:SetValue(dirs[val])
			for k, v in pairs (dirs) do
				drop.Combo:AddChoice(v, k)
			end
			function drop.Combo.OnSelect(_, index, value, data)
				ent:DoInput("projvis_spin", data)
			end

			drop:SetHeight(25)
			drop:Dock(TOP)
			drop:DockMargin(padding,betweenitems,padding,0)
			//drop:DockMargin(padding,padding-9,padding,0) //-9 to base the "top" off the text, not the box
			function drop.PerformLayout(_, w, h)
				drop.Label:SetWide(w / 2.4)
			end


			local slider = vgui.Create("DNumSlider", rpnl)
			slider:SetText("Spin velocity")
			slider:SetMinMax(-1500,1500)
			slider:SetDefaultValue(0)
			slider:SetDark(true)
			slider:SetHeight(18)
			slider:Dock(TOP)
			slider:DockMargin(padding,betweenitems,0,3) //less up and extra down on sliders because we want to base the "top" off the text, not the knob, but also want 16px between sliders' text

			slider.ValueChanged = SliderValueChangedUnclampedMax
			slider.SetValue = SliderSetValueUnclampedMax

			local val = ent:GetProjSpinVelocity() or 0
			slider:SetValue(val)
			slider.Val = val
			function slider.OnValueChanged(_, val)
				ent:DoInput("projvis_spin_velocity", val)
			end


			local entrypnl = vgui.Create("Panel", rpnl)
			entrypnl:SetHeight(20)
			entrypnl:Dock(TOP)
			entrypnl:DockMargin(padding,betweencategories,padding,0)

			local label = vgui.Create("DLabel", entrypnl)
			label:SetDark(true)
			label:SetText("Material")
			label:Dock(LEFT)

			local entry = vgui.Create("DTextEntry", entrypnl)
			entry:SetHeight(20)
			entry:Dock(FILL)
			entry:SetText(ent:GetMaterial())

			entry.OnEnter = function()
				ent:DoInput("projvis_material", entry:GetText())
			end
			entry.OnFocusChanged = function(_, b) 
				if !b then entry:OnEnter() end
			end

			function entrypnl.PerformLayout(_, w, h)
				local w2, h2 = label:GetTextSize()
				label:SetWide(w2 + padding*2)
			end


			local col = vgui.Create("DColorMixer", rpnl)
			col:SetAlphaBar(true)
			col:Dock(TOP)
			col:DockMargin(padding,padding,padding,0)
			col:SetLabel("Color")

			function col.PerformLayout(self, x, y)
				//Modified version of CtrlColor:PerformLayout (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/spawnmenu/controls/ctrlcolor.lua#L13)
				//Only does palette button sizes, doesn't clamp their sizes and resizes them more smoothly
				local ColorRows = #self.Palette:GetChildren() / 3
				self.Palette:SetButtonSize(self:GetWide() / ColorRows)
			end

			col:SetColor(ent:GetColor())
			function col.ValueChanged(_, val)
				ent:DoInput("projvis_color", Color(val.r,val.g,val.b,val.a))
			end
	
	end

	local icon_error = Material("icon16/exclamation.png")

	function ENT:SpecialEffectAddRoleControls(window, pnl, k, v2, ent2)

		local padding = window.padding
		local betweenitems = window.betweenitems

		if v2.sfx_role == 1 then
			local attachcount = 0
			local tab = self:GetAttachments()
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
				//This doesn't look all that great, but it lets the player see the attachments, which is better than nothing
				slider.PartCtrl_AttachSlider = {ent = self, attach = v2.attach}
				slider.Slider.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider
				slider.Slider.Knob.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
				slider.TextArea.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
				slider.Label.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
				slider.Scratch.PartCtrl_AttachSlider = slider.PartCtrl_AttachSlider 
			end
		end


		//Warning message for incompatible sfx roles
		//Automatically show and hide this in its own think func, so we don't have to update every cpoint's controls when a role changes

		local pnl2 = vgui.Create("DSizeToContents", pnl)
		pnl2:SetSizeX(false)
		pnl2:Dock(TOP)
		pnl2.Paint = function(self, w, h) 
			draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,70))
			//draw info icon
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(icon_error)
			//surface.DrawTexturedRect(padding,betweenitems,16,16)
			surface.DrawTexturedRect(padding,(h/2)-8,16,16)
		end

		local text = vgui.Create("DLabel", pnl2)
		text:SetDark(true)
		text:SetWrap(true)
		text:SetTextInset(0, 0)
		text:SetText("Can't attach an effect to both the projectile model and expire point at the same time!")
		text:SetContentAlignment(5)
		text:SetAutoStretchVertical(true)
		text:DockMargin(padding,padding-1,padding,0) //padding-1 for top is trial and error, results in nice 16px spacing on both top and bottom of text
		text:Dock(TOP)

		//pnl2.oldThink = pnl2.Think
		pnl2.Think = function(...)
			pnl2.ShouldShow = pnl2.ShouldShow or false
			if !IsValid(self) then return end
			local new_shouldshow = self.SpecialEffectChildrenSorted.bad[ent2] and self.SpecialEffectChildrenSorted.bad[ent2][k]
			if pnl2.ShouldShow != new_shouldshow then
				if new_shouldshow then
					pnl2:DockPadding(16+padding,0,0,padding) //extra left to make room for the info icon; DSizeToContents is finicky and ignores the bottom dock margin of the lowermost item
					pnl2:DockMargin(4,padding,4,1000)
					pnl2:SetSizeY(true)
					pnl:DockPadding(0,0,0,4) //fit the warning message snugly at the bottom of the panel
				else
					pnl2:DockPadding(0,0,0,0)
					pnl2:DockMargin(0,0,0,0)
					pnl2:SetSizeY(false)
					pnl2:SetHeight(0)
					pnl:DockPadding(0,0,0,padding) //undo padding change from warning message
				end
				pnl2.ShouldShow = new_shouldshow
			end
			//pnl2.oldThink(...)
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

		self:StopParticles() //if the projectile model has its own built-in particle fx, don't show them on this ent (i.e. tf2 sentry rockets)
	else
		self.SpecialEffectChildrenSorted = self.SpecialEffectChildrenSorted or {[false] = {}, [true] = {}, bad = {}}
	end

	//list of projectile entities we've created; we use this to clean them up
	self.ProjectileEnts = {}
	self.ProjectileTimers = {}
	self.ProjectileHitData = {}

end




local cv_max = GetConVar("sv_partctrl_particlesperent")

function ENT:SpecialEffectThink()

	//if CLIENT and (!self.SpecialEffectChildren or table.Count(self.SpecialEffectChildren) == 0) then return end

	local max = nil
	if self:GetLoopSafety() then
		max = math.max(0, math.min(self:GetProjCount(), cv_max:GetInt()) - 1)
		//note: safety code is mostly copied from tracer - projectiles have a key difference from tracers, in that some projectiles might not have hit and played their impact fx yet 
		//upon the start of the next loop, meaning the max won't get rid of them all uniformly like it does with the other fx. this is still acceptable because it fulfills the *safety*
		//purpose of this feature, preventing too many fx from being created at once.
	end
	local time = CurTime()
	local svproj = self:GetProjServerside() and svproj_enabled:GetBool()

	local ispaused = false
	local starttime
	if !svproj then
		starttime = self.ParticleStartTime
	else
		starttime = self:GetParticleStartTime()
	end
	if starttime and starttime > 0 then
		local pausetime = self:GetPauseTime()
		ispaused = pausetime >= 0 and pausetime <= (time - starttime)
		if ispaused then
			//MsgN("pausing")
			//if not paused, but should be, then pause it
			local didpause
			if CLIENT then
				for child, _ in pairs (self.SpecialEffectChildren) do
					if !child.PauseOverride then
						didpause = true
						child.PauseOverride = true
					end
				end
			end
			//pause projectiles, and store their velocity
			for _, proj in pairs (self.ProjectileEnts) do
				if IsValid(proj) then
					local phys = proj:GetPhysicsObject()
					if IsValid(phys) then
						if phys:IsMotionEnabled() then
							self.ProjectileStoredVel = self.ProjectileStoredVel or {}
							if !self.ProjectileStoredVel[proj] then
								self.ProjectileStoredVel[proj] = {
									vel = phys:GetVelocity(),
									angvel = phys:GetAngleVelocity()
								}
								didpause = true //don't update the pausetime if we get unfrozen by the physgun while paused
							end
							phys:EnableMotion(false)
						end
					end
				end
			end
			if didpause then
				//MsgN("pausing")
				self.ParticlePauseTime = time
			end
		else
			//MsgN("unpausing")
			//if paused, but shouldn't be, then unpause it
			local didunpause
			if CLIENT then
				for child, _ in pairs (self.SpecialEffectChildren) do
					if child.PauseOverride then
						didunpause = true
						child.PauseOverride = nil
					end
				end
			end
			//unpause projectiles and restore their velocity
			if self.ProjectileStoredVel then
				for proj, tab in pairs (self.ProjectileStoredVel) do
					if IsValid(proj) then
						local phys = proj:GetPhysicsObject()
						if IsValid(phys) then
							//if !phys:IsMotionEnabled() then
								phys:EnableMotion(true)
								//PrintTable(tab)
								phys:SetVelocity(tab.vel)
								phys:SetAngleVelocity(tab.angvel)
								didunpause = true
							//end
						end
					end
				end
				self.ProjectileStoredVel = nil
			end
			if didunpause then
				//MsgN("unpausing")
				if self.ParticlePauseTime != nil then
					//change the particlestarttime to compensate for the time we spent paused, so that if we pause it 
					//again afterward, the effect's lifetime doesn't include the time it spent paused prior to that
					local diff = (time - self.ParticlePauseTime)
					if (!svproj and CLIENT) then
						self.ParticleStartTime = starttime + diff
					elseif (svproj and SERVER) then
						self:SetParticleStartTime(starttime + diff)
					end
					//do the same for loop time
					if self.LastLoop then
						self.LastLoop = self.LastLoop + diff
					end
					//do the same for projectile lifetime
					for k, v in pairs (self.ProjectileTimers) do
						self.ProjectileTimers[k] = v + diff
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
		if CLIENT then
			for child, _ in pairs (self.SpecialEffectChildren) do
				child.MaxOldParticlesOverride = max
			end
		end
		if !ispaused then 
			if (!svproj and CLIENT) or (svproj and SERVER) then
				local loop = self:GetLoop()
				if self.was_waiting then
					local wait = false
					if CLIENT then
						for child, _ in pairs (self.SpecialEffectChildren) do
							local pcf = PartCtrl_GetGamePCF(child:GetPCF(), child:GetPath())
							if istable(PartCtrl_ProcessedPCFs[pcf]) and istable(PartCtrl_ProcessedPCFs[pcf][child:GetParticleName()]) //don't get stuck here if a child has an invalid effect, just skip it
							and !child.ParticleInfo then
								wait = true
								break
							end
						end
					end
					if !wait then
						if (!svproj and CLIENT) then
							self.ParticleStartTime = nil //effect was either newly spawned, or disabled and enabled, so reset the timer
						elseif (svproj and SERVER) then
							self:SetParticleStartTime(0)
						end

						self.ParticlePauseTime = nil
						self.was_waiting = nil
						self:CreateProjectile()
					end
				end
				if loop then //loop mode 2: repeat every X seconds
					if self.LastLoop and (self.LastLoop + math.max(0.0001, self:GetLoopDelay())) <= time then //don't let the loop delay actually be 0 here, otherwise it'll make a new effect every frame while paused
						local wait = false
						if CLIENT then
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
						end
						if !wait then
							self:CreateProjectile()
							self.LastLoop = nil
						end
					end
					
					if self.LastLoop == nil then
						self.LastLoop = time
						//MsgN(time, ": set last loop to ", self.LastLoop)
					end
				end
			end
		end
	else
		if CLIENT then
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
		end
		self.LastLoop = nil //reset loop time, so it restarts the timer as soon as we reenable
		self.was_waiting = true
	end

	//Limit the number of spawned projectiles, just like ent_partctrl does with particles
	local max2 = cv_max:GetInt()
	if max != nil then
		if !numpadisdisabling then
			max2 = self:GetProjCount()
		else
			max2 = 0
		end
	end
	while #self.ProjectileEnts > max2 do
		local v = self.ProjectileEnts[1]
		if IsValid(v) then v:Remove() end
		table.remove(self.ProjectileEnts, 1)
	end

	//Do projectile timers
	if !ispaused then
		for proj, dietime in pairs (self.ProjectileTimers) do
			if IsValid(proj) then
				if CLIENT then proj:FrameAdvance() end //make clientside projs play their idle animation, if applicable
				if time >= dietime then
					if CLIENT then
						if IsValid(proj) and !proj.DontDoExpire and IsValid(self) then
							if self.ProjectileHitData[proj] then
								self:StartParticle(proj, self.ProjectileHitData[proj].HitPos, -self.ProjectileHitData[proj].HitNormal)
							else
								self:StartParticle(proj, true)
							end
						end
					else
						if IsValid(proj) and !proj.DontDoExpire then
							if self.ProjectileHitData[proj] then
								proj:DoExpire(self.ProjectileHitData[proj].HitPos, -self.ProjectileHitData[proj].HitNormal)
							else
								proj:DoExpire()
							end
						end
					end
					proj:Remove()
				end
			else
				self.ProjectileTimers[proj] = nil
				self.ProjectileHitData[proj] = nil
			end
		end
	end

	self:NextThink(time)
	return true

end




local ang_fwd = Angle(0,0,0)
local ang_back = Angle(0,180,0)
local ang_left = Angle(0,90,0)
local ang_right = Angle(0,-90,0)
local ang_up = Angle(-90,0,0)
local ang_down = Angle(90,0,0)

function ENT:CreateProjectile()

	self.hitfunc = self.hitfunc or function(proj, data)
		if IsValid(proj) and IsValid(self) then
			local time = CurTime()
			local svproj = self:GetProjServerside() and svproj_enabled:GetBool()

			//dumb duplicated code from think func; don't register hits if the effect is paused
			local ispaused = false
			local starttime
			if !svproj then
				starttime = self.ParticleStartTime
			else
				starttime = self:GetParticleStartTime()
			end
			if starttime and starttime > 0 then
				local pausetime = self:GetPauseTime()
				ispaused = pausetime >= 0 and pausetime <= (time - starttime)
			end
			if ispaused then return end

			if proj.Hit then return end //there's no reason to call this more than once
			proj.Hit = true
			if proj.lifetime_posthit == 0 then
				self.ProjectileHitData[proj] = data
				if CLIENT then proj:SetNoDraw(true) end //fix clientside projs that hit the world appearing at a deflected angle for a split sec until they get deleted; serverside projs don't have this problem
			end
			self.ProjectileTimers[proj] = math.min(self.ProjectileTimers[proj], time + proj.lifetime_posthit)
		end
	end

	local ent = self:GetSpecialEffectParent()
	if !IsValid(ent) then return end
	local time = CurTime()

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
		//a lot of attachment points are oriented at an angle on the roll axis (i.e. hl2 gun muzzles) - correct this, we want the default projectile angle to be upright
		local _, ang2 = WorldToLocal(pos, ang, ent:GetPos(), ent:GetAngles())
		ang = Angle(ang.p,ang.y,ang.r - ang2.r)
	else
		ang = ent:GetAngles()
		pos = ent:GetPos()
	end
	local dir = self:GetProjDir()
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

	//Save particle creation time (used for pausing, which needs to pause at a certain point in the effect's lifetime)
	if CLIENT then
		if !self.ParticleStartTime then
			self.ParticleStartTime = time
		end
	else
		if self:GetParticleStartTime() <= 0 then
			self:SetParticleStartTime(time)
		end
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
		if spread > 0 then
			fwd:RotateAroundAxis(fwd:Forward(), randang.r)
			fwd:RotateAroundAxis(fwd:Right(), randang.p * (spread / 2))
			fwd:RotateAroundAxis(fwd:Up(), randang.y * (spread / 4))
			//now de-randomize the roll so the prop still spawns upright
			fwd:RotateAroundAxis(fwd:Forward(), -randang.r)
		end

		local proj
		if CLIENT then
			proj = ClientsideModel(self:GetModel())
		else
			proj = ents.Create("ent_partctrl_proj")
			proj:SetModel(self:GetModel())
			proj:SetOwnerEntity(self) //reference to the effect ent on the projectile; it uses this to run StartParticles on clients
		end
		proj:SetOwner(ent) //don't collide with the prop that the effect ent is parented to
		proj:SetPos(pos)
		local spinang
		local projang = Angle(fwd) //create a copy of the firing direction to use for the prop angle, so we can rotate the prop without rotating the firing direction
		local projang_ = self:GetProjAngle()
		if projang_ == 0 then
			//forward
			spinang = ang_fwd
		elseif projang_ == 1 then
			//back
			projang:RotateAroundAxis(fwd:Up(), 180)
			spinang = ang_back
		elseif projang_ == 2 then
			//left
			projang:RotateAroundAxis(fwd:Up(), 90)
			spinang = ang_right //yes, this is inverted
		elseif projang_ == 3 then
			//right
			projang:RotateAroundAxis(fwd:Up(), -90)
			spinang = ang_left //^
		elseif projang_ == 4 then
			//up
			projang:RotateAroundAxis(fwd:Right(), 90)
			spinang = ang_down //^
		else
			//down
			projang:RotateAroundAxis(fwd:Right(), -90)
			spinang = ang_up //^
		end
		proj:SetAngles(projang)

		if self:GetProjCollide() then
			proj:SetCollisionGroup(COLLISION_GROUP_NONE) //default collision group, collide with everything
		else
			proj:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS) //don't collide with other projectiles
		end
		if !util.IsValidProp(proj:GetModel()) then
			proj:PhysicsInitBox(proj:GetModelBounds())
		else
			proj:PhysicsInit(SOLID_VPHYSICS)
		end

		proj:SetSkin(self:GetSkin())
		proj:SetMaterial(self:GetMaterial())
		local col = self:GetColor()
		proj:SetColor(col)
		if col.a < 255 then
			proj:SetRenderMode(RENDERMODE_TRANSCOLOR)
		end

		self.ProjectileTimers[proj] = time + self:GetProjLifetimePre()
		proj.lifetime_posthit = self:GetProjLifetimePost()
		if CLIENT then
			proj:AddCallback("PhysicsCollide", self.hitfunc)
		else
			proj.PhysicsCollide = self.hitfunc
		end

		proj:Spawn()
		table.insert(self.ProjectileEnts, proj)
		if CLIENT then self:StartParticle(proj) end //serverside projectile ent handles this in its clientside think func

		local phys = proj:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetVelocity(fwd:Forward() * self:GetProjVelocity()) //note: client projs have a max speed of 2000, and server projs have a max speed of 4000. don't know if there's a way to bypass either of these.
			local spinvel = self:GetProjSpinVelocity()
			if spinvel != 0 then
				local spinaxis = self:GetProjSpin()
				if spinaxis == 0 then
					//random tumble, emulates tf2 grenade tumble code since that's what the random setting was originally made for (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/tf/tf_weaponbase_gun.cpp#L694)
					phys:SetAngleVelocity((spinang:Forward()*spinvel) + (spinang:Right()*math.Rand(-spinvel*2,spinvel*2)))
				elseif spinaxis == 1 then
					//random axis
					local ang = Angle()
					ang:Random()
					ang = ang:Forward()
					phys:SetAngleVelocity(ang * spinvel)
				elseif spinaxis == 2 then
					//pitch
					phys:SetAngleVelocity(spinang:Right()*-spinvel )
				elseif spinaxis == 3 then
					//yaw
					phys:SetAngleVelocity(spinang:Up()*spinvel )
				else
					//roll
					phys:SetAngleVelocity(spinang:Forward()*spinvel )
				end
			end
			phys:EnableGravity(self:GetProjGravity()) //would like to use proj:SetGravity() instead for more fine-tuned control, but that doesn't work on vphysics ents 
			phys:EnableDrag(self:GetProjDrag())
			if CLIENT and !self:GetProjPhysSounds() then
				phys:SetMaterial("gmod_silent") //EntityEmitSound doesn't catch impact sounds, so use this to make them silent
				proj.PartCtrl_ProjDisableSounds = true //gmod_silent doesn't catch scrape sounds, so use the hook below to remove them
				//serverside projectile ent handles both of these in its initialize func
			end
		end

	end
end

hook.Add("EntityEmitSound", "PartCtrl_ProjDisableSounds", function(data)
	local ent = data.Entity
	if IsValid(ent) and ent.PartCtrl_ProjDisableSounds then
		return false
	end
end)




if CLIENT then

	function ENT:StartParticle(proj, hitpos, hitnorm)

		local ent = self:GetSpecialEffectParent()
		if !IsValid(ent) then return end

		//If hitpos is available, then do expire effect
		local hit
		if hitpos then
			//Unless the projectile hit a surface, use a generic pos/ang
			if isbool(hitpos) then
				//if !IsValid(proj) then return end
				hitpos = proj:GetPos()
			end
			local ang = nil
			local hitdir = self:GetProjHitDir()
			if hitdir < 2 then
				//surface normal
				if !hitnorm then
					local tr = {}
					tr.start = hitpos
					tr.endpos = hitpos + Vector(0,0,-32) //trace downward to find the floor we're sitting on; matches tf2 grenade code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/tf/tf_weaponbase_grenadeproj.cpp#L468)
					tr.filter = proj
					tr.collisiongroup = COLLISION_GROUP_INTERACTIVE_DEBRIS //don't hit other projectiles
					tr = util.TraceLine(tr)
					if tr.Entity != nil and tr.Fraction < 1 then //tr.Fraction check stops this from returning a bad angle when stuck in a wall
						hitnorm = tr.HitNormal //use the floor's angle
					else
						hitnorm = -tr.Normal //use the same angle as a flat floor if we explode mid-air, for consistency
					end
				end
				if hitdir == 1 then
					//inverted surface normal
					hitnorm = -hitnorm
				end
				ang = hitnorm:Angle()
			elseif hitdir < 4 then
				//toward start point
				local pos = nil
				if IsValid(ent.AttachedEntity) then
					pos = ent.AttachedEntity:GetAttachment(self:GetAttachmentID())
				else
					pos = ent:GetAttachment(self:GetAttachmentID())
				end
				if istable(pos) then
					pos = pos.Pos
				else
					pos = ent:GetPos()
				end
				local hitnorm = (hitpos-pos):GetNormalized()
				//away from start point
				if hitdir == 3 then
					hitnorm = -hitnorm
				end
				ang = hitnorm:Angle()
			elseif hitdir == 4 then
				//forward
				ang = ang_fwd
			elseif hitdir == 5 then
				//back
				ang = ang_back
			elseif hitdir == 6 then
				//left
				ang = ang_left
			elseif hitdir == 7 then
				//right
				ang = ang_right
			elseif hitdir == 8 then
				//up
				ang = ang_up
			else
				//down
				ang = ang_down
			end

			hit = ents.CreateClientside("ent_partctrl_sfxtarget")
			hit:SetPos(hitpos)
			hit:SetAngles(ang_back) //immediately pointing exactly forward causes the angle to break for some reason, but this fixes it
			hit:SetAngles(ang)
			hit:Spawn()
			hit.OwnerEntity = self
			hit.Particles = {}
		end

		for child, _ in pairs (self.SpecialEffectChildrenSorted[tobool(hitpos)]) do
			if child.PartCtrl_Ent then
				local pcf = PartCtrl_GetGamePCF(child:GetPCF(), child:GetPath())
				local cpointtab = PartCtrl_ProcessedPCFs[pcf][child:GetParticleName()].cpoints
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

	self.ParticleStartTime = nil
	if SERVER then self:SetParticleStartTime(0) end
	self.ParticlePauseTime = nil
	self.was_waiting = true //tells the think func to run StartParticle as soon as possible

	if CLIENT then
		if self.SpecialEffectChildren then
			self.SpecialEffectChildrenSorted = {[false] = {}, [true] = {}, bad = {}}

			for child, _ in pairs (self.SpecialEffectChildren) do
				child:BeginNewParticle()

				//Sort our particle effects by when they should play; do this here because we have to be sure the client has received the particleinfo for the fx first
				if child.ParticleInfo then
					local attach_to_proj = nil
					local attach_to_expire = nil
					local pcf = PartCtrl_GetGamePCF(child:GetPCF(), child:GetPath())
					local cpointtab = PartCtrl_ProcessedPCFs[pcf][child:GetParticleName()].cpoints
					for k, v in pairs (child.ParticleInfo) do
						if cpointtab[k].mode == PARTCTRL_CPOINT_MODE_POSITION then
							if v.sfx_role == 1 then
								attach_to_proj = attach_to_proj or {}
								attach_to_proj[k] = true
							elseif v.sfx_role == 2 then
								attach_to_expire = attach_to_expire or {}
								attach_to_expire[k] = true
							end	
						end
					end
					//If the particle doesn't attach to the projectile OR the expire effect (i.e. muzzleflashes),
					//or the particle attaches to the projectile but not the expire effect,
					//then play it when the projectile initializes.
					if (!attach_to_proj and !attach_to_expire) or (attach_to_proj and !attach_to_expire) then
						self.SpecialEffectChildrenSorted[false][child] = true
					//If the particle doesn't attach to the projectile, but instead the expire effect,
					//then play it when the projectile expires.
					elseif (!attach_to_proj and attach_to_expire) then
						self.SpecialEffectChildrenSorted[true][child] = true
					//If a particle wants to attach to both the projectile AND the expire effect,
					//then don't play it, because those two roles can't exist at the same time.
					elseif (attach_to_proj and attach_to_expire) then
						//Keep a list of all the offending cpoints so that we can add warnings to them in the controls
						local tab = {}
						table.Merge(tab, attach_to_proj)
						table.Merge(tab, attach_to_expire)
						self.SpecialEffectChildrenSorted.bad[child] = tab
					end
				end
			end
		end
	end

	//reset projectile ents and numpad on both server and client
	if self.ProjectileEnts then
		for _, proj in pairs (self.ProjectileEnts) do
			if IsValid(proj) then
				proj.DontDoExpire = true //make sure they don't make expire fx on reset; this can happen if we reset this effect after it's been paused for a long time
				proj:Remove()
			end
		end
		self.ProjectileEnts = {}
	end
	self.LastLoop = nil

end




function ENT:SpecialEffectOnRemove()

	if self.ProjectileEnts then
		for _, proj in pairs (self.ProjectileEnts) do
			if IsValid(proj) then proj:Remove() end
		end
		self.ProjectileEnts = {}
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
			local svproj = self:GetProjServerside() and svproj_enabled:GetBool()
			if !svproj then
				//This requires a ParticleStartTime value that only exists clientside, so tell the client to send it, using the same "effect_pause" input as the cpanel
				if IsValid(ply) and ply.IsPlayer and ply:IsPlayer() then
					net.Start("PartCtrl_DoPauseInput_SendToCl")
						net.WriteEntity(self)
					net.Send(ply)
				else
					local pcf = PartCtrl_GetGamePCF(self:GetPCF(), self:GetPath())
					local name = self:GetParticleName()
					MsgN(self, " tried to send a numpad pause input with invalid player ", ply, ". Report this!")
				end
			else
				//stupid duplicated code from input receive func
				if self:GetPauseTime() < 0 and self:GetParticleStartTime() > 0 then
					//not paused, so pause it at the current time
					self:SetPauseTime(CurTime() - self:GetParticleStartTime())
				else
					//paused, so unpause it
					self:SetPauseTime(-1)
				end
			end

		elseif mode == 2 then

			//Mode 2: Restart effect
			//Refresh special effect on server
			if self.SpecialEffectRefresh then self:SpecialEffectRefresh() end
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
	"proj_spread",
	"proj_count",
	"proj_dir",
	"proj_hitdir",
	"proj_velocity",
	"proj_gravity",
	"proj_drag",
	"proj_lifetime_pre",
	"proj_lifetime_post",
	"proj_collide",
	"proj_physsounds",
	"proj_serverside",
	"projvis_model",
	"projvis_skin",
	"projvis_angle",
	"projvis_spin",
	"projvis_spin_velocity",
	"projvis_material",
	"projvis_color",
}
ENT.EditMenuInputs_bits = 6 //max 63
ENT.EditMenuInputs = table.Flip(EditMenuInputs)

if CLIENT then
	
	function ENT:SpecialEffectDoInput(input, args)

		if input == "effect_pause" then

			if !(self:GetProjServerside() and svproj_enabled:GetBool()) then
				//For clientside projectiles, pausing works the same as it does for other fx
				if self:GetPauseTime() < 0 and self.ParticleStartTime then
					//not paused, so pause it at the current time
					net.WriteFloat(CurTime() - self.ParticleStartTime)
					//pause the effect immediately, don't wait for the pausetime nwvar to be networked back to us
					self:SetPauseTime(CurTime() - self.ParticleStartTime)
				else
					//paused, so unpause it
					net.WriteFloat(-1)
					self:SetPauseTime(-1)
				end
			else
				//For serverside projectiles, ParticleStartTime is handled serverside, so tell the server to figure it out
				net.WriteFloat(-1) //dummy value, just in case the client thinks we're doing clientside projectiles and tries to read it
			end

		elseif input == "loop_mode" then

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

		elseif input == "proj_spread" then
			
			net.WriteFloat(args[1]) //new spread

		elseif input == "proj_count" then 

			net.WriteUInt(args[1], 5) //new count; generous max of 31

		elseif input == "proj_dir" then
			
			net.WriteUInt(args[1], 3) //new dir (0-5)

		elseif input == "proj_hitdir" then

			net.WriteUInt(args[1], 4) //new dir (0-9)

		elseif input == "proj_velocity" then
			
			net.WriteFloat(args[1]) //new velocity

		elseif input == "proj_gravity" then
			
			net.WriteBool(args[1])

		elseif input == "proj_drag" then
			
			net.WriteBool(args[1])

		elseif input == "proj_lifetime_pre" then
			
			net.WriteFloat(args[1]) //new lifetime (pre-hit)

		elseif input == "proj_lifetime_post" then
			
			net.WriteFloat(args[1]) //new lifetime (post-hit)

		elseif input == "proj_collide" then
			
			net.WriteBool(args[1])

		elseif input == "proj_physsounds" then
			
			net.WriteBool(args[1])

		elseif input == "proj_serverside" then
			
			net.WriteBool(args[1])

		elseif input == "projvis_model" then

			net.WriteString(args[1])

		elseif input == "projvis_skin" then 

			net.WriteUInt(args[1], 6) //new skin; i think the max number of skins is 32

		elseif input == "projvis_angle" then
			
			net.WriteUInt(args[1], 3) //new dir (0-5)

		elseif input == "projvis_spin" then
			
			net.WriteUInt(args[1], 3) //new spin angle (0-4)

		elseif input == "projvis_spin_velocity" then
			
			net.WriteFloat(args[1]) //new velocity

		elseif input == "projvis_material" then
			
			net.WriteString(args[1]) //new material

		elseif input == "projvis_color" then
			
			net.WriteColor(args[1], true) //new color

		end

	end

else
	
	function ENT:SpecialEffectDoInput(input, ply)

		local refreshtable = false

		if input == "effect_pause" then
			
			if !(self:GetProjServerside() and svproj_enabled:GetBool()) then
				//For clientside projectiles, pausing works the same as it does for other fx
				self:SetPauseTime(net.ReadFloat())
			else
				//For serverside projectiles, ParticleStartTime is handled serverside
				if self:GetPauseTime() < 0 and self:GetParticleStartTime() > 0 then
					//not paused, so pause it at the current time
					self:SetPauseTime(CurTime() - self:GetParticleStartTime())
				else
					//paused, so unpause it
					self:SetPauseTime(-1)
				end
				net.ReadFloat() //dummy value, see send func
			end

		elseif input == "loop_mode" then
				
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
				//everything else should be handled in Think once the client receives the new NumpadState value
			end

		elseif input == "proj_spread" then

			self:SetProjSpread(net.ReadFloat())
			refreshtable = true

		elseif input == "proj_count" then

			self:SetProjCount(net.ReadUInt(5))
			refreshtable = true

		elseif input == "proj_dir" then
			
			self:SetProjDir(math.min(net.ReadUInt(3), 5))
			refreshtable = true

		elseif input == "proj_hitdir" then

			self:SetProjHitDir(math.min(net.ReadUInt(4), 9))
			refreshtable = true

		elseif input == "proj_velocity" then
			
			self:SetProjVelocity(net.ReadFloat())
			refreshtable = true

		elseif input == "proj_gravity" then

			self:SetProjGravity(net.ReadBool())
			refreshtable = true

		elseif input == "proj_drag" then
			
			self:SetProjDrag(net.ReadBool())
			refreshtable = true

		elseif input == "proj_lifetime_pre" then
			
			self:SetProjLifetimePre(net.ReadFloat())
			refreshtable = true

		elseif input == "proj_lifetime_post" then
			
			self:SetProjLifetimePost(net.ReadFloat())
			refreshtable = true

		elseif input == "proj_collide" then
			
			self:SetProjCollide(net.ReadBool())
			refreshtable = true

		elseif input == "proj_physsounds" then
			
			self:SetProjPhysSounds(net.ReadBool())
			refreshtable = true

		elseif input == "proj_serverside" then
			
			self:SetProjServerside(net.ReadBool())
			refreshtable = true

		elseif input == "projvis_model" then

			self:SetModel(net.ReadString())
			self:StopParticles() //if the projectile model has its own built-in particle fx, don't show them on this ent (i.e. tf2 sentry rockets)
			refreshtable = true

		elseif input == "projvis_skin" then

			self:SetSkin(net.ReadUInt(6))
			refreshtable = true

		elseif input == "projvis_angle" then
			
			self:SetProjAngle(math.min(net.ReadUInt(3), 5))
			refreshtable = true

		elseif input == "projvis_spin" then
			
			self:SetProjSpin(math.min(net.ReadUInt(3), 4))
			refreshtable = true

		elseif input == "projvis_spin_velocity" then
			
			self:SetProjSpinVelocity(net.ReadFloat())
			refreshtable = true

		elseif input == "projvis_material" then

			local Data = {MaterialOverride = net.ReadString()}
			
			//duplicate of SetMaterial from the material stool, this is dumb but it gets the job done
			--
			-- Make sure this is in the 'allowed' list in multiplayer - to stop people using exploits
			--
			if ( !game.SinglePlayer() && !list.Contains( "OverrideMaterials", Data.MaterialOverride ) && Data.MaterialOverride != "" ) then return end

			self:SetMaterial( Data.MaterialOverride )
			duplicator.StoreEntityModifier( self, "material", Data )

		elseif input == "projvis_color" then
			
			local Data = {Color = net.ReadColor()}

			self:SetColor(Data.Color)

			duplicator.StoreEntityModifier( self, "colour", Data )

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

		//Don't store this either
		data.ProjectileEnts = nil

	end

end




duplicator.RegisterEntityClass("ent_partctrl_sfx_proj", function(ply, data)

	local ent = ents.Create("ent_partctrl_sfx_proj")
	if !ent:IsValid() then return false end

	//default dtvars for old dupes that don't have them
	if data.DT.PauseTime == nil then data.DT.PauseTime = -1 end

	//duplicator.GenericDuplicatorFunction(ply, data)
	duplicator.DoGeneric(ent, data)
	duplicator.DoGenericPhysics(ent, ply, data)

	ent.DoneFirstSpawn = data.DoneFirstSpawn //all special fx need this; don't set nwvar defaults or make a parent grip point if the dupe is already taking care of those
	ent:SetPlayer(ply) //NOTE: this still works if ply doesn't exist

	ent:Spawn()

	ent:SetModel(data.Model) //override the model set in initialize with our duplicated model

	return ent

end, "Data")

PartCtrl_AddBlankSpecialEffect(ENT) //Add blank variant to spawnmenu