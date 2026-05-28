Map = Object:extend()
Map:implement(GameObject)

function Map:init(args)
	self:init_game_object(args)

	-- for the tiles that make up the map
	self.grid = {}
	-- for the units that take actions
	self.units = {}
	-- for non-action objects that dont
	-- take up a cell and follow a pre-determined set of actions
	self.entities = {}

	self.room_index = 0

	self.rows = 10
	self.cols = 10

	for i, unit in ipairs(self.player_units) do
		local new_x = i
		local new_y = 1
		local new_unit = Unit({
			group = self.group,
			x = self.x + self.cell_size,
			y = self.y + self.cell_size,
			tile_x = new_x, -- top left alinged
			tile_y = new_y,
			w = random:int(1, 1),
			h = random:int(1, 1),
			type = unit.type,
			timeline_type = unit.timeline_type,
			timeline = unit.timeline,
			cell_size = self.cell_size,
			visible = false,
			is_player = true,
			hit_window = 0.1,
		})

		table.insert(self.units, new_unit)
	end

	self.base_reaction_color = Color(0.3, 0.3, 0.3, 0.1)
	self.reaction_color = self.base_reaction_color
	self.reaction_color_t = 0
end

function Map:update(dt)
	self:update_game_object(dt)

	local color_shift_rate = 0.1
	if self.reaction_color_t < 1 then
		self.reaction_color_t = self.reaction_color_t + dt * color_shift_rate
	end
	self.reaction_color = self.reaction_color:lerp(self.base_reaction_color, math.linear, self.reaction_color_t)

	for _, entity in pairs(self.entities) do
		-- possible behaviours for hitting a unit:
		-- > ignore and pass through
		-- > collide and dissapear
		--		> can affect the unit
		--		> doesn't affect the unit
		if entity:is(Projectile) then
			local x = math.round(entity.tile_x, 0)
			local y = math.round(entity.tile_y, 0)
			if x > 0 and y > 0 and x <= self.cols and y <= self.rows then
				local cell = self.grid[x][y]

				if cell and cell.unit then
					if entity.source.is_player ~= cell.unit.is_player then
						local consume_source = cell.unit:take_damage(entity.damage)
						if consume_source then
							entity.dead = true
						end

						if cell.unit.hp <= 0 then
							cell.unit = nil
						end
					end
				end
			end
		end
	end

	-- todo: clear all dead entities from self.entities
	_, self.entities = table.reject(self.entities, function(v)
		return v.dead
	end)
	_, self.units = table.reject(self.units, function(v)
		return v.dead
	end)

	-- for i = 1, self.rows do
	-- 	self.grid[i] = table.map(self.grid[i], function(v)
	-- 		if v.unit and v.unit.dead then
	-- 			v.unit = nil
	-- 		end
	--
	-- 		return v
	-- 	end)
	-- 	-- local cell = self.grid[x][y]
	-- 	-- if cell.unit.dead then
	-- 	-- 	table.delete(self.units, cell.unit)
	-- 	-- 	cell.unit = nil
	-- 	-- end
	-- end
end

function Map:set_song_info(args)
	self.duration = args.duration or -1
end

function Map:room_completed(current_time)
	-- todo: make each room decide its win condition
	local kill_all = table.contains(self.room_data.win, "kill all") --
		and not table.any(self.units, function(v)
			return not v.is_player
		end)

	local survive = (self.duration and current_time > self.duration - 0.1 or false) and
	table.contains(self.room_data.win, "survive")

	return kill_all or survive
end

-- function Map:can_play_next_song()
-- 	self.song_played = self.song_played or false
-- 	if not self.song_played then
-- 		self.song_played = true
-- 		return true
-- 	else
-- 		self.song_finished = true
-- 		return not table.contains(self.room_data.win, "survive")
-- 	end
-- end

function Map:load_next_room()
	for _, entity in pairs(self.entities) do
		entity.dead = true
	end
	self.entities = {}

	if self.room_index == #self.level.map_order then
		print("no more rooms")
		return
	end

	self.room_index = self.room_index + 1
	self.room_data = self.level.map_order[self.room_index]
	self.room = self.level.rooms[self.room_data.filename]

	-- level limitation: sprite must be square, layers must be added to the right in a spritesheet
	self.rows, self.cols = self.room.h, self.room.h
	local layers = self.room.w / self.cols
	self.grid = {}

	-- setup the base layer
	for x = 0, self.rows - 1 do
		local row = {}
		for y = 0, self.cols - 1 do
			local r, g, b, a = self.room:get_pixel(x, y)
			row[y + 1] = a > 0 and { color = Color(r, g, b, a), unit = nil } or nil
		end
		self.grid[x + 1] = row
	end

	-- setup entity/unit layer
	local enemy_spawn_points = {}
	local player_spawn_points = {}
	if layers > 1 then
		local offset = self.rows

		for x = 0, self.rows - 1 do
			for y = 0, self.cols - 1 do
				local r, g, b, a = self.room:get_pixel(x + offset, y)
				if a > 0 and self.grid[x + 1][y + 1] then
					local point = { x = x + 1, y = y + 1 }

					if g == 1 then
						table.insert(player_spawn_points, point)
					elseif r == 1 then
						table.insert(enemy_spawn_points, point)
					end
					-- self.grid[x + 1][y + 1].color = Color(r, g, b, a)
				end
			end
		end
	end

	for i, player in ipairs(self.units) do
		if player.is_player then
			local random_point = table.pop_random(player_spawn_points)

			if random_point then
				player.tile_x = random_point.x
				player.tile_y = random_point.y
			end
		end
	end

	for i, point in ipairs(enemy_spawn_points) do
		local type = random:table(Enemy_Type)
		local new_unit = Unit({
			group = self.group,
			x = self.x + self.cell_size,
			y = self.y + self.cell_size,
			tile_x = point.x, -- top left alinged
			tile_y = point.y,
			w = random:int(1, 1),
			h = random:int(1, 1),
			type = type,
			timeline_type = type.timeline_type,
			timeline = type.timeline,
			cell_size = self.cell_size,
			visible = false,
			hit_window = 0.05,
			accuracy = 0.95,
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

	return { name = self.room_data.filename, offset_beats = self.room_data.offset_beats }
end

function Map:react_to_hit(args)
	if not args.beat then
		return
	end

	args.unit.spring:pull(0.2, 200, 10)
	self.spring:pull(0.2, 200, 10)
	self.reaction_color = args.beat.action.color:clone():darken(0.3)
	self.reaction_color_t = 0

	-- print(table.tostring(args.beat))
	self.counter = (self.counter or 0) + 1
	-- print(self.counter .. ", " .. args.beat.press_accuracy)

	Timing_Judgement({
		group = self.group,
		x = args.unit.x,
		y = args.unit.y,
		accuracy = args.beat.press_accuracy,
		duration = 0.5,
		size = self.cell_size,
	})
end

function Map:react_to_beat()
	-- if not args.beat then
	-- 	return
	-- end

	-- args.unit.spring:pull(0.2, 200, 10)
	self.spring:pull(0.2, 200, 10)
	self.reaction_color = Color(0.3, 0.9, 0.2, 1)
	self.reaction_color_t = 0
end

function Map:all_enemies_act(time)
	local units = table.select(self.units, function(v)
		return not v.is_player
	end)

	for i, unit in ipairs(units) do
		self:handle_enemy_input({ unit = unit, beat = unit:get_next_beat() })
	end
end

function Map:react_to_miss(args)
	args.unit.spring:pull(0.1, 100, 10)
	self.spring:pull(0.1, 100, 10)
	self.counter = (self.counter or 0) + 1

	Timing_Judgement({
		group = self.group,
		x = args.unit.x,
		y = args.unit.y,
		accuracy = 2,
		duration = 0.3,
		size = self.cell_size,
	})
end

function Map:beat_tracker(time, is_new_beat)
	local speed = 2.1
	self.r = math.cos(time * speed)
	self.time = time -- WARN: for janky drawing

	for i, entity in ipairs(self.entities) do
		entity:beat_tracker(time, is_new_beat)
		if entity.tile_x < 0 or entity.tile_x > self.cols + 1 or entity.tile_y < 0 or entity.tile_y > self.rows + 1 then
			entity.dead = true
		end
	end

	_, self.entities = table.reject(self.entities, function(v)
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

	local id = state.spacebar_controls --
		and (input.spacebar.down and Timings.Hold.id or Timings.Beat.id)
		or args.beat.action.id
	local action = Beat_Actions[id]

	if action then
		action(self, args)
	end
end

function Map:handle_enemy_input(args)
	-- enemy AI
	-- if beat is move then
	--		where does unit want to go?
	--		map decides route and moves it
	--	elseif beat is attack then
	--		select based off unit's priority target
	--		map acts out the attack
	--
	if args.beat.action == Timings.Beat then -- move
		local target, range, axis_distance = args.unit:choose_move_target(self:get_all_alive_units(),
			self:get_all_interactible_entities())
		-- WARN: Current issue: randomly chooses new target every beat
		-- TODO: include range and stuff

		local target_x = target.tile_x
		local target_y = target.tile_y
		local new_x, new_y = self:pathfind(args.unit, args.unit.tile_x, args.unit.tile_y, target_x, target_y)
		self:move_unit(args.unit, new_x, new_y)
	elseif args.beat.action == Timings.Hold then -- attack
		local targets, attack = args.unit:choose_attack_targets(self:get_all_alive_units(),
			self:get_all_interactible_entities())
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
		source = args.unit,
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
				if unit.is_player then
					-- print("bounds", i, j)
				end
				return false -- out of bounds
			end

			if self.grid[i][j].unit and self.grid[i][j].unit.id ~= unit.id then
				if unit.is_player then
					-- print("occupied by ", self.grid[i][j].unit.type.name, i, j)
				end
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
		a.x + a.w <= b.x     --
		or b.x + b.w <= a.x
		or a.y + a.h <= b.y
		or b.y + b.h <= a.y
	)
end

function Map:draw()
	local visual_center_x = self.cell_size * math.ceil(self.rows / 2)
	local visual_center_y = self.cell_size * math.ceil(self.cols / 2)
	local visual_x = camera.x -- self.x + visual_center_x
	local visual_y = camera.y -- self.y + visual_center_y
	graphics.push(visual_x, visual_y, self.r, self.spring.x, self.spring.x)
	graphics.rectangle(    --
		visual_x,
		visual_y,
		self.cell_size * 10, --(self.rows + 4),
		self.cell_size * 10, --(self.cols + 4),
		0,
		0,
		self.reaction_color
	)
	graphics.pop()

	graphics.push(visual_x, visual_y, 1 - self.r, self.spring.x, self.spring.x)
	graphics.rectangle( --
		visual_x,
		visual_y,
		self.cell_size * 8, --(self.rows + 2),
		self.cell_size * 8, --(self.cols + 2),
		0,
		0,
		self.reaction_color
	)
	graphics.pop()

	local angle = 3 * math.pi / 2
	local time_spring = 1 + (self.spring.x - 1) * 0.5
	local time_color = self.reaction_color:clone():lighten(0.2)
	time_color.a = 1
	graphics.push(visual_x, visual_y, 0, time_spring, time_spring)
	graphics.arc( --
		"open",
		visual_x,
		visual_y,
		self.cell_size * 6, --(self.rows + 1),
		angle,
		angle + 2 * math.pi * (self.duration and ((self.duration - self.time) / self.duration) or 1),
		time_color,
		self.cell_size
	)
	graphics.pop()

	graphics.push(self.x, self.y, 0)
	for j = 1, self.rows do
		for i = 1, self.cols do
			local cell = self.grid[i][j]
			if cell then
				graphics.rectangle(
					self.x + self.cell_size * i,
					self.y + self.cell_size * j,
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
			{ 1,  0 },
			{ -1, 0 },
			{ 0,  1 },
			{ 0,  -1 },
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

--
--
--
--
--
-- group = self.group,
-- x = args.unit.x,
-- y = args.unit.y,
-- accuracy = args.beat.press_accuracy,
-- duration = 0.5,
-- size = self.cell_size,
--
Timing_Judgement = Object:extend()
Timing_Judgement:implement(GameObject)
function Timing_Judgement:init(args)
	self:init_game_object(args)
	-- self.rs = self.rs or 8
	-- self.duration = self.duration or 0.05
	-- self.color = self.color or fg[0]
	self.opacity = 1

	local text = self.accuracy < -0.8 and "[red]early"
		or self.accuracy < -0.4 and "[orange]almost"
		or self.accuracy < -0.2 and "[green1]good"
		or self.accuracy < 0.2 and "[yellow]perfect"
		or self.accuracy < 0.4 and "[green1]good"
		or self.accuracy < 0.8 and "[orange]delayed"
		or self.accuracy < 1 and "[red]late"
		or "[p_blue1]miss"
	self.text = Text({ { text = text, font = pixul_font, alignment = "center" } }, global_text_tags)
	self.t:after(self.duration, function()
		self.text.dead = true
		self.text = nil

		self.dead = true
	end, "die")

	self.t:tween(self.duration, self, { opacity = 0 }, math.cubic_in)
	self.t:tween(self.duration, self, { y = self.y - self.size }, math.cubic_out)
	return self
end

function Timing_Judgement:update(dt)
	self:update_game_object(dt)

	if self.text then
		self.text:update(dt)
	end
end

function Timing_Judgement:draw()
	if self.text then
		self.text:draw(self.x, self.y - self.size, 0, 1, 1, self.opacity)
	end
end
