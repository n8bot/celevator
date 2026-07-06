celevator.doors.centerglass = {}

local S = core.get_translator("celevator")

core.register_node("celevator:hwdoor_left_glass_bottom",{
	description = S("Glass Hoistway Door (left, bottom - you hacker you!)"),
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
	drop = "celevator:hwdoor_centerglass",
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
		local erefs = core.get_objects_inside_radius(pos,1.5)
		for _,ref in pairs(erefs) do
			if ref:get_luaentity() and ref:get_luaentity().name == "celevator:door_sill" then ref:remove() end
		end
		local facedir = core.dir_to_yaw(core.fourdir_to_dir(node.param2))
		local xnames = {
			[0] = "left",
			[1] = "right",
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
				if core.get_node(piecepos).name == piecename then core.remove_node(piecepos) end
			end
		end
	end,
	_celevator_doortype = "centerglass",
})

core.register_node("celevator:hwdoor_left_glass_middle",{
	description = S("Glass Hoistway Door (left, middle - you hacker you!)"),
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
	_celevator_doortype = "centerglass",
})

core.register_node("celevator:hwdoor_left_glass_top",{
	description = S("Glass Hoistway Door (left, top - you hacker you!)"),
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
	_celevator_doortype = "centerglass",
})

core.register_node("celevator:hwdoor_right_glass_bottom",{
	description = S("Glass Hoistway Door (right, bottom - you hacker you!)"),
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
			{-0.5,-0.5,0.4,0.5,0.5,0.5},
		},
	},
	_celevator_doortype = "centerglass",
})

core.register_node("celevator:hwdoor_right_glass_middle",{
	description = S("Glass Hoistway Door (right, middle - you hacker you!)"),
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
	_celevator_doortype = "centerglass",
})

core.register_node("celevator:hwdoor_right_glass_top",{
	description = S("Glass Hoistway Door (right, top - you hacker you!)"),
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
	_celevator_doortype = "centerglass",
})

core.register_node("celevator:hwdoor_centerglass",{
	description = S("Center-Opening Glass Elevator Hoistway Door"),
	paramtype2 = "4dir",
	buildable_to = true,
	inventory_image = "celevator_door_centerglass_inventory.png",
	wield_image = "celevator_door_centerglass_inventory.png",
	wield_scale = vector.new(1,3,1),
	tiles = {"celevator_transparent.png"},
	after_place_node = function(pos,player)
		if not player:is_player() then
			core.remove_node(pos)
			return true
		end
		local name = player:get_player_name()
		local newnode = core.get_node(pos)
		local facedir = core.dir_to_yaw(core.fourdir_to_dir(newnode.param2))
		local xnames = {
			[0] = "left",
			[1] = "right",
		}
		local ynames = {
			[0] = "bottom",
			[1] = "middle",
			[2] = "top",
		}
		for x=0,1,1 do
			for y=0,2,1 do
				local placeoffset = vector.new(x,y,0)
				local placepos = vector.add(pos,vector.rotate_around_axis(placeoffset,vector.new(0,1,0),facedir))
				local replaces = core.get_node(placepos).name
				if not (core.registered_nodes[replaces] and core.registered_nodes[replaces].buildable_to) then
					local errormsg = S("Can't place door here - position @1m to the right and @2m up is blocked!",x,y)
					core.chat_send_player(name,errormsg)
					core.remove_node(pos)
					return true
				end
				if core.is_protected(placepos,name) and not core.check_player_privs(name,{protection_bypass=true}) then
					local errormsg = S("Can't place door here - position @1m to the right and @2m up is protected!",x,y)
					core.chat_send_player(name,errormsg)
					core.record_protection_violation(placepos,name)
					core.remove_node(pos)
					return true
				end
			end
		end
		for x=0,1,1 do
			for y=0,2,1 do
				local piecename = string.format("celevator:hwdoor_%s_glass_%s",xnames[x],ynames[y])
				local placeoffset = vector.new(x,y,0)
				local placepos = vector.add(pos,vector.rotate_around_axis(placeoffset,vector.new(0,1,0),facedir))
				core.set_node(placepos,{name=piecename,param2=newnode.param2})
				if y==0 then
					celevator.doors.placesill(placepos,{name=piecename,param2=newnode.param2})
				end
			end
		end
		local carpos = vector.add(pos,vector.rotate_around_axis(vector.new(0,0,1),vector.new(0,1,0),facedir))
		local carndef = core.registered_nodes[celevator.get_node(carpos).name] or {}
		if carndef._root then
			celevator.get_meta(carpos):set_string("doortype","centerglass")
			celevator.doors.spawncardoors(carpos,core.fourdir_to_dir(newnode.param2),"centerglass",true)
		end
	end,
})

core.register_lbm({
	label = "Respawn hoistway door sills (center-opening glass)",
	name = "celevator:spawn_sill_centerglass",
	nodenames = {
		"celevator:hwdoor_left_glass_bottom",
		"celevator:hwdoor_right_glass_bottom",
	},
	run_at_every_load = true,
	action = celevator.doors.placesill,
})

celevator.doors.centerglass.spawncardoors = function(pos,dir,replace)
	local refs = {}
	for x=2,1,-1 do
		for y=1,3,1 do
			local yaw = core.dir_to_yaw(dir)+math.pi
			local doorpos = vector.add(pos,vector.rotate_around_axis(vector.new(x-2,y-1,0),vector.new(0,1,0),yaw))
			local xnames = {"left","right"}
			local ynames = {"bottom","middle","top"}
			local nname = string.format("celevator:hwdoor_%s_glass_%s",xnames[x],ynames[y])
			if replace then
				local oldrefs = core.get_objects_inside_radius(doorpos,0.1)
				for _,i in pairs(oldrefs) do
					if i:get_luaentity() and i:get_luaentity().name == "celevator:car_door" then
						i:remove()
					end
				end
			end
			local ref = core.add_entity(doorpos,"celevator:car_door")
			ref:set_yaw(yaw)
			ref:set_properties({
				wield_item = nname,
			})
			table.insert(refs,ref)
		end
	end
	return refs
end

function celevator.doors.centerglass.hwopen(pos,drivepos)
	celevator.doors.hwdoor_step_enabled = true
	local hwdoors_moving = core.deserialize(celevator.storage:get_string("hwdoors_moving")) or {}
	local hash = core.hash_node_position(pos)
	if not hwdoors_moving[hash] then
		local param2 = celevator.get_node(pos).param2
		local fdir = core.fourdir_to_dir(param2)
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
		hwdoors_moving[hash] = {
			direction = "open",
			positions = positions,
			nodes = oldnodes,
			time = 0,
			opendir = vector.rotate_around_axis(fdir,vector.new(0,1,0),-math.pi/2),
			drivepos = drivepos,
			param2 = param2,
			doortype = "centerglass",
		}
		celevator.doors.erefs[hash] = erefs
		celevator.storage:set_string("hwdoors_moving",core.serialize(hwdoors_moving))
		core.set_node(pos,{name="celevator:hwdoor_placeholder",param2=param2})
		local pmeta = celevator.get_meta(pos)
		pmeta:set_string("data",core.serialize(hwdoors_moving[hash]))
		pmeta:set_string("state","opening")
		pmeta:set_string("doortype","centerglass")
		local carpos = vector.add(pos,fdir)
		local carndef = core.registered_nodes[celevator.get_node(carpos).name] or {}
		if carndef._root then
			celevator.doors.caropen(carpos)
		end
	elseif hwdoors_moving[hash].direction == "close" then
		hwdoors_moving[hash].direction = "open"
		hwdoors_moving[hash].time = math.pi-hwdoors_moving[hash].time
		celevator.storage:set_string("hwdoors_moving",core.serialize(hwdoors_moving))
		local fdir = core.fourdir_to_dir(hwdoors_moving[hash].param2)
		local carpos = vector.add(pos,fdir)
		local carndef = core.registered_nodes[celevator.get_node(carpos).name] or {}
		if carndef._root then
			celevator.doors.caropen(carpos)
		end
		core.set_node(pos,{name="celevator:hwdoor_placeholder",param2=hwdoors_moving[hash].param2})
		local pmeta = celevator.get_meta(pos)
		pmeta:set_string("data",core.serialize(hwdoors_moving[hash]))
		pmeta:set_string("state","opening")
		pmeta:set_string("doortype","centerglass")
	end
end

function celevator.doors.centerglass.hwclose(pos,drivepos,nudge)
	celevator.doors.hwdoor_step_enabled = true
	local hwdoors_moving = core.deserialize(celevator.storage:get_string("hwdoors_moving")) or {}
	local hash = core.hash_node_position(pos)
	if hwdoors_moving[hash] then
		return
	end
	local pmeta = celevator.get_meta(pos)
	local state = pmeta:get_string("state")
	if state ~= "open" then return end
	local fdir = core.fourdir_to_dir(celevator.get_node(pos).param2)
	local carpos = vector.add(pos,fdir)
	local carndef = core.registered_nodes[celevator.get_node(carpos).name] or {}
	if carndef._root then
		celevator.doors.carclose(carpos,nudge)
	end
	local data = core.deserialize(pmeta:get_string("data"))
	if not data then return end
	for i=1,6,1 do
		core.set_node(data.positions[i],data.nodes[i])
	end
	data.direction = "close"
	data.time = 0
	data.drivepos = drivepos
	data.nudging = nudge
	local erefs = celevator.drives.entity.nodestoentities(data.positions,"celevator:hwdoor_moving")
	local roffset = vector.multiply(data.opendir,-1)
	local loffset = data.opendir
	for i=1,3,1 do
		erefs[i]:set_pos(vector.add(erefs[i]:get_pos(),roffset))
	end
	for i=4,6,1 do
		erefs[i]:set_pos(vector.add(erefs[i]:get_pos(),loffset))
	end
	celevator.doors.erefs[hash] = erefs
	hwdoors_moving[hash] = data
	celevator.storage:set_string("hwdoors_moving",core.serialize(hwdoors_moving))
end

function celevator.doors.centerglass.hwstep(hash,data,dtime,hwdoors_moving)
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
				celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel*-0.5))
			end
			for i=4,6,1 do
				celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel*0.5))
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
				celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel/2*speed))
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
				core.set_node(data.positions[i],data.nodes[i])
			end
			celevator.get_meta(data.positions[1]):set_string("state","closed")
			if hwdoors_moving[hash].drivepos then celevator.get_meta(hwdoors_moving[hash].drivepos):set_string("doorstate","closed") end
			hwdoors_moving[hash] = nil
		end
	end
end

function celevator.doors.centerglass.caropen(pos)
	celevator.doors.cardoor_step_enabled = true
	local cardoors_moving = core.deserialize(celevator.storage:get_string("cardoors_moving")) or {}
	local hash = core.hash_node_position(pos)
	local cartimer = core.get_node_timer(pos)
	cartimer:start(0.25)
	if not cardoors_moving[hash] then
		local fdir = core.fourdir_to_dir(celevator.get_node(pos).param2)
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
			local objs = core.get_objects_inside_radius(dpos,0.5)
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
			doortype = "centerglass",
		}
		core.sound_play("celevator_door_open",{
			pos = pos,
			gain = 0.4,
			max_hear_distance = 10
		},true)
		celevator.doors.erefs[hash] = erefs
		celevator.storage:set_string("cardoors_moving",core.serialize(cardoors_moving))
		local meta = celevator.get_meta(pos)
		meta:set_string("doordata",core.serialize(cardoors_moving[hash]))
		meta:set_string("doorstate","opening")
	elseif cardoors_moving[hash].direction == "close" then
		if cardoors_moving[hash].soundhandle then
			core.sound_stop(cardoors_moving[hash].soundhandle)
		end
		core.sound_play("celevator_door_reverse",{
			pos = pos,
			gain = 1,
			max_hear_distance = 10
		},true)
		core.sound_play("celevator_door_open",{
			pos = pos,
			gain = 0.4,
			start_time = math.max(0,2.75-cardoors_moving[hash].time),
			max_hear_distance = 10
		},true)
		cardoors_moving[hash].direction = "open"
		cardoors_moving[hash].time = math.pi-cardoors_moving[hash].time
		celevator.storage:set_string("cardoors_moving",core.serialize(cardoors_moving))
	end
end

function celevator.doors.centerglass.carclose(pos,nudge)
	celevator.doors.cardoor_step_enabled = true
	local cardoors_moving = core.deserialize(celevator.storage:get_string("cardoors_moving")) or {}
	local hash = core.hash_node_position(pos)
	if cardoors_moving[hash] then
		return
	end
	local meta = celevator.get_meta(pos)
	local state = meta:get_string("doorstate")
	if state ~= "open" then return end
	local data = core.deserialize(meta:get_string("doordata"))
	if not data then return end
	local dir = core.fourdir_to_dir(celevator.get_node(pos).param2)
	data.direction = "close"
	data.time = 0
	data.doortype = "centerglass"
	local erefs = celevator.doors.spawncardoors(pos,dir,"centerglass")
	local loffset = data.opendir
	local roffset = vector.multiply(loffset,-1)
	for i=1,3,1 do
		erefs[i]:set_pos(vector.add(erefs[i]:get_pos(),roffset))
	end
	for i=4,6,1 do
		erefs[i]:set_pos(vector.add(erefs[i]:get_pos(),loffset))
	end
	celevator.doors.erefs[hash] = erefs
	if nudge then
		data.soundhandle = core.sound_play("celevator_nudge",{
			pos = pos,
			gain = 0.75,
			max_hear_distance = 10
		})
	else
		data.soundhandle = core.sound_play("celevator_door_close",{
			pos = pos,
			gain = 0.3,
			max_hear_distance = 10
		})
	end
	data.nudging = nudge
	cardoors_moving[hash] = data
	celevator.storage:set_string("cardoors_moving",core.serialize(cardoors_moving))
end

function celevator.doors.centerglass.carstep(hash,data,dtime,cardoors_moving)
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
				celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel*-0.5))
			end
			for i=4,6,1 do
				celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel*0.5))
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
				celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel/2*speed))
			end
			for i=4,6,1 do
				celevator.doors.erefs[hash][i]:set_velocity(vector.multiply(data.opendir,vel/2*-speed))
			end
			if data.time >= math.pi then
				for _,ref in ipairs(celevator.doors.erefs[hash]) do
					ref:remove()
				end
				local carmeta = celevator.get_meta(data.positions[1])
				carmeta:set_string("doorstate","closed")
				cardoors_moving[hash] = nil
				local cartimer = core.get_node_timer(data.positions[1])
				cartimer:stop()
				local fdir = core.facedir_to_dir(core.get_node(data.positions[1]).param2)
				celevator.doors.spawncardoors(data.positions[1],fdir,"centerglass")
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
			local fdir = core.fourdir_to_dir(celevator.get_node(data.positions[1]).param2)
			celevator.doors.spawncardoors(data.positions[1],vector.rotate_around_axis(fdir,vector.new(0,1,0),math.pi),"centerglass")
			celevator.get_meta(data.positions[1]):set_string("doorstate","closed")
			cardoors_moving[hash] = nil
		end
	end
end
