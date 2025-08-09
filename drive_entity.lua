celevator.drives.entity = {
	name = "Drive",
	description = "Normal entity-based drive",
	nname = "celevator:drive",
	buzzsoundhandles = {},
	movementsoundhandles = {},
	movementsoundstate = {},
	carsoundhandles = {},
	carsoundstate = {},
	entityinfo = {},
	sheaverefs = {},
	step_enabled = true, --Not a setting, is overwritten on globalstep, true here to check for running drives on startup
}

local playerposlimits = {}

local function update_ui(pos)
	local meta = minetest.get_meta(pos)
	local apos = tonumber(meta:get_string("apos")) or 0
	local status = "Idle"
	local vel = tonumber(meta:get_string("vel")) or 0
	local state = meta:get_string("state")
	if state == "running" and vel > 0 then
		status = string.format("Running: Up, %0.02f m/s",vel)
	elseif state == "running" and vel < 0 then
		status = string.format("Running: Down, %0.02f m/s",math.abs(vel))
	elseif state == "fakerunning" and vel > 0 then
		status = string.format("Running (simulated): Up, %0.02f m/s",vel)
	elseif state == "fakerunning" and vel < 0 then
		status = string.format("Running (simulated): Down, %0.02f m/s",math.abs(vel))
	end
	meta:set_string("infotext",string.format("Drive - %s - Position: %0.02f m",status,apos))
end

local function playbuzz(pos)
	local hash = minetest.hash_node_position(pos)
	if celevator.drives.entity.buzzsoundhandles[hash] == "cancel" then return end
	celevator.drives.entity.buzzsoundhandles[hash] = minetest.sound_play("celevator_drive_run",{
		pos = pos,
		loop = true,
		gain = 0.1,
	})
end

local function startbuzz(pos)
	local hash = minetest.hash_node_position(pos)
	if celevator.drives.entity.buzzsoundhandles[hash] == "cancel" then
		celevator.drives.entity.buzzsoundhandles[hash] = nil
		return
	end
	if celevator.drives.entity.buzzsoundhandles[hash] then return end
	celevator.drives.entity.buzzsoundhandles[hash] = "pending"
	minetest.after(0.5,playbuzz,pos)
end

local function stopbuzz(pos)
	local hash = minetest.hash_node_position(pos)
	if not celevator.drives.entity.buzzsoundhandles[hash] then return end
	if celevator.drives.entity.buzzsoundhandles[hash] == "pending" then
		celevator.drives.entity.buzzsoundhandles[hash] = "cancel"
	end
	if type(celevator.drives.entity.buzzsoundhandles[hash]) ~= "string" then
		minetest.sound_stop(celevator.drives.entity.buzzsoundhandles[hash])
		celevator.drives.entity.buzzsoundhandles[hash] = nil
	end
end

local function motorsound(pos,newstate)
	local hash = minetest.hash_node_position(pos)
	local oldstate = celevator.drives.entity.movementsoundstate[hash]
	oldstate = oldstate or "idle"
	if oldstate == newstate then return end
	local carid = minetest.get_meta(pos):get_int("carid")
	local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not (carinfo and carinfo.machinepos) then return end
	local oldhandle = celevator.drives.entity.movementsoundhandles[hash]
	if newstate == "slow" then
		if oldstate == "idle" then
			minetest.sound_play("celevator_brake_release",{
				pos = carinfo.machinepos,
				gain = 1,
			},true)
			celevator.drives.entity.movementsoundhandles[hash] = minetest.sound_play("celevator_motor_slow",{
				pos = carinfo.machinepos,
				loop = true,
				gain = 1,
			})
		elseif oldstate == "accel" or oldstate == "fast" or oldstate == "decel" then
			if oldhandle then minetest.sound_stop(oldhandle) end
			celevator.drives.entity.movementsoundhandles[hash] = minetest.sound_play("celevator_motor_slow",{
				pos = carinfo.machinepos,
				loop = true,
				gain = 1,
			})
		end
	elseif newstate == "accel" then
		if oldhandle then minetest.sound_stop(oldhandle) end
		celevator.drives.entity.movementsoundhandles[hash] = minetest.sound_play("celevator_motor_accel",{
			pos = carinfo.machinepos,
			gain = 1,
		})
	elseif newstate == "fast" then
		if oldhandle then minetest.sound_stop(oldhandle) end
		celevator.drives.entity.movementsoundhandles[hash] = minetest.sound_play("celevator_motor_fast",{
			pos = carinfo.machinepos,
			loop = true,
			gain = 1,
		})
	elseif newstate == "decel" then
		if oldhandle then minetest.sound_stop(oldhandle) end
		celevator.drives.entity.movementsoundhandles[hash] = minetest.sound_play("celevator_motor_decel",{
			pos = carinfo.machinepos,
			gain = 1,
		})
	elseif newstate == "idle" then
		if oldhandle then minetest.sound_stop(oldhandle) end
		minetest.sound_play("celevator_brake_apply",{
			pos = carinfo.machinepos,
			gain = 1,
		},true)
	end
	celevator.drives.entity.movementsoundstate[hash] = newstate
end

local function carsound(pos,newstate,speed)
	if speed < 0.5 then return end
	local hash = minetest.hash_node_position(pos)
	local oldstate = celevator.drives.entity.carsoundstate[hash]
	oldstate = oldstate or "idle"
	if oldstate == newstate then return end
	if not celevator.drives.entity.entityinfo[hash] then return end
	local eref = celevator.drives.entity.entityinfo[hash].handles[1]
	if not eref:get_pos() then return end
	local oldhandle = celevator.drives.entity.carsoundhandles[hash]
	local gain = math.min(1,speed/6)
	if newstate == "accel" then
		if oldhandle then minetest.sound_stop(oldhandle) end
		celevator.drives.entity.carsoundhandles[hash] = minetest.sound_play("celevator_car_start",{
			object = eref,
			gain = gain,
		})
		minetest.after(3,function()
			if celevator.drives.entity.carsoundstate[hash] == "accel" then
				carsound(pos,"run",speed)
			end
		end)
	elseif newstate == "run" then
		if oldhandle then minetest.sound_stop(oldhandle) end
		celevator.drives.entity.carsoundhandles[hash] = minetest.sound_play("celevator_car_run",{
			object = eref,
			loop = true,
			gain = gain,
		})
	elseif newstate == "decel" then
		if oldhandle then minetest.sound_stop(oldhandle) end
		celevator.drives.entity.carsoundhandles[hash] = minetest.sound_play("celevator_car_stop",{
			object = eref,
			gain = gain,
		})
	elseif newstate == "stopped" then
		if oldhandle then minetest.sound_stop(oldhandle) end
	end
	celevator.drives.entity.carsoundstate[hash] = newstate
end

local function compareexchangesound(pos,compare,new)
	local hash = minetest.hash_node_position(pos)
	local oldstate = celevator.drives.entity.movementsoundstate[hash]
	if oldstate == compare then
		motorsound(pos,new)
	end
end

local function accelsound(pos)
	motorsound(pos,"slow")
	minetest.after(1,compareexchangesound,pos,"slow","accel")
	minetest.after(4,compareexchangesound,pos,"accel","fast")
end

local function decelsound(pos)
	motorsound(pos,"decel")
	minetest.after(2,compareexchangesound,pos,"decel","slow")
end

minetest.register_node("celevator:drive",{
	description = "Elevator "..celevator.drives.entity.name,
	groups = {
		cracky = 1,
		_celevator_drive = 1,
	},
	tiles = {
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_cabinet_sides.png",
		"celevator_drive_front.png",
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4,-0.4,-0.1,0.4,0.4,0.5},
			{-0.5,-0.3,0.4,-0.4,-0.22,0.32},
			{-0.5,0.22,0.4,-0.4,0.3,0.32},
		},
	},
	_celevator_drive_type = "entity",
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("apos","0")
		meta:set_string("dpos","0")
		meta:set_string("vel","0")
		meta:set_string("maxvel","0.2")
		meta:set_string("state","uninit")
		meta:set_string("startpos","0")
		meta:set_string("doorstate","closed")
		meta:mark_as_private({"apos","dpos","vel","maxvel","state","startpos","doorstate"})
		update_ui(pos)
	end,
	on_destruct = stopbuzz,
})

minetest.register_entity("celevator:car_moving",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.667,0.667,0.667),
		wield_item = "default:dirt",
		static_save = false,
		glow = minetest.LIGHT_MAX,
		pointable = false,
	},
})

minetest.register_entity("celevator:player_holder",{
	initial_properties = {
		visual = "cube",
		textures = {
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
		},
		--I have no idea where this magic number comes from, but it seems about right and that's good enough
		visual_size = vector.new(3,3,3),
		static_save = false,
		pointable = false,
	},
	on_step = function(self,dtime)
		local obj = self.object
		local car,_,attachoffset = obj:get_attach()
		if not car then
			obj:remove()
			return
		end
		local children = obj:get_children()
		local player
		for _,i in pairs(children) do
			if i:is_player() then
				player = i
			end
		end
		if not player then return end
		local caryaw = car:get_yaw()
		local playeryaw = player:get_look_horizontal()
		local attachrot = vector.new(0,(caryaw-playeryaw)*57.296,0)
		local control = player:get_player_control()
		if (control.up or control.down or control.left or control.right) then
			local walkspeed = 120
			local walkamount = walkspeed*dtime
			local displacement = vector.new(0,0,0)
			if control.up then
				displacement = vector.add(displacement,vector.new(0,0,walkamount))
			end
			if control.down then
				displacement = vector.add(displacement,vector.new(0,0,0-walkamount))
			end
			if control.left then
				displacement = vector.add(displacement,vector.new(0-walkamount,0,0))
			end
			if control.right then
				displacement = vector.add(displacement,vector.new(walkamount,0,0))
			end
			displacement = vector.rotate_around_axis(displacement,vector.new(0,1,0),playeryaw)
			displacement = vector.rotate_around_axis(displacement,vector.new(0,-1,0),caryaw)
			local oldattachoffset = vector.copy(attachoffset)
			attachoffset = vector.add(attachoffset,displacement)
			local realattachoffset = vector.rotate_around_axis(vector.multiply(attachoffset,1/30),vector.new(0,1,0),caryaw)
			local newpos = vector.add(car:get_pos(),realattachoffset)
			local limits = playerposlimits[player:get_player_name()] or {}
			if limits.xmin and limits.xmax and limits.xmin < limits.xmax then
				if newpos.x > limits.xmax or newpos.x < limits.xmin then
					attachoffset = oldattachoffset
				end
			end
			if limits.zmin and limits.zmax and limits.zmin < limits.zmax then
				if newpos.z > limits.zmax or newpos.z < limits.zmin then
					attachoffset = oldattachoffset
				end
			end
		end
		obj:set_attach(car,"",attachoffset,vector.new(0,0,0))
		player:set_attach(obj,"",vector.new(0,0,0),attachrot)
	end,
})

function celevator.drives.entity.gathercar(pos,yaw,nodes)
	if not nodes then nodes = {} end
	local hash = minetest.hash_node_position(pos)
	if nodes[hash] then return nodes end
	nodes[hash] = true
	if minetest.get_item_group(celevator.get_node(pos).name,"_connects_xp") == 1 then
		celevator.drives.entity.gathercar(vector.add(pos,vector.rotate_around_axis(vector.new(1,0,0),vector.new(0,1,0),yaw)),yaw,nodes)
	end
	if minetest.get_item_group(celevator.get_node(pos).name,"_connects_xm") == 1 then
		celevator.drives.entity.gathercar(vector.add(pos,vector.rotate_around_axis(vector.new(-1,0,0),vector.new(0,1,0),yaw)),yaw,nodes)
	end
	if minetest.get_item_group(celevator.get_node(pos).name,"_connects_yp") == 1 then
		celevator.drives.entity.gathercar(vector.add(pos,vector.new(0,1,0)),yaw,nodes)
	end
	if minetest.get_item_group(celevator.get_node(pos).name,"_connects_ym") == 1 then
		celevator.drives.entity.gathercar(vector.add(pos,vector.new(0,-1,0)),yaw,nodes)
	end
	if minetest.get_item_group(celevator.get_node(pos).name,"_connects_zp") == 1 then
		celevator.drives.entity.gathercar(vector.add(pos,vector.rotate_around_axis(vector.new(0,0,1),vector.new(0,1,0),yaw)),yaw,nodes)
	end
	if minetest.get_item_group(celevator.get_node(pos).name,"_connects_zm") == 1 then
		celevator.drives.entity.gathercar(vector.add(pos,vector.rotate_around_axis(vector.new(0,0,-1),vector.new(0,1,0),yaw)),yaw,nodes)
	end
	return nodes
end

function celevator.drives.entity.nodestoentities(nodes,ename)
	local refs = {}
	local xmin = 32000
	local xmax = -32000
	local zmin = 32000
	local zmax = -32000
	for _,pos in ipairs(nodes) do
		if pos.x < xmin then xmin = pos.x end
		if pos.x > xmax then xmax = pos.x end
		if pos.z < zmin then zmin = pos.z end
		if pos.z > zmax then zmax = pos.z end
	end
	for _,pos in ipairs(nodes) do
		local node = celevator.get_node(pos)
		local attach = minetest.get_objects_inside_radius(pos,0.9)
		local eref = minetest.add_entity(pos,(ename or "celevator:car_moving"))
		eref:set_properties({
			wield_item = node.name,
		})
		eref:set_yaw(minetest.dir_to_yaw(minetest.fourdir_to_dir(node.param2)))
		table.insert(refs,eref)
		local ndef = minetest.registered_nodes[node.name] or {}
		if ndef._cartopbox or ndef._tapehead then
			local toppos = vector.add(pos,vector.new(0,1,0))
			local topattach = minetest.get_objects_inside_radius(toppos,0.75)
			for _,ref in pairs(topattach) do
				table.insert(attach,ref)
			end
		end
		if not ename then --If ename is set, something other than the car is moving
			for _,attachref in ipairs(attach) do
				local included = {
					["celevator:incar_pi_entity"] = true,
					["celevator:car_top_box"] = true,
					["celevator:car_door"] = true,
					["celevator:tapehead"] = true,
				}
				if attachref:get_luaentity() and included[attachref:get_luaentity().name] then
					table.insert(refs,attachref)
				elseif attachref:is_player() then
					local attachpos = attachref:get_pos()
					local basepos = eref:get_pos()
					local attachoffset = vector.subtract(attachpos,basepos)
					attachoffset = vector.rotate_around_axis(attachoffset,vector.new(0,-1,0),eref:get_yaw())
					local holder = minetest.add_entity(attachpos,"celevator:player_holder")
					holder:set_attach(eref,"",vector.multiply(attachoffset,30),vector.new(0,0,0))
					attachref:set_attach(holder,"")
					local extra = 0.25 --To allow getting closer to walls
					playerposlimits[attachref:get_player_name()] = {
						xmin = xmin-extra,
						xmax = xmax+extra,
						zmin = zmin-extra,
						zmax = zmax+extra,
					}
				else
					local attachpos = attachref:get_pos()
					local basepos = eref:get_pos()
					local attachoffset = vector.subtract(attachpos,basepos)
					attachoffset = vector.rotate_around_axis(attachoffset,vector.new(0,-1,0),eref:get_yaw())
					attachref:set_attach(eref,"",vector.multiply(attachoffset,30),vector.new(0,0,0))
				end
			end
		end
		minetest.remove_node(pos)
	end
	return refs
end

function celevator.drives.entity.entitiestonodes(refs,carid)
	local ok = true
	for _,eref in ipairs(refs) do
		local pos = eref:get_pos()
		local top = false
		local ename = eref:get_luaentity() and eref:get_luaentity().name
		if pos and (ename == "celevator:car_moving" or ename == "celevator:hwdoor_moving") then
			pos = vector.round(pos)
			local node = {
				name = eref:get_properties().wield_item,
				param2 = minetest.dir_to_fourdir(minetest.yaw_to_dir(eref:get_yaw()))
			}
			if minetest.get_item_group(eref:get_properties().wield_item,"_connects_yp") ~= 1 then top = true end
			minetest.set_node(pos,node)
			eref:remove()
			if carid then celevator.get_meta(pos):set_int("carid",carid) end
		elseif pos and ename == "celevator:incar_pi_entity" then
			pos = vector.new(pos.x,math.floor(pos.y+0.5),pos.z)
			eref:set_pos(pos)
		elseif not ok then
			eref:remove()
		else
			if not pos then ok = false end
		end
		if pos and ename == "celevator:car_moving" then
			local rounded = {
				["celevator:car_top_box"] = true,
				["celevator:car_door"] = true,
				["celevator:tapehead"] = true,
			}
			for _,i in ipairs(minetest.get_objects_inside_radius(pos,0.9)) do
				i:set_velocity(vector.new(0,0,0))
				if i:is_player() then
					local ppos = i:get_pos()
					ppos.y=ppos.y-0.48
					if top then ppos.y = ppos.y+1.02 end
					i:set_pos(ppos)
					minetest.after(0.5,function()
						if not i:is_player() then return end
						local newpos = i:get_pos()
						newpos.y = math.max(newpos.y,ppos.y)
						i:set_pos(newpos)
					end)
				elseif i:get_luaentity() and rounded[i:get_luaentity().name] then
					local epos = i:get_pos()
					epos.y = math.floor(epos.y+0.5)
					if i:get_luaentity() and i:get_luaentity().name == "celevator:car_top_box" then
						epos.y = epos.y+0.1
					end
					i:set_pos(epos)
				end
			end
		end
	end
	return ok
end

function celevator.drives.entity.step(dtime)
	if not celevator.drives.entity.step_enabled then return end
	local entitydrives_running = minetest.deserialize(celevator.storage:get_string("entitydrives_running")) or {}
	local save = false
	for i,hash in ipairs(entitydrives_running) do
		save = true
		local pos = minetest.get_position_from_hash(hash)
		local node = celevator.get_node(pos)
		local sound = false
		if node.name == "ignore" then
			minetest.forceload_block(pos,true)
		elseif node.name ~= "celevator:drive" then
			table.remove(entitydrives_running,i)
		else
			local meta = celevator.get_meta(pos)
			local carid = meta:get_int("carid")
			local state = meta:get_string("state")
			if not (state == "running" or state == "start" or state == "fakerunning") then
				table.remove(entitydrives_running,i)
			else
				local dpos = tonumber(meta:get_string("dpos")) or 0
				local maxvel = tonumber(meta:get_string("maxvel")) or 0.2
				local startpos = tonumber(meta:get_string("startpos")) or 0
				local oldvel = tonumber(meta:get_string("vel")) or 0
				local inspection = meta:get_int("inspection") == 1
				local origin = minetest.string_to_pos(meta:get_string("origin"))
				if not origin then
					minetest.log("error","[celevator] [entity drive] Invalid origin for drive at "..minetest.pos_to_string(pos))
					meta:set_string("fault","badorigin")
					table.remove(entitydrives_running,i)
					return
				end
				if state == "start" then
					if math.abs(dpos-startpos) > 0.1 then
						sound = true
						if not inspection then
							accelsound(pos)
						else
							motorsound(pos,"slow")
						end
					end
					local startv = vector.add(origin,vector.new(0,startpos,0))
					local hashes = celevator.drives.entity.gathercar(startv,minetest.dir_to_yaw(minetest.fourdir_to_dir(celevator.get_node(startv).param2)))
					local nodes = {}
					for carhash in pairs(hashes) do
						local carpos = minetest.get_position_from_hash(carhash)
						if vector.equals(startv,carpos) then
							table.insert(nodes,1,carpos) --0,0,0 node must be first in the list
						else
							table.insert(nodes,carpos)
						end
					end
					local carparam2 = celevator.get_node(nodes[1]).param2
					local cardef = minetest.registered_nodes[celevator.get_node(nodes[1]).name] or {}
					local cartype = cardef._celevator_car_type or "standard"
					local carmeta = celevator.get_meta(startv)
					meta:set_int("carparam2",carparam2)
					meta:set_string("cartype",cartype)
					meta:set_string("doortype",carmeta:get_string("doortype"))
					local handles = celevator.drives.entity.nodestoentities(nodes)
					celevator.drives.entity.entityinfo[hash] = {
						handles = handles,
					}
					carsound(pos,"accel",maxvel)
					meta:set_string("state","running")
					celevator.drives.entity.sheavetoentity(carid)
				elseif state == "running" then
					if not celevator.drives.entity.entityinfo[hash] then
						meta:set_string("state","fakerunning")
						return
					end
					local handles = celevator.drives.entity.entityinfo[hash].handles
					if (not handles) or (not handles[1]:get_pos()) then
						meta:set_string("state","fakerunning")
						return
					end
					local apos = handles[1]:get_pos().y - origin.y
					local sheaverefs = celevator.drives.entity.sheaverefs[carid]
					if sheaverefs and sheaverefs[1] then
						local rotation = sheaverefs[1]:get_rotation()
						if rotation then
							rotation.z = math.pi*apos*-1
							sheaverefs[1]:set_rotation(rotation)
						end
					end
					local dremain = math.abs(dpos-apos)
					local dmoved = math.abs(apos-startpos)
					local vel
					local relevel = (dpos < apos and oldvel > 0) or (dpos > apos and oldvel < 0)
					if dremain < 0.01 or (inspection and relevel) then
						vel = 0
						meta:set_string("state","stopped")
						motorsound(pos,"idle")
						celevator.drives.entity.sheavetonode(carid)
						local ok = celevator.drives.entity.entitiestonodes(handles,carid)
						local doortype = meta:get_string("doortype")
						if (not doortype) or doortype == "" then doortype = "glass" end
						local spawnpos = vector.round(vector.add(origin,vector.new(0,apos,0)))
						if not ok then
							local carparam2 = meta:get_int("carparam2")
							local cartype = meta:get_string("cartype")
							celevator.car.spawncar(spawnpos,minetest.dir_to_yaw(minetest.fourdir_to_dir(carparam2)),carid,cartype,doortype)
						else
							celevator.get_meta(spawnpos):set_string("doortype",doortype)
						end
						apos = math.floor(apos+0.5)
						minetest.after(0.25,celevator.drives.entity.updatecopformspec,pos)
						table.remove(entitydrives_running,i)
					elseif dremain < 0.1 and not inspection then
						vel = 0.1
					elseif dremain < 2*maxvel and dremain < dmoved and not inspection then
						vel = math.min(dremain,maxvel)
						if celevator.drives.entity.movementsoundstate[hash] == "fast" or celevator.drives.entity.movementsoundstate[hash] == "accel" then
							decelsound(pos)
							carsound(pos,"decel",maxvel)
						end
					elseif dmoved+0.1 > maxvel or inspection then
						vel = maxvel
					else
						vel = dmoved+0.1
					end
					if dpos < apos then vel = 0-vel end
					for _,eref in ipairs(handles) do
						eref:set_velocity(vector.new(0,vel,0))
					end
					meta:set_string("apos",tostring(apos))
					sound = vel ~= 0
					meta:set_string("vel",tostring(vel))
				elseif state == "fakerunning" then
					celevator.drives.entity.carsoundstate[hash] = "stopped"
					local apos = tonumber(meta:get_string("apos")) or 0
					local sheaverefs = celevator.drives.entity.sheaverefs[carid]
					if sheaverefs and sheaverefs[1] then
						local rotation = sheaverefs[1]:get_rotation()
						if rotation then
							rotation.z = math.pi*apos*-1
							sheaverefs[1]:set_rotation(rotation)
						end
					end
					local dremain = math.abs(dpos-apos)
					local dmoved = math.abs(apos-startpos)
					local vel
					local relevel = (dpos < apos and oldvel > 0) or (dpos > apos and oldvel < 0)
					if dremain < 0.01 or (relevel and inspection) then
						vel = 0
						meta:set_string("state","stopped")
						motorsound(pos,"idle")
						celevator.drives.entity.sheavetonode(carid)
						local carparam2 = meta:get_int("carparam2")
						local cartype = meta:get_string("cartype")
						local doortype = meta:get_string("doortype")
						if (not doortype) or doortype == "" then doortype = "glass" end
						local spawnpos = vector.round(vector.add(origin,vector.new(0,apos,0)))
						celevator.car.spawncar(spawnpos,minetest.dir_to_yaw(minetest.fourdir_to_dir(carparam2)),carid,cartype,doortype)
						apos = math.floor(apos+0.5)
						minetest.after(0.25,celevator.drives.entity.updatecopformspec,pos)
						table.remove(entitydrives_running,i)
					elseif dremain < 0.1 and not inspection then
						vel = 0.1
					elseif dremain < 2*maxvel and dremain < dmoved and not inspection then
						vel = math.min(dremain,maxvel)
						if celevator.drives.entity.movementsoundstate[hash] == "fast" or celevator.drives.entity.movementsoundstate[hash] == "accel" then
							decelsound(pos)
						end
					elseif dmoved+0.1 > maxvel or inspection then
						vel = maxvel
					else
						vel = dmoved+0.1
					end
					if dpos < apos then vel = 0-vel end
					apos = apos+(vel*dtime)
					meta:set_string("apos",tostring(apos))
					sound = vel ~= 0
					meta:set_string("vel",tostring(vel))
				end
			end
		end
		update_ui(pos)
		if sound then
			startbuzz(pos)
		else
			stopbuzz(pos)
		end
	end
	if save then
		celevator.storage:set_string("entitydrives_running",minetest.serialize(entitydrives_running))
	end
	celevator.drives.entity.step_enabled = save
end

minetest.register_globalstep(celevator.drives.entity.step)

function celevator.drives.entity.moveto(pos,target,inspection)
	local meta = celevator.get_meta(pos)
	meta:mark_as_private({"apos","dpos","vel","maxvel","state","startpos","doorstate"})
	local carid = celevator.get_meta(pos):get_int("carid")
	local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not (carinfo and carinfo.machinepos and celevator.get_node(carinfo.machinepos).name == "celevator:machine") then
		meta:set_string("fault","nomachine")
		return
	end
	if not carinfo.controllerpos then return end
	local controllermeta = celevator.get_meta(carinfo.controllerpos)
	if controllermeta:get_int("carid") ~= carid then
		meta:set_string("fault","controllermismatch")
		return
	end
	local machinemeta = celevator.get_meta(carinfo.machinepos)
	if machinemeta:get_int("carid") ~= carid then
		meta:set_string("fault","machinemismatch")
		return
	end
	local origin = minetest.string_to_pos(meta:get_string("origin"))
	if not origin then
		minetest.log("error","[celevator] [entity drive] Invalid origin for drive at "..minetest.pos_to_string(pos))
		meta:set_string("fault","badorigin")
		return
	end
	if target < 0 or origin.y + target > (carinfo.machinepos.y-3) then
		meta:set_string("fault","outofbounds")
		return
	end
	if meta:get_string("state") ~= "stopped" then
		local apos = tonumber(meta:get_string("apos"))
		local vel = tonumber(meta:get_string("vel"))
		if vel > 0 then
			if target < apos+(vel*2) and not inspection then return end
		elseif vel < 0 then
			if target > apos-(vel*-2) and not inspection then return end
		else
			return
		end
	end
	meta:set_string("dpos",tostring(target))
	if meta:get_string("state") == "stopped" then
		meta:set_string("state","start")
		meta:set_int("inspection",inspection and 1 or 0)
		meta:set_string("startpos",meta:get_string("apos"))
		local hash = minetest.hash_node_position(pos)
		local entitydrives_running = minetest.deserialize(celevator.storage:get_string("entitydrives_running")) or {}
		local running = false
		for _,dhash in ipairs(entitydrives_running) do
			if hash == dhash then
				running = true
				break
			end
		end
		if not running then
			celevator.drives.entity.step_enabled = true
			table.insert(entitydrives_running,hash)
			celevator.storage:set_string("entitydrives_running",minetest.serialize(entitydrives_running))
			--Controller needs to see something so it knows the drive is running
			local apos = tonumber(meta:get_string("apos"))
			if apos and apos > target then
				meta:set_string("vel","-0.0001")
			else
				meta:set_string("vel","0.0001")
			end
		end
	end
end


function celevator.drives.entity.resetpos(pos)
	celevator.drives.entity.moveto(pos,0)
end

function celevator.drives.entity.estop(pos)
	local meta = celevator.get_meta(pos)
	if meta:get_string("state") ~= "running" then return end
	local apos = math.floor(tonumber(meta:get_string("apos"))+0.5)
	meta:set_string("dpos",tostring(apos))
	meta:set_string("apos",tostring(apos))
	local hash = minetest.hash_node_position(pos)
	local handles = celevator.drives.entity.entityinfo[hash].handles
	meta:set_string("state","stopped")
	meta:set_string("vel","0")
	local carid = meta:get_int("carid")
	celevator.drives.entity.entitiestonodes(handles,carid)
	stopbuzz(pos)
	motorsound(pos,"idle")
	if carid ~= 0 then celevator.drives.entity.sheavetonode(carid) end
	minetest.after(0.25,celevator.drives.entity.updatecopformspec,pos)
end


function celevator.drives.entity.setmaxvel(pos,maxvel)
	local meta = celevator.get_meta(pos)
	meta:set_string("maxvel",tostring(maxvel))
end


function celevator.drives.entity.rezero(pos)
	celevator.drives.entity.moveto(pos,0)
end

function celevator.drives.entity.getstatus(pos,call2)
	local node = minetest.get_node(pos)
	if node.name == "ignore" and not call2 then
		minetest.forceload_block(pos,true)
		return celevator.drives.entity.get_status(pos,true)
	elseif node.name ~= "celevator:drive" then
		minetest.log("error","[celevator] [entity drive] Could not load drive status at "..minetest.pos_to_string(pos))
		return {fault = "metaload"}
	else
		local meta = celevator.get_meta(pos)
		local ret = {}
		ret.apos = tonumber(meta:get_string("apos")) or 0
		ret.dpos = tonumber(meta:get_string("dpos")) or 0
		ret.vel = tonumber(meta:get_string("vel")) or 0
		ret.maxvel = tonumber(meta:get_string("maxvel")) or 0.2
		ret.state = meta:get_string("state")
		ret.doorstate = meta:get_string("doorstate")
		ret.fault = meta:get_string("fault")
		ret.neareststop = ret.apos+(ret.vel*2)
		if ret.fault == "" then ret.fault = nil end
		return ret
	end
end

function celevator.drives.entity.movedoors(drivepos,direction,nudge)
	local drivehash = minetest.hash_node_position(drivepos)
	local entitydrives_running = minetest.deserialize(celevator.storage:get_string("entitydrives_running")) or {}
	local drivemeta = celevator.get_meta(drivepos)
	for _,hash in pairs(entitydrives_running) do
		if drivehash == hash then
			minetest.log("error","[celevator] [entity drive] Attempted to open doors while drive at "..minetest.pos_to_string(drivepos).." was still moving")
			drivemeta:set_string("fault","doorinterlock")
			return
		end
	end
	local origin = minetest.string_to_pos(drivemeta:get_string("origin"))
	if not origin then
		minetest.log("error","[celevator] [entity drive] Invalid origin for drive at "..minetest.pos_to_string(drivepos))
		drivemeta:set_string("fault","badorigin")
		return
	end
	local apos = tonumber(drivemeta:get_string("apos")) or 0
	local carpos = vector.add(origin,vector.new(0,apos,0))
	local carnode = celevator.get_node(carpos)
	local hwdoorpos = vector.add(carpos,vector.rotate_around_axis(minetest.fourdir_to_dir(carnode.param2),vector.new(0,1,0),math.pi))
	local isroot = minetest.get_item_group(celevator.get_node(hwdoorpos).name,"_celevator_hwdoor_root") == 1
	if direction == "open" and (isroot or drivemeta:get_string("doorstate") == "closing") then
		celevator.doors.hwopen(hwdoorpos,drivepos)
		drivemeta:set_string("doorstate","opening")
	elseif direction == "close" and celevator.get_node(hwdoorpos).name == "celevator:hwdoor_placeholder" then
		celevator.doors.hwclose(hwdoorpos,drivepos,nudge)
		drivemeta:set_string("doorstate","closing")
	end
end

function celevator.drives.entity.resetfault(pos)
	celevator.get_meta(pos):set_string("fault","")
end

function celevator.drives.entity.pibeep(drivepos)
	local drivemeta = celevator.get_meta(drivepos)
	local origin = minetest.string_to_pos(drivemeta:get_string("origin"))
	if not origin then
		minetest.log("error","[celevator] [entity drive] Invalid origin for drive at "..minetest.pos_to_string(drivepos))
		drivemeta:set_string("fault","badorigin")
		return
	end
	local apos = tonumber(drivemeta:get_string("apos")) or 0
	local beeppos = vector.add(origin,vector.new(0,apos+2,0))
	minetest.sound_play("celevator_pi_beep",{
		pos = beeppos,
		gain = 1,
	},true)
end

local function carsearch(pos)
	for i=1,500,1 do
		local searchpos = vector.subtract(pos,vector.new(0,i,0))
		local node = celevator.get_node(searchpos)
		if minetest.get_item_group(node.name,"_celevator_car") == 1 then
			local yaw = minetest.dir_to_yaw(minetest.fourdir_to_dir(node.param2))
			local offsettext = minetest.registered_nodes[node.name]._position
			local xoffset = tonumber(string.sub(offsettext,1,1))
			local yoffset = tonumber(string.sub(offsettext,2,2))
			local zoffset = tonumber(string.sub(offsettext,3,3))
			local offset = vector.new(xoffset,yoffset,zoffset)
			offset = vector.rotate_around_axis(offset,vector.new(0,1,0),yaw)
			return vector.subtract(searchpos,offset)
		end
	end
end

local function updatecarpos(pos)
	local meta = celevator.get_meta(pos)
	if meta:get_int("carid") == 0 then return end
	local carpos = carsearch(pos)
	if carpos then
		meta:set_string("origin",minetest.pos_to_string(carpos))
		celevator.get_meta(carpos):set_string("machinepos",minetest.pos_to_string(pos))
		meta:set_string("infotext",string.format("Using car with origin %s",minetest.pos_to_string(carpos)))
		local carid = meta:get_int("carid")
		local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
		if not (carinfo and carinfo.controllerpos) then return end
		carinfo.origin = carpos
		celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
		local drivepos = celevator.controller.finddrive(carinfo.controllerpos)
		if drivepos then
			local drivemeta = celevator.get_meta(drivepos)
			if drivemeta:get_string("state") == "uninit" then
				drivemeta:set_string("origin",minetest.pos_to_string(carpos))
				drivemeta:set_string("state","stopped")
				drivemeta:set_int("carid",carid)
			end
		end
		local caryaw = minetest.dir_to_yaw(minetest.fourdir_to_dir(celevator.get_node(carpos).param2))
		local carnodes = celevator.drives.entity.gathercar(carpos,caryaw)
		for hash in pairs(carnodes) do
			local carmeta = celevator.get_meta(minetest.get_position_from_hash(hash))
			carmeta:set_int("carid",carid)
		end
	else
		meta:set_string("infotext","No car found! Punch to try again")
	end
end

minetest.register_node("celevator:machine",{
	description = "Elevator Hoist Machine",
	groups = {
		dig_immediate = 2,
		_celevator_machine = 1,
	},
	paramtype = "light",
	paramtype2 = "4dir",
	tiles = {
		"celevator_machine_top.png",
		"celevator_machine_top.png",
		"celevator_machine_sides.png",
		"celevator_machine_sides.png",
		"celevator_machine_front.png",
		"celevator_machine_front.png",
	},
	inventory_image = "celevator_machine_inventory.png",
	wield_image = "celevator_machine_inventory.png",
	wield_scale = vector.new(1,1,3),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.3,-0.5,-0.2,0.3,0.4,0.2}, -- Main body
			{-0.2,0.4,-0.2,0.2,0.5,0.2}, -- Top of circle
			{-0.4,-0.1,-0.2,-0.3,0.3,0.2}, -- Left of circle
			{0.3,-0.1,-0.2,0.4,0.3,0.2}, -- Right of circle
			{-0.42,0.075,-0.22,0.42,0.125,0.22}, -- Sealing flanges
			{0.3,-0.3,-0.1,0.35,-0.1,0.1}, -- Bearing cap opposite motor
			{-0.35,-0.3,-0.1,-0.3,-0.1,0.1}, -- Bearing cap on motor side
			{-0.1,0,-0.5,0.1,0.2,-0.2}, -- Shaft to sheave
			{-0.15,-0.05,0.2,0.15,0.25,0.25}, -- Bearing cap opposite sheave
			{-0.15,-0.05,-0.25,0.15,0.25,-0.2}, -- Bearing cap on sheave side
			{-0.5,-0.25,-0.05,-0.35,-0.15,0.05} -- Shaft from motor
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-1.5,-0.5,-0.5,0.5,0.5,0.5},
			{-0.5,-0.5,-0.8,0.5,0.5,-0.5},
		},
	},
	after_place_node = function(pos,player)
		if not player:is_player() then
			minetest.remove_node(pos)
			return true
		end
		local newnode = minetest.get_node(pos)
		local facedir = minetest.dir_to_yaw(minetest.fourdir_to_dir(newnode.param2))
		local motorpos = vector.add(pos,vector.rotate_around_axis(vector.new(-1,0,0),vector.new(0,1,0),facedir))
		local motorreplaces = minetest.get_node(motorpos).name
		local sheavepos = vector.add(pos,vector.rotate_around_axis(vector.new(0,0,-1),vector.new(0,1,0),facedir))
		local sheavereplaces = minetest.get_node(sheavepos).name
		local name = player:get_player_name()
		if not (minetest.registered_nodes[motorreplaces] and minetest.registered_nodes[motorreplaces].buildable_to) then
			minetest.chat_send_player(name,"Can't place machine here - no room for the motor (to the left)!")
			minetest.remove_node(pos)
			return true
		end
		if minetest.is_protected(motorpos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
			minetest.chat_send_player(name,"Can't place machine here - space for the motor (to the left) is protected!")
			minetest.record_protection_violation(motorpos,name)
			minetest.remove_node(pos)
			return true
		end
		if not (minetest.registered_nodes[sheavereplaces] and minetest.registered_nodes[sheavereplaces].buildable_to) then
			minetest.chat_send_player(name,"Can't place machine here - no room for the sheave (in front)!")
			minetest.remove_node(pos)
			return true
		end
		if minetest.is_protected(sheavepos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
			minetest.chat_send_player(name,"Can't place machine here - space for the sheave (in front) is protected!")
			minetest.record_protection_violation(sheavepos,name)
			minetest.remove_node(pos)
			return true
		end
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec","formspec_version[7]size[8,5]field[0.5,0.5;7,1;carid;Car ID;]button[3,3.5;2,1;save;Save]")
		minetest.set_node(motorpos,{name="celevator:motor",param2=newnode.param2})
		minetest.set_node(sheavepos,{name="celevator:sheave",param2=newnode.param2})
	end,
	after_dig_node = function(pos,node)
		local facedir = minetest.dir_to_yaw(minetest.fourdir_to_dir(node.param2))
		local motorpos = vector.add(pos,vector.rotate_around_axis(vector.new(-1,0,0),vector.new(0,1,0),facedir))
		if minetest.get_node(motorpos).name == "celevator:motor" then
			minetest.remove_node(motorpos)
		end
		local sheavepos = vector.add(pos,vector.rotate_around_axis(vector.new(0,0,-1),vector.new(0,1,0),facedir))
		if minetest.get_node(sheavepos).name == "celevator:sheave" then
			minetest.remove_node(sheavepos)
		end
		local erefs = minetest.get_objects_inside_radius(sheavepos,0.5)
		for _,ref in pairs(erefs) do
			if ref:get_luaentity() and ref:get_luaentity().name == "celevator:sheave_moving" then
				ref:remove()
			end
		end
	end,
	on_punch = function(pos)
		local meta = minetest.get_meta(pos)
		if not minetest.string_to_pos(meta:get_string("origin")) then
			updatecarpos(pos)
		end
	end,
	on_receive_fields = function(pos,_,fields)
		if tonumber(fields.carid) then
			local carid = tonumber(fields.carid)
			local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not carinfo then return end
			local oldmachinepos = carinfo.machinepos
			if oldmachinepos then
				local oldmachine = celevator.get_node(oldmachinepos)
				if oldmachine.name == "celevator:machine" then
					return
				end
			end
			carinfo.machinepos = pos
			celevator.storage:set_string(string.format("car%d",carid),minetest.serialize(carinfo))
			local meta = minetest.get_meta(pos)
			meta:set_int("carid",carid)
			meta:set_string("formspec","")
			updatecarpos(pos)
		end
	end,
})

minetest.register_node("celevator:motor",{
	description = "Hoist Motor (you hacker you!)",
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "4dir",
	tiles = {
		"celevator_machine_top.png",
		"celevator_machine_top.png",
		"celevator_motor_sides.png",
		"celevator_motor_sides.png",
		"celevator_motor_back.png",
		"celevator_motor_front.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.3,0.1,0.1,0.3}, -- Motor body
			{0.1,-0.25,-0.05,0.5,-0.15,0.05}, -- Shaft
			{0.3,-0.4,-0.2,0.35,0,0.2}, -- Brake disc
			{0.275,-0.3,-0.1,0.375,-0.1,0.1}, -- Brake disc clamp
			{0.2,-0.5,0.15,0.45,0.1,0.3}, -- Brake housing
			{-0.4,0.1,-0.2,0,0.3,0.2}, -- Junction box
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {},
	},
})

minetest.register_node("celevator:sheave",{
	description = "Sheave (you hacker you!)",
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "4dir",
	tiles = {
		"celevator_sheave_sides.png^[transformR90",
		"celevator_sheave_sides.png^[transformR270",
		"celevator_sheave_sides.png",
		"celevator_sheave_sides.png^[transformR180",
		"celevator_sheave_front.png",
		"celevator_sheave_front.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.3,-0.2,0.2,0.3,0.4,0.5},
			{-0.4,-0.1,0.2,-0.3,0.3,0.5},
			{0.3,-0.1,0.2,0.4,0.3,0.5},
			{-0.2,0.4,0.2,0.2,0.5,0.5},
			{-0.2,-0.3,0.2,0.2,-0.2,0.5},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {},
	},
})

minetest.register_node("celevator:sheave_centered",{
	description = "Centered Sheave (you hacker you!)",
	groups = {
		not_in_creative_inventory = 1,
	},
	drop = "",
	paramtype = "light",
	paramtype2 = "4dir",
	tiles = {
		"celevator_sheave_sides.png^[transformR90",
		"celevator_sheave_sides.png^[transformR270",
		"celevator_sheave_sides.png",
		"celevator_sheave_sides.png^[transformR180",
		"celevator_sheave_front_centered.png",
		"celevator_sheave_front_centered.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.3,-0.3,0.2,0.3,0.3,0.5},
			{-0.4,-0.2,0.2,-0.3,0.2,0.5},
			{0.3,-0.2,0.2,0.4,0.2,0.5},
			{-0.2,0.3,0.2,0.2,0.4,0.5},
			{-0.2,-0.4,0.2,0.2,-0.3,0.5},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {},
	},
})

minetest.register_entity("celevator:sheave_moving",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.667,0.667,0.667),
		wield_item = "celevator:sheave_centered",
		static_save = false,
		pointable = false,
	},
})

function celevator.drives.entity.sheavetoentity(carid)
	local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not (carinfo and carinfo.machinepos) then return end
	local dir = minetest.fourdir_to_dir(celevator.get_node(carinfo.machinepos).param2)
	local pos = vector.add(carinfo.machinepos,vector.multiply(dir,-1))
	minetest.set_node(pos,{
		name = "celevator:sheave",
		param2 = minetest.dir_to_fourdir(dir),
	})
	local sheaverefs = celevator.drives.entity.nodestoentities({pos},"celevator:sheave_moving")
	celevator.drives.entity.sheaverefs[carid] = sheaverefs
	sheaverefs[1]:set_properties({wield_item = "celevator:sheave_centered"})
	sheaverefs[1]:set_pos(vector.add(pos,vector.new(0,0.1,0)))
end

function celevator.drives.entity.sheavetonode(carid)
	local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not (carinfo and carinfo.machinepos) then return end
	local dir = minetest.fourdir_to_dir(celevator.get_node(carinfo.machinepos).param2)
	local pos = vector.add(carinfo.machinepos,vector.multiply(dir,-1))
	local erefs = celevator.drives.entity.sheaverefs[carid]
	if erefs and erefs[1] then
		erefs[1]:remove()
	end
	minetest.set_node(pos,{
		name = "celevator:sheave",
		param2 = minetest.dir_to_fourdir(dir),
	})
end

function celevator.drives.entity.updatecopformspec(drivepos)
	local entitydrives_running = minetest.deserialize(celevator.storage:get_string("entitydrives_running")) or {}
	if entitydrives_running[minetest.hash_node_position(drivepos)] then return end
	local drivemeta = celevator.get_meta(drivepos)
	local carid = drivemeta:get_int("carid")
	if carid == 0 then return end
	local carinfo = minetest.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not carinfo then return end
	local copformspec = celevator.get_meta(carinfo.controllerpos):get_string("copformspec")
	local switchformspec = celevator.get_meta(carinfo.controllerpos):get_string("switchformspec")
	local origin = minetest.string_to_pos(drivemeta:get_string("origin"))
	if not origin then
		minetest.log("error","[celevator] [entity drive] Invalid origin for drive at "..minetest.pos_to_string(drivepos))
		drivemeta:set_string("fault","badorigin")
		return
	end
	local apos = tonumber(drivemeta:get_string("apos")) or 0
	if apos == math.floor(apos) then
		local carpos = vector.add(origin,vector.new(0,apos,0))
		local carnodes = celevator.drives.entity.gathercar(carpos,minetest.dir_to_yaw(minetest.fourdir_to_dir(celevator.get_node(carpos).param2)))
		for hash in pairs(carnodes) do
			local piecepos = minetest.get_position_from_hash(hash)
			local piece = celevator.get_node(piecepos)
			local ndef = minetest.registered_nodes[piece.name] or {}
			if ndef._cop then
				celevator.get_meta(piecepos):set_string("formspec",copformspec)
			elseif ndef._keyswitches then
				celevator.get_meta(piecepos):set_string("formspec",switchformspec)
			end
		end
	end
end
