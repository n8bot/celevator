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

if minetest.get_modpath("laptop") then
	table.insert(components,"laptop")
end

for _,v in ipairs(components) do
	dofile(string.format("%s%s%s.lua",minetest.get_modpath("celevator"),DIR_DELIM,v))
end
