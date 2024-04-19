local pos,event,mem = ...

local changedinterrupts = {}

local function interrupt(time,iid)
	mem.interrupts[iid] = time
	changedinterrupts[iid] = true
end

mem.messages = {}

local function send(carid,channel,message)
	table.insert(mem.messages,{
		carid = carid,
		channel = channel,
		message = message,
	})
end

mem.formspec = ""

local function fs(element)
	mem.formspec = mem.formspec..element
end

if event.type == "program" then
	mem.carstatus = {}
	mem.screenstate = "oobe_welcome"
	mem.editingfloor = 1
	mem.screenpage = 1
	mem.editingconnection = 1
	mem.newconncarid = 0
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
			mem.screenstate = (mem.screenstate == "oobe_floortable" and "oobe_connections" or "parameters")
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
	elseif mem.screenstate == "oobe_connections" or mem.screenstate == "connections" then
		local exp = event.fields.connection and minetest.explode_textlist_event(event.fields.connection) or {}
		if event.fields.back then
			mem.screenstate = "oobe_floortable"
		elseif event.fields.next and #mem.params.carids > 0 then
			mem.screenstate = (mem.screenstate == "oobe_connections" and "status" or "parameters")
			mem.screenpage = 1
		elseif exp.type == "CHG" then
			mem.editingconnection = #mem.params.carids-exp.index+1
		elseif exp.type == "DCL" then
			mem.editingconnection = #mem.params.carids-exp.index+1
			mem.screenstate = (mem.screenstate == "oobe_connections" and "oobe_connection" or "connection")
		elseif event.fields.edit then
			mem.screenstate = (mem.screenstate == "oobe_connections" and "oobe_connection" or "connection")
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
				dispatcherid = mem.carid,
				floornames = floornames,
				floorheights = floorheights,
			})
			interrupt(3,"connecttimeout")
		elseif exp.type == "CHG" then
			local floor = #mem.params.floornames-exp.index+1
			mem.newconnfloors[floor] = not mem.newconnfloors[floor]
		end
	elseif mem.screenstate == "oobe_connectionfailed" or mem.screenstate == "connectionfailed" then
		if fields.back then
			mem.screenstate = (mem.screenstate == "oobe_connectionfailed" and "oobe_newconnection" or "newconnection")
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
			upcalls = {},
			dncalls = {},
			carcalls = {},
			position = event.msg.drive.status.apos or 0,
			state = event.msg.carstate,
		}
		mem.params.floorsserved[event.source] = mem.newconnfloors
		table.insert(mem.params.carids,event.source)
	end
end

fs("formspec_version[6]")
fs("size[16,12]")
fs("background9[0,0;16,12;celevator_fs_bg.png;true;3]")

if mem.screenstate == "oobe_welcome" then
	fs("image[6,1;4,2;celevator_logo.png]")
	fs("label[1,4;Welcome to your new MTronic XT elevator dispatcher!]")
	fs("label[1,4.5;Before continuing, make sure you have at least two controllers in group operation mode and ready to connect.]")
	fs("label[1,5.5;Press Next to begin.]")
	fs("button[1,10;2,1;license;License Info]")
	fs("button[13,10;2,1;next;Next >]")
elseif mem.screenstate == "oobe_license" then
	local licensefile = io.open(minetest.get_modpath("celevator")..DIR_DELIM.."COPYING")
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
		fs(";"..tostring(#mem.params.floornames-mem.editingfloor+1)..";false]")
	else
		fs("label[1,2;No Connections]")
	end
	if #mem.params.carids < 16 then fs("button[8,2;2,1;add;New Connection]") end
	if #mem.params.carids > 0 then fs("button[8,3.5;2,1;edit;Edit Connection]") end
	if #mem.params.carids > 0 then fs("button[8,5;2,1;remove;Remove Connection]") end
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
		fs("button[1,10;2,1;back;< Back]")
		if numfloors >= 2 then fs("button[13,10;2,1;connect;Connect >]") end
	end
	fs("textlist[8,2;6,7;floors;")
	for i=#mem.params.floornames,1,-1 do
		fs(string.format("%s - %s",minetest.formspec_escape(mem.params.floornames[i]),mem.newconnfloors[i] and "YES" or "NO")..(i==1 and "" or ","))
	end
	fs(";0;false]")
	fs("field[2,3;4,1;carid;Car ID;]")
elseif mem.screenstate == "oobe_connecting" or mem.screenstate == "connecting" then
	fs("label[1,1;Connecting to controller...]")
elseif mem.screenstate == "oobe_connectionfailed" or mem.screenstate == "connectionfailed" then
	fs("label[4,4;Connection timed out!]")
	fs("label[4,5;Make sure the car ID is correct and]")
	fs("label[4,5.5;that the controller is ready to pair.]")
	fs("button[1,10;2,1;back;< Back]")
end

mem.infotext = string.format("ID: %d",mem.carid)

return pos,mem,changedinterrupts
