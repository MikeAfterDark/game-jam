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
	self.offset = self.data.offset
	self.speed = self.data.speed

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
			self.notes[i] = Note({
				group = self.group,
				time = note.time,
				name = i,
				x = gw * 0.5,
				y = self.floor - note.time * self.speed * 10, -- /1000  temporarily cuz im dumb and data is in ms instead of seconds
				size = 0.3,
				speed = self.speed,
				asset = rock_bug,
			})
		end
		self.notes[self.beat].color = red[0]
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
	local file = io.open("maps/" .. self.folder .. "/map2.lua", "w")
	file:write("return {\n  notes = {\n")
	for _, note in ipairs(self.notes) do
		file:write(string.format("    { time = %.2f },\n", note.time))
	end
	file:write("  }\n}")
	file:close()
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
	self.song_position = self:get_song_position()
	self:update_note_tracking()

	self:update_score()
end

function Map:basic_hit()
	if self.recording then
		self:add_recorded_note(self.song_position)
	else
		self:attempt_note_hit(self.song_position)
	end
end

function Map:update_note_tracking()
	local current = self:get_current_note()
	if not current then
		return
	end

	local current_time = current.time - self.song_position
	if current_time < self.crotchet / 2 and current_time > -self.crotchet / 2 then
		current.color = green[0] -- hittable
	elseif current_time < -self.crotchet / 2 then
		current.color = blue[0] -- Missed
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
		elseif note.hit then
			hits = hits + 1
			if note.score then
				accuracy = accuracy + note.score
				score = score + math.abs(note.score)
			end
		end
	end

	self.score = score
	self.accuracy = accuracy / hits
	self.hits = hits
	self.misses = misses
end

function Map:attempt_note_hit(time)
	local current = self:get_current_note()
	if not current then
		return
	end

	if math.abs(current.time - time) < self.crotchet / 2 then
		current.hit = time
		self.beat = self.beat + 1
		local next = self:get_current_note()
		if next then
			next.color = red[0]
		end
	end
end

function Map:add_recorded_note(time)
	self.notes[self.beat] = { time = time }
	self.beat = self.beat + 1
end

function Map:get_current_note()
	return self.notes[self.beat]
end

function Map:get_song_position()
	local instance = self.song._instances[#self.song._instances]
	if instance and not instance:isStopped() then
		local tell = instance._source:tell()
		local now = love.timer.getTime() - (self.song_start_time or now)
		return math.max(tell, now)
	end
	return 0
end

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
	-- self:set_as_rectangle(self.w, self.h, "static", "indicator")
	self.color = self.color or fg[0]

	self.asset = args.asset
end

function HitIndicator:update(dt)
	self:update_game_object(dt)
end

function HitIndicator:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	-- graphics.rectangle(self.x, self.y, self.shape.w, 3, 0, 0, black[0])

	-- Draw self.asset animation
	local time = love.timer.getTime()
	local asset = self.asset
	local frame_count = #asset.sprites
	local frame = math.floor(time / asset.animation_speed) % frame_count + 1
	local sprite = asset.sprites[frame]

	local scale = 0.3
	sprite:draw(self.x, self.y, 0, scale, scale)

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
		self.y = self.y + dt * 100 -- self.speed
		self:set_position(self.x, self.y) -- ignores the physics collision detection
	end
end

function Note:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	-- self.shape:draw(self.color)
	-- self:draw_physics(nil, 1) -- draws physics shape

	self.asset.sprites[1]:draw(self.x, self.y, 0, self.size)

	if self.missed or self.hit then
		self.note_text:draw(self.x + 50, self.y, self.r, self.sx * self.spring.x, self.sy * self.spring.x)
	end
	graphics.pop()
end
