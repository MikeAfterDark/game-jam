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

	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0

	self.floor = Group()
	self.main = Group()
	-- :set_as_physics_world(
	-- 8 * global_game_scale,
	-- 0,
	-- 1000,
	-- {}
	-- { "player", "transparent", "opaque", "runner", "pill" }
	-- )
	self.post_main = Group()
	self.effects = Group()
	self.ui = Group():no_camera()
	self.end_ui = Group()
	self.paused_ui = Group():no_camera()
	self.options_ui = Group():no_camera()
	self.keybinding_ui = Group():no_camera()
	self.credits = Group():no_camera()

	-- self.main:disable_collision_between("runner", "runner")
	-- self.main:disable_collision_between("runner", "transparent")
	-- self.main:disable_collision_between("runner", "pill")
	--
	-- self.main:enable_trigger_between("player", "transparent")
	-- self.main:enable_trigger_between("transparent", "player")
	--
	-- self.main:enable_trigger_between("runner", "transparent")
	-- self.main:enable_trigger_between("transparent", "runner")
	--
	-- self.main:enable_trigger_between("runner", "pill")
	-- self.main:enable_trigger_between("pill", "runner")
	-- self.main:enable_trigger_between("wall", "player")

	self.main_slow_amount = 1
	slow_amount = 1

	self.x1, self.y1 = 0, 0
	self.x2, self.y2 = gw, gh
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1
	self.song_info_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)

	self.in_pause = false
	self.stuck = false
	self.won = false

	self.game_ui_elements = {}

	-- local ui_layer =
	-- local ui_group = self.options_ui
	-- self.options_ui_elements = {}
	-- main.ui_layer_stack:push({
	-- 	layer = ui_interaction_layer.Options,
	-- 	layer_has_music = not main.current.in_pause,
	-- 	music_type = "options",
	-- 	ui_elements = self.options_ui_elements,
	-- })

	-- if layer underneath this one has layer_type == "game" and the same music type then dont push
	local layer = main.ui_layer_stack:peek()
	if layer and layer.music_type ~= self.music_type then
		if layer.game then
			pop_ui_layer(self)
		end

		main.ui_layer_stack:push({
			layer = ui_interaction_layer.Game,
			layer_has_music = self.has_music,
			game = true,
			music_type = self.music_type,
			ui_elements = self.game_ui_elements,
		})
	end

	game_mouse = {
		holding = nil,
	}

	local num_tiles = 12
	local tile_size = gh * 1 / (num_tiles + 1.8)
	local shop_slot_size = gh * 0.03

	local run = system.load_run()
	if next(run) == nil then -- new run
		self.board = Board({
			group = self.floor,
			x = gw / 2,
			y = gh / 2,
			tile_size = tile_size,
			rows = num_tiles,
			columns = num_tiles,
		})
		self.shop = Shop({
			group = self.main,
			positions = { -- WARN: HARDCODED POSITIONS for 'global_game_scale = 4'
				{ x = 337, y = 647 },
				{ x = 414, y = 727 },
				{ x = 523, y = 810 },
				{ x = 654, y = 916 },
				{ x = 1387, y = 741 },
				{ x = 1536, y = 634 },
			},
			shop_slot_size = shop_slot_size,
			open_slots = 5,
			max_slots = 6,
			level = 1,
		})
		self.gold = { total = 5, gold_per_interest = 3 }
		self.game_state = { turn = 1, phase = Game_Loop[1], phase_index = 1, event = Events.Calm }
		self.players_turn = true
		-- self.shop:populate()
	else -- rebuild run from savestate
	end

	self.next_button = collect_into(
		self.game_ui_elements,
		Button({
			group = self.ui,
			layer = ui_interaction_layer.Game,
			x = gw * 0.9,
			y = gh * 0.9,
			-- w = gw * 0.15,
			button_text = "end turn",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				-- [SFX]
				print("    next pressed")
				self:next_turn(true) -- TODO: remove
			end,
		})
	)
end

Phases = {
	Shop = function(game)
		print("shop")
	end,
	Pieces = function(game)
		print("pieces")
		-- game.board:trigger_buildings()
		game:next_turn(true)
	end,
	Event = function(game)
		game.game_state.event.current_countdown = game.game_state.event.current_countdown or game.game_state.event.countdown -- failsafe
		print("event: " .. game.game_state.event.name .. ", countdown: " .. game.game_state.event.current_countdown)

		if game.game_state.event.current_countdown > 0 then
			game.game_state.event.current_countdown = game.game_state.event.current_countdown - 1
		else
			print("triggering " .. game.game_state.event.name .. " event")
			-- game.board:trigger_event(game.game_state.event)
			game.game_state.event = random:table(Events)
			game.game_state.event.current_countdown = game.game_state.event.countdown
		end
		game:next_turn(true)
	end,
}

Events = {
	Calm = { -- nothing happens
		name = "calm",
		countdown = 2,
	},
	Fissure = { -- earthquake, in a line converts tiles to lava and destroys buildings that can't handle 'shake' and lava traits
		name = "fissue",
		countdown = 4,
	},
}
Game_Loop = { Phases.Shop, Phases.Pieces, Phases.Event }

function Game:next_turn(force)
	if not force and not self.players_turn then -- TODO: uncomment
		return
	end
	self.players_turn = false

	-- goto next phase, proc next phase,
	self.game_state.phase_index = (self.game_state.phase_index % #Game_Loop) + 1
	self.game_state.phase = Game_Loop[self.game_state.phase_index]
	self.game_state.phase(self)
end

function Game:update(dt)
	play_music({ volume = 0.3 })
	if self.song_info_text then
		self.song_info_text:update(dt)
	end

	if not self.in_pause and not self.stuck and not self.won then
		run_time = run_time + dt
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

			-- random:table(menu_loading):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
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

	if input.space.pressed then
		self.shop:reroll()
	end

	if input.m1.pressed then
		-- 	local mouse_x, mouse_y = self.main:get_mouse_position()
		-- 	print("Mouse at: (" .. mouse_x .. ", " .. mouse_y .. ")")
	end

	if input.select.released and game_mouse.holding then
		local building = game_mouse.holding -- temp var for clarity

		local valid_tile, errors = self.board:valid_tile_for_building(building)
		if valid_tile then
			self.board:place(building, valid_tile)
			self.shop:clear_slot(building)
		else
			print(table.concat(errors, ", "))
			building:return_to_origin()
		end
		game_mouse.holding = nil
	end

	if game_mouse.holding then
		local mouse_x, mouse_y = self.main:get_mouse_position()
		game_mouse.holding.x = mouse_x
		game_mouse.holding.y = mouse_y
	end

	self:update_game_object(dt * slow_amount)
	star_group:update(dt * slow_amount)
	self.floor:update(dt * slow_amount)
	self.post_main:update(dt * slow_amount)
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
	self.main:update(dt * slow_amount * self.main_slow_amount)
end

function Game:quit()
	if self.died then
		return
	end

	self.quitting = true
	if not self.win_text and not self.win_text2 and self.win and not self.won then
		local level_name = self.pack.levels[self.level].name
		local old_pb = state[level_name]
		state[level_name] = old_pb > self.level_timer and old_pb or self.level_timer
		system.save_state()
		-- random:table(level_victory):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
		input:set_mouse_visible(true)
		self.won = true
		locked_state = nil
		system.save_run()
		trigger:tween(1, _G, { slow_amount = 0 }, math.linear, function()
			slow_amount = 0
		end, "slow_amount")
		trigger:tween(1, _G, { music_slow_amount = 0 }, math.linear, function()
			music_slow_amount = 0
		end, "music_slow_amount")

		ui_layer = ui_interaction_layer.Win
		self.win_ui_elements = {}
		main.ui_layer_stack:push({
			layer = ui_layer,
			layer_has_music = false,
			ui_elements = self.win_ui_elements,
		})

		trigger:after(0.5, function()
			local win_msg = random:table({
				"Knights down",
				"that'll show 'em",
				"good shit",
				"a win is a win",
				"nothin' but death",
				"area secure",
				"just a few more",
			})

			self.win_text = collect_into(
				self.win_ui_elements,
				Text2({
					group = self.end_ui,
					x = gw / 2,
					y = gh / 2 - 40 * global_game_scale,
					force_update = true,
					lines = { { text = "[wavy_mid, cbyc2]" .. win_msg, font = fat_font, alignment = "center" } },
				})
			)

			self.retry = collect_into(
				self.win_ui_elements,
				Button({
					group = self.end_ui,
					x = gw / 2 - 30 * global_game_scale,
					y = gh / 2 + 5 * global_game_scale,
					w = gw * 0.07,
					force_update = true,
					button_text = "[orange]redo",
					fg_color = "fg",
					bg_color = "bg_alt",
					action = function()
						play_level(self, {
							creator_mode = self.creator_mode,
							level = self.level,
							pack = self.pack,
							level_folder = self.level_folder,
						})
					end,
				})
			)

			self.credits_button = collect_into(
				self.win_ui_elements,
				Button({
					group = self.end_ui,
					x = gw / 2,
					y = gh / 2 + 25 * global_game_scale,
					w = gw * 0.12,
					force_update = true,
					button_text = "[yellow]credits",
					fg_color = "fg",
					bg_color = "bg_alt",
					action = function()
						open_credits(self)
					end,
				})
			)
			for _, v in pairs(self.win_ui_elements) do
				-- v.group = ui_group
				-- ui_group:add(v)

				v.layer = ui_layer
				v.force_update = true
			end
		end)

		self.t:after(2, function()
			self.t:tween(0.7, self, { main_slow_amount = 0 }, math.linear, function()
				self.main_slow_amount = 0
			end)
			slow_amount = 1
			music_slow_amount = 1
		end)
	end
end

function Game:draw()
	self.floor:draw()
	self.main:draw()
	self.post_main:draw()
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

	if self.song_info_text then
		local x_pos, y_pos = gw * 0.275, gh * 0.95
		graphics.rectangle(x_pos, y_pos - 5, self.song_info_text.w, self.song_info_text.h, nil, nil, modal_transparent)
		self.song_info_text:draw(x_pos, y_pos, 0, 1, 1)
	end
end

function Game:die()
	if not self.died_text and not self.won then
		-- random:table(level_failure):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
		input:set_mouse_visible(true)
		self.died = true
		locked_state = nil
		system.save_run()

		self.t:tween(2, self, { main_slow_amount = 0 }, math.linear, function()
			self.main_slow_amount = 0
		end)
		self.t:tween(2, _G, { music_slow_amount = 0 }, math.linear, function()
			music_slow_amount = 0
		end)

		main.current.in_death = true
		local ui_layer = ui_interaction_layer.GameLoss
		local ui_group = self.end_ui
		self.game_loss_ui_elements = {}
		main.ui_layer_stack:push({
			layer = ui_layer,
			layer_has_music = false,
			ui_elements = self.game_loss_ui_elements,
		})

		self.died_text = collect_into(
			self.game_loss_ui_elements,
			Text2({
				group = ui_group,
				layer = ui_layer,
				x = gw / 2,
				y = gh / 2,
				force_update = true,
				lines = {
					{
						text = "[wavy_mid, cbyc_fast]" .. self.reason_for_loss,
						font = fat_font,
						alignment = "center",
					},
				},
			})
		)

		self.t:after(0.8, function()
			play_level(self, {
				fast_load = true,
				creator_mode = self.creator_mode,
				level = self.level,
				pack = self.pack,
				level_folder = self.level_folder,
			})

			-- self.died_restart_button = collect_into(
			-- 	self.game_loss_ui_elements,
			-- 	Button({
			-- 		group = ui_group,
			-- 		layer = ui_layer,
			-- 		x = gw / 2,
			-- 		y = gh / 2 + 20,
			-- 		force_update = true,
			-- 		button_text = "run it back",
			-- 		fg_color = "bg",
			-- 		bg_color = "green",
			-- 		action = function(b)
			-- 			play_level(self, {
			-- 				fast_load = true,
			-- 				creator_mode = self.creator_mode,
			-- 				level = self.level,
			-- 				pack = self.pack,
			-- 				level_folder = self.level_folder,
			-- 			})
			-- 		end,
			-- 	})
			-- )
		end)
		-- trigger:tween(2, camera, { x = gw / 2, y = gh / 2, r = 0 }, math.linear, function()
		-- 	camera.x, camera.y, camera.r = gw / 2, gh / 2, 0
		-- end)
	end
	return true
end

function Game:on_exit()
	self.main:destroy()
	self.post_main:destroy()
	self.effects:destroy()
	self.ui:destroy()
	self.end_ui:destroy()
	self.paused_ui:destroy()
	self.options_ui:destroy()
	self.keybinding_ui:destroy()

	self.main = nil
	self.post_main = nil
	self.effects = nil
	self.ui = nil
	self.end_ui = nil
	self.paused_ui = nil
	self.options_ui = nil
	self.keybinding_ui = nil
	self.credits = nil
	self.flashes = nil
	self.hfx = nil
end
