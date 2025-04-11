local pos,event,mem = ...

local changedinterrupts = {}

mem.messages = {}

local function send(carid,channel,message)
	table.insert(mem.messages,{
		carid = carid,
		channel = channel,
		message = message,
	})
end

local function fault(ftype,fatal)
	if fatal then mem.fatalfault = true end
	if not mem.activefaults then mem.activefaults = {} end
	if not mem.faultlog then mem.faultlog = {} end
	if mem.activefaults[ftype] then return end
	mem.activefaults[ftype] = true
	table.insert(mem.faultlog,{ftype = ftype,timestamp = os.time()})
end

if not mem.drive.status then
	fault("drivecomm",true)
	mem.drive.status = {
		apos = 0,
		dpos = 0,
		vel = 0,
		maxvel = 0,
	}
elseif mem.drive.status.fault then
	fault("drive"..mem.drive.status.fault,true)
end

if mem.drive.state == "uninit" then
	fault("driveuninit",true)
end

local juststarted = false

local modenames = {
	normal = "Normal Operation",
	uninit = "Uninitialized",
	resync = "Position Sync - Floor",
	bfdemand = "Position Sync - Terminal",
	fault = "Fault",
	stop = "Emergency Stop",
	mrinspect = "Machine Room Inspection",
	carinspect = "Car Top Inspection",
	inspconflict = "Inspection Conflict", --No longer used but some controllers may be in it at update time
	fs1 = "Fire Service - Phase 1",
	fs2 = "Fire Service - Phase 2",
	fs2hold = "Fire Service - Phase 2 Hold",
	indep = "Independent Service",
	capture = "Captured",
	test = "Test Mode",
	swing = "Swing Operation",
}

local doorstates = {
	open = "Open",
	opening = "Opening",
	closing = "Closing",
	closed = "Closed",
	testtiming = "Closed",
}

local faultnames = {
	opentimeout = "Door Open Timeout",
	closetimeout = "Door Close Timeout",
	drivecomm = "Lost Communication With Drive",
	driveuninit = "Drive Not Configured",
	drivemetaload = "Drive Metadata Load Failure",
	drivebadorigin = "Drive Origin Invalid",
	drivedoorinterlock = "Attempted to Move Doors With Car in Motion",
	driveoutofbounds = "Target Position Out of Bounds",
	drivenomachine = "Hoist Machine Missing",
	drivemachinemismatch = "Drive<->Machine ID Mismatch",
	drivecontrollermismatch = "Controller<->Drive ID Mismatch",
}

local function drivecmd(command)
	table.insert(mem.drive.commands,command)
end

local function interrupt(time,iid)
	mem.interrupts[iid] = time
	changedinterrupts[iid] = true
end

local function getpos(pioffset)
	local ret = 0
	local searchpos = mem.drive.status.apos
	if pioffset then searchpos = math.max(0,searchpos+0.5) end
	for k,v in ipairs(mem.params.floorheights) do
		ret = ret+v
		if ret > searchpos then return k end
	end
	return #mem.params.floorheights
end

local function gettarget(floor)
	local target = 0
	if floor == 1 then return 0 end
	for i=1,floor-1,1 do
		if not mem.params.floorheights[i] then return 0 end
		target = target+mem.params.floorheights[i]
	end
	return target
end

local function gotofloor(floor)
	mem.carmotion = true
	drivecmd({
		command = "setmaxvel",
		maxvel = mem.params.contractspeed
	})
	if gettarget(floor) ~= mem.drive.status.apos then
		drivecmd({
			command = "moveto",
			pos = gettarget(floor)
		})
	end
	interrupt(0,"checkdrive")
	juststarted = true
end

local function getnextcallabove(dir,excludecurrent)
	local start = (excludecurrent and getpos()+1 or getpos())
	for i=start,#mem.params.floorheights,1 do
		if not dir then
			if mem.carcalls[i] then
				return i,"car"
			elseif mem.upcalls[i] then
				return i,"up"
			elseif mem.dncalls[i] then
				return i,"down"
			end
		elseif dir == "up" then
			if mem.carcalls[i] then
				return i,"car"
			elseif mem.upcalls[i] then
				return i,"up"
			end
		elseif dir == "down" then
			if mem.carcalls[i] then
				return i,"car"
			elseif mem.dncalls[i] then
				return i,"down"
			end
		end
	end
end

local function getnextcallbelow(dir,excludecurrent)
	local start = (excludecurrent and getpos()-1 or getpos())
	for i=start,1,-1 do
		if not dir then
			if mem.carcalls[i] then
				return i,"car"
			elseif mem.upcalls[i] then
				return i,"up"
			elseif mem.dncalls[i] then
				return i,"down"
			end
		elseif dir == "up" then
			if mem.carcalls[i] then
				return i,"car"
			elseif mem.upcalls[i] then
				return i,"up"
			end
		elseif dir == "down" then
			if mem.carcalls[i] then
				return i,"car"
			elseif mem.dncalls[i] then
				return i,"down"
			end
		end
	end
end

local function getlowestupcall()
	for i=1,#mem.params.floornames,1 do
		if mem.upcalls[i] then return i end
	end
end

local function gethighestdowncall()
	for i=#mem.params.floornames,1,-1 do
		if mem.dncalls[i] then return i end
	end
end

local function open()
	mem.doorstate = "opening"
	drivecmd({command = "open"})
	interrupt(0.2,"checkopen")
	interrupt(10,"opentimeout")
	interrupt(nil,"closetimeout")
	if mem.nudging then
		if (mem.carstate == "normal" or mem.carstate == "swing") then
			interrupt(0,"nudge")
		else
			mem.nudging = false
		end
	end
end

local function close(nudge)
	mem.doorstate = "closing"
	drivecmd({command = "close",nudge = nudge})
	interrupt(0.2,"checkclosed")
	interrupt((nudge and 30 or 10),"closetimeout")
	interrupt(nil,"opentimeout")
end

mem.formspec = ""

local function fs(element)
	mem.formspec = mem.formspec..element
end

if type(mem.groupupcalls) ~= "table" then mem.groupupcalls = {} end
if type(mem.groupdncalls) ~= "table" then mem.groupdncalls = {} end
if type(mem.swingupcalls) ~= "table" then mem.swingupcalls = {} end
if type(mem.swingdncalls) ~= "table" then mem.swingdncalls = {} end
if mem.params and not mem.params.carcallsecurity then mem.params.carcallsecurity = {} end
if mem.params and not mem.params.nudgetimer then mem.params.nudgetimer = 30 end
if mem.params and not mem.params.altrecalllanding then mem.params.altrecalllanding = 2 end
if mem.params and not mem.recallto then mem.recallto = mem.params.mainlanding or 1 end
if mem.params and not mem.params.inspectionspeed then mem.params.inspectionspeed = 0.2 end
if mem.params and not mem.params.indepunlock then mem.params.indepunlock = {} end
if mem.params and not mem.params.secoverrideusers then mem.params.secoverrideusers = {} end
if mem.params and mem.params.swingcallwhennotswing == nil then mem.params.swingcallwhennotswing = true end
if not mem.editinguser then mem.editinguser = 1 end

if mem.params and #mem.params.floornames < 2 then
	mem.params.floornames = {"1","2","3"}
	mem.params.floorheights = {5,5,5}
	mem.carstate = "bfdemand"
	if mem.doorstate == "closed" then
		drivecmd({
			command = "setmaxvel",
			maxvel = mem.params.contractspeed,
		})
		drivecmd({command = "resetpos"})
		interrupt(0.1,"checkdrive")
		mem.carmotion = true
		juststarted = true
	else
		close()
	end
end

if event.type == "program" then
	mem.carstate = "uninit"
	mem.editingfloor = 1
	mem.editinguser = 1
	mem.doorstate = "closed"
	mem.carmotion = false
	mem.carcalls = {}
	mem.upcalls = {}
	mem.dncalls = {}
	mem.groupupcalls = {}
	mem.groupdncalls = {}
	mem.swingupcalls = {}
	mem.swingdncalls = {}
	mem.screenpage = 1
	mem.scrollfollowscar = true
	mem.controllerstopsw = false
	mem.controllerinspectsw = false
	mem.cartopinspectsw = false
	mem.capturesw = false
	mem.testsw = false
	mem.activefaults = {}
	mem.faultlog = {}
	mem.fatalfault = false
	mem.fs1switch = false
	mem.fs1led = false
	mem.fs2sw = "off"
	mem.indsw = false
	mem.lightsw = true
	mem.fansw = true
	if not mem.params then
		mem.state = "unconfigured"
		mem.screenstate = "oobe_welcome"
		mem.params = {
			contractspeed = 1,
			floorheights = {5,5,5},
			floornames = {"1","2","3"},
			doortimer = 5,
			groupmode = "simplex",
			mainlanding = 1,
			altrecalllanding = 2,
			carcallsecurity = {},
			nudgetimer = 30,
			inspectionspeed = 0.2,
			indepunlock = {},
			secoverrideusers = {},
			swingcallwhennotswing = true,
		}
	end
elseif event.type == "ui" then
	if mem.screenstate == "oobe_welcome" then
		if event.fields.license then
			mem.screenstate = "oobe_license"
		elseif event.fields.next then
			mem.screenstate = "oobe_groupmode"
		end
	elseif mem.screenstate == "oobe_license" then
		if event.fields.back then
			mem.screenstate = "oobe_welcome"
		end
	elseif mem.screenstate == "oobe_groupmode" then
		if event.fields.back then
			mem.screenstate = "oobe_welcome"
		elseif event.fields.simplex then
			mem.screenstate = "oobe_floortable"
			mem.params.groupmode = "simplex"
		elseif event.fields.group then
			mem.screenstate = "oobe_dispatcherconnect"
			mem.params.groupmode = "group"
		end
	elseif mem.screenstate == "oobe_dispatcherconnect" then
		if event.fields.back then
			mem.screenstate = "oobe_groupmode"
		end
	elseif mem.screenstate == "oobe_floortable" or mem.screenstate == "floortable" then
		local exp = event.fields.floor and minetest.explode_textlist_event(event.fields.floor) or {}
		if event.fields.back then
			mem.screenstate = "oobe_groupmode"
		elseif event.fields.next then
			if mem.screenstate == "oobe_floortable" then
				mem.activefaults = {}
				mem.faultlog = {}
				mem.fatalfault = false
			end
			mem.state = "configured"
			mem.screenstate = (mem.screenstate == "oobe_floortable" and "status" or "parameters")
			mem.screenpage = 1
			mem.carstate = "bfdemand"
			if mem.doorstate == "closed" then
				drivecmd({
					command = "setmaxvel",
					maxvel = mem.params.contractspeed,
				})
				drivecmd({command = "resetpos"})
				interrupt(0.1,"checkdrive")
				mem.carmotion = true
				juststarted = true
			else
				close()
			end
		elseif exp.type == "CHG" then
			mem.editingfloor = #mem.params.floornames-exp.index+1
		elseif exp.type == "DCL" then
			mem.editingfloor = #mem.params.floornames-exp.index+1
			mem.screenstate = (mem.screenstate == "oobe_floortable" and "oobe_floortable_edit" or "floortable_edit")
		elseif event.fields.edit then
			mem.screenstate = (mem.screenstate == "oobe_floortable" and "oobe_floortable_edit" or "floortable_edit")
		elseif event.fields.add then
			table.insert(mem.params.floorheights,5)
			table.insert(mem.params.floornames,tostring(#mem.params.floornames+1))
		elseif event.fields.remove and #mem.params.floornames > 2 then
			table.remove(mem.params.floorheights,mem.editingfloor)
			table.remove(mem.params.floornames,mem.editingfloor)
			mem.editingfloor = math.max(1,mem.editingfloor-1)
		elseif event.fields.moveup then
			local height = mem.params.floorheights[mem.editingfloor]
			local name = mem.params.floornames[mem.editingfloor]
			table.remove(mem.params.floorheights,mem.editingfloor)
			table.remove(mem.params.floornames,mem.editingfloor)
			table.insert(mem.params.floorheights,mem.editingfloor+1,height)
			table.insert(mem.params.floornames,mem.editingfloor+1,name)
			mem.editingfloor = mem.editingfloor + 1
		elseif event.fields.movedown then
			local height = mem.params.floorheights[mem.editingfloor]
			local name = mem.params.floornames[mem.editingfloor]
			table.remove(mem.params.floorheights,mem.editingfloor)
			table.remove(mem.params.floornames,mem.editingfloor)
			table.insert(mem.params.floorheights,mem.editingfloor-1,height)
			table.insert(mem.params.floornames,mem.editingfloor-1,name)
			mem.editingfloor = mem.editingfloor - 1
		end
	elseif mem.screenstate == "oobe_floortable_edit" or mem.screenstate == "floortable_edit" then
		if event.fields.back or event.fields.save then
			mem.screenstate = (mem.screenstate == "oobe_floortable_edit" and "oobe_floortable" or "floortable")
			local height = tonumber(event.fields.height)
			if height then
				height = math.floor(height+0.5)
				mem.params.floorheights[mem.editingfloor] = math.max(1,height)
			end
			mem.params.floornames[mem.editingfloor] = string.sub(event.fields.name,1,256)
		end
	elseif mem.screenstate == "parameters" then
		if event.fields.save then
			mem.screenstate = "status"
			local doortimer = tonumber(event.fields.doortimer)
			if doortimer and doortimer > 0 and doortimer <= 30 then
				mem.params.doortimer = doortimer
			end
			local contractspeed = tonumber(event.fields.contractspeed)
			if contractspeed and contractspeed >= 0.1 and contractspeed <= 20 then
				mem.params.contractspeed = contractspeed
			end
			local nudgetimer = tonumber(event.fields.nudgetimer)
			if nudgetimer and nudgetimer >= 0 and nudgetimer <= 3600 then
				mem.params.nudgetimer = nudgetimer
			end
			local mainlanding = tonumber(event.fields.mainlanding)
			if mainlanding and mainlanding >= 1 and mainlanding <= #mem.params.floorheights then
				mem.params.mainlanding = math.floor(mainlanding)
				mem.params.carcallsecurity[math.floor(mainlanding)] = nil
			end
			local altrecalllanding = tonumber(event.fields.altrecalllanding)
			if altrecalllanding and altrecalllanding >= 1 and altrecalllanding <= #mem.params.floorheights then
				mem.params.altrecalllanding = math.floor(altrecalllanding)
			end
			local inspectionspeed = tonumber(event.fields.inspectionspeed)
			if inspectionspeed and inspectionspeed >= 0.1 and inspectionspeed < 0.75 and inspectionspeed <= mem.params.contractspeed then
				mem.params.inspectionspeed = inspectionspeed
			end
		elseif event.fields.floortable then
			mem.screenstate = "floortable"
		elseif event.fields.cancel then
			mem.screenstate = "status"
		elseif event.fields.resetdoors then
			mem.screenstate = "status"
			if mem.doorstate ~= "closed" then close() end
		elseif event.fields.resetcontroller then
			mem.screenstate = "status"
			mem.carstate = "bfdemand"
			if mem.doorstate == "closed" then
				drivecmd({
					command = "setmaxvel",
					maxvel = mem.params.contractspeed,
				})
				drivecmd({command = "resetpos"})
				interrupt(0.1,"checkdrive")
				mem.carmotion = true
				juststarted = true
			else
				close()
			end
		elseif event.fields.carcallsecurity then
			mem.screenstate = "carcallsecurity"
		end
	elseif mem.screenstate == "status" then
		for i=1,#mem.params.floornames,1 do
			if event.fields[string.format("carcall%d",i)]
			   and (mem.carstate == "normal"
			   or mem.carstate == "test"
			   or mem.carstate == "capture"
			   or mem.carstate == "indep"
			   or mem.carstate == "swing")
			then
				mem.carcalls[i] = true
			elseif event.fields[string.format("upcall%d",i)] and (mem.carstate == "normal" or mem.carstate == "swing") and not mem.capturesw then
				if mem.params.groupmode == "group" then
					mem.swingupcalls[i] = true
				else
					mem.upcalls[i] = true
				end
			elseif event.fields[string.format("downcall%d",i)] and (mem.carstate == "normal" or mem.carstate == "swing") and not mem.capturesw then
				if mem.params.groupmode == "group" then
					mem.swingdncalls[i] = true
				else
					mem.dncalls[i] = true
				end
			end
		end
		if event.fields.scrollup then
			mem.screenpage = mem.screenpage + 1
			mem.scrollfollowscar = false
		elseif event.fields.scrolldown then
			mem.screenpage = mem.screenpage - 1
			mem.scrollfollowscar = false
		elseif event.fields.scrollfollowscar then
			mem.scrollfollowscar = (event.fields.scrollfollowscar == "true")
		elseif event.fields.stopsw then
			mem.controllerstopsw = not mem.controllerstopsw
		elseif event.fields.inspectsw then
			mem.controllerinspectsw = not mem.controllerinspectsw
		elseif event.fields.capturesw then
			mem.capturesw = not mem.capturesw
		elseif event.fields.testsw then
			mem.testsw = not mem.testsw
		elseif event.fields.inspectup and mem.carstate == "mrinspect" and mem.doorstate == "closed" and getpos() < #mem.params.floornames then
			mem.carmotion = true
			juststarted = true
			drivecmd({
				command = "setmaxvel",
				maxvel = mem.params.inspectionspeed,
			})
			drivecmd({
				command = "moveto",
				pos = math.floor(mem.drive.status.apos)+1,
				inspection = true,
			})
		elseif event.fields.inspectdown and mem.carstate == "mrinspect" and mem.doorstate == "closed" and mem.drive.status.apos-1 >= 0 then
			mem.carmotion = true
			juststarted = true
			drivecmd({
				command = "setmaxvel",
				maxvel = mem.params.inspectionspeed,
			})
			drivecmd({
				command = "moveto",
				pos = math.floor(mem.drive.status.apos)-1,
				inspection = true,
			})
		elseif event.fields.parameters then
			mem.screenstate = "parameters"
		elseif event.fields.faults then
			mem.screenstate = "faults"
		end
	elseif mem.screenstate == "faults" then
		if event.fields.back then
			mem.screenstate = "status"
		elseif event.fields.clear then
			mem.faultlog = {}
			mem.activefaults = {}
			mem.fatalfault = false
			drivecmd({command = "resetfault"})
		end
	elseif mem.screenstate == "carcallsecurity" then
		if event.fields.indepunlock then
			mem.params.indepunlock[mem.editingfloor] = (event.fields.indepunlock == "true")
		end
		if event.fields.swingcallwhennotswing then
			mem.params.swingcallwhennotswing = (event.fields.swingcallwhennotswing == "true")
		end
		if event.fields.save then
			mem.screenstate = "parameters"
		elseif event.fields.floor then
			local exp = minetest.explode_textlist_event(event.fields.floor) or {}
			if exp.type == "CHG" then
				mem.editingfloor = #mem.params.floornames-exp.index+1
			elseif exp.type == "DCL" then
				mem.editingfloor = #mem.params.floornames-exp.index+1
				local oldmode = mem.params.carcallsecurity[mem.editingfloor]
				if oldmode == "deny" or mem.editingfloor == (mem.params.mainlanding or 1) then
					mem.params.carcallsecurity[mem.editingfloor] = nil
				elseif oldmode == "auth" then
					mem.params.carcallsecurity[mem.editingfloor] = "deny"
				elseif not oldmode then
					mem.params.carcallsecurity[mem.editingfloor] = "auth"
				end
			end
		elseif event.fields.secmode then
			if event.fields.secmode == "1" or mem.editingfloor == (mem.params.mainlanding or 1) then
				mem.params.carcallsecurity[mem.editingfloor] = nil
			elseif event.fields.secmode == "2" then
				mem.params.carcallsecurity[mem.editingfloor] = "auth"
			elseif event.fields.secmode == "3" then
				mem.params.carcallsecurity[mem.editingfloor] = "deny"
			end
		end
		if event.fields.user then
			if not mem.params.secoverrideusers[mem.editingfloor] then
				mem.params.secoverrideusers[mem.editingfloor] = {}
			end
			local exp = minetest.explode_textlist_event(event.fields.user) or {}
			if exp.type == "CHG" then
				mem.editinguser = exp.index
			elseif exp.type == "DCL" then
				mem.editinguser = exp.index
				if mem.params.secoverrideusers[mem.editingfloor][mem.editinguser] then
					table.remove(mem.params.secoverrideusers[mem.editingfloor],mem.editinguser)
					mem.editinguser = math.min(mem.editinguser,#mem.params.secoverrideusers[mem.editingfloor])
				end
			end
		end
		if event.fields.adduser then
			table.insert(mem.params.secoverrideusers[mem.editingfloor],event.fields.username)
			mem.editinguser = #mem.params.secoverrideusers[mem.editingfloor]
		elseif event.fields.deluser then
			if mem.params.secoverrideusers[mem.editingfloor][mem.editinguser] then
				table.remove(mem.params.secoverrideusers[mem.editingfloor],mem.editinguser)
				mem.editinguser = math.min(mem.editinguser,#mem.params.secoverrideusers[mem.editingfloor])
			end
		end
	end
elseif event.iid == "opened" and mem.doorstate == "opening" then
	mem.doorstate = "open"
	if (mem.carstate == "normal" or mem.carstate == "swing") then
		interrupt(mem.params.doortimer,"close")
	end
elseif event.iid == "close" and mem.doorstate == "open" then
	close()
elseif event.iid == "closed" and (mem.doorstate == "closing" or mem.doorstate == "testtiming") then
	mem.doorstate = "closed"
	if mem.carstate == "bfdemand" then
			drivecmd({
				command = "setmaxvel",
				maxvel = mem.params.contractspeed,
			})
			drivecmd({command = "resetpos"})
			interrupt(0.1,"checkdrive")
			mem.carmotion = true
			juststarted = true
	elseif mem.carstate == "resync" then
			gotofloor(getpos())
			interrupt(0.1,"checkdrive")
			mem.carmotion = true
			juststarted = true
	end
elseif event.type == "callbutton" and (mem.carstate == "normal" or mem.carstate == "swing") then
	if mem.doorstate == "closed" or mem.direction ~= event.dir or getpos() ~= event.landing then
		if mem.params.groupmode == "group" and not (mem.carstate == "normal" and not mem.params.swingcallwhennotswing) then
			if event.dir == "up" and event.landing >= 1 and event.landing < #mem.params.floornames then
				mem.swingupcalls[event.landing] = true
			elseif event.dir == "down" and event.landing > 1 and event.landing <= #mem.params.floornames then
				mem.swingdncalls[event.landing] = true
			end
		else
			if event.dir == "up" and event.landing >= 1 and event.landing < #mem.params.floornames then
				mem.upcalls[event.landing] = true
			elseif event.dir == "down" and event.landing > 1 and event.landing <= #mem.params.floornames then
				mem.dncalls[event.landing] = true
			end
		end
	elseif mem.direction == event.dir and mem.doorstate == "open" then
		interrupt(mem.params.doortimer,"close")
	elseif mem.direction == event.dir and mem.doorstate == "closing" and not mem.nudging then
		open()
	end
elseif event.iid == "checkopen" then
	if mem.drive.status.doorstate == "open" then
		interrupt(0,"opened")
		if mem.carstate == "normal"
			or mem.carstate == "indep"
			or mem.carstate == "fs1"
			or mem.carstate == "fs2"
			or mem.carstate == "fs2hold"
			or mem.carstate == "swing" then
			interrupt(nil,"opentimeout")
		end
		if (mem.carstate == "normal" or mem.carstate == "swing") and not mem.interrupts.nudge and mem.params.nudgetimer > 0 then
			interrupt(mem.params.nudgetimer,"nudge")
		end
	else
		interrupt(0.2,"checkopen")
	end
elseif event.iid == "checkclosed" then
	if mem.drive.status.doorstate == "closed" then
		interrupt(0,"closed")
		interrupt(nil,"closetimeout")
		interrupt(nil,"nudge")
		mem.nudging = false
	else
		interrupt(0.2,"checkclosed")
	end
elseif event.iid == "opentimeout" then
	fault("opentimeout",true)
elseif event.iid == "closetimeout" then
	fault("closetimeout",true)
elseif event.type == "cop" then
	local fields = event.fields
	if mem.carstate == "normal" or mem.carstate == "indep" or mem.carstate == "fs2" or mem.carstate == "swing" then
		for k,v in pairs(fields) do
			if string.sub(k,1,7) == "carcall" then
				local landing = tonumber(string.sub(k,8,-1))
				local secmode = mem.params.carcallsecurity[landing]
				local secok = true
				if mem.carstate ~= "fs2" then
					if secmode == "deny" then
						secok = false
					elseif secmode == "auth" and event.protected then
						secok = false
					end
				end
				if mem.carstate == "indep" and mem.params.indepunlock[landing] then
					secok = true
				elseif mem.params.secoverrideusers[landing] then
					for _,name in ipairs(mem.params.secoverrideusers[landing]) do
						if name == event.player then
							secok = true
						end
					end
				end
				if v and landing and landing >= 1 and landing <= #mem.params.floorheights and secok then
					if getpos() == landing then
						if mem.carstate == "normal" or mem.carstate == "indep" or mem.carstate == "swing" then
							if mem.doorstate == "closing" and not mem.nudging then
								open()
							elseif mem.doorstate == "open" then
								interrupt(mem.params.doortimer,"close")
							elseif mem.doorstate == "closed" then
								mem.carcalls[landing] = true
							end
						end
					else
						mem.carcalls[landing] = true
					end
				end
			end
		end
		if fields.close and mem.doorstate == "open" then
			interrupt(0,"close")
		elseif fields.open and (mem.doorstate == "closed" or mem.doorstate == "closing") and not (mem.carmotion or juststarted) then
			open()
		elseif fields.callcancel and (mem.carstate == "indep" or mem.carstate == "fs2") then
			mem.carcalls = {}
		end
	end
elseif event.type == "copswitches" then
	local fields = event.fields
	if fields.fanon then
		mem.fansw = true
	elseif fields.fanoff then
		mem.fansw = false
	elseif fields.lighton then
		mem.lightsw = true
	elseif fields.lightoff then
		mem.lightsw = false
	elseif fields.indon then
		mem.indsw = true
	elseif fields.indoff then
		mem.indsw = false
	elseif fields.fs2on then
		mem.fs2sw = "on"
	elseif fields.fs2hold then
		mem.fs2sw = "hold"
	elseif fields.fs2off then
		mem.fs2sw = "off"
	end
elseif event.type == "fs1switch" then
	if event.state and not mem.fs1led then
		if event.mode == "alternate" then
			mem.recallto = mem.params.altrecalllanding
		else
			mem.recallto = mem.params.mainlanding or 1
		end
	end
	mem.fs1switch = event.state
	mem.fs1led = event.state
	if not event.state then mem.flashfirehat = false end
elseif event.type == "cartopbox" then
	if event.control == "inspectswitch" then
		mem.cartopinspectsw = not mem.cartopinspectsw
	elseif event.control == "up" and mem.carstate == "carinspect" and mem.doorstate == "closed" and getpos() < #mem.params.floornames then
		mem.carmotion = true
		juststarted = true
		drivecmd({
			command = "setmaxvel",
			maxvel = mem.params.inspectionspeed,
		})
		drivecmd({
			command = "moveto",
			pos = gettarget(#mem.params.floornames),
			inspection = true,
		})
	elseif event.control == "down" and mem.carstate == "carinspect" and mem.doorstate == "closed" and mem.drive.status.apos-1 >= 0 then
		mem.carmotion = true
		juststarted = true
		drivecmd({
			command = "setmaxvel",
			maxvel = mem.params.inspectionspeed,
		})
		drivecmd({
			command = "moveto",
			pos = 0,
			inspection = true,
		})
	elseif event.control == "up_release" and mem.carstate == "carinspect" and mem.drive.status.vel > 0 then
		drivecmd({
			command = "moveto",
			pos = math.ceil(mem.drive.status.apos),
			inspection = true,
		})
	elseif event.control == "down_release" and mem.carstate == "carinspect" and mem.drive.status.vel < 0 then
		drivecmd({
			command = "moveto",
			pos = math.floor(mem.drive.status.apos),
			inspection = true,
		})
	end
elseif event.type == "dispatchermsg" then
	local swingstateok = false
	if mem.carstate == "normal" then
		swingstateok = mem.params.swingcallwhennotswing
	elseif mem.carstate == "swing" then
		swingstateok = true
	end
	if event.channel == "pairrequest" and mem.screenstate == "oobe_dispatcherconnect" then
		mem.params.floornames = event.msg.floornames
		mem.params.floorheights = event.msg.floorheights
		mem.activefaults = {}
		mem.faultlog = {}
		mem.fatalfault = false
		mem.state = "configured"
		mem.screenstate = "status"
		mem.screenpage = 1
		mem.carstate = "bfdemand"
		if mem.doorstate == "closed" then
			drivecmd({
				command = "setmaxvel",
				maxvel = mem.params.contractspeed,
			})
			drivecmd({command = "resetpos"})
			interrupt(0.1,"checkdrive")
			mem.carmotion = true
			juststarted = true
		else
			close()
		end
		send(event.source,"pairok",mem)
	elseif event.channel == "newfloortable" then
		mem.params.floornames = event.msg.floornames
		mem.params.floorheights = event.msg.floorheights
		mem.carstate = "bfdemand"
		if mem.doorstate == "closed" then
			drivecmd({
				command = "setmaxvel",
				maxvel = mem.params.contractspeed,
			})
			drivecmd({command = "resetpos"})
			interrupt(0.1,"checkdrive")
			mem.carmotion = true
			juststarted = true
		else
			close()
		end
	elseif event.channel == "getstatus" then
		send(event.source,"status",mem)
	elseif event.channel == "groupupcall" and mem.carstate == "normal" then
		mem.groupupcalls[event.msg] = true
	elseif event.channel == "groupdncall" and mem.carstate == "normal" then
		mem.groupdncalls[event.msg] = true
	elseif event.channel == "groupupcancel" then
		mem.groupupcalls[event.msg] = nil
	elseif event.channel == "groupdncancel" then
		mem.groupdncalls[event.msg] = nil
	elseif event.channel == "swingupcall" and swingstateok then
		mem.swingupcalls[event.msg] = true
	elseif event.channel == "swingdncall" and swingstateok then
		mem.swingdncalls[event.msg] = true
	elseif event.channel == "carcall" and (mem.carstate == "normal" or mem.carstate == "swing") then
		mem.carcalls[event.msg] = true
		send(event.source,"status",mem)
	elseif event.channel == "fs1switch" then
		if event.msg and not mem.fs1led then
			mem.recallto = mem.params.mainlanding or 1
		end
		mem.fs1switch = event.msg
		mem.fs1led = event.msg
		if not event.msg then mem.flashfirehat = false end
	end
elseif event.type == "remotemsg" then
	local swingstateok = false
	if mem.carstate == "normal" then
		swingstateok = mem.params.swingcallwhennotswing
	elseif mem.carstate == "swing" then
		swingstateok = true
	end
	if event.channel == "groupupcall" and mem.carstate == "normal" then
		mem.groupupcalls[event.msg] = true
	elseif event.channel == "groupdncall" and mem.carstate == "normal" then
		mem.groupdncalls[event.msg] = true
	elseif event.channel == "swingupcall" and swingstateok then
		mem.swingupcalls[event.msg] = true
	elseif event.channel == "swingdncall" and swingstateok then
		mem.swingdncalls[event.msg] = true
	elseif event.channel == "upcall" and (mem.carstate == "normal" or mem.carstate == "swing") then
		mem.upcalls[event.msg] = true
	elseif event.channel == "dncall" and (mem.carstate == "normal" or mem.carstate == "swing") then
		mem.dncalls[event.msg] = true
	elseif event.channel == "groupupcancel" then
		mem.groupupcalls[event.msg] = nil
	elseif event.channel == "groupdncancel" then
		mem.groupdncalls[event.msg] = nil
	elseif event.channel == "carcall" and (mem.carstate == "normal" or mem.carstate == "swing") then
		mem.carcalls[event.msg] = true
	elseif event.channel == "security" and type(event.msg.floor) == "number" then
		if mem.params.floornames[event.msg.floor] and event.msg.floor ~= (mem.params.mainlanding or 1) then
			mem.params.carcallsecurity[event.msg.floor] = event.msg.mode
		end
	elseif event.channel == "swing" then
		mem.swing = event.msg
		if mem.carstate == "normal" and event.msg then
			mem.carstate = "swing"
		elseif mem.carstate == "swing" and not event.msg then
			mem.carstate = "normal"
		end
	end
elseif event.type == "lightcurtain" and not mem.nudging then
	if mem.carstate == "normal" or mem.carstate == "indep" or mem.carstate == "swing" then
		if mem.doorstate == "closing" then
			open()
		elseif mem.doorstate == "open" and (mem.carstate == "normal" or mem.carstate == "swing") then
			interrupt(mem.params.doortimer,"close")
		end
	end
elseif event.iid == "nudge" and (mem.carstate == "normal" or mem.carstate == "swing") then
	mem.nudging = true
	if mem.doorstate == "open" then
		close(true)
	elseif mem.doorstate == "opening" then
		interrupt(1,"nudge")
	end
elseif event.type == "mrsmoke" then
	mem.flashfirehat = true
	if not mem.fs1led then
		mem.fs1switch = true
		mem.fs1led = true
		mem.recallto = nil
		if mem.drive.status.vel > 0 then
			for i=getpos(),#mem.params.floornames,1 do
				if mem.drive.status.neareststop < gettarget(i) then
					mem.recallto = i
					break
				end
			end
		elseif mem.drive.status.vel < 0 then
			for i=#mem.params.floornames,1,-1 do
				if mem.drive.status.neareststop < gettarget(i) then
					mem.recallto = i
					break
				end
			end
		end
		if not mem.recallto then mem.recallto = getpos() end
	end
end

local oldstate = mem.carstate

if mem.fatalfault then
	mem.carstate = "fault"
	drivecmd({command="estop"})
	mem.carcalls = {}
	mem.upcalls = {}
	mem.dncalls = {}
	mem.swingupcalls = {}
	mem.swingdncalls = {}
	mem.groupupcalls = {}
	mem.groupdncalls = {}
	mem.direction = nil
	interrupt(nil,"opentimeout")
	interrupt(nil,"closetimeout")
elseif mem.controllerstopsw or mem.screenstate == "floortable" or mem.screenstate == "floortable_edit" then
	mem.carstate = "stop"
	drivecmd({command="estop"})
	mem.carcalls = {}
	mem.upcalls = {}
	mem.dncalls = {}
	mem.swingupcalls = {}
	mem.swingdncalls = {}
	mem.groupupcalls = {}
	mem.groupdncalls = {}
	mem.direction = nil
	interrupt(nil,"opentimeout")
	interrupt(nil,"closetimeout")
elseif mem.controllerinspectsw and not mem.cartopinspectsw then
	mem.carstate = "mrinspect"
	mem.carcalls = {}
	mem.upcalls = {}
	mem.dncalls = {}
	mem.swingupcalls = {}
	mem.swingdncalls = {}
	mem.groupupcalls = {}
	mem.groupdncalls = {}
	mem.direction = nil
	interrupt(nil,"opentimeout")
	interrupt(nil,"closetimeout")
	if oldstate ~= "mrinspect" then drivecmd({command="estop"}) end
elseif mem.cartopinspectsw then
	mem.carstate = "carinspect"
	mem.carcalls = {}
	mem.upcalls = {}
	mem.dncalls = {}
	mem.swingupcalls = {}
	mem.swingdncalls = {}
	mem.groupupcalls = {}
	mem.groupdncalls = {}
	mem.direction = nil
	interrupt(nil,"opentimeout")
	interrupt(nil,"closetimeout")
	if oldstate ~= "carinspect" then drivecmd({command="estop"}) end
elseif mem.fs2sw == "on" then
	mem.carstate = "fs2"
	mem.upcalls = {}
	mem.dncalls = {}
	mem.swingupcalls = {}
	mem.swingdncalls = {}
	mem.groupupcalls = {}
	mem.groupdncalls = {}
	if oldstate ~= "fs2" then mem.carcalls = {} end
	if mem.doorstate == "open" and oldstate ~= "fs2" then interrupt(nil,"close") end
elseif mem.fs2sw == "hold" then
	mem.carstate = "fs2hold"
	mem.upcalls = {}
	mem.dncalls = {}
	mem.carcalls = {}
	mem.swingupcalls = {}
	mem.swingdncalls = {}
	mem.groupupcalls = {}
	mem.groupdncalls = {}
	if mem.doorstate == "open" then interrupt(nil,"close") end
elseif mem.fs1switch then
	mem.carstate = "fs1"
	mem.carcalls = {}
	mem.upcalls = {}
	mem.dncalls = {}
	mem.swingupcalls = {}
	mem.swingdncalls = {}
	mem.groupupcalls = {}
	mem.groupdncalls = {}
	interrupt(nil,"close")
	if mem.drive.status.vel > 0 and mem.drive.status.apos > gettarget(mem.recallto) then
		for i=getpos(),#mem.params.floornames,1 do
			if mem.drive.status.neareststop < gettarget(i) and mem.drive.status.dpos > gettarget(i) then
				gotofloor(i)
				break
			end
		end
	elseif mem.drive.status.vel < 0 and mem.drive.status.apos < gettarget(mem.recallto) then
		for i=getpos(),1,-1 do
			if mem.drive.status.neareststop > gettarget(i) and mem.drive.status.dpos < gettarget(i) then
				gotofloor(i)
				break
			end
		end
	elseif mem.drive.status.vel < 0 and mem.drive.status.dpos < gettarget(mem.recallto) and mem.drive.status.apos > gettarget(mem.recallto) then
		for i=mem.recallto,1,-1 do
			if mem.drive.status.neareststop > gettarget(i) and mem.drive.status.dpos < gettarget(i) then
				gotofloor(i)
				break
			end
		end
	elseif mem.drive.status.vel > 0 and mem.drive.status.dpos > gettarget(mem.recallto) and mem.drive.status.apos < gettarget(mem.recallto) then
		for i=mem.recallto,#mem.params.floornames,1 do
			if mem.drive.status.neareststop < gettarget(i) and mem.drive.status.dpos > gettarget(i) then
				gotofloor(i)
				break
			end
		end
	elseif getpos() ~= mem.recallto then
		if not (mem.carmotion or juststarted) then
			if mem.doorstate == "closed" then
				gotofloor(mem.recallto)
			elseif mem.doorstate == "open" then
				close()
			end
		end
	elseif mem.doorstate == "closed" or mem.doorstate == "closing" then
		if not (mem.carmotion or juststarted) then
			open()
		end
	end
elseif mem.indsw then
	if mem.carstate ~= "resync" then mem.carstate = "indep" end
	mem.upcalls = {}
	mem.dncalls = {}
	mem.swingupcalls = {}
	mem.swingdncalls = {}
	mem.groupupcalls = {}
	mem.groupdncalls = {}
	if oldstate == "stop" or oldstate == "mrinspect" or oldstate == "fault" then
		mem.carstate = "resync"
		gotofloor(getpos())
	elseif (oldstate == "normal" or oldstate == "swing") and (mem.doorstate == "closed" or mem.doorstate == "closing") and not (mem.carmotion or juststarted) then
		open()
	elseif (oldstate == "normal" or oldstate == "swing") and mem.doorstate == "open" then
		interrupt(nil,"close")
	end
elseif mem.testsw then
	mem.upcalls = {}
	mem.dncalls = {}
	mem.swingupcalls = {}
	mem.swingdncalls = {}
	mem.groupupcalls = {}
	mem.groupdncalls = {}
	if mem.carstate ~= "resync" then mem.carstate = "test" end
	if oldstate == "stop" or oldstate == "mrinspect" or oldstate == "carinspect" or oldstate == "fault" then
		mem.carstate = "resync"
		gotofloor(getpos())
	end
elseif mem.capturesw then
	mem.upcalls = {}
	mem.dncalls = {}
	mem.swingupcalls = {}
	mem.swingdncalls = {}
	mem.groupupcalls = {}
	mem.groupdncalls = {}
	if oldstate == "stop" or oldstate == "mrinspect" or oldstate == "carinspect" or oldstate == "fault" then
		mem.carstate = "resync"
		gotofloor(getpos())
	elseif mem.carstate ~= "resync" and not mem.direction then
		mem.carstate = "capture"
	end
else
	if oldstate == "stop" or oldstate == "mrinspect" or oldstate == "carinspect" or oldstate == "fault" then
		mem.carstate = "resync"
		gotofloor(getpos())
	elseif oldstate == "test" or oldstate == "capture" or oldstate == "fs1" or oldstate == "fs2" or oldstate == "fs2hold" then
		if (oldstate == "fs1" or oldstate == "fs2" or oldstate == "fs2hold") and mem.doorstate == "open" then
			interrupt(mem.params.doortimer,"close")
		end
		mem.carstate = (mem.swing and "swing" or "normal")
	elseif oldstate == "indep" then
		mem.carstate = (mem.swing and "swing" or "normal")
		if mem.doorstate == "open" then interrupt(mem.params.doortimer,"close") end
	end
end

if (mem.carstate == "normal" or mem.carstate == "swing")
	and oldstate ~= "normal" and oldstate ~= "swing"
	and mem.doorstate ~= "closed"
	and mem.params.nudgetimer > 0
	and not mem.interrupts.nudge then
	interrupt(mem.params.nudgetimer,"nudge")
elseif mem.carstate ~= "normal" and oldstate == "normal" then
	interrupt(nil,"nudge")
end

if mem.carmotion then
	mem.carmotion = (mem.drive.status.vel ~= 0) or juststarted
	if mem.carmotion then
		interrupt(0.1,"checkdrive")
	else
		local hallcall = mem.upcalls[getpos()] or mem.dncalls[getpos()]
		if mem.carstate == "normal" or mem.carstate == "indep" or mem.carstate == "fs1" or mem.carstate == "fs2" or mem.carstate == "swing" then
			mem.carcalls[getpos()] = nil
			if mem.direction == "up" then
				mem.upcalls[getpos()] = nil
				mem.swingupcalls[getpos()] = nil
				mem.groupupcalls[getpos()] = nil
				if (not hallcall) and (not getnextcallabove()) and getnextcallbelow() then
					mem.direction = "down"
				elseif (not hallcall) and mem.dncalls[getpos()] and (not mem.upcalls[getpos()]) and (not getnextcallabove(nil,true)) then
					mem.direction = "down"
					mem.dncalls[getpos()] = nil
					mem.swingdncalls[getpos()] = nil
					mem.groupdncalls[getpos()] = nil
				end
			elseif mem.direction == "down" then
				mem.dncalls[getpos()] = nil
				mem.swingdncalls[getpos()] = nil
				mem.groupdncalls[getpos()] = nil
				if (not hallcall) and (not getnextcallbelow()) and getnextcallabove() then
					mem.direction = "up"
				elseif (not hallcall) and mem.upcalls[getpos()] and (not mem.dncalls[getpos()]) and (not getnextcallbelow(nil,true)) then
					mem.direction = "up"
					mem.upcalls[getpos()] = nil
					mem.swingupcalls[getpos()] = nil
					mem.groupupcalls[getpos()] = nil
				end
			end
			if getpos() >= #mem.params.floornames then
				mem.direction = "down"
				mem.dncalls[#mem.params.floornames] = nil
				mem.swingdncalls[#mem.params.floornames] = nil
				mem.groupdncalls[#mem.params.floornames] = nil
			elseif getpos() <= 1 then
				mem.direction = "up"
				mem.upcalls[1] = nil
				mem.swingupcalls[1] = nil
				mem.groupupcalls[1] = nil
			end
			if (mem.carstate ~= "fs1" or getpos() == mem.recallto) and mem.carstate ~= "fs2" and mem.carstate ~= "fs2hold" then
				open()
				mem.nudging = false
			end
			if mem.carstate == "fs1" and getpos() ~= mem.recallto then
				gotofloor(mem.recallto)
			end
		elseif mem.carstate == "test" then
			mem.carcalls[getpos()] = nil
			mem.doorstate = "testtiming"
			interrupt(5,"closed")
			if getpos() >= #mem.params.floornames then
				mem.direction = "down"
			elseif getpos() <= 1 then
				mem.direction = "up"
			end
		elseif mem.carstate == "bfdemand" or mem.carstate == "resync" then
			if mem.indsw then
				mem.carstate = "indep"
			elseif mem.testsw then
				mem.carstate = "test"
			elseif mem.capturesw then
				mem.carstate = "capture"
			else
				mem.carstate = (mem.swing and "swing" or "normal")
			end
		end
	end
end

if mem.params.groupmode == "group" then
	mem.upcalls = table.copy(mem.groupupcalls)
	mem.dncalls = table.copy(mem.groupdncalls)
	for i in pairs(mem.swingupcalls) do
		mem.upcalls[i] = true
	end
	for i in pairs(mem.swingdncalls) do
		mem.dncalls[i] = true
	end
end

local canprocesscalls = {
	normal = true,
	capture = true,
	test = true,
	indep = true,
	fs2 = true,
	swing = true,
}

if canprocesscalls[mem.carstate] and mem.doorstate == "closed" then
	if not mem.carmotion then
		if mem.direction == "up" then
			if getnextcallabove("up") then
				mem.direction = "up"
				gotofloor(getnextcallabove("up"))
			elseif gethighestdowncall() then
				mem.direction = "down"
				gotofloor(gethighestdowncall())
			elseif getlowestupcall() then
				gotofloor(getlowestupcall())
			elseif getnextcallbelow("down") then
				mem.direction = "down"
				gotofloor(getnextcallbelow("down"))
			else
				mem.direction = nil
			end
		elseif mem.direction == "down" then
			if getnextcallbelow("down") then
				gotofloor(getnextcallbelow("down"))
			elseif getlowestupcall() then
				mem.direction = "up"
				gotofloor(getlowestupcall())
			elseif gethighestdowncall() then
				gotofloor(gethighestdowncall())
			elseif getnextcallabove("up") then
				mem.direction = "up"
				gotofloor(getnextcallabove())
			else
				mem.direction = nil
			end
		else
			if getnextcallabove("up") then
				mem.direction = "up"
				gotofloor(getnextcallabove())
			elseif getnextcallbelow("down") then
				mem.direction = "down"
				gotofloor(getnextcallbelow("down"))
			elseif getlowestupcall() then
				mem.direction = "up"
				gotofloor(getlowestupcall())
			elseif gethighestdowncall() then
				mem.direction = "down"
				gotofloor(gethighestdowncall())
			end
		end
		if (mem.carstate == "normal" or mem.carstate == "swing") and mem.capturesw and not mem.direction then
			mem.upcalls = {}
			mem.dncalls = {}
			mem.carstate = "capture"
		elseif mem.carstate == "capture" and mem.direction then
			mem.carstate = (mem.swing and "swing" or "normal")
		end
	elseif (mem.carstate == "normal" or mem.carstate == "capture" or mem.carstate == "test" or mem.carstate == "swing") and mem.carmotion then
		if mem.drive.status.vel > 0 then
			local nextup = getnextcallabove("up")
			if nextup then
				mem.direction = "up"
				local target = gettarget(nextup)
				if target < mem.drive.status.dpos and target > mem.drive.status.neareststop then
					gotofloor(nextup)
				end
			end
		elseif mem.drive.status.vel < 0 then
			local nextdown = getnextcallbelow("down")
			if nextdown then
				mem.direction = "down"
				local target = gettarget(nextdown)
				if target > mem.drive.status.dpos and target < mem.drive.status.neareststop then
					gotofloor(nextdown)
				end
			end
		end
	end
end

if mem.scrollfollowscar and mem.screenstate == "status" then
	mem.screenpage = math.floor((getpos()-1)/10)+1
end

fs("formspec_version[6]")
fs("size[16,12]")
fs("no_prepend[]")
fs("background9[0,0;16,12;celevator_fs_bg.png;true;3]")
if mem.screenstate == "oobe_welcome" then
	fs("image[6,1;4,2;celevator_logo.png]")
	fs("label[1,4;Welcome to your new MTronic XT elevator controller!]")
	fs("label[1,4.5;This setup wizard is designed to get your elevator up and running as quickly as possible.]")
	fs("label[1,5.5;Press Next to begin.]")
	fs("button[1,10;2,1;license;License Info]")
	fs("button[13,10;2,1;next;Next >]")
elseif mem.screenstate == "oobe_license" then
	local licensefile = io.open(minetest.get_modpath("celevator")..DIR_DELIM.."LICENSE")
	local license = minetest.formspec_escape(licensefile:read("*all"))
	licensefile:close()
	fs("textarea[1,1;14,8;license;This applies to the whole celevator mod\\, not just this controller:;"..license.."]")
	fs("button[7,10.5;2,1;back;OK]")
elseif mem.screenstate == "oobe_groupmode" then
	fs("button[1,10;2,1;back;< Back]")
	fs("label[1,1;Select a group operation mode:]")
	fs("button[1,3;2,1;simplex;Simplex]")
	fs("label[1,4.5;This will be the only elevator in the group. Hall calls will be handled by this controller.]")
	fs("button[1,6;2,1;group;Group]")
	fs("label[1,7.5;This elevator will participate in a group with others. Hall calls will be handled by a dispatcher.]")
elseif mem.screenstate == "oobe_dispatcherconnect" then
	fs("button[1,10;2,1;back;< Cancel]")
	fs("label[1,1;Waiting for connection from dispatcher...]")
	fs(string.format("label[1,1.5;This controller's car ID is: %d]",mem.carid))
elseif mem.screenstate == "oobe_floortable" or mem.screenstate == "floortable" then
	if mem.screenstate == "oobe_floortable" then
		fs("label[1,1;Enter details of all floors this elevator will serve, then press Done.]")
		fs("button[1,10;2,1;back;< Back]")
		fs("button[13,10;2,1;next;Done >]")
	else
		fs("label[1,1;EDIT FLOOR TABLE]")
		fs("button[1,10;2,1;next;Done]")
	end
	fs("textlist[1,2;6,7;floor;")
	for i=#mem.params.floornames,1,-1 do
		fs(minetest.formspec_escape(string.format("%d - Height: %d - PI: %s",i,mem.params.floorheights[i],mem.params.floornames[i]))..(i==1 and "" or ","))
	end
	fs(";"..tostring(#mem.params.floornames-mem.editingfloor+1)..";false]")
	if #mem.params.floornames < 100 then fs("button[8,2;2,1;add;New Floor]") end
	fs("button[8,3.5;2,1;edit;Edit Floor]")
	if #mem.params.floornames > 2 then fs("button[8,5;2,1;remove;Remove Floor]") end
	if mem.editingfloor < #mem.params.floornames then fs("button[8,6.5;2,1;moveup;Move Up]") end
	if mem.editingfloor > 1 then fs("button[8,8;2,1;movedown;Move Down") end
elseif mem.screenstate == "oobe_floortable_edit" or mem.screenstate == "floortable_edit" then
	if mem.screenstate == "oobe_floortable_edit" then
		fs("button[7,10.5;2,1;back;OK]")
		fs("label[1,5;The Floor Height is the distance (in meters/nodes) from the floor level of this floor to the floor level of the next floor.]")
		fs("label[1,5.5;(not used at the highest floor)]")
		fs("label[1,6.5;The Floor Name is how the floor will be displayed on the position indicators.]")
	else
		fs("button[7,10.5;2,1;save;Save]")
	end
	fs("label[1,1;Editing floor "..tostring(mem.editingfloor).."]")
	fs("field[1,3;3,1;height;Floor Height;"..tostring(mem.params.floorheights[mem.editingfloor]).."]")
	fs("field[5,3;3,1;name;Floor Name;"..minetest.formspec_escape(mem.params.floornames[mem.editingfloor]).."]")
elseif mem.screenstate == "status" then
	fs("style_type[image_button;font=mono;font_size=*0.75]")
	fs("box[12,2.5;0.1,9;#AAAAAAFF]")
	fs("box[13.12,2.5;0.05,9;#AAAAAAFF]")
	fs("box[14.12,2.5;0.05,9;#AAAAAAFF]")
	fs("box[15.25,2.5;0.1,9;#AAAAAAFF]")
	fs("label[12.5,2;UP]")
	fs("label[13.38,2;CAR]")
	fs("label[14.25,2;DOWN]")
	local maxfloor = #mem.params.floornames
	local bottom = (mem.screenpage-1)*10+1
	for i=0,9,1 do
		local ypos = 11-(i*0.9)
		local floornum = bottom+i
		if floornum > maxfloor then break end
		fs(string.format("label[11.25,%f;%s]",ypos,minetest.formspec_escape(mem.params.floornames[floornum])))
		local ccdot = mem.carcalls[floornum] and "*" or ""
		if getpos() == floornum then
			local cargraphics = {
				open = "\\[   \\]",
				opening = "\\[< >\\]",
				closing = "\\[> <\\]",
				closed = "\\[ | \\]",
				testtiming = "\\[ | \\]",
			}
			ccdot = cargraphics[mem.doorstate]
			if mem.direction == "up" then
				ccdot = minetest.colorize("#55FF55",ccdot)
			elseif mem.direction == "down" then
				ccdot = minetest.colorize("#FF5555",ccdot)
			end
		end
		fs(string.format("image_button[13.25,%f;0.75,0.75;celevator_fs_bg.png;carcall%d;%s]",ypos-0.25,floornum,ccdot))
		if floornum < maxfloor then
			local arrow = mem.upcalls[floornum] and minetest.colorize("#55FF55","^") or ""
			if mem.params.groupmode == "group" then
				arrow = mem.groupupcalls[floornum] and minetest.colorize("#55FF55","^") or ""
				arrow = (mem.swingupcalls[floornum] and minetest.colorize("#FFFF55","^") or "")..arrow
			end
			fs(string.format("image_button[12.25,%f;0.75,0.75;celevator_fs_bg.png;upcall%d;%s]",ypos-0.25,floornum,arrow))
		end
		if floornum > 1 then
			local arrow = mem.dncalls[floornum] and minetest.colorize("#FF5555","v") or ""
			if mem.params.groupmode == "group" then
				arrow = mem.swingdncalls[floornum] and minetest.colorize("#FFFF55","v") or ""
				arrow = (mem.groupdncalls[floornum] and minetest.colorize("#FF5555","v") or "")..arrow
			end
			fs(string.format("image_button[14.25,%f;0.75,0.75;celevator_fs_bg.png;downcall%d;%s]",ypos-0.25,floornum,arrow))
		end
	end
	if maxfloor > 10 then
		fs(string.format("checkbox[13,1.25;scrollfollowscar;Follow Car;%s]",tostring(mem.scrollfollowscar)))
		if bottom+9 < maxfloor then
			fs("image_button[12.75,0.25;0.75,0.75;celevator_menu_arrow.png;scrollup;;false;false;celevator_menu_arrow.png]")
		end
		if bottom > 1 then
			fs("image_button[13.87,0.25;0.75,0.75;celevator_menu_arrow.png^\\[transformFY;scrolldown;;false;false;celevator_menu_arrow.png^\\[transformFY]")
		end
	end
	fs("label[1,1;CAR STATUS]")
	fs(string.format("label[1,2;%s]",modenames[mem.carstate]))
	fs(string.format("label[1,2.5;Doors %s]",doorstates[mem.doorstate]))
	local currentfloor = minetest.formspec_escape(mem.params.floornames[getpos()])
	fs(string.format("label[1,3;Position: %0.02fm Speed: %+0.02fm/s PI: %s]",mem.drive.status.apos,mem.drive.status.vel,currentfloor))
	if #mem.faultlog > 0 then
		fs("label[1,3.5;Fault(s) Active]")
	else
		fs("label[1,3.5;No Current Faults]")
	end
	fs("button[1,10;3,1;faults;Fault History]")
	fs("button[4.5,10;3,1;parameters;Edit Parameters]")
	local redon = "celevator_led_red_on.png"
	local redoff = "celevator_led_red_off.png"
	local yellowon = "celevator_led_yellow_on.png"
	local yellowoff = "celevator_led_yellow_off.png"
	local greenon = "celevator_led_green_on.png"
	local greenoff = "celevator_led_green_off.png"
	fs(string.format("image[7,1;0.7,0.7;%s]",mem.carstate == "fault" and redon or redoff))
	fs("label[8,1.35;FAULT]")
	local inspectionstates = {
		mrinspect = true,
		carinspect = true,
		inspconflict = true,
	}
	fs(string.format("image[7,1.9;0.7,0.7;%s]",inspectionstates[mem.carstate] and yellowon or yellowoff))
	fs("label[8,2.25;INSP/ACCESS]")
	fs(string.format("image[7,2.8;0.7,0.7;%s]",mem.carstate == "normal" and greenon or greenoff))
	fs("label[8,3.15;NORMAL OPERATION]")
	fs(string.format("image[7,3.7;0.7,0.7;%s]",mem.drive.status.vel > 0.01 and yellowon or yellowoff))
	fs("label[8,4.05;UP]")
	fs(string.format("image[7,4.6;0.7,0.7;%s]",math.abs(mem.drive.status.vel) > 0.01 and yellowon or yellowoff))
	fs("label[8,4.95;DRIVE CMD]")
	fs(string.format("image[7,5.5;0.7,0.7;%s]",mem.drive.status.vel < -0.01 and yellowon or yellowoff))
	fs("label[8,5.85;DOWN]")
	fs(string.format("image[7,6.4;0.7,0.7;%s]",math.abs(mem.drive.status.vel) > math.min(0.4,mem.params.contractspeed/2) and yellowon or yellowoff))
	fs("label[8,6.75;HIGH SPEED]")
	fs(string.format("image[7,7.3;0.7,0.7;%s]",math.abs(gettarget(getpos(true))-mem.drive.status.apos) < 0.5 and greenon or greenoff))
	fs("label[8,7.65;DOOR ZONE]")
	fs(string.format("image[7,8.2;0.7,0.7;%s]",mem.doorstate == "closed" and greenon or greenoff))
	fs("label[8,8.55;DOORS LOCKED]")
	fs("style[*;font=mono]")
	local stopswimg = "celevator_toggle_switch.png"..(mem.controllerstopsw and "^\\[transformFY" or "")
	fs(string.format("image_button[1,5;1,1.33;%s;stopsw;;false;false;%s]",stopswimg,stopswimg))
	fs("label[1.3,4.75;RUN]")
	fs("label[1.2,6.6;STOP]")
	local captureswimg = "celevator_toggle_switch.png"..(mem.capturesw and "" or "^\\[transformFY")
	fs(string.format("image_button[3,5;1,1.33;%s;capturesw;;false;false;%s]",captureswimg,captureswimg))
	fs("label[3,4.75;CAPTURE]")
	local testswimg = "celevator_toggle_switch.png"..(mem.testsw and "" or "^\\[transformFY")
	fs(string.format("image_button[5,5;1,1.33;%s;testsw;;false;false;%s]",testswimg,testswimg))
	fs("label[5.23,4.75;TEST]")
	local inspectswimg = "celevator_toggle_switch.png"..(mem.controllerinspectsw and "" or "^\\[transformFY")
	fs(string.format("image_button[1,8;1,1.33;%s;inspectsw;;false;false;%s]",inspectswimg,inspectswimg))
	fs("label[1.05,7.75;INSPECT]")
	fs("label[1.1,9.6;NORMAL]")
	fs(string.format("image_button[3,8.25;1,1;%s;inspectup;;false;false;%s]","celevator_button_black.png","celevator_button_black.png"))
	fs("label[3.4,7.75;UP]")
	fs(string.format("image_button[5,8.25;1,1;%s;inspectdown;;false;false;%s]","celevator_button_black.png","celevator_button_black.png"))
	fs("label[5.25,7.75;DOWN]")
elseif mem.screenstate == "parameters" then
	fs("label[1,1;EDIT PARAMETERS]")
	fs("button[1,10;3,1;save;Save]")
	fs("button[4.5,10;3,1;cancel;Cancel]")
	if mem.params.groupmode == "simplex" then fs("button[8,10;3,1;floortable;Edit Floor Table]") end
	fs(string.format("field[1,3;3,1;doortimer;Door Dwell Timer;%0.1f]",mem.params.doortimer))
	fs(string.format("field[1,5;3,1;contractspeed;Contract Speed (m/s);%0.1f]",mem.params.contractspeed))
	fs(string.format("field[4.5,5;3,1;inspectionspeed;Inspection Speed (m/s);%0.1f]",mem.params.inspectionspeed))
	fs(string.format("field[1,7;3,1;mainlanding;Main Egress Landing;%d]",mem.params.mainlanding or 1))
	fs(string.format("field[4.5,3;3,1;nudgetimer;Nudging Timer (0 = None);%0.1f]",mem.params.nudgetimer))
	fs(string.format("field[4.5,7;3,1;altrecalllanding;Alternate Recall Landing;%d]",mem.params.altrecalllanding))
	fs("style[resetdoors,resetcontroller;bgcolor=#DD3333]")
	fs("button[12,1;3,1;resetdoors;Reset Doors]")
	fs("button[12,2.5;3,1;resetcontroller;Reset Controller]")
	fs("button[1,8.5;3,1;carcallsecurity;Car Call Security]")
elseif mem.screenstate == "faults" then
	fs("label[1,1;FAULT HISTORY]")
	if #mem.faultlog > 0 then
		for i=0,9,1 do
			if #mem.faultlog-i >= 1 then
				local currfault = mem.faultlog[#mem.faultlog-i]
				local date = os.date("*t",currfault.timestamp)
				local timestamp = string.format("%04d-%02d-%02d %02d:%02d:%02d",date.year,date.month,date.day,date.hour,date.min,date.sec)
				fs(string.format("label[1,%0.1f;%s - %s]",2+i,timestamp,faultnames[currfault.ftype]))
			end
		end
	else
		fs("label[1,2;No Current Faults]")
	end
	fs("button[1,10;3,1;back;Back]")
	fs("button[4.5,10;3,1;clear;Clear]")
elseif mem.screenstate == "carcallsecurity" then
	fs("label[1,1;CAR CALL SECURITY]")
	fs("button[1,10;3,1;save;Done]")
	fs("textlist[1,2;6,7;floor;")
	for i=#mem.params.floornames,1,-1 do
		local secmode = mem.params.carcallsecurity[i]
		if secmode == "auth" then
			secmode = "Authorized Users Only"
		elseif secmode == "deny" then
			secmode = "Locked"
		else
			secmode = "Security Disabled"
		end
		fs(minetest.formspec_escape(string.format("%s - %s",mem.params.floornames[i],secmode))..(i==1 and "" or ","))
	end
	fs(";"..tostring(#mem.params.floornames-mem.editingfloor+1)..";false]")
	fs("checkbox[1,9.5;swingcallwhennotswing;Allow Swing Calls When Not In Swing Operation;"..tostring(mem.params.swingcallwhennotswing).."]")
	if mem.editingfloor ~= (mem.params.mainlanding or 1) then
		fs("dropdown[8,2;4,1;secmode;Security Disabled,Authorized Users Only,Locked;")
		if mem.params.carcallsecurity[mem.editingfloor] == "auth" then
			fs("2;true]")
		elseif mem.params.carcallsecurity[mem.editingfloor] == "deny" then
			fs("3;true]")
		else
			fs("1;true]")
		end
		if mem.params.carcallsecurity[mem.editingfloor] then
			fs(string.format("checkbox[8,3.5;indepunlock;Unlock in Independent;%s]",(mem.params.indepunlock[mem.editingfloor] and "true" or "false")))
			fs("label[8,4.7;Extra Allowed Users]")
			if not mem.params.secoverrideusers[mem.editingfloor] then mem.params.secoverrideusers[mem.editingfloor] = {} end
			if #mem.params.secoverrideusers[mem.editingfloor] > 0 then
				fs("textlist[8,6;4,2;user;")
				for i=1,#mem.params.secoverrideusers[mem.editingfloor],1 do
					fs(minetest.formspec_escape(mem.params.secoverrideusers[mem.editingfloor][i])..(i==#mem.params.secoverrideusers[mem.editingfloor] and "" or ","))
				end
				fs(";"..tostring(mem.editinguser)..";false]")
			else
				fs("label[8,6.25;(none)]")
			end
			fs("field[8,5;3,1;username;;]")
			fs("button[11.25,5;0.5,1;adduser;+]")
			fs("button[12,5;0.5,1;deluser;-]")
		end
	else
		fs("label[8,2;Main landing cannot be locked]")
	end
end

local arrow = " "
if mem.drive.status.dpos > mem.drive.status.apos then
	arrow = "^"
elseif mem.drive.status.dpos < mem.drive.status.apos then
	arrow = "v"
end
local floorname = mem.params.floornames[getpos()]
local modename = modenames[mem.carstate]
local doorstate = doorstates[mem.doorstate]
mem.infotext = string.format("ID %d: Floor %s %s - %s - Doors %s",mem.carid,floorname,arrow,modename,doorstate)

if mem.drive.type then
	mem.showrunning = mem.drive.status.vel ~= 0
else
	mem.showrunning = false
end

local oldpifloor = mem.pifloor

mem.pifloor = mem.params.floornames[getpos(true)]
local hidepi = {
	bfdemand = true,
	uninit = true,
	stop = true,
	fault = true,
	mrinspect = true,
	carinspect = true,
	inspconflict = true,
}
if hidepi[mem.carstate] then mem.pifloor = "--" end

if mem.pifloor ~= oldpifloor and (mem.carstate == "normal" or mem.carstate == "swing") then
	drivecmd({command="pibeep"})
end

local arrowenabled = {
	normal = true,
	fs1 = true,
	fs2 = true,
	indep = true,
	capture = true,
	test = true,
	swing = true,
}
mem.piuparrow = mem.drive.status.vel > 0 and arrowenabled[mem.carstate]
mem.pidownarrow = mem.drive.status.vel < 0 and arrowenabled[mem.carstate]

mem.flash_fs = (mem.carstate == "fs1" or mem.carstate == "fs2" or mem.carstate == "fs2hold")
mem.flash_is = mem.carstate == "indep"
mem.flash_blank = mem.nudging

mem.lanterns = {}
if (mem.carstate == "normal" or mem.carstate == "swing") and (mem.doorstate == "open" or mem.doorstate == "opening") then
	mem.lanterns[getpos()] = mem.direction
elseif (mem.carstate == "normal" or mem.carstate == "swing") and mem.doorstate == "closed" and mem.drive.status then
	local ring = false
	if mem.drive.status.vel > 0 and mem.drive.status.neareststop > mem.drive.status.dpos then
		ring = true
	elseif mem.drive.status.vel < 0 and mem.drive.status.neareststop < mem.drive.status.dpos then
		ring = true
	end
	if ring then
		for i=1,#mem.params.floornames,1 do
			if gettarget(i) == mem.drive.status.dpos then
				if mem.direction == "up" and mem.upcalls[i] then
					mem.lanterns[i] = "up"
				elseif mem.direction == "down" and mem.dncalls[i] then
					mem.lanterns[i] = "down"
				end
			end
		end
	end
end

mem.copformspec = "formspec_version[7]"
local floorcount = #mem.params.floornames
local copcols = math.floor((floorcount-1)/10)+1
local coprows = math.floor((floorcount-1)/copcols)+1
local litimg = "celevator_copbutton_lit.png"
local unlitimg = "celevator_copbutton_unlit.png"
mem.copformspec = mem.copformspec..string.format("size[%f,%f]",copcols*1.25+2.5,coprows*1.25+5)
mem.copformspec = mem.copformspec.."no_prepend[]"
mem.copformspec = mem.copformspec.."background9[0,0;16,12;celevator_fs_bg.png;true;3]"
for i=1,floorcount,1 do
	local row = math.floor((i-1)/copcols)+1
	local col = ((i-1)%copcols)+1
	local yp = (coprows-row+1)*1.25+1
	local xp = col*1.25
	local tex = mem.carcalls[i] and litimg or unlitimg
	local star = (i == (mem.params.mainlanding or 1) and "*" or "")
	local label = minetest.formspec_escape(star..mem.params.floornames[i])
	mem.copformspec = mem.copformspec..string.format("image_button[%f,%f;1.2,1.2;%s;carcall%d;%s;false;false;%s]",xp,yp,tex,i,label,litimg)
end

local doxp = (copcols == 1) and 0.5 or 1.25
local openlabel = minetest.formspec_escape("<|>")
mem.copformspec = mem.copformspec..string.format("image_button[%f,%f;1.2,1.2;%s;open;%s;false;false;%s]",doxp,coprows*1.25+2.5,unlitimg,openlabel,litimg)

local dcxp = 3.75
if copcols == 1 then
	dcxp = 2
elseif copcols == 2 then
	dcxp = 2.5
end
local closelabel = minetest.formspec_escape(">|<")
mem.copformspec = mem.copformspec..string.format("image_button[%f,%f;1.2,1.2;%s;close;%s;false;false;%s]",dcxp,coprows*1.25+2.5,unlitimg,closelabel,litimg)

mem.copformspec = mem.copformspec..string.format("image_button[0.4,0.5;1.4,1.4;%s;callcancel;Call\nCancel;false;false;%s]",unlitimg,litimg)

if mem.flashfirehat then
	mem.copformspec = mem.copformspec.."animated_image[2.2,0.5;1.4,1.4;firehat;celevator_fire_hat_flashing.png;2;750]"
else
	local firehat = mem.flash_fs and "celevator_fire_hat_lit.png" or "celevator_fire_hat_unlit.png"
	mem.copformspec = mem.copformspec..string.format("image[2.2,0.5;1.4,1.4;%s]",firehat)
end

mem.switchformspec = "formspec_version[7]size[8,10]no_prepend[]background9[0,0;16,12;celevator_fs_bg.png;true;3]"
local fs2ontex = (mem.fs2sw == "on") and "celevator_button_rect_active.png" or "celevator_button_rect.png"
local fs2holdtex = (mem.fs2sw == "hold") and "celevator_button_rect_active.png" or "celevator_button_rect.png"
local fs2offtex = (mem.fs2sw == "off" or not mem.fs2sw) and "celevator_button_rect_active.png" or "celevator_button_rect.png"
mem.switchformspec = mem.switchformspec..string.format("image_button[1.5,1.5;1.5,1;%s;fs2on;ON;false;false;celevator_button_rect_active.png]",fs2ontex)
mem.switchformspec = mem.switchformspec..string.format("image_button[1.5,2.5;1.5,1;%s;fs2hold;HOLD;false;false;celevator_button_rect_active.png]",fs2holdtex)
mem.switchformspec = mem.switchformspec..string.format("image_button[1.5,3.5;1.5,1;%s;fs2off;OFF;false;false;celevator_button_rect_active.png]",fs2offtex)
mem.switchformspec = mem.switchformspec.."label[1.6,4.75;FIRE SVC]"

local indontex = mem.indsw and "celevator_button_rect_active.png" or "celevator_button_rect.png"
local indofftex = (not mem.indsw) and "celevator_button_rect_active.png" or "celevator_button_rect.png"
mem.switchformspec = mem.switchformspec..string.format("image_button[4.5,1.5;1.5,1;%s;indon;ON;false;false;celevator_button_rect_active.png]",indontex)
mem.switchformspec = mem.switchformspec..string.format("image_button[4.5,3.5;1.5,1;%s;indoff;OFF;false;false;celevator_button_rect_active.png]",indofftex)
mem.switchformspec = mem.switchformspec.."label[4.6,4.75;IND SVC]"

local lightontex = mem.lightsw and "celevator_button_rect_active.png" or "celevator_button_rect.png"
local lightofftex = (not mem.lightsw) and "celevator_button_rect_active.png" or "celevator_button_rect.png"
mem.switchformspec = mem.switchformspec..string.format("image_button[1.5,5.5;1.5,1;%s;lighton;ON;false;false;celevator_button_rect_active.png]",lightontex)
mem.switchformspec = mem.switchformspec..string.format("image_button[1.5,7.5;1.5,1;%s;lightoff;OFF;false;false;celevator_button_rect_active.png]",lightofftex)
mem.switchformspec = mem.switchformspec.."label[1.6,8.75;CAR LIGHT]"

local fanontex = mem.fansw and "celevator_button_rect_active.png" or "celevator_button_rect.png"
local fanofftex = (not mem.fansw) and "celevator_button_rect_active.png" or "celevator_button_rect.png"
mem.switchformspec = mem.switchformspec..string.format("image_button[4.5,5.5;1.5,1;%s;fanon;ON;false;false;celevator_button_rect_active.png]",fanontex)
mem.switchformspec = mem.switchformspec..string.format("image_button[4.5,7.5;1.5,1;%s;fanoff;OFF;false;false;celevator_button_rect_active.png]",fanofftex)
mem.switchformspec = mem.switchformspec.."label[4.6,8.75;CAR FAN]"

return pos,mem,changedinterrupts
