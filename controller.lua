celevator.controller = {}

celevator.controller.iqueue = minetest.deserialize(celevator.storage:get_string("controller_iqueue")) or {}

celevator.controller.equeue = minetest.deserialize(celevator.storage:get_string("controller_equeue")) or {}

celevator.controller.running = {}

local fw,err = loadfile(minetest.get_modpath("celevator")..DIR_DELIM.."controllerfw.lua")
if not fw then error(err) end

minetest.register_chatcommand("celevator_reloadcontroller",{
	params = "",
	description = "Reload celevator controller firmware from disk",
	privs = {server = true},
	func = function()
		local newfw,loaderr = loadfile(minetest.get_modpath("celevator")..DIR_DELIM.."controllerfw.lua")
		if newfw then
			fw = newfw
			return true,"Firmware reloaded successfully"
		else
			return false,loaderr
		end
	end,
})

local function after_place(pos,placer)
	local node = minetest.get_node(pos)
	local toppos = {x=pos.x,y=pos.y + 1,z=pos.z}
	local topnode = minetest.get_node(toppos)
	local placername = placer:get_player_name()
	if topnode.name ~= "air" then
		if placer:is_player() then
			minetest.chat_send_player(placername,"Can't place cabinet - no room for the top half!")
		end
		minetest.set_node(pos,{name="air"})
		return true
	end
	if minetest.is_protected(toppos,placername) and not minetest.check_player_privs(placername,{protection_bypass=true}) then
		if placer:is_player() then
			minetest.chat_send_player(placername,"Can't place cabinet - top half is protected!")
			minetest.record_protection_violation(toppos,placername)
		end
		minetest.set_node(pos,{name="air"})
		return true
	end
	node.name = "celevator:controller_top"
	minetest.set_node(toppos,node)
end

local function ondestruct(pos)
	pos.y = pos.y + 1
	local topnode = minetest.get_node(pos)
	local controllertops = {
		["celevator:controller_top"] = true,
		["celevator:controller_top_running"] = true,
		["celevator:controller_top_open"] = true,
		["celevator:controller_top_open_running"] = true,
	}
	if controllertops[topnode.name] then
		minetest.set_node(pos,{name="air"})
	end
	celevator.controller.equeue[minetest.hash_node_position(pos)] = nil
	celevator.storage:set_string("controller_equeue",minetest.serialize(celevator.controller.equeue))
end

local function onrotate(controllerpos,node,user,mode,new_param2)
	if not minetest.global_exists("screwdriver") then
		return false
	end
	local ret = screwdriver.rotate_simple(controllerpos,node,user,mode,new_param2)
	minetest.after(0,function(pos)
		local newnode = minetest.get_node(pos)
		local param2 = newnode.param2
		pos.y = pos.y + 1
		local topnode = minetest.get_node(pos)
		topnode.param2 = param2
		minetest.set_node(pos,topnode)
	end,controllerpos)
	return ret
end

local function handlefields(pos,_,fields,sender)
	local playername = sender and sender:get_player_name() or ""
	local event = {}
	event.type = "ui"
	event.fields = fields
	event.sender = playername
	celevator.controller.run(pos,event)
end

local function controllerleds(pos,running)
	local toppos = vector.add(pos,vector.new(0,1,0))
	local node = minetest.get_node(toppos)
	local sparams = {
		pos = toppos,
	}
	if node.name == "celevator:controller_top_open" and running then
		node.name = "celevator:controller_top_open_running"
		minetest.swap_node(toppos,node)
		minetest.sound_play("celevator_controller_start",sparams,true)
	elseif node.name == "celevator:controller_top" and running then
		node.name = "celevator:controller_top_running"
		minetest.swap_node(toppos,node)
		minetest.sound_play("celevator_controller_start",sparams,true)
	elseif node.name == "celevator:controller_top_open_running" and not running then
		node.name = "celevator:controller_top_open"
		minetest.swap_node(toppos,node)
		minetest.sound_play("celevator_controller_stop",sparams,true)
	elseif node.name == "celevator:controller_top_running" and not running then
		node.name = "celevator:controller_top"
		minetest.swap_node(toppos,node)
		minetest.sound_play("celevator_controller_stop",sparams,true)
	end
end

minetest.register_node("celevator:controller",{
	description = "Controller",
	groups = {
		cracky = 1,
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0,0.5,0.5,0.5},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0,0.5,1.5,0.5},
		},
	},
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_front_bottom.png",
	},
	after_place_node = after_place,
	on_destruct = ondestruct,
	on_rotate = onrotate,
	on_receive_fields = handlefields,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("mem",minetest.serialize({}))
		local event = {}
		event.type = "program"
		celevator.controller.run(pos,event)
	end,
	on_punch = function(pos,node,puncher)
		if not puncher:is_player() then
			return
		end
		local name = puncher:get_player_name()
		if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
			minetest.chat_send_player(name,"Can't open cabinet - cabinet is locked.")
			minetest.record_protection_violation(pos,name)
			return
		end
		node.name = "celevator:controller_open"
		minetest.swap_node(pos,node)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec",meta:get_string("formspec_hidden"))
		pos.y = pos.y + 1
		node = minetest.get_node(pos)
		if node.name == "celevator:controller_top_running" then
			node.name = "celevator:controller_top_open_running"
		else
			node.name = "celevator:controller_top_open"
		end
		minetest.swap_node(pos,node)
		minetest.sound_play("doors_steel_door_open",{
			pos = pos,
			gain = 0.5,
			max_hear_distance = 10
		},true)
	end,
})

minetest.register_node("celevator:controller_open",{
	description = "Controller (door open - you hacker you!)",
	groups = {
		cracky = 1,
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	drop = "celevator:controller",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0,0.5,0.5,0.5},
			{-0.5,-0.5,-0.5,-0.45,0.5,0},
			{0.45,-0.5,-0.5,0.5,0.5,0},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.5,0.5,1.5,0.5},
		},
	},
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_front_bottom_open_rside.png",
		"celevator_cabinet_front_bottom_open_lside.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_front_bottom_open.png",
	},
	after_place_node = after_place,
	on_destruct = ondestruct,
	on_rotate = onrotate,
	on_receive_fields = handlefields,
	on_punch = function(pos,node,puncher)
		if not puncher:is_player() then
			return
		end
		node.name = "celevator:controller"
		minetest.swap_node(pos,node)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec","")
		pos.y = pos.y + 1
		node = minetest.get_node(pos)
		if node.name == "celevator:controller_top_open_running" then
			node.name = "celevator:controller_top_running"
		else
			node.name = "celevator:controller_top"
		end
		minetest.swap_node(pos,node)
		minetest.sound_play("doors_steel_door_close",{
			pos = pos,
			gain = 0.5,
			max_hear_distance = 10
		},true)
	end,
})

minetest.register_node("celevator:controller_top",{
	description = "Controller (top section - you hacker you!)",
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0,0.5,0.5,0.5},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{0,0,0,0,0,0},
		},
	},
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_front_top.png",
	},
})

minetest.register_node("celevator:controller_top_running",{
	description = "Controller (top section, car in motion - you hacker you!)",
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0,0.5,0.5,0.5},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{0,0,0,0,0,0},
		},
	},
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_front_top.png",
	},
})

minetest.register_node("celevator:controller_top_open",{
	description = "Controller (top section, open - you hacker you!)",
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0,0.5,0.5,0.5},
			{-0.5,-0.5,-0.5,-0.45,0.5,0},
			{0.45,-0.5,-0.5,0.5,0.5,0},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{0,0,0,0,0,0},
		},
	},
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_front_top_open_rside.png",
		"celevator_cabinet_front_top_open_lside.png",
		"celevator_cabinet_sides.png",
		{
			name="celevator_cabinet_front_top_open_stopped.png",
			animation={type="vertical_frames", aspect_w=32, aspect_h=32, length=2},
		}
	},
})

minetest.register_node("celevator:controller_top_open_running",{
	description = "Controller (top section, open, car in motion - you hacker you!)",
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,0,0.5,0.5,0.5},
			{-0.5,-0.5,-0.5,-0.45,0.5,0},
			{0.45,-0.5,-0.5,0.5,0.5,0},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{0,0,0,0,0,0},
		},
	},
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_front_top_open_rside.png",
		"celevator_cabinet_front_top_open_lside.png",
		"celevator_cabinet_sides.png",
		{
			name="celevator_cabinet_front_top_open_running.png",
			animation={type="vertical_frames", aspect_w=32, aspect_h=32, length=2},
		}
	},
})

function celevator.controller.iscontroller(pos,call2)
	local node = minetest.get_node(pos)
	if node.name == "ignore" and not call2 then
		minetest.forceload_block(pos)
		return celevator.controller.iscontroller(pos,true)
	elseif node.name == "celevator:controller" or node.name == "celevator:controller_open" then
		return true
	else
		return false
	end
end

function celevator.controller.finddrive(pos)
	local node = minetest.get_node(pos)
	local dir = minetest.facedir_to_dir(node.param2)
	local drivepos = vector.add(pos,vector.new(0,1,0))
	drivepos = vector.add(drivepos,vector.rotate_around_axis(dir,vector.new(0,-1,0),math.pi/2))
	drivepos = vector.round(drivepos)
	local drivename = minetest.get_node(drivepos).name
	return drivepos,minetest.registered_nodes[drivename]._celevator_drive_type
end

function celevator.controller.finish(pos,mem)
	if not celevator.controller.iscontroller(pos) then
		return
	else
		local drivepos,drivetype = celevator.controller.finddrive(pos)
		if drivetype then
			for _,command in ipairs(mem.drive.commands) do
				if command.command == "moveto" then
					celevator.drives[drivetype].moveto(drivepos,command.pos)
				elseif command.command == "setmaxvel" then
					celevator.drives[drivetype].setmaxvel(drivepos,command.maxvel)
				elseif command.command == "resetpos" then
					celevator.drives[drivetype].resetpos(drivepos)
				elseif command.command == "estop" then
					celevator.drives[drivetype].estop(drivepos)
				end
			end
		end
		local meta = minetest.get_meta(pos)
		local node = minetest.get_node(pos)
		local oldmem = minetest.deserialize(meta:get_string("mem")) or {}
		local oldupbuttonlights = oldmem.upcalls or {}
		local olddownbuttonlights = oldmem.dncalls or {}
		local newupbuttonlights = mem.upcalls or {}
		local newdownbuttonlights = mem.dncalls or {}
		local callbuttons = minetest.deserialize(meta:get_string("callbuttons")) or {}
		for hash,landing in pairs(callbuttons) do
			if oldupbuttonlights[landing] ~= newupbuttonlights[landing] then
				celevator.callbutton.setlight(minetest.get_position_from_hash(hash),"up",newupbuttonlights[landing])
			end
			if olddownbuttonlights[landing] ~= newdownbuttonlights[landing] then
				celevator.callbutton.setlight(minetest.get_position_from_hash(hash),"down",newdownbuttonlights[landing])
			end
		end
		meta:set_string("mem",minetest.serialize(mem))
		if node.name == "celevator:controller_open" then meta:set_string("formspec",mem.formspec or "") end
		meta:set_string("formspec_hidden",mem.formspec or "")
		meta:set_string("infotext",mem.infotext or "")
		local hash = minetest.hash_node_position(pos)
		celevator.controller.iqueue[hash] = mem.interrupts
		celevator.storage:set_string("controller_iqueue",minetest.serialize(celevator.controller.iqueue))
		controllerleds(pos,mem.showrunning)
		celevator.controller.running[hash] = nil
		if #celevator.controller.equeue[hash] > 0 then
			local event = celevator.controller.equeue[hash][1]
			table.remove(celevator.controller.equeue[hash],1)
			celevator.storage:set_string("controller_equeue",minetest.serialize(celevator.controller.equeue))
			celevator.controller.run(pos,event)
		end
	end
end

function celevator.controller.run(pos,event)
	if not celevator.controller.iscontroller(pos) then
		return
	else
		local hash = minetest.hash_node_position(pos)
		if not celevator.controller.equeue[hash] then
			celevator.controller.equeue[hash] = {}
			celevator.storage:set_string("controller_equeue",minetest.serialize(celevator.controller.equeue))
		end
		if celevator.controller.running[hash] then
			table.insert(celevator.controller.equeue[hash],event)
			celevator.storage:set_string("controller_equeue",minetest.serialize(celevator.controller.equeue))
			if #celevator.controller.equeue[hash] > 5 then
				minetest.log("warning","[celevator] [controller] Async process for controller at %s is falling behind, %d events in queue",minetest.pos_to_string(pos),#celevator.controller.equeue[hash])
			end
			return
		end
		celevator.controller.running[hash] = true
		local meta = minetest.get_meta(pos)
		local mem = minetest.deserialize(meta:get_string("mem"))
		if not mem then
			minetest.log("error","[celevator] [controller] Failed to load controller memory at "..minetest.pos_to_string(pos))
			return
		end
		mem.drive = {}
		mem.drive.commands = {}
		local drivepos,drivetype = celevator.controller.finddrive(pos)
		if drivetype then
			mem.drive.type = drivetype
			mem.drive.status = celevator.drives[drivetype].getstatus(drivepos)
		end
		mem.interrupts = celevator.controller.iqueue[minetest.hash_node_position(pos)] or {}
		minetest.handle_async(fw,celevator.controller.finish,pos,event,mem)
	end
end

function celevator.controller.handlecallbutton(controllerpos,buttonpos,dir)
	local buttonhash = minetest.hash_node_position(buttonpos)
	local controllermeta = minetest.get_meta(controllerpos)
	local pairings = minetest.deserialize(controllermeta:get_string("callbuttons")) or {}
	if pairings[buttonhash] then
		local landing = pairings[buttonhash]
		local event = {
			type = "callbutton",
			landing = landing,
			dir = dir,
		}
		celevator.controller.run(controllerpos,event)
	end
end

function celevator.controller.checkiqueue(dtime)
	for hash,iqueue in pairs(celevator.controller.iqueue) do
		local pos = minetest.get_position_from_hash(hash)
		for iid,time in pairs(iqueue) do
			iqueue[iid] = time-dtime
			if iqueue[iid] < 0 then
				iqueue[iid] = nil
				local event = {}
				event.type = "interrupt"
				event.iid = iid
				celevator.controller.run(pos,event)
			end
		end
	end
end

minetest.register_globalstep(celevator.controller.checkiqueue)
