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

	main.ui_layer_stack:push({
		layer = ui_interaction_layer.Main,
		layer_has_music = false,
		ui_elements = self.game_ui_elements,
	})
	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0

	self.floor = Group()
	self.main = Group():set_as_physics_world(
		32 * global_game_scale,
		0,
		0, --
		-- { "indicator", "note" }
		{ "note", "indicator" }
	)
	self.post_main = Group()
	self.effects = Group()
	self.ui = Group():no_camera()
	self.paused_ui = Group():no_camera()
	self.options_ui = Group():no_camera()
	self.keybinding_ui = Group():no_camera()
	self.credits = Group():no_camera()

	self.main:disable_collision_between("indicator", "note")
	self.main:disable_collision_between("note", "note")

	self.main:enable_trigger_between("indicator", "note")
	self.main:enable_trigger_between("note", "indicator")

	self.main_slow_amount = 1

	self.x1, self.y1 = 0, 0
	self.x2, self.y2 = gw, gh
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1

	self.in_pause = false
	self.stuck = false
	self.won = false
end

function Game:on_exit()
	self.main:destroy()
	self.post_main:destroy()
	self.effects:destroy()
	self.ui:destroy()
	self.paused_ui:destroy()
	self.options_ui:destroy()
	self.keybinding_ui:destroy()
	self.main = nil
	self.post_main = nil
	self.effects = nil
	self.ui = nil
	self.paused_ui = nil
	self.options_ui = nil
	self.keybinding_ui = nil
	self.credits = nil
	self.flashes = nil
	self.hfx = nil
end

function Game:unpause_in(time)
	if self.started then
		self.countdown = time
	end
end

function Game:update(dt)
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
			self.transitioning = true
			ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

			scene_transition(self, gw / 2, gh / 2, MainMenu("main_menu"), { destination = "main_menu", args = {} }, {
				text = "loading main menu...",
				font = pixul_font,
				alignment = "center",
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
	self.post_main:update(dt * slow_amount)
	self.effects:update(dt * slow_amount)
	self.ui:update(dt * slow_amount)
	self.paused_ui:update(dt * slow_amount)
	self.options_ui:update(dt * slow_amount)

	-------------------------------------------------------------
	----------------------- UI MENU STUFF -----------------------
	-------------------------------------------------------------

	if self.in_keybinding then
		update_keybind_button_display(self)
	end
	self.keybinding_ui:update(dt * slow_amount)
	self.credits:update(dt * slow_amount)

	if input.m2.pressed then -- NOTE: PLAYTIME DEBUG TEXT
		if not self.counter then
			self.counter = 1
		end
		if not self.debug then
			self.debug = Text2({
				group = self.ui,
				x = 100,
				y = 20,
				force_update = true,
				lines = {
					{
						-- text = tostring(main.current_music_type),
						-- text = string.format("%.2f", self.map.song_position),
						text = tostring("hi"),
						font = pixul_font,
						alignment = "center",
					},
				},
			})
		end
	end
	if input.m3.pressed and self.debug then
		self.debug:clear()
		self.debug = nil
	end
end

function Game:quit()
	if self.died then
		return
	end

	self.quitting = true
	if not self.win_text and not self.win_text2 and self.win then
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
		trigger:tween(4, camera, { x = gw / 2, y = gh / 2, r = 0 }, math.linear, function()
			camera.x, camera.y, camera.r = gw / 2, gh / 2, 0
		end)

		ui_layer = ui_interaction_layer.Win
		local ui_group = self.ui
		self.win_ui_elements = {}
		main.ui_layer_stack:push({
			layer = ui_layer,
			-- music = self.options_menu_song_instance,
			layer_has_music = false,
			ui_elements = self.win_ui_elements,
		})

		self.win_text = Text2({
			group = self.ui,
			x = gw / 2,
			y = gh / 2 - 40 * global_game_scale,
			force_update = true,
			lines = { { text = "[wavy_mid, cbyc2]congratulations!", font = fat_font, alignment = "center" } },
		})
		trigger:after(2.5, function()
			self.win_text2 = collect_into(
				self.win_ui_elements,
				Text2({
					group = self.ui,
					x = gw / 2,
					y = gh / 2,
					force_update = true,
					lines = {
						{
							text = "[fg]you've beaten the game!",
							font = pixul_font,
							alignment = "center",
							height_multiplier = 1.24,
						},
						{ text = "[wavy_mid, yellow]thanks for playing!", font = pixul_font, alignment = "center" },
						-- {
						-- 	text = "[wavy_mid, yellow]victory PCB: [wavy_mid, green]#",
						-- 	font = pixul_font,
						-- 	alignment = "center",
						-- },
					},
				})
			)
			self.credits_button = collect_into(
				self.win_ui_elements,
				Button({
					group = self.ui,
					x = gw / 2,
					y = gh / 2 + 35 * global_game_scale,
					force_update = true,
					button_text = "credits",
					fg_color = "bg10",
					bg_color = "bg",
					action = function()
						open_credits(self)
					end,
				})
			)

			for _, v in pairs(self.win_ui_elements) do
				v.group = ui_group
				ui_group:add(v)

				v.layer = ui_layer
				v.force_update = true
			end
		end)

		self.t:after(2, function()
			self.slow_transitioning = true
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

	graphics.draw_with_mask(function()
		star_canvas:draw(0, 0, 0, 1, 1)
	end, function()
		camera:attach()
		graphics.rectangle(gw / 2, gh / 2, self.w, self.h, nil, nil, fg[0])
		camera:detach()
	end, true)

	if self.in_pause then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.ui:draw()

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

function Game:die()
	if not self.died_text then
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

		-- main.current.in_death = true
		-- local ui_layer = ui_interaction_layer.GameLoss
		-- local ui_group = self.game_loss_ui
		-- self.game_loss_ui_elements = {}
		-- main.ui_layer_stack:push({
		-- 	layer = ui_layer,
		-- 	layer_has_music = false,
		-- 	ui_elements = self.game_loss_ui_elements,
		-- })
		--
		-- self.died_text = collect_into( -- TODO: stopped here, gotta make this ui group, responsive
		-- 	self.options_ui_elements,
		self.died_text = Text2({
			group = self.ui,
			x = gw / 2,
			y = gh / 2 - 32 * global_game_scale,
			force_update = true,
			lines = {
				{
					text = "[wavy_mid, cbyc]ran outta time...",
					font = fat_font,
					alignment = "center",
					height_multiplier = 1.25,
				},
			},
		})
		-- )

		self.t:after(2.2, function()
			self.died_text2 = Text2({
				group = self.ui,
				force_update = true,
				x = gw / 2,
				y = gh / 2,
				lines = {
					{
						text = "[wavy_mid, cbyc2]try again?",
						font = fat_font,
						alignment = "center",
						height_multiplier = 1.25,
					},
				},
			})

			ui_layer = ui_interaction_layer.Loss
			local ui_group = self.ui
			self.loss_ui_elements = {}
			main.ui_layer_stack:push({
				layer = ui_layer,
				-- music = self.options_menu_song_instance,
				layer_has_music = false,
				ui_elements = self.loss_ui_elements,
			})
			self.died_restart_button = collect_into(
				self.loss_ui_elements,
				Button({
					group = self.ui,
					layer = ui_layer,
					x = gw / 2,
					y = gh / 2 + 20,
					force_update = true,
					button_text = "restart",
					fg_color = "bg",
					bg_color = "green",
					action = function(b)
						if not self.transitioning then
							self.transitioning = true
							ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
							ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
							ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

							slow_amount = 1
							music_slow_amount = 1
							locked_state = nil
							scene_transition(self, gw / 2, gh / 2, Game("game"), { destination = "game", args = { level = 1, num_players = 1 } }, {
								text = "chill mode will pause the timer [wavy]forever",
								font = pixul_font,
								alignment = "center",
							})
						end
					end,
				})
			)
		end)
		trigger:tween(2, camera, { x = gw / 2, y = gh / 2, r = 0 }, math.linear, function()
			camera.x, camera.y, camera.r = gw / 2, gh / 2, 0
		end)
	end
	return true
end
