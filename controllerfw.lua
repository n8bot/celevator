local pos,event,mem = ...

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
	inspconflict = "Inspection Conflict",
	fs1 = "Fire Service - Phase 1",
	fs2 = "Fire Service - Phase 2",
	indep = "Independent Service",
	capture = "Captured",
	test = "Test Mode",
}

local doorstates = {
	open = "Open",
	opening = "Opening",
	closing = "Closing",
	closed = "Closed",
	testtiming = "Closed",
}

local faultnames = {
	drivecomm = "Lost Communication With Drive",
	driveuninit = "Drive Not Configured",
}

local function drivecmd(command)
	table.insert(mem.drive.commands,command)
end

local function interrupt(time,iid)
	mem.interrupts[iid] = time
end

local function getpos()
	local ret = 0
	for k,v in ipairs(mem.params.floorheights) do
		ret = ret+v
		if ret > mem.drive.status.apos then return k end
	end
	return mem.params.floorheights[#mem.params.floorheights]
end

local function gettarget(floor)
	local target = 0
	if floor == 1 then return 0 end
	for i=1,floor-1,1 do
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
	drivecmd({
		command = "moveto",
		pos = gettarget(floor)
	})
	interrupt(0,"checkdrive")
	juststarted = true
end

local function getnextcallabove(dir)
	for i=getpos(),#mem.params.floorheights,1 do
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

local function getnextcallbelow(dir)
	for i=getpos(),1,-1 do
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
end

local function close()
	mem.doorstate = "closing"
	drivecmd({command = "close"})
	interrupt(0.2,"checkclosed")
end

mem.formspec = ""

local function fs(element)
	mem.formspec = mem.formspec..element
end

if event.type == "program" then
	mem.carstate = "uninit"
	mem.editingfloor = 1
	mem.doorstate = "closed"
	mem.carmotion = false
	mem.carcalls = {}
	mem.upcalls = {}
	mem.dncalls = {}
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
	if not mem.params then
		mem.state = "unconfigured"
		mem.screenstate = "oobe_welcome"
		mem.params = {
			contractspeed = 1,
			floorheights = {5,5,5},
			floornames = {"1","2","3"},
			doortimer = 5,
			groupmode = "simplex",
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
		elseif event.fields.remove then
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
				mem.params.floorheights[mem.editingfloor] = math.max(0,height)
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
		elseif event.fields.floortable then
			mem.screenstate = "floortable"
		elseif event.fields.cancel then
			mem.screenstate = "status"
		end
	elseif mem.screenstate == "status" then
		for i=1,#mem.params.floornames,1 do
			if event.fields[string.format("carcall%d",i)] and (mem.carstate == "normal" or mem.carstate == "test" or mem.carstate == "capture") then
				mem.carcalls[i] = true
			elseif event.fields[string.format("upcall%d",i)] and mem.carstate == "normal" and not mem.capturesw then
				mem.upcalls[i] = true
			elseif event.fields[string.format("downcall%d",i)] and mem.carstate == "normal" and not mem.capturesw then
				mem.dncalls[i] = true
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
				maxvel = 0.2,
			})
			drivecmd({
				command = "moveto",
				pos = math.floor(mem.drive.status.apos)+1
			})
		elseif event.fields.inspectdown and mem.carstate == "mrinspect" and mem.doorstate == "closed" and mem.drive.status.apos-1 >= 0 then
			mem.carmotion = true
			juststarted = true
			drivecmd({
				command = "setmaxvel",
				maxvel = 0.2,
			})
			drivecmd({
				command = "moveto",
				pos = math.floor(mem.drive.status.apos)-1
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
		end
	end
elseif event.iid == "opened" and mem.doorstate == "opening" then
	mem.doorstate = "open"
	if mem.carstate == "normal" then
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
elseif event.type == "callbutton" and mem.carstate == "normal" then
	if event.dir == "up" and event.landing >= 1 and event.landing < #mem.params.floornames then
		mem.upcalls[event.landing] = true
	elseif event.dir == "down" and event.landing > 1 and event.landing <= #mem.params.floornames then
		mem.dncalls[event.landing] = true
	end
elseif event.iid == "checkopen" then
	if mem.drive.status.doorstate == "open" then
		interrupt(0,"opened")
	else
		interrupt(0.2,"checkopen")
	end
elseif event.iid == "checkclosed" then
	if mem.drive.status.doorstate == "closed" then
		interrupt(0,"closed")
	else
		interrupt(0.2,"checkclosed")
	end
end

local oldstate = mem.carstate

if mem.fatalfault then
	mem.carstate = "fault"
	drivecmd({command="estop"})
	mem.carcalls = {}
	mem.upcalls = {}
	mem.dncalls = {}
	mem.direction = nil
elseif mem.controllerstopsw or mem.screenstate == "floortable" or mem.screenstate == "floortable_edit" then
	mem.carstate = "stop"
	drivecmd({command="estop"})
	mem.carcalls = {}
	mem.upcalls = {}
	mem.dncalls = {}
	mem.direction = nil
elseif mem.controllerinspectsw and not mem.cartopinspectsw then
	mem.carstate = "mrinspect"
	mem.carcalls = {}
	mem.upcalls = {}
	mem.dncalls = {}
	mem.direction = nil
	if oldstate ~= "mrinspect" then drivecmd({command="estop"}) end
elseif mem.testsw then
	mem.upcalls = {}
	mem.dncalls = {}
	mem.carstate = "test"
elseif mem.capturesw then
	mem.upcalls = {}
	mem.dncalls = {}
	if not mem.direction then mem.carstate = "capture" end
else
	if oldstate == "stop" or oldstate == "mrinspect" or oldstate == "fault" then
		mem.carstate = "resync"
		gotofloor(getpos())
	elseif oldstate == "test" or oldstate == "capture" then
		mem.carstate = "normal"
	end
end

if mem.carmotion then
	mem.carmotion = (mem.drive.status.vel ~= 0) or juststarted
	if mem.carmotion then
		interrupt(0.1,"checkdrive")
	else
		if mem.carstate == "normal" then
			mem.carcalls[getpos()] = nil
			if mem.direction == "up" then
				mem.upcalls[getpos()] = nil
			elseif mem.direction == "down" then
				mem.dncalls[getpos()] = nil
			end
			if getpos() >= #mem.params.floornames then
				mem.direction = "down"
			elseif getpos() <= 1 then
				mem.direction = "up"
			end
			open()
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
			mem.carstate = "normal"
		end
	end
end

if (mem.carstate == "normal" or mem.carstate == "capture" or mem.carstate == "test") and mem.doorstate == "closed" and not mem.carmotion then
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
	if mem.carstate == "normal" and mem.capturesw and not mem.direction then
		mem.upcalls = {}
		mem.dncalls = {}
		mem.carstate = "capture"
	elseif mem.carstate == "capture" and mem.direction then
		mem.carstate = "normal"
	end
end

if mem.scrollfollowscar and mem.screenstate == "status" then
	mem.screenpage = math.floor((getpos()-1)/10)+1
end

fs("formspec_version[6]")
fs("size[16,12]")
fs("background9[0,0;16,12;celevator_fs_bg.png;true;3]")
if mem.screenstate == "oobe_welcome" then
	fs("image[6,1;4,2;celevator_logo.png]")
	fs("label[1,4;Welcome to your new MTronic XT elevator controller!]")
	fs("label[1,4.5;This setup wizard is designed to get your elevator up and running as quickly as possible.]")
	fs("label[1,5.5;Press Next to begin.]")
	fs("button[1,10;2,1;license;License Info]")
	fs("button[13,10;2,1;next;Next >]")
elseif mem.screenstate == "oobe_license" then
	local licensefile = io.open(minetest.get_modpath("celevator")..DIR_DELIM.."COPYING")
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
	fs("label[1,7.5;This elevator will participate in a group with others. Hall calls will be handled by a dispatcher. (not implemented)]")
elseif mem.screenstate == "oobe_dispatcherconnect" then
	fs("button[1,10;2,1;back;< Back]")
	fs("label[1,1;Not yet implemented. Press Back.]")
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
	fs("button[8,2;2,1;add;New Floor]")
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
		fs(string.format("label[11.25,%f;%s]",ypos,mem.params.floornames[floornum]))
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
			fs(string.format("image_button[12.25,%f;0.75,0.75;celevator_fs_bg.png;upcall%d;%s]",ypos-0.25,floornum,arrow))
		end
		if floornum > 1 then
			local arrow = mem.dncalls[floornum] and minetest.colorize("#FF5555","v") or ""
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
	fs(string.format("label[1,3;Position: %0.02fm Speed: %+0.02fm/s PI: %s]",mem.drive.status.apos,mem.drive.status.vel,minetest.formspec_escape(mem.params.floornames[getpos()])))
	if #mem.faultlog > 0 then
		fs("label[1,3.5;Fault(s) Active]")
	else
		fs("label[1,3.5;No Current Faults]")
	end
	fs("button[1,10;3,1;faults;Fault History]")
	fs("button[4.5,10;3,1;parameters;Edit Parameters]")
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
	fs("button[8,10;3,1;floortable;Edit Floor Table]")
	fs(string.format("field[1,3;3,1;doortimer;Door Dwell Timer;%0.1f]",mem.params.doortimer))
	fs(string.format("field[1,5;3,1;contractspeed;Contract Speed (m/s);%0.1f]",mem.params.contractspeed))
elseif mem.screenstate == "faults" then
	fs("label[1,1;FAULT HISTORY]")
	if #mem.faultlog > 0 then
		for i=0,9,1 do
			if #mem.faultlog-i >= 1 then
				local currfault = mem.faultlog[#mem.faultlog-i]
				local date = os.date("*t",currfault.timestamp)
				fs(string.format("label[1,%0.1f;%04d-%02d-%02d %02d:%02d:%02d - %s]",2+i,date.year,date.month,date.day,date.hour,date.min,date.sec,faultnames[currfault.ftype]))
			end
		end
	else
		fs("label[1,2;No Current Faults]")
	end
	fs("button[1,10;3,1;back;Back]")
	fs("button[4.5,10;3,1;clear;Clear]")
end

local arrow = " "
if mem.drive.status.dpos > mem.drive.status.apos then
	arrow = "^"
elseif mem.drive.status.dpos < mem.drive.status.apos then
	arrow = "v"
end
mem.infotext = string.format("Floor %s %s - %s - Doors %s",mem.params.floornames[getpos()],arrow,modenames[mem.carstate],doorstates[mem.doorstate])

if mem.drive.type then
	mem.showrunning = mem.drive.status.vel ~= 0
else
	mem.showrunning = false
end

mem.pifloor = mem.params.floornames[getpos()]
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
local arrowenabled = {
	normal = true,
	fs1 = true,
	fs2 = true,
	indep = true,
	capture = true,
	test = true,
}
mem.piuparrow = mem.drive.status.vel > 0 and arrowenabled[mem.carstate]
mem.pidownarrow = mem.drive.status.vel < 0 and arrowenabled[mem.carstate]

mem.lanterns = {}
if mem.carstate == "normal" and (mem.doorstate == "open" or mem.doorstate == "opening") then
	mem.lanterns[getpos()] = mem.direction
end

return pos,mem
