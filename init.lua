local components = {
	"framework",
	"car",
	"doors",
	"drive_null",
	"drive_entity",
	"controller",
	"callbuttons",
	"pilantern",
	"fs1switch",
	"dispatcher",
	"dbdkiosk",
	"decorations",
	"crafts",
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
