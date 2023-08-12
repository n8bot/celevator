celevator.doors = {}

celevator.doors.erefs = {}

minetest.register_node("celevator:hwdoor_fast_glass_bottom",{
	description = "Glass Hoistway Door (fast, bottom)",
	tiles = {
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png^[transformFY",
		"celevator_door_glass_topbottom.png^[transformFY",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.4,0.5,0.5,0.5},
		},
	},
})

minetest.register_node("celevator:hwdoor_fast_glass_middle",{
	description = "Glass Hoistway Door (fast, middle)",
	tiles = {
		"celevator_transparent.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_middle.png",
		"celevator_door_glass_middle.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.4,0.5,0.5,0.5},
		},
	},
})

minetest.register_node("celevator:hwdoor_fast_glass_top",{
	description = "Glass Hoistway Door (fast, top)",
	tiles = {
		"celevator_door_glass_edge.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png",
		"celevator_door_glass_topbottom.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.4,0.5,0.5,0.5},
		},
	},
})

minetest.register_node("celevator:hwdoor_slow_glass_bottom",{
	description = "Glass Hoistway Door (slow, bottom)",
	tiles = {
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png^[transformFY",
		"celevator_door_glass_topbottom.png^[transformFY",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.3,0.5,0.5,0.4},
		},
	},
})

minetest.register_node("celevator:hwdoor_slow_glass_middle",{
	description = "Glass Hoistway Door (slow, middle)",
	tiles = {
		"celevator_transparent.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_middle.png",
		"celevator_door_glass_middle.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.3,0.5,0.5,0.4},
		},
	},
})

minetest.register_node("celevator:hwdoor_slow_glass_top",{
	description = "Glass Hoistway Door (slow, top)",
	tiles = {
		"celevator_door_glass_edge.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png",
		"celevator_door_glass_topbottom.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.3,0.5,0.5,0.4},
		},
	},
})

minetest.register_node("celevator:hwdoor_placeholder",{
	description = "Hoistway Door Open-State Placeholder",
	tiles = {
		"celevator_transparent.png",
	},
	paramtype = "light",
	drawtype = "airlike",
})

minetest.register_entity("celevator:hwdoor_moving",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.667,0.667,0.667),
		wield_item = "default:dirt",
		static_save = false,
	},
})

function celevator.doors.hwopen(pos)
	local hwdoors_moving = minetest.deserialize(celevator.storage:get_string("hwdoors_moving")) or {}
	local hash = minetest.hash_node_position(pos)
	if hwdoors_moving[hash] then
		return
	end
	local fdir = minetest.fourdir_to_dir(minetest.get_node(pos).param2)
	local otherpanel = vector.add(pos,vector.rotate_around_axis(fdir,vector.new(0,1,0),-math.pi/2))
	local positions = {
		pos,
		vector.add(pos,vector.new(0,1,0)),
		vector.add(pos,vector.new(0,2,0)),
		otherpanel,
		vector.add(otherpanel,vector.new(0,1,0)),
		vector.add(otherpanel,vector.new(0,2,0)),
	}
	local oldnodes = {}
	for i,position in ipairs(positions) do
		oldnodes[i] = minetest.get_node(position)
	end
	local erefs = celevator.drives.entity.nodestoentities(positions)
	hwdoors_moving[hash] = {
		direction = "open",
		positions = positions,
		nodes = oldnodes,
		time = 0,
		opendir = vector.rotate_around_axis(fdir,vector.new(0,1,0),-math.pi/2),
	}
	celevator.doors.erefs[hash] = erefs
	celevator.storage:set_string("hwdoors_moving",minetest.serialize(hwdoors_moving))
	minetest.set_node(pos,{name="celevator:hwdoor_placeholder"})
	local pmeta = minetest.get_meta(pos)
	pmeta:set_string("data",minetest.serialize(hwdoors_moving[hash]))
	pmeta:set_string("state","opening")
end

function celevator.doors.hwclose(pos)
	local hwdoors_moving = minetest.deserialize(celevator.storage:get_string("hwdoors_moving")) or {}
	local hash = minetest.hash_node_position(pos)
	if hwdoors_moving[hash] then
		return
	end
	local pmeta = minetest.get_meta(pos)
	local state = pmeta:get_string("state")
	if state ~= "open" then return end
	local data = minetest.deserialize(pmeta:get_string("data"))
	if not data then return end
	for i=1,6,1 do
		minetest.set_node(data.positions[i],data.nodes[i])
	end
	data.direction = "close"
	data.time = 0
	local erefs = celevator.drives.entity.nodestoentities(data.positions,"celevator:hwdoor_moving")
	local foffset = vector.multiply(data.opendir,2)
	local soffset = data.opendir
	for i=1,3,1 do
		erefs[i]:set_pos(vector.add(erefs[i]:get_pos(),foffset))
	end
	for i=4,6,1 do
		erefs[i]:set_pos(vector.add(erefs[i]:get_pos(),soffset))
	end
	celevator.doors.erefs[hash] = erefs
	hwdoors_moving[hash] = data
	celevator.storage:set_string("hwdoors_moving",minetest.serialize(hwdoors_moving))
end

function celevator.doors.step(dtime)
	local hwdoors_moving = minetest.deserialize(celevator.storage:get_string("hwdoors_moving")) or {}
	local save = false
	for hash,data in pairs(hwdoors_moving) do
		save = true
		local present = celevator.doors.erefs[hash]
		if present then
			for i=1,6,1 do
				if not celevator.doors.erefs[hash][i]:get_pos() then
					present = false
					break
				end
			end
		end
		if present then
			if data.direction == "open" then
				data.time = data.time+dtime
				local vel = math.sin(data.time)
				for i=1,3,1 do
					celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel))
				end
				for i=4,6,1 do
					celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel/2))
				end
				if data.time >= math.pi then
					for i=1,6,1 do
						celevator.doors.erefs[hash][i]:remove()
					end
					minetest.get_meta(data.positions[1]):set_string("state","open")
					hwdoors_moving[hash] = nil
				end
			elseif data.direction == "close" then
				data.time = data.time+(0.66*dtime)
				local vel = math.sin(data.time)
				for i=1,3,1 do
					celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel*-0.66))
				end
				for i=4,6,1 do
					celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel/2*-0.66))
				end
				if data.time >= math.pi then
					for i=1,6,1 do
						celevator.doors.erefs[hash][i]:set_pos(data.positions[i])
					end
					celevator.drives.entity.entitiestonodes(celevator.doors.erefs[hash])
					hwdoors_moving[hash] = nil
				end
			end
		else
			for i=1,6,1 do
				celevator.doors.erefs[hash][i]:remove()
			end
			minetest.get_meta(data.positions[1]):set_string("state","open")
			hwdoors_moving[hash] = nil
		end
	end
	if save then
		celevator.storage:set_string("hwdoors_moving",minetest.serialize(hwdoors_moving))
	end
end

minetest.register_globalstep(celevator.doors.step)
