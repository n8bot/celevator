celevator.dbdkiosk = {}

function celevator.dbdkiosk.checkprot(pos,name)
	if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
		minetest.chat_send_player(name,"Can't open cabinet - cabinet is locked.")
		minetest.record_protection_violation(pos,name)
		return false
	end
	return true
end

function celevator.dbdkiosk.updatefields(pos)
	if minetest.get_node(pos).name ~= "celevator:dbdkiosk" then return end
	local meta = minetest.get_meta(pos)
	local screenstate = meta:get_string("screenstate")
	if screenstate == "connect" then
		meta:set_string("formspec","formspec_version[7]"..
		                           "size[8,5]"..
		                           "field[0.5,0.5;7,1;carid;Dispatcher ID;]"..
		                           "field[0.5,2;7,1;landing;Landing Number;]"..
		                           "button[3,3.5;2,1;save;Save]"
		               )
	elseif screenstate == "main" then
		local landing = meta:get_int("landing")
		local fs = "formspec_version[7]"
		fs = fs.."size[8,14]"
		fs = fs.."label[3,0.5;Please select a floor\\:]"
		local floornames = minetest.deserialize(meta:get_string("floornames"))
		local floorsavailable = minetest.deserialize(meta:get_string("floorsavailable"))
		local showfloors = {}
		for i=1,#floornames,1 do
			if floorsavailable[i] then
				table.insert(showfloors,i)
			end
		end
		local startfloor = (meta:get_int("screenpage")-1)*10+1
		for i=1,10,1 do
			local floornum = showfloors[startfloor+i-1]
			local floorname = floornum and floornames[floornum]
			if floorname and floornum ~= landing then
				fs = fs..string.format("button[2,%f;4,1;floor%d;%s]",12-i,floornum,minetest.formspec_escape(floorname))
			end
		end
		if startfloor > 1 then
			fs = fs.."button[3.75,12.2;0.8,0.8;scrolldown;vvv]"
		end
		if startfloor+9 < #showfloors then
			fs = fs.."button[3.75,1;0.8,0.8;scrollup;^^^]"
		end
		meta:set_string("formspec",fs)
	elseif screenstate == "assignment" then
		local fs = "formspec_version[7]"
		fs = fs.."size[8,14]"
		fs = fs.."label[3,3;Please use elevator]"
		fs = fs.."style_type[label;font_size=*4]"
		fs = fs.."label[3.5,5;"..meta:get_string("assignedcar").."]"
		meta:set_string("formspec",fs)
	elseif screenstate == "error" then
		local fs = "formspec_version[7]"
		fs = fs.."size[8,14]"
		fs = fs.."label[3.5,0.5;ERROR]"
		fs = fs.."label[2.5,3;Could not find a suitable elevator]"
		fs = fs.."label[2.5,3.5;Please try again later]"
		meta:set_string("formspec",fs)
	end
end

function celevator.dbdkiosk.handlefields(pos,_,fields,player)
	local name = player:get_player_name()
	local meta = minetest.get_meta(pos)
	local screenstate = meta:get_string("screenstate")
	if screenstate == "connect" then
		if not (fields.save and celevator.dbdkiosk.checkprot(pos,name)) then return end
		if not (tonumber(fields.carid) and tonumber(fields.landing)) then return end
		local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",fields.carid)))
		if not carinfo then return end
		if not (carinfo.dispatcherpos and celevator.dispatcher.isdispatcher(carinfo.dispatcherpos)) then return end
		local dmem = minetest.deserialize(minetest.get_meta(carinfo.dispatcherpos):get_string("mem"))
		if not dmem then return end
		local floornames = dmem.params.floornames
		local floorsavailable = {}
		for i=1,#floornames,1 do
			floorsavailable[i] = true
		end
		meta:set_string("floornames",minetest.serialize(floornames))
		meta:set_string("floorsavailable",minetest.serialize(floorsavailable))
		meta:set_int("screenpage",1)
		meta:set_string("screenstate","main")
		meta:set_int("carid",tonumber(fields.carid))
		meta:set_int("landing",tonumber(fields.landing))
		celevator.dbdkiosk.updatefields(pos)
	elseif screenstate == "main" then
		for k,v in pairs(fields) do
			if v and string.sub(k,1,5) == "floor" then
				local floor = tonumber(string.sub(k,6,-1))
				if not floor then return end
				local carid = meta:get_int("carid")
				local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
				if not carinfo then return end
				if not (carinfo.dispatcherpos and celevator.dispatcher.isdispatcher(carinfo.dispatcherpos)) then return end
				local dmem = minetest.deserialize(minetest.get_meta(carinfo.dispatcherpos):get_string("mem"))
				if dmem then
					local floornames = dmem.params.floornames
					meta:set_string("floornames",minetest.serialize(floornames))
				end
				local event = {
					type = "dbdkiosk",
					source = minetest.hash_node_position(pos),
					player = name,
					srcfloor = meta:get_int("landing"),
					destfloor = floor,
				}
				celevator.dispatcher.run(carinfo.dispatcherpos,event)
			end
		end
		if fields.scrollup then
			local page = meta:get_int("screenpage")
			meta:set_int("screenpage",page+1)
		elseif fields.scrolldown then
			local page = meta:get_int("screenpage")
			meta:set_int("screenpage",math.max(1,page-1))
		end
		celevator.dbdkiosk.updatefields(pos)
	elseif screenstate == "assignment" or screenstate == "error" then
		meta:set_string("screenstate","main")
		celevator.dbdkiosk.updatefields(pos)
	end
end

function celevator.dbdkiosk.showassignment(pos,assignment)
	local meta = minetest.get_meta(pos)
	if meta:get_string("screenstate") == "main" then
		local carnames = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P"}
		if carnames[assignment] then
			meta:set_string("screenstate","assignment")
			meta:set_string("assignedcar",carnames[assignment])
		else
			meta:set_string("screenstate","error")
		end
		celevator.dbdkiosk.updatefields(pos)
		minetest.after(5,function()
			meta:set_string("screenstate","main")
			celevator.dbdkiosk.updatefields(pos)
		end)
	end
end

minetest.register_node("celevator:dbdkiosk",{
	description = "Elevator Destination Entry Kiosk",
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "4dir",
	groups = {
		cracky = 1,
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.2,-0.5,0.4,0.2,0.1,0.5},
		},
	},
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png^celevator_dbdkiosk.png",
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("screenstate","connect")
		celevator.dbdkiosk.updatefields(pos)
	end,
	on_receive_fields = celevator.dbdkiosk.handlefields,
})
