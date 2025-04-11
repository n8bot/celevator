local components = {
	"framework",
	"car",
	"car_standard",
	"car_glassback",
	"car_metal",
	"car_metalglass",
	"doors",
	"drive_null",
	"drive_entity",
	"controller",
	"callbuttons",
	"pilantern",
	"fs1switch",
	"dispatcher",
	"dbdkiosk",
	"genericswitch",
	"decorations",
	"governor",
	"crafts",
	"chatcommands",
}

local integrations = {
	"laptop",
	"mesecons",
	"digilines",
}

for _,i in ipairs(integrations) do
	if minetest.get_modpath(i) then table.insert(components,i) end
end

for _,v in ipairs(components) do
	dofile(string.format("%s%s%s.lua",minetest.get_modpath("celevator"),DIR_DELIM,v))
end
