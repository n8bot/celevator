local iorules = {
	vector.new(-1,0,0),
	vector.new(1,0,0),
	vector.new(0,0,-1),
	vector.new(0,0,1),
}

local function getpos(mem,searchpos,pioffset)
	local carpos = 0
	if not searchpos then searchpos = mem.drive.status.apos end
	if pioffset then searchpos = searchpos+0.5 end
	for k,v in ipairs(mem.params.floorheights) do
		carpos = carpos+v
		if carpos > searchpos then
			return k
		end
	end
end

local outputoptions = {
	{
		id = "normal",
		desc = "Normal Operation",
		func = function(mem)
			return (mem.carstate == "normal")
		end,
		needsfloor = false,
	},
	{
		id = "fault",
		desc = "Fault",
		func = function(mem)
			return (mem.carstate == "fault")
		end,
		needsfloor = false,
	},
	{
		id = "estop",
		desc = "Emergency Stop",
		func = function(mem)
			return (mem.carstate == "stop")
		end,
		needsfloor = false,
	},
	{
		id = "inspect",
		desc = "Inspection (Any)",
		func = function(mem)
			return (mem.carstate == "mrinspect" or mem.carstate == "inspconflict" or mem.carstate == "carinspect")
		end,
		needsfloor = false,
	},
	{
		id = "fire",
		desc = "Fire Service",
		func = function(mem)
			return (mem.carstate == "fs1" or mem.carstate == "fs2" or mem.carstate == "fs2hold")
		end,
		needsfloor = false,
	},
	{
		id = "fire1",
		desc = "Fire Service Phase 1",
		func = function(mem)
			return (mem.carstate == "fs1")
		end,
		needsfloor = false,
	},
	{
		id = "fire2",
		desc = "Fire Service Phase 2",
		func = function(mem)
			return (mem.carstate == "fs2" or mem.carstate == "fs2hold")
		end,
		needsfloor = false,
	},
	{
		id = "independent",
		desc = "Independent Service",
		func = function(mem)
			return (mem.carstate == "indep")
		end,
		needsfloor = false,
	},
	{
		id = "swing",
		desc = "Swing Operation",
		func = function(mem)
			return (mem.carstate == "swing")
		end,
		needsfloor = false,
	},
	{
		id = "opening",
		desc = "Doors Opening",
		func = function(mem)
			return (mem.doorstate == "opening")
		end,
		needsfloor = false,
	},
	{
		id = "open",
		desc = "Doors Open",
		func = function(mem)
			return (mem.doorstate == "open")
		end,
		needsfloor = false,
	},
	{
		id = "closing",
		desc = "Doors Closing",
		func = function(mem)
			return (mem.doorstate == "closing")
		end,
		needsfloor = false,
	},
	{
		id = "closed",
		desc = "Doors Closed",
		func = function(mem)
			return (mem.doorstate == "closed")
		end,
		needsfloor = false,
	},
	{
		id = "moveup",
		desc = "Moving Up",
		func = function(mem)
			return (mem.drive.status and mem.drive.status.vel > 0)
		end,
		needsfloor = false,
	},
	{
		id = "movedown",
		desc = "Moving Down",
		func = function(mem)
			return (mem.drive.status and mem.drive.status.vel < 0)
		end,
		needsfloor = false,
	},
	{
		id = "moving",
		desc = "Moving (Any Direction)",
		func = function(mem)
			return (mem.drive.status and mem.drive.status.vel ~= 0)
		end,
		needsfloor = false,
	},
	{
		id = "collectorup",
		desc = "Collecting Up Calls",
		func = function(mem)
			return (mem.carstate == "normal" and mem.direction == "up")
		end,
		needsfloor = false,
	},
	{
		id = "collectordown",
		desc = "Collecting Down Calls",
		func = function(mem)
			return (mem.carstate == "normal" and mem.direction == "down")
		end,
		needsfloor = false,
	},
	{
		id = "lightsw",
		desc = "Car Light Switch",
		func = function(mem)
			return mem.lightsw
		end,
		needsfloor = false,
	},
	{
		id = "fansw",
		desc = "Car Fan Switch",
		func = function(mem)
			return mem.fansw
		end,
		needsfloor = false,
	},
	{
		id = "upcall",
		desc = "Up Call Exists at Landing:",
		func = function(mem,floor)
			return mem.upcalls[floor]
		end,
		needsfloor = true,
	},
	{
		id = "downcall",
		desc = "Down Call Exists at Landing:",
		func = function(mem,floor)
			return mem.dncalls[floor]
		end,
		needsfloor = true,
	},
	{
		id = "carcall",
		desc = "Car Call Exists at Landing:",
		func = function(mem,floor)
			return mem.carcalls[floor]
		end,
		needsfloor = true,
	},
	{
		id = "apos",
		desc = "Car at Landing:",
		func = function(mem,floor)
			if mem.drive.status then
				return (getpos(mem,nil,true) == floor)
			end
		end,
		needsfloor = true,
	},
	{
		id = "dpos",
		desc = "Moving to Landing:",
		func = function(mem,floor)
			if mem.drive.status then
				return (getpos(mem,mem.drive.status.dpos) == floor)
			end
		end,
		needsfloor = true,
	},
}

local doutputoptions = {
	{
		id = "fire",
		desc = "Fire Service",
		func = function(mem)
			return mem.fs1led
		end,
		needsfloor = false,
	},
	{
		id = "upcall",
		desc = "Up Call Exists at Landing:",
		func = function(mem,floor)
			return mem.upcalls[floor]
		end,
		needsfloor = true,
	},
	{
		id = "downcall",
		desc = "Down Call Exists at Landing:",
		func = function(mem,floor)
			return mem.dncalls[floor]
		end,
		needsfloor = true,
	},
}

local inputoptions = {
	{
		id = "carcall",
		desc = "Car Call at Landing:",
		func_on = function(controllerpos,floor)
			celevator.controller.run(controllerpos,{
				type = "remotemsg",
				channel = "carcall",
				msg = floor,
			})
		end,
		needsfloor = true,
	},
	{
		id = "upcall",
		desc = "Up Call (simplex car) at Landing:",
		func_on = function(controllerpos,floor)
			celevator.controller.run(controllerpos,{
				type = "remotemsg",
				channel = "upcall",
				msg = floor,
			})
		end,
		needsfloor = true,
	},
	{
		id = "downcall",
		desc = "Down Call (simplex car) at Landing:",
		func_on = function(controllerpos,floor)
			celevator.controller.run(controllerpos,{
				type = "remotemsg",
				channel = "dncall",
				msg = floor,
			})
		end,
		needsfloor = true,
	},
	{
		id = "swingupcall",
		desc = "Up Call (swing) at Landing:",
		func_on = function(controllerpos,floor)
			celevator.controller.run(controllerpos,{
				type = "remotemsg",
				channel = "swingupcall",
				msg = floor,
			})
		end,
		needsfloor = true,
	},
	{
		id = "swingdowncall",
		desc = "Down Call (swing) at Landing:",
		func_on = function(controllerpos,floor)
			celevator.controller.run(controllerpos,{
				type = "remotemsg",
				channel = "swingdncall",
				msg = floor,
			})
		end,
		needsfloor = true,
	},
	{
		id = "fs1off",
		desc = "Deactivate Fire Service Phase 1",
		func_on = function(controllerpos)
			celevator.controller.run(controllerpos,{
				type = "fs1switch",
				state = false,
			})
		end,
		needsfloor = false,
	},
	{
		id = "fs1on",
		desc = "Activate Fire Service (main landing) Phase 1",
		func_on = function(controllerpos)
			celevator.controller.run(controllerpos,{
				type = "fs1switch",
				state = true,
			})
		end,
		needsfloor = false,
	},
	{
		id = "fs1onalt",
		desc = "Activate Fire Service (alternate landing) Phase 1",
		func_on = function(controllerpos)
			celevator.controller.run(controllerpos,{
				type = "fs1switch",
				state = true,
				mode = "alternate",
			})
		end,
		needsfloor = false,
	},
	{
		id = "mrsmoke",
		desc = "Machine Room or Hoistway Smoke Detector",
		func_on = function(controllerpos)
			celevator.controller.run(controllerpos,{
				type = "mrsmoke",
			})
		end,
		needsfloor = false,
	},
	{
		id = "secdeny",
		desc = "Lock Car Calls at Landing:",
		func_on = function(controllerpos,floor)
			celevator.controller.run(controllerpos,{
				type = "remotemsg",
				channel = "security",
				msg = {
					floor = floor,
					mode = "deny",
				},
			})
		end,
		needsfloor = true,
	},
	{
		id = "secauth",
		desc = "Require Auth for Car Calls at Landing:",
		func_on = function(controllerpos,floor)
			celevator.controller.run(controllerpos,{
				type = "remotemsg",
				channel = "security",
				msg = {
					floor = floor,
					mode = "auth",
				},
			})
		end,
		needsfloor = true,
	},
	{
		id = "secallow",
		desc = "Unlock Car Calls at Landing:",
		func_on = function(controllerpos,floor)
			celevator.controller.run(controllerpos,{
				type = "remotemsg",
				channel = "security",
				msg = {
					floor = floor,
					mode = nil,
				},
			})
		end,
		needsfloor = true,
	},
	{
		id = "swingon",
		desc = "Activate Swing Operation",
		func_on = function(controllerpos)
			celevator.controller.run(controllerpos,{
				type = "remotemsg",
				channel = "swing",
				msg = true,
			})
		end,
		needsfloor = false,
	},
	{
		id = "swingoff",
		desc = "Deactivate Swing Operation",
		func_on = function(controllerpos)
			celevator.controller.run(controllerpos,{
				type = "remotemsg",
				channel = "swing",
				msg = false,
			})
		end,
		needsfloor = false,
	},
}

local dinputoptions = {
	{
		id = "upcall",
		desc = "Up Call at Landing:",
		func_on = function(dispatcherpos,floor)
			celevator.dispatcher.run(dispatcherpos,{
				type = "remotemsg",
				channel = "upcall",
				msg = floor,
			})
		end,
		needsfloor = true,
	},
	{
		id = "downcall",
		desc = "Down Call at Landing:",
		func_on = function(dispatcherpos,floor)
			celevator.dispatcher.run(dispatcherpos,{
				type = "remotemsg",
				channel = "dncall",
				msg = floor,
			})
		end,
		needsfloor = true,
	},
	{
		id = "fs1off",
		desc = "Deactivate Fire Service Phase 1",
		func_on = function(dispatcherpos)
			celevator.dispatcher.run(dispatcherpos,{
				type = "fs1switch",
				state = false,
			})
		end,
		needsfloor = false,
	},
	{
		id = "fs1on",
		desc = "Activate Fire Service Phase 1",
		func_on = function(dispatcherpos)
			celevator.dispatcher.run(dispatcherpos,{
				type = "fs1switch",
				state = true,
			})
		end,
		needsfloor = false,
	},
}

local function updateoutputform(pos)
	local meta = minetest.get_meta(pos)
	local dmode = meta:get_int("dispatcher") == 1
	local fs = "formspec_version[7]size[8,6.5]"
	fs = fs.."tabheader[0,0;1;tab;Controller,Dispatcher;"..(dmode and "2" or "1")..";true;true]"
	fs = fs.."dropdown[1,0.5;6,1;signal;"
	local selected = 1
	local currentid = meta:get_string("signal")
	for k,v in ipairs(dmode and doutputoptions or outputoptions) do
		fs = fs..minetest.formspec_escape(v.desc)..","
		if v.id == currentid then selected = k end
	end
	fs = string.sub(fs,1,-2)
	fs = fs..";"..selected..";false]"
	fs = fs.."field[0.5,2.5;3,1;carid;"..(dmode and "Dispatcher ID" or "Car ID")..";${carid}]"
	fs = fs.."field[4.5,2.5;3,1;floor;Landing Number;${floor}]"
	fs = fs.."label[1.5,4;Not all signal options require a landing number.]"
	fs = fs.."button_exit[2.5,5;3,1;save;Save]"
	meta:set_string("formspec",fs)
end

local function handleoutputfields(pos,_,fields,player)
	local meta = minetest.get_meta(pos)
	if fields.quit and not fields.save then return end
	local name = player:get_player_name()
	if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
		if player:is_player() then
			minetest.record_protection_violation(pos,name)
		end
		return
	end
	if fields.save then
		local dmode = meta:get_int("dispatcher") == 1
		if not tonumber(fields.carid) then return end
		meta:set_int("carid",fields.carid)
		local carid = tonumber(fields.carid)
		local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid))) or {}
		if dmode then
			if not carinfo.dispatcherpos then return end
			if not celevator.dispatcher.isdispatcher(carinfo.dispatcherpos) then return end
			if minetest.is_protected(carinfo.dispatcherpos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
				if player:is_player() then
					minetest.chat_send_player(name,"Can't connect to a dispatcher you don't have access to.")
					minetest.record_protection_violation(carinfo.dispatcherpos,name)
				end
				return
			end
		else
			if not carinfo.controllerpos then return end
			if not celevator.controller.iscontroller(carinfo.controllerpos) then return end
			if minetest.is_protected(carinfo.controllerpos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
				if player:is_player() then
					minetest.chat_send_player(name,"Can't connect to a controller you don't have access to.")
					minetest.record_protection_violation(carinfo.controllerpos,name)
				end
				return
			end
		end
		local floor = tonumber(fields.floor)
		if floor then meta:set_int("floor",floor) end
		local def
		for _,v in ipairs(dmode and doutputoptions or outputoptions) do
			if v.desc == fields.signal then
				def = v
			end
		end
		if not def then return end
		if def.needsfloor and not floor then return end
		meta:set_string("signal",def.id)
		updateoutputform(pos)
		local infotext = carid.." - "..def.desc..(def.needsfloor and " "..floor or "")
		if dmode then
			infotext = "Dispatcher: "..infotext
		else
			infotext = "Car: "..infotext
		end
		meta:set_string("infotext",infotext)
	elseif fields.tab then
		meta:set_int("dispatcher",tonumber(fields.tab)-1)
		updateoutputform(pos)
	end
end

minetest.register_node("celevator:mesecons_output_off",{
	description = "Elevator Mesecons Output",
	tiles = {
		"celevator_meseconsoutput_top_off.png",
		"celevator_cabinet_sides.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.5,0.5,-0.47,0.5},
			{-0.438,-0.47,-0.438,0.438,-0.42,0.438},
		},
	},
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = iorules,
		},
	},
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("floor",1)
		updateoutputform(pos)
	end,
	on_receive_fields = handleoutputfields,
})

minetest.register_node("celevator:mesecons_output_on",{
	description = "Elevator Mesecons Output (on state - you hacker you!)",
	tiles = {
		"celevator_meseconsoutput_top_on.png",
		"celevator_cabinet_sides.png",
	},
	drop = "celevator:mesecons_output_off",
	groups = {
		dig_immediate = 2,
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.5,0.5,-0.47,0.5},
			{-0.438,-0.47,-0.438,0.438,-0.42,0.438},
		},
	},
	mesecons = {
		receptor = {
			state = mesecon.state.on,
			rules = iorules,
		},
	},
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("floor",1)
		updateoutputform(pos)
	end,
	on_receive_fields = handleoutputfields,
})

minetest.register_abm({
	label = "Update mesecons output",
	nodenames = {"celevator:mesecons_output_off","celevator:mesecons_output_on",},
	interval = 1,
	chance = 1,
	action = function(pos,node)
		local meta = minetest.get_meta(pos)
		local dmode = meta:get_int("dispatcher") == 1
		local oldstate = (node.name == "celevator:mesecons_output_on")
		local carid = meta:get_int("carid")
		if carid == 0 then return end
		local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid))) or {}
		if dmode then
			if not carinfo.dispatcherpos then return end
			if not celevator.dispatcher.isdispatcher(carinfo.dispatcherpos) then return end
		else
			if not carinfo.controllerpos then return end
			if not celevator.controller.iscontroller(carinfo.controllerpos) then return end
		end
		local floor = meta:get_int("floor")
		local mem = minetest.deserialize(minetest.get_meta(dmode and carinfo.dispatcherpos or carinfo.controllerpos):get_string("mem")) or {}
		local signal = meta:get_string("signal")
		local def
		for _,v in ipairs(dmode and doutputoptions or outputoptions) do
			if v.id == signal then
				def = v
				break
			end
		end
		if not def then return end
		local newstate = def.func(mem,floor)
		if newstate ~= oldstate then
			node.name = (newstate and "celevator:mesecons_output_on" or "celevator:mesecons_output_off")
			minetest.swap_node(pos,node)
			if newstate then
				mesecon.receptor_on(pos,iorules)
			else
				mesecon.receptor_off(pos,iorules)
			end
		end
	end,
})

local function updateinputform(pos)
	local meta = minetest.get_meta(pos)
	local dmode = meta:get_int("dispatcher") == 1
	local fs = "formspec_version[7]size[8,6.5]"
	fs = fs.."tabheader[0,0;1;tab;Controller,Dispatcher;"..(dmode and "2" or "1")..";true;true]"
	fs = fs.."dropdown[1,0.5;6,1;signal;"
	local selected = 1
	local currentid = meta:get_string("signal")
	for k,v in ipairs(dmode and dinputoptions or inputoptions) do
		fs = fs..minetest.formspec_escape(v.desc)..","
		if v.id == currentid then selected = k end
	end
	fs = string.sub(fs,1,-2)
	fs = fs..";"..selected..";false]"
	fs = fs.."field[0.5,2.5;3,1;carid;"..(dmode and "Dispatcher ID" or "Car ID")..";${carid}]"
	fs = fs.."field[4.5,2.5;3,1;floor;Landing Number;${floor}]"
	fs = fs.."label[1.5,4;Not all signal options require a landing number.]"
	fs = fs.."button_exit[2.5,5;3,1;save;Save]"
	meta:set_string("formspec",fs)
end

local function handleinputfields(pos,_,fields,player)
	if fields.quit and not fields.save then return end
	local meta = minetest.get_meta(pos)
	local name = player:get_player_name()
	if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
		if player:is_player() then
			minetest.record_protection_violation(pos,name)
		end
		return
	end
	if fields.save then
		local dmode = meta:get_int("dispatcher") == 1
		if not tonumber(fields.carid) then return end
		meta:set_int("carid",fields.carid)
		local carid = tonumber(fields.carid)
		local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid))) or {}
		if dmode then
			if not carinfo.dispatcherpos then return end
			if not celevator.dispatcher.isdispatcher(carinfo.dispatcherpos) then return end
			if minetest.is_protected(carinfo.dispatcherpos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
				if player:is_player() then
					minetest.chat_send_player(name,"Can't connect to a dispatcher you don't have access to.")
					minetest.record_protection_violation(carinfo.dispatcherpos,name)
				end
				return
			end
		else
			if not carinfo.controllerpos then return end
			if not celevator.controller.iscontroller(carinfo.controllerpos) then return end
			if minetest.is_protected(carinfo.controllerpos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
				if player:is_player() then
					minetest.chat_send_player(name,"Can't connect to a controller you don't have access to.")
					minetest.record_protection_violation(carinfo.controllerpos,name)
				end
				return
			end
		end
		local floor = tonumber(fields.floor)
		if floor then meta:set_int("floor",floor) end
		local def
		for _,v in ipairs(dmode and dinputoptions or inputoptions) do
			if v.desc == fields.signal then
				def = v
			end
		end
		if not def then return end
		if def.needsfloor and not floor then return end
		meta:set_string("signal",def.id)
		updateinputform(pos)
		local infotext = carid.." - "..def.desc..(def.needsfloor and " "..floor or "")
		if dmode then
			infotext = "Dispatcher: "..infotext
		else
			infotext = "Car: "..infotext
		end
		meta:set_string("infotext",infotext)
	elseif fields.tab then
		meta:set_int("dispatcher",tonumber(fields.tab)-1)
		updateinputform(pos)
	end
end

local function handleinput(pos,on)
	local meta = minetest.get_meta(pos)
	local carid = meta:get_int("carid")
	if carid == 0 then return end
	local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid))) or {}
	local dmode = meta:get_int("dispatcher") == 1
	if dmode then
		if not carinfo.dispatcherpos then return end
		if not celevator.dispatcher.isdispatcher(carinfo.dispatcherpos) then return end
	else
		if not carinfo.controllerpos then return end
		if not celevator.controller.iscontroller(carinfo.controllerpos) then return end
	end
	local floor = meta:get_int("floor")
	local signal = meta:get_string("signal")
	local def
	for _,v in ipairs(dmode and dinputoptions or inputoptions) do
		if v.id == signal then
			def = v
			break
		end
	end
	if not def then return end
	if dmode then
		if on then
			if def.func_on then def.func_on(carinfo.dispatcherpos,floor) end
		else
			if def.func_off then def.func_off(carinfo.dispatcherpos,floor) end
		end
	else
		if on then
			if def.func_on then def.func_on(carinfo.controllerpos,floor) end
		else
			if def.func_off then def.func_off(carinfo.controllerpos,floor) end
		end
	end
end

minetest.register_node("celevator:mesecons_input_off",{
	description = "Elevator Mesecons Input",
	tiles = {
		"celevator_meseconsinput_top_off.png",
		"celevator_cabinet_sides.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.5,0.5,-0.47,0.5},
			{-0.438,-0.47,-0.438,0.438,-0.42,0.438},
		},
	},
	mesecons = {
		effector = {
			rules = iorules,
			action_on = function(pos,node)
				node.name = "celevator:mesecons_input_on"
				minetest.swap_node(pos,node)
				handleinput(pos,true)
			end,
		},
	},
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("floor",1)
		updateinputform(pos)
	end,
	on_receive_fields = handleinputfields,
})

minetest.register_node("celevator:mesecons_input_on",{
	description = "Elevator Mesecons Input (on state - you hacker you!)",
	tiles = {
		"celevator_meseconsinput_top_on.png",
		"celevator_cabinet_sides.png",
	},
	drop = "celevator:mesecons_input_off",
	groups = {
		dig_immediate = 2,
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.5,0.5,-0.47,0.5},
			{-0.438,-0.47,-0.438,0.438,-0.42,0.438},
		},
	},
	mesecons = {
		effector = {
			rules = iorules,
			action_off = function(pos,node)
				node.name = "celevator:mesecons_input_off"
				minetest.swap_node(pos,node)
				handleinput(pos,false)
			end,
		},
	},
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("floor",1)
		updateinputform(pos)
	end,
	on_receive_fields = handleinputfields,
})
