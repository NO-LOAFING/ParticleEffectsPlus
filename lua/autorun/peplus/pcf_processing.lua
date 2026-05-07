AddCSLuaFile()

//add these as enums, but also store them in a table so that we can
//translate the numbers back into human-readable names easily
PEPLUS_CPOINT_MODES = {
	[0] = "PEPLUS_CPOINT_MODE_NONE",
	[1] = "PEPLUS_CPOINT_MODE_POSITION",
	[2] = "PEPLUS_CPOINT_MODE_POSITION_COMBINE",
	[3] = "PEPLUS_CPOINT_MODE_AXIS"
}
for k, v in pairs (PEPLUS_CPOINT_MODES) do
	_G[v] = k
end

//for networking convenience
peplus_cpointbits = 7 //-1 - 63

peplus_wait = "wait" //another convenient global, used by particlesystems that can't currently be created (due to CrashCheck or a disabled particle entity) but should be created as soon as possible

//for vector/axis cpoints; names and comments from https://github.com/SourceSDK2013Ports/csgo-src/blob/main/src/public/particles/particles.h#L78
PEPLUS_PARTICLE_ATTRIBUTE_XYZ = 0 // required
PEPLUS_PARTICLE_ATTRIBUTE_LIFE_DURATION = 1 // particle lifetime (duration) of particle as a float.
PEPLUS_PARTICLE_ATTRIBUTE_PREV_XYZ = 2 // prev coordinates for verlet integration
PEPLUS_PARTICLE_ATTRIBUTE_RADIUS = 3 // radius of particle
PEPLUS_PARTICLE_ATTRIBUTE_ROTATION = 4 // rotation angle of particle
PEPLUS_PARTICLE_ATTRIBUTE_ROTATION_SPEED = 5 // rotation speed of particle
PEPLUS_PARTICLE_ATTRIBUTE_TINT_RGB = 6 // tint of particle
PEPLUS_PARTICLE_ATTRIBUTE_ALPHA = 7 // alpha tint of particle
PEPLUS_PARTICLE_ATTRIBUTE_CREATION_TIME = 8 // creation time stamp (relative to particle system creation)
PEPLUS_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER = 9 // sequnece # (which animation sequence number this particle uses )
PEPLUS_PARTICLE_ATTRIBUTE_TRAIL_LENGTH = 10 // length of the trail 
PEPLUS_PARTICLE_ATTRIBUTE_PARTICLE_ID = 11 // unique particle identifier
PEPLUS_PARTICLE_ATTRIBUTE_YAW = 12 // unique rotation around up vector
PEPLUS_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1 = 13 // second sequnece # (which animation sequence number this particle uses )
PEPLUS_PARTICLE_ATTRIBUTE_HITBOX_INDEX = 14 // hit box index
PEPLUS_PARTICLE_ATTRIBUTE_HITBOX_RELATIVE_XYZ = 15
PEPLUS_PARTICLE_ATTRIBUTE_ALPHA2 = 16
PEPLUS_PARTICLE_ATTRIBUTE_SCRATCH_VEC = 17 //scratch field used for storing arbitraty vec data
PEPLUS_PARTICLE_ATTRIBUTE_SCRATCH_FLOAT = 18 //scratch field used for storing arbitraty float data	
PEPLUS_PARTICLE_ATTRIBUTE_UNUSED = 19
PEPLUS_PARTICLE_ATTRIBUTE_PITCH = 20
PEPLUS_PARTICLE_ATTRIBUTE_NORMAL = 21 // 0 0 0 if none
PEPLUS_PARTICLE_ATTRIBUTE_GLOW_RGB = 22 // glow color
PEPLUS_PARTICLE_ATTRIBUTE_GLOW_ALPHA = 23 // glow alpha
//old attributes from pre-csgo particles https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/public/particles/particles.h#L62
//PEPLUS_PARTICLE_ATTRIBUTE_TRACE_P0 = 17 // particle trace caching fields // start pnt of trace
//PEPLUS_PARTICLE_ATTRIBUTE_TRACE_P1 = 18 // end pnt of trace
//PEPLUS_PARTICLE_ATTRIBUTE_TRACE_HIT_T = 19 // 0..1 if hit
//PEPLUS_PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL = 20 // 0 0 0 if no hit
local ParticleAttributeNames = { //names from https://github.com/SourceSDK2013Ports/csgo-src/blob/main/src/particles/particles.cpp#L3782
	[PEPLUS_PARTICLE_ATTRIBUTE_XYZ] = "Position", // XYZ, 0
	[PEPLUS_PARTICLE_ATTRIBUTE_LIFE_DURATION] = "Life Duration", // LIFE_DURATION, 1 );
	[PEPLUS_PARTICLE_ATTRIBUTE_PREV_XYZ] = "Position Previous", // PREV_XYZ 
	[PEPLUS_PARTICLE_ATTRIBUTE_RADIUS] = "Radius", // RADIUS, 3 );
	[PEPLUS_PARTICLE_ATTRIBUTE_ROTATION] = "Roll", // ROTATION, 4 );
	[PEPLUS_PARTICLE_ATTRIBUTE_ROTATION_SPEED] = "Roll Speed", // ROTATION_SPEED, 5 );
	[PEPLUS_PARTICLE_ATTRIBUTE_TINT_RGB] = "Color", // TINT_RGB, 6 );
	[PEPLUS_PARTICLE_ATTRIBUTE_ALPHA] = "Alpha", // ALPHA, 7 );
	[PEPLUS_PARTICLE_ATTRIBUTE_CREATION_TIME] = "Creation Time", // CREATION_TIME, 8 );
	[PEPLUS_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER] = "Texture", //better display name, technically inaccurate but players are more likely to understand what this means; original: "Sequence Number", // SEQUENCE_NUMBER, 9 );
	[PEPLUS_PARTICLE_ATTRIBUTE_TRAIL_LENGTH] = "Trail Length", // TRAIL_LENGTH, 10 );
	[PEPLUS_PARTICLE_ATTRIBUTE_PARTICLE_ID] = "Particle ID", // PARTICLE_ID, 11 ); 
	[PEPLUS_PARTICLE_ATTRIBUTE_YAW] = "Yaw", // YAW, 12 );
	[PEPLUS_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1] = "Texture", //better display name, technically inaccurate but players are more likely to understand what this means; original: "Sequence Number 1", // SEQUENCE_NUMBER1, 13 );
	[PEPLUS_PARTICLE_ATTRIBUTE_HITBOX_INDEX] = "Hitbox Index", // HITBOX_INDEX, 14
	[PEPLUS_PARTICLE_ATTRIBUTE_HITBOX_RELATIVE_XYZ] = "Hitbox Offset Position", // HITBOX_XYZ_RELATIVE 15
	[PEPLUS_PARTICLE_ATTRIBUTE_ALPHA2] = "Alpha", //better display name, there's no difference between the two alphas as far as players are concerned; original: "Alpha Alternate", // ALPHA2, 16
	[PEPLUS_PARTICLE_ATTRIBUTE_SCRATCH_VEC] = "Scratch Vector", // SCRATCH_VEC 17
	[PEPLUS_PARTICLE_ATTRIBUTE_SCRATCH_FLOAT] = "Scratch Float", // SCRATCH_FLOAT 18
	[PEPLUS_PARTICLE_ATTRIBUTE_UNUSED] = "Unused Particle Attribute", //NULL,
	[PEPLUS_PARTICLE_ATTRIBUTE_PITCH] = "Pitch", // PITCH, 20
	[PEPLUS_PARTICLE_ATTRIBUTE_NORMAL] = "Normal", // NORMAL, 21
	[PEPLUS_PARTICLE_ATTRIBUTE_GLOW_RGB] = "Glow RGB", //GLOW_RGB,22 //i don't think these last two are implemented in gmod, actually?
	[PEPLUS_PARTICLE_ATTRIBUTE_GLOW_ALPHA] = "Glow Alpha", //GLOW_ALPHA,23
	//old attributes from pre-csgo particles https://github.com/nillerusr/source-engine/blob/master/particles/particles.cpp#L3026
	//[PEPLUS_PARTICLE_ATTRIBUTE_TRACE_P0] = "PARTICLE_ATTRIBUTE_TRACE_P0 (internal)",
	//[PEPLUS_PARTICLE_ATTRIBUTE_TRACE_P1] = "PARTICLE_ATTRIBUTE_TRACE_P1 (internal)",
	//[PEPLUS_PARTICLE_ATTRIBUTE_TRACE_HIT_T] = "PARTICLE_ATTRIBUTE_TRACE_HIT_T (internal)",
	//[PEPLUS_PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL] = "PARTICLE_ATTRIBUTE_TRACE_HIT_NORMAL (internal)"
}

//enums from https://github.com/nillerusr/Kisak-Strike/blob/master/public/datamodel/dmattributetypes.h#L66-L106
//names from https://github.com/nillerusr/Kisak-Strike/blob/master/public/datamodel/dmattributetypes.h#L320-L349
local a = {}
table.insert(a, "element")	//AT_ELEMENT
table.insert(a, "int")		//AT_INT
table.insert(a, "float")	//AT_FLOAT
table.insert(a, "bool")		//AT_BOOL
table.insert(a, "string")	//AT_STRING
table.insert(a, "binary")	//AT_VOID
table.insert(a, "time")		//AT_TIME
table.insert(a, "color")	//AT_COLOR
table.insert(a, "vector2") 	//AT_VECTOR2
table.insert(a, "vector3") 	//AT_VECTOR3
table.insert(a, "vector4") 	//AT_VECTOR4
table.insert(a, "qangle") 	//AT_QANGLE
table.insert(a, "quaternion") 	//AT_QUATERNION
table.insert(a, "matrix") 	//AT_VMATRIX
table.insert(a, "element_array")//AT_ELEMENT_ARRAY
table.insert(a, "int_array")	//AT_INT_ARRAY
table.insert(a, "float_array") 	//AT_FLOAT_ARRAY
table.insert(a, "bool_array") 	//AT_BOOL_ARRAY
table.insert(a, "string_array")	//AT_STRING_ARRAY
table.insert(a, "binary_array")	//AT_VOID_ARRAY
table.insert(a, "time_array")	//AT_TIME_ARRAY
table.insert(a, "color_array")	//AT_COLOR_ARRAY
table.insert(a, "vector2_array")//AT_VECTOR2_ARRAY
table.insert(a, "vector3_array")//AT_VECTOR3_ARRAY
table.insert(a, "vector4_array")//AT_VECTOR4_ARRAY
table.insert(a, "qangle_array")	//AT_QANGLE_ARRAY
table.insert(a, "quaternion_array")//AT_QUATERNION_ARRAY
table.insert(a, "matrix_array")	//AT_VMATRIX_ARRAY

//from https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/devtools/bin/fix_particle_operator_names.pl#L54
local fixes = {
	alpha_fade = "Alpha Fade and Decay",
	alpha_fade_in_random = "Alpha Fade In Random",
	alpha_fade_out_random = "Alpha Fade Out Random",
	basic_movement = "Movement Basic",
	color_fade = "Color Fade",
	controlpoint_light = "Color Light From Control Point",
	["Dampen Movement Relative to Control Point"] = "Movement Dampen Relative to Control Point",
	["Distance Between Control Points Scale"] = "Remap Distance Between Two Control Points to Scalar",
	["Distance to Control Points Scale"] = "Remap Distance to Control Point to Scalar",
	lifespan_decay = "Lifespan Decay",
	["lock to bone"] = "Movement Lock to Bone",
	postion_lock_to_controlpoint = "Movement Lock to Control Point",
	["maintain position along path"] = "Movement Maintain Position Along Path",
	["Match Particle Velocities"] = "Movement Match Particle Velocities",
	["Max Velocity"] = "Movement Max Velocity",
	["noise"] = "Noise Scalar",
	["vector noise"] = "Noise Vector",
	oscillate_scalar = "Oscillate Scalar",
	oscillate_vector = "Oscillate Vector",
	["Orient Rotation to 2D Direction"] = "Rotation Orient to 2D Direction",
	radius_scale = "Radius Scale",
	["Random Cull"] = "Cull Random",
	remap_scalar = "Remap Scalar",
	rotation_movement = "Rotation Basic",
	rotation_spin = "Rotation Spin Roll",
	["rotation_spin yaw"] = "Rotation Spin Yaw",
	alpha_random = "Alpha Random",
	color_random = "Color Random",
	["create from parent particles"] = "Position From Parent Particles",
	["Create In Hierarchy"] = "Position In CP Hierarchy",
	["random position along path"] = "Position Along Path Random",
	["random position on model"] = "Position on Model Random",
	["sequential position along path"] = "Position Along Path Sequential",
	position_offset_random = "Position Modify Offset Random",
	position_warp_random = "Position Modify Warp Random",
	position_within_box = "Position Within Box Random",
	position_within_sphere = "Position Within Sphere Random",
	["Inherit Velocity"] = "Velocity Inherit from Control Point",
	["Initial Repulsion Velocity"] = "Velocity Repulse from World",
	["Initial Velocity Noise"] = "Velocity Noise",
	["Initial Scalar Noise"] = "Remap Noise to Scalar",
	["Lifespan from distance to world"] = "Lifetime from Time to Impact",
	["Pre-Age Noise"] = "Lifetime Pre-Age Noise",
	lifetime_random = "Lifetime Random",
	radius_random = "Radius Random",
	["random yaw"] = "Rotation Yaw Random",
	["Randomly Flip Yaw"] = "Rotation Yaw Flip Random",
	rotation_random = "Rotation Random",
	rotation_speed_random = "Rotation Speed Random",
	sequence_random = "Sequence Random",
	second_sequence_random = "Sequence Two Random",
	trail_length_random = "Trail Length Random",
	velocity_random = "Velocity Random",
}
local fixes2 = {}
for k, v in pairs (fixes) do
	fixes2[string.lower(k)] = string.lower(v)
end
fixes = fixes2
fixes2 = nil


//copied 1/1/25; if an update changes a default value on the main effect table or on any operator, update this table and increment cache_version above
local defs = {
	_main = {
		["Sort particles"] = true,
		["batch particle systems"] = false,
		bounding_box_max = Vector(10,10,10),
		bounding_box_min = Vector(-10,-10,-10),
		children = {}, //according to a bug report, this value is nil in pcf(s) from Day of Defeat: Source (usually this is a blank table if there's no children), so add a fallback for these; i don't have DoD:S so this is a blind fix
		color = Color(255,255,255,255),
		["control point to disable rendering if it is the camera"] = -1,
		cull_control_point = 0,
		cull_cost = 1,
		cull_radius = 0,
		cull_replacement_definition = "",
		["group id"] = 0,
		initial_particles = 0,
		material = "vgui/white",
		max_particles = 1000,
		["maximum draw distance"] = 100000,
		["maximum sim tick rate"] = 0,
		["maximum time step"] = 0.10000000149012,
		["minimum rendered frames"] = 0,
		["minimum sim tick rate"] = 0,
		normal = Vector(0,0,1),
		preventNameBasedLookup = false,
		radius = 5,
		rotation = 0,
		rotation_speed = 0,
		["screen space effect"] = false,
		sequence_number = 0,
		["sequence_number 1"] = 0,
		["time to sleep when not drawn"] = 8,
		["view model effect"] = false,
	},
	renderers = {
		_generic = {
			["Visibility Alpha Scale maximum"] = 1, //render_rope doesn't actually have the Visibility ones; whatever
			["Visibility Alpha Scale minimum"] = 0,
			["Visibility Camera Depth Bias"] = 0,
			["Visibility Proxy Input Control Point Number"] = -1,
			["Visibility Proxy Radius"] = 1,
			["Visibility Radius Scale maximum"] = 1,
			["Visibility Radius Scale minimum"] = 1,
			["Visibility input distance maximum"] = 0,
			["Visibility input distance minimum"] = 0,
			["Visibility input dot maximum"] = 0,
			["Visibility input dot minimum"] = 0,
			["Visibility input maximum"] = 1,
			["Visibility input minimum"] = 0,
			["operator end cap state"] = -1,
			["operator end fadein"] = 0,
			["operator end fadeout"] = 0,
			["operator fade oscillate"] = 0,
			["operator start fadein"] = 0,
			["operator start fadeout"] = 0,
			["operator strength random scale max"] = 1,
			["operator strength random scale min"] = 1,
			["operator strength scale seed"] = 0,
			["operator time offset max"] = 0,
			["operator time offset min"] = 0,
			["operator time offset seed"] = 0,
			["operator time scale max"] = 1,
			["operator time scale min"] = 1,
			["operator time scale seed"] = 0,
			["operator time strength random scale max"] = 1,
		},
		["Render models"] = {
			["activity override"] = "",
			["animation rate"] = 30,
			["animation rate scale field"] = 10,
			["orient model z to normal"] = false,
			["scale animation rate"] = false,
			["sequence 0 model"] = "NONE",
			["skin number"] = 0,
		},
		render_animated_sprites = {
			["animation rate"] = 0.10000000149012,
			animation_fit_lifetime = false,
			["orientation control point"] = -1,
			orientation_type = 0,
			["second sequence animation rate"] = 0,
			["use animation rate as FPS"] = false,
		},
		render_rope = {
			["scale CP end"] = -1,
			["scale CP start"] = -1,
			["scale offset by CP distance"] = false,
			["scale scroll by CP distance"] = false,
			["scale texture by CP distance"] = false,
			subdivision_count = 3,
			texel_size = 4,
			texture_offset = 0,
			texture_scroll_rate = 0,
		},
		render_screen_velocity_rotate = {
			forward_angle = -90,
			["rotate_rate(dps)"] = 0,
		},
		render_sprite_trail = {
			["animation rate"] = 0.10000000149012,
			["constrain radius to length"] = true,
			["ignore delta time"] = false,
			["length fade in time"] = 0,
			["max length"] = 2000,
			["min length"] = 0,
			["tail color and alpha scale factor"] = {
				[1] = 1,
				[2] = 1,
				[3] = 1,
				[4] = 1,
			},
		},
	},
	operators = {
		_generic = {
			["operator end cap state"] = -1,
			["operator end fadein"] = 0,
			["operator end fadeout"] = 0,
			["operator fade oscillate"] = 0,
			["operator start fadein"] = 0,
			["operator start fadeout"] = 0,
			["operator strength random scale max"] = 1,
			["operator strength random scale min"] = 1,
			["operator strength scale seed"] = 0,
			["operator time offset max"] = 0,
			["operator time offset min"] = 0,
			["operator time offset seed"] = 0,
			["operator time scale max"] = 1,
			["operator time scale min"] = 1,
			["operator time scale seed"] = 0,
			["operator time strength random scale max"] = 1,
		},
		["Alpha Fade and Decay"] = {
			end_alpha = 0,
			end_fade_in_time = 0.5,
			end_fade_out_time = 1,
			start_alpha = 1,
			start_fade_in_time = 0,
			start_fade_out_time = 0.5,
		},
		["Alpha Fade and Decay for Tracers"] = {
			end_alpha = 0,
			end_fade_in_time = 0.5,
			end_fade_out_time = 1,
			start_alpha = 1,
			start_fade_in_time = 0,
			start_fade_out_time = 0.5,
		},
		["Alpha Fade In Random"] = {
			["fade in time exponent"] = 1,
			["fade in time max"] = 0.25,
			["fade in time min"] = 0.25,
			["proportional 0/1"] = true,
		},
		["Alpha Fade In Simple"] = {
			["proportional fade in time"] = 0.25,
		},
		["Alpha Fade Out Random"] = {
			["ease in and out"] = true,
			["fade bias"] = 0.5,
			["fade out time exponent"] = 1,
			["fade out time max"] = 0.25,
			["fade out time min"] = 0.25,
			["proportional 0/1"] = true,
		},
		["Alpha Fade Out Simple"] = {
			["proportional fade out time"] = 0.25,
		},
		["Clamp Scalar"] = {
			["output field"] = 3,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Clamp Vector"] = {
			["output field"] = 0,
			["output maximum"] = Vector(1,1,1),
			["output minimum"] = Vector(0,0,0),
		},
		["Color Fade"] = {
			color_fade = Color(255,255,255,255),
			ease_in_and_out = true,
			fade_end_time = 1,
			fade_start_time = 0,
			["output field"] = 6,
		},
		["Color Light from Control Point"] = {
			["Clamp Maximum Light Value to Initial Color"] = false,
			["Clamp Minimum Light Value to Initial Color"] = false,
			["Compute Normals From Control Points"] = false,
			["Half-Lambert Normals"] = true,
			["Initial Color Bias"] = 0,
			["Light 1 0% Distance"] = 200,
			["Light 1 50% Distance"] = 100,
			["Light 1 Color"] = Color(0,0,0,255),
			["Light 1 Control Point"] = 0,
			["Light 1 Control Point Offset"] = Vector(0,0,0),
			["Light 1 Direction"] = Vector(0,0,0),
			["Light 1 Dynamic Light"] = false,
			["Light 1 Spot Inner Cone"] = 30,
			["Light 1 Spot Outer Cone"] = 45,
			["Light 1 Type 0=Point 1=Spot"] = false,
			["Light 2 0% Distance"] = 200,
			["Light 2 50% Distance"] = 100,
			["Light 2 Color"] = Color(0,0,0,255),
			["Light 2 Control Point"] = 0,
			["Light 2 Control Point Offset"] = Vector(0,0,0),
			["Light 2 Direction"] = Vector(0,0,0),
			["Light 2 Dynamic Light"] = false,
			["Light 2 Spot Inner Cone"] = 30,
			["Light 2 Spot Outer Cone"] = 45,
			["Light 2 Type 0=Point 1=Spot"] = false,
			["Light 3 0% Distance"] = 200,
			["Light 3 50% Distance"] = 100,
			["Light 3 Color"] = Color(0,0,0,255),
			["Light 3 Control Point"] = 0,
			["Light 3 Control Point Offset"] = Vector(0,0,0),
			["Light 3 Direction"] = Vector(0,0,0),
			["Light 3 Dynamic Light"] = false,
			["Light 3 Spot Inner Cone"] = 30,
			["Light 3 Spot Outer Cone"] = 45,
			["Light 3 Type 0=Point 1=Spot"] = false,
			["Light 4 0% Distance"] = 200,
			["Light 4 50% Distance"] = 100,
			["Light 4 Color"] = Color(0,0,0,255),
			["Light 4 Control Point"] = 0,
			["Light 4 Control Point Offset"] = Vector(0,0,0),
			["Light 4 Direction"] = Vector(0,0,0),
			["Light 4 Dynamic Light"] = false,
			["Light 4 Spot Inner Cone"] = 30,
			["Light 4 Spot Outer Cone"] = 45,
			["Light 4 Type 0=Point 1=Spot"] = false,

		},
		["Cull Random"] = {
			["Cull End Time"] = 1,
			["Cull Percentage"] = 0.5,
			["Cull Start Time"] = 0,
			["Cull Time Exponent"] = 1,

		},
		["Cull relative to model"] = {
			control_point_number = 0,
			["cull outside instead of inside"] = false,
			["hitbox set"] = "effects",
			["use only bounding box"] = false,
		},
		["Cull when crossing plane"] = {
			["Control Point for point on plane"] = 0,
			["Cull plane offset"] = 0,
			["Plane Normal"] = Vector(0,0,1),
		},
		["Cull when crossing sphere"] = {
			["Control Point"] = 0,
			["Control Point offset"] = Vector(0,0,0),
			["Cull Distance"] = 0,
			["Cull inside instead of outside"] = false,
		},
		["Inherit Attribute From Parent Particle"] = {
			["Inherited Field"] = 3,
			["Particle Increment Amount"] = 1,
			["Random Parent Particle Distribution"] = false,
			Scale = 1,
		},
		["Lerp EndCap Scalar"] = {
			["lerp time"] = 1,
			["output field"] = 3,
			["value to lerp to"] = 1,
		},
		["Lerp EndCap Vector"] = {
			["lerp time"] = 1,
			["output field"] = 0,
			["value to lerp to"] = Vector(0,0,0),
		},
		["Lerp Initial Scalar"] = {
			["end time"] = 1,
			["output field"] = 3,
			["start time"] = 0,
			["value to lerp to"] = 1,
		},
		["Lerp Initial Vector"] = {
			["end time"] = 1,
			["output field"] = 0,
			["start time"] = 0,
			["value to lerp to"] = Vector(0,0,0),
		},
		["Lifespan Decay"] = {},
		["Lifespan Maintain Count Decay"] = {
			["count to maintain"] = 100,
			["decay delay"] = 0,
			["maintain count scale control point"] = -1,
			["maintain count scale control point field"] = 0,
		},
		["Lifespan Minimum Alpha Decay"] = {
			["minimum alpha"] = 0,
		},
		["Lifespan Minimum Radius Decay"] = {
			["minimum radius"] = 1,
		},
		["Lifespan Minimum Velocity Decay"] = {
			["minimum velocity"] = 1,
		},
		["Movement Basic"] = {
			drag = 0,
			gravity = Vector(0,0,0),
			["max constraint passes"] = 3,
		},
		["Movement Dampen Relative to Control Point"] = {
			control_point_number = 0,
			["dampen scale"] = 1,
			["falloff range"] = 100,
		},
		["Movement Lag Compensation"] = {
			["Desired Velocity CP"] = -1,
			["Desired Velocity CP Field Override(for speed only)"] = -1,
			["Latency CP"] = -1,
			["Latency CP field"] = 0,
		},
		["Movement Lock to Bone"] = {
			control_point_number = 0,
			["hitbox set"] = "effects",
			["lifetime fade end"] = 0,
			["lifetime fade start"] = 0,
		},
		["Movement Lock to Control Point"] = {
			control_point_number = 0,
			["distance fade range"] = 0,
			end_fadeout_exponent = 1,
			end_fadeout_max = 1,
			end_fadeout_min = 1,
			["lock rotation"] = false,
			start_fadeout_exponent = 1,
			start_fadeout_max = 1,
			start_fadeout_min = 1,
		},
		["Movement Lock to Saved Position Along Path"] = {
			["Use sequential CP pairs between start and end point"] = false,
			bulge = 0,
			["bulge control 0=random 1=orientation of start pnt 2=orientation of end point"] = 0,
			["end control point number"] = 1,
			["mid point position"] = 0.5,
			["start control point number"] = 0,
		},
		["Movement Maintain Offset"] = {
			["Desired Offset"] = Vector(0,0,0),
			["Local Space CP"] = -1,
			["Scale by Radius"] = false,
		},
		["Movement Maintain Position Along Path"] = {
			bulge = 0,
			["bulge control 0=random 1=orientation of start pnt 2=orientation of end point"] = 0,
			["cohesion strength"] = 1,
			["control point movement tolerance"] = 0,
			["end control point number"] = 0,
			["maximum distance"] = 0,
			["mid point position"] = 0.5,
			["particles to map from start to end"] = 100,
			["restart behavior (0 = bounce, 1 = loop )"] = true,
			["start control point number"] = 0,
			["use existing particle count"] = false,
		},
		["Movement Match Particle Velocities"] = {
			["Control Point to Broadcast Speed and Direction To"] = -1,
			["Direction Matching Strength"] = 0.25,
			["Speed Matching Strength"] = 0.25,
		},
		["Movement Max Velocity"] = {
			["Maximum Velocity"] = 0,
			["Override CP field"] = 0,
			["Override Max Velocity from this CP"] = -1,
		},
		["Movement Place On Ground"] = {
			["CP movement tolerance"] = 32,
			["collision group"] = "NONE",
			["include water"] = false,
			["interploation distance tolerance cp"] = -1,
			["interpolation rate"] = 0,
			["kill on no collision"] = false,
			["max trace length"] = 128,
			offset = 0,
			["reference CP 1"] = -1,
			["reference CP 2"] = -1,
			["trace offset"] = 64,
		},
		["Movement Rotate Particle Around Axis"] = {
			["Control Point"] = 0,
			["Rotation Axis"] = Vector(0,0,1),
			["Rotation Rate"] = 180,
			["Use Local Space"] = false,
		},
		["Noise Scalar"] = {
			additive = false,
			["noise coordinate scale"] = 0.10000000149012,
			["output field"] = 3,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Noise Vector"] = {
			additive = false,
			["noise coordinate scale"] = 0.10000000149012,
			["output field"] = 6,
			["output maximum"] = Vector(1,1,1),
			["output minimum"] = Vector(0,0,0),
		},
		["Normal Lock to Control Point"] = {
			control_point_number = 0,
		},
		["Normalize Vector"] = {
			["output field"] = 0,
			["scale factor"] = 1,
		},
		["Oscillate Scalar"] = {
			["end time max"] = 1,
			["end time min"] = 1,
			["oscillation field"] = 7,
			["oscillation frequency max"] = 1,
			["oscillation frequency min"] = 1,
			["oscillation multiplier"] = 2,
			["oscillation rate max"] = 0,
			["oscillation rate min"] = 0,
			["oscillation start phase"] = 0.5,
			["proportional 0/1"] = true,
			["start time max"] = 0,
			["start time min"] = 0,
			["start/end proportional"] = true,
		},
		["Oscillate Scalar Simple"] = {
			["oscillation field"] = 7,
			["oscillation frequency"] = 1,
			["oscillation multiplier"] = 2,
			["oscillation rate"] = 0,
			["oscillation start phase"] = 0.5,
		},
		["Oscillate Vector"] = {
			["end time max"] = 1,
			["end time min"] = 1,
			["oscillation field"] = 0,
			["oscillation frequency max"] = Vector(1,1,1),
			["oscillation frequency min"] = Vector(1,1,1),
			["oscillation multiplier"] = 2,
			["oscillation rate max"] = Vector(0,0,0),
			["oscillation rate min"] = Vector(0,0,0),
			["oscillation start phase"] = 0.5,
			["proportional 0/1"] = true,
			["start time max"] = 0,
			["start time min"] = 0,
			["start/end proportional"] = true,
		},
		["Oscillate Vector Simple"] = {
			["oscillation field"] = 0,
			["oscillation frequency"] = Vector(1,1,1),
			["oscillation multiplier"] = 2,
			["oscillation rate"] = Vector(0,0,0),
			["oscillation start phase"] = 0.5,
		},
		["Radius Scale"] = {
			ease_in_and_out = false,
			end_time = 1,
			radius_end_scale = 1,
			radius_start_scale = 1,
			scale_bias = 0.5,
			start_time = 0,
		},
		["Ramp Scalar Linear Random"] = {
			["end time max"] = 1,
			["end time min"] = 1,
			["ramp field"] = 3,
			["ramp rate max"] = 0,
			["ramp rate min"] = 0,
			["start time max"] = 0,
			["start time min"] = 0,
			["start/end proportional"] = true,
		},
		["Ramp Scalar Linear Simple"] = {
			["end time"] = 1,
			["ramp field"] = 3,
			["ramp rate"] = 0,
			["start time"] = 0,
		},
		["Ramp Scalar Spline Random"] = {
			bias = 0.5,
			["ease out"] = false,
			["end time max"] = 1,
			["end time min"] = 1,
			["ramp field"] = 3,
			["ramp rate max"] = 0,
			["ramp rate min"] = 0,
			["start time max"] = 0,
			["start time min"] = 0,
			["start/end proportional"] = true,
		},
		["Ramp Scalar Spline Simple"] = {
			["ease out"] = false,
			["end time"] = 1,
			["ramp field"] = 3,
			["ramp rate"] = 0,
			["start time"] = 0,
		},
		["Remap Average Scalar Value to CP"] = {
			["Scalar field"] = 3,
			["input volume maximum"] = 1,
			["input volume minimum"] = 0,
			["output control point"] = 1,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap Control Point Direction to Vector"] = {
			["control point number"] = 0,
			["output field"] = 0,
			["scale factor"] = 1,
		},
		["Remap Control Point to Scalar"] = {
			["emitter lifetime end time (seconds)"] = -1,
			["emitter lifetime start time (seconds)"] = -1,
			["input control point number"] = 0,
			["input field 0-2 X/Y/Z"] = 0,
			["input maximum"] = 1,
			["input minimum"] = 0,
			["output field"] = 3,
			["output is scalar of current value"] = false,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap Control Point to Vector"] = {
			["accelerate position"] = false,
			["emitter lifetime end time (seconds)"] = -1,
			["emitter lifetime start time (seconds)"] = -1,
			["input control point number"] = 0,
			["input maximum"] = Vector(0,0,0),
			["input minimum"] = Vector(0,0,0),
			["local space CP"] = -1,
			["offset position"] = false,
			["output field"] = 0,
			["output is scalar of current value"] = false,
			["output is scalar of initial random range"] = false,
			["output maximum"] = Vector(0,0,0),
			["output minimum"] = Vector(0,0,0),
		},
		["Remap CP Speed to CP"] = {
			["Output field 0-2 X/Y/Z"] = 0,
			["input control point"] = 0,
			["input maximum"] = 1,
			["input minimum"] = 0,
			["output control point"] = -1,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap CP Velocity to Vector"] = {
			["control point"] = 0,
			normalize = false,
			["output field"] = 0,
			["scale factor"] = 1,
		},
		["Remap Difference of Sequential Particle Vector to Scalar"] = {
			["also set ouput to previous particle"] = false,
			["difference maximum"] = 128,
			["difference minimum"] = 0,
			["input field"] = 0,
			["only active within specified difference"] = false,
			["output field"] = 3,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap Direction to CP to Vector"] = {
			["control point"] = 0,
			normalize = false,
			["offset axis"] = Vector(0,0,0),
			["offset rotation"] = 0,
			["output field"] = 0,
			["scale factor"] = 1,
		},
		["Remap Distance Between Two Control Points to CP"] = {
			["LOS Failure Scale"] = 0,
			["LOS collision group"] = "NONE",
			["Maximum Trace Length"] = -1,
			["distance maximum"] = 128,
			["distance minimum"] = 0,
			["ending control point"] = 1,
			["ensure line of sight"] = false,
			["output control point"] = 2,
			["output control point field"] = 0,
			["output maximum"] = 1,
			["output minimum"] = 0,
			["starting control point"] = 0,
		},
		["Remap Distance Between Two Control Points to Scalar"] = {
			["LOS Failure Scalar"] = 0,
			["LOS collision group"] = "NONE",
			["Maximum Trace Length"] = -1,
			["distance maximum"] = 128,
			["distance minimum"] = 0,
			["ending control point"] = 1,
			["ensure line of sight"] = false,
			["output field"] = 3,
			["output is scalar of current value"] = false,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
			["starting control point"] = 0,
		},
		["Remap Distance to Control Point to Scalar"] = {
			["LOS Failure Scalar"] = 0,
			["LOS collision group"] = "NONE",
			["Maximum Trace Length"] = -1,
			["control point"] = 0,
			["distance maximum"] = 128,
			["distance minimum"] = 0,
			["ensure line of sight"] = false,
			["only active within specified distance"] = false,
			["output field"] = 3,
			["output is scalar of current value"] = false,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap Dot Product to Scalar"] = {
			["first input control point"] = 0,
			["input maximum (-1 to 1)"] = 1,
			["input minimum (-1 to 1)"] = 0,
			["only active within specified input range"] = false,
			["output field"] = 3,
			["output is scalar of current value"] = false,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
			["second input control point"] = 0,
			["use particle velocity for first input"] = false,
		},
		["Remap Particle BBox Volume to CP"] = {
			["input volume maximum in cubic units"] = 128,
			["input volume minimum in cubic units"] = 0,
			["output control point"] = -1,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap Percentage Between Two Control Points to Scalar"] = {
			["ending control point"] = 1,
			["only active within input range"] = false,
			["output field"] = 3,
			["output is scalar of current value"] = false,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
			["percentage maximum"] = 1,
			["percentage minimum"] = 0,
			["starting control point"] = 0,
			["treat distance between points as radius"] = true,
		},
		["Remap Percentage Between Two Control Points to Vector"] = {
			["ending control point"] = 1,
			["only active within input range"] = false,
			["output field"] = 6,
			["output is scalar of current value"] = false,
			["output is scalar of initial random range"] = false,
			["output maximum"] = Vector(1,1,1),
			["output minimum"] = Vector(0,0,0),
			["percentage maximum"] = 1,
			["percentage minimum"] = 0,
			["starting control point"] = 0,
			["treat distance between points as radius"] = true,
		},
		["Remap Scalar"] = {
			["input field"] = 7,
			["input maximum"] = 1,
			["input minimum"] = 0,
			["output field"] = 3,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap Speed to Scalar"] = {
			["input maximum"] = 1,
			["input minimum"] = 0,
			["output field"] = 3,
			["output is scalar of current value"] = false,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap Velocity to Vector"] = {
			normalize = false,
			["output field"] = 0,
			["scale factor"] = 1,
		},
		["Restart Effect after Duration"] = {
			["Child Group ID"] = 0,
			["Control Point Field X/Y/Z"] = 0,
			["Control Point to Scale Duration"] = -1,
			["Maximum Restart Time"] = 1,
			["Minimum Restart Time"] = 0,
			["Only Restart Children"] = false,
		},
		["Rotate Vector Random"] = {
			["Normalize Ouput"] = 0,
			["Rotation Axis Max"] = Vector(0,0,1),
			["Rotation Axis Min"] = Vector(0,0,1),
			["Rotation Rate Max"] = 180,
			["Rotation Rate Min"] = 180,
			["output field"] = 21,
		},
		["Rotation Basic"] = {},
		["Rotation Orient Relative to CP"] = {
			["Control Point"] = 0,
			["Rotation Offset"] = 0,
			["Spin Strength"] = 1,
			["rotation field"] = 4,
		},
		["Rotation Orient to 2D Direction"] = {
			["Rotation Offset"] = 0,
			["Spin Strength"] = 1,
			["rotation field"] = 4,
		},
		["Rotation Spin Roll"] = {
			spin_rate_degrees = 0,
			spin_rate_min = 0,
			spin_stop_time = 0,
		},
		["Rotation Spin Yaw"] = {
			yaw_rate_degrees = 0,
			yaw_rate_min = 0,
			yaw_stop_time = 0,
		},
		["Set child control points from particle positions"] = {
			["# of control points to set"] = 1,
			["First control point to set"] = 0,
			["Group ID to affect"] = 0,
			["first particle to copy"] = 0,
			["set orientation"] = false,
		},
		["Set Control Point Positions"] = {
			["Control Point to offset positions from"] = 0,
			["First Control Point Location"] = Vector(128,0,0),
			["First Control Point Number"] = 1,
			["First Control Point Parent"] = 0,
			["Fourth Control Point Location"] = Vector(0,-128,0),
			["Fourth Control Point Number"] = 4,
			["Fourth Control Point Parent"] = 0,
			["Second Control Point Location"] = Vector(0,128,0),
			["Second Control Point Number"] = 2,
			["Second Control Point Parent"] = 0,
			["Set positions in world space"] = false,
			["Third Control Point Location"] = Vector(-128,0,0),
			["Third Control Point Number"] = 3,
			["Third Control Point Parent"] = 0,
		},
		["Set Control Point Rotation"] = {
			["Control Point"] = 0,
			["Local Space Control Point"] = -1,
			["Rotation Axis"] = Vector(0,0,1),
			["Rotation Rate"] = 180,
		},
		["Set Control Point to Impact Point"] = {
			["Control Point to Set"] = 1,
			["Control Point to Trace From"] = 1,
			["Max Trace Length"] = 1024,
			["Offset End Point Amount"] = 0,
			["Trace Direction Override"] = Vector(0,0,0),
			["Trace Update Rate"] = 0.5,
			["trace collision group"] = "NONE",
		},
		["Set Control Point To Particles' Center"] = {
			["Center Offset"] = Vector(0,0,0),
			["Control Point Number to Set"] = 1,
		},
		["Set Control Point To Player"] = {
			["Control Point Number"] = 1,
			["Control Point Offset"] = Vector(0,0,0),
			["Use Eye Orientation"] = false,
		},
		["Set control points from particle positions"] = {
			["# of control points to set"] = 1,
			["First control point to set"] = 0,
			["first particle to copy"] = 0,
			["set orientation"] = false,
		},
		["Set CP Offset to CP Percentage Between Two Control Points"] = {
			["ending control point"] = 1,
			["input control point"] = 3,
			["offset amount"] = Vector(0,0,0),
			["offset control point"] = 2,
			["output control point"] = 4,
			["percentage bias"] = 0.5,
			["percentage maximum"] = 1,
			["percentage minimum"] = 0,
			["starting control point"] = 0,
			["treat distance between points as radius"] = true,
			["treat offset as scale of total distance"] = false,
		},
		["Set CP Orientation to CP Direction"] = {
			["input control point"] = 0,
			["output control point"] = 0,
		},
		["Set per child control point from particle positions"] = {
			["# of children to set"] = 1,
			["Group ID to affect"] = 0,
			["control point to set"] = 0,
			["first particle to copy"] = 0,
			["set orientation"] = false,
		},
		["Stop Effect after Duration"] = {
			["Control Point Field X/Y/Z"] = 0,
			["Control Point to Scale Duration"] = -1,
			["Destroy All Particles Immediately"] = false,
			["Duration at which to Stop"] = 1,
		},
	},
	initializers = {
		_generic = {
			["operator end cap state"] = -1,
			["operator end fadein"] = 0,
			["operator end fadeout"] = 0,
			["operator fade oscillate"] = 0,
			["operator start fadein"] = 0,
			["operator start fadeout"] = 0,
			["operator strength random scale max"] = 1,
			["operator strength random scale min"] = 1,
			["operator strength scale seed"] = 0,
			["operator time offset max"] = 0,
			["operator time offset min"] = 0,
			["operator time offset seed"] = 0,
			["operator time scale max"] = 1,
			["operator time scale min"] = 1,
			["operator time scale seed"] = 0,
			["operator time strength random scale max"] = 1,
		},
		["Alpha Random"] = {
			alpha_max = 255,
			alpha_min = 255,
			alpha_random_exponent = 1,
		},
		["Color Lit Per Particle"] = {
			color1 = Color(255,255,255,255),
			color2 = Color(255,255,255,255),
			["light amplification amount"] = 1,
			["light bias"] = 0,
			["tint blend mode"] = 0,
			["tint clamp max"] = Color(255,255,255,255),
			["tint clamp min"] = Color(0,0,0,0),
		},
		["Color Random"] = {
			color1 = Color(255,255,255,255),
			color2 = Color(255,255,255,255),
			["light amplification amount"] = 1,
			["output field"] = 6,
			["tint blend mode"] = 0,
			["tint clamp max"] = Color(255,255,255,255),
			["tint clamp min"] = Color(0,0,0,0),
			["tint control point"] = 0,
			["tint update movement threshold"] = 32,
			tint_perc = 0,
		},
		["Cull relative to model"] = {
			control_point_number = 0,
			["cull outside instead of inside"] = false,
			["hitbox set"] = "effects",
			["use only bounding box"] = false,
		},
		["Cull relative to Ray Trace Environment"] = {
			["cull normal"] = Vector(0,0,0),
			["cull on miss"] = false,
			["ray trace environment name"] = "PRECIPITATION",
			["test direction"] = Vector(0,0,1),
			["use velocity for test direction"] = false,
			["velocity test adjust lifespan"] = false,
		},
		["Inherit Initial Value From Parent Particle"] = {
			["Inherited Field"] = 3,
			["Particle Increment Amount"] = 1,
			["Random Parent Particle Distribution"] = false,
			Scale = 1,
		},
		["Lifetime From Sequence"] = {
			["Frames Per Second"] = 30,
		},
		["Lifetime from Time to Impact"] = {
			["bias distance"] = Vector(1,1,1),
			["collide with water"] = true,
			["maximum points to cache"] = 16,
			["maximum trace length"] = 1024,
			["trace collision group"] = "NONE",
			["trace offset"] = 0,
			["trace recycle tolerance"] = 64,
		},
		["Lifetime Pre-Age Noise"] = {
			["absolute value"] = false,
			["invert absolute value"] = false,
			["spatial coordinate offset"] = Vector(0,0,0),
			["spatial noise coordinate scale"] = 1,
			["start age maximum"] = 1,
			["start age minimum"] = 0,
			["time coordinate offset"] = 0,
			["time noise coordinate scale"] = 1,
		},
		["Lifetime Random"] = {
			lifetime_max = 0,
			lifetime_min = 0,
			lifetime_random_exponent = 1,
		},
		["Move Particles Between 2 Control Points"] = {
			["bias lifetime by trail length"] = false,
			["end control point"] = 1,
			["end offset"] = 0,
			["end spread"] = 0,
			["maximum speed"] = 1,
			["minimum speed"] = 1,
			["start offset"] = 0,
		},
		["Normal Align to CP"] = {
			control_point_number = 0,
		},
		["Normal Modify Offset Random"] = {
			control_point_number = 0,
			["normalize output 0/1"] = false,
			["offset in local space 0/1"] = false,
			["offset max"] = Vector(0,0,0),
			["offset min"] = Vector(0,0,0),
		},
		["Offset Vector to Vector"] = {
			["input field"] = 0,
			["output field"] = 0,
			["output offset maximum"] = Vector(1,1,1),
			["output offset minimum"] = Vector(0,0,0),
		},
		["Position Along Epitrochoid"] = {
			["control point number"] = 0,
			["first dimension 0-2 (-1 disables)"] = 0,
			["local space"] = false,
			["offset from existing position"] = false,
			["particle density"] = 10,
			["point offset"] = 4,
			["radius 1"] = 40,
			["radius 2"] = 24,
			["scale from conrol point (radius 1/radius 2/offset)"] = -1,
			["second dimension 0-2 (-1 disables)"] = 1,
			["use particle count instead of creation time"] = false,
		},
		["Position Along Path Random"] = {
			bulge = 0,
			["bulge control 0=random 1=orientation of start pnt 2=orientation of end point"] = 0,
			["end control point number"] = 0,
			["maximum distance"] = 0,
			["mid point position"] = 0.5,
			["randomly select sequential CP pairs between start and end points"] = false,
			["start control point number"] = 0,
		},
		["Position Along Path Sequential"] = {
			["Save Offset"] = false,
			["Use sequential CP pairs between start and end point"] = false,
			bulge = 0,
			["bulge control 0=random 1=orientation of start pnt 2=orientation of end point"] = 0,
			["end control point number"] = 0,
			["maximum distance"] = 0,
			["mid point position"] = 0.5,
			["particles to map from start to end"] = 100,
			["restart behavior (0 = bounce, 1 = loop )"] = true,
			["start control point number"] = 0,
		},
		["Position Along Ring"] = {
			["Override CP (X/Y/Z *= Radius/Thickness/Speed)"] = -1,
			["Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)"] = -1,
			["XY velocity only"] = true,
			["control point number"] = 0,
			["even distribution"] = false,
			["even distribution count"] = -1,
			["initial radius"] = 0,
			["max initial speed"] = 0,
			["min initial speed"] = 0,
			pitch = 0,
			roll = 0,
			thickness = 0,
			yaw = 0,
		},
		["Position From Chaotic Attractor"] = {
			["Pickover A Parameter"] = -0.96296292543411,
			["Pickover B Parameter"] = 2.7911388874054,
			["Pickover C Parameter"] = 1.8518518209457,
			["Pickover D Parameter"] = 1.5,
			["Relative Control point number"] = 0,
			Scale = 1,
			["Speed Max"] = 0,
			["Speed Min"] = 0,
			["Uniform speed"] = false,
		},
		["Position from Parent Cache"] = {
			["Local Offset Max"] = Vector(0,0,0),
			["Local Offset Min"] = Vector(0,0,0),
			["Set Normal"] = false,
		},
		["Position From Parent Particles"] = {
			["Inherited Velocity Scale"] = 0,
			["Particle Increment Amount"] = 1,
			["Random Parent Particle Distribution"] = false,
		},
		["Position In CP Hierarchy"] = {
			bulge = 0,
			["bulge control 0=random 1=orientation of start pnt 2=orientation of end point"] = 0,
			distance_bias = Vector(1,1,1),
			distance_bias_absolute_value = Vector(0,0,0),
			["end control point number"] = 1,
			["growth time"] = 0,
			["maximum distance"] = 0,
			["mid point position"] = 0.5,
			["start control point number"] = 0,
			["use highest supplied end point"] = false,
		},
		["Position Modify Offset Random"] = {
			control_point_number = 0,
			["offset in local space 0/1"] = false,
			["offset max"] = Vector(0,0,0),
			["offset min"] = Vector(0,0,0),
			["offset proportional to radius 0/1"] = false,
		},
		["Position Modify Place On Ground"] = {
			["collision group"] = "NONE",
			["include water"] = false,
			["kill on no collision"] = false,
			["max trace length"] = 128,
			offset = 0,
			["set normal"] = false,
		},
		["Position Modify Warp Random"] = {
			["control point number"] = 0,
			["reverse warp (0/1)"] = false,
			["use particle count instead of time"] = false,
			["warp max"] = Vector(1,1,1),
			["warp min"] = Vector(1,1,1),
			["warp transition start time"] = 0,
			["warp transition time (treats min/max as start/end sizes)"] = 0,
		},
		["Position on Model Random"] = {
			control_point_number = 0,
			["desired hitbox"] = -1,
			["direction bias"] = Vector(0,0,0),
			["force to be inside model"] = 0,
			["hitbox set"] = "effects",
			["model hitbox scale"] = 1,
		},
		["Position Within Box Random"] = {
			["control point number"] = 0,
			max = Vector(0,0,0),
			min = Vector(0,0,0),
			["use local space"] = false,
		},
		["Position Within Sphere Random"] = {
			["bias in local system"] = false,
			control_point_number = 0,
			["create in model"] = 0,
			distance_bias = Vector(1,1,1),
			distance_bias_absolute_value = Vector(0,0,0),
			distance_max = 0,
			distance_min = 0,
			["randomly distribute to highest supplied Control Point"] = false,
			["randomly distribution growth time"] = 0,
			["scale cp (distance/speed/local speed)"] = -1,
			speed_in_local_coordinate_system_max = Vector(0,0,0),
			speed_in_local_coordinate_system_min = Vector(0,0,0),
			speed_max = 0,
			speed_min = 0,
			speed_random_exponent = 1,
		},
		["Radius Random"] = {
			radius_max = 1,
			radius_min = 1,
			radius_random_exponent = 1,
		},
		["Remap Control Point to Scalar"] = {
			["emitter lifetime end time (seconds)"] = -1,
			["emitter lifetime start time (seconds)"] = -1,
			["input control point number"] = 0,
			["input field 0-2 X/Y/Z"] = 0,
			["input maximum"] = 1,
			["input minimum"] = 0,
			["output field"] = 3,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap Control Point to Vector"] = {
			["accelerate position"] = false,
			["emitter lifetime end time (seconds)"] = -1,
			["emitter lifetime start time (seconds)"] = -1,
			["input control point number"] = 0,
			["input maximum"] = Vector(0,0,0),
			["input minimum"] = Vector(0,0,0),
			["local space CP"] = -1,
			["offset position"] = false,
			["output field"] = 0,
			["output is scalar of initial random range"] = false,
			["output maximum"] = Vector(0,0,0),
			["output minimum"] = Vector(0,0,0),
		},
		["Remap CP Orientation to Rotation"] = {
			axis = 0,
			["control point"] = 0,
			["offset rotation"] = 0,
			["rotation field"] = 0,
		},
		["Remap Initial Direction to CP to Vector"] = {
			["control point"] = 0,
			normalize = false,
			["offset axis"] = Vector(0,0,0),
			["offset rotation"] = 0,
			["output field"] = 0,
			["scale factor"] = 1,
		},
		["Remap Initial Distance to Control Point to Scalar"] = {
			["LOS Failure Scalar"] = 0,
			["LOS collision group"] = "NONE",
			["Maximum Trace Length"] = -1,
			["control point"] = 0,
			["distance maximum"] = 128,
			["distance minimum"] = 0,
			["ensure line of sight"] = false,
			["only active within specified distance"] = false,
			["output field"] = 3,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap Initial Scalar"] = {
			["emitter lifetime end time (seconds)"] = -1,
			["emitter lifetime start time (seconds)"] = -1,
			["input field"] = 8,
			["input maximum"] = 1,
			["input minimum"] = 0,
			["only active within specified input range"] = false,
			["output field"] = 3,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap Noise to Scalar"] = {
			["absolute value"] = false,
			["invert absolute value"] = false,
			["output field"] = 3,
			["output maximum"] = 1,
			["output minimum"] = 0,
			["spatial coordinate offset"] = Vector(0,0,0),
			["spatial noise coordinate scale"] = 0.0010000000474975,
			["time coordinate offset"] = 0,
			["time noise coordinate scale"] = 0.10000000149012,
			["world time noise coordinate scale"] = 0,
		},
		["Remap Particle Count to Scalar"] = {
			["input maximum"] = 10,
			["input minimum"] = 0,
			["only active within specified input range"] = false,
			["output field"] = 3,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
		},
		["Remap Scalar to Vector"] = {
			control_point_number = 0,
			["emitter lifetime end time (seconds)"] = -1,
			["emitter lifetime start time (seconds)"] = -1,
			["input field"] = 8,
			["input maximum"] = 1,
			["input minimum"] = 0,
			["output field"] = 0,
			["output is scalar of initial random range"] = false,
			["output maximum"] = Vector(1,1,1),
			["output minimum"] = Vector(0,0,0),
			["use local system"] = true,
		},
		["Remap Speed to Scalar"] = {
			["control point number (ignored if per particle)"] = 0,
			["emitter lifetime end time (seconds)"] = -1,
			["emitter lifetime start time (seconds)"] = -1,
			["input maximum"] = 1,
			["input minimum"] = 0,
			["output field"] = 3,
			["output is scalar of initial random range"] = false,
			["output maximum"] = 1,
			["output minimum"] = 0,
			["per particle"] = false,
		},
		["Rotation Random"] = {
			randomly_flip_direction = false,
			rotation_initial = 0,
			rotation_offset_max = 360,
			rotation_offset_min = 0,
			rotation_random_exponent = 1,
		},
		["Rotation Speed Random"] = {
			randomly_flip_direction = false,
			rotation_speed_constant = 0,
			rotation_speed_random_exponent = 1,
			rotation_speed_random_max = 360,
			rotation_speed_random_min = 0,
		},
		["Rotation Yaw Flip Random"] = {
			["Flip Percentage"] = 0.5,
		},
		["Rotation Yaw Random"] = {
			yaw_initial = 0,
			yaw_offset_max = 360,
			yaw_offset_min = 0,
			yaw_random_exponent = 1,
		},
		["Scalar Random"] = {
			exponent = 1,
			max = 0,
			min = 0,
			["output field"] = 3,
		},
		["Sequence From Control Point"] = {
			["control point"] = 1,
			["offset propotional to radius"] = false,
			["per particle spatial offset"] = Vector(0,0,0),
		},
		["Sequence Random"] = {
			linear = false,
			sequence_max = 0,
			sequence_min = 0,
			shuffle = false,
		},
		["Sequence Two Random"] = {
			sequence_max = 0,
			sequence_min = 0,
		},
		["Set Hitbox Position on Model"] = {
			control_point_number = 0,
			["desired hitbox"] = -1,
			["direction bias"] = Vector(0,0,0),
			["force to be inside model"] = 0,
			["hitbox set"] = "effects",
			["maintain existing hitbox"] = false,
			["model hitbox scale"] = 1,
		},
		["Set Hitbox to Closest Hitbox"] = {
			control_point_number = 0,
			["desired hitbox"] = -1,
			["hitbox set"] = "effects",
			["model hitbox scale"] = 1,
		},
		["Trail Length Random"] = {
			length_max = 0.10000000149012,
			length_min = 0.10000000149012,
			length_random_exponent = 1,
		},
		["Vector Component Random"] = {
			["component 0/1/2 X/Y/Z"] = 0,
			max = 0,
			min = 0,
			["output field"] = 0,
		},
		["Vector Random"] = {
			max = Vector(0,0,0),
			min = Vector(0,0,0),
			["output field"] = 0,
		},
		["Velocity Inherit from Control Point"] = {
			["control point number"] = 0,
			["velocity scale"] = 1,
		},
		["Velocity Noise"] = {
			["Absolute Value"] = Vector(0,0,0),
			["Apply Velocity in Local Space (0/1)"] = false,
			["Control Point Number"] = 0,
			["Invert Abs Value"] = Vector(0,0,0),
			["Spatial Coordinate Offset"] = Vector(0,0,0),
			["Spatial Noise Coordinate Scale"] = 0.0099999997764826,
			["Time Coordinate Offset"] = 0,
			["Time Noise Coordinate Scale"] = 1,
			["output maximum"] = Vector(1,1,1),
			["output minimum"] = Vector(0,0,0),
		},
		["Velocity Random"] = {
			control_point_number = 0,
			random_speed_max = 0,
			random_speed_min = 0,
			speed_in_local_coordinate_system_max = Vector(0,0,0),
			speed_in_local_coordinate_system_min = Vector(0,0,0),
		},
		["Velocity Repulse from World"] = {
			["Child Group ID to affect"] = 0,
			["Inherit from Parent"] = false,
			["Offset instead of accelerate"] = false,
			["Offset proportional to radius 0/1"] = false,
			["Per Particle World Collision Tests"] = false,
			["Trace Length"] = 64,
			["Use radius for Per Particle Trace Length"] = false,
			["collision group"] = "NONE",
			["control points to broadcast to children (n + 1)"] = -1,
			control_point_number = 0,
			["maximum velocity"] = Vector(1,1,1),
			["minimum velocity"] = Vector(0,0,0),
		},
		["Velocity Set from Control Point"] = {
			["comparison control point number"] = -1,
			["control point number"] = 0,
			["direction only"] = false,
			["local space control point number"] = -1,
			["velocity scale"] = 1,
		},
	},
	emitters = {
		_generic = {
			["operator end cap state"] = -1,
			["operator end fadein"] = 0,
			["operator end fadeout"] = 0,
			["operator fade oscillate"] = 0,
			["operator start fadein"] = 0,
			["operator start fadeout"] = 0,
			["operator strength random scale max"] = 1,
			["operator strength random scale min"] = 1,
			["operator strength scale seed"] = 0,
			["operator time offset max"] = 0,
			["operator time offset min"] = 0,
			["operator time offset seed"] = 0,
			["operator time scale max"] = 1,
			["operator time scale min"] = 1,
			["operator time scale seed"] = 0,
			["operator time strength random scale max"] = 1,
		},
		["emit noise"] = {
			["absolute value"] = false,
			["emission maximum"] = 100,
			["emission minimum"] = 0,
			emission_duration = 0,
			emission_start_time = 0,
			["invert absolute value"] = false,
			["scale emission to used control points"] = 0,
			["time coordinate offset"] = 0,
			["time noise coordinate scale"] = 0.10000000149012,
			["world time noise coordinate scale"] = 0,
		},
		["emit to maintain count"] = {
			["count to maintain"] = 100,
			["emission start time"] = 0,
			["maintain count scale control point"] = -1,
			["maintain count scale control point field"] = 0,
		},
		emit_continuously = {
			["emission count scale control point"] = -1,
			["emission count scale control point field"] = 0,
			emission_duration = 0,
			emission_rate = 100,
			emission_start_time = 0,
			["scale emission to used control points"] = 0,
			["use parent particles for emission scaling"] = false,
		},
		emit_instantaneously = {
			["emission count scale control point"] = -1,
			["emission count scale control point field"] = 0,
			emission_start_time = 0,
			["emission_start_time max"] = -1,
			["maximum emission per frame"] = -1,
			num_to_emit = 100,
			num_to_emit_minimum = -1,
		},
	},
	forces = {
		_generic = {
			["operator end cap state"] = -1,
			["operator end fadein"] = 0,
			["operator end fadeout"] = 0,
			["operator fade oscillate"] = 0,
			["operator start fadein"] = 0,
			["operator start fadeout"] = 0,
			["operator strength random scale max"] = 1,
			["operator strength random scale min"] = 1,
			["operator strength scale seed"] = 0,
			["operator time offset max"] = 0,
			["operator time offset min"] = 0,
			["operator time offset seed"] = 0,
			["operator time scale max"] = 1,
			["operator time scale min"] = 1,
			["operator time scale seed"] = 0,
			["operator time strength random scale max"] = 1,
		},
		["Create vortices from parent particles"] = {
			["amount of force"] = 0,
			["flip twist axis with yaw"] = false,
			["twist axis"] = Vector(0,0,1),
		},
		["Force based on distance from plane"] = {
			["Control point number"] = 0,
			Exponent = 1,
			["Force at Max distance"] = Vector(0,0,0),
			["Force at Min distance"] = Vector(0,0,0),
			["Max Distance from plane"] = 1,
			["Min distance from plane"] = 0,
			["Plane Normal"] = Vector(0,0,1),
		},
		["Pull towards control point"] = {
			["amount of force"] = 0,
			["control point number"] = 0,
			["falloff power"] = 2,
		},
		["random force"] = {
			["max force"] = Vector(0,0,0),
			["min force"] = Vector(0,0,0),
		},
		["time varying force"] = {
			["ending force"] = Vector(0,0,0),
			["starting force"] = Vector(0,0,0),
			["time to end transition"] = 10,
			["time to start transition"] = 0,
		},
		["turbulent force"] = {
			["Noise amount 0"] = Vector(1,1,1),
			["Noise amount 1"] = Vector(0.5,0.5,0.5),
			["Noise amount 2"] = Vector(0.25,0.25,0.25),
			["Noise amount 3"] = Vector(0.125,0.125,0.125),
			["Noise scale 0"] = 1,
			["Noise scale 1"] = 0,
			["Noise scale 2"] = 0,
			["Noise scale 3"] = 0,
		},
		["twist around axis"] = {
			["amount of force"] = 0,
			["object local space axis 0/1"] = false,
			["twist axis"] = Vector(0,0,1),
		},
	},
	constraints = {
		_generic = {
			["operator end cap state"] = -1,
			["operator end fadein"] = 0,
			["operator end fadeout"] = 0,
			["operator fade oscillate"] = 0,
			["operator start fadein"] = 0,
			["operator start fadeout"] = 0,
			["operator strength random scale max"] = 1,
			["operator strength random scale min"] = 1,
			["operator strength scale seed"] = 0,
			["operator time offset max"] = 0,
			["operator time offset min"] = 0,
			["operator time offset seed"] = 0,
			["operator time scale max"] = 1,
			["operator time scale min"] = 1,
			["operator time scale seed"] = 0,
			["operator time strength random scale max"] = 1,
		},
		["Collision via traces"] = {
			["Confirm Collision"] = false,
			["amount of bounce"] = 0,
			["amount of slide"] = 0,
			["brush only"] = false,
			["collision group"] = "NONE",
			["collision mode"] = 0,
			["control point movement distance tolerance"] = 5,
			["control point offset for fast collisions"] = Vector(0,0,0),
			["kill particle on collision"] = false,
			["minimum speed to kill on collision"] = -1,
			["radius scale"] = 1,
			["trace accuracy tolerance"] = 24,
		},
		["Constrain distance to control point"] = {
			["control point number"] = 0,
			["global center point"] = false,
			["maximum distance"] = 100,
			["minimum distance"] = 0,
			["offset of center"] = Vector(0,0,0),
		},
		["Constrain distance to path between two control points"] = {
			["bulge control 0=random 1=orientation of start pnt 2=orientation of end point"] = 0,
			["end control point number"] = 0,
			["maximum distance"] = 100,
			["maximum distance end"] = -1,
			["maximum distance middle"] = -1,
			["mid point position"] = 0.5,
			["minimum distance"] = 0,
			["random bulge"] = 0,
			["start control point number"] = 0,
			["travel time"] = 10,
		},
		["Constrain particles to a box"] = {
			["max coords"] = Vector(0,0,0),
			["min coords"] = Vector(0,0,0),
		},
		["Prevent passing through a plane"] = {
			["control point number"] = 0,
			["global normal"] = false,
			["global origin"] = false,
			["plane normal"] = Vector(0,0,1),
			["plane point"] = Vector(0,0,0),
		},
		["Prevent passing through static part of world"] = {},
	},
}
local tab = {}
for k, v in pairs (defs) do
	tab[k] = {}
	if k != "_main" then
		for k2, v2 in pairs (v) do
			tab[k][string.lower(k2)] = v2
		end
	else
		tab[k] = v
	end
end
defs = tab
tab = nil

//the above table is generated by creating a test effect with default values, and then using the function below to output a lua-readable version of its contents,
//i.e. PrintTable(PEPlus_ReadPCF("particles/test.pcf")["test"} - make sure to set sv_peplus_cachereadpcf 0 so that the json bug doesn't turn color objects into normal tables
--[[local function PrintTable( t, indent, done ) //edited PrintTable that outputs a correctly formatted lua table we can paste into code
	local Msg = Msg

	done = done or {}
	indent = indent or 0
	local keys = table.GetKeys( t )

	table.sort( keys, function( a, b )
		if ( isnumber( a ) and isnumber( b ) ) then return a < b end
		return tostring( a ) < tostring( b )
	end )

	done[ t ] = true

	for i = 1, #keys do
		local key = keys[ i ]
		if key == "functionName" then continue end
		local value = t[ key ]
		if istable(value) and value.functionName then
			key = value.functionName
		end
		if !(type(key) == "string" and !string.find(key, " ", nil, true)) then
			key = ( type( key ) == "string" ) and "[\"" .. key .. "\"]" || "[" .. tostring( key ) .. "]"
		end
		Msg( string.rep( "\t", indent ) )

		if IsColor(value) then
			Msg( key, " = Color(", value.r, ",", value.g, ",", value.b, ",", value.a, "),\n")
		elseif (istable(value) and !done[value]) then
			done[ value ] = true
			Msg( key, " = {\n" )
			PrintTable ( value, indent + 1, done )
			done[ value ] = nil

			Msg( string.rep( "\t", indent ) )
			Msg("},\n")
		elseif isvector(value) then
			Msg( key, " = Vector(", value.x, ",", value.y, ",", value.z, "),\n")
		elseif isstring(value) then
			Msg(key, " = \"", value, "\",\n")
		else
			Msg( key, " = ", value, ",\n" )
		end
	end
end]]


//adapted from the only good glua file parser code i could find on github; we use this to read strings from binary files (https://github.com/RaphaelIT7/gmod-lua-gma-writer/blob/master/gma.lua#L202)
//returns all data from the point we start reading, up to (but not including) the terminating character
local str_b0 = string.char(0)
local function ReadUntilNull(f, endtoken, len)
	//optional endtoken arg to look for some other arbitrary ending character; otherwise look for str_b0
	if len == nil then
		len = endtoken
		endtoken = str_b0
	end

	local pos = f:Tell()
	local str = f:Read(len)
	if str then
		local found, found_end = string.find(str, endtoken)
		if found then
			str = string.sub(str, 0, found - 1)
			f:Seek(pos + found_end)
			return str
		end
	end

	//either f:Read returned nil or we couldn't find the terminating character within it, abort
	f:Seek(pos)
	return
end

//this is an emulation of valve's ParseToken func (https://github.com/nillerusr/Kisak-Strike/blob/master/public/tier1/utlbuffer.h#L301), used to read file headers and keyvalues2 data
//grabs all text between, but not including a starting delimiter and an ending delimiter (the first ones it finds from the point we start reading)
local function ParseToken(f, starttoken, endtoken, len)
	local pos = f:Tell()
	local str = f:Read(len)
	if str then
		local _, found1_end = string.find(str, starttoken, nil, true)
		if found1_end then
			local found2, found2_end = string.find(str, endtoken, nil, true)
			if found2 then
				str = string.sub(str, found1_end + 1, found2 - 1)
				f:Seek(pos + found2_end)
				return str
			end
		end
	end

	//either f:Read returned nil or we couldn't find the starting or ending delimiter within it, abort
	f:Seek(pos)
	return
end


//reference:
//https://developer.valvesoftware.com/wiki/PCF, https://developer.valvesoftware.com/w/index.php?title=DMX/Binary&oldid=176216#Version_3, https://developer.valvesoftware.com/wiki/DMX/Binary

local cache_version = "1" //update this in case ReadPCF is updated post-release to return a different table
local docache = GetConVar("sv_peplus_cachereadpcf")

function PEPlus_ReadPCF(filename, path)

	local function RestoreDefaultValues(tab)
		for p, ptab in pairs (tab) do
			for k, v in pairs (ptab) do
				if defs[k] then
					for k2, op in pairs (v) do
						//fill in any default values that are missing from the operator
						if defs[k][op.functionName] then
							for k3, v3 in pairs (defs[k][op.functionName]) do
								if op[k3] == nil then tab[p][k][k2][k3] = v3 end
							end
						end
						for k3, v3 in pairs (defs[k]._generic) do
							if op[k3] == nil then tab[p][k][k2][k3] = v3 end
						end
					end
				end
			end
			//Fill in any default values that are missing from the main table
			for k, v in pairs (defs._main) do
				if ptab[k] == nil then
					tab[p][k] = v
				end
			end
		end
		//PrintTable(tab)
	end
	local function store_nodefs(tab)
		//Store a leaner table without default values - this gets used by PEPlus_GetDuplicateFx()
		//This is a good place to do this because it means we don't have to read the file a second time to populate this
		if CLIENT and !path then
			PEPlus_NoDefPCFs[filename] = table.Copy(tab)
		end
	end

	//don't print non-critical messages unless we're in developer mode; 
	//always print messages for bugs that player should report
	local dodebug = (GetConVarNumber("developer") >= 1)

	local checksum
	if docache:GetBool() then
		//If possible, load the results of this function from cache instead. This makes PEPlus_ReadAndProcessPCFs 2-3x faster on all subsequent
		//startups (compared to without caching), but makes the very first load quite a bit slower as we save the files to the cache, and also adds
		//approx. 50MB to the data folder (because of how BIG tf2's pcfs are!).
		checksum = file.Read(filename, path or "GAME")
		if !checksum then MsgN("PEPlus_ReadPCF: ", filename, " (", path or "GAME", ") can't be read, report this bug!") return end
		checksum = util.SHA256(checksum) //if the pcf file is updated, then the checksum will be different; this stops us from loading outdated data
		local cached_file = file.Read("peplus_cache_v" .. cache_version ..  "/" .. filename .. "/" .. checksum .. ".txt", "DATA")
		if cached_file then
			//"true" arg below stops it from converting all table keys from strings to numbers where possible.
			//this prevents edge cases where an effect just named a number can get converted into a bad name, and doesn't 
			//*seem* to cause any issues with sequential subtables like operator lists, but keep an eye on this just in case.
			cached_file = util.JSONToTable(cached_file, false, true)
			//PrintTable(cached_file)
			if cached_file then
				store_nodefs(cached_file)
				RestoreDefaultValues(cached_file) //saved cache files omit all default values to save space and read time, so repopulate those
				if GetConVarNumber("developer") >= 2 then MsgN("PEPlus_ReadPCF: ", filename, " loading from cache") end //this is really spammy, gate it behind developer 2
				return cached_file
			end
		end
	end

	local f = file.Open(filename, "rb", path or "GAME")
	if !f then MsgN("PEPlus_ReadPCF: ", filename, " (", path or "GAME", ") can't be opened, report this bug!") return end
	//path arg is only used by PEPlus_GetPCFConflicts, don't worry about it past this point

	//If the pcf is packed into the current map, then write a copy of it into the data folder and read that instead.
	//This is necessary because performing read operations on packed files takes a very long time (only if the map file is compressed, but we don't have 
	//a way to check for that); pd_watergate's *7* packed pcfs add *10 whole minutes* to the load time if we don't cache them like this!
	if file.Exists(filename, "BSP") then
		if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " is packed into the current BSP file, caching") end
		if file.Write("temp_peplus_readpcfcache.txt", f:Read()) then
			f = file.Open("temp_peplus_readpcfcache.txt", "rb", "DATA")
			if !f then MsgN("PEPlus_ReadPCF: ", filename, " cache was written, but can't be read; report this bug!") return end
		else
			MsgN("PEPlus_ReadPCF: ", filename, " was unable to be cached; report this bug!")
			return
		end
	end
	//we *could* run file.Delete("temp_peplus_readpcfcache.txt", "DATA") after we're done with it, but that doesn't seem necessary; 
	//there's only ever one of these files at a time and they're not that big, it'd just be another write operation on the user's HD for no benefit

	local header = ParseToken(f, "<!-- dmx encoding", " -->", 40 + 2 * 64) //max length from code (https://github.com/nillerusr/Kisak-Strike/blob/master/datamodel/datamodel.cpp#L1054-L1055, defined in https://github.com/nillerusr/Kisak-Strike/blob/master/public/datamodel/dmxheader.h#L28)
	if !header then
		if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " couldn't get file header, ignoring") end
		return
	end
	header = string.Explode(" ", string.Trim(header))
	//PrintTable(header)
	if #header != 5 or header[3] != "format" then
		if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " has unsupported file header ", table.concat(header, " "), ", ignoring") end
		return
	end
	//information about headers:
	//the header is formatted as "dmx encoding (encoding type) (encoding version) format (format type) (format version)", for example, "dmx encoding binary 2 format pcf 1".
	//encoding types:
	//binary 1: not used by any pcfs i can find, but exists according to source code and docs; not supporting this until i can find a pcf using it (https://developer.valvesoftware.com/wiki/DMX/Binary)
	//binary 2: used by all orangebox pcfs and pcfs saved with gmod's particle editor; adds string dictionary
	//binary 3: used by a few unused portal 2 pcfs (zombie.pcf, paint_fizzler.pcf, chicken.pcf) and reportedly l4d1 pcfs; according to source code and documentation, this overrides one attribute data type from "OBJECTID" to "TIME", but as far as i can tell, neither are used in pcfs (https://github.com/nillerusr/Kisak-Strike/blob/master/datamodel/dmserializerbinary.cpp#L456-L462, https://developer.valvesoftware.com/wiki/DMX/Binary#Attribute_Values)
	//binary 4: used by all(?) l4d2 pcfs; string dictionary count is now an int instead of a short, element names and non-array string attributes are now stored in the string dictionary instead of using a null-terminated in-line string
	//binary 5: used by most portal 2 pcfs and all(?) alien swarm pcfs; string dictionary indices are now ints instead of shorts
	//keyvalues2 1: used by bladesymphony pcfs and reportedly Source Particle Benchmark; these are NOT stored as binary data and are instead plain text, which means they require a different parser; according to code, no other versions of keyvalues2 exist, so for now we won't check version on these (https://github.com/nillerusr/Kisak-Strike/blob/master/datamodel/dmserializerkeyvalues2.cpp)
	//format types (only included for reference, currently no reason to handle these differently):
	//dmx 1: only used by css's fire_medium_01.pcf and reportedly DoD:S pcfs; no noticeable differences from pcf 1
	//pcf 1: used by all orange box pcfs and portal2's clouds.pcf
	//pcf 2: used by all other portal2 pcfs, l4d2 pcfs, and swarm pcfs; as far as i can tell, all the ones that exclude all default values use pcf 2, but so do bladesymphony pcfs that *don't* exclude default values, so who knows??

	local result = {}
	if header[1] == "binary" then

		local version = tonumber(header[2])
		if version < 2 or version > 5 then
			if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " has unsupported pcf format ", table.concat(header, " "), ", ignoring") end
			return
		end
		f:Skip(2) //skip the newline char and then the null terminating char after the header

		local nStrings
		if version <= 3 then
			nStrings = f:ReadUShort() //this is a short in DMX version 2 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
		else
			nStrings = f:ReadULong() //this is an int in both version 4 and 5 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions / https://developer.valvesoftware.com/w/index.php?title=DMX/Binary&oldid=176216#Version_3
		end
		local StringDict = {}
		//MsgN(filename, " nStrings = ", nStrings)
		for k = 0, nStrings - 1 do
			local v = ReadUntilNull(f, 2048) //max length from code (https://github.com/nillerusr/Kisak-Strike/blob/master/datamodel/dmserializerbinary.cpp#L596-L605)
			StringDict[k] = v
		end
		//PrintTable(StringDict)


		local nElements = f:ReadULong() //int
		//MsgN(filename, " nElements = ", nElements)

		local function DmeHeader()
			local tab = {}
			if version <= 3 then
				tab.Type = StringDict[f:ReadUShort()] //string dictionary indices are shorts in DMX version 2 https://developer.valvesoftware.com/wiki/DMX/Binary#Previous_versions
				tab.Name = ReadUntilNull(f, 2048) //element names are null-terminated strings in DMX version 2 https://developer.valvesoftware.com/w/index.php?title=DMX/Binary&oldid=176216#Version_3; max length from code (https://github.com/nillerusr/Kisak-Strike/blob/master/datamodel/dmserializerbinary.cpp#L672)
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
			local at = f:ReadByte()
			//MsgN("at ", at, " = ", a[at])
			at = a[at] or ""
			tab.AttributeType = at
			local function DoAttribute(is_array)
				//MsgN("at = ", at)
				if at == "element" then //AT_ELEMENT
					return f:ReadLong()
				elseif at == "int" then //AT_INT
					return f:ReadLong()
				elseif at == "float" then //AT_FLOAT
					return f:ReadFloat()
				elseif at == "bool" then //AT_BOOL
					return f:ReadBool()
				elseif at == "string" then //AT_STRING
					if version <= 3 or is_array then //in higher versions, arrays of strings still use null-terminated strings instead of being stored in the string dictionary
						return ReadUntilNull(f, 1024) //i think this is the correct max length value from code; it calls a separate unserialize func for the string that i can't find, but beforehand it defines a string object of this length to put the value into (https://github.com/nillerusr/Kisak-Strike/blob/master/datamodel/dmserializerbinary.cpp#L429)
					elseif version == 4 then
						return StringDict[f:ReadUShort()] //this is a short in version 4 (https://developer.valvesoftware.com/wiki/PCF#Element_Dictionary), which matches the headers
					elseif version == 5 then
						return StringDict[f:ReadULong()]
					end
				elseif at == "binary" then //AT_VOID
					local count = f:ReadULong()
					return f:Read(count)
				elseif at == "time" then //AT_TIME
					return f:ReadLong() / 10000 //according to https://developer.valvesoftware.com/wiki/PCF; TODO: should this be unsigned? can't find anything that uses this to check
				elseif at == "color" then //AT_COLOR
					return Color(string.byte(f:Read(1)), string.byte(f:Read(1)), string.byte(f:Read(1)), string.byte(f:Read(1)))
				elseif at == "vector2" then //AT_VECTOR2
					return {f:ReadFloat(), f:ReadFloat()}
				elseif at == "vector3" then //AT_VECTOR3
					return Vector(f:ReadFloat(), f:ReadFloat(), f:ReadFloat())
				elseif at == "vector4" then //AT_VECTOR4
					return {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()}
				elseif at == "qangle" then //AT_QANGLE
					return Vector(f:ReadFloat(), f:ReadFloat(), f:ReadFloat()) //"Same as ATTRIBUTE_VECTOR3" according to https://developer.valvesoftware.com/wiki/PCF
				elseif at == "quaternion" then //AT_QUATERNION
					return {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()} //"Same as ATTRIBUTE_VECTOR4" according to https://developer.valvesoftware.com/wiki/PCF
				elseif at == "matrix" then //AT_VMATRIX
					return Matrix({ {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()}, {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()},
							{f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()}, {f:ReadFloat(), f:ReadFloat(), f:ReadFloat(), f:ReadFloat()} })
				elseif string.EndsWith(at, "_array") then
					at = string.Replace(at, "_array", "")
					local tab2 = {}
					local arraysize = f:ReadULong() //int, is ReadULong the right way to interpret this?
					if arraysize > 1000 then MsgN("PEPlus_ReadPCF: ", filename, " got crazy array size ", arraysize, " - we screwed up file reading somewhere, report this bug!") return end
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
			if !attributecount then MsgN("PEPlus_ReadPCF: ", filename, " got no attribute count - we screwed up file reading somewhere, report this bug!") return end
			if attributecount > 100 then MsgN("PEPlus_ReadPCF: ", filename, " got crazy attribute count ", attributecount, " - we screwed up file reading somewhere, report this bug!") return end
			for i = 1, attributecount do
				local attrib = DmAttribute()
				if !attrib.Name then MsgN("PEPlus_ReadPCF: ", filename, " attribute ", i, " has no name value - we screwed up file reading somewhere, report this bug!") return end
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
			//tab.k = index.Type .. " " .. index.Name
			tab.k = index

			local v = {}
			if !ElementBodies[i] then
				MsgN("PEPlus_ReadPCF: ", filename, " element index ", i, " has no body - we screwed up file reading somewhere, report this bug!")
				break //note: in all the cases where this bug has happened (reading pcfs packed into compressed tf2 maps before 3/26/25 update) every element after the first one with this bug will also be empty, so stop here
			else
				for i, attrib in pairs (ElementBodies[i]) do
					if attrib.AttributeType == "element_array" then //AT_ELEMENT_ARRAY
						v[attrib.Name] = {
							ElementTable = attrib.Value
						}
					elseif attrib.AttributeType == "element" then //AT_ELEMENT
						v[attrib.Name] = {
							ElementTable = {attrib.Value}
						}
					else
						v[attrib.Name] = attrib.Value
					end
				end
				tab.v = v
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
		result = {}
		if !ElementsUnsorted[0].v.particleSystemDefinitions or !ElementsUnsorted[0].v.particleSystemDefinitions.ElementTable then 
			if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " element 0 doesn't contain a particleSystemDefinitions table, ignoring") end
			return
		end
		for _, i in pairs (ElementsUnsorted[0].v.particleSystemDefinitions.ElementTable) do
			if !ElementsUnsorted[i] then
				if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " tried to get DmeParticleSystemDefinition from nil element ", i) end
			elseif ElementsUnsorted[i].k.Type != "DmeParticleSystemDefinition" then
				if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " tried to get DmeParticleSystemDefinition element ", ElementsUnsorted[i].k.Name, ", but it was a ", ElementsUnsorted[i].k.Type, " element") end
			else
				for k, v in pairs (ElementsUnsorted[i].v) do
					if istable(v) and v.ElementTable then
						local tab = {}
						for et_k, et_i in pairs (v.ElementTable) do
							if !ElementsUnsorted[et_i] then
								if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " attribute ", k, " tried to get nil element ", et_i) end
							else
								if ElementsUnsorted[et_i].k.Type == "DmeParticleChild" then
									if !ElementsUnsorted[et_i].v.child then
										if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " DmeParticleChild has no child value") end
									else
										//store particle children as effect name strings
										local childName = nil
										for et2_k, et2_i in pairs (ElementsUnsorted[et_i].v.child.ElementTable) do
											if !ElementsUnsorted[et2_i] then
												if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " DmeParticleChild tried to get invalid element id ", et2_i) end
											else
												//table.insert(tab, ElementsUnsorted[et2_i].k.Name)
												childName = string.lower(ElementsUnsorted[et2_i].k.Name) //for this addon's purposes, we make effect names all lowercase, see below
											end
										end
										ElementsUnsorted[et_i].v.child = childName
									end
								end
								//table.insert(tab, ElementsUnsorted[et_i])
								//discard key for DmeParticleOperators; the name is redundant and is also stored in the functionName value, and also there can be multiple with the same name
								table.insert(tab, ElementsUnsorted[et_i].v)
								//this doesn't handle recursive element tables but i don't think any particle operators have those
							end
						end
						ElementsUnsorted[i].v[k] = tab
						//v = tab
					end
				end
				result[ElementsUnsorted[i].k.Name] = ElementsUnsorted[i].v
			end
		end

		//Particle effect names are caps-agnostic internally, so for this addon's purposes, we'll make them all lowercase to avoid issues further 
		//down the line (effects with the same name but capitalized differently will conflict with each other, so make sure we detect those properly)
		local result2 = {}
		for k, v in pairs (result) do
			for k2, v2 in pairs (v) do
				//This is also a good place to fix up operator names - make all of these lowercase too, and check for any alternate names
				if defs[k2] then
					for k3, v3 in pairs (v2) do
						local name = v3.functionName or ""
						name = string.lower(name)
						if fixes[name] then name = fixes[name] end
						v[k2][k3].functionName = name
					end
				end
			end
			v._nicename = k //store the capitalized name so we can use it for display purposes
			result2[string.lower(k)] = v
		end
		result = result2

	//elseif header[1] == "keyvalues2" then
		//omitted; keyvalues2 parser is available on a separate branch (https://github.com/NO-LOAFING/ParticleEffectsPlus/tree/keyvalues2), but is
		//currently useless and can't be tested yet because gmod itself doesn't read these files (https://github.com/Facepunch/garrysmod-issues/issues/6782)
	else
		if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " has unsupported pcf format ", table.concat(header, " "), ", ignoring") end
		return
	end

	if !result then 
		if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " couldn't get result for some unhandled reason, ignoring") end
		return
	end

	local str
	if CLIENT or docache:GetBool() then
		//Remove all default values from the cached table, to significantly reduce both the size and load times of cached files
		str = {}
		for effect, effecttab in pairs (result) do
			//PrintTable(effecttab)
			str[effect] = {}
			for k, v in pairs (effecttab) do
				if defs._main[k] == v then //check each value in the main table, and don't add it to the tab if it's default
					continue
				elseif defs[k] then //operator categories
					local tab = {}
					for k2, v2 in pairs (v) do //operators
						local def = defs[k][v2.functionName]
						if def then
							local tab2 = {}
							for k3, v3 in pairs (v2) do //check each value in the operator, and only add it to the tab if it's non-default
								local def2 = def[k3]
								if def2 == nil then def2 = defs[k]._generic[k3] end
								if def2 != v3 then
									//this returns false negatives when comparing some decimal values, so double-check them as strings
									if isnumber(def2) then 
										if tostring(v3) != tostring(def2) then
											tab2[k3] = v3
										end
									else
										tab2[k3] = v3
									end
								end
							end
							tab[k2] = tab2
						else
							tab[k2] = v2
						end
					end
					str[effect][k] = tab
				else
					//this returns false negatives when comparing some decimal values, so double-check them as strings
					if isnumber(v) then
						if tostring(v) == tostring(defs._main[k]) then
							continue
						end
					end
					str[effect][k] = v
				end
			end
		end
		//Also store this in PEPlus_NoDefPCFs
		store_nodefs(str)
	end
	//PrintTable(str)
	if docache:GetBool() then
		str = util.TableToJSON(str)
		if str then
			local dirs = string.Explode("/", "peplus_cache_v" .. cache_version ..  "/" .. filename)
			local d = ""
			for k,v in ipairs(dirs) do
				d = (d..v.."/")
				if !file.IsDir(d, "DATA") then file.CreateDir(d) end
			end
			if file.Write("peplus_cache_v" .. cache_version ..  "/" .. filename .. "/" .. checksum .. ".txt", str) then
				if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " saved to cache") end
			else
				if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " couldn't be cached because file.Write failed?") end
			end
		else
			if dodebug then MsgN("PEPlus_ReadPCF: ", filename, " couldn't be cached because util.TableToJSON failed?") end
		end
	end
	
	//PrintTable(result)
	RestoreDefaultValues(result) //newer PCF versions omit all default values from the PCF file itself, so make sure to repopulate those
	return result

end


//For testing purposes, lists all fx using a certain operator, and optionally prints the operator's values
//Example: PEPlus_GetParticlesWithOperator("Remap Control Point to Vector") to get all fx in all pcfs with that operator, 
//or PEPlus_GetParticlesWithOperator("Remap Control Point to Vector", "particles/critglowtool_colorablefx.pcf") for just the fx in that file;
//add an extra "true" arg to the end of either of those to print the operator's values
function PEPlus_GetParticlesWithOperator(desiredfunc, filename, extended)
	desiredfunc = string.lower(desiredfunc)
	local function GetOperatorsFromFile(desiredfunc, filename, extended)
		local tab = PEPlus_ReadPCF(filename)
		if tab then
			for particle, ptab in SortedPairs (tab) do
				for category, ops in pairs (ptab) do
					if istable(ops) then
						for k, v in pairs (ops) do
							if istable(v) and v.functionName == desiredfunc then
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
		for _, filename2 in pairs (PEPlus_AllPCFPaths) do
			GetOperatorsFromFile(desiredfunc, filename2, extended)
		end
	else
		GetOperatorsFromFile(desiredfunc, filename, extended)
	end
end


//Test: Get a list of all pcfs that are defined by multiple games, and for each one, print the checksums of each copy of the file, along with the checksum
//of the one actually being loaded by the game. This lets us determine which games have unique instances of a pcf as opposed to identical copies, and also 
//tells us which ones are getting loaded vs. getting clobbered by mount order.
//TODO: almost certainly not necessary any more with the new data pcf system
function PEPlus_GetPCFConflicts(alternate)
	
	local particles = {}
	for k, v in pairs (PEPlus_AllPCFPaths) do
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
				local f = PEPlus_ReadPCF(name, v.folder)
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
				local f = PEPlus_ReadPCF(name)
				if f then
					particles[name]["      0: mounted          "] = util.SHA256(util.TableToKeyValues(f)) //top of list
				end
			end
		end
	end
	PrintTable(particles)

end


//Test: Prints all differences between 2 raw pcf data tables.
function PEPlus_ComparePCFs(file1, file2, shownil)

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
		for k, _ in SortedPairs (allkeys) do
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

	for _, v in pairs (Compare(PEPlus_ReadPCF(file1), PEPlus_ReadPCF(file2), true)) do
		if istable(v) then
			PrintTable(v)
		else
			MsgN(v)
		end
	end

end


//Test: Get all missing materials in a pcf
function PEPlus_GetMissingPCFMats(filename)

	local function Check(filename2)
		local tab = {}
	
		for particle, ptab in pairs (PEPlus_ReadPCF(filename2)) do
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
		for k, v in pairs (PEPlus_AllPCFPaths) do
			Check(v)
		end
	end

end


//Test: Get all particle effects used by info_particle_system ents on the map
//TODO: should rework this from scratch, can we get a list of ents from the server but then do PEPlus_PCFsByParticleName for each of them on client?
//DOUBLE TODO: update 1/3/26 makes PEPlus_PCFsByParticleName accessible serverside again, see if we can fix this
function PEPlus_GetMapFx()

	for k, v in pairs (ents.FindByClass("info_particle_system")) do
		local name = v:GetInternalVariable("effect_name")
		MsgN(name)
		//this no longer works now that we only build PEPlus_PCFsByParticleName clientside to save time
		--[[for _, v2 in pairs (PEPlus_PCFsByParticleName[name]) do 
			//wanted to use this to figure out which instance of this effect is currently mounted,
			//but info_particle_system ents are only serverside and this table is only clientside, argh
			//MsgN(v2, " ", table.KeyFromValue(PEPlus_AddParticles_AddedParticles, v2))
			MsgN(v2)
		end
		MsgN("")]]
	end

end


function PEPlus_GetUnhandledOperators(list_individual_fx)
	local allcategories = {
		renderers = {},
		operators = {},
		initializers = {},
		emitters = {},
		forces = {}, //forcegenerator
		constraints = {},
	}
	for _, filename in pairs (PEPlus_AllPCFPaths) do
		local tab = PEPlus_ReadPCF(filename)
		if tab then
			for particle, ptab in pairs (tab) do
				for category, _ in pairs (allcategories) do
					if ptab[category] then
						for _, op in pairs (ptab[category]) do
							local name = op.functionName
							if !defs[category][name] then
								allcategories[category][name] = allcategories[category][name] or {count = 0, paths = {}}
								allcategories[category][name].count = allcategories[category][name].count + 1
								allcategories[category][name].paths[filename] = allcategories[category][name].paths[filename] or {}
								if list_individual_fx then
									table.insert(allcategories[category][name].paths[filename], particle)
								end
							end
						end
					end
				end
			end
		end
	end

	PrintTable(allcategories)
	return allcategories
end


function PEPlus_GetUnhandledOperatorValues(list_individual_fx)
	local allcategories = {
		renderers = {},
		operators = {},
		initializers = {},
		emitters = {},
		forces = {}, //forcegenerator
		constraints = {},
	}
	local _main = {}
	for _, filename in pairs (PEPlus_AllPCFPaths) do
		local tab = PEPlus_ReadPCF(filename)
		if tab then
			for particle, ptab in pairs (tab) do
				for category, _ in pairs (allcategories) do
					if ptab[category] then
						for _, op in pairs (ptab[category]) do
							local name = op.functionName
							if defs[category][name] then
								for k, v in pairs (op) do
									if k != "functionName" and defs[category][name][k] == nil and defs[category]._generic[k] == nil then
										allcategories[category][name] = allcategories[category][name] or {}
										allcategories[category][name][k] = allcategories[category][name][k] or {count = 0, paths = {}}
										allcategories[category][name][k].count = allcategories[category][name][k].count + 1
										allcategories[category][name][k].paths[filename] = allcategories[category][name][k].paths[filename] or {}
										if list_individual_fx then
											allcategories[category][name][k].paths[filename][particle] = v
										end
									end
								end
							end
						end
					end
				end
				for k, v in pairs (ptab) do
					if k != "_nicename" and allcategories[k] == nil and defs._main[k] == nil then
						_main[k] = _main[k] or {count = 0, paths = {}}
						_main[k].count = _main[k].count + 1
						_main[k].paths[filename] = _main[k].paths[filename] or {}
						if list_individual_fx then
							_main[k].paths[filename][particle] = v
						end
					end
				end
			end
		end
	end

	allcategories._main = _main
	PrintTable(allcategories)
	return allcategories
end



//For reference:
//Orangebox particle code: https://github.com/nillerusr/source-engine/tree/master/particles
//Newer (Portal 2/Alien Swarm/CSGO-era?) particle code: https://github.com/nillerusr/Kisak-Strike/tree/master/particles
//https://developer.valvesoftware.com/wiki/Category:Particle_System
local badoutputparams = {
	["operator start fadein"] = 0,
	//["operator start fadeout"] = 0, //not actually functional without start fadein
	//["operator end fadein"] = 0, //not actually functional without end fadeout
	["operator end fadeout"] = 0,
	["first particle to copy"] = 1, //see striderbuster_flechette_attached
}
//new operator params that seem like they *might* matter re. outputs, but in practice, the only fx i could find with them were a few l4d2 ones,
//and none of them needed to have their outputs rejected, so ignore these for now
--[[local badoutputparams2 = {
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
function PEPlus_CPoint_AddToProcessed(processed, k, name, processedk, processedv, op)
	if op then
		//if an output has a fadein/fadeout, then it isn't always overriding this cpoint, so we don't care about it - reject it
		if (processedk == "output" or processedk == "output_axis" or processedk == "output_children")
		and op._categoryName != "initializers" then //the operator fadein/out values exist on the only initializer output (initializer Velocity Repulse from World), but don't seem to work, so ignore them
			for bad, v in pairs (badoutputparams) do
				if (op[bad] or 0) > v then //yes, they all default to 0
					//MsgN(name, " output doesn't always override cpoint because ", bad, " ", op[bad], " > ", v, ", rejecting") //no way to get the name of the particle with the output we're rejecting, argh
					//PrintTable(op)
					return
				end
			end
			//test: which fx even have these?
			--[[for bad, v in pairs (badoutputparams2) do
				if op[bad] != nil and op[bad] > v then
					if !processed.bad2 then
						processed.bad2 = ""
					else
						processed.bad2 = processed.bad2 .. "\n"
					end
					processed.bad2 = processed.bad2 .. name .. ": " .. bad .. " = " .. op[bad]
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
			if processedv.colorpicker then
				processedv.outMin = Vector(0,0,0) //color picker code expects outMin/Max to be 0-1
			else
				processedv.outMin = processedv.min
			end
			processedv.min = nil
		end
		if processedv.max then
			processedv.inMax = processedv.max
			if processedv.colorpicker then
				processedv.outMax = Vector(1,1,1) //color picker code expects outMin/Max to be 0-1
			else
				processedv.outMax = processedv.max
			end
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
		end
	end
	processedv.name = name
	processed.cpoints[k] = processed.cpoints[k] or {}
	processed.cpoints[k][processedk] = processed.cpoints[k][processedk] or {}

	table.insert(processed.cpoints[k][processedk], processedv)
end

local function cpoint_from_op_value(processed, op, value, processedk, processedv)
	local k = op[value]
	//if k == nil then MsgN(processed.nicename, " ", op.functionName, " ", value, " has nil value, fix this!\nhere's the bad op table:") PrintTable(op) return end
	if k > -1 or (processedv and processedv.force_allow_minusone) then
		local name
		if CLIENT and (GetConVarNumber("developer") >= 1) then //these names are only used by the "print processed pcf data" debug option
			name = value
			if op.functionName then
				name = op.functionName .. ": " .. name
			end
			if op._categoryName then
				name = op._categoryName .. " " .. name
			end
		end
		PEPlus_CPoint_AddToProcessed(processed, k, name, processedk, processedv, op)
	end
end

local function DoScalarIO(op, use_distance_input, is_position_control)
	local field = op["output field"] //PARTICLE_ATTRIBUTE_x enum
	local label = ParticleAttributeNames[field]
	local inMin
	local inMax
	if !use_distance_input then
		inMin = op["input minimum"]
		inMax = op["input maximum"]
	else
		inMin = op["distance minimum"]
		inMax = op["distance maximum"]
	end
	//local inMin_strict //currently unused
	local inMax_strict
	local outMin = op["output minimum"]
	local outMax = op["output maximum"]
	local is_multiplier = op["output is scalar of initial random range"] or op["output is scalar of current value"] //initializers don't have the latter, but this should be fine
	local default
	local decimals = nil
	if !is_position_control then
		//Defaults for axis controls (slider in options menu)
		local big = 4096 //10000 //arbitrary; for reference, a radius of 15359 is big enough to cover the entirety of flatgrass if spawned at the center; i could conceivably see a dev want to make effects bigger than this, but probably not with a scalar control, so err on the side of player usability here
		if outMax > big then
			//Sanity check for really big scalars; we don't want the max value to be so high the slider is unusable
			inMax = math.Remap(big, outMin, outMax, inMin, inMax)
			outMax = big
		end
		if field == PEPLUS_PARTICLE_ATTRIBUTE_RADIUS and !is_multiplier then
			//radius scalars should default to a nice big size, not 1 pixel
			default = math.Remap(32, outMin, outMax, inMin, inMax)
		elseif field == PEPLUS_PARTICLE_ATTRIBUTE_ALPHA or field == PEPLUS_PARTICLE_ATTRIBUTE_ALPHA2 then 
			//Alpha should always default to max visibility;
			//make sure to handle wacky fx like tf2's speech_mediccall that flip the scale around on output
			if outMin <= outMax then
				default = math.max(inMin, inMax)
			else
				default = math.min(inMin, inMax)
			end
		elseif field == PEPLUS_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER or field == PEPLUS_PARTICLE_ATTRIBUTE_SEQUENCE_NUMBER1 then
			//don't let sequence number scalars set the value to 64, or it'll crash (for particles/asw_order_fx.pcf order_use_item)
			if outMax > 63 then
				inMax = math.Remap(63, outMin, outMax, inMin, inMax)
				inMax_strict = inMax
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
		default = (inMin + inMax) / 2 //set the default distance to the midpoint of the effective radius, so players can visibly see what the scalar cpoint is doing
	end

	return {
		label = label,
		inMin = inMin,
		inMax = inMax,
		//inMin_strict = inMin_strict, //currently unused
		inMax_strict = inMax_strict,
		outMin = outMin,
		outMax = outMax,
		default = default,
		decimals = decimals,
	}
end

local function DoVectorIO(op)
	//Roll sets the angle of the particle, with the output measured in radians (pi radians = 180 degrees). Output maximum/minimum sets how many radians it can be rotated up to, 
	//with values past pi just rotating it past 180 degrees. With a standard render_animated_sprites, only the x value does anything, regardless of orientation type. With render 
	//models, this is broken and spawns models at random rotations regardless of the cpoint value.
	//Position sets the position of the particle, with the output measured in hammer units i think?
	//Color sets the color of the particle, with the output measured in 0 0 0 = black and 1 1 1 = white. Output values under 0 or over 1 don't seem to do anything different, so
	//no additive color or negative color wackiness here.
	local field = op["output field"] //PARTICLE_ATTRIBUTE_x enum
	local label = ParticleAttributeNames[field]
	local inMin = op["input minimum"]
	local inMax = op["input maximum"]
	local outMin = op["output minimum"]
	local outMax = op["output maximum"]
	local is_multiplier = op["output is scalar of initial random range"] or op["output is scalar of current value"] //initializers don't have the latter, but this should be fine
	local default = nil
	local colorpicker = nil
	if field == PEPLUS_PARTICLE_ATTRIBUTE_ROTATION then
		//Convert roll controls from radians to degrees to make them more user-friendly
		outMin = Vector(math.deg(outMin.x), math.deg(outMin.y), math.deg(outMin.z))
		outMax = Vector(math.deg(outMax.x), math.deg(outMax.y), math.deg(outMax.z))
	end
	if field == PEPLUS_PARTICLE_ATTRIBUTE_TINT_RGB or is_multiplier then
		//Color should default to the equivalent of 1,1,1 (white),
		//and multipliers should default to 100%
		default = Vector(math.Remap(1, outMin.x, outMax.x, inMin.x, inMax.x), math.Remap(1, outMin.y, outMax.y, inMin.y, inMax.y), math.Remap(1, outMin.z, outMax.z, inMin.z, inMax.z))
		if field == PEPLUS_PARTICLE_ATTRIBUTE_TINT_RGB then
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
	if field == PEPLUS_PARTICLE_ATTRIBUTE_ROTATION then
		label = {"Pitch", "Yaw", "Roll"}
	elseif field == PEPLUS_PARTICLE_ATTRIBUTE_XYZ then
		label = {label .. " Back/Fwd", label .. " Right/Left", label .. " Down/Up"}
	elseif field != PEPLUS_PARTICLE_ATTRIBUTE_TINT_RGB then
		label = {label .. " X", label .. " Y", label .. " Z"}
	end

	return {
		vector = true,
		label = label,
		inMin = inMin,
		inMax = inMax,
		outMin = outMin,
		outMax = outMax,
		default = default,
		colorpicker = colorpicker,
	}
end

local processfuncs = {
	renderers = {
		["render models"] = function(processed, op) processed.has_renderer = true end, //add this value manually for each renderer operator, rather than doing it in _generic, so that we can catch fx that don't have a valid one, like those ep2 blob fx
		render_rope = function(processed, op)
			//this definitely isn't how this is intended to be used lol; GOTTA SUPPORT IT ANYWAY
			if (op["scale CP start"] > -1) and (op["scale CP end"] > -1) then
				local scalar = nil
				for varname, label in pairs({
					["scale texture by CP distance"] = "Texture",
					["scale scroll by CP distance"] = "Scroll",
					["scale offset by CP distance"] = "Offset",
				}) do
					if op[varname] then
						if !scalar then
							scalar = "Rope " .. label .. " Scale"
						else
							scalar = scalar .. ", Rope " .. label .. " Scale"
						end
					end
				end
				if scalar then
					cpoint_from_op_value(processed, op, "scale CP end", "axis", {
						axis = 0, //arbitrary; any axis could work for this, but ent_peplus:StartParticle checks axis_0 for relative_to_cpoint
						label = scalar,
						inMin = 0,
						outMin = 0,
						inMax = 1024, //arbitrary max scale; these are really small units and are meant to rescale the beam texture to be suitable for a beam X units long
						outMax = 1024,
						default = 100, //arbitrary default
						relative_to_cpoint = op["scale CP start"] //?
					})
					cpoint_from_op_value(processed, op, "scale CP start", "position_combine") //this is iffy; we assume the start cpoint might be attached to something while the end point isn't
				end
			end
			processed.has_renderer = true
		end,
		render_sprite_trail = function(processed, op) processed.has_renderer = true end,
		render_animated_sprites = function(processed, op)
			cpoint_from_op_value(processed, op, "orientation control point", "position_combine")
			processed.has_renderer = true //global value on the effect, not cpoint-specfic
		end, //TODO: limit this to "orientation_type" cases where the orientation is actually used for something? this is sort of dependent on the VMT to work actually
		_generic = function(processed, op) cpoint_from_op_value(processed, op, "Visibility Proxy Input Control Point Number", "position_combine") end, //pet doesn't add cpoint control for this; all renderers except render_rope have this; uses this position for visiblilty testing, which can then scale particle alpha/size based on how visible the area around the point is (https://developer.valvesoftware.com/wiki/Generic_Render_Operator_Visibility_Options)
	},
	operators = {
		["alpha fade and decay"] = function(processed, op)
			//only do tracer_min_distance if we have one of the right decay operators; tracer fx using other things 
			//(i.e. alien swarm tracers using "alpha fade and decay for tracers") don't have a minimum length between cpoints to render
			processed.tracer_min_distance_hasdecay = true
		end,
		["color light from control point"] = function(processed, op)
			cpoint_from_op_value(processed, op, "Light 1 Control Point", "position_combine")
			cpoint_from_op_value(processed, op, "Light 2 Control Point", "position_combine")
			cpoint_from_op_value(processed, op, "Light 3 Control Point", "position_combine")
			cpoint_from_op_value(processed, op, "Light 4 Control Point", "position_combine")
		end,
		["cull relative to model"] = function(processed, op) cpoint_from_op_value(processed, op, "control_point_number", nil, { //TODO: should this be a position_combine? can't actually find any fx that use this, even in portal2/asw/l4d2
			ignore_outputs = true, //this cpoint sets an associated model, not a position, so outputs don't override it
		}) end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Cull_relative_to_model, yeah it's on the wrong page); pet doesn't add a control for this
		["cull when crossing plane"] = function(processed, op) 
			local norm = op["Plane Normal"]
			cpoint_from_op_value(processed, op, "Control Point for point on plane", nil, {
				plane = {
					pos = norm * -op["Cull plane offset"],
					pos_fixed_offset = true,
					normal = norm,
					normal_global = true
				}		
			})
		end,
		["cull when crossing sphere"] = function(processed, op) cpoint_from_op_value(processed, op, "Control Point") end, //TODO: this should have its own special handling similar to cull planes
		["lifespan decay"] = function(processed, op)
			//only do tracer_min_distance if we have one of the right decay operators; tracer fx using other things 
			//(i.e. alien swarm tracers using "alpha fade and decay for tracers") don't have a minimum length between cpoints to render
			processed.tracer_min_distance_hasdecay = true
		end,
		["lifespan maintain count decay"] = function(processed, op)
			local axis = op["maintain count scale control point field"]
			if axis > -1 then
				cpoint_from_op_value(processed, op, "maintain count scale control point", "axis", {
					axis = axis,
					label = "Maintain Count Scale",
					inMin = 0,
					outMin = 0,
					//no max
					default = 1,
				})
			end
		end,
		["movement basic"] = function(processed, op)
			if processed.drag_for_override then //global value on the effect, not cpoint-specific
				processed.drag_for_override = math.min(processed.drag_for_override, op.drag)
			else
				processed.drag_for_override = op.drag
			end
		end,
		--[[["movement lag compensation"] = function(processed, op)
			//description: "Movement Lag Compensation - Sets a speed and decelerates it based on an input lag amount (Sort of DotA specific)"
			//in practice, uses the length of (or the value of an axis of) one cpoint to set the desired speed, and then uses the value of
			//another cpoint's axis (which is meant to be a ping value?) to do some remapping math to multiply that speed by up to 3.
			https://github.com/kallinosis-dev/srcmodbase-source/blob/dev/particles/builtin_particle_ops.cpp#L8142
			//this is complicated and i can't find any existing fx using it in porta2/asw/l4d2, so it's hard to say what controls we should
			//add to support it. leave this blank until we find an effect we need to add support for.
		end,]]
		["movement dampen relative to control point"] = function(processed, op) 
			if op["falloff range"] >= 5 then //don't process if this value is too small to do anything (lots of ep2 electrical fx have extra useless cpoints with only these for whatever reason)
				cpoint_from_op_value(processed, op, "control_point_number", nil, {
					info = "slows down nearby particles"
				})
			end
		end,
		["movement lock to bone"] = function(processed, op)
			cpoint_from_op_value(processed, op, "control_point_number", "position_combine", {ignore_outputs = true}) //this cpoint sets an associated model, not a position, so outputs don't override it
			processed.movement_lock = processed.movement_lock or {}
			processed.movement_lock[op.control_point_number] = true
		end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_System_Operators#Movement_Lock_to_Bone)
		["movement lock to control point"] = function(processed, op)
			cpoint_from_op_value(processed, op, "control_point_number", "position_combine")
			processed.movement_lock = processed.movement_lock or {}
			processed.movement_lock[op.control_point_number] = true
		end,
		["movement lock to saved position along path"] = function(processed, op)
			//this is intended to use matching cpoints with position along path sequential, but you can set them to different
			//cpoints to make wacky nonsense where those cpoints move the effect instead, which to be fair is the sort of thing
			//position_combine is for, since that's not likely to be intended.
			//only works if the saved position is set by something like initializer "Position Along Path Sequential" with "Save Offset" enabled;
			//and some fx designers include this anyway even though it doesn't work (smissmas2021_unusuals.pcf unusual_smissmas_tree_* fx),
			//so we definitely don't want to make position controls for these.
			if op["Use sequential CP pairs between start and end point"] then
				//uses all cpoints from start to end
				local startp = op["start control point number"]
				local endp = op["end control point number"]
				local name = op._categoryName .. " " .. op.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
				for i = startp, endp do
					PEPlus_CPoint_AddToProcessed(processed, i, name, "position_combine", nil, op)
				end
			else
				//uses start and end cpoint only
				cpoint_from_op_value(processed, op, "start control point number", "position_combine")
				cpoint_from_op_value(processed, op, "end control point number", "position_combine") //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			end
		end,
		["movement maintain offset"] = function(processed, op) cpoint_from_op_value(processed, op, "Local Space CP", "position_combine") 
		end, //rotates the "desired offset" value by the angles of the cpoint; follow the precedent of angle-only cpoints being combined
		["movement maintain position along path"] = function(processed, op)
			cpoint_from_op_value(processed, op, "start control point number", nil, {sets_particle_pos = true})
			cpoint_from_op_value(processed, op, "end control point number", nil, {sets_particle_pos = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			//if there's no way for other cpoint operators (like the ones that initialize in a box/sphere) to influence the particles because this operator forces them onto a very specific path, then don't make position controls for those cpoints
			//this functionality was intended for constraints, but this operator does the same thing
			if op["maximum distance"] < 1 then
				processed.constraint_does_override = true //global value on the effect, not cpoint-specific
			end
		end,
		["movement match particle velocities"] = function(processed, op) cpoint_from_op_value(processed, op, "Control Point to Broadcast Speed and Direction To", "output") end, //pet doesn't add control for this; sets all 3 axes of the cpoint's position vector to the speed, and sets the cpoint's angle to face the direction (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_ops.cpp#L3788)
		["movement max velocity"] = function(processed, op)
			local axis = op["Override CP field"]
			if axis > -1 then
				cpoint_from_op_value(processed, op, "Override Max Velocity from this CP", "axis", {
					axis = axis,
					label = "Max Velocity",
					inMin = 0,
					outMin = 0,
					inMax = 2500, //arbitrary max, because the default max of 10 is too low;
					outMax = 2500, //no idea if this is good, because i can't find any existing fx using this
					default = 1,
				})
			end
		end,
		--[[["movement place on ground"] = function(processed, op)
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L9390
			//uses the movement of the last two cpoints to throttle updates; if either one has moved enough from its previous pos, then update immediately.
			//also uses the movement of the first one to throttle something(?) involving interpolation the same way.
			//no existing portal2/asw/l4d2 fx use this, is this a dota thing? can't even get a custom effect to use these in any meaningful way, ignore for now.
			cpoint_from_op_value(processed, op, "interploation distance tolerance cp", "position_combine") //sic
			cpoint_from_op_value(processed, op, "reference CP 1", "position_combine")
			cpoint_from_op_value(processed, op, "reference CP 2", "position_combine")
		end,]]
		["movement rotate particle around axis"] = function(processed, op) cpoint_from_op_value(processed, op, "Control Point", nil, {
			info = "is a target for particles to rotate around"
		}) end,
		["normal lock to control point"] = function(processed, op) cpoint_from_op_value(processed, op, "control_point_number", "position_combine") end, //controls angle of Render Models fx; this is an angle control, so combine it
		["remap average scalar value to cp"] = function(processed, op) cpoint_from_op_value(processed, op, "output control point", "output") end, //overrides the cpoint's position to Vector(result,0,0) (https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L2602)
		["remap control point direction to vector"] = function(processed, op) 
			//like remap control point to vector, but it sets the vector to the forward normal vector of the cpoint's angle.
			//can't really turn this into a set of sliders/color picker since that's not how normals work, and the only existing
			//fx that use this are some alien swarm gib fx that use it to set the particle's "normal" vector to control the gib
			//model's angle, so make this a position_combine.
			cpoint_from_op_value(processed, op, "control point number", "position_combine") 
		end, 
		["remap control point to scalar"] = function(processed, op)
			//controls a whole bunch of stuff (lifetime, radius, alpha, etc.) with the value of a single axis of the cpoint, definitely not a position control
			local axis = op["input field 0-2 X/Y/Z"]
			if axis > -1 then
				local tab = DoScalarIO(op)
				tab.axis = axis
				cpoint_from_op_value(processed, op, "input control point number", "axis", tab)
			end
		end,
		["remap control point to vector"] = function(processed, op)
			//Similar to above, use all 3 axes of the cpoint to set Position, Roll, or Color
			//TF2/episodes/HL2 pcfs only have use cases for Color, so the others required some testing.
			cpoint_from_op_value(processed, op, "input control point number", "axis", DoVectorIO(op))
			cpoint_from_op_value(processed, op, "local space CP", "position_combine") //uses the cpoint's angles to rotate the output in some odd way, can be used to make a position sort-of-rotate with the cpoint, or make colors change as it spins
		end,
		["remap cp speed to cp"] = function(processed, op)
			local axis = op["Output field 0-2 X/Y/Z"]
			if axis > -1 and op["output control point"] != -1 then
				cpoint_from_op_value(processed, op, "input control point", "position_combine") //only used if the output is defined (https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L2383)
				cpoint_from_op_value(processed, op, "output control point", "output_axis", {axis = axis})
			end
		end,
		["remap cp velocity to vector"] = function(processed, op)
			//like remap control point to vector, but it sets the vector to the cpoint's velocity value.
			//can't really turn this into a set of sliders/color picker unless we make some custom functionality to constantly move
			//the cpoint around, and i can't find any existing fx using this to accomodate, so just position_combine it for now.
			cpoint_from_op_value(processed, op, "control point", "position_combine")
		end,
		["remap direction to cp to vector"] = function(processed, op)
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L9390
			//uses the angle of the cpoint to set a vector value; only existing fx i could find using this are a few in  portal 2's portals.pcf,
			//which use it to set the new "normal" value; creates an extraneous cpoint that doesn't visibly do anything, so just position_combine it.
			cpoint_from_op_value(processed, op, "control point", "position_combine")
		end,
		["remap distance between two control points to cp"] = function(processed, op)
			//i guess we could convert this into a relative_to_cp vector control just like "remap distance between two control points to scalar" below,
			//but what would we actually describe the control as? can't find any existing fx using this, so just add normal position controls and output for now.
			//not sure how we'd do info text for this, either, since we can't intuitively figure out what the output cpoint does here.
			cpoint_from_op_value(processed, op, "starting control point")
			cpoint_from_op_value(processed, op, "ending control point")
			local axis = op["output control point field"]
			if axis > -1 and op["output control point"] != -1 then
				cpoint_from_op_value(processed, op, "output control point", "output_axis", {axis = axis})
			end
		end,
		["remap distance between two control points to scalar"] = function(processed, op)
			//this uses all the same scalars as remap control point to scalar, but actually uses the distance between two positions to get the value
			local tab = DoScalarIO(op, true)
			tab.axis = 0 //arbitrary; any axis could work for this, but ent_peplus:StartParticle checks axis_0 for relative_to_cpoint
			tab.relative_to_cpoint = op["starting control point"] //?
			cpoint_from_op_value(processed, op, "ending control point", "axis", tab)
			cpoint_from_op_value(processed, op, "starting control point", "position_combine") //this is iffy; we assume the start cpoint might be attached to something while the end point isn't, which *is* the case with all existing fx, but doesn't necessarily have to be
		end,
		["remap distance to control point to scalar"] = function(processed, op)
			//like the above, but uses the distance between a single cpoint's position and each individual particle itself (https://developer.valvesoftware.com/wiki/Particle_System_Operators#Remap_Distance_to_Control_Point_to_Scalar)
			cpoint_from_op_value(processed, op, "control point", nil, {distance_scalar = DoScalarIO(op, true, true)})
		end,
		["remap dot product to scalar"] = function (processed, op)
			//like "remap control point to scalar", except it gets the angle(?) of 2 cpoints and does math with them to set the scalar. not listed in wiki.
			//every example i could find for this (it's used by a lot of "ring" child fx in dr grordbord fx) works in conjunction with another "set control point to player" operator, which 
			//uses an output to set a cpoint to the player's position. then, this operator does math with that to set output field Yaw (12) to rotate the particles, attempting to orient 
			//them to face "forward" in the direction of the first cpoint(not the player one), with mixed results. the only exceptions i could find for this were some unused effects in 
			//eyeboss.pcf, which were the same but without the player cpoint, and instead use the angle (not the position!) of the second cpoint to change the particle's yaw.
			//whatever, just make this a position control, seems it's like "remap direction to cp to vector", and should be either this or a manual angle input.
			//update: actually just combine this one, the only effects that have a position control *for this operator only* are ones that didn't set up the player yaw thing properly
			local label = ParticleAttributeNames[op["output field"]] //PARTICLE_ATTRIBUTE_x enum //put this in the table so we can see what it does in the debug
			cpoint_from_op_value(processed, op, "first input control point", "position_combine", {label = label})
			cpoint_from_op_value(processed, op, "second input control point", "position_combine", {label = label})
		end,
		["remap particle bbox volume to cp"] = function(processed, op) cpoint_from_op_value(processed, op, "output control point", "output") end, //sets the whole cpoint to Vector(volume,0,0) https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L2532
		["remap percentage between two control points to scalar"] = function(processed, op)
			//sets a scalar value on *each individual particle* based on what percentage of the distance between two cpoints it's covered
			//TODO: do we need to handle this like distance scalars?
			//TODO: info text? are there any fx with cpoints only used for this?
			cpoint_from_op_value(processed, op, "starting control point")
			cpoint_from_op_value(processed, op, "ending control point")
		end,
		["remap percentage between two control points to vector"] = function(processed, op)
			//sets a vector value on *each individual particle* based on what percentage of the distance between two cpoints it's covered
			//TODO: do we need to handle this like distance scalars?
			//TODO: info text? are there any fx with cpoints only used for this?
			cpoint_from_op_value(processed, op, "starting control point")
			cpoint_from_op_value(processed, op, "ending control point")
		end,
		["restart effect after duration"] = function(processed, op)
			local axis = op["Control Point Field X/Y/Z"]
			if axis > -1 then
				cpoint_from_op_value(processed, op, "Control Point to Scale Duration", "axis", {
					axis = axis,
					label = "Duration Scale",
					inMin = 0, //no point in negative scale for this one
					outMin = 0,
					//no max
					default = 1,
				})
			end
		end,
		["rotation orient relative to cp"] = function(processed, op) 
			cpoint_from_op_value(processed, op, "Control Point", nil, {
			//	info = "something something rotation orient" //TODO: can't find any existing fx with a cpoint for just this, so don't worry about info text until we need it
			})
		end,
		["set child control points from particle positions"] = function(processed, op)
			local groupid = op["Group ID to affect"]
			local startp = op["First control point to set"]
			local endp = startp + (op["# of control points to set"] - 1)
			local name = op._categoryName .. " " .. op.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
			for i = startp, endp do
				PEPlus_CPoint_AddToProcessed(processed, i, name, "output_children", {groupid = groupid}, op)
			end
			//some fx (i.e. utaunt_tornado_oscillate_) emit invisible particles (no renderer) and then use them to set the position of a child control point. ordinarily, we'd cull the
			//cpoint data from fx with no renderer, because their operators don't do anything that the player can see, but in this case, we don't want to do that, so mark as having a renderer.
			//TODO: this might be bad if the children don't have a renderer either, can we catch those?
			if #processed.children > 0 then
				processed.has_renderer = true
				processed.ignore_zero_alpha = true //for particles/infection_particles.pcf: zombie_lightning_controller
			end
			//processed.sets_particle_pos_on_children = groupid
		end,
		["set control point positions"] = function(processed, op)
			local cpoints = {
				[1] = {
					//input = "First Control Point Parent",
					output = "First Control Point Number",
					location = "First Control Point Location",
				},
				[2] = {
					//input = "Second Control Point Parent",
					output = "Second Control Point Number",
					location = "Second Control Point Location",
				},
				[3] = {
					//input"= "Third Control Point Parent",
					output = "Third Control Point Number",
					location = "Third Control Point Location",
				},
				[4] = {
					//input = "Fourth Control Point Parent",
					output = "Fourth Control Point Number",
					location = "Fourth Control Point Location",
				},
			}
			local used_cpoint //fix some fx that have an output set to the main cpoint they're all offset from (tfc_sniper_charge_blue) - in these cases, the cpoint is not overridden
			if !op["Set positions in world space"] then //according to code, only used if not setting in world space (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_ops.cpp#L2725)
				local tab2 = {}
				for k, tab in pairs (cpoints) do
					tab2[op[tab.output]] = true
				end
				cpoint_from_op_value(processed, op, "Control Point to offset positions from", nil, {
					doesnt_need_renderer_or_emitter = true, 
					copy_sets_particle_pos = tab2}
				)
				used_cpoint = op["Control Point to offset positions from"]
				if used_cpoint == -1 then used_cpoint = nil end //TODO: nothing actually does this?
			else
				//If set to positions in worldspace, these cpoints can break spawnicon renderbounds, so tell it to account for that
				processed.spawnicon_forcedpositions = processed.spawnicon_forcedpositions or {0,0,0,0,0,0}
				for k, tab in pairs (cpoints) do
					//Create a table of 6 numbers, the mins and maxs of the forced positions
					local function DoParticle3(i, domax, axis)
						local val = op[tab.location]
						if !domax then
							processed.spawnicon_forcedpositions[i] = math.min(processed.spawnicon_forcedpositions[i], val[axis])
						else
							processed.spawnicon_forcedpositions[i] = math.max(processed.spawnicon_forcedpositions[i], val[axis])
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
					cpoint_from_op_value(processed, op, tab.input, nil, {doesnt_need_renderer_or_emitter = true, remove_if_other_cpoint_is_empty = op[tab.output]})
				end]]
				//then do outputs - remove position controls from the "child" cpoints that are having their positions overridden
				if op[tab.output] != used_cpoint then
					cpoint_from_op_value(processed, op, tab.output, "output")
				end
			end
		end,
		--[[["set control point rotation"] = function(processed, op)
			//the rotation from this cpoint gets stomped by the angle of the position control, and i don't see a way to fix this. 
			//even output isn't great because either A: the cpoint being rotated is the first cpoint, it gets assigned to fallback cpoint
			//-1 instead, and it uses the angle of *that* instead, or B: the cpoint being rotated doesn't get a position set and ends up
			//at 0,0,0. hrmph.
			//only way to fix all this would be to add special handling for cpoints using this operator, where ent_peplus would use
			//something other than self.particle:AddControlPoint so that the cpoint angle doesn't get set. i can't find any working 
			//effects that actually use this, so that would be overengineered for now.
			cpoint_from_op_value(processed, op, "Control Point", "output")
			//there's also a "Local Space Control Point" we could position_combine, but again, not useful.
		end,]]
		["set control point to impact point"] = function(processed, op)
			cpoint_from_op_value(processed, op, "Control Point to Trace From", "position_combine", 
				{copy_sets_particle_pos = {
					[op["Control Point to Set"]] = true
				}}
			)
			cpoint_from_op_value(processed, op, "Control Point to Set", "output") 
			//note: if we have a control for the output cpoint (i.e. output doesn't get set because of fadein or something), 
			//then this operator's changes get squashed completely, even for the window of time where it *should* be doing something.
			//all existing fx i could find with these conditions work better with a cpoint, though, so do it this way for now.
		end,
		["set control point to particles' center"] = function(processed, op) cpoint_from_op_value(processed, op, "Control Point Number to Set", "output") end,
		["set control point to player"] = function(processed, op)
			cpoint_from_op_value(processed, op, "Control Point Number", "output")
			processed.spawnicon_playerposfix = true //this operator forces a cpoint to the player's position, which can break spawnicon renderbounds, so tell it to account for that
		end,
		["set control points from particle positions"] = function(processed, op)
			//like "set child control points from particle positions", but it sets the effect's own cpoints instead.
			//only existing effect i could find using this was portal 2's dissolve_flashes_glow particles/spark_fx.pcf, which uses
			//it to move the renderer's "Visibility Proxy Input Control Point Number" to each particle as it's spawned, and i made
			//a test effect that uses it functionally the same way as the child one, by moving a cpoint that's only used by child fx.
			local startp = op["First control point to set"]
			local endp = startp + (op["# of control points to set"] - 1)
			local name = op._categoryName .. " " .. op.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
			for i = startp, endp do
				PEPlus_CPoint_AddToProcessed(processed, i, name, "output", nil, op)
			end
		end,
		["set cp offset to cp percentage between two control points"] = function(processed, op)
			//this one is pretty elaborate, it gets the position of an "input" control point relative to two other "start" and
			//"ending" control points, uses it to scale a value relative to a fourth "offset" control point, and then outputs 
			//that to a fifth "output" control point.
			//no existing portal2/asw/l4d2 fx use this, what could this possibly be for? just handle the output and then do 
			//normal position controls for the rest, until we find an effect we need to accomodate. no idea how we'd do info
			//text for this, either, since, again, we don't actually know what the output does.
			cpoint_from_op_value(processed, op, "starting control point")
			cpoint_from_op_value(processed, op, "ending control point")
			cpoint_from_op_value(processed, op, "offset control point")
			cpoint_from_op_value(processed, op, "input control point")
			cpoint_from_op_value(processed, op, "output control point", "output") //note: this output gets clobbered if we make a position control for the same cpoint, probably interacts badly if we don't create this control due to fadein or something
		end,
		--[[["set cp orientation to cp direction"] = function(processed, op)
			//gets the direction the input cpoint is currently moving, and rotates the angle of the output cpoint
			//to point in that direction. no existing portal2/asw/l4d2 fx use this, what is this used for?
			//the output angle gets clobbered by the angle of the position control if it has one, so should we handle this like
			//a pos output to keep it untouched? maybe wait until there's an effect using this to see how we should accomodate it.
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L9338
			cpoint_from_op_value(processed, op, "input control point")
			cpoint_from_op_value(processed, op, "output control point", "output")
		end,]]
		["set per child control point from particle positions"] = function(processed, op)
			//sets a single control point on a limited number of child fx
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_ops.cpp#L5220
			cpoint_from_op_value(processed, op, "control point to set", "output_children", {groupid = op["Group ID to affect"], limit = op["# of children to set"]})

			//again, like "set child control points from particle positions", some fx (portalgun_beam_holding_object) emit invisible particles (no renderer) 
			//and then use them to set the position of a child control point. ordinarily, we'd cull the cpoint data from fx with no renderer, because their 
			//operators don't do anything that the player can see, but in this case, we don't want to do that, so mark as having a renderer.
			//TODO: this might be bad if the children don't have a renderer either, can we catch those?
			if #processed.children > 0 then processed.has_renderer = true end
			//processed.sets_particle_pos_on_children = groupid
		end,
		["stop effect after duration"] = function(processed, op)
			local axis = op["Control Point Field X/Y/Z"]
			if axis > -1 then
				cpoint_from_op_value(processed, op, "Control Point to Scale Duration", "axis", {
					axis = axis,
					label = "Duration Scale",
					inMin = 0, //no point in negative scale for this one
					outMin = 0,
					//no max
					default = 1,
				})
			end
		end,
	},
	initializers = {
		["alpha random"] = function(processed, op)
			//some fx use an alpha of 0 to make it invisible?? who does that??
			//(particles/scary_ghost (plr_hacksaw_event).pcf: halloween_boss_eye_glow)
			if op.alpha_max == 0 and op.alpha_min == 0 then
				processed.has_zero_alpha = true
			end
		end,
		["color random"] = function(processed, op)
			if op.tint_perc > 0 then //by default, the value of "tint control point" is 0, not -1, so pet adds a control for it by default, but in code, this isn't used unless tint_perc is non-zero (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L1705)
				cpoint_from_op_value(processed, op, "tint control point", "position_combine") //samples the lighting from this cpoint's position (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Color_Random)
			end
		end,
		["cull relative to model"] = function(processed, op) cpoint_from_op_value(processed, op, "control_point_number", nil, { //TODO: should this be a position_combine? can't actually find any fx that use this, even in portal2/asw/l4d2
			ignore_outputs = true, //this cpoint sets an associated model, not a position, so outputs don't override it
		}) end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Cull_relative_to_model)
		["move particles between 2 control points"] = function(processed, op) cpoint_from_op_value(processed, op, "end control point", nil, { //yes, it only defines an endpoint (https://developer.valvesoftware.com/wiki/Particle_System_Initializers#Move_Particles_Between_2_Control_Points); seems to work based on each particle's initial position (https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_initializers.cpp#L3787)
			sets_particle_pos = true,
			//the minimum distance between cpoints needed to render fx using this operator actually scales with FRAMERATE, ridiculous
			//TODO: not much more we can do about this since actually spawning the cpoints is serverside, argh. i guess this could use a convar? a serverside convar for how much fps they expect clients to have? nonsense
			tracer_min_distance = (math.max(op["maximum speed"], op["minimum speed"])/58) + 1 + op["start offset"] - op["end offset"]
		}) end,
		["normal align to cp"] = function(processed, op) cpoint_from_op_value(processed, op, "control_point_number", "position_combine") end, //controls angle of Render Models fx; this is an angle control, so combine it
		["normal modify offset random"] = function(processed, op)
			if op["offset in local space 0/1"] then //cpoint is only used if this is true https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_initializers.cpp#L7267
				cpoint_from_op_value(processed, op, "control_point_number", "position_combine") //controls angle of Render Models fx; this is an angle control, so combine it
			end
		end,
		["position along epitrochoid"] = function(processed, op)
			cpoint_from_op_value(processed, op, "control point number", nil, {sets_particle_pos = true})
			if op["scale from conrol point (radius 1/radius 2/offset)"] > -1 then //sic (conrol point)
				local function DoEpitrochoidAxis(axis, axisv, min)
					if op[axisv] != 0 then
						cpoint_from_op_value(processed, op, "scale from conrol point (radius 1/radius 2/offset)", "axis", { //sic
							axis = axis,
							label = "Epitrochoid " .. string.NiceName(axisv) .. " Scale",
							inMin = min,
							outMin = min,
							//no max
							default = 1,
						})
					end
				end
				DoEpitrochoidAxis(0, "radius 1")
				DoEpitrochoidAxis(1, "radius 2")
				DoEpitrochoidAxis(2, "point offset", 0) //no point in negatives for this one
			end
		end,
		["position along path random"] = function(processed, op)
			if op["randomly select sequential CP pairs between start and end points"] then
				//uses all cpoints from start to end
				local startp = op["start control point number"]
				local endp = op["end control point number"]
				local name = op._categoryName .. " " .. op.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
				for i = startp, endp do
					PEPlus_CPoint_AddToProcessed(processed, i, name, nil, {overridable_by_constraint = true, sets_particle_pos = true}, op)
				end
			else
				//uses start and end cpoint only
				cpoint_from_op_value(processed, op, "start control point number", nil, {overridable_by_constraint = true, sets_particle_pos = true})
				cpoint_from_op_value(processed, op, "end control point number", nil, {overridable_by_constraint = true, sets_particle_pos = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			end
		end,
		["position along path sequential"] = function(processed, op)
			if op["Use sequential CP pairs between start and end point"] then
				//uses all cpoints from start to end
				local startp = op["start control point number"]
				local endp = op["end control point number"]
				local name = op._categoryName .. " " .. op.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
				for i = startp, endp-startp do //note: if the starting cpoint is non-0, it behaves oddly and deducts that many cpoints from the other end, see portal2 particles/debug.pcf debug_sc_square; this is almost certainly a bug, but a valve effect was designed with it in mind, so we're going with it
					PEPlus_CPoint_AddToProcessed(processed, i, name, nil, {
						overridable_by_constraint = true,
						sets_particle_pos = true, 
						pathseqcheck_min_particles = (op["particles to map from start to end"] / (endp - startp)) * (i - startp - 1)
					}, op)
				end
				processed.pathseqcheck = true
			else
				//uses start and end cpoint only
				cpoint_from_op_value(processed, op, "start control point number", nil, {overridable_by_constraint = true, sets_particle_pos = true})
				cpoint_from_op_value(processed, op, "end control point number", nil, {overridable_by_constraint = true, sets_particle_pos = true}) //pet adds controls for all the cpoints between these two, but the effect itself still only seems to use the start and end
			end
		end,
		["position along ring"] = function(processed, op)
			cpoint_from_op_value(processed, op, "control point number", nil, {sets_particle_pos = true})
			//"Override CP (X/Y/Z *= Radius/Thickness/Speed)" and "Override CP 2 (X/Y/Z *= Pitch/Yaw/Roll)" control those things with the values of the cpoint
			//These are all MULTIPLIERS so an axis doesn't do anything if the value is 0, ignore those
			//Unlike remap control point to vector, pitch/yaw/roll are in degrees, not radians
			local function DoRingAxis(cpoint, axis, axisv, min)
				if op[cpoint] > -1 then
					local doaxis = false
					if axisv == "speed" then //this one uses two values so it has special handling 
						if op["min initial speed"] != 0 
						or op["max initial speed"] != 0 then
							doaxis = true
						end
					elseif op[axisv] != 0 then
						doaxis = true
					end
					if doaxis then
						if axisv == "initial radius" then axisv = "radius" end //nicer name for slider label
						cpoint_from_op_value(processed, op, cpoint, "axis", {
							axis = axis,
							label = "Ring " .. string.NiceName(axisv) .. " Scale",
							inMin = min,
							outMin = min,
							//no max
							default = 1,
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
		["position from chaotic attractor"] = function(processed, op)
			cpoint_from_op_value(processed, op, "Relative Control point number", nil, {sets_particle_pos = true})
		end,
		["position from parent cache"] = function(processed, op)
			//this operator's presence overrides others that would set the particle pos (i.e. "position within sphere random") and actively makes
			//the effect unusable on its own - see l4d2's particles/firework_crate_fx.pcf firework_crate_ground_sparks_01.
			//this shouldn't even be possible, gmod's pet doesn't let you add this operator and another position one at the same time.
			processed.sets_particle_pos_forcedisable = true
		end,
		["position from parent particles"] = function(processed, op)
			//don't cull parent fx if they don't have a valid renderer, but one of their children has this operator (i.e. parent alien_ufo_explode_trailing_bits_alt, child alien_ufo_explode_alt_trail_smoke)
			processed.parent_force_has_renderer = true
			//processed.sets_particle_pos_if_child = true
		end,
		["position in cp hierarchy"] = function(processed, op)
			//this one is a bit strange. it defines a cpoint for every id between the start and end, and then moves the particle spawn point between them all.
			//the weird pet behavior where it adds controls for every cpoint between start and end seems to be designed for this initializer.
			local startp = op["start control point number"]
			local endp = op["end control point number"]
			if op["use highest supplied end point"] then //with this arg set, the particle system uses as many cpoints as you give it. any amount works.
				//endp = 63 //this is what pet does, and it's functional, but this is stupid, don't do this. no one needs 64 whole cpoints to move around.
				endp = math.min(startp + 1, 63) //TODO: give players a way to manually enable as many cpoints as they want, without dumping 64 on them by default.
			end
			local name = op._categoryName .. " " .. op.functionName .. ": cpoints " .. tostring(startp) .. " to " .. tostring(endp)
			for i = startp, endp do
				PEPlus_CPoint_AddToProcessed(processed, i, name, nil, {sets_particle_pos = true}, op)
			end
		end,
		["position modify offset random"] = function(processed, op)
			//code only uses this cpoint if offset in local space is enabled; (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L776)
			//this cpoint's ANGLES are used to rotate the offset mins/maxs, its position is not used, so we should either use a position control or a manual angle input maybe
			if op["offset in local space 0/1"] then
				cpoint_from_op_value(processed, op, "control_point_number", "position_combine")
			end
		end,
		["position modify warp random"] = function(processed, op)
			//this can potentially be used to make the position stretch and skew with the movement of the cpoint, but only if the values are set up a specific way. (test_PositionModifyWarpRandom_2)
			//otherwise, in practice, making a separate cpoint for this doesn't do anything except move the center of the effect around, which is extraneous, so use position_combine.
			if op["warp transition time (treats min/max as start/end sizes)"] == 0 and op["warp min"] != op["warp max"] then
				cpoint_from_op_value(processed, op, "control point number", nil, {
					info = "warps particle positions" //eh, good enough, only test fx have a separate cpoint for just this
				})
			else
				cpoint_from_op_value(processed, op, "control point number", "position_combine")
			end
		end,
		["position on model random"] = function(processed, op) 
			cpoint_from_op_value(processed, op, "control_point_number", nil, {
				ignore_outputs = true, //this cpoint sets an associated model, not a position, so outputs don't override it
				on_model = true,
				sets_particle_pos = true,
			})
			//if op["desired hitbox"] > -1 then
				//TODO: should there be different info text handling for this? it doesn't apply to the *entire* model, 
				//but rather to a *specific part* of the model, though we don't have a way of knowing what that part is
			//end
		end, //uses the model that the cpoint is attached to, so use position (https://developer.valvesoftware.com/wiki/Particle_position#Position_on_Model_Random)
		["position within box random"] = function(processed, op)
			if op["use local space"] then 
				 //if this var is set, then the cpoint controls the angle of the box, but not the position. this feels like a bug, but alright.
				cpoint_from_op_value(processed, op, "control point number", "position_combine")
			else
				cpoint_from_op_value(processed, op, "control point number", nil, {overridable_by_constraint = true, sets_particle_pos = true})
			end
		end,
		["position within sphere random"] = function(processed, op)
			if !op["randomly distribute to highest supplied Control Point"] then
				cpoint_from_op_value(processed, op, "control_point_number", nil, {overridable_by_constraint = true, sets_particle_pos = true})
			else
				local name = op._categoryName .. " " .. op.functionName .. ": randomly distribute to highest supplied Control Point"
				PEPlus_CPoint_AddToProcessed(processed, -1, name, "position_combine", {sets_particle_pos = true, force_allow_minusone = true}, op)
				//TODO: ehh, this makes it combine with the control of the first available position control; 
				//works on all fx i could find, but could potentially result in bad cpoints on more complex fx 
			end
			if op["scale cp (distance/speed/local speed)"] > -1 then
				local function DoSphereAxis(axis, label, axisvs, min)
					local doaxis = false
					for k, v in pairs (axisvs) do
						if op[k] != v then
							doaxis = true
							break
						end
					end
					if doaxis then
						cpoint_from_op_value(processed, op, "scale cp (distance/speed/local speed)", "axis", {
							axis = axis,
							label = "Sphere " .. label .. " Scale",
							inMin = min,
							outMin = min,
							//no max
							default = 1,
						})
					end
				end
				DoSphereAxis(0, "Distance", {distance_min = 0, distance_max = 0}, 0) //no point in negative scale for this one
				DoSphereAxis(1, "Speed", {speed_min = 0, speed_max = 0})
				DoSphereAxis(2, "Local Speed", {speed_in_local_coordinate_system_min = Vector(), speed_in_local_coordinate_system_max = Vector()})
			end
		end,
		["remap control point to scalar"] = function(processed, op)
			//like the operator of the same name
			//controls a whole bunch of stuff (lifetime, radius, alpha, etc.) with the value of a single axis of the cpoint, definitely not a position control
			local axis = op["input field 0-2 X/Y/Z"]
			if axis > -1 then
				local tab = DoScalarIO(op)
				tab.axis = axis
				cpoint_from_op_value(processed, op, "input control point number", "axis", tab)
			end
		end,
		["remap control point to vector"] = function(processed, op)
			//same as operator of the same name; actually, orangebox only has the initializer version of this, the operator is new from pcf v5
			//Similar to above, use all 3 axes of the cpoint to set Position, Roll, or Color
			cpoint_from_op_value(processed, op, "input control point number", "axis", DoVectorIO(op))
			cpoint_from_op_value(processed, op, "local space CP", "position_combine") //uses the cpoint's angles to rotate the output in some odd way, can be used to make a position sort-of-rotate with the cpoint, or make colors change as it spins
		end,
		["remap cp orientation to rotation"] = function(processed, op) cpoint_from_op_value(processed, op, "control point", "position_combine") end, //uses the cpoint's angles to set the pitch/yaw/roll of particles; this is an angle control, so position_combine it
		["remap initial direction to cp to vector"] = function(processed, op)
			//like "remap direction to cp to vector" but an initializer instead of operator.
			//can't find any fx using this in portal2/asw/l4d2, and can't get it to do anything useful in a custom effect,
			//so just position_combine it like the operator version.
			cpoint_from_op_value(processed, op, "control point", "position_combine")
		end,
		["remap initial distance to control point to scalar"] = function(processed, op)
			//like "remap distance to control point to scalar", but an initializer instead of an operator. 
			//uses the distance between a single cpoint's position and each individual particle itself
			cpoint_from_op_value(processed, op, "control point", nil, {distance_scalar = DoScalarIO(op, true, true)})
		end,
		["remap noise to scalar"] = function(processed, op)
			//for particles/blood_impact.pcf blood_impact_synth_01_short: ignore the initializer "alpha random" zero alpha check if the zero alpha is being
			//overwritten by the scalar. TODO: there's almost certainly a lot of other scalar operators that could potentially do the same thing, but we'll
			//just add those if we run into them. there's really no good reason for fx to be set up this way, it just makes alpha random do nothing.
			if op["output field"] == PEPLUS_PARTICLE_ATTRIBUTE_ALPHA then
				processed.ignore_zero_alpha = true
			end
		end,
		["remap scalar to vector"] = function(processed, op)
			if op["output field"] == PEPLUS_PARTICLE_ATTRIBUTE_XYZ then //cpoint is only used by position vector (0) to make the position relative to that cpoint (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3155)
				cpoint_from_op_value(processed, op, "control_point_number", nil, {sets_particle_pos = true}) //yes, this sets particle pos, see unusual_poseidon_light_ fx
			end
		end,
		["remap speed to scalar"] = function(processed, op)
			if !op["per particle"] then
				//uses the speed of the cpoint to set a scalar value, just position_combine it
				cpoint_from_op_value(processed, op, "control point number (ignored if per particle)", "position_combine")
			end
		end,
		["sequence from control point"] = function(processed, op)
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
			cpoint_from_op_value(processed, op, "control point", "axis", {
				vector = true,
				label = {"Sprites 1", "Sprites 2", "Sprites 3"},
				inMin = min,
				inMax = max,
				outMin = min,
				outMax = max,
				default = Vector(0,1,0),
				decimals = 0,
				//info text can't be too specific, since custom fx could potentially use these for any conceivable sprites, and we would have no way of knowing about it
				textentry = {info = "Enter numbers into the boxes to set the effect's sprites. Each number can correspond to a different sprite, and each axis has its own set of sprites."},
			})
		end,
		["set hitbox position on model"] = function(processed, op) cpoint_from_op_value(processed, op, "control_point_number") end, //presumably uses the model that the cpoint is attached to, so use position; TODO: these two are csgo(?) ports and i can't get them to do anything, don't know if they even function in gmod
		["set hitbox to closest hitbox"] = function(processed, op) cpoint_from_op_value(processed, op, "control_point_number") end, //^
		["velocity inherit from control point"] = function(processed, op) cpoint_from_op_value(processed, op, "control point number", "position_combine") end,
		["velocity noise"] = function(processed, op)
			if op["Apply Velocity in Local Space (0/1)"] then //cpoint is only used if this is enabled (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L1243)
				cpoint_from_op_value(processed, op, "Control Point Number", "position_combine")
			end
		end,
		["velocity random"] = function(processed, op)
			local lmin = op.speed_in_local_coordinate_system_min
			local lmax = op.speed_in_local_coordinate_system_max
			if lmin != vector_origin or lmax != vector_origin then //code uses this cpoint if bHasLocalSpeed (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L892), which is determined by this same check (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L855)
				//if !(lmin.x == lmin.y and lmin.x == lmin.z and lmin.x == -lmax.x and lmin.y == -lmax.y and lmin.z == -lmax.z) then
					cpoint_from_op_value(processed, op, "control_point_number", "position_combine")
				//end
			end
		end,
		["velocity repulse from world"] = function(processed, op)
			if !op["Per Particle World Collision Tests"] then //according to code, neither the cpoint nor broadcast-to-children are used with per-particle collision on (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3421)
				if !op["Inherit from Parent"] then
					cpoint_from_op_value(processed, op, "control_point_number", "position_combine") //this cpoint is used to detect nearby world geometry to apply countervelocity away from; no reason this needs to use its own separate grip point, so position_combine it
					local i = op["control points to broadcast to children (n + 1)"] //this also isn't used if inheriting
					if i != -1 then
						local groupid = op["Child Group ID to affect"]
						local name = op._categoryName .. " " .. op.functionName .. ": control points to broadcast to children (n + 1)"
						PEPlus_CPoint_AddToProcessed(processed, i, name, "output_children", {groupid = groupid}, op)
						PEPlus_CPoint_AddToProcessed(processed, i + 1, name, "output_children", {groupid = groupid}, op) //this sets axis 0 to a force value, and the other two to 0 (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_initializers.cpp#L3586)
					end
				else
					//let players manually set the values if they spawned a child effect on its own, or for some hypothetical use case where it's 
					//intended to be supplied by code or something.
					//the way this works is a little complex; the operator has two velocity vectors, "maximum velocity" (min) and "minimum 
					//velocity" (max). by default, the 1st cpoint (a vector) sets the particle velocity to (its vector value * max), so 
					//inputting (1,1,1) sets them to max, while inputting (-1,-1,-1) sets them to negative max. the 2nd cpoint interpolates 
					//it between using min (at 0) to max (at 1) as the multiplier, so at either extreme, it only uses one of the values.
					local sets_pos = op["Offset instead of accelerate"]
					local max = op["maximum velocity"] //these are in worldspace, so if any of the axes are asymmetrical, the velocity will change as your rotate the effect.
					local min = op["minimum velocity"]
					local use_max = math.abs(max.x) > 0 or math.abs(max.y) > 0 or math.abs(max.z) > 0
					local use_min = min != -max and (math.abs(min.x) > 0 or math.abs(min.y) > 0 or math.abs(min.z) > 0) //if min is just negative max, don't bother
					
					if use_max then
						//max/min are in worldspace, so if any of the axes are asymmetrical, the velocity will change as your rotate the effect,
						//so we need to display sliders as 0-1 scalars instead of showing the velocity values. of course. if we're using both
						//max and min, the velocity we're setting will change as we modify the 2nd cpoint, so show a 0-1 scalar in those cases too.
						local is_scalar
						if use_min or max.x != max.y or max.x != max.z or max.y != max.z then
							is_scalar = true
						end
						local outMax
						local label = "Velocity"
						if sets_pos then label = "Position" end
						if is_scalar then
							outMax = Vector(1,1,1)
							label = label .. " Scale"
						else
							outMax = max
						end
						//don't create controls for velocity values that are too small and are just going to get wiped out by drag
						local drag
						if !sets_pos then
							drag = math.max(math.abs(max.x),math.abs(max.y),math.abs(max.z))
							if do_min then drag = math.max(drag, math.abs(min.x),math.abs(min.y),math.abs(min.z)) end
							drag = drag / 5
						end
						cpoint_from_op_value(processed, op, "control_point_number", "axis", {
							vector = true,
							label = {label .. " Back/Fwd", label .. " Right/Left", label .. " Down/Up"},
							inMin = Vector(-1,-1,-1),
							inMax = Vector(1,1,1),
							outMin = -outMax,
							outMax = outMax,
							default = Vector(0,0,0),
							relative_to_cpoint_angle = -1, //-1 value tells the particle entity to use the angle of the first available position control
							overridable_by_drag = drag,
						})
						local name = op._categoryName .. " " .. op.functionName .. ": control_point_number (+ 1 for Inherit from parent)"
						PEPlus_CPoint_AddToProcessed(processed, op.control_point_number + 1, name, "axis", {
							axis = 0,
							label = "Alternate " .. label .. " Value", //TODO: add explanation for player; no existing fx actually have use_min true for now
							inMin = 0,
							inMax = 1,
							outMin = 0,
							outMax = 1,
							default = 1,
							hidden = !use_min, //if the min value isn't useful to the player, then don't add a control, just set the cpoint to 1 in the background
							overridable_by_drag = drag,
						}, op)
						//TODO: add handling for cases where use_min is true but use_max is false; no existing fx actually have use_min true for now
					end
					//according to code, broadcast to children doesn't run if inheriting
				end
			end
		end,
		["velocity set from control point"] = function(processed, op)
			//https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_initializers.cpp#L4160-L4255
			//"control point number"'s position sets the velocity value, local to either the map or to "comparison control point number"
			//"local space control point number"'s ANGLE rotates the velocity value; its position does not matter
			//"direction only" makes the outputted velocity a normalized vector (which is still multiplied by another param)
			cpoint_from_op_value(processed, op, "comparison control point number", "position_combine")
			cpoint_from_op_value(processed, op, "local space control point number", "position_combine")
			local relative_to_cpoint = op["comparison control point number"]
			if !(relative_to_cpoint > -1) then relative_to_cpoint = nil end
			local outMax = 1024 //arbitrary
			local inMax = outMax / op["velocity scale"]
			local default = 100 / op["velocity scale"]
			local label = {"Velocity Back/Fwd", "Velocity Right/Left", "Velocity Down/Up"}
			if op["direction only"] then
				inMax = 1
				outMax = 1
				default = 1
				label = {"Velocity Direction Back/Fwd", "Velocity Direction Right/Left", "Velocity Direction Down/Up"}
			end
			local relative_to_cpoint_angle = op["local space control point number"]
			if !(relative_to_cpoint_angle > -1) then
				relative_to_cpoint_angle = -1 //-1 value tells the particle entity to use the angle of the first available position control
			else
				relative_to_cpoint_angle = nil
			end
			cpoint_from_op_value(processed, op, "control point number", "axis", {
				vector = true,
				label = label,
				inMin = Vector(-inMax,-inMax,-inMax),
				inMax = Vector(inMax,inMax,inMax),
				outMin = Vector(-outMax,-outMax,-outMax),
				outMax = Vector(outMax,outMax,outMax),
				default = Vector(default,0,0),
				relative_to_cpoint = relative_to_cpoint,
				relative_to_cpoint_angle = relative_to_cpoint_angle
			})
		end,
	},
	emitters = {
		["emit noise"] = function(processed, op)
			if op["emission minimum"] > 0 or op["emission maximum"] > 0 then
				op._starttime = op.emission_start_time //store this in the unprocessed operator so the _generic func below can access it
				processed.has_emitter = true
			end
			processed.pathseqcheck_disable = true
		end,
		["emit to maintain count"] = function(processed, op)
			if op["count to maintain"] > 0 then
				op._starttime = op["emission start time"] //store this in the unprocessed operator so the _generic func below can access it; yes, it lacks underscores in just this one operator
				processed.has_emitter = true
			end
			local axis = op["maintain count scale control point field"]
			if axis > -1 then
				cpoint_from_op_value(processed, op, "maintain count scale control point", "axis", {
					axis = axis,
					label = "Maintain Count Scale",
					inMin = 0,
					outMin = 0,
					//no max
					default = 1,
				})
			end
			processed.pathseqcheck_disable = true
		end,
		emit_continuously = function(processed, op)
			if op.emission_rate > 0 then
				op._starttime = op.emission_start_time //store this in the unprocessed operator so the _generic func below can access it
				processed.has_emitter = true
				if processed.do_starttime_raw_fromrate then
					op._starttime_raw_fromrate = 1 / op.emission_rate //store this in the unprocessed operator so the _generic func below can access it
				end
			end
			local axis = op["emission count scale control point field"]
			if axis > -1 then
				cpoint_from_op_value(processed, op, "emission count scale control point", "axis", {
					axis = axis,
					label = "Emission Count Scale",
					inMin = 0,
					inMin_strict = 0, //if this control goes below 0, it'll crash
					outMin = 0,
					//no max
					default = 1,
				})
			end
			processed.pathseqcheck_disable = true
		end,
		//"emit noise" and "emit_continuously" have "scale emission to used control points", which wiki claims is a cpoint id, but it's actually a float that's multiplied by the number of cpoints the effect has, we don't care about this (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_particle_emitters.cpp#L449)
		emit_instantaneously = function(processed, op)
			if op.num_to_emit_minimum > 0 or op.num_to_emit > 0 then
				op._starttime = op.emission_start_time //store this in the unprocessed operator so the _generic func below can access it
				//TODO: do we want to handle op["emission_start_time max"], which is unique to this one? https://github.com/nillerusr/Kisak-Strike/blob/master/particles/builtin_particle_emitters.cpp#L139
				processed.has_emitter = true
				processed.pathseqcheck_particles = op.num_to_emit //TODO: do we need to account for num_to_emit_minimum here?
			end
			local axis = op["emission count scale control point field"]
			if axis > -1 then
				cpoint_from_op_value(processed, op, "emission count scale control point", "axis", {
					axis = axis,
					label = "Emission Count Scale",
					inMin = 0,
					inMin_strict = 0, //if this control goes below 0, it'll crash
					outMin = 0,
					//no max
					default = 1,
				})
			end
		end,
		_generic = function(processed, op)
			//store the time it takes for the emitter to start emitting particles; we use this to display info text if necessary
			if op._starttime then //don't do any of this for unhandled emitters that don't supply a start time
				local starttime = math.max(op._starttime,
				op["operator start fadein"]) //some fx use fadein instead (l4d2's barricade_groundfire)
				+ (op._starttime_raw_fromrate or 0) //also add extra time from emission rate
				if processed.starttime_raw != nil then
					processed.starttime_raw = math.min(processed.starttime_raw, starttime)
				else
					processed.starttime_raw = starttime
				end
			end
		end,
	},
	forces = { //ForceGenerator
		["force based on distance from plane"] = function(processed, op) cpoint_from_op_value(processed, op, "Control point number") end, //don't know if the extra overrides on "pull toward control point" are necessary here, i don't think any existing fx need them
		["pull towards control point"] = function(processed, op)
			local force = op["amount of force"]
			local falloff = op["falloff power"]
			local type = nil
			local text = nil
			if (math.abs(force) < 10 and falloff >= 0) //force can be negative to push particles away; falloff power can be negative to make it stronger the farther away it gets
			or falloff >= 3 then
				//a lot of effects have this operator with miniscule force values, for whatever reason. they don't visibly appear to do anything, maybe it's part of some hacky workaround
				//that particle developers use, i don't know. either way, don't let them create their own position control in these cases, because they aren't useful.
				type = "position_combine"
			else
				if force > 0 then
					if falloff > 0 then
						text = "pulls nearby particles toward itself"
					else
						text = "pulls particles toward itself"
					end
				else
					if falloff > 0 then
						text = "pushes nearby particles away"
					else
						text = "pushes particles away"
					end
				end
			end
			cpoint_from_op_value(processed, op, "control point number", type, {
				overridable_by_constraint = true, 
				overridable_by_drag = 0.98, //stupid handling for one effect that has a cpoint with just a force "move towards control point", but also maximum drag on its movement basic that makes the force not work (particles/taunt_fx.pcf taunt_yeti_fistslam_whirlwind)
				dont_offset_distance_scalar = true,
				info = text,
			})
		end
	},
	constraints = {
		//"collision via traces" always sets cpoint 0 in pet, but this doesn't seem necessary, it functions just fine without it in a test effect using only cpoint 1, and even if we add another cpoint for 0 it doesn't actually seem to do anything; can't find any code actually using a cpoint either (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L630-L1098)
		["constrain distance to control point"] = function(processed, op)
			if !op["global center point"] then //according to code, cpoint is only used if global center point is false (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L87)
				cpoint_from_op_value(processed, op, "control point number", nil, {sets_particle_pos = true}) //pet doesn't add control for this
				if op["maximum distance"] < 1 then
					processed.constraint_does_override = true //global value on the effect, not cpoint-specific
				end
			end
		end,
		["constrain distance to path between two control points"] = function(processed, op)
			cpoint_from_op_value(processed, op, "start control point number", nil, {sets_particle_pos = true})
			cpoint_from_op_value(processed, op, "end control point number", nil, {sets_particle_pos = true})
			//if there's no way for other cpoint operators (like the ones that initialize in a box/sphere) to influence the particles because this constraint forces them onto a very specific path, then don't make position controls for those cpoints
			if op["maximum distance"] < 1 then
				processed.constraint_does_override = true //global value on the effect, not cpoint-specific
			end
		end,
		//"constrain particles to a box" is in worldspace only?? why? what is this for?
		["prevent passing through a plane"] = function(processed, op)
			if !op["global origin"] or !op["global normal"] then
				local norm = Vector(op["plane normal"])
				local x = norm.x //x and y values are swapped, and y is negative. why does this normal and *only* this normal use a totally different coordinate system?
				norm.x = norm.y
				norm.y = -x
				cpoint_from_op_value(processed, op, "control point number", nil, {
					plane = {
						pos = op["plane point"],
						normal = norm,
						pos_global = op["global origin"],
						normal_global = op["global normal"],
					}
				})
			end
		end,
		//code says this one always uses cpoint 0 for some trace stuff, but when trying to test it, on every single effect i could find or make with this operator, it just doesn't seem to work at all? particles pass through brushes, displacements, and static props just fine. (https://github.com/nillerusr/source-engine/blob/master/particles/builtin_constraints.cpp#L473)
		//TODO: test on a map that isn't gm_flatgrass, maybe it's a problem with distance from the world origin or something
		//["prevent passing through static part of world"] = function(processed, op) PEPlus_CPoint_AddToProcessed(processed, 0, op._categoryName .. " " .. op.functionName .. ": always uses cpoint 0", nil, nil, op) end,
	}
}
local PEPlus_BadMaterials = PEPlus_BadMaterials or {}
local blacklist_screenfx = GetConVar("sv_peplus_blacklist_screenspace")
function PEPlus_ProcessPCF(filename)
	local original_filename = filename
	if PEPlus_AllDataPCFs[filename] then original_filename = PEPlus_AllDataPCFs[filename].original_filename end //make sure hook funcs receive the original pcf file path, not a data pcf file path, becaues the latter isn't consistent between sessions

	if hook.Call("PEPlus_PreProcessPCF", nil, original_filename) == false then return end //Let hook funcs prevent PCFs from being read by returning false

	//don't print non-critical messages unless we're in developer mode; 
	//always print messages for bugs that player should report
	local dodebug = (GetConVarNumber("developer") >= 1)

	local t = PEPlus_ReadPCF(filename)
	if !t then
		if dodebug then MsgN("PEPlus_ProcessPCF: ", filename, " couldn't be read") end
	else
		PEPlus_CulledFx[filename] = {}
		local t2 = {}
		for particle, ptab in pairs (t) do
			local processed = {
				cpoints = {},
				children = t[particle].children,
				parents = {},
				do_starttime_raw_fromrate = ptab.initial_particles <= 0, //for emitter starttime calculation, don't add extra time from the emission rate if we have initial particles; have to do this here because the processfunc needs this info
			}
			if CLIENT then processed.nicename = t[particle]._nicename end //properly capitalized name for display purposes
			//Go through all of the effects's operators (initializers, operators, renderers, etc. are all called "operators" internally, it's confusing) 
			//and use the corresponding functions in processfuncs to "process" them (populate the table above with all their relevant cpoint info). 
			//This is the meat of this function, everything else is just working with this info.
			for k, v in pairs (processfuncs) do
				if ptab[k] then
					for _, op in pairs (ptab[k]) do
						local sf = op["operator start fadein"]
						local ef = op["operator end fadein"]
						if !sf or !ef or (!(sf >= 99) and !(ef >= 99)) then //some fx use a superlong fadein to effectively comment out operators, ridiculous (particles/advisor_fx.pcf Advisor_Psychic_Attach_01b operator Remap Distance to Control Point to Scalar)
							op._categoryName = k
							if v[op.functionName] then v[op.functionName](processed, op) end
							if v._generic then v._generic(processed, op) end
						end
					end
				end
			end
			//also process a couple things that are stored in the main table and not in operators
			if ptab.cull_radius > 0 then //(https://github.com/VSES/SourceEngine2007/blob/master/src_main/particles/particles.cpp#L500-L503)
				cpoint_from_op_value(processed, ptab, "cull_control_point", "position_combine", {
					ignore_outputs = true, //unlike the other things that ignore outputs, this one actually does set a position, but outputs still don't override it because it runs first i guess
					dont_inherit = true,
				}) //this system only runs if an obscure cheat command cl_particle_retire_cost is enabled (https://developer.valvesoftware.com/wiki/Particle_System_Properties), and also only runs on the frame a particle is spawned (https://github.com/nillerusr/source-engine/blob/master/game/client/particlemgr.cpp#L1707); culls the particle by deleting it (or optionally spawning an alternative particle) if this cpoint is taking up too much of the screen
			end
			cpoint_from_op_value(processed, ptab, "control point to disable rendering if it is the camera", "position_combine", {
				ignore_outputs = true, //this cpoint sets an associated model, not a position, so outputs don't override it
				dont_inherit = true,
			}) //makes the particle not render if this cpoint is attached to the ent the camera is viewing from (i.e. the player, or a camera ent they're using)
			if ptab.preventNameBasedLookup then
				processed.prevent_name_based_lookup = true //makes the particle impossible to spawn on its own, but still usable as a child. not sure what the point of this is.
			end
			if ptab.initial_particles > 0 then
				processed.has_emitter = true
			end
			t2[particle] = processed
			//Also store "screen space effect" here (so we can disable these with a convar)
			if ptab["screen space effect"] then
				processed.screenspace = true
			end
			//"pathseqcheck": cull cpoints added by initializer "position along path sequential" that emitter "emit_instantaneously" doesn't emit enough particles to actually use; 
			//we have to do this here because the initializer's processfunc doesn't have a way to get the emitted particle count, and we want to do all this before inheritance.
			//(for particles/summer2025_unusuals.pcf's utaunt_waterwave_lensflare child fx)
			if processed.pathseqcheck and !processed.pathseqcheck_disable then
				local count = processed.pathseqcheck_particles or -math.huge
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
			local mat = "materials/" .. ptab.material
			if !string.EndsWith(mat, ".vmt") then mat = mat .. ".vmt" end
			if PEPlus_BadMaterials[mat] == nil then PEPlus_BadMaterials[mat] = file.Exists(mat, "GAME") end
			if !PEPlus_BadMaterials[mat] then
				t2[particle].has_renderer = false
			else
				//Don't count fx as having a renderer if they have 0 alpha, since they won't render visibly
				if processed.has_zero_alpha and !processed.ignore_zero_alpha then
					processed.has_renderer = false
				end
				//Get and cache particle min distance from materials (used for info text)
				//The intention here is to prevent cases where a player spawns an effect on the ground in front 
				//of them, can't see anything because it's too close to render, and mistakenly thinks it's broken.
				if CLIENT and t2[particle].has_renderer and t2[particle].has_emitter then
					if true or isbool(PEPlus_BadMaterials[mat]) then
						local mat2 = Material(string.Replace(string.TrimLeft(mat, "materials/"), "\\", "/"))
						PEPlus_BadMaterials[mat] = {
							min = mat2:GetFloat("$endfadesize") or 20, //for mats that don't have these values at all (not SpriteCard), act as if they're default
							min_alt = mat2:GetFloat("$maxsize") or 20,
						}
					end
					processed.dist_min = PEPlus_BadMaterials[mat].min
					processed.dist_min_alt =  PEPlus_BadMaterials[mat].min_alt
				end
			end
		end
		for particle, _ in pairs (t2) do
			if !t2[particle].has_renderer then
				for _, childtab in pairs (t2[particle].children) do
					if t2[childtab.child] and t2[childtab.child].parent_force_has_renderer then
						t2[particle].has_renderer = true 
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
					MsgN("PEPlus_ProcessPCF: ", filename, " ", particle2, " child ", child, " cpoints_from_child_fx has crazy recursion when trying to get child fx, aborting - report this bug!") //don't even know if this is possible, but want to be safe anyway
					return cpoints
				end
				for _, childtab in pairs (t[particle2].children) do
					if t2[childtab.child] and !childtab["end cap effect"] then //"end cap effect" children aren't supposed to run until the effect ends. in practice, they don't seem to run *at all*, and i can't find any code that would call StopEmission with the right arg to trigger them. (https://github.com/search?q=repo%3Anillerusr%2FKisak-Strike+StopEmission&type=code)
						local cpoints2 = table.Copy(t2[childtab.child].cpoints)
						//make sure the child has also inherited cpoints from its own children
						//if #t[childtab.child].children > 0 then MsgN("children of ", childtab.child, ":") PrintTable(t[childtab.child].children) end
						for _, childtab2 in pairs (t[childtab.child].children) do
							if t2[childtab2.child] and !childtab2["end cap effect"] then
								local cpoints3 = cpoints_from_child_fx(table.Copy(t2[childtab2.child].cpoints), childtab2.child, depth)
								for i, tab in pairs (cpoints3) do
									cpoints2[i] = cpoints2[i] or {}
									for processedk, processedv in pairs (tab) do
										for k, v in pairs (processedv) do
											//mark operators as being inherited from a child
											if v.name then
												processedv[k].name = "child " .. childtab2.child .. " | " .. processedv[k].name
											end
											if v.label then
												processedv[k].label_childname = processedv[k].label_childname or ("'" .. childtab2.child .. "' ")
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
						//inherit cpoints from the child
						for i, tab in pairs (cpoints2) do
							cpoints[i] = cpoints[i] or {}
							for processedk, processedv in pairs (tab) do
								for k, v in pairs (processedv) do
									//mark operators as being inherited from a child
									if v.name then
										processedv[k].name = "child " .. childtab.child .. " | " .. processedv[k].name
									end
									if v.label then
										processedv[k].label_childname = processedv[k].label_childname or ("'" .. childtab.child .. "' ")
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
			//Store the PEPLUS_CPOINT_MODE_ for each cpoint
			local modes = {}
			local output_children = {}
			local output_axis = {}
			local on_model = nil
			local cpoint_planes = nil
			local distance_scalars = nil
			local dont_offset_distance_scalar = nil
			local tracer_min_distance = nil
			local cpoint_info_text = nil
			local sets_particle_pos = nil
			local copy_sets_particle_pos = nil
			local remove_if_other_cpoint_is_empty = {}
			local function SetCPointModes(particle2, parent)
				//a little heavy-handed? maybe. might result in some false positives in complex hierarchy trees. haven't found any actual examples of this causing problems,
				//and we'd have to totally rework how we handle hierarchy here to make this more accurate (currently have no way to get the parent of a parent, etc. to check if
				//it's using output_children); output_children[parent] structure probably does limits wrong if a parent has multiple children of the same effect, who then
				//themselves use output_children (they'd all share the same limit), but no existing fx use a complicated structure like that.

				local groupid = t[particle2]["group id"]

				if parent and !output_children[parent] then
					tab = nil
					for k, v in pairs (t2[parent].cpoints) do
						if v.output_children then
							for k2, v2 in pairs (v.output_children) do
								if v2.groupid then
									tab = tab or {}
									tab[k] = tab[k] or {}
									//"limit" value sets the number of children to override the target cpoint on;
									//use the largest possible limit provided, no limit provided means unlimited
									local limit = v2.limit or math.huge
									if tab[k][v2.groupid] then
										limit = math.max(limit, tab[k][v2.groupid])
									end
									tab[k][v2.groupid] = limit
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
						if v.output_axis then
							for k2, v2 in pairs (v.output_axis) do
								if v2.axis then
									output_axis[k] = output_axis[k] or {}
									output_axis[k][v2.axis] = true
								end
							end
						end
						local did_output = false
						if v.output or (istable(output_axis[k]) and output_axis[k][0] and output_axis[k][1] and output_axis[k][2]) then
							//- outputs override the target cpoint on the effect itself, and on all of its children
							//- outputs on the children of an effect do NOT override the target cpoint on their parent
							//- output_axis follows the same two rules above but only overrides a single axis
							if modes[k] == nil then
								did_output = true
								modes[k] = PEPLUS_CPOINT_MODE_NONE
							end
						end
						remove_if_other_cpoint_is_empty[k] = {}
						if v.position then
							//If we're inheriting the cpoint mode from a child, make sure it's not from an operator that shouldn't be inherited
							local newtab = {}
							for k2, v2 in pairs (v.position) do
								if !(parenttab and v2.dont_inherit) --[[and !(t2[particle2].constraint_does_override and v2.overridable_by_constraint)]] then
									newtab[k2] = v2
								end
							end
							//Make sure to check for the "ignore_outputs" value for operators that aren't overridden by output
							local ignore_outputs = false
							for k2, v2 in pairs (newtab) do
								if v2.ignore_outputs then
									ignore_outputs = true
									break
								end
							end
							for k2, v2 in pairs (newtab) do
								if v2.pathseqcheck_fail then continue end
								if (t2[particle2].has_renderer and t2[particle2].has_emitter) or v2.doesnt_need_renderer_or_emitter then
									if modes[k] == nil or modes[k] == PEPLUS_CPOINT_MODE_POSITION_COMBINE or (did_output and ignore_outputs) then
										if (t2[particle2].constraint_does_override and v2.overridable_by_constraint)
										or (v2.overridable_by_drag and t2[particle2].drag_for_override 
										and t2[particle2].drag_for_override >= v2.overridable_by_drag) then
											modes[k] = PEPLUS_CPOINT_MODE_POSITION_COMBINE
										else
											modes[k] = PEPLUS_CPOINT_MODE_POSITION
										end
										did_output = false //make sure position_combine below doesn't override this
									end
									if modes[k] == PEPLUS_CPOINT_MODE_POSITION then
										//also make a list of all the cpoints that have "on_model" fx so that we can print extra info about it in spawnicons
										if CLIENT and v2.on_model then
											on_model = on_model or {}
											on_model[k] = true
										end
										//also make a list of cpoints that define a cull plane, so we can reposition them and draw helpers for them
										if v2.plane then
											cpoint_planes = cpoint_planes or {}
											cpoint_planes[k] = cpoint_planes[k] or {}
											table.insert(cpoint_planes[k], v2.plane)
										end
										//also make a list of distance scalars
										if v2.distance_scalar then
											distance_scalars = distance_scalars or {}
											distance_scalars[k] = distance_scalars[k] or {}
											table.insert(distance_scalars[k], v2.distance_scalar)
										end
										//also inherit tracer_min_distance stuff here
										if v2.tracer_min_distance and t2[particle2].tracer_min_distance_hasdecay then
											tracer_min_distance = tracer_min_distance or {}
											tracer_min_distance[k] = math.max((tracer_min_distance[k] or 0), v2.tracer_min_distance)
										end
										//also inherit cpoint info text
										if CLIENT and v2.info then
											cpoint_info_text = cpoint_info_text or {}
											cpoint_info_text[k] = cpoint_info_text[k] or {}
											cpoint_info_text[k][v2.info] = true
										end
										//also check for "remove_if_other_cpoint_is_empty"; we only care about this if ALL position controls for this cpoint have this
										local remove = v2.remove_if_other_cpoint_is_empty
										if remove != nil and remove_if_other_cpoint_is_empty[k] != nil then
											remove_if_other_cpoint_is_empty[k][remove] = true
										else
											remove_if_other_cpoint_is_empty[k] = nil
										end
									end
								end
								if v2.sets_particle_pos and !t2[particle2].sets_particle_pos_forcedisable then
									sets_particle_pos = sets_particle_pos or {}
									sets_particle_pos[k] = true
								end
								if v2.dont_offset_distance_scalar then //for operators that don't set particle pos, but still should prevent distance scalar operators on the same cpoint from moving the cpoint
									dont_offset_distance_scalar = dont_offset_distance_scalar or {}
									dont_offset_distance_scalar[k] = true
								end
								if v2.copy_sets_particle_pos then
									copy_sets_particle_pos = copy_sets_particle_pos or {}
									copy_sets_particle_pos[k] = copy_sets_particle_pos[k] or {}
									table.Merge(copy_sets_particle_pos[k], v2.copy_sets_particle_pos) 
								end
							end
						end
						if v.position_combine then
							//If we're inheriting the cpoint mode from a child, make sure it's not from an operator that shouldn't be inherited
							local newtab = {}
							if parenttab then
								for k2, v2 in pairs (v.position_combine) do
									if !v2.dont_inherit then
										newtab[k2] = v2
									end
								end
							else
								newtab = v.position_combine
							end
							//Make sure to check for the "ignore_outputs" value for operators that aren't overridden by output
							local ignore_outputs = false
							for k2, v2 in pairs (newtab) do
								if v2.ignore_outputs then
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
								if ((t2[particle2].has_renderer and t2[particle2].has_emitter) or v2.doesnt_need_renderer_or_emitter) 
								and (!t2[particle2].movement_lock or !t2[particle2].movement_lock[k] or t2[particle].movement_lock_cpoint == k) then
									if modes[k] == nil or (did_output and ignore_outputs) then
										modes[k] = PEPLUS_CPOINT_MODE_POSITION_COMBINE
									end
								end
								if v2.sets_particle_pos and !t2[particle2].sets_particle_pos_forcedisable then
									sets_particle_pos = sets_particle_pos or {}
									sets_particle_pos[k] = true
								end
								if v2.dont_offset_distance_scalar then //for operators that don't set particle pos, but still should prevent distance scalar operators on the same cpoint from moving the cpoint
									dont_offset_distance_scalar = dont_offset_distance_scalar or {}
									dont_offset_distance_scalar[k] = true
								end
								if v2.copy_sets_particle_pos then
									copy_sets_particle_pos = copy_sets_particle_pos or {}
									copy_sets_particle_pos[k] = copy_sets_particle_pos[k] or {}
									table.Merge(copy_sets_particle_pos[k], v2.copy_sets_particle_pos)
								end
							end
						end
						if v.axis then
							local doaxis = false
							if modes[k] == nil then
								for k2, v2 in pairs (v.axis) do
									if !(v2.overridable_by_drag and t2[particle2].drag_for_override 
									and t2[particle2].drag_for_override >= v2.overridable_by_drag)
									//handle output_axis overriding specific axes
									and (!istable(output_axis[k]) or ((v2.axis != nil) and !output_axis[k][v2.axis]) 
									or (v2.vector and (!output_axis[k][0] or !output_axis[k][1] or !output_axis[k][2]))) then
										doaxis = true
									end
								end
							end
							if doaxis and (t2[particle2].has_renderer and t2[particle2].has_emitter) then
								modes[k] = PEPLUS_CPOINT_MODE_AXIS
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
					if CLIENT then
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
			end
			SetCPointModes(particle)
			//Cpoints that haven't been filled in yet should inherit from children
			local function CPointModesFromChildren(particle2, depth)
				depth = depth or 0
				depth = depth + 1
				if depth > 99 then
					MsgN("PEPlus_ProcessPCF: ", filename, " ", particle2, " CPointModesFromChildren has crazy recursion when trying to get child fx, aborting - report this bug!") //don't even know if this is possible, but want to be safe anyway
					return
				end

				for _, childtab in pairs (t2[particle2].children) do
					if !t2[childtab.child] then
						if dodebug then MsgN("PEPlus_ProcessPCF: ", filename, " ", particle2, " CPointModesFromChildren tried to get nonexistent child effect ", child) end
					elseif !childtab["end cap effect"] then //"end cap effect" children aren't supposed to run until the effect ends. in practice, they don't seem to run *at all*, and i can't find any code that would call StopEmission with the right arg to trigger them. (https://github.com/search?q=repo%3Anillerusr%2FKisak-Strike+StopEmission&type=code)
						SetCPointModes(childtab.child, particle2)
						//Now inherit from the child's children, and so on
						//TODO: the order here might not be quite right if we have multiple branching children of children, but I don't know if that actually matters in practice
						CPointModesFromChildren(childtab.child, depth)
					end
				end
			end
			CPointModesFromChildren(particle)

			//Do remove_if_other_cpoint_is_empty thing for operator "set control point positions"; this operator has "parent" cpoints that move 
			//around "child" cpoints, but if those child cpoints don't actually do anything, then the parent cpoints are useless, so remove them.
			for k, v in pairs (remove_if_other_cpoint_is_empty) do
				if istable(v) and table.Count(v) > 0 and modes[k] == PEPLUS_CPOINT_MODE_POSITION then
					local empty = true
					for k2, _ in pairs (v) do
						if t2[particle].cpoints_with_children[k2] and t2[particle].cpoints_with_children[k2].position then
							empty = false
							break
						end
					end
					if empty then
						//MsgN(particle, ": empty detected: cpoint ", k)
						modes[k] = PEPLUS_CPOINT_MODE_NONE
					end
				end
			end

			local shouldcull = !t2[particle].has_renderer or !t2[particle].has_emitter
			local pos_control_count = 0
			local needfallback = -1
			for k, v in pairs (modes) do
				if !shouldcull and !needfallback and pos_control_count > 1 then break end
				if shouldcull and v != PEPLUS_CPOINT_MODE_NONE then
					//Clear out empty effects (no renderer, no emitter, no cpoints even from children)
					shouldcull = false
				end
				if v == PEPLUS_CPOINT_MODE_POSITION then
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
				t2[particle].renderer_emitter_shouldcull = true
			end
			if needfallback then
				if !modes[0] then
					//just use cpoint 0 if it's open
					needfallback = 0
				else
					//If possible, turn the first available position_combine cpoint into a normal position cpoint
					for k, v in SortedPairs (modes) do
						if k != -1 and v == PEPLUS_CPOINT_MODE_POSITION_COMBINE then
							needfallback = k
							break
						end
					end
				end
				//if neither of those work, then use the nonsense cpoint -1, which is probably fine since it's most likely
				//not going to be able to do anything anyway; it's just there so we have an entity to associate the effect with.

				t2[particle].cpoints_with_children[needfallback] = t2[particle].cpoints_with_children[needfallback] or {}
				t2[particle].cpoints_with_children[needfallback].position = t2[particle].cpoints_with_children[needfallback].position or {}
				table.insert(t2[particle].cpoints_with_children[needfallback].position, {name = "fallback position cpoint created due to no position cpoint"})

				modes[needfallback] = PEPLUS_CPOINT_MODE_POSITION
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
					if modes[k] == PEPLUS_CPOINT_MODE_POSITION or modes[k] == PEPLUS_CPOINT_MODE_POSITION_COMBINE then
						sets_particle_pos_2 = sets_particle_pos_2 or {}
						sets_particle_pos_2[k] = true
					end
				end
			end
			t2[particle].sets_particle_pos = sets_particle_pos_2

			//Do info text for on_model
			if CLIENT and on_model then
				if pos_control_count and pos_control_count == 1 then
					PEPlus_AddInfoText(t2[particle], "Applies to a whole model if attached")
				else
					local text = ""
					local docomma = false
					for k, _ in pairs (on_model) do
						if docomma then text = text .. ", " end
						text = text .. k
						docomma = true
					end
					local text2
					if table.Count(on_model) > 1 then
						text2 = "Applies to a whole model if control points %CPOINTS are attached"
					else
						text2 = "Applies to a whole model if control point %CPOINTS is attached"
					end
					PEPlus_AddInfoText(t2[particle], string.Replace(text2, "%CPOINTS", text))
				end
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
					if CLIENT then
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
							text2 = "Control points %CPOINTS control planes that prevent particles from passing through"
						else
							text2 = "Control point %CPOINTS controls a plane that prevents particles from passing through"
						end
						PEPlus_AddInfoText(t2[particle], string.Replace(text2, "%CPOINTS", text))
					end
				end

				//Do min cpoint distance for tracer fx
				if tracer_min_distance then
					t2[particle].cpoint_distance_overrides = t2[particle].cpoint_distance_overrides or {}
					for k, v in pairs (tracer_min_distance) do
						t2[particle].cpoint_distance_overrides[k] = {
							min = v
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
							increase = {},
							decrease = {},
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
							if CLIENT then
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
									text = "Control point " .. k .. " increases and decreases " .. text_decrease .. " of particles as they get closer to it"
								elseif table.Count(text.increase) == 0 then
									text = "Control point " .. k .. " decreases " .. text_decrease .. " of particles as they get closer to it"
								elseif table.Count(text.decrease) == 0 then
									text = "Control point " .. k .. " increases " .. text_increase .. " of particles as they get closer to it"
								else
									text = "Control point " .. k .. " increases " .. text_increase .. " and decreases " .. text_decrease .. " of particles as they get closer to it"
								end
								PEPlus_AddInfoText(t2[particle], text)
							end
						end
					end
				end

				//Do position control info text
				if CLIENT and cpoint_info_text and t2[particle].sets_particle_pos then
					for k, v in pairs (cpoint_info_text) do
						//This is for position control cpoints that don't set particle positions, but are instead used for some
						//less intuitive purpose like applying force or acting as a rotation target. 
						//
						//The idea is that if a cpoint is being used to spawn or constrain particles, then it should immediately 
						//be visually obvious that the cpoint is useful, meaning no text is required and any other things like 
						//forces on the same cpoint are just a bonus (i.e. don't clutter up info text with a dozen tiny nuances 
						//on top of positioning that the player doesn't care about). 
						//
						//On the other hand, if a cpoint is ONLY used for one of these other things, then the player will spawn 
						//the effect and see an extra cpoint with no immediately clear purpose - these we need to explain.
						if !t2[particle].sets_particle_pos[k] then
							local text = "Control point " .. k .. " "
							local docomma = false
							for k2, _ in pairs (v) do
								if docomma then text = text .. ", " end
								text = text .. k2
								docomma = true
							end
							PEPlus_AddInfoText(t2[particle], text)
						end
					end
				end
			end

			if CLIENT then
				//Inherit starttime and min particle distance from children, and add info text if necessary
				local starttime = t2[particle].starttime_raw
				local min = t2[particle].dist_min
				local min_alt = t2[particle].dist_min_alt
				local function StartTimeFromChildren(particle2, depth, child_delay)
					depth = depth or 0
					depth = depth + 1
					if depth > 99 then
						MsgN("PEPlus_ProcessPCF: ", filename, " ", particle2, " StartTimeFromChildren has crazy recursion when trying to get child fx, aborting - report this bug!") //don't even know if this is possible, but want to be safe anyway
						return
					end

					for _, childtab in pairs (t2[particle2].children) do
						if !t2[childtab.child] then
							if dodebug then MsgN("PEPlus_ProcessPCF: ", filename, " ", particle2, " StartTimeFromChildren tried to get nonexistent child effect ", child) end
						elseif !childtab["end cap effect"] then //"end cap effect" children aren't supposed to run until the effect ends. in practice, they don't seem to run *at all*, and i can't find any code that would call StopEmission with the right arg to trigger them. (https://github.com/search?q=repo%3Anillerusr%2FKisak-Strike+StopEmission&type=code)
							if t2[childtab.child].starttime_raw != nil then
								//starttime
								if starttime == nil then
									starttime = t2[childtab.child].starttime_raw + (childtab.delay or 0) + child_delay
								else
									starttime = math.min(t2[childtab.child].starttime_raw + (childtab.delay or 0) + child_delay, starttime)
								end
								//particle distance
								if min == nil then
									min = t2[childtab.child].dist_min
								elseif t2[childtab.child].dist_min != nil then
									min = math.max(min, t2[childtab.child].dist_min)
								end
								if min_alt == nil then
									min_alt = t2[childtab.child].dist_min_alt
								elseif t2[childtab.child].dist_min_alt != nil then
									min_alt = math.max(min, t2[childtab.child].dist_min_alt)
								end
							end
							//Now inherit from the child's children, and so on
							//TODO: the order here might not be quite right if we have multiple branching children of children, but I don't know if that actually matters in practice
							StartTimeFromChildren(childtab.child, depth, (childtab.delay or 0) + child_delay)
						end
					end
				end
				StartTimeFromChildren(particle, nil, 0)
				//starttime
				if starttime != nil then
					starttime = math.Round(starttime, 2)
					if starttime > 0.5 then
						t2[particle].starttime = starttime
						if starttime == 1 then
							PEPlus_AddInfoText(t2[particle], "Effect starts after " .. starttime .. " second")
						else
							PEPlus_AddInfoText(t2[particle], "Effect starts after " .. starttime .. " seconds")
						end
					end
				end
				//particle distance
				//fadesize is based off the fraction of the screen taken up by the particle (i.e. 0.75 means
				//particles stops rendering once they're 75% the width of the screen), which means the distance 
				//where it takes effect scales with particle radius. we could either A: hook into every single 
				//operator that can modify radius, which would be too much work, or B: be conservative here and 
				//only display this for materials that *definitely* need it, disregarding edge cases. 
				//(for example, hl2's explosion_huge_flames uses the same mat as a bunch of other stock flame fx, 
				//with a fadesize of 0.55, but it's only an issue with the former because it has abnormally large
				//particles, so err on the side of not cluttering up info text with false positives for the latter.)
				if (min != nil and min < 0.5)
				//for mats like materials\particle\smoke1\dust_motes.vmt that use a very
				//low maxsize value to become extremely difficult to see when close up
				or (min_alt != nil and min_alt < 0.01) then
					PEPlus_AddInfoText(t2[particle], "Not visible if too close to the camera")
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
					t2[particle].cpoints[k].mode = PEPLUS_CPOINT_MODE_NONE
				end
				if v.output_axis then
					for k2, v2 in pairs (v.output_axis) do
						t2[particle].cpoints[k]["axis_overridden_" .. v2.axis] = true
					end
				end
				if v.axis then
					//Squish together axis entries that have the same values except for the name
					local newaxes = {}
					local newaxes_by_axis = {
						[0] = {},
						[1] = {},
						[2] = {},
					}
					for k2, v2 in pairs (v.axis) do
						if v.axis[k2] != nil then
							local newtab = table.Copy(v2)
							newtab.labels = {}
							if !newtab.hidden then newtab.labels = {[v2.label_childname or ""] = {[v2.label] = true}} end
							for k3, v3 in pairs (v.axis) do
								if k3 != k2 and v3.axis == v2.axis and v3.vector == v2.vector and v3.inMin == v2.inMin 
								and v3.inMax == v2.inMax and v3.outMin == v2.outMin and v3.outMax == v2.outMax and 
								v3.default == v2.default and v3.decimals == v2.decimals and v3.relative_to_cpoint == 
								v2.relative_to_cpoint and v3.relative_to_cpoint_angle == v2.relative_to_cpoint_angle 
								and v3.colorpicker == v2.colorpicker and v3.textentry == v2.textentry then
									if CLIENT and dodebug then newtab.name = newtab.name .. ",\n" .. v3.name end //these names are only used by the "print processed pcf data" debug option
									if !newtab.hidden then
										newtab.labels[v3.label_childname or ""] = newtab.labels[v3.label_childname or ""] or {}
										newtab.labels[v3.label_childname or ""][v3.label] = true
									end
									v.axis[k3] = nil
								end
							end
							v.axis[k2] = nil
							local i = table.insert(newaxes, newtab)
							if v2.axis != nil then
								table.insert(newaxes_by_axis[v2.axis], i)
							elseif v2.vector then
								table.insert(newaxes_by_axis[0], i)
								table.insert(newaxes_by_axis[1], i)
								table.insert(newaxes_by_axis[2], i)
							end
						end
					end
					t2[particle].cpoints[k].axis = newaxes
					if v.mode == PEPLUS_CPOINT_MODE_AXIS then
						for i = 0, 2 do
							if !t2[particle].cpoints[k]["axis_overridden_" .. i] then
								if #newaxes_by_axis[i] > 0 then
									local newtab = table.Copy(newaxes[newaxes_by_axis[i][1]])
									if newtab.vector then
										for k, v in pairs (newtab) do
											if isvector(v) then
												newtab[k] = v[i+1]
											end
										end
									end
									//If there's only one entry, use that one; if there are multiple 
									//entries with different values, try to combine them together
									if #newaxes_by_axis[i] > 1 then
										//This value is used to round outMins/outMaxs to nice even numbers for things like 
										//texture selectors; this won't function at all if we rescale the values
										newtab.decimals = nil
										for i2 = 2, #newaxes_by_axis[i] do
											local tab2 = newaxes[newaxes_by_axis[i][i2]]
											//The colorpicker is mutually exclusive from other controls, and takes precedence
											if newtab.colorpicker != tab2.colorpicker then
												if newtab.colorpicker then
													//newtab has colorpicker but tab2 doesn't, so just skip it
													continue
												else
													//tab2 has colorpicker but newtab doesn't, so replace newtab
													newtab = table.Copy(tab2)
													if newtab.vector then
														for k, v in pairs (newtab) do
															if isvector(v) then
																newtab[k] = v[i+1]
															end
														end
													end
													continue
												end
											end
											//If an entry should be skipped due to drag, don't use it
											if (tab2.overridable_by_drag and t2[particle].drag_for_override 
											and t2[particle].drag_for_override >= tab2.overridable_by_drag) then
												continue
											elseif (newtab.overridable_by_drag and t2[particle].drag_for_override 
											and t2[particle].drag_for_override >= newtab.overridable_by_drag) then
												newtab = table.Copy(tab2)
												if newtab.vector then
													for k, v in pairs (newtab) do
														if isvector(v) then
															newtab[k] = v[i+1]
														end
													end
												end
												continue
											end
											//If we encounter a conflicting value that can't be combined, bail out
											if newtab.relative_to_cpoint != tab2.relative_to_cpoint 
											or newtab.relative_to_cpoint_angle != tab2.relative_to_cpoint_angle
											or newtab.textentry != tab2.textentry then
												MsgN("PEPlus_ProcessPCF: can't combine axis entries for ", filename, " ", particle, " cpoint ", k, " axis ", i, "; report this bug!")
												//TODO: bail how? no existing fx run into this issue.
											end
											local function CombineValues(val, mathfunc)
												if newtab[val] != nil or tab2[val] != nil then
													if newtab[val] == nil then
														if tab2.vector and isvector(tab2[val]) then
															newtab[val] = tab2[val][i+1]
														else
															newtab[val] = tab2[val]
														end
													elseif tab2[val] != nil then
														if tab2.vector and isvector(tab2[val]) then
															newtab[val] = math[mathfunc](newtab[val], tab2[val][i+1])
														else
															newtab[val] = math[mathfunc](newtab[val], tab2[val])
														end
													end
												end
											end
											//inMin/inMax is the real value that the cpoint itself will get set to;
											//make its range as wide as possible to make the full breadth of possible
											//settings accessible to the user
											CombineValues("inMin", "min")
											CombineValues("inMax", "max")
											//"strict" inMin/inMax, for values that *must* remain within a range to 
											//prevent a crash; these are used later to clamp the final values
											CombineValues("inMin_strict", "max")
											CombineValues("inMax_strict", "min")
											//outMin/outMax is the "display" value of the cpoint, corresponding to
											//the color, radius, etc. value that the cpoint will set on the effect.
											//the numbers created from combining disparate controls together here
											//are basically meaningless, but this is necessary to make combined 
											//colorpicker controls function properly.
											CombineValues("outMin", "min")
											CombineValues("outMax", "max")
											//Err on the side of larger defaults, to try to avoid cases where something
											//like a radius scalar is too small to be visible by default
											CombineValues("default", "max")
											if !tab2.hidden then
												//Don't hide the control unless all combined values are hidden
												newtab.hidden = nil
												//Add labels
												for childname, labels in pairs (tab2.labels) do
													if !newtab.labels[childname] then
														newtab.labels[childname] = labels
													else
														for label, _ in pairs (labels) do
															newtab.labels[childname][label] = true
														end
													end
												end
											end
										end
										//Clamp the final inMin/inMax, if applicable
										if newtab.inMin_strict then
											newtab.inMin = math.max(newtab.inMin, newtab.inMin_strict)
										end
										if newtab.inMax_strict then
											newtab.inMax = math.min(newtab.inMax, newtab.inMax_strict)
										end
									end
									//Make a big combined label for all the controls on this axis
									local str = ""
									local docomma = false
									//First de-tableize vector labels to make sure they don't contain dupes
									local tab = {}
									for effectname, v in pairs (newtab.labels) do
										tab[effectname] = {}
										for label, _ in pairs (v) do
											if istable(label) then
												tab[effectname][label[i+1]] = true
											else
												tab[effectname][label] = true
											end
										end
									end
									newtab.labels = tab
									//Then make the string
									for effectname, v in pairs (newtab.labels) do
										for label, _ in pairs (v) do
											if docomma then str = str .. ", " end
											str = str .. effectname .. label
											docomma = true
										end
									end
									newtab.label = str
									//Special handling for colorpicker:
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
									if newtab.colorpicker then
										newtab.outMin2 = math.Min(newtab.outMin, 0)
										newtab.outMax2 = math.Max(newtab.outMax, 1)
									end
									//Now use the finished table for this axis
									t2[particle].cpoints[k]["axis_" .. i] = newtab
								end
							end
						end
					end
				end
				if SERVER or !dodebug then
					//If we're not in debug mode, then discard all but the essential info to save memory
					//(the extended info is only used by the "print processed pcf data" debug option)
					local newtab = {
						mode = v.mode,
						axis_0 = v.axis_0,
						axis_1 = v.axis_1,
						axis_2 = v.axis_2
					}
					t2[particle].cpoints[k] = newtab
				end
			end

			//Flag effects for culling - we do this before calling the PostProcessPCF hook, so that the hook can override it
			//Cull empty effects
			if t2[particle].renderer_emitter_shouldcull then
				if t2[particle].has_zero_alpha then
					PEPlus_AddCullReason(t2[particle], "#PEPlus_Cull_ZeroAlpha")
				else
					PEPlus_AddCullReason(t2[particle], "#PEPlus_Cull_NoRendererOrEmitter")
				end
			end
			//Cull effects that are stuck at the world origin because they don't have any cpoints setting their particle pos
			if !t2[particle].sets_particle_pos then
				PEPlus_AddCullReason(t2[particle], "#PEPlus_Cull_NoParticlePos")
			end
			//Also, now that their parents have inherited cpoint data from them, cull effects with preventNameBasedLookup, since we can't spawn them on their own.
			if t2[particle].prevent_name_based_lookup then
				PEPlus_AddCullReason(t2[particle], "#PEPlus_Cull_PreventNameBasedLookup")
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
					PEPlus_AddCullReason(t2[particle], "#PEPlus_Cull_ScreenSpace_NotViewModel")
				end
			end
			if screenspace then
				if blacklist_screenfx:GetBool() then
					PEPlus_AddCullReason(t2[particle], "#PEPlus_Cull_ScreenSpace_Blacklisted")
				elseif CLIENT then
					PEPlus_AddInfoText(t2[particle], "Screenspace effect: draws an overlay directly onto the screen")
				end
			elseif CLIENT and vm then
				//Also add info text for viewmodel effects here, because this isn't inherited and doesn't apply to screenspace fx
				PEPlus_AddInfoText(t2[particle], "Viewmodel effect: draws in front of everything, and has a distorted position unless attached to a model on a non-0 attachment")
			end
		end
		//Now that the processed table is finished, let hook funcs modify it arbitrarily (including deciding which fx to cull)
		hook.Call("PEPlus_PostProcessPCF", nil, original_filename, t2)
		for particle, _ in pairs (t2) do
			//Cull bad effects from the table
			local cull = t2[particle].shouldcull //this will be a table if we ran PEPlus_AddCullReason(), or nil otherwise
			PEPlus_CulledFx[filename][particle] = cull
			//If the player starts up the game in developer mode, effects aren't culled, but instead have a warning in the spawnicon telling the dev why they won't show up to players.
			if cull and !dodebug then
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
			if dodebug then MsgN("PEPlus_ProcessPCF: ", filename, " contains no usable effects, ignoring") end
		else
			return t2
		end
	end
end

function PEPlus_AddCullReason(tab, str)
	tab.shouldcull = tab.shouldcull or {}
	table.insert(tab.shouldcull, str)
end

function PEPlus_AddInfoText(tab, str)
	tab.info = tab.info or {}
	table.insert(tab.info, str)
end

//Comprehensive output testing: 
--[[
- All "output" and "output_axis":
- operator "set control point to player"
  - with the output and the operator it overrides on the same effect, overrides everything unless noted
    - doesn't override operators that use the associated model's bones/hitboxes/etc, because this output doesn't change the associated model, just pos/ang (intitializer "position on model random", operator "cull relative to model", operator "movement lock to bone")
    - doesn't override main table "control point to disable rendering if it is the camera", main table "cull_control_point"
    - (TODO: is this right? test output pileups on their own later, seems inconsistent) operator "remap cp speed to cp"'s output_axis erroneously always sends max output if "set control point to player"/"set control point to particles' center" is defined after it outputting to its input cpoint; "set control point to player"/"set control point positions" still outputs the same values if either a "set control point to player"/"set control point positions" is defined after it, outputting to its input cpoint and trying to move it
  - with the output on parent and the operator it overrides on child, same as above
    - interactions with other outputs on the same cpoint, do we care about these?
      - operator "movement match particle velocities"'s output on same cpoint gets squashed by parent's output
      - operator "remap cp speed to cp"'s input cpoint, if moved by a parent output, measures the new cp's speed instead as expected
      - operator "set control point positions"'s input cpoint, if moved by a parent output, uses the new position instead as expected
      - operators "remap cp speed to cp"/"set control point positions"/"set control point to particles' center"/"set control point to player"'s output to a cpoint on child is NOT squashed by parent's output to the same cpoint (!) instead the child uses its own output for that cpoint, while the parent uses *its* own output for *its* cpoint, resulting in multiple cpoints with the same id in different places
  - with the output on child and the operator it overrides on parent, doesn't override anything
    - also, output operators on the parent outputting to the same cpoint do not override the child's output either
- operator "remap cp speed to cp"
  - same as "set control point positions", but for just one axis
- operator "set control point positions", operator "set control point to particles' center"
  - same as "set control point to player", except:
    - doesn't override ang for operators that use ang, because this output doesn't change ang, just pos (renderer "render_animated_sprites"s "orientation control point", constraint "prevent passing through a plane" if !op["global normal"], initializer "position along epitrochoid" "control point number" ang, initializer "position along ring" "control point number" ang, initializer "position from chaotic attractor" "Relative Control point number" ang, initializer "Position Within Sphere Random" "control_point_number" ang if "bias in local system" is in use, initializer "Position Modify Offset Random" "control_point_number" ang if "offset in local space 0/1" is in use) (TODO: check initializers after "position modify offset random", and all non-initializers)
      - any path stuff with operator "bulge control 0=random 1=orientation of start pnt 2=orientation of end point" set to an overwritten cpoint (TODO check stuff before initializer; initializer "Position Along Path Random", initializer "Position Along Path Sequential", initializer "Position In CP Hierarchy"; TODO: check initializers after "position modify offset random")
      - cstrike_achieved and that one beany effect have cpoints being overwritten by "set control point positions" outputs that can still be rotated separately to move the effect around, but this doesn't seem to be a deliberate design feature, since this output is used to composite child fx together all the time. the right course of action here seems to be to omit the overwritten cpoints anyway, instead of keeping more grip points around that only set the angle.
- operator "movement match particle velocities"
  - same as "set control point to player", except:
    - with the output and the operator it overrides on the same effect
      - if a position control exists for the output cpoint, overridable operators will use the cpoint's pos/ang instead of it being overridden by the output pos/ang, except for the ones listed below. (if a position control doesn't exist, the value will be overridden by the output normally.)
	- renderer generic "Visibility Proxy Input Control Point Number" always overrides properly
	- operators will be overridden properly IF they're defined AFTER "movement match particle velocities" in the operators list
	- some initializers ("position along ring", "position in cp hierarchy", "position within box random", "position within sphere random", "position modify warp random", "remap scalar to vector" position, "velocity inherit from control point", "velocity repulse from world") appear to alternate every frame or so between the position control's value, and a point halfway between the position control and the output
	- if no particles exist, child cpoint's value reverts back to the position control value instead of the output value, otherwise overrides properly
    - with the output on parent and the operator it overrides on child, all operators have their pos overridden properly, but ang uses the position control's ang instead if available (except initializer "remap scalar to vector")
- All "output_children":
- operator "set child control points from particle positions"
    TODO
- initializer "velocity repulse from world"
    TODO
- Misc. notes:
- can't test initializer "position within sphere random" value "create in model" because it always crashes upon spawning any particles (blood_impact.pcf/blood_antlionguard_injured_light is the only default effect with this set, and it doesn't crash because it doesn't actually emit any particles); can't test initializers "set hitbox position on model" or "set hitbox to closest hitbox" because i can't get them to work at all, these are csgo? ports anyway)
- main table "control point to disable rendering if it is the camera" or "cull_control_point" don't work on children at all
]]


//Normally, we only need to run this function once per session, when the entity code in ent_peplus calls it. This ensures that it runs AFTER all the autorun code has had 
//a chance to run first and populate the blacklist. However, if the player mounts/unmounts something and calls the GameContentChanged hook (in spawnmenu.lua), we want to 
//run this again. This function is really expensive (~16 sec freezing with a few games and particle addons installed), so we don't want to run it any more than we have to.
//
//This sounds simple, but here's what makes it more complicated: when a player starts a singleplayer game for the first time in a session, the GameContentChanged hook also
//runs on startup. On subsequent games that session, the hook WON'T run on startup. On the server, the GameContentChanged hook runs just AFTER the entity code, but on the 
//client, the hook runs just BEFORE the entity code. What we need to do is somehow ensure the function only runs once on startup, without knowing whether GameContentChanged
//will run on startup or not, and without knowing if GameContentChanged or the entity code will run first, AND do all of this without clobbering unrelated instances of 
//GameContentChanged being run AFTER startup.
//
//Our solution to this is to define a brief "startup" period, during which the function is only allowed to run once, and then after which it can run all it likes. This is 
//controlled by a timer.Simple in the entity code, which sets PEPlus_ReadAndProcessPCFs_StartupIsOver to true after all the stuff mentioned in the last paragraph has had
//time to happen already.
//
//TODO: make sure this works in multiplayer

PEPlus_ReadAndProcessPCFs_StartupHasRun = PEPlus_ReadAndProcessPCFs_StartupHasRun
PEPlus_ReadAndProcessPCFs_StartupIsOver = PEPlus_ReadAndProcessPCFs_StartupIsOver

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

function PEPlus_ReadAndProcessPCFs(new_file_only)

	local starttime = SysTime()

	if !new_file_only then 
		PEPlus_AllPCFPaths = {}
		local function PEPlus_FindAllPCFPaths(dir)
			local files, dirs = file.Find(dir .. "*", "GAME")
			for _, filename in pairs (files) do
				filename = dir .. filename
				if !HasBadEnding(filename, "GAME") then
					table.insert(PEPlus_AllPCFPaths, filename)
				end
			end
			for _, dirname in pairs (dirs) do
				PEPlus_FindAllPCFPaths(dir .. dirname .. "/")
			end
		end
		PEPlus_FindAllPCFPaths("particles/")
	
		PEPlus_PCFsByParticleName_CurrentlyLoaded = {}
		if CLIENT then PEPlus_NoDefPCFs = {} end //cache these so that dupe detection doesn't have to waste several seconds reading all of them again
		PEPlus_CulledFx = {} //also build a list of fx that are culled from ProcessedPCFs, because we still need them for pcf conflict/dupe detection (i.e. load a pcf, it has culled fx with the same name as non-culled fx, so we want to detect that the latter got overwritten by the former, and tell the player about it in spawnicons)

		PEPlus_ProcessedPCFs = {}
		PEPlus_AllDataPCFs = {} //spawnlists, spawnicons, and PEPlus_ProcessPCF use this table to quickly get a data pcf's original filename and path
		for _, filename in pairs (PEPlus_AllPCFPaths) do
			if !ProtectedCall(function() PEPlus_ProcessedPCFs[filename] = PEPlus_ProcessPCF(filename) end) then //don't interrupt the function if we get an error while loading a file
				ErrorNoHalt("PEPlus_ReadAndProcessPCFs: ", filename, " failed to load due to the above error, report this bug!\n(make sure to include the game or addon the PCF came from in your report; enter \"whereis ", filename, "\" (without quotes) into the console if you're not sure)\n\n")
			end
		end
		PEPlus_GamePCFs = {}
		PEPlus_GamePCFs_DefaultPaths = {} //which game is each pcf currently loaded from? nil if not currently loaded from a game.
	end


	//Categorize all the pcfs by searching for them in load priority order
	local allpcfs = {}
	for k, _ in pairs (PEPlus_ProcessedPCFs) do
		allpcfs[k] = true
	end
	allpcfs.UtilFx = nil

	local game_pcf_hashes = {}
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
					if new_file_only and new_file_only != filename then
						//If we're only running this func to add a new file, then we should already have
						//PEPlus_GamePCFs entries for every other file, so just reuse those instead
						if PEPlus_GamePCFs[filename] and PEPlus_GamePCFs[filename][path] then
							filename = PEPlus_GamePCFs[filename][path]
						end
					else
						local original_filename = filename
						if !game_pcf_hashes[filename] then //cache these so we don't have to do this extra file.Read more than once per file
							local f1 = file.Read(filename, "GAME")
							if f1 then game_pcf_hashes[filename] = util.SHA256(f1) end
						end
						local f2 = file.Read(filename, path)
						if f2 then
							f2_hash = util.SHA256(f2)
						end
						//Resolve conflicts where multiple mounted games have different, unique pcf files sharing the same file path. 
						//For example, TF2 has an "explosion.pcf" which shares a name with a pcf from HL2, and a "blood_impact.pcf" 
						//which shares a name with a pcf included in gmod by default. The former will always be overridden if HL2 is 
						//mounted, and the latter will always be overridden no matter what. All of the inaccessible pcfs contain
						//unique effects that we don't want the player to be locked out of using, so write copies of these files to
						//the data folder, and load those instead.
						if game_pcf_hashes[filename] and f2_hash and game_pcf_hashes[filename] != f2_hash then
							local writepath = "peplus_datapcfs/" .. path .. "/" .. filename
							writepath = string.Replace(writepath, ".pcf", ".txt")
							local write_new_file = true
							if file.Exists(writepath, "DATA") then
								local f3 = file.Read(writepath, "DATA")
								if f3 and f2_hash == util.SHA256(f3) then
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
							if !PEPlus_ProcessedPCFs[filename] then
								PEPlus_AllDataPCFs[filename] = {
									original_filename = original_filename,
									path = path
								}
								if ProtectedCall(function() PEPlus_ProcessedPCFs[filename] = PEPlus_ProcessPCF(filename) end) then //don't interrupt the function if we get an error while loading a file
									table.insert(PEPlus_AllPCFPaths, filename)
									if PEPlus_ProcessedPCFs[filename] then //don't do this if ProcessPCF returns nothing
										allpcfs[filename] = true
									end
								else
									ErrorNoHalt("PEPlus_ReadAndProcessPCFs: ", filename, " failed to load due to the above error, report this bug!\n\n")
									//PEPlus_AllDataPCFs[filename] = nil //actually, leave this in place so that spawnicons can show the nicely formatted name; this shouldn't cause false positives anywhere else because they shouldn't be running if the pcf isn't valid
								end
							end
						end
						//Always associate pcfs from games with a game path, whether they're currently using a data pcf or not. This is 
						//used by particle ents and spawnicons, which store the *original* filename and the game path, and then use this 
						//table to retrieve the right pcf for the game. This ensures that that saves/spawnlists continue to work 
						//seamlessly between sessions, even as different combinations of mounted games change which ones use data pcfs.
						PEPlus_GamePCFs[original_filename] = PEPlus_GamePCFs[original_filename] or {}
						PEPlus_GamePCFs[original_filename][path] = filename
						PEPlus_GamePCFs_DefaultPaths[original_filename] = PEPlus_GamePCFs_DefaultPaths[original_filename] or path
					end
				else
					//If the currently loaded instance of this pcf isn't from a game at all, put a blank entry in here for now
					//so that game paths can't overwrite it later
					PEPlus_GamePCFs_DefaultPaths[filename] = PEPlus_GamePCFs_DefaultPaths[filename] or ""
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
	PEPlus_PCFsInDupeOrder = pcfs_dupe_order //global so that PEPlus_GetDuplicateFx can be run again later without rebuilding this table
	PEPlus_GetDuplicateFx() //run this on server too, to build PEPlus_PCFsByParticleName for use by backcomp

	if CLIENT and !new_file_only then
		//Run AddParticles in another particular order, so things like gmod fx take priority by default;
		//this prevents TF2's blood fx from becoming the default when you shoot an NPC, for instance
		//NOTE: had to put gmod+games above addons to prevent an issue where tf2 map particles addon's 
		//particles/brine_salmann_goop.pcf would unintentionally override the default blood fx, is this bad? 
		local pcfs_load_order = {}
		table.Add(pcfs_load_order, pcfs_sorted[1]) //packed into bsp
		table.Add(pcfs_load_order, pcfs_sorted[4]) //garrysmod/particles/ folder
		table.Add(pcfs_load_order, pcfs_sorted[5]) //games
		table.Add(pcfs_load_order, pcfs_sorted[2]) //legacy addons
		table.Add(pcfs_load_order, pcfs_sorted[3]) //workshop addons
		table.Add(pcfs_load_order, pcfs_sorted[6]) //garrysmod/download/ folder
		table.Add(pcfs_load_order, pcfs_sorted[7]) //other
		for _, filename in SortedPairs (pcfs_load_order, true) do
			PEPlus_AddParticles(filename)
		end
		//Next, run AddParticles for all the files that other addons ran AddParticles for before our startup; 
		//this is to ensure we don't break effect replacement addons (i.e. if other addons deliberately try to 
		//override stock fx by loading their own pcf, then make sure those effects take priority by default)
		for _, filename in SortedPairs (PEPlus_AddParticles_PreStartupQueue) do
			PEPlus_AddParticles(filename)
		end
		//don't clear PEPlus_AddParticles_PreStartupQueue, we can use it again 
		//if we have to rerun this func later (i.e. sv_peplus_reloadpcfs all)
	end


	//clean unnecessary entries out of this table now that we're done building it
	for k, v in pairs (PEPlus_GamePCFs_DefaultPaths) do
		if v == "" then //if PEPlus_GamePCFs[k] == nil then
			PEPlus_GamePCFs_DefaultPaths[k] = nil
		end
	end

	if !new_file_only then 
		//add util fx to processedpcfs as well, so that particle entities and spawnicons can use them natively
		PEPlus_ProcessUtilFx()

		PEPlus_ReadAndProcessPCFs_StartupHasRun = true

		MsgN("PEPlus_ReadAndProcessPCFs: took " , SysTime() - starttime, " secs")
	end

end

//If this game has this pcf, but it's not currently loadable because it's being overridden by a conflicting pcf of the same name, this returns 
//the filepath for a copy of the inaccessible pcf, located in the data folder (a "data pcf"). Otherwise, returns the same pcf we gave it.
//(for details, see the part of PEPlus_ReadAndProcessPCFs() where we populate PEPlus_GamePCFs)
function PEPlus_GetGamePCF(pcf, path)
	if !path or !PEPlus_GamePCFs[pcf] or !PEPlus_GamePCFs[pcf][path] then return pcf end
	return PEPlus_GamePCFs[pcf][path]
end

function PEPlus_GetDataPCFNiceName(pcf)
	if pcf == "UtilFx" then return "Scripted Effect" end
	local tab = PEPlus_AllDataPCFs[pcf]
	if !tab then return pcf end
	return tab.original_filename .. " (" .. tab.path .. ")"
end




//Determine which fx are actually identical copies of another effect of the same name.
//This is used to prevent unnecessary AddParticles loading and bad "effect is unloaded, click to load" info in spawnicons (dupes are considered 
//equivalent to the effect they're a copy of), and also to prevent search results from getting clogged up with multiple identical effects.
//On server, this function only builds PEPlus_PCFsByParticleName, for use by backcomp.
function PEPlus_GetDuplicateFx()

	if CLIENT then PEPlus_DuplicateFx = {} end
	PEPlus_PCFsByParticleName = {}
	//TODO: can't do debug spew for everything when developer mode is on, since there's too much stuff per pcf, so currently this is all done 
	//for a single pcf and/or effect defined manually in code. i guess this could be moved to some convars in case other devs want to use it?
	
	for _, filename in SortedPairs (PEPlus_PCFsInDupeOrder) do
		if CLIENT then PEPlus_DuplicateFx[filename] = {} end
		//local dodebug = filename == "particles/rain_fx_unused.pcf"
		local dupe_candidates = {}

		local allfx = {}
		for k, _ in pairs (PEPlus_ProcessedPCFs[filename]) do
			allfx[k] = true
		end
		for k, _ in pairs (PEPlus_CulledFx[filename]) do
			allfx[k] = true
		end

		for effect, _ in SortedPairs (allfx) do
			//local dodebug = effect == "halloween_boss_foot_fire_customcolor"
			//if dodebug then MsgN(effect) end
			//if dodebug and effect == "ash_eddy_b" then PrintTable(PEPlus_PCFsByParticleName[effect]) end
			PEPlus_PCFsByParticleName[effect] = PEPlus_PCFsByParticleName[effect] or {}
			if CLIENT then
				for _, filename2 in SortedPairs (PEPlus_PCFsByParticleName[effect]) do
					//Compare the effect to all other fx of the same name (except the ones that we know 
					//are dupes themselves) to determine if this effect is a duplicate of one of them
					if PEPlus_DuplicateFx[filename2][effect] then
						//if dodebug then MsgN(filename .. "/" .. filename2 .. ": ", effect, " this potential candidate is a dupe of ", PEPlus_DuplicateFx[filename2][effect], ", skipping") end
						continue
					end
					//if dupe_candidates[effect] then break end
					local is_dupe = true
					local function CompareTables(t1, t2, level, table_name_for_debug)
						if !is_dupe then return end
						local operator_tables = {
							constraints = true,
							emitters = true,
							forces = true,
							initializers = true,
							operators = true,
							renderers = true,
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

						for k, _ in SortedPairs (allkeys) do
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
					CompareTables(table.Copy(PEPlus_NoDefPCFs[filename][effect]), table.Copy(PEPlus_NoDefPCFs[filename2][effect]), 1, filename .. "/" .. filename2 .. ": " .. effect)
					if is_dupe then
						dupe_candidates[effect] = dupe_candidates[effect] or {}
						table.insert(dupe_candidates[effect], filename2)
						//if dodebug then MsgN(filename .. "/" .. filename2 .. ": ", effect, " dupe candidate found") end
						//break
					end
				end
			end
			table.insert(PEPlus_PCFsByParticleName[effect], filename)
		end
		if SERVER then continue end
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
				for _, tab in pairs (PEPlus_NoDefPCFs[filename][effect2].children) do
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
									//	MsgN("DUPECHECK: v = ", v, ", PEPlus_DuplicateFx = ", PEPlus_DuplicateFx[v][tab.child], ", v2 = ", v2)
									//end
									if PEPlus_DuplicateFx[v][tab.child] == v2 then //this seems like nonsense but it works, argh
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
				PEPlus_DuplicateFx[filename][effect] = dupe_candidates[effect][1]
				//if dodebug then MsgN(filename .. "/" .. dupe_candidates[effect][1] .. ": " .. effect .. ": dupe found!") end
			end
		end
	end

end