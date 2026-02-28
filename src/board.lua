Board = Object:extend()
Board:implement(GameObject)

function Board:init(args)
	self:init_game_object(args)

	self.tiles = {}
	self.tile_map = {}
	for row = 1, self.rows do
		self.tile_map[row] = {}
	end

	local screen_vertical_offset = gh * 0.45
	local depth_scale = 0.543
	local horizontal_scale = 0.635

	local x_axis = {
		x = self.tile_size * horizontal_scale,
		y = self.tile_size * depth_scale,
	}

	local y_axis = {
		x = -self.tile_size * horizontal_scale,
		y = self.tile_size * depth_scale,
	}

	for row = 1, self.rows do
		for col = 1, self.columns do
			local screen_x = self.x + (col - 1) * x_axis.x + (row - 1) * y_axis.x
			local screen_y = self.y + (col - 1) * x_axis.y + (row - 1) * y_axis.y - screen_vertical_offset

			local tile = Tile({
				group = self.group,
				layer = self.layer,
				x = screen_x,
				y = screen_y,
				size = self.tile_size,
				row = row,
				col = col,
				type = random:table(Tile_Type),
			})

			self.tile_map[row][col] = tile
			table.insert(self.tiles, tile)
		end
	end

	self.automata = CellularAutomata({ board = self })
	apply_cellular_automata_rules(self.automata)
	self:automata_step()
end

function Board:automata_step()
	self.automata:step()
end

function Board:mark_line(args)
	local width = args.width or 1
	local r = args.r or (math.pi * 2 * random:float(0, 1))

	local pivot_row = random:int(1, self.rows)
	local pivot_col = random:int(1, self.columns)

	local dir_x = math.cos(r)
	local dir_y = math.sin(r)

	local len = math.sqrt(dir_x * dir_x + dir_y * dir_y)
	dir_x = dir_x / len
	dir_y = dir_y / len

	local half_width = width * 0.5

	local tiles = {}
	for _, tile in ipairs(self.tiles) do
		local dx = tile.col - pivot_col
		local dy = tile.row - pivot_row
		local perp_dist = math.abs(dx * dir_y - dy * dir_x)

		tile.marked = perp_dist <= half_width
		if perp_dist <= half_width then
			table.insert(tile.event_ids, args.event_id)
			table.insert(tiles, tile)
		end
	end
	return tiles
end

function Board:get_tiles_marked_for_event(id)
	local tiles = {}
	for _, tile in ipairs(self.tiles) do
		if table.contains(tile.event_ids, id) then
			table.insert(tiles, tile)
		end
	end
	return tiles
end

function Board:update(dt)
	self:update_game_object(dt)
end

function Board:valid_tile_for_building(building)
	local selected_tile = nil
	for _, tile in ipairs(self.tiles) do
		if tile.selected then
			selected_tile = tile
			break
		end
	end

	if selected_tile == nil or selected_tile.holding then
		return nil, { selected_tile and "tile already contains a " .. selected_tile.holding.type.name }
	end

	local valid, errors = building:is_valid_placement({
		tile = selected_tile,
		adjacent_tiles = self:get_adjacent_tiles(selected_tile),
	})

	return valid and selected_tile or nil, errors
end

function Board:trigger_buildings()
	local stages = { "modifiers", "bonus", "secrets" }
	local results = { order = {} }

	for _, stage in ipairs(stages) do
		table.insert(results.order, stage)
		results[stage] = {}
	end

	for _, stage in ipairs(stages) do
		for i = 1, #self.tiles do
			local tile = self.tiles[i]
			local building = tile.holding
			if building then
				table.insert(results[stage], {
					building = building,
					results = building:apply({
						stage = stage,
						tile = tile,
						adjacent_tiles = self:get_adjacent_tiles(tile),
					}),
				})
			end
		end
	end

	return results
end

function Board:place(building, tile)
	building:place_on(tile)
	tile:hold(building)
end

function Board:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	graphics.pop()
end

function Board:get_adjacent_tiles(tile)
	local adjacent_tiles = {}

	for i = -1, 1 do
		for j = -1, 1 do
			local row = tile.row + i
			local col = tile.col + j
			if not (i == 0 and j == 0) and self.tile_map[row] and self.tile_map[row][col] then
				table.insert(adjacent_tiles, self.tile_map[row][col])
			end
		end
	end

	return adjacent_tiles
end
