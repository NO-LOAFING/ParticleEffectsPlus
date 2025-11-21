AddCSLuaFile()

//Populate the spawn menu with a list of all the .pcf files, sorted by the game or addon they're from

if CLIENT then

	local browseAddonParticles
	local browseGameParticles
	local searchParticles = nil
	local RefreshAddonParticles
	local RefreshGameParticles

	local cv_childfx_spawnlist = GetConVar("cl_partctrl_childfx_in_autospawnlists")

	local function OnParticleNodeSelected(pcf, path, ViewPanel, pnlContent)
		ViewPanel:Clear(true)
		local pcf2 = PartCtrl_GetGamePCF(pcf, path)
		//MsgN("running OnParticleNodeSelected for ", pcf, ", ", path)

		if !istable(PartCtrl_ProcessedPCFs[pcf2]) then
			MsgN("OnParticleNodeSelected tried to make spawnlist for invalid pcf ", pcf2)
		else
			local dochildfx = cv_childfx_spawnlist:GetInt()
			if dochildfx == 0 then
				//No child fx
				for particle, _ in PartCtrl_SortedPairsLower (PartCtrl_ProcessedPCFs[pcf2]) do //sort them in alphabetical order
					if !PartCtrl_ProcessedPCFs[pcf2][particle].parents or table.Count(PartCtrl_ProcessedPCFs[pcf2][particle].parents) < 1 then
						spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["pcf"] = pcf, ["name"] = particle, ["path"] = path})
					end
				end
			elseif dochildfx == 1 then
				local tab = {}
				//Separate child fx
				for particle, _ in PartCtrl_SortedPairsLower (PartCtrl_ProcessedPCFs[pcf2]) do //sort them in alphabetical order
					if !PartCtrl_ProcessedPCFs[pcf2][particle].parents or table.Count(PartCtrl_ProcessedPCFs[pcf2][particle].parents) < 1 then
						spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["pcf"] = pcf, ["name"] = particle, ["path"] = path})
					else
						table.insert(tab, particle)
					end
				end
				if table.Count(tab) > 0 then
					spawnmenu.CreateContentIcon("header", ViewPanel, {["text"] = "Child effects"})
					for k, particle in pairs (tab) do
						spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["pcf"] = pcf, ["name"] = particle, ["path"] = path})
					end
				end
			else
				//All fx sorted alphabetically
				for particle, _ in PartCtrl_SortedPairsLower (PartCtrl_ProcessedPCFs[pcf2]) do //sort them in alphabetical order
					spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["pcf"] = pcf, ["name"] = particle, ["path"] = path})
				end
			end
		end

		pnlContent:SwitchPanel(ViewPanel)
		ViewPanel.CurrentPCF = pcf2 //used by developer click-to-refresh-pcf function
		ViewPanel.CurrentPath = path //^

	end

	local function OnUtilFxNodeSelected(name, ViewPanel, pnlContent)

		ViewPanel:Clear(true)

		if !istable(PartCtrl_UtilFxByTitle[name]) then
			MsgN("OnUtilFxNodeSelected tried to make spawnlist for invalid title ", name)
		else
			for particle, _ in PartCtrl_SortedPairsLower (PartCtrl_UtilFxByTitle[name]) do //sort them in alphabetical order
				spawnmenu.CreateContentIcon("partctrl", ViewPanel, {["pcf"] = "UtilFx", ["name"] = particle})
			end
		end

		pnlContent:SwitchPanel(ViewPanel)
		ViewPanel.CurrentPCF = "UtilFx" //used by developer click-to-refresh-pcf function
		ViewPanel.CurrentPath = nil //^
		ViewPanel.CurrentUtilFxName = name //^

	end

	function PartCtrl_CreateCustomSpawnlist(tab, name, icon) //globally available so we can use it to make arbitrary spawnlists for testing

		local tab2 = {}

		local dochildfx = cv_childfx_spawnlist:GetInt()
		if dochildfx == 0 then
			//No child fx
			for k, v in pairs (tab) do
				local pcf2 = PartCtrl_GetGamePCF(v.pcf, v.path)
				if !PartCtrl_ProcessedPCFs[pcf2][v.particle].parents or table.Count(PartCtrl_ProcessedPCFs[pcf2][v.particle].parents) < 1 then
					table.insert(tab2, {["type"] = "partctrl", ["pcf"] = v.pcf, ["name"] = v.particle, ["path"] = v.path})
				end
			end
		elseif dochildfx == 1 then
			//Separate child fx
			local tab3 = {}
			for k, v in pairs (tab) do
				local pcf2 = PartCtrl_GetGamePCF(v.pcf, v.path)
				if !PartCtrl_ProcessedPCFs[pcf2][v.particle].parents or table.Count(PartCtrl_ProcessedPCFs[pcf2][v.particle].parents) < 1 then
					table.insert(tab2, {["type"] = "partctrl", ["pcf"] = v.pcf, ["name"] = v.particle, ["path"] = v.path})
				else
					table.insert(tab3, {["type"] = "partctrl", ["pcf"] = v.pcf, ["name"] = v.particle, ["path"] = v.path})
				end
			end
			if table.Count(tab3) > 0 then
				table.insert(tab2, {["type"] = "header", ["text"] = "Child effects"})
				table.Add(tab2, tab3)
			end
		else
			//All fx sorted alphabetically
			for k, v in pairs (tab) do
				tab2[k] = {["type"] = "partctrl", ["pcf"] = v.pcf, ["name"] = v.particle, ["path"] = v.path}
			end
		end

		AddPropsOfParent(g_SpawnMenu.CustomizableSpawnlistNode.SMContentPanel, g_SpawnMenu.CustomizableSpawnlistNode, 0, {[name] = {
			icon = icon or "icon16/page.png",
			id = math.random( 0, 999999 ), -- Eeehhhh
			name = name,
			parentid = 0,
			contents = tab2
		}})
	
		-- We added a new spawnlist, show the save changes button
		hook.Run("SpawnlistContentChanged")

	end

	//Most of the spawnmenu code here this is ripped off wholesale from the Enhanced Spawnmenu addon - this is lame but I've gone over all the code and there's really no reason
	//to reinvent the wheel here, it does everything we need it to do

	local function AddBrowseContentParticle(node, name, icon, path, pathid, wsid, is_game_folder)

		local ViewPanel = node.ViewPanel
		local pnlContent = node.pnlContent

		if !string.EndsWith(path, "/") && string.len(path) > 1 then path = path .. "/" end

		local fi, fo = file.Find(path .. "particles", pathid)
		if (!fi && !fo) and !PartCtrl_UtilFxByTitle[name] then return end

		local particles = node:AddFolder(name, path .. "particles", pathid, true, false, "*.*") //unlike ES, the arg after pathid is true, which adds nodes for files as well
		particles:SetIcon(icon)
		particles.is_game_folder = is_game_folder

		particles.FilePopulateCallback = function(self, files, folders, foldername, path, bAndChildren, wildcard) //based on DTree_Node.FilePopulateCallback (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dtree_node.lua#L448)
			local showfiles = self:GetShowFiles()

			self.ChildNodes:InvalidateLayout(true)
		
			local FileCount = 0
		
			if folders then
				for k, File in SortedPairsByValue (folders) do
					local Node = self:AddNode(File)
					Node:MakeFolder(string.Trim( foldername .. "/" .. File, "/" ), path, showfiles, wildcard, true)
					Node.FilePopulateCallback = particles.FilePopulateCallback
					FileCount = FileCount + 1
				end
			end
		
			if showfiles then
				//Create unique node for utilfx
				if !particles.utilfxnode and PartCtrl_UtilFxByTitle[name] then
					//MsgN("making utilfx node for ", name)
					particles.utilfxnode = particles:AddNode("Scripted Effects", "icon16/page_gear.png")
					particles.utilfxnode.utilfx = true
					FileCount = FileCount + 1
					particles.utilfxnode.DoRightClick = function()
						if !IsValid(particles.utilfxnode) then return end
						local menu = DermaMenu()

						menu:AddOption("#spawnmenu.createautospawnlist", function()
							local tab = {}
							for particle, _ in PartCtrl_SortedPairsLower (PartCtrl_UtilFxByTitle[name]) do //sort them in alphabetical order
								table.insert(tab, {["pcf"] = "UtilFx", ["particle"] = particle})
							end
							PartCtrl_CreateCustomSpawnlist(tab, "Scripted Effects", "icon16/page_gear.png")
						end):SetIcon("icon16/page_add.png")

						//developer control to reload a .pcf file manually; we want this for utilfx too just in case one of the list entries was edited
						if GetConVarNumber("developer") >= 1 then
							menu:AddOption("Reload UtilFx", function()
								RunConsoleCommand("partctrl_reloadpcf", "UtilFx")
							end)
						end

						menu:Open()
					end
				end

				//Legacy addons will have a file path starting with the addon folder instead of the particle folder, so trim that stuff out
				//(i.e. turn addons/test_onlyparticles/particles/ukmovement.pcf into particles/ukmovement.pcf)
				if !string.StartsWith(foldername, "particles") then
					local start, _, _ = string.find(foldername, "/particles", 1, true) //this will break if someone names a legacy addon literally just "particles", OH WELL
					if start == nil then
						//if we got a nonsense folder somehow, then back out now
						showfiles = false
						self:SetShowFiles(nil)
					else
						foldername = string.sub(foldername, start + 1)
					end
				end

				if showfiles then
					local function AddFile(name, filename, path)
						//Clear out .txt file particle manifests and such, also clear out bad .pcf files that weren't processed
						local filename2 = PartCtrl_GetGamePCF(filename, path)
						if !istable(PartCtrl_ProcessedPCFs[filename2]) then return end

						local Node = self:AddNode(name, "icon16/page.png")
						Node:SetFileName(filename)
						Node.path = path
						FileCount = FileCount + 1
						Node.DoRightClick = function()
							if !IsValid(Node) then return end
							local menu = DermaMenu()

							menu:AddOption("Copy .pcf file path to clipboard", function() 
								SetClipboardText(filename)
							end):SetIcon("icon16/page_copy.png")

							if filename != filename2 then
								menu:AddOption("Copy internal .pcf file path to clipboard", function() 
									SetClipboardText(filename2)
								end):SetIcon("icon16/page_copy.png")
							end

							menu:AddOption("#spawnmenu.createautospawnlist", function()
								local tab = {}
								for particle, _ in PartCtrl_SortedPairsLower (PartCtrl_ProcessedPCFs[filename2]) do //sort them in alphabetical order
									table.insert(tab, {["pcf"] = filename, ["particle"] = particle, ["path"] = path})
								end
								PartCtrl_CreateCustomSpawnlist(tab, name)
							end):SetIcon("icon16/page_add.png")

							//developer control to reload a .pcf file manually
							if GetConVarNumber("developer") >= 1 then
								menu:AddSpacer()

								menu:AddOption("Reload " .. filename2, function()
									RunConsoleCommand("partctrl_reloadpcf", filename2)
								end)
							end

							menu:Open()
						end
					end
			
					for k, name in SortedPairs (files) do
						local tab = {}
						local pcf = string.Trim(foldername .. "/" .. name, "/")
						local file_path = PartCtrl_GamePCFs_DefaultPaths[pcf] 
						//note: due to how this is implemented, this means if a game has an identical copy of a higher-priority 
						//game's pcf, it will use that game's path instead. (i.e hl2 has a bunch of duplicates of gmod pcfs, so 
						//if you open a spawnlist for any of these pcfs, none of them will have the "hl2" path like the other hl2
						//pcfs do) i don't *think* there are any situations where this is a problem, but *maybe* this could cause
						//issues with some weird combination of mounted game changes between sessions? not sure.
						////test
						//if PartCtrl_ProcessedPCFs[pcf] and file_path != path then
						//	MsgN(path, "'s ", pcf, " is from ", file_path, "!")
						//end

						//For the "All" folder, add every data pcf for this file, in addition to the mounted pcf file
						if path == "GAME" and PartCtrl_GamePCFs[pcf] then
							for path2, pcf2 in pairs (PartCtrl_GamePCFs[pcf]) do
								if pcf2 != pcf then
									table.insert(tab, {
										["name"] = name .. " (" .. path2  .. ")", ["pcf"] = pcf, ["path"] = path2
									})
								end
							end
						end

						if self.is_game_folder and PartCtrl_GetGamePCF(pcf, path) != pcf then
							//For game folders, if this game is using a data pcf for this file, always label it
							//(and set the right file_path to make our spawnlist use it)
							name = name .. " (" .. path  .. ")"
							file_path = path
						//elseif #tab > 0 and file_path then 
						//	//For the "All" folder, if there are multiple entries and they're all from games, 
						//	//then label the first one too if applicable
						//	name = name .. " (" .. file_path  .. ")"
						//elseif !self.is_game_folder and file_path then
						//	//or maybe *every* game pcf in the "All" folder should be labeled, just so the names 
						//	//stay consistent between sessions as you mount different games? 
						//	name = name .. " (" .. file_path  .. ")"
						end

						table.insert(tab, 1, {
							["name"] = name, ["pcf"] = pcf, ["path"] = file_path
						})
						for _, v in pairs (tab) do
							AddFile(v.name, v.pcf, v.path)
						end
					end
				end
			end
		
			if FileCount == 0 then
				if name != "#spawnmenu.category.downloads" then
					//clear out folders that generate empty - checking fi/fo up above doesn't work because some games (ep1) have empty tables even though they have files(??)
					//this looks kind of bad because you can see the folders appear and then disappear, but i don't know what a better solution would be
					self:Remove()
				else
					//default empty folder behavior
					self.ChildNodes:Remove()
					self.ChildNodes = nil
			
					self:SetNeedsPopulating(false)
					self:SetShowFiles(nil)
					self:SetWildCard(nil)
			
					self:InvalidateLayout()
			
					self.Expander:SetExpanded(true)
		
					return
				end
			end
		
			self:InvalidateLayout()
		end

		particles.OnNodeSelected = function(self, node_sel)
			local name2 = node_sel:GetFileName() //returns nil if the selected node was a folder - we only want files to be selectable
			if name2 != nil and string.find(name2, ".pcf") then
				OnParticleNodeSelected(name2, node_sel.path, ViewPanel, pnlContent)
			elseif node_sel.utilfx then
				OnUtilFxNodeSelected(name, ViewPanel, pnlContent)
			end
		end

		if wsid then
			particles.DoRightClick = function()
				local menu = DermaMenu()
				menu:AddOption("#spawnmenu.openaddononworkshop", function()
					steamworks.ViewFile(wsid)
				end):SetIcon("icon16/link_go.png")
				menu:Open()
			end
		end

	end

	language.Add("spawnmenu.category.browseparticles", "Browse Particles")

	RefreshAddonParticles = function(node)
		for _, addon in SortedPairsByMemberValue(engine.GetAddons(), "title") do
			if !addon.downloaded then continue end
			if !addon.mounted then continue end
			if !table.HasValue(select(2, file.Find("*", addon.title)), "particles") and !PartCtrl_UtilFxByTitle[addon.title] then continue end
			AddBrowseContentParticle(node, addon.title, "icon16/bricks.png", "", addon.title, addon.wsid)
		end
	end
	RefreshGameParticles = function(node)
		local games = engine.GetGames()
		table.insert(games, {
			title = "All",
			folder = "GAME",
			icon = "all",
			mounted = true,
		})
		table.insert(games, {
			title = "Garry's Mod",
			folder = "garrysmod",
			mounted = true,
		})
		for _, game in SortedPairsByMemberValue(games, "title") do
			if !game.mounted then continue end
			AddBrowseContentParticle(node, game.title, "games/16/" .. (game.icon or game.folder) .. ".png", "", game.folder, nil, game.folder != "GAME")
		end
	end

	hook.Add("PopulateContent", "PartCtrl_PopulateContent", function(pnlContent, tree, browseNode) timer.Simple(0.5, function()

		if (!IsValid(tree) or !IsValid(pnlContent) or !istable(PartCtrl_ProcessedPCFs)) then //check to make sure PartCtrl_ProcessedPCFs exists because AddBrowseContentParticle needs it
			print("ParticleControl: Failed to initialize PopulateContent hook")
			return
		end

		local ViewPanel = vgui.Create("ContentContainer", pnlContent)
		ViewPanel:SetVisible(false)
		ViewPanel.IconList:SetReadOnly(true) //not in enhanced spawnmenu; prevents contenticons in pcf spawnlists from being deleted using dropdown
		//Make these globally accessible so the developer pcf refresh button can access them
		PartCtrl_ViewPanel = ViewPanel
		ViewPanel.pnlContent = pnlContent

		local browseParticles = tree:AddNode("#spawnmenu.category.browseparticles", "icon16/fire.png")
		browseParticles.ViewPanel = ViewPanel
		browseParticles.pnlContent = pnlContent


		browseAddonParticles = browseParticles:AddNode("#spawnmenu.category.addons", "icon16/folder_database.png")
		browseAddonParticles.ViewPanel = ViewPanel
		browseAddonParticles.pnlContent = pnlContent

		RefreshAddonParticles(browseAddonParticles)


		local addon_particles = {}
		local _, particle_folders = file.Find("addons/*", "MOD")
		for _, addon in SortedPairs(particle_folders) do
			if !file.IsDir("addons/" .. addon .. "/particles/", "MOD") and !PartCtrl_UtilFxByTitle[addon] then continue end
			table.insert(addon_particles, addon)
		end

		local browseLegacyParticles = browseParticles:AddNode("#spawnmenu.category.addonslegacy", "icon16/folder_database.png")
		browseLegacyParticles.ViewPanel = ViewPanel
		browseLegacyParticles.pnlContent = pnlContent

		for _, addon in SortedPairsByValue(addon_particles) do
			AddBrowseContentParticle(browseLegacyParticles, addon, "icon16/bricks.png", "addons/" .. addon .. "/", "MOD")
		end


		AddBrowseContentParticle(browseParticles, "#spawnmenu.category.downloads", "icon16/folder_database.png", "download/", "MOD")


		browseGameParticles = browseParticles:AddNode("#spawnmenu.category.games", "icon16/folder_database.png")
		browseGameParticles.ViewPanel = ViewPanel
		browseGameParticles.pnlContent = pnlContent

		RefreshGameParticles(browseGameParticles)


		browseParticles:SetExpanded(true)

		if GetConVarNumber("developer") >= 1 then MsgN("PartCtrl: running PopulateContent") end

	end) end)

	local cv_childfx_search = GetConVar("cl_partctrl_childfx_in_search")
	local cv_dupes_search = GetConVar("cl_partctrl_dupes_in_search")

	search.AddProvider(function(str)

		local searchTerms = string.Explode(" ", str)

		if searchParticles == nil then
			searchParticles = {}
			for pcf, _ in SortedPairs (PartCtrl_ProcessedPCFs) do
				if !PartCtrl_AllDataPCFs[pcf] then
					for particle, _ in PartCtrl_SortedPairsLower (PartCtrl_ProcessedPCFs[pcf]) do
						table.insert(searchParticles, {
							["name"] = particle, 
							["searchtext"] = particle:lower() .. " " .. pcf:lower(), //lowercase needs to be separate, because effect names are case-sensitive when spawning them
							["pcf"] = pcf,
							["path"] = PartCtrl_GamePCFs_DefaultPaths[pcf] //optional, can be nil
						}) 
					end
				else
					for particle, _ in PartCtrl_SortedPairsLower (PartCtrl_ProcessedPCFs[pcf]) do
						table.insert(searchParticles, {
							["name"] = particle, 
							["searchtext"] = particle:lower() .. " " .. pcf:lower() .. " " .. PartCtrl_GetDataPCFNiceName(pcf):lower(), //let us search for both the nicename and internal name
							["pcf"] = PartCtrl_AllDataPCFs[pcf].original_filename,
							["path"] = PartCtrl_AllDataPCFs[pcf].path
						}) 
					end
				end
			end
		end

		local results = {}

		for k, v in ipairs (searchParticles) do
			local pcf = PartCtrl_GetGamePCF(v.pcf, v.path)
			if (cv_childfx_search:GetBool() or !PartCtrl_ProcessedPCFs[pcf][v.name].parents or table.Count(PartCtrl_ProcessedPCFs[pcf][v.name].parents) < 1) 
			and (cv_dupes_search:GetBool() or !PartCtrl_DuplicateFx[pcf] or !PartCtrl_DuplicateFx[pcf][v.name]) then
				for k2, v2 in ipairs (searchTerms) do
					if !v.searchtext:find(v2, nil, true) then
						break
					elseif k2 == #searchTerms then
						local entry = {
							text = v.name,
							icon = spawnmenu.CreateContentIcon("partctrl", g_SpawnMenu.SearchPropPanel, {["pcf"] = v.pcf, ["name"] = v.name, ["path"] = v.path}),
							words = {v.name}
						}
						table.insert(results, entry)
					end
				end
			end
			if #results >= GetConVarNumber("sbox_search_maxresults") / 2 then break end
		end

		return results

	end, "partctrl")




	//PCF reloading functions; these would be in pcf_processing, except they have to be able to access a bunch of spawnmenu-related local vars

	function PartCtrl_ReloadPCF(str)

		if str == "all" then
			MsgN("PartCtrl: Reloading all PCFs on client ", LocalPlayer())

			if PartCtrl_ReadAndProcessPCFs_StartupIsOver or !PartCtrl_ReadAndProcessPCFs_StartupHasRun then
				PartCtrl_ReadAndProcessPCFs()
			end

			//Spawnlist stuff from enhanced spawnmenu
			if IsValid(browseAddonParticles) then
				-- TODO: Maybe be more advaced and do not delete => recreate all the nodes, only delete nodes for addons that were removed, add only the new ones?
				browseAddonParticles:Clear()
				browseAddonParticles.ViewPanel:Clear(true)

				RefreshAddonParticles(browseAddonParticles)
			end
			if IsValid(browseGameParticles) then
				-- TODO: Maybe be more advaced and do not delete => recreate all the nodes, only delete nodes for addons that were removed, add only the new ones?
				browseGameParticles:Clear()
				browseGameParticles.ViewPanel:Clear(true)

				RefreshGameParticles(browseGameParticles)
			end

			//Search stuff
			searchParticles = nil
		else
			MsgN("PartCtrl: Reloading ", str, " on client ", LocalPlayer())

			if str != "UtilFx" then
				PartCtrl_ProcessedPCFs[str] = PartCtrl_ProcessPCF(str)
			else
				PartCtrl_ProcessUtilFx()
			end
			searchParticles = nil //force search to rebuild search cache so any new fx will be found

			if str != "UtilFx" then
				//Handle duplicate fx detection again; it's possible that an effect was updated to start/stop being a dupe, OR that an 
				//effect being updated made an effect from a lower-priority PCF start/stop being considered a dupe of this pcf's effect
				PartCtrl_GetDuplicateFx()

				//Make sure the reloaded pcf is highest priority
				//(try to prevent oddness with PartCtrl_PCFsByParticleName_CurrentlyLoaded on fx that change dupe status)
				PartCtrl_AddParticles(str)
			end

			//if this pcf's auto-generated spawnlist is currently open, then rebuild it (to handle fx being added to or removed from the list)
			if IsValid(PartCtrl_ViewPanel) and IsValid(PartCtrl_ViewPanel.pnlContent) then
				if PartCtrl_ViewPanel.pnlContent.SelectedPanel == PartCtrl_ViewPanel and PartCtrl_ViewPanel.CurrentPCF == str then
					//MsgN("we doin this")
					if str != "UtilFx" then
						if PartCtrl_AllDataPCFs[str] then str = PartCtrl_AllDataPCFs[str].original_filename end
						OnParticleNodeSelected(str, PartCtrl_ViewPanel.CurrentPath, PartCtrl_ViewPanel, PartCtrl_ViewPanel.pnlContent)
					else
						OnUtilFxNodeSelected(PartCtrl_ViewPanel.CurrentUtilFxName, PartCtrl_ViewPanel, PartCtrl_ViewPanel.pnlContent)
					end
				end
			end
		end

		//Refresh spawnicons (this is handled by the think hook in contenticon_partctrl.lua)
		//Do this for all spawnicons, not just the ones for the pcf we updated (i.e. in case 
		//updating one of this pcf's fx made a lower priority pcf's effect no longer a dupe of it)
		if PartCtrl_IconFx then
			for pcf, _ in pairs (PartCtrl_IconFx) do
				for name, _ in pairs (PartCtrl_IconFx[pcf]) do
					PartCtrl_IconFx[pcf][name].reset = true
				end
			end
		end

	end

	net.Receive("PartCtrl_ReloadPCF_SendToCl", function()
		PartCtrl_ReloadPCF(net.ReadString())
	end)

else
	
	function PartCtrl_ReloadPCF(str, dont_network) //local var scope also forces us to have two of these, instead of one func with "if CLIENT then" conditionals

		if str == "all" then
			MsgN("PartCtrl: Reloading all PCFs on server")

			if PartCtrl_ReadAndProcessPCFs_StartupIsOver or !PartCtrl_ReadAndProcessPCFs_StartupHasRun then
				PartCtrl_ReadAndProcessPCFs()
			end
		else
			MsgN("PartCtrl: Reloading ", str, " on server")

			if str != "UtilFx" then
				PartCtrl_ProcessedPCFs[str] = PartCtrl_ProcessPCF(str)
			else
				PartCtrl_ProcessUtilFx()
			end

			if str != "UtilFx" then
				//Make sure the reloaded effect is highest priority
				//(not sure if this matters serverside, but better safe than sorry)
				game.AddParticles(str)
			end
		end

		//now send the update to all players
		if !dont_network then
			net.Start("PartCtrl_ReloadPCF_SendToCl")
				net.WriteString(str)
			net.Broadcast()
		end

	end

	util.AddNetworkString("PartCtrl_ReloadPCF_SendToCl")

	concommand.Add("partctrl_reloadpcf", function(ply, cmd, args)
		//Only let server owners run this command cause it can lag everyone
		//Mostly copied from gmod's lua/autorun/developer_functions.lua (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/autorun/developer_functions.lua#L79)
		if !game.SinglePlayer() and IsValid(ply) and !ply:IsListenServerHost() and !ply:IsSuperAdmin() then
			return false
		end
		PartCtrl_ReloadPCF(args[1])
	end, nil, "Reloads a .pcf file on the server and all clients")
	
end


hook.Add("GameContentChanged", "PartCtrl_GameContentChanged", function()
	if GetConVarNumber("developer") >= 1 then MsgN("PartCtrl: running GameContentChanged") end
	PartCtrl_ReloadPCF("all", true) //clients should run this hook on their own, no need to network it
end)