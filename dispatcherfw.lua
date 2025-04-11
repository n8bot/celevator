local pos,event,mem = ...

local changedinterrupts = {}

local function interrupt(time,iid)
	mem.interrupts[iid] = time
	changedinterrupts[iid] = true
end

mem.messages = {}
mem.kioskmessages = {}
if not mem.powerstate then mem.powerstate = "awake" end
if not mem.dbdcalls then mem.dbdcalls = {} end

local function getpos(carid)
	if not mem.params.floorsserved[carid] then return 0 end
	if not mem.carstatus[carid] then return 0 end
	local floormap = {}
	local floorheights = {}
	for i=1,#mem.params.floornames,1 do
		if mem.params.floorsserved[carid][i] then
			table.insert(floormap,i)
			table.insert(floorheights,mem.params.floorheights[i])
		elseif #floorheights > 0 then
			floorheights[#floorheights] = floorheights[#floorheights]+mem.params.floorheights[i]
		end
	end
	local ret = 0
	local searchpos = mem.carstatus[carid].position
	for k,v in ipairs(floorheights) do
		ret = ret+v
		if ret > searchpos then return floormap[k] end
	end
	return 1
end

local function getdpos(carid)
	if not mem.carstatus[carid] then return 0 end
	local floormap = {}
	local floorheights = {}
	for i=1,#mem.params.floornames,1 do
		if mem.params.floorsserved[carid][i] then
			table.insert(floormap,i)
			table.insert(floorheights,mem.params.floorheights[i])
		elseif #floorheights > 0 then
			floorheights[#floorheights] = floorheights[#floorheights]+mem.params.floorheights[i]
		end
	end
	local ret = 0
	local searchpos = mem.carstatus[carid].target
	for k,v in ipairs(floorheights) do
		ret = ret+v
		if ret > searchpos then return floormap[k] end
	end
	return 1
end

local function cartorealfloor(carid,floor)
	if type(floor) == "table" then
		local ret = {}
		for i in pairs(floor) do
			if cartorealfloor(carid,i) then
				ret[cartorealfloor(carid,i)] = true
			end
		end
		return ret
	end
	local map = {}
	for i=1,#mem.params.floornames,1 do
		if mem.params.floorsserved[carid][i] then
			table.insert(map,i)
		end
	end
	return map[floor]
end

local function realtocarfloor(carid,floor)
	if type(floor) == "table" then
		local ret = {}
		for i in pairs(floor) do
			ret[realtocarfloor(carid,i)] = true
		end
		return ret
	end
	local map = {}
	for i=1,#mem.params.floornames,1 do
		if mem.params.floorsserved[carid][i] then
			table.insert(map,i)
		end
	end
	local pmap = {}
	for k,v in pairs(map) do
		pmap[v] = k
	end
	return pmap[floor]
end

local function send(carid,channel,message)
	table.insert(mem.messages,{
		carid = carid,
		channel = channel,
		message = message,
	})
end

local function kiosksend(kioskpos,carnum)
	table.insert(mem.kioskmessages,{
		pos = kioskpos,
		type = "assigned",
		car = carnum,
	})
end

local function getnextcallabove(carid,dir,startpos,carcalls,upcalls,dncalls)
	for i=(startpos or getpos(carid)),#mem.params.floorheights,1 do
		if not dir then
			if carcalls[i] then
				return i,"car"
			elseif upcalls[i] then
				return i,"up"
			elseif dncalls[i] then
				return i,"down"
			end
		elseif dir == "up" then
			if carcalls[i] then
				return i,"car"
			elseif upcalls[i] then
				return i,"up"
			end
		elseif dir == "down" then
			if carcalls[i] then
				return i,"car"
			elseif dncalls[i] then
				return i,"down"
			end
		end
	end
end

local function getnextcallbelow(carid,dir,startpos,carcalls,upcalls,dncalls)
	for i=(startpos or getpos(carid)),1,-1 do
		if not dir then
			if carcalls[i] then
				return i,"car"
			elseif upcalls[i] then
				return i,"up"
			elseif dncalls[i] then
				return i,"down"
			end
		elseif dir == "up" then
			if carcalls[i] then
				return i,"car"
			elseif upcalls[i] then
				return i,"up"
			end
		elseif dir == "down" then
			if carcalls[i] then
				return i,"car"
			elseif dncalls[i] then
				return i,"down"
			end
		end
	end
end

local function getlowestupcall(upcalls)
	for i=1,#mem.params.floornames,1 do
		if upcalls[i] then return i end
	end
end

local function gethighestdowncall(dncalls)
	for i=#mem.params.floornames,1,-1 do
		if dncalls[i] then return i end
	end
end

local function gettarget(floor)
	local target = 0
	if floor == 1 then return 0 end
	for i=1,floor-1,1 do
		target = target+mem.params.floorheights[i]
	end
	return target
end

local function predictnextstop(carid,startpos,direction,carcalls,upcalls,dncalls,leaving)
	if leaving then
		local vel = mem.carstatus[carid].vel
		if vel > 0 then
			startpos = startpos+1
		elseif vel < 0 then
			startpos = startpos-1
		end
	end
	if direction == "up" then
		if getnextcallabove(carid,"up",startpos,carcalls,upcalls,dncalls) then
			return getnextcallabove(carid,"up",startpos,carcalls,upcalls,dncalls),"up"
		elseif gethighestdowncall(dncalls) then
			return gethighestdowncall(dncalls),"down"
		elseif getlowestupcall(upcalls) then
			return getlowestupcall(upcalls),"up"
		elseif getnextcallbelow(carid,"down",startpos,carcalls,upcalls,dncalls) then
			return getnextcallbelow(carid,"down",startpos,carcalls,upcalls,dncalls),"down"
		else
			return
		end
	elseif direction == "down" then
		if getnextcallbelow(carid,"down",startpos,carcalls,upcalls,dncalls) then
			return getnextcallbelow(carid,"down",startpos,carcalls,upcalls,dncalls),"down"
		elseif getlowestupcall(upcalls) then
			return getlowestupcall(upcalls),"up"
		elseif gethighestdowncall(dncalls) then
			return gethighestdowncall(dncalls),"down"
		elseif getnextcallabove(carid,"up",startpos,carcalls,upcalls,dncalls) then
			return getnextcallabove(carid,nil,startpos,carcalls,upcalls,dncalls),"up"
		else
			return
		end
	else
		if getnextcallabove(carid,"up",startpos,carcalls,upcalls,dncalls) then
			return getnextcallabove(carid,nil,startpos,carcalls,upcalls,dncalls),"up"
		elseif getnextcallbelow(carid,"down",startpos,carcalls,upcalls,dncalls) then
			return getnextcallbelow(carid,"down",startpos,carcalls,upcalls,dncalls),"down"
		elseif getlowestupcall(upcalls) then
			return getlowestupcall(upcalls),"up"
		elseif gethighestdowncall(dncalls) then
			return gethighestdowncall(dncalls),"down"
		end
	end
end

local function estimatetraveltime(carid,src,dest)
	local srcpos = gettarget(src)
	local dstpos = gettarget(dest)
	local estimate = math.abs(srcpos-dstpos)
	estimate = estimate/mem.carstatus[carid].contractspeed
	estimate = estimate+(mem.carstatus[carid].contractspeed*2)
	return estimate
end

local function buildstopsequence(carid,startfloor,direction,target,targetdir,leaving)
	local carcalls = cartorealfloor(carid,mem.carstatus[carid].carcalls)
	local upcalls = cartorealfloor(carid,mem.carstatus[carid].upcalls)
	local dncalls = cartorealfloor(carid,mem.carstatus[carid].dncalls)
	if targetdir == "up" then
		upcalls[target] = true
	elseif targetdir == "down" then
		dncalls[target] = true
	end
	local carpos = startfloor
	local sequence = {}
	local vel = mem.carstatus[carid].vel
	if vel > 0 then
		direction = "up"
	elseif vel < 0 then
		direction = "down"
	end
	repeat
		local src = carpos
		carpos,direction = predictnextstop(carid,carpos,direction,carcalls,upcalls,dncalls,leaving)
		carcalls[carpos] = nil
		if direction == "up" then
			upcalls[carpos] = nil
		elseif direction == "down" then
			dncalls[carpos] = nil
		end
		table.insert(sequence,{
			src = src,
			dest = carpos,
		})
	until (carpos == target and direction == targetdir) or #sequence > 100
	return sequence
end

local function calculateeta(carid,floor,direction)
	if not mem.carstatus[carid] then return 999 end
	local leaving = (getpos(carid) ~= getdpos(carid)) and (getpos(carid) == floor)
	local sequence = buildstopsequence(carid,getpos(carid),mem.carstatus[carid].direction,floor,direction,leaving)
	local doorstate = mem.carstatus[carid].doorstate
	local doortimes = {
		closed = 0,
		closing = 3,
		open = 10,
		opening = 13,
	}
	local eta = doortimes[doorstate] or 0
	for k,v in ipairs(sequence) do
		eta = eta+estimatetraveltime(carid,v.src,v.dest)
		if k < #sequence then
			eta = eta+mem.carstatus[carid].doortimer+9
		end
	end
	return eta
end

mem.formspec = ""

local function fs(element)
	mem.formspec = mem.formspec..element
end

if mem.params and #mem.params.floornames < 2 then
	mem.params.floorheights = {5,5,5}
	mem.params.floornames = {"1","2","3"}
	for _,carid in ipairs(mem.params.carids) do
		local floornames = {}
		local floorheights = {}
		for i=1,#mem.params.floornames,1 do
			if mem.params.floorsserved[carid][i] then
				table.insert(floornames,mem.params.floornames[i])
				table.insert(floorheights,mem.params.floorheights[i])
			elseif #floornames > 0 then
				floorheights[#floorheights] = floorheights[#floorheights]+mem.params.floorheights[i]
			end
		end
		send(carid,"newfloortable",{
			floornames = floornames,
			floorheights = floorheights,
		})
	end
end

if event.type == "program" then
	mem.carstatus = {}
	mem.screenstate = "oobe_welcome"
	mem.editingfloor = 1
	mem.screenpage = 1
	mem.editingconnection = 1
	mem.newconncarid = 0
	mem.upcalls = {}
	mem.dncalls = {}
	mem.assignedup = {}
	mem.assigneddn = {}
	mem.upeta = {}
	mem.dneta = {}
	mem.dbdcalls = {}
	if not mem.params then
		mem.params = {
			carids = {},
			floorheights = {5,5,5},
			floornames = {"1","2","3"},
			floorsserved = {},
		}
	end
elseif event.type == "ui" then
	local fields = event.fields
	if mem.screenstate == "oobe_welcome" then
		if fields.license then
			mem.screenstate = "oobe_license"
		elseif fields.next then
			mem.screenstate = "oobe_floortable"
		end
	elseif mem.screenstate == "oobe_license" then
		if fields.back then
			mem.screenstate = "oobe_welcome"
		end
	elseif mem.screenstate == "oobe_floortable" or mem.screenstate == "floortable" then
		local exp = event.fields.floor and minetest.explode_textlist_event(event.fields.floor) or {}
		if event.fields.back then
			mem.screenstate = "oobe_welcome"
		elseif event.fields.next then
			for _,carid in ipairs(mem.params.carids) do
				local floornames = {}
				local floorheights = {}
				for i=1,#mem.params.floornames,1 do
					if mem.params.floorsserved[carid][i] then
						table.insert(floornames,mem.params.floornames[i])
						table.insert(floorheights,mem.params.floorheights[i])
					elseif #floornames > 0 then
						floorheights[#floorheights] = floorheights[#floorheights]+mem.params.floorheights[i]
					end
				end
				send(carid,"newfloortable",{
					floornames = floornames,
					floorheights = floorheights,
				})
			end
			mem.screenstate = (mem.screenstate == "oobe_floortable" and "oobe_connections" or "menu")
			mem.screenpage = 1
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
	elseif mem.screenstate == "oobe_connections" or mem.screenstate == "connections" then
		local exp = event.fields.connection and minetest.explode_textlist_event(event.fields.connection) or {}
		if event.fields.back then
			mem.screenstate = "oobe_floortable"
		elseif event.fields.next and #mem.params.carids > 0 then
			mem.screenstate = (mem.screenstate == "oobe_connections" and "status" or "menu")
			mem.screenpage = 1
		elseif exp.type == "CHG" then
			mem.editingconnection = #mem.params.carids-exp.index+1
		elseif exp.type == "DCL" then
			mem.editingconnection = #mem.params.carids-exp.index+1
			mem.screenstate = (mem.screenstate == "oobe_connections" and "oobe_connection" or "connection")
		elseif event.fields.edit then
			mem.screenstate = (mem.screenstate == "oobe_connections" and "oobe_connection" or "connection")
			mem.newconnfloors = mem.params.floorsserved[mem.params.carids[mem.editingconnection]]
		elseif event.fields.add then
			mem.newconnfloors = {}
			for i in ipairs(mem.params.floornames) do
				mem.newconnfloors[i] = true
			end
			mem.screenstate = (mem.screenstate == "oobe_connections" and "oobe_newconnection" or "newconnection")
		elseif event.fields.remove then
			mem.carstatus[mem.params.carids[mem.editingconnection]] = nil
			table.remove(mem.params.carids,mem.editingconnection)
			mem.editingconnection = math.max(1,mem.editingconnection-1)
		end
	elseif mem.screenstate == "oobe_newconnection" or mem.screenstate == "newconnection" then
		local exp = event.fields.floors and minetest.explode_textlist_event(event.fields.floors) or {}
		if event.fields.back then
			mem.screenstate = (mem.screenstate == "oobe_newconnection" and "oobe_connections" or "connections")
		elseif event.fields.connect and fields.carid and tonumber(fields.carid) then
			mem.screenstate = (mem.screenstate == "oobe_newconnection" and "oobe_connecting" or "connecting")
			local floornames = {}
			local floorheights = {}
			for i=1,#mem.params.floornames,1 do
				if mem.newconnfloors[i] then
					table.insert(floornames,mem.params.floornames[i])
					table.insert(floorheights,mem.params.floorheights[i])
				elseif #floornames > 0 then
					floorheights[#floorheights] = floorheights[#floorheights]+mem.params.floorheights[i]
				end
			end
			send(tonumber(fields.carid),"pairrequest",{
				floornames = floornames,
				floorheights = floorheights,
			})
			interrupt(3,"connecttimeout")
		elseif exp.type == "CHG" then
			local floor = #mem.params.floornames-exp.index+1
			mem.newconnfloors[floor] = not mem.newconnfloors[floor]
		end
	elseif mem.screenstate == "oobe_connection" or mem.screenstate == "connection" then
		local exp = event.fields.floors and minetest.explode_textlist_event(event.fields.floors) or {}
		if event.fields.back then
			mem.screenstate = (mem.screenstate == "oobe_connection" and "oobe_connections" or "connections")
		elseif event.fields.save then
			mem.screenstate = (mem.screenstate == "oobe_connection" and "oobe_connections" or "connections")
			local floornames = {}
			local floorheights = {}
			for i=1,#mem.params.floornames,1 do
				if mem.newconnfloors[i] then
					table.insert(floornames,mem.params.floornames[i])
					table.insert(floorheights,mem.params.floorheights[i])
				elseif #floornames > 0 then
					floorheights[#floorheights] = floorheights[#floorheights]+mem.params.floorheights[i]
				end
			end
			send(mem.params.carids[mem.editingconnection],"newfloortable",{
				floornames = floornames,
				floorheights = floorheights,
			})
		elseif exp.type == "CHG" then
			local floor = #mem.params.floornames-exp.index+1
			mem.newconnfloors[floor] = not mem.newconnfloors[floor]
		end
	elseif mem.screenstate == "oobe_connectionfailed" or mem.screenstate == "connectionfailed" then
		if fields.back then
			mem.screenstate = (mem.screenstate == "oobe_connectionfailed" and "oobe_newconnection" or "newconnection")
		end
	elseif mem.screenstate == "status" then
		for k,v in pairs(fields) do
			if string.sub(k,1,7) == "carcall" then
				local car = tonumber(string.sub(k,8,9))
				local floor = tonumber(string.sub(k,10,-1))
				if v and car and floor then
					local carid = mem.params.carids[car]
					send(carid,"carcall",realtocarfloor(carid,floor))
				end
			elseif string.sub(k,1,6) == "upcall" then
				local floor = tonumber(string.sub(k,7,-1))
				if v and floor and not mem.upcalls[floor] then
					mem.upcalls[floor] = true
					mem.upeta[floor] = 0
					interrupt(0,"run")
				end
			elseif string.sub(k,1,6) == "dncall" then
				local floor = tonumber(string.sub(k,7,-1))
				if v and floor and not mem.dncalls[floor] then
					mem.dncalls[floor] = true
					mem.dneta[floor] = 0
					interrupt(0,"run")
				end
			end
		end
		if fields.scrollup and (mem.screenpage-1)*10+1 < #mem.params.floornames then
			mem.screenpage = mem.screenpage + 1
		elseif fields.scrolldown and mem.screenpage > 1 then
			mem.screenpage = mem.screenpage - 1
		elseif fields.menu then
			mem.screenstate = "menu"
		end
	elseif mem.screenstate == "menu" then
		if fields.back then
			mem.screenstate = "status"
		elseif fields.floortable then
			mem.screenstate = "floortable"
		elseif fields.connections then
			mem.screenstate = "connections"
		end
	end
elseif event.iid == "connecttimeout" then
	if mem.screenstate == "oobe_connecting" then
		mem.screenstate = "oobe_connectionfailed"
	elseif mem.screenstate == "connecting" then
		mem.screenstate = "connectionfailed"
	end
elseif event.channel == "pairok" then
	if mem.screenstate == "oobe_connecting" or mem.screenstate == "connecting" then
		interrupt(nil,"connecttimeout")
		mem.screenstate = (mem.screenstate == "oobe_connecting" and "oobe_connections" or "connections")
		mem.carstatus[event.source] = {
			groupupcalls = {},
			groupdncalls = {},
			swingupcalls = {},
			swingdncalls = {},
			upcalls = {},
			dncalls = {},
			carcalls = {},
			doorstate = event.msg.doorstate,
			position = event.msg.drive.status.apos or 0,
			target = event.msg.drive.status.dpos or 0,
			state = event.msg.carstate,
			direction = event.msg.direction,
			vel = event.msg.drive.status.vel or 0,
			contractspeed = event.msg.params.contractspeed,
			doortimer = event.msg.params.doortimer,
		}
		mem.params.floorsserved[event.source] = mem.newconnfloors
		table.insert(mem.params.carids,event.source)
	end
elseif event.channel == "status" then
	mem.carstatus[event.source] = {
		groupupcalls = event.msg.groupupcalls,
		groupdncalls = event.msg.groupdncalls,
		swingupcalls = event.msg.swingupcalls,
		swingdncalls = event.msg.swingdncalls,
		upcalls = event.msg.upcalls,
		dncalls = event.msg.dncalls,
		carcalls = event.msg.carcalls,
		doorstate = event.msg.doorstate,
		position = event.msg.drive.status.apos or 0,
		target = event.msg.drive.status.dpos or 0,
		state = event.msg.carstate,
		direction = event.msg.direction,
		vel = event.msg.drive.status.vel,
		contractspeed = event.msg.params.contractspeed,
		doortimer = event.msg.params.doortimer,
	}
	if event.msg.carstate == "normal" and event.msg.doorstate == "opening" then
		local floor = getpos(event.source)
		if event.msg.direction == "up" then
			mem.upcalls[floor] = nil
		elseif event.msg.direction == "down" then
			mem.dncalls[floor] = nil
		end
	end
	local busy = false
	local check = {
		"groupupcalls",
		"groupdncalls",
		"swingupcalls",
		"swingdncalls",
		"upcalls",
		"dncalls",
		"carcalls",
	}
	for _,list in ipairs(check) do
		for _,i in ipairs(event.msg[list]) do
			if i then busy = true end
		end
	end
	if busy then
		if mem.powerstate == "asleep" then
			mem.powerstate = "awake"
			interrupt(1,"run")
		end
	end
elseif event.type == "abm"
       or event.type == "remotewake"
       or (event.iid == "run" and mem.powerstate ~= "asleep")
       and (mem.screenstate == "status" or mem.screenstate == "menu")
then
	local busy = false
	if not mem.upcalls then mem.upcalls = {} end
	if not mem.dncalls then mem.dncalls = {} end
	if not mem.upeta then mem.upeta = {} end
	if not mem.dneta then mem.dneta = {} end
	if not mem.assignedup then mem.assignedup = {} end
	if not mem.assigneddn then mem.assigneddn = {} end
	local unassignedup = table.copy(mem.upcalls)
	local unassigneddn = table.copy(mem.dncalls)
	for _,carid in ipairs(mem.params.carids) do
		for floor in pairs(mem.carstatus[carid].groupupcalls) do
			unassignedup[cartorealfloor(carid,floor)] = nil
		end
		for floor in pairs(mem.carstatus[carid].groupdncalls) do
			unassigneddn[cartorealfloor(carid,floor)] = nil
		end
	end
	for i in pairs(unassignedup) do
		busy = true
		local eligiblecars = {}
		for _,carid in pairs(mem.params.carids) do
			if mem.carstatus[carid].state == "normal" and mem.params.floorsserved[carid][i] then
				local serveshigher = false
				for floor,served in pairs(mem.params.floorsserved[carid]) do
					if floor > i and served then
						serveshigher = true
						break
					end
				end
				if serveshigher then eligiblecars[carid] = true end
			end
		end
		local besteta = 999
		local bestcar
		local alreadyserved
		for carid in pairs(eligiblecars) do
			local eta = calculateeta(carid,i,"up")
			if eta < besteta then
				besteta = eta
				bestcar = carid
			end
			if getpos(carid) == i
			   and mem.carstatus[carid].direction == "up"
			   and (mem.carstatus[carid].doorstate == "opening" or mem.carstatus[carid].doorstate == "open")
			then
				alreadyserved = true
			end
		end
		mem.upeta[i] = besteta
		if bestcar and not alreadyserved then
			send(bestcar,"groupupcall",realtocarfloor(bestcar,i))
			mem.assignedup[i] = bestcar
		else
			mem.upcalls[i] = nil
		end
	end
	for i in pairs(mem.assignedup) do
		if mem.upcalls[i] and mem.upeta[i] then
			busy = true
			local eligiblecars = {}
			local permanent = false
			for _,carid in pairs(mem.params.carids) do
				if getdpos(carid) == i and mem.carstatus[carid].direction == "up" and mem.carstatus[carid].state == "normal" then permanent = true end
				if mem.carstatus[carid].state == "normal" and mem.params.floorsserved[carid][i] then
					local serveshigher = false
					for floor,served in pairs(mem.params.floorsserved[carid]) do
						if floor > i and served then
							serveshigher = true
							break
						end
					end
					if serveshigher then eligiblecars[carid] = true end
				end
			end
			if not permanent then
				local besteta = 999
				local bestcar
				for carid in pairs(eligiblecars) do
					local eta = calculateeta(carid,i,"up")
					if eta < besteta then
						besteta = eta
						bestcar = carid
					end
				end
				if mem.upeta[i]-besteta > 15 and mem.upeta[i]/besteta > 2 then
					send(mem.assignedup[i],"groupupcancel",realtocarfloor(mem.assignedup[i],i))
					mem.upeta[i] = besteta
					send(bestcar,"groupupcall",realtocarfloor(bestcar,i))
					mem.assignedup[i] = bestcar
				end
			end
		end
	end
	for floor,carid in pairs(mem.assignedup) do
		mem.upeta[floor] = calculateeta(carid,floor,"up")
	end
	for i in pairs(unassigneddn) do
		busy = true
		local eligiblecars = {}
		local permanent = false
		for _,carid in pairs(mem.params.carids) do
			if getdpos(carid) == i and mem.carstatus[carid].direction == "down" and mem.carstatus[carid].state == "normal" then permanent = true end
			if mem.carstatus[carid].state == "normal" and mem.params.floorsserved[carid][i] then
				local serveslower = false
				for floor,served in pairs(mem.params.floorsserved[carid]) do
					if floor < i and served then
						serveslower = true
						break
					end
				end
				if serveslower then eligiblecars[carid] = true end
			end
		end
		if not permanent then
			local besteta = 999
			local bestcar
			local alreadyserved = false
			for carid in pairs(eligiblecars) do
				local eta = calculateeta(carid,i,"down")
				if eta < besteta then
					besteta = eta
					bestcar = carid
				end
				if getpos(carid) == i
				   and mem.carstatus[carid].direction == "down"
				   and (mem.carstatus[carid].doorstate == "opening" or mem.carstatus[carid].doorstate == "open")
				then
					alreadyserved = true
				end
			end
			mem.dneta[i] = besteta
			if bestcar and not alreadyserved then
				send(bestcar,"groupdncall",realtocarfloor(bestcar,i))
				mem.assigneddn[i] = bestcar
			else
				mem.dncalls[i] = nil
			end
		end
	end
	for i in pairs(mem.assigneddn) do
		if mem.dncalls[i] and mem.dneta[i] then
			busy = true
			local eligiblecars = {}
			for _,carid in pairs(mem.params.carids) do
				if mem.carstatus[carid].state == "normal" and mem.params.floorsserved[carid][i] then
					local serveslower = false
					for floor,served in pairs(mem.params.floorsserved[carid]) do
						if floor < i and served then
							serveslower = true
							break
						end
					end
					if serveslower then eligiblecars[carid] = true end
				end
			end
			local besteta = 999
			local bestcar
			for carid in pairs(eligiblecars) do
				local eta = calculateeta(carid,i,"down")
				if eta < besteta then
					besteta = eta
					bestcar = carid
				end
			end
			if mem.dneta[i]-besteta > 15 and mem.dneta[i]/besteta > 2 then
				send(mem.assigneddn[i],"groupdncancel",realtocarfloor(mem.assigneddn[i],i))
				mem.dneta[i] = besteta
				send(bestcar,"groupdncall",realtocarfloor(bestcar,i))
				mem.assigneddn[i] = bestcar
			end
		end
	end
	for floor,carid in pairs(mem.assigneddn) do
		mem.dneta[floor] = calculateeta(carid,floor,"down")
	end
	for k,call in ipairs(mem.dbdcalls) do
		if call.assigned then
			if not mem.carstatus[call.assigned] then
				table.remove(mem.dbdcalls,k)
			else
				local carstate = mem.carstatus[call.assigned].state
				local doorstate = mem.carstatus[call.assigned].doorstate
				local direction = mem.carstatus[call.assigned].direction
				local desireddir = (call.srcfloor < call.destfloor and "up" or "down")
				if direction == desireddir and doorstate ~= "closed" then
					if carstate == "normal" then send(call.assigned,"carcall",realtocarfloor(call.assigned,call.destfloor)) end
					table.remove(mem.dbdcalls,k)
				end
			end
		else
			local direction = (call.srcfloor < call.destfloor and "up" or "down")
			local eligiblecars = {}
			local revcarids = {}
			for carnum,carid in pairs(mem.params.carids) do
				if mem.carstatus[carid].state == "normal" and mem.params.floorsserved[carid][call.srcfloor] and mem.params.floorsserved[carid][call.destfloor] then
					table.insert(eligiblecars,carid)
				end
				revcarids[carid] = carnum
			end
			local besteta = 999
			local bestcar
			if #eligiblecars > 0 then
				for _,carid in pairs(eligiblecars) do
					local eta = calculateeta(carid,call.srcfloor,direction)
					if eta < besteta then
						besteta = eta
						bestcar = carid
					end
				end
			end
			if bestcar then
				call.assigned = bestcar
				send(bestcar,(direction == "up" and "swingupcall" or "swingdncall"),realtocarfloor(bestcar,call.srcfloor))
				kiosksend(call.kioskpos,revcarids[bestcar])
			else
				table.remove(mem.dbdcalls,k)
				kiosksend(call.kioskpos,-1)
			end
		end
	end
	if busy or event.type == "remotewake" or #mem.dbdcalls > 0 then
		mem.powerstate = "awake"
		interrupt(nil,"sleep")
		interrupt(1,"run")
	else
		if mem.powerstate == "awake" then
			interrupt(1,"run")
			mem.powerstate = "timing"
			interrupt(10,"sleep")
		elseif mem.powerstate == "timing" then
			interrupt(1,"run")
		end
	end
	if mem.powerstate ~= "asleep" or event.type == "abm" or event.type == "remotewake" then
		interrupt(0.5,"getstatus")
	end
elseif event.iid == "getstatus" then
	for _,carid in ipairs(mem.params.carids) do
		send(carid,"getstatus")
	end
elseif event.type == "callbutton" then
	if mem.powerstate == "asleep" then
		mem.powerstate = "awake"
		interrupt(0,"getstatus")
		interrupt(1,"run")
	elseif mem.powerstate == "timing" then
		mem.powerstate = "awake"
	end
	if event.dir == "up" and event.landing >= 1 and event.landing < #mem.params.floornames then
		mem.upcalls[event.landing] = true
	elseif event.dir == "down" and event.landing > 1 and event.landing <= #mem.params.floornames then
		mem.dncalls[event.landing] = true
	end
elseif event.type == "fs1switch" then
	mem.fs1switch = event.state
	mem.fs1led = event.state
	for _,carid in ipairs(mem.params.carids) do
		send(carid,"fs1switch",event.state)
	end
elseif event.iid == "sleep" and mem.powerstate == "timing" then
	interrupt(nil,"run")
	mem.powerstate = "asleep"
elseif event.type == "remotemsg" then
	if mem.powerstate == "asleep" then
		mem.powerstate = "awake"
		interrupt(0,"getstatus")
		interrupt(1,"run")
	elseif mem.powerstate == "timing" then
		mem.powerstate = "awake"
	end
	if event.channel == "upcall" then
		mem.upcalls[event.msg] = true
	elseif event.channel == "dncall" then
		mem.dncalls[event.msg] = true
	elseif event.channel == "carcall" then
		if mem.params.carids[event.car] then
			send(mem.params.carids[event.car],"carcall",event.floor)
		end
	end
elseif event.type == "dbdkiosk" then
	if mem.powerstate == "asleep" then
		mem.powerstate = "awake"
		interrupt(0,"getstatus")
		interrupt(1,"run")
	elseif mem.powerstate == "timing" then
		mem.powerstate = "awake"
	end
	table.insert(mem.dbdcalls,{
		srcfloor = event.srcfloor,
		destfloor = event.destfloor,
		kioskpos = event.source,
	})
end

if not (mem.screenstate == "status" or mem.screenstate == "menu") then
	mem.upcalls = {}
	mem.dncalls = {}
end

fs("formspec_version[6]")
fs("size[20,12]")
fs("no_prepend[]")
fs("background9[0,0;16,12;celevator_fs_bg.png;true;3]")

if mem.screenstate == "oobe_welcome" then
	fs("image[6,1;4,2;celevator_logo.png]")
	fs("label[1,4;Welcome to your new MTronic XT elevator dispatcher!]")
	fs("label[1,4.5;Before continuing, make sure you have at least two controllers in group operation mode and ready to connect.]")
	fs("label[1,5.5;Press Next to begin.]")
	fs("button[1,10;2,1;license;License Info]")
	fs("button[13,10;2,1;next;Next >]")
elseif mem.screenstate == "oobe_license" then
	local licensefile = io.open(minetest.get_modpath("celevator")..DIR_DELIM.."LICENSE")
	local license = minetest.formspec_escape(licensefile:read("*all"))
	licensefile:close()
	fs("textarea[1,1;14,8;license;This applies to the whole celevator mod\\, not just this dispatcher:;"..license.."]")
	fs("button[7,10.5;2,1;back;OK]")
elseif mem.screenstate == "oobe_floortable" or mem.screenstate == "floortable" then
	if mem.screenstate == "oobe_floortable" then
		fs("label[1,1;Enter details of all floors this group will serve, then press Next.]")
		fs("label[1,1.3;Include all floors served by any car in the group, even if not served by all cars.]")
		fs("button[1,10;2,1;back;< Back]")
		fs("button[13,10;2,1;next;Next >]")
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
elseif mem.screenstate == "oobe_connections" or mem.screenstate == "connections" then
	if mem.screenstate == "oobe_connections" then
		fs("label[1,1;Connect to each car in the group, then click Done.]")
		fs("button[1,10;2,1;back;< Back]")
		if #mem.params.carids > 0 then fs("button[13,10;2,1;next;Done >]") end
	else
		fs("label[1,1;EDIT CONNECTIONS]")
		if #mem.params.carids > 0 then fs("button[1,10;2,1;next;Done]") end
	end
	if #mem.params.carids > 0 then
		fs("textlist[1,2;6,7;connection;")
		for i=#mem.params.carids,1,-1 do
			fs(string.format("Car %d - ID #%d",i,mem.params.carids[i])..(i==1 and "" or ","))
		end
		fs(";"..tostring(#mem.params.carids-mem.editingconnection+1)..";false]")
	else
		fs("label[1,2;No Connections]")
	end
	if #mem.params.carids < 16 then fs("button[8,2;3,1;add;New Connection]") end
	if #mem.params.carids > 0 then fs("button[8,3.5;3,1;edit;Edit Connection]") end
	if #mem.params.carids > 0 then fs("button[8,5;3,1;remove;Remove Connection]") end
elseif mem.screenstate == "oobe_newconnection" or mem.screenstate == "newconnection" then
	local numfloors = 0
	for _,v in ipairs(mem.newconnfloors) do
		if v then numfloors = numfloors + 1 end
	end
	if mem.screenstate == "oobe_newconnection" then
		fs("label[1,1;Enter the car ID and select the floors served (click them to toggle), then click Connect.]")
		fs("label[1,1.3;You must select at least two floors.]")
		fs("button[1,10;2,1;back;< Back]")
		if numfloors >= 2 then fs("button[13,10;2,1;connect;Connect >]") end
	else
		fs("label[1,1;NEW CONNECTION]")
		fs("button[1,10;2,1;back;Back]")
		if numfloors >= 2 then fs("button[13,10;2,1;connect;Connect]") end
	end
	fs("textlist[8,2;6,7;floors;")
	for i=#mem.params.floornames,1,-1 do
		fs(string.format("%s - %s",minetest.formspec_escape(mem.params.floornames[i]),mem.newconnfloors[i] and "YES" or "NO")..(i==1 and "" or ","))
	end
	fs(";0;false]")
	fs("field[2,3;4,1;carid;Car ID;]")
elseif mem.screenstate == "oobe_connection" or mem.screenstate == "connection" then
	local numfloors = 0
	for _,v in ipairs(mem.newconnfloors) do
		if v then numfloors = numfloors + 1 end
	end
	if mem.screenstate == "oobe_newconnection" then
		fs("label[1,1;Enter the car ID and select the floors served (click them to toggle), then click Connect.]")
		fs("label[1,1.3;You must select at least two floors.]")
		fs("button[1,10;2,1;back;< Back]")
		if numfloors >= 2 then fs("button[13,10;2,1;save;Save >]") end
	else
		fs("label[1,1;EDIT CONNECTION]")
		fs("button[1,10;2,1;back;< Back]")
		if numfloors >= 2 then fs("button[13,10;2,1;save;Save >]") end
	end
	fs("textlist[8,2;6,7;floors;")
	for i=#mem.params.floornames,1,-1 do
		fs(string.format("%s - %s",minetest.formspec_escape(mem.params.floornames[i]),mem.newconnfloors[i] and "YES" or "NO")..(i==1 and "" or ","))
	end
	fs(";0;false]")
	fs("label[2,3;Car ID: "..mem.params.carids[mem.editingconnection].."]")
elseif mem.screenstate == "oobe_connecting" or mem.screenstate == "connecting" then
	fs("label[1,1;Connecting to controller...]")
elseif mem.screenstate == "oobe_connectionfailed" or mem.screenstate == "connectionfailed" then
	fs("label[4,4;Connection timed out!]")
	fs("label[4,5;Make sure the car ID is correct and]")
	fs("label[4,5.5;that the controller is ready to pair.]")
	fs("button[1,10;2,1;back;< Back]")
elseif mem.screenstate == "status" then
	if not mem.screenpage then mem.screenpage = 1 end
	fs("label[1,1;GROUP DISPLAY]")
	fs("box[1.5,1.5;0.1,10;#AAAAAAFF]")
	fs("box[18.5,1.5;0.1,10;#AAAAAAFF]")
	fs("label[0.55,11.5;UP]")
	fs("label[18.85,11.5;DOWN]")
	fs("button[15,0.5;2,1;menu;Menu]")
	fs("style_type[image_button;font=mono;font_size=*0.75]")
	for car=1,#mem.params.carids,1 do
		local xp = 1.7+(car-1)
		local carid = mem.params.carids[car]
		local carstate = mem.carstatus[carid].state
		fs(string.format("label[%f,11;CAR %d]",xp,car))
		fs(string.format("label[%f,11.35;%s]",xp+0.1,minetest.colorize("#ff5555",(carstate == "normal" and " IN" or "OUT"))))
	end
	local lowestfloor = (mem.screenpage-1)*10+1
	for i=1,math.min(10,#mem.params.floornames-lowestfloor+1),1 do
		local yp = 9.75-0.8*(i-1)
		local floor = i+lowestfloor-1
		fs(string.format("label[0.9,%f;%s]",yp+0.35,mem.params.floornames[floor]))
		local uplabel = ""
		if mem.upcalls[floor] then uplabel = minetest.colorize("#55FF55",math.floor(mem.upeta[floor] or 0)) end
		if floor < #mem.params.floornames then fs(string.format("image_button[0.15,%f;0.75,0.75;celevator_fs_bg.png;upcall%d;%s]",yp,floor,uplabel)) end
		fs(string.format("label[18.65,%f;%s]",yp+0.35,mem.params.floornames[floor]))
		local dnlabel = ""
		if mem.dncalls[floor] then dnlabel = minetest.colorize("#FF5555",math.floor(mem.dneta[floor] or 0)) end
		if floor > 1 then fs(string.format("image_button[19.1,%f;0.75,0.75;celevator_fs_bg.png;dncall%d;%s]",yp,floor,dnlabel)) end
		for car=1,#mem.params.carids,1 do
			local xp = 1.7+(car-1)
			local carid = mem.params.carids[car]
			local carfloor = realtocarfloor(carid,floor)
			if carfloor then
				local ccdot = mem.carstatus[carid].carcalls[carfloor] and "*" or ""
				local groupup = mem.carstatus[carid].groupupcalls[carfloor] and minetest.colorize("#55FF55","^") or ""
				local swingup = mem.carstatus[carid].swingupcalls[carfloor] and minetest.colorize("#FFFF55","^") or ""
				local swingdn = mem.carstatus[carid].swingdncalls[carfloor] and minetest.colorize("#FFFF55","v") or ""
				local groupdn = mem.carstatus[carid].groupdncalls[carfloor] and minetest.colorize("#FF5555","v") or ""
				ccdot = groupup..swingup..ccdot..swingdn..groupdn
				if getpos(carid) == floor then
					local cargraphics = {
						open = "\\[   \\]",
						opening = "\\[< >\\]",
						closing = "\\[> <\\]",
						closed = "\\[ | \\]",
						testtiming = "\\[ | \\]",
					}
					ccdot = cargraphics[mem.carstatus[carid].doorstate]
					if mem.carstatus[carid].direction == "up" then
						ccdot = minetest.colorize("#55FF55",ccdot)
					elseif mem.carstatus[carid].direction == "down" then
						ccdot = minetest.colorize("#FF5555",ccdot)
					end
				end
				fs(string.format("image_button[%f,%f;0.75,0.75;celevator_fs_bg.png;carcall%02d%d;%s]",xp,yp,car,floor,ccdot))
			end
		end
	end
	if lowestfloor > 1 then
		fs("image_button[6,0.5;0.75,0.75;celevator_menu_arrow.png^\\[transformFY;scrolldown;;false;false;celevator_menu_arrow.png^\\[transformFY]")
	end
	if lowestfloor+9 < #mem.params.floornames then
		fs("image_button[5,0.5;0.75,0.75;celevator_menu_arrow.png;scrollup;;false;false;celevator_menu_arrow.png]")
	end
	elseif mem.screenstate == "menu" then
		fs("label[1,1;MAIN MENU]")
		fs("button[1,3;3,1;floortable;Edit Floor Table]")
		fs("button[1,4.5;3,1;connections;Edit Connections]")
		fs("button[1,10;3,1;back;< Back]")
end

mem.infotext = string.format("ID: %d",mem.carid)

return pos,mem,changedinterrupts
