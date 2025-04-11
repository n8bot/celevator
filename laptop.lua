laptop.register_app("celevator",{
	app_name = "mView",
	app_info = "Remote interface for MTronic XT elevator controllers",
	app_icon = "celevator_laptop_icon.png",
	formspec_func = function(_,mtos)
		local ram = mtos.bdev:get_app_storage("ram","celevator")
		local mem = mtos.bdev:get_app_storage("hdd","celevator")
		if not mem then return mtos.theme:get_label("0.5,0.5","This application requires a hard disk drive.") end
		if not mem.connections then mem.connections = {} end
		if not ram.screenstate then ram.screenstate = (#mem.connections > 0 and "connections" or "welcome") end
		if not mem.selectedconnection then mem.selectedconnection = 1 end
		if not mem.screenpage then mem.screenpage = 1 end
		if not mem.newconnection then mem.newconnection = {} end
		if not mem.scrollfollowscar then mem.scrollfollowscar = false end
		local fs = ""
		if ram.screenstate == "welcome" then
			fs = fs.."background9[5.5,1;4,2;celevator_fs_bg.png;false;3]"
			fs = fs.."image[5.75,1;4,2;celevator_logo.png]"
			fs = fs..mtos.theme:get_label("2,4","Welcome to the mView remote interface for MTronic XT elevator controllers!")
			fs = fs..mtos.theme:get_label("2,6","Add a connection to get started.")
			fs = fs..mtos.theme:get_button("5.5,7;4,1","major","connections","Add/Edit Connections")
		elseif ram.screenstate == "connections" then
			fs = fs..mtos.theme:get_label("0.5,0.5","MANAGE CONNECTIONS")
			if #mem.connections > 0 then
				fs = fs.."textlist[1,2;6,7;connection;"
				for i=#mem.connections,1,-1 do
					local text = string.format("ID %d - %s",mem.connections[i].carid,mem.connections[i].name)
					fs = fs..minetest.formspec_escape(text)
					fs = fs..(i==1 and "" or ",")
				end
				fs = fs..";"..tostring(#mem.connections-mem.selectedconnection+1)..";false]"
			else
				fs = fs..mtos.theme:get_label("1,2","No Connections")
			end
			fs = fs..mtos.theme:get_button("8,2;3,1","major","new","New Connection")
			if mem.connections[mem.selectedconnection] then
				fs = fs..mtos.theme:get_button("8,3;3,1","major","edit","Edit Connection")
				fs = fs..mtos.theme:get_button("8,4;3,1","major","delete","Delete Connection")
				fs = fs..mtos.theme:get_button("8,7;3,1","major","connect","Connect >")
				if #mem.connections > mem.selectedconnection then fs = fs..mtos.theme:get_button("8,5;3,1","major","moveup","Move Up") end
				if mem.selectedconnection > 1 then fs = fs..mtos.theme:get_button("8,6;3,1","major","movedown","Move Down") end
			end
		elseif ram.screenstate == "newconnection" then
			fs = fs..mtos.theme:get_label("0.5,0.5","NEW CONNECTION")
			fs = fs..mtos.theme:get_label("0.5,1","Please enter the ID you would like to connect to and a name for the connection.")
			fs = fs..mtos.theme:get_label("0.7,1.8","ID")
			fs = fs..mtos.theme:get_label("3.7,1.8","Name")
			fs = fs..string.format("field[1,2.5;2,1;carid;;%s]",minetest.formspec_escape(mem.newconnection.carid))
			fs = fs..string.format("field[4,2.5;4,1;name;;%s]",minetest.formspec_escape(mem.newconnection.name))
			fs = fs..mtos.theme:get_button("3,4;3,1","major","save","Save")
			fs = fs..mtos.theme:get_button("3,5.5;3,1","major","cancel","Cancel")
		elseif ram.screenstate == "editconnection" then
			fs = fs..mtos.theme:get_label("0.5,0.5","EDIT CONNECTION")
			fs = fs..mtos.theme:get_label("0.7,1.8","ID: "..mem.connections[mem.selectedconnection].carid)
			fs = fs..mtos.theme:get_label("3.7,1.8","Name")
			fs = fs..string.format("field[4,2.5;4,1;name;;%s]",minetest.formspec_escape(mem.connections[mem.selectedconnection].name))
			fs = fs..mtos.theme:get_button("3,4;3,1","major","save","Save")
			fs = fs..mtos.theme:get_button("3,5.5;3,1","major","cancel","Cancel")
		elseif ram.screenstate == "notfound" then
			fs = fs..mtos.theme:get_label("0.5,0.5","Error")
			fs = fs..mtos.theme:get_label("0.5,1","Could not find a controller or dispatcher with the given ID.")
			fs = fs..mtos.theme:get_label("0.5,1.3","Please check the ID number and try again.")
			fs = fs..mtos.theme:get_button("0.5,3;2,1","major","ok","OK")
		elseif ram.screenstate == "protected" then
			fs = fs..mtos.theme:get_label("0.5,0.5","Error")
			fs = fs..mtos.theme:get_label("0.5,1","Controller or dispatcher is protected.")
			fs = fs..mtos.theme:get_button("0.5,3;2,1","major","ok","OK")
		elseif ram.screenstate == "dispatcherstatus" then
			local connection = mem.connections[mem.selectedconnection]
			local pos = connection.pos
			if celevator.dispatcher.isdispatcher(pos) then
				local meta = minetest.get_meta(pos)
				local dmem = minetest.deserialize(meta:get_string("mem"))
				if not dmem then return end
				fs = fs.."background9[-0.1,0.4;15.2,10.05;celevator_fs_bg.png;false;3]"
				fs = fs.."label[0.5,0.5;"..string.format("Connected to %s (ID %d)",connection.name,connection.carid).."]"
				fs = fs.."button[1,1;2,1;disconnect;Disconnect]"
				fs = fs.."box[0.5,1;0.1,9;#AAAAAAFF]"
				fs = fs.."box[14.25,1;0.1,9;#AAAAAAFF]"
				fs = fs.."style_type[label;font_size=*0.75]"
				fs = fs.."label[0.05,10;UP]"
				fs = fs.."label[14.35,10;DOWN]"
				fs = fs.."style_type[image_button;font=mono;font_size=*0.66]"
				for car=1,#dmem.params.carids,1 do
					local xp = (car-1)*0.75+1
					local carid = dmem.params.carids[car]
					local carstate = dmem.carstatus[carid].state
					fs = fs..string.format("label[%f,9.8;CAR %d]",xp,car)
					fs = fs..string.format("label[%f,10;%s]",xp+0.1,minetest.colorize("#ff5555",(carstate == "normal" and " IN" or "OUT")))
				end
				local lowestfloor = (mem.screenpage-1)*10+1
				local maxfloor = #dmem.params.floornames
				if maxfloor > 10 then
					if lowestfloor+9 < maxfloor then
						fs = fs.."image_button[4,1;0.75,0.75;celevator_menu_arrow.png;scrollup;;false;false;celevator_menu_arrow.png]"
					end
					if lowestfloor > 1 then
						fs = fs.."image_button[5,1;0.75,0.75;celevator_menu_arrow.png^\\[transformFY;scrolldown;;false;false;celevator_menu_arrow.png^\\[transformFY]"
					end
				end
				local function getpos(carid)
					local floormap = {}
					local floorheights = {}
					for i=1,#dmem.params.floornames,1 do
						if dmem.params.floorsserved[carid][i] then
							table.insert(floormap,i)
							table.insert(floorheights,dmem.params.floorheights[i])
						elseif #floorheights > 0 then
							floorheights[#floorheights] = floorheights[#floorheights]+dmem.params.floorheights[i]
						end
					end
					local ret = 0
					local searchpos = dmem.carstatus[carid].position
					for k,v in ipairs(floorheights) do
						ret = ret+v
						if ret > searchpos then return floormap[k] end
					end
					return 1
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
					for i=1,#dmem.params.floornames,1 do
						if dmem.params.floorsserved[carid][i] then
							table.insert(map,i)
						end
					end
					local pmap = {}
					for k,v in pairs(map) do
						pmap[v] = k
					end
					return pmap[floor]
				end
				for i=1,math.min(10,#dmem.params.floornames-lowestfloor+1),1 do
					local yp = 8.75-0.72*(i-1)
					local floor = i+lowestfloor-1
					fs = fs..string.format("label[0.62,%f;%s]",yp+0.05,dmem.params.floornames[floor])
					local uplabel = ""
					if dmem.upcalls[floor] then uplabel = minetest.colorize("#55FF55",math.floor(dmem.upeta[floor] or 0)) end
					if floor < #dmem.params.floornames then fs = fs..string.format("image_button[0,%f;0.66,0.66;celevator_fs_bg.png;upcall%d;%s]",yp,floor,uplabel) end
					fs = fs..string.format("label[14,%f;%s]",yp+0.05,dmem.params.floornames[floor])
					local dnlabel = ""
					if dmem.dncalls[floor] then dnlabel = minetest.colorize("#FF5555",math.floor(dmem.dneta[floor] or 0)) end
					if floor > 1 then fs = fs..string.format("image_button[14.4,%f;0.66,0.66;celevator_fs_bg.png;dncall%d;%s]",yp,floor,dnlabel) end
					for car=1,#dmem.params.carids,1 do
						local xp = (car-1)*0.75+1
						local carid = dmem.params.carids[car]
						local carfloor = realtocarfloor(carid,floor)
						if carfloor then
							local ccdot = dmem.carstatus[carid].carcalls[carfloor] and "*" or ""
							local groupup = dmem.carstatus[carid].groupupcalls[carfloor] and minetest.colorize("#55FF55","^") or ""
							local swingup = dmem.carstatus[carid].swingupcalls[carfloor] and minetest.colorize("#FFFF55","^") or ""
							local swingdn = dmem.carstatus[carid].swingdncalls[carfloor] and minetest.colorize("#FFFF55","v") or ""
							local groupdn = dmem.carstatus[carid].groupdncalls[carfloor] and minetest.colorize("#FF5555","v") or ""
							ccdot = groupup..swingup..ccdot..swingdn..groupdn
							if getpos(carid) == floor then
								local cargraphics = {
									open = "\\[   \\]",
									opening = "\\[< >\\]",
									closing = "\\[> <\\]",
									closed = "\\[ | \\]",
									testtiming = "\\[ | \\]",
								}
								ccdot = cargraphics[dmem.carstatus[carid].doorstate]
								if dmem.carstatus[carid].direction == "up" then
									ccdot = minetest.colorize("#55FF55",ccdot)
								elseif dmem.carstatus[carid].direction == "down" then
									ccdot = minetest.colorize("#FF5555",ccdot)
								end
							end
							fs = fs..string.format("image_button[%f,%f;0.66,0.66;celevator_fs_bg.png;carcall%02d%d;%s]",xp,yp,car,floor,ccdot)
						end
					end
				end
				if dmem.powerstate == "asleep" then
					celevator.dispatcher.run(pos,{type = "remotewake"})
				end
			end
		elseif ram.screenstate == "controllerstatus" then
			local connection = mem.connections[mem.selectedconnection]
			local pos = connection.pos
			if celevator.controller.iscontroller(pos) then
				local meta = minetest.get_meta(pos)
				local cmem = minetest.deserialize(meta:get_string("mem"))
				if not cmem then return end
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
				local carpos = 0
				local carfloor = 0
				local searchpos = cmem.drive.status.apos
				for k,v in ipairs(cmem.params.floorheights) do
					carpos = carpos+v
					if carpos > searchpos then
						carfloor = k
						break
					end
				end
				fs = fs..mtos.theme:get_label("1,1",string.format("Connected to %s (ID %d)",connection.name,connection.carid))
				fs = fs..mtos.theme:get_label("1,2",modenames[cmem.carstate])
				fs = fs..mtos.theme:get_label("1,2.5",string.format("Doors %s",doorstates[cmem.doorstate]))
				local pi = minetest.formspec_escape(cmem.params.floornames[carfloor])
				fs = fs..mtos.theme:get_label("1,3",string.format("Position: %0.02fm Speed: %+0.02fm/s PI: %s",cmem.drive.status.apos,cmem.drive.status.vel,pi))
				if #cmem.faultlog > 0 then
					fs = fs..mtos.theme:get_label("1,3.5","Fault(s) Active")
				else
					fs = fs..mtos.theme:get_label("1,3.5","No Current Faults")
				end
				fs = fs.."background9[8,0.3;6.2,10;celevator_fs_bg.png;false;3]"
				fs = fs.."style_type[image_button;font=mono;font_size=*0.75]"
				fs = fs.."box[10.8,0.75;0.1,9;#AAAAAAFF]"
				fs = fs.."box[11.808,0.75;0.05,9;#AAAAAAFF]"
				fs = fs.."box[12.708,0.75;0.05,9;#AAAAAAFF]"
				fs = fs.."box[13.725,0.75;0.1,9;#AAAAAAFF]"
				fs = fs.."label[11.25,0.3;UP]"
				fs = fs.."label[12.042,0.3;CAR]"
				fs = fs.."label[12.825,0.3;DOWN]"
				if mem.scrollfollowscar then mem.screenpage = math.floor((carfloor-1)/10)+1 end
				local maxfloor = #cmem.params.floornames
				local bottom = (mem.screenpage-1)*10+1
				if maxfloor > 10 then
					fs = fs..string.format("checkbox[8.4,1.5;scrollfollowscar;Follow Car;%s]",tostring(mem.scrollfollowscar))
					if bottom+9 < maxfloor then
						fs = fs.."image_button[8.5,1;0.75,0.75;celevator_menu_arrow.png;scrollup;;false;false;celevator_menu_arrow.png]"
					end
					if bottom > 1 then
						fs = fs.."image_button[8.5,2.25;0.75,0.75;celevator_menu_arrow.png^\\[transformFY;scrolldown;;false;false;celevator_menu_arrow.png^\\[transformFY]"
					end
				end
				for i=0,9,1 do
					local ypos = (11-(i*0.9))*0.9-0.75
					local floornum = bottom+i
					if floornum > maxfloor then break end
					fs = fs..string.format("label[10.125,%f;%s]",ypos-0.2,minetest.formspec_escape(cmem.params.floornames[floornum]))
					local ccdot = cmem.carcalls[floornum] and "*" or ""
					if carfloor == floornum then
						local cargraphics = {
							open = "\\[   \\]",
							opening = "\\[< >\\]",
							closing = "\\[> <\\]",
							closed = "\\[ | \\]",
							testtiming = "\\[ | \\]",
						}
						ccdot = cargraphics[cmem.doorstate]
						if cmem.direction == "up" then
							ccdot = minetest.colorize("#55FF55",ccdot)
						elseif cmem.direction == "down" then
							ccdot = minetest.colorize("#FF5555",ccdot)
						end
					end
					fs = fs..string.format("image_button[11.925,%f;0.75,0.75;celevator_fs_bg.png;carcall%d;%s]",ypos-0.25,floornum,ccdot)
					if floornum < maxfloor then
						local arrow = cmem.upcalls[floornum] and minetest.colorize("#55FF55","^") or ""
						if cmem.params.groupmode == "group" then
							arrow = cmem.groupupcalls[floornum] and minetest.colorize("#55FF55","^") or ""
							arrow = (cmem.swingupcalls[floornum] and minetest.colorize("#FFFF55","^") or "")..arrow
						end
						fs = fs..string.format("image_button[11.025,%f;0.75,0.75;celevator_fs_bg.png;upcall%d;%s]",ypos-0.25,floornum,arrow)
					end
					if floornum > 1 then
						local arrow = cmem.dncalls[floornum] and minetest.colorize("#FF5555","v") or ""
						if cmem.params.groupmode == "group" then
							arrow = cmem.swingdncalls[floornum] and minetest.colorize("#FFFF55","v") or ""
							arrow = (cmem.groupdncalls[floornum] and minetest.colorize("#FF5555","v") or "")..arrow
						end
						fs = fs..string.format("image_button[12.825,%f;0.75,0.75;celevator_fs_bg.png;downcall%d;%s]",ypos-0.25,floornum,arrow)
					end
				end
			else
				ram.screenstate = "notfound"
			end
			fs = fs..mtos.theme:get_button("1,8;3,1","major","disconnect","Disconnect")
		end
		return fs
	end,
	receive_fields_func = function(app,mtos,_,fields)
		local ram = mtos.bdev:get_app_storage("ram","celevator")
		local mem = mtos.bdev:get_app_storage("hdd","celevator")
		if not mem then return end
		if ram.screenstate == "welcome" then
			if fields.connections then
				ram.screenstate = "connections"
			end
		elseif ram.screenstate == "connections" then
			local exp = fields.connection and minetest.explode_textlist_event(fields.connection) or {}
			if fields.new then
				ram.screenstate = "newconnection"
				mem.newconnection.name = "Untitled"
				mem.newconnection.carid = ""
			elseif fields.edit then
				ram.screenstate = "editconnection"
			elseif fields.delete then
				table.remove(mem.connections,mem.selectedconnection)
				mem.selectedconnection = math.max(1,#mem.connections)
			elseif fields.moveup then
				local connection = mem.connections[mem.selectedconnection]
				table.remove(mem.connections,mem.selectedconnection)
				table.insert(mem.connections,mem.selectedconnection+1,connection)
				mem.selectedconnection = mem.selectedconnection+1
			elseif fields.movedown then
				local connection = mem.connections[mem.selectedconnection]
				table.remove(mem.connections,mem.selectedconnection)
				table.insert(mem.connections,mem.selectedconnection-1,connection)
				mem.selectedconnection = mem.selectedconnection-1
			elseif fields.connection and exp.type == "CHG" then
				mem.selectedconnection = #mem.connections-exp.index+1
			elseif fields.connect or exp.type == "DCL" then
				mem.screenpage = 1
				if exp.type == "DCL" then mem.selectedconnection = #mem.connections-exp.index+1 end
				local connection = mem.connections[mem.selectedconnection]
				local cpos = connection.pos
				if minetest.is_protected(cpos,mtos.sysram.current_player) and not minetest.check_player_privs(mtos.sysram.current_player,{protection_bypass=true}) then
					minetest.record_protection_violation(cpos,mtos.sysram.current_player)
					ram.screenstate = "protected"
					return
				end
				if connection.itemtype == "controller" and celevator.controller.iscontroller(cpos) then
					ram.screenstate = "controllerstatus"
					app:get_timer():start(0.2)
				elseif connection.itemtype == "dispatcher" and celevator.dispatcher.isdispatcher(cpos) then
					ram.screenstate = "dispatcherstatus"
					app:get_timer():start(0.2)
				else
					ram.screenstate = "notfound"
				end
			end
		elseif ram.screenstate == "editconnection" then
			if fields.save then
				mem.connections[mem.selectedconnection].name = fields.name
				ram.screenstate = "connections"
			elseif fields.cancel then
				ram.screenstate = "connections"
			end
		elseif ram.screenstate == "newconnection" then
			if fields.save then
				local carid = tonumber(fields.carid)
				if not (carid and math.floor(carid) == carid) then return end
				local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
				if not carinfo then return end
				local pos = carinfo.controllerpos
				local itemtype
				if pos and celevator.controller.iscontroller(pos) then
					itemtype = "controller"
				elseif carinfo.dispatcherpos and celevator.dispatcher.isdispatcher(carinfo.dispatcherpos) then
					pos = carinfo.dispatcherpos
					itemtype = "dispatcher"
				else
					ram.screenstate = "notfound"
					return
				end
				if minetest.is_protected(pos,mtos.sysram.current_player) and not minetest.check_player_privs(mtos.sysram.current_player,{protection_bypass=true}) then
					minetest.record_protection_violation(pos,mtos.sysram.current_player)
					ram.screenstate = "protected"
					return
				end
				local connection = {
					name = fields.name,
					carid = carid,
					itemtype = itemtype,
					pos = pos,
				}
				table.insert(mem.connections,connection)
				mem.selectedconnection = #mem.connections
				ram.screenstate = "connections"
			elseif fields.cancel then
				ram.screenstate = "connections"
			end
		elseif ram.screenstate == "notfound" then
			if fields.ok then
				ram.screenstate = "newconnection"
			end
		elseif ram.screenstate == "protected" then
			if fields.ok then
				ram.screenstate = #mem.connections > 0 and "connections" or "newconnection"
			end
		elseif ram.screenstate == "dispatcherstatus" then
			if fields.disconnect then
				ram.screenstate = "connections"
				return
			end
			local pos = mem.connections[mem.selectedconnection].pos
			if celevator.dispatcher.isdispatcher(pos) then
				local meta = minetest.get_meta(pos)
				local dmem = minetest.deserialize(meta:get_string("mem"))
				if not dmem then return end
				for k in pairs(fields) do
					if string.sub(k,1,7) == "carcall" then
						local car = tonumber(string.sub(k,8,9))
						local floor = tonumber(string.sub(k,10,-1))
						if car and floor then
						local map = {}
						for i=1,#dmem.params.floornames,1 do
							if dmem.params.floorsserved[dmem.params.carids[car]][i] then
								table.insert(map,i)
							end
						end
						local pmap = {}
						for k2,v in pairs(map) do
							pmap[v] = k2
						end
							celevator.dispatcher.run(pos,{
								type = "remotemsg",
								channel = "carcall",
								car = car,
								floor = pmap[floor],
							})
						end
					elseif string.sub(k,1,6) == "upcall" then
						local floor = tonumber(string.sub(k,7,-1))
						if floor then
							celevator.dispatcher.run(pos,{
								type = "remotemsg",
								channel = "upcall",
								msg = floor,
							})
						end
					elseif string.sub(k,1,6) == "dncall" then
						local floor = tonumber(string.sub(k,7,-1))
						if floor then
							celevator.dispatcher.run(pos,{
								type = "remotemsg",
								channel = "dncall",
								msg = floor,
							})
						end
					end
				end
				if fields.scrolldown then
					mem.screenpage = math.max(1,mem.screenpage-1)
				elseif fields.scrollup then
					mem.screenpage = math.min(mem.screenpage+1,math.floor((#dmem.params.floornames-1)/10)+1)
				end
			end
		elseif ram.screenstate == "controllerstatus" then
			if fields.disconnect then
				ram.screenstate = "connections"
				return
			end
			local pos = mem.connections[mem.selectedconnection].pos
			if celevator.controller.iscontroller(pos) then
				local meta = minetest.get_meta(pos)
				local cmem = minetest.deserialize(meta:get_string("mem"))
				if not cmem then return end
				local carcallacceptstates = {
					normal = true,
					test = true,
					capture = true,
					indep = true,
				}
				for i=1,#cmem.params.floornames,1 do
					if fields[string.format("carcall%d",i)] and carcallacceptstates[cmem.carstate] then
						celevator.controller.run(pos,{
							type = "remotemsg",
							source = 0,
							channel = "carcall",
							msg = i,
						})
					elseif fields[string.format("upcall%d",i)] and cmem.carstate == "normal" and not cmem.capturesw then
						if cmem.params.groupmode == "group" then
							celevator.controller.run(pos,{
								type = "remotemsg",
								channel = "swingupcall",
								msg = i,
							})
						else
							celevator.controller.run(pos,{
								type = "remotemsg",
								channel = "upcall",
								msg = i,
							})
						end
					elseif fields[string.format("downcall%d",i)] and cmem.carstate == "normal" and not cmem.capturesw then
						if cmem.params.groupmode == "group" then
							celevator.controller.run(pos,{
								type = "remotemsg",
								channel = "swingdncall",
								msg = i,
							})
						else
							celevator.controller.run(pos,{
								type = "remotemsg",
								channel = "dncall",
								msg = i,
							})
						end
					end
				end
				if fields.scrolldown then
					mem.screenpage = math.max(1,mem.screenpage-1)
					mem.scrollfollowscar = false
				elseif fields.scrollup then
					mem.screenpage = math.min(mem.screenpage+1,math.floor((#cmem.params.floornames-1)/10)+1)
					mem.scrollfollowscar = false
				elseif fields.scrollfollowscar then
					mem.scrollfollowscar = (fields.scrollfollowscar == "true")
				end
			end
		end
	end,
	on_timer = function(_,mtos)
		local ram = mtos.bdev:get_app_storage("ram","celevator")
		local loop = {
			["controllerstatus"] = true,
			["dispatcherstatus"] = true,
		}
		return loop[ram.screenstate]
	end,
})
