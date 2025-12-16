//TODO: should these be somewhere else? they're all assigned in pcf_processing.lua, but that file is super bloated, and this is the panel that actually displays them.
language.Add("PartCtrl_Cull_ZeroAlpha",			"This effect has an alpha of 0, preventing it from rendering. If this effect was flagged\nin error (it's actually visible), then report this bug!")
language.Add("PartCtrl_Cull_ZeroAlpha_Short",		"Effect doesn't render")
language.Add("PartCtrl_Cull_NoRendererOrEmitter",	"This effect is missing a valid renderer, emitter, or material, and has no control points\ninherited from children, which means it's probably empty, blank, or invisible. If this\neffect was flagged in error (it's actually visible), then report this bug!")
language.Add("PartCtrl_Cull_NoRendererOrEmitter_Short",	"Effect doesn't render")
language.Add("PartCtrl_Cull_NoParticlePos",		"This effect doesn't have any operators setting the particles' spawn position (i.e. 'Position\nWithin Box Random'), or their position is being overwritten by another operator (i.e.\n'Set Control Point Positions') which means it will always spawn particles in the same\nimmovable location on the map. This isn't useful to players 99% of the time, and would\njust clutter up spawnlists and searches with unusable effects. If this effect was flagged\nin error (it's not actually stuck in one place), then report this bug!")
language.Add("PartCtrl_Cull_NoParticlePos_Short",	"Effect is immovable")
language.Add("PartCtrl_Cull_PreventNameBasedLookup",	"This effect has the value preventNameBasedLookup set to true, which prevents the game\nfrom spawning it directly, though other effects can still use it as a child.")
language.Add("PartCtrl_Cull_PreventNameBasedLookup_Short","Effect is non-spawnable")
language.Add("PartCtrl_Cull_ScreenSpace_NotViewModel",	"This effect has the value \"screen space effect\" set to true, but isn't set\nas a view model effect, which prevents it from rendering properly.")
language.Add("PartCtrl_Cull_ScreenSpace_NotViewModel_Short","Effect doesn't render")
language.Add("PartCtrl_Cull_ScreenSpace_Blacklisted",	"sv_partctrl_blacklist_screenspace is 1, blocking all fx with \"screen space effect\"")

local PANEL = {}

local icon_invalid = Material("icon16/cancel.png")
local icon_multiplydefined = Material("icon16/page_copy.png")
local icon_multiplydefined_2 = Material("icon16/bullet_error.png")
local icon_position = Material("sprites/grip") //Material("icon16/arrow_right.png") //Material("icon16/arrow_inout.png")
local icon_edit = Material("icon16/pencil.png")
local icon_color = Material("icon16/color_wheel.png")
local icon_test = Material("icon16/color_wheel.png")
local icon_utilfx = Material("icon16/cog.png")
local icon_info = Material("icon16/information.png")

if system.IsLinux() then
	surface.CreateFont("PartCtrl_DermaDefaultSmall", {
		font		= "DejaVu Sans",
		size		= 14, //don't have this font, so just have to trust that this is right (1pt larger than the tahoma, like in https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/derma/init.lua#L6C1-L45C4)
		weight		= 1000,
		extended	= true
	})
else
	surface.CreateFont("PartCtrl_DermaDefaultSmall", {
		font		= "Tahoma",
		size		= 13,
		weight		= 1000,
		extended	= true
	})
end

function PANEL:Setup(pcf, name, path)

	self.pcf = pcf
	self.name = name
	self.path = path
	self:SetName(name) //display name on icon
	self:SetContentType("partctrl")

	if pcf == "UtilFx" then
		self:SetMaterial("icon16/cog.png") //icon_utilfx) //why doesn't this one take a Material()? whatever
	end

	self.DoneSetup = true

end

local ViewAngle = Angle(25, 220, 0)
local icon_loading = Material("vgui/loading-rotate.vmt") //TODO: replace this with a custom texture eventually, something bulkier that looks better when it's drawn small like this
local cv_debugicons = GetConVar("cl_partctrl_debug_spawnicons")
function PANEL:Paint(w, h)

	if !self.DoneSetup then
		baseclass.Get("ContentIcon").Paint(self, w, h)
		return
	end

	//Add this effect to PartCtrl_IconFx - even if we're not showing a particle in this panel, 
	//we still want it to populate other stuff like icons and tooltips
	local pcf = PartCtrl_GetGamePCF(self.pcf, self.path)
	local name = self.childname or self.name //when the player hovers over a child effect in the dropdown, override the spawnicon to display that effect instead
	PartCtrl_IconFx[pcf] = PartCtrl_IconFx[pcf] or {}
	PartCtrl_IconFx[pcf][name] = PartCtrl_IconFx[pcf][name] or {}
	PartCtrl_IconFx[pcf][name].panels = PartCtrl_IconFx[pcf][name].panels or {}
	
	local itab = PartCtrl_IconFx[pcf][name]
	local tooltip = itab.tooltip
	local overridden = self:IsCurrentlyOverridden(pcf, name)
	if tooltip then
		local path_nice = ""
		local path_dev = ""
		if self.path then
			path_nice = self.path
			for k, v in pairs (engine.GetGames()) do
				if v.folder == self.path then
					path_nice = v.title
					break
				end
			end
			path_nice = ", probably from game " .. path_nice
			if GetConVarNumber("developer") >= 1 then
				path_dev = "\n(path: " .. self.path .. ")"
			end
		end
		local override_pcf = "this file"
		if overridden then
			override_pcf = '"' .. overridden .. '"'
		end
		tooltip = string.Replace(tooltip, "%PATH_NICE", path_nice)
		tooltip = string.Replace(tooltip, "%PATH_DEV", path_dev)
		tooltip = string.Replace(tooltip, "%OVERRIDE_PCF", override_pcf)
	end
	self:SetTooltip(tooltip)

	
	local bd = self.Border + 4 //this resizes dynamically when the button is clicked on
	local showparticle = true

	//If the icon's effect is currently being overridden by another pcf's effect of the same name, show a notification instead
	if overridden then
		local mdef_width = math.min(w,h) * 0.5 - bd
		surface.SetDrawColor(0,0,0,64)
		surface.DrawRect(0 + bd, 0 + bd, w - (bd*2), h - (bd*2))

		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(icon_multiplydefined)
		surface.DrawTexturedRect((w-mdef_width)/2, (h-mdef_width)/2, mdef_width, mdef_width)
		surface.SetMaterial(icon_multiplydefined_2)
		surface.DrawTexturedRect((w-mdef_width)/2, (h-mdef_width)/2, mdef_width, mdef_width)

		local text = "(click to load)"
		draw.SimpleTextOutlined(text, "DermaDefaultBold", w/2, h/2, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,255))
		showparticle = nil
	end

	//Draw particle preview
	itab.panels[self] = showparticle //don't bother creating a particle for this panel if we're not showing it
	if showparticle then 
		if itab.particle and itab.particle.IsValid and itab.particle:IsValid() then
			if itab.view then
				local x, y = self:LocalToScreen(0,0)
				cam.Start3D(itab.view.pos, ViewAngle, 90, x + bd, y + bd, w - (bd*2), h - (bd*2), 1, math.huge)

				//Buncha stuff copied from DModelPanel:DrawModel (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dmodelpanel.lua#L77);
				//properly cuts off the 3D render if this panel is partially hidden by scrolling
				local curparent = self
				local leftx, topy = self:LocalToScreen(0, 0)
				local rightx, bottomy = self:LocalToScreen(self:GetWide(), self:GetTall())
				while curparent:GetParent() != nil do
					curparent = curparent:GetParent()
					local x1, y1 = curparent:LocalToScreen(0, 0)
					local x2, y2 = curparent:LocalToScreen(curparent:GetWide(), curparent:GetTall())
					leftx = math.max(leftx, x1)
					topy = math.max(topy, y1)
					rightx = math.min(rightx, x2)
					bottomy = math.min(bottomy, y2)
					previous = curparent
				end
				render.ClearDepth(false)
				render.SetScissorRect(leftx, topy, rightx, bottomy, true)

				cam.StartOrthoView(-itab.view.ortho, itab.view.ortho, itab.view.ortho, -itab.view.ortho) //we use an orthogonal view instead of how RenderSpawnIcon does it, because RenderSpawnIcon's FOV code sucks really bad for icons that zoom out a lot
				itab.particle:Render()

				if cv_debugicons:GetBool() then
					if itab.mins and itab.maxs then
						render.DrawWireframeBox(vector_origin, angle_zero, itab.mins, itab.maxs, Color(255,255,255), true)
					end
					local mn, mx = itab.particle:GetRenderBounds()
					render.DrawWireframeBox(vector_origin, angle_zero, mn, mx, Color(255,0,0), true)
					if itab.particle2 and itab.particle2:IsValid() then
						local mn_, mx_ = itab.particle2:GetRenderBounds()
						render.DrawWireframeBox(vector_origin, angle_zero, mn_, mx_, Color(0,255,0), true)
					end
					if itab.particle3 then
						for k, v in pairs (itab.particle3) do
							if v:IsValid() then
								local mn_, mx_ = v:GetRenderBounds()
								if k == 1 then
									mn_.x = mn_.x - itab.particle3_forcedpositions[k]
									mx_.x = mn_.x
								elseif k == 2 then
									mn_.y = mn_.y - itab.particle3_forcedpositions[k]
									mx_.y = mn_.y
								elseif k == 3 then
									mn_.z = mn_.z - itab.particle3_forcedpositions[k]
									mx_.z = mn_.z
								elseif k == 4 then
									mx_.x = mx_.x - itab.particle3_forcedpositions[k]
									mn_.x = mx_.x
								elseif k == 5 then
									mx_.y = mx_.y - itab.particle3_forcedpositions[k]
									mn_.y = mx_.y
								else
									mx_.z = mx_.z - itab.particle3_forcedpositions[k]
									mn_.z = mx_.z
								end
								render.DrawWireframeBox(vector_origin, angle_zero, mn_, mx_, Color(0,0,255), true)
							end
						end
					end
				end

				render.SetScissorRect(0, 0, 0, 0, false) //also from DModelPanel:DrawModel
				cam.End3D()
				cam.EndOrthoView()
			end
		else
			//If particle is being throttled by crash prevention, draw loading icon
			if PartCtrl_AddParticles_CrashCheck_ThrottledPCFs[pcf] and (!itab.particle or !(itab.particle.IsValid and itab.particle:IsValid())) then
				local load_width = math.min(w,h) * 0.65
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(icon_loading)
				surface.DrawTexturedRectRotated(w/2, h/2, load_width, load_width, CurTime() * 300 % 360)
			end
		end
	end

	//Draw the default contenticon stuff on top of the particle
	baseclass.Get("ContentIcon").Paint(self, w, h)

	//Draw info icons
	if itab.icons then
		local x = self.Border + 8
		local y = self.Border + 8
		for k, v in pairs (itab.icons) do
			//Draw icon
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(v.icon)
			surface.DrawTexturedRect(x, y, 16, 16)
			//Draw icon2
			if v.icon2 then
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(v.icon2)
				surface.DrawTexturedRect(x, y, 16, 16)
			end
			//Draw number
			if v.num then
				draw.SimpleTextOutlined(v.num, "PartCtrl_DermaDefaultSmall", x+8, y+7, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,255))
			end
			x = x + 16 + 2 //move the position of the next icon to the right by the width of this icon, plus a bit more
			if x + 16 > (w - self.Border - 8) then //if this would cause the next icon to stick out past the right edge of the panel, then start a new row instead
				y = y + 16 + 2
				x = self.Border + 8
			end
		end
	end

end

function PANEL:IsCurrentlyOverridden(pcf, name)

	if !PartCtrl_IconFx[pcf][name].MultiplyDefined then return false end

	local function CheckEffectAndChildren(name2)
		if !(PartCtrl_PCFsByParticleName_CurrentlyLoaded[name2] == pcf)
		and !(PartCtrl_DuplicateFx[pcf][name2] and PartCtrl_PCFsByParticleName_CurrentlyLoaded[name2] == PartCtrl_DuplicateFx[pcf][name2]) then
			return PartCtrl_PCFsByParticleName_CurrentlyLoaded[name2]
		end
		for k, childtab in pairs (PartCtrl_ProcessedPCFs[pcf][name2].children) do
			//Also check all child fx for overrides
			local val = CheckEffectAndChildren(childtab.child)
			if val then return val end
		end
	end
	return PartCtrl_GetDataPCFNiceName(CheckEffectAndChildren(name))

end

PartCtrl_IconFx = {}

local function DoPosCPoints(self, p, particle3_k)

	local origin = vector_origin
	if p == self.particle2 and self.particle2_playerposfix then
		origin = LocalPlayer():GetPos()
	elseif particle3_k != nil then
		//TODO: should particle3 compensate for playerposfix too? don't think there are any fx that require this
		origin = Vector()
		if particle3_k == 1 or particle3_k == 4 then
			origin.x = self.particle3_forcedpositions[particle3_k]
		elseif particle3_k == 2 or particle3_k == 5 then
			origin.y = self.particle3_forcedpositions[particle3_k]
		else
			origin.z = self.particle3_forcedpositions[particle3_k]
		end
	end

	done_position_combine = false

	for k, pos in pairs (self.PosCPoints) do
		if p != self.particle2 or !self.OffsetPosCPoints or !self.OffsetPosCPoints[k] then
			if p == self.particle2 and self.particle2_playerposfix then
				p:AddControlPoint(k, LocalPlayer(), PATTACH_ABSORIGIN_FOLLOW, nil, pos)
			else
				p:SetControlPoint(k, pos + origin)
			end
			p:SetControlPointOrientation(k, angle_zero)
			if !done_position_combine then
				local function do_position_combine(k2)
					if p == self.particle2 and self.particle2_playerposfix then
						p:AddControlPoint(k2, LocalPlayer(), PATTACH_ABSORIGIN_FOLLOW, nil, pos)
					else
						p:SetControlPoint(k2, pos + origin)
					end
					p:SetControlPointOrientation(k2, angle_zero)
				end
				for _, k2 in pairs (self.iPositionCombine) do
					do_position_combine(k2)
				end
				if p == self.particle2 then
					//Move offset pos cpoints (distance scalars) in the same manner as position_combine cpoints,
					//to prevent them from stretching out the renderbounds
					if self.OffsetPosCPoints then
						for k2, _ in pairs (self.OffsetPosCPoints) do
							do_position_combine(k2)
						end
					end
				end
				done_position_combine = true
			end
		end
	end

end

local function DoColorCPoints(self)

	//For color cpoints, cycle through rainbow colors
	local speed = 50
	for i, k in pairs (self.iColorCPoints) do
		local offset = (360/#self.iColorCPoints)*(i-1) //if there are multiple color cpoints, try to make them distinct from each other
		//How this works: HSVToColor generates a 0-255 color, we convert this to the desired 0-1 color, and then we convert that to 
		//whatever scale inMin/inMax uses, which could be anything (the particle then receives this and internally converts it to 0-1 scale)
		local col = HSVToColor(((CurTime() * speed) + offset) % 360, 1, 1)
		col = Vector(col.r/255, col.g/255, col.b/255)
		local tab = self.ColorCPoints[k]
		col.x = math.Remap(col.x, tab.outMin2.x, tab.outMax2.x, tab.inMin.x, tab.inMax.x)
		col.y = math.Remap(col.y, tab.outMin2.y, tab.outMax2.y, tab.inMin.y, tab.inMax.y)
		col.z = math.Remap(col.z, tab.outMin2.z, tab.outMax2.z, tab.inMin.z, tab.inMax.z)
		self.particle:SetControlPoint(k, col)
	end

end

//All spawnicon fx are handled by this external think func, instead of by individual panels.
//Each effect has one single particlesystem instance, which is shared between every spawnicon for that effect.
//This is to try to reduce the lag caused by spawnmenu search loading, which rapidly deletes and replaces all the search result spawnicons every few
//secs - instead of each new panel having to do all this from scratch each time, the effects can be seamlessly transfered over to the new panels.
hook.Add("Think", "PartCtrl_ManageIconFx_Think", function()

	local autohide = !g_SpawnMenu:IsVisible()

	for pcf, pcftab in pairs (PartCtrl_IconFx) do
		local utilfx = (pcf == "UtilFx")
		for name, _ in pairs (pcftab) do

			local self = PartCtrl_IconFx[pcf][name] //this works??

			//First, go through the list of panels using this effect, and remove any that are invalid or not visible
			for panel, _ in pairs (self.panels) do
				if !IsValid(panel) or (autohide or !panel:GetParent():GetParent():GetParent():IsVisible()) then //this dumb nested parent is the spawnlist containing the spawnicon (or a container for it or something), which becomes non-visible when another spawnlist is selected
					self.panels[panel] = nil
				else
					//Remove panels from list and clean up their particles when they scroll offscreen (IsVisible doesn't catch these)
					//This fixes scrolling down really long spawnlists tanking FPS, and potentially fixes an out-of-memory crash?
					local _, a = panel:LocalToScreen(0,0)
					local _, b = panel:LocalToScreen(0, panel:GetTall())
					if a > ScrH() or b < 0 then //if top of panel is below bottom of screen, or bottom of panel is above top of screen
						self.panels[panel] = nil
					end
				end
			end

			//Store first-time info
			if !self.tooltip then
				local tooltip = name .. "\n(" .. PartCtrl_GetDataPCFNiceName(pcf) .. ")%PATH_DEV"
				
				self.icons = {}
				if !istable(PartCtrl_ProcessedPCFs[pcf]) or !istable(PartCtrl_ProcessedPCFs[pcf][name]) or !istable(PartCtrl_ProcessedPCFs[pcf][name].cpoints) then
					if PartCtrl_CulledFx[pcf] and PartCtrl_CulledFx[pcf][name] then
						//If effect was culled, add list of cull reasons to the tooltip, but use short non-technical reasons if possible
						local text = ""
						local docomma = false
						for _, v in pairs (PartCtrl_CulledFx[pcf][name]) do
							local v1 = language.GetPhrase(v)
							if v1 != v then
								local v2 = language.GetPhrase(v .. "_Short")
								if v2 != v .. "_Short" then
									v = v2
								else
									v = v1
								end
							end
							if docomma then
								text = text .. "; "
							end
							text = text .. v
							docomma = true
						end
						tooltip = tooltip .. "\n\n\nERROR: Invalid particle effect (" .. text .. ")"
					elseif !istable(PartCtrl_ProcessedPCFs[pcf]) then
						tooltip = tooltip .. "\n\n\nERROR: Invalid particle effect (No loaded .pcf file with this name%PATH_NICE)"
					else
						tooltip = tooltip .. "\n\n\nERROR: Invalid particle effect (No effect with this name in this .pcf)"
					end
					table.insert(self.icons, {["icon"] = icon_invalid})
				else
					if PartCtrl_DuplicateFx[pcf] and PartCtrl_DuplicateFx[pcf][name] then
						tooltip = tooltip .. "\n\nThis is a duplicate of \"" .. name .. "\" from \"" .. PartCtrl_GetDataPCFNiceName(PartCtrl_DuplicateFx[pcf][name]) .. "\"."
						table.insert(self.icons, {["icon"] = Material("icon16/page_paste.png")})
					end
			
					local types = {}
					for _, v in pairs (PartCtrl_ProcessedPCFs[pcf][name].cpoints) do
						types[v.mode] = types[v.mode] or 0
						types[v.mode] = types[v.mode] + 1
					end
			
					if types[PARTCTRL_CPOINT_MODE_POSITION] > 1 then
						table.insert(self.icons, {["icon"] = icon_position, ["num"] = types[PARTCTRL_CPOINT_MODE_POSITION]})
					end
			
					self.particle2_playerposfix = PartCtrl_ProcessedPCFs[pcf][name].spawnicon_playerposfix //particle operator "set control point to player" sets this to true
					self.particle3_forcedpositions = PartCtrl_ProcessedPCFs[pcf][name].spawnicon_forcedpositions //particle operator "set control point positions" creates this table
					self.PosCPoints, _, _, self.OffsetPosCPoints = PartCtrl_GetParticleDefaultPositions(pcf, name)
					self.doparticle2 = self.OffsetPosCPoints or self.particle2_playerposfix
					self.iPositionCombine = {}
					self.EditCPoints = {}
					self.EditCPointsText = {}
					self.ColorCPoints = {}
					for k, v in pairs (PartCtrl_ProcessedPCFs[pcf][name].cpoints) do
						if v.mode == PARTCTRL_CPOINT_MODE_VECTOR then
							if !v.vector or !v.vector[v.which] then MsgN(pcf, ": ", name, " - this effect is trying to get a vector value that it doesn't have, some dumb inheritance problem, go report this!") end
							if v.vector[v.which].colorpicker then
								self.ColorCPoints[k] = v.vector[v.which]
							else
								self.EditCPoints[k] = v.vector[v.which].default or vector_origin
								table.insert(self.EditCPointsText, v.vector[v.which].label)
							end
						elseif v.mode == PARTCTRL_CPOINT_MODE_AXIS then
							self.EditCPoints[k] = Vector(0,0,0)
							for i = 0, 2 do
								axistab = v.axis[v["which_" .. i]]
								if istable(axistab) then
									self.EditCPoints[k][i+1] = axistab.default or 0
									table.insert(self.EditCPointsText, axistab.label)
								end
							end
						elseif v.mode == PARTCTRL_CPOINT_MODE_POSITION_COMBINE then
							table.insert(self.iPositionCombine, k)
						end
					end
					self.iColorCPoints = {}
					local num = table.Count(self.ColorCPoints)
					if num > 0 then
						if num == 1 then
							num = nil
							tooltip = tooltip .. "\n\nThis effect is colorable."
						else
							tooltip = tooltip .. "\n\nThis effect has " .. num .. " editable colors. You can set them all at once\nwith the color tool, or set them separately in the edit window."
						end
						table.insert(self.icons, {["icon"] = icon_color, ["num"] = num})
						for k, v in SortedPairs (self.ColorCPoints) do
							table.insert(self.iColorCPoints, k)
							//do particle2 if the default is large enough to stretch the bounds
							if !self.doparticle2 and (math.abs(v.default.x) > 1 or math.abs(v.default.y) > 1 or math.abs(v.default.z) > 1) then
								self.doparticle2 = true
							end
						end
					end
					if table.Count(self.EditCPoints) > 0 then
						table.insert(self.icons, {["icon"] = icon_edit})
						tooltip = tooltip .. "\n\nThis effect has editable properties:"
						for _, v in pairs (self.EditCPointsText) do
							tooltip = tooltip .. "\n" .. v
						end
						for k, v in pairs (self.EditCPoints) do
							//do particle2 if the default is large enough to stretch the bounds
							if !self.doparticle2 and (math.abs(v.x) > 1 or math.abs(v.y) > 1 or math.abs(v.z) > 1) then
								self.doparticle2 = true
							end
						end
					end
					if PartCtrl_ProcessedPCFs[pcf][name].info then
						table.insert(self.icons, {["icon"] = icon_info})
						tooltip = tooltip .. "\n\nInfo:\n" .. table.concat(PartCtrl_ProcessedPCFs[pcf][name].info, "\n")
					end

					//developer warnings for culled fx
					if PartCtrl_CulledFx[pcf] and PartCtrl_CulledFx[pcf][name] then
						tooltip = tooltip .. "\n\n\nERROR: This effect is invalid, and won't be loaded outside of developer mode."
						for _, v in pairs (PartCtrl_CulledFx[pcf][name]) do
							tooltip = tooltip .. "\n\n" .. language.GetPhrase(v) //use verbose cull reasons for this one
						end
						//tooltip reaches max length if lots of errors are on one effect, but whatever
						table.insert(self.icons, {["icon"] = icon_invalid})
					end

					//warning for multiply defined fx
					if !utilfx then
						local listed_pcfs = {}
						local listed_dupes = {}
						local listed_invalids = {}
						local pcfs_added = 0
						local conflicting_self = false
						local conflicting_children = false
						local function CheckEffectAndChildren(name2, is_child)
							//if is_child then MsgN("checking child ", name2, " of ", name) else MsgN("checking ", name2) end
							local this_listed_pcfs = {}
							local this_listed_dupes = {}
							local this_listed_invalids = {}
							local this_pcfs_added = 0
							for _, v in pairs (PartCtrl_PCFsByParticleName[name2]) do
								//if PartCtrl_PCFsWithConflicts[v] then //if every single conflicting effect in a pcf is culled or a duplicate, then there's no chance of the player reloading it, so don't bother listing it
									if PartCtrl_ProcessedPCFs[v][name2] and PartCtrl_DuplicateFx[v][name2] then
										if listed_dupes[v] == nil then
											this_listed_dupes[v] = PartCtrl_DuplicateFx[v][name2]
										end
									else
										this_listed_dupes[v] = false
										this_pcfs_added = this_pcfs_added + 1
									end
									if PartCtrl_CulledFx[v] and PartCtrl_CulledFx[v][name2] then
										if listed_invalids[v] == nil then
											this_listed_invalids[v] = true
										end
									else
										this_listed_invalids[v] = false
									end
									this_listed_pcfs[v] = true
								//end
							end
							if this_pcfs_added > 1 then
								//Don't add conflict warnings for dupes unless there's at least 2 non-dupe fx with that name 
								//(no point in conflict warning if every version of the effect is the same)
								table.Merge(listed_pcfs, this_listed_pcfs)
								table.Merge(listed_dupes, this_listed_dupes)
								table.Merge(listed_invalids, this_listed_invalids)
								pcfs_added = pcfs_added + this_pcfs_added
								if !is_child then
									conflicting_self = true
								else
									conflicting_children = true
								end
							end
							for k, childtab in pairs (PartCtrl_ProcessedPCFs[pcf][name2].children) do
								//Also check all child fx for overrides
								CheckEffectAndChildren(childtab.child, true)
							end
						end
						CheckEffectAndChildren(name)
						if pcfs_added > 1 then
							local text = ""
							for k, _ in SortedPairs (listed_pcfs) do
								text = text .. "\n" .. PartCtrl_GetDataPCFNiceName(k)
								if listed_dupes[k] then 
									text = text .. " (duplicate of " .. PartCtrl_GetDataPCFNiceName(listed_dupes[k]) .. ")"
								end
								if listed_invalids[k] then
									text = text .. " (invalid)"
								end
							end
							//slightly different messages depending on which fx have conflicts
							if conflicting_self and conflicting_children then
								tooltip = tooltip .. "\n\n\nWarning: This particle effect and/or its children are defined in multiple files:" .. text .. "\n\nCurrently, the ones from %OVERRIDE_PCF are loaded.\nOnly one effect with the same name can be loaded at a time.\nIf you load effects from any of these files, even in spawnicons, then\nit will use the ones from the most recently loaded file."
							elseif conflicting_self then
								tooltip = tooltip .. "\n\n\nWarning: This particle effect name is defined in multiple files:" .. text .. "\n\nCurrently, the one from %OVERRIDE_PCF is loaded.\nOnly one effect with the same name can be loaded at a time.\nIf you load effects from any of these files, even in spawnicons, then\nit will use the \"" .. name .. "\" from the most recently loaded file."
							elseif conflicting_children then
								tooltip = tooltip .. "\n\n\nWarning: This particle effect's children are defined in multiple files:" .. text .. "\n\nCurrently, the ones from %OVERRIDE_PCF are loaded.\nOnly one effect with the same name can be loaded at a time.\nIf you load effects from any of these files, even in spawnicons, then\nit will use the ones from the most recently loaded file."
							end
							table.insert(self.icons, {["icon"] = icon_multiplydefined, ["icon2"] = icon_multiplydefined_2})
							self.MultiplyDefined = true
						end
					end
			
					//test lots of icons
					--[[for i = 1, 20 do
						table.insert(self.icons, {["icon"] = icon_test, ["num"] = i})
					end]]
				end
				self.tooltip = tooltip
			end

			//Manage the particle
			if !utilfx and !PartCtrl_AddParticles_CrashCheck_ThrottledPCFs[pcf] then //if this effect is being throttled, then we want the crash prevention func to handle removing it, not remove it here
				if !self.reset and table.Count(self.panels) > 0
				and istable(PartCtrl_ProcessedPCFs[pcf]) and istable(PartCtrl_ProcessedPCFs[pcf][name]) //run remove particle check if these fail, because it's possible for a pcf or effect to become invalid after refreshing a pcf file
				and !PartCtrl_ProcessedPCFs[pcf][name].prevent_name_based_lookup then //don't bother trying to create fx with this attribute, even in developer mode, it'll just fail and spam the console with errors
					if !(self.particle and self.particle.IsValid and self.particle:IsValid()) then

						//Create the particle

						if !self.precached then
							PrecacheParticleSystem(name)
							self.precached = true
						end

						self.particle = CreateParticleSystemNoEntity(name, vector_origin)
						if self.particle and self.particle:IsValid() then
							if self.doparticle2 then
								//For effects using a color or edit cpoint, their renderbounds will be stretched out by the cpoint if they're too far away,
								//so create a second particlesystem without those cpoints, so we can use its renderbounds instead
								if self.particle2_playerposfix then
									//In addition, we also account for certain fx with "set control point to player", which have a cpoint that always 
									//sets its position to the player. We can't stop the cpoint from moving there, so instead we move all the other 
									//cpoints to be relative to the player as well. This isn't perfect, because the position updates are sort of choppy, 
									//so a moving player will still stretch out the bounds a bit in the direction they're currently moving, but it's 
									//better than the alternative of the renderbounds being stretched all the way from the origin to the player pos.
									self.particle2 = CreateParticleSystem(LocalPlayer(), name, PATTACH_ABSORIGIN_FOLLOW)
								else
									self.particle2 = CreateParticleSystemNoEntity(name, vector_origin)
								end
								
								if self.particle2 and (!self.particle2.IsValid or !self.particle2:IsValid()) then
									self.particle2 = nil
								end
								self.particle2:SetShouldDraw(false)
							end
							if self.particle3_forcedpositions then
								//For effects with with cpoints using "set control point positions" set to "Set positions in world space", create another
								//particlesystem in each direction they stretch the renderbounds in, so we can use those to determine how much the bounds 
								//are stretched by, and resize the final bounds accordingly
								self.particle3 = {}
								for i = 1, 6 do
									if math.abs(self.particle3_forcedpositions[i]) > 0 then
										self.particle3[i] = CreateParticleSystemNoEntity(name, vector_origin)
										if self.particle3[i] and (!self.particle3[i].IsValid or !self.particle3[i]:IsValid()) then
											self.particle3[i] = nil
										end
										self.particle3[i]:SetShouldDraw(false)
									end
								end
							end
							self.particle:SetShouldDraw(false)
							self.mins = nil
							self.maxs = nil
							//self.view = nil
							DoPosCPoints(self, self.particle)
							if self.particle2 then
								DoPosCPoints(self, self.particle2)
							end
							if self.particle3 then
								for k, v in pairs (self.particle3) do
									DoPosCPoints(self, v, k)
								end
							end
							//Handle axis cpoints and vector cpoints other than colors by just setting them to their default value
							for k, v in pairs (self.EditCPoints) do
								self.particle:SetControlPoint(k, v)
							end
							DoColorCPoints(self) //accomodate CERTAIN EFFECTS that don't change color after spawning, looking at you wrangler :shakefist:
							PartCtrl_AddParticles_CrashCheck[pcf] = PartCtrl_AddParticles_CrashCheck[pcf] or {}
							PartCtrl_AddParticles_CrashCheck[pcf][self.particle] = true
							if self.particle2 then
								PartCtrl_AddParticles_CrashCheck[pcf][self.particle2] = true
							end
							if self.particle3 then
								for _, v in pairs (self.particle3) do
									PartCtrl_AddParticles_CrashCheck[pcf][v] = true
								end
							end
						end

					end

					if self.particle and self.particle.IsValid and self.particle:IsValid() then

						//Update the particle and render bounds
						//Based off PositionSpawnIcon (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/util/client.lua#L208)
						//as called by IconEditor:BestGuessLayout (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/gui/iconeditor.lua#L362)
						
						local mn, mx
						if self.particle2 and self.particle2:IsValid() then
							if self.particle2_playerposfix then
								self.particle2:Render() //always render particle2 or it'll fall asleep and stop updating cpoint positions properly
							end
							mn, mx = self.particle2:GetRenderBounds()
							//If self.particle2 fails and generates an effect with bad bounds (i.e. with axis scalars
							//at 0,0,0, no particles spawn at all), then bail and use self.particle's bounds instead.
							if mn == mx then mn, mx = self.particle:GetRenderBounds() end
						else
							mn, mx = self.particle:GetRenderBounds()
						end

						if self.particle3 then
							local function DoParticle3(i, use_mx, axis)
								local p = self.particle3[i]
								if p and p:IsValid() then
									local mn2, mx2 = p:GetRenderBounds()
									if !use_mx then
										mn[axis] = mn2[axis] - self.particle3_forcedpositions[i]
									else
										mx[axis] = mx2[axis] - self.particle3_forcedpositions[i]
									end
								end
							end
							DoParticle3(1, false, "x")
							DoParticle3(2, false, "y")
							DoParticle3(3, false, "z")
							DoParticle3(4, true, "x")
							DoParticle3(5, true, "y")
							DoParticle3(6, true, "z")
						end

						//Don't let the bounds be any taller than they are wide, so that rising smoke, falling debris, etc. don't move the camera totally out of position
						local width = math.max((math.abs(mn.x) + math.abs(mx.x)), (math.abs(mn.y) + math.abs(mx.y)))
						local height = math.max(-mn.z + mx.z, 1) //min 1 here to prevent divide-by-zero errors
						if width == 0 then width = height end //try not to completely screw up on fx with no width
						height = width/height
						mn.z = math.max(mn.z, mn.z * height)
						mx.z = math.min(mx.z, mx.z * height)

						self.mins = self.mins or mn
						self.maxs = self.maxs or mx
						if math.abs(self.mins.x - mn.x) > 1000 or math.abs(self.mins.y - mn.y) > 1000 or math.abs(self.mins.z - mn.z) > 1000
						or math.abs(self.maxs.x - mx.x) > 1000 or math.abs(self.maxs.y - mx.y) > 1000 or math.abs(self.maxs.z - mx.z) > 1000 then
							//If the render bounds shrink drastically in a single frame, use those new bounds instead. This fixes cases where some fx start off
							//at some huge overscaled value, then shrink down to something reasonable shortly after (swarm's particles/fire_fx.pcf ent_on_fire, 
							//tf2's particles/item_fx.pcf unusual_tentmonster_purple_parent)
							self.mins = nil
							self.maxs = nil
						else
							//Expand our bounds using the new bounds. Because the particle's render bounds are constantly fluctuating as more particles are added, 
							//destroyed, and moved, this lets us keep expanding our bounds bit by bit until we can settle down at the maximum potential bounds.
							mn = Vector(math.min(mn.x, self.mins.x), math.min(mn.y, self.mins.y), math.min(mn.z, self.mins.z))
							mx = Vector(math.max(mx.x, self.maxs.x), math.max(mx.y, self.maxs.y), math.max(mx.z, self.maxs.z))
						end
						//Only recreate all the view info if the bounds have changed
						if mn != self.mins or mx != self.maxs or !self.view then
							self.mins = mn
							self.maxs = mx

							local middle = (mn + mx) * 0.5
							//Works better with ortho than RenderSpawnIcon's size code; uses the distance between the edges of the box on the left and right sides of the panel
							local mn2 = Vector(mn.x, mx.y, mn.z)
							local mx2 = Vector(mx.x, mn.y, mx.z)
							local size = mn2:Distance2D(mx2) * 0.9 //zoom in just a bit; the majority of effects still have a good distance between the visible edge of the effect and the edge of the bbox, so this helps make them more visible; a small number of effects that don't have this issue get cut off slightly, but it's worth the tradeoff
							if size == 0 then size = math.Distance(mn.z, 0, mx.z, 0) end //try not to completely screw up on fx with no width

							//Loosely based off RenderSpawnIcon_Prop (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/util/client.lua#L53)
							local ViewPos = vector_origin + ViewAngle:Forward() * size * -15
							self.view = {
								pos = ViewPos + middle,
								ortho = size/2
							}
						end

						DoColorCPoints(self)

					end
				else

					//Remove the particle

					if self.particle then
						if self.particle.IsValid and self.particle:IsValid() then
							self.particle:StopEmissionAndDestroyImmediately()
						else
							self.particle = nil
						end
					end
					if self.particle2 then
						if self.particle2.IsValid and self.particle2:IsValid() then
							self.particle2:StopEmissionAndDestroyImmediately()
						else
							self.particle2 = nil
						end
					end
					if self.particle3 then
						for k, v in pairs (self.particle3) do
							if v.IsValid and v:IsValid() then
								v:StopEmissionAndDestroyImmediately()
							else
								self.particle3[k]  = nil
							end
						end
						if table.IsEmpty(self.particle3) then
							self.particle3 = nil
						end
					end

				end
			end

			if self.reset then
				//Remove all info for this particle, recreate it from scratch next frame
				//(this is set by reloading a pcf with the partctrl_reloadpcf concommand)
				PartCtrl_IconFx[pcf][name] = nil
			end

		end
	end

end)

function PANEL:DoClick()

	local pcf = PartCtrl_GetGamePCF(self.pcf, self.path)

	//If the icon's effect is currently being overridden by another pcf's effect of the same name, reload the pcf on click instead
	if self:IsCurrentlyOverridden(pcf, self.name) then
		surface.PlaySound("common/wpn_select.wav") //TODO: is this a good sound? needs to be different enough from the spawn sound so players can tell that clicking didn't spawn an effect yet.
		PartCtrl_AddParticles(pcf, self.name) //crash prevention
		//Update the tooltip, so it doesn't still say the effect is being overridden by another pcf
		timer.Simple(0, function()
			if IsValid(self) then ChangeTooltip(self) end
		end)
	else
		RunConsoleCommand("partctrl_spawnparticle", self.name, self.pcf, self.path)
		surface.PlaySound("ui/buttonclickrelease.wav")
	end

end

function PANEL:OpenMenu()

	local menu = DermaMenu()
	local pcf = PartCtrl_GetGamePCF(self.pcf, self.path) //use this unless we're doing something that handles the path arg on its own, like spawning an effect

	menu:AddOption("Copy effect name to clipboard", function() SetClipboardText(self.name) end):SetIcon("icon16/page_copy.png")
	if pcf != "UtilFx" then 
		menu:AddOption("Copy .pcf file path to clipboard", function() 
			SetClipboardText(self.pcf)
		end):SetIcon("icon16/page_copy.png")

		if self.pcf != pcf then
			menu:AddOption("Copy internal .pcf file path to clipboard", function() 
				SetClipboardText(pcf)
			end):SetIcon("icon16/page_copy.png")
		end
	end 

	menu:AddOption("#spawnmenu.menu.spawn_with_toolgun", function()
		RunConsoleCommand("gmod_tool", "partctrl_creator")
		RunConsoleCommand("partctrl_creator_pcf", self.pcf)
		RunConsoleCommand("partctrl_creator_name", self.name)
		RunConsoleCommand("partctrl_creator_path", self.path or "")
	end):SetIcon("icon16/brick_add.png")

	//List all parents and children of this effect recursively; this means we don't have to clutter up the spawnlists with children
	if istable(PartCtrl_ProcessedPCFs[pcf]) and istable(PartCtrl_ProcessedPCFs[pcf][self.name]) then
		local function ListChildFx(submenu, submenuoption, name2, tabname)
			local listed_fx = {} //don't list the same effect more than once - sometimes a parent can have multiple of the same child
			for _, child in pairs (PartCtrl_ProcessedPCFs[pcf][name2][tabname]) do
				//ptab.children is a table of tables containing both child names and other info about them;
				//ptab.parents is just a table of strings
				if istable(child) then
					child = child.child
				end
				if PartCtrl_ProcessedPCFs[pcf][child] and !listed_fx[child] then
					listed_fx[child] = true
					local OnClick = function()
						RunConsoleCommand("partctrl_spawnparticle", child, self.pcf, self.path)
						surface.PlaySound("ui/buttonclickrelease.wav")
					end
					local submenu2
					local option2
					if PartCtrl_ProcessedPCFs[pcf][child][tabname] and table.Count(PartCtrl_ProcessedPCFs[pcf][child][tabname]) > 0 then
						submenu2, option2 = submenu:AddSubMenu(child, OnClick)
						ListChildFx(submenu2, option2, child, tabname)
					else
						option2 = submenu:AddOption(child, OnClick)
					end
					if PartCtrl_CulledFx[pcf] and PartCtrl_CulledFx[pcf][child] then //in developer mode, add warnings to culled fx
						option2:SetMaterial(icon_invalid)
						//duplicate of text string from this panel's setup func, whatever
						local tooltip = "ERROR: This effect is invalid, and won't be loaded outside of developer mode."
						for _, v in pairs (PartCtrl_CulledFx[pcf][child]) do
							tooltip = tooltip .. "\n\n" .. language.GetPhrase(v)
						end
						option2:SetTooltip(tooltip)
					end
					//When the player hovers over a child effect, override the spawnicon to display that effect instead
					local old_OnCursorEntered = option2.OnCursorEntered
					function option2.OnCursorEntered()
						old_OnCursorEntered(option2)
						if IsValid(self) then
							self.childname = child
						end
					end
					local old_OnCursorExited = option2.OnCursorExited
					function option2.OnCursorExited()
						old_OnCursorExited(option2)
						if IsValid(self) then
							self.childname = nil
							if PartCtrl_IconFx[pcf] and PartCtrl_IconFx[pcf][child] and PartCtrl_IconFx[pcf][child].panels then
								PartCtrl_IconFx[pcf][child].panels[self] = nil
							end
						end
					end
					//local old_OnRemove = option2.OnRemove
					function option2.OnRemove()
						//old_OnRemove(option2)
						if IsValid(self) then
							self.childname = nil
							if PartCtrl_IconFx[pcf] and PartCtrl_IconFx[pcf][child] and PartCtrl_IconFx[pcf][child].panels then
								PartCtrl_IconFx[pcf][child].panels[self] = nil
							end
						end
					end
				end
			end
			submenuoption:SetText(submenuoption:GetText() .. " (" .. table.Count(listed_fx) .. ")") //count the number of fx not including dupes
		end
		local ptab = PartCtrl_ProcessedPCFs[pcf][self.name]
		if ptab.parents and table.Count(ptab.parents) > 0 then
			local base_submenu, base_submenuoption = menu:AddSubMenu("Spawn parent effect")
			base_submenuoption:SetImage("icon16/shape_group.png")
			ListChildFx(base_submenu, base_submenuoption, self.name, "parents")
		end
		if ptab.children and table.Count(ptab.children) > 0 then
			local base_submenu, base_submenuoption = menu:AddSubMenu("Spawn child effect")
			base_submenuoption:SetImage("icon16/shape_ungroup.png")
			ListChildFx(base_submenu, base_submenuoption, self.name, "children")
		end
	end

	//not implemented on this icon type, but included to match the others (model icon also includes this despite not having OpenMenuExtra, i think)
	if isfunction(self.OpenMenuExtra) then
		self:OpenMenuExtra(menu)
	end

	hook.Run("SpawnmenuIconMenuOpen", menu, self, "partctrl")
	
	//Do not allow removal from read only panels
	if !IsValid(self:GetParent()) or !self:GetParent().GetReadOnly or !self:GetParent():GetReadOnly() then
		menu:AddSpacer()

		menu:AddOption("#spawnmenu.menu.delete", function()
			self:Remove()
			hook.Run("SpawnlistContentChanged")
		end):SetIcon("icon16/bin_closed.png")
	end

	//developer controls to reload a .pcf file manually, or dump pcf data into console
	if GetConVarNumber("developer") >= 1 then
		menu:AddSpacer()

		menu:AddOption("Reload " .. pcf, function()
			RunConsoleCommand("partctrl_reloadpcf", pcf)
		end)

		if pcf != "UtilFx" then
			menu:AddOption("Print raw PCF data for this effect", function()
				MsgN("PartCtrl_ReadPCF(\"" .. pcf .. "\")[\"" .. self.name .. "\"]:")
				PrintTable(PartCtrl_ReadPCF(pcf)[self.name])
				MsgN()
			end)
		end

		menu:AddOption("Print processed PCF data for this effect", function()
			MsgN("PartCtrl_ProcessedPCFs[\"" .. pcf .. "\"][\"" .. self.name .. "\"]:")
			PrintTable(PartCtrl_ProcessedPCFs[pcf][self.name])
		end)
	end

	menu:Open()

end

function PANEL:Copy()

	//This function is called when dragging an icon from a search into a spawnlist - the baseclass' version of this always creates a normal ContentIcon panel, and also causes errors
	//because it tries to copy a nonexistent "material" value; don't overthink this, just have our own function, this works fine

	local copy = vgui.Create("ContentIcon_PartCtrl", self:GetParent())
	copy:Setup(self.pcf, self.name, self.path)

	return copy

end

//variant of baseclass' ToTable, writes our custom values instead (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/spawnmenu/creationmenu/content/contenticon.lua#L221)
function PANEL:ToTable(bigtable)

	local tab = {}

	tab.type = self:GetContentType()
	tab.name = self.name
	tab.pcf = self.pcf
	tab.path = self.path

	table.insert(bigtable, tab)

end

vgui.Register("ContentIcon_PartCtrl", PANEL, "ContentIcon")

spawnmenu.AddContentType("partctrl", function(container, obj)

	if !obj.pcf or !obj.name then return end //obj.path is optional

	local icon = vgui.Create("ContentIcon_PartCtrl", container)
	icon:Setup(obj.pcf, obj.name, obj.path)

	container:Add(icon)

	return icon

end)