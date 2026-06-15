Game = Object:extend()
Game:implement(State)
Game:implement(GameObject)
function Game:init(name)
	self:init_state(name)
	self:init_game_object()
end

function Game:on_enter(from, args)
	self.level = args.level
	self.player_units = args.player_units
	self.pitch = args.pitch or 1
	self.num_players = args.num_players or 1

	camera.x, camera.y = gw * 0.5, gh * 0.5
	camera.r = 0
	camera.follow_style = "lockon_tight"
	camera.lerp.x = 0.06
	camera.lerp.y = 0.06
	self.camera_tracker = { x = gw / 2, y = gh / 2 }
	camera:follow_object(self.camera_tracker)

	self.floor = Group()
	self.main = Group()
	self.game_ui = Group():no_camera()
	self.effects = Group()
	self.ui = Group()
	self.end_ui = Group():no_camera()

	self.main_slow_amount = 1
	slow_amount = 1

	self.x1, self.y1 = 0, 0
	self.x2, self.y2 = gw, gh
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1
	self.song_info_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)

	self.won = false
	self.lost = false

	self.game_ui_elements = {}

	-- if layer underneath this one has layer_type == "game" and the same music type then dont push
	local layer = main.ui_layer_stack:peek()
	if layer and layer.music_type ~= self.music_type then
		if layer.game then
			pop_ui_layer(self)
		end

		main.ui_layer_stack:push({
			layer = ui_interaction_layer.Game,
			layer_has_music = args.layer_has_music,
			-- game = true,
			music_type = args.music_type,
			ui_elements = self.game_ui_elements,
		})
	end

	self.enemy_hit_window = 0.05
	self.song_position = 0

	-- controls the unit locations, hp, collisions and fights
	-- based on user input triggers
	-- print(table.tostring(self.level))
	local cell_size = gh * 0.08 * 1
	self.map = Map({
		group = self.main,
		x = gw * 0.5,
		y = gh * 0.5, -- center aligned
		scale = 1,
		cell_size = cell_size,
		level = self.level,
		player_units = self.player_units,
	})

	-- displays times and holds and displays the beats for the current turn
	self.timeline = Timeline({
		group = self.ui,
		max_beats = args.max_beats,
		cell_size = cell_size,
	})

	-- controls the upcoming turns, including new spawns and deaths
	self.turn_order = Turn_Order({
		group = self.game_ui,
		x = gw * 0.1,
		y = gh * 0.1, -- top-center aligned
		w = gw * 0.1,
		h = gh * 0.3,
		section_height = gh * 0.03,
	})

	self.is_calibration = self.level.id == "calibration"
	self.calibration_hits = {}
	self.audio_offset_text = collect_into(
		self.game_ui_elements,
		Text2({
			group = self.ui,
			x = gw * 0.5,
			y = gh * 0.3,
			lines = { { text = tostring(state.global_time_offset or "hello1"), font = pixul_font } },
			visible = self.is_calibration,
		})
	)
	self.visual_offset_text = collect_into(
		self.game_ui_elements,
		Text2({
			group = self.ui,
			x = gw * 0.5,
			y = gh * 0.35,
			lines = { { text = tostring(state.visual_offset or "hello2"), font = pixul_font } },
			visible = false,
		})
	)

	self.room = self.map:load_next_room() -- spawns player_units and enemies based off self.map.level
	self:play_room_song()

	self:prep_turn()
end

function Game:prep_turn()
	self.turn_order:insert(self.map:get_all_alive_units())

	if self.turn_order:num_turns() <= 1 then -- guarantees at least 2 turns
		self.turn_order:insert(self.map:get_all_alive_units())
	end

	self.active_units = self.turn_order:get_units()
	table.foreach(self.active_units, function(unit)
		self.timeline:add(unit, self.song_position)
		unit:highlight(1)
	end)

	self.focused_unit = self.turn_order:pop()
	self.timeline:add(self.focused_unit, self.song_position)
	self.focused_unit:highlight(1)

	local unit2 = self.turn_order:pop()
	local next_song_position = self.song_position + self.timeline:time_left_for(self.focused_unit, self.song_position)
	self.timeline:add(unit2, next_song_position)

	self.next_unit = unit2
	self.next_unit:highlight(2)
end

function Game:next_turn()
	if self.focused_unit then
		self.focused_unit:highlight(0)
	end

	if self.next_unit then
		self.focused_unit = self.next_unit
		self.focused_unit:highlight(1)

		if self.turn_order:num_turns() <= 1 then
			self.turn_order:insert(self.map:get_all_alive_units())
		end

		local unit2 = self.turn_order:pop()
		local next_song_position = self.song_position --
			+ self.timeline:time_left_for(self.focused_unit, self.song_position)
		self.timeline:add(unit2, next_song_position)

		self.next_unit = unit2
		if self.next_unit then
			self.next_unit:highlight(2)
		end
	else
		self:loss()
	end
end

local directions = {
	up = { x = 0, y = -1 },
	down = { x = 0, y = 1 },
	left = { x = -1, y = 0 },
	right = { x = 1, y = 0 },
}

function Game:play_room_song()
	if self.in_countdown or main:get("settings").transitioning or self.won or self.lost then
		return
	end

	if main:get("settings").in_pause then
		if self.song and not self.song:isStopped() then
			self.song:pause()
		end
		return
	end

	if self.song and self.song._source:isPlaying() then
		return
	end

	self.in_countdown = true
	if not self.song then
		local viable_songs = table.select(self.level.room_songs, function(v)
			return table.contains(v.valid_maps, self.room.name)
		end)
		self.song_data = table.random(viable_songs)
		local bpm = self.song_data.bpm
		self.timeline:set_bpm(bpm)
	end

	-- self.timeline:setup_all_timelines(self.song_data)

	local next_song_beat = self.timeline:get_next_beat_time(self.song_position)
	local beat_duration = self.timeline:get_beat_duration()

	local countdown_beats = 3
	for i = 0, countdown_beats do
		local beat_time = next_song_beat + (i * beat_duration)
		local delay = beat_time - self.song_position

		trigger:after(delay, function()
			if main:get("settings").transitioning or main:get("settings").in_pause then
				self.in_countdown = false
				return
			end
			sfx.metronome:play({
				pitch = random:float(0.95, 1.05),
				volume = 0.35,
			})
		end)
	end

	-- Start song exactly after countdown
	local song_start_time = next_song_beat + (countdown_beats * beat_duration)
	local start_delay = song_start_time - self.song_position

	trigger:after(start_delay, function()
		if main:get("settings").transitioning or main:get("settings").in_pause then
			return
		end
		self.in_countdown = false

		if self.song then
			self.song:resume()
		else
			self.pitch = self.song_data.pitch or 1
			self.song = self.level.songs[self.song_data.song_name]:play({
				volume = 0.35,
				pitch = self.pitch,
			})

			self.map:set_song_info({ duration = self.song._source:getDuration() })
		end
	end)
end

function Game:update(dt)
	self:play_room_song()

	-- if self.song then
	-- 	self.song:update(dt)
	-- end

	-- temp debug controls
	if input.z.pressed and self.pitch > 0.1 then
		self.pitch = self.pitch - 0.1
	end
	if input.x.pressed and self.pitch < 10 then
		self.pitch = self.pitch + 0.1
	end

	local zoom_percent = 1.1
	if (input.wheel_up.down or input.wheel_up.pressed) and camera.sx < 4 then
		camera.sx, camera.sy = camera.sx * zoom_percent, camera.sy * zoom_percent
	end
	if (input.wheel_down.down or input.wheel_down.pressed) and camera.sx > 0.5 then
		camera.sx, camera.sy = camera.sx / zoom_percent, camera.sy / zoom_percent
	end
	---------------------

	local default_pos = { x = gw / 2, y = gh / 2 }
	local average_pos = { x = 0, y = 0 }
	table.foreach(self.active_units, function(unit)
		local x = unit.x * (unit.camera_weight or 1) / #self.active_units
		local y = unit.y * (unit.camera_weight or 1) / #self.active_units
		average_pos.x = average_pos.x + x
		average_pos.y = average_pos.y + y
	end)
	self.camera_tracker = #self.active_units > 10 and average_pos or default_pos
	camera:follow_object(self.camera_tracker)
	-- print(table.tostring(average_pos), self.active_units[1].x, self.active_units[1].y)

	local paused = main:get("settings").in_pause
	local game_over = self.won or self.lost
	if not paused and not game_over then
		run_time = run_time + dt

		if self.song and not self.song:isStopped() then
			self.song._source:setPitch(self.pitch)

			local song_time = self.song._source:tell()
			local delta = math.max(0, song_time - (self.last_song_time or song_time))
			self.last_song_time = song_time

			self.song_position = self.song_position + delta
		end

		if self.map.new_room_loaded then
			while (not self.focused_unit or self.focused_unit.dead) and not self.lost do
				print("focused unit died/DNE")
				self:next_turn()
			end

			if self.map:room_completed(self.song_position) then
				self.map.new_room_loaded = false
				self.timeline:reset()
				self.turn_order:reset()
				self.room = self.map:load_next_room()
				if not self.room then
					self:win()
				end

				return
			end

			local is_new_beat, missed = self.timeline:beat_tracker(self.map:get_all_alive_units(), self.song_position)

			if missed and not self.is_calibration then
				self.map:react_to_miss({ unit = self.focused_unit })
			end

			if self.focused_unit.is_player and not self.is_calibration then
				if input.up.pressed or input.down.pressed or input.left.pressed or input.right.pressed then
					local hits = self.timeline:press(self.focused_unit, self.song_position, Input_Type.Direction)
					if #hits > 0 then
						-- print("tap beat pressed!", self.song_position, hits[1].id)
						-- sfx.metronome:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
						self.map:react_to_hit({ unit = self.focused_unit, beat = hits[1] }) -- WARN: overlaps get ignored

						for i, beat in ipairs(hits) do
							local data = { unit = self.focused_unit, beat = beat }

							for key, dir in pairs(directions) do
								if input[key].pressed then
									data.dir = dir
									self.map:handle_press(data)
								end
							end
						end
					end
				end

				if input.arix.pressed then
					local hits = self.timeline:press(self.focused_unit, self.song_position, Input_Type.Arix)
					if #hits > 0 then
						-- print(#hits, "arix pressed", self.song_position)
					end
				end
				if input.arix.released then
					local releases = self.timeline:release(self.focused_unit, self.song_position, Input_Type.Arix)
					if #releases > 0 then
						-- sfx.metronome:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
						self.map:react_to_hit({ unit = self.focused_unit, beat = releases[1] }) -- WARN: overlaps get ignored
						for i, beat in ipairs(releases) do
							-- consume the held beat
							-- print("Arix released", beat.time, beat.pressed, "and", beat.end_time, beat.released,
							-- 	beat.percent_complete)
						end
					end
				end

				if input.myon.pressed then
					local hits = self.timeline:press(self.focused_unit, self.song_position, Input_Type.Myon)
					if #hits > 0 then
						-- print(#hits, "myon pressed", self.song_position)
					end
				end
				if input.myon.released then
					local releases = self.timeline:release(self.focused_unit, self.song_position, Input_Type.Myon)

					if #releases > 0 then
						-- sfx.metronome:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
						self.map:react_to_hit({ unit = self.focused_unit, beat = releases[1] }) -- WARN: overlaps get ignored
						for i, beat in ipairs(releases) do
							-- consume the held beat
							-- print("Myon released", beat.time, beat.pressed, "and", beat.end_time, beat.released,
							-- beat.percent_complete)
						end
					end
				end
			elseif not self.focused_unit.is_player and not self.is_calibration and not state.enemies_act_every_beat then -- non-player turn
				local beats = self.timeline:try_hit_or_release(self.focused_unit, self.song_position)
				if #beats > 0 then
					-- sfx.metronome:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
					self.map:react_to_hit({ unit = self.focused_unit, beat = beats[1] })
					for i, beat in ipairs(beats) do
						local data = { unit = self.focused_unit, beat = beat }
						self.map:handle_enemy_input(data)
					end
				end
			end

			if state.enemies_act_every_beat then
				-- TODO: if we choose this option then this needs a rework
				-- its just 'playing' the beats of each unit, instead of adding
				-- to the timelines (hint: timeline:is_end_of_turn())
				local act = is_new_beat and not state.enemies_only_move_when_player_doesnt
				if act then
					self.map:all_enemies_act(self.song_position)
				end
			end

			self.map:beat_tracker(self.song_position, is_new_beat)

			if self.timeline:is_end_of_turn(self.focused_unit, self.song_position) then
				self:next_turn()
			end

			if self.is_calibration then
				for i = 1, self.num_players do
					local any_input_pressed = input[i .. "up"].pressed
						or input[i .. "down"].pressed
						or input[i .. "left"].pressed
						or input[i .. "right"].pressed
						or input[i .. "arix"].pressed
						or input[i .. "myon"].pressed

					if any_input_pressed then -- care, can be spammed, might use up lots of memory
						self.focused_unit.spring:pull(0.2, 200, 10)
						local time_difference = self.timeline:how_on_beat_is(self.song_position)
						table.insert(self.calibration_hits, { time = self.song_position, offset = time_difference })

						local sum = table.reduce(self.calibration_hits, function(memo, v)
							return memo + v.offset
						end, 0)
						local average = sum / #self.calibration_hits
						local average_ms = math.ceil(average * 1000)
						self.timeline:calibration_offset(i, average)
						self.audio_offset_text:set_text({ { text = tostring(average_ms) .. "ms", font = pixul_font } })
					end
				end
			else
				self.audio_offset_text:set_text({ { text = tostring(state.global_time_offset) .. "s", font = pixul_font } })
				self.visual_offset_text:set_text({ { text = tostring(state.visual_offset) .. "s", font = pixul_font } })
			end
		end
	end

	self:update_game_object(dt * slow_amount)
	star_group:update(dt * slow_amount)
	self.floor:update(dt * slow_amount)
	self.main:update(dt * slow_amount * self.main_slow_amount)
	self.game_ui:update(dt * slow_amount)
	self.effects:update(dt * slow_amount)
	self.ui:update(dt * slow_amount)
	self.end_ui:update(dt * slow_amount)
end

function Game:win()
	self.won = true
	print("gj, you won")

	if self.song then
		self.song:stop()
	end

	scene_transition(self, {
		x = gw / 2,
		y = gh / 2,
		type = "circle",
		target = {
			scene = Level_Select,
			name = "level_select",
			args = {
				num_players = self.num_players,
				clear_music = true,
			},
		},
		display = {
			text = "gg wp! loading...",
			font = pixul_font,
			alignment = "center",
		},
	})
end

function Game:loss()
	self.lost = true
	print("booo, you lost")

	if self.song then
		self.song:stop()
	end

	scene_transition(self, {
		x = gw / 2,
		y = gh / 2,
		type = "circle",
		target = {
			scene = Level_Select,
			name = "level_select",
			args = {
				num_players = self.num_players,
				clear_music = true,
			},
		},
		display = {
			text = "ripperonis, you lost. loading...",
			font = pixul_font,
			alignment = "center",
		},
	})
end

function Game:draw()
	self.floor:draw()
	self.main:draw()
	self.game_ui:draw()
	self.effects:draw()
	self.ui:draw()

	graphics.draw_with_mask(function()
		star_canvas:draw(0, 0, 0, 1, 1)
	end, function()
		camera:attach()
		graphics.rectangle(gw / 2, gh / 2, self.w, self.h, nil, nil, fg[0])
		camera:detach()
	end, true)

	if self.won or self.died then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.end_ui:draw()
end

function Game:on_exit()
	self.main:destroy()
	self.game_ui:destroy()
	self.effects:destroy()
	self.ui:destroy()
	self.end_ui:destroy()

	self.main = nil
	self.game_ui = nil
	self.effects = nil
	self.ui = nil
	self.end_ui = nil
	self.flashes = nil
	self.hfx = nil

	camera.x, camera.y = gw / 2, gh / 2
	camera.sx, camera.sy = 1, 1
	camera.r = 0
	camera:follow_object(nil)
end
