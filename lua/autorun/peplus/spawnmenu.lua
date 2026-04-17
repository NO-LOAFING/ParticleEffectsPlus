AddCSLuaFile()

//Populate the spawn menu with a list of all the .pcf files, sorted by the game or addon they're from

local browseAddonParticles //TODO: these break if we refresh this file, can't find a good way to fix this without unlocalizing them
local browseLegacyParticles
local browseGameParticles
local RefreshAddonParticles
local RefreshLegacyParticles
local RefreshGameParticles
local OnParticleNodeSelected
local searchParticles = nil

if CLIENT then

	local cv_childfx_spawnlist = GetConVar("cl_peplus_childfx_in_autospawnlists")

	OnParticleNodeSelected = function(pcf, path, ViewPanel, pnlContent)

		ViewPanel:Clear(true)
		local pcf2 = PEPlus_GetGamePCF(pcf, path)
		//MsgN("running OnParticleNodeSelected for ", pcf, ", ", path)

		if !istable(PEPlus_ProcessedPCFs[pcf2]) then
			MsgN("OnParticleNodeSelected tried to make spawnlist for invalid pcf ", pcf2)
		else
			local dochildfx = cv_childfx_spawnlist:GetInt()
			if dochildfx == 0 then
				//No child fx
				for particle, _ in SortedPairs (PEPlus_ProcessedPCFs[pcf2]) do //sort them in alphabetical order
					if !PEPlus_ProcessedPCFs[pcf2][particle].parents or table.Count(PEPlus_ProcessedPCFs[pcf2][particle].parents) < 1 then
						spawnmenu.CreateContentIcon("peplus", ViewPanel, {pcf = pcf, name = particle, path = path})
					end
				end
			elseif dochildfx == 1 then
				local tab = {}
				//Separate child fx
				for particle, _ in SortedPairs (PEPlus_ProcessedPCFs[pcf2]) do //sort them in alphabetical order
					if !PEPlus_ProcessedPCFs[pcf2][particle].parents or table.Count(PEPlus_ProcessedPCFs[pcf2][particle].parents) < 1 then
						spawnmenu.CreateContentIcon("peplus", ViewPanel, {pcf = pcf, name = particle, path = path})
					else
						table.insert(tab, particle)
					end
				end
				if table.Count(tab) > 0 then
					spawnmenu.CreateContentIcon("header", ViewPanel, {text = "Child effects"})
					for k, particle in pairs (tab) do
						spawnmenu.CreateContentIcon("peplus", ViewPanel, {pcf = pcf, name = particle, path = path})
					end
				end
			else
				//All fx sorted alphabetically
				for particle, _ in SortedPairs (PEPlus_ProcessedPCFs[pcf2]) do //sort them in alphabetical order
					spawnmenu.CreateContentIcon("peplus", ViewPanel, {pcf = pcf, name = particle, path = path})
				end
			end
		end

		pnlContent:SwitchPanel(ViewPanel)
		ViewPanel.CurrentPCF = pcf2 //used by developer click-to-refresh-pcf function
		ViewPanel.CurrentPath = path //^

	end

	OnUtilFxNodeSelected = function(name, ViewPanel, pnlContent)

		ViewPanel:Clear(true)

		if !istable(PEPlus_UtilFxByTitle[name]) then
			MsgN("OnUtilFxNodeSelected tried to make spawnlist for invalid title ", name)
		else
			for particle, _ in SortedPairs (PEPlus_UtilFxByTitle[name]) do //sort them in alphabetical order
				spawnmenu.CreateContentIcon("peplus", ViewPanel, {pcf = "UtilFx", name = particle})
			end
		end

		pnlContent:SwitchPanel(ViewPanel)
		ViewPanel.CurrentPCF = "UtilFx" //used by developer click-to-refresh-pcf function
		ViewPanel.CurrentPath = nil //^
		ViewPanel.CurrentUtilFxName = name //^

	end

	function PEPlus_CreateCustomSpawnlist(tab, name, icon) //globally available so we can use it to make arbitrary spawnlists for testing

		local tab2 = {}

		local dochildfx = cv_childfx_spawnlist:GetInt()
		if dochildfx == 0 then
			//No child fx
			for k, v in pairs (tab) do
				local pcf2 = PEPlus_GetGamePCF(v.pcf, v.path)
				if !PEPlus_ProcessedPCFs[pcf2][v.particle].parents or table.Count(PEPlus_ProcessedPCFs[pcf2][v.particle].parents) < 1 then
					table.insert(tab2, {type = "peplus", pcf = v.pcf, name = v.particle, path = v.path})
				end
			end
		elseif dochildfx == 1 then
			//Separate child fx
			local tab3 = {}
			for k, v in pairs (tab) do
				local pcf2 = PEPlus_GetGamePCF(v.pcf, v.path)
				if !PEPlus_ProcessedPCFs[pcf2][v.particle].parents or table.Count(PEPlus_ProcessedPCFs[pcf2][v.particle].parents) < 1 then
					table.insert(tab2, {type = "peplus", pcf = v.pcf, name = v.particle, path = v.path})
				else
					table.insert(tab3, {type = "peplus", pcf = v.pcf, name = v.particle, path = v.path})
				end
			end
			if table.Count(tab3) > 0 then
				table.insert(tab2, {type = "header", text = "Child effects"})
				table.Add(tab2, tab3)
			end
		else
			//All fx sorted alphabetically
			for k, v in pairs (tab) do
				tab2[k] = {type = "peplus", pcf = v.pcf, name = v.particle, path = v.path}
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
		if (!fi && !fo) and !PEPlus_UtilFxByTitle[name] then return end

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
				if !particles.utilfxnode and PEPlus_UtilFxByTitle[name] then
					//MsgN("making utilfx node for ", name)
					particles.utilfxnode = particles:AddNode("Scripted Effects", "icon16/page_gear.png")
					particles.utilfxnode.utilfx = true
					FileCount = FileCount + 1
					particles.utilfxnode.DoRightClick = function()
						if !IsValid(particles.utilfxnode) then return end
						local menu = DermaMenu()

						menu:AddOption("#spawnmenu.createautospawnlist", function()
							local tab = {}
							for particle, _ in SortedPairs (PEPlus_UtilFxByTitle[name]) do //sort them in alphabetical order
								table.insert(tab, {pcf = "UtilFx", particle = particle})
							end
							PEPlus_CreateCustomSpawnlist(tab, "Scripted Effects", "icon16/page_gear.png")
						end):SetIcon("icon16/page_add.png")

						//developer control to reload a .pcf file manually; we want this for utilfx too just in case one of the list entries was edited
						if GetConVarNumber("developer") >= 1 then
							menu:AddOption("Reload UtilFx", function()
								RunConsoleCommand("sv_peplus_reloadpcf", "UtilFx")
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
						local filename2 = PEPlus_GetGamePCF(filename, path)
						if !istable(PEPlus_ProcessedPCFs[filename2]) then return end

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
								for particle, _ in SortedPairs (PEPlus_ProcessedPCFs[filename2]) do //sort them in alphabetical order
									table.insert(tab, {pcf = filename, particle = particle, path = path})
								end
								PEPlus_CreateCustomSpawnlist(tab, name)
							end):SetIcon("icon16/page_add.png")

							//developer control to reload a .pcf file manually
							if GetConVarNumber("developer") >= 1 then
								menu:AddSpacer()

								menu:AddOption("Reload " .. filename2, function()
									RunConsoleCommand("sv_peplus_reloadpcf", filename2)
								end)
							end

							menu:Open()
						end
					end
			
					for k, name in SortedPairs (files) do
						local tab = {}
						local pcf = string.Trim(foldername .. "/" .. name, "/")
						local file_path = PEPlus_GamePCFs_DefaultPaths[pcf] 
						//note: due to how this is implemented, this means if a game has an identical copy of a higher-priority 
						//game's pcf, it will use that game's path instead. (i.e hl2 has a bunch of duplicates of gmod pcfs, so 
						//if you open a spawnlist for any of these pcfs, none of them will have the "hl2" path like the other hl2
						//pcfs do) i don't *think* there are any situations where this is a problem, but *maybe* this could cause
						//issues with some weird combination of mounted game changes between sessions? not sure.
						////test
						//if PEPlus_ProcessedPCFs[pcf] and file_path != path then
						//	MsgN(path, "'s ", pcf, " is from ", file_path, "!")
						//end

						//For the "All" folder, add every data pcf for this file, in addition to the mounted pcf file
						if path == "GAME" and PEPlus_GamePCFs[pcf] then
							for path2, pcf2 in pairs (PEPlus_GamePCFs[pcf]) do
								if pcf2 != pcf then
									table.insert(tab, {
										name = name .. " (" .. path2  .. ")", pcf = pcf, path = path2
									})
								end
							end
						end

						if self.is_game_folder and PEPlus_GetGamePCF(pcf, path) != pcf then
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
							name = name, pcf = pcf, path = file_path
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

	language.Add("spawnmenu.category.browseparticles", "Browse Particle Effects")

	RefreshAddonParticles = function(node)
		for _, addon in SortedPairsByMemberValue(engine.GetAddons(), "title") do
			if !addon.downloaded then continue end
			if !addon.mounted then continue end
			if !table.HasValue(select(2, file.Find("*", addon.title)), "particles") and !PEPlus_UtilFxByTitle[addon.title] then continue end
			AddBrowseContentParticle(node, addon.title, "icon16/bricks.png", "", addon.title, addon.wsid)
		end
	end
	RefreshLegacyParticles = function(node)
		local addon_particles = {}
		local _, particle_folders = file.Find("addons/*", "MOD")
		for _, addon in SortedPairs(particle_folders) do
			if !file.IsDir("addons/" .. addon .. "/particles/", "MOD") and !PEPlus_UtilFxByTitle[addon] then continue end
			table.insert(addon_particles, addon)
		end

		for _, addon in SortedPairsByValue(addon_particles) do
			AddBrowseContentParticle(node, addon, "icon16/bricks.png", "addons/" .. addon .. "/", "MOD")
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

	hook.Add("PopulateContent", "PEPlus_PopulateContent", function(pnlContent, tree, browseNode) timer.Simple(0.5, function()

		if (!IsValid(tree) or !IsValid(pnlContent) or !istable(PEPlus_ProcessedPCFs)) then //check to make sure PEPlus_ProcessedPCFs exists because AddBrowseContentParticle needs it
			print("Particle Effects+: Failed to initialize PopulateContent hook")
			return
		end

		local ViewPanel = vgui.Create("ContentContainer", pnlContent)
		ViewPanel:SetVisible(false)
		ViewPanel.IconList:SetReadOnly(true) //not in enhanced spawnmenu; prevents contenticons in pcf spawnlists from being deleted using dropdown
		//Make these globally accessible so the developer pcf refresh button can access them
		PEPlus_ViewPanel = ViewPanel
		ViewPanel.pnlContent = pnlContent

		local browseParticles = tree:AddNode("#spawnmenu.category.browseparticles", "icon16/fire.png")
		browseParticles.ViewPanel = ViewPanel
		browseParticles.pnlContent = pnlContent

		browseAddonParticles = browseParticles:AddNode("#spawnmenu.category.addons", "icon16/folder_database.png")
		browseAddonParticles.ViewPanel = ViewPanel
		browseAddonParticles.pnlContent = pnlContent
		RefreshAddonParticles(browseAddonParticles)

		browseLegacyParticles = browseParticles:AddNode("#spawnmenu.category.addonslegacy", "icon16/folder_database.png")
		browseLegacyParticles.ViewPanel = ViewPanel
		browseLegacyParticles.pnlContent = pnlContent
		RefreshLegacyParticles(browseLegacyParticles)

		AddBrowseContentParticle(browseParticles, "#spawnmenu.category.downloads", "icon16/folder_database.png", "download/", "MOD")

		browseGameParticles = browseParticles:AddNode("#spawnmenu.category.games", "icon16/folder_database.png")
		browseGameParticles.ViewPanel = ViewPanel
		browseGameParticles.pnlContent = pnlContent
		RefreshGameParticles(browseGameParticles)

		//browseParticles:SetExpanded(true)

		if GetConVarNumber("developer") >= 1 then MsgN("Particle Effects+: running PopulateContent") end

	end) end)




	//Search populator

	local cv_childfx_search = GetConVar("cl_peplus_childfx_in_search")
	local cv_dupes_search = GetConVar("cl_peplus_dupes_in_search")

	search.AddProvider(function(str)

		local searchTerms = string.Explode(" ", str)

		if searchParticles == nil then
			searchParticles = {}
			for pcf, _ in SortedPairs (PEPlus_ProcessedPCFs) do
				if !PEPlus_AllDataPCFs[pcf] then
					for particle, _ in SortedPairs (PEPlus_ProcessedPCFs[pcf]) do
						table.insert(searchParticles, {
							name = particle, 
							searchtext = particle:lower() .. " " .. pcf:lower(), //lowercase needs to be separate, because effect names are case-sensitive when spawning them
							pcf = pcf,
							path = PEPlus_GamePCFs_DefaultPaths[pcf] //optional, can be nil
						}) 
					end
				else
					for particle, _ in SortedPairs (PEPlus_ProcessedPCFs[pcf]) do
						table.insert(searchParticles, {
							name = particle, 
							searchtext = particle:lower() .. " " .. pcf:lower() .. " " .. PEPlus_GetDataPCFNiceName(pcf):lower(), //let us search for both the nicename and internal name
							pcf = PEPlus_AllDataPCFs[pcf].original_filename,
							path = PEPlus_AllDataPCFs[pcf].path
						}) 
					end
				end
			end
		end

		local results = {}

		for k, v in ipairs (searchParticles) do
			local pcf = PEPlus_GetGamePCF(v.pcf, v.path)
			if (cv_childfx_search:GetBool() or !PEPlus_ProcessedPCFs[pcf][v.name].parents or table.Count(PEPlus_ProcessedPCFs[pcf][v.name].parents) < 1) 
			and (cv_dupes_search:GetBool() or !PEPlus_DuplicateFx[pcf] or !PEPlus_DuplicateFx[pcf][v.name]) then
				for k2, v2 in ipairs (searchTerms) do
					if !v.searchtext:find(v2, nil, true) then
						break
					elseif k2 == #searchTerms then
						local entry = {
							text = v.name,
							icon = spawnmenu.CreateContentIcon("peplus", g_SpawnMenu.SearchPropPanel, {pcf = v.pcf, name = v.name, path = v.path}),
							words = {v.name}
						}
						table.insert(results, entry)
					end
				end
			end
			if #results >= GetConVarNumber("sbox_search_maxresults") / 2 then break end
		end

		return results

	end, "peplus")




	//Curated game spawnlists

	hook.Add("PopulatePropMenu", "PEPlus_GameSpawnlists", function()

		local function ReadSpawnlist(path, parent, gameid, listid)
			local str = file.Read("lua/autorun/peplus/spawnlists/" .. path .. ".lua", "GAME")
			if str then
				local tab = util.KeyValuesToTable(str)
				if tab then
					local name = "PEPlus_GameSpawnlists_" .. string.StripExtension(string.GetFileFromFilename(path))
					spawnmenu.AddPropCategory(name, tab.name, tab.contents, tab.icon, listid, parent, gameid)
					return spawnmenu.GetCustomPropTable()[name].id
				end
			end
		end

		local par = ReadSpawnlist("root", nil, nil, 72782875) //root spawnlist has a predetermined id, so that other addons can add their own spawnlists to it regardless of load order

		ReadSpawnlist("gmod", par)

		ReadSpawnlist("portal", par, "portal")

		//HL2 spawnlists also include all the stock source pcfs, so no mount requirement for these ones
		local hl2par = ReadSpawnlist("hl2", par)
		local hl2 = {}
		for i = 1, 8 do
			local ipar
			if i == 3 then
				ipar = hl2[2] //Blood and Gore is a subcategory of Characters and NPCs
			elseif i > 4 then
				ipar = hl2[4] //All of these are subcategories of Environment
			end
			hl2[i] = ReadSpawnlist("hl2_0" .. i, ipar or hl2par)
		end

		local tfpar = ReadSpawnlist("tf", par, "tf")
		local tf = {}
		for i = 1, 11 do
			local ipar
			if i == 2 or i == 4 or i == 5 then
				ipar = tf[1] //Weapons, Cosmetics and Taunts are subcategories of Items
			elseif i == 3 then
				ipar = tf[2] //Unusual Weapons is a subcategory of Weapons
			elseif i == 7 then
				ipar = tf[6] //Blood and Gore is a subcategory of Characters and NPCs
			elseif i > 8 then
				ipar = tf[8] //All of these are subcategories of Environment
			end
			local zero = "0"
			if i >= 10 then zero = "" end
			tf[i] = ReadSpawnlist("tf_" .. zero .. i, ipar or tfpar, "tf")
		end

		ReadSpawnlist("cstrike", par, "cstrike")

		ReadSpawnlist("hl1", par, "hl1")

	end)

end




//PCF reloading function; this would be in pcf_processing, except it has to be able to access a bunch of spawnmenu-related local vars

function PEPlus_ReloadPCF(str, dont_network)

	local realm
	if CLIENT then
		realm = "client " .. tostring(LocalPlayer())
	else
		realm = "server"
	end

	if str then str = string.Trim(string.Replace(str, "\\", "/")) end
	if str != "UtilFx" and str != "all" and (!str or !file.Exists(str, "GAME")) then
		MsgN("PEPlus_ReloadPCF: Failed to reload PCF ", str, " on ", realm, "; file not found")
		if !str or !string.StartsWith(str, "particles/") or !string.EndsWith(str, ".pcf") then
			MsgN("(this should either be \"all\" (without quotes) or a full file path starting with particles/ and ending with .pcf)") //technically wrong because data pcfs end with .txt internally, OH WELL
		end
		return
	end

	if str != "UtilFx" and (!PEPlus_ProcessedPCFs or !PEPlus_ProcessedPCFs[str]) then //TODO: this doesn't catch cases where a player adds a new pcf with the same name as one from a game (ideally we should catch these and seamlessly convert the old one to a data pcf)
		local new_file_only
		if str == "all" then
			MsgN("PEPlus_ReloadPCF: Reloading all PCFs on ", realm)
		else
			MsgN("PEPlus_ReloadPCF: Loading new PCF ", str, " on ", realm)
			//If we try to reload a pcf that hasn't been loaded before (i.e. create a new pcf with the particle editor or
			//something, then try to load it) then vital tables like PEPlus_PCFsInDupeOrder won't have it, which'll cause 
			//errors, so run PEPlus_ReadAndProcessPCFs again to rebuild those, but without also reloading all the PCFs.
			new_file_only = str
			table.insert(PEPlus_AllPCFPaths, str)
			PEPlus_ProcessedPCFs[str] = PEPlus_ProcessPCF(str)
		end

		if PEPlus_ReadAndProcessPCFs_StartupIsOver or !PEPlus_ReadAndProcessPCFs_StartupHasRun then
			PEPlus_ReadAndProcessPCFs(new_file_only)
		end

		if new_file_only then 
			if CLIENT then
				PEPlus_AddParticles(str)
			else
				game.AddParticles(str)
			end
		end

		if CLIENT then
			//Spawnlist stuff from enhanced spawnmenu
			if IsValid(browseAddonParticles) then
				browseAddonParticles:Clear()
				browseAddonParticles.ViewPanel:Clear(true)
				RefreshAddonParticles(browseAddonParticles)
			end
			if IsValid(browseLegacyParticles) then
				browseLegacyParticles:Clear()
				browseLegacyParticles.ViewPanel:Clear(true)
				RefreshLegacyParticles(browseLegacyParticles)
			end
			if IsValid(browseGameParticles) then
				browseGameParticles:Clear()
				browseGameParticles.ViewPanel:Clear(true)
				RefreshGameParticles(browseGameParticles)
			end

			//Search stuff
			searchParticles = nil
		end
	else
		//TODO: this probably doesn't work for data pcfs in multiplayer if a player has different content mounted than the server
		MsgN("PEPlus_ReloadPCF: Reloading PCF ", str, " on ", realm)

		if str != "UtilFx" then
			PEPlus_ProcessedPCFs[str] = PEPlus_ProcessPCF(str)
		else
			PEPlus_ProcessUtilFx()
		end

		if str != "UtilFx" then
			//Handle duplicate fx detection again; it's possible that an effect was updated to start/stop being a dupe, OR that an 
			//effect being updated made an effect from a lower-priority PCF start/stop being considered a dupe of this pcf's effect
			//Server also needs this to rebuild PEPlus_PCFsByParticleName for use by backcomp
			PEPlus_GetDuplicateFx()

			if CLIENT then
				//Make sure the reloaded pcf is highest priority
				//(try to prevent oddness with PEPlus_PCFsByParticleName_CurrentlyLoaded on fx that change dupe status)
				PEPlus_AddParticles(str)
			else
				//(not sure if this matters serverside, but better safe than sorry)
				game.AddParticles(str)
			end
		end

		if CLIENT then
			//force search to rebuild search cache so any new fx will be found
			searchParticles = nil

			//if this pcf's auto-generated spawnlist is currently open, then rebuild it (to handle fx being added to or removed from the list)
			if IsValid(PEPlus_ViewPanel) and IsValid(PEPlus_ViewPanel.pnlContent) then
				if PEPlus_ViewPanel.pnlContent.SelectedPanel == PEPlus_ViewPanel and PEPlus_ViewPanel.CurrentPCF == str then
					//MsgN("we doin this")
					if str != "UtilFx" then
						if PEPlus_AllDataPCFs[str] then str = PEPlus_AllDataPCFs[str].original_filename end
						OnParticleNodeSelected(str, PEPlus_ViewPanel.CurrentPath, PEPlus_ViewPanel, PEPlus_ViewPanel.pnlContent)
					else
						OnUtilFxNodeSelected(PEPlus_ViewPanel.CurrentUtilFxName, PEPlus_ViewPanel, PEPlus_ViewPanel.pnlContent)
					end
				end
			end
		end
	end

	if CLIENT then
		//Refresh spawnicons (this is handled by the think hook in contenticon_peplus.lua)
		//Do this for all spawnicons, not just the ones for the pcf we updated (i.e. in case 
		//updating one of this pcf's fx made a lower priority pcf's effect no longer a dupe of it)
		if PEPlus_IconFx then
			for pcf, _ in pairs (PEPlus_IconFx) do
				for name, _ in pairs (PEPlus_IconFx[pcf]) do
					PEPlus_IconFx[pcf][name].reset = true
				end
			end
		end
	else
		//now send the update to all players
		if !dont_network then
			net.Start("PEPlus_ReloadPCF_SendToCl")
				net.WriteString(str)
			net.Broadcast()
		end
	end

end

if CLIENT then
	net.Receive("PEPlus_ReloadPCF_SendToCl", function()
		PEPlus_ReloadPCF(net.ReadString())
	end)

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
	util.AddNetworkString("PEPlus_ReloadPCF_SendToCl")

	concommand.Add("sv_peplus_reloadpcf", function(ply, cmd, args)
		//Only let server owners run this command cause it can lag everyone
		//Mostly copied from gmod's lua/autorun/developer_functions.lua (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/autorun/developer_functions.lua#L79)
		if !game.SinglePlayer() and IsValid(ply) and !ply:IsListenServerHost() and !ply:IsSuperAdmin() then
			return false
		end
		PEPlus_ReloadPCF(args[1])
	end, nil, "Reloads a .pcf file on the server and all clients; takes either \"all\" (without quotes) or a file path starting with particles/ and ending with .pcf")
end


hook.Add("GameContentChanged", "PEPlus_GameContentChanged", function()
	if GetConVarNumber("developer") >= 1 then MsgN("Particle Effects+: running GameContentChanged") end
	PEPlus_ReloadPCF("all", true) //clients should run this hook on their own, no need to network it
end)