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
	"digistuff",
}

for _,i in ipairs(integrations) do
	if core.get_modpath(i) then table.insert(components,i) end
end

for _,v in ipairs(components) do
	dofile(string.format("%s/%s.lua",core.get_modpath("celevator"),v))
end
