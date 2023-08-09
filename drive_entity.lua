celevator.drives.entity = {
	name = "Drive",
	description = "Normal entity-based drive",
	nname = "celevator:drive",
	soundhandles = {},
	entityinfo = {},
}

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
	end
	meta:set_string("infotext",string.format("Drive - %s - Position: %0.02f m",status,apos))
end

local function playbuzz(pos)
	local hash = minetest.hash_node_position(pos)
	if celevator.drives.null.soundhandles[hash] == "cancel" then return end
	celevator.drives.null.soundhandles[hash] = minetest.sound_play("celevator_drive_run",{
		pos = pos,
		loop = true,
		gain = 0.4,
	})
end

local function startbuzz(pos)
	local hash = minetest.hash_node_position(pos)
	if celevator.drives.null.soundhandles[hash] == "cancel" then
		celevator.drives.null.soundhandles[hash] = nil
		return
	end
	if celevator.drives.null.soundhandles[hash] then return end
	celevator.drives.null.soundhandles[hash] = "pending"
	minetest.after(0.5,playbuzz,pos)
end

local function stopbuzz(pos)
	local hash = minetest.hash_node_position(pos)
	if not celevator.drives.null.soundhandles[hash] then return end
	if celevator.drives.null.soundhandles[hash] == "pending" then
		celevator.drives.null.soundhandles[hash] = "cancel"
	end
	if type(celevator.drives.null.soundhandles[hash]) ~= "string" then
		minetest.sound_stop(celevator.drives.null.soundhandles[hash])
		celevator.drives.null.soundhandles[hash] = nil
	end
end

minetest.register_node("celevator:drive",{
	description = celevator.drives.entity.name,
	groups = {
		cracky = 1,
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
		meta:set_string("state","stopped")
		meta:set_string("startpos","0")
		meta:set_string("origin",minetest.pos_to_string(vector.new(-726,9,77)))
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
	},
})

function celevator.drives.entity.nodestoentities(nodes)
	local refs = {}
	for _,pos in ipairs(nodes) do
		local node = minetest.get_node(pos)
		local eref = minetest.add_entity(pos,"celevator:car_moving")
		eref:set_properties({
			wield_item = node.name,
		})
		eref:set_yaw(minetest.dir_to_yaw(minetest.fourdir_to_dir(node.param2)))
		minetest.remove_node(pos)
		table.insert(refs,eref)
	end
	return refs
end

function celevator.drives.entity.entitiestonodes(refs)
	for _,eref in ipairs(refs) do
		local pos = vector.round(eref:get_pos())
		local node = {
			name = eref:get_properties().wield_item,
			param2 = minetest.dir_to_fourdir(minetest.yaw_to_dir(eref:get_yaw()))
		}
		minetest.set_node(pos,node)
		eref:remove()
	end
end

function celevator.drives.entity.step()
	local entitydrives_running = minetest.deserialize(celevator.storage:get_string("entitydrives_running")) or {}
	local save = false
	for i,hash in ipairs(entitydrives_running) do
		save = true
		local pos = minetest.get_position_from_hash(hash)
		local node = minetest.get_node(pos)
		local sound = false
		if node.name == "ignore" then
			minetest.forceload_block(pos,true)
		elseif node.name ~= "celevator:drive" then
			table.remove(entitydrives_running,i)
		else
			local meta = minetest.get_meta(pos)
			local state = meta:get_string("state")
			if not (state == "running" or state == "start") then
				table.remove(entitydrives_running,i)
			else
				local dpos = tonumber(meta:get_string("dpos")) or 0
				local maxvel = tonumber(meta:get_string("maxvel")) or 0.2
				local startpos = tonumber(meta:get_string("startpos")) or 0
				local origin = minetest.string_to_pos(meta:get_string("origin"))
				if not origin then
					minetest.log("error","[celevator] [entity drive] Invalid origin for drive at "..minetest.pos_to_string(pos))
					table.remove(entitydrives_running,i)
				end
				if state == "start" then
					sound = true
					local handles = celevator.drives.entity.nodestoentities({vector.add(origin,vector.new(0,startpos,0))})
					celevator.drives.entity.entityinfo[hash] = {
						handles = handles,
					}
					meta:set_string("state","running")
				elseif state == "running" then
					local handles = celevator.drives.entity.entityinfo[hash].handles
					local apos = handles[1]:get_pos().y - origin.y
					local dremain = math.abs(dpos-apos)
					local dmoved = math.abs(apos-startpos)
					local vel
					if dremain < 0.05 then
						vel = 0
						meta:set_string("state","stopped")
						celevator.drives.entity.entitiestonodes(handles)
						apos = math.floor(apos+0.5)
					elseif dremain < 0.2 then
						vel = 0.2
					elseif dremain < maxvel and dremain < dmoved then
						vel = dremain
					elseif dmoved+0.1 > maxvel then
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
end

minetest.register_globalstep(celevator.drives.entity.step)

function celevator.drives.entity.moveto(pos,target)
	local meta = minetest.get_meta(pos)
	meta:set_string("dpos",tostring(target))
	meta:set_string("state","start")
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
		table.insert(entitydrives_running,hash)
		celevator.storage:set_string("entitydrives_running",minetest.serialize(entitydrives_running))
		meta:set_string("vel","0.0001") --Controller needs to see something so it knows the drive is running
	end
end


function celevator.drives.entity.resetpos(pos)
	celevator.drives.entity.moveto(pos,0)
end

function celevator.drives.entity.estop(pos)
	local meta = minetest.get_meta(pos)
	if meta:get_string("state") == "stopped" then return end
	local apos = math.floor(tonumber(meta:get_string("apos"))+0.5)
	meta:set_string("dpos",tostring(apos))
	local hash = minetest.hash_node_position(pos)
	local handles = celevator.drives.entity.entityinfo[hash].handles
	meta:set_string("state","stopped")
	meta:set_string("vel","0")
	celevator.drives.entity.entitiestonodes(handles)
	stopbuzz(pos)
end


function celevator.drives.entity.setmaxvel(pos,maxvel)
	local meta = minetest.get_meta(pos)
	meta:set_string("maxvel",tostring(maxvel))
end


function celevator.drives.entity.rezero(pos)
	celevator.drives.entity.moveto(pos,0)
end

function celevator.drives.entity.getstatus(pos,call2)
	local node = minetest.get_node(pos)
	if node.name == "ignore" and not call2 then
		minetest.forceload_block(pos,true)
		return celevator.drives.null.get_status(pos,true)
	elseif node.name ~= "celevator:drive" then
		minetest.log("error","[celevator] [entity drive] Could not load drive status at "..minetest.pos_to_string(pos))
		return
	else
		local meta = minetest.get_meta(pos)
		local ret = {}
		ret.apos = tonumber(meta:get_string("apos")) or 0
		ret.dpos = tonumber(meta:get_string("dpos")) or 0
		ret.vel = tonumber(meta:get_string("vel")) or 0
		ret.maxvel = tonumber(meta:get_string("maxvel")) or 0.2
		return ret
	end
end
