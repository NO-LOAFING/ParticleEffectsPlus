if CLIENT then

	//Wrapper for game.AddParticles - this way, a lot of spawnicons or particle entities created at once can all try to run game.AddParticles at the 
	//same time, but won't unnecessarily run it more than once for the same .pcf file at one time.
	//Works on a "queuing" system, where each spawnicon/ent adds the relevant pcf to a table, and a Think hook loops through this table cleaning 
	//up all pre-existing fx that could cause crashes, then - once we're sure they're gone - runs game.AddParticles for each pcf in the table.
	
	local AddParticles_Queued = {}
	local AddParticles_QueuedTime = nil
	PartCtrl_AddParticles_CrashCheck = {}
	PartCtrl_AddParticles_CrashCheck_ThrottledPCFs = {}
	PartCtrl_AddParticles_AddedParticles = PartCtrl_AddParticles_AddedParticles or {}
	PartCtrl_AddParticles_AddedParticles_Overrides = PartCtrl_AddParticles_AddedParticles_Overrides or {}

	function PartCtrl_AddParticles(pcf, effectname) //optional effectname arg for spawnicons and particle entities, which usually only care about conflicts with their one effect

		if !istable(PartCtrl_ProcessedPCFs[pcf]) then return end
		if effectname and !istable(PartCtrl_ProcessedPCFs[pcf][effectname]) then return end

		local doaddparticles = false
		local key2 = table.KeyFromValue(AddParticles_Queued, pcf)
		if key2 then
			if key2 == #AddParticles_Queued then
				//this pcf is already queued and already the most recent entry to the list, no need to do more
				return
			else
				doaddparticles = true
				table.remove(AddParticles_Queued, key2)
			end
		end

		//MsgN("old PartCtrl_AddParticles_AddedParticles: ")
		//PrintTable(PartCtrl_AddParticles_AddedParticles)
		//We only want to run game.AddParticles if A: we haven't loaded this pcf before, 
		//or B: since we last loaded it, another pcf has been loaded that overrode one of its effects, so we load this one again to un-override the effect
		local key = table.KeyFromValue(PartCtrl_AddParticles_AddedParticles, pcf)
		if key == nil then
			//MsgN(pcf .. " hasn't been added before, time to do AddParticles")
			doaddparticles = true
		end
		//Get a list of all the pcfs that override one of our effects
		if !istable(PartCtrl_AddParticles_AddedParticles_Overrides[pcf]) then
			local tab = {}
			for name, _ in pairs (PartCtrl_ProcessedPCFs[pcf]) do
				for _, v in pairs (PartCtrl_PCFsByParticleName[name]) do
					tab[v] = true
				end
			end
			for name, _ in pairs (PartCtrl_CulledFx[pcf]) do
				for _, v in pairs (PartCtrl_PCFsByParticleName[name]) do
					tab[v] = true
				end
			end
			tab[pcf] = nil
			PartCtrl_AddParticles_AddedParticles_Overrides[pcf] = tab
			//PrintTable(tab)
		end
		if !doaddparticles then
			local tab = {}
			if effectname then
				//If this function is being called by a spawnicon or particle entity, then only check its one effect for overrides.
				//Otherwise, we don't care, and running game.AddParticles(pcf) again would just cause an unnecessary stutter.
				if !(PartCtrl_PCFsByParticleName_CurrentlyLoaded[effectname] == pcf)
				and !(PartCtrl_DuplicateFx[pcf][effectname] and PartCtrl_PCFsByParticleName_CurrentlyLoaded[effectname] == PartCtrl_DuplicateFx[pcf][effectname]) then
					for _, v in pairs (PartCtrl_PCFsByParticleName[effectname]) do
						tab[v] = true
					end
					tab[pcf] = nil
					//MsgN("tab for effect ", effectname, ":")
					//PrintTable(tab)
				end
			else
				tab = PartCtrl_AddParticles_AddedParticles_Overrides[pcf]
			end
			if table.Count(tab) > 0 then
				for k, v in SortedPairs (PartCtrl_AddParticles_AddedParticles) do
					if k > key and tab[v] then
						//MsgN(k .. " " .. v .. " is greater than " .. key .. " " .. pcf .. ", time to do AddParticles")
						doaddparticles = true
						break
					end
				end
			end
		end

		if doaddparticles then
			//Queue this pcf to be game.AddParticles'd - this is handled in the think hook below.
			//This queuing system lets every effect in a spawnlist run this function at once and queue every applicable
			//pcf, without any of those pcfs getting game.AddParticles'd multiple times at once and causing a stutter.
			if key2 then
				table.remove(AddParticles_Queued, key2) //make sure the most recently called pcf takes precedence (i.e. if swapping between multiple pcf spawnlists with conflicting fx, make sure the one we clicked on last has the right fx when we call game.AddParticles)
			end
			table.insert(AddParticles_Queued, pcf)
			//Crash prevention: throttle effects from the queued pcf, and all pcfs it conflicts with
			PartCtrl_AddParticles_CrashCheck_ThrottledPCFs[pcf] = true
			table.Merge(PartCtrl_AddParticles_CrashCheck_ThrottledPCFs, PartCtrl_AddParticles_AddedParticles_Overrides[pcf])

			//Also move the pcf to the end of the AddedParticles list
			if key then
				table.remove(PartCtrl_AddParticles_AddedParticles, key)
			end
			table.insert(PartCtrl_AddParticles_AddedParticles, pcf)

			local allfx = {}
			for k, _ in pairs (PartCtrl_ProcessedPCFs[pcf]) do
				allfx[k] = true
			end
			for k, _ in pairs (PartCtrl_CulledFx[pcf]) do
				allfx[k] = true
			end
			for effectname, _ in pairs (allfx) do
				if PartCtrl_DuplicateFx[pcf][effectname] then
					PartCtrl_PCFsByParticleName_CurrentlyLoaded[effectname] = PartCtrl_DuplicateFx[pcf][effectname]
				else
					PartCtrl_PCFsByParticleName_CurrentlyLoaded[effectname] = pcf
				end
			end

			AddParticles_QueuedTime = CurTime()
		end

	end

	//Function override for game.AddParticles, mostly so when another addon loads a pcf, we can tell when it overrides an effect
	//TODO: if some other addon's entity works by running game.AddParticles when the entity spawns instead of on autorun for some reason, then 
	//our delayed-load crash prevention system could hypothetically cause issues if it expects to be able to create its particle fx immediately. 
	//revisit this if we find any instances of this actually happening!
	local old_AddParticles = game.AddParticles
	if old_AddParticles then
		game.AddParticles = function(pcf)
			if !PartCtrl_ProcessedPCFs then
				//If another addon loads a pcf before we've built PartCtrl_ProcessedPCFs, just load it normally
				//TODO: do we want to do something with these? if there are effect-replacement addons deliberately trying to override
				//stock fx with fx from their own pcf, then we'll want to keep track of them here, then reload them in the same order 
				//again after PartCtrl_ReadAndProcessPCFs, to make sure we don't break their overrides. revisit this if we find any 
				//addons we need to do this for!
				//MsgN("mounting ", pcf, " before partctrl startup")
				old_AddParticles(pcf)
				return
			end
			//MsgN("mounting ", pcf, " after partctrl startup")
			PartCtrl_AddParticles(pcf)
		end
	end

	hook.Add("Think", "PartCtrl_AddParticles_Think", function()

		if #AddParticles_Queued > 0 then
			local time = CurTime()
			local delay = nil

			if !PartCtrl_DoneFirstPrecache then
				//MsgN("skipping")
				//if we're loading pcfs on startup, then don't waste time searching for old fx to clean up
				delay = 0
			else
				//MsgN("not skipping")
				delay = 0.1
				//Crash prevention:
				//Internally, when gmod loads a new pcf from game.AddParticles, and that pcf overrides any effect names, any existing particlesystems using those effects are forcibly stopped. If too 
				//many unique effects are stopped at once by the engine this way, it can crash. If our panel/entity code recreates them too soon after the engine stops them, it can also crash. 
				//Finally, if there are too many existing particlesystems that simply share a pcf with one being overridden, then it can also crash (why? the engine doesn't even remove these ones!).
				//To get around all this, we first remove all the offending particlesystems ourselves, then call game.AddParticles a frame later, after we can be sure they're all gone.
				for v, _ in pairs (PartCtrl_AddParticles_CrashCheck_ThrottledPCFs) do
					if istable(PartCtrl_AddParticles_CrashCheck[v]) then
						for k2, v2 in pairs (PartCtrl_AddParticles_CrashCheck[v]) do
							if k2 and k2:IsValid() then
								//MsgN(time, " ", k2, " removed")
								AddParticles_QueuedTime = time
								k2:StopEmissionAndDestroyImmediately()
								//surface.PlaySound("vo/ravenholm/monk_danger01.wav")
							else
								//Don't remove fx from the list until we're absolutely sure they're gone; some of them can
								//be really stubborn, try swapping between spawnlists for blood_impact.pcf and its tf2 version
								PartCtrl_AddParticles_CrashCheck[v][k2] = nil
							end
						end
					end
				end
			end

			if AddParticles_QueuedTime != nil and time > (AddParticles_QueuedTime + delay) then
				for _, pcf in ipairs (AddParticles_Queued) do
					//surface.PlaySound("vo/ravenholm/engage03.wav")
					//MsgN("running game.AddParticles for ", pcf)
					old_AddParticles(pcf)
				end
				AddParticles_Queued = {}
				AddParticles_QueuedTime = nil
				PartCtrl_AddParticles_CrashCheck_ThrottledPCFs = {}
				//Stupid fix: the first time PrecacheParticleSystem is run by anything, it will cause a substantial stutter, 
				//so get it over with during map load instead of disrupting gameplay the first time the player opens a spawnlist or something.
				if !PartCtrl_DoneFirstPrecache then
					PrecacheParticleSystem("")
					PartCtrl_DoneFirstPrecache = true
				end
			end
		end

	end)

end