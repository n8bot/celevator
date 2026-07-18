celevator.doors = {}

local S = core.get_translator("celevator")

celevator.doors.erefs = {}

local typealiases = {
	glass = "twospeedglass",
	steel = "twospeedmetal",
}

local function typelookup(doortype)
	if (not doortype) or doortype == "" then return "twospeedglass" end
	return typealiases[doortype] or doortype
end

--These get overwritten on globalstep and aren't settings.
--They're just set to true here so the globalstep functions run at least once,
--in case a door was moving when the server last shut down.
celevator.doors.hwdoor_step_enabled = true
celevator.doors.cardoor_step_enabled = true

function celevator.doors.placesill(pos,node)
	local erefs = core.get_objects_inside_radius(pos,0.5)
	for _,ref in pairs(erefs) do
		if ref:get_luaentity() and ref:get_luaentity().name == "celevator:door_sill" then return end
	end
	local yaw = core.dir_to_yaw(core.fourdir_to_dir(node.param2))
	local entity = core.add_entity(pos,"celevator:door_sill")
	entity:set_yaw(yaw)
end

core.register_node("celevator:hwdoor_placeholder",{
	description = S("Hoistway Door Open-State Placeholder (you hacker you!)"),
	groups = {
		not_in_creative_inventory = 1,
	},
	tiles = {
		"celevator_transparent.png",
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "airlike",
	collision_box = {
		type = "fixed",
		fixed = {
			{0,0,0,0,0,0}
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{0,0,0,0,0,0}
		}
	},
})

core.register_entity("celevator:hwdoor_moving",{
	initial_properties = {
		visual = "node",
		node = {name="air"},
		static_save = false,
		pointable = false,
	},
})

function celevator.doors.hwopen(pos,...)
	local nname = celevator.get_node(pos).name
	local doortype
	if nname == "celevator:hwdoor_placeholder" then
		doortype = celevator.get_meta(pos):get_string("doortype")
	else
		local ndef = core.registered_nodes[nname]
		if not ndef then return end
		doortype = ndef._celevator_doortype
	end
	if not doortype then
		local hwdoors_moving = core.deserialize(celevator.storage:get_string("hwdoors_moving")) or {}
		doortype = hwdoors_moving[core.hash_node_position(pos)].doortype
	end
	celevator.doors[typelookup(doortype)].hwopen(pos,...)
end

function celevator.doors.hwclose(pos,...)
	local pmeta = celevator.get_meta(pos)
	local doortype = typelookup(pmeta:get_string("doortype"))
	celevator.doors[doortype].hwclose(pos,...)
end

function celevator.doors.hwstep(dtime)
	if not celevator.doors.hwdoor_step_enabled then return end
	local hwdoors_moving = core.deserialize(celevator.storage:get_string("hwdoors_moving")) or {}
	local save = false
	for hash,data in pairs(hwdoors_moving) do
		save = true
		local doortype = typelookup(data.doortype)
		celevator.doors[doortype].hwstep(hash,data,dtime,hwdoors_moving)
	end
	if save then
		celevator.storage:set_string("hwdoors_moving",core.serialize(hwdoors_moving))
	end
	celevator.doors.hwdoor_step_enabled = save
end

core.register_globalstep(celevator.doors.hwstep)

function celevator.doors.carstep(dtime)
	if not celevator.doors.cardoor_step_enabled then return end
	local cardoors_moving = core.deserialize(celevator.storage:get_string("cardoors_moving")) or {}
	local save = false
	for hash,data in pairs(cardoors_moving) do
		save = true
		local doortype = typelookup(data.doortype)
		celevator.doors[doortype].carstep(hash,data,dtime,cardoors_moving)
	end
	if save then
		celevator.storage:set_string("cardoors_moving",core.serialize(cardoors_moving))
	end
	celevator.doors.cardoor_step_enabled = save
end

core.register_globalstep(celevator.doors.carstep)

core.register_entity("celevator:car_door",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.667,0.667,0.667),
		wield_item = "default:dirt",
		static_save = false,
		pointable = false,
		glow = core.LIGHT_MAX,
	},
})

function celevator.doors.spawncardoors(pos,dir,doortype,replace)
	doortype = typelookup(doortype)
	return celevator.doors[doortype].spawncardoors(pos,dir,replace)
end

function celevator.doors.caropen(pos)
	local meta = celevator.get_meta(pos)
	local doortype = typelookup(meta:get_string("doortype"))
	celevator.doors[doortype].caropen(pos)
end

function celevator.doors.carclose(pos,...)
	local meta = celevator.get_meta(pos)
	local doortype = typelookup(meta:get_string("doortype"))
	celevator.doors[doortype].carclose(pos,...)
end

core.register_abm({
	label = "Respawn car doors",
	nodenames = {"group:_celevator_car_root"},
	interval = 1,
	chance = 1,
	action = function(pos)
		if core.get_meta(pos):get_string("doorstate") ~= "closed" then return end
		local entitiesnearby = core.get_objects_inside_radius(pos,0.5)
		for _,i in pairs(entitiesnearby) do
			if i:get_luaentity() and i:get_luaentity().name == "celevator:car_door" then
				return
			end
		end
		local fdir = core.facedir_to_dir(core.get_node(pos).param2)
		local carmeta = core.get_meta(pos)
		local doortype = carmeta:get_string("doortype")
		celevator.doors.spawncardoors(pos,fdir,doortype)
	end,
})

core.register_node("celevator:door_sill",{
	description = S("Hoistway Door Sill, Double Track (you hacker you!)"),
	drop = "",
	groups = {
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.28,0.5,-0.495,0.5},
		},
	},
	tiles = {
		"celevator_door_sill.png^[transformR180",
		"celevator_cabinet_sides.png",
	},
})

core.register_entity("celevator:door_sill",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.667,0.667,0.667),
		wield_item = "celevator:door_sill",
		static_save = false,
		pointable = false,
		glow = core.LIGHT_MAX,
	},
})

