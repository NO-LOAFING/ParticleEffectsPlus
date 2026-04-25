AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.PrintName			= "Particle Effects+ Entity"

ENT.Spawnable			= false
//ENT.RenderGroup		= RENDERGROUP_NONE

ENT.PEPlus_Ent			= true //lets us detect if an ent is an ent_peplus without having to compare strings with GetClass

if CLIENT then
	language.Add("Undone_PEPlus", "Undone Particle Effect")
    	language.Add("Cleanup_peplus", "Particle Effects")
   	language.Add("Cleaned_peplus", "Cleaned up all Particle Effects")
	language.Add("SBoxLimit_peplus", "You've hit the Particle Effect limit!")
   	language.Add("max_peplus", "Max Particle Effects:")
end




function ENT:SetupDataTables()

	self:NetworkVar("String", 0, "ParticleName")
	self:NetworkVar("String", 1, "PCF")
	self:NetworkVar("String", 2, "Path")

	self:NetworkVar("Int", 0, "LoopMode")
	self:NetworkVar("Float", 0, "LoopDelay")
	self:NetworkVar("Bool", 0, "LoopSafety")

	self:NetworkVar("Int", 1, "Numpad")
	self:NetworkVar("Bool", 1, "NumpadToggle")
	self:NetworkVar("Bool", 2, "NumpadStartOn")
	self:NetworkVar("Bool", 3, "NumpadState")
	self:NetworkVar("Int", 2, "NumpadMode")

	self:NetworkVar("Float", 1, "PauseTime")

	self:NetworkVar("Entity", 0, "SpecialEffectParent")
	self:NetworkVarNotify("SpecialEffectParent", self.OnSpecialEffectParentChanged)

end




function ENT:Initialize()

	//self:SetNoDraw(true)
	self:SetModel("models/props_junk/watermelon01.mdl") //dummy model to prevent addons that look for the error model from affecting this entity, should this be something smaller?
	self:DrawShadow(false) //make sure the ent's shadow doesn't render, just in case RENDERGROUP_NONE/SetNoDraw don't work and we have to rely on the blank draw function
	self:SetCollisionBounds(vector_origin,vector_origin) //stop this ent from bloating up duplicator bounds

	local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
	local name = self:GetParticleName()
	if !istable(PEPlus_ProcessedPCFs[pcf]) then
		if self:GetPath() != "" then
			MsgN(self, ": invalid pcf \"", self:GetPCF(), "\" from game \"", self:GetPath(), "\"" )
		else
			MsgN(self, ": invalid pcf \"", self:GetPCF(), "\"")
		end
		//if SERVER then self:Remove() end //not a great solution; causes our grip ents to delete themselves
		return 
	elseif !istable(PEPlus_ProcessedPCFs[pcf][name]) then
		if self:GetPath() != "" then
			MsgN(self, ": invalid effect \"", name, "\" in pcf \"", self:GetPCF(), "\" from game \"", self:GetPath(), "\"" )
		else
			MsgN(self, ": invalid effect \"", name, "\" in pcf \"", self:GetPCF(), "\"")
		end
		//if SERVER then self:Remove() end
		return
	end
	//TODO: should we handle this better? if we load a dupe or something with an effect that's no longer valid, it just spawns an orphaned ent_peplus that doesn't do anything, but is that
	//what we want? what if it's not valid because the player just doesn't have a game or addon loaded, and they decide to save it again and then load it again with the game reenabled?

	self.utilfx = PEPlus_ProcessedPCFs[pcf][name].utilfx

	if SERVER then
		if !self.ParticleInfo then 
			MsgN("ERROR: ", self, " (", name, ", ", PEPlus_GetDataPCFNiceName(pcf), ") doesn't have an info table! Something went wrong!") 
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
		self.NumDown = numpad.OnDown(ply, key, "PEPlus_Numpad", self, true)
		self.NumUp = numpad.OnUp(ply, key, "PEPlus_Numpad", self, false)
	end

	if CLIENT then
		self:OnSpecialEffectParentChanged(nil, nil, self:GetSpecialEffectParent()) //nwvar callbacks don't run when the value is set immediately upon spawning, so run it manually

		if !self.utilfx then
			PEPlus_AddParticles(pcf, name) //crash prevention
		end

		//For PostDrawTranslucentRenderables hook
		AllPEPlusEnts = AllPEPlusEnts or {}
		AllPEPlusEnts[self] = true
		self.LastDrawn = 0
	end

end




local cv_max
local cv_distancescalar_helpers
if CLIENT then 
	cv_max = GetConVar("sv_peplus_particlesperent")
	cv_distancescalar_helpers = GetConVar("cl_peplus_distancescalar_helpers")
end

function ENT:Think()

	if CLIENT then

		local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
		local name = self:GetParticleName()
		if !istable(PEPlus_ProcessedPCFs[pcf]) or !istable(PEPlus_ProcessedPCFs[pcf][name]) then return end
		local ptab = PEPlus_ProcessedPCFs[pcf][name]
		local time = CurTime()
		self.cpoint_posang = {} //Reset this table every think

		//TODO: see if we need to copy the demo fix that ragdoll resizer/animpropoverhaul/advbone have for their info tables

		//If we don't have an info table, or need to update it, then request it from the server
		if !self.ParticleInfo_Received then
			net.Start("PEPlus_InfoTable_GetFromSv", true)
				net.WriteEntity(self)
			net.SendToServer()

			self:NextThink(time)
			return
		end

		//If a particle effect and its attached entities are spawned outside the client's PVS, only the first cpoint's entity is guaranteed to be
		//transmitted to the client, while any other cpoints' ents might still be NULL until the client moves into their PVS. In these cases,
		//keep checking until we can find them - if the entity actually gets removed, then this table should get updated by the server anyway.
		if self.ParticleInfo_InvalidEnts then
			local found = false
			for k, v in pairs (self.ParticleInfo_InvalidEnts) do
				if !IsValid(self.ParticleInfo[k].ent) then
					local ent = Entity(v)
					if IsValid(ent) then
						self.ParticleInfo[k].ent = ent
						self.ParticleInfo_InvalidEnts[k] = nil
						found = true
					end
				else
					self.ParticleInfo_InvalidEnts[k] = nil
					found = true
				end
			end
			if found then
				if table.Count(self.ParticleInfo_InvalidEnts) == 0 then self.ParticleInfo_InvalidEnts = nil end
				self:BeginNewParticle() //fix up the particle now that we have a valid ent for it to use
			end
		end


		//Handle pausing/unpausing the effect
		local ispaused = false
		if self.ParticleStartTime then
			local pausetime = self:GetPauseTime()
			ispaused = self.PauseOverride or (pausetime >= 0 and pausetime <= (time - self.ParticleStartTime))
			if ispaused then
				//if not paused, but should be, then pause it
				local didpause
				if IsValid(self.particle) and self.particle:GetShouldSimulate() then
					didpause = true
					self.particle:SetShouldSimulate(false)
				end
				for _, v in pairs (self.OldParticles) do
					if IsValid(v) and v:GetShouldSimulate() then
						didpause = true
						v:SetShouldSimulate(false)
					end
				end
				if didpause then
					//MsgN("pausing")
					self.ParticlePauseTime = time
				end
			else
				//if paused, but shouldn't be, then unpause it
				local didunpause
				if IsValid(self.particle) and !self.particle:GetShouldSimulate() then
					didunpause = true
					self.particle:SetShouldSimulate(true)
				end
				for _, v in pairs (self.OldParticles) do
					if IsValid(v) and !v:GetShouldSimulate() then 
						didunpause = true
						v:SetShouldSimulate(true)
					end
				end
				if didunpause then
					//MsgN("unpausing")
					if self.ParticlePauseTime != nil then
						//change the particlestarttime to compensate for the time we spent paused, so that if we pause it 
						//again afterward, the effect's lifetime doesn't include the time it spent paused prior to that
						local diff = (time - self.ParticlePauseTime)
						self.ParticleStartTime = self.ParticleStartTime + diff
						//do the same for loop time
						if self.LastLoop then
							self.LastLoop = self.LastLoop + diff
						end
						self.ParticlePauseTime = nil
					end
				end
			end
		end

		if !ispaused then self:UpdateCPoints() end


		//Do renderbounds
		local extra = Vector(20,20,20) //add arrow length to bounds so it doesn't get cut off at weird angles
		if !self.utilfx then
			//Cache which cpoint the renderbounds are relative to, so we don't have to keep retrieving this
			if self.ParticleInfo_LastCPoint == nil then
				for k, v in pairs (self.ParticleInfo) do
					if self.AdvBoneCPointsToUpdate and self.AdvBoneCPointsToUpdate[k] then continue end //bounds are actually relative to the last position cpoint that *isn't* using PATTACH_CUSTOMORIGIN; if all pos cpoints are using that, then they're relative to worldspace
					if ptab.cpoints[k].mode == PEPLUS_CPOINT_MODE_POSITION then
						self.ParticleInfo_LastCPoint = k
						if self.ParticleInfo_FirstPos == nil then
							self.ParticleInfo_FirstPos = k
						end
					elseif ptab.cpoints[k].mode == PEPLUS_CPOINT_MODE_POSITION_COMBINE then
						self.ParticleInfo_LastCPoint = self.ParticleInfo_FirstPos or self.ParticleInfo_LastCPoint
					end
				end
			end
			//Set our renderbounds to the combined renderbounds of our current particle and all our old particles, so that we
			//run our Draw func whenever any part of the particles are visible; these are relative to the last position cpoint
			local pos
			local k = self.ParticleInfo_LastCPoint
			if k then
				if ptab.cpoints[k].mode == PEPLUS_CPOINT_MODE_POSITION_COMBINE then
					k = self.ParticleInfo_FirstPos
				end
				if ptab.cpoints[k].mode == PEPLUS_CPOINT_MODE_POSITION then
					local p = self:GetCPointPos(k)
					if p then pos = p.pos end
				end
			end
			local mins, maxs
			local function AddParticleRenderBounds(part)
				if IsValid(part) and part.GetRenderBounds then
					local mins2, maxs2 = part:GetRenderBounds()
					if pos then
						mins2 = mins2 + pos
						maxs2 = maxs2 + pos
					end
					if !mins then
						mins = mins2
						maxs = maxs2
					else
						mins = Vector(math.min(mins.x,mins2.x), math.min(mins.y,mins2.y), math.min(mins.z,mins2.z))
						maxs = Vector(math.max(maxs.x,maxs2.x), math.max(maxs.y,maxs2.y), math.max(maxs.z,maxs2.z))
					end
				end
			end
			AddParticleRenderBounds(self.particle)
			for k, v in pairs (self.OldParticles) do
				AddParticleRenderBounds(v)
			end
			if mins and maxs then
				if ispaused then
					//When the effect is paused, its renderbounds no longer update to contain its cpoint positions, which means 
					//helpers can stop rendering if we move them so that the effect is off-screen. Fix this by adding cpoint 
					//positions to the renderbounds if paused.
					for k2, v2 in pairs (self.ParticleInfo) do
						local p = self:GetCPointPos(k2)
						if p then
							mins = Vector(math.min(mins.x,p.pos.x), math.min(mins.y,p.pos.y), math.min(mins.z,p.pos.z))
							maxs = Vector(math.max(maxs.x,p.pos.x), math.max(maxs.y,p.pos.y), math.max(maxs.z,p.pos.z))
						end
					end
				end
				//debugoverlay.Box(Vector(0,0,0), mins - extra, maxs + extra, 0.1, Color(255,255,0,0))
				self:SetRenderBoundsWS(mins, maxs, extra)
				self._wsmins = mins
				self._wsmaxs = maxs
			end
		else
			//For utilfx, just make our renderbounds a box around all the cpoints, so that helpers render when any cpoint is on-screen
			local mins, maxs
			for k, v in pairs (self.ParticleInfo) do
				local p = self:GetCPointPos(k)
				if p then
					if !mins then
						mins = p.pos
						maxs = p.pos
					else
						mins = Vector(math.min(mins.x,p.pos.x), math.min(mins.y,p.pos.y), math.min(mins.z,p.pos.z))
						maxs = Vector(math.max(maxs.x,p.pos.x), math.max(maxs.y,p.pos.y), math.max(maxs.z,p.pos.z))
					end
				end
			end
			if mins then
				self:SetRenderBoundsWS(mins, maxs, extra)
				//self._wsmins = mins
				//self._wsmaxs = maxs
			end
		end


		//Handle looping
		local sfxpar = self:GetSpecialEffectParent()
		if !IsValid(sfxpar) or !sfxpar.DisableChildAutoplay then
			local numpadisdisabling = self:GetNumpadState()
			if !self:GetNumpadStartOn() then
				numpadisdisabling = !numpadisdisabling
			end
			if !numpadisdisabling then
				if !ispaused then
					local loop = self:GetLoopMode()
					if self.particle or self.utilfx then 
						if self.particle and !(self.particle.IsValid and self.particle:IsValid()) then
							//Particle is non-nil but invalid; that probably means that it ran to completion and expired, so make a new particle
							if PEPlus_AddParticles_CrashCheck[pcf] and PEPlus_AddParticles_CrashCheck[pcf][self.particle] then
								//Remove now-invalid particles from the crashcheck list
								PEPlus_AddParticles_CrashCheck[pcf][self.particle] = nil
							end
							
							if self.particle == peplus_wait then
								//MsgN(time, ": waiting")
								self.ParticleStartTime = nil //effect was either disabled and enabled, or clobbered by crashcheck, so reset the timer
								self.ParticlePauseTime = nil
								self:StartParticle()
							else
								if loop == 1 then //loop mode 1: repeat X seconds after ending
									if self.LastLoop == nil then
										self.LastLoop = time
										//MsgN(time, ": set last loop to ", self.LastLoop)
									end
									if (self.LastLoop + self:GetLoopDelay()) <= time then
										//MsgN(time, ": did loop 1")
										self.ParticleStartTime = nil //loop mode 1 resets the timer with every new effect; otherwise, don't reset the timer unless we restart the effect
										self.ParticlePauseTime = nil
										self:StartParticle()
										self.LastLoop = nil
									end
								end
							end
						end
						if self.utilfx_waiting then
							self:StartParticle()
							self.utilfx_waiting = nil
						end
						if loop == 2 then //loop mode 2: repeat every X seconds
							//TODO: do we need to handle peplus_wait differently? tested, doesn't seem so
							
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
				end
			else
				if self.particle and self.particle != peplus_wait then
					if self.particle.IsValid and self.particle:IsValid() then
						//Stop any existing particles and throw them into the OldParticles table to get cleaned up
						self.particle:StopEmission()
						table.insert(self.OldParticles, self.particle)
					end
					//Create a new particle as soon as we're no longer disabled
					self.particle = peplus_wait
				end
				self.LastLoop = nil //reset loop time, so it restarts the timer as soon as we reenable
				if self.utilfx then self.utilfx_waiting = true end //tell utilfx to replay when reenabled as well, since they don't have a self.particle to check for
			end
		end

		//Clean up old particle list
		for k, v in pairs (self.OldParticles) do
			if v and !(v.IsValid and v:IsValid()) then
				//MsgN("old particle ", k, " ", v, " expired")
				//Particle is non-nil but invalid; that probably means that it ran to completion and expired
				if PEPlus_AddParticles_CrashCheck[pcf] and PEPlus_AddParticles_CrashCheck[pcf][v] then
					//Remove now-invalid particles from the crashcheck list
					PEPlus_AddParticles_CrashCheck[pcf][v] = nil
				end
				table.remove(self.OldParticles, k)
			end
		end
		//If there are too many old particles, remove the oldest one
		local max = cv_max:GetInt() - 1
		if self.MaxOldParticlesOverride then
			max = self.MaxOldParticlesOverride //used by special fx
		elseif self:GetLoopSafety() then 
			max = 0
		end
		while #self.OldParticles > max do
			local v = self.OldParticles[1]
			//MsgN(#self.OldParticles, " is too many particles, removing oldest ", v)
			if IsValid(v) then v:StopEmissionAndDestroyImmediately() end
			--[[if PEPlus_AddParticles_CrashCheck[pcf] and PEPlus_AddParticles_CrashCheck[pcf][v] then
				//Remove now-invalid particles from the crashcheck list
				PEPlus_AddParticles_CrashCheck[pcf][v] = nil
			end]] //this doesn't work, we can't always assume StopEmissionAndDestroyImmediately actually cleared the particle immediately
			table.remove(self.OldParticles, 1)
		end

		//If loop mode is set to minimum, ensure we run next frame (for utilfx like CommandPointer that need to draw a sprite every frame to render correctly)
		if self:GetLoopDelay() == 0 and self:GetLoopMode() == 2 then
			self:NextThink(time)
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




function ENT:OnSpecialEffectParentChanged(_,old,new)

	if old != new then
		//MsgN(self, " sfx parent changed from ", old, " to ", new)
		if IsValid(old) then
			if CLIENT and old.SpecialEffectChildren then
				old.SpecialEffectChildren[self] = nil
				self.MaxOldParticlesOverride = nil
				self.PauseOverride = nil
			end
			//Restart the effect
			if old.SpecialEffectRefresh then old:SpecialEffectRefresh() end
		end
		if IsValid(new) then
			if CLIENT then
				new.SpecialEffectChildren = new.SpecialEffectChildren or {}
				new.SpecialEffectChildren[self] = true
			end
			//Restart the effect
			if new.SpecialEffectRefresh then new:SpecialEffectRefresh() end
		end
	end

end




//Convenience func for cpoint locations
function ENT:GetCPointPos(k)

	if CLIENT and self.cpoint_posang[k] then return self.cpoint_posang[k] end //server doesn't call this often enough to be worth caching and uncaching

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
			pos = ent:GetPos()
		end
		local res = {ang = ang, pos = pos}
		if CLIENT then self.cpoint_posang[k] = res end
		return res
	end

end




if CLIENT then

	local PEPlus_IsSkyboxDrawing = false

	hook.Add("PreDrawSkyBox", "PEPlus_IsSkyboxDrawing_Pre", function()
		PEPlus_IsSkyboxDrawing = true
	end)

	hook.Add("PostDrawSkyBox", "PEPlus_IsSkyboxDrawing_Post", function()
		PEPlus_IsSkyboxDrawing = false
	end)

	//make these global so that special fx can use them too
	//peplus_colortext = Color(130,255,31,255) //matches effect grip
	peplus_colortext = Color(31,201,255,255) //matches arrow texture
	peplus_colorborder = Color(255,255,255,255)
	surface.CreateFont( "PEPlus_3D2DFont", {
		font = "Arial",
		size = 100,
		weight = 5000,
	} )
	peplus_arrowmat = Material("sprites/peplus_arrow")

	function ENT:Draw()

		//Don't draw our particles in the 3D skybox if their renderbounds are clipping into it but we're not actually in there
		//(common problem for ents with big renderbounds on gm_flatgrass, where the 3D skybox area is right under the floor)
		if PEPlus_IsSkyboxDrawing and !self:GetNWBool("IsInSkybox") then
			if IsValid(self.particle) and self.particle.SetShouldDraw then
				self.particle:SetShouldDraw(false)
			end
			if self.OldParticles then
				for k, v in pairs (self.OldParticles) do
					if IsValid(v) then
						v:SetShouldDraw(false)
					end
				end
			end
		else
			if IsValid(self.particle) and self.particle.SetShouldDraw then
				self.particle:SetShouldDraw(true)
			end
			if self.OldParticles then
				for k, v in pairs (self.OldParticles) do
					if IsValid(v) then
						v:SetShouldDraw(true)
					end
				end
			end
		end

		//Instead of drawing the cpoint helpers ourselves, we tell our PostDrawTranslucentRenderables hook to do it, so that it always renders above particle effects
		self.LastDrawn = CurTime()

	end

	local icon_loading = Material("vgui/loading-rotate.vmt")
	local mat_plane = Material("sprites/peplus_plane_solid.vmt") //Material("sprites/peplus_plane.vmt") //this looks nicer but it could be mistaken for a legitimate part of an effect
	function ENT:DrawCPointHelpers(k)

		if self.ParticleInfo and !IsValid(self:GetSpecialEffectParent()) then
			local window = IsValid(self.PEPlusWindow) and g_ContextMenu:IsVisible()
			local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
			local ptab = PEPlus_ProcessedPCFs[pcf][self:GetParticleName()]

			local view = LocalPlayer():GetViewEntity()
			local camang = nil
			if view:IsPlayer() then
				camang = view:EyeAngles()
			else
				camang = view:GetAngles()
			end
			camang:RotateAroundAxis(camang:Up(), -90)
			camang:RotateAroundAxis(camang:Forward(), 90)

			local p = self:GetCPointPos(k)
			if istable(p) then
				if window or self.ParticleInfo[k].ent.PEPlus_Grip then //hide helpers when they're attached to other ents unless the window is open
					//Draw plane helpers
					if ptab.cpoint_planes and ptab.cpoint_planes[k] then
						render.SetMaterial(mat_plane)
						for _, tab in pairs (ptab.cpoint_planes[k]) do
							local pos2 = tab.pos
							local norm = tab.normal
							if !tab.pos_global then
								if !tab.pos_fixed_offset then
									pos2, _ = LocalToWorld(tab.pos, Angle(), p.pos, p.ang)
								else
									pos2 = tab.pos + p.pos
								end
							end
							if !tab.normal_global then
								norm, _ = LocalToWorld(tab.normal, Angle(), Vector(), p.ang)
							end

							//draw at partial opacity through walls, so you can see where it intersects with the world
							render.DrawQuadEasy(pos2, norm, 50, 50, Color(0,255,0,(128/3)*2))
							render.DrawQuadEasy(pos2, -norm, 50, 50, Color(255,0,0,(128/3)*2))
							cam.IgnoreZ(true)
							render.DrawQuadEasy(pos2, norm, 50, 50, Color(0,255,0,128/3))
							render.DrawQuadEasy(pos2, -norm, 50, 50, Color(255,0,0,128/3))
							cam.IgnoreZ(false)

						end
					end

					//Draw distance scalar helpers (spheres showing min/max distance)
					//These are useful for debugging, but impossible to make look good, so gate them behind a convar
					if ptab.distance_scalars and ptab.distance_scalars[k] and cv_distancescalar_helpers:GetInt() > 0 then
						for _, tab in pairs (ptab.distance_scalars[k]) do
							//if tab.do_helpers then
								if tab.outMax > tab.outMin then
									//decreases with proximity
									render.DrawWireframeSphere(p.pos, tab.inMax, 8, 8, Color(255,0,0), true)
									if tab.inMax != tab.inMin then
										render.DrawWireframeSphere(p.pos, tab.inMin, 8, 8, Color(0,255,0), true)
									end
								else
									//increases with proximity
									render.DrawWireframeSphere(p.pos, tab.inMin, 8, 8, Color(0,255,0), true)
									if tab.inMax != tab.inMin then
										render.DrawWireframeSphere(p.pos, tab.inMax, 8, 8, Color(255,0,0), true)
									end
								end
							//end
						end
					end
				
					//Draw cpoint helpers (arrow showing cpoint orientation, number showing cpoint id)
					render.SetMaterial(peplus_arrowmat)
					render.DrawBeam(p.pos + (p.ang:Forward() * -3.01), p.pos + (p.ang:Forward() * (20-3.01)), 20, 1, 0, color_white)

					cam.IgnoreZ(true)
					cam.Start3D2D(p.pos, camang, 0.125)
						draw.SimpleTextOutlined(k,"PEPlus_3D2DFont",0,-50,peplus_colortext,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM,3,peplus_colorborder)
					cam.End3D2D()
					cam.IgnoreZ(false)
				end
				//If particle is being throttled by crash prevention, draw loading icon
				if PEPlus_AddParticles_CrashCheck_ThrottledPCFs[pcf] and (!self.particle or !(self.particle.IsValid and self.particle:IsValid())) then
					//This has to use 3D2D again instead of a simple render.DrawSprite, 
					//just because DrawSprite doesn't seem to have a way to rotate the image
					cam.IgnoreZ(true)
					cam.Start3D2D(p.pos, camang, 1)
						surface.SetDrawColor(255,255,255,255)
						surface.SetMaterial(icon_loading)
						surface.DrawTexturedRectRotated(0, 0, 16, 16, CurTime() * 300 % 360)
					cam.End3D2D()
					cam.IgnoreZ(false)
				end
			end

			//Draw particle render bounds if control window is open
			//TODO: this looks bad for fx with axis controls, do we really need to port over the whole particle2 thing from the spawnicon code?
			//if window then
			//	render.DrawWireframeBox(vector_origin, angle_zero, self._wsmins, self._wsmaxs, color_white, true)
			//end
		end

	end

	hook.Add("PostDrawTranslucentRenderables", "PEPlus_DrawParticleHelpers", function(depth, skybox)

		if !skybox then
			if GetConVarNumber("cl_draweffectrings") == 0 then return end

			//Don't draw the grip if there's no chance of us picking it up
			local ply = LocalPlayer()
			local vpos = MainEyePos and MainEyePos() or EyePos()
			local wep = ply:GetActiveWeapon()
			if !IsValid(wep) then return end
		
			local weapon_name = wep:GetClass()
		
			if weapon_name != "weapon_physgun" and weapon_name != "weapon_physcannon" and weapon_name != "gmod_tool" then
				return
			end

			local time = CurTime()
			local todraw = {}

			if istable(AllPEPlusGripEnts) then
				//Queue grip point rings			
				for self, _ in pairs (AllPEPlusGripEnts) do
					if self.LastDrawn == time then
						local pos = self:GetPos()
						table.insert(todraw, {
							dist = pos:DistToSqr(vpos),
							grip = {pos = pos, ent = self}
						})
					end
				end
			end

			if istable(AllPEPlusEnts) then
				//Queue cpoint helpers
				for self, _ in pairs (AllPEPlusEnts) do
					if self.LastDrawn == time then
						if !self.PEPlus_SpecialEffect then
							if self.ParticleInfo then
								local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
								local ptab = PEPlus_ProcessedPCFs[pcf][self:GetParticleName()]
								for k, v in pairs (self.ParticleInfo) do
									if ptab.cpoints[k] and ptab.cpoints[k].mode == PEPLUS_CPOINT_MODE_POSITION then
										local p = self:GetCPointPos(k)
										if istable(p) then
											table.insert(todraw, {
												dist = p.pos:DistToSqr(vpos) - 0.0001, //draw on top of the grip for the same cpoint
												cpoint = {k = k, ent = self}
											})
										end
									end
								end
							end
						else
							local p = self:GetCPointPos()
							if istable(p) then
								table.insert(todraw, {
									dist = p.pos:DistToSqr(vpos) - 0.0001, //draw on top of the grip for the same cpoint
									cpoint = {ent = self}
								})
							end
						end
					end
				end
			end

			//Check the particle attacher tool, and draw a different sprite for the currently selected grip
			local sel
			if wep:GetClass() == "gmod_tool" and wep.Mode == "peplus_attacher" then sel = wep:GetToolObject(sel) end
			if sel then sel = sel.SelectedGripPoint end

			//Draw them in order of distance from the camera, so closer ones render on top of farther ones
			table.SortByMember(todraw, "dist")
			for _, v in ipairs (todraw) do
				if v.grip then
					v.grip.ent:DrawGripSprite(v.grip.pos, sel == v.grip.ent)
				elseif v.cpoint then
					v.cpoint.ent:DrawCPointHelpers(v.cpoint.k)
				end
			end
		end
	end)




	function ENT:RemoveParticle()

		//local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
		if self.particle and self.particle.IsValid and self.particle:IsValid() then
			self.particle:StopEmissionAndDestroyImmediately()
			--[[if PEPlus_AddParticles_CrashCheck[pcf] and PEPlus_AddParticles_CrashCheck[pcf][self.particle] then
				//Remove now-invalid particles from the crashcheck list
				PEPlus_AddParticles_CrashCheck[pcf][self.particle] = nil
			end]] //this doesn't work, we can't always assume StopEmissionAndDestroyImmediately actually cleared the particle immediately
		end
		//Clean up old particles
		if istable(self.OldParticles) then
			for k, v in pairs (self.OldParticles) do
				if v and v.IsValid and v:IsValid() then
					v:StopEmissionAndDestroyImmediately()
					--[[if PEPlus_AddParticles_CrashCheck[pcf] and PEPlus_AddParticles_CrashCheck[pcf][v] then
						//Remove now-invalid particles from the crashcheck list
						PEPlus_AddParticles_CrashCheck[pcf][v] = nil
					end]] //this doesn't work, we can't always assume StopEmissionAndDestroyImmediately actually cleared the particle immediately
				end
			end
		end
		self.OldParticles = nil

	end

	function ENT:BeginNewParticle()

		self:RemoveParticle()
		local sfxpar = self:GetSpecialEffectParent()
		if !IsValid(sfxpar) or !sfxpar.DisableChildAutoplay then
			self.ParticleStartTime = nil
			self.ParticlePauseTime = nil
			self:StartParticle()
		end
		local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
		if !self.utilfx and !self.particle and PEPlus_AddParticles_CrashCheck_ThrottledPCFs[pcf] then
			self.particle = peplus_wait	//ordinarily, ENT:Think won't try to recreate the particle if self.particle is nil, which is what we want. however, if crash prevention
		end					//prevented us from creating our effect here, then make this value non-nil so ENT:Think will try to create it once crash prevention is over.
		//Reset loop-related vars
		self.OldParticles = {}
		self.LastLoop = nil

	end

	function ENT:UpdateCPoints()

		//Update the positions of control points that aren't handled automatically by PATTACH_ enums

		//Update axis controls that are rotated relative to another cpoint (used for velocity sliders, 
		//which we want to go forward/left/etc. relative to the direction the main position cpoint is facing)
		if self.RelativeCPointsToUpdate then
			for k, v in pairs (self.RelativeCPointsToUpdate) do
				local p = self:GetCPointPos(v)
				if p then
					//update the cpoint on both old particles and new particles
					if IsValid(self.particle) and self.particle.SetControlPoint then
						self.particle:SetControlPoint(k, LocalToWorld(self.ParticleInfo[k].val, angle_zero, vector_origin, p.ang))
					end
					if self.OldParticles then
						for _, part in pairs (self.OldParticles) do
							if IsValid(part) and part.SetControlPoint then
								part:SetControlPoint(k, LocalToWorld(self.ParticleInfo[k].val, angle_zero, vector_origin, p.ang))
							end
						end
					end
				end
			end
		end

		//Update position controls that belong to a particle grip point attached to a model with Advanced Bonemerge
		if self.AdvBoneCPointsToUpdate then
			for k, tabk in pairs (self.AdvBoneCPointsToUpdate) do
				local ent = self.ParticleInfo[tabk].ent
				if IsValid(ent) then
					//if the grip point is parented, then its position will be out of date
					//unless we force it to update again right now
					if IsValid(ent:GetParent()) and IsValid(ent:GetParent():GetParent()) then ent:Think() end
					//update the cpoint on both old particles and new particles
					if IsValid(self.particle) and self.particle.SetControlPoint then
						self.particle:SetControlPoint(k, ent:GetPos())
						self.particle:SetControlPointOrientation(k, ent:GetAngles())
					end
					if self.OldParticles then
						for _, part in pairs (self.OldParticles) do
							if IsValid(part) and part.SetControlPoint then
								part:SetControlPoint(k, ent:GetPos())
								part:SetControlPointOrientation(k, ent:GetAngles())
							end
						end
					end
				end
			end
		end

	end

	hook.Add("EntityEmitSound", "PEPlus_UtilFxInterceptSound", function(data)
		if PEPlus_InterceptSound then return false end
	end)

	function ENT:StartParticle()

		local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
		local name = self:GetParticleName()
		if !self.ParticleInfo or pcf == "" then return end //pcf can temporarily return a bad result during a clientside "full update", bail if that happens
		local ptab = PEPlus_ProcessedPCFs[pcf][name]

		//If doing utilfx, then do that and stop here
		if self.utilfx then
			//Make sure we don't run DoEffect if we have an invalid entity, that'll cause errors that we can't really detect from here
			local bad = false
			for k, v in pairs (self.ParticleInfo) do
				if v.ent != nil and !IsValid(v.ent) then
					bad = true
					break
				end
			end
			if bad then return end
			local ed = EffectData()
			if ptab.utilfx_doeffect(self, ed) then
				//If the normal is pointed exactly up or down, it results in bad effects (see AR2Explosion), so tilt it just a bit in those cases
				local norm = ed:GetNormal()
				if math.Round(norm.x, 6) == 0 and math.Round(norm.y, 6) == 0 then
					norm.x = 0.00001
					ed:SetNormal(norm)
				end
				util.Effect(name, ed, true)
				PEPlus_InterceptSound = nil //this is set to true by some DoEffect funcs, to suppress sounds played during the effect
			end
			return
		end

		if PEPlus_AddParticles_CrashCheck_ThrottledPCFs[pcf] then return end
		if !self.precached then
			PrecacheParticleSystem(name)
			self.precached = true
		end

		self.RelativeCPointsToUpdate = nil
		self.AdvBoneCPointsToUpdate = nil

		//Create our particle system and attach it to our first position cpoint
		local firstcpoint = nil
		local function DoFirstCPoint(k)
			if istable(self.ParticleInfo[k]) and ptab.cpoints[k].mode == PEPLUS_CPOINT_MODE_POSITION and IsValid(self.ParticleInfo[k].ent) then
				local ent = self.ParticleInfo[k].ent
				local attach
				local pattach
				if (ent.GetPEPlus_MergedGrip and ent:GetPEPlus_MergedGrip()) then
					//This cpoint's ent is a particle grip point that was attached to a model with Advanced Bonemerge.
					//We want the cpoint to follow the attached grip, but also still associate model-covering fx with
					//the parent model it was attached to. To accomplish this, we set ent to the parent model, and 
					//then continuously update the cpoint to the grip's pos/ang in self:UpdateCPoints().
					self.AdvBoneCPointsToUpdate = self.AdvBoneCPointsToUpdate or {}
					self.AdvBoneCPointsToUpdate[k] = k
					ent = ent:GetParent()
					if !IsValid(ent) then return end
					pattach = PATTACH_CUSTOMORIGIN
				else
					attach = self.ParticleInfo[k].attach
					if attach == 0 then
						attach = nil
						pattach = PATTACH_ABSORIGIN_FOLLOW
					else
						pattach = PATTACH_POINT_FOLLOW
					end
				end
				if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
				self.particle = CreateParticleSystem(ent, name, pattach, attach, nil)
				if pattach == PATTACH_CUSTOMORIGIN and self.particle and self.particle:IsValid() then 
					//For merged grip fx; if ent is parented, then PATTACH_ABSORIGIN (and PATTACH_POINT) gets overwritten 
					//to act like the _FOLLOW versions anyway for some reason, which makes UpdateCPoints not work at all. (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/particle_property.cpp#L544-L547)
					//Instead, use PATTACH_CUSTOMORIGIN, and then associate the cpoint with the ent manually afterward 
					//to make model-covering fx still work properly. (we got lucky that this happens to work)
					self.particle:SetControlPointEntity(k, ent)
				end
				//if self.particle and self.particle:IsValid() then
				//	self.particle:SetIsViewModelEffect(false) //thought this would fix the position issues on viewmodel effects, but it doesn't change anything
				//end
				return true
			end
		end
		for k, v in SortedPairs (self.ParticleInfo) do
			if ptab.cpoints[k].mode == PEPLUS_CPOINT_MODE_POSITION then
				firstcpoint = k
				break 
			end
		end
		DoFirstCPoint(firstcpoint)

		local ignore = firstcpoint
		if firstcpoint > 0 then ignore = nil end //cpoint 0 automatically follows the entity it's created on, but the others won't, so if our only position cpoint is > 0, then do AddControlPoint for it too.

		//Save particle creation time (used for pausing, which needs to pause at a certain point in the effect's lifetime)
		if !self.ParticleStartTime then
			self.ParticleStartTime = CurTime()
		end

		if self.particle and self.particle.IsValid and self.particle:IsValid() then
			//Do other cpoints
			for k, v in pairs (ptab.cpoints) do
				if k != ignore then
				//if k >= 0 then //don't do this for -1 because it's not a real cpoint
					local mode = ptab.cpoints[k].mode
					if mode == PEPLUS_CPOINT_MODE_POSITION or mode == PEPLUS_CPOINT_MODE_POSITION_COMBINE then
						local tab = self.ParticleInfo[k]
						if mode == PEPLUS_CPOINT_MODE_POSITION_COMBINE then
							//"combine" this cpoint with the first position cpoint by having it follow all the same parameters as that one
							tab = self.ParticleInfo[firstcpoint]
						end
						if tab then
							local ent = tab.ent
							if IsValid(ent) then
								local attachstr
								local pattach
								if (ent.GetPEPlus_MergedGrip and ent:GetPEPlus_MergedGrip()) then
									self.AdvBoneCPointsToUpdate = self.AdvBoneCPointsToUpdate or {}
									if mode == PEPLUS_CPOINT_MODE_POSITION then
										self.AdvBoneCPointsToUpdate[k] = k
									else//if mode == PEPLUS_CPOINT_MODE_POSITION_COMBINE then
										self.AdvBoneCPointsToUpdate[k] = firstcpoint
									end
									ent = ent:GetParent()
									if !IsValid(ent) then self.particle:StopEmissionAndDestroyImmediately() return end //if you merge an ent that has a grip merged to it, this might return NULL for a frame or two, so just wait until it resolves itself; this is quick enough to be seamless
									if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
									pattach = PATTACH_CUSTOMORIGIN
								else
									if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
									//unlike CreateParticleSystem, the attachment id arg for this function actually needs to be a string
									attachstr = ent:GetAttachments()
									if attachstr[tab.attach] and attachstr[tab.attach].name then
										attachstr = attachstr[tab.attach].name
										pattach = PATTACH_POINT_FOLLOW
									else
										attachstr = nil
										pattach = PATTACH_ABSORIGIN_FOLLOW
									end
									self.BoundsAreNonLocal = false
								end
								self.particle:AddControlPoint(k, ent, pattach, attachstr)
								if pattach == PATTACH_CUSTOMORIGIN then 
									self.particle:SetControlPointEntity(k, ent)
								end
							end
						end
					elseif mode == PEPLUS_CPOINT_MODE_AXIS then
						local rel = nil
						local rel_ang = nil
						local axistab = ptab.cpoints[k].axis_0
						if istable(axistab) then
							rel = axistab.relative_to_cpoint
							rel_ang = axistab.relative_to_cpoint_angle
						end

						if rel != nil and ptab.cpoints[rel] != nil then
							//If this cpoint is relative to another cpoint, then move it to that cpoint's position + this cpoint's value
							local mode2 = ptab.cpoints[rel].mode
							if mode2 == PEPLUS_CPOINT_MODE_POSITION or mode2 == PEPLUS_CPOINT_MODE_POSITION_COMBINE then
								local tab = self.ParticleInfo[rel]
								if mode2 == PEPLUS_CPOINT_MODE_POSITION_COMBINE then
									tab = self.ParticleInfo[firstcpoint]
								end
								if tab then
									local ent = tab.ent
									if IsValid(ent) then
										if IsValid(ent.AttachedEntity) then ent = ent.AttachedEntity end
										//unlike CreateParticleSystem, the attachment id arg for this function actually needs to be a string
										local attachstr = ent:GetAttachments()
										local pattach = PATTACH_POINT_FOLLOW
										if attachstr[tab.attach] and attachstr[tab.attach].name then
											attachstr = attachstr[tab.attach].name
										else
											attachstr = nil
											pattach = PATTACH_ABSORIGIN_FOLLOW
										end
										if self.ParticleInfo[k] then
											self.particle:AddControlPoint(k, ent, pattach, attachstr, self.ParticleInfo[k].val) //TODO: this probably won't work at all if the cpoint is using an attachment point; whatever, this is niche functionality
										end
									end
								end
							elseif mode2 == PEPLUS_CPOINT_MODE_AXIS then
								if self.ParticleInfo[k] and self.ParticleInfo[rel] then
									self.particle:SetControlPoint(k, self.ParticleInfo[k].val + self.ParticleInfo[rel].val)
								end
							end
						elseif rel_ang != nil then
							//If this cpoint is relative to the angle of another cpoint, then rotate its value accordingly
							if rel_ang == -1 or ptab.cpoints[rel_ang].mode == PEPLUS_CPOINT_MODE_POSITION_COMBINE then rel_ang = firstcpoint end
							if ptab.cpoints[rel_ang] != nil then
								self.RelativeCPointsToUpdate = self.RelativeCPointsToUpdate or {}
								self.RelativeCPointsToUpdate[k] = rel_ang
								//this has to be done in a separate self:UpdateCPoints() function so Think can keep the position updated after this
							end
						else
							//Otherwise, just set this cpoint to its value
							if self.ParticleInfo[k] then
								self.particle:SetControlPoint(k, self.ParticleInfo[k].val)
							end
						end
					end
				end
			end

			self:UpdateCPoints()
			
			PEPlus_AddParticles_CrashCheck[pcf] = PEPlus_AddParticles_CrashCheck[pcf] or {}
			PEPlus_AddParticles_CrashCheck[pcf][self.particle] = true
		end

	end

end




function ENT:OnRemove(fullupdate)

	if fullupdate then return end //don't do any of this if the ent is only being "full updated" on client, not actually removed (https://wiki.facepunch.com/gmod/ENTITY:OnRemove#clientsidebehaviourremarks)

	if CLIENT then
		self:RemoveParticle()

		//Remove us from the list of particles on each cpoint ent (used by properties)
		if istable(self.ParticleInfo) then
			for k, v in pairs (self.ParticleInfo) do
				if IsValid(v.ent) and istable(v.ent.PEPlus_ParticleEnts) then
					v.ent.PEPlus_ParticleEnts[self] = nil
					//Refresh attacher tool effect list if this effect was removed from the list
					local panel = controlpanel.Get("peplus_attacher")
					if panel and panel.effectlist and panel.CurEntity == v.ent then
						panel.effectlist.PopulateEffectList(panel.CurEntity)
					end
				end
			end
		end

		//For PostDrawTranslucentRenderables hook
		if istable(AllPEPlusEnts) then
			AllPEPlusEnts[self] = nil
		end
	end

	local sfxpar = self:GetSpecialEffectParent()
	if IsValid(sfxpar) then
		if CLIENT then
			if sfxpar.SpecialEffectChildren then
				sfxpar.SpecialEffectChildren[self] = nil	
			end
			//If we're a child of a special effect, remove us from its control window
			if IsValid(self.PEPlusWindow) and self.PEPlusWindow.m_Entity != self then
				self.PEPlusWindow.SpecialEffect_ChildList.AddOrRemoveChild(self)
			end
		end
		if sfxpar.SpecialEffectRefresh then sfxpar:SpecialEffectRefresh() end
	end

end




if CLIENT then

	net.Receive("PEPlus_DoPauseInput_SendToCl", function(_, ply)
		local self = net.ReadEntity()
		if !IsValid(self) or !((self.PEPlus_Ent and istable(self.ParticleInfo)) or self.PEPlus_SpecialEffect) then return end
		self:DoInput("effect_pause")
	end)
	
else

	util.AddNetworkString("PEPlus_DoPauseInput_SendToCl")

	function ENT:UpdateTransmitState()

		//Fix particle not rendering if the first movement cpoint (which this ent is attached to) is located outside the PVS 
		//(i.e. if the first cpoint of a beam is outside the PVS, but the second cpoint is right in front of you, then it should 
		//render; also prevents large fx from disappearing as you go around a corner and exit their PVS)
		return TRANSMIT_ALWAYS

	end

	function ENT:NumpadSetState(newstate, ply)

		local mode = self:GetNumpadMode()
		
		if mode == 0 then

			//Mode 0: Disable/enable effect
			self:SetNumpadState(newstate)
			//Everything else is handled clientside in Think once the client receives the new NumpadState value

		elseif mode == 1 then

			//Mode 1: Pause/unpause effect
			//This requires a ParticleStartTime value that only exists clientside, so tell the client to send it, using the same "effect_pause" input as the cpanel
			if IsValid(ply) and ply.IsPlayer and ply:IsPlayer() then
				net.Start("PEPlus_DoPauseInput_SendToCl")
					net.WriteEntity(self)
				net.Send(ply)
			else
				local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
				MsgN(self, " (", self:GetParticleName(), ", ", PEPlus_GetDataPCFNiceName(pcf), ") tried to send a numpad pause input with invalid player ", ply, ". Report this!")
			end

		elseif mode == 2 then

			//Mode 2: Restart effect
			//Tell all clients to restart the effect
			net.Start("PEPlus_InfoTableUpdate_SendToCl")
				net.WriteEntity(self)
			net.Broadcast()

		end

	end

	function PEPlusNumpadFunction(pl, ent, keydown)

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
			ent:NumpadSetState(newstate, pl)
		end
		ent.NumpadKeyDown = keydown
	
	end

	numpad.Register("PEPlus_Numpad", PEPlusNumpadFunction)

	function ENT:AttachToEntity(ent, k, attach, ply, addundo)

		if !IsValid(ent) or !istable(self.ParticleInfo) then return false end

		local oldent = self.ParticleInfo[k].ent
		if !IsValid(oldent) then return false end
		local oldconst = nil
		local doparent = false
		local tab = constraint.FindConstraint(oldent, "PEPlus_Ent")
		if istable(tab) and tab.Ent1 == self then
			oldconst = tab.Constraint
			doparent = tab.DoParent
		else
			return false
		end
	
		//don't let us set attach to an attachment that the model doesn't have
		if IsValid(ent.AttachedEntity) then
			if !istable(ent.AttachedEntity:GetAttachment(attach)) then attach = 0 end 
		else
			if !istable(ent:GetAttachment(attach)) then attach = 0 end
		end
		//self.ParticleInfo[k].ent = ent //the constraint function already does this
		self.ParticleInfo[k].attach = attach
	
		//Detach the corresponding cpoint of the particle effect from the grip point we clicked on, then attach that cpoint to the new parent
		oldent:DontDeleteOnRemove(self)
		self:DontDeleteOnRemove(oldent)
		oldconst:RemoveCallOnRemove("PEPlus_Ent_UnmergeOnUndo")
		oldconst:Remove()
		oldent:Remove()
		local const = constraint.PEPlus_Ent(self, ent, k, doparent, ply)

		
		if addundo then
			//Add an undo entry
			undo.Create("PEPlus_Ent")
				undo.AddEntity(const)  //the constraint entity will detach us upon being removed
				undo.SetPlayer(ply)
			undo.Finish("Attach Particle Effect " ..self:GetParticleName() .. " to "  .. string.GetFileFromFilename(tostring(ent:GetModel())))
		end

		//Tell clients to retrieve the updated info table
		net.Start("PEPlus_InfoTableUpdate_SendToCl")
			net.WriteEntity(self)
		net.Broadcast()

		return const

	end

	function ENT:AttachToSpecialEffect(ent, ply, addundo)

		//Detach ALL of the particle's cpoints and delete any corresponding grip points, then attach it to the special effect

		if !IsValid(ent) or !ent.PEPlus_SpecialEffect or !istable(self.ParticleInfo) then return false end

		local const = constraint.PEPlus_SpecialEffect(ent, self, ply)
		constraint.RemoveConstraints(self, "PEPlus_Ent")
		local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
		local cpointtab = PEPlus_ProcessedPCFs[pcf][self:GetParticleName()].cpoints
		local cpoints_for_defaults = {}
		for k, v in pairs (self.ParticleInfo) do
			if cpointtab[k].mode == PEPLUS_CPOINT_MODE_POSITION then
				if v.ent.PEPlus_Grip then
					v.ent:DontDeleteOnRemove(self)
					v.ent:Remove()
				end
				self.ParticleInfo[k].ent = nil //this will be replaced clientside by the special effect
				self.ParticleInfo[k].attach = 0
				table.insert(cpoints_for_defaults, k)
			end
		end
		for k, v in pairs (ent:SpecialEffectDefaultRoles(cpoints_for_defaults)) do
			self.ParticleInfo[k].sfx_role = v
		end

		if addundo then
			//Add an undo entry
			undo.Create("PEPlus_Ent")
				undo.AddEntity(const)  //the constraint entity will detach us upon being removed
				undo.SetPlayer(ply)
			undo.Finish("Attach Particle Effect " .. self:GetParticleName() .. " to "  .. ent.PrintName)
		end

		//Tell clients to retrieve the updated info table
		net.Start("PEPlus_InfoTableUpdate_SendToCl")
			net.WriteEntity(self)
		net.Broadcast()

		return const

	end

	function ENT:DetachFromEntity(k, ply)

		//Detaches a single cpoint from its parent entity, and spawns a new grip for the cpoint to attach to instead
	
		if !istable(self.ParticleInfo[k]) then return false end
		local ent = self.ParticleInfo[k].ent
		if !IsValid(ent) then return false end

		//If the ent is an adv bonemerged grip point, then unmerge it instead
		if (ent.GetPEPlus_MergedGrip and ent:GetPEPlus_MergedGrip()) then
			if ent:Unmerge(ply) then
				ply:SendLua("GAMEMODE:AddNotify('#undone_AdvBonemerge', NOTIFY_UNDO, 2)")
				ply:SendLua("surface.PlaySound('buttons/button15.wav')")
			else
				ply:SendLua("GAMEMODE:AddNotify('Cannot unmerge this entity', NOTIFY_ERROR, 5)")
				ply:SendLua("surface.PlaySound('buttons/button11.wav')")
			end
			return nil
		end

		local oldconst = nil
		local doparent = false
		local tab = constraint.FindConstraints(ent, "PEPlus_Ent")
		if istable(tab) then
			for k2, v2 in pairs (tab) do
				if v2.Ent1 == self and v2.CPoint == k then
					oldconst = v2.Constraint
					doparent = v2.DoParent
				end
			end
		end
		if !IsValid(oldconst) then return false end

		local g = ents.Create("ent_peplus_grip")
		if !IsValid(g) then return false end
		g:Spawn()

		local p = self:GetCPointPos(k)
		local _, bboxtop1 = ent:GetRotatedAABB(ent:GetCollisionBounds())
		local bboxtop2, _ = g:GetCollisionBounds()
		local height = bboxtop1.z + -bboxtop2.z + ent:GetPos().z
		g:SetPos(Vector(p.pos.x, p.pos.y, height))
		g:SetAngles(p.ang)

		oldconst:RemoveCallOnRemove("PEPlus_Ent_UnmergeOnUndo")
		oldconst:Remove()
		//Check if we want to clear DeleteOnRemove or not - if the same particle has another cpoint attached to the same entity, then we want to maintain
		//the DeleteOnRemove, but if this was the only cpoint attached to that entity, then clear the DeleteOnRemove
		local clear = true
		local tab = constraint.FindConstraints(ent, "PEPlus_Ent")
		if istable(tab) then
			for k2, v2 in pairs (tab) do
				if v2.Constraint != oldconst and v2.Ent1 == self then
					clear = false
					break
				end
			end
		end
		if clear then
			ent:DontDeleteOnRemove(self)
		end
		self.ParticleInfo[k].attach = 0
		constraint.PEPlus_Ent(self, g, k, doparent, ply)


		//Tell clients to retrieve the updated info table
		net.Start("PEPlus_InfoTableUpdate_SendToCl")
			net.WriteEntity(self)
		net.Broadcast()


		return true

	end

	function ENT:DetachFromSpecialEffect(ply)

		//Detaches EVERY cpoint from the special effect parent, and spawns new grips for all of them to attach to instead

		if !istable(self.ParticleInfo) then return false end
		local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
		local ptab = PEPlus_ProcessedPCFs[pcf][self:GetParticleName()]
		if !ptab then return end
		local parentent = self:GetSpecialEffectParent()
		if !IsValid(parentent) then return false end
		local parentmodel = parentent:GetSpecialEffectParent()
		if !IsValid(parentmodel) then return false end


		local tab = constraint.FindConstraints(self, "PEPlus_SpecialEffect")
		if istable(tab) then
			for k2, v2 in pairs (tab) do
				if v2.Ent2 == self and v2.Ent1 == parentent then
					oldconst = v2.Constraint
				end
			end
		end
		if !IsValid(oldconst) then return false end
		oldconst:RemoveCallOnRemove("PEPlus_Ent_UnmergeOnUndo")
		oldconst:Remove()
		parentent:DontDeleteOnRemove(self)

		local grips, mins, maxs = PEPlus_GetParticleDefaultPositions(pcf, self:GetParticleName())
		local pos = parentmodel:GetPos()
		local _, bboxtop1 = parentmodel:GetRotatedAABB(parentmodel:GetCollisionBounds())
		local height = bboxtop1.z + pos.z - mins.z
		pos = Vector(pos.x, pos.y, height)


		for k, v in pairs (ptab.cpoints) do
			if v.mode == PEPLUS_CPOINT_MODE_POSITION then
				self.ParticleInfo[k].sfx_role = 0
				self.ParticleInfo[k].attach = 0
			end
		end

		local parent = nil
		grips, parent = PEPlus_SpawnParticleGripPoints(grips, pos)

		self:SetSpecialEffectParent(nil)
		for k, v in pairs (grips) do
			constraint.PEPlus_Ent(self, v, k, parent == v, ply)
		end


		//Tell clients to retrieve the updated info table
		net.Start("PEPlus_InfoTableUpdate_SendToCl")
			net.WriteEntity(self)
		net.Broadcast()


		return true

	end

end




//Networking for edit menu inputs
local EditMenuInputs = {
	[0] = "cpoint_position_ent_setwithtool",
	"cpoint_position_ent_detach",
	"cpoint_position_attach",
	"cpoint_position_sfx_role",
	"cpoint_axis_val",
	"cpoint_axis_val_all",
	"loop_mode",
	"loop_delay",
	"loop_safety",
	"numpad_num",
	"numpad_toggle",
	"numpad_starton",
	"numpad_mode",
	"effect_pause",
	"effect_restart"
}
local EditMenuInputs_bits = 4 //max 15
EditMenuInputs = table.Flip(EditMenuInputs)
//How this works:
//- table.Flip sets the table to {cpoint_position_ent_setwithtool = 0}, and so on
//- net.Write retrieves the corresponding number of a string with EditMenuInputs[input], then sends that number
//- net.Read gets the number, then retrieves its corresponding string with table.KeyFromValue(EditMenuInputs, input)
//This lets us add as many networkable strings to this table as we want, without having to manually assign each one a number.


if CLIENT then

	function ENT:DoInput(input, ...)

		net.Start("PEPlus_EditMenuInput_SendToSv")

			net.WriteEntity(self)
			local args = {...}

			net.WriteUInt(EditMenuInputs[input], EditMenuInputs_bits)

			if string.StartsWith(input, "cpoint_") then
				net.WriteInt(args[1], peplus_cpointbits) //cpoint id, can be -1
			end

			//if input == "cpoint_position_ent_setwithtool" then

			//elseif input == "cpoint_position_ent_detach" then

			if input == "cpoint_position_attach" then

				net.WriteUInt(args[2], 8) //new attachment id; don't know what the max attachment number is, assume 255

			elseif input == "cpoint_position_sfx_role" then
				
				net.WriteUInt(args[2], 2) //new value for sfx role (max 3)
				
			elseif input == "cpoint_axis_val" then

				net.WriteUInt(args[2], 2) //axis (1/2/3)
				net.WriteFloat(args[3]) //new value for axis
			
			elseif input == "cpoint_axis_val_all" then

				net.WriteFloat(args[2].x) //new value for all 3 axes; we network vectors as 3 floats so that compression doesn't mess up precise values
				net.WriteFloat(args[2].y)
				net.WriteFloat(args[2].z)

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

			elseif input == "numpad_mode" then
	
				net.WriteUInt(args[1], 2) //numpad mode id

			elseif input == "effect_pause" then

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

			end

		net.SendToServer()

	end

	concommand.Add("peplus_resetallparticles", function (ply, cmd, args)
		//Only let server owners run this command to prevent (network) spam if there are many particle effects 
		if !game.SinglePlayer() and IsValid(ply) and !ply:IsListenServerHost() and !ply:IsSuperAdmin() then
			return false
		end
		
		for _, ent in ipairs(ents.FindByClass("ent_peplus")) do
			ent:DoInput("effect_restart")
		end
	end, nil, "Resets all Particle Effects+ particles")

else

	util.AddNetworkString("PEPlus_EditMenuInput_SendToSv")

	//Respond to inputs from the clientside edit menu
	net.Receive("PEPlus_EditMenuInput_SendToSv", function(_, ply)

		local self = net.ReadEntity()
		if !IsValid(self) or !self.PEPlus_Ent or !istable(self.ParticleInfo) then return end

		local input = net.ReadUInt(EditMenuInputs_bits)
		if !input then return end
		input = table.KeyFromValue(EditMenuInputs, input)

		local k = nil
		local cpointtab = nil
		if string.StartsWith(input, "cpoint_") then
			k = net.ReadInt(peplus_cpointbits) //cpoint id, can be -1
			local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
			cpointtab = PEPlus_ProcessedPCFs[pcf][self:GetParticleName()].cpoints[k]
		end
		local refreshtable = false

		if input == "cpoint_position_ent_setwithtool" then
			
			if !IsValid(ply) then return end
			if !GetConVar("toolmode_allow_peplus_attacher"):GetBool() then return end //TODO: this was copied from advbonemerge, which also does a CanTool check with a fake trace. is that necessary here?

			local tool = ply:GetTool("peplus_attacher")
			if !istable(tool) or !IsValid(tool:GetWeapon()) then return end

			ply:ConCommand("gmod_tool peplus_attacher")
			//Fix: The tool's holster function clears the nwentity, and if this is already the toolgun's selected tool, it'll "holster" the tool before "deploying" it again.
			//To make this worse, it's different if the toolgun is the active weapon or not (if active, it holsters then deploys; if not active, it deploys, holsters, then deploys again)
			//so instead of having to deal with any of that, just set the entity on a delay so we're sure the tool is already done equipping.
			timer.Simple(0.1, function()
				if !IsValid(self) or !IsValid(ply) then return end
				tool:GetWeapon():SetNWInt("PEPlus_Attacher_CPoint", k)
				tool:GetWeapon():SetNWEntity("PEPlus_Attacher_CurEntity", self)
				tool:SetStage(1)
			end)

		elseif input == "cpoint_position_ent_detach" then

			//Send a notification to the player saying whether or not we managed to detach the particle
			local detach = self:DetachFromEntity(k, ply)
			if detach == true then
				ply:SendLua("GAMEMODE:AddNotify('#undone_PEPlus_Ent', NOTIFY_UNDO, 2)")
				ply:SendLua("surface.PlaySound('buttons/button15.wav')")
			elseif detach == false then
				ply:SendLua("GAMEMODE:AddNotify('Failed to detach particle', NOTIFY_ERROR, 5)")
				ply:SendLua("surface.PlaySound('buttons/button11.wav')")
			end
			//don't refresh table, DetachFromEntity handles this

		elseif input == "cpoint_position_attach" then

			local new = net.ReadUInt(8)

			if !istable(self.ParticleInfo[k]) or cpointtab.mode != PEPLUS_CPOINT_MODE_POSITION then return end

			self.ParticleInfo[k].attach = new
			refreshtable = true

		elseif input == "cpoint_position_sfx_role" then
			
			local new = net.ReadUInt(2)

			if !istable(self.ParticleInfo[k]) or cpointtab.mode != PEPLUS_CPOINT_MODE_POSITION then return end

			self.ParticleInfo[k].sfx_role = new
			refreshtable = true

		elseif input == "cpoint_axis_val" then

			local axis = net.ReadUInt(2)
			local new = net.ReadFloat()

			if !istable(self.ParticleInfo[k]) or cpointtab.mode != PEPLUS_CPOINT_MODE_AXIS then return end

			//Sanity check: for some axis controls ("Emission Count Scale"), going out of range causes a crash, so make sure that doesn't happen
			local tab = cpointtab["axis_" .. axis-1]
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

		elseif input == "cpoint_axis_val_all" then

			local new = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())

			if !istable(self.ParticleInfo[k]) or cpointtab.mode != PEPLUS_CPOINT_MODE_AXIS then return end

			self.ParticleInfo[k].val = new
			refreshtable = true

		elseif input == "loop_mode" then
			
			self:SetLoopMode(net.ReadUInt(2))
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

			self.NumDown = numpad.OnDown(ply, key, "PEPlus_Numpad", self, true)
			self.NumUp = numpad.OnUp(ply, key, "PEPlus_Numpad", self, false)

			//If the player is holding down the old key then let go of it
			if self.NumpadKeyDown then
				PEPlusNumpadFunction(ply, self, false)
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
					PEPlusNumpadFunction(ply, self, keydown)
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
				//everything else should be handled clientside in Think once the client receives the new NumpadState value
			end

		elseif input == "effect_pause" then
			
			self:SetPauseTime(net.ReadFloat())

		elseif input == "effect_restart" then
			
			refreshtable = true

		end

		if refreshtable then
			//Refresh special effect parent on server
			local sfxpar = self:GetSpecialEffectParent()
			if IsValid(sfxpar) and sfxpar.SpecialEffectRefresh then sfxpar:SpecialEffectRefresh() end
			//Tell clients to retrieve the updated info table
			net.Start("PEPlus_InfoTableUpdate_SendToCl")
				net.WriteEntity(self)
			net.Broadcast()
		end

	end)

	//Used by Advanced Bonemerge to fix merged fx breaking when their parent (or parent's parent, etc.) is changed
	function PEPlus_RefreshAllChildFx(ent)

		//MsgN("refreshing all child fx: ", ent)
		if !IsValid(ent) then return end
		if ent.PEPlus_Ent then
			//Tell clients to retrieve the updated info table
			net.Start("PEPlus_InfoTableUpdate_SendToCl")
				net.WriteEntity(ent)
			net.Broadcast()
		elseif ent.PEPlus_SpecialEffect then
			//Refresh special effect on server
			if ent.SpecialEffectRefresh then ent:SpecialEffectRefresh() end
			//Tell clients to refresh the special effect
			net.Start("PEPlus_SpecialEffect_Refresh_SendToCl")
				net.WriteEntity(ent)
			net.Broadcast()
		else
			local tab = {}
			//Add all children of the ent to the list
			for _, v in pairs (ent:GetChildren()) do
				tab[v] = true
			end
			//Also add all particle effect ents attached to the ent to the list; these won't be 
			//listed by GetChildren if they're attached by a position cpoint after the first
			for _, v in pairs (constraint.FindConstraints(ent, "PEPlus_Ent")) do
				if IsValid(v.Ent1) then 
					tab[v.Ent1] = true
				end
			end
			for k, _ in pairs (tab) do
				PEPlus_RefreshAllChildFx(k)
			end
		end

	end

end




//Networking for infotable
if SERVER then 

	util.AddNetworkString("PEPlus_InfoTable_GetFromSv")
	util.AddNetworkString("PEPlus_InfoTable_SendToCl")
	util.AddNetworkString("PEPlus_InfoTableUpdate_SendToCl")

	//If we received a request for an info table, then send it to the client
	net.Receive("PEPlus_InfoTable_GetFromSv", function(_, ply)
		local ent = net.ReadEntity()
		if !IsValid(ent) or !istable(ent.ParticleInfo) then return end
		local pcf = PEPlus_GetGamePCF(ent:GetPCF(), ent:GetPath())
		if !istable(PEPlus_ProcessedPCFs[pcf]) then return end
		local ptab = PEPlus_ProcessedPCFs[pcf][ent:GetParticleName()]
		if !istable(ptab) then return end

		if !IsValid(ent:GetSpecialEffectParent()) then //children of special fx don't need valid .ent values
			//Make sure the table is ready to send first - if we're a dupe, and our constraints haven't restored the .ent values for our cpoints using PEPLUS_CPOINT_MODE_POSITION,
			//then this is most likely a bad dupe, so remove us and stop here
			local badparticle = nil
			for k, v in pairs (ent.ParticleInfo) do
				if ptab.cpoints[k].mode == PEPLUS_CPOINT_MODE_POSITION and v.ent == nil then
					//MsgN("stop")
					//return
					badparticle = k
					break
				end
			end
			if badparticle != nil then
				MsgN(ent, " (", ent:GetParticleName(), ", ", PEPlus_GetDataPCFNiceName(pcf), ") has nil target entity ", badparticle, "; most likely a bad dupe, removing")
				for k, v in pairs (ent.ParticleInfo) do
					//don't leave behind any orphaned grip points (i.e. loaded a dupe; one cpoint was attached to a non-dupable entity, another was attached to a grip)
					if IsValid(v.ent) and v.ent.PEPlus_Grip then
						v.ent:Remove()
					end
				end
				ent:Remove()
				return
			end
			//MsgN("go")
		end

		net.Start("PEPlus_InfoTable_SendToCl", true)

			net.WriteEntity(ent)

			net.WriteInt(table.Count(ent.ParticleInfo), peplus_cpointbits + 1) //+1 for the super edge case where all 64 cpoints are occupied AND we use fallback cpoint -1
			for k, v in pairs (ent.ParticleInfo) do
				net.WriteInt(k, peplus_cpointbits)

				local mode = ptab.cpoints[k].mode
				if mode == PEPLUS_CPOINT_MODE_POSITION then
					net.WriteEntity(v.ent or NULL)
					net.WriteUInt(v.attach or 0, 8) //don't know what the max attachment number is, assume 255
					net.WriteUInt(v.sfx_role or 0, 2) //max of 3, since we don't need any more so far (projectile effect has 0-2)
				elseif mode == PEPLUS_CPOINT_MODE_AXIS then
					//we network vectors as 3 floats so that compression doesn't mess up precise values
					local val = v.val or Vector()
					net.WriteFloat(val.x)
					net.WriteFloat(val.y)
					net.WriteFloat(val.z)
				end
			end

		net.Send(ply)
	end)

else

	//If we received an info table from the server, then use it
	net.Receive("PEPlus_InfoTable_SendToCl", function()

		local self = net.ReadEntity()
		if !IsValid(self) or !self.PEPlus_Ent then return end 
		local pcf = PEPlus_GetGamePCF(self:GetPCF(), self:GetPath())
		if !istable(PEPlus_ProcessedPCFs[pcf]) then return end
		local ptab = PEPlus_ProcessedPCFs[pcf][self:GetParticleName()]
		if !istable(ptab) then return end

		local tab = {}
		local badents_tab = {}

		for i = 1, net.ReadInt(peplus_cpointbits + 1) do
			local k = net.ReadInt(peplus_cpointbits)
			local v = {}

			local mode = ptab.cpoints[k].mode
			if mode == PEPLUS_CPOINT_MODE_POSITION then
				//v.ent = net.ReadEntity()
				//the ent can be null if it's outside the player's pvs, so tell the think func to keep checking until it becomes valid
				local entnum = net.ReadUInt(MAX_EDICT_BITS)
				v.ent = Entity(entnum)
				if !IsValid(v.ent) then badents_tab[k] = entnum end

				v.attach = net.ReadUInt(8)
				v.sfx_role = net.ReadUInt(2)
			elseif mode == PEPLUS_CPOINT_MODE_AXIS then
				v.val = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
				for i = 0, 2 do
					//Sanity check: for some axis controls ("Emission Count Scale"), going out of range causes a crash, so make sure that doesn't happen
					local tab2 = ptab.cpoints[k]["axis_" .. i]
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
		if table.Count(badents_tab) > 0 and !IsValid(self:GetSpecialEffectParent()) then
			self.ParticleInfo_InvalidEnts = badents_tab
		end

		local sfxpar = self:GetSpecialEffectParent()
		//If we're a child of a special effect, update its control window
		local parwindow
		if IsValid(sfxpar) then
			if sfxpar.SpecialEffectRefresh then sfxpar:SpecialEffectRefresh() end
			parwindow = sfxpar.PEPlusWindow //don't check if this is valid; we want to do all this even if the parent's window isn't open, to clear our old window
			//If we were just parented, and still have our own control window from back when we were unparented, close it
			if IsValid(self.PEPlusWindow) and self.PEPlusWindow != parwindow then
				self.PEPlusWindow:OnEntityLost()
			end
			//Assign ourself to the parent's control window, so that info table updates and such will update those controls
			self.PEPlusWindow = parwindow
		end
		if IsValid(self.PEPlusWindow) and self.PEPlusWindow.m_Entity != self then
			//Update the list of children to add or remove us
			self.PEPlusWindow.SpecialEffect_ChildList.AddOrRemoveChild(self)
			//If we're no longer parented, then stop being assigned to its control window
			if !parwindow then
				self.PEPlusWindow = nil
			end
		end
		if istable(oldtab) then
			local window = IsValid(self.PEPlusWindow) and istable(self.PEPlusWindow.CPointCategories) and istable(self.PEPlusWindow.CPointCategories[self])
			for k, v in pairs (oldtab) do
				if self.ParticleInfo[k].ent != oldtab[k].ent then
					local oldent = oldtab[k].ent
					//Remove us from the list of particles on the old ent
					if oldent.PEPlus_ParticleEnts then
						oldent.PEPlus_ParticleEnts[self] = nil
					end
					//Refresh attacher tool effect list if this effect was removed from the list
					local panel = controlpanel.Get("peplus_attacher")
					if panel and panel.effectlist and panel.CurEntity == oldent then
						panel.effectlist.PopulateEffectList(panel.CurEntity)
					end
				end
				//Refresh control window if we changed something that requires the controls to be rebuilt
				if window and ((!IsValid(sfxpar) and self.ParticleInfo[k].ent != oldtab[k].ent) or self.ParticleInfo[k].sfx_role != oldtab[k].sfx_role) then
					self.PEPlusWindow.CPointCategories[self][k].RebuildContents(self.ParticleInfo[k])
				end
			end
		end
		if !IsValid(sfxpar) then //don't do this if we're a special effect's child, otherwise we'll get added to the PEPlus_ParticleEnts list on the special effect's parent
			for k, v in pairs (self.ParticleInfo) do
				if IsValid(v.ent) then
					//Store us in a list on the cpoint ent (used by properties)
					v.ent.PEPlus_ParticleEnts = v.ent.PEPlus_ParticleEnts or {}
					v.ent.PEPlus_ParticleEnts[self] = true
					//Refresh attacher tool effect list if this effect was added to the list
					local panel = controlpanel.Get("peplus_attacher")
					if panel and panel.effectlist and panel.CurEntity == v.ent then
						panel.effectlist.PopulateEffectList(panel.CurEntity)
					end
				end
			end
		end
		oldtab = nil

	end)

	//If we received a message from the server telling us an ent's info table is out of date, then change its ParticleInfo_Received value so its Think function requests a new one
	net.Receive("PEPlus_InfoTableUpdate_SendToCl", function()
		local ent = net.ReadEntity()
		if !IsValid(ent) or !ent.PEPlus_Ent then return end

		ent.ParticleInfo_Received = false
	end)

end




//Constraint, used to keep entities associated together between dupes/saves
//We use a separate constraint for each entity pair instead of one big constraint for the whole effect, because constraint.AddConstraintTable can only handle a max of 4 entities,
//while the worst-case-scenario particle effect could have up to 64 cpoint entities + the 1 particle entity itself
if SERVER then
	
	function constraint.PEPlus_Ent(Ent1, Ent2, CPoint, DoParent, ply)

		if !Ent1 or !Ent2 or !Ent1.PEPlus_Ent then return end
		local pcf = PEPlus_GetGamePCF(Ent1:GetPCF(), Ent1:GetPath())
		//if !istable(PEPlus_ProcessedPCFs[pcf]) or !istable(PEPlus_ProcessedPCFs[pcf][Ent1:GetParticleName()]) then return end //causes grip ents from dupes with invalid fx to delete themselves due to having no particle
		
		//create a dummy ent for the constraint functions to use
		local const = ents.Create("info_target")
		const:Spawn()
		const:Activate()

		if !(Ent2.PEPlus_Grip or (Ent2.GetPEPlus_MergedGrip and Ent2:GetPEPlus_MergedGrip())) then
			//If the constraint is removed by an Undo, unmerge the second entity - this shouldn't do anything if the constraint's removed some other way i.e. one of the ents is removed
			timer.Simple(0.1, function()  //CallOnRemove won't do anything if we try to run it now instead of on a timer
				if const:GetTable() then  //CallOnRemove can error if this table doesn't exist - this can happen if the constraint is removed at the same time it's created for some reason
					const:CallOnRemove("PEPlus_Ent_UnmergeOnUndo", function(const,Ent1,ply)
						//MsgN("PEPlus_Ent_UnmergeOnUndo called by constraint ", const, ", ents ", Ent1, " ", Ent2)
						//NOTE: if we use the remover tool to get rid of ent2, it'll still be valid for a second, so we need to look for the NoDraw and MoveType that the tool sets the ent to instead.
						//this might have a few false positives, but i don't think that many people will be attaching stuff to invisible, intangible ents a whole lot anyway so it's not a huge deal
						if !IsValid(const) or !IsValid(Ent2) or Ent2:IsMarkedForDeletion() or (Ent2:GetNoDraw() == true and Ent2:GetMoveType() == MOVETYPE_NONE) or !IsValid(Ent1) or Ent1:IsMarkedForDeletion() or !IsValid(ply) or !Ent1.DetachFromEntity then return end
						Ent1:DetachFromEntity(CPoint, ply)
					end, Ent1, ply)
				end
			end)
		end

		if istable(Ent1.ParticleInfo) and istable(Ent1.ParticleInfo[CPoint]) and PEPlus_ProcessedPCFs[pcf] and PEPlus_ProcessedPCFs[pcf][Ent1:GetParticleName()] and PEPlus_ProcessedPCFs[pcf][Ent1:GetParticleName()].cpoints[CPoint] and PEPlus_ProcessedPCFs[pcf][Ent1:GetParticleName()].cpoints[CPoint].mode == PEPLUS_CPOINT_MODE_POSITION then
			Ent1.ParticleInfo[CPoint].ent = Ent2
		end
		if DoParent then
			Ent1:SetPos(Ent2:GetPos())
			Ent1:SetAngles(Ent2:GetAngles())
			Ent1:SetParent(Ent2)
		end

		if (Ent2.PEPlus_Grip or (Ent2.GetPEPlus_MergedGrip and Ent2:GetPEPlus_MergedGrip())) then
			Ent1:DeleteOnRemove(Ent2)
		end
		Ent2:DeleteOnRemove(Ent1)

		constraint.AddConstraintTable(Ent1, const, Ent2)
		
		local ctable = {
			Type = "PEPlus_Ent",
			Ent1 = Ent1,
			Ent2 = Ent2,
			CPoint = CPoint,
			DoParent = DoParent,
			ply = ply,
		}
	
		const:SetTable(ctable)
	
		return const
		
	end
	duplicator.RegisterConstraint("PEPlus_Ent", constraint.PEPlus_Ent, "Ent1", "Ent2", "CPoint", "DoParent", "ply")
	duplicator.RegisterConstraint("PartCtrl_Ent", constraint.PEPlus_Ent, "Ent1", "Ent2", "CPoint", "DoParent", "ply")  //old in-dev constraint name, for old saves/dupes




	function ENT:OnEntityCopyTableFinish(data)

		//Don't store these DTvars
		if data.DT then
			data.DT.NumpadState = nil
			data.DT.SpecialEffectParent = nil
		end

		//Clear out entity values when copying the ParticleInfo table, these won't dupe correctly anyway and will be filled back in by constraints
		if istable(data.ParticleInfo) then
			data.ParticleInfo = table.Copy(data.ParticleInfo) //make sure to create a separate table; otherwise, clearing the .ent value below will also clear the one still in use on the actual entity
			for k, v in pairs (data.ParticleInfo) do
				data.ParticleInfo[k].ent = nil
			end
		end

	end




	//When NPCs die and create a serverside ragdoll, then transfer over the particle to the ragdoll
	//TODO: can we do a clientside version of this for clientside ragdolls?
	hook.Add("CreateEntityRagdoll", "PEPlus_CreateEntityRagdoll", function(oldent, rag)
		local oldentconsts = constraint.GetTable(oldent)
		for k, const in pairs (oldentconsts) do
			if const.Entity then
				if const.Type == "PEPlus_Ent" or const.Type == "PEPlus_SpecialEffect" then
					//Clear DeleteOnRemoves and transfer over parents
					local oldconst = const.Constraint
					oldconst:RemoveCallOnRemove("PEPlus_Ent_UnmergeOnUndo")
					const.Ent1:DontDeleteOnRemove(const.Ent2)
					const.Ent2:DontDeleteOnRemove(const.Ent1)
					if const.Ent1:GetParent() == oldent then const.Ent1:SetParent(rag) end
					if const.Ent2:GetParent() == oldent then const.Ent2:SetParent(rag) end
					oldconst:Remove()

					//If any of the values in the constraint table are oldent, switch them over to the ragdoll
					for key, val in pairs (const) do
						if val == oldent then 
							const[key] = rag
						end
					end

					local entstab = {}

					//Also switch over any instances of oldent to rag inside the entity subtable
					for tabnum, tab in pairs (const.Entity) do
						if tab.Entity then
							if tab.Entity == oldent then 
								const.Entity[tabnum].Entity = rag
								const.Entity[tabnum].Index = rag:EntIndex()
							end
						end
						entstab[const.Entity[tabnum].Index] = const.Entity[tabnum].Entity
					end

					//Now copy the constraint over to the ragdoll
					duplicator.CreateConstraintFromTable(const, entstab)

					//Tell clients to retrieve the updated info table from the constraint func
					if const.Ent1 and const.Ent1.PEPlus_Ent then
						net.Start("PEPlus_InfoTableUpdate_SendToCl")
							net.WriteEntity(const.Ent1)
						net.Broadcast()
					end
				end
			end
		end
	end)

end




duplicator.RegisterEntityClass("ent_peplus", function(ply, data)

	//default dtvars for old dupes that don't have them
	if data.DT.PauseTime == nil then data.DT.PauseTime = -1 end
	if data.DT.LoopMode == nil then data.DT.LoopMode = 1 end
	if data.DT.NumpadToggle == nil then data.DT.NumpadToggle = true end
	if data.DT.NumpadStartOn == nil then data.DT.NumpadStartOn = true end
	//fix old dupes from before all the effect names were converted to lowercase
	if isstring(data.DT.ParticleName) then data.DT.ParticleName = string.lower(data.DT.ParticleName) end
	//fix old in-dev test pcf names
	if string.StartsWith(data.DT.PCF, "particles/partctrl_test") then data.DT.PCF = string.Replace(data.DT.PCF, "particles/partctrl_test", "particles/peplus_test") end

	if IsValid(ply) and !gamemode.Call("PlayerSpawnParticle", ply, data.DT.ParticleName, data.DT.PCF, data.DT.Path) then return false end

	local ent = ents.Create("ent_peplus")
	if !ent:IsValid() then return false end

	//duplicator.GenericDuplicatorFunction(ply, data)
	duplicator.DoGeneric(ent, data)
	duplicator.DoGenericPhysics(ent, ply, data)

	ent.ParticleInfo = table.Copy(data.ParticleInfo)
	ent:SetPlayer(ply) //NOTE: this still works if ply doesn't exist

	ent:Spawn()

	if IsValid(ply) then gamemode.Call("PlayerSpawnedParticle", ply, data.DT.ParticleName, data.DT.PCF, data.DT.Path, ent) end

	return ent

end, "Data")
duplicator.RegisterEntityClass("ent_partctrl", duplicator.FindEntityClass("ent_peplus").Func, "Data") //old in-dev ent name, for old saves/dupes




local grip_radius = 6/2

function PEPlus_GetParticleDefaultPositions(pcf, name)

	local ptab = PEPlus_ProcessedPCFs[pcf][name]

	local grips = {}
	local igrips = {}
	local offset_grips
	for k, v in pairs (ptab.cpoints) do
		if v.mode == PEPLUS_CPOINT_MODE_POSITION then
			if !ptab.cpoint_planes or !ptab.cpoint_planes[k] then
				if ptab.cpoint_distance_overrides and ptab.cpoint_distance_overrides[k] and ptab.cpoint_distance_overrides[k].offset_from_main_row then
					offset_grips = offset_grips or {}
					offset_grips[k] = true
				else
					table.insert(igrips, k)
				end
			end
		end
	end

	//Arrange all normal cpoints in a line
	local total_length = 0
	for i, k in ipairs (igrips) do
		local this_length = 0
		if i > 1 then
			this_length = 100/(#igrips-1) //by default, arrange all points in a line 100 units long
			if ptab.cpoint_distance_overrides and ptab.cpoint_distance_overrides[k] then
				if ptab.cpoint_distance_overrides[k].min then this_length = math.max(this_length, ptab.cpoint_distance_overrides[k].min) end
				if ptab.cpoint_distance_overrides[k].max then 
					this_length = math.min(this_length, ptab.cpoint_distance_overrides[k].max)
					this_length = math.max(this_length, grip_radius*2)
				end
				//math.Clamp(this_length, ptab.cpoint_distance_overrides[k].min or this_length, ptab.cpoint_distance_overrides[k].max or this_length)
			end
		end
		total_length = total_length + this_length
		grips[k] = Vector(total_length, 0, 0)
	end
	//For distance scalar cpoints; offset each of these a set distance away from a normal cpoint that sets particle positions
	if offset_grips then
		local fallback = igrips[1]
		for i, k in pairs (igrips) do
			if !ptab.sets_particle_pos[k] then
				table.remove(igrips, k)
			end
		end
		if #igrips == 0 then igrips[1] = fallback end //i don't think there are any effects where this can happen, but let's be safe here
		local cpoints_to_offset = {}
		local i = 1
		for k, _ in pairs (offset_grips) do
			cpoints_to_offset[i] = cpoints_to_offset[i] or {}
			table.insert(cpoints_to_offset[i], k)
			i = i + 1
			if i > #igrips then i = 1 end
		end
		for i, tab in pairs (cpoints_to_offset) do
			local k = igrips[i]
			for _, k2 in pairs (tab) do
				local this_length //= 50 //distance is arbitrary
				if ptab.cpoint_distance_overrides and ptab.cpoint_distance_overrides[k2] then
					if this_length == nil then
						//if we only have min or max defined, just use that as the distance,
						//so we can be sure the cpoint ends up at a good position
						this_length = ptab.cpoint_distance_overrides[k2].min or ptab.cpoint_distance_overrides[k2].max
					end
					if ptab.cpoint_distance_overrides[k2].min then this_length = math.max(this_length, ptab.cpoint_distance_overrides[k2].min) end
					if ptab.cpoint_distance_overrides[k2].max then this_length = math.min(this_length, ptab.cpoint_distance_overrides[k2].max) end
					this_length = math.max(this_length, grip_radius*2)
					//math.Clamp(this_length, ptab.cpoint_distance_overrides[k2].min or this_length, ptab.cpoint_distance_overrides[k2].max or this_length)
				end
				if this_length == nil then this_length = 50 end
				//TODO: if there's multiple cpoints offset from this mainline cpoint, arrange them in an arc or something
				//so they don't overlap each other; haven't found any existing fx that would actually need this
				//if table.Count(tab) > 1 then MsgN("check ", pcf, " ", name, ", it has multiple cpoints offset from the same cpoint") end
				grips[k2] = grips[k] + Vector(0,0,this_length)
			end
		end
	end
	//For plane cpoints, offset each of these a set distance away from everything else in the direction of their plane
	if ptab.cpoint_planes then
		for k, v in pairs (ptab.cpoint_planes) do
			local vec = v[1].normal * -50 //distance is arbitrary
			if v[1].normal.x > 0 then
				vec.x = vec.x + (total_length * v[1].normal.x)
			elseif v[1].normal.x == 0 then
				vec.x = vec.x + (total_length/2)
			end
			grips[k] = Vector(vec)
		end
	end

	local mins, maxs
	for k, v in pairs (grips) do
		if !mins then
			mins = grips[k]
			maxs = grips[k]
		else
			mins = Vector(math.min(mins.x, grips[k].x), math.min(mins.y, grips[k].y), math.min(mins.z, grips[k].z))
			maxs = Vector(math.max(maxs.x, grips[k].x), math.max(maxs.y, grips[k].y), math.max(maxs.z, grips[k].z))
		end
	end
	//Center the grip points and mins/maxs
	local midpoint = (mins + maxs) / 2
	for k, v in pairs (grips) do
		grips[k] = v - midpoint
	end
	mins = mins - midpoint - Vector(grip_radius, grip_radius, grip_radius)
	maxs = maxs - midpoint + Vector(grip_radius, grip_radius, grip_radius)

	return grips, mins, maxs, offset_grips

end

if SERVER then

	function PEPlus_SpawnParticleGripPoints(grips, localpos)
		
		local parent = nil
		for k, pos in pairs (grips) do
			local g = ents.Create("ent_peplus_grip")
			if IsValid(g) then
				g:SetPos(pos + localpos)
				g:Spawn()
				grips[k] = g
				//tab[k].ent = g //no longer valid now that the grip spawning was moved out of SpawnParticle - i think the constraint should handle this anyway
				if !IsValid(parent) then parent = g end
			end
		end
		return grips, parent

	end

	function PEPlus_SpawnParticle(ply, pos, name, pcf_original, path, disableundo)

		//MsgN("PEPlus_SpawnParticle ", name, " ", pcf_original, " ", path)
		if name then name = string.lower(name) end
		if path == "" then path = nil end

		if !IsValid(ply) and pos == nil then
			MsgN("PEPlus_SpawnParticle has no player or position, can't get spawn location")
			return
		end

		if !name or !pcf_original then
			MsgN("PEPlus_SpawnParticle: failed, missing name or pcf (first arg is effect name, second arg is pcf file path starting with particles/ and ending with .pcf, third arg is game path (optional, for conflicting pcfs))")
			return
		end
		local pcf = PEPlus_GetGamePCF(pcf_original, path)
		if !istable(PEPlus_ProcessedPCFs) then
			MsgN("PEPlus_SpawnParticle: failed, no PEPlus_ProcessedPCFs table (this shouldn't happen, report this bug!)")
			return
		elseif !istable(PEPlus_ProcessedPCFs[pcf]) then
			if path then
				MsgN("PEPlus_SpawnParticle: failed, invalid pcf \"", pcf, "\" from game \"", path, "\"" )
			else
				MsgN("PEPlus_SpawnParticle: failed, invalid pcf \"", pcf, "\"")
			end
			return
		elseif !istable(PEPlus_ProcessedPCFs[pcf][name]) then
			if path then
				MsgN("PEPlus_SpawnParticle: failed, invalid effect \"", name, "\" in pcf \"", pcf, "\" from game \"", path, "\"" )
			else
				MsgN("PEPlus_SpawnParticle: failed, invalid effect \"", name, "\" in pcf \"", pcf, "\"")
			end
			return
		end

		if IsValid(ply) and !gamemode.Call("PlayerSpawnParticle", ply, name, pcf_original, path) then return end

		local tab = {}
		for k, v in pairs (PEPlus_ProcessedPCFs[pcf][name].cpoints) do
			if v.mode == PEPLUS_CPOINT_MODE_POSITION then
				tab[k] = {
					ent = nil,
					attach = 0,
					sfx_role = 0,
				}
			elseif v.mode == PEPLUS_CPOINT_MODE_AXIS then
				tab[k] = {
					val = Vector(0,0,0)
				}
				for i = 0, 2 do
					axistab = v["axis_" .. i]
					if istable(axistab) then
						if axistab.default then
							tab[k].val[i+1] = axistab.default
						end
					end
				end
			end
		end

		local grips, mins, maxs = PEPlus_GetParticleDefaultPositions(pcf, name)
		if IsValid(ply) and pos == nil then
			//util.TraceHull returns a nonsense hitpos if we're up against a surface, and doesn't spawn things exactly where we click unless we
			//move all the mins, maxs, and all the grips to put 0,0,0 flat against the surface. Just copy how gmod's prop spawn func does it instead.
			local tr = util.TraceLine({
				start = ply:GetShootPos(),
				endpos = ply:GetShootPos() + (ply:GetAimVector() * 2048),
				filter = {ply, ply:GetVehicle()}
			})
			pos = tr.HitPos

			//copied from gmod's DoPlayerEntitySpawn function (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/commands.lua#L364-L370)
			-- Attempt to move the object so it sits flush
			-- We could do a TraceEntity instead of doing all
			-- of this - but it feels off after the old way
			local vFlushPoint = tr.HitPos - ( tr.HitNormal * -512 )	-- Find a point that is definitely out of the object in the direction of the floor
			vFlushPoint = util.IntersectRayWithOBB(vFlushPoint, pos-vFlushPoint, pos, Angle(), mins, maxs) or pos //ent:NearestPoint( vFlushPoint )	-- Find the nearest point inside the object to that point
			//vFlushPoint = pos - vFlushPoint		-- Get the difference //completely redundant, classic garry
			//vFlushPoint = tr.HitPos - vFlushPoint	-- Add it to our target pos
			pos = vFlushPoint
			
			//modified version of local functions TryFixPropPosition/fixupProp, from the same file (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/commands.lua#L29)
			-- A little hacky function to help prevent spawning props partially inside walls
			local function fixupParticle( ply, pos, mins, maxs )
				local endposD = mins + pos
				local tr_down = util.TraceLine( {
					start = pos,
					endpos = endposD,
					filter = { ply }
				} )

				local endposU = maxs + pos
				local tr_up = util.TraceLine( {
					start = pos,
					endpos = endposU,
					filter = { ply }
				} )

				-- Both traces hit meaning we are probably inside a wall on both sides, do nothing
				if ( tr_up.Hit && tr_down.Hit ) then return pos end

				if ( tr_down.Hit ) then pos = pos + ( tr_down.HitPos - endposD ) end
				if ( tr_up.Hit ) then pos = pos + ( tr_up.HitPos - endposU ) end

				return pos
			end
			pos = fixupParticle( ply, pos, Vector( mins.x, 0, 0 ), Vector( maxs.x, 0, 0 ) )
			pos = fixupParticle( ply, pos, Vector( 0, mins.y, 0 ), Vector( 0, maxs.y, 0 ) )
			pos = fixupParticle( ply, pos, Vector( 0, 0, mins.z ), Vector( 0, 0, maxs.z ) )
		end

		local parent = nil
		grips, parent = PEPlus_SpawnParticleGripPoints(grips, pos)

		local p = ents.Create("ent_peplus")
		if !IsValid(p) then return end
		p:SetPlayer(ply)
		p:SetParticleName(name)
		p:SetPCF(pcf_original)
		p:SetPath(path or "")
		//Set NWVar defaults
		if pcf != "UtilFx" then
			p:SetLoopMode(1)
			p:SetLoopDelay(0)
		else
			//utilfx don't support mode 1 (wait for end of effect) because we don't have a way to tell when a util effect is over, so use mode 2 (just a timer) instead
			local time = PEPlus_ProcessedPCFs[pcf][name].default_time
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
		p:SetPauseTime(-1)
		p.ParticleInfo = tab
		p:Spawn()

		for k, v in pairs (grips) do
			constraint.PEPlus_Ent(p, v, k, parent == v, ply)
		end

		if IsValid(ply) then
			gamemode.Call("PlayerSpawnedParticle", ply, name, pcf_original, path, p)
			if !disableundo then
				undo.Create("PEPlus")
					undo.SetPlayer(ply)
					undo.AddEntity(p)
					local str = tostring(pcf_original)
					if pcf != pcf_original then
						str = str .. " (" .. tostring(path) .. ")"
					end
				undo.Finish("Particle Effect (" .. tostring(name) .. " (" .. str .. "))")
				ply:AddCleanup("peplus", p)
			end
		end

		return p

	end

	//Console command for contenticon_peplus to spawn particles
	concommand.Add("peplus_spawnparticle", function(ply, cmd, args)
		PEPlus_SpawnParticle(ply, nil, args[1], args[2], args[3])
	end, nil, "Spawns a particle effect; first arg is effect name, second arg is pcf file path starting with particles/ and ending with .pcf, third arg is game path (optional, for conflicting pcfs)")

	//Add hooks for these, in case someone wants to selectively prevent players from spawning particles
	function GAMEMODE:PlayerSpawnParticle(ply, name, pcf, path)
		local function LimitReachedProcess()
			if !IsValid(ply) then return true end
			return ply:CheckLimit("peplus")
		end
		return LimitReachedProcess()
	end

	function GAMEMODE:PlayerSpawnedParticle(ply, name, pcf, path, ent)
		ply:AddCount("peplus", ent)
	end

end




//Function override for SetColor: set all color vector cpoints to the color value, so players can recolor them with the color tool instead of the edit window

if SERVER then

	local meta = FindMetaTable("Entity")

	local old_SetColor = meta.SetColor
	if old_SetColor then

		function meta:SetColor(color, ...)

			if isentity(self) and IsValid(self) and self.PEPlus_Grip then
				local tab = constraint.FindConstraint(self, "PEPlus_Ent")
				if istable(tab) then
					local ent = tab.Ent1
					if IsValid(ent) and ent.PEPlus_Ent and istable(ent.ParticleInfo) and istable(PEPlus_ProcessedPCFs) then
						local pcf = PEPlus_GetGamePCF(ent:GetPCF(), ent:GetPath())
						local name = ent:GetParticleName()
						if !istable(PEPlus_ProcessedPCFs[pcf]) or !istable(PEPlus_ProcessedPCFs[pcf][name]) then return end
						local ptab = PEPlus_ProcessedPCFs[pcf][name]
						local refreshtable = false
						local color2 = Vector(color.r/255, color.g/255, color.b/255)
						for k, v in pairs (ent.ParticleInfo) do
							if ptab.cpoints[k].mode == PEPLUS_CPOINT_MODE_AXIS then
								for i = 0, 2 do
									local tab = ptab.cpoints[k]["axis_" .. i]
									if istable(tab) and tab.colorpicker then
										ent.ParticleInfo[k].val[i+1] = math.Remap(color2[i+1], tab.outMin2, tab.outMax2, tab.inMin, tab.inMax)
										refreshtable = true
									end
								end
							end
						end
						if refreshtable then
							//Tell clients to retrieve the updated info table
							net.Start("PEPlus_InfoTableUpdate_SendToCl")
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




if GetConVarNumber("developer") >= 1 then MsgN("Particle Effects+: running entity code") end

//See PEPlus_ReadAndProcessPCFs comments in pcf_processing.lua

if !PEPlus_ReadAndProcessPCFs_StartupHasRun then
	PEPlus_ReadAndProcessPCFs()
end

timer.Simple(0, function()
	if GetConVarNumber("developer") >= 1 then MsgN("Particle Effects+: running entity code on timer") end
	PEPlus_ReadAndProcessPCFs_StartupIsOver = true
end)