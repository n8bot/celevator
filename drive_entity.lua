local S = core.get_translator("celevator")

local copfscontext = {}

local keyswitchfscontext = {}

celevator.drives.entity = {
	name = S("Elevator Drive"),
	description = S("Normal entity-based drive"),
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
	local meta = core.get_meta(pos)
	local apos = tonumber(meta:get_string("apos")) or 0
	local status
	local vel = tonumber(meta:get_string("vel")) or 0
	local state = meta:get_string("state")
	local velstr = string.format("%0.02f",math.abs(vel))
	local aposstr = string.format("%0.02f",apos)
	if state == "running" and vel > 0 then
		status = S("Drive - Running: Up, @1m/s - Position: @2m",velstr,aposstr)
	elseif state == "running" and vel < 0 then
		status = S("Drive - Running: Down, @1m/s - Position: @2m",velstr,aposstr)
	elseif state == "fakerunning" and vel > 0 then
		status = S("Drive - Running (simulated): Up, @1m/s - Position: @2m",velstr,aposstr)
	elseif state == "fakerunning" and vel < 0 then
		status = S("Drive - Running (simulated): Down, @1m/s - Position: @2m",velstr,aposstr)
	else
		status = S("Drive - Idle")
	end
	meta:set_string("infotext",status)
end

local function playbuzz(pos)
	local hash = core.hash_node_position(pos)
	if celevator.drives.entity.buzzsoundhandles[hash] == "cancel" then return end
	celevator.drives.entity.buzzsoundhandles[hash] = core.sound_play("celevator_drive_run",{
		pos = pos,
		loop = true,
		gain = 0.1,
	})
end

local function startbuzz(pos)
	local hash = core.hash_node_position(pos)
	if celevator.drives.entity.buzzsoundhandles[hash] == "cancel" then
		celevator.drives.entity.buzzsoundhandles[hash] = nil
		return
	end
	if celevator.drives.entity.buzzsoundhandles[hash] then return end
	celevator.drives.entity.buzzsoundhandles[hash] = "pending"
	core.after(0.5,playbuzz,pos)
end

local function stopbuzz(pos)
	local hash = core.hash_node_position(pos)
	if not celevator.drives.entity.buzzsoundhandles[hash] then return end
	if celevator.drives.entity.buzzsoundhandles[hash] == "pending" then
		celevator.drives.entity.buzzsoundhandles[hash] = "cancel"
	end
	if type(celevator.drives.entity.buzzsoundhandles[hash]) ~= "string" then
		core.sound_stop(celevator.drives.entity.buzzsoundhandles[hash])
		celevator.drives.entity.buzzsoundhandles[hash] = nil
	end
end

local function motorsound(pos,newstate)
	local hash = core.hash_node_position(pos)
	local oldstate = celevator.drives.entity.movementsoundstate[hash]
	oldstate = oldstate or "idle"
	if oldstate == newstate then return end
	local carid = core.get_meta(pos):get_int("carid")
	local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not (carinfo and carinfo.machinepos) then return end
	local oldhandle = celevator.drives.entity.movementsoundhandles[hash]
	if newstate == "slow" then
		if oldstate == "idle" then
			core.sound_play("celevator_brake_release",{
				pos = carinfo.machinepos,
				gain = 1,
			},true)
			celevator.drives.entity.movementsoundhandles[hash] = core.sound_play("celevator_motor_slow",{
				pos = carinfo.machinepos,
				loop = true,
				gain = 1,
			})
		elseif oldstate == "accel" or oldstate == "fast" or oldstate == "decel" then
			if oldhandle then core.sound_stop(oldhandle) end
			celevator.drives.entity.movementsoundhandles[hash] = core.sound_play("celevator_motor_slow",{
				pos = carinfo.machinepos,
				loop = true,
				gain = 1,
			})
		end
	elseif newstate == "accel" then
		if oldhandle then core.sound_stop(oldhandle) end
		celevator.drives.entity.movementsoundhandles[hash] = core.sound_play("celevator_motor_accel",{
			pos = carinfo.machinepos,
			gain = 1,
		})
	elseif newstate == "fast" then
		if oldhandle then core.sound_stop(oldhandle) end
		celevator.drives.entity.movementsoundhandles[hash] = core.sound_play("celevator_motor_fast",{
			pos = carinfo.machinepos,
			loop = true,
			gain = 1,
		})
	elseif newstate == "decel" then
		if oldhandle then core.sound_stop(oldhandle) end
		celevator.drives.entity.movementsoundhandles[hash] = core.sound_play("celevator_motor_decel",{
			pos = carinfo.machinepos,
			gain = 1,
		})
	elseif newstate == "idle" then
		if oldhandle then core.sound_stop(oldhandle) end
		core.sound_play("celevator_brake_apply",{
			pos = carinfo.machinepos,
			gain = 1,
		},true)
	end
	celevator.drives.entity.movementsoundstate[hash] = newstate
end

local function carsound(pos,newstate,speed)
	if speed < 0.5 then return end
	local hash = core.hash_node_position(pos)
	local oldstate = celevator.drives.entity.carsoundstate[hash]
	oldstate = oldstate or "idle"
	if oldstate == newstate then return end
	if not celevator.drives.entity.entityinfo[hash] then return end
	local eref = celevator.drives.entity.entityinfo[hash].handles[1]
	if not eref:get_pos() then return end
	local oldhandle = celevator.drives.entity.carsoundhandles[hash]
	local gain = math.min(1,speed/6)
	if newstate == "accel" then
		if oldhandle then core.sound_stop(oldhandle) end
		celevator.drives.entity.carsoundhandles[hash] = core.sound_play("celevator_car_start",{
			object = eref,
			gain = gain,
		})
		core.after(3,function()
			if celevator.drives.entity.carsoundstate[hash] == "accel" then
				carsound(pos,"run",speed)
			end
		end)
	elseif newstate == "run" then
		if oldhandle then core.sound_stop(oldhandle) end
		celevator.drives.entity.carsoundhandles[hash] = core.sound_play("celevator_car_run",{
			object = eref,
			loop = true,
			gain = gain,
		})
	elseif newstate == "decel" then
		if oldhandle then core.sound_stop(oldhandle) end
		celevator.drives.entity.carsoundhandles[hash] = core.sound_play("celevator_car_stop",{
			object = eref,
			gain = gain,
		})
	elseif newstate == "stopped" then
		if oldhandle then core.sound_stop(oldhandle) end
	end
	celevator.drives.entity.carsoundstate[hash] = newstate
end

local function compareexchangesound(pos,compare,new)
	local hash = core.hash_node_position(pos)
	local oldstate = celevator.drives.entity.movementsoundstate[hash]
	if oldstate == compare then
		motorsound(pos,new)
	end
end

local function accelsound(pos)
	motorsound(pos,"slow")
	core.after(1,compareexchangesound,pos,"slow","accel")
	core.after(4,compareexchangesound,pos,"accel","fast")
end

local function decelsound(pos)
	motorsound(pos,"decel")
	core.after(2,compareexchangesound,pos,"decel","slow")
end

core.register_node("celevator:drive",{
	description = celevator.drives.entity.name,
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
		local meta = core.get_meta(pos)
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

core.register_entity("celevator:car_moving",{
	initial_properties = {
		visual = "node",
		node = {name="air"},
		static_save = false,
		glow = core.LIGHT_MAX,
		pointable = false,
	},
	on_step = function(self, dtime)
		local pos = self.object:get_pos()
		if not pos then return end
		
		local node_prop = self.object:get_properties().node
		if not (node_prop and node_prop.name) then return end
		if not string.match(node_prop.name, "_020$") then return end

		local limits = self.car_limits
		if not limits then return end

		for _, obj in ipairs(core.get_objects_inside_radius(pos, 6.0)) do
			if obj:is_player() and not obj:get_attach() then
				local player_name = obj:get_player_name()
				local p_limits = playerposlimits[player_name] or {}
				
				local immune = false
				if p_limits.ignore_ticks and p_limits.ignore_ticks > 0 then
					p_limits.ignore_ticks = p_limits.ignore_ticks - 1
					immune = true
				end
				
				if not immune then
					local vel = obj:get_velocity()
					
					if vel and vel.y <= 0.1 then
						local attachpos = obj:get_pos()
						
						local inside_x = attachpos.x >= limits.xmin - 0.25 and attachpos.x <= limits.xmax + 0.25
						local inside_z = attachpos.z >= limits.zmin - 0.25 and attachpos.z <= limits.zmax + 0.25
						local inside_y = attachpos.y > pos.y - 2.5 and attachpos.y < pos.y + 1.0
						
						if inside_x and inside_z and inside_y then
							local offset = vector.subtract(attachpos, pos)
							local attachoffset = vector.rotate_around_axis(
								vector.new(offset.x, 0.5, offset.z), 
								vector.new(0, -1, 0), 
								self.object:get_yaw()
							)
							
							local holder = core.add_entity(attachpos, "celevator:player_holder")
							if holder then
								holder:set_attach(self.object, "", vector.multiply(attachoffset, 10), vector.new(0,0,0))
								obj:set_attach(holder, "")
								
								playerposlimits[player_name] = {
									xmin = limits.xmin - 0.25, xmax = limits.xmax + 0.25,
									zmin = limits.zmin - 0.25, zmax = limits.zmax + 0.25,
									is_roof = true
								}
							end
						end
					end
				end
			end
		end
	end
})

core.register_entity("celevator:player_holder",{
	initial_properties = {
		visual = "cube",
		textures = { "blank.png", "blank.png", "blank.png", "blank.png", "blank.png", "blank.png" },
		static_save = false,
		pointable = false,
	},
	on_step = function(self, dtime)
		if self.jump_cooldown == nil then
			self.jump_cooldown = 5
			self.was_jumping = true 
		end
		if self.jump_cooldown > 0 then
			self.jump_cooldown = self.jump_cooldown - 1
		end

		local obj = self.object
		local car, _, attachoffset = obj:get_attach()
		
		local children = obj:get_children()
		local player
		for _, i in pairs(children) do
			if i:is_player() then player = i end
		end
		if not player then 
			obj:remove()
			return 
		end
		
		local player_name = player:get_player_name()
		local limits = playerposlimits[player_name] or {}

		if not car then 
			player:set_detach()
			if limits.is_roof and self.last_world_pos then
				local ppos = self.last_world_pos
				core.after(0, function()
					if player:is_player() then
						player:set_pos(vector.new(ppos.x, ppos.y + 0.1, ppos.z))
					end
				end)
			end
			obj:remove() 
			return 
		end
		
		local caryaw = car:get_yaw()
		local playeryaw = player:get_look_horizontal()
		local control = player:get_player_control()

		if control.jump and not self.was_jumping and limits.is_roof and self.jump_cooldown == 0 then
			local realattachoffset = vector.rotate_around_axis(vector.multiply(attachoffset, 0.1), vector.new(0, 1, 0), caryaw)
			local current_world_pos = vector.add(car:get_pos(), realattachoffset)
			
			player:set_detach()
			obj:remove()
			
			playerposlimits[player_name] = { ignore_ticks = 8 }
			
			core.after(0, function()
				if player:is_player() then
					player:set_pos(vector.new(current_world_pos.x, current_world_pos.y + 1.2, current_world_pos.z))
				end
			end)
			return
		end

		self.was_jumping = control.jump

		if control.up or control.down or control.left or control.right then
			local walkamount = 40 * dtime
			local move_x = (control.right and 1 or 0) - (control.left and 1 or 0)
			local move_z = (control.up and 1 or 0) - (control.down and 1 or 0)
			
			local displacement = vector.rotate_around_axis(vector.new(move_x * walkamount, 0, move_z * walkamount), vector.new(0, 1, 0), playeryaw)
			displacement = vector.rotate_around_axis(displacement, vector.new(0, -1, 0), caryaw)
			
			local oldattachoffset = vector.copy(attachoffset)
			attachoffset = vector.add(attachoffset, displacement)
			
			local realattachoffset = vector.rotate_around_axis(vector.multiply(attachoffset, 0.1), vector.new(0, 1, 0), caryaw)
			local newpos = vector.add(car:get_pos(), realattachoffset)
			
			if limits.xmin and limits.xmax and limits.xmin < limits.xmax then
				if newpos.x > limits.xmax or newpos.x < limits.xmin then attachoffset = oldattachoffset end
			end
			if limits.zmin and limits.zmax and limits.zmin < limits.zmax then
				if newpos.z > limits.zmax or newpos.z < limits.zmin then attachoffset = oldattachoffset end
			end
		end
		
		local final_realattachoffset = vector.rotate_around_axis(vector.multiply(attachoffset, 0.1), vector.new(0, 1, 0), caryaw)
		self.last_world_pos = vector.add(car:get_pos(), final_realattachoffset)
		
		obj:set_attach(car, "", attachoffset, vector.new(0, 0, 0))
		player:set_attach(obj, "", vector.new(0, 0, 0), vector.new(0, (caryaw - playeryaw) * 57.296, 0))
	end,
})

function celevator.drives.entity.gathercar(pos,yaw,nodes)
	if not nodes then nodes = {} end
	local hash = core.hash_node_position(pos)
	if nodes[hash] then return nodes end
	nodes[hash] = true
	if core.get_item_group(celevator.get_node(pos).name,"_connects_xp") == 1 then
		celevator.drives.entity.gathercar(vector.add(pos,vector.rotate_around_axis(vector.new(1,0,0),vector.new(0,1,0),yaw)),yaw,nodes)
	end
	if core.get_item_group(celevator.get_node(pos).name,"_connects_xm") == 1 then
		celevator.drives.entity.gathercar(vector.add(pos,vector.rotate_around_axis(vector.new(-1,0,0),vector.new(0,1,0),yaw)),yaw,nodes)
	end
	if core.get_item_group(celevator.get_node(pos).name,"_connects_yp") == 1 then
		celevator.drives.entity.gathercar(vector.add(pos,vector.new(0,1,0)),yaw,nodes)
	end
	if core.get_item_group(celevator.get_node(pos).name,"_connects_ym") == 1 then
		celevator.drives.entity.gathercar(vector.add(pos,vector.new(0,-1,0)),yaw,nodes)
	end
	if core.get_item_group(celevator.get_node(pos).name,"_connects_zp") == 1 then
		celevator.drives.entity.gathercar(vector.add(pos,vector.rotate_around_axis(vector.new(0,0,1),vector.new(0,1,0),yaw)),yaw,nodes)
	end
	if core.get_item_group(celevator.get_node(pos).name,"_connects_zm") == 1 then
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
		local attach = core.get_objects_inside_radius(pos,0.9)
		local eref = core.add_entity(pos,(ename or "celevator:car_moving"))
		eref:set_properties({
			node = {name = node.name},
		})
		eref:set_yaw(core.dir_to_yaw(core.fourdir_to_dir(node.param2)))
		eref:set_armor_groups({
			immortal = 1,
		})
		table.insert(refs,eref)
		local luaent = eref:get_luaentity()
        if luaent then
            luaent.car_limits = {
                xmin = xmin, xmax = xmax,
                zmin = zmin, zmax = zmax
            }
        end
		local ndef = core.registered_nodes[node.name] or {}
		local nbox = ndef.selection_box or ndef.node_box
		if nbox and nbox.fixed then
			local selbox = {0,0,0,0,0,0}
			if type(nbox.fixed[1]) ~= "table" then
				selbox = table.copy(nbox.fixed)
			else
				for _,box in ipairs(nbox.fixed) do
					for i=1,3 do
						selbox[i] = math.min(selbox[i],box[i])
					end
					for i=4,6 do
						selbox[i] = math.max(selbox[i],box[i])
					end
				end
			end
			selbox.rotate = true
			eref:set_properties({selectionbox=selbox})
		end
		if ndef._cartopbox or ndef._tapehead then
			local toppos = vector.add(pos,vector.new(0,1,0))
			local topattach = core.get_objects_inside_radius(toppos,0.75)
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
					local offset = vector.subtract(attachpos, basepos)
					
					local y_level = tonumber(string.match(node.name, "_%d(%d)%d$")) or 0
					local player_is_on_roof = (y_level >= 2)
					
					local attachoffset = vector.rotate_around_axis(offset, vector.new(0,-1,0), eref:get_yaw())
					local holder = core.add_entity(attachpos, "celevator:player_holder")
					holder:set_attach(eref, "", vector.multiply(attachoffset, 10), vector.new(0,0,0))
					attachref:set_attach(holder, "")
					
					local extra = 0.25 
					playerposlimits[attachref:get_player_name()] = {
						xmin = xmin - extra,
						xmax = xmax + extra,
						zmin = zmin - extra,
						zmax = zmax + extra,
						is_roof = player_is_on_roof
					}
				else
					if not attachref:get_attach() then
						local attachpos = attachref:get_pos()
						local basepos = eref:get_pos()
						local attachoffset = vector.subtract(attachpos,basepos)
						attachref:set_attach(eref,"",vector.multiply(attachoffset,10),vector.new(0,0,0))
					end
				end
			end
			local meta = celevator.get_meta(pos)
			local carid = meta:get_int("carid")
			if carid ~= 0 then
				if core.get_item_group(node.name,"_has_cop") == 1 then
					eref:set_properties({
						pointable = true,
					})
					eref:get_luaentity().on_rightclick = function(self,player)
						celevator.drives.entity.coprightclick(carid,player,self.object:get_pos())
					end
				elseif core.get_item_group(node.name,"_has_keyswitches") == 1 then
					eref:set_properties({
						pointable = true,
					})
					eref:get_luaentity().on_rightclick = function(self,player)
						celevator.drives.entity.keyswitchrightclick(carid,player,self.object:get_pos())
					end
				end
			end
		end
		core.remove_node(pos)
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
			local node = eref:get_properties().node or {name="air"}
			node.param2 = core.dir_to_fourdir(core.yaw_to_dir(eref:get_yaw()))
			if core.get_item_group(node.name,"_connects_yp") ~= 1 then top = true end
			core.set_node(pos,node)
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
			for _,i in ipairs(core.get_objects_inside_radius(pos,0.9)) do
				i:set_velocity(vector.new(0,0,0))
				if i:is_player() then
					local ppos = i:get_pos()
					ppos.y=ppos.y-0.48
					if top then ppos.y = ppos.y+1.02 end
					i:set_pos(ppos)
					core.after(0.5,function()
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
	local entitydrives_running = core.deserialize(celevator.storage:get_string("entitydrives_running")) or {}
	local save = false
	for i,hash in ipairs(entitydrives_running) do
		save = true
		local pos = core.get_position_from_hash(hash)
		local node = celevator.get_node(pos)
		local sound = false
		if node.name == "ignore" then
			core.forceload_block(pos,true)
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
				local origin = core.string_to_pos(meta:get_string("origin"))
				if not origin then
					core.log("error","[celevator] [entity drive] Invalid origin for drive at "..core.pos_to_string(pos))
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
					local hashes = celevator.drives.entity.gathercar(startv,core.dir_to_yaw(core.fourdir_to_dir(celevator.get_node(startv).param2)))
					local nodes = {}
					for carhash in pairs(hashes) do
						local carpos = core.get_position_from_hash(carhash)
						if vector.equals(startv,carpos) then
							table.insert(nodes,1,carpos) --0,0,0 node must be first in the list
						else
							table.insert(nodes,carpos)
						end
					end
					local carparam2 = celevator.get_node(nodes[1]).param2
					local cardef = core.registered_nodes[celevator.get_node(nodes[1]).name] or {}
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
							celevator.car.spawncar(spawnpos,core.dir_to_yaw(core.fourdir_to_dir(carparam2)),carid,cartype,doortype)
						else
							celevator.get_meta(spawnpos):set_string("doortype",doortype)
						end
						apos = math.floor(apos+0.5)
						core.after(0.25,celevator.drives.entity.updatecopformspec,pos)
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
						celevator.car.spawncar(spawnpos,core.dir_to_yaw(core.fourdir_to_dir(carparam2)),carid,cartype,doortype)
						apos = math.floor(apos+0.5)
						core.after(0.25,celevator.drives.entity.updatecopformspec,pos)
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
		celevator.storage:set_string("entitydrives_running",core.serialize(entitydrives_running))
	end
	celevator.drives.entity.step_enabled = save
end

core.register_globalstep(celevator.drives.entity.step)

function celevator.drives.entity.moveto(pos,target,inspection)
	local meta = celevator.get_meta(pos)
	meta:mark_as_private({"apos","dpos","vel","maxvel","state","startpos","doorstate"})
	local carid = celevator.get_meta(pos):get_int("carid")
	local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
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
	local origin = core.string_to_pos(meta:get_string("origin"))
	if not origin then
		core.log("error","[celevator] [entity drive] Invalid origin for drive at "..core.pos_to_string(pos))
		meta:set_string("fault","badorigin")
		return
	end
	if target < 0 or origin.y + target > (carinfo.machinepos.y-3) or target ~= target then
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
		local hash = core.hash_node_position(pos)
		local entitydrives_running = core.deserialize(celevator.storage:get_string("entitydrives_running")) or {}
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
			celevator.storage:set_string("entitydrives_running",core.serialize(entitydrives_running))
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
	local hash = core.hash_node_position(pos)
	local handles = celevator.drives.entity.entityinfo[hash].handles
	meta:set_string("state","stopped")
	meta:set_string("vel","0")
	local carid = meta:get_int("carid")
	celevator.drives.entity.entitiestonodes(handles,carid)
	stopbuzz(pos)
	motorsound(pos,"idle")
	if carid ~= 0 then celevator.drives.entity.sheavetonode(carid) end
	core.after(0.25,celevator.drives.entity.updatecopformspec,pos)
end


function celevator.drives.entity.setmaxvel(pos,maxvel)
	if maxvel ~= maxvel then return end
	local meta = celevator.get_meta(pos)
	meta:set_string("maxvel",tostring(maxvel))
end


function celevator.drives.entity.rezero(pos)
	celevator.drives.entity.moveto(pos,0)
end

function celevator.drives.entity.getstatus(pos,call2)
	local node = core.get_node(pos)
	if node.name == "ignore" and not call2 then
		core.forceload_block(pos,true)
		return celevator.drives.entity.get_status(pos,true)
	elseif node.name ~= "celevator:drive" then
		core.log("error","[celevator] [entity drive] Could not load drive status at "..core.pos_to_string(pos))
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
	local drivehash = core.hash_node_position(drivepos)
	local entitydrives_running = core.deserialize(celevator.storage:get_string("entitydrives_running")) or {}
	local drivemeta = celevator.get_meta(drivepos)
	for _,hash in pairs(entitydrives_running) do
		if drivehash == hash then
			core.log("error","[celevator] [entity drive] Attempted to open doors while drive at "..core.pos_to_string(drivepos).." was still moving")
			drivemeta:set_string("fault","doorinterlock")
			return
		end
	end
	local origin = core.string_to_pos(drivemeta:get_string("origin"))
	if not origin then
		core.log("error","[celevator] [entity drive] Invalid origin for drive at "..core.pos_to_string(drivepos))
		drivemeta:set_string("fault","badorigin")
		return
	end
	local apos = tonumber(drivemeta:get_string("apos")) or 0
	local carpos = vector.add(origin,vector.new(0,apos,0))
	local carnode = celevator.get_node(carpos)
	local hwdoorpos = vector.add(carpos,vector.rotate_around_axis(core.fourdir_to_dir(carnode.param2),vector.new(0,1,0),math.pi))
	local isroot = core.get_item_group(celevator.get_node(hwdoorpos).name,"_celevator_hwdoor_root") == 1
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
	local origin = core.string_to_pos(drivemeta:get_string("origin"))
	if not origin then
		core.log("error","[celevator] [entity drive] Invalid origin for drive at "..core.pos_to_string(drivepos))
		drivemeta:set_string("fault","badorigin")
		return
	end
	local apos = tonumber(drivemeta:get_string("apos")) or 0
	local beeppos = vector.add(origin,vector.new(0,apos+2,0))
	core.sound_play("celevator_pi_beep",{
		pos = beeppos,
		gain = 1,
	},true)
end

local function carsearch(pos)
	local maxdistance = tonumber(core.settings:get("celevator.max_height")) or 500
	maxdistance = math.max(1,maxdistance)
	for i=1,maxdistance,1 do
		local searchpos = vector.subtract(pos,vector.new(0,i,0))
		local node = celevator.get_node(searchpos)
		if core.get_item_group(node.name,"_celevator_car") == 1 then
			local yaw = core.dir_to_yaw(core.fourdir_to_dir(node.param2))
			local offsettext = core.registered_nodes[node.name]._position
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
		meta:set_string("origin",core.pos_to_string(carpos))
		celevator.get_meta(carpos):set_string("machinepos",core.pos_to_string(pos))
		meta:set_string("infotext",S("Using car with origin @1",core.pos_to_string(carpos)))
		local carid = meta:get_int("carid")
		local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
		if not (carinfo and carinfo.controllerpos) then return end
		carinfo.origin = carpos
		celevator.storage:set_string(string.format("car%d",carid),core.serialize(carinfo))
		local drivepos = celevator.controller.finddrive(carinfo.controllerpos)
		if drivepos then
			local drivemeta = celevator.get_meta(drivepos)
			if drivemeta:get_string("state") == "uninit" then
				drivemeta:set_string("origin",core.pos_to_string(carpos))
				drivemeta:set_string("state","stopped")
				drivemeta:set_int("carid",carid)
			end
		end
		local caryaw = core.dir_to_yaw(core.fourdir_to_dir(celevator.get_node(carpos).param2))
		local carnodes = celevator.drives.entity.gathercar(carpos,caryaw)
		for hash in pairs(carnodes) do
			local carmeta = celevator.get_meta(core.get_position_from_hash(hash))
			carmeta:set_int("carid",carid)
		end
	else
		meta:set_string("infotext",S("No car found! Punch to try again"))
	end
end

core.register_node("celevator:machine",{
	description = S("Elevator Hoist Machine"),
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
			core.remove_node(pos)
			return true
		end
		local newnode = core.get_node(pos)
		local facedir = core.dir_to_yaw(core.fourdir_to_dir(newnode.param2))
		local motorpos = vector.add(pos,vector.rotate_around_axis(vector.new(-1,0,0),vector.new(0,1,0),facedir))
		local motorreplaces = core.get_node(motorpos).name
		local sheavepos = vector.add(pos,vector.rotate_around_axis(vector.new(0,0,-1),vector.new(0,1,0),facedir))
		local sheavereplaces = core.get_node(sheavepos).name
		local name = player:get_player_name()
		if not (core.registered_nodes[motorreplaces] and core.registered_nodes[motorreplaces].buildable_to) then
			core.chat_send_player(name,S("Can't place machine here - no room for the motor (to the left)!"))
			core.remove_node(pos)
			return true
		end
		if core.is_protected(motorpos,name) and not core.check_player_privs(name,{protection_bypass=true}) then
			core.chat_send_player(name,S("Can't place machine here - space for the motor (to the left) is protected!"))
			core.record_protection_violation(motorpos,name)
			core.remove_node(pos)
			return true
		end
		if not (core.registered_nodes[sheavereplaces] and core.registered_nodes[sheavereplaces].buildable_to) then
			core.chat_send_player(name,S("Can't place machine here - no room for the sheave (in front)!"))
			core.remove_node(pos)
			return true
		end
		if core.is_protected(sheavepos,name) and not core.check_player_privs(name,{protection_bypass=true}) then
			core.chat_send_player(name,S("Can't place machine here - space for the sheave (in front) is protected!"))
			core.record_protection_violation(sheavepos,name)
			core.remove_node(pos)
			return true
		end
		local meta = core.get_meta(pos)
		meta:set_string("formspec","formspec_version[7]size[8,5]field[0.5,0.5;7,1;carid;"..S("Car ID")..";]button[3,3.5;2,1;save;"..S("Save").."]")
		core.set_node(motorpos,{name="celevator:motor",param2=newnode.param2})
		core.set_node(sheavepos,{name="celevator:sheave",param2=newnode.param2})
	end,
	after_dig_node = function(pos,node)
		local facedir = core.dir_to_yaw(core.fourdir_to_dir(node.param2))
		local motorpos = vector.add(pos,vector.rotate_around_axis(vector.new(-1,0,0),vector.new(0,1,0),facedir))
		if core.get_node(motorpos).name == "celevator:motor" then
			core.remove_node(motorpos)
		end
		local sheavepos = vector.add(pos,vector.rotate_around_axis(vector.new(0,0,-1),vector.new(0,1,0),facedir))
		if core.get_node(sheavepos).name == "celevator:sheave" then
			core.remove_node(sheavepos)
		end
		local erefs = core.get_objects_inside_radius(sheavepos,0.5)
		for _,ref in pairs(erefs) do
			if ref:get_luaentity() and ref:get_luaentity().name == "celevator:sheave_moving" then
				ref:remove()
			end
		end
	end,
	on_punch = function(pos)
		local meta = core.get_meta(pos)
		if not core.string_to_pos(meta:get_string("origin")) then
			updatecarpos(pos)
		end
	end,
	on_receive_fields = function(pos,_,fields)
		if tonumber(fields.carid) then
			local carid = tonumber(fields.carid)
			local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
			if not carinfo then return end
			local oldmachinepos = carinfo.machinepos
			if oldmachinepos then
				local oldmachine = celevator.get_node(oldmachinepos)
				if oldmachine.name == "celevator:machine" and not vector.equals(pos,oldmachinepos) then
					return
				end
			end
			carinfo.machinepos = pos
			celevator.storage:set_string(string.format("car%d",carid),core.serialize(carinfo))
			local meta = core.get_meta(pos)
			meta:set_int("carid",carid)
			meta:set_string("formspec","")
			updatecarpos(pos)
		end
	end,
})

core.register_node("celevator:motor",{
	description = S("Hoist Motor (you hacker you!)"),
	groups = {
		cracky = 3,
		oddly_breakable_by_hand = 1,
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

core.register_node("celevator:sheave",{
	description = S("Sheave (you hacker you!)"),
	groups = {
		cracky = 3,
		oddly_breakable_by_hand = 1,
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

core.register_node("celevator:sheave_centered",{
	description = S("Centered Sheave (you hacker you!)"),
	groups = {
		cracky = 3,
		oddly_breakable_by_hand = 1,
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

core.register_entity("celevator:sheave_moving",{
	initial_properties = {
		visual = "wielditem",
		visual_size = vector.new(0.667,0.667,0.667),
		wield_item = "celevator:sheave_centered",
		static_save = false,
		pointable = false,
	},
})

function celevator.drives.entity.sheavetoentity(carid)
	local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not (carinfo and carinfo.machinepos) then return end
	local dir = core.fourdir_to_dir(celevator.get_node(carinfo.machinepos).param2)
	local pos = vector.add(carinfo.machinepos,vector.multiply(dir,-1))
	core.set_node(pos,{
		name = "celevator:sheave",
		param2 = core.dir_to_fourdir(dir),
	})
	local sheaverefs = celevator.drives.entity.nodestoentities({pos},"celevator:sheave_moving")
	celevator.drives.entity.sheaverefs[carid] = sheaverefs
	sheaverefs[1]:set_properties({wield_item = "celevator:sheave_centered"})
	sheaverefs[1]:set_pos(vector.add(pos,vector.new(0,0.1,0)))
end

function celevator.drives.entity.sheavetonode(carid)
	local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not (carinfo and carinfo.machinepos) then return end
	local dir = core.fourdir_to_dir(celevator.get_node(carinfo.machinepos).param2)
	local pos = vector.add(carinfo.machinepos,vector.multiply(dir,-1))
	local erefs = celevator.drives.entity.sheaverefs[carid]
	if erefs and erefs[1] then
		erefs[1]:remove()
	end
	core.set_node(pos,{
		name = "celevator:sheave",
		param2 = core.dir_to_fourdir(dir),
	})
end

function celevator.drives.entity.updatecopformspec(drivepos)
	local entitydrives_running = core.deserialize(celevator.storage:get_string("entitydrives_running")) or {}
	if entitydrives_running[core.hash_node_position(drivepos)] then return end
	local drivemeta = celevator.get_meta(drivepos)
	local carid = drivemeta:get_int("carid")
	if carid == 0 then return end
	local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not carinfo then return end
	local copformspec = celevator.get_meta(carinfo.controllerpos):get_string("copformspec")
	local switchformspec = celevator.get_meta(carinfo.controllerpos):get_string("switchformspec")
	for playername,context in pairs(copfscontext) do
		if carid == context.carid then
			core.show_formspec(playername,"celevator:cop",copformspec)
		end
	end
	for playername,context in pairs(keyswitchfscontext) do
		if carid == context.carid then
			core.show_formspec(playername,"celevator:keyswitches",switchformspec)
		end
	end
end

function celevator.drives.entity.coprightclick(carid,player,pos)
	if type(player) == "userdata" then player = player:get_player_name() end
	local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not (carinfo and carinfo.controllerpos) then return end
	if not celevator.controller.iscontroller(carinfo.controllerpos) then return end
	local meta = celevator.get_meta(carinfo.controllerpos)
	local formspec = meta:get_string("copformspec")
	core.show_formspec(player,"celevator:cop",formspec)
	copfscontext[player] = {carid = carid,pos = pos}
end

function celevator.drives.entity.keyswitchrightclick(carid,player,pos)
	if type(player) == "userdata" then player = player:get_player_name() end
	local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
	if not (carinfo and carinfo.controllerpos) then return end
	if not celevator.controller.iscontroller(carinfo.controllerpos) then return end
	local meta = celevator.get_meta(carinfo.controllerpos)
	local formspec = meta:get_string("switchformspec")
	core.show_formspec(player,"celevator:keyswitches",formspec)
	keyswitchfscontext[player] = {carid = carid,pos = pos}
end

core.register_on_player_receive_fields(function(player,formname,fields)
	local playername = player:get_player_name()
	if formname == "celevator:cop" then
		if fields.quit then
			copfscontext[playername] = nil
		end
		local carid = (copfscontext[playername] or {}).carid
		if not carid then return end
		local coppos = copfscontext[playername].pos
		local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
		if not carinfo then return end
		local protected = core.is_protected(vector.round(coppos),playername) and not core.check_player_privs(playername,{protection_bypass=true})
		local event = {
			type = "cop",
			fields = fields,
			player = playername,
			protected = protected,
		}
		if fields.alarm then
			core.sound_play({name="celevator_alarm"},{pos=coppos,max_hear_distance=32,ephemeral=true})
		elseif fields.phone then
			core.sound_play({name="celevator_phone"},{pos=coppos,gain=0.3,max_hear_distance=8,ephemeral=true})
		end
		celevator.controller.run(carinfo.controllerpos,event)
		return true
	elseif formname == "celevator:keyswitches" then
		if fields.quit then
			keyswitchfscontext[playername] = nil
		end
		local carid = (keyswitchfscontext[playername] or {}).carid
		if not carid then return end
		local switchpos = keyswitchfscontext[playername].pos
		local carinfo = core.deserialize(celevator.storage:get_string(string.format("car%d",carid)))
		if not carinfo then return end
		if core.is_protected(switchpos,playername) and not core.check_player_privs(playername,{protection_bypass=true}) then
			core.chat_send_player(playername,S("You don't have access to these switches."))
			core.record_protection_violation(switchpos,playername)
			return
		end
		local event = {
			type = "copswitches",
			fields = fields,
			player = playername,
		}
		celevator.controller.run(carinfo.controllerpos,event)
		return true
	else
		return false
	end
end)
