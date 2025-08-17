local PANEL = {}

local icon_invalid = Material("icon16/cancel.png")
//local icon_multiplydefined = Material("icon16/exclamation.png")
local icon_multiplydefined = Material("icon16/page_copy.png")
local icon_multiplydefined_2 = Material("icon16/bullet_error.png")
local icon_position = Material("icon16/arrow_right.png")//Material("sprites/grip") //Material("icon16/arrow_inout.png")
//local icon_position_none = Material("icon16/bullet_delete.png")
local icon_edit = Material("icon16/pencil.png")
local icon_color = Material("icon16/color_wheel.png")
local icon_test = Material("icon16/color_wheel.png")
local icon_deverror = Material("icon16/error.png")
local icon_utilfx = Material("icon16/cog.png")
local icon_info = Material("icon16/information.png")

if system.IsLinux() then
	surface.CreateFont("PartCtrl_DermaDefaultSmall", {
		font		= "DejaVu Sans",
		size		= 13, //don't have this font, so just have to trust that this is right (1pt larger than the tahoma, like in https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/derma/init.lua#L6C1-L45C4)
		weight		= 500,
		extended	= true
	})
else
	surface.CreateFont("PartCtrl_DermaDefaultSmall", {
		font		= "Tahoma",
		size		= 12,
		weight		= 500,
		extended	= true
	})
end

function PANEL:Setup(pcf, name)

	self.pcf = pcf
	self.name = name
	self:SetName(name)
	self:SetSpawnName(pcf)
	self:SetContentType("partctrl")

	if pcf == "UtilFx" then
		self:SetMaterial("icon16/cog.png") //icon_utilfx) //why doesn't this one take a Material()? whatever
	end

	//PartCtrl_AddParticles(pcf, name) //crash prevention
	self.DoneSetup = true

end

local ViewAngle = Angle(25, 220, 0)
local icon_loading = Material("vgui/loading-rotate.vmt") //TODO: replace this with a custom texture eventually, something bulkier that looks better when it's drawn small like this
function PANEL:Paint(w, h)

	if !self.DoneSetup then
		baseclass.Get("ContentIcon").Paint(self, w, h)
		return
	end

	//Add this effect to PartCtrl_IconFx - even if we're not showing a particle in this panel, 
	//we still want it to populate other stuff like icons and tooltips
	PartCtrl_IconFx[self.pcf] = PartCtrl_IconFx[self.pcf] or {}
	PartCtrl_IconFx[self.pcf][self.name] = PartCtrl_IconFx[self.pcf][self.name] or {}
	PartCtrl_IconFx[self.pcf][self.name].panels = PartCtrl_IconFx[self.pcf][self.name].panels or {}
	
	local itab = PartCtrl_IconFx[self.pcf][self.name]
	self:SetTooltip(itab.tooltip)

	if self.invalid != itab.invalid then
		if itab.invalid then
			self:SetMaterial("icon16/cancel.png") //icon_invalid) //why doesn't this one take a Material()? whatever
		else
			self:SetMaterial("")
		end
		self.invalid = itab.invalid
	end

	
	local bd = self.Border + 4
	local showparticle = true

	//If the icon's effect is currently being overridden by another pcf's effect of the same name, show a notification instead
	if self:IsCurrentlyOverridden() then
		local mdef_width = math.min(w,h) * 0.5
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
				--[[render.DrawWireframeBox(vector_origin, angle_zero, itab.mins, itab.maxs, color_white, true)
				if itab.particle2 then
					local mn_, mx_ = itab.particle2:GetRenderBounds()
					render.DrawWireframeBox(vector_origin, angle_zero, mn_, mx_, Color(255,0,0), true)
				end]]
				//render.DrawWireframeBox(Vector(mn.x, mx.y, mn.z), angle_zero, Vector(-1,-1,-1), Vector(1,1,1), Color(255,0,0), false)
				//render.DrawWireframeBox(Vector(mx.x, mn.y, mx.z), angle_zero, Vector(-1,-1,-1), Vector(1,1,1), Color(0,0,255), false)
				render.SetScissorRect(0, 0, 0, 0, false) //also from DModelPanel:DrawModel
				cam.End3D()
				cam.EndOrthoView()
			end
		else
			//If particle is being throttled by crash prevention, draw loading icon
			if PartCtrl_AddParticles_CrashCheck_ThrottledPCFs[self.pcf] and (!itab.particle or !(itab.particle.IsValid and itab.particle:IsValid())) then
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
				draw.SimpleTextOutlined(v.num, "PartCtrl_DermaDefaultSmall", x+8, y+8, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,255))
			end
			x = x + 16 + 2 //move the position of the next icon to the right by the width of this icon, plus a bit more
			if x + 16 > (w - self.Border - 8) then //if this would cause the next icon to stick out past the right edge of the panel, then start a new row instead
				y = y + 16 + 2
				x = self.Border + 8
			end
		end
	end

end

function PANEL:IsCurrentlyOverridden()

	if PartCtrl_IconFx[self.pcf][self.name].MultiplyDefined
	and !(PartCtrl_PCFsByParticleName_CurrentlyLoaded[self.name] == self.pcf)
	and !(PartCtrl_DuplicateFx[self.pcf][self.name] and PartCtrl_PCFsByParticleName_CurrentlyLoaded[self.name] == PartCtrl_DuplicateFx[self.pcf][self.name]) then
		return true
	end

end

PartCtrl_IconFx = {}

local function DoPosCPoints(self, p)

	//Handle position cpoints by placing them all in a fixed-length line, with the cpoints distributed evenly from one end of the line to another

	//In addition to not setting vector/axis cpoints that would stretch out the renderbounds, we also account for certain fx with "set control point to player", which have a cpoint that always 
	//sets its position to the player. We can't stop the cpoint from moving there, so instead we move all the other cpoints to be relative to the player as well. This isn't perfect, because the
	//position updates are sort of choppy, so a moving player will still stretch out the bounds a bit in the direction they're currently moving, but it's better than the alternative of the 
	//renderbounds being stretched all the way from the origin to the player pos.
	local origin = nil
	if p == self.particle2 and self.particle2_playerposfix then
		origin = LocalPlayer():GetPos()
	else
		origin = vector_origin
	end

	done_position_combine = false

	for i, k in ipairs (self.iGrips) do
		local pos = 0
		if i > 1 then
			pos = ((i-1)/(#self.iGrips-1))*self.length
		end
		pos = Vector(pos,0,0)
		//MsgN(i, " = ", pos)

		if p == self.particle2 and self.particle2_playerposfix then
			p:AddControlPoint(k, LocalPlayer(), PATTACH_ABSORIGIN_FOLLOW, nil, pos)
		else
			p:SetControlPoint(k, pos + origin)
		end
		p:SetControlPointOrientation(k, angle_zero)
		if !done_position_combine then
			for _, k2 in pairs (self.iPositionCombine) do
				if p == self.particle2 and self.particle2_playerposfix then
					p:AddControlPoint(k2, LocalPlayer(), PATTACH_ABSORIGIN_FOLLOW, nil, pos)
				else
					p:SetControlPoint(k2, pos + origin)
				end
				p:SetControlPointOrientation(k2, angle_zero)
			end
			done_position_combine = true
		end
	end

	//test: cpoints that are overridden by the effect to a fixed position in worldspace are stuck there and stretch the bounds, see if we can move them back.
	//(example: many fx in tf2's particles/rps.pcf) unfortunately this doesn't work at all on those cpoints, they're stuck there.
	//for i = 0, 10 do
	//	p:SetControlPoint(i, origin)
	//end
	--[[p:AddControlPoint(9, game.GetWorld(), PATTACH_ABSORIGIN)
	p:SetControlPoint(9, origin)
	p:AddControlPoint(4, game.GetWorld(), PATTACH_ABSORIGIN)
	p:SetControlPoint(4, origin)
	p:AddControlPoint(2, game.GetWorld(), PATTACH_ABSORIGIN)
	p:SetControlPoint(2, origin)
	p:AddControlPoint(3, game.GetWorld(), PATTACH_ABSORIGIN)
	p:SetControlPoint(3, origin)]]

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
		for name, effecttab in pairs (pcftab) do

			local self = PartCtrl_IconFx[pcf][name] //this works??

			//First, go through the list of panels using this effect, and remove any that are invalid or not visible
			for panel, _ in pairs (effecttab.panels) do
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
			if !effecttab.tooltip then
				local tooltip = name
				self.icons = {}
				if !istable(PartCtrl_ProcessedPCFs[pcf]) or !istable(PartCtrl_ProcessedPCFs[pcf][name]) or !istable(PartCtrl_ProcessedPCFs[pcf][name].cpoints) then
					tooltip = tooltip .. "\n(" .. pcf .. ")\n\nInvalid particle effect (from game/addon that isn't mounted?)"
					self.invalid = true
				else
					if !utilfx then
						tooltip = tooltip .. "\n(" .. pcf .. ")"
			
						if #PartCtrl_PCFsByParticleName[name] > 1 then
							local pcfs_added = 0
							local text = "\n\nWarning: This particle effect name is defined in multiple files:"
							for _, v in pairs (PartCtrl_PCFsByParticleName[name]) do
								//if PartCtrl_PCFsWithConflicts[v] then //if every single conflicting effect in a pcf is culled or a duplicate, then there's no chance of the player reloading it, so don't bother listing it
									text = text .. "\n" .. v
									if PartCtrl_ProcessedPCFs[v][name] and PartCtrl_DuplicateFx[v][name] then
										text = text .. " (duplicate of " .. PartCtrl_DuplicateFx[v][name] .. ")"
										//Don't add conflict warnings for dupes unless there's at least 2 non-dupe fx with that name 
										//(no point in conflict warning if every version of the effect is the same)
									else
										pcfs_added = pcfs_added + 1
									end
									if !PartCtrl_ProcessedPCFs[v] or !PartCtrl_ProcessedPCFs[v][name] or PartCtrl_ProcessedPCFs[v][name].shouldcull then
										text = text .. " (culled)"
									end
								//end
							end
							text = text .. "\n\nOnly one effect called \"" .. name .. "\" can be loaded at a time.\nIf you reload effects from any of these files, even in spawnicons,\nit will use the \"" .. name .. "\" from the most recently loaded file." 
							if pcfs_added > 1 then
								tooltip = tooltip .. text
								table.insert(self.icons, {["icon"] = icon_multiplydefined, ["icon2"] = icon_multiplydefined_2})
								self.MultiplyDefined = true
							end
						end
			
						//developer warnings for culled fx
						if PartCtrl_ProcessedPCFs[pcf][name].shouldcull then
							tooltip = tooltip .. "\n\nERROR: This effect will not be loaded outside of developer mode.\n\n" .. tostring(PartCtrl_ProcessedPCFs[pcf][name].shouldcull) //just in case some doofus makes it a bool
							//tooltip reaches max length if all 3 errors are on one effect, but whatever
							table.insert(self.icons, {["icon"] = icon_deverror})
						end
					else
						tooltip = tooltip .. "\n(Scripted Effect)"
					end

					if PartCtrl_DuplicateFx[pcf] and PartCtrl_DuplicateFx[pcf][name] then
						tooltip = tooltip .. "\n\nThis effect is a duplicate of " .. PartCtrl_DuplicateFx[pcf][name] .. "'s " .. name .. "."
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
			
					self.particle2_playerposfix = PartCtrl_ProcessedPCFs[pcf][name].spawnicon_playerposfix //particle attrib "set control point to player" sets this to true
					self.doparticle2 = self.particle2_playerposfix
					self.length = PartCtrl_ProcessedPCFs[pcf][name].min_length or 100
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
						end
						self.doparticle2 = true
					end
					if table.Count(self.EditCPoints) > 0 then
						table.insert(self.icons, {["icon"] = icon_edit})
						tooltip = tooltip .. "\n\nThis effect has editable properties:"
						for _, v in pairs (self.EditCPointsText) do
							tooltip = tooltip .. "\n" .. v
						end
						self.doparticle2 = true
					end
					if PartCtrl_ProcessedPCFs[pcf][name].info then
						table.insert(self.icons, {["icon"] = icon_info})
						tooltip = tooltip .. "\n\nInfo:\n" .. PartCtrl_ProcessedPCFs[pcf][name].info
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
				if !effecttab.reset and table.Count(effecttab.panels) > 0
				and istable(PartCtrl_ProcessedPCFs[pcf]) and istable(PartCtrl_ProcessedPCFs[pcf][name]) //run remove particle check if these fail, because it's possible for a pcf or effect to become invalid after refreshing a pcf file
				and !PartCtrl_ProcessedPCFs[pcf][name].prevent_name_based_lookup then //don't bother trying to create fx with this attribute, even in developer mode, it'll just fail and spam the console with errors
					if !(effecttab.particle and effecttab.particle.IsValid and effecttab.particle:IsValid()) then

						//Create the particle

						if !self.precached then
							PrecacheParticleSystem(name)
							self.precached = true
						end

						self.particle = CreateParticleSystemNoEntity(name, vector_origin)
						if self.particle and self.particle:IsValid() then
							//For effects using a color or edit cpoint, their renderbounds will be stretched out by the cpoint if they're too far away,
							//so create a second particlesystem without those cpoints, so we can use its renderbounds instead
							if self.doparticle2 then
								if self.particle2_playerposfix then
									self.particle2 = CreateParticleSystem(LocalPlayer(), name, PATTACH_ABSORIGIN_FOLLOW)
								else
									self.particle2 = CreateParticleSystemNoEntity(name, vector_origin)
								end
								
								if self.particle2 and (!self.particle2.IsValid or !self.particle2:IsValid()) then
									self.particle2 = nil
								end
								self.particle2:SetShouldDraw(false)
							end
							self.particle:SetShouldDraw(false)
							self.mins = nil
							self.maxs = nil
							self.iGrips = {}
							self.iPositionCombine = {}
							for k, v in pairs (PartCtrl_ProcessedPCFs[pcf][name].cpoints) do
								if v.mode == PARTCTRL_CPOINT_MODE_POSITION then
									table.insert(self.iGrips, k)
								elseif v.mode == PARTCTRL_CPOINT_MODE_POSITION_COMBINE then
									table.insert(self.iPositionCombine, k)
								end
							end
							DoPosCPoints(self, self.particle)
							if self.particle2 then
								DoPosCPoints(self, self.particle2)
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
						end

					else

						//Update the particle

						//Based off PositionSpawnIcon (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/util/client.lua#L208)
						//as called by IconEditor:BestGuessLayout (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/gui/iconeditor.lua#L362)
						self.mins = self.mins or vector_origin
						self.maxs = self.maxs or vector_origin
						local mn, mx
						if self.particle2 and self.particle2:IsValid() then
							if self.particle2_playerposfix then
								self.particle2:Render() //always render particle2 or it'll fall asleep and stop updating cpoint positions properly
							end
							mn, mx = self.particle2:GetRenderBounds()
						else
							mn, mx = self.particle:GetRenderBounds()
						end
						//MsgN(mn, ",     ", mx)
						//Clamp the up/down axis so that rising smoke, falling debris, etc. don't move the camera totally out of position
						local width = math.max((math.abs(mn.x) + math.abs(mx.x)), (math.abs(mn.y) + math.abs(mx.y)), 100) / 2 //minimum 50 so that certain really small effects (tf2 medic bubbles) don't end up with no height at all
						mn.z = math.max(mn.z, -width)
						mx.z = math.min(mx.z, width)

						//Expand our bounds using the new bounds, and only recreate all the view info if the bounds have changed
						//Because the particle's render bounds are constantly fluctuating as more particles are added, destroyed, and moved, this behavior lets us keep expanding our bounds
						//bit by bit until we can settle down at the maximum potential bounds.
						mn = Vector(math.min(mn.x, self.mins.x), math.min(mn.y, self.mins.y), math.min(mn.z, self.mins.z))
						mx = Vector(math.max(mx.x, self.maxs.x), math.max(mx.y, self.maxs.y), math.max(mx.z, self.maxs.z))
						if mn != self.mins or mx != self.maxs then
							self.mins = mn
							self.maxs = mx

							local middle = (mn + mx) * 0.5
							//Works better with ortho than RenderSpawnIcon's size code; uses the distance between the edges of the box on the left and right sides of the panel
							local mn2 = Vector(mn.x, mx.y, mn.z)
							local mx2 = Vector(mx.x, mn.y, mx.z)
							local size = mn2:Distance2D(mx2) * 0.9 //zoom in just a bit; the majority of effects still have a good distance between the visible edge of the effect and the edge of the bbox, so this helps make them more visible; a small number of effects that don't have this issue get cut off slightly, but it's worth the tradeoff
							
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

					if effecttab.particle then
						if effecttab.particle.IsValid and effecttab.particle:IsValid() then
							effecttab.particle:StopEmissionAndDestroyImmediately()
						//elseif PartCtrl_AddParticles_CrashCheck[pcf] and PartCtrl_AddParticles_CrashCheck[pcf][effecttab.particle] then
						//	//Remove now-invalid particles from the crashcheck list
						//	PartCtrl_AddParticles_CrashCheck[pcf][effecttab.particle] = nil
						else
							self.particle = nil
						end
					end
					if effecttab.particle2 then
						if effecttab.particle2.IsValid and effecttab.particle2:IsValid() then
							effecttab.particle2:StopEmissionAndDestroyImmediately()
						//elseif PartCtrl_AddParticles_CrashCheck[pcf] and PartCtrl_AddParticles_CrashCheck[pcf][effecttab.particle2] then
						//	//Remove now-invalid particles from the crashcheck list
						//	PartCtrl_AddParticles_CrashCheck[pcf][effecttab.particle2] = nil
						else
							self.particle2 = nil
						end
					end

				end
			end

			if effecttab.reset then
				//Remove all info for this particle, recreate it from scratch next frame
				//(this is set by reloading a pcf with the extra dev dropdown options)
				PartCtrl_IconFx[pcf][name] = nil
			end

		end
	end

end)

function PANEL:DoClick()

	//If the icon's effect is currently being overridden by another pcf's effect of the same name, reload the pcf on click instead
	if self:IsCurrentlyOverridden() then
		surface.PlaySound("common/wpn_select.wav") //TODO: is this a good sound? needs to be different enough from the spawn sound so players can tell that clicking didn't spawn an effect yet.
		PartCtrl_AddParticles(self.pcf, self.name) //crash prevention
	else
		RunConsoleCommand("partctrl_spawnparticle", self.name, self.pcf)
		surface.PlaySound("ui/buttonclickrelease.wav")
	end

end

function PANEL:OpenMenu()

	local menu = DermaMenu()

	menu:AddOption("Copy effect name to clipboard", function() SetClipboardText(self.name) end):SetIcon("icon16/page_copy.png")
	if self.pcf != "UtilFx" then menu:AddOption("Copy .pcf file path to clipboard", function() SetClipboardText(self.pcf) end):SetIcon("icon16/page_copy.png") end

	menu:AddOption("#spawnmenu.menu.spawn_with_toolgun", function()
		RunConsoleCommand("gmod_tool", "partctrl_creator")
		RunConsoleCommand("partctrl_creator_pcf", self.pcf)
		RunConsoleCommand("partctrl_creator_name", self.name)
	end):SetIcon("icon16/brick_add.png")

	//List all parents and children of this effect recursively; this means we don't have to clutter up the spawnlists with children
	if istable(PartCtrl_ProcessedPCFs[self.pcf]) and istable(PartCtrl_ProcessedPCFs[self.pcf][self.name]) then
		local function ListChildFx(submenu, submenuoption, name2, tabname)
			local listed_fx = {} //don't list the same effect more than once - sometimes a parent can have multiple of the same child
			for _, child in pairs (PartCtrl_ProcessedPCFs[self.pcf][name2][tabname]) do
				//ptab.children is a table of tables containing both child names and other info about them;
				//ptab.parents is just a table of strings
				if istable(child) then
					child = child.child
				end
				if PartCtrl_ProcessedPCFs[self.pcf][child] and !listed_fx[child] then
					listed_fx[child] = true
					local OnClick = function()
						RunConsoleCommand("partctrl_spawnparticle", child, self.pcf)
						surface.PlaySound("ui/buttonclickrelease.wav")
					end
					local submenu2
					local option2
					if PartCtrl_ProcessedPCFs[self.pcf][child][tabname] and table.Count(PartCtrl_ProcessedPCFs[self.pcf][child][tabname]) > 0 then
						submenu2, option2 = submenu:AddSubMenu(child, OnClick)
						ListChildFx(submenu2, option2, child, tabname)
					else
						option2 = submenu:AddOption(child, OnClick)
					end
					if PartCtrl_ProcessedPCFs[self.pcf][child].shouldcull then //in developer mode, add warnings to culled fx
						option2:SetImage("icon16/error.png")
						//duplicate of text string from this panel's setup func, whatever
						option2:SetTooltip("NOTE: This effect will not be loaded outside of developer mode.\n\n" .. tostring(PartCtrl_ProcessedPCFs[self.pcf][child].shouldcull))
					end
				end
			end
			submenuoption:SetText(submenuoption:GetText() .. " (" .. table.Count(listed_fx) .. ")") //count the number of fx not including dupes
		end
		local ptab = PartCtrl_ProcessedPCFs[self.pcf][self.name]
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

		local text = "Reload .pcf file"
		if self.pcf == "UtilFx" then text = "Reload PartCtrl_UtilFx" end
		menu:AddOption(text, function()
			net.Start("PartCtrl_ReloadPCF_SendToSv")
				net.WriteString(self.pcf)
			net.SendToServer()
		end)

		if self.pcf != "UtilFx" then
			menu:AddOption("Print raw PCF data for this effect", function()
				MsgN("PartCtrl_ReadPCF(\"" .. self.pcf .. "\")[\"" .. self.name .. "\"]:")
				PrintTable(PartCtrl_ReadPCF(self.pcf)[self.name])
				MsgN()
			end)
		end

		menu:AddOption("Print processed PCF data for this effect", function()
			MsgN("PartCtrl_ProcessedPCFs[\"" .. self.pcf .. "\"][\"" .. self.name .. "\"]:")
			PrintTable(PartCtrl_ProcessedPCFs[self.pcf][self.name])
		end)
	end

	menu:Open()

end

function PANEL:Copy()

	//This function is called when dragging an icon from a search into a spawnlist - the baseclass' version of this always creates a normal ContentIcon panel, and also causes errors
	//because it tries to copy a nonexistent "material" value; don't overthink this, just have our own function, this works fine

	local copy = vgui.Create("ContentIcon_PartCtrl", self:GetParent())
	copy:Setup(self.pcf, self.name)
	//copy.IsInSearch = self.IsInSearch

	return copy

end

vgui.Register("ContentIcon_PartCtrl", PANEL, "ContentIcon")

spawnmenu.AddContentType("partctrl", function(container, obj)

	//Particle name and pcf are stored in the "nicename" and "spawnname" values that ContentIcon already has; these will save and load in spawnlists correctly
	if !obj.spawnname then return end
	if !obj.nicename then return end

	local icon = vgui.Create("ContentIcon_PartCtrl", container)
	icon:Setup(obj.spawnname, obj.nicename)

	container:Add(icon)

	return icon

end)