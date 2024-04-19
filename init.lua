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
}

for _,v in ipairs(components) do
	dofile(string.format("%s%s%s.lua",minetest.get_modpath("celevator"),DIR_DELIM,v))
end
