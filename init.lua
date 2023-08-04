local components = {
	"framework",
	"drive_null",
	"controller",
	"callbuttons",
	"pairingtool",
}

for _,v in ipairs(components) do
	dofile(string.format("%s%s%s.lua",minetest.get_modpath("celevator"),DIR_DELIM,v))
end
