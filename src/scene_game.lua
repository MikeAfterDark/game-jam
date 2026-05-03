Game = Object:extend()
Game:implement(State)
Game:implement(GameObject)
function Game:init(name)
	self:init_state(name)
	self:init_game_object()
end

function Game:on_enter(from, args)
	self.hfx:add("condition1", 1)
	self.hfx:add("condition2", 1)

	self.level = args.level
	self.player_units = args.player_units
	self.pitch = args.pitch or 1

	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0
	camera.follow_style = "lockon_tight"
	camera.lerp.x = 0.06
	camera.lerp.y = 0.06

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

	self.game_ui_elements = {}

	-- if layer underneath this one has layer_type == "game" and the same music type then dont push
	local layer = main.ui_layer_stack:peek()
	if layer and layer.music_type ~= self.music_type then
		if layer.game then
			pop_ui_layer(self)
		end

		main.ui_layer_stack:push({
			layer = ui_interaction_layer.Game,
			layer_has_music = self.has_music,
			-- game = true,
			music_type = self.music_type,
			ui_elements = self.game_ui_elements,
		})
	end

	self.enemy_hit_window = 0.05
	self.song_position = 0

	-- controls the unit locations, hp, collisions and fights
	-- based on user input triggers
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
		bpm = 120,
		max_beats = 8,
		cell_size = cell_size,
	})
	self.beats_per_sec = 2 * 120 / 60 -- *2 for eighths

	-- controls the upcoming turns, including new spawns and deaths
	self.turn_order = Turn_Order({
		group = self.game_ui,
		x = gw * 0.1,
		y = gh * 0.1, -- top-center aligned
		w = gw * 0.1,
		h = gh * 0.3,
		section_height = gh * 0.03,
	})

	self.map:load_next_room() -- spawns player_units and enemies based off self.map.level
	self.turn_order:insert(self.map:get_all_alive_units())
	self:prep_turn()
end

function Game:prep_turn()
	if self.turn_order:num_turns() <= 1 then -- guarantees at least 2 turns
		self.turn_order:insert(self.map:get_all_alive_units())
	end

	self.focused_unit = self.turn_order:pop()
	self.timeline:add(self.focused_unit, self.song_position)
	self.focused_unit:highlight(1)
	camera:follow_object(self.focused_unit)

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

	self.focused_unit = self.next_unit
	self.focused_unit:highlight(1)
	camera:follow_object(self.focused_unit)

	if self.turn_order:num_turns() <= 1 then
		self.turn_order:insert(self.map:get_all_alive_units())
	end

	local unit2 = self.turn_order:pop()
	local next_song_position = self.song_position + self.timeline:time_left_for(self.focused_unit, self.song_position)
	self.timeline:add(unit2, next_song_position)

	self.next_unit = unit2
	self.next_unit:highlight(2)
end

local directions = {
	up = { x = 0, y = -1 },
	down = { x = 0, y = 1 },
	left = { x = -1, y = 0 },
	right = { x = 1, y = 0 },
}

function Game:update(dt)
	self.song = play_music({ return_song = true, pitch = self.pitch })

	if input.z.pressed and self.pitch > 0.1 then
		self.pitch = self.pitch - 0.1
	end
	if input.x.pressed then
		self.pitch = self.pitch + 0.1
	end
	self.song._source:setPitch(self.pitch)

	if not main:get("settings").in_pause and not self.won then
		run_time = run_time + dt

		if self.song and not self.song:isStopped() then
			local song_time = self.song._source:tell()
			local delta = song_time - (self.last_song_time or song_time)
			self.last_song_time = song_time

			self.song_position = self.song_position + delta
		end

		if self.map.new_room_loaded then
			local is_new_beat = self.timeline:beat_tracker(self.map:get_all_alive_units(), self.song_position)

			if self.focused_unit.is_player then
				if input.up.pressed or input.down.pressed or input.left.pressed or input.right.pressed then
					local hits = self.timeline:press(self.focused_unit, self.song_position, Input_Type.Direction)
					if #hits > 0 then
						-- print("tap beat pressed!", self.song_position, hits[1].id)
						sfx.metronome:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
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
						sfx.metronome:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
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
						sfx.metronome:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
						self.map:react_to_hit({ unit = self.focused_unit, beat = releases[1] }) -- WARN: overlaps get ignored
						for i, beat in ipairs(releases) do
							-- consume the held beat
							-- print("Myon released", beat.time, beat.pressed, "and", beat.end_time, beat.released,
							-- beat.percent_complete)
						end
					end
				end
			elseif not state.enemies_act_every_beat then -- non-player turn
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
				local act = is_new_beat and not state.enemies_only_move_when_player_doesnt
				if act then
					self.map:all_enemies_act(self.song_position)
				end
			end

			self.map:beat_tracker(self.song_position, is_new_beat)

			if self.timeline:is_end_of_turn(self.focused_unit, self.song_position) then
				self:next_turn()
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

	if self.win or self.died then
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
	camera.r = 0
	camera:follow_object(nil)
end
