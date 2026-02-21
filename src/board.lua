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

	-- back to front ordering
	for sum = 2, self.rows + self.columns do
		for row = 1, self.rows do
			local col = sum - row

			if col >= 1 and col <= self.columns then
				local screen_x = self.x + (col - 1) * x_axis.x + (row - 1) * y_axis.x
				local screen_y = self.y + (col - 1) * x_axis.y + (row - 1) * y_axis.y - screen_vertical_offset

				local tile = Tile({
					group = self.group,
					x = screen_x,
					y = screen_y,
					size = self.tile_size,
					angle = math.pi * 0.25,
					row = row,
					col = col,
					type = random:table(Tile_Type),
				})
				self.tile_map[row][col] = tile
				table.insert(self.tiles, tile)
			end
		end
	end
end

function Board:update(dt)
	self:update_game_object(dt)
end

-- check if tile matches requirements, return tile if yes, return nil in all other cases
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

	local adjacent_tiles = {}

	for i = -1, 1 do
		for j = -1, 1 do
			local row = selected_tile.row + i
			local col = selected_tile.col + j

			if not (i == 0 and j == 0) and self.tile_map[row] and self.tile_map[row][col] then
				table.insert(adjacent_tiles, self.tile_map[row][col])
			end
		end
	end

	local valid, errors = building:is_valid_placement({
		tile = selected_tile,
		adjacent_tiles = adjacent_tiles,
		building = building,
	})
	return valid and selected_tile or nil, errors
end

function Board:place(building, tile)
	building:place_on(tile)
	tile:hold(building)
end

function Board:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	graphics.pop()
end
