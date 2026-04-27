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
		x = gw * 0.5,
		y = gh * 0.94,          -- center aligned
		w = gw * 0.9,
		hit_window = 0.1,       -- seconds
		max_beats = 8,
		beat_spread = gw * 0.2, -- TODO: look into this VS beat speed
		beats_per_sec = 2 * 120 / 60, -- *2 for eighths
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
	self:next_turn()

	-- Load the map,
	-- load some turns into the turn order
	-- set timeline:
	--		load the 'lead in beats' (no camera focus)
	--		select units from map, and figure out order until everyone went at least once
	--
	--		pop() turn
	--		add to timeline
	--		focus on new unit
	--
	-- gameplay:
	-- while #turns > 0
	--		if unit's timeline beats remaining == 0
	--			pop() turn
	--			add to timeline
	--			focus on new unit
	--		play timeline
	--	else
	--		self.turn_order:insert(self.map:get_all_alive_units())
	--		repeat while until win+next_room/fail
end

function Game:next_turn()
	if self.focused_unit then
		self.focused_unit:highlight(0)
	end

	if self.turn_order:num_turns() == 0 then
		self.turn_order:insert(self.map:get_all_alive_units())
	end

	local unit = self.turn_order:pop()
	self.timeline:add(unit, self.song_position)
	self.focused_unit = unit
	self.focused_unit:highlight(1)
	camera:follow_object(self.focused_unit)

	local next_unit = self.turn_order:peek()
	if next_unit then
		next_unit:highlight(2)
	end
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
			local is_new_beat = false
			local beats_left = 1
			local valid_hit = nil

			if self.focused_unit.is_player then
				local new_beat_from_hit = false
				if input.up.pressed or input.down.pressed or input.left.pressed or input.right.pressed then
					local hit_time
					valid_hit, hit_time, new_beat_from_hit = self.timeline:beat_hit_at(self.song_position)

					if valid_hit then
						sfx.metronome:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
						local data = { unit = self.focused_unit, beat = valid_hit, time_offset = hit_time }
						self.map:react_to_hit(data)
						self.timeline:react_to_hit()

						for key, dir in pairs(directions) do
							if input[key].pressed then
								data.dir = dir
								self.map:handle_press(data)
							end
						end
					end
				end

				local missed_beat, new_beat
				beats_left, missed_beat, new_beat = self.timeline:beat_tracker(self.song_position)
				if missed_beat then
					sfx.tile_mouse_enter:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
					self.map:react_to_miss({ unit = self.focused_unit, beat = missed_beat })
					self.timeline:react_to_miss()
				end
				self.focused_unit:beats_remaining(beats_left)

				is_new_beat = new_beat_from_hit or new_beat
			elseif not state.enemies_act_every_beat then -- non-player turn
				local beat = nil
				beats_left, beat, is_new_beat = self.timeline:check_for_new_beat_to_hit(self.song_position,
					self.enemy_hit_window)
				if is_new_beat then
					-- sfx.metronome:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
					local data = { unit = self.focused_unit, beat = beat }
					self.map:react_to_hit(data)
					self.timeline:react_to_hit()
				end
			end

			if state.enemies_act_every_beat then
				local act = is_new_beat and (not state.enemies_only_move_when_player_doesnt or not valid_hit)
				if act then
					self.map:all_enemies_act(self.song_position)
				end
			end

			self.map:beat_tracker(self.song_position, is_new_beat)

			if beats_left < 0 then
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
