minetest.register_node("celevator:digilines_io",{
	description = "Elevator Digilines Input/Output",
	tiles = {
		"celevator_digilinesio_top.png",
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
	digilines = {
		receptor = {},
		effector = {
			action = function(pos,_,channel,msg)
				if msg == "GET" then msg = {command = "GET"} end
				if type(msg) ~= "table" or type(msg.command) ~= "string" then return end
				local meta = minetest.get_meta(pos)
				local setchannel = meta:get_string("channel")
				if setchannel ~= channel then return end
				local carid = meta:get_int("carid")
				if carid == 0 then return end
				local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid))) or {}
				if not carinfo.controllerpos then return end
				if not celevator.controller.iscontroller(carinfo.controllerpos) then return end
				msg.command = string.lower(msg.command)
				if msg.command == "get" then
					local mem = minetest.deserialize(minetest.get_meta(carinfo.controllerpos):get_string("mem"))
					if not mem then return end
					local ret = {
						carstate = mem.carstate,
						doorstate = mem.doorstate,
						carcalls = mem.carcalls,
						upcalls = mem.upcalls,
						swingupcalls = mem.swingupcalls,
						groupupcalls = mem.groupupcalls,
						downcalls = mem.dncalls,
						swingdowncalls = mem.swingdncalls,
						groupdowncalls = mem.groupdncalls,
						fireserviceled = mem.fs1led,
						switches = {
							stop = mem.controllerstopsw,
							machineroominspection = mem.controllerinspectsw,
							cartopinspection = mem.cartopinspectsw,
							capture = mem.capturesw,
							test = mem.testsw,
							fireservice1 = mem.fs1switch,
							fireservice2 = mem.fs2sw,
							indpedendent = mem.indsw,
							light = mem.lightsw,
							fan = mem.fansw,
						},
						parameters = mem.params,
						drivestatus = mem.drive.status,
						direction = mem.direction,
					}
					digilines.receptor_send(pos,digilines.rules.default,channel,ret)
				elseif msg.command == "carcall" and type(msg.floor) == "number" then
					celevator.controller.run(carinfo.controllerpos,{
						type = "remotemsg",
						channel = "carcall",
						msg = msg.floor,
					})
				elseif msg.command == "upcall" and type(msg.floor) == "number" then
					celevator.controller.run(carinfo.controllerpos,{
						type = "remotemsg",
						channel = "upcall",
						msg = msg.floor,
					})
				elseif msg.command == "downcall" and type(msg.floor) == "number" then
					celevator.controller.run(carinfo.controllerpos,{
						type = "remotemsg",
						channel = "dncall",
						msg = msg.floor,
					})
				elseif msg.command == "swingupcall" and type(msg.floor) == "number" then
					celevator.controller.run(carinfo.controllerpos,{
						type = "remotemsg",
						channel = "swingupcall",
						msg = msg.floor,
					})
				elseif msg.command == "swingdowncall" and type(msg.floor) == "number" then
					celevator.controller.run(carinfo.controllerpos,{
						type = "remotemsg",
						channel = "swingdncall",
						msg = msg.floor,
					})
				end
			end,
		},
	},
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		local fs = "formspec_version[7]size[8,4.5]"
		fs = fs.."field[0.5,0.5;3,1;channel;Channel;${channel}]"
		fs = fs.."field[4.5,0.5;3,1;carid;Car ID;${carid}]"
		fs = fs.."button_exit[2.5,2;3,1;save;Save]"
		meta:set_string("formspec",fs)
	end,
	on_receive_fields = function(pos,_,fields,player)
		local meta = minetest.get_meta(pos)
		if not fields.save then return end
		local name = player:get_player_name()
		if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
			if player:is_player() then
				minetest.record_protection_violation(pos,name)
			end
			return
		end
		if not tonumber(fields.carid) then return end
		meta:set_int("carid",fields.carid)
		local carid = tonumber(fields.carid)
		local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid))) or {}
		if not carinfo.controllerpos then return end
		if not celevator.controller.iscontroller(carinfo.controllerpos) then return end
		if minetest.is_protected(carinfo.controllerpos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
			if player:is_player() then
				minetest.chat_send_player(name,"Can't connect to a controller you don't have access to.")
				minetest.record_protection_violation(carinfo.controllerpos,name)
			end
			return
		end
		meta:set_string("channel",fields.channel)
		local infotext = "Car: "..carid
		meta:set_string("infotext",infotext)
	end,
})
