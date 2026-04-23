Map = Object:extend()
Map:implement(GameObject)

function Map:init(args)
	self:init_game_object(args)

	self.grid = {} -- for the tiles that make up the map
	self.units = {} -- for the units that take actions
	self.entities = {} -- for non-action objects that dont take up a cell and follow a pre-determined set of actions

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
			is_player = true,
		})

		table.insert(self.units, new_unit)
	end

	self.base_reaction_color = Color(0.3, 0.3, 0.3, 0.1)
	self.reaction_color = self.base_reaction_color
	self.reaction_color_t = 0
end

function Map:update(dt)
	self:update_game_object(dt)

	local speed = 0.1
	if self.reaction_color_t < 1 then
		self.reaction_color_t = self.reaction_color_t + dt * speed
	end
	self.reaction_color = self.reaction_color:lerp(self.base_reaction_color, math.linear, self.reaction_color_t)
end

function Map:load_next_room()
	-- todo:
	-- make sure self.units only has 'alive' units (should be only player units)
	for _, entity in pairs(self.entities) do
		entity.dead = true
	end
	self.entities = {}

	-- load the next room from the level data
	for i = 1, self.rows do
		self.grid[i] = {}
		for j = 1, self.cols do
			local shade = random:float(0.2, 0.4)
			local color = Color(shade, shade, shade, 1)
			self.grid[i][j] = random:float() <= 1.9 and { color = color, unit = nil } or nil
		end
	end

	-- spawn each unit onto the board
	local num_enemies = 3
	for i = 1, num_enemies do
		local new_x = self.cols - i
		local new_y = self.rows
		local type = random:table(Enemy_Type)
		local new_unit = Unit({
			group = self.group,
			x = self.x + self.cell_size * ((0 - 0.0) - self.rows / 2),
			y = self.y + self.cell_size * ((0 - 0.0) - self.cols / 2),
			tile_x = new_x, -- top left alinged
			tile_y = new_y,
			w = random:int(1, 1),
			h = random:int(1, 1),
			type = type,
			timeline = type.timeline,
			cell_size = self.cell_size,
			visible = false,
		})

		table.insert(self.units, new_unit)
	end

	-- init each unit for this specific level
	for _, unit in ipairs(self:get_all_alive_units()) do
		if unit.tile_x and unit.tile_y then -- WARN: temp init until levels/room decide where to spawn
			self:place_unit(unit, unit.tile_x, unit.tile_y)
		end
		unit.visible = true
	end

	self.new_room_loaded = true
end

function Map:react_to_hit(args)
	args.unit.spring:pull(0.2, 200, 10)
	self.spring:pull(0.2, 200, 10)
	self.reaction_color = args.beat.action.color:clone():darken(0.3)
	self.reaction_color_t = 0

	if not args.unit.is_player then -- player actions handled in handle_press()
		-- enemy AI
		-- if beat is move then
		--		where does unit want to go?
		--		map decides route and moves it
		--	elseif beat is attack then
		--		select based off unit's priority target
		--		map acts out the attack

		if args.beat.action == Timings.Beat then -- move
			local target, range, axis_distance = args.unit:choose_move_target(self:get_all_alive_units(), self:get_all_interactible_entities())
			-- WARN: Current issue: randomly chooses new target every beat

			-- TODO: include range and stuff

			local target_x = target.tile_x
			local target_y = target.tile_y
			local new_x, new_y = self:pathfind(args.unit, args.unit.tile_x, args.unit.tile_y, target_x, target_y)
			self:move_unit(args.unit, new_x, new_y)
		elseif args.beat.action == Timings.Hold then -- attack
			local targets, attack = args.unit:choose_attack_targets(self:get_all_alive_units(), self:get_all_interactible_entities())
			-- WARN: Current issue: randomly chooses new target every beat
			--
			if targets and #targets > 0 and attack then
				table.insert(
					self.entities,
					attack({
						source = args.unit,
						targets = targets,
						map = self,
					})
				)
			end
		end
	end
end

function Map:all_enemies_act(time)
	for i, unit in ipairs(self.units) do
		if not unit.is_player then
			local data = { unit = unit, beat = unit:get_next_beat() }
			self:react_to_hit(data)
		end
	end
end

function Map:react_to_miss(args)
	args.unit.spring:pull(0.1, 100, 10)
	self.spring:pull(0.1, 100, 10)
end

function Map:beat_tracker(time, is_new_beat)
	local speed = 2.1
	self.r = math.cos(time * speed)

	for i, entity in ipairs(self.entities) do
		entity:beat_tracker(time, is_new_beat)
		if entity.tile_x < 0 or entity.tile_x > self.cols + 1 or entity.tile_y < 0 or entity.tile_y > self.rows + 1 then
			entity.dead = true
		end
	end

	table.reject(self.entities, function(v)
		return v.dead == true
	end)
end

Beat_Actions = {
	Empty = function(self, args) end,

	Beat = function(self, args)
		self:move_unit(args.unit, args.tile_x, args.tile_y)
	end,

	Hold = function(self, args)
		self:shoot(args)
	end,

	Special = function(self, args) end,
}

local directions = {
	up = { x = 0, y = -1 },
	down = { x = 0, y = 1 },
	left = { x = -1, y = 0 },
	right = { x = 1, y = 0 },
}

function Map:handle_press(args)
	args.tile_x = args.unit.tile_x + args.dir.x
	args.tile_y = args.unit.tile_y + args.dir.y

	local action = Beat_Actions[args.beat.action.id]
	if action then
		action(self, args)
	end
end

function Map:get_all_alive_units()
	return (table.select(self.units, function(v)
		return v.hp and v.hp > 0 or false
	end)) or {}
end

function Map:get_all_interactible_entities()
	return (table.select(self.entities, function(v)
		return not v:is(Projectile)
	end)) or {}
end

function Map:get_random_unit()
	return table.random(self.units) or {}
end

function Map:shoot(args)
	-- spawn a projectile that updates based on the beat
	-- projectile type selected based on the unit that fired it
	-- projectile updates based on its type
	local projectile_type = args.unit:get_projectile_type()
	local projectile = Projectile({
		group = self.group,
		x = args.unit.base_x,
		y = args.unit.base_y,
		tile_x = args.unit.tile_x, -- top left alinged
		tile_y = args.unit.tile_y,
		dir_x = args.dir.x,
		dir_y = args.dir.y,
		cell_size = self.cell_size,
		type = projectile_type,
	})

	table.insert(self.entities, projectile)
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
				-- print("bounds", i, j)
				return false -- out of bounds
			end

			if self.grid[i][j].unit and self.grid[i][j].unit.id ~= unit.id then
				-- print("occupied by ", self.grid[i][j].unit.type.name, i, j)
				return false -- occupied
			end
		end
	end
	return true
end

function Map:place_unit(unit, x, y)
	-- print("Placing: " .. unit.type.name .. " at: ", x, y)
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
	graphics.rectangle(self.x, self.y, self.cell_size * (self.rows + 4), self.cell_size * (self.cols + 4), 0, 0, self.reaction_color)
	graphics.pop()

	graphics.push(self.x, self.y, 1 - self.r, self.spring.x, self.spring.y)
	graphics.rectangle(self.x, self.y, self.cell_size * (self.rows + 2), self.cell_size * (self.cols + 2), 0, 0, self.reaction_color)
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

function Map:pathfind(unit, x1, y1, x2, y2)
	local function key(x, y)
		return y * 10000 + x
	end

	local queue = {}
	local came_from = {}
	local visited = {}

	table.insert(queue, { x = x1, y = y1 })
	visited[key(x1, y1)] = true

	local found = false

	while #queue > 0 do
		local current = table.remove(queue, 1)

		if current.x == x2 and current.y == y2 then
			found = true
			break
		end

		local dirs = {
			{ 1, 0 },
			{ -1, 0 },
			{ 0, 1 },
			{ 0, -1 },
		}

		for _, d in ipairs(table.shuffle(dirs)) do -- shuffle to spice up pathfinding
			local nx = current.x + d[1]
			local ny = current.y + d[2]
			local k = key(nx, ny)

			if not visited[k] then
				local can_move = self:can_place(unit, nx, ny)

				if can_move or (nx == x2 and ny == y2) then
					visited[k] = true
					came_from[k] = current
					table.insert(queue, { x = nx, y = ny })
				end
			end
		end
	end

	if not found then
		return x1, y1
	end

	-- reconstruct path
	local path = {}
	local current = { x = x2, y = y2 }

	while current do
		table.insert(path, 1, current)
		local k = key(current.x, current.y)
		current = came_from[k]
	end

	if #path > 1 then
		return path[2].x, path[2].y
	end

	return x1, y1
end
