Timeline = Object:extend()
Timeline:implement(GameObject)
function Timeline:init(args)
	self:init_game_object(args)

	self.tick_count = 12
	self.tick_colors = {}
	for i = 1, 8 do
		local color = Color(1, 1, 1, 1) --random:color()
		table.insert(self.tick_colors, color)
	end

	self.tick_offset = 0
	self.draw_circle = 0

	self.beats = {}
	self.beat_index = 1
end

function Timeline:update(dt)
	self:update_game_object(dt)

	local delta = self.beat_spread * dt * self.beats_per_sec
	local prev_tick = self.tick_offset
	self.tick_offset = (self.tick_offset + delta) % self.beat_spread

	if prev_tick > self.tick_offset then -- we looped
		local consumed_tick
		if #self.tick_colors > 0 then
			consumed_tick, self.tick_colors = table.shift(self.tick_colors)
		end

		self.draw_circle = 20
		trigger:tween(0.2, self, { draw_circle = 0 }, math.linear)
	end
end

function Timeline:add(unit)
	for i, tick in ipairs(unit.timeline) do
		local color = tick.color or Color(0, 0, 0, 1)
		table.insert(self.tick_colors, color)
	end

	for i, action in ipairs(unit.timeline) do
		local time = (#self.beats + 1) / self.beats_per_sec
		-- print("inserted time: ", time)
		table.insert(self.beats, Beat({ action = action, unit = unit, time = time }))
	end
end

-- returns true if a valid beat was hit
function Timeline:beat_hit_at(time)
	-- get all the beats that get hit at that time within their hit window
	-- figure out which one is closest to perfect
	-- 'miss' all the ones before it
	-- increment beat_index up to its at/ahead of the hit beat
	local hit_beats = {}
	for i = self.beat_index, #self.beats do
		local past = self.beats[i].time - self.hit_window
		local future = self.beats[i].time + self.hit_window
		if time >= past and time <= future then
			-- print("including: ", past, time, future)
			local min_time_offset = math.min(time - past, future - time)
			table.insert(hit_beats, { beat = self.beats[i], index = i, time_offset = min_time_offset })
		else
			break
		end
	end

	table.sort(hit_beats, function(a, b)
		return a.time_offset < b.time_offset
	end)
	local closest_hit = hit_beats[1]

	if closest_hit then
		self.beat_index = closest_hit.index + 1
		return closest_hit.beat, closest_hit.time_offset
	else
		return false
	end
end

-- returns number of beats left, updates beat positions
function Timeline:beat_tracker(time)
	local miss = false
	for i = self.beat_index, #self.beats do
		local future = self.beats[i].time + self.hit_window
		if time > future then
			self.beat_index = i + 1
			miss = true
			break
		end
	end

	return self:beats_left(), miss
end

function Timeline:beats_left()
	return #self.beats - self.beat_index
end

function Timeline:draw()
	graphics.push(self.x, self.y, self.r)

	-- local line_color = Color(1, 1, 1, 1)
	-- local line_thickness = 5
	-- graphics.line(self.x - self.w / 2, self.y, self.x + self.w / 2, self.y, line_color, line_thickness)
	-- graphics.line(self.x - self.w / 2, self.y - 20, self.x - self.w / 2, self.y + 20, line_color, line_thickness)
	--
	-- local tick_height = 20
	-- local tick_thickness = tick_height * 0.4
	-- for i = 1, self.tick_count, 1 do
	-- 	local x = (self.x - self.w / 2) + i * self.beat_spread - self.tick_offset
	-- 	-- local x = i * self.beat_spread - self.tick_offset
	-- 	graphics.line(x, self.y - tick_height, x, self.y + tick_height, self.tick_colors[i], tick_thickness)
	-- end
	--
	-- if self.draw_circle > 0 then
	-- 	graphics.circle(self.x - self.w / 2, self.y, self.draw_circle, Color(1, 0, 0, 1))
	-- end

	graphics.pop()
end

Beat = function(args)
	local self = {
		action = args.action,
		unit = args.unit,
		time = args.time,
		hit = -1,
	}

	-- function self.a()
	--     return 1
	-- end

	return self
end
