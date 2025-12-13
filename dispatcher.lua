celevator.dispatcher = {}

celevator.dispatcher.iqueue = core.deserialize(celevator.storage:get_string("dispatcher_iqueue")) or {}

celevator.dispatcher.equeue = core.deserialize(celevator.storage:get_string("dispatcher_equeue")) or {}

celevator.dispatcher.running = {}

local fw,err = loadfile(core.get_modpath("celevator").."/dispatcherfw.lua")
if not fw then error(err) end

core.register_chatcommand("celevator_reloaddispatcher",{
	params = "",
	description = "Reload celevator dispatcher firmware from disk",
	privs = {server = true},
	func = function()
		local newfw,loaderr = loadfile(core.get_modpath("celevator").."/dispatcherfw.lua")
		if newfw then
			fw = newfw
			return true,"Firmware reloaded successfully"
		else
			return false,loaderr
		end
	end,
})

local function after_place(pos,placer)
	local node = core.get_node(pos)
	local toppos = {x=pos.x,y=pos.y + 1,z=pos.z}
	local topnode = core.get_node(toppos)
	local placername = placer:get_player_name()
	if topnode.name ~= "air" then
		if placer:is_player() then
			core.chat_send_player(placername,"Can't place cabinet - no room for the top half!")
		end
		core.set_node(pos,{name="air"})
		return true
	end
	if core.is_protected(toppos,placername) and not core.check_player_privs(placername,{protection_bypass=true}) then
		if placer:is_player() then
			core.chat_send_player(placername,"Can't place cabinet - top half is protected!")
			core.record_protection_violation(toppos,placername)
		end
		core.set_node(pos,{name="air"})
		return true
	end
	node.name = "celevator:dispatcher_top"
	core.set_node(toppos,node)
end

local function ondestruct(pos)
	pos.y = pos.y + 1
	local topnode = core.get_node(pos)
	local dispatchertops = {
		["celevator:dispatcher_top"] = true,
		["celevator:dispatcher_top_open"] = true,
	}
	if dispatchertops[topnode.name] then
		core.set_node(pos,{name="air"})
	end
	celevator.dispatcher.equeue[core.hash_node_position(pos)] = nil
	celevator.storage:set_string("dispatcher_equeue",core.serialize(celevator.dispatcher.equeue))
	local carid = core.get_meta(pos):get_int("carid")
	if carid ~= 0 then celevator.storage:set_string(string.format("car%d",carid),"") end
end

local function onrotate(controllerpos,node,user,mode,new_param2)
	if not core.global_exists("screwdriver") then
		return false
	end
	local ret = screwdriver.rotate_simple(controllerpos,node,user,mode,new_param2)
	core.after(0,function(pos)
		local newnode = core.get_node(pos)
		local param2 = newnode.param2
		pos.y = pos.y + 1
		local topnode = core.get_node(pos)
		topnode.param2 = param2
		core.set_node(pos,topnode)
	end,controllerpos)
	return ret
end

local function handlefields(pos,_,fields,sender)
	local playername = sender and sender:get_player_name() or ""
	local event = {}
	event.type = "ui"
	event.fields = fields
	event.sender = playername
	celevator.dispatcher.run(pos,event)
end

local function candig(_,player)
	local controls = player:get_player_control()
	if controls.sneak then
		return true
	else
		core.chat_send_player(player:get_player_name(),"Hold the sneak button while digging to remove.")
		return false
	end
end

core.register_node("celevator:dispatcher",{
	description = "Elevator Dispatcher",
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
	can_dig = candig,
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("mem",core.serialize({}))
		meta:mark_as_private("mem")
		local event = {}
		event.type = "program"
		local carid = celevator.storage:get_int("maxcarid")+1
		meta:set_int("carid",carid)
		celevator.storage:set_int("maxcarid",carid)
		celevator.storage:set_string(string.format("car%d",carid),core.serialize({dispatcherpos=pos,callbuttons={},fs1switches={}}))
		celevator.dispatcher.run(pos,event)
	end,
	on_punch = function(pos,node,puncher)
		if not puncher:is_player() then
			return
		end
		local name = puncher:get_player_name()
		if core.is_protected(pos,name) and not core.check_player_privs(name,{protection_bypass=true}) then
			core.chat_send_player(name,"Can't open cabinet - cabinet is locked.")
			core.record_protection_violation(pos,name)
			return
		end
		node.name = "celevator:dispatcher_open"
		core.swap_node(pos,node)
		local meta = core.get_meta(pos)
		meta:set_string("formspec",meta:get_string("formspec_hidden"))
		pos.y = pos.y + 1
		node = core.get_node(pos)
		node.name = "celevator:dispatcher_top_open"
		core.swap_node(pos,node)
		core.sound_play("celevator_cabinet_open",{
			pos = pos,
			gain = 0.5,
			max_hear_distance = 10
		},true)
	end,
})

core.register_node("celevator:dispatcher_open",{
	description = "Dispatcher (door open - you hacker you!)",
	groups = {
		cracky = 1,
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	drop = "celevator:dispatcher",
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
		{
			name="celevator_dispatcher_front_bottom_open.png",
			animation={type="vertical_frames", aspect_w=32, aspect_h=32, length=2},
		}
	},
	after_place_node = after_place,
	on_destruct = ondestruct,
	on_rotate = onrotate,
	on_receive_fields = handlefields,
	can_dig = candig,
	on_punch = function(pos,node,puncher)
		if not puncher:is_player() then
			return
		end
		node.name = "celevator:dispatcher"
		core.swap_node(pos,node)
		local meta = core.get_meta(pos)
		meta:set_string("formspec","")
		pos.y = pos.y + 1
		node = core.get_node(pos)
		node.name = "celevator:dispatcher_top"
		core.swap_node(pos,node)
		core.sound_play("celevator_cabinet_close",{
			pos = pos,
			gain = 0.5,
			max_hear_distance = 10
		},true)
	end,
})

core.register_node("celevator:dispatcher_top",{
	description = "Dispatcher (top section - you hacker you!)",
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
		"celevator_dispatcher_front_top.png",
	},
})

core.register_node("celevator:dispatcher_top_open",{
	description = "Dispatcher (top section, open - you hacker you!)",
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
		"celevator_dispatcher_front_top_open_lside.png",
		"celevator_cabinet_sides.png",
		"celevator_dispatcher_front_top_open.png",
	},
})

function celevator.dispatcher.isdispatcher(pos)
	local node = celevator.get_node(pos)
	return (node.name == "celevator:dispatcher" or node.name == "celevator:dispatcher_open")
end

function celevator.dispatcher.finish(pos,mem,changedinterrupts)
	if not celevator.dispatcher.isdispatcher(pos) then
		return
	else
		local meta = core.get_meta(pos)
		local carid = meta:get_int("carid")
		local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
		local carinfodirty = false
		if not carinfo then
			core.log("error","[celevator] [controller] Bad car info for dispatcher at "..core.pos_to_string(pos))
			return
		end
		local node = celevator.get_node(pos)
		local oldmem = core.deserialize(meta:get_string("mem")) or {}
		local oldupbuttonlights = oldmem.upcalls or {}
		local olddownbuttonlights = oldmem.dncalls or {}
		local newupbuttonlights = mem.upcalls or {}
		local newdownbuttonlights = mem.dncalls or {}
		local callbuttons = carinfo.callbuttons
		for _,button in pairs(callbuttons) do
			if oldupbuttonlights[button.landing] ~= newupbuttonlights[button.landing] then
				celevator.callbutton.setlight(button.pos,"up",newupbuttonlights[button.landing])
			end
			if olddownbuttonlights[button.landing] ~= newdownbuttonlights[button.landing] then
				celevator.callbutton.setlight(button.pos,"down",newdownbuttonlights[button.landing])
			end
		end
		local oldfs1led = oldmem.fs1led
		local newfs1led = mem.fs1led
		local fs1switches = carinfo.fs1switches or {}
		if oldfs1led ~= newfs1led then
			for _,fs1switch in pairs(fs1switches) do
				celevator.fs1switch.setled(fs1switch.pos,newfs1led)
			end
		end
		for _,message in ipairs(mem.messages) do
			local destinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",message.carid)))
			if destinfo and destinfo.controllerpos then
				celevator.controller.run(destinfo.controllerpos,{
					type = "dispatchermsg",
					source = mem.carid,
					channel = message.channel,
					msg = message.message,
				})
			end
		end
		for _,message in ipairs(mem.kioskmessages) do
			celevator.dbdkiosk.showassignment(core.get_position_from_hash(message.pos),message.car)
		end
		meta:set_string("mem",core.serialize(mem))
		if node.name == "celevator:dispatcher_open" then meta:set_string("formspec",mem.formspec or "") end
		meta:set_string("formspec_hidden",mem.formspec or "")
		meta:set_string("infotext",mem.infotext or "")
		local hash = core.hash_node_position(pos)
		if not celevator.dispatcher.iqueue[hash] then celevator.dispatcher.iqueue[hash] = mem.interrupts end
		for iid in pairs(changedinterrupts) do
			celevator.dispatcher.iqueue[hash][iid] = mem.interrupts[iid]
		end
		celevator.storage:set_string("dispatcher_iqueue",core.serialize(celevator.dispatcher.iqueue))
		celevator.dispatcher.running[hash] = nil
		if #celevator.dispatcher.equeue[hash] > 0 then
			local event = celevator.dispatcher.equeue[hash][1]
			table.remove(celevator.dispatcher.equeue[hash],1)
			celevator.storage:set_string("dispatcher_equeue",core.serialize(celevator.dispatcher.equeue))
			celevator.dispatcher.run(pos,event)
		end
		if carinfodirty then
			celevator.storage:set_string(string.format("car%d",carid),core.serialize(carinfo))
		end
	end
end

function celevator.dispatcher.run(pos,event)
	if not celevator.dispatcher.isdispatcher(pos) then
		return
	else
		local hash = core.hash_node_position(pos)
		if not celevator.dispatcher.equeue[hash] then
			celevator.dispatcher.equeue[hash] = {}
			celevator.storage:set_string("dispatcher_equeue",core.serialize(celevator.dispatcher.equeue))
		end
		if celevator.dispatcher.running[hash] then
			table.insert(celevator.dispatcher.equeue[hash],event)
			celevator.storage:set_string("dispatcher_equeue",core.serialize(celevator.dispatcher.equeue))
			if #celevator.dispatcher.equeue[hash] > 20 then
				local message = "[celevator] [dispatcher] Async process for dispatcher at %s is falling behind, %d events in queue"
				core.log("warning",string.format(message,core.pos_to_string(pos),#celevator.dispatcher.equeue[hash]))
			end
			return
		end
		celevator.dispatcher.running[hash] = true
		local meta = core.get_meta(pos)
		local mem = core.deserialize(meta:get_string("mem"))
		if not mem then
			core.log("error","[celevator] [controller] Failed to load dispatcher memory at "..core.pos_to_string(pos))
			return
		end
		mem.interrupts = celevator.dispatcher.iqueue[core.hash_node_position(pos)] or {}
		mem.carid = meta:get_int("carid")
		core.handle_async(fw,celevator.dispatcher.finish,pos,event,mem)
	end
end

function celevator.dispatcher.handlecallbutton(dispatcherpos,landing,dir)
	local event = {
		type = "callbutton",
		landing = landing,
		dir = dir,
	}
	celevator.dispatcher.run(dispatcherpos,event)
end

function celevator.dispatcher.handlefs1switch(dispatcherpos,on)
	local event = {
		type = "fs1switch",
		state = on,
	}
	celevator.dispatcher.run(dispatcherpos,event)
end

function celevator.dispatcher.checkiqueue(dtime)
	for hash,iqueue in pairs(celevator.dispatcher.iqueue) do
		local pos = core.get_position_from_hash(hash)
		local noneleft = true
		for iid,time in pairs(iqueue) do
			noneleft = false
			iqueue[iid] = time-dtime
			if iqueue[iid] < 0 then
				iqueue[iid] = nil
				local event = {}
				event.type = "interrupt"
				event.iid = iid
				celevator.dispatcher.run(pos,event)
			end
		end
		if noneleft then
			celevator.dispatcher.iqueue[hash] = nil
			celevator.storage:set_string("dispatcher_iqueue",core.serialize(celevator.dispatcher.iqueue))
		end
	end
end

core.register_globalstep(celevator.dispatcher.checkiqueue)

core.register_abm({
	label = "Run otherwise idle dispatchers if a user is nearby",
	nodenames = {"celevator:dispatcher","celevator:dispatcher_open"},
	interval = 1,
	chance = 1,
	action = function(pos)
		local event = {
			type = "abm"
		}
		celevator.dispatcher.run(pos,event)
	end,
})
