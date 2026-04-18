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
	local time = ((#self.beats + 1) / self.beats_per_sec)
	table.insert(self.beats, Beat({ action = Timings.Empty, unit = unit, time = time }))
	for i, action in ipairs(unit.timeline) do
		time = ((#self.beats + 1) / self.beats_per_sec)
		table.insert(self.beats, Beat({ action = action, unit = unit, time = time }))
	end

	self.unit_start_time = song_time
	self.unit_start_index = self.beat_index
end

-- returns true if a valid beat was hit
function Timeline:beat_hit_at(time)
	-- get all the beats that get hit at that time within their hit window
	-- figure out which one is closest to perfect
	-- 'miss' all the ones before it
	-- increment beat_index up to its at/ahead of the hit beat
	local hit_beats = {}
	for i = self.beat_index, #self.beats do
		local beat_time = self.beats[i].time
		if self:beat_can_be_hit_at(beat_time, time) then
			-- print("including: ", past, time, future)
			local min_time_offset = math.min(time - self:past(beat_time), self:future(beat_time) - time)
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
		local is_new_beat = true
		return closest_hit.beat, closest_hit.time_offset, is_new_beat
	else
		return false
	end
end

function Timeline:beat_can_be_hit_at(beat_time, hit_time)
	return self.beats[self.beat_index].action ~= Timings.Empty --
		and hit_time >= self:past(beat_time)
		and hit_time <= self:future(beat_time)
end

function Timeline:past(time)
	return time - self.hit_window
end

function Timeline:future(time)
	return time + self.hit_window
end

-- returns number of beats left, updates beat positions
function Timeline:beat_tracker(time)
	local missed_beat = nil
	local is_new_beat = false
	for i = self.beat_index, #self.beats do
		local beat = self.beats[i]
		if time > self:future(beat.time) then
			self.beat_index = i + 1
			is_new_beat = true

			if beat.action ~= Timings.Empty then
				missed_beat = beat
			end
			break
		end
	end

	self.time = time
	return self:beats_left(), missed_beat, is_new_beat
end

function Timeline:beats_left()
	return #self.beats - self.beat_index
end

function Timeline:react_to_hit()
	-- self.spring:pull(0.2, 200, 10)
end

function Timeline:react_to_miss()
	-- self.spring:pull(0.1, 100, 10)
end

function Timeline:draw()
	local unit = self.unit
	graphics.push(unit.x, unit.y, self.r, unit.spring.x, unit.spring.y)

	local radius = self.cell_size * 0.9
	local thickness = radius * 0.3
	graphics.circle(unit.x, unit.y, radius, Color(1, 1, 1, 0.8), thickness * 1.2)

	local tau = 2 * math.pi
	local speed = 2

	local radians_per_segment = speed * (tau / self.max_beats)
	local rotation_speed = self.beats_per_sec * radians_per_segment
	local max_visible_time = tau / rotation_speed

	local i = #self.beats
	while i >= self.beat_index do
		local beat = self.beats[i]

		if beat and beat.action ~= Timings.Empty then
			local dt = beat.time - self.time

			if math.abs(dt) <= max_visible_time then
				local angle = dt * rotation_speed

				if angle < math.pi * 1.6 and angle > -math.pi * 1.5 then -- visibility range
					-- angle = (angle + math.pi) % tau - math.pi

					local hit_window_angle = self.hit_window * rotation_speed
					local spacing = radians_per_segment * 0.1

					angle = angle - math.pi / 2
					local start_angle = angle - hit_window_angle + spacing * 0.5
					local end_angle = angle + hit_window_angle - spacing * 0.5

					local draw_thickness = thickness
					local draw_color = beat.action.color

					local background_color = Color(0, 0, 0, 1)
					local background_width = spacing * 0.5

					local tick_size = 0.05
					local tick_start_angle = angle - tick_size
					local tick_end_angle = angle + tick_size

					if self:beat_can_be_hit_at(beat.time, self.time) then
						draw_thickness = thickness * 1.4
						draw_color = draw_color:clone():lighten(0.6)
					end

					local tick_color = draw_color:clone():darken(0.3)

					graphics.arc(
						"open",
						unit.x,
						unit.y,
						radius,
						start_angle - background_width,
						end_angle + background_width,
						background_color,
						draw_thickness * 1.5
					)
					graphics.arc("open", unit.x, unit.y, radius, start_angle, end_angle, draw_color, draw_thickness)
					graphics.arc("open", unit.x, unit.y, radius, tick_start_angle, tick_end_angle, tick_color,
						draw_thickness / 2)
				end
			end
		end

		i = i - 1
	end
	local indicator_angle = -math.pi / 2
	local line_length = radius + 12
	local ix = unit.x + math.cos(indicator_angle) * radius
	local iy = unit.y + math.sin(indicator_angle) * radius
	local ox = unit.x + math.cos(indicator_angle) * line_length
	local oy = unit.y + math.sin(indicator_angle) * line_length

	graphics.line(ix, iy, ox, oy, Color(0, 0, 0, 1), 5)

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
