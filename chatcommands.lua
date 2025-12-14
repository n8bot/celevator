local S = core.get_translator("celevator")

core.register_chatcommand("carcall",{
	description = S("Places a car call at the specified landing on the specified elevator"),
	params = S("<car ID> <landing number>"),
	func = function(name,param)
		local carid,landing = string.match(param,"(%d+) (%d+)")
		if not (carid and tonumber(carid)) then
			return false,S("Invalid car ID")
		end
		if not (landing and tonumber(landing)) then
			return false,S("Invalid landing number")
		end
		local carinfo = core.deserialize(celevator.storage:get_string("car"..carid))
		if not (carinfo and carinfo.controllerpos) then
			return false,S("No such car or car info is missing")
		end
		if not celevator.controller.iscontroller(carinfo.controllerpos) then
			return false,S("Controller is missing")
		end
		if celevator.get_meta(carinfo.controllerpos):get_int("carid") ~= tonumber(carid) then
			return false,S("Controller found but with wrong ID")
		end
		if core.is_protected(carinfo.controllerpos,name) then
			core.record_protection_violation(carinfo.controllerpos,name)
			return false,S("Controller is protected")
		end
		celevator.controller.run(carinfo.controllerpos,{
				type = "remotemsg",
				channel = "carcall",
				msg = tonumber(landing),
		})
		return true,S("Command sent")
	end,
})

core.register_chatcommand("upcall",{
	description = S("Places an up hall call at the specified landing on the specified elevator or dispatcher"),
	params = S("<car ID> <landing number>"),
	func = function(name,param)
		local carid,landing = string.match(param,"(%d+) (%d+)")
		if not (carid and tonumber(carid)) then
			return false,S("Invalid car ID")
		end
		if not (landing and tonumber(landing)) then
			return false,S("Invalid landing number")
		end
		local carinfo = core.deserialize(celevator.storage:get_string("car"..carid))
		if not (carinfo and (carinfo.controllerpos or carinfo.dispatcherpos)) then
			return false,S("No such car or car info is missing")
		end
		if carinfo.controllerpos then
			if not celevator.controller.iscontroller(carinfo.controllerpos) then
				return false,S("Controller is missing")
			end
			if celevator.get_meta(carinfo.controllerpos):get_int("carid") ~= tonumber(carid) then
				return false,S("Controller found but with wrong ID")
			end
			if core.is_protected(carinfo.controllerpos,name) then
				core.record_protection_violation(carinfo.controllerpos,name)
				return false,S("Controller is protected")
			end
			--One of these will work depending on the mode, the other will be ignored
			celevator.controller.run(carinfo.controllerpos,{
					type = "remotemsg",
					channel = "upcall",
					msg = tonumber(landing),
			})
			celevator.controller.run(carinfo.controllerpos,{
					type = "remotemsg",
					channel = "swingupcall",
					msg = tonumber(landing),
			})
			return true,S("Command sent")
		elseif carinfo.dispatcherpos then
			if not celevator.dispatcher.isdispatcher(carinfo.dispatcherpos) then
				return false,S("Dispatcher is missing")
			end
			if celevator.get_meta(carinfo.dispatcherpos):get_int("carid") ~= tonumber(carid) then
				return false,S("Dispatcher found but with wrong ID")
			end
			if core.is_protected(carinfo.dispatcherpos,name) then
				core.record_protection_violation(carinfo.dispatcherpos,name)
				return false,S("Dispatcher is protected")
			end
			celevator.dispatcher.run(carinfo.dispatcherpos,{
					type = "remotemsg",
					channel = "upcall",
					msg = tonumber(landing),
			})
			return true,S("Command sent")
		end
	end,
})

core.register_chatcommand("downcall",{
	description = S("Places a down hall call at the specified landing on the specified elevator or dispatcher"),
	params = S("<car ID> <landing number>"),
	func = function(name,param)
		local carid,landing = string.match(param,"(%d+) (%d+)")
		if not (carid and tonumber(carid)) then
			return false,S("Invalid car ID")
		end
		if not (landing and tonumber(landing)) then
			return false,S("Invalid landing number")
		end
		local carinfo = core.deserialize(celevator.storage:get_string("car"..carid))
		if not (carinfo and (carinfo.controllerpos or carinfo.dispatcherpos)) then
			return false,S("No such car or car info is missing")
		end
		if carinfo.controllerpos then
			if not celevator.controller.iscontroller(carinfo.controllerpos) then
				return false,S("Controller is missing")
			end
			if celevator.get_meta(carinfo.controllerpos):get_int("carid") ~= tonumber(carid) then
				return false,S("Controller found but with wrong ID")
			end
			if core.is_protected(carinfo.controllerpos,name) then
				core.record_protection_violation(carinfo.controllerpos,name)
				return false,S("Controller is protected")
			end
			--One of these will work depending on the mode, the other will be ignored
			celevator.controller.run(carinfo.controllerpos,{
					type = "remotemsg",
					channel = "dncall",
					msg = tonumber(landing),
			})
			celevator.controller.run(carinfo.controllerpos,{
					type = "remotemsg",
					channel = "swingdncall",
					msg = tonumber(landing),
			})
			return true,S("Command sent")
		elseif carinfo.dispatcherpos then
			if not celevator.dispatcher.isdispatcher(carinfo.dispatcherpos) then
				return false,S("Dispatcher is missing")
			end
			if celevator.get_meta(carinfo.dispatcherpos):get_int("carid") ~= tonumber(carid) then
				return false,S("Dispatcher found but with wrong ID")
			end
			if core.is_protected(carinfo.dispatcherpos,name) then
				core.record_protection_violation(carinfo.dispatcherpos,name)
				return false,S("Dispatcher is protected")
			end
			celevator.dispatcher.run(carinfo.dispatcherpos,{
					type = "remotemsg",
					channel = "dncall",
					msg = tonumber(landing),
			})
			return true,S("Command sent")
		end
	end,
})

core.register_chatcommand("elevstatus",{
	description = S("View the status of the specified elevator"),
	params = S("<car ID>"),
	func = function(_,param)
		if not (param and tonumber(param)) then
			return false,S("Invalid car ID")
		end
		local carinfo = core.deserialize(celevator.storage:get_string("car"..param))
		if not (carinfo and carinfo.controllerpos) then
			return false,S("No such car or car info is missing")
		end
		if not celevator.controller.iscontroller(carinfo.controllerpos) then
			return false,S("Controller is missing")
		end
		local controllermeta = celevator.get_meta(carinfo.controllerpos)
		if controllermeta:get_int("carid") ~= tonumber(param) then
			return false,S("Controller found but with wrong ID")
		end
		local mem = core.deserialize(controllermeta:get_string("mem"))
		if not mem then
			return false,S("Failed to load controller memory")
		end
		local infotext = controllermeta:get_string("infotext")
		if mem.drive and mem.drive.status and mem.drive.status.vel and mem.drive.status.apos then
			infotext = infotext..string.format(" - %0.02fm - %+0.02fm/s",mem.drive.status.apos,mem.drive.status.vel)
		end
		return true,infotext
	end,
})
