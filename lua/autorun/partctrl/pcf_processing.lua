AddCSLuaFile()

//silly pretend enums
PARTCTRL_CPOINT_MODE_NONE		= 0
PARTCTRL_CPOINT_MODE_POSITION		= 1
PARTCTRL_CPOINT_MODE_VECTOR		= 2
PARTCTRL_CPOINT_MODE_AXIS		= 3
PARTCTRL_CPOINT_MODE_POSITION_COMBINE	= 4
//for networking convenience
partctrl_cpointbits = 7 //-1 - 63

partctrl_wait = "wait" //another convenient global, used by particlesystems that can't currently be created (due to CrashCheck or a disabled particle entity) but should be created as soon as possible

//for vector/axis cpoints; names and comments from https://github.com/SourceSDK2013Ports/csgo-src/blob/main/src/public/particles/particles.h#L78
PARTCTRL_PARTICLE_ATTRIBUTE_XYZ = 0 // required
PARTCTRL_PARTICLE_ATTRIBUTE_LIFE_DURATION = 1 // particle lifetime (duration) of particle as a float.
PARTCTRL_PARTICLE_ATTRIBUTE_PREV_XYZ = 2 // prev coordinates for verlet integration
PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS = 3 // radius of particle
PARTCTRL_PARTICLE_ATTRIBUTE_ROTATION = 4 // rotation angle of particle
PARTCTRL_PARTICLE_ATTRIBUTE_ROTATION_SPEED = 5 // rotation speed of particle
PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB = 6 // tint of particle
PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA = 7 // alpha tint of particle
PARTCTRL_PARTICLE_ATTRIBUTE_CREATION_TIME = 8 // creation time stamp (relative to particle system creation)
PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER = 9 // sequnece # (which animation sequence number this particle uses )
PARTCTRL_PARTICLE_ATTRIBUTE_TRAIL_LENGTH = 10 // length of the trail 
PARTCTRL_PARTICLE_ATTRIBUTE_PARTICLE_ID = 11 // unique particle identifier
PARTCTRL_PARTICLE_ATTRIBUTE_YAW = 12 // unique rotation around up vector
PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1 = 13 // second sequnece # (which animation sequence number this particle uses )
PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_INDEX = 14 // hit box index
PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_RELATIVE_XYZ = 15
PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA2 = 16
PARTCTRL_PARTICLE_ATTRIBUTE_SCRATCH_VEC = 17 //scratch field used for storing arbitraty vec data
PARTCTRL_PARTICLE_ATTRIBUTE_SCRATCH_FLOAT = 18 //scratch field used for storing arbitraty float data	
PARTCTRL_PARTICLE_ATTRIBUTE_UNUSED = 19
PARTCTRL_PARTICLE_ATTRIBUTE_PITCH = 20
PARTCTRL_PARTICLE_ATTRIBUTE_NORMAL = 21 // 0 0 0 if none
PARTCTRL_PARTICLE_ATTRIBUTE_GLOW_RGB = 22 // glow color
PARTCTRL_PARTICLE_ATTRIBUTE_GLOW_ALPHA = 23 // glow alpha
//old attributes from pre-csgo particles https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/public/particles/particles.h#L62
//PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P0 = 17 // particle trace caching fields // start pnt of trace
//PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P1 = 18 // end pnt of trace
//PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_T = 19 // 0..1 if hit
//PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL = 20 // 0 0 0 if no hit
local ParticleAttributeNames = { //names and comments from https://github.com/SourceSDK2013Ports/csgo-src/blob/main/src/particles/particles.cpp#L3782
	[PARTCTRL_PARTICLE_ATTRIBUTE_XYZ] = "Position", // XYZ, 0
	[PARTCTRL_PARTICLE_ATTRIBUTE_LIFE_DURATION] = "Life Duration", // LIFE_DURATION, 1 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_PREV_XYZ] = "Position Previous", // PREV_XYZ 
	[PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS] = "Radius", // RADIUS, 3 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_ROTATION] = "Roll", // ROTATION, 4 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_ROTATION_SPEED] = "Roll Speed", // ROTATION_SPEED, 5 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB] = "Color", // TINT_RGB, 6 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA] = "Alpha", // ALPHA, 7 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_CREATION_TIME] = "Creation Time", // CREATION_TIME, 8 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER] = "Texture", //better display name, technically inaccurate but players are more likely to understand what this means; original: "Sequence Number", // SEQUENCE_NUMBER, 9 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_TRAIL_LENGTH] = "Trail Length", // TRAIL_LENGTH, 10 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_PARTICLE_ID] = "Particle ID", // PARTICLE_ID, 11 ); 
	[PARTCTRL_PARTICLE_ATTRIBUTE_YAW] = "Yaw", // YAW, 12 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1] = "Texture", //better display name, technically inaccurate but players are more likely to understand what this means; original: "Sequence Number 1", // SEQUENCE_NUMBER1, 13 );
	[PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_INDEX] = "Hitbox Index", // HITBOX_INDEX, 14
	[PARTCTRL_PARTICLE_ATTRIBUTE_HITBOX_RELATIVE_XYZ] = "Hitbox Offset Position", // HITBOX_XYZ_RELATIVE 15
	[PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA2] = "Alpha", //better display name, there's no difference between the two alphas as far as players are concerned; original: "Alpha Alternate", // ALPHA2, 16
	[PARTCTRL_PARTICLE_ATTRIBUTE_SCRATCH_VEC] = "Scratch Vector", // SCRATCH_VEC 17
	[PARTCTRL_PARTICLE_ATTRIBUTE_SCRATCH_FLOAT] = "Scratch Float", // SCRATCH_FLOAT 18
	[PARTCTRL_PARTICLE_ATTRIBUTE_UNUSED] = "Unused Particle Attribute", //NULL,
	[PARTCTRL_PARTICLE_ATTRIBUTE_PITCH] = "Pitch", // PITCH, 20
	[PARTCTRL_PARTICLE_ATTRIBUTE_NORMAL] = "Normal", // NORMAL, 21
	[PARTCTRL_PARTICLE_ATTRIBUTE_GLOW_RGB] = "Glow RGB", //GLOW_RGB,22 //i don't think these last two are implemented in gmod, actually?
	[PARTCTRL_PARTICLE_ATTRIBUTE_GLOW_ALPHA] = "Glow Alpha", //GLOW_ALPHA,23
	//old attributes from pre-csgo particles https://github.com/nillerusr/source-engine/blob/master/particles/particles.cpp#L3026
	//[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P0] = "PARTICLE_ATTRIBUTE_TRACE_P0 (internal)",
	//[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_P1] = "PARTICLE_ATTRIBUTE_TRACE_P1 (internal)",
	//[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_T] = "PARTICLE_ATTRIBUTE_TRACE_HIT_T (internal)",
	//[PARTCTRL_PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL] = "PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL (internal)"
}

//from the only good glua file parser code i could find on github; we use this to get strings (https://github.com/RaphaelIT7/gmod-lua-gma-writer/blob/master/gma.lua#L202)
local str_b0 = string.char(0)
local function ReadUntilNull(f) //TODO: during development of file reading, this could cause errors when it tried to grab a string from the wrong part of the file. is this still possible?
	local steps = 64 //arbitrary
	local pos = f:Tell()

	local file_str = ""
	local finished = false
	while !finished do
		local str = f:Read(steps)
		local found = string.find(str, str_b0)
		if found then
			str = string.sub(str, 0, found - 1)
			finished = true
		end

		file_str = file_str .. str
	end

	f:Seek(pos + string.len(file_str) + 1) -- + 1 for the Null byte we remove from the String.

	return file_str
end

local a = {}
table.insert(a, "ATTRIBUTE_ELEMENT")
table.insert(a, "ATTRIBUTE_INTEGER")
table.insert(a, "ATTRIBUTE_FLOAT")
table.insert(a, "ATTRIBUTE_BOOLEAN")
table.insert(a, "ATTRIBUTE_STRING")
table.insert(a, "ATTRIBUTE_BINARY")
table.insert(a, "ATTRIBUTE_TIME")
table.insert(a, "ATTRIBUTE_COLOR")
table.insert(a, "ATTRIBUTE_VECTOR2")
table.insert(a, "ATTRIBUTE_VECTOR3")
table.insert(a, "ATTRIBUTE_VECTOR4")
table.insert(a, "ATTRIBUTE_QANGLE")
table.insert(a, "ATTRIBUTE_QUATERNION")
table.insert(a, "ATTRIBUTE_MATRIX")
table.insert(a, "ATTRIBUTE_ELEMENT_ARRAY")
table.insert(a, "ATTRIBUTE_INTEGER_ARRAY")
table.insert(a, "ATTRIBUTE_FLOAT_ARRAY")
table.insert(a, "ATTRIBUTE_BOOLEAN_ARRAY")
table.insert(a, "ATTRIBUTE_STRING_ARRAY")
table.insert(a, "ATTRIBUTE_BINARY_ARRAY")
table.insert(a, "ATTRIBUTE_TIME_ARRAY")
table.insert(a, "ATTRIBUTE_COLOR_ARRAY")
table.insert(a, "ATTRIBUTE_VECTOR2_ARRAY")
table.insert(a, "ATTRIBUTE_VECTOR3_ARRAY")
table.insert(a, "ATTRIBUTE_VECTOR4_ARRAY")
table.insert(a, "ATTRIBUTE_QANGLE_ARRAY")
table.insert(a, "ATTRIBUTE_QUATERNION_ARRAY")
table.insert(a, "ATTRIBUTE_MATRIX_ARRAY")

//reference:
//https://developer.valvesoftware.com/wiki/PCF, https://developer.valvesoftware.com/w/index.php?title=DMX/Binary&oldid=176216#Version_3, https://developer.valvesoftware.com/wiki/DMX/Binary

local cache_version = "1" //update this in case ReadPCF is updated to return a different table
local docache = GetConVar("sv_partctrl_cachereadpcf")

function PartCtrl_ReadPCF(filename, path) 

	//don't print non-critical messages unless we're in developer mode; 
	//always print messages for bugs that player should report
	local dodebug = (GetConVarNumber("developer") >= 1)

	local checksum
	if docache:GetBool() then
		//If possible, load the results of this function from cache instead. This makes PartCtrl_ReadAndProcessPCFs 2-3x faster on all subsequent
		//startups (compared to without caching), but makes the very first load quite a bit slower as we save the files to the cache, and also adds
		//approx. 50MB to the data folder (because of how BIG tf2's pcfs are!).
		checksum = file.Read(filename, path or "GAME")
		if !checksum then MsgN("PartCtrl: ", filename, " (", path or "GAME", ") can't be read, report this bug!") return end
		checksum = util.SHA256(checksum) //if the pcf file is updated, then the checksum will be different; this stops us from loading outdated data
		local cached_file = file.Read("partctrl_cache_" .. cache_version ..  "/" .. filename .. "/" .. checksum .. ".txt", "DATA")
		if cached_file then
			//"true" arg below stops it from converting all table keys from strings to numbers where possible.
			//this prevents edge cases where an effect just named a number can get converted into a bad name, and doesn't 
			//*seem* to cause any issues with sequential subtables like operator lists, but keep an eye on this just in case.
			cached_file = util.JSONToTable(cached_file, false, true)
			//PrintTable(cached_file)
			if cached_file then 
				if dodebug then MsgN("PartCtrl: ", filename, " loading from cache") end
				return cached_file
			end
		end
	end

	local f = file.Open(filename, "rb", path or "GAME")
	if !f then MsgN("PartCtrl: ", filename, " (", path or "GAME", ") can't be opened, report this bug!") return end
	//path arg is only used by PartCtrl_GetPCFConflicts, don't worry about it past this point

	//If the pcf is packed into the current map, then write a copy of it into the data folder and read that instead.
	//This is necessary because performing read operations on packed files takes a very long time (only if the map file is compressed, but we don't have 
	//a way to check for that); pd_watergate's *7* packed pcfs add *10 whole minutes* to the load time if we don't cache them like this!
	if file.Exists(filename, "BSP") then
		if dodebug then MsgN("PartCtrl: ", filename, " is packed into the current BSP file, caching") end
		if file.Write("temp_partctrl_readpcfcache.txt", f:Read()) then
			f = file.Open("temp_partctrl_readpcfcache.txt", "rb", "DATA")
			if !f then MsgN("PartCtrl: ", filename, " cache was written, but can't be read; report this bug!") return end
		else
			MsgN("PartCtrl: ", filename, " was unable to be cached; report this bug!")
			return
		end
	end
	//we *could* run file.Delete("temp_partctrl_readpcfcache.txt", "DATA") after we're done with it, but that doesn't seem necessary; 
	//there's only ever one of these files at a time and they're not that big, it'd just be another write operation on the user's HD for no benefit

	local version
	local header = ReadUntilNull(f)
	//MsgN(header)
	if header == "<!-- dmx encoding binary 2 format pcf 1 -->\n" //used by all orange box pcfs
	or header == "<!-- dmx encoding binary 2 format dmx 1 -->\n" //only used by css's fire_medium_01.pcf, appears to be identical to orangebox's binary 2 format pcf 1
	or header == "<!-- dmx encoding binary 3 format pcf 1 -->\n" //only used by portal 2's clouds.pcf
	or header == "<!-- dmx encoding binary 3 format pcf 2 -->\n" //used by a few portal 2 pcfs; this and the above don't seem to have any formatting differences from binary 2
	then 
		version = 2
	elseif header == "<!-- dmx encoding binary 4 format pcf 2 -->\n" then //only used by by l4d2 pcfs?
		version = 4
	elseif header == "<!-- dmx encoding binary 5 format pcf 2 -->\n" then //used by most portal 2 pcfs and all(?) alien swarm pcfs
		version = 5
	else
		if dodebug then MsgN("PartCtrl: ", filename, " has unsupported pcf format ", string.TrimRight(header, "\n"), ", ignoring") end
		return
	end


	local nStrings
	if version <= 3 then
		nStrings = f:ReadUShort() //this is a short in DMX version 2 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
	else
		nStrings = f:ReadULong() //this is an int in both version 4 and 5 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions / https://developer.valvesoftware.com/w/index.php?title=DMX/Binary&oldid=176216#Version_3
	end
	local StringDict = {}
	//MsgN(filename, " nStrings = ", nStrings)
	for k = 0, nStrings - 1 do
		local v = ReadUntilNull(f)
		StringDict[k] = v
	end
	//PrintTable(StringDict)


	local nElements = f:ReadULong() //int
	//MsgN(filename, " nElements = ", nElements)

	local function DmeHeader()
		local tab = {}
		if version <= 3 then
			tab.Type = StringDict[f:ReadUShort()] //string dictionary indices are shorts in DMX version 2 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
			tab.Name = ReadUntilNull(f) //element names are in-line strings in DMX version 2 https://developer.valvesoftware.com/w/index.php?title=DMX/Binary&oldid=176216#Version_3
		elseif version == 4 then
			//in version 4, element names are also stored in the string dictionary, but string dictionary indices are still shorts https://developer.valvesoftware.com/wiki/PCF#Element_Dictionary / https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
			tab.Type = StringDict[f:ReadUShort()]
			tab.Name = StringDict[f:ReadUShort()]
		elseif version == 5 then
			//in version 5, string dictionary indices are now ints https://developer.valvesoftware.com/wiki/PCF#Element_Dictionary / https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
			tab.Type = StringDict[f:ReadULong()]
			tab.Name = StringDict[f:ReadULong()]
		end
		//tab.GUID = f:Read(16) //GUID[16]
		f:Skip(16) //GUID[16], just skip this one
		return tab
	end
	local ElementIndex = {}
	for i = 1, nElements do
		ElementIndex[i-1] = DmeHeader()
	end
	//PrintTable(ElementIndex)


	local function DmAttribute()
		local tab = {}
		if version <= 4 then
			tab.Name = StringDict[f:ReadUShort()] //string dictionary indices are shorts in DMX version 2 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
		elseif version == 5 then
			tab.Name = StringDict[f:ReadULong()]
		end
		//MsgN("name = ", tab.Name)
		if !tab.Name then return tab end //if we returned a bad attribute, bail out immediately; NOTE 3/22/25: this and all the file-reading checks with error messages below were to address a bug with PCFs packed into compressed map files, which would start returning garbage with a "Warning! LZMA compression header is invalid! Extraction failed! particles\_.pcf ( ERR: 1 )" error in console after an arbitrary point; this bug was fixed by the most recent gmod update, so this may no longer be necessary
		//local at = math.BinToInt(f:Read(1)) or 0 //returns nil
		//local at = math.BinToInt(ReadUntilNull(f)) or 0
		local at = f:ReadByte()
		//MsgN("at ", at, " = ", a[at])
		at = a[at] or ""
		tab.AttributeType = at
		local function DoAttribute(is_array)
			//MsgN("at = ", at)
			if at == "ATTRIBUTE_ELEMENT" then
				return f:ReadLong()
			elseif at == "ATTRIBUTE_INTEGER" then
				return f:ReadLong()
			elseif at == "ATTRIBUTE_FLOAT" then
				return f:ReadFloat()
			elseif at == "ATTRIBUTE_BOOLEAN" then
				return f:ReadBool()
			elseif at == "ATTRIBUTE_STRING" then
				if version <= 3 or is_array then //in higher versions, arrays of strings still use null-terminated strings instead of being stored in the string dictionary
					return ReadUntilNull(f)
				elseif version == 4 then
					return StringDict[f:ReadUShort()] //this is a short in version 4 (https://developer.valvesoftware.com/wiki/PCF#Element_Dictionary), which matches the headers
				elseif version == 5 then
					return StringDict[f:ReadULong()]
				end
			elseif at == "ATTRIBUTE_BINARY" then
				local count = f:ReadULong()
				return f:Read(count)
			elseif at == "ATTRIBUTE_TIME" then
				return f:ReadLong() / 10000 //according to https://developer.valvesoftware.com/wiki/PCF; TODO: should this be unsigned? can't find anything that uses this to check
			elseif at == "ATTRIBUTE_COLOR" then
				return Color(string.byte(f:Read(1)), string.byte(f:Read(1)), string.byte(f:Read(1)), string.byte(f:Read(1)))
			elseif at == "ATTRIBUTE_VECTOR2" then
				return {f:ReadFloat(), f:ReadFloat()}
			elseif at == "ATTRIBUTE_VECTOR3" then
				return Vector(f:ReadFloat(), f:ReadFloat(), f:ReadFloat())
			elseif at == "ATTRIBUTE_VECTOR4" then
				return {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()}
			elseif at == "ATTRIBUTE_QANGLE" then
				return Vector(f:ReadFloat(), f:ReadFloat(), f:ReadFloat()) //"Same as ATTRIBUTE_VECTOR3" according to https://developer.valvesoftware.com/wiki/PCF
			elseif at == "ATTRIBUTE_QUATERNION" then
				return {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()} //"Same as ATTRIBUTE_VECTOR4" according to https://developer.valvesoftware.com/wiki/PCF
			elseif at == "ATTRIBUTE_MATRIX" then
				return Matrix({ {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()}, {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()},
						{f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()}, {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()} })
			elseif string.EndsWith(at, "_ARRAY") then
				at = string.Replace(at, "_ARRAY", "")
				local tab2 = {}
				local arraysize = f:ReadULong() //int, is ReadULong the right way to interpret this?
				if arraysize > 1000 then MsgN("PartCtrl: ", filename, " got crazy array size ", arraysize, " - we screwed up file reading somewhere, report this bug!") return end
				for i = 1, arraysize do
					table.insert(tab2, DoAttribute(true))
				end
				return tab2
			end
			return 0
		end
		tab.Value = DoAttribute()
		return tab
	end
	local ElementBodies = {}
	for i = 1, nElements do
		//MsgN("Element ", i, " = ")
		local body = {}
		local attributecount = f:ReadULong() //int, is ReadULong the right way to interpret this?
		//MsgN("attributecount = ", attributecount)
		if !attributecount then MsgN("PartCtrl: ", filename, " got no attribute count - we screwed up file reading somewhere, report this bug!") return end
		if attributecount > 100 then MsgN("PartCtrl: ", filename, " got crazy attribute count ", attributecount, " - we screwed up file reading somewhere, report this bug!") return end
		for i = 1, attributecount do
			local attrib = DmAttribute()
			if !attrib.Name then MsgN("PartCtrl: ", filename, " attribute ", i, " has no name value - we screwed up file reading somewhere, report this bug!") return end
			table.insert(body, attrib)
		end
		ElementBodies[i-1] = body
		//MsgN("nElement ", i, " body:")
		//PrintTable(body)
	end
	f:Close()


	//smoosh the index and bodies into a single table
	//PrintTable(ElementIndex)
	//PrintTable(ElementBodies)
	local ElementsUnsorted = {}
	for i, index in pairs (ElementIndex) do
		local tab = {}
		//tab["k"] = index["Type"] .. " " .. index["Name"]
		tab["k"] = index

		local v = {}
		if !ElementBodies[i] then
			MsgN("PartCtrl: ", filename, " element index ", i, " has no body - we screwed up file reading somewhere, report this bug!")
			break //note: in all the cases where this bug has happened (reading pcfs packed into compressed tf2 maps before 3/26/25 update) every element after the first one with this bug will also be empty, so stop here
		else
			for i, attrib in pairs (ElementBodies[i]) do
				if attrib.AttributeType == "ATTRIBUTE_ELEMENT_ARRAY" then
					v[attrib.Name] = {
						["ElementTable"] = attrib.Value
					}
				elseif attrib.AttributeType == "ATTRIBUTE_ELEMENT" then
					v[attrib.Name] = {
						["ElementTable"] = {attrib.Value}
					}
				else
					v[attrib.Name] = attrib.Value
				end
			end
			tab["v"] = v
			ElementsUnsorted[i] = tab
		end
	end
	//PrintTable(ElementsUnsorted)


	//Now sort that table into a conventional keyvalue structure
	--[[local nonParentedElements = {}
	for i = 0, nElements - 1 do
		nonParentedElements[i] = true
	end
	for i, kv in pairs (ElementsUnsorted) do
		for k2, v2 in pairs(kv.v) do
			if istable(v2) and v2.ElementTable then
				for _, element in pairs (v2.ElementTable) do
					nonParentedElements[element] = nil
				end
			end
		end
	end
	PrintTable(nonParentedElements)]]
	//Looks like in every pcf, 0 is the only unparented element, so start there to save time instead of iterating over the whole table again
	local Elements = {}
	if !ElementsUnsorted[0].v.particleSystemDefinitions or !ElementsUnsorted[0].v.particleSystemDefinitions.ElementTable then 
		if dodebug then MsgN("PartCtrl: ", filename, " element 0 doesn't contain a particleSystemDefinitions table, ignoring") end
		return
	end
	for _, i in pairs (ElementsUnsorted[0].v.particleSystemDefinitions.ElementTable) do
		if !ElementsUnsorted[i] then
			if dodebug then MsgN("PartCtrl: ", filename, " tried to get DmeParticleSystemDefinition from nil element ", i) end
		elseif ElementsUnsorted[i].k.Type != "DmeParticleSystemDefinition" then
			if dodebug then MsgN("PartCtrl: ", filename, " tried to get DmeParticleSystemDefinition element ", ElementsUnsorted[i].k.Name, ", but it was a ", ElementsUnsorted[i].k.Type, " element") end
		else
			for k, v in pairs (ElementsUnsorted[i].v) do
				if istable(v) and v.ElementTable then
					local tab = {}
					for et_k, et_i in pairs (v.ElementTable) do
						if !ElementsUnsorted[et_i] then
							if dodebug then MsgN("PartCtrl: ", filename, " attribute ", k, " tried to get nil element ", et_i) end
						else
							if ElementsUnsorted[et_i].k.Type == "DmeParticleChild" then
								if !ElementsUnsorted[et_i].v.child then
									if dodebug then MsgN("PartCtrl: ", filename, " DmeParticleChild has no child value") end
								else
									//store particle children as strings (names of the corresponding fx) to keep the table simple and avoid recursive nonsense
									local childName = nil
									for et2_k, et2_i in pairs (ElementsUnsorted[et_i].v.child.ElementTable) do
										if !ElementsUnsorted[et2_i] then
											if dodebug then MsgN("PartCtrl: ", filename, " DmeParticleChild tried to get nil element ", et2_i) end
										else
											//table.insert(tab, ElementsUnsorted[et2_i].k.Name)
											childName = ElementsUnsorted[et2_i].k.Name
										end
									end
									ElementsUnsorted[et_i].v.child = childName
								end
							end
							//table.insert(tab, ElementsUnsorted[et_i])
							//discard key for DmeParticleOperators; the name is redundant and is also stored in the functionName attribute, and also there can be multiple with the same name
							table.insert(tab, ElementsUnsorted[et_i].v)
							//this doesn't handle recursive element tables but i don't think any particle operators have those
						end
					end
					ElementsUnsorted[i].v[k] = tab
					//v = tab
				end
			end
			Elements[ElementsUnsorted[i].k.Name] = ElementsUnsorted[i].v
		end
	end

	if docache:GetBool() then
		local str = util.TableToJSON(Elements)
		if str then
			local dirs = string.Explode("/", "partctrl_cache_" .. cache_version ..  "/" .. filename)
			local d = ""
			for k,v in ipairs(dirs) do
				d = (d..v.."/")
				if !file.IsDir(d, "DATA") then file.CreateDir(d) end
			end
			if file.Write("partctrl_cache_" .. cache_version ..  "/" .. filename .. "/" .. checksum .. ".txt", str) then
				if dodebug then MsgN("PartCtrl: ", filename, " saved to cache") end
			else
				if dodebug then MsgN("PartCtrl: ", filename, " couldn't be cached because file.Write failed?") end
			end
		else
			if dodebug then MsgN("PartCtrl: ", filename, " couldn't be cached because util.TableToJSON failed?") end
		end
	end
	
	//PrintTable(Elements)
	return Elements

end


//from https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/devtools/bin/fix_particle_operator_names.pl#L54
local fixes = {
	["alpha_fade"] = "Alpha Fade and Decay",
	["alpha_fade_in_random"] = "Alpha Fade In Random",
	["alpha_fade_out_random"] = "Alpha Fade Out Random",
	["basic_movement"] = "Movement Basic",
	["color_fade"] = "Color Fade",
	["controlpoint_light"] = "Color Light From Control Point",
	["Dampen Movement Relative to Control Point"] = "Movement Dampen Relative to Control Point",
	["Distance Between Control Points Scale"] = "Remap Distance Between Two Control Points to Scalar",
	["Distance to Control Points Scale"] = "Remap Distance to Control Point to Scalar",
	["lifespan_decay"] = "Lifespan Decay",
	["lock to bone"] =	"Movement Lock to Bone",
	["postion_lock_to_controlpoint"] = "Movement Lock to Control Point",
	["maintain position along path"] = "Movement Maintain Position Along Path",
	["Match Particle Velocities"] = "Movement Match Particle Velocities",
	["Max Velocity"] = "Movement Max Velocity",
	["noise"] = "Noise Scalar",
	["vector noise"] = "Noise Vector",
	["oscillate_scalar"] = "Oscillate Scalar",
	["oscillate_vector"] = "Oscillate Vector",
	["Orient Rotation to 2D Direction"] = "Rotation Orient to 2D Direction",
	["radius_scale"] = "Radius Scale",
	["Random Cull"] = "Cull Random",
	["remap_scalar"] = "Remap Scalar",
	["rotation_movement"] = "Rotation Basic",
	["rotation_spin"] = "Rotation Spin Roll",
	["rotation_spin yaw"] = "Rotation Spin Yaw",
	["alpha_random"] = "Alpha Random",
	["color_random"] = "Color Random",
	["create from parent particles"] = "Position From Parent Particles",
	["Create In Hierarchy"] = "Position In CP Hierarchy",
	["random position along path"] = "Position Along Path Random",
	["random position on model"] = "Position on Model Random",
	["sequential position along path"] = "Position Along Path Sequential",
	["position_offset_random"] = "Position Modify Offset Random",
	["position_warp_random"] = "Position Modify Warp Random",
	["position_within_box"] = "Position Within Box Random",
	["position_within_sphere"] = "Position Within Sphere Random",
	["Inherit Velocity"] = "Velocity Inherit from Control Point",
	["Initial Repulsion Velocity"] = "Velocity Repulse from World",
	["Initial Velocity Noise"] = "Velocity Noise",
	["Initial Scalar Noise"] = "Remap Noise to Scalar",
	["Lifespan from distance to world"] = "Lifetime from Time to Impact",
	["Pre-Age Noise"] = "Lifetime Pre-Age Noise",
	["lifetime_random"] = "Lifetime Random",
	["radius_random"] = "Radius Random",
	["random yaw"] = "Rotation Yaw Random",
	["Randomly Flip Yaw"] = "Rotation Yaw Flip Random",
	["rotation_random"] = "Rotation Random",
	["rotation_speed_random"] = "Rotation Speed Random",
	["sequence_random"] = "Sequence Random",
	["second_sequence_random"] = "Sequence Two Random",
	["trail_length_random"] = "Trail Length Random",
	["velocity_random"] = "Velocity Random",
}
local fixes2 = {}
for k, v in pairs (fixes) do
	fixes2[string.lower(k)] = string.lower(v)
end
fixes = fixes2
fixes2 = nil


//manually copied from gmod's own particle editor 5/13/24, necessary for development but not finished addon
local default_attribs = {
	//Renderer
	"Render models", 
	"render_animated_sprites", 
	"render_rope", 
	"render_screen_velocity_rotate", 
	"render_sprite_trail", 
	//Operator
	"Alpha Fade and Decay", 
	"Alpha Fade and Decay for Tracers", //NEW 3/26/25
	"Alpha Fade In Random", 
	"Alpha Fade In Simple", //NEW 3/26/25
	"Alpha Fade Out Random", 
	"Alpha Fade Out Simple", //NEW 3/26/25
	"Clamp Scalar", //NEW 3/26/25
	"Clamp Vector", //NEW 3/26/25
	"Color Fade", 
	"Color Light from Control Point", 
	"Cull Random", 
	"Cull relative to model", 
	"Cull when crossing plane", 
	"Cull when crossing sphere", //NEW 3/26/25
	"Inherit Attribute From Parent Particle", //NEW 3/26/25
	"Lerp EndCap Scalar", //NEW 3/26/25
	"Lerp EndCap Vector", //NEW 3/26/25
	"Lerp Initial Scalar", //NEW 3/26/25
	"Lerp Initial Vector", //NEW 3/26/25
	"Lifespan Decay", 
	"Lifespan Maintain Count Decay", //NEW 3/26/25
	"Lifespan Minimum Alpha Decay", //NEW 3/26/25
	"Lifespan Minimum Radius Decay", //NEW 3/26/25
	"Lifespan Minimum Velocity Decay", 
	"Movement Basic", 
	"Movement Dampen Relative to Control Point", 
	"Movement Lag Compensation", //NEW 3/26/25
	"Movement Lock to Bone", 
	"Movement Lock to Control Point", 
	"Movement Lock to Saved Position Along Path", //NEW 3/26/25
	"Movement Maintain Offset", //NEW 3/26/25
	"Movement Maintain Position Along Path", 
	"Movement Match Particle Velocities", 
	"Movement Max Velocity", 
	"Movement Place On Ground", //NEW 3/26/25
	"Movement Rotate Particle Around Axis", 
	"Noise Scalar", 
	"Noise Vector", 
	"Normal Lock to Control Point", //NEW 3/26/25
	"Normalize Vector", //NEW 3/26/25
	"Oscillate Scalar", 
	"Oscillate Scalar Simple", //NEW 3/26/25
	"Oscillate Vector", 
	"Oscillate Vector Simple", //NEW 3/26/25
	"Radius Scale", 
	"Ramp Scalar Linear Random", //NEW 3/26/25
	"Ramp Scalar Linear Simple", //NEW 3/26/25
	"Ramp Scalar Spline Random", //NEW 3/26/25
	"Ramp Scalar Spline Simple", //NEW 3/26/25
	"Remap Average Scalar Value to CP", //NEW 3/26/25
	"Remap Control Point Direction to Vector", //NEW 3/26/25
	"Remap Control Point to Scalar", 
	"Remap Control Point to Vector", //NEW 3/26/25
	"Remap CP Speed to CP", 
	"Remap CP Velocity to Vector", //NEW 3/26/25
	"Remap Difference of Sequential Particle Vector to Scalar", //NEW 3/26/25
	"Remap Direction to CP to Vector", 
	"Remap Distance Between Two Control Points to CP", //NEW 3/26/25
	"Remap Distance Between Two Control Points to Scalar", 
	"Remap Distance to Control Point to Scalar", 
	"Remap Dot Product to Scalar", 
	"Remap Particle BBox Volume to CP", //NEW 3/26/25
	"Remap Percentage Between Two Control Points to Scalar", //NEW 3/26/25
	"Remap Percentage Between Two Control Points to Vector", //NEW 3/26/25
	"Remap Scalar", 
	"Remap Speed to Scalar", //NEW 3/26/25
	"Remap Velocity to Vector", //NEW 3/26/25
	"Restart Effect after Duration", //NEW 3/26/25
	"Rotate Vector Random", //NEW 3/26/25
	"Rotation Basic", 
	"Rotation Orient Relative to CP", 
	"Rotation Orient to 2D Direction", 
	"Rotation Spin Roll", 
	"Rotation Spin Yaw", 
	"Set child control points from particle positions", 
	"Set Control Point Positions", 
	"Set Control Point Rotation", //NEW 3/26/25
	"Set Control Point to Impact Point", //NEW 3/26/25
	"Set Control Point To Particles' Center", 
	"Set Control Point To Player", 
	"Set control points from particle positions", //NEW 3/26/25
	"Set CP Offset to CP Percentage Between Two Control Points", //NEW 3/26/25
	"Set CP Orientation to CP Direction", //NEW 3/26/25
	"Set per child control point from particle positions", //NEW 3/26/25
	"Stop Effect after Duration", //NEW 3/26/25
	//Initializer
	"Alpha Random", 
	"Color Lit Per Particle", 
	"Color Random", 
	"Cull relative to model", //NEW 3/26/25
	"Cull relative to Ray Trace Environment", //NEW 3/26/25
	"Inherit Initial Value From Parent Particle", //NEW 3/26/25
	"Lifetime From Sequence", 
	"Lifetime from Time to Impact", 
	"Lifetime Pre-Age Noise", 
	"Lifetime Random", 
	"Move Particles Between 2 Control Points", 
	"Normal Align to CP", //NEW 3/26/25
	"Normal Modify Offset Random", //NEW 3/26/25
	"Offset Vector to Vector", //NEW 3/26/25
	"Position Along Epitrochoid", 
	"Position Along Path Random", 
	"Position Along Path Sequential", 
	"Position Along Ring", 
	"Position From Chaotic Attractor", 
	"Position from Parent Cache", 
	"Position From Parent Particles", 
	"Position In CP Hierarchy", 
	"Position Modify Offset Random", 
	"Position Modify Place On Ground", 
	"Position Modify Warp Random", 
	"Position on Model Random", 
	"Position Within Box Random", 
	"Position Within Sphere Random", 
	"Radius Random", 
	"Remap Control Point to Scalar", 
	"Remap Control Point to Vector", 
	"Remap CP Orientation to Rotation", //NEW 3/26/25
	"Remap Initial Direction to CP to Vector", //NEW 3/26/25
	"Remap Initial Distance to Control Point to Scalar", 
	"Remap Initial Scalar",
	"Remap Noise to Scalar", 
	"Remap Particle Count to Scalar", 
	"Remap Scalar to Vector", 
	"Remap Speed to Scalar", //NEW 3/26/25
	"Rotation Random", 
	"Rotation Speed Random", 
	"Rotation Yaw Flip Random", 
	"Rotation Yaw Random", 
	"Scalar Random", 
	"Sequence From Control Point", //NEW 3/26/25
	"Sequence Random", 
	"Sequence Two Random", 
	"Set Hitbox Position on Model", 
	"Set Hitbox to Closest Hitbox", 
	"Trail Length Random", 
	"Vector Component Random", 
	"Vector Random", 
	"Velocity Inherit from Control Point", 
	"Velocity Noise", 
	"Velocity Random", 
	"Velocity Repulse from World", 
	"Velocity Set from Control Point", 
	//Emitter
	"emit noise", 
	"emit to maintain count", //NEW 3/26/25
	"emit_continuously", 
	"emit_instantaneously", 
	//ForceGenerator
	"Create vortices from parent particles", //NEW 3/26/25
	"Force based on distance from plane", //NEW 3/26/25
	"Pull towards control point", 
	"random force", 
	"time varying force", //NEW 3/26/25
	"turbulent force", //NEW 3/26/25
	"twist around axis", 
	//Constraint
	"Collision via traces", 
	"Constrain distance to control point", 
	"Constrain distance to path between two control points", 
	"Constrain particles to a box", //NEW 3/26/25
	"Prevent passing through a plane", 
	"Prevent passing through static part of world", 
}
local default_attribs2 = {}
for _, k in pairs (default_attribs) do
	default_attribs2[string.lower(k)] = true
end
default_attribs = default_attribs2
default_attribs2 = nil

function PartCtrl_GetUnhandledOperators()
	local allproperties = {
		["renderers"] = {},
		["operators"] = {},
		["initializers"] = {},
		["emitters"] = {},
		["forces"] = {}, //forcegenerator
		["constraints"] = {},
	}
	for _, filename in pairs (PartCtrl_AllPCFPaths) do
		local tab = PartCtrl_ReadPCF(filename)
		if tab then
			for particle, ptab in pairs (tab) do
				for category, _ in pairs (allproperties) do
					if ptab[category] then
						for _, attribute in pairs (ptab[category]) do
							local name = string.lower(attribute.functionName)
							if fixes[name] then name = fixes[name] end
							
							if !default_attribs[name] then
								allproperties[category][name] = allproperties[category][name] or { ["count"] = 0, ["paths"] = {} }
								allproperties[category][name].count = allproperties[category][name].count + 1
								table.insert(allproperties[category][name].paths, filename .. " " .. particle)
							end
						end
					else
						MsgN(filename, ": ", particle, " has no attribute category ", category)
					end
				end
			end
		end
	end

	PrintTable(allproperties)
end


//For testing purposes, lists all fx using a certain attribute, and optionally prints the attribute's values
//Example: PartCtrl_GetParticlesWithAttrib("Remap Control Point to Vector") to get all fx in all pcfs with that attribute, 
//or PartCtrl_GetParticlesWithAttrib("Remap Control Point to Vector", "particles/critglowtool_colorablefx.pcf") for just the fx in that file;
//add an extra "true" arg to the end of either of those to print the attribute's values
function PartCtrl_GetParticlesWithAttrib(desiredfunc, filename, extended)
	local function GetAttribsFromFile(desiredfunc, filename, extended)
		local tab = PartCtrl_ReadPCF(filename)
		if tab then
			for particle, ptab in PartCtrl_SortedPairsLower (tab) do
				for category, attribs in pairs (ptab) do
					if istable(attribs) then
						for k, v in pairs (attribs) do
							if istable(v) and v.functionName and string.lower(v.functionName) == string.lower(desiredfunc) then
								//MsgN("(", filename, ") ", particle)
								MsgN(particle, " ", filename) //actually do it like this so it's easier to spawn them in console
								if extended then
									MsgN(category, " ", desiredfunc)
									PrintTable(v)
									MsgN("")
								end
							end
						end
					end
				end
			end
		end
	end
	//filename arg is optional; if so, then check every file
	if !isstring(filename) then
		extended = filename
		for _, filename2 in pairs (PartCtrl_AllPCFPaths) do
			GetAttribsFromFile(desiredfunc, filename2, extended)
		end
	else
		GetAttribsFromFile(desiredfunc, filename, extended)
	end
end


//Test: Get a list of all pcfs that are defined by multiple games, and for each one, print the checksums of each copy of the file, along with the checksum
//of the one actually being loaded by the game. This lets us determine which games have unique instances of a pcf as opposed to identical copies, and also 
//tells us which ones are getting loaded vs. getting clobbered by mount order.
//TODO: almost certainly not necessary any more with the new data pcfs system
function PartCtrl_GetPCFConflicts(alternate)
	
	local particles = {}
	for k, v in pairs (PartCtrl_AllPCFPaths) do
		particles[v] = {}
	end
	local games = engine.GetGames()
	games[0] = {depot = 1, folder = "garrysmod", mounted = true}
	for k, v in pairs (games) do
		if !v.mounted then continue end

		//make folder and depot names all the same length so it reads better
		local folder2 = v.folder
		for i = 1, (17-#(v.folder)) do //longest folder name in engine.GetGames is thestanleyparable
			folder2 = folder2 .. " "
		end
		v.depot = tostring(v.depot)
		for i = 1, (7-#(v.depot)) do //longest depot number in engine.GetGames is treason's 1786950
			v.depot = " " .. v.depot
		end

		for name, _ in pairs (particles) do
			if !alternate then
				local f = file.Read(name, v.folder)
				if f then
					particles[name][v.depot .. ": " .. folder2] = util.SHA256(f)
				end
			else
				//alternative: get checksum of the table we return from reading the file, just in case there's some false positive making
				//file.Read return a non-identical string even if nothing relevant is different (i.e. file save timestamp or something?)
				//the results of this turned out to be no different from the above, and it's much slower, so don't do this by default.
				local f = PartCtrl_ReadPCF(name, v.folder)
				if f then
					particles[name][v.depot .. ": " .. folder2] = util.SHA256(util.TableToKeyValues(f))
				end
			end
		end
	end
	for name, v in pairs (particles) do
		if table.Count(v) <= 1 then
			particles[name] = nil
		else
			if !alternate then
				local f = file.Read(name, "GAME")
				if f then
					particles[name]["      0: mounted          "] = util.SHA256(f) //top of list
				end
			else
				//see above
				local f = PartCtrl_ReadPCF(name)
				if f then
					particles[name]["      0: mounted          "] = util.SHA256(util.TableToKeyValues(f)) //top of list
				end
			end
		end
	end
	PrintTable(particles)

end


//Test: Prints all differences between 2 raw pcf data tables.
function PartCtrl_ComparePCFs(file1, file2, shownil)

	local checksum1 = util.SHA256(file.Read(file1, "GAME"))
	local checksum2 = util.SHA256(file.Read(file2, "GAME"))
	if checksum1 == checksum2 then
		//files are identical, stop here
		MsgN("matching checksum ", checksum1)
		return
	end
	
	local allresults = {}

	//returns if a table is a default color table
	local function bad(tab)
		if (tab.r == 255 and tab.g == 255 and tab.b == 255 and (tab.a == nil or tab.a == 255))
		or (tab.r == 0 and tab.g == 0 and tab.b == 0 and (tab.a == nil or tab.a == 0)) then
			return true
		end
	end

	local function Compare(t1, t2, isfirst, spew)
		local allkeys = {}
		for k, _ in pairs (t1) do
			allkeys[k] = true
		end
		for k, _ in pairs (t2) do
			allkeys[k] = true
		end
		local results = {}
		for k, _ in PartCtrl_SortedPairsLower (allkeys) do
			if spew or t1[k] != t2[k] then
				if istable(t1[k]) and istable(t2[k]) then
					//They're both tables, compare their contents
					local results2 = Compare(t1[k], t2[k], false, spew)
					if #results2 > 0 or isfirst then
						local name = k
						if t1[k].functionName and t2[k].functionName then
							if t1[k].functionName == t2[k].functionName then
								name = tostring(k) .. " (" .. t1[k].functionName .. ")"
							else
								name = tostring(k) .. " (" .. t1[k].functionName .. "/" .. t2[k].functionName .. ")"
							end
						end
						if isfirst then 
							name = "\n\n\n\n@@@@@@@@@@@@@@@@@@@@@ " .. name //make effect names extra visible
						end
						table.insert(results, name)
						if #results2 > 0 then
							table.Add(results, results2)
						else
							table.insert(results, "no differences")
						end
						table.insert(results, "")
					end
				elseif shownil or (
					(
						t1[k] != nil or (istable(t2[k]) and !bad(t2[k]))
					) and 
					(
						t2[k] != nil or (istable(t1[k]) and !bad(t1[k]))
					)
				) then
					local name = k
					if istable(t1[k]) and t1[k].functionName then
						name = tostring(k) .. " (" .. t1[k].functionName .. ")"
					elseif istable(t2[k]) and t2[k].functionName then
						name = tostring(k) .. " (" .. t2[k].functionName .. ")"
					end
					local result1 = t1[k]
					local result2 = t2[k]
					if isfirst then
						name = "@@@@@@@@@@@@@@@@@@@@@ " .. name //make effect names extra visible
						//don't dump entire effect tables if they're only in 1 file
						if istable(result1) then result1 = "EFFECT ONLY IN " .. file1 end
						if istable(result2) then result2 = "EFFECT ONLY IN " .. file2 end
					end 
					if result1 == nil then result1 = "nil" end
					if result2 == nil then result2 = "nil" end
					table.Add(results, {name, result1, result2, ""})
				end
			end
		end
		return results
	end

	for _, v in pairs (Compare(PartCtrl_ReadPCF(file1), PartCtrl_ReadPCF(file2), true)) do
		if istable(v) then
			PrintTable(v)
		else
			MsgN(v)
		end
	end

end


//Test: Get all missing materials in a pcf
function PartCtrl_GetMissingPCFMats(filename)

	local function Check(filename2)
		local tab = {}
	
		for particle, ptab in pairs (PartCtrl_ReadPCF(filename2)) do
			local mat = "materials\\" .. string.StripExtension(ptab.material) .. ".vmt"
			if !file.Exists(mat, "GAME") then
				table.insert(tab, particle .. ": " .. mat)
			end
		end
		
		if table.Count(tab) > 0 then
			MsgN("Missing materials in ", filename2, ":")
			for k, v in pairs (tab) do
				local repstr = string.Replace(v, "\\", "/")
				local pos, _, _ = string.find(repstr, "materials/")
				repstr = string.Replace(repstr, "materials/effects/", "materials/effects/workshop/")
				repstr = string.sub(repstr, pos)
				//MsgN(repstr, file.Exists(repstr, "GAME"))
				if file.Exists(repstr, "GAME") then
					MsgN(v, ", should be ", repstr)
				else
					MsgN(v)
				end
			end
			MsgN("")
		end
	end

	//if filename is provided, check that file, otherwise check all files
	if filename then
		Check(filename)
	else
		for k, v in pairs (PartCtrl_AllPCFPaths) do
			Check(v)
		end
	end

end


//Test: Get all particle effects used by info_particle_system ents on the map
//TODO: should rework this from scratch, can we get a list of ents from the server but then do PartCtrl_PCFsByParticleName for each of them on client?
function PartCtrl_GetMapFx()

	for k, v in pairs (ents.FindByClass("info_particle_system")) do
		local name = v:GetInternalVariable("effect_name")
		MsgN(name)
		//this no longer works now that we only build PartCtrl_PCFsByParticleName clientside to save time
		--[[for _, v2 in pairs (PartCtrl_PCFsByParticleName[name]) do 
			//wanted to use this to figure out which instance of this effect is currently mounted,
			//but info_particle_system ents are only serverside and this table is only clientside, argh
			//MsgN(v2, " ", table.KeyFromValue(PartCtrl_AddParticles_AddedParticles, v2))
			MsgN(v2)
		end
		MsgN("")]]
	end

end


//For reference:
//Orangebox particle code: https://github.com/nillerusr/source-engine/tree/master/particles
//Newer (Portal 2/Alien Swarm/CSGO-era?) particle code: https://github.com/nillerusr/Kisak-Strike/tree/master/particles
//https://developer.valvesoftware.com/wiki/Category:Particle_System
local badoutputattribs = {
	["operator start fadein"] = 0,
	//["operator start fadeout"] = 0, //not actually functional without start fadein
	//["operator end fadein"] = 0, //not actually functional without end fadeout
	["operator end fadeout"] = 0,
	["first particle to copy"] = 1, //see striderbuster_flechette_attached
}
//new operator params that seem like they *might* matter re. outputs, but in practice, the only fx i could find with them were a few l4d2 ones,
//and none of them needed to have their outputs rejected, so ignore these for now
--[[local badoutputattribs2 = {
	["time strength random scale max"] = 1,
	["operator time scale seed"] = 0,
	["operator time scale min"] = 1,
	["operator time scale max"] = 1,
	["operator time offset seed"] = 0,
	["operator time offset min"] = 0,
	["operator time offset max"] = 0,
	["operator strength scale seed"] = 0,
	["operator strength random scale min"] = 1,
	["operator strength random scale max"] = 1,
	["operator fade oscillate"] = 0,
	["operator end cap state"] = -1,
}]]
function PartCtrl_CPoint_AddToProcessed(processed, k, name, processedk, processedv, attrib)
	if attrib then
		//if an output has a fadein/fadeout, then it isn't always overriding this cpoint, so we don't care about it - reject it
		if (processedk == "output" or processedk == "output_axis" or processedk == "output_children")
		and !string.StartsWith(name, "initializer") then //the operator fadein/out values exist on the only initializer output (initializer Velocity Repulse from World), but don't seem to work, so ignore them
			for bad, v in pairs (badoutputattribs) do
				if (attrib[bad] or 0) > v then //yes, they all default to 0
					//MsgN(name, " output doesn't always override cpoint because ", bad, " ", attrib[bad], " > ", v, ", rejecting") //no way to get the name of the particle with the output we're rejecting, argh
					//PrintTable(attrib)
					return
				end
			end
			//test: which fx even have these?
			--[[for bad, v in pairs (badoutputattribs2) do
				if attrib[bad] != nil and attrib[bad] > v then
					if !processed.bad2 then
						processed.bad2 = ""
					else
						processed.bad2 = processed.bad2 .. "\n"
					end
					processed.bad2 = processed.bad2 .. name .. ": " .. bad .. " = " .. attrib[bad]
				end
			end]]
		end
	end
	
	if processedk == nil then
		processedk = "position" //by far the most common use, so make it the default
	end
	if processedv == nil then
		processedv = {}
	else
		//Convenience handling to convert min/max to inMin/outMin + inMax/outMax, for utilfx that don't need to define these separately
		if processedv.min then
			processedv.inMin = processedv.min
			processedv.outMin = processedv.min
			processedv.min = nil
		end
		if processedv.max then
			processedv.inMax = processedv.max
			processedv.outMax = processedv.max
			processedv.max = nil
		end
		//Convenience handling for axis dropdown and checkbox controls:
		if processedv.dropdown then
			//Creates a dropdown control in the editor instead of a slider, but still uses axis internally for networking and dupes and stuff, so fill out all the necessary axis values
			//Networking sanity check clamps values between a min and max, so make sure we set those properly
			local min
			local max
			for k, v in pairs (processedv.dropdown) do
				if min == nil then
					min = k
					max = k
				else
					min = math.min(k, min)
					max = math.max(k, max)
				end
			end
			processedv.inMin = min
			processedv.inMax = max
			processedv.outMin = min
			processedv.outMax = max
			processedv.decimals = 0
		elseif processedv.checkboxes then
			//Similar to above, create a series of checkboxes in the editor instead of a slider, but works internally by setting an axis value to the sum of the checkbox values
			local min = 0
			local max = 0
			local label //in this case, only used by the spawnicon tooltip's list of editable options, so just make this a list of checkbox names separated by newlines
			for k, v in pairs (processedv.checkboxes) do
				max = max + k
				if !label then
					label = ""
				else
					label = label .. "\n"
				end
				label = label .. v
			end
			processedv.label = label
			processedv.inMin = min
			processedv.inMax = max
			processedv.outMin = min
			processedv.outMax = max
			processedv.decimals = 0
		elseif processedv.colorpicker then
			//the color picker only supports colors from 0-255, which correspond to a vector value on the particle effect from 0-1.
			//- some color controls have a narrower color range (outMin greater than 0, or outMax less than 1), and in those cases, the color picker
			//  would just arbitrarily stop changing the color once it goes past the min/max value, so instead we rescale those so that the picker
			//  always displays the min value as 0,0,0 and the max value as 255,255,255. (example: many portal2 colorable portalgun fx)
			//- some color controls also have a broader color range than 0-1 (outMin less than 0, or outMax greater than 1), but supporting these
			//  in the color picker in the same way proved not to be useful because they'd either A: stop doing anything past a value of 1, or even 
			//  B: overflow into an entirely different color value, producing nonsense colors (example: portal2 paintgun fx)
			//cache these here because a bunch of stuff uses this (color picker, color tool setcolor, spawnicons)
			//TODO: this completely breaks on a test effect where outMin has a narrower range but outMax has a broader range, or vice versa;
			//can't wrap my head around the math it would take to fix this, but thankfully i can't find any real fx that have this issue
			processedv.outMin2 = Vector(
				math.Min(processedv.outMin.x, 0),
				math.Min(processedv.outMin.y, 0),
				math.Min(processedv.outMin.z, 0)
			)
			processedv.outMax2 = Vector(
				math.Max(processedv.outMax.x, 1),
				math.Max(processedv.outMax.y, 1),
				math.Max(processedv.outMax.z, 1)
			)
		end
	end
	processedv["name"] = name
	processed.cpoints[k] = processed.cpoints[k] or {}
	processed.cpoints[k][processedk] = processed.cpoints[k][processedk] or {}

	table.insert(processed.cpoints[k][processedk], processedv)
end

local function cpoint_from_attrib_value(processed, attrib, value, default_k, processedk, processedv)
	local k = attrib[value] or default_k
	if k > -1 or (processedv and processedv["force_allow_-1"]) then
		local name = value
		if attrib.functionName then
			name = attrib.functionName .. ": " .. name
		end
		if attrib._categoryName then
			name = attrib._categoryName .. " " .. name
		end
		PartCtrl_CPoint_AddToProcessed(processed, k, name, processedk, processedv, attrib)
	end
end

local function DoScalarIO(attrib, use_distance_input, is_position_control)
	local field = attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS //PARTICLE_ATTRIBUTE_x enum
	local label = ParticleAttributeNames[field]
	local inMin
	local inMax
	if !use_distance_input then
		inMin = attrib["input minimum"] or 0
		inMax = attrib["input maximum"] or 1
	else
		inMin = attrib["distance minimum"] or 0
		inMax = attrib["distance maximum"] or 128
	end
	local outMin = attrib["output minimum"] or 0
	local outMax = attrib["output maximum"] or 1
	local is_multiplier = attrib["output is scalar of initial random range"] or attrib["output is scalar of current value"] //initializers don't have the latter, but this should be fine
	local default
	local decimals = nil
	if !is_position_control then
		//Defaults for axis controls (slider in options menu)
		if field == PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS and !is_multiplier then
			//radius scalars should default to a nice big size, not 1 pixel
			default = math.Remap(8, outMin, outMax, inMin, inMax)
		elseif field == PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA or field == PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA2 then 
			//Alpha should always default to max visibility;
			//make sure to handle wacky fx like tf2's speech_mediccall that flip the scale around on output
			if outMin <= outMax then
				default = math.max(inMin, inMax)
			else
				default = math.min(inMin, inMax)
			end
		elseif field == PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER or field == PARTCTRL_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1 then
			//don't let sequence number scalars set the value to 64, or it'll crash (for particles/asw_order_fx.pcf order_use_item)
			if outMax > 63 then
				inMax = math.Remap(63, outMin, outMax, inMin, inMax)
				outMax = 63
			end
			//sequence number scalars should be whole numbers, and default to 0 (first sequence)
			default = math.Remap(0, outMin, outMax, inMin, inMax)
			decimals = 0
		else
			//default to 1
			default = math.Remap(1, outMin, outMax, inMin, inMax)
		end
		//make sure the default value of the control in the edit window isn't outside its range
		default = math.Clamp(default, math.Remap(outMin, outMin, outMax, inMin, inMax), math.Remap(outMax, outMin, outMax, inMin, inMax))
		if is_multiplier then
			label = label .. " Scale"
		end
	else
		//Defaults for position controls (movable cpoint in the world)
		//clamping in/outMin/Max is not applicable to these, since we can't actually clamp where the player can move the position control to
		//don't print "Scale" in label for these ones, this looks bad
		default = (inMin + inMax) / 2 //test: set the default distance to the midpoint of the effective radius, so players can visibly see what the scalar cpoint is doing
	end

	return {
		["label"] = label,
		["inMin"] = inMin,
		["inMax"] = inMax,
		["outMin"] = outMin,
		["outMax"] = outMax,
		["default"] = default,
		["decimals"] = decimals,
	}
end

local function DoVectorIO(attrib)
	local field = attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_XYZ //PARTICLE_ATTRIBUTE_x enum //assume the default is Position because that's what shows in pet by default, just like Radius is for scalars; can't find any v5 fx to test with that omit this value
	local label = ParticleAttributeNames[field]
	local inMin = attrib["input minimum"] or Vector()
	local inMax = attrib["input maximum"] or Vector()
	local outMin = attrib["output minimum"] or Vector()
	local outMax = attrib["output maximum"] or Vector()
	local is_multiplier = attrib["output is scalar of initial random range"] or attrib["output is scalar of current value"] //initializers don't have the latter, but this should be fine
	local default = nil
	local colorpicker = nil
	if field == PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB or is_multiplier then
		//Color should default to the equivalent of 1,1,1 (white),
		//and multipliers should default to 100%
		default = Vector(math.Remap(1, outMin.x, outMax.x, inMin.x, inMax.x), math.Remap(1, outMin.y, outMax.y, inMin.y, inMax.y), math.Remap(1, outMin.z, outMax.z, inMin.z, inMax.z))
		if field == PARTCTRL_PARTICLE_ATTRIBUTE_TINT_RGB then
			colorpicker = true
		end
	else
		//default to 0
		default = Vector(math.Remap(0, outMin.x, outMax.x, inMin.x, inMax.x), math.Remap(0, outMin.y, outMax.y, inMin.y, inMax.y), math.Remap(0, outMin.z, outMax.z, inMin.z, inMax.z))
	end
	for i = 1, 3 do
		//make sure the default value of the control in the edit window isn't outside its range (see portal 2 portalgun_top_light_squiggles)
		default[i] = math.Clamp(default[i], math.Remap(outMin[i], outMin[i], outMax[i], inMin[i], inMax[i]), math.Remap(outMax[i], outMin[i], outMax[i], inMin[i], inMax[i]))
	end
	if is_multiplier then
		label = label .. " Scale"
	end

	return {
		["label"] = label,
		["inMin"] = inMin,
		["inMax"] = inMax,
		["outMin"] = outMin,
		["outMax"] = outMax,
		["default"] = default,
		["colorpicker"] = colorpicker,
	}
end

local processfuncs = {
	["renderers"] = {
		["render models"] = function(processed, attrib) processed["has_renderer"] = true end, //add this value manually for each renderer attribute, rather than doing it in _generic, so that we can catch fx that don't have a valid one, like those ep2 blob fx
		["render_rope"] = function(processed, attrib)
			//this definitely isn't how this is intended to be used lol; GOTTA SUPPORT IT ANYWAY
			if ((attrib["scale CP start"] or -1) > -1) and ((attrib["scale CP end"] or -1) > -1) then
				local scalar = nil
				for varname, label in pairs({
					["scale texture by CP distance"] = "texture",
					["scale scroll by CP distance"] = "scroll",
					["scale offset by CP distance"] = "offset",
				}) do
					if attrib[varname] then
						if !scalar then
							scalar = "Rope " .. label
						else
							scalar = scalar .. ", " .. label
						end
					end
				end
				if scalar then
					scalar = scalar .. " scale"
					cpoint_from_attrib_value(processed, attrib, "scale CP end", -1, "axis", {
						["axis"] = 0, //arbitrary; any axis could work for this, but ent_partctrl:StartParticle checks which_0 for relative_to_cpoint
						["label"] = scalar,
						["inMin"] = 0,
						["outMin"] = 0,
						["inMax"] = 1024, //arbitrary max scale; these are really small units and are meant to rescale the beam texture to be suitable for a beam X units long
						["outMax"] = 1024,
						["default"] = 100, //arbitrary default
						["relative_to_cpoint"] = attrib["scale CP start"] or -1 //?
					})
					cpoint_from_attrib_value(processed, attrib, "scale CP start", -1, "position_combine") //this is iffy; we assume the start cpoint might be attached to something while the end point isn't
				end
			end
			processed["has_renderer"] = true
		end,
		["render_sprite_trail"] = function(processed, attrib) processed["has_renderer"] = true end,
		["render_animated_sprites"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "orientation control point", -1, "position_combine")
			processed["has_renderer"] = true //global value on the effect, not cpoint-specfic
		end, //TODO: limit this to "orientation_type" cases where the orientation is actually used for something? this is sort of dependent on the VMT to work actually
		["_generic"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Visibility Proxy Input Control Point Number", -1, "position_combine") end, //pet doesn't add cpoint control for this; all renderers except render_rope have this; uses this position for visiblilty testing, which can then scale particle alpha/size based on how visible the area around the point is (https://developer.valvesoftware.com/wiki/Generic_Render_Operator_Visibility_Options)
	},
	["operators"]= {
		["alpha fade and decay"] = function(processed, attrib)
			//only do tracer_min_distance if we have one of the right decay operators; tracer fx using other things 
			//(i.e. alien swarm tracers using "alpha fade and decay for tracers") don't have a minimum length between cpoints to render
			processed["tracer_min_distance_hasdecay"] = true
		end,
		["color light from control point"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "Light 1 Control Point", 0, "position_combine")
			cpoint_from_attrib_value(processed, attrib, "Light 2 Control Point", 0, "position_combine")
			cpoint_from_attrib_value(processed, attrib, "Light 3 Control Point", 0, "position_combine")
			cpoint_from_attrib_value(processed, attrib, "Light 4 Control Point", 0, "position_combine")
		end,
		["cull relative to model"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, nil, { //TODO: should this be a position_combine? can't actually find any fx that use this, even in portal2/asw/l4d2
			["ignore_outputs"] = true, //this cpoint sets an associated model, not a position, so outputs don't override it
		}) end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Cull_relative_to_model, yeah it's on the wrong page); pet doesn't add a control for this
		["cull when crossing plane"] = function(processed, attrib) 
			local norm = attrib["Plane Normal"] or Vector(0,0,1)
			cpoint_from_attrib_value(processed, attrib, "Control Point for point on plane", 0, nil, {
				["plane"] = {
					["pos"] = norm * -(attrib["Cull plane offset"] or 0),
					["pos_fixed_offset"] = true,
					["normal"] = norm,
					["normal_global"] = true
				}		
			})
		end,
		["cull when crossing sphere"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point", 0) end,
		["lifespan decay"] = function(processed, attrib)
			//only do tracer_min_distance if we have one of the right decay operators; tracer fx using other things 
			//(i.e. alien swarm tracers using "alpha fade and decay for tracers") don't have a minimum length between cpoints to render
			processed["tracer_min_distance_hasdecay"] = true
		end,
		["lifespan maintain count decay"] = function(processed, attrib)
			local axis = attrib["maintain count scale control point field"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "maintain count scale control point", -1, "axis", {
					["axis"] = axis,
					["label"] = "Maintain Count Scale",
					["inMin"] = 0,
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
		end,
		["movement basic"] = function(processed, attrib)
			//stupid handling for one effect that has a cpoint with just a force "move towards control point", but also maximum drag on its movement basic that makes the force not work (particles/taunt_fx.pcf taunt_yeti_fistslam_whirlwind)
			if (attrib["drag"] or 0) >= 0.98 then
				processed["drag_does_override"] = true //global value on the effect, not cpoint-specific
			end
		end,
		--[[["movement lag compensation"] = function(processed, attrib)
			//description: "Movement Lag Compensation - Sets a speed and decelerates it based on an input lag amount (Sort of DotA specific)"
			//in practice, uses the length of (or the value of an axis of) one cpoint to set the desired speed, and then uses the value of
			//another cpoint's axis (which is meant to be a ping value?) to do some remapping math to multiply that speed by up to 3.
			https://github.com/kallinosis-dev/srcmodbase-source/blob/dev/particles/builtin_particle_ops.cpp#L8142
			//this is complicated and i can't find any existing fx using it in porta2/asw/l4d2, so it's hard to say what controls we should
			//add to support it. leave this blank until we find an effect we need to add support for.
		end,]]
		["movement dampen relative to control point"] = function(processed, attrib) 
			if attrib["falloff range"] >= 5 then //don't process if this value is too small to do anything (lots of ep2 electrical fx have extra useless cpoints with only these for whatever reason)
				cpoint_from_attrib_value(processed, attrib, "control_point_number", 0)
			end
		end,
		["movement lock to bone"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine", {["ignore_outputs"] = true}) //this cpoint sets an associated model, not a position, so outputs don't override it
			processed["movement_lock"] = processed["movement_lock"] or {}
			processed["movement_lock"][attrib["control_point_number"] or 0] = true
		end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_System_Operators#Movement_Lock_to_Bone)
		["movement lock to control point"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine")
			processed["movement_lock"] = processed["movement_lock"] or {}
			processed["movement_lock"][attrib["control_point_number"] or 0] = true
		end,
		["movement lock to saved position along path"] = function(processed, attrib)
			//this is intended to use matching cpoints with position along path sequential, but you can set them to different
			//cpoints to make wacky nonsense where those cpoints move the effect instead, which to be fair is the sort of thing
			//position_combine is for, since that's not likely to be intended.
			//only works if the saved position is set by something like initializer "Position Along Path Sequential" with "Save Offset" enabled;
			//and some fx designers include this anyway even though it doesn't work (smissmas2021_unusuals.pcf unusual_smissmas_tree_* fx),
			//so we definitely don't want to make position controls for these.
			if attrib["Use sequential CP pairs between start and end point"] then
				//uses all cpoints from start to end
				local startp = attrib["start control point number"] or 0
				local endp = attrib["end control point number"] or 1
				local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
				for i = startp, endp do
					PartCtrl_CPoint_AddToProcessed(processed, i, name, "position_combine", nil, attrib)
				end
			else
				//uses start and end cpoint only
				cpoint_from_attrib_value(processed, attrib, "start control point number", 0, "position_combine")
				cpoint_from_attrib_value(processed, attrib, "end control point number", 1, "position_combine") //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			end
		end,
		["movement maintain offset"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Local Space CP", 0, "position_combine") end, //rotates the "desired offset" value by the angles of the cpoint; follow the precedent of angle-only cpoints being combined
		["movement maintain position along path"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "start control point number", 0, nil, {["sets_particle_pos"] = true})
			cpoint_from_attrib_value(processed, attrib, "end control point number", 0, nil, {["sets_particle_pos"] = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			//if there's no way for other cpoint attribs (like the ones that initialize in a box/sphere) to influence the particles because this attrib forces them onto a very specific path, then don't make position controls for those cpoints
			//this functionality was intended for constraints, but this operator does the same thing
			if (attrib["maximum distance"] or 0) < 1 then
				processed["constraint_does_override"] = true //global value on the effect, not cpoint-specific
			end
		end,
		["movement match particle velocities"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point to Broadcast Speed and Direction To", -1, "output") end, //pet doesn't add control for this; sets all 3 axes of the cpoint's position vector to the speed, and sets the cpoint's angle to face the direction (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_ops.cpp#L3788)
		["movement max velocity"] = function(processed, attrib)
			local axis = attrib["Override CP field"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "Override Max Velocity from this CP", -1, "axis", {
					["axis"] = axis,
					["label"] = "Max Velocity",
					["inMin"] = 0,
					["outMin"] = 0,
					["inMax"] = 2500, //arbitrary max, because the default max of 10 is too low;
					["outMax"] = 2500, //no idea if this is good, because i can't find any existing fx using this
					["default"] = 1,
				})
			end
		end,
		--[[["movement place on ground"] = function(processed, attrib)
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L9390
			//uses the movement of the last two cpoints to throttle updates; if either one has moved enough from its previous pos, then update immediately.
			//also uses the movement of the first one to throttle something(?) involving interpolation the same way.
			//no existing portal2/asw/l4d2 fx use this, is this a dota thing? can't even get a custom effect to use these in any meaningful way, ignore for now.
			cpoint_from_attrib_value(processed, attrib, "interploation distance tolerance cp", -1, "position_combine") //sic
			cpoint_from_attrib_value(processed, attrib, "reference CP 1", -1, "position_combine")
			cpoint_from_attrib_value(processed, attrib, "reference CP 2", -1, "position_combine")
		end,]]
		["movement rotate particle around axis"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point", 0) end,
		["normal lock to control point"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine") end, //controls angle of Render Models fx; this is an angle control, so combine it
		["remap average scalar value to cp"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "output control point", 1, "output") end, //overrides the cpoint's position to Vector(result,0,0) (https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L2602)
		["remap control point direction to vector"] = function(processed, attrib) 
			//like remap control point to vector, but it sets the vector to the forward normal vector of the cpoint's angle.
			//can't really turn this into a set of sliders/color picker since that's not how normals work, and the only existing
			//fx that use this are some alien swarm gib fx that use it to set the particle's "normal" vector to control the gib
			//model's angle, so make this a position_combine.
			cpoint_from_attrib_value(processed, attrib, "control point number", 0, "position_combine") 
		end, 
		["remap control point to scalar"] = function(processed, attrib)
			//controls a whole bunch of stuff (lifetime, radius, alpha, etc.) with the value of a single axis of the cpoint, definitely not a position control
			local axis = attrib["input field 0-2 X/Y/Z"] or 0
			if axis > -1 then
				local tab = DoScalarIO(attrib)
				cpoint_from_attrib_value(processed, attrib, "input control point number", 0, "axis", {
					["axis"] = axis,
					["label"] = tab.label,
					["inMin"] = tab.inMin,
					["inMax"] = tab.inMax,
					["outMin"] = tab.outMin,
					["outMax"] = tab.outMax,
					["default"] = tab.default,
					["decimals"] = tab.decimals,
				})
			end
		end,
		["remap control point to vector"] = function(processed, attrib)
			//Similar to above, use all 3 axes of the cpoint to set Position, Roll, or Color
			//TF2/episodes/HL2 pcfs only have use cases for Color, so the others required some testing.
			local tab = DoVectorIO(attrib)
			cpoint_from_attrib_value(processed, attrib, "input control point number", 0, "vector", {
				["label"] = tab.label,
				["inMin"] = tab.inMin,
				["inMax"] = tab.inMax,
				["outMin"] = tab.outMin,
				["outMax"] = tab.outMax,
				["default"] = tab.default,
				["colorpicker"] = tab.colorpicker,
			})
			cpoint_from_attrib_value(processed, attrib, "local space CP", -1, "position_combine") //uses the cpoint's angles to rotate the output in some odd way, can be used to make a position sort-of-rotate with the cpoint, or make colors change as it spins
		end,
		["remap cp speed to cp"] = function(processed, attrib)
			local axis = attrib["Output field 0-2 X/Y/Z"] or 0
			if axis > -1 and (attrib["output control point"] or -1) != -1 then
				cpoint_from_attrib_value(processed, attrib, "input control point", 0, "position_combine") //only used if the output is defined (https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L2383)
				cpoint_from_attrib_value(processed, attrib, "output control point", -1, "output_axis", {["axis"] = axis})
			end
		end,
		["remap cp velocity to vector"] = function(processed, attrib)
			//like remap control point to vector, but it sets the vector to the cpoint's velocity value.
			//can't really turn this into a set of sliders/color picker unless we make some custom functionality to constantly move
			//the cpoint around, and i can't find any existing fx using this to accomodate, so just position_combine it for now.
			cpoint_from_attrib_value(processed, attrib, "control point", 0, "position_combine")
		end,
		["remap direction to cp to vector"] = function(processed, attrib)
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L9390
			//uses the angle of the cpoint to set a vector value; only existing fx i could find using this are a few in  portal 2's portals.pcf,
			//which use it to set the new "normal" value; creates an extraneous cpoint that doesn't visibly do anything, so just position_combine it.
			cpoint_from_attrib_value(processed, attrib, "control point", 0, "position_combine")
		end,
		["remap distance between two control points to cp"] = function(processed, attrib)
			//i guess we could convert this into a relative_to_cp vector control just like "remap distance between two control points to scalar" below,
			//but what would we actually describe the control as? can't find any existing fx using this, so just add normal position controls and output for now.
			cpoint_from_attrib_value(processed, attrib, "starting control point", 0)
			cpoint_from_attrib_value(processed, attrib, "ending control point", 1)
			local axis = attrib["output control point field"] or 0
			if axis > -1 and (attrib["output control point"] or 2) != -1 then
				cpoint_from_attrib_value(processed, attrib, "output control point", 2, "output_axis", {["axis"] = axis})
			end
		end,
		["remap distance between two control points to scalar"] = function(processed, attrib)
			//this uses all the same scalars as remap control point to scalar, but actually uses the distance between two positions to get the value
			local tab = DoScalarIO(attrib, true)
			cpoint_from_attrib_value(processed, attrib, "ending control point", 1, "axis", {
				["axis"] = 0, //arbitrary; any axis could work for this, but ent_partctrl:StartParticle checks which_0 for relative_to_cpoint
				["label"] = tab.label,
				["inMin"] = tab.inMin,
				["inMax"] = tab.inMax,
				["outMin"] = tab.outMin,
				["outMax"] = tab.outMax,
				["default"] = tab.default,
				["decimals"] = tab.decimals,
				["relative_to_cpoint"] = attrib["starting control point"] or 0 //?
			})
			cpoint_from_attrib_value(processed, attrib, "starting control point", 0, "position_combine") //this is iffy; we assume the start cpoint might be attached to something while the end point isn't, which *is* the case with all existing fx, but doesn't necessarily have to be
		end,
		["remap distance to control point to scalar"] = function(processed, attrib)
			//like the above, but uses the distance between a single cpoint's position and each individual particle itself (https://developer.valvesoftware.com/wiki/Particle_System_Operators#Remap_Distance_to_Control_Point_to_Scalar)
			cpoint_from_attrib_value(processed, attrib, "control point", 0, nil, {["distance_scalar"] = DoScalarIO(attrib, true, true)})
		end,
		["remap dot product to scalar"] = function (processed, attrib)
			//like "remap control point to scalar", except it gets the angle(?) of 2 cpoints and does math with them to set the scalar. not listed in wiki.
			//every example i could find for this (it's used by a lot of "ring" child fx in dr grordbord fx) works in conjunction with another "set control point to player" operator, which 
			//uses an output to set a cpoint to the player's position. then, this operator does math with that to set output field Yaw (12) to rotate the particles, attempting to orient 
			//them to face "forward" in the direction of the first cpoint(not the player one), with mixed results. the only exceptions i could find for this were some unused effects in 
			//eyeboss.pcf, which were the same but without the player cpoint, and instead use the angle (not the position!) of the second cpoint to change the particle's yaw.
			//whatever, just make this a position control, seems it's like "remap direction to cp to vector", and should be either this or a manual angle input.
			//update: actually just combine this one, the only effects that have a position control *for this operator only* are ones that didn't set up the player yaw thing properly
			local label = ParticleAttributeNames[attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS] //PARTICLE_ATTRIBUTE_x enum //put this in the table so we can see what it does in the debug
			cpoint_from_attrib_value(processed, attrib, "first input control point", 0, "position_combine", {["label"] = label})
			cpoint_from_attrib_value(processed, attrib, "second input control point", 0, "position_combine", {["label"] = label})
		end,
		["remap particle bbox volume to cp"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "output control point", -1, "output") end, //sets the whole cpoint to Vector(volume,0,0) https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L2532
		["remap percentage between two control points to scalar"] = function(processed, attrib)
			//sets a scalar value on *each individual particle* based on what percentage of the distance between two cpoints it's covered
			//TODO: do we need to handle this like distance scalars?
			cpoint_from_attrib_value(processed, attrib, "starting control point", 0)
			cpoint_from_attrib_value(processed, attrib, "ending control point", 1)
		end,
		["remap percentage between two control points to vector"] = function(processed, attrib)
			//sets a vector value on *each individual particle* based on what percentage of the distance between two cpoints it's covered
			//TODO: do we need to handle this like distance scalars?
			cpoint_from_attrib_value(processed, attrib, "starting control point", 0)
			cpoint_from_attrib_value(processed, attrib, "ending control point", 1)
		end,
		["restart effect after duration"] = function(processed, attrib)
			local axis = attrib["Control Point Field X/Y/Z"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "Control Point to Scale Duration", -1, "axis", {
					["axis"] = axis,
					["label"] = "Duration Scale",
					["inMin"] = 0, //no point in negative scale for this one
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
		end,
		["rotation orient relative to cp"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point", 0) end,
		["set child control points from particle positions"] = function(processed, attrib)
			local groupid = attrib["Group ID to affect"] or 0
			local startp = attrib["First control point to set"] or 0
			local endp = startp + ((attrib["# of control points to set"] or 1) - 1)
			local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
			for i = startp, endp do
				PartCtrl_CPoint_AddToProcessed(processed, i, name, "output_children", {["groupid"] = groupid}, attrib)
			end
			//some fx (i.e. utaunt_tornado_oscillate_) emit invisible particles (no renderer) and then use them to set the position of a child control point. ordinarily, we'd cull the
			//cpoint data from fx with no renderer, because their attribs don't do anything that the player can see, but in this case, we don't want to do that, so mark as having a renderer.
			//TODO: this might be bad if the children don't have a renderer either, can we catch those?
			if #processed["children"] > 0 then
				processed["has_renderer"] = true
				processed["ignore_zero_alpha"] = true //for particles/infection_particles.pcf: zombie_lightning_controller
			end
			//processed["sets_particle_pos_on_children"] = groupid
		end,
		["set control point positions"] = function(processed, attrib)
			local cpoints = {
				[1] = {
					//["input"] = "First Control Point Parent",
					//["input_def"] = 0,
					["output"] = "First Control Point Number",
					["output_def"] = 1,
					["location"] = "First Control Point Location",
					["location_def"] = Vector(128, 0, 0),
				},
				[2] = {
					//["input"] = "Second Control Point Parent",
					//["input_def"] = 0,
					["output"] = "Second Control Point Number",
					["output_def"] = 2,
					["location"] = "Second Control Point Location",
					["location_def"] = Vector(0, 128, 0),
				},
				[3] = {
					//["input"] = "Third Control Point Parent",
					//["input_def"] = 0,
					["output"] = "Third Control Point Number",
					["output_def"] = 3,
					["location"] = "Third Control Point Location",
					["location_def"] = Vector(-128, 0, 0),
				},
				[4] = {
					//["input"] = "Fourth Control Point Parent",
					//["input_def"] = 0,
					["output"] = "Fourth Control Point Number",
					["output_def"] = 4,
					["location"] = "Fourth Control Point Location",
					["location_def"] = Vector(0, -128, 0),
				},
			}
			local used_cpoint //fix some fx that have an output set to the main cpoint they're all offset from (tfc_sniper_charge_blue) - in these cases, the cpoint is not overridden
			if !attrib["Set positions in world space"] then //according to code, only used if not setting in world space (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_ops.cpp#L2725)
				local tab2 = {}
				for k, tab in pairs (cpoints) do
					tab2[attrib[tab.output] or tab.output_def] = true
				end
				cpoint_from_attrib_value(processed, attrib, "Control Point to offset positions from", 0, nil, {
					["doesnt_need_renderer_or_emitter"] = true, 
					["copy_sets_particle_pos"] = tab2}
				)
				used_cpoint = attrib["Control Point to offset positions from"] or 0
				if used_cpoint == -1 then used_cpoint = nil end //TODO: nothing actually does this?
			else
				//If set to positions in worldspace, these cpoints can break spawnicon renderbounds, so tell it to account for that
				processed["spawnicon_forcedpositions"] = processed["spawnicon_forcedpositions"] or {0,0,0,0,0,0}
				for k, tab in pairs (cpoints) do
					//Create a table of 6 numbers, the mins and maxs of the forced positions
					local function DoParticle3(i, domax, axis)
						local val = attrib[tab.location] or tab.location_def
						if !domax then
							processed["spawnicon_forcedpositions"][i] = math.min(processed["spawnicon_forcedpositions"][i], val[axis])
						else
							processed["spawnicon_forcedpositions"][i] = math.max(processed["spawnicon_forcedpositions"][i], val[axis])
						end
					end
					DoParticle3(1, false, "x")
					DoParticle3(2, false, "y")
					DoParticle3(3, false, "z")
					DoParticle3(4, true, "x")
					DoParticle3(5, true, "y")
					DoParticle3(6, true, "z")
				end
			end

			for k, tab in pairs (cpoints) do
				//after testing, i can't find any evidence that these "parent" cpoints actually do anything. if we're setting positions in world space, then 
				//the positions are relative to the world, not the parent cpoints. if they're not being set in world space, then they're relative to used_cpoint, 
				//not the parent cpoints. leaving this here just in case we find an exception later.
				--[[//do inputs - add position controls for the "parent" cpoints that move things around
				if used_cpoint == nil then //if "control point to offset positions from" is being used, then control point parents are not used, see L4D2 storm_lightning_0#_branch_# fx and our test effect test_cpointpos_2
					cpoint_from_attrib_value(processed, attrib, tab.input, tab.input_def, nil, {["doesnt_need_renderer_or_emitter"] = true, ["remove_if_other_cpoint_is_empty"] = attrib[tab.output] or tab.output_def})
				end]]
				//then do outputs - remove position controls from the "child" cpoints that are having their positions overridden
				if (attrib[tab.output] or tab.output_def) != used_cpoint then
					cpoint_from_attrib_value(processed, attrib, tab.output, tab.output_def, "output")
				end
			end
		end,
		--[[["set control point rotation"] = function(processed, attrib)
			//the rotation from this cpoint gets stomped by the angle of the position control, and i don't see a way to fix this. 
			//even output isn't great because either A: the cpoint being rotated is the first cpoint, it gets assigned to fallback cpoint
			//-1 instead, and it uses the angle of *that* instead, or B: the cpoint being rotated doesn't get a position set and ends up
			//at 0,0,0. hrmph.
			//only way to fix all this would be to add special handling for cpoints using this operator, where ent_partctrl would use
			//something other than self.particle:AddControlPoint so that the cpoint angle doesn't get set. i can't find any working 
			//effects that actually use this, so that would be overengineered for now.
			cpoint_from_attrib_value(processed, attrib, "Control Point", 0, "output")
			//there's also a "Local Space Control Point" we could position_combine, but again, not useful.
		end,]]
		["set control point to impact point"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "Control Point to Trace From", 1, "position_combine", 
				{["copy_sets_particle_pos"] = {
					[attrib["Control Point to Set"] or 1] = true
				}}
			)
			cpoint_from_attrib_value(processed, attrib, "Control Point to Set", 1, "output") 
			//note: if we have a control for the output cpoint (i.e. output doesn't get set because of fadein or something), 
			//then this operator's changes get squashed completely, even for the window of time where it *should* be doing something.
			//all existing fx i could find with these conditions work better with a cpoint, though, so do it this way for now.
		end,
		["set control point to particles' center"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control Point Number to Set", 1, "output") end,
		["set control point to player"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "Control Point Number", 1, "output")
			processed["spawnicon_playerposfix"] = true //this attrib forces a cpoint to the player's position, which can break spawnicon renderbounds, so tell it to account for that
		end,
		["set control points from particle positions"] = function(processed, attrib)
			//like "set child control points from particle positions", but it sets the effect's own cpoints instead.
			//only existing effect i could find using this was portal 2's dissolve_flashes_glow particles/spark_fx.pcf, which uses
			//it to move the renderer's "Visibility Proxy Input Control Point Number" to each particle as it's spawned, and i made
			//a test effect that uses it functionally the same way as the child one, by moving a cpoint that's only used by child fx.
			local startp = attrib["First control point to set"] or 0
			local endp = startp + ((attrib["# of control points to set"] or 1) - 1)
			local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
			for i = startp, endp do
				PartCtrl_CPoint_AddToProcessed(processed, i, name, "output", nil, attrib)
			end
		end,
		["set cp offset to cp percentage between two control points"] = function(processed, attrib)
			//this one is pretty elaborate, it gets the position of an "input" control point relative to two other "start" and
			//"ending" control points, uses it to scale a value relative to a fourth "offset" control point, and then outputs 
			//that to a fifth "output" control point.
			//no existing portal2/asw/l4d2 fx use this, what could this possibly be for? just handle the output and then do 
			//normal position controls for the rest, until we find an effect we need to accomodate.
			cpoint_from_attrib_value(processed, attrib, "starting control point", 0)
			cpoint_from_attrib_value(processed, attrib, "ending control point", 1)
			cpoint_from_attrib_value(processed, attrib, "offset control point", 2)
			cpoint_from_attrib_value(processed, attrib, "input control point", 3)
			cpoint_from_attrib_value(processed, attrib, "output control point", 4, "output") //note: this output gets clobbered if we make a position control for the same cpoint, probably interacts badly if we don't create this control due to fadein or something
		end,
		--[[["set cp orientation to cp direction"] = function(processed, attrib)
			//gets the direction the input cpoint is currently moving, and rotates the angle of the output cpoint
			//to point in that direction. no existing portal2/asw/l4d2 fx use this, what is this used for?
			//the output angle gets clobbered by the angle of the position control if it has one, so should we handle this like
			//a pos output to keep it untouched? maybe wait until there's an effect using this to see how we should accomodate it.
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L9338
			cpoint_from_attrib_value(processed, attrib, "input control point", 0)
			cpoint_from_attrib_value(processed, attrib, "output control point", 0, "output")
		end,]]
		["set per child control point from particle positions"] = function(processed, attrib)
			//sets a single control point on a limited number of child fx
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L5220
			local groupid = attrib["Group ID to affect"] or 0
			local limit = attrib["# of children to set"] or 1
			cpoint_from_attrib_value(processed, attrib, "control point to set", 0, "output_children", {["groupid"] = groupid, ["limit"] = limit})

			//again, like "set child control points from particle positions", some fx (portalgun_beam_holding_object) emit invisible particles (no renderer) 
			//and then use them to set the position of a child control point. ordinarily, we'd cull the cpoint data from fx with no renderer, because their 
			//attribs don't do anything that the player can see, but in this case, we don't want to do that, so mark as having a renderer.
			//TODO: this might be bad if the children don't have a renderer either, can we catch those?
			if #processed["children"] > 0 then processed["has_renderer"] = true end
			//processed["sets_particle_pos_on_children"] = groupid
		end,
		["stop effect after duration"] = function(processed, attrib)
			local axis = attrib["Control Point Field X/Y/Z"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "Control Point to Scale Duration", -1, "axis", {
					["axis"] = axis,
					["label"] = "Duration Scale",
					["inMin"] = 0, //no point in negative scale for this one
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
		end,
	},
	["initializers"] = {
		["alpha random"] = function(processed, attrib)
			//some fx use an alpha of 0 to make it invisible?? who does that??
			//(particles/scary_ghost (plr_hacksaw_event).pcf: halloween_boss_eye_glow)
			if (attrib["alpha_max"] or 255) == 0 and (attrib["alpha_min"] or 255) == 0 then
				processed["has_zero_alpha"] = true
			end
		end,
		["color random"] = function(processed, attrib)
			if (attrib["tint_perc"] or 0) > 0 then //by default, the value of "tint control point" is 0, not -1, so pet adds a control for it by default, but in code, this isn't used unless tint_perc is non-zero (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L1705)
				cpoint_from_attrib_value(processed, attrib, "tint control point", 0, "position_combine") //samples the lighting from this cpoint's position (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Color_Random)
			end
		end,
		["cull relative to model"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, nil, { //TODO: should this be a position_combine? can't actually find any fx that use this, even in portal2/asw/l4d2
			["ignore_outputs"] = true, //this cpoint sets an associated model, not a position, so outputs don't override it
		}) end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Cull_relative_to_model)
		["move particles between 2 control points"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "end control point", 1, nil, { //yes, it only defines an endpoint (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Move_Particles_Between_2_Control_Points); seems to work based on each particle's initial position (https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_initializers.cpp#L3787)
			["sets_particle_pos"] = true,
			//the minimum distance between cpoints needed to render fx using this operator actually scales with FRAMERATE, ridiculous
			//TODO: not much more we can do about this since actually spawning the cpoints is serverside, argh. i guess this could use a convar? a serverside convar for how much fps they expect clients to have? nonsense
			["tracer_min_distance"] = (math.max((attrib["maximum speed"] or 1), (attrib["minimum speed"] or 1))/58) + 1 + (attrib["start offset"] or 0) - (attrib["end offset"] or 0)
		}) end, 
		["normal align to cp"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine") end, //controls angle of Render Models fx; this is an angle control, so combine it
		["normal modify offset random"] = function(processed, attrib)
			if attrib["offset in local space 0/1"] then //cpoint is only used if this is true https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_initializers.cpp#L7267
				cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine") //controls angle of Render Models fx; this is an angle control, so combine it
			end
		end,
		["position along epitrochoid"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control point number", 0, nil, {["sets_particle_pos"] = true})
			if (attrib["scale from conrol point (radius 1/radius 2/offset)"] or -1) > -1 then //sic (conrol point)
				local function DoEpitrochoidAxis(axis, axisv, default, min)
					if (attrib[axisv] or default) != 0 then
						cpoint_from_attrib_value(processed, attrib, "scale from conrol point (radius 1/radius 2/offset)", -1, "axis", {
							["axis"] = axis,
							["label"] = "Epitrochoid " .. axisv .. " multiplier",
							["inMin"] = min,
							["outMin"] = min,
							//no max
							["default"] = 1,
						})
					end
				end
				DoEpitrochoidAxis(0, "radius 1", 40)
				DoEpitrochoidAxis(1, "radius 2", 24)
				DoEpitrochoidAxis(2, "point offset", 4, 0) //no point in negatives for this one
			end
		end,
		["position along path random"] = function(processed, attrib)
			if attrib["randomly select sequential CP pairs between start and end points"] then
				//uses all cpoints from start to end
				local startp = attrib["start control point number"] or 0
				local endp = attrib["end control point number"] or 0
				local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
				for i = startp, endp do
					PartCtrl_CPoint_AddToProcessed(processed, i, name, nil, {["sets_particle_pos"] = true}, attrib)
				end
			else
				//uses start and end cpoint only
				cpoint_from_attrib_value(processed, attrib, "start control point number", 0, nil, {["sets_particle_pos"] = true})
				cpoint_from_attrib_value(processed, attrib, "end control point number", 0, nil, {["sets_particle_pos"] = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			end
		end,
		["position along path sequential"] = function(processed, attrib)
			if attrib["Use sequential CP pairs between start and end point"] then
				//uses all cpoints from start to end
				local startp = attrib["start control point number"] or 0
				local endp = attrib["end control point number"] or 0
				local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
				for i = startp, endp-startp do //note: if the starting cpoint is non-0, it behaves oddly and deducts that many cpoints from the other end, see portal2 particles/debug.pcf debug_sc_square; this is almost certainly a bug, but a valve effect was designed with it in mind, so we're going with it
					PartCtrl_CPoint_AddToProcessed(processed, i, name, nil, {
						["sets_particle_pos"] = true, 
						["pathseqcheck_min_particles"] = ((attrib["particles to map from start to end"] or 100) / (endp - startp)) * (i - startp - 1)
					}, attrib)
				end
				processed["pathseqcheck"] = true
			else
				//uses start and end cpoint only
				cpoint_from_attrib_value(processed, attrib, "start control point number", 0, nil, {["sets_particle_pos"] = true})
				cpoint_from_attrib_value(processed, attrib, "end control point number", 0, nil, {["sets_particle_pos"] = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			end
		end,
		["position along ring"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "control point number", 0, nil, {["sets_particle_pos"] = true})
			//"Override CP (X/Y/Z *= Radius/Thickness/Speed)" and "Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)" control those things with the values of the cpoint
			//These are all MULTIPLIERS so an axis doesn't do anything if the value is 0, ignore those
			//Unlike remap control point to vector, pitch/yaw/roll are in degrees, not radians
			local function DoRingAxis(cpoint, axis, axisv, min)
				if (attrib[cpoint] or -1) > -1 then
					local doaxis = false
					if axisv == "speed" then //this one uses two values so it has special handling 
						if (attrib["min initial speed"] or 0) != 0 
						or (attrib["max initial speed"] or 0) != 0 then
							doaxis = true
						end
					elseif (attrib[axisv] or 0) != 0 then //yes, they all default to 0
						doaxis = true
					end
					if doaxis then
						if axisv == "initial radius" then axisv = "radius" end //nicer name for slider label
						cpoint_from_attrib_value(processed, attrib, cpoint, -1, "axis", {
							["axis"] = axis,
							["label"] = "Ring " .. axisv .. " multiplier",
							["inMin"] = min,
							["outMin"] = min,
							//no max
							["default"] = 1,
						})
					end
				end
			end
			DoRingAxis("Override CP (X/Y/Z *= Radius/Thickness/Speed)", 0, "initial radius", 0) //no point in negatives for these ones
			DoRingAxis("Override CP (X/Y/Z *= Radius/Thickness/Speed)", 1, "thickness", 0)
			DoRingAxis("Override CP (X/Y/Z *= Radius/Thickness/Speed)", 2, "speed", 0)
			DoRingAxis("Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)", 0, "pitch")
			DoRingAxis("Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)", 1, "yaw")
			DoRingAxis("Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)", 2, "roll")
		end,
		["position from chaotic attractor"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "Relative Control point number", 0, nil, {["sets_particle_pos"] = true})
		end,
		["position from parent cache"] = function(processed, attrib)
			//this operator's presence overrides others that would set the particle pos (i.e. "position within sphere random") and actively makes
			//the effect unusable on its own - see l4d2's particles/firework_crate_fx.pcf firework_crate_ground_sparks_01.
			//this shouldn't even be possible, gmod's pet doesn't let you add this operator and another position one at the same time.
			processed["sets_particle_pos_forcedisable"] = true
		end,
		["position from parent particles"] = function(processed, attrib)
			//don't cull parent fx if they don't have a valid renderer, but one of their children has this attribute (i.e. parent alien_ufo_explode_trailing_bits_alt, child alien_ufo_explode_alt_trail_smoke)
			processed["parent_force_has_renderer"] = true
			//processed["sets_particle_pos_if_child"] = true
		end,
		["position in cp hierarchy"] = function(processed, attrib)
			//this one is a bit strange. it defines a cpoint for every id between the start and end, and then moves the particle spawn point between them all.
			//the weird pet behavior where it adds controls for every cpoint between start and end seems to be designed for this initializer.
			local startp = attrib["start control point number"] or 0
			local endp = attrib["end control point number"] or 1
			if attrib["use highest supplied end point"] then //with this arg set, the particle system uses as many cpoints as you give it. any amount works.
				//endp = 63 //this is what pet does, and it's functional, but this is stupid, don't do this. no one needs 64 whole cpoints to move around.
				endp = math.min(startp + 1, 63) //TODO: give players a way to manually enable as many cpoints as they want, without dumping 64 on them by default.
			end
			local name = attrib._categoryName .. " " .. attrib.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
			for i = startp, endp do
				PartCtrl_CPoint_AddToProcessed(processed, i, name, nil, {["sets_particle_pos"] = true}, attrib)
			end
		end,
		["position modify offset random"] = function(processed, attrib)
			//code only uses this cpoint if offset in local space is enabled; (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L776)
			//this cpoint's ANGLES are used to rotate the offset mins/maxs, its position is not used, so we should either use a position control or a manual angle input maybe
			if attrib["offset in local space 0/1"] then
				cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine")
			end
		end,
		["position modify warp random"] = function(processed, attrib)
			//this can potentially be used to make the position stretch and skew with the movement of the cpoint, but only if the values are set up a specific way. (test_PositionModifyWarpRandom_2)
			//otherwise, in practice, making a separate cpoint for this doesn't do anything except move the center of the effect around, which is extraneous, so use position_combine.
			local min = attrib["warp min"] or Vector(1,1,1)
			local max = attrib["warp max"] or Vector(1,1,1)
			local time = attrib["warp transition time (treats min/max as start/end sizes)"] or 0
			if time == 0 and min != max then
				cpoint_from_attrib_value(processed, attrib, "control point number", 0)
			else
				cpoint_from_attrib_value(processed, attrib, "control point number", 0, "position_combine")
			end
		end,
		["position on model random"] = function(processed, attrib) 
			cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, nil, {
				["ignore_outputs"] = true, //this cpoint sets an associated model, not a position, so outputs don't override it
				["on_model"] = true,
				["sets_particle_pos"] = true,
			})
			//if (attrib["desired hitbox"] or -1) > -1 then
				//TODO: should there be different info text handling for this? it doesn't apply to the *entire* model, 
				//but rather to a *specific part* of the model, though we don't have a way of knowing what that part is
			//end
		end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_position#Position_on_Model_Random)
		["position within box random"] = function(processed, attrib)
			if attrib["use local space"] then 
				 //if this var is set, then the cpoint controls the angle of the box, but not the position. this feels like a bug, but alright.
				cpoint_from_attrib_value(processed, attrib, "control point number", 0, "position_combine")
			else
				cpoint_from_attrib_value(processed, attrib, "control point number", 0, nil, {["overridable_by_constraint"] = true, ["sets_particle_pos"] = true})
			end
		end,
		["position within sphere random"] = function(processed, attrib)
			if !attrib["randomly distribute to highest supplied Control Point"] then
				cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, nil, {["overridable_by_constraint"] = true, ["sets_particle_pos"] = true})
			else
				local name = attrib._categoryName .. " " .. attrib.functionName .. ": randomly distribute to highest supplied Control Point"
				PartCtrl_CPoint_AddToProcessed(processed, -1, name, "position_combine", {["sets_particle_pos"] = true, ["force_allow_-1"] = true}, attrib)
				//TODO: ehh, this makes it combine with the control of the first available position control; 
				//works on all fx i could find, but could potentially result in bad cpoints on more complex fx 
			end
			if (attrib["scale cp (distance/speed/local speed)"] or -1) > -1 then
				local function DoSphereAxis(axis, label, axisvs, min)
					local doaxis = false
					for k, v in pairs (axisvs) do
						if (attrib[k] or v) != v then
							doaxis = true
							break
						end
					end
					if doaxis then
						cpoint_from_attrib_value(processed, attrib, "scale cp (distance/speed/local speed)", -1, "axis", {
							["axis"] = axis,
							["label"] = "Sphere " .. label .. " multiplier",
							["inMin"] = min,
							["outMin"] = min,
							//no max
							["default"] = 1,
						})
					end
				end
				DoSphereAxis(0, "distance", {["distance_min"] = 0, ["distance_max"] = 0}, 0) //no point in negative scale for this one
				DoSphereAxis(1, "speed", {["speed_min"] = 0, ["speed_max"] = 0})
				DoSphereAxis(2, "local speed", {["speed_in_local_coordinate_system_min"] = Vector(), ["speed_in_local_coordinate_system_max"] = Vector()})
			end
		end,
		["remap control point to scalar"] = function(processed, attrib)
			//like the operator of the same name
			//controls a whole bunch of stuff (lifetime, radius, alpha, etc.) with the value of a single axis of the cpoint, definitely not a position control
			local axis = attrib["input field 0-2 X/Y/Z"] or 0
			if axis > -1 then
				local tab = DoScalarIO(attrib)
				cpoint_from_attrib_value(processed, attrib, "input control point number", 0, "axis", {
					["axis"] = axis,
					["label"] = tab.label,
					["inMin"] = tab.inMin,
					["inMax"] = tab.inMax,
					["outMin"] = tab.outMin,
					["outMax"] = tab.outMax,
					["default"] = tab.default,
					["decimals"] = tab.decimals,
				})
			end
		end,
		["remap control point to vector"] = function(processed, attrib)
			//same as operator of the same name; actually, orangebox only has the initializer version of this, the operator is new from pcf v5
			//Similar to above, use all 3 axes of the cpoint to set Position, Roll, or Color
			local tab = DoVectorIO(attrib)
			cpoint_from_attrib_value(processed, attrib, "input control point number", 0, "vector", {
				["label"] = tab.label,
				["inMin"] = tab.inMin,
				["inMax"] = tab.inMax,
				["outMin"] = tab.outMin,
				["outMax"] = tab.outMax,
				["default"] = tab.default,
				["colorpicker"] = tab.colorpicker,
			})
			cpoint_from_attrib_value(processed, attrib, "local space CP", -1, "position_combine") //uses the cpoint's angles to rotate the output in some odd way, can be used to make a position sort-of-rotate with the cpoint, or make colors change as it spins
		end,
		["remap cp orientation to rotation"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control point", 0, "position_combine") end, //uses the cpoint's angles to set the pitch/yaw/roll of particles; this is an angle control, so position_combine it
		["remap initial direction to cp to vector"] = function(processed, attrib)
			//like "remap direction to cp to vector" but an initializer instead of operator.
			//can't find any fx using this in portal2/asw/l4d2, and can't get it to do anything useful in a custom effect,
			//so just position_combine it like the operator version.
			cpoint_from_attrib_value(processed, attrib, "control point", 0, "position_combine")
		end,
		["remap initial distance to control point to scalar"] = function(processed, attrib)
			//like "remap distance to control point to scalar", but an initializer instead of an operator. 
			//uses the distance between a single cpoint's position and each individual particle itself
			cpoint_from_attrib_value(processed, attrib, "control point", 0, nil, {["distance_scalar"] = DoScalarIO(attrib, true, true)})
		end,
		["remap noise to scalar"] = function(processed, attrib)
			//for particles/blood_impact.pcf blood_impact_synth_01_short: ignore the initializer "alpha random" zero alpha check if the zero alpha is being
			//overwritten by the scalar. TODO: there's almost certainly a lot of other scalar operators that could potentially do the same thing, but we'll
			//just add those if we run into them. there's really no good reason for fx to be set up this way, it just makes alpha random do nothing.
			if (attrib["output field"] or PARTCTRL_PARTICLE_ATTRIBUTE_RADIUS) == PARTCTRL_PARTICLE_ATTRIBUTE_ALPHA then
				processed["ignore_zero_alpha"] = true
			end
		end,
		["remap scalar to vector"] = function(processed, attrib)
			if (attrib["output field"] or 0) == PARTCTRL_PARTICLE_ATTRIBUTE_XYZ then //cpoint is only used by position vector (0) to make the position relative to that cpoint (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3155)
				cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, nil, {["sets_particle_pos"] = true}) //yes, this sets particle pos, see unusual_poseidon_light_ fx
			end
		end,
		["remap speed to scalar"] = function(processed, attrib)
			if !attrib["per particle"] then
				//uses the speed of the cpoint to set a scalar value, just position_combine it
				cpoint_from_attrib_value(processed, attrib, "control point number (ignored if per particle)", 0, "position_combine")
			end
		end,
		["sequence from control point"] = function(processed, attrib)
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_initializers.cpp#L3172
			//this is incredibly specific and needs its own special handling with textentries.

			//every digit of the number supplied to each axis is turned into a sprite, with each digit potentially corresponding to 
			//a unique sprite, and each axis having its own set of sprites.

			//in the only working effect with this operator, particles/infested_damage.pcf damage_numbers_digits from alien swarm, 
			//axis 0 shows a minus for every 0 and a plus for every 1 or higher; axis 1 shows the corresponding number for each digit; 
			//and axis 2 shows an exclamation point for every digit. this means axis 1 just displays whichever number you give it, 
			//while the other two are less intuitive.

			local max = Vector(16777216, 16777216, 16777216) //largest integer value we can network as a float until we start running into precision issues
			local min = Vector(0,0,0)
			cpoint_from_attrib_value(processed, attrib, "control point", 1, "vector", {
				["label"] = "Sprites",
				["inMin"] = min,
				["inMax"] = max,
				["outMin"] = min,
				["outMax"] = max,
				["default"] = Vector(0,1,0),
				["decimals"] = 0,
				//info text can't be too specific, since custom fx could potentially use these for any conceivable sprites, and we would have no way of knowing about it
				["textentry"] = {["info"] = "Enter numbers into the boxes to set the effect's sprites. Each number can correspond to a different sprite, and each axis has its own set of sprites."},
			})
		end,
		["set hitbox position on model"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0) end, //presumably uses the model that the cpoint is attached to, so use position; TODO: these two are csgo(?) ports and i can't get them to do anything, don't know if they even function in gmod
		["set hitbox to closest hitbox"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control_point_number", 0) end, //^
		["velocity inherit from control point"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "control point number", 0, "position_combine") end,
		["velocity noise"] = function(processed, attrib)
			if attrib["Apply Velocity in Local Space (0/1)"] then //cpoint is only used if this is enabled (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L1243)
				cpoint_from_attrib_value(processed, attrib, "Control Point Number", 0, "position_combine")
			end
		end,
		["velocity random"] = function(processed, attrib)
			local lmin = attrib["speed_in_local_coordinate_system_min"] or Vector()
			local lmax = attrib["speed_in_local_coordinate_system_max"] or Vector()
			if lmin != vector_origin or lmax != vector_origin then //code uses this cpoint if bHasLocalSpeed (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L892), which is determined by this same check (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L855)
				//if !(lmin.x == lmin.y and lmin.x == lmin.z and lmin.x == -lmax.x and lmin.y == -lmax.y and lmin.z == -lmax.z) then
					cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine")
				//end
			end
		end,
		["velocity repulse from world"] = function(processed, attrib)
			if !attrib["Per Particle World Collision Tests"] then //according to code, neither the cpoint nor broadcast-to-children are used with per-particle collision on (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3421)
				if !attrib["Inherit from Parent"] then
					cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "position_combine") //this cpoint is used to detect nearby world geometry to apply countervelocity away from; no reason this needs to use its own separate grip point, so position_combine it
					local i = attrib["control points to broadcast to children (n + 1)"] or -1 //this also isn't used if inheriting
					if i != -1 then
						local groupid = attrib["Child Group ID to affect"] or 0
						local name = attrib._categoryName .. " " .. attrib.functionName .. ": control points to broadcast to children (n + 1)"
						PartCtrl_CPoint_AddToProcessed(processed, i, name, "output_children", {["groupid"] = groupid}, attrib)
						PartCtrl_CPoint_AddToProcessed(processed, i + 1, name, "output_children", {["groupid"] = groupid}, attrib) //this sets axis 0 to a force value, and the other two to 0 (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3586)
					end
				else
					//let players manually set the values if they spawned a child effect on its own, or for some hypothetical use case where it's intended to be supplied by code or something
					//this is silly, who's going to use this?
					cpoint_from_attrib_value(processed, attrib, "control_point_number", 0, "vector", {
						["label"] = "Velocity Direction",
						["inMin"] = Vector(-1,-1,-1),
						["inMax"] = Vector(1,1,1),
						["outMin"] = Vector(-1,-1,-1),
						["outMax"] = Vector(1,1,1),
						["default"] = Vector(1,0,0),
						["relative_to_cpoint_angle"] = -1 //-1 value tells the particle entity to use the angle of the first available position control
					})
					local cpoint = attrib["control_point_number"] or 0
					local name = attrib._categoryName .. " " .. attrib.functionName .. ": control_point_number (+ 1 for Inherit from parent)"
					PartCtrl_CPoint_AddToProcessed(processed, cpoint + 1, name, "axis", {
						["axis"] = 0,
						["label"] = "Velocity Scale",
						["inMin"] = 0,
						["inMax"] = 1,
						["outMin"] = 0, //I'd like the slider to use maximum/minimum velocity instead so it looks nicer,
						["outMax"] = 1, //but unfortunately those can be different for each axis, which doesn't work here
						["default"] = 1,
					}, attrib)
					//according to code, broadcast to children doesn't run if inheriting
				end
			end
		end,
		["velocity set from control point"] = function(processed, attrib)
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_initializers.cpp#L4160-L4255
			//"control point number"'s position sets the velocity value, local to either the map or to "comparison control point number"
			//"local space control point number"'s ANGLE rotates the velocity value; its position does not matter
			//"direction only" makes the outputted velocity a normalized vector (which is still multiplied by another param)
			cpoint_from_attrib_value(processed, attrib, "comparison control point number", -1, "position_combine")
			cpoint_from_attrib_value(processed, attrib, "local space control point number", -1, "position_combine")
			local relative_to_cpoint = attrib["comparison control point number"] or -1
			if !(relative_to_cpoint > -1) then relative_to_cpoint = nil end
			local outMax = 1024 //arbitrary
			local inMax = outMax / (attrib["velocity scale"] or 1)
			local default = 100 / (attrib["velocity scale"] or 1)
			local label = "Velocity"
			if attrib["direction only"] then
				inMax = 1
				outMax = 1
				default = 1
				label = "Velocity Direction"
			end
			local relative_to_cpoint_angle = attrib["local space control point number"] or -1
			if !(relative_to_cpoint_angle > -1) then
				relative_to_cpoint_angle = -1 //-1 value tells the particle entity to use the angle of the first available position control
			else
				relative_to_cpoint_angle = nil
			end
			cpoint_from_attrib_value(processed, attrib, "control point number", 0, "vector", {
				["label"] = label,
				["inMin"] = Vector(-inMax,-inMax,-inMax),
				["inMax"] = Vector(inMax,inMax,inMax),
				["outMin"] = Vector(-outMax,-outMax,-outMax),
				["outMax"] = Vector(outMax,outMax,outMax),
				["default"] = Vector(default,0,0),
				["relative_to_cpoint"] = relative_to_cpoint,
				["relative_to_cpoint_angle"] = relative_to_cpoint_angle
			})
		end,
	},
	["emitters"] = {
		["emit noise"] = function(processed, attrib)
			if (attrib["emission minimum"] or 0) > 0 or (attrib["emission maximum"] or 100) > 0 then
				processed["has_emitter"] = true
			end
			processed["pathseqcheck_disable"] = true
		end,
		["emit to maintain count"] = function(processed, attrib)
			if (attrib["count to maintain"] or 100) > 0 then
				processed["has_emitter"] = true
			end
			local axis = attrib["maintain count scale control point field"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "maintain count scale control point", -1, "axis", {
					["axis"] = axis,
					["label"] = "Maintain Count Scale",
					["inMin"] = 0,
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
			processed["pathseqcheck_disable"] = true
		end,
		["emit_continuously"] = function(processed, attrib)
			if (attrib["emission_rate"] or 100) > 0 then
				processed["has_emitter"] = true
			end
			local axis = attrib["emission count scale control point field"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "emission count scale control point", -1, "axis", {
					["axis"] = axis,
					["label"] = "Emission Count Scale",
					["inMin"] = 0,
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
			processed["pathseqcheck_disable"] = true
		end,
		//"emit noise" and "emit_continuously" have "scale emission to used control points", which wiki claims is a cpoint id, but it's actually a float that's multiplied by the number of cpoints the effect has, we don't care about this (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_emitters.cpp#L449)
		["emit_instantaneously"] = function(processed, attrib)
			if (attrib["num_to_emit_minimum"] or -1) > 0 or (attrib["num_to_emit"] or 100) > 0 then
				processed["has_emitter"] = true
				processed["pathseqcheck_particles"] = (attrib["num_to_emit"] or 100) //TODO: do we need to account for num_to_emit_minimum here?
			end
			local axis = attrib["emission count scale control point field"] or 0
			if axis > -1 then
				cpoint_from_attrib_value(processed, attrib, "emission count scale control point", -1, "axis", {
					["axis"] = axis,
					["label"] = "Emission Count Scale",
					["inMin"] = 0,
					["outMin"] = 0,
					//no max
					["default"] = 1,
				})
			end
		end,
	},
	["forces"] = { //ForceGenerator
		["force based on distance from plane"] = function(processed, attrib) cpoint_from_attrib_value(processed, attrib, "Control point number", 0) end, //don't know if the extra overrides on "pull toward control point" are necessary here, i don't think any existing fx need them
		["pull towards control point"] = function(processed, attrib)
			local type = nil
			if math.abs(attrib["amount of force"] or 0) < 10 then //can be negative to push particles away
				//a lot of effects have this attrib with miniscule force values, for whatever reason. they don't visibly appear to do anything, maybe it's part of some hacky workaround
				//that particle developers use, i don't know. either way, don't let them create their own position control in these cases, because they aren't useful.
				type = "position_combine" 
			end
			cpoint_from_attrib_value(processed, attrib, "control point number", 0, type, {["overridable_by_constraint"] = true, ["overridable_by_drag"] = true, ["dont_offset_distance_scalar"] = true})
		end
	},
	["constraints"] = {
		//"collision via traces" always sets cpoint 0 in pet, but this doesn't seem necessary, it functions just fine without it in a test effect using only cpoint 1, and even if we add another cpoint for 0 it doesn't actually seem to do anything; can't find any code actually using a cpoint either (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L630-L1098)
		["constrain distance to control point"] = function(processed, attrib)
			if !attrib["global center point"] then //according to code, cpoint is only used if global center point is false (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L87)
				cpoint_from_attrib_value(processed, attrib, "control point number", 0, nil, {["sets_particle_pos"] = true}) //pet doesn't add control for this
				if (attrib["maximum distance"] or 100) < 1 then
					processed["constraint_does_override"] = true //global value on the effect, not cpoint-specific
				end
			end
		end,
		["constrain distance to path between two control points"] = function(processed, attrib)
			cpoint_from_attrib_value(processed, attrib, "start control point number", 0, nil, {["sets_particle_pos"] = true})
			cpoint_from_attrib_value(processed, attrib, "end control point number", 0, nil, {["sets_particle_pos"] = true})
			//if there's no way for other cpoint attribs (like the ones that initialize in a box/sphere) to influence the particles because this constraint forces them onto a very specific path, then don't make position controls for those cpoints
			if (attrib["maximum distance"] or 100) < 1 then
				processed["constraint_does_override"] = true //global value on the effect, not cpoint-specific
			end
		end,
		//"constrain particles to a box" is in worldspace only?? why? what is this for?
		["prevent passing through a plane"] = function(processed, attrib)
			if !attrib["global origin"] or !attrib["global normal"] then
				local norm = attrib["plane normal"] or Vector(0,0,1)
				local x = norm.x //x and y values are swapped, and y is negative. why does this normal and *only* this normal use a totally different coordinate system?
				norm.x = norm.y
				norm.y = -x
				cpoint_from_attrib_value(processed, attrib, "control point number", 0, nil, {
					["plane"] = {
						["pos"] = attrib["plane point"] or Vector(0,0,0),
						["normal"] = norm,
						["pos_global"] = attrib["global origin"],
						["normal_global"] = attrib["global normal"],
					}
				})
			end
		end,
		//code says this one always uses cpoint 0 for some trace stuff, but when trying to test it, on every single effect i could find or make with this attribute, it just doesn't seem to work at all? particles pass through brushes, displacements, and static props just fine. (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L473)
		//TODO: test on a map that isn't gm_flatgrass, maybe it's a problem with distance from the world origin or something
		//["prevent passing through static part of world"] = function(processed, attrib) PartCtrl_CPoint_AddToProcessed(processed, 0, attrib._categoryName .. " " .. attrib.functionName .. ": always uses cpoint 0", nil, nil, attrib) end,
	}
}
local PartCtrl_BadMaterials = PartCtrl_BadMaterials or {}
local blacklist_screenfx = GetConVar("sv_partctrl_blacklist_screenspace")
function PartCtrl_ProcessPCF(filename)
	if hook.Call("PartCtrl_PreProcessPCF", nil, filename) == false then return end //Let hook funcs prevent PCFs from being read by returning false

	//don't print non-critical messages unless we're in developer mode; 
	//always print messages for bugs that player should report
	local dodebug = (GetConVarNumber("developer") >= 1)

	local t = PartCtrl_ReadPCF(filename)
	if !t then
		if dodebug then MsgN("PartCtrl: ", filename, " couldn't be read") end
	else
		PartCtrl_CachedReadPCFs[filename] = t
		PartCtrl_CulledFx[filename] = {}
		local t2 = {}
		for particle, ptab in pairs (t) do
			local processed = {
				["cpoints"] = {},
				["children"] = t[particle].children,
				["parents"] = {},
			}
			//Go through all of the effects's operators (initializers, operators, renderers, etc. are all called "operators" internally, it's confusing) 
			//and use the corresponding functions in processfuncs to "process" them (populate the table above with all their relevant cpoint info). 
			//This is the meat of this function, everything else is just working with this info.
			for k, v in pairs (processfuncs) do
				if ptab[k] then
					for _, attrib in pairs (ptab[k]) do
						if !((attrib["operator start fadein"] or 0) >= 99) and !((attrib["operator end fadein"] or 0) >= 99) then //some fx use a superlong fadein to effectively comment out attribs, ridiculous (particles/advisor_fx.pcf Advisor_Psychic_Attach_01b operator Remap Distance to Control Point to Scalar)
							if !attrib.functionName then
								if dodebug then MsgN("PartCtrl: ", filename, " particle ", particle, " has attribute with no function name") end
							else
								attrib._categoryName = string.TrimRight(k, "s") //for name
								local name = string.lower(attrib.functionName) or ""
								if fixes[name] then name = fixes[name] end

								if v[name] then v[name](processed, attrib) end
								if v["_generic"] then v["_generic"](processed, attrib) end
							end
						end
					end
				end
			end
			//also process a couple things that are stored in the main table and not in operators
			if (ptab["cull_radius"] or 0) > 0 then //(https://github.com/VSES/SourceEngine2007/blob/master/src_main/particles/particles.cpp#L500-L503)
				cpoint_from_attrib_value(processed, ptab, "cull_control_point", 0, "position_combine", {
					["ignore_outputs"] = true, //unlike the other things that ignore outputs, this one actually does set a position, but outputs still don't override it because it runs first i guess
					["dont_inherit"] = true,
				}) //this system only runs if an obscure cheat command cl_particle_retire_cost is enabled (https://developer.valvesoftware.com/wiki/Particle_System_Properties), and also only runs on the frame a particle is spawned (https://github.com/nillerusr/source-engine/blob/master/game/client/particlemgr.cpp#L1707); culls the particle by deleting it (or optionally spawning an alternative particle) if this cpoint is taking up too much of the screen
			end
			cpoint_from_attrib_value(processed, ptab, "control point to disable rendering if it is the camera", -1, "position_combine", {
				["ignore_outputs"] = true, //this cpoint sets an associated model, not a position, so outputs don't override it
				["dont_inherit"] = true,
			}) //makes the particle not render if this cpoint is attached to the ent the camera is viewing from (i.e. the player, or a camera ent they're using)
			if ptab["preventNameBasedLookup"] then
				processed["prevent_name_based_lookup"] = true //makes the particle impossible to spawn on its own, but still usable as a child. not sure what the point of this is.
			end
			if (ptab["initial_particles"] or 0) > 0 then
				processed["has_emitter"] = true
			end
			t2[particle] = processed
			//Also store "screen space effect" here (so we can disable these with a convar)
			if ptab["screen space effect"] then
				processed.screenspace = true
			end
			//"pathseqcheck": cull cpoints added by initializer "position along path sequential" that emitter "emit_instantaneously" doesn't emit enough particles to actually use; 
			//we have to do this here because the initializer's processfunc doesn't have a way to get the emitted particle count, and we want to do all this before inheritance.
			//(for particles/summer2025_unusuals.pcf's utaunt_waterwave_lensflare child fx)
			if processed["pathseqcheck"] and !processed["pathseqcheck_disable"] then
				local count = processed["pathseqcheck_particles"] or -math.huge
				for k, _ in pairs (processed.cpoints) do
					if processed.cpoints[k].position then
						for k2, v2 in pairs (processed.cpoints[k].position) do
							if v2.pathseqcheck_min_particles != nil and v2.pathseqcheck_min_particles > count then
								processed.cpoints[k].position[k2].pathseqcheck_fail = true
							end
						end
					end
				end
			end
			//Don't count fx as having a renderer if their material is invalid (the majority of fx with invalid materials don't render at all; 
			//there's a few exceptions like trails, ropes, and sprites with a different orientation_type, but these aren't worth preserving)
			local mat = "materials/" .. (ptab.material or "vgui/white")
			if !string.EndsWith(mat, ".vmt") then mat = mat .. ".vmt" end
			if PartCtrl_BadMaterials[mat] == nil then PartCtrl_BadMaterials[mat] = file.Exists(mat, "GAME") end
			if !PartCtrl_BadMaterials[mat] then
				t2[particle].has_renderer = false
			//Don't count fx as having a renderer if they have 0 alpha, since they won't render visibly
			elseif processed["has_zero_alpha"] and !processed["ignore_zero_alpha"] then
				processed["has_renderer"] = false
			end
		end
		for particle, _ in pairs (t2) do
			if !t2[particle]["has_renderer"] then
				for _, childtab in pairs (t2[particle].children) do
					if t2[childtab.child] and t2[childtab.child]["parent_force_has_renderer"] then
						t2[particle]["has_renderer"] = true 
						break
					end
				end
			end
		end
		//Inherit cpoint info from children; for spawnicons, particle entities, and control windows to make use of; cpoint modes handle inheritance differently because of how outputs work,
		//so store all of this in a separate table for now, and don't apply it until after we're done setting cpoint modes.
		for particle, _ in pairs (t2) do
			local cpoints = table.Copy(t2[particle].cpoints)
			local function cpoints_from_child_fx(cpoints, particle2, depth)
				depth = depth or 0
				depth = depth + 1
				if depth > 99 then
					MsgN("PartCtrl: ", filename, " ", particle2, " child ", child, " cpoints_from_child_fx has crazy recursion when trying to get child fx, aborting - report this bug!") //don't even know if this is possible, but want to be safe anyway
					return cpoints
				end
				for _, childtab in pairs (t[particle2].children) do
					if t2[childtab.child] then
						local cpoints2 = table.Copy(t2[childtab.child].cpoints)
						//make sure the child has also inherited cpoints from its own children
						if istable(t[childtab.child].children) then
							//if #t[childtab.child].children > 0 then MsgN("children of ", childtab.child, ":") PrintTable(t[childtab.child].children) end
							for _, childtab2 in pairs (t[childtab.child].children) do
								if t2[childtab2.child] then
									local cpoints3 = cpoints_from_child_fx(table.Copy(t2[childtab2.child].cpoints), childtab2.child, depth)
									for i, tab in pairs (cpoints3) do
										cpoints2[i] = cpoints2[i] or {}
										for processedk, processedv in pairs (tab) do
											for k, v in pairs (processedv) do
												//mark attribs as being inherited from a child
												if v["name"] then
													processedv[k]["name"] = "child " .. childtab2.child .. " | " .. processedv[k]["name"]
												end
											end
											if istable(cpoints2[i][processedk]) then
												table.Add(cpoints2[i][processedk], processedv)
											else
												cpoints2[i][processedk] = processedv
											end
										end
									end
								end
							end
						end
						//inherit cpoints from the child
						for i, tab in pairs (cpoints2) do
							cpoints[i] = cpoints[i] or {}
							for processedk, processedv in pairs (tab) do
								for k, v in pairs (processedv) do
									//mark attribs as being inherited from a child
									if v["name"] then
										processedv[k]["name"] = "child " .. childtab.child .. " | " .. processedv[k]["name"]
									end
								end
								if istable(cpoints[i][processedk]) then
									table.Add(cpoints[i][processedk], processedv)
								else
									cpoints[i][processedk] = processedv
								end
							end
						end
					end
				end
				return cpoints
			end
			//store this separately for now, so that other particles grabbing cpoints from their children won't retrieve an already altered table and then alter it again
			t2[particle].cpoints_with_children = cpoints_from_child_fx(cpoints, particle)
		end
		for particle, _ in pairs (t2) do
			//Store the PARTCTRL_CPOINT_MODE_ for each cpoint
			local modes = {}
			local output_children = {}
			local output_axis = {}
			local on_model = nil
			local cpoint_planes = nil
			local distance_scalars = nil
			local dont_offset_distance_scalar = nil
			local tracer_min_distance = nil
			local sets_particle_pos = nil
			local copy_sets_particle_pos = nil
			local remove_if_other_cpoint_is_empty = {}
			local function SetCPointModes(particle2, parent)
				//a little heavy-handed? maybe. might result in some false positives in complex hierarchy trees. haven't found any actual examples of this causing problems,
				//and we'd have to totally rework how we handle hierarchy here to make this more accurate (currently have no way to get the parent of a parent, etc. to check if
				//it's using output_children); output_children[parent] structure probably does limits wrong if a parent has multiple children of the same effect, who then
				//themselves use output_children (they'd all share the same limit), but no existing fx use a complicated structure like that.

				local groupid = t[particle2]["group id"] or 0

				if parent and !output_children[parent] then
					tab = nil
					for k, v in pairs (t2[parent].cpoints) do
						if v["output_children"] then
							for k2, v2 in pairs (v["output_children"]) do
								if v2["groupid"] then
									tab = tab or {}
									tab[k] = tab[k] or {}
									//"limit" value sets the number of children to override the target cpoint on;
									//use the largest possible limit provided, no limit provided means unlimited
									local limit = v2["limit"] or math.huge
									if tab[k][v2["groupid"]] then
										limit = math.max(limit, tab[k][v2["groupid"]])
									end
									tab[k][v2["groupid"]] = limit
								end
							end
						end
					end
					if tab then
						output_children[parent] = tab
					end
				end
				
				for k, v in pairs (t2[particle2].cpoints) do
					//this method doesn't work, argh
					//can't detect that a parent of a parent is doing output_children on a cpoint
					//if output_children[parent] and output_children[parent][k] and output_children[parent][k][groupid] and output_children[parent][k][groupid] > 0 then
					//	//if the target cpoint is being overridden by output_children, decrease the limit by 1 if applicable, and then skip to the next cpoint
					//	output_children[parent][k][groupid] = output_children[parent][k][groupid] - 1
					//else
					//dumber brute-force method, just get the first parent setting output_axis, and hope nothing complicated is using limits
					local doskip = false
					for ent, tab in pairs (output_children) do
						if tab[k] and tab[k][groupid] and tab[k][groupid] > 0 then
							//if the target cpoint is being overridden by output_children, decrease the limit by 1 if applicable, and then skip to the next cpoint
							output_children[ent][k][groupid] = output_children[ent][k][groupid] - 1
							doskip = true
							break
						end
					end
					if !doskip then
						if v["output_axis"] then
							for k2, v2 in pairs (v["output_axis"]) do
								if v2["axis"] then
									output_axis[k] = output_axis[k] or {}
									output_axis[k][v2["axis"]] = true
								end
							end
						end
						local did_output = false
						if v["output"] or (istable(output_axis[k]) and output_axis[k][0] and output_axis[k][1] and output_axis[k][2]) then
							//- outputs override the target cpoint on the effect itself, and on all of its children
							//- outputs on the children of an effect do NOT override the target cpoint on their parent
							//- output_axis follows the same two rules above but only overrides a single axis
							if modes[k] == nil then
								did_output = true
								modes[k] = PARTCTRL_CPOINT_MODE_NONE
							end
						end
						remove_if_other_cpoint_is_empty[k] = {}
						if v["position"] then
							//If we're inheriting the cpoint mode from a child, make sure it's not from an attrib that shouldn't be inherited
							local newtab = {}
							for k2, v2 in pairs (v["position"]) do
								if !(parenttab and v2["dont_inherit"]) --[[and !(t2[particle2].constraint_does_override and v2["overridable_by_constraint"])]] then
									newtab[k2] = v2
								end
							end
							//Make sure to check for the "ignore_outputs" value for attribs that aren't overridden by output
							local ignore_outputs = false
							for k2, v2 in pairs (newtab) do
								if v2["ignore_outputs"] then
									ignore_outputs = true
									break
								end
							end
							for k2, v2 in pairs (newtab) do
								if v2["pathseqcheck_fail"] then continue end
								if (t2[particle2].has_renderer and t2[particle2].has_emitter) or v2["doesnt_need_renderer_or_emitter"] then
									if modes[k] == nil or modes[k] == PARTCTRL_CPOINT_MODE_POSITION_COMBINE or (did_output and ignore_outputs) then
										if t2[particle2].constraint_does_override and v2["overridable_by_constraint"]
										or t2[particle2].drag_does_override and v2["overridable_by_drag"] then
											modes[k] = PARTCTRL_CPOINT_MODE_POSITION_COMBINE
										else
											modes[k] = PARTCTRL_CPOINT_MODE_POSITION
										end
										did_output = false //make sure position_combine below doesn't override this
									end
									if modes[k] == PARTCTRL_CPOINT_MODE_POSITION then
										//also make a list of all the cpoints that have "on_model" fx so that we can print extra info about it in spawnicons
										if v2["on_model"] then
											on_model = on_model or {}
											on_model[k] = true
										end
										//also make a list of cpoints that define a cull plane, so we can draw helpers for them
										if v2["plane"] then
											cpoint_planes = cpoint_planes or {}
											cpoint_planes[k] = cpoint_planes[k] or {}
											table.insert(cpoint_planes[k], v2["plane"])
										end
										//also make a list of distance scalars
										if v2["distance_scalar"] then
											distance_scalars = distance_scalars or {}
											distance_scalars[k] = distance_scalars[k] or {}
											table.insert(distance_scalars[k], v2["distance_scalar"])
										end
										//also inherit tracer_min_distance stuff here
										if v2["tracer_min_distance"] and t2[particle2].tracer_min_distance_hasdecay then
											tracer_min_distance = tracer_min_distance or {}
											tracer_min_distance[k] = math.max((tracer_min_distance[k] or 0), v2["tracer_min_distance"])
										end
										//also check for "remove_if_other_cpoint_is_empty"; we only care about this if ALL position controls for this cpoint have this
										local remove = v2["remove_if_other_cpoint_is_empty"]
										if remove != nil and remove_if_other_cpoint_is_empty[k] != nil then
											remove_if_other_cpoint_is_empty[k][remove] = true
										else
											remove_if_other_cpoint_is_empty[k] = nil
										end
									end
								end
								if v2["sets_particle_pos"] and !t2[particle2].sets_particle_pos_forcedisable then
									sets_particle_pos = sets_particle_pos or {}
									sets_particle_pos[k] = true
								end
								if v2["dont_offset_distance_scalar"] then //for operators that don't set particle pos, but still should prevent distance scalar operators on the same cpoint from moving the cpoint
									dont_offset_distance_scalar = dont_offset_distance_scalar or {}
									dont_offset_distance_scalar[k] = true
								end
								if v2["copy_sets_particle_pos"] then
									copy_sets_particle_pos = copy_sets_particle_pos or {}
									copy_sets_particle_pos[k] = copy_sets_particle_pos[k] or {}
									table.Merge(copy_sets_particle_pos[k], v2["copy_sets_particle_pos"]) 
								end
							end
						end
						if v["position_combine"] then
							//If we're inheriting the cpoint mode from a child, make sure it's not from an attrib that shouldn't be inherited
							local newtab = {}
							if parenttab then
								for k2, v2 in pairs (v["position_combine"]) do
									if !v2["dont_inherit"] then
										newtab[k2] = v2
									end
								end
							else
								newtab = v["position_combine"]
							end
							//Make sure to check for the "ignore_outputs" value for attribs that aren't overridden by output
							local ignore_outputs = false
							for k2, v2 in pairs (newtab) do
								if v2["ignore_outputs"] then
									ignore_outputs = true
									break
								end
							end
							for k2, v2 in pairs (newtab) do
								//combining multiple cpoints with movement lock will result in the the movement being applied additively from each one
								//(see speech_mediccall_auto, utaunt_cremation_smoke_black, utaunt_cremation_black_parent);
								//instead, only allow 1 cpoint with movement lock to be combined, while the rest are ignored.
								if t2[particle2].movement_lock and t2[particle2].movement_lock[k] and t2[particle].movement_lock_cpoint == nil then
									t2[particle].movement_lock_cpoint = k
								end
								if ((t2[particle2].has_renderer and t2[particle2].has_emitter) or v2["doesnt_need_renderer_or_emitter"]) 
								and (!t2[particle2].movement_lock or !t2[particle2].movement_lock[k] or t2[particle].movement_lock_cpoint == k) then
									if modes[k] == nil or (did_output and ignore_outputs) then
										modes[k] = PARTCTRL_CPOINT_MODE_POSITION_COMBINE
									end
								end
								if v2["sets_particle_pos"] and !t2[particle2].sets_particle_pos_forcedisable then
									sets_particle_pos = sets_particle_pos or {}
									sets_particle_pos[k] = true
								end
								if v2["dont_offset_distance_scalar"] then //for operators that don't set particle pos, but still should prevent distance scalar operators on the same cpoint from moving the cpoint
									dont_offset_distance_scalar = dont_offset_distance_scalar or {}
									dont_offset_distance_scalar[k] = true
								end
								if v2["copy_sets_particle_pos"] then
									copy_sets_particle_pos = copy_sets_particle_pos or {}
									copy_sets_particle_pos[k] = copy_sets_particle_pos[k] or {}
									table.Merge(copy_sets_particle_pos[k], v2["copy_sets_particle_pos"])
								end
							end
						end
						if v["vector"] then
							if modes[k] == nil and (t2[particle2].has_renderer and t2[particle2].has_emitter) then
								modes[k] = PARTCTRL_CPOINT_MODE_VECTOR
							end
						end
						if v["axis"] then
							local doaxis = false
							if modes[k] == nil then
								for k2, v2 in pairs (v["axis"]) do
									//handle output_axis overriding specific axes
									if !istable(output_axis[k]) or !output_axis[k][v2.axis] then
										doaxis = true
									end
								end
							end
							if doaxis and (t2[particle2].has_renderer and t2[particle2].has_emitter) then
								modes[k] = PARTCTRL_CPOINT_MODE_AXIS
							end
						end
					end
				end
				//MsgN("Current modes:")
				//PrintTable(modes)

				if particle2 != particle then
					//Also inherit screenspace flag from children here
					if t2[particle2].screenspace then
						t2[particle].screenspace_from_child = true
					end
					//Also inherit spawnicon_playerposfix from children here
					if t2[particle2].spawnicon_playerposfix then
						t2[particle].spawnicon_playerposfix = true
					end
					//Also inherit spawnicon_forcedpositions from children here
					if t2[particle2].spawnicon_forcedpositions then
						t2[particle].spawnicon_forcedpositions = t2[particle].spawnicon_forcedpositions or {0,0,0,0,0,0}
						t2[particle].spawnicon_forcedpositions = {
							math.min(t2[particle].spawnicon_forcedpositions[1], t2[particle2].spawnicon_forcedpositions[1]),
							math.min(t2[particle].spawnicon_forcedpositions[2], t2[particle2].spawnicon_forcedpositions[2]),
							math.min(t2[particle].spawnicon_forcedpositions[3], t2[particle2].spawnicon_forcedpositions[3]),
							math.max(t2[particle].spawnicon_forcedpositions[4], t2[particle2].spawnicon_forcedpositions[4]),
							math.max(t2[particle].spawnicon_forcedpositions[5], t2[particle2].spawnicon_forcedpositions[5]),
							math.max(t2[particle].spawnicon_forcedpositions[6], t2[particle2].spawnicon_forcedpositions[6]),
						}
					end
				end
			end
			SetCPointModes(particle)
			//Cpoints that haven't been filled in yet should inherit from children
			local function CPointModesFromChildren(particle2, depth)
				depth = depth or 0
				depth = depth + 1
				if depth > 99 then
					MsgN("PartCtrl: ", filename, " ", particle2, " CPointModesFromChildren has crazy recursion when trying to get child fx, aborting - report this bug!") //don't even know if this is possible, but want to be safe anyway
					return
				end

				if istable(t2[particle2].children) then
					for _, childtab in pairs (t2[particle2].children) do
						if !t2[childtab.child] then
							if dodebug then MsgN("PartCtrl: ", filename, " ", particle2, " CPointModesFromChildren tried to get nonexistent child effect ", child) end
						else
							SetCPointModes(childtab.child, particle2)
							//Now inherit from the child's children, and so on
							//TODO: the order here might not be quite right if we have multiple branching children of children, but I don't know if that actually matters in practice
							CPointModesFromChildren(childtab.child, depth)
						end
					end
				end
			end
			CPointModesFromChildren(particle)

			//Do remove_if_other_cpoint_is_empty thing for operator "set control point positions"; this operator has "parent" cpoints that move 
			//around "child" cpoints, but if those child cpoints don't actually do anything, then the parent cpoints are useless, so remove them.
			for k, v in pairs (remove_if_other_cpoint_is_empty) do
				if istable(v) and table.Count(v) > 0 and modes[k] == PARTCTRL_CPOINT_MODE_POSITION then
					local empty = true
					for k2, _ in pairs (v) do
						if t2[particle].cpoints_with_children[k2] and t2[particle].cpoints_with_children[k2].position then
							empty = false
							break
						end
					end
					if empty then
						//MsgN(particle, ": empty detected: cpoint ", k)
						modes[k] = PARTCTRL_CPOINT_MODE_NONE
					end
				end
			end

			local shouldcull = !t2[particle].has_renderer or !t2[particle].has_emitter
			local pos_control_count = 0
			local needfallback = -1
			for k, v in pairs (modes) do
				if !shouldcull and !needfallback and pos_control_count > 1 then break end
				if shouldcull and v != PARTCTRL_CPOINT_MODE_NONE then
					//Clear out empty effects (no renderer, no emitter, no cpoints even from children)
					shouldcull = false
				end
				if v == PARTCTRL_CPOINT_MODE_POSITION then
					if needfallback then 
						//Create fallback position cpoint for effects that don't have any
						needfallback = nil
					end
					if pos_control_count != nil then
						pos_control_count = pos_control_count + 1
					end
				end
			end
			if shouldcull then
				t2[particle]["renderer_emitter_shouldcull"] = true
			end
			if needfallback then
				if !modes[0] then
					//just use cpoint 0 if it's open
					needfallback = 0
				else
					//If possible, turn the first available position_combine cpoint into a normal position cpoint
					for k, v in SortedPairs (modes) do
						if k != -1 and v == PARTCTRL_CPOINT_MODE_POSITION_COMBINE then
							needfallback = k
							break
						end
					end
				end
				//if neither of those work, then use the nonsense cpoint -1, which is probably fine since it's most likely
				//not going to be able to do anything anyway; it's just there so we have an entity to associate the effect with.

				t2[particle].cpoints_with_children[needfallback] = t2[particle].cpoints_with_children[needfallback] or {}
				t2[particle].cpoints_with_children[needfallback].position = t2[particle].cpoints_with_children[needfallback].position or {}
				table.insert(t2[particle].cpoints_with_children[needfallback].position, {["name"] = "fallback position cpoint created due to no position cpoint"})

				modes[needfallback] = PARTCTRL_CPOINT_MODE_POSITION
			end
			//Finally, store the cpoint modes
			for k, v in pairs (modes) do
				t2[particle].cpoints_with_children[k].mode = v
			end

			//Handle copy_sets_particle_pos - this is used by operators "Set Control Point Positions" and "Set Control Point to Impact Point" to inherit the
			//sets_particle_pos value of the cpoints they're overriding. (i.e. if cpoint 0 controls the position of particles, and then cpoint 1 overrides 
			//the position of cpoint 0, then that means cpoint 1 should be counted as controlling the position of particles) This matters because 
			//sets_particle_pos then filters out cpoints that the player can't control (in our example, cpoint 0, because it's being overwritten).
			//
			//This works in a funky two-stage process to handle an edge case where there are *two* operator "Set Control Point Positions" on one effect, the 
			//first setting other cpoints relative to its own cpoint, and then the second one setting the position of *that* cpoint to *its* own (see cstrike 
			//particles/achievement.pcf: achieved). I say "first" and "second" here, but according to testing, the order of the operators doesn't actually 
			//matter, so we have to handle this in a way that lets the copy succeed even if we handle the cpoints out of order, hence the two-stage process.
			if copy_sets_particle_pos and sets_particle_pos then
				for k, v in pairs (copy_sets_particle_pos) do
					if !sets_particle_pos[k] then
						sets_particle_pos[k] = "copy"
					end
				end
				for k, v in pairs (sets_particle_pos) do
					if v == "copy" then
						local copy_succeeded = nil
						for k2, _ in pairs (copy_sets_particle_pos[k]) do
							if sets_particle_pos[k2] then //make sure it still counts if the other value is a "copy" we haven't gone over yet; not 100% satisfied with this solution but so far it seems to work
								copy_succeeded = true
								break 
							end
						end
						sets_particle_pos[k] = copy_succeeded
					end
				end
			end

			//Filter out cpoints that set particle positions, but are overwritten by an output so the player can't control them 
			//(examples: l4d2 storm_lightning_01_branch_parent_01), which sets child cpoints to the positions of its particles, but its own particles don't have
			//anything to set their position because this effect is meant to be the child of something else; tf2 map particles embargo_shore_center_heli_fg,
			//which sets its cpoints to specific coordinates on the map that cannot be moved by the player)
			//This is used a bit later to filter out fx that are unusable because the player can't move them at all.
			local sets_particle_pos_2 = nil
			if sets_particle_pos then
				for k, v in pairs (sets_particle_pos) do
					if modes[k] == PARTCTRL_CPOINT_MODE_POSITION or modes[k] == PARTCTRL_CPOINT_MODE_POSITION_COMBINE then
						sets_particle_pos_2 = sets_particle_pos_2 or {}
						sets_particle_pos_2[k] = true
					end
				end
			end
			t2[particle]["sets_particle_pos"] = sets_particle_pos_2

			//Do info text for on_model
			if on_model then
				local text = ""
				local docomma = false
				for k, _ in pairs (on_model) do
					if docomma then text = text .. ", " end
					text = text .. k
					docomma = true
				end
				local text2
				if table.Count(on_model) > 1 then
					text2 = "This effect will apply to a whole model if control points %CPOINTS are attached."
				else
					text2 = "This effect will apply to a whole model if control point %CPOINTS is attached."
				end
				PartCtrl_AddInfoText(t2[particle], string.Replace(text2, "%CPOINTS", text))
			end

			if pos_control_count and pos_control_count > 1 then
				//Do cpoint_planes; not necessary if the effect only has 1 position control
				if cpoint_planes then
					//Squish together entries that have the same values
					t2[particle].cpoint_planes = {}
					for k, v in pairs (cpoint_planes) do
						local newplanes = {}
						for k2, v2 in pairs (v) do
							if cpoint_planes[k][k2] != nil then
								local newtab = table.Copy(v2)
								for k3, v3 in pairs (cpoint_planes[k]) do
									if k3 != k2 and v3.pos == v2.pos and v3.pos_global == v2.pos_global and v3.pos_fixed_offset == v2.pos_fixed_offset
									and v3.normal == v2.normal and v3.normal_global == v2.normal_global then
										cpoint_planes[k][k3] = nil
									end
								end
								cpoint_planes[k][k2] = nil
								table.insert(newplanes, newtab)
							end
						end
						t2[particle].cpoint_planes[k] = newplanes
					end
					//Add info text for planes
					local text = ""
					local docomma = false
					for k, _ in pairs (t2[particle].cpoint_planes) do
						if docomma then text = text .. ", " end
						text = text .. k
						docomma = true
					end
					local text2
					if table.Count(t2[particle].cpoint_planes) > 1 then
						text2 = "Control points %CPOINTS control planes that prevent particles from passing through."
					else
						text2 = "Control point %CPOINTS controls a plane that prevents particles from passing through."
					end
					PartCtrl_AddInfoText(t2[particle], string.Replace(text2, "%CPOINTS", text))
				end

				//Do min cpoint distance for tracer fx
				if tracer_min_distance then
					t2[particle].cpoint_distance_overrides = t2[particle].cpoint_distance_overrides or {}
					for k, v in pairs (tracer_min_distance) do
						t2[particle].cpoint_distance_overrides[k] = {
							["min"] = v
						}
					end
				end
				
				//Do min/max cpoint distance for distance scalars
				if distance_scalars and t2[particle].sets_particle_pos then
					t2[particle].distance_scalars = distance_scalars
					t2[particle].cpoint_distance_overrides = t2[particle].cpoint_distance_overrides or {}
					for k, v in pairs (distance_scalars) do
						local is_non_spp = false
						if !t2[particle].sets_particle_pos[k] and (!dont_offset_distance_scalar or !dont_offset_distance_scalar[k]) then
							//This cpoint doesn't control particle placement, so we can get more creative with its positioning.
							//Instead of putting it in a row with the standard cpoints, offset this cpoint a set distance above
							//another one that spawns particles, to make sure this cpoint starts off an ideal distance to
							//demonstrate the scalar, and never starts off at a bad distance that prevents any particles
							//from rendering.
							is_non_spp = true
						else
							//This cpoint also controls particle placement, so it's just a "normal" cpoint in the row that we
							//need to set the min/max distance from its next cpoint.
							if k == 0 then
								//we can't move cpoint 0, so move the next relevant cpoint instead
								local spp_copy = table.Copy(t2[particle].sets_particle_pos)
								spp_copy[0] = nil
								if table.Count(spp_copy) == 0 then --[[MsgN(filename, " ", particle, " failed when doing distance scalars!")]] continue end
								k = table.GetFirstKey(spp_copy)
							end
						end
						t2[particle].cpoint_distance_overrides[k] = t2[particle].cpoint_distance_overrides[k] or {}
						local text = {
							["increase"] = {},
							["decrease"] = {},
						}
						for k2, v2 in pairs (v) do
							if v2.outMax > v2.outMin then
								t2[particle].cpoint_distance_overrides[k].min = math.max(t2[particle].cpoint_distance_overrides[k].min or v2.default, v2.default)
								text.decrease[v2.label] = true
							elseif v2.outMin > v2.outMax then
								t2[particle].cpoint_distance_overrides[k].max = math.min(t2[particle].cpoint_distance_overrides[k].max or v2.default, v2.default)
								text.increase[v2.label] = true
							end
							if is_non_spp then t2[particle].distance_scalars[k][k2].do_helpers = true end
						end
						if is_non_spp then
							t2[particle].cpoint_distance_overrides[k].offset_from_main_row = true
							//Do info text
							local identical = false
							if table.Count(text.increase) == table.Count(text.decrease) then
								identical = true
								for k, _ in pairs (text.increase) do
									if !text.decrease[k] then identical = false break end
								end
							end
							local text_increase = ""
							local docomma = false
							for k, _ in SortedPairs (text.increase) do
								if docomma then text_increase = text_increase .. ", " end
								text_increase = text_increase .. k
								docomma = true
							end
							local text_decrease = ""
							docomma = false
							for k, _ in SortedPairs (text.decrease) do
								if docomma then text_decrease = text_decrease .. ", " end
								text_decrease = text_decrease .. k
								docomma = true
							end
							if identical then
								text = "Control point " .. k .. " increases and decreases " .. text_decrease .. " of particles as they get closer to it."
							elseif table.Count(text.increase) == 0 then
								text = "Control point " .. k .. " decreases " .. text_decrease .. " of particles as they get closer to it."
							elseif table.Count(text.decrease) == 0 then
								text = "Control point " .. k .. " increases " .. text_increase .. " of particles as they get closer to it."
							else
								text = "Control point " .. k .. " increases " .. text_increase .. " and decreases " .. text_decrease .. " of particles as they get closer to it."
							end
							PartCtrl_AddInfoText(t2[particle], text)
						end
					end
				end
			end
		end
		for particle, _ in pairs (t2) do
			//Now that we're done setting cpoint modes, apply cpoint data from children
			t2[particle].cpoints = t2[particle].cpoints_with_children
			t2[particle].cpoints_with_children = nil
			for k, v in pairs (t2[particle].cpoints) do
				if v.mode == nil then
					//Fill in empty mode entries
					t2[particle].cpoints[k].mode = PARTCTRL_CPOINT_MODE_NONE
				end
				if v.vector then
					//Squish together vector entries that have the same values except for the name
					local newvectors = {}
					for k2, v2 in pairs (v.vector) do
						if v.vector[k2] != nil then
							local newtab = table.Copy(v2)
							for k3, v3 in pairs (v.vector) do
								if k3 != k2 and v3.label == v2.label and v3.inMin == v2.inMin and v3.inMax == v2.inMax
								and v3.outMin == v2.outMin and v3.outMax == v2.outMax then
									newtab.name = newtab.name .. ",\n" .. v3.name
									v.vector[k3] = nil
								end
							end
							v.vector[k2] = nil
							table.insert(newvectors, newtab)
						end
					end
					t2[particle].cpoints[k].vector = newvectors
					//set "which" value (which entry in v.vector for the particle entity, edit window, etc. to get values like inMin and label from)
					t2[particle].cpoints[k].which = 0
					for k2, v2 in pairs (newvectors) do
						t2[particle].cpoints[k].which = k2
						break
					end
				end
				if v.output_axis then
					for k2, v2 in pairs (v.output_axis) do
						t2[particle].cpoints[k]["which_" .. v2.axis] = -1 //special value for both vector and axis controls to check for, so they can remove a specific axis being overwritten
					end
				end
				if v.axis then
					//Squish together axis entries that have the same values except for the name
					local newaxes = {}
					for k2, v2 in pairs (v.axis) do
						if v.axis[k2] != nil then
							local newtab = table.Copy(v2)
							for k3, v3 in pairs (v.axis) do
								if k3 != k2 and v3.label == v2.label and v3.inMin == v2.inMin and v3.inMax == v2.inMax
								and v3.outMin == v2.outMin and v3.outMax == v2.outMax and v3.axis == v2.axis then
									newtab.name = newtab.name .. ",\n" .. v3.name
									v.axis[k3] = nil
								end
							end
							v.axis[k2] = nil
							table.insert(newaxes, newtab)
						end
					end
					t2[particle].cpoints[k].axis = newaxes
					//set "which" value for each axis (which entry in v.axis for the particle entity, edit window, etc. to get values like inMin and label from)
					for i = 0, 2 do
						if t2[particle].cpoints[k]["which_" .. i] != -1 then
							t2[particle].cpoints[k]["which_" .. i] = 0
							for k2, v2 in pairs (newaxes) do
								if v2.axis == i then 
									t2[particle].cpoints[k]["which_" .. i] = k2
									break
								end
							end
						end
					end
				end
			end

			//Flag effects for culling - we do this before calling the PostProcessPCF hook, so that the hook can override it
			//Cull empty effects
			if t2[particle].renderer_emitter_shouldcull then
				if t2[particle].has_zero_alpha then
					PartCtrl_AddCullReason(filename, particle, "#PartCtrl_Cull_ZeroAlpha")
				else
					PartCtrl_AddCullReason(filename, particle, "#PartCtrl_Cull_NoRendererOrEmitter")
				end
			end
			//Cull effects that are stuck at the world origin because they don't have any cpoints setting their particle pos
			if !t2[particle].sets_particle_pos then
				PartCtrl_AddCullReason(filename, particle, "#PartCtrl_Cull_NoParticlePos")
			end
			//Also, now that their parents have inherited cpoint data from them, cull effects with preventNameBasedLookup, since we can't spawn them on their own.
			if t2[particle].prevent_name_based_lookup then
				PartCtrl_AddCullReason(filename, particle, "#PartCtrl_Cull_PreventNameBasedLookup")
			end
			
			//Handle screenspace fx
			//TODO: this isn't perfectly 1-to-1 with which screenspace fx actually display fx on the screen (generally, these fx don't render on their 
			//own unless they're also a viewmodel effect, but if they're a child of another effect, then *usually* their parent will render them anyway? 
			//not 100% sure what the criteria is here.) All the fx that still render here but get flagged as "unable to render properly" are still
			//various flavors of broken anyway, so this is what we're going with for now.
			local screenspace = false
			local vm = t[particle]["view model effect"]
			if t2[particle].screenspace_from_child then
				screenspace = true
			elseif t2[particle].screenspace then
				if vm then
					screenspace = true
				else
					PartCtrl_AddCullReason(filename, particle, "#PartCtrl_Cull_ScreenSpace_NotViewModel")
				end
			end
			if screenspace then
				if blacklist_screenfx:GetBool() then
					PartCtrl_AddCullReason(filename, particle, "#PartCtrl_Cull_ScreenSpace_Blacklisted")
				else
					PartCtrl_AddInfoText(t2[particle], "Screenspace effect: draws an overlay directly onto the screen")
				end
			elseif vm then
				//Also add info text for viewmodel effects here, because this isn't inherited and doesn't apply to screenspace fx
				PartCtrl_AddInfoText(t2[particle], "Viewmodel effect: draws in front of everything, and has a distorted position unless attached to a model on a non-0 attachment.")
			end
		end
		//Now that the processed table is finished, let hook funcs modify it arbitrarily (including deciding which fx to cull)
		hook.Call("PartCtrl_PostProcessPCF", nil, filename, t2)
		for particle, _ in pairs (t2) do
			//Cull bad effects from the table.
			//If the player starts up the game in developer mode, effects aren't culled, but instead have a warning in the spawnicon telling the dev why they won't show up to players.
			if PartCtrl_CulledFx[filename][particle] and GetConVarNumber("developer") < 1 then
				t2[particle] = nil
			end
		end
		//Remove culled children and empty entries from child lists, add parents to parent lists
		for particle, _ in pairs (t2) do
			local shouldclean = false
			for k, childtab in pairs (t2[particle].children) do
				if !t2[childtab.child] then 
					t2[particle].children[k] = nil
					shouldclean = true
				else
					table.insert(t2[childtab.child].parents, particle)
				end
			end
			if shouldclean then
				t2[particle].children = table.ClearKeys(t2[particle].children)
			end
		end
		
		if table.Count(t2) == 0 then
			if dodebug then MsgN("PartCtrl: ", filename, " contains no usable effects, ignoring") end
		else
			return t2
		end
	end
end

function PartCtrl_AddCullReason(pcf, effect, str)
	PartCtrl_CulledFx[pcf][effect] = PartCtrl_CulledFx[pcf][effect] or {}
	table.insert(PartCtrl_CulledFx[pcf][effect], str)
end

function PartCtrl_AddInfoText(tab, str)
	tab.info = tab.info or {}
	table.insert(tab.info, str)
end

//Comprehensive output testing: 
--[[
- All "output" and "output_axis":
- operator "set control point to player"
  - with the output and the attrib it overrides on the same effect, overrides everything unless noted
    - doesn't override attribs that use the associated model's bones/hitboxes/etc, because this output doesn't change the associated model, just pos/ang (intitializer "position on model random", operator "cull relative to model", operator "movement lock to bone")
    - doesn't override main table "control point to disable rendering if it is the camera", main table "cull_control_point"
    - (TODO: is this right? test output pileups on their own later, seems inconsistent) operator "remap cp speed to cp"'s output_axis erroneously always sends max output if "set control point to player"/"set control point to particles' center" is defined after it outputting to its input cpoint; "set control point to player"/"set control point positions" still outputs the same values if either a "set control point to player"/"set control point positions" is defined after it, outputting to its input cpoint and trying to move it
  - with the output on parent and the attrib it overrides on child, same as above
    - interactions with other outputs on the same cpoint, do we care about these?
      - operator "movement match particle velocities"'s output on same cpoint gets squashed by parent's output
      - operator "remap cp speed to cp"'s input cpoint, if moved by a parent output, measures the new cp's speed instead as expected
      - operator "set control point positions"'s input cpoint, if moved by a parent output, uses the new position instead as expected
      - operators "remap cp speed to cp"/"set control point positions"/"set control point to particles' center"/"set control point to player"'s output to a cpoint on child is NOT squashed by parent's output to the same cpoint (!) instead the child uses its own output for that cpoint, while the parent uses *its* own output for *its* cpoint, resulting in multiple cpoints with the same id in different places
  - with the output on child and the attrib it overrides on parent, doesn't override anything
    - also, output operators on the parent outputting to the same cpoint do not override the child's output either
- operator "remap cp speed to cp"
  - same as "set control point positions", but for just one axis
- operator "set control point positions", operator "set control point to particles' center"
  - same as "set control point to player", except:
    - doesn't override ang for attribs that use ang, because this output doesn't change ang, just pos (renderer "render_animated_sprites"s "orientation control point", constraint "prevent passing through a plane" if !attrib["global normal"], initializer "position along epitrochoid" "control point number" ang, initializer "position along ring" "control point number" ang, initializer "position from chaotic attractor" "Relative Control point number" ang, initializer "Position Within Sphere Random" "control_point_number" ang if "bias in local system" is in use, initializer "Position Modify Offset Random" "control_point_number" ang if "offset in local space 0/1" is in use) (TODO: check initializers after "position modify offset random", and all non-initializers)
      - any path stuff with attrib "bulge control 0=random 1=orientation of start pnt 2=orientation of end point" set to an overwritten cpoint (TODO check stuff before initializer; initializer "Position Along Path Random", initializer "Position Along Path Sequential", initializer "Position In CP Hierarchy"; TODO: check initializers after "position modify offset random")
      - cstrike_achieved and that one beany effect have cpoints being overwritten by "set control point positions" outputs that can still be rotated separately to move the effect around, but this doesn't seem to be a deliberate design feature, since this output is used to composite child fx together all the time. the right course of action here seems to be to omit the overwritten cpoints anyway, instead of keeping more grip points around that only set the angle.
- operator "movement match particle velocities"
  - same as "set control point to player", except:
    - with the output and the attrib it overrides on the same effect
      - if a position control exists for the output cpoint, overridable attribs will use the cpoint's pos/ang instead of it being overridden by the output pos/ang, except for the ones listed below. (if a position control doesn't exist, the value will be overridden by the output normally.)
	- renderer generic "Visibility Proxy Input Control Point Number" always overrides properly
	- operators will be overridden properly IF they're defined AFTER "movement match particle velocities" in the operators list
	- some initializers ("position along ring", "position in cp hierarchy", "position within box random", "position within sphere random", "position modify warp random", "remap scalar to vector" position, "velocity inherit from control point", "velocity repulse from world") appear to alternate every frame or so between the position control's value, and a point halfway between the position control and the output
	- if no particles exist, child cpoint's value reverts back to the position control value instead of the output value, otherwise overrides properly
    - with the output on parent and the attrib it overrides on child, all attribs have their pos overridden properly, but ang uses the position control's ang instead if available (except initializer "remap scalar to vector")
- All "output_children":
- operator "set child control points from particle positions"
    TODO
- initializer "velocity repulse from world"
    TODO
- Misc. notes:
- can't test initializer "position within sphere random" value "create in model" because it always crashes upon spawning any particles (blood_impact.pcf/blood_antlionguard_injured_light is the only default effect with this set, and it doesn't crash because it doesn't actually emit any particles); can't test initializers "set hitbox position on model" or "set hitbox to closest hitbox" because i can't get them to work at all, these are csgo? ports anyway)
- main table "control point to disable rendering if it is the camera" or "cull_control_point" don't work on children at all
]]


//Normally, we only need to run this function once per session, when the entity code in ent_partctrl calls it. This ensures that it runs AFTER all the autorun code has had 
//a chance to run first and populate the blacklist. However, if the player mounts/unmounts something and calls the GameContentChanged hook, we want to run this again. This 
//function is really expensive (~16 sec freezing with a few games and particle addons installed), so we don't want to run it any more than we have to.
//
//This sounds simple, but here's what makes it more complicated: when a player starts a singleplayer game for the first time in a session, the GameContentChanged hook also
//runs on startup. On subsequent games that session, the hook WON'T run on startup. On the server, the GameContentChanged hook runs just AFTER the entity code, but on the 
//client, the hook runs just BEFORE the entity code. What we need to do is somehow ensure the function only runs once on startup, without knowing whether GameContentChanged
//will run on startup or not, and without knowing if GameContentChanged or the entity code will run first, AND do all of this without clobbering unrelated instances of 
//GameContentChanged being run AFTER startup.
//
//Our solution to this is to define a brief "startup" period, during which the function is only allowed to run once, and then after which it can run all it likes. This is 
//controlled by a timer.Simple in the entity code, which sets PartCtrl_ReadAndProcessPCFs_StartupIsOver to true after all the stuff mentioned in the last paragraph has had
//time to happen already.
//
//TODO: make sure this works in multiplayer

PartCtrl_ReadAndProcessPCFs_StartupHasRun = PartCtrl_ReadAndProcessPCFs_StartupHasRun
PartCtrl_ReadAndProcessPCFs_StartupIsOver = PartCtrl_ReadAndProcessPCFs_StartupIsOver

local badendings = {
	["_dx80.pcf"] = true,
	["_dx90_slow.pcf"] = true,
	["_high.pcf"] = true,
}
local function HasBadEnding(filename, path)
	if !string.EndsWith(filename, ".pcf") then return true end
	//if a file has one of these suffixes, then it's probably a copy of another pcf, loaded based on dxlevel;
	//make sure this is the case by checking if a file without the suffix exists, to avoid false positives.
	for ending, _ in pairs (badendings) do
		if string.EndsWith(filename, ending) and file.Exists(string.Replace(filename, ending, ".pcf"), path) then
			return true
		end
	end
end

function PartCtrl_ReadAndProcessPCFs()

	local dodebug = (GetConVarNumber("developer") >= 1)
	local starttime = SysTime()

	PartCtrl_AllPCFPaths = {}
	local function PartCtrl_FindAllPCFPaths(dir)
		local files, dirs = file.Find(dir .. "*", "GAME")
		for _, filename in pairs (files) do
			filename = dir .. filename
			if !HasBadEnding(filename, "GAME") then
				table.insert(PartCtrl_AllPCFPaths, filename)
			end
		end
		for _, dirname in pairs (dirs) do
			PartCtrl_FindAllPCFPaths(dir .. dirname .. "/")
		end
	end
	PartCtrl_FindAllPCFPaths("particles/")
	
	PartCtrl_PCFsByParticleName_CurrentlyLoaded = {}
	PartCtrl_CachedReadPCFs = {} //cache these so that dupe detection doesn't have to waste several seconds reading all of them again
	PartCtrl_CulledFx = {} //also build a list of fx that are culled from ProcessedPCFs, because we still need them for pcf conflict/dupe detection (i.e. load a pcf, it has culled fx with the same name as non-culled fx, so we want to detect that the latter got overwritten by the former, and tell the player about it in spawnicons)

	PartCtrl_ProcessedPCFs = {}
	for _, filename in pairs (PartCtrl_AllPCFPaths) do
		PartCtrl_ProcessedPCFs[filename] = PartCtrl_ProcessPCF(filename)
	end


	//Categorize all the pcfs by searching for them in load priority order
	local allpcfs = {}
	for k, _ in pairs (PartCtrl_ProcessedPCFs) do
		allpcfs[k] = true
	end
	allpcfs.UtilFx = nil

	PartCtrl_GamePCFs = {}
	PartCtrl_AllDataPCFs = {} //spawnlists and spawnicons use this table to quickly get a data pcf's original filename and path
	PartCtrl_GamePCFs_DefaultPaths = {} //which game is each pcf currently loaded from? nil if not currently loaded from a game.
	local function AddPCFsToSet(tab, dir, path, do_game_pcfs)
		local files, dirs = file.Find(dir .. "*", path)
		if files then
			local dir_clean = dir
			//Legacy addons will have a file path starting with the addon folder instead of the particle folder, so trim that stuff out
			//(i.e. turn addons/test_onlyparticles/particles/ukmovement.pcf into particles/ukmovement.pcf)
			if !string.StartsWith(dir, "particles") then
				local start, _, _ = string.find(dir, "/particles", 1, true) //this will break if someone names a legacy addon literally just "particles", OH WELL
				if start then
					dir_clean = string.sub(dir, start + 1)
				end
			end
			for _, filename in SortedPairsByValue (files) do
				filename = dir_clean .. filename

				//Do extra stuff for game pcfs
				if do_game_pcfs and !HasBadEnding(filename, path) then
					local original_filename = filename
					local f1 = file.Read(filename, "GAME")
					local f2 = file.Read(filename, path)
					//Resolve conflicts where multiple mounted games have different, unique pcf files sharing the same file path. 
					//For example, TF2 has an "explosion.pcf" which shares a name with a pcf from HL2, and a "blood_impact.pcf" 
					//which shares a name with a pcf included in gmod by default. The former will always be overridden if HL2 is 
					//mounted, and the latter will always be overridden no matter what. All of the inaccessible pcfs contain
					//unique effects that we don't want the player to be locked out of using, so write copies of these files to
					//the data folder, and load those instead.
					if f1 and f2 and util.SHA256(f1) != util.SHA256(f2) then
						local writepath = "partctrl_datapcfs/" .. path .. "/" .. filename
						writepath = string.Replace(writepath, ".pcf", ".txt")
						local write_new_file = true
						if file.Exists(writepath, "DATA") then
							local f3 = file.Read(writepath, "DATA")
							if f3 and util.SHA256(f2) == util.SHA256(f3) then
							//	MsgN("loading existing ", writepath)
								filename = "data/" .. writepath
								write_new_file = false
							//else
							//	MsgN("overwriting outdated ", writepath)
							end
						end
						if write_new_file then
							local dirs = string.Explode("/", writepath)
							local d = ""
							for k,v in ipairs(dirs) do
								d = (d..v.."/")
								if !string.EndsWith(d, ".txt/") then
									if !file.IsDir(d, "DATA") then file.CreateDir(d) end
								end
							end

							if file.Write(writepath, f2) then
							//	MsgN("successfully wrote ", writepath)
								filename = "data/" .. writepath
							//else
							//	MsgN("failed to write ", writepath)
							end
						end
						//Add the data pcf to all the tables
						if !PartCtrl_ProcessedPCFs[filename] then
							PartCtrl_ProcessedPCFs[filename] = PartCtrl_ProcessPCF(filename)
							PartCtrl_AllPCFPaths[filename] = true
							allpcfs[filename] = true
							PartCtrl_AllDataPCFs[filename] = {
								["original_filename"] = original_filename,
								["path"] = path
							}
						end
					end
					//Always associate pcfs from games with a game path, whether they're currently using a data pcf or not. This is 
					//used by particle ents and spawnicons, which store the *original* filename and the game path, and then use this 
					//table to retrieve the right pcf for the game. This ensures that that saves/spawnlists continue to work 
					//seamlessly between sessions, even as different combinations of mounted games change which ones use data pcfs.
					PartCtrl_GamePCFs[original_filename] = PartCtrl_GamePCFs[original_filename] or {}
					PartCtrl_GamePCFs[original_filename][path] = filename
					PartCtrl_GamePCFs_DefaultPaths[original_filename] = PartCtrl_GamePCFs_DefaultPaths[original_filename] or path
				else
					//If the currently loaded instance of this pcf isn't from a game at all, put a blank entry in here for now
					//so that game paths can't overwrite it later
					PartCtrl_GamePCFs_DefaultPaths[filename] = PartCtrl_GamePCFs_DefaultPaths[filename] or ""
				end
				
				if allpcfs[filename] then
					table.insert(tab, filename)
					allpcfs[filename] = nil
				end
			end
		end
		if dirs then
			for _, dirname in SortedPairsByValue (dirs) do
				AddPCFsToSet(tab, dir .. dirname .. "/", path)
			end
		end
	end

	local pcfs_sorted = {}
	for i = 1, 7 do
		pcfs_sorted[i] = {}
	end

	//1: packed into bsp
	AddPCFsToSet(pcfs_sorted[1], "particles/", "BSP")

	//2: legacy addons
	local addon_particles = {}
	local _, particle_folders = file.Find("addons/*", "MOD")
	for _, addon in SortedPairs(particle_folders) do
		if !file.IsDir("addons/" .. addon .. "/particles/", "MOD") then continue end
		table.insert(addon_particles, addon)
	end
	for _, addon in SortedPairsByValue(addon_particles) do
		AddPCFsToSet(pcfs_sorted[2], "addons/" .. addon .. "/particles/", "MOD")
	end

	//3: workshop addons
	for _, addon in SortedPairs(engine.GetAddons()) do
		if !addon.downloaded then continue end
		if !addon.mounted then continue end
		if !table.HasValue(select(2, file.Find("*", addon.title)), "particles") then continue end
		AddPCFsToSet(pcfs_sorted[3], "particles/", addon.title)
	end

	//4: garrysmod/particles/ folder
	AddPCFsToSet(pcfs_sorted[4], "particles/", "garrysmod", true) //handle this like a mounted game (keep track of what game they're from, and do data pcfs if they're overridden by an addon or something)

	//5: mounted games
	for _, game in SortedPairs(engine.GetGames()) do
		if !game.mounted and (game.folder != "hl2" and game.folder != "cstrike") then continue end //also load stuff from hl2/css fallback vpks; they don't have all the pcfs, but they have a few
		AddPCFsToSet(pcfs_sorted[5], "particles/", game.folder, true)
	end

	//6: garrysmod/download/ folder
	AddPCFsToSet(pcfs_sorted[6], "download/particles/", "MOD")

	//7: anything we missed somehow (this shouldn't happen)
	for k, _ in SortedPairs(allpcfs) do
		table.insert(pcfs_sorted[7], k)
	end
	//PrintTable(pcfs_sorted)


	if CLIENT then
		//sort sets into hierarchical order for dupe detection (the more "permanent" something is, the higher priority we should assign to it for dupe 
		//detection; i.e. garrysmod/particles/ are always installed, so its fx should always be considered the "originals", followed by mounted games, 
		//which are above addons because it would be absurd to consider a valve game to be derivative of a gmod addon; bsp particles and server 
		//downloads are at the end because they're transient and should never take priority over other sources)
		local pcfs_dupe_order = {}
		table.Add(pcfs_dupe_order, pcfs_sorted[4]) //garrysmod/particles/ folder
		table.Add(pcfs_dupe_order, pcfs_sorted[5]) //games
		table.Add(pcfs_dupe_order, pcfs_sorted[2]) //legacy addons
		table.Add(pcfs_dupe_order, pcfs_sorted[3]) //workshop addons
		table.Add(pcfs_dupe_order, pcfs_sorted[6]) //garrysmod/download/ folder
		table.Add(pcfs_dupe_order, pcfs_sorted[1]) //packed into bsp
		table.Add(pcfs_dupe_order, pcfs_sorted[7]) //other
		PartCtrl_PCFsInDupeOrder = pcfs_dupe_order //global so that PartCtrl_GetDuplicateFx can be run again later without rebuilding this table
		PartCtrl_GetDuplicateFx()
	end


	//Run AddParticles in another particular order, so things like gmod fx take priority by default;
	//this prevents TF2's blood fx from becoming the default when you shoot an NPC, for instance
	//NOTE: had to put gmod+games above addons to prevent an issue where tf2 map particles addon's 
	//particles/brine_salmann_goop.pcf would unintentionally override the default blood fx, is this bad? 
	//TODO: could this cause issues with other addons i'm not aware of that try to override gmod or game fx?
	local pcfs_load_order = {}
	table.Add(pcfs_load_order, pcfs_sorted[1]) //packed into bsp
	table.Add(pcfs_load_order, pcfs_sorted[4]) //garrysmod/particles/ folder
	table.Add(pcfs_load_order, pcfs_sorted[5]) //games
	table.Add(pcfs_load_order, pcfs_sorted[2]) //legacy addons
	table.Add(pcfs_load_order, pcfs_sorted[3]) //workshop addons
	table.Add(pcfs_load_order, pcfs_sorted[6]) //garrysmod/download/ folder
	table.Add(pcfs_load_order, pcfs_sorted[7]) //other
	for _, filename in SortedPairs (pcfs_load_order, true) do
		//MsgN("running AddParticles for ", filename)
		if CLIENT then
			PartCtrl_AddParticles(filename)
		else
			game.AddParticles(filename)
		end
	end


	//clean unnecessary entries out of this table now that we're done building it
	for k, v in pairs (PartCtrl_GamePCFs_DefaultPaths) do
		if v == "" then //if PartCtrl_GamePCFs[k] == nil then
			PartCtrl_GamePCFs_DefaultPaths[k] = nil
		end
	end

	//add util fx to processedpcfs as well, so that particle entities and spawnicons can use them natively
	PartCtrl_ProcessUtilFx()

	PartCtrl_ReadAndProcessPCFs_StartupHasRun = true

	--[[if dodebug then]] MsgN("PartCtrl: PartCtrl_ReadAndProcessPCFs took " , SysTime() - starttime, " secs") //end

end

//If this game has this pcf, but it's not currently loadable because it's being overridden by a conflicting pcf of the same name, this returns 
//the filepath for a copy of the inaccessible pcf, located in the data folder (a "data pcf"). Otherwise, returns the same pcf we gave it.
//(for details, see the part of PartCtrl_ReadAndProcessPCFs() where we populate PartCtrl_GamePCFs)
function PartCtrl_GetGamePCF(pcf, path)
	if !path or !PartCtrl_GamePCFs[pcf] or !PartCtrl_GamePCFs[pcf][path] then return pcf end
	return PartCtrl_GamePCFs[pcf][path]
end

function PartCtrl_GetDataPCFNiceName(pcf)
	if pcf == "UtilFx" then return "Scripted Effect" end
	local tab = PartCtrl_AllDataPCFs[pcf]
	if !tab then return pcf end
	return tab.original_filename .. " (" .. tab.path .. ")"
end




if CLIENT then

	//Determine which fx are actually identical copies of another effect of the same name.
	//This is used to prevent unnecessary AddParticles loading and bad "effect is unloaded, click to load" info in spawnicons (dupes are considered 
	//equivalent to the effect they're a copy of), and also to prevent search results from getting clogged up with multiple identical effects.
	function PartCtrl_GetDuplicateFx()

		PartCtrl_DuplicateFx = {}
		PartCtrl_PCFsByParticleName = {}
		//TODO: can't do debug spew for everything when developer mode is on, since there's too much stuff per pcf, so currently this is all done 
		//for a single pcf and/or effect defined manually in code. i guess this could be moved to some convars in case other devs want to use it?
		
		for _, filename in SortedPairs (PartCtrl_PCFsInDupeOrder) do
			PartCtrl_DuplicateFx[filename] = {}
			//local dodebug = filename == "particles/rain_fx_unused.pcf"
			local dupe_candidates = {}

			local allfx = {}
			for k, _ in pairs (PartCtrl_ProcessedPCFs[filename]) do
				allfx[k] = true
			end
			for k, _ in pairs (PartCtrl_CulledFx[filename]) do
				allfx[k] = true
			end

			for effect, _ in SortedPairs (allfx) do
				//local dodebug = effect == "halloween_boss_foot_fire_customcolor"
				//if dodebug then MsgN(effect) end
				//if dodebug and effect == "ash_eddy_b" then PrintTable(PartCtrl_PCFsByParticleName[effect]) end
				PartCtrl_PCFsByParticleName[effect] = PartCtrl_PCFsByParticleName[effect] or {}
				for _, filename2 in SortedPairs (PartCtrl_PCFsByParticleName[effect]) do
					//Compare the effect to all other fx of the same name (except the ones that we know 
					//are dupes themselves) to determine if this effect is a duplicate of one of them
					if PartCtrl_DuplicateFx[filename2][effect] then
						//if dodebug then MsgN(filename .. "/" .. filename2 .. ": ", effect, " this potential candidate is a dupe of ", PartCtrl_DuplicateFx[filename2][effect], ", skipping") end
						continue
					end
					//if dupe_candidates[effect] then break end
					local is_dupe = true
					local function CompareTables(t1, t2, level, table_name_for_debug)
						if !is_dupe then return end
						local operator_tables = {
							["constraints"] = true,
							["emitters"] = true,
							["forces"] = true,
							["initializers"] = true,
							["operators"] = true,
							["renderers"] = true,
						}

						local allkeys = {}
						for k, _ in pairs (t1) do
							allkeys[k] = true
						end
						for k, _ in pairs (t2) do
							allkeys[k] = true
						end
						if level == 1 then
							for _, v in pairs ({
								//these definitely don't matter at all
								"bounding_box_max", 
								"bounding_box_min",
								//less sure about this one; there are plenty of false positives where the change in max_particles doesn't matter at all
								//since it never actually reaches the cap (left4dead2 fire_01.pcf's smoke_exhaust_01a/smoke_exhaust_01b), but a few where
								//it actually does make it visibly different by cutting off particle emission (particles/mvm.pcf's mini_fireworks, 
								//left4dead2 fire_01.pcf's smoke_medium_02c). in the cases where it does make a difference, it's still pretty subtle, so 
								//i'm making an executive decision here to treat those as dupes anyway, to err on the side of not clogging up searches.
								"max_particles",
							}) do
								allkeys[v] = nil
							end
						end

						for k, _ in PartCtrl_SortedPairsLower (allkeys) do
							if !is_dupe then return end
							if t1[k] != nil and t2[k] != nil then //if a value exists in one table but not another, then ignore it; newer pcf versions omit keys with default values, but older versions don't
								if istable(t1[k]) and istable(t2[k]) then
									if level == 1 and table.IsSequential(t1[k]) then
										//if a sequential table (list of children or operators) has a mismatched count,
										//then it's different, don't bother comparing them
										if #t1[k] != #t2[k] then
											//if dodebug then MsgN(table_name_for_debug, ".", k, ": table count ", #t1[k], " != ", #t2[k]) end
											is_dupe = false
											return
										end
										//special handling for operator/child lists to order their subtables by functionName or child,
										//to catch cases where fx have the same items listed in a different order
										if operator_tables[k] then
											table.SortByMember(t1[k], "functionName", true)
											table.SortByMember(t2[k], "functionName", true)
										elseif k == "children" then
											table.SortByMember(t1[k], "child", true)
											table.SortByMember(t2[k], "child", true)
										end
									end
									--[[local d = table_name_for_debug .. "." .. k
									if t1[k].functionName then
										d = d .. "(" .. t1[k].functionName .. ")"
									elseif t1[k].child then
										d = d .. "(" .. t1[k].child .. ")"
									end]]
									CompareTables(t1[k], t2[k], level + 1, d)
								else
									//catch cases where values refer to the same file path, but with mismatched slashes
									if isstring(t1[k]) then
										t1[k] = string.Replace(t1[k], "\\", "/")
									end
									if isstring(t2[k]) then
										t2[k] = string.Replace(t2[k], "\\", "/")
									end
									//if values don't match, then it's not a dupe
									if t1[k] != t2[k] then
										//if dodebug then MsgN(table_name_for_debug, ".", k, ": ", t1[k], " != ", t2[k]) end
										is_dupe = false
										return
									end
								end
							end
						end
					end
					//note: this needs to use copies of the cached tables, not the originals, otherwise table.SortByMember above will modify the 
					//cached table and cause inconsistent results (i.e. operators with the same functionName no longer being in the same order) 
					//if this function is run multiple times in a session
					CompareTables(table.Copy(PartCtrl_CachedReadPCFs[filename][effect]), table.Copy(PartCtrl_CachedReadPCFs[filename2][effect]), 1, filename .. "/" .. filename2 .. ": " .. effect)
					if is_dupe then
						dupe_candidates[effect] = dupe_candidates[effect] or {}
						table.insert(dupe_candidates[effect], filename2)
						//if dodebug then MsgN(filename .. "/" .. filename2 .. ": ", effect, " dupe candidate found") end
						//break
					end
				end
				table.insert(PartCtrl_PCFsByParticleName[effect], filename)
			end
			//Double check to make sure all the children of an effect are dupes as well
			//if dodebug then PrintTable(dupe_candidates) end
			for effect, v in pairs (dupe_candidates) do
				children_all_dupes = true
				local function CheckIfChildrenAreDupes(effect2)
					if !children_all_dupes then return end
					//local dodebug = effect == "fire_large_01"
					//Q: What's all this complicated nonsense for?
					//
					//A: This is for complex cases like particles/fire_01_unused.pcf's fire_large_01. This effect has multiple children:
					//
					//   Some, like smoke_large_01, are dupes of left4dead2 fire_01.pcf, but are DIFFERENT from the effect of the same name
					//   in particles/fire_01.pcf.
					//
					//   Others, like embers_large_01, are dupes of particles/fire_01.pcf, and the effect of the same name in the left4dead2 pcf
					//   is ALSO a dupe of fire_01.pcf, but embers_large_01 doesn't catch it as a dupe candidate, because the compare code doesn't
					//   compare it with effects we've already confirmed to be dupes - that would be redundant.
					//
					//   fire_large_01 itself has no differences on its own, and returns as a dupe of both fire_01.pcf and the left4dead2 pcf.
					//
					//   In this case, we want fire_large_01 to return as a dupe of the left4dead2 pcf, but not fire_01.pcf, because its child 
					//   smoke_large_01 is different. This requires us to keep a whole list of potential dupe candidates instead of just the first 
					//   we find, and then also associate the child embers_large_01 with the left4dead2 pcf, despite that pcf not being in the 
					//   child's list of dupe candidates.
					for _, tab in pairs (PartCtrl_CachedReadPCFs[filename][effect2].children) do
						if !dupe_candidates[tab.child] then
							//if dodebug then MsgN(filename, ": ", effect, ": child ", tab.child, " has no dupe candidates, discarding") end
							children_all_dupes = false
							return
						else
							for k, v in pairs (dupe_candidates[effect]) do
								if !table.HasValue(dupe_candidates[tab.child], v) then
									local dupecheck = false
									//if dodebug --[[and tab.child == "embers_large_01"]] then PrintTable(dupe_candidates[tab.child]) end
									for k2, v2 in pairs (dupe_candidates[tab.child]) do
										//if dodebug --[[and tab.child == "embers_large_01"]] then
										//	MsgN("DUPECHECK: v = ", v, ", PartCtrl_DuplicateFx = ", PartCtrl_DuplicateFx[v][tab.child], ", v2 = ", v2)
										//end
										if PartCtrl_DuplicateFx[v][tab.child] == v2 then //this seems like nonsense but it works, argh
											//if dodebug then MsgN(filename, ": ", effect, ": child ", tab.child, " dupecheck found that ", v, " is a dupe of ", v2, ", so the former should remain in candidates") end
											dupecheck = true
											break
										end
									end

									if !dupecheck then
										//if dodebug then MsgN(filename, ": ", effect, ": child ", tab.child, " does not have dupe candidate ", v, ", removing from candidates") end
										table.RemoveByValue(dupe_candidates[effect], v)
									end
								end
							end
							if #dupe_candidates[effect] == 0 then
								//if dodebug then MsgN(filename, ": ", effect, ": child ", tab.child, " has no dupe candidates left, discarding") end
								children_all_dupes = false
								return
							else
								CheckIfChildrenAreDupes(tab.child)
							end
						end
					end
				end

				CheckIfChildrenAreDupes(effect)
				if children_all_dupes then
					PartCtrl_DuplicateFx[filename][effect] = dupe_candidates[effect][1]
					//if dodebug then MsgN(filename .. "/" .. dupe_candidates[effect][1] .. ": " .. effect .. ": dupe found!") end
				end
			end
		end

		//TODO: used for old conflict detection, do we still need this? keeping this here until 100% sure it's unnecessary.
		//Build PartCtrl_PCFsWithConflicts for spawnicon conflicting pcf lists: if every single conflicting effect in
		//a pcf is culled or a duplicate, then there's no chance of the player reloading it, so don't bother listing it
		--[[PartCtrl_PCFsWithConflicts = {}
		for _, pcf in pairs (PartCtrl_PCFsInDupeOrder) do
			for name, _ in pairs (PartCtrl_ProcessedPCFs[pcf]) do
				if !PartCtrl_DuplicateFx[pcf] then MsgN(pcf, " bad") end
				if !PartCtrl_PCFsByParticleName[name] then MsgN(pcf, " bad") end
				if !PartCtrl_DuplicateFx[pcf][name] and #PartCtrl_PCFsByParticleName[name] > 1 then
					PartCtrl_PCFsWithConflicts[pcf] = true 
					break
				end
			end
		end]]

	end

end