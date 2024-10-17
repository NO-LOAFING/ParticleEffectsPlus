AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.PrintName			= "Particle Controller"
ENT.Author			= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
//ENT.RenderGroup		= RENDERGROUP_NONE

if CLIENT then
	language.Add("Undone_PartCtrl", "Undone Particle Effect")
    	language.Add("Cleanup_partctrl", "Particle Effects")
   	language.Add("Cleaned_partctrl", "Cleaned up all Particle Effects")
	language.Add("SBoxLimit_partctrl", "You've hit the Particle Effect limit!")
   	language.Add("max_partctrl", "Max Particle Effects:")
end




function ENT:SetupDataTables()

	self:NetworkVar("String", 0, "ParticleName")
	self:NetworkVar("String", 1, "PCF")

	self:NetworkVar("Int", 0, "LoopMode")
	self:NetworkVar("Float", 0, "LoopDelay")
	self:NetworkVar("Bool", 0, "LoopSafety")

	self:NetworkVar("Int", 1, "Numpad")
	self:NetworkVar("Bool", 1, "NumpadToggle")
	self:NetworkVar("Bool", 2, "NumpadStartOn")
	self:NetworkVar("Bool", 3, "NumpadState")

end




function ENT:Initialize()

	//self:SetNoDraw(true)
	self:SetModel("models/props_junk/watermelon01.mdl") //dummy model to prevent addons that look for the error model from affecting this entity, should this be something smaller?
	self:DrawShadow(false) //make sure the ent's shadow doesn't render, just in case RENDERGROUP_NONE/SetNoDraw don't work and we have to rely on the blank draw function
	self:SetCollisionBounds(vector_origin,vector_origin) //stop this ent from bloating up duplicator bounds

	if !istable(PartCtrl_ProcessedPCFs[self:GetPCF()]) or !istable(PartCtrl_ProcessedPCFs[self:GetPCF()][self:GetParticleName()]) then
		MsgN(self, " particle ", self:GetPCF(), " ", self:GetParticleName(), " is invalid")
		//if SERVER then self:Remove() end //not a great solution; causes our grip ents to delete themselves
		return
		//TODO: should we handle this better? if we load a dupe or something with an effect that's no longer valid, it just spawns an orphaned ent_partctrl that doesn't do anything, but is that
		//what we want? what if it's not valid because the player just doesn't have a game or addon loaded, and they decide to save it again and then load it again with the game reenabled?
	end

	//if SERVER then self:SetTransmitWithParent(true) end

	self.utilfx = PartCtrl_ProcessedPCFs[self:GetPCF()][self:GetParticleName()].utilfx

	if SERVER then
		if !self.ParticleInfo then 
			MsgN("ERROR: PartCtrl particle " .. self:GetParticleName() .. " (" .. self:GetPCF() .. ") doesn't have an info table! Something went wrong!") 
			self:Remove() 
			return
		end

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

	if CLIENT then
		if !self.utilfx then
			PartCtrl_AddParticles(self:GetPCF(), self:GetParticleName()) //crash prevention
		end

		AllPartCtrlEnts = AllPartCtrlEnts or {}
		AllPartCtrlEnts[self] = true
		self.LastDrawn = 0
	end

end




function ENT:Think()

	if CLIENT then

		local pcf = self:GetPCF()
		if !istable(PartCtrl_ProcessedPCFs[pcf]) or !istable(PartCtrl_ProcessedPCFs[pcf][self:GetParticleName()]) then return end

		//TODO: see if we need to copy the demo fix that ragdoll resizer/animpropoverhaul/advbone have for their info tables

		//If we don't have an info table, or need to update it, then request it from the server
		if !self.ParticleInfo_Received then
			net.Start("PartCtrl_InfoTable_GetFromSv")
				net.WriteEntity(self)
			net.SendToServer()

			self:NextThink(CurTime())
			return
		end

		local numpadisdisabling = self:GetNumpadState()
		if !self:GetNumpadStartOn() then
			numpadisdisabling = !numpadisdisabling
		end
		if !numpadisdisabling then
			local loop = self:GetLoopMode()
			local time = CurTime()
			if self.particle or self.utilfx then 
				local waiting = (self.particle == partctrl_wait)
				if self.particle and !(self.particle.IsValid and self.particle:IsValid()) then
					//Particle is non-nil but invalid; that probably means that it ran to completion and expired, so make a new particle
					if PartCtrl_AddParticles_CrashCheck[pcf] and PartCtrl_AddParticles_CrashCheck[pcf][self.particle] then
						//Remove now-invalid particles from the crashcheck list
						PartCtrl_AddParticles_CrashCheck[pcf][self.particle] = nil
					end
					
					if waiting then
						//MsgN(time, ": waiting")
						//We're ready to create the particle now, but crashcheck is making us wait, so just start the particle as soon as possible
						self:StartParticle()
					else
						if loop == 1 then //loop mode 1: repeat X seconds after ending
							if self.LastLoop == nil then
								self.LastLoop = time
								//MsgN(time, ": set last loop to ", self.LastLoop)
							end
							if (self.LastLoop + self:GetLoopDelay()) <= time then
								//MsgN(time, ": did loop 1")
								self:StartParticle()
								self.LastLoop = nil
							end
						end
					end
				end
				if loop == 2 then //loop mode 2: repeat every X seconds
					//TODO: do we need to handle the waiting var differently? tested, doesn't seem so
					
					if self.LastLoop and (self.LastLoop + math.max(0.0001, self:GetLoopDelay())) <= time then //don't let the loop delay actually be 0 here, otherwise it'll make a new effect every frame while paused
						//This loop mode can start a new particle while the old particle is still valid, so handle it
						if self.particle and self.particle.IsValid and self.particle:IsValid() then
							//self.particle:StopEmission() //interacts poorly with fx that players would actually want to repeat quickly like explosions, so commented it out; unfortunately this means we get stupid effect pileups with fx that last forever like flamethrowers, but there's no legitimate reason to repeat those anyway so we'll just have to trust people here
							table.insert(self.OldParticles, self.particle)
						end
						//MsgN(time, ": did loop 2")
						self:StartParticle()
						self.LastLoop = nil
					end

					if self.LastLoop == nil then
						self.LastLoop = time
						//MsgN(time, ": set last loop to ", self.LastLoop)
					end
				end
			end
		else
			if self.particle and self.particle.IsValid and self.particle:IsValid() and self.particle != partctrl_wait then
				//Stop any existing particles and throw them into the OldParticles table to get cleaned up
				self.particle:StopEmission()
				table.insert(self.OldParticles, self.particle)
				//Create a new particle as soon as we're no longer disabled
				self.particle = partctrl_wait
			end 
		end

		//Clean up old particle list
		for k, v in pairs (self.OldParticles) do
			if v and !(v.IsValid and v:IsValid()) then
				//MsgN("old particle ", k, " ", v, " expired")
				//Particle is non-nil but invalid; that probably means that it ran to completion and expired
				if PartCtrl_AddParticles_CrashCheck[pcf] and PartCtrl_AddParticles_CrashCheck[pcf][v] then
					//Remove now-invalid particles from the crashcheck list
					PartCtrl_AddParticles_CrashCheck[pcf][v] = nil
				end
				table.remove(self.OldParticles, k)
			end
		end
		//If there are too many old particles, remove the oldest one
		local max = 16 //TODO: make this a server convar so admins can control how many particles a player can create this way
		if self:GetLoopSafety() then max = 0 end
		while #self.OldParticles > max do
			local v = self.OldParticles[1]
			//MsgN(#self.OldParticles, " is too many particles, removing oldest ", v)
			v:StopEmissionAndDestroyImmediately()
			if PartCtrl_AddParticles_CrashCheck[pcf] and PartCtrl_AddParticles_CrashCheck[pcf][v] then
				//Remove now-invalid particles from the crashcheck list
				PartCtrl_AddParticles_CrashCheck[pcf][v] = nil
			end
			table.remove(self.OldParticles, 1)
		end

		//Do renderbounds
		if IsValid(self.particle) and self.particle.GetRenderBounds then
			//Cache which cpoint the renderbounds are relative to, so we don't have to keep retrieving this
			if self.ParticleInfo_LastCPoint == nil then
				for k, v in pairs (self.ParticleInfo) do
					if v.mode == PARTCTRL_CPOINT_MODE_POSITION then
						self.ParticleInfo_LastCPoint = k
						if self.ParticleInfo_FirstPos == nil then
							self.ParticleInfo_FirstPos = k
						end
					elseif v.mode == PARTCTRL_CPOINT_MODE_POSITION_COMBINE then
						self.ParticleInfo_LastCPoint = self.ParticleInfo_FirstPos or self.ParticleInfo_LastCPoint
					end
				end
			end
			//Set our renderbounds to the particle renderbounds, so that we run our Draw func whenever any part of the particle is visible; these are relative to the last position cpoint
			local pos = nil
			local v = self.ParticleInfo[self.ParticleInfo_LastCPoint]
			if v.mode == PARTCTRL_CPOINT_MODE_POSITION_COMBINE then
				v = self.ParticleInfo[self.ParticleInfo_FirstPos]
			end
			if v.mode == PARTCTRL_CPOINT_MODE_POSITION then
				if IsValid(v.ent.AttachedEntity) then
					pos = v.ent.AttachedEntity:GetAttachment(v.attach)
				else
					pos = v.ent:GetAttachment(v.attach)
				end
				if istable(pos) then
					pos = pos.Pos
				else
					pos = v.ent:GetPos() + v.pos
				end
			end
			if pos then
				local mins, maxs = self.particle:GetRenderBounds()
				local extra = Vector(20,20,20) //add arrow length to bounds so it doesn't get cut off at weird angles
				mins = mins + pos //- extra
				maxs = maxs + pos //+ extra
				self:SetRenderBoundsWS(mins, maxs, extra)
				self._wsmins = mins
				self._wsmaxs = maxs
			end
		end

		//If loop mode is set to minimum, ensure we run next frame (for utilfx like CommandPointer that need to draw a sprite every frame to render correctly)
		if self:GetLoopDelay() == 0 and self:GetLoopMode() == 2 then
			self:NextThink(CurTime())
			return true
		end

	else

		//Detect whether we're in the 3D skybox, and network that to clients to use in the Draw function because they can't detect it themselves
		//(sky_camera ent is serverside only and ent:IsEFlagSet(EFL_IN_SKYBOX) always returns false)
		local skycamera = ents.FindByClass("sky_camera")
		if istable(skycamera) then skycamera = skycamera[1] end
		if IsValid(skycamera) then
			local inskybox = self:TestPVS(skycamera)
			if self:GetNWBool("IsInSkybox") != inskybox then
				self:SetNWBool("IsInSkybox", inskybox)
			end
		end

	end

end




if CLIENT then

	local PartCtrl_IsSkyboxDrawing = false

	hook.Add("PreDrawSkyBox", "PartCtrl_IsSkyboxDrawing_Pre", function()
		PartCtrl_IsSkyboxDrawing = true
	end)

	hook.Add("PostDrawSkyBox", "PartCtrl_IsSkyboxDrawing_Post", function()
		PartCtrl_IsSkyboxDrawing = false
	end)

	//local colortext = Color(130,255,31,255) //matches effect grip
	local colortext = Color(234,125,0,255) //matches temporary arrow texture; gmod blue would probably be a better final color
	local colorborder = Color(255,255,255,255)
	surface.CreateFont( "PartCtrl_3D2DFont", {
		font = "Arial",
		size = 100,
		weight = 5000,
	} )
	local arrowmat = Material("hud/arrow_big") //TODO: make better custom material eventually, this is a tf2 material; end of the arrow should be at the end of the texture; also compare "trails/laser" which doesn't render through walls

	function ENT:Draw()

		//Don't draw our particle in the 3D skybox if its renderbounds are clipping into it but we're not actually in there
		//(common problem for ents with big renderbounds on gm_flatgrass, where the 3D skybox area is right under the floor)
		if IsValid(self.particle) and self.particle.SetShouldDraw then
			if PartCtrl_IsSkyboxDrawing and !self:GetNWBool("IsInSkybox") then
				self.particle:SetShouldDraw(false)
			else
				self.particle:SetShouldDraw(true)
			end
		end

		//Instead of drawing the cpoint helpers ourselves, we tell our PostDrawTranslucentRenderables hook to do it, so that it always renders above particle effects
		self.LastDrawn = CurTime()

	end

	function ENT:DrawCPointHelpers()	
		if self.ParticleInfo then
			local window = IsValid(self.PartCtrlWindow) and g_ContextMenu:IsVisible()
			for k, v in pairs (self.ParticleInfo) do
				if v.mode == PARTCTRL_CPOINT_MODE_POSITION then
					if IsValid(v.ent) then
						local isgrip = v.ent:GetClass() == "ent_partctrl_grip"
						if window or isgrip then //hide helpers when they're attached to other ents unless the window is open
							//Draw particle effect helpers (numbers showing cpoint id, arrows showing cpoint orientation)
							local pos = nil
							local ang = nil
							if IsValid(v.ent.AttachedEntity) then
								pos = v.ent.AttachedEntity:GetAttachment(self.ParticleInfo[k].attach)
							else
								pos = v.ent:GetAttachment(self.ParticleInfo[k].attach)
							end
							if istable(pos) then
								ang = pos.Ang
								pos = pos.Pos
							else
								ang = v.ent:GetAngles()
								pos = v.ent:GetPos() + self.ParticleInfo[k].pos
							end

							render.SetMaterial(arrowmat)
							render.DrawBeam(pos, pos + (ang:Forward() * 20), 20, 1, 0, color_white)

							//TODO: this doesn't render through walls like the arrows or grips do, is there a better way than 3D2D to make text that resizes nicely like this?
							local view = LocalPlayer():GetViewEntity()
							local camang = nil
							if view:IsPlayer() then
								camang = view:EyeAngles()
							else
								camang = view:GetAngles()
							end
							camang:RotateAroundAxis( camang:Up(), -90 )
							camang:RotateAroundAxis( camang:Forward(), 90 )
							cam.Start3D2D(pos, camang, 0.125)
								draw.SimpleTextOutlined(k,"PartCtrl_3D2DFont",0,-50,colortext,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM,3,colorborder)
							cam.End3D2D()
						end
					end
				end
			end

			//Draw particle render bounds if control window is open
			//TODO: this looks bad for fx with vector/axis controls, do we really need to port over the whole particle2 thing from the spawnicon code?
			//if window then
			//	render.DrawWireframeBox(vector_origin, angle_zero, self._wsmins, self._wsmaxs, color_white, true)
			//end
		end
	end

	hook.Add("PostDrawTranslucentRenderables", "PartCtrl_DrawParticleHelpers", function(depth, skybox)

		if !skybox then
			if GetConVarNumber("cl_draweffectrings") == 0 then return end

			//Don't draw the grip if there's no chance of us picking it up
			local ply = LocalPlayer()
			local wep = ply:GetActiveWeapon()
			if !IsValid(wep) then return end
		
			local weapon_name = wep:GetClass()
		
			if weapon_name != "weapon_physgun" and weapon_name != "weapon_physcannon" and weapon_name != "gmod_tool" then
				return
			end

			local time = CurTime()

			if istable(AllPartCtrlGripEnts) then
				//Check the particle attacher tool, and draw a different sprite if it's selecting us
				local function get_active_tool(ply, tool)
					-- find toolgun
					local activeWep = ply:GetActiveWeapon()
					if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end

					return activeWep:GetToolObject(tool)
				end
				local tool = get_active_tool(ply, "partctrl_attacher")

				for self, _ in pairs (AllPartCtrlGripEnts) do
					if self.LastDrawn == time then
						self:DrawGripSprite(tool and tool.SelectedGripPoint == self)
					end
				end
			end

			if istable(AllPartCtrlEnts) then
				for self, _ in pairs (AllPartCtrlEnts) do
					if self.LastDrawn == time then
						self:DrawCPointHelpers()
					end
				end
			end
		end
	end)




	function ENT:RemoveParticle()

		local pcf = self:GetPCF()
		if self.particle and self.particle.IsValid and self.particle:IsValid() then
			self.particle:StopEmissionAndDestroyImmediately()
			if PartCtrl_AddParticles_CrashCheck[pcf] and PartCtrl_AddParticles_CrashCheck[pcf][self.particle] then
				//Remove now-invalid particles from the crashcheck list
				PartCtrl_AddParticles_CrashCheck[pcf][self.particle] = nil
			end
		end
		//Clean up old particles
		if istable(self.OldParticles) then
			for k, v in pairs (self.OldParticles) do
				if v and v.IsValid and v:IsValid() then
					v:StopEmissionAndDestroyImmediately()
					if PartCtrl_AddParticles_CrashCheck[pcf] and PartCtrl_AddParticles_CrashCheck[pcf][v] then
						//Remove now-invalid particles from the crashcheck list
						PartCtrl_AddParticles_CrashCheck[pcf][v] = nil
					end
				end
			end
		end
		self.OldParticles = nil

	end

	function ENT:BeginNewParticle()

		self:RemoveParticle()
		self:StartParticle()
		if !self.utilfx and !self.particle and PartCtrl_AddParticles_CrashCheck_PreventingCrash then
			self.particle = partctrl_wait	//ordinarily, ENT:Think won't try to recreate the particle if self.particle is nil, which is what we want. however, if crash prevention
		end					//prevented us from creating our effect here, then make this value non-nil so ENT:Think will try to create it once crash prevention is over.
		//Reset loop-related vars
		self.OldParticles = {}
		self.NextLoop = nil

	end

	function ENT:StartParticle()

		//If doing utilfx, then do that and stop here
		if self.utilfx then
			local ed = EffectData()
			local tab = list.GetForEdit("PartCtrl_UtilFx", true)[self:GetParticleName()]

			local cpoint_posang = {}
			local function DoCPointPosAng(k)
				if !self.ParticleInfo[k] then return end
				local ent = self.ParticleInfo[k].ent
				if IsValid(ent) then
					local pos = nil
					local ang = nil
					if IsValid(ent.AttachedEntity) then
						pos = ent.AttachedEntity:GetAttachment(self.ParticleInfo[k].attach)
					else
						pos = ent:GetAttachment(self.ParticleInfo[k].attach)
					end
					if istable(pos) then
						ang = pos.Ang
						pos = pos.Pos
					else
						ang = ent:GetAngles()
						pos = ent:GetPos() + self.ParticleInfo[k].pos
					end
					cpoint_posang[k] = {["ang"] = ang, ["pos"] = pos}
				end
			end

			//Get values from position controls
			if tab.cpoint_angles then
				local k = tab.cpoint_angles
				if !cpoint_posang[k] then DoCPointPosAng(k) end
				if cpoint_posang[k] then
					ed:SetAngles(cpoint_posang[k].ang)
				end
			end
			if tab.cpoint_normal then
				local k = tab.cpoint_normal
				if !cpoint_posang[k] then DoCPointPosAng(k) end
				if cpoint_posang[k] then
					//Results in bad effects if pointed exactly up or down (see AR2Explosion), so tilt it just a bit in those cases
					local norm = cpoint_posang[k].ang:Forward()
					if math.Round(norm.x, 6) == 0 and math.Round(norm.y, 6) == 0 then norm.x = 0.00001 end
					ed:SetNormal(norm)
				end
			end
			if tab.cpoint_attachment then
				ed:SetAttachment(self.ParticleInfo[tab.cpoint_attachment].attach)
			end
			if tab.cpoint_entity then
				local ent = self.ParticleInfo[tab.cpoint_entity].ent
				if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
				//special functionality for impact fx: set effect entity to world if unattached
				if tab.impact_entity then
					if ent:GetClass() == "ent_partctrl_grip" then
						ent = game.GetWorld()
					end
					//TODO: implement damagetype? doesn't seem to do anything except handle one special decal type, so just set it to default here to prevent issues.
					ed:SetDamageType(0)
				end
				ed:SetEntity(ent)
			end
			if tab.cpoint_origin then
				local k = tab.cpoint_origin
				if !cpoint_posang[k] then DoCPointPosAng(k) end
				if cpoint_posang[k] then
					ed:SetOrigin(cpoint_posang[k].pos)
				end
			end
			if tab.cpoint_start then
				local k = tab.cpoint_start
				if !cpoint_posang[k] then DoCPointPosAng(k) end
				if cpoint_posang[k] then
					ed:SetStart(cpoint_posang[k].pos)
				end
			end
			//Get values from vectors
			if tab.vector_angles then
				local k = tab.vector_angles.cpoint
				if self.ParticleInfo[k].val then
					ed:SetAngles(self.ParticleInfo[k].val)
				end
			end
			if tab.vector_normal then
				local k = tab.vector_normal.cpoint
				if self.ParticleInfo[k].val then
					ed:SetNormal(self.ParticleInfo[k].val)
				end
			end
			if tab.vector_origin then
				local k = tab.vector_origin.cpoint
				if self.ParticleInfo[k].val then
					ed:SetOrigin(self.ParticleInfo[k].val)
				end
			end
			if tab.vector_start then
				local k = tab.vector_start.cpoint
				if self.ParticleInfo[k].val then
					ed:SetStart(self.ParticleInfo[k].val)
				end
			end

			//Get scale, magnitude, radius values from axis controls
			if self.ParticleInfo[32] and self.ParticleInfo[32].val then
				if tab.scale then
					ed:SetScale(self.ParticleInfo[32].val.x)
				end
				if tab.magnitude then
					ed:SetMagnitude(self.ParticleInfo[32].val.y)
				end
				if tab.radius then
					ed:SetRadius(self.ParticleInfo[32].val.z)
				end
			end

			//Get color, surfaceprop value from axis controls
			if self.ParticleInfo[33] and self.ParticleInfo[33].val then
				if tab.color then
					ed:SetColor(self.ParticleInfo[33].val.x)
				end
				if tab.surfaceprop then
					ed:SetSurfaceProp(self.ParticleInfo[33].val.y)
				end
			end

			//Get flags value from axis controls - this uses multiple axes to store checkbox and dropdown values, which we just add together to get our final flag value
			if self.ParticleInfo[34] and self.ParticleInfo[34].val then
				ed:SetFlags(self.ParticleInfo[34].val.x + self.ParticleInfo[34].val.y + self.ParticleInfo[34].val.z)
			end

			//TODO: other unconventional values?

			util.Effect(self:GetParticleName(), ed, true)
			return
		end

		if PartCtrl_AddParticles_CrashCheck_PreventingCrash then return end
		if !self.precached then
			PrecacheParticleSystem(self:GetParticleName())
			self.precached = true
		end

		//Create our particle system and attach it to our first position cpoint
		local firstcpoint = nil
		local function DoFirstCPoint(k)
			if istable(self.ParticleInfo[k]) and self.ParticleInfo[k].mode == PARTCTRL_CPOINT_MODE_POSITION and IsValid(self.ParticleInfo[k].ent) then
				local ent = self.ParticleInfo[k].ent
				if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
				local attach = self.ParticleInfo[k].attach
				local pattach = PATTACH_POINT_FOLLOW
				if attach == 0 then
					attach = nil
					pattach = PATTACH_ABSORIGIN_FOLLOW
				end
				self.particle = CreateParticleSystem(ent, self:GetParticleName(), pattach, attach, self.ParticleInfo[k].pos)
				return true
			end
		end
		for k, v in SortedPairs (self.ParticleInfo) do
			if v.mode == PARTCTRL_CPOINT_MODE_POSITION then
				firstcpoint = k
				break 
			end
		end
		DoFirstCPoint(firstcpoint)

		local ignore = firstcpoint
		if firstcpoint > 0 then ignore = nil end //cpoint 0 automatically follows the entity it's created on, but the others won't, so if our only position cpoint is > 0, then do AddControlPoint for it too.

		if self.particle and self.particle:IsValid() then
			//Do other cpoints
			for k, v in pairs (self.ParticleInfo) do
				if k != ignore then
				//if k >= 0 then //don't do this for -1 because it's not a real cpoint
					if v.mode == PARTCTRL_CPOINT_MODE_POSITION or v.mode == PARTCTRL_CPOINT_MODE_POSITION_COMBINE then
						local tab = v
						if v.mode == PARTCTRL_CPOINT_MODE_POSITION_COMBINE then
							//"combine" this cpoint with the first position cpoint by having it follow all the same parameters as that one
							tab = self.ParticleInfo[firstcpoint]
						end
						local ent = tab.ent
						if IsValid(ent) then
							if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
							//The wiki is wrong: unlike CreateParticleSystem, the attachment id arg for this function actually needs to be a string!
							local attachstr = ent:GetAttachments()
							local pattach = PATTACH_POINT_FOLLOW
							if attachstr[tab.attach] and attachstr[tab.attach].name then
								attachstr = attachstr[tab.attach].name
							else
								//always dumps error in console "Model '(null)' doesn't have attachment '' to attach particle system '_' to."
								//unless we give it a valid attachment name. changing to PATTACH_ABSORIGIN_FOLLOW doesn't fix this, even though 
								//that pattach type doesn't even use attachments. this doesn't actually matter but it's messy, bleh.
								attachstr = nil
								pattach = PATTACH_ABSORIGIN_FOLLOW
							end
							self.particle:AddControlPoint(k, ent, pattach, attachstr, tab.pos)
						end
					elseif v.mode == PARTCTRL_CPOINT_MODE_VECTOR or v.mode == PARTCTRL_CPOINT_MODE_AXIS then
						self.particle:SetControlPoint(k, v.val)
					end
				end
			end
			
			local pcf = self:GetPCF()
			PartCtrl_AddParticles_CrashCheck[pcf] = PartCtrl_AddParticles_CrashCheck[pcf] or {}
			PartCtrl_AddParticles_CrashCheck[pcf][self.particle] = true
		end

	end




	function ENT:OnRemove()

		self:RemoveParticle()

		//Remove us from the list of particles on each cpoint ent (used by properties)
		if istable(self.ParticleInfo) then
			for k, v in pairs (self.ParticleInfo) do
				if v.mode == PARTCTRL_CPOINT_MODE_POSITION and IsValid(v.ent) and istable(v.ent.PartCtrl_ParticleEnts) then
					v.ent.PartCtrl_ParticleEnts[self] = nil
					//Refresh attacher tool effect list if this effect was removed from the list
					local panel = controlpanel.Get("partctrl_attacher")
					if panel and panel.effectlist and panel.CurEntity == v.ent then
						panel.effectlist.PopulateEffectList(panel.CurEntity)
					end
				end
			end
		end

		AllPartCtrlEnts[self] = nil

	end

end




if SERVER then

	function PartCtrlNumpadFunction(pl, ent, keydown)

		if !IsValid(ent) then return end
		if !ent.GetNumpadState then return end  //if the function doesn't exist yet, not if the function returns false
	
		local newstate
		if ent:GetNumpadToggle() then
			if keydown then
				newstate = !ent:GetNumpadState()
			end
		else
			newstate = keydown
		end

		if newstate != nil then
			ent:SetNumpadState(newstate)
			//Everything else is handled clientside in Think once the client receives the new NumpadState value
		end
		ent.NumpadKeyDown = keydown
	
	end

	numpad.Register("PartCtrl_Numpad", PartCtrlNumpadFunction)

	function ENT:DetachFromEntity(k, ply)
	
		if !istable(self.ParticleInfo[k]) then return end
		local ent = self.ParticleInfo[k].ent
		if !IsValid(ent) then return end

		local oldconst = nil
		local doparent = false
		local tab = constraint.FindConstraints(ent, "PartCtrl_Ent")
		if istable(tab) then
			for k2, v2 in pairs (tab) do
				if v2.Ent1 == self and v2.CPoint == k then
					oldconst = v2.Constraint
					doparent = v2.DoParent
				end
			end
		end
		if !IsValid(oldconst) then return end

		local g = ents.Create("ent_partctrl_grip")
		if !IsValid(g) then return end
		g:Spawn()

		local ang = nil
		local pos = nil
		if IsValid(ent.AttachedEntity) then
			pos = ent.AttachedEntity:GetAttachment(self.ParticleInfo[k].attach)
		else
			pos = ent:GetAttachment(self.ParticleInfo[k].attach)
		end
		if istable(pos) then
			ang = pos.Ang
			pos = pos.Pos
		else
			ang = ent:GetAngles()
			pos = ent:GetPos()
		end
		local _, bboxtop1 = ent:GetRotatedAABB(ent:GetCollisionBounds())
		local bboxtop2, _ = g:GetCollisionBounds()
		local height = bboxtop1.z + -bboxtop2.z + ent:GetPos().z
		g:SetPos(Vector(pos.x, pos.y, height))
		g:SetAngles(ang)

		//self.ParticleInfo[k].ent = g //the constraint function already does this
		self.ParticleInfo[k].attach = 0

		oldconst:RemoveCallOnRemove("PartCtrl_Ent_UnmergeOnUndo")
		oldconst:Remove()
		//Check if we want to clear DeleteOnRemove or not - if the same particle has another cpoint attached to the same entity, then we want to maintain
		//the DeleteOnRemove, but if this was the only cpoint attached to that entity, then clear the DeleteOnRemove
		local clear = true
		local tab = constraint.FindConstraints(ent, "PartCtrl_Ent")
		if istable(tab) then
			for k2, v2 in pairs (tab) do
				if v2.Constraint != oldconst and v2.Ent1 == self then
					clear = false
				end
			end
		end
		if clear then
			ent:DontDeleteOnRemove(self)
		end
		constraint.PartCtrl_Ent(self, g, k, doparent, ply)


		//Tell clients to retrieve the updated info table
		net.Start("PartCtrl_InfoTableUpdate_SendToCl")
			net.WriteEntity(self)
		net.Broadcast()


		return true

	end

end




//Networking for edit menu inputs
local EditMenuInputs = {
	[0] = "cpoint_mode",
	"cpoint_position_ent_setwithtool",
	"cpoint_position_ent_detach",
	"cpoint_position_attach",
	"cpoint_position_pos",
	"cpoint_vector_which",
	"cpoint_vector_val_all",
	"cpoint_vector_val_axis",
	"cpoint_axis_which",
	"cpoint_axis_val",
	"loop_mode",
	"loop_delay",
	"loop_safety",
	"numpad_num",
	"numpad_toggle",
	"numpad_starton"
}
local EditMenuInputs_bits = 4 //max 15
EditMenuInputs = table.Flip(EditMenuInputs)
//How this works:
//- table.Flip sets the table to {["cpoint_mode"] = 0}, and so on
//- net.Write retrieves the corresponding number of a string with EditMenuInputs[input], then sends that number
//- net.Read gets the number, then retrieves its corresponding string with table.KeyFromValue(EditMenuInputs, input)
//This lets us add as many networkable strings to this table as we want, without having to manually assign each one a number.


if CLIENT then

	function ENT:DoInput(input, ...)

		net.Start("PartCtrl_EditMenuInput_SendToSv")

			net.WriteEntity(self)
			local args = {...}

			net.WriteUInt(EditMenuInputs[input], EditMenuInputs_bits)

			if string.StartsWith(input, "cpoint_") then
				net.WriteInt(args[1], partctrl_cpointbits) //cpoint id
			end

			if input == "cpoint_mode" then

				net.WriteUInt(args[2], partctrl_cpointmodebits) //new cpoint mode
			
			//elseif input == "cpoint_position_ent_setwithtool" then

			//elseif input == "cpoint_position_ent_detach" then

			elseif input == "cpoint_position_attach" then

				net.WriteUInt(args[2], 8) //new attachment id; don't know what the max attachment number is, assume 255

			elseif input == "cpoint_position_pos" then
				
				net.WriteUInt(args[2], 2) //axis (1/2/3)
				net.WriteFloat(args[3]) //new value for axis

			//elseif input == "cpoint_vector_which" then

				//TODO

			elseif input == "cpoint_vector_val_all" then

				net.WriteVector(args[2]) //new value for all 3 axes

			elseif input == "cpoint_vector_val_axis" then

				net.WriteUInt(args[2], 2) //axis (1/2/3)
				net.WriteFloat(args[3]) //new value for axis

			//elseif input == "cpoint_axis_which" then

				//TODO
				
			elseif input == "cpoint_axis_val" then

				net.WriteUInt(args[2], 2) //axis (1/2/3)
				net.WriteFloat(args[3]) //new value for axis

			elseif input == "loop_mode" then

				net.WriteUInt(args[1], 2) //new loop mode (0/1/2)

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

		net.SendToServer()

	end

else

	util.AddNetworkString("PartCtrl_EditMenuInput_SendToSv")

	//Respond to inputs from the clientside edit menu
	net.Receive("PartCtrl_EditMenuInput_SendToSv", function(_, ply)

		local self = net.ReadEntity()
		if !IsValid(self) or self:GetClass() != "ent_partctrl" or !istable(self.ParticleInfo) then return end

		local input = net.ReadUInt(EditMenuInputs_bits)
		if !input then return end
		input = table.KeyFromValue(EditMenuInputs, input)

		local k = nil
		if string.StartsWith(input, "cpoint_") then
			k = net.ReadInt(partctrl_cpointbits)
		end
		local refreshtable = false

		if input == "cpoint_mode" then

			local newmode = net.ReadUInt(partctrl_cpointmodebits)
			//TODO: once we implement more cpoint modes, handle switching between modes (figure out what we want the default values to be,
			//create grip point ent in case we're switching from something else to position)

		elseif input == "cpoint_position_ent_setwithtool" then
			
			if !IsValid(ply) then return end
			if !GetConVar("toolmode_allow_partctrl_attacher"):GetBool() then return end //TODO: this was copied from advbonemerge, which also does a CanTool check with a fake trace. is that necessary here?

			local tool = ply:GetTool("partctrl_attacher")
			if !istable(tool) or !IsValid(tool:GetWeapon()) then return end

			ply:ConCommand("gmod_tool partctrl_attacher")
			//Fix: The tool's holster function clears the nwentity, and if this is already the toolgun's selected tool, it'll "holster" the tool before "deploying" it again.
			//To make this worse, it's different if the toolgun is the active weapon or not (if active, it holsters then deploys; if not active, it deploys, holsters, then deploys again)
			//so instead of having to deal with any of that, just set the entity on a delay so we're sure the tool is already done equipping.
			timer.Simple(0.1, function()
				if !IsValid(self) or !IsValid(ply) then return end
				tool:GetWeapon():SetNWInt("PartCtrl_Attacher_CPoint", k)
				tool:GetWeapon():SetNWEntity("PartCtrl_Attacher_CurEntity", self)
				tool:SetStage(1)
			end)

		elseif input == "cpoint_position_ent_detach" then

			//Send a notification to the player saying whether or not we managed to detach the particle
			if self:DetachFromEntity(k, ply) then
				ply:SendLua("GAMEMODE:AddNotify('#undone_PartCtrl_Ent', NOTIFY_UNDO, 2)")
				ply:SendLua("surface.PlaySound('buttons/button15.wav')")
			else
				ply:SendLua("GAMEMODE:AddNotify('Failed to detach particle', NOTIFY_ERROR, 5)")
				ply:SendLua("surface.PlaySound('buttons/button11.wav')")
			end
			//don't refresh table, DetachFromEntity handles this

		elseif input == "cpoint_position_attach" then

			local new = net.ReadUInt(8)

			if !istable(self.ParticleInfo[k]) or self.ParticleInfo[k].mode != PARTCTRL_CPOINT_MODE_POSITION then return end

			self.ParticleInfo[k].attach = new
			refreshtable = true

		elseif input == "cpoint_position_pos" then
			
			local axis = net.ReadUInt(2)
			local new = net.ReadFloat()

			if !istable(self.ParticleInfo[k]) or self.ParticleInfo[k].mode != PARTCTRL_CPOINT_MODE_POSITION then return end

			self.ParticleInfo[k].pos[axis] = new
			refreshtable = true

		//elseif input == "cpoint_vector_which" then

			//TODO

		elseif input == "cpoint_vector_val_all" then

			local new = net.ReadVector()

			if !istable(self.ParticleInfo[k]) or self.ParticleInfo[k].mode != PARTCTRL_CPOINT_MODE_VECTOR then return end

			self.ParticleInfo[k].val = new
			refreshtable = true

		elseif input == "cpoint_vector_val_axis" then

			local axis = net.ReadUInt(2)
			local new = net.ReadFloat()

			if !istable(self.ParticleInfo[k]) or self.ParticleInfo[k].mode != PARTCTRL_CPOINT_MODE_VECTOR then return end

			self.ParticleInfo[k].val[axis] = new
			refreshtable = true

		//elseif input == "cpoint_axis_which" then

			//TODO

		elseif input == "cpoint_axis_val" then

			local axis = net.ReadUInt(2)
			local new = net.ReadFloat()

			if !istable(self.ParticleInfo[k]) or self.ParticleInfo[k].mode != PARTCTRL_CPOINT_MODE_AXIS then return end

			//Sanity check: for some axis controls ("Emission Count Scale"), going out of range causes a crash, so make sure that doesn't happen
			local tab = PartCtrl_ProcessedPCFs[self:GetPCF()][self:GetParticleName()]["cpoints"][k]["axis"][self.ParticleInfo[k]["which_" .. axis-1]] //awesome
			if istable(tab) then
				if tab.inMin then
					new = math.max(tab.inMin, new)
				end
				if tab.inMax then
					new = math.min(tab.inMax, new)
				end
			end

			self.ParticleInfo[k].val[axis] = new
			refreshtable = true

		elseif input == "loop_mode" then
			
			self:SetLoopMode(net.ReadUInt(2))

		elseif input == "loop_delay" then
			
			self:SetLoopDelay(net.ReadFloat())

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

		if refreshtable then
			//Tell clients to retrieve the updated info table
			net.Start("PartCtrl_InfoTableUpdate_SendToCl")
				net.WriteEntity(self)
			net.Broadcast()
		end

	end)

end




//Networking for infotable
if SERVER then 

	util.AddNetworkString("PartCtrl_InfoTable_GetFromSv")
	util.AddNetworkString("PartCtrl_InfoTable_SendToCl")
	util.AddNetworkString("PartCtrl_InfoTableUpdate_SendToCl")

	//If we received a request for an info table, then send it to the client
	net.Receive("PartCtrl_InfoTable_GetFromSv", function(_, ply)
		local ent = net.ReadEntity()
		if !IsValid(ent) or !istable(ent.ParticleInfo) then return end

		//Make sure the table is ready to send first - if we're a dupe, and our constraints haven't restored the .ent values for our cpoints using PARTCTRL_CPOINT_MODE_POSITION,
		//then this is most likely a bad dupe, so remove us and stop here
		local badparticle = nil
		for k, v in pairs (ent.ParticleInfo) do
			if v.mode == PARTCTRL_CPOINT_MODE_POSITION and v.ent == nil then
				//MsgN("stop")
				//return
				badparticle = k
				break
			end
		end
		if badparticle != nil then
			MsgN("ent_partctrl ", ent, " (", ent:GetParticleName(), ") has nil target entity ", badparticle, "; most likely a bad dupe, removing")
			for k, v in pairs (ent.ParticleInfo) do
				//don't leave behind any orphaned grip points (i.e. loaded a dupe; one cpoint was attached to a non-dupable entity, another was attached to a grip)
				if IsValid(v.ent) and v.ent:GetClass() == "ent_partctrl_grip" then
					v.ent:Remove()
				end
			end
			ent:Remove()
			return
		end
		//MsgN("go")

		net.Start("PartCtrl_InfoTable_SendToCl")

			net.WriteEntity(ent)

			net.WriteInt(table.Count(ent.ParticleInfo), partctrl_cpointbits + 1) //+1 for the super edge case where all 64 cpoints are occupied AND we use fallback cpoint -1
			for k, v in pairs (ent.ParticleInfo) do
				net.WriteInt(k, partctrl_cpointbits)

				net.WriteUInt(v.mode, partctrl_cpointmodebits) 
				if v.mode == PARTCTRL_CPOINT_MODE_POSITION then
					net.WriteEntity(v.ent or NULL)
					net.WriteUInt(v.attach or 0, 8) //don't know what the max attachment number is, assume 255
					net.WriteVector(v.pos or Vector())
				elseif v.mode == PARTCTRL_CPOINT_MODE_VECTOR then
					net.WriteUInt(v.which or 0, 4) //the number of attributes modifying a single cpoint is potentially unlimited, but the vast majority won't have more than 1 since they'll all conflict with each other, so assume a generous max of 16
					net.WriteVector(v.val or Vector())
				elseif v.mode == PARTCTRL_CPOINT_MODE_AXIS then
					net.WriteVector(v.val or Vector())
					for i = 0, 2 do
						net.WriteUInt(v["which_" .. i] or 0, 4) //again, potentially unlimited but very unlikely to have more than 3 (one for each axis), assume generous max of 16
					end
				end
			end

		net.Send(ply)
	end)

else

	//If we received an info table from the server, then use it
	net.Receive("PartCtrl_InfoTable_SendToCl", function()

		local self = net.ReadEntity()
		if !IsValid(self) or !self:GetClass("ent_partctrl") then return end

		local tab = {}

		local window = IsValid(self.PartCtrlWindow) and istable(self.PartCtrlWindow.CPointCategories)

		for i = 1, net.ReadInt(partctrl_cpointbits + 1) do
			local k = net.ReadInt(partctrl_cpointbits)

			local v = {mode = net.ReadUInt(partctrl_cpointmodebits)}
			if v.mode == PARTCTRL_CPOINT_MODE_POSITION then
				v.ent = net.ReadEntity()
				v.attach = net.ReadUInt(8)
				v.pos = net.ReadVector()
			elseif v.mode == PARTCTRL_CPOINT_MODE_VECTOR then
				v.which = net.ReadUInt(4)
				v.val = net.ReadVector()
			elseif v.mode == PARTCTRL_CPOINT_MODE_AXIS then
				v.val = net.ReadVector()
				for i = 0, 2 do
					v["which_" .. i] = net.ReadUInt(4)
					//Sanity check: for some axis controls ("Emission Count Scale"), going out of range causes a crash, so make sure that doesn't happen
					local tab2 = PartCtrl_ProcessedPCFs[self:GetPCF()][self:GetParticleName()]["cpoints"][k]["axis"][v["which_" .. i]]
					if istable(tab2) then
						if tab2.inMin then
							v.val[i+1] = math.max(tab2.inMin, v.val[i+1])
						end
						if tab2.inMax then
							v.val[i+1] = math.min(tab2.inMax, v.val[i+1])
						end
					end
				end
			end

			tab[k] = v
		end
	
		local oldtab = table.Copy(self.ParticleInfo)
		self.ParticleInfo = tab
		self.ParticleInfo_Received = true
		self.ParticleInfo_LastCPoint = nil
		self.ParticleInfo_FirstPos = nil
		self:BeginNewParticle()

		if istable(oldtab) then
			local window = IsValid(self.PartCtrlWindow) and istable(self.PartCtrlWindow.CPointCategories)
			for k, v in pairs (oldtab) do
				if self.ParticleInfo[k].ent != oldtab[k].ent then
					local oldent = oldtab[k].ent
					//Remove us from the list of particles on the ent
					if oldent.PartCtrl_ParticleEnts then
						oldent.PartCtrl_ParticleEnts[self] = nil
					end
					//Refresh attacher tool effect list if this effect was removed from the list
					local panel = controlpanel.Get("partctrl_attacher")
					if panel and panel.effectlist and panel.CurEntity == oldent then
						panel.effectlist.PopulateEffectList(panel.CurEntity)
					end
				end
				//Refresh control window if we changed something that requires the controls to be rebuilt
				if window and (self.ParticleInfo[k].mode != oldtab[k].mode or self.ParticleInfo[k].ent != oldtab[k].ent) then
					self.PartCtrlWindow.CPointCategories[k].RebuildContents(self.ParticleInfo[k])
				end
			end
		end
		for k, v in pairs (self.ParticleInfo) do
			if IsValid(v.ent) then
				//Store us in a list on the cpoint ent (used by properties)
				v.ent.PartCtrl_ParticleEnts = v.ent.PartCtrl_ParticleEnts or {}
				v.ent.PartCtrl_ParticleEnts[self] = true
				//Refresh attacher tool effect list if this effect was added to the list
				local panel = controlpanel.Get("partctrl_attacher")
				if panel and panel.effectlist and panel.CurEntity == v.ent then
					panel.effectlist.PopulateEffectList(panel.CurEntity)
				end
			end
		end
		oldtab = nil

	end)

	//If we received a message from the server telling us an ent's info table is out of date, then change its ParticleInfo_Received value so its Think function requests a new one
	net.Receive("PartCtrl_InfoTableUpdate_SendToCl", function()
		local ent = net.ReadEntity()
		if !IsValid(ent) or ent:GetClass() != "ent_partctrl" then return end

		ent.ParticleInfo_Received = false
	end)

end




//Constraint, used to keep entities associated together between dupes/saves
//We use a separate constraint for each entity pair instead of one big constraint for the whole effect, because constraint.AddConstraintTable can only handle a max of 4 entities,
//while the worst-case-scenario particle effect could have up to 64 cpoint entities + the 1 particle entity itself
if SERVER then
	
	function constraint.PartCtrl_Ent(Ent1, Ent2, CPoint, DoParent, ply)

		if !Ent1 or !Ent2 or Ent1:GetClass() != "ent_partctrl" then return end
		//if !istable(PartCtrl_ProcessedPCFs[Ent1:GetPCF()]) or !istable(PartCtrl_ProcessedPCFs[Ent1:GetPCF()][Ent1:GetParticleName()]) then return end //causes grip ents from dupes with invalid fx to delete themselves due to having no particle
		
		//create a dummy ent for the constraint functions to use
		local const = ents.Create("info_target")
		const:Spawn()
		const:Activate()

		if Ent2:GetClass() != "ent_partctrl_grip" then
			//If the constraint is removed by an Undo, unmerge the second entity - this shouldn't do anything if the constraint's removed some other way i.e. one of the ents is removed
			timer.Simple(0.1, function()  //CallOnRemove won't do anything if we try to run it now instead of on a timer
				if const:GetTable() then  //CallOnRemove can error if this table doesn't exist - this can happen if the constraint is removed at the same time it's created for some reason
					const:CallOnRemove("PartCtrl_Ent_UnmergeOnUndo", function(const,Ent1,ply)
						//MsgN("PartCtrl_Ent_UnmergeOnUndo called by constraint ", const, ", ents ", Ent1, " ", Ent2)
						//NOTE: if we use the remover tool to get rid of ent2, it'll still be valid for a second, so we need to look for the NoDraw and MoveType that the tool sets the ent to instead.
						//this might have a few false positives, but i don't think that many people will be attaching stuff to invisible, intangible ents a whole lot anyway so it's not a huge deal
						if !IsValid(const) or !IsValid(Ent2) or Ent2:IsMarkedForDeletion() or (Ent2:GetNoDraw() == true and Ent2:GetMoveType() == MOVETYPE_NONE) or !IsValid(Ent1) or Ent1:IsMarkedForDeletion() or !IsValid(ply) or !Ent1.DetachFromEntity then return end
						Ent1:DetachFromEntity(CPoint, ply)
					end, Ent1, ply)
				end
			end)
		end

		if istable(Ent1.ParticleInfo) and istable(Ent1.ParticleInfo[CPoint]) and Ent1.ParticleInfo[CPoint].mode == PARTCTRL_CPOINT_MODE_POSITION then
			Ent1.ParticleInfo[CPoint].ent = Ent2
		end
		if DoParent then
			Ent1:SetPos(Ent2:GetPos())
			Ent1:SetAngles(Ent2:GetAngles())
			Ent1:SetParent(Ent2)
		end

		if Ent2:GetClass() == "ent_partctrl_grip" then
			Ent1:DeleteOnRemove(Ent2)
		end
		Ent2:DeleteOnRemove(Ent1)

		constraint.AddConstraintTable(Ent1, const, Ent2)
		
		local ctable = {
			Type = "PartCtrl_Ent",
			Ent1 = Ent1,
			Ent2 = Ent2,
			CPoint = CPoint,
			DoParent = DoParent,
			ply = ply,
		}
	
		const:SetTable(ctable)
	
		return const
	end
	duplicator.RegisterConstraint("PartCtrl_Ent", constraint.PartCtrl_Ent, "Ent1", "Ent2", "CPoint", "DoParent", "ply")




	function ENT:OnEntityCopyTableFinish(data)

		//Don't store this DTvar
		if data.DT then
			data.DT["NumpadState"] = nil
		end

		//Clear out entity values when copying the ParticleInfo table, these won't dupe correctly anyway and will be filled back in by constraints
		if istable(data.ParticleInfo) then
			data.ParticleInfo = table.Copy(data.ParticleInfo) //make sure to create a separate table; otherwise, clearing the .ent value below will also clear the one still in use on the actual entity
			for k, v in pairs (data.ParticleInfo) do
				if v.mode == PARTCTRL_CPOINT_MODE_POSITION then
					data.ParticleInfo[k].ent = nil
				end
			end
		end

	end

end




duplicator.RegisterEntityClass("ent_partctrl", function(ply, data)

	if IsValid(ply) and !ply:CheckLimit("partctrl") then return false end

	local ent = ents.Create("ent_partctrl")
	if !ent:IsValid() then return false end

	//duplicator.GenericDuplicatorFunction(ply, data)
	duplicator.DoGeneric(ent, data)
	duplicator.DoGenericPhysics(ent, ply, data)

	ent.ParticleInfo = table.Copy(data.ParticleInfo)
	ent:SetPlayer(ply) //NOTE: this still works if ply doesn't exist

	ent:Spawn()

	if IsValid(ply) then ply:AddCount("partctrl", ent) end

	return ent

end, "Data")




if SERVER then

	function PartCtrl_SpawnParticle(ply, name, pcf)

		if !name or !pcf then 
			MsgN("partctrl_spawnparticle: failed, missing name or pcf (first arg is effect name, second arg is pcf file path starting with particles/ and ending with .pcf)")
			return
		elseif !istable(PartCtrl_ProcessedPCFs) then
			MsgN("partctrl_spawnparticle: failed, no PartCtrl_ProcessedPCFs table (this shouldn't happen, report this bug!)")
			return
		elseif !istable(PartCtrl_ProcessedPCFs[pcf]) then
			MsgN("partctrl_spawnparticle: failed, invalid pcf \"", pcf, "\"")
			return
		elseif !istable(PartCtrl_ProcessedPCFs[pcf][name]) then
			MsgN("partctrl_spawnparticle: failed, invalid name \"", name, "\" in pcf \"", pcf, "\"")
			return
		end

		if IsValid(ply) and !gamemode.Call("PlayerSpawnParticle", ply, name, pcf) then return end

		local tab = {}
		local grips = {}
		for k, v in pairs (PartCtrl_ProcessedPCFs[pcf][name].cpoints) do
			local mode = PartCtrl_ProcessedPCFs[pcf][name].defaults[k]
			if mode == PARTCTRL_CPOINT_MODE_POSITION then
				grips[k] = true
				tab[k] = {
					mode = PARTCTRL_CPOINT_MODE_POSITION,
					ent = nil,
					attach = 0,
					pos = Vector(0,0,0),
				}
			elseif mode == PARTCTRL_CPOINT_MODE_VECTOR then
				tab[k] = {
					mode = PARTCTRL_CPOINT_MODE_VECTOR,
					which = 0, //which entry in v["vector"] for the edit window to get values like inMin and pattach from
					val = Vector(0,0,0),
				}
				for k2, v2 in pairs (v["vector"]) do
					tab[k]["which"] = k2
					if v2.default then
						tab[k]["val"] = Vector(v2.default)
					end
					break
				end
			elseif mode == PARTCTRL_CPOINT_MODE_AXIS then
				tab[k] = {
					mode = PARTCTRL_CPOINT_MODE_AXIS,
					val = Vector(0,0,0)
				}
				for i = 0, 2 do
					tab[k]["which_" .. i] = 0 //which entry in v["axis"] for the edit window to get values like inMin and pattach from
					for k2, v2 in pairs (v["axis"]) do
						if v2.axis == i then 
							tab[k]["which_" .. i] = k2
							if v2.default then
								tab[k]["val"][i+1] = v2.default
							end
							break
						end
					end
				end
			elseif mode == PARTCTRL_CPOINT_MODE_POSITION_COMBINE then
				tab[k] = {
					mode = PARTCTRL_CPOINT_MODE_POSITION_COMBINE
				}
			else
				tab[k] = {
					mode = PARTCTRL_CPOINT_MODE_NONE
				}
			end
		end
		local grip_radius = 6/2
		local multigrip_length = PartCtrl_ProcessedPCFs[pcf][name].min_length or 100
		local maxs = Vector(grip_radius, grip_radius, grip_radius)
		if table.Count(grips) > 1 then
			maxs.x = multigrip_length/2 + grip_radius //add grip_radius so that grips won't spawn half-embedded in a wall
		end
		local tr = util.TraceHull({
			start = ply:GetShootPos(),
			endpos = ply:GetShootPos() + (ply:GetAimVector() * 2048),
			filter = ply,
			maxs = maxs,
			mins = -maxs
		})

		//Handle position cpoints by placing them all in a line 50 units long, with the cpoints distributed evenly from one end of the line to another
		//(note: this would take 18 or more grips on one single effect for them to start spawning inside each other, and no official fx get anywhere close, so don't worry about this)
		local igrips = {}
		for k, v in pairs (grips) do
			table.insert(igrips, k)
		end
		local parent = nil
		for i, k in ipairs (igrips) do
			local pos = 0
			if i > 1 then
				pos = ((i-1)/(#igrips-1))*multigrip_length
			end
			if #igrips > 1 then
				pos = tr.HitPos - Vector((multigrip_length/2)-pos, 0, 0)
			else
				pos = tr.HitPos
			end

			local g = ents.Create("ent_partctrl_grip")
			if !IsValid(g) then return end
			g:SetPos(pos)
			g:Spawn()
			grips[k] = g
			tab[k].ent = g
			if !IsValid(parent) then parent = g end
		end

		local p = ents.Create("ent_partctrl")
		if !IsValid(p) then return end
		p:SetPlayer(ply)
		p:SetParticleName(name)
		p:SetPCF(pcf)
		//Set NWVar defaults
		if pcf != "UtilFx" then
			p:SetLoopMode(1)
			p:SetLoopDelay(0)
		else
			//utilfx don't support mode 1 (wait for end of effect) because we don't have a way to tell when a util effect is over, so use mode 2 (just a timer) instead
			local time = PartCtrl_ProcessedPCFs[pcf][name].default_time or 1
			if time < 0 then
				//-1 sets no loop by default
				p:SetLoopMode(0)
			else
				p:SetLoopMode(2)
				p:SetLoopDelay(time)
			end
		end
		p:SetLoopSafety(false)
		p:SetNumpad(0)
		p:SetNumpadToggle(true)
		p:SetNumpadStartOn(true)
		p.ParticleInfo = tab
		p:Spawn()

		for k, v in pairs (grips) do
			constraint.PartCtrl_Ent(p, v, k, parent == v, ply)
		end

		if IsValid(ply) then
			gamemode.Call("PlayerSpawnedParticle", ply, name, pcf, p)
		end

		undo.Create("PartCtrl")
			undo.SetPlayer(ply)
			undo.AddEntity(p)
		undo.Finish("Particle Effect (" .. tostring(name) .. " (" .. tostring(pcf) .. "))")
		ply:AddCleanup("partctrl", p)

	end

end

concommand.Add("partctrl_spawnparticle", function(ply, cmd, args)
	//Note: this callback function runs on the SERVER only
	PartCtrl_SpawnParticle(ply, args[1], args[2])
end, nil, "Spawns a particle effect; first arg is effect name, second arg is pcf file path starting with particles/ and ending with .pcf")

if SERVER then

	//MsgN("in ent_partctrl, GM = ", GM, ", GAMEMODE = ", GAMEMODE)

	//Add hooks for these, in case someone wants to selectively prevent players from spawning particles

	function GAMEMODE:PlayerSpawnParticle(ply, name, pcf)

		local function LimitReachedProcess()
			if !IsValid(ply) then return true end
			return ply:CheckLimit("partctrl")
		end
		return LimitReachedProcess()

	end

	function GAMEMODE:PlayerSpawnedParticle(ply, name, pcf, ent)

		ply:AddCount("partctrl", ent)

	end

end




//Function override for SetColor: set all color vector cpoints to the color value, so players can recolor them with the color tool instead of the edit window

if SERVER then
	local meta = FindMetaTable("Entity")

	local old_SetColor = meta.SetColor
	if old_SetColor then

		function meta:SetColor(color, ...)

			if isentity(self) and IsValid(self) and self:GetClass() == "ent_partctrl_grip" then
				local tab = constraint.FindConstraint(self, "PartCtrl_Ent")
				if istable(tab) then
					local ent = tab.Ent1
					if IsValid(ent) and ent:GetClass() == "ent_partctrl" and istable(ent.ParticleInfo) and istable(PartCtrl_ProcessedPCFs) then
						if !istable(PartCtrl_ProcessedPCFs[ent:GetPCF()]) or !istable(PartCtrl_ProcessedPCFs[ent:GetPCF()][ent:GetParticleName()]) then return end
						local refreshtable = false
						for k, v in pairs (ent.ParticleInfo) do
							if v.mode == PARTCTRL_CPOINT_MODE_VECTOR then
								local tab = PartCtrl_ProcessedPCFs[ent:GetPCF()][ent:GetParticleName()]["cpoints"][k]["vector"][v.which]
								if istable(tab) and tab.pattrib == "Color" then
									local vec = Vector()
									vec.x = math.Remap(color.r/255, tab.outMin.x, tab.outMax.x, tab.inMin.x, tab.inMax.x)
									vec.y = math.Remap(color.g/255, tab.outMin.y, tab.outMax.y, tab.inMin.y, tab.inMax.y)
									vec.z = math.Remap(color.b/255, tab.outMin.z, tab.outMax.z, tab.inMin.z, tab.inMax.z)
									ent.ParticleInfo[k].val = vec
									refreshtable = true
								end
							end
						end
						if refreshtable then
							//Tell clients to retrieve the updated info table
							net.Start("PartCtrl_InfoTableUpdate_SendToCl")
								net.WriteEntity(ent)
							net.Broadcast()
						end
					end
				end
			else //don't actually run the normal SetColor on grips, it could cause unwanted behavior when loading the color from dupes
				return old_SetColor(self, color, ...)
			end
			
		end

	end

end




MsgN("partctrl test: running entity code")

//See PartCtrl_ReadAndProcessPCFs comments in partctrl_autorun.lua

if !PartCtrl_ReadAndProcessPCFs_StartupHasRun then
	PartCtrl_ReadAndProcessPCFs()
end

timer.Simple(0, function()
	MsgN("partctrl test: running entity code on timer")
	PartCtrl_ReadAndProcessPCFs_StartupIsOver = true
end)