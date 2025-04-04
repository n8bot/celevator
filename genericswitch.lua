local inputoptions = {
	{
		id = "none",
		desc = "(none)",
		func_on = function() end,
		needsfloor = false,
	},
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
		id = "none",
		desc = "(none)",
		func_on = function() end,
		needsfloor = false,
	},
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

local function updateinputform(pos)
	local meta = minetest.get_meta(pos)
	local dmode = meta:get_int("dispatcher") == 1
	local fs = "formspec_version[7]size[8,8.5]"
	fs = fs.."tabheader[0,0;1;tab;Controller,Dispatcher;"..(dmode and "2" or "1")..";true;true]"
	fs = fs.."vertlabel[0.33,1;ON]"
	fs = fs.."dropdown[1,0.5;6,1;signal_on;"
	local selected_on = 1
	local currentid_on = meta:get_string("signal_on")
	for k,v in ipairs(dmode and dinputoptions or inputoptions) do
		fs = fs..minetest.formspec_escape(v.desc)..","
		if v.id == currentid_on then selected_on = k end
	end
	fs = string.sub(fs,1,-2)
	fs = fs..";"..selected_on..";false]"
	fs = fs.."field[0.5,2;3,1;carid;"..(dmode and "Dispatcher ID" or "Car ID")..";${carid}]"
	fs = fs.."field[4.5,2;3,1;floor_on;Landing Number;${floor_on}]"
	fs = fs.."box[0,3.25;8,0.1;#CCCCCC]"
	fs = fs.."vertlabel[0.33,4;OFF]"
	fs = fs.."dropdown[1,3.5;6,1;signal_off;"
	local selected_off = 1
	local currentid_off = meta:get_string("signal_off")
	for k,v in ipairs(dmode and dinputoptions or inputoptions) do
		fs = fs..minetest.formspec_escape(v.desc)..","
		if v.id == currentid_off then selected_off = k end
	end
	fs = string.sub(fs,1,-2)
	fs = fs..";"..selected_off..";false]"
	fs = fs.."field[4.5,5;3,1;floor_off;Landing Number;${floor_off}]"
	fs = fs.."label[1.5,6.5;Not all signal options require a landing number.]"
	fs = fs.."button_exit[2.5,7;3,1;save;Save]"
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
		local floor_on = tonumber(fields.floor_on)
		if floor_on then meta:set_int("floor_on",floor_on) end
		local def_on
		for _,v in ipairs(dmode and dinputoptions or inputoptions) do
			if v.desc == fields.signal_on then
				def_on = v
			end
		end
		if not def_on then return end
		if def_on.needsfloor and not floor_on then return end
		local floor_off = tonumber(fields.floor_off)
		if floor_off then meta:set_int("floor_off",floor_off) end
		local def_off
		for _,v in ipairs(dmode and dinputoptions or inputoptions) do
			if v.desc == fields.signal_off then
				def_off = v
			end
		end
		if not def_off then return end
		if def_off.needsfloor and not floor_off then return end
		meta:set_string("signal_on",def_on.id)
		meta:set_string("signal_off",def_off.id)
		updateinputform(pos)
		local infotext = carid.." - "..def_on.desc..(def_on.needsfloor and " "..floor_on or "")
		if def_on.id == "none" or def_off.id ~= "none" then
			infotext = infotext.." / "..def_off.desc..(def_off.needsfloor and " "..floor_off or "")
		end
		if dmode then
			infotext = "Dispatcher: "..infotext
		else
			infotext = "Car: "..infotext
		end
		meta:set_string("infotext",infotext)
		if def_on.id ~= "none" or def_off.id ~= "none" then
			meta:set_string("formspec","")
			local momentary = def_off.id == "none"
			local node = minetest.get_node(pos)
			node.name = (momentary and "celevator:genericswitch_momentary_off" or "celevator:genericswitch_maintained_off")
			minetest.swap_node(pos,node)
		end
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
	local floor = meta:get_int(on and "floor_on" or "floor_off")
	local signal = meta:get_string(on and "signal_on" or "signal_off")
	local def
	for _,v in ipairs(dmode and dinputoptions or inputoptions) do
		if v.id == signal then
			def = v
			break
		end
	end
	if not def then return end
	if dmode then
		if def.func_on then def.func_on(carinfo.dispatcherpos,floor) end
	else
		if def.func_on then def.func_on(carinfo.controllerpos,floor) end
	end
end

minetest.register_node("celevator:genericswitch",{
	description = "Elevator Keyswitch",
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_genericswitch_off.png",
	},
	groups = {
		dig_immediate = 2,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.219,-0.198,0.475,0.214,0.464,0.5},
		},
	},
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("floor",1)
		updateinputform(pos)
	end,
	on_receive_fields = handleinputfields,
})

minetest.register_node("celevator:genericswitch_maintained_off",{
	description = "Elevator Keyswitch (maintained, off state - you hacker you!)",
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_genericswitch_off.png",
	},
	drop = "celevator:genericswitch",
	groups = {
		dig_immediate = 2,
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.219,-0.198,0.475,0.214,0.464,0.5},
		},
	},
	on_rightclick = function(pos,node,player)
		local name = player:get_player_name()
		if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
			minetest.chat_send_player(name,"You don't have a key for this switch.")
			minetest.record_protection_violation(pos,name)
			return
		end
		node.name = "celevator:genericswitch_maintained_on"
		minetest.swap_node(pos,node)
		handleinput(pos,true)
	end,
})

minetest.register_node("celevator:genericswitch_maintained_on",{
	description = "Elevator Keyswitch (maintained, on state - you hacker you!)",
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_genericswitch_on.png",
	},
	drop = "celevator:genericswitch",
	groups = {
		dig_immediate = 2,
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.219,-0.198,0.475,0.214,0.464,0.5},
		},
	},
	on_rightclick = function(pos,node,player)
		local name = player:get_player_name()
		if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
			minetest.chat_send_player(name,"You don't have a key for this switch.")
			minetest.record_protection_violation(pos,name)
			return
		end
		node.name = "celevator:genericswitch_maintained_off"
		minetest.swap_node(pos,node)
		handleinput(pos,false)
	end,
})

minetest.register_node("celevator:genericswitch_momentary_off",{
	description = "Elevator Keyswitch (momentary, off state - you hacker you!)",
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_genericswitch_momentary_off.png",
	},
	drop = "celevator:genericswitch",
	groups = {
		dig_immediate = 2,
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.219,-0.198,0.475,0.214,0.464,0.5},
		},
	},
	on_rightclick = function(pos,node,player)
		local name = player:get_player_name()
		if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
			minetest.chat_send_player(name,"You don't have a key for this switch.")
			minetest.record_protection_violation(pos,name)
			return
		end
		node.name = "celevator:genericswitch_momentary_on"
		minetest.swap_node(pos,node)
		handleinput(pos,true)
		minetest.after(1,function()
			local newnode = minetest.get_node(pos)
			if newnode.name == "celevator:genericswitch_momentary_on" then
				newnode.name = "celevator:genericswitch_momentary_off"
				minetest.swap_node(pos,newnode)
			end
		end)
	end,
})

minetest.register_node("celevator:genericswitch_momentary_on",{
	description = "Elevator Keyswitch (momentary, on state - you hacker you!)",
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_genericswitch_momentary_on.png",
	},
	drop = "celevator:genericswitch",
	groups = {
		dig_immediate = 2,
		not_in_creative_inventory = 1,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.219,-0.198,0.475,0.214,0.464,0.5},
		},
	},
})
