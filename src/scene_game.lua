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

	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0
	camera.follow_style = "lockon_tight"
	camera.lerp.x = 0.02
	camera.lerp.y = 0.02

	self.floor = Group()
	self.main = Group()
	self.game_ui = Group():no_camera()
	self.effects = Group()
	self.ui = Group()
	self.end_ui = Group():no_camera()
	self.paused_ui = Group():no_camera()
	self.options_ui = Group():no_camera()
	self.keybinding_ui = Group():no_camera()
	self.credits = Group():no_camera()

	self.main_slow_amount = 1
	slow_amount = 1

	self.x1, self.y1 = 0, 0
	self.x2, self.y2 = gw, gh
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1
	self.song_info_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)

	self.in_pause = false
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

	-- [load room draw grid (future: tilemap)]
	-- [spawn units] and [spawn enemies]
	-- [setup timeline] and [add units to turn queue]
	-- [start countdown] and [start/resume song]
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
		group = self.main,
		x = gw * 0.5,
		y = gh * 0.94,    -- center aligned
		w = gw * 0.9,
		hit_window = 0.1, -- seconds
		max_beats = 6,
		beat_spread = gw * 0.1, -- TODO: look into this VS beat speed
		beats_per_sec = 120 / 60,
		cell_size = cell_size,
	})
	self.beats_per_sec = 120 / 60

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

	-- self.beat_number = 0

	-- self.hit_window = 0.4 -- seconds
	-- self.lead_in_beats_count = self.level.lead_in_beats

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

function Game:update(dt)
	self.song = play_music({ return_song = true, pitch = self.pitch })

	if not self.in_pause and not self.won then
		run_time = run_time + dt

		if self.song and not self.song:isStopped() then
			local song_time = self.song._source:tell()
			local delta = song_time - (self.last_song_time or song_time)
			self.last_song_time = song_time

			self.song_position = self.song_position + delta
		end

		if input.z.pressed then
			self.timeline:print_beats()
		end

		if self.map.new_room_loaded then
			local valid_hit = nil
			if input.up.pressed or input.down.pressed or input.left.pressed or input.right.pressed then
				valid_hit = self.timeline:beat_hit_at(self.song_position)

				if valid_hit then
					sfx.metronome:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
					self.map:react_to_beat({ unit = self.focused_unit, beat = valid_hit })
					self.timeline:react_to_beat()

					local unit = self.focused_unit
					if input.up.pressed then
						self.map:move_unit(unit, unit.tile_x + 0, unit.tile_y - 1)
					end
					if input.down.pressed then
						self.map:move_unit(unit, unit.tile_x + 0, unit.tile_y + 1)
					end
					if input.left.pressed then
						self.map:move_unit(unit, unit.tile_x - 1, unit.tile_y + 0)
					end
					if input.right.pressed then
						self.map:move_unit(unit, unit.tile_x + 1, unit.tile_y + 0)
					end
				end
			end

			local beats_left, miss = self.timeline:beat_tracker(self.song_position)
			if miss then
				sfx.tile_mouse_enter:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
				self.map:react_to_miss({ unit = self.focused_unit, beat = valid_hit })
				self.timeline:react_to_miss()
			end

			self.map:beat_tracker(self.song_position)
			self.focused_unit:beats_remaining(beats_left)

			if beats_left < 0 then
				self:next_turn() -- TODO: last beat never shown on timeline
			end
		end
	end

	if input.escape.pressed and not self.transitioning and not self.in_credits then
		if not self.in_pause and not self.died and not self.won then
			pause_game(self)
		elseif self.in_options and not self.died and not self.won then
			if self.in_keybinding then
				close_keybinding(self)
			else
				close_options(self)
			end
		else
			local layer = main.ui_layer_stack:peek()

			scene_transition(self, {
				x = gw / 2,
				y = gh / 2,
				type = "fade",
				target = {
					scene = MainMenu,
					name = "main_menu",
					args = { clear_music = true },
				},
				display = {
					text = "loading main menu...",
					font = pixul_font,
					alignment = "center",
				},
			})
			return
		end
	elseif input.escape.pressed and self.in_credits then
		close_credits(self)
		self.in_credits = false
		if self.credits_button then
			self.credits_button:on_mouse_exit()
		end
		self.credits:update(0)
	end

	self:update_game_object(dt * slow_amount)
	star_group:update(dt * slow_amount)
	self.floor:update(dt * slow_amount)
	self.main:update(dt * slow_amount * self.main_slow_amount)
	self.game_ui:update(dt * slow_amount)
	self.effects:update(dt * slow_amount)
	self.ui:update(dt * slow_amount)
	self.end_ui:update(dt * slow_amount)
	self.paused_ui:update(dt * slow_amount)
	self.options_ui:update(dt * slow_amount)
	if self.in_keybinding then
		update_keybind_button_display(self)
	end
	self.keybinding_ui:update(dt * slow_amount)
	self.credits:update(dt * slow_amount)
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

	if self.in_pause then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.paused_ui:draw()

	if self.in_options then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
	end
	self.options_ui:draw()

	if self.in_keybinding then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.keybinding_ui:draw()

	if self.in_credits then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
	end
	self.credits:draw()
end

function Game:on_exit()
	self.main:destroy()
	self.game_ui:destroy()
	self.effects:destroy()
	self.ui:destroy()
	self.end_ui:destroy()
	self.paused_ui:destroy()
	self.options_ui:destroy()
	self.keybinding_ui:destroy()

	self.main = nil
	self.game_ui = nil
	self.effects = nil
	self.ui = nil
	self.end_ui = nil
	self.paused_ui = nil
	self.options_ui = nil
	self.keybinding_ui = nil
	self.credits = nil
	self.flashes = nil
	self.hfx = nil

	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0
	camera:follow_object(nil)
end
