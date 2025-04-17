local PANEL = {}

local icon_invalid = Material("icon16/cancel.png")
//local icon_multiplydefined = Material("icon16/exclamation.png")
local icon_multiplydefined = Material("icon16/page_copy.png")
local icon_multiplydefined_2 = Material("icon16/bullet_error.png")
local icon_position = Material("icon16/arrow_right.png")//Material("sprites/grip") //Material("icon16/arrow_inout.png")
//local icon_position_none = Material("icon16/bullet_delete.png")
local icon_edit = Material("icon16/pencil.png")
local icon_color = Material("icon16/color_wheel.png")
local icon_model = Material("icon16/brick_go.png") //ehh
local icon_test = Material("icon16/color_wheel.png")
local icon_deverror = Material("icon16/error.png")
local icon_utilfx = Material("icon16/cog.png")
local icon_info = Material("icon16/information.png")

if system.IsLinux() then
	--[[surface.CreateFont("PartCtrl_DermaDefaultSmall", {
		font		= "DejaVu Sans",
		size		= 12, //don't have this font, so just have to trust that this is right (1pt larger than the tahoma, like in https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/derma/init.lua#L6C1-L45C4)
		weight		= 500,
		extended	= true
	})]]
	surface.CreateFont("PartCtrl_DermaDefaultSmallOutlined", {
		font		= "DejaVu Sans",
		size		= 12, //don't have this font, so just have to trust that this is right (1pt larger than the tahoma, like in https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/derma/init.lua#L6C1-L45C4)
		weight		= 500,
		extended	= true,
		outline		= true
	})
else
	--[[surface.CreateFont("PartCtrl_DermaDefaultSmall", {
		font		= "Tahoma",
		size		= 11, //not too happy with this, 10pt is just a bit too small to be easily readable, but 11pt is still too big for a lot of particle names
		weight		= 500,
		extended	= true
	})]]
	surface.CreateFont("PartCtrl_DermaDefaultSmallOutlined", {
		font		= "Tahoma",
		size		= 11, //not too happy with this, 10pt is just a bit too small to be easily readable, but 11pt is still too big for a lot of particle names
		weight		= 500,
		extended	= true,
		outline		= true
	})
end

function PANEL:Setup(pcf, name)

	//list of all panels, for developer refresh func and particle cleanup
	PartCtrl_AllContentIcons = PartCtrl_AllContentIcons or {}
	PartCtrl_AllContentIcons[pcf] = PartCtrl_AllContentIcons[pcf] or {}
	PartCtrl_AllContentIcons[pcf][self] = true

	self.pcf = pcf
	self.name = name
	self:SetName(name)
	self:SetSpawnName(pcf)
	self:SetContentType("partctrl")
	//particle names are consistently too long for a single line, try multiline text
	//self.Label:SetWrap(true)
	//self.Label:SetAutoStretchVertical(true)
	//self.Label:SetContentAlignment(5) //doesn't work when SetWrap is set to true
	//we can't make multiline text look good, try small text
	//self.Label:SetFont("HudHintTextSmall") //too blurry
	//self.Label:SetFont("PartCtrl_DermaDefaultSmall") //as of 3/26/25 update, this doesn't work either; in the implementation of label text scrolling, the label is now hard-coded in the paint function instead of being a separate object, so we can't change its font easily, though it's not as necessary to do so any more (https://github.com/Facepunch/garrysmod/commit/57ab57d524376c15a95b4072d1dc7d81070f0ee5)

	local tooltip = name
	self.icons = {}
	if !istable(PartCtrl_ProcessedPCFs[pcf]) or !istable(PartCtrl_ProcessedPCFs[pcf][name]) or !istable(PartCtrl_ProcessedPCFs[pcf][name].cpoints) then
		tooltip = tooltip .. "\n(" .. pcf .. ")\n\nInvalid particle effect (from game/addon that isn't mounted?)"
		//table.insert(self.icons, {["icon"] = icon_invalid})
		self:SetMaterial("icon16/cancel.png") //icon_invalid) //why doesn't this one take a Material()? whatever
	else
		self.utilfx = PartCtrl_ProcessedPCFs[pcf][name].utilfx
		if !self.utilfx then
			tooltip = tooltip .. "\n(" .. pcf .. ")"

			if table.Count(PartCtrl_PCFsByParticleName[name]) > 1 then
				tooltip = tooltip .. "\n\nWarning: This particle effect name is defined in multiple files:"
				for k, _ in pairs (PartCtrl_PCFsByParticleName[name]) do
					tooltip = tooltip .. "\n" .. k
				end
				tooltip = tooltip .. "\nOnly one effect called \"" .. name .. "\" can be loaded at a time.\nIf you load effects from any of these files, even in spawnicons, it will\nuse the \"" .. name .. "\" from the most recently loaded file." 
				table.insert(self.icons, {["icon"] = icon_multiplydefined, ["icon2"] = icon_multiplydefined_2})
			end

			//developer warnings for culled fx
			if PartCtrl_ProcessedPCFs[pcf][name].shouldcull then
				tooltip = tooltip .. "\n\nERROR: This effect will not be loaded outside of developer mode.\n\n" .. tostring(PartCtrl_ProcessedPCFs[pcf][name].shouldcull) //just in case some doofus makes it a bool
				//tooltip reaches max length if all 3 errors are on one effect, but whatever
				table.insert(self.icons, {["icon"] = icon_deverror})
			end
		else
			tooltip = tooltip .. "\n(Scripted Effect)"
			//table.insert(self.icons, {["icon"] = icon_utilfx})
			self:SetMaterial("icon16/cog.png") //icon_utilfx) //why doesn't this one take a Material()? whatever
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
		if PartCtrl_ProcessedPCFs[pcf][name].on_model then
			local count = table.Count(PartCtrl_ProcessedPCFs[pcf][name].on_model)
			if types[PARTCTRL_CPOINT_MODE_POSITION] > count then
				tooltip = tooltip .. "\n\nThis effect will cover a whole model if control point"
				if count > 1 then tooltip = tooltip .. "s" end
				local docomma = false
				for k, _ in pairs (PartCtrl_ProcessedPCFs[pcf][name].on_model) do
					if docomma then tooltip = tooltip .. "," end
					tooltip = tooltip .. " " .. k
					docomma = true
				end
				if docomma then
					tooltip = tooltip .. " is attached."
				else
					tooltip = tooltip .. " are attached."
				end
			else
				tooltip = tooltip .. "\n\nThis effect will cover a whole model if attached."
			end
			table.insert(self.icons, {["icon"] = icon_model})
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
	self:SetTooltip(tooltip)

	self:BeginNewParticle()
	self.DoneSetup = true

end

function PANEL:OnRemove()

	//list of all panels, for developer refresh func and particle cleanup
	PartCtrl_AllContentIcons = PartCtrl_AllContentIcons or {}
	PartCtrl_AllContentIcons[self.pcf] = PartCtrl_AllContentIcons[self.pcf] or {}
	PartCtrl_AllContentIcons[self.pcf][self] = nil

	//don't leave behind an orphaned particle
	self:RemoveParticle()

end

function PANEL:RemoveParticle()

	if self.particle and self.particle.IsValid and self.particle:IsValid() then
		self.particle:StopEmissionAndDestroyImmediately()
		--[[if PartCtrl_AddParticles_CrashCheck[self.pcf] and PartCtrl_AddParticles_CrashCheck[self.pcf][self.particle] then
			//Remove now-invalid particles from the crashcheck list
			PartCtrl_AddParticles_CrashCheck[self.pcf][self.particle] = nil
		end]] //this doesn't work, we can't always assume StopEmissionAndDestroyImmediately actually cleared the particle immediately
	end
	if self.particle2 and self.particle2.IsValid and self.particle2:IsValid() then
		self.particle2:StopEmissionAndDestroyImmediately()
		--[[if PartCtrl_AddParticles_CrashCheck[self.pcf] and PartCtrl_AddParticles_CrashCheck[self.pcf][self.particle2] then
			//Remove now-invalid particles from the crashcheck list
			PartCtrl_AddParticles_CrashCheck[self.pcf][self.particle2] = nil
		end]] //this doesn't work, we can't always assume StopEmissionAndDestroyImmediately actually cleared the particle immediately
	end

end

function PANEL:BeginNewParticle()

	if self.utilfx or !istable(PartCtrl_ProcessedPCFs[self.pcf]) or !istable(PartCtrl_ProcessedPCFs[self.pcf][self.name]) 
	or PartCtrl_ProcessedPCFs[self.pcf][self.name].prevent_name_based_lookup then //don't bother trying to create fx with this attribute, even in developer mode, it'll just fail and spam the console with errors
		return
	end

	self:RemoveParticle()

	//TODO: none of this works because we can't tell if our parent is the search panel. the IsInSearch = true that we set in search.AddProvider stops being true when the spawnicon is recreated by 
	//a model search update, and self:GetParent() == g_SpawnMenu.SearchPropPanel NEVER works.
	////If this spawnicon is from a search, then if the spawnmenu model search is currently populating, it'll recreate the spawnicon every time it finds a new model.
	////If this spawnicon has a conflicting PCF, then it'll run game.AddParticles every time the spawnicon is recreated, which will cause a stutter.
	////If both of these are true, then that means it'll stutter *every single time* the search finds a new model, which can slow the game down to a crawl or even crash. Instead, just wait
	////for the model search to finish populating before we start the particle.
	//local badsearchparticle = false
	//local par2 = self:GetParent():GetParent()
	//if self.IsInSearch and table.Count(PartCtrl_PCFsByParticleName[self.name]) > 1 and timer.Exists("search_models_update") then //the check for search_models_update is sort of a hack, but it's the only way i could find to check if the spawnmenu model search is currently populating (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/cl_search_models.lua#L38)
	//	badsearchparticle = true
	//else
		//Call game.AddParticles every time we begin a new particle, so that re-opening a spawnlist can reload pcf files with conflicting effects that have since been overridden
		//MsgN("PANEL:BeginNewParticle ", self.pcf)
		PartCtrl_AddParticles(self.pcf, self.name) //crash prevention

		//self:StartParticle()
		self.particle = partctrl_wait //make think run StartParticle next frame; this lets all the spawnicons in a spawnlist run PartCtrl_AddParticles first, before any of them have spawned any fx
	//end
	//MsgN(self.IsInSearch, table.Count(PartCtrl_PCFsByParticleName[self.name]) > 1, timer.Exists("search_models_update"), " ", par2:GetClassName(), " ", self.name, " ", self.pcf)
	//MsgN("according to icon, parent is ", self:GetParent(), " and self is ", self)

	//if (!self.particle and PartCtrl_AddParticles_CrashCheck_ThrottledPCFs[self.pcf]) or badsearchparticle then
	if (!self.particle or self.particle == "cleaned_up") and PartCtrl_AddParticles_CrashCheck_ThrottledPCFs[self.pcf] then
		self.particle = partctrl_wait	//ordinarily, PANEL:Paint won't try to recreate the particle if self.particle is nil, which is what we want. however, if crash prevention
	end					//prevented us from creating our effect here, then make this value non-nil so PANEL:Paint will try to create it once crash prevention is over.

end

function PANEL:StartParticle()

	if self.utilfx or !istable(PartCtrl_ProcessedPCFs[self.pcf]) or !istable(PartCtrl_ProcessedPCFs[self.pcf][self.name]) then return end

	if PartCtrl_AddParticles_CrashCheck_ThrottledPCFs[self.pcf] then return end
	if !self.precached then
		PrecacheParticleSystem(self.name)
		self.precached = true
	end
	self.particle = CreateParticleSystemNoEntity(self.name, vector_origin)
	if self.particle and self.particle:IsValid() then
		//For effects using a color or edit cpoint, their renderbounds will be stretched out by the cpoint if they're too far away,
		//so create a second particlesystem without those cpoints, so we can use its renderbounds instead
		if self.doparticle2 then
			if self.particle2_playerposfix then
				self.particle2 = CreateParticleSystem(LocalPlayer(), self.name, PATTACH_ABSORIGIN_FOLLOW)
			else
				self.particle2 = CreateParticleSystemNoEntity(self.name, vector_origin)
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
		for k, v in pairs (PartCtrl_ProcessedPCFs[self.pcf][self.name].cpoints) do
			if v.mode == PARTCTRL_CPOINT_MODE_POSITION then
				table.insert(self.iGrips, k)
			elseif v.mode == PARTCTRL_CPOINT_MODE_POSITION_COMBINE then
				table.insert(self.iPositionCombine, k)
			end
		end
		self:DoPosCPoints(self.particle)
		if self.particle2 then
			self:DoPosCPoints(self.particle2)
		end
		//Handle axis cpoints and vector cpoints other than colors by just setting them to their default value
		for k, v in pairs (self.EditCPoints) do
			self.particle:SetControlPoint(k, v)
		end
		self:DoColorCPoints() //accomodate CERTAIN EFFECTS that don't change color after spawning, looking at you wrangler :shakefist:
		PartCtrl_AddParticles_CrashCheck[self.pcf] = PartCtrl_AddParticles_CrashCheck[self.pcf] or {}
		PartCtrl_AddParticles_CrashCheck[self.pcf][self.particle] = true
		if self.particle2 then
			PartCtrl_AddParticles_CrashCheck[self.pcf][self.particle2] = true
		end
	else
		//we should've been able to create the particlesystem, but failed for some reason (i.e. pcf wasn't precached yet?), try again
		self.particle = partctrl_wait
	end

end

function PANEL:DoPosCPoints(p)

	//Handle position cpoints by placing them all in a fixed-length line, with the cpoints distributed evenly from one end of the line to another
	local multigrip_length = 100

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
			pos = ((i-1)/(#self.iGrips-1))*multigrip_length
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

end

function PANEL:DoColorCPoints()

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

local ViewAngle = Angle(25, 220, 0)
local icon_loading = Material("vgui/loading-rotate.vmt") //TODO: replace this with a custom texture eventually, something bulkier that looks better when it's drawn small like this
function PANEL:Paint(w, h)

	if !self.DoneSetup then
		baseclass.Get("ContentIcon").Paint(self, w, h)
		return
	end

	//When hovered over with the mouse, check AddParticles again.
	//(i.e. hover over an effect being overridden to make it show the correct one)
	//This only runs if hovered over for *two* frames in a row, to get around an issue where upon opening the 
	//spawnmenu, the cursor is considered to be hovering over the panel in the center of the screen for 1 frame.
	self.LastHovered = self.LastHovered or 0
	if self:IsHovered() then
		self.LastHovered = self.LastHovered + 1
	else
		self.LastHovered = 0
	end
	if self.LastHovered == 2 then
		//surface.PlaySound("vo/ravenholm/engage02.wav")
		PartCtrl_AddParticles(self.pcf, self.name) //crash prevention
	end

	//Draw particle preview
	if self.particle then
		if self.particle.IsValid and self.particle:IsValid() then
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
			if self.view then
				local x, y = self:LocalToScreen(0,0)
				local bd = self.Border + 4
				cam.Start3D(self.view.pos, ViewAngle, 90, x + bd, y + bd, w - (bd*2), h - (bd*2), 1, math.huge)

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

				self:DoColorCPoints()

				cam.StartOrthoView(-self.view.ortho, self.view.ortho, self.view.ortho, -self.view.ortho) //we use an orthogonal view instead of how RenderSpawnIcon does it, because RenderSpawnIcon's FOV code sucks really bad for icons that zoom out a lot
				self.particle:Render()
				--[[render.DrawWireframeBox(vector_origin, angle_zero, self.mins, self.maxs, color_white, true)
				if self.particle2 then
					local mn_, mx_ = self.particle2:GetRenderBounds()
					render.DrawWireframeBox(vector_origin, angle_zero, mn_, mx_, Color(255,0,0), true)
				end]]
				//render.DrawWireframeBox(Vector(mn.x, mx.y, mn.z), angle_zero, Vector(-1,-1,-1), Vector(1,1,1), Color(255,0,0), false)
				//render.DrawWireframeBox(Vector(mx.x, mn.y, mx.z), angle_zero, Vector(-1,-1,-1), Vector(1,1,1), Color(0,0,255), false)
				render.SetScissorRect(0, 0, 0, 0, false) //also from DModelPanel:DrawModel
				cam.End3D()
				cam.EndOrthoView()
			end
		else
			//Particle is non-nil but invalid; that means we should have a particle but lost it, so make a new particle
			if PartCtrl_AddParticles_CrashCheck[self.pcf] and PartCtrl_AddParticles_CrashCheck[self.pcf][self.particle] then
				//Remove now-invalid particles from the crashcheck list
				PartCtrl_AddParticles_CrashCheck[self.pcf][self.particle] = nil
			end
			if self.particle2 then
				if self.particle2.IsValid and self.particle2:IsValid() then
					self.particle2:StopEmissionAndDestroyImmediately()
				else
					if PartCtrl_AddParticles_CrashCheck[self.pcf] and PartCtrl_AddParticles_CrashCheck[self.pcf][self.particle2] then
						//Remove now-invalid particles from the crashcheck list
						PartCtrl_AddParticles_CrashCheck[self.pcf][self.particle2] = nil
					end
				end
			end
			if self.particle == "cleaned_up" then
				//Cleaned up by the panel being hidden; run BeginNewParticle to reload the PCF file if necessary
				self:BeginNewParticle()
			else
				//Either the particle ran to completion and expired, or we ran BeginNewParticle earlier and the crashcheck is making us wait,
				//so just run StartParticle and don't bother with PCF file stuff
				self:StartParticle()
			end
			//If particle is being throttled by crash prevention, draw loading icon
			if PartCtrl_AddParticles_CrashCheck_ThrottledPCFs[self.pcf] and (!self.particle or !(self.particle.IsValid and self.particle:IsValid())) then
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
	local x = self.Border + 8
	local y = self.Border + 8
	for k, v in pairs (self.icons) do
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
			surface.SetFont("PartCtrl_DermaDefaultSmallOutlined")
			local x2, y2 = surface.GetTextSize(v.num)
			x2 = x + 8 - (x2/2)
			y2 = y + 8 - (y2/3) //matches better with icon2 than y2/2
			surface.SetTextColor(255,255,255)
			surface.SetTextPos(x2, y2)
			surface.DrawText(v.num)
		end
		x = x + 16 + 2 //move the position of the next icon to the right by the width of this icon, plus a bit more
		if x + 16 > (w - self.Border - 8) then //if this would cause the next icon to stick out past the right edge of the panel, then start a new row instead
			y = y + 16 + 2
			x = self.Border + 8
		end
	end

end

function PANEL:DoClick()

	RunConsoleCommand("partctrl_spawnparticle", self.name, self.pcf)
	surface.PlaySound("ui/buttonclickrelease.wav")

end

function PANEL:OpenMenu()

	local menu = DermaMenu()

	menu:AddOption("Copy effect name to clipboard", function() SetClipboardText(self.name) end):SetIcon("icon16/page_copy.png")
	if !self.utilfx then menu:AddOption("Copy .pcf file path to clipboard", function() SetClipboardText(self.pcf) end):SetIcon("icon16/page_copy.png") end

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
						option2:SetTooltip("ERROR: This effect will not be loaded outside of developer mode.\n\n" .. tostring(PartCtrl_ProcessedPCFs[self.pcf][child].shouldcull))
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
		if self.utilfx then text = "Reload PartCtrl_UtilFx" end
		menu:AddOption(text, function()
			net.Start("PartCtrl_ReloadPCF_SendToSv")
				net.WriteString(self.pcf)
			net.SendToServer()
		end)

		if !self.utilfx then
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