Map = Object:extend()
Map:implement(GameObject)
function Map:init(args)
	self:init_game_object(args)

	self.folder = args.folder
	self.song = Map_Song(self.folder, { { tags = music } })
	self.data = self:load_map_data()
	self.floor = args.floor
	self.recording = args.recording

	self.bpm = self.data.bpm
	self.offset = not web and self.data.offset or 0 -- no seek in web
	self.speed = self.data.speed or 10

	self.song_position = self.offset
	self.crotchet = 60 / self.bpm
	self.beat = 1

	self.score = 0
	self.accuracy = 0
	self.hits = 0
	self.misses = 0

	self.notes = {}
	if not self.recording then
		for i, note in ipairs(self.data.notes) do
			local asset = note.beats > 1 and (note.color == "red" and red_centipede or blue_centipede)
				or (note.color == "red" and red_rock_bug or blue_rock_bug)
			self.notes[i] = Note({
				group = self.group,
				time = note.time,
				note_color = note.color,
				lane = note.lane,
				beats = note.beats,
				name = i,
				x = gw * 0.5 + (gw * 0.2 * (note.lane - 1.5)) * (note.color == "red" and 0.6 or 1),
				y = self.floor - (note.time - self.offset) * self.speed * 10,
				size = 0.2 * global_game_scale,
				speed = self.speed,
				spacing = self.spacing,
				asset = asset,
			})
		end
		if #self.notes > 0 then
			self.notes[self.beat].color = red[0]
		end
	end
end

function Map:load_map_data()
	local path = "maps/" .. self.folder .. "/map.lua"

	local chunk, err = love.filesystem.load(path)
	if not chunk then
		error("Failed to load map for (" .. self.folder .. "): " .. err)
	end

	local data = chunk()
	return data
end

function Map:save_map_data()
	local data_str = "return {\n"

	data_str = data_str .. string.format("bpm = %d, \n", self.bpm or 120)
	data_str = data_str .. string.format("speed = %d, \n", self.speed or 30)

	data_str = data_str .. string.format("notes = {\n")
	for _, note in ipairs(self.notes) do
		data_str = data_str
			.. string.format('    { time = %.2f, color = "%s", lane = %d, beats = %d },\n', note.time, note.color, note.lane, note.beats or 1)
	end
	data_str = data_str .. "  }\n}"

	local path = "maps/" .. self.folder .. "/map.lua"
	local file = io.open(path, "w")
	if file then
		file:write(data_str)
		file:close()
		print("written to file successfully at: " .. path)
	else
		print("failed to open file for writing at: " .. path)
	end
end

function Map:start()
	self.song:play({
		volume = 0.1 or state.music_volume,
		seek = self.offset,
		fadeDuration = 0,
	})
	self.song_start_time = love.timer.getTime()

	if not self.recording then
		for _, note in ipairs(self.notes) do
			note:start()
		end
	end
end

function Map:update()
	local volume = (music and music.volume or state.music_volume or 0.1)
	self.song.volume = volume

	self.song_position = self:get_song_position()
	self:update_note_tracking()

	self:update_score()

	local current_beat = math.floor(self.song_position / self.crotchet)
	self._last_beat = self._last_beat or -1
	if current_beat > self._last_beat then
		beat_alpha = 0.05 -- immediate flash value
		trigger:tween(0.3, _G, { beat_alpha = 0 }, math.cubic_out, nil, "beat_flash")
		self._last_beat = current_beat
	else
		beat = false
	end
end

function Map:pause()
	self.song:pause()
	self.was_paused = true
	self.pause_start_time = love.timer.getTime()
end

function Map:unpause()
	if not self.was_paused then
		return
	end
	self.was_paused = false

	local pause_duration = love.timer.getTime() - (self.pause_start_time or love.timer.getTime())
	self.total_paused_time = (self.total_paused_time or 0) + pause_duration
	self.pause_start_time = nil
	self.song:resume()
end

function Map:update_note_tracking()
	local current = self:get_current_note()
	if not current then
		return
	end

	local current_time = current.time - self.song_position
	if current_time < self.crotchet / 2 and current_time > -self.crotchet / 2 then
		if not current.pulled then
			-- current.spring:pull(0.03, 100, 10)
			-- current.spring:pull(0.2, 200, 10)
			current.pulled = true
		end
		current.color = green[0] -- hittable
	elseif current_time < -self.crotchet / 2 then
		current.color = blue[0] -- Missed
		camera:shake(2, 0.5)
		current.missed = true
		self.beat = self.beat + 1
		local note = self:get_current_note()
		if note then
			note.color = red[0] -- next note to be hit
		end
	end
end

function Map:update_score()
	local score = 0
	local accuracy = 0
	local hits = 0
	local misses = 0
	for _, note in ipairs(self.notes) do
		if note.missed then
			misses = misses + 1
			score = score - 1
		elseif note.hit then
			hits = hits + 1
			if note.score then
				accuracy = accuracy + note.score
				score = score + (1 - math.abs(note.score))
			end
		end
	end

	self.score = score
	self.accuracy = accuracy / hits
	self.hits = hits
	self.misses = misses
end

function Map:basic_hit(color)
	if self.recording then
		self:add_recorded_note(self.song_position, color)
	else
		self:attempt_note_hit(self.song_position, color)
	end
end

function Map:long_hit(color, beats)
	print("long hit with " .. beats .. " beats")
	if self.recording then
		self:add_recorded_note(self.song_position, color, beats)
	else
		self:attempt_note_hit(self.song_position, color, beats)
	end
end

function Map:attempt_note_hit(time, color, beats)
	local note = self:get_current_note()
	if not note then
		return
	end

	-- Skip if already hit
	if not note.hit and note.note_color == color then
		if math.abs(note.time - time) < self.crotchet / 2 then
			note.hit = time

			-- Mark as long note if beats > 1
			if beats and beats > 1 then
				note.beats = beats
			end

			-- Visual effects
			HitCircle({
				group = main.current.effects,
				x = note.x,
				y = note.y,
				rs = 9,
				color = fg[0],
				duration = self.crotchet / 4,
			})

			for j = 1, random:int(10, 20) do
				HitParticle({
					group = main.current.effects,
					x = note.x,
					y = note.y,
					w = 10,
					color = note.color,
					duration = self.crotchet,
				})
			end

			self.beat = self.beat + 1

			-- Optional: break if you only want to hit one matching note per call
		end
	end
end

function Map:destroy()
	-- Stop the song and release it
	if self.song then
		self.song:stop()
		self.song = nil
	end

	-- Clear notes
	if self.notes then
		for _, note in ipairs(self.notes) do
			if note.destroy then
				note:destroy()
			end
		end
	end
	self.notes = nil

	-- Reset related references
	self.group = nil
	self.floor = nil
	self.recording = nil

	-- Optional: stop any tweens, effects, or timers if they are global or lingering
	trigger:cancel("beat_flash")

	-- Optional: clear any effects or visuals (depends on implementation)
	-- if main and main.current and main.current.effects then
	-- 	main.current.effects:clear()
	-- end

	-- Reset internal state
	self._last_beat = nil
	self.song_start_time = nil
	self.pause_start_time = nil
	self.total_paused_time = nil

	-- Help garbage collector
	for k in pairs(self) do
		self[k] = nil
	end
end

-- function Map:attempt_note_hit(time, color, beats)
-- 	local current = self:get_current_note()
-- 	if not current then
-- 		return
-- 	end
--
-- 	if math.abs(current.time - time) < self.crotchet / 2 then
-- 		current.hit = time
--
-- 		HitCircle({ group = main.current.effects, x = current.x, y = current.y, rs = 9, color = fg[0], duration = self
-- 		.crotchet / 4 })
-- 		for i = 1, random:int(10, 20) do
-- 			HitParticle({ group = main.current.effects, x = current.x, y = current.y, w = 10, color = current.color, duration =
-- 			self.crotchet })
-- 		end
-- 		self.beat = self.beat + 1
-- 		local next = self:get_current_note()
-- 		if next then
-- 			next.color = red[0]
-- 		end
-- 	end
-- end

function Map:add_recorded_note(time, color, beats)
	local lane = input.last_key_released == controls[color .. "_hit"].default[1] and 1 or 2

	local note = {
		time = time,
		color = color,
		lane = lane,
	}

	if beats and beats > 1 then
		print("beats:" .. beats)
		note.beats = beats
	end

	self.notes[self.beat] = note
	self.beat = self.beat + 1
end

function Map:get_current_note()
	return self.notes[self.beat]
end

function Map:get_song_position()
	local instance = self.song._instances[#self.song._instances]

	if instance and not instance:isStopped() then
		local tell = instance._source:tell()

		local current_time = love.timer.getTime()
		local paused_duration = self.total_paused_time or 0

		-- If currently paused, also add time since it was paused
		if self.was_paused and self.pause_start_time then
			paused_duration = paused_duration + (current_time - self.pause_start_time)
		end

		local now = current_time - (self.song_start_time or current_time) - paused_duration
		return math.max(tell, now)
	end

	return 0
end

-- function Map:get_song_position()
-- 	local instance = self.song._instances[#self.song._instances]
-- 	if instance and not instance:isStopped() then
-- 		local tell = instance._source:tell()
-- 		local now = love.timer.getTime() - (self.song_start_time or now)
-- 		return math.max(tell, now)
-- 	end
-- 	return 0
-- end

function Map:draw() end

------------------------------------------------------------------
-----------------------  HitIndicator  ---------------------------
------------------------------------------------------------------
HitIndicator = Object:extend()
HitIndicator:implement(GameObject)
HitIndicator:implement(Physics)
function HitIndicator:init(args)
	self:init_game_object(args)

	self.group = args.group
	self:set_as_rectangle(self.w, self.h, "static", "indicator")
	self.color = self.color or fg[0]

	self.asset = args.asset
end

function HitIndicator:update(dt)
	self:update_game_object(dt)
end

function HitIndicator:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	-- self.shape:draw(self.color)
	self:draw_physics(nil, global_game_scale) -- draws physics shape
	graphics.rectangle(self.x, self.y, gw, 3, 0, 0, red[0])

	-- Draw self.asset animation
	-- local time = love.timer.getTime()
	-- local asset = self.asset
	-- local frame_count = #asset.sprites
	-- local frame = math.floor(time / asset.animation_speed) % frame_count + 1
	local released = input.red_hit.released or input.blue_hit.released
	local pressed = input.red_hit.pressed or input.blue_hit.pressed
	self.frame = pressed and 2 or released and 1 or self.frame or 1
	-- local frame = input.basic_hit.down and 2 or 1
	--
	local sprite = self.asset.sprites[self.frame]

	sprite:draw(self.x, self.y + 15, 0, 0.2 * global_game_scale)

	graphics.pop()
end

------------------------------------------------------------------
-----------------------     Notes     ----------------------------
------------------------------------------------------------------
Note = Object:extend()
Note:implement(GameObject)
Note:implement(Physics)
function Note:init(args)
	self:init_game_object(args)
	self.group = args.group

	self.time = args.time
	self.size = args.size
	self.speed = args.speed
	self.asset = args.asset

	-- self:set_as_circle(self.size, "dynamic", "note")
	self.color = self.color or fg[0]

	self.moving = false
	self.missed = false
	self.hit = false

	self.note_text = Text({
		{
			text = "[fg]MISS",
			font = mystery_font,
			alignment = "center",
		},
	}, global_text_tags)
end

function Note:start()
	self.moving = true
end

function Note:update(dt)
	if self.y > gh + 20 or main.current.map.was_paused then
		return
	end
	self:update_game_object(dt)

	if self.hit then
		self.color = yellow[0]
		if not self.score then
			self.score = 2 * (self.hit - self.time) / main.current.map.crotchet

			self.note_text:set_text({
				{
					text = "[yellow]       HIT: " .. string.format("%.2f", self.score),

					font = mystery_font,
					alignment = "right",
				},
			})
		end
	end

	if self.moving then
		-- self:move_along_angle(self.speed, math.pi / 2)
		self.y = self.y + dt * 10 * self.speed
		self:set_position(self.x, self.y) -- ignores the physics collision detection
	end
end

function Note:draw()
	if self.y > gh + 20 then
		return
	end
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	-- self.shape:draw(self.color)
	-- self:draw_physics(nil, 1) -- draws physics shape

	if not self.hit then
		if self.beats == 1 then
			if self.pulled and not self.missed then
				local song_pos = main.current.map.song_position
				local hit_time = self.time
				local max_distance = 0.1 -- X: max distance for full transition (adjust as needed)

				-- Compute normalized distance (0 = perfect hit, 1 = max distance or more)
				local dist = math.abs(song_pos - hit_time)
				local t = math.min(dist / max_distance, 1)

				-- Interpolate color from green (perfect) to red (off-timing)
				-- Red = (1, 0.1, 0.1), Green = (0.1, 1, 0.1)
				local r = 0.1 + 0.9 * t -- goes from 0.1 → 1 as t goes 0 → 1
				local g = 1 - 0.9 * t -- goes from 1 → 0.1 as t goes 0 → 1
				local b = 0.1
				local a = 1

				local indicator_color = Color(r, g, b, a)
				graphics.circle(self.x, self.y, self.size + 10 * global_game_scale, indicator_color)
			end
			self.asset.sprites[1]:draw(self.x, self.y, 0, self.size)
		else
			-- long note, draw head at self.beats ahead of tail
			local pixels_per_beat = 1.2 * global_game_scale * self.speed -- pixels per beat
			local pixels_per_segment = 8 * global_game_scale
			local bottom_y = self.y + pixels_per_beat * self.beats

			self.asset.sprites[1]:draw(self.x, bottom_y, 0, self.size)
			for y = self.y + pixels_per_segment, bottom_y - pixels_per_segment, pixels_per_segment do
				self.asset.sprites[2]:draw(self.x, y, 0, self.size)
			end
			self.asset.sprites[3]:draw(self.x, self.y, 0, self.size)
		end
	end

	if self.missed or self.hit then
		self.note_text:draw(self.x + 50, self.y, self.r, self.sx * self.spring.x, self.sy * self.spring.x)
	end
	graphics.pop()
end
