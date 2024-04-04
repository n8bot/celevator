local components = {
	"framework",
	"car",
	"doors",
	"drive_null",
	"drive_entity",
	"controller",
	"callbuttons",
	"pilantern",
}

for _,v in ipairs(components) do
	dofile(string.format("%s%s%s.lua",minetest.get_modpath("celevator"),DIR_DELIM,v))
end
