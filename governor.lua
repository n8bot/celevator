local function spawngovsheave(pos)
	local entitiesnearby = minetest.get_objects_inside_radius(pos,0.5)
	for _,i in pairs(entitiesnearby) do
		if i:get_luaentity() and i:get_luaentity().name == "celevator:governor_sheave" then
			return
		end
	end
	local entity = minetest.add_entity(pos,"celevator:governor_sheave")
	local fdir = minetest.fourdir_to_dir(minetest.get_node(pos).param2)
	local yaw = minetest.dir_to_yaw(fdir)
	local offset = vector.rotate_around_axis(vector.new(0,-0.05,-0.143),vector.new(0,1,0),yaw)
	entity:set_yaw(yaw)
	entity:set_pos(vector.add(pos,offset))
end

minetest.register_node("celevator:governor",{
	description = "Elevator Governor",
	groups = {
		cracky = 1,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	tiles = {
		"celevator_machine_top.png",
		"celevator_machine_top.png",
		"celevator_machine_top.png",
		"celevator_machine_top.png",
		"celevator_governor_back.png",
		"celevator_governor_front.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.2,-0.5,-0.1,0.2,0.1,-0.07},
			{-0.2,-0.5,0.07,0.2,0.1,0.1},
			{-0.2,-0.5,-0.25,0.2,-0.45,-0.1},
			{-0.2,-0.5,0.1,0.2,-0.45,0.25},
		},
	},
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("formspec","field[carid;Car ID;]")
		spawngovsheave(pos)
	end,
	after_dig_node = function(pos)
		local entitiesnearby = minetest.get_objects_inside_radius(pos,0.5)
		for _,i in pairs(entitiesnearby) do
			if i:get_luaentity() and i:get_luaentity().name == "celevator:governor_sheave" then
				i:remove()
			end
		end
	end,
	on_receive_fields = function(pos,_,fields)
		if not (fields.carid and tonumber(fields.carid)) then return end
		local carid = tonumber(fields.carid)
		local carinfo = minetest.deserialize(celevator.storage:get_string("car"..carid))
		if not (carinfo and carinfo.controllerpos) then return end
		if not celevator.controller.iscontroller(carinfo.controllerpos) then return end
		local meta = minetest.get_meta(pos)
		meta:set_string("controllerpos",minetest.pos_to_string(carinfo.controllerpos))
		meta:set_string("formspec","")
	end,
})

minetest.register_node("celevator:governor_sheave",{
	description = "Governor Sheave (you hacker you!)",
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "4dir",
	tiles = {
		"celevator_governor_sheave_sides.png^[transformR90",
		"celevator_governor_sheave_sides.png^[transformR270",
		"celevator_governor_sheave_sides.png",
		"celevator_governor_sheave_sides.png^[transformR180",
		"celevator_sheave_front_centered.png",
		"celevator_sheave_front_centered.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.3,-0.3,0.2,0.3,0.3,0.5},
			{-0.4,-0.2,0.2,-0.3,0.2,0.5},
			{0.3,-0.2,0.2,0.4,0.2,0.5},
			{-0.2,0.3,0.2,0.2,0.4,0.5},
			{-0.2,-0.4,0.2,0.2,-0.3,0.5},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {},
	},
})

minetest.register_entity("celevator:governor_sheave",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.4,0.4,0.27),
		wield_item = "celevator:governor_sheave",
		static_save = false,
		pointable = false,
	},
	on_step = function(self)
		local sheave = self.object
		if not sheave then return end
		local governorpos = vector.round(sheave:get_pos())
		local governormeta = celevator.get_meta(governorpos)
		local controllerpos = minetest.string_to_pos(governormeta:get_string("controllerpos"))
		if not controllerpos then return end
		local controllermeta = celevator.get_meta(controllerpos)
		local vel = tonumber(controllermeta:get_string("vel")) or 0
		if vel == 0 then return end
		local drivepos = celevator.controller.finddrive(controllerpos)
		local drivemeta = celevator.get_meta(drivepos)
		local apos = tonumber(drivemeta:get_string("apos")) or 0
		local rotation = sheave:get_rotation()
		rotation.z = apos*2*math.pi
		sheave:set_rotation(rotation)
	end,
})

minetest.register_lbm({
	name = "celevator:spawngovsheave",
	label = "Spawn governor sheaves",
	nodenames = {"celevator:governor"},
	run_at_every_load = true,
	action = spawngovsheave,
})
