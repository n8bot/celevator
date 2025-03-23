minetest.register_chatcommand("carcall",{
	description = "Places a car call at the specified landing on the specified elevator",
	params = "<car ID> <landing number>",
	func = function(name,param)
		local carid,landing = string.match(param,"(%d+) (%d+)")
		if not (carid and tonumber(carid)) then
			return false,"Invalid car ID"
		end
		if not (landing and tonumber(landing)) then
			return false,"Invalid landing number"
		end
		local carinfo = minetest.deserialize(celevator.storage:get_string("car"..carid))
		if not (carinfo and carinfo.controllerpos) then
			return false,"No such car or car info is missing"
		end
		if not celevator.controller.iscontroller(carinfo.controllerpos) then
			return false,"Controller is missing"
		end
		if celevator.get_meta(carinfo.controllerpos):get_int("carid") ~= tonumber(carid) then
			return false,"Controller found but with wrong ID"
		end
		if minetest.is_protected(carinfo.controllerpos,name) then
			minetest.record_protection_violation(carinfo.controllerpos,name)
			return false,"Controller is protected"
		end
		celevator.controller.run(carinfo.controllerpos,{
				type = "remotemsg",
				channel = "carcall",
				msg = tonumber(landing),
		})
		return true,"Command sent"
	end,
})

minetest.register_chatcommand("upcall",{
	description = "Places an up hall call at the specified landing on the specified elevator or dispatcher",
	params = "<car ID> <landing number>",
	func = function(name,param)
		local carid,landing = string.match(param,"(%d+) (%d+)")
		if not (carid and tonumber(carid)) then
			return false,"Invalid car ID"
		end
		if not (landing and tonumber(landing)) then
			return false,"Invalid landing number"
		end
		local carinfo = minetest.deserialize(celevator.storage:get_string("car"..carid))
		if not (carinfo and (carinfo.controllerpos or carinfo.dispatcherpos)) then
			return false,"No such car or car info is missing"
		end
		if carinfo.controllerpos then
			if not celevator.controller.iscontroller(carinfo.controllerpos) then
				return false,"Controller is missing"
			end
			if celevator.get_meta(carinfo.controllerpos):get_int("carid") ~= tonumber(carid) then
				return false,"Controller found but with wrong ID"
			end
			if minetest.is_protected(carinfo.controllerpos,name) then
				minetest.record_protection_violation(carinfo.controllerpos,name)
				return false,"Controller is protected"
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
			return true,"Command sent"
		elseif carinfo.dispatcherpos then
			if not celevator.dispatcher.isdispatcher(carinfo.dispatcherpos) then
				return false,"Dispatcher is missing"
			end
			if celevator.get_meta(carinfo.dispatcherpos):get_int("carid") ~= tonumber(carid) then
				return false,"Dispatcher found but with wrong ID"
			end
			if minetest.is_protected(carinfo.dispatcherpos,name) then
				minetest.record_protection_violation(carinfo.dispatcherpos,name)
				return false,"Dispatcher is protected"
			end
			celevator.dispatcher.run(carinfo.dispatcherpos,{
					type = "remotemsg",
					channel = "upcall",
					msg = tonumber(landing),
			})
			return true,"Command sent"
		end
	end,
})

minetest.register_chatcommand("downcall",{
	description = "Places a down hall call at the specified landing on the specified elevator or dispatcher",
	params = "<car ID> <landing number>",
	func = function(name,param)
		local carid,landing = string.match(param,"(%d+) (%d+)")
		if not (carid and tonumber(carid)) then
			return false,"Invalid car ID"
		end
		if not (landing and tonumber(landing)) then
			return false,"Invalid landing number"
		end
		local carinfo = minetest.deserialize(celevator.storage:get_string("car"..carid))
		if not (carinfo and (carinfo.controllerpos or carinfo.dispatcherpos)) then
			return false,"No such car or car info is missing"
		end
		if carinfo.controllerpos then
			if not celevator.controller.iscontroller(carinfo.controllerpos) then
				return false,"Controller is missing"
			end
			if celevator.get_meta(carinfo.controllerpos):get_int("carid") ~= tonumber(carid) then
				return false,"Controller found but with wrong ID"
			end
			if minetest.is_protected(carinfo.controllerpos,name) then
				minetest.record_protection_violation(carinfo.controllerpos,name)
				return false,"Controller is protected"
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
			return true,"Command sent"
		elseif carinfo.dispatcherpos then
			if not celevator.dispatcher.isdispatcher(carinfo.dispatcherpos) then
				return false,"Dispatcher is missing"
			end
			if celevator.get_meta(carinfo.dispatcherpos):get_int("carid") ~= tonumber(carid) then
				return false,"Dispatcher found but with wrong ID"
			end
			if minetest.is_protected(carinfo.dispatcherpos,name) then
				minetest.record_protection_violation(carinfo.dispatcherpos,name)
				return false,"Dispatcher is protected"
			end
			celevator.dispatcher.run(carinfo.dispatcherpos,{
					type = "remotemsg",
					channel = "dncall",
					msg = tonumber(landing),
			})
			return true,"Command sent"
		end
	end,
})

minetest.register_chatcommand("elevstatus",{
	description = "View the status of the specified elevator",
	params = "<car ID>",
	func = function(_,param)
		if not (param and tonumber(param)) then
			return false,"Invalid car ID"
		end
		local carinfo = minetest.deserialize(celevator.storage:get_string("car"..param))
		if not (carinfo and carinfo.controllerpos) then
			return false,"No such car or car info is missing"
		end
		if not celevator.controller.iscontroller(carinfo.controllerpos) then
			return false,"Controller is missing"
		end
		local controllermeta = celevator.get_meta(carinfo.controllerpos)
		if controllermeta:get_int("carid") ~= tonumber(param) then
			return false,"Controller found but with wrong ID"
		end
		local mem = minetest.deserialize(controllermeta:get_string("mem"))
		if not mem then
			return false,"Failed to load controller memory"
		end
		local infotext = controllermeta:get_string("infotext")
		if mem.drive and mem.drive.status and mem.drive.status.vel and mem.drive.status.apos then
			infotext = infotext..string.format(" - %0.02fm - %+0.02fm/s",mem.drive.status.apos,mem.drive.status.vel)
		end
		return true,infotext
	end,
})
