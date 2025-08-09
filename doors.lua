celevator.doors = {}

celevator.doors.erefs = {}

--These get overwritten on globalstep and aren't settings.
--They're just set to true here so the globalstep functions run at least once,
--in case a door was moving when the server last shut down.
celevator.doors.hwdoor_step_enabled = true
celevator.doors.cardoor_step_enabled = true

local function placesill(pos,node)
	local erefs = minetest.get_objects_inside_radius(pos,0.5)
	for _,ref in pairs(erefs) do
		if ref:get_luaentity() and ref:get_luaentity().name == "celevator:door_sill" then return end
	end
	local yaw = minetest.dir_to_yaw(minetest.fourdir_to_dir(node.param2))
	local entity = minetest.add_entity(pos,"celevator:door_sill")
	if node.name == "celevator:hwdoor_slow_glass_bottom" or node.name == "celevator:hwdoor_slow_steel_bottom" then
		entity:set_properties({
			wield_item = "celevator:door_sill_double",
		})
	end
	entity:set_yaw(yaw)
end

minetest.register_node("celevator:hwdoor_fast_glass_bottom",{
	description = "Glass Hoistway Door (fast, bottom - you hacker you!)",
	tiles = {
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png^[transformFY",
		"celevator_door_glass_topbottom.png^[transformFY",
	},
	groups = {
		not_in_creative_inventory = 1,
		_celevator_hwdoor_root = 1,
		oddly_breakable_by_hand = 2,
	},
	drop = "celevator:hwdoor_glass",
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
	after_dig_node = function(pos,node)
		local erefs = minetest.get_objects_inside_radius(pos,1.5)
		for _,ref in pairs(erefs) do
			if ref:get_luaentity() and ref:get_luaentity().name == "celevator:door_sill" then ref:remove() end
		end
		local facedir = minetest.dir_to_yaw(minetest.fourdir_to_dir(node.param2))
		local xnames = {
			[0] = "fast",
			[1] = "slow",
		}
		local ynames = {
			[0] = "bottom",
			[1] = "middle",
			[2] = "top",
		}
		for x=0,1,1 do
			for y=0,2,1 do
				local piecename = string.format("celevator:hwdoor_%s_glass_%s",xnames[x],ynames[y])
				local pieceoffset = vector.new(x,y,0)
				local piecepos = vector.add(pos,vector.rotate_around_axis(pieceoffset,vector.new(0,1,0),facedir))
				if minetest.get_node(piecepos).name == piecename then minetest.remove_node(piecepos) end
			end
		end
	end,
})

minetest.register_node("celevator:hwdoor_fast_glass_middle",{
	description = "Glass Hoistway Door (fast, middle - you hacker you!)",
	tiles = {
		"celevator_transparent.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_middle.png",
		"celevator_door_glass_middle.png",
	},
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
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
	description = "Glass Hoistway Door (fast, top - you hacker you!)",
	tiles = {
		"celevator_door_glass_edge.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png",
		"celevator_door_glass_topbottom.png",
	},
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
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
	description = "Glass Hoistway Door (slow, bottom - you hacker you!)",
	tiles = {
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png^[transformFY",
		"celevator_door_glass_topbottom.png^[transformFY",
	},
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
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
	description = "Glass Hoistway Door (slow, middle - you hacker you!)",
	tiles = {
		"celevator_transparent.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_middle.png",
		"celevator_door_glass_middle.png",
	},
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
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
	description = "Glass Hoistway Door (slow, top - you hacker you!)",
	tiles = {
		"celevator_door_glass_edge.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_topbottom.png",
		"celevator_door_glass_topbottom.png",
	},
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
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

minetest.register_node("celevator:hwdoor_fast_steel_bottom",{
	description = "Steel Hoistway Door (fast, bottom - you hacker you!)",
	tiles = {
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_metal.png",
		"celevator_door_metal.png",
	},
	groups = {
		not_in_creative_inventory = 1,
		_celevator_hwdoor_root = 1,
		oddly_breakable_by_hand = 2,
	},
	drop = "celevator:hwdoor_steel",
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.4,0.5,0.5,0.5},
		},
	},
	after_dig_node = function(pos,node)
		local erefs = minetest.get_objects_inside_radius(pos,1.5)
		for _,ref in pairs(erefs) do
			if ref:get_luaentity() and ref:get_luaentity().name == "celevator:door_sill" then ref:remove() end
		end
		local facedir = minetest.dir_to_yaw(minetest.fourdir_to_dir(node.param2))
		local xnames = {
			[0] = "fast",
			[1] = "slow",
		}
		local ynames = {
			[0] = "bottom",
			[1] = "middle",
			[2] = "top",
		}
		for x=0,1,1 do
			for y=0,2,1 do
				local piecename = string.format("celevator:hwdoor_%s_steel_%s",xnames[x],ynames[y])
				local pieceoffset = vector.new(x,y,0)
				local piecepos = vector.add(pos,vector.rotate_around_axis(pieceoffset,vector.new(0,1,0),facedir))
				if minetest.get_node(piecepos).name == piecename then minetest.remove_node(piecepos) end
			end
		end
	end,
})

minetest.register_node("celevator:hwdoor_fast_steel_middle",{
	description = "Steel Hoistway Door (fast, middle - you hacker you!)",
	tiles = {
		"celevator_transparent.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_metal.png",
		"celevator_door_metal.png",
	},
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.4,0.5,0.5,0.5},
		},
	},
})

minetest.register_node("celevator:hwdoor_fast_steel_top",{
	description = "Steel Hoistway Door (fast, top - you hacker you!)",
	tiles = {
		"celevator_door_glass_edge.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_metal.png",
		"celevator_door_metal.png",
	},
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.4,0.5,0.5,0.5},
		},
	},
})

minetest.register_node("celevator:hwdoor_slow_steel_bottom",{
	description = "Steel Hoistway Door (slow, bottom - you hacker you!)",
	tiles = {
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_metal.png",
		"celevator_door_metal.png",
	},
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.3,0.5,0.5,0.4},
		},
	},
})

minetest.register_node("celevator:hwdoor_slow_steel_middle",{
	description = "Steel Hoistway Door (slow, middle - you hacker you!)",
	tiles = {
		"celevator_transparent.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_metal.png",
		"celevator_door_metal.png",
	},
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.3,0.5,0.5,0.4},
		},
	},
})

minetest.register_node("celevator:hwdoor_slow_steel_top",{
	description = "Steel Hoistway Door (slow, top - you hacker you!)",
	tiles = {
		"celevator_door_glass_edge.png",
		"celevator_transparent.png",
		"celevator_door_glass_edge.png",
		"celevator_door_glass_edge.png",
		"celevator_door_metal.png",
		"celevator_door_metal.png",
	},
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0.3,0.5,0.5,0.4},
		},
	},
})

minetest.register_node("celevator:hwdoor_placeholder",{
	description = "Hoistway Door Open-State Placeholder (you hacker you!)",
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

minetest.register_entity("celevator:hwdoor_moving",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.667,0.667,0.667),
		wield_item = "default:dirt",
		static_save = false,
		pointable = false,
	},
})

function celevator.doors.hwopen(pos,drivepos)
	celevator.doors.hwdoor_step_enabled = true
	local hwdoors_moving = minetest.deserialize(celevator.storage:get_string("hwdoors_moving")) or {}
	local hash = minetest.hash_node_position(pos)
	if not hwdoors_moving[hash] then
		local param2 = celevator.get_node(pos).param2
		local fdir = minetest.fourdir_to_dir(param2)
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
			oldnodes[i] = celevator.get_node(position)
		end
		local erefs = celevator.drives.entity.nodestoentities(positions,"celevator:hwdoor_moving")
		local doortype = "glass"
		if oldnodes[1].name == "celevator:hwdoor_slow_steel_bottom" then
			doortype = "steel"
		end
		hwdoors_moving[hash] = {
			direction = "open",
			positions = positions,
			nodes = oldnodes,
			time = 0,
			opendir = vector.rotate_around_axis(fdir,vector.new(0,1,0),-math.pi/2),
			drivepos = drivepos,
			param2 = param2,
			doortype = doortype,
		}
		celevator.doors.erefs[hash] = erefs
		celevator.storage:set_string("hwdoors_moving",minetest.serialize(hwdoors_moving))
		minetest.set_node(pos,{name="celevator:hwdoor_placeholder",param2=param2})
		local pmeta = celevator.get_meta(pos)
		pmeta:set_string("data",minetest.serialize(hwdoors_moving[hash]))
		pmeta:set_string("state","opening")
		pmeta:set_string("doortype",doortype)
		local carpos = vector.add(pos,fdir)
		local carndef = minetest.registered_nodes[celevator.get_node(carpos).name] or {}
		if carndef._root then
			celevator.doors.caropen(carpos)
		end
	elseif hwdoors_moving[hash].direction == "close" then
		hwdoors_moving[hash].direction = "open"
		hwdoors_moving[hash].time = math.pi-hwdoors_moving[hash].time
		celevator.storage:set_string("hwdoors_moving",minetest.serialize(hwdoors_moving))
		local fdir = minetest.fourdir_to_dir(hwdoors_moving[hash].param2)
		local carpos = vector.add(pos,fdir)
		local carndef = minetest.registered_nodes[celevator.get_node(carpos).name] or {}
		if carndef._root then
			celevator.doors.caropen(carpos)
		end
		minetest.set_node(pos,{name="celevator:hwdoor_placeholder",param2=hwdoors_moving[hash].param2})
		local pmeta = celevator.get_meta(pos)
		pmeta:set_string("data",minetest.serialize(hwdoors_moving[hash]))
		pmeta:set_string("state","opening")
	end
end

function celevator.doors.hwclose(pos,drivepos,nudge)
	celevator.doors.hwdoor_step_enabled = true
	local hwdoors_moving = minetest.deserialize(celevator.storage:get_string("hwdoors_moving")) or {}
	local hash = minetest.hash_node_position(pos)
	if hwdoors_moving[hash] then
		return
	end
	local pmeta = celevator.get_meta(pos)
	local state = pmeta:get_string("state")
	if state ~= "open" then return end
	local fdir = minetest.fourdir_to_dir(celevator.get_node(pos).param2)
	local carpos = vector.add(pos,fdir)
	local carndef = minetest.registered_nodes[celevator.get_node(carpos).name] or {}
	if carndef._root then
		celevator.doors.carclose(carpos,nudge)
	end
	local data = minetest.deserialize(pmeta:get_string("data"))
	if not data then return end
	for i=1,6,1 do
		minetest.set_node(data.positions[i],data.nodes[i])
	end
	data.direction = "close"
	data.time = 0
	data.drivepos = drivepos
	data.nudging = nudge
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

function celevator.doors.hwstep(dtime)
	if not celevator.doors.hwdoor_step_enabled then return end
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
					celevator.get_meta(data.positions[1]):set_string("state","open")
					if hwdoors_moving[hash].drivepos then celevator.get_meta(hwdoors_moving[hash].drivepos):set_string("doorstate","open") end
					hwdoors_moving[hash] = nil
				end
			elseif data.direction == "close" then
				local speed = 0.66
				if data.nudging then speed = 0.2 end
				data.time = data.time+(speed*dtime)
				local vel = math.sin(data.time)
				for i=1,3,1 do
					celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel*-speed))
				end
				for i=4,6,1 do
					celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel/2*-speed))
				end
				if data.time >= math.pi then
					for i=1,6,1 do
						celevator.doors.erefs[hash][i]:set_pos(data.positions[i])
					end
					celevator.drives.entity.entitiestonodes(celevator.doors.erefs[hash])
					if hwdoors_moving[hash].drivepos then celevator.get_meta(hwdoors_moving[hash].drivepos):set_string("doorstate","closed") end
					hwdoors_moving[hash] = nil
				end
			end
		else
			if data.direction == "open" then
				for i=1,6,1 do
					if celevator.doors.erefs[hash] then
						celevator.doors.erefs[hash][i]:remove()
					end
				end
				celevator.get_meta(data.positions[1]):set_string("state","open")
				if hwdoors_moving[hash].drivepos then celevator.get_meta(hwdoors_moving[hash].drivepos):set_string("doorstate","open") end
				hwdoors_moving[hash] = nil
			elseif data.direction == "close" then
				for i=1,6,1 do
					minetest.set_node(data.positions[i],data.nodes[i])
				end
				celevator.get_meta(data.positions[1]):set_string("state","closed")
				if hwdoors_moving[hash].drivepos then celevator.get_meta(hwdoors_moving[hash].drivepos):set_string("doorstate","closed") end
				hwdoors_moving[hash] = nil
			end
		end
	end
	if save then
		celevator.storage:set_string("hwdoors_moving",minetest.serialize(hwdoors_moving))
	end
	celevator.doors.hwdoor_step_enabled = save
end

minetest.register_globalstep(celevator.doors.hwstep)

function celevator.doors.carstep(dtime)
	if not celevator.doors.cardoor_step_enabled then return end
	local cardoors_moving = minetest.deserialize(celevator.storage:get_string("cardoors_moving")) or {}
	local save = false
	for hash,data in pairs(cardoors_moving) do
		save = true
		local present = celevator.doors.erefs[hash]
		if present then
			for i=1,6,1 do
				if not (celevator.doors.erefs[hash][i] and celevator.doors.erefs[hash][i]:get_pos()) then
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
					celevator.get_meta(data.positions[1]):set_string("doorstate","open")
					cardoors_moving[hash] = nil
				end
			elseif data.direction == "close" then
				local speed = 0.66
				if data.nudging then speed = 0.2 end
				data.time = data.time+(speed*dtime)
				local vel = math.sin(data.time)
				for i=1,3,1 do
					celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel*-speed))
				end
				for i=4,6,1 do
					celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel/2*-speed))
				end
				if data.time >= math.pi then
					for _,ref in ipairs(celevator.doors.erefs[hash]) do
						ref:set_velocity(vector.new(0,0,0))
					end
					celevator.get_meta(data.positions[1]):set_string("doorstate","closed")
					cardoors_moving[hash] = nil
					local cartimer = minetest.get_node_timer(data.positions[1])
					cartimer:stop()
				end
			end
		else
			if data.direction == "open" then
				for i=1,6,1 do
					if celevator.doors.erefs[hash] and celevator.doors.erefs[hash][i] then
						celevator.doors.erefs[hash][i]:remove()
					end
				end
				celevator.get_meta(data.positions[1]):set_string("doorstate","open")
				cardoors_moving[hash] = nil
			elseif data.direction == "close" then
				local fdir = minetest.fourdir_to_dir(celevator.get_node(data.positions[1]).param2)
				celevator.doors.spawncardoors(data.positions[1],vector.rotate_around_axis(fdir,vector.new(0,1,0),math.pi))
				celevator.get_meta(data.positions[1]):set_string("doorstate","closed")
				cardoors_moving[hash] = nil
			end
		end
	end
	if save then
		celevator.storage:set_string("cardoors_moving",minetest.serialize(cardoors_moving))
	end
	celevator.doors.cardoor_step_enabled = save
end

minetest.register_globalstep(celevator.doors.carstep)

minetest.register_entity("celevator:car_door",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.667,0.667,0.667),
		wield_item = "default:dirt",
		static_save = false,
		pointable = false,
		glow = minetest.LIGHT_MAX,
	},
})

function celevator.doors.spawncardoors(pos,dir,doortype,replace)
	if not doortype then doortype = "glass" end
	local refs = {}
	for x=2,1,-1 do
		for y=1,3,1 do
			local yaw = minetest.dir_to_yaw(dir)+math.pi
			local doorpos = vector.add(pos,vector.rotate_around_axis(vector.new(x-2,y-1,0),vector.new(0,1,0),yaw))
			local xnames = {"slow","fast"}
			local ynames = {"bottom","middle","top"}
			local nname = string.format("celevator:hwdoor_%s_%s_%s",xnames[x],doortype,ynames[y])
			if replace then
				local oldrefs = minetest.get_objects_inside_radius(doorpos,0.1)
				for _,i in pairs(oldrefs) do
					if i:get_luaentity() and i:get_luaentity().name == "celevator:car_door" then
						i:remove()
					end
				end
			end
			local ref = minetest.add_entity(doorpos,"celevator:car_door")
			ref:set_yaw(yaw)
			ref:set_properties({
				wield_item = nname,
			})
			table.insert(refs,ref)
		end
	end
	return refs
end

function celevator.doors.caropen(pos)
	celevator.doors.cardoor_step_enabled = true
	local cardoors_moving = minetest.deserialize(celevator.storage:get_string("cardoors_moving")) or {}
	local hash = minetest.hash_node_position(pos)
	local cartimer = minetest.get_node_timer(pos)
	cartimer:start(0.25)
	if not cardoors_moving[hash] then
		local fdir = minetest.fourdir_to_dir(celevator.get_node(pos).param2)
		local otherpanel = vector.add(pos,vector.rotate_around_axis(fdir,vector.new(0,1,0),-math.pi/2))
		local positions = {
			pos,
			vector.add(pos,vector.new(0,1,0)),
			vector.add(pos,vector.new(0,2,0)),
			otherpanel,
			vector.add(otherpanel,vector.new(0,1,0)),
			vector.add(otherpanel,vector.new(0,2,0)),
		}
		local erefs = {}
		for _,dpos in ipairs(positions) do
			local objs = minetest.get_objects_inside_radius(dpos,0.1)
			for _,obj in pairs(objs) do
				if obj:get_luaentity() and obj:get_luaentity().name == "celevator:car_door" then
					table.insert(erefs,obj)
				end
			end
		end
		cardoors_moving[hash] = {
			direction = "open",
			positions = positions,
			time = 0,
			opendir = vector.rotate_around_axis(fdir,vector.new(0,1,0),-math.pi/2),
		}
		minetest.sound_play("celevator_door_open",{
			pos = pos,
			gain = 0.4,
			max_hear_distance = 10
		},true)
		celevator.doors.erefs[hash] = erefs
		celevator.storage:set_string("cardoors_moving",minetest.serialize(cardoors_moving))
		local meta = celevator.get_meta(pos)
		meta:set_string("doordata",minetest.serialize(cardoors_moving[hash]))
		meta:set_string("doorstate","opening")
	elseif cardoors_moving[hash].direction == "close" then
		if cardoors_moving[hash].soundhandle then
			minetest.sound_stop(cardoors_moving[hash].soundhandle)
		end
		minetest.sound_play("celevator_door_reverse",{
			pos = pos,
			gain = 1,
			max_hear_distance = 10
		},true)
		minetest.sound_play("celevator_door_open",{
			pos = pos,
			gain = 0.4,
			start_time = math.max(0,2.75-cardoors_moving[hash].time),
			max_hear_distance = 10
		},true)
		cardoors_moving[hash].direction = "open"
		cardoors_moving[hash].time = math.pi-cardoors_moving[hash].time
		celevator.storage:set_string("cardoors_moving",minetest.serialize(cardoors_moving))
	end
end

function celevator.doors.carclose(pos,nudge)
	celevator.doors.cardoor_step_enabled = true
	local cardoors_moving = minetest.deserialize(celevator.storage:get_string("cardoors_moving")) or {}
	local hash = minetest.hash_node_position(pos)
	if cardoors_moving[hash] then
		return
	end
	local meta = celevator.get_meta(pos)
	local state = meta:get_string("doorstate")
	if state ~= "open" then return end
	local data = minetest.deserialize(meta:get_string("doordata"))
	if not data then return end
	local dir = minetest.fourdir_to_dir(celevator.get_node(pos).param2)
	data.direction = "close"
	data.time = 0
	local doortype = meta:get_string("doortype")
	if (not doortype) or doortype == "" then doortype = "glass" end
	local erefs = celevator.doors.spawncardoors(pos,dir,doortype)
	local soffset = data.opendir
	local foffset = vector.multiply(soffset,2)
	for i=1,3,1 do
		erefs[i]:set_pos(vector.add(erefs[i]:get_pos(),foffset))
	end
	for i=4,6,1 do
		erefs[i]:set_pos(vector.add(erefs[i]:get_pos(),soffset))
	end
	celevator.doors.erefs[hash] = erefs
	if nudge then
		data.soundhandle = minetest.sound_play("celevator_nudge",{
			pos = pos,
			gain = 0.75,
			max_hear_distance = 10
		})
	else
		data.soundhandle = minetest.sound_play("celevator_door_close",{
			pos = pos,
			gain = 0.3,
			max_hear_distance = 10
		})
	end
	data.nudging = nudge
	cardoors_moving[hash] = data
	celevator.storage:set_string("cardoors_moving",minetest.serialize(cardoors_moving))
end

minetest.register_abm({
	label = "Respawn car doors",
	nodenames = {"group:_celevator_car_root"},
	interval = 1,
	chance = 1,
	action = function(pos)
		if minetest.get_meta(pos):get_string("doorstate") ~= "closed" then return end
		local entitiesnearby = minetest.get_objects_inside_radius(pos,0.5)
		for _,i in pairs(entitiesnearby) do
			if i:get_luaentity() and i:get_luaentity().name == "celevator:car_door" then
				return
			end
		end
		local fdir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
		local carmeta = minetest.get_meta(pos)
		local doortype = carmeta:get_string("doortype")
		if (not doortype) or doortype == "" then doortype = "glass" end
		celevator.doors.spawncardoors(pos,fdir,doortype)
	end,
})

minetest.register_node("celevator:hwdoor_glass",{
	description = "Glass Elevator Hoistway Door",
	paramtype2 = "4dir",
	buildable_to = true,
	inventory_image = "celevator_door_glass_inventory.png",
	wield_image = "celevator_door_glass_inventory.png",
	wield_scale = vector.new(1,3,1),
	tiles = {"celevator_transparent.png"},
	after_place_node = function(pos,player)
		if not player:is_player() then
			minetest.remove_node(pos)
			return true
		end
		local name = player:get_player_name()
		local newnode = minetest.get_node(pos)
		local facedir = minetest.dir_to_yaw(minetest.fourdir_to_dir(newnode.param2))
		local xnames = {
			[0] = "fast",
			[1] = "slow",
		}
		local ynames = {
			[0] = "bottom",
			[1] = "middle",
			[2] = "top",
		}
		for x=0,1,1 do
			for y=0,2,1 do
				local offsetdesc = string.format("%dm to the right and %dm up",x,y)
				local placeoffset = vector.new(x,y,0)
				local placepos = vector.add(pos,vector.rotate_around_axis(placeoffset,vector.new(0,1,0),facedir))
				local replaces = minetest.get_node(placepos).name
				if not (minetest.registered_nodes[replaces] and minetest.registered_nodes[replaces].buildable_to) then
					minetest.chat_send_player(name,string.format("Can't place door here - position %s is blocked!",offsetdesc))
					minetest.remove_node(pos)
					return true
				end
				if minetest.is_protected(placepos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
					minetest.chat_send_player(name,string.format("Can't place door here - position %s is protected!",offsetdesc))
					minetest.record_protection_violation(placepos,name)
					minetest.remove_node(pos)
					return true
				end
			end
		end
		for x=0,1,1 do
			for y=0,2,1 do
				local piecename = string.format("celevator:hwdoor_%s_glass_%s",xnames[x],ynames[y])
				local placeoffset = vector.new(x,y,0)
				local placepos = vector.add(pos,vector.rotate_around_axis(placeoffset,vector.new(0,1,0),facedir))
				minetest.set_node(placepos,{name=piecename,param2=newnode.param2})
				if y==0 then
					placesill(placepos,{name=piecename,param2=newnode.param2})
				end
			end
		end
		local carpos = vector.add(pos,vector.rotate_around_axis(vector.new(0,0,1),vector.new(0,1,0),facedir))
		local carndef = minetest.registered_nodes[celevator.get_node(carpos).name] or {}
		if carndef._root then
			celevator.get_meta(carpos):set_string("doortype","glass")
			celevator.doors.spawncardoors(carpos,minetest.fourdir_to_dir(newnode.param2),"glass",true)
		end
	end,
})

minetest.register_node("celevator:hwdoor_steel",{
	description = "Steel Elevator Hoistway Door",
	paramtype2 = "4dir",
	buildable_to = true,
	inventory_image = "celevator_door_metal_inventory.png",
	wield_image = "celevator_door_metal_inventory.png",
	wield_scale = vector.new(1,3,1),
	tiles = {"celevator_transparent.png"},
	after_place_node = function(pos,player)
		if not player:is_player() then
			minetest.remove_node(pos)
			return true
		end
		local name = player:get_player_name()
		local newnode = minetest.get_node(pos)
		local facedir = minetest.dir_to_yaw(minetest.fourdir_to_dir(newnode.param2))
		local xnames = {
			[0] = "fast",
			[1] = "slow",
		}
		local ynames = {
			[0] = "bottom",
			[1] = "middle",
			[2] = "top",
		}
		for x=0,1,1 do
			for y=0,2,1 do
				local offsetdesc = string.format("%dm to the right and %dm up",x,y)
				local placeoffset = vector.new(x,y,0)
				local placepos = vector.add(pos,vector.rotate_around_axis(placeoffset,vector.new(0,1,0),facedir))
				local replaces = minetest.get_node(placepos).name
				if not (minetest.registered_nodes[replaces] and minetest.registered_nodes[replaces].buildable_to) then
					minetest.chat_send_player(name,string.format("Can't place door here - position %s is blocked!",offsetdesc))
					minetest.remove_node(pos)
					return true
				end
				if minetest.is_protected(placepos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
					minetest.chat_send_player(name,string.format("Can't place door here - position %s is protected!",offsetdesc))
					minetest.record_protection_violation(placepos,name)
					minetest.remove_node(pos)
					return true
				end
			end
		end
		for x=0,1,1 do
			for y=0,2,1 do
				local piecename = string.format("celevator:hwdoor_%s_steel_%s",xnames[x],ynames[y])
				local placeoffset = vector.new(x,y,0)
				local placepos = vector.add(pos,vector.rotate_around_axis(placeoffset,vector.new(0,1,0),facedir))
				minetest.set_node(placepos,{name=piecename,param2=newnode.param2})
				if y==0 then
					placesill(placepos,{name=piecename,param2=newnode.param2})
				end
			end
		end
		local carpos = vector.add(pos,vector.rotate_around_axis(vector.new(0,0,1),vector.new(0,1,0),facedir))
		local carndef = minetest.registered_nodes[celevator.get_node(carpos).name] or {}
		if carndef._root then
			celevator.get_meta(carpos):set_string("doortype","steel")
			celevator.doors.spawncardoors(carpos,minetest.fourdir_to_dir(newnode.param2),"steel",true)
		end
	end,
})

minetest.register_node("celevator:door_sill_single",{
	description = "Hoistway Door Sill, Single Track (you hacker you!)",
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
		"celevator_door_sill_single.png^[transformR180",
		"celevator_cabinet_sides.png",
	},
})

minetest.register_node("celevator:door_sill_double",{
	description = "Hoistway Door Sill, Double Track (you hacker you!)",
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
		"celevator_door_sill_double.png^[transformR180",
		"celevator_cabinet_sides.png",
	},
})

minetest.register_entity("celevator:door_sill",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.667,0.667,0.667),
		wield_item = "celevator:door_sill_single",
		static_save = false,
		pointable = false,
		glow = minetest.LIGHT_MAX,
	},
})

minetest.register_lbm({
	label = "Respawn hoistway door sills",
	name = "celevator:spawn_sill",
	nodenames = {
		"celevator:hwdoor_fast_glass_bottom",
		"celevator:hwdoor_slow_glass_bottom",
		"celevator:hwdoor_fast_steel_bottom",
		"celevator:hwdoor_slow_steel_bottom",
	},
	run_at_every_load = true,
	action = placesill,
})
