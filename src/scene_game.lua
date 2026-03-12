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
	self.post_main = Group()
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
	self.stuck = false
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
			game = true,
			music_type = self.music_type,
			ui_elements = self.game_ui_elements,
		})
	end

	game_mouse = {
		holding = nil,
	}
	self.layer = ui_interaction_layer.Game

	local num_tiles = 12
	local tile_size = gh * 1 / (num_tiles + 1.8)
	local shop_slot_size = gh * 0.03

	-- init game elements:
	-- board, shop, UI
	self.board = Board({
		group = self.floor,
		layer = ui_interaction_layer.Game,
		x = gw / 2,
		y = gh / 2,
		tile_size = tile_size,
	})

	self.shop = Shop({
		group = self.main,
		layer = ui_interaction_layer.Game,
		positions = {    -- WARN: HARDCODED POSITIONS for 'global_game_scale = 4'
			{ x = 337,  y = 647 }, --
			{ x = 414,  y = 727 },
			{ x = 523,  y = 810 },
			{ x = 654,  y = 916 },
			{ x = 1387, y = 741 },
			{ x = 1536, y = 634 },
		},
		shop_slot_size = shop_slot_size,
		open_slots = 5,
		max_slots = 6,
		level = 1,
	})

	-- local run = system.load_run() --
	if
		true --[[ or next(run) == nil ]]
	then -- new run
		self.run_data = {
			board = { x = 1, y = 1 },
		}
		self:new_board({ x = 1, y = 1, shape = table.random(board_shapes) })
		-- self.board = Board({
		-- 	group = self.floor,
		-- 	layer = ui_interaction_layer.Game,
		-- 	x = gw / 2,
		-- 	y = gh / 2,
		-- 	tile_size = tile_size,
		-- 	rows = num_tiles,
		-- 	columns = num_tiles,
		-- })

		self.resources = {
			gold = {
				total = 15,
				gold_per_interest = 3,
			},
			people = { alive = 25 },
		}

		self.game_state = {
			turn = 1,
			phase = Game_Loop[1](),
			phase_index = 1,
			max_turns = 5,
		}

		self.game_state.in_events = false
		self.events = {}
	else -- rebuild run from savestate
	end

	self.reroll_button = collect_into(
		self.game_ui_elements,
		Button({
			group = self.ui,
			layer = ui_interaction_layer.Game,
			x = gw * 0.7,
			y = gh * 0.88,
			button_text = "reroll",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				-- [SFX]
				self.shop:reroll()
			end,
		})
	)

	self.end_turn_button = collect_into(
		self.game_ui_elements,
		Button({
			group = self.ui,
			layer = ui_interaction_layer.Game,
			x = gw * 0.7,
			y = gh * 0.94,
			button_text = "end turn",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				-- [SFX]
				self:next_turn()
			end,
		})
	)

	self.top_left_escape_button = collect_into(
		self.game_ui_elements,
		Button({
			group = self.ui,
			layer = ui_interaction_layer.Game,
			x = gw * 0.3,
			y = gh * 0.15,
			button_text = "500 gold",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				if self.resources.gold.total > 10 then
					self:new_board({
						x = self.run_data.board.x,
						direction = "left",
						y = self.run_data.board.y + 1,
						shape = table.random(board_shapes),
					})
				end
			end,
		})
	)

	self.top_right_escape_button = collect_into(
		self.game_ui_elements,
		Button({
			group = self.ui,
			layer = ui_interaction_layer.Game,
			x = gw * 0.6,
			y = gh * 0.15,
			button_text = "300 gold",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				if self.resources.gold.total > 5 then
					self:new_board({
						x = self.run_data.board.x + 1, --
						y = self.run_data.board.y,
						direction = "right",
						shape = table.random(board_shapes),
					})
				end
			end,
		})
	)

	self.phase_text = collect_into(
		self.game_ui_elements,
		Text2({
			group = self.ui,
			x = gw * 0.34,
			y = gh * 0.1,
			lines = {
				{ text = self.game_state.phase.name, font = pixul_font },
			},
		})
	)

	self.resources_text = collect_into(
		self.game_ui_elements,
		Text2({
			group = self.ui,
			x = gw * 0.70,
			y = gh * 0.1,
			lines = {
				{ text = "[yellow]Gold: " .. self.resources.gold.total .. "     [green]Babies: " .. self.resources.people.alive, font = pixul_font },
			},
		})
	)
	self._pending_tile_results = {}

	self.info_display = Info_Display({
		group = self.end_ui,
		x = state.info_display_on_right_side and gw * 1.125 or -gw * 0.125,
		y = gh / 2,
		w = gw * 0.25,
		h = gh * 0.95,
		left_button_action = function()
			self:expand_info_display(not state.expanded_info_display)
		end,
		right_button_action = function()
			self:expand_info_display(not state.expanded_info_display)
		end,
	})

	self:play_intro()
end

function Game:play_intro()
	-- some intro animation
	--
	-- do this at the end of the intro
	local color = self.game_state.phase.background_color
	trigger:tween(0.5, background_color, { r = color.r, g = color.g, b = color.g, a = color.a }, math.linear)

	trigger:after(0.4, function()
		if state.expanded_info_display then
			self:expand_info_display(true)
		end
		trigger:after(0.2, function()
			self.players_turn = true
			self.shop:reroll()
			self.game_state.phase:run(self)
		end)
	end)
end

function Game:new_board(data)
	-- clean up old board:
	--		apply any permanent buffs/bonuses
	--		remove all buildings,
	self.board:clear_all() -- animation: each tile drops out of frame in a 'happy' way
	--		remove all tiles,
	--		remove all events,
	--		clear/reset shop upgrades
	self.shop:reset()    -- animation: incremental pops down to base level
	--		reset self.game_state variables
	self:clear_game_state() -- animation: blank out all indicators while other animations play
	self.new_board_animation = true

	--
	-- new board:
	--		init new board,
	self.board:generate_board({ shape = data.shape, direction = data.direction, x = data.x, y = data.y })
	--		set self.game_state variables
	self.game_state = {
		turn = 1,
		phase = Game_Loop[1](),
		phase_index = 1,
		max_turns = 5,
	}
	self.run_data.board.x = data.x
	self.run_data.board.y = data.y
	--		apply any events/bonuses on this board
	--
end

function Game:clear_game_state() end

Phases = {
	Shop = function()
		local phase = {
			name = "Shop",
			background_color = Color(0.1, 0.1, 0.1, 0.3),
		}

		function phase:run(game)
			local end_turns = game.game_state.turn - game.game_state.max_turns
			if end_turns == 3 then
				print("GAME OVER")
			elseif end_turns > 0 then
				print("MAX TURNS REACHED, START ENDING: " .. tostring(end_turns))
			end

			if end_turns < 3 then
				print("Turn " .. game.game_state.turn .. ": ", self.name)
				game.players_turn = true
			end
		end

		return phase
	end,

	Pieces = function()
		local phase = {
			name = "Pieces",
			background_color = Color(0.6, 0.9, 0.3, 0.3),
		}

		function phase:run(game)
			print(self.name)

			local building_triggers = game.board:trigger_buildings()

			game._pending_results = {}
			game._pending_index = 1
			game._pending_timer = 0
			game._processing_triggers = true

			for _, stage in ipairs(building_triggers.order) do
				for _, proc in ipairs(building_triggers[stage]) do
					for _, result in ipairs(proc.results) do
						if result.success then
							table.insert(game._pending_results, {
								building = proc.building,
								effects = result.effects,
							})
						end
					end
				end
			end
		end

		return phase
	end,

	Event = function()
		local phase = {
			name = "Event",
			background_color = Color(0.9, 0.1, 0.1, 0.2),
		}

		function phase:run(game)
			print(self.name)

			local state = game.game_state
			local events = game.events

			local new_event = random:table(Events)()
			new_event.current_countdown = new_event.countdown
			new_event.prepared = false
			table.insert(events, new_event)
			print("new event: " .. new_event.name .. ", countdown: " .. new_event.current_countdown)

			for i, event in ipairs(events) do
				event.current_countdown = event.current_countdown or event.countdown
				if not event.prepared then
					event:prep(game)
					event.prepared = true
				end

				if event.current_countdown > 0 then
					event.current_countdown = event.current_countdown - 1
				else
					print("triggering " .. event.name .. " event")
					state.in_events = true
					event.complete = false
					event.triggered = true
					event:trigger(game)
				end

				if not event.triggered then
					print("event: " .. event.name .. ", countdown: " .. event.current_countdown)
				end
			end

			if not state.in_events then
				game:next_turn(true)
			end
		end

		return phase
	end,
}

Events = {
	-- Calm = { -- nothing happens
	-- 	name = "calm",
	-- 	countdown = 2,
	-- 	prep = function(game) -- choose and mark the areas/targets that'll be affected
	-- 	end,
	-- 	trigger = function(game) -- trigger the logic, save the result to a list that'll be processed in Game:update()
	-- 	end,
	-- },

	Fissure = function()
		local event = {
			id = random:uid(),
			name = "fissure",
			countdown = 1,
			tiles = {},
		}

		function event:prep(game)
			self.tiles = game.board:mark_line({
				width = 3,
				r = math.pi * 2 * random:float(),
				event_id = self.id,
			})
		end

		function event:trigger(game)
			camera:shake(20, 0.6)

			for i, tile in ipairs(self.tiles) do
				trigger:after(random:float() * 0.1, function()
					tile:bounce(30, 0.2)
					trigger:after(0.2, function()
						tile:convert_tile({
							event_id = self.id,
							tiles = tiles,
							target = Tile_Type.Lava,
							effects = { "shake" },
						})
					end)
				end)
			end
		end

		function event:update(game) -- so that each event can control the visuals of what it does
			if not self.complete then
				local all_done = true
				for i, tile in ipairs(self.tiles) do
					if table.contains(tile.event_ids, self.id) then
						all_done = false
					end
				end
				self.complete = all_done
			end
		end

		return event
	end,
}

Game_Loop = { Phases.Shop, Phases.Pieces, Phases.Event }

function Game:next_turn(force)
	if not force and not self.players_turn then
		return
	end

	if self.players_turn then
		self.game_state.turn = self.game_state.turn + 1
	end
	self.players_turn = false

	-- goto next phase, proc next phase,
	self.game_state.phase_index = (self.game_state.phase_index % #Game_Loop) + 1
	self.game_state.phase = Game_Loop[self.game_state.phase_index]()
	self.phase_text:set_text({
		{ text = self.game_state.phase.name, font = pixul_font },
	})

	local color = self.game_state.phase.background_color
	trigger:tween(0.2, background_color, { r = color.r, g = color.g, b = color.g, a = color.a }, math.linear)

	trigger:after(0.5, function()
		self.game_state.phase:run(self)
	end)
end

function Game:update(dt)
	play_music({ volume = 0.3 })
	if self.song_info_text then
		self.song_info_text:update(dt)
	end

	if self.phase_text then
		self.phase_text:update(dt)
	end

	if self.resources_text then
		self.resources_text:update(dt)
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

	self.reroll_button.locked = not self.players_turn
	self.end_turn_button.locked = not self.players_turn

	--
	-- Player actions
	--
	if self.players_turn and on_current_ui_layer(self) then
		if input.reroll.pressed then
			self.shop:reroll()
		end
		if input.next_turn.pressed then
			self:next_turn()
		end

		if input.select.released and game_mouse.holding and not game_mouse.holding.dead then
			local building = game_mouse.holding -- temp var for clarity

			local valid_tile, errors = self.board:valid_tile_for_building(building)
			if valid_tile then
				self.board:place(building, valid_tile)
				self.shop:clear_slot(building)
			else
				if #errors > 0 then
					print("cannot place a " .. game_mouse.holding.type.name .. " there: " .. table.concat(errors, ", "))
				end
				building:return_to_origin()
			end
			game_mouse.holding = nil
		end
	end

	if game_mouse.holding then
		local mouse_x, mouse_y = self.main:get_mouse_position()
		game_mouse.holding.x = mouse_x
		game_mouse.holding.y = mouse_y
	end

	--
	-- for processing Pieces event
	--
	if self._processing_triggers then
		self._pending_timer = self._pending_timer - dt

		if self._pending_timer <= 0 then
			local item = self._pending_results[self._pending_index]

			if item then
				item.building.spring:pull(0.2, 200, 10)

				local gold = item.effects.gold or 0
				local people = item.effects.people or 0

				self.resources.gold.total = self.resources.gold.total + gold
				self.resources.people.alive = self.resources.people.alive + people

				if people < 0 then
					self.resources.people.dead = self.resources.people.dead - people
				end

				-- self.resources_text.spring:pull(0.1, 200, 10)
				-- self.resources_text:set_text({
				self.resources_text:set_text({
					{
						text = "[yellow]Gold: " ..
						self.resources.gold.total .. "     [green]Babies: " .. self.resources.people.alive,
						font = pixul_font,
					},
				})

				print("Applying: " .. table.tostring(item.effects))
				self.board:automata_step() -- in case the building did anything to tiles

				-- Move to next
				self._pending_index = self._pending_index + 1
				self._pending_timer = 0.3 -- delay between each animation
			else
				-- Done processing all
				self._processing_triggers = false
				-- print(table.tostring(self.resources))
				self:next_turn(true)
			end
		end
	end

	--
	-- for processing Tile events
	--
	if self.game_state.in_events then
		table.delete(self.events, function(v)
			v:update()
			return v.complete
		end)

		local done = true
		for i, event in ipairs(self.events) do
			if event.triggered and not event.complete then
				done = false
			end
		end

		if done then
			print("event finished")
			self.game_state.in_events = false
			self.board:automata_step()
			self:next_turn(true)
		end
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

function Game:expand_info_display(expand, time)
	if self.info_display.moving then
		return
	end

	time = time or 0.3
	self.info_display.moving = true

	local side = state.info_display_on_right_side and 1 or -1
	local direction = expand and -side or side

	state.expanded_info_display = expand
	system.save_state()

	trigger:tween(
		time,
		self.info_display,
		{
			x = self.info_display.x + direction * self.info_display.w,
		},
		math.quad_in_out,
		function()
			self.info_display.moving = false
		end
	)

	local target_camera_x

	if state.info_display_on_right_side then
		target_camera_x = expand and gw * 0.6 or gw / 2
	else
		target_camera_x = expand and gw * 0.38 or gw / 2
	end

	trigger:tween(time, camera, {
		x = target_camera_x,
	}, math.quad_in_out)
end

function Game:swap_info_display_side()
	if self.info_display.moving then
		return
	end

	local time = 0.1
	local was_expanded = state.expanded_info_display

	if was_expanded then
		state.info_display_on_right_side = not state.info_display_on_right_side -- stupid jank
		self:expand_info_display(false, time)
		state.info_display_on_right_side = not state.info_display_on_right_side
	end

	trigger:after(time + 0.01, function()
		if state.info_display_on_right_side then
			self.info_display.x = gw + self.info_display.w / 2
		else
			self.info_display.x = -self.info_display.w / 2
		end

		if was_expanded then
			self:expand_info_display(true, time)
		end
	end)
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
