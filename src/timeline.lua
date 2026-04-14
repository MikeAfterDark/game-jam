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

	self.unit_start_time = 0
	self.time = 0
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

function Timeline:add(unit, song_time)
	for i, tick in ipairs(unit.timeline) do
		local color = tick.color or Color(0, 0, 0, 1)
		table.insert(self.tick_colors, color)
	end

	self.unit = unit
	for i, action in ipairs(unit.timeline) do
		local time = (#self.beats + 1) / self.beats_per_sec
		-- print("inserted time: ", time)
		table.insert(self.beats, Beat({ action = action, unit = unit, time = time }))
	end

	self.unit_start_time = song_time
	print("start time: ", self.unit_start_time)
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

	self.time = time
	return self:beats_left(), miss
end

function Timeline:beats_left()
	return #self.beats - self.beat_index
end

function Timeline:react_to_beat()
	-- self.spring:pull(0.2, 200, 10)
end

function Timeline:react_to_miss()
	-- self.spring:pull(0.1, 100, 10)
end

function Timeline:draw()
	-- TODO: gpt is being stupid
	-- - draw beats to be hit_window wide (either speed up circle or shrink size)
	-- - make sure beats are properly spaced apart
	-- - make sure highlight detection is TIME based, stupid gpt is doing atan garbage
	--
	local unit = self.unit
	graphics.push(unit.x, unit.y, self.r, unit.spring.x, unit.spring.y)

	local radius = self.cell_size * 0.9
	local thickness = radius * 0.3
	graphics.circle(unit.x, unit.y, radius, Color(1, 1, 1, 0.8), thickness)

	local max_beats = 6
	local total_segments = 8
	local radians_per_segment = (2 * math.pi) / total_segments
	local spacing = radians_per_segment * 0.2

	local speed = 1
	local time_offset = (self.time - self.unit_start_time) * speed
	local rotation = time_offset % (2 * math.pi)

	-- 👇 fixed indicator (top of circle)
	local indicator_angle = -math.pi / 2

	for i = 1, max_beats do
		local beat = self.beats[i]
		local action = beat.action or Timings.Empty
		local color = action.color

		local base_angle = (i - 1) * radians_per_segment
		local start_angle = base_angle + spacing / 2 + rotation
		local end_angle = base_angle + radians_per_segment - spacing / 2 + rotation

		-- normalize angles for comparison
		local mid_angle = (start_angle + end_angle) / 2

		-- 👇 detect if this segment is near the indicator
		local diff = math.atan2(math.sin(mid_angle - indicator_angle), math.cos(mid_angle - indicator_angle))
		local hit_window = radians_per_segment * 0.4

		local is_hit = math.abs(diff) < hit_window

		local draw_thickness = thickness
		local draw_color = color

		if is_hit and action ~= Timings.Empty then
			-- highlight hit window
			draw_thickness = thickness * 1.4
			draw_color = Color(1, 1, 1, 1) -- or brighten original color
		end

		graphics.arc("open", unit.x, unit.y, radius, start_angle, end_angle, draw_color, draw_thickness)
	end

	-- 👇 draw indicator line (always on top)
	local line_length = radius + 12
	local ix = unit.x + math.cos(indicator_angle) * radius
	local iy = unit.y + math.sin(indicator_angle) * radius
	local ox = unit.x + math.cos(indicator_angle) * line_length
	local oy = unit.y + math.sin(indicator_angle) * line_length

	graphics.line(ix, iy, ox, oy, Color(1, 1, 1, 1), 2)

	-- local unit = self.unit
	--
	--
	--
	-- graphics.push(unit.x, unit.y, self.r, unit.spring.x, unit.spring.y)
	--
	-- local radius = self.cell_size * 0.9
	-- local thickness = radius * 0.3
	-- graphics.circle(unit.x, unit.y, radius, Color(1, 1, 1, 0.8), thickness)
	--
	-- local radians_per_beat = 2 * math.pi / 8 -- should be able to change depending on user preferences with how fast the circle moves, but this might put actions out of view so idk
	-- local spacing = math.pi / 16
	-- local speed = 1
	-- local max_beats = 6
	-- for i = 1, max_beats do
	-- 	local beat = self.beats[i]
	-- 	local action = beat.action or Timings.Empty
	--
	-- 	local time_offset = self.time - self.unit_start_time
	--
	-- 	local start_angle = i * (radians_per_beat + spacing) + time_offset * speed
	-- 	local end_angle = (i + 1) * (radians_per_beat - spacing) + time_offset * speed
	-- 	local beat_color = action.color
	-- 	graphics.arc("open", unit.x, unit.y, radius, start_angle, end_angle, beat_color, thickness)
	-- end
	--
	--
	--
	--
	--

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
