local gbb = {}

-- local logger = require("libsote.debug-loggers").get_soils_logger("d:/temp")

local clay_quantity
local silt_quantity
local sand_quantity
local mineral_quantity

function gbb.run(world)
	clay_quantity = world.tmp_int_1
	silt_quantity = world.tmp_int_2
	sand_quantity = world.tmp_int_3
	mineral_quantity = world.tmp_int_4

	world:fill_ffi_array(clay_quantity, 0)
	world:fill_ffi_array(silt_quantity, 0)
	world:fill_ffi_array(sand_quantity, 0)
	world:fill_ffi_array(mineral_quantity, 0)

	--* ---We need a "tag" variable on tiles. We need to bring in soil texture and mineral nutrient values + logic values for each.
	--* ---Expand around tile X times. More is technically better, but will become costly quickly I think.
	--* ---Store tiles in list of effected tiles. Do no math until the end. Take percentage of each quantity based on "tiles tagged"

	--* ---At the very, very, very end of the process, iterate through all land tiles in the world divide all values by "tiles tagged" variable to
	--* furnish us with final quantity

	-- local land_tiles = {}
	-- world:for_each_tile(function(ti)
	-- 	if not world.is_land[ti] then return end
	-- 	table.insert(land_tiles, ti)
	-- end)

	local tiles_to_expand = 100 --* How far each tile will share its material. Has diminishing effect the further out you go.

	while tiles_to_expand > 0 do
		tiles_to_expand = tiles_to_expand - 1

		for ti = 0, world.tile_count - 1 do
		-- for _, ti in ipairs(land_tiles) do
			if not world.is_land[ti] then goto continue1 end

			local num_neighs = world:neighbors_count(ti)

			local sand_to_contribute = math.floor(world.sand[ti] / (num_neighs + 1))
			local silt_to_contribute = math.floor(world.silt[ti] / (num_neighs + 1))
			local clay_to_contribute = math.floor(world.clay[ti] / (num_neighs + 1))
			local mineral_to_contribute = math.floor(world.mineral_richness[ti] / (num_neighs + 1))
			-- logger:log(ti .. ": " .. sand_to_contribute .. " " .. silt_to_contribute .. " " .. clay_to_contribute .. " " .. mineral_to_contribute)

			for i = 0, num_neighs - 1 do
				local nti = world.neighbors[ti * 6 + i]

				if world.is_land[nti] then
					sand_quantity[nti] = sand_quantity[nti] + sand_to_contribute
					silt_quantity[nti] = silt_quantity[nti] + silt_to_contribute
					clay_quantity[nti] = clay_quantity[nti] + clay_to_contribute
					mineral_quantity[nti] = mineral_quantity[nti] + mineral_to_contribute

					world.sand[ti] = world.sand[ti] - sand_to_contribute
					world.silt[ti] = world.silt[ti] - silt_to_contribute
					world.clay[ti] = world.clay[ti] - clay_to_contribute
					world.mineral_richness[ti] = world.mineral_richness[ti] - mineral_to_contribute
				end
			end

			::continue1::
		end

		for ti = 0, world.tile_count - 1 do
		-- for _, ti in ipairs(land_tiles) do
			if not world.is_land[ti] then goto continue2 end

			world.sand[ti] = world.sand[ti] + sand_quantity[ti]
			world.silt[ti] = world.silt[ti] + silt_quantity[ti]
			world.clay[ti] = world.clay[ti] + clay_quantity[ti]
			world.mineral_richness[ti] = world.mineral_richness[ti] + mineral_quantity[ti]

			sand_quantity[ti] = 0
			silt_quantity[ti] = 0
			clay_quantity[ti] = 0
			mineral_quantity[ti] = 0

			::continue2::
		end

		-- world:fill_ffi_array(clay_quantity, 0)
		-- world:fill_ffi_array(silt_quantity, 0)
		-- world:fill_ffi_array(sand_quantity, 0)
		-- world:fill_ffi_array(mineral_quantity, 0)
	end

	-- world:for_each_tile(function(ti)
	-- 	if not world.is_land[ti] then return end
	-- 	logger:log(ti .. ": " .. world.sand[ti] .. " " .. world.silt[ti] .. " " .. world.clay[ti] .. " " .. world.mineral_richness[ti])
	-- end)
end

return gbb