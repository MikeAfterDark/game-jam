Map = Object:extend()
Map:implement(GameObject)

function Map:init(args)
	self:init_game_object(args)

	self.grid = {}
	self.units = {}

	self.rows = 10
	self.cols = 10

	for i, unit in ipairs(self.player_units) do
		local new_x = i
		local new_y = 1
		local new_unit = Unit({
			group = self.group,
			x = self.x + self.cell_size * ((0 - 0.0) - self.rows / 2),
			y = self.y + self.cell_size * ((0 - 0.0) - self.cols / 2),
			tile_x = new_x, -- top left alinged
			tile_y = new_y,
			w = random:int(1, 1),
			h = random:int(1, 1),
			type = unit.type,
			timeline = unit.timeline,
			cell_size = self.cell_size,
			visible = false,
		})

		table.insert(self.units, new_unit)
	end
end

function Map:update(dt)
	self:update_game_object(dt)
end

function Map:load_next_room()
	-- load the next room from the level data
	for i = 1, self.rows do
		self.grid[i] = {}
		for j = 1, self.cols do
			local color = Color(0.3, 0.3, 0.3, random:float(0.7, 1))
			self.grid[i][j] = random:float() <= 1.9 and { color = color, unit = nil } or nil
		end
	end

	-- spawn each unit onto the board

	-- init each unit for this specific level
	for _, unit in ipairs(self:get_all_alive_units()) do
		if unit.tile_x and unit.tile_y then -- WARN: temp init until levels/room decide where to spawn
			self:place_unit(unit, unit.tile_x, unit.tile_y)
		end
		unit.visible = true
	end

	self.new_room_loaded = true
end

function Map:react_to_beat(args)
	args.unit.spring:pull(0.2, 200, 10)
	self.spring:pull(0.2, 200, 10)
end

function Map:react_to_miss(args)
	args.unit.spring:pull(0.1, 100, 10)
	self.spring:pull(0.1, 100, 10)
end

function Map:beat_tracker(time)
	local speed = 2.1
	self.r = math.cos(time * speed)
end

function Map:get_all_alive_units()
	return (table.select(self.units, function(v)
		return v.hp and v.hp > 0 or false
	end)) or {}
end

function Map:get_random_unit()
	return table.random(self.units) or {}
end

function Map:move_unit(unit, new_x, new_y)
	if self:can_place(unit, new_x, new_y) then
		self:clear_unit(unit)
		self:place_unit(unit, new_x, new_y)
		return true
	else
		return false
	end
end

function Map:can_place(unit, x, y)
	for i = x, x + unit.w - 1 do
		for j = y, y + unit.h - 1 do
			if not self.grid[i] or not self.grid[i][j] then
				print("bounds", i, j)
				return false -- out of bounds
			end

			if self.grid[i][j].unit and self.grid[i][j].unit.id ~= unit.id then
				print("occupied by ", self.grid[i][j].unit.type.name, i, j)
				return false -- occupied
			end
		end
	end
	return true
end

function Map:place_unit(unit, x, y)
	print("Placing: " .. unit.type.name .. " at: ", x, y)
	unit.tile_x = x
	unit.tile_y = y

	for i = x, x + unit.w - 1 do
		for j = y, y + unit.h - 1 do
			self.grid[i][j].unit = unit
		end
	end
end

function Map:clear_unit(unit)
	for i = unit.tile_x, unit.tile_x + unit.w - 1 do
		for j = unit.tile_y, unit.tile_y + unit.h - 1 do
			if self.grid[i] and self.grid[i][j] then
				self.grid[i][j].unit = nil
			end
		end
	end
end

function rects_overlap(a, b) -- unit x unit collision check
	return not (
		a.x + a.w <= b.x --
		or b.x + b.w <= a.x
		or a.y + a.h <= b.y
		or b.y + b.h <= a.y
	)
end

function Map:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.y)
	graphics.rectangle(self.x, self.y, self.cell_size * (self.rows + 4), self.cell_size * (self.cols + 4), 0, 0, Color(0.3, 0.3, 0.3, 0.1))
	graphics.pop()

	graphics.push(self.x, self.y, 1 - self.r, self.spring.x, self.spring.y)
	graphics.rectangle(self.x, self.y, self.cell_size * (self.rows + 2), self.cell_size * (self.cols + 2), 0, 0, Color(0.5, 0.5, 0.5, 0.1))
	graphics.pop()

	graphics.push(self.x, self.y, 0)
	for i = 1, self.rows do
		for j = 1, self.cols do
			local cell = self.grid[i][j]
			if cell then
				graphics.rectangle(
					self.x + self.cell_size * ((i - 0.5) - self.rows / 2),
					self.y + self.cell_size * ((j - 0.5) - self.cols / 2),
					self.cell_size,
					self.cell_size,
					0,
					0,
					cell.color
					-- cell.unit and cell.unit.color or cell.color
				)
			end
		end
	end

	graphics.pop()
end
