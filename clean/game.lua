Game = Object:extend()
Game:implement(State)
Game:implement(GameObject)
function Game:init(name)
	self:init_state(name)
	self:init_game_object()
end

function Game:on_enter(from, args) -- level, num_players, player_inputs)
	self.hfx:add("condition1", 1)
	self.hfx:add("condition2", 1)
	self.level = args.level or 1
	self.start_time = 4
	self.t:every(1, function()
		if self.start_time > -1 then
			self.start_time = self.start_time - 1
		end
	end)
	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0

	if not state.mouse_control then
		input:set_mouse_visible(false)
	end

	trigger:tween(2, main_song_instance, { volume = 0.5, pitch = 1 }, math.linear)

	self.floor = Group()
	self.main = Group():set_as_physics_world(
		32,
		0,
		0,
		{ "player", "boss", "projectile", "boss_projectile" } -- "force_field", "longboss" }
	)
	self.post_main = Group()
	self.effects = Group()
	self.ui = Group()
	self.options_ui = Group()
	self.credits = Group()

	self.main:disable_collision_between("player", "player")
	self.main:disable_collision_between("player", "projectile")
	self.main:disable_collision_between("player", "boss_projectile")

	self.main:disable_collision_between("projectile", "projectile")
	self.main:disable_collision_between("projectile", "boss_projectile")
	self.main:disable_collision_between("projectile", "boss")

	self.main:disable_collision_between("boss_projectile", "boss")
	self.main:disable_collision_between("boss_projectile", "boss_projectile")
	self.main:disable_collision_between("boss", "boss")
	self.main:enable_trigger_between("projectile", "boss")

	-- self.main:disable_collision_between("player", "force_field")
	-- self.main:disable_collision_between("projectile", "force_field")

	self.main:enable_trigger_between("projectile", "boss")
	self.main:enable_trigger_between("boss_projectile", "player")
	self.main:enable_trigger_between("player", "boss_projectile")
	self.main:enable_trigger_between("boss_projectile", "boss")
	self.enemies = { LongBoss }

	self.main_slow_amount = 1

	-- Spawn solids and player
	-- self.x1, self.y1 = gw / 2 - 0.8 * gw / 2, gh / 2 - 0.8 * gh / 2
	-- self.x2, self.y2 = gw / 2 + 0.8 * gw / 2, gh / 2 + 0.8 * gh / 2
	self.x1, self.y1 = 0, 0
	self.x2, self.y2 = gw, gh
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1

	self.players = {}
	local player_colors = { red[0], yellow[0], green[0], yellow2[0] }
	for i = 1, args.num_players do
		self.players[i] = Player({
			group = self.main,
			x = gw / 2 + i * 20,
			y = gh / 2 + 16,
			color = player_colors[i],
			id = i,
		})
		local chp = CharacterHP({ group = self.effects, x = self.x1 + 8, y = self.y2 + 14, parent = self.players[i] })
		self.players[i].character_hp = chp
	end

	-- Init bosses, choose one randomly (except for debugging)
	if self.level == 1 then
		self.bosses = {
			[1] = self:new_longboss(5),
		}
	elseif self.level == 2 then
		self.bosses = {
			[1] = self:new_longboss(20),
		}
	elseif self.level == 3 then
		self.bosses = {
			[1] = self:new_longboss(40),
			[2] = self:new_longboss(40),
		}
	elseif self.level == 4 then
		self.bosses = {
			[1] = self:new_longboss(10),
			[2] = self:new_longboss(15),
			[3] = self:new_longboss(25),
			[4] = self:new_longboss(10),
		}
	elseif self.level == 5 then
		self.bosses = {
			[1] = self:new_longboss(150),
		}
	end

	Wall({ group = self.main, vertices = math.to_rectangle_vertices(-40, -40, self.x1, gh + 40), color = bg[-1] })
	Wall({ group = self.main, vertices = math.to_rectangle_vertices(self.x2, -40, gw + 40, gh + 40), color = bg[-1] })
	Wall({ group = self.main, vertices = math.to_rectangle_vertices(self.x1, -40, self.x2, self.y1), color = bg[-1] })
	Wall({
		group = self.main,
		vertices = math.to_rectangle_vertices(self.x1, self.y2, self.x2, gh + 40),
		color = bg[-1],
	})
	-- WallCover({
	-- 	group = self.post_main,
	-- 	vertices = math.to_rectangle_vertices(-40, -40, self.x1, gh + 40),
	-- 	color = bg[-1],
	-- })
	-- WallCover({
	-- 	group = self.post_main,
	-- 	vertices = math.to_rectangle_vertices(self.x2, -40, gw + 40, gh + 40),
	-- 	color = bg[-1],
	-- })
	-- WallCover({
	-- 	group = self.post_main,
	-- 	vertices = math.to_rectangle_vertices(self.x1, -40, self.x2, self.y1),
	-- 	color = bg[-1],
	-- })
	-- WallCover({
	-- 	group = self.post_main,
	-- 	vertices = math.to_rectangle_vertices(self.x1, self.y2, self.x2, gh + 40),
	-- 	color = bg[-1],
	-- })
	--
	--
	self.t:every(function()
		for _, boss in ipairs(self.bosses) do
			if not boss.dead then
				return false
			end
		end
		return true
	end, function()
		self:quit()
	end)
end

function Game:on_exit()
	self.main:destroy()
	self.post_main:destroy()
	self.effects:destroy()
	self.ui:destroy()
	self.options_ui:destroy()
	self.main = nil
	self.post_main = nil
	self.effects = nil
	self.ui = nil
	self.options_ui = nil
	self.credits = nil
	self.passives = nil
	self.flashes = nil
	self.bosses = nil
	self.players = nil
	self.hfx = nil
end

function Game:update(dt)
	play_music(0.3)

	if not self.paused and not self.stuck and not self.won then
		run_time = run_time + dt
	end

	-- if self.shop_text then
	-- 	self.shop_text:update(dt)
	-- end

	if input.escape.pressed and not self.transitioning and not self.in_credits then
		if not self.paused and not self.died and not self.won then
			pause_game(self)
		elseif self.in_options and not self.died and not self.won then
			close_options(self)
			self.options_button.selected = true
		else
			self.transitioning = true
			ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

			scene_transition(self, gw / 2, gh / 2, MainMenu("main_menu"), { destination = "main_menu", args = {} }, {
				text = "SPAAAAAAAACE",
				font = pixul_font,
				alignment = "center",
			})
			return
		end
	end

	if not self.transitioning then
		-- if input.r.pressed then
		-- 	self.transitioning = true
		-- 	ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		-- 	ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		-- 	ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		-- 	TransitionEffect({
		-- 		group = main.transitions,
		-- 		x = gw / 2,
		-- 		y = gh / 2,
		-- 		color = state.dark_transitions and bg[-2] or fg[0],
		-- 		transition_action = function()
		-- 			slow_amount = 1
		-- 			music_slow_amount = 1
		-- 			-- main_song_instance:stop()
		-- 			locked_state = nil
		-- 			system.save_run()
		-- 			main:add(Game("game"))
		-- 			main:go_to("game", self.level, #self.players)
		-- 		end,
		-- 		text = Text({
		-- 			{
		-- 				text = "[wavy, "
		-- 					.. tostring(state.dark_transitions and "fg" or "bg")
		-- 					.. "] level "
		-- 					.. (main.current.level == 5 and "[red]" or "")
		-- 					.. main.current.level
		-- 					.. "[red]/5",
		-- 				font = pixul_font,
		-- 				alignment = "center",
		-- 			},
		-- 		}, global_text_tags),
		-- 	})
		-- end

		if input.escape.pressed then
			self.in_credits = false
			if self.credits_button then
				self.credits_button:on_mouse_exit()
			end
			for _, object in ipairs(self.credits.objects) do
				object.dead = true
			end
			self.credits:update(0)
		end
	end

	self:update_game_object(dt * slow_amount)
	main_song_instance.pitch = math.clamp(slow_amount * music_slow_amount, 0.05, 1)

	star_group:update(dt * slow_amount)
	self.floor:update(dt * slow_amount)
	self.main:update(dt * slow_amount * self.main_slow_amount)
	self.post_main:update(dt * slow_amount)
	self.effects:update(dt * slow_amount)
	self.ui:update(dt * slow_amount)
	self.options_ui:update(dt * slow_amount)
	self.credits:update(dt * slow_amount)
end

function Game:quit()
	if self.died then
		return
	end

	self.quitting = true
	if self.level < 5 then
		if not self.arena_clear_text then
			self.arena_clear_text = Text2({
				group = self.ui,
				x = gw / 2,
				y = gh / 2 - 48,
				lines = {
					{
						text = "[wavy_mid, fg] Level [green]" .. self.level .. "[red]/5[wavy_mid, fg] beat",
						font = fat_font,
						alignment = "center",
					},
				},
			})
		end
		self.t:after(2, function()
			self.slow_transitioning = true
			self.t:tween(0.7, self, { main_slow_amount = 0 }, math.linear, function()
				self.main_slow_amount = 0
			end)
		end)
		self.t:after(3, function()
			self.transitioning = true
			ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

			slow_amount = 1
			music_slow_amount = 1
			locked_state = nil
			local next_level = self.level + 1 -- new var for clarity
			scene_transition(
				self,
				gw / 2,
				gh / 2,
				Game("game"),
				{ destination = "game", args = { level = next_level, num_players = #self.players } },
				{
					text = " level " .. ((self.level + 1) == 5 and "[red]" .. (self.level + 1) or tostring(
						self.level + 1
					)) .. "[red]/5",
					font = pixul_font,
					alignment = "center",
				}
			)
		end)
	elseif not self.win_text and not self.win_text2 then
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
		self.win_text = Text2({
			group = self.ui,
			x = gw / 2,
			y = gh / 2 - 40,
			force_update = true,
			lines = { { text = "[wavy_mid, cbyc2]congratulations!", font = fat_font, alignment = "center" } },
		})
		trigger:after(2.5, function()
			self.win_text2 = Text2({
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
			self.credits_button = Button({
				group = self.ui,
				x = gw / 2,
				y = gh / 2 + 35,
				force_update = true,
				button_text = "credits",
				fg_color = "bg10",
				bg_color = "bg",
				action = function()
					self:create_credits()
				end,
			})
			self.credits_button.selected = true
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

function Game:create_credits()
	local open_url = function(b, url)
		ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		b.spring:pull(0.2, 200, 10)
		b.selected = true
		ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		system.open_url(url)
	end
	self.in_credits = true

	local yOffset = 20
	Text2({ group = self.credits, x = 60, y = yOffset, lines = { { text = "[fg]dev: ", font = pixul_font } } })
	Button({
		group = self.credits,
		x = 125,
		y = yOffset,
		button_text = "Mikey",
		fg_color = "bg",
		bg_color = "fg",
		credits_button = true,
		action = function(b)
			open_url(b, "https://gusakm.itch.io/")
		end,
	})

	yOffset = yOffset + 30
	Text2({
		group = self.credits,
		x = 70,
		y = yOffset,
		lines = { { text = "[fg]inspiration: ", font = pixul_font } },
	})
	Button({
		group = self.credits,
		x = 135,
		y = yOffset,
		button_text = "SNKRX",
		fg_color = "bg",
		bg_color = "fg",
		credits_button = true,
		action = function(b)
			open_url(b, "https://store.steampowered.com/app/915310/SNKRX/")
		end,
	})
	yOffset = yOffset + 30
	Text2({ group = self.credits, x = 60, y = yOffset, lines = { { text = "[blue]libraries: ", font = pixul_font } } })
	Button({
		group = self.credits,
		x = 113,
		y = yOffset,
		button_text = "love2d",
		fg_color = "bg",
		bg_color = "blue",
		credits_button = true,
		action = function(b)
			open_url(b, "https://love2d.org")
		end,
	})
	Button({
		group = self.credits,
		x = 170,
		y = yOffset,
		button_text = "bakpakin",
		fg_color = "bg",
		bg_color = "blue",
		credits_button = true,
		action = function(b)
			open_url(b, "https://github.com/bakpakin/binser")
		end,
	})
	Button({
		group = self.credits,
		x = 237,
		y = yOffset,
		button_text = "davisdude",
		fg_color = "bg",
		bg_color = "blue",
		credits_button = true,
		action = function(b)
			open_url(b, "https://github.com/davisdude/mlib")
		end,
	})
	Button({
		group = self.credits,
		x = 306,
		y = yOffset,
		button_text = "tesselode",
		fg_color = "bg",
		bg_color = "blue",
		credits_button = true,
		action = function(b)
			open_url(b, "https://github.com/tesselode/ripple")
		end,
	})

	yOffset = yOffset + 30
	Text2({ group = self.credits, x = 60, y = yOffset, lines = { { text = "[green]music: ", font = pixul_font } } })
	Button({
		group = self.credits,
		x = 160,
		y = yOffset,
		button_text = "pixabay royalty-free",
		fg_color = "bg",
		bg_color = "green",
		credits_button = true,
		action = function(b)
			open_url(b, "https://pixabay.com/music/search/genre/video%20games/")
		end,
	})

	yOffset = yOffset + 30
	Text2({ group = self.credits, x = 60, y = yOffset, lines = { { text = "[yellow]sounds: ", font = pixul_font } } })
	Button({
		group = self.credits,
		x = 215,
		y = yOffset,
		button_text = "BlueYeti Snowball + Audacity + My Mouth",
		fg_color = "bg",
		bg_color = "yellow",
		credits_button = true,
	})
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

	camera:attach()
	if self.start_time and self.start_time > 0 and not self.choosing_passives then
		graphics.push(gw / 2, gh / 2 - 48, 0, self.hfx.condition1.x, self.hfx.condition1.x)
		graphics.print_centered(
			tostring(self.start_time),
			fat_font,
			gw / 2,
			gh / 2 - 48,
			0,
			1,
			1,
			nil,
			nil,
			self.hfx.condition1.f and fg[0] or red[0]
		)
		graphics.pop()
	end

	if self.win_condition then
		if self.win_condition == "wave" then
			if self.start_time <= 0 then
				graphics.push(self.x2 - 50, self.y1 - 10, 0, self.hfx.condition2.x, self.hfx.condition2.x)
				graphics.print_centered("wave:", fat_font, self.x2 - 50, self.y1 - 10, 0, 0.6, 0.6, nil, nil, fg[0])
				graphics.pop()
				local wave = self.wave
				if wave > self.max_waves then
					wave = self.max_waves
				end
				graphics.push(
					self.x2 - 25 + fat_font:get_text_width(wave .. "/" .. self.max_waves) / 2,
					self.y1 - 8,
					0,
					self.hfx.condition1.x,
					self.hfx.condition1.x
				)
				graphics.print(
					wave .. "/" .. self.max_waves,
					fat_font,
					self.x2 - 25,
					self.y1 - 8,
					0,
					0.75,
					0.75,
					nil,
					fat_font.h / 2,
					self.hfx.condition1.f and fg[0] or yellow[0]
				)
				graphics.pop()
			end
		end
	end
	-- end

	if state.run_timer then
		graphics.print_centered(
			math.round(run_time, 0),
			fat_font,
			self.x2 - 12,
			self.y2 + 16,
			0,
			0.6,
			0.6,
			nil,
			nil,
			fg[0]
		)
	end
	camera:detach()

	if self.level == 20 and self.trailer then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	if self.choosing_passives or self.won or self.paused or self.died then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	if self.paused then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.ui:draw()

	if self.shop_text then
		self.shop_text:draw(gw - 40, gh - 17)
	end

	if self.in_options then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.options_ui:draw()

	if self.in_credits then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
	end
	self.credits:draw()
end

function Game:die()
	if not self.died_text and not self.won and not self.arena_clear_text then
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
		self.died_text = Text2({
			group = self.ui,
			x = gw / 2,
			y = gh / 2 - 32,
			lines = {
				{
					text = "[wavy_mid, cbyc]you died...",
					font = fat_font,
					alignment = "center",
					height_multiplier = 1.25,
				},
			},
		})

		self.t:after(2.2, function()
			self.died_text2 = Text2({
				group = self.ui,
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

			self.died_restart_button = Button({
				group = self.ui,
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
						scene_transition(
							self,
							gw / 2,
							gh / 2,
							Game("game"),
							{ destination = "game", args = { level = self.level, num_players = #self.players } },
							{
								text = "level "
									.. (main.current.level == 5 and "[red]" or "")
									.. main.current.level
									.. "[red]/5",
								font = pixul_font,
								alignment = "center",
							}
						)
					end
				end,
			})
			self.died_restart_button.selected = true
		end)
		trigger:tween(2, camera, { x = gw / 2, y = gh / 2, r = 0 }, math.linear, function()
			camera.x, camera.y, camera.r = gw / 2, gh / 2, 0
		end)
	end
	return true
end

function Game:new_longboss(length)
	local boss = LongBoss({
		group = self.main,
		x = 0,
		y = random:int(0, gh),
		leader = true,
		ii = 1,
	})
	for i = 2, length - 1 do
		boss:add_follower(LongBoss({
			group = self.main,
			ii = i,
		}))
	end

	local units = boss:get_all_units()
	for _, unit in ipairs(units) do
		local chp =
			CharacterHP({ group = self.effects, x = self.x1 + 8 + (unit.ii - 1) * 22, y = self.y2 + 14, parent = unit })
		unit.character_hp = chp
	end
	return boss
end

function Game:get_random_player()
	return self.players[math.random(#self.players)]
end

--
--
--
--
CharacterHP = Object:extend()
CharacterHP:implement(GameObject)
function CharacterHP:init(args)
	self:init_game_object(args)
	self.hfx:add("hit", 1)
	self.cooldown_ratio = 0
end

function CharacterHP:update(dt)
	self:update_game_object(dt)
	local t, d = self.parent.t:get_timer_and_delay("shoot")
	if t and d then
		local m = self.parent.t:get_every_multiplier("shoot")
		self.cooldown_ratio = math.min(t / (d * m), 1)
	end
	local t, d = self.parent.t:get_timer_and_delay("attack")
	if t and d then
		local m = self.parent.t:get_every_multiplier("attack")
		self.cooldown_ratio = math.min(t / (d * m), 1)
	end
	local t, d = self.parent.t:get_timer_and_delay("heal")
	if t and d then
		self.cooldown_ratio = math.min(t / d, 1)
	end
	local t, d = self.parent.t:get_timer_and_delay("buff")
	if t and d then
		self.cooldown_ratio = math.min(t / d, 1)
	end
	local t, d = self.parent.t:get_timer_and_delay("spawn")
	if t and d then
		self.cooldown_ratio = math.min(t / d, 1)
	end
end

function CharacterHP:draw()
	graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
	graphics.rectangle(
		self.x,
		self.y - 2,
		14,
		4,
		2,
		2,
		self.parent.dead and bg[5] or (self.hfx.hit.f and fg[0] or self.parent.color[-2]),
		2
	)
	if self.parent.hp > 0 then
		graphics.rectangle2(
			self.x - 7,
			self.y - 4,
			14 * (self.parent.hp / self.parent.max_hp),
			4,
			nil,
			nil,
			self.parent.dead and bg[5] or (self.hfx.hit.f and fg[0] or self.parent.color[-2])
		)
	end
	if not self.parent.dead then
		graphics.line(
			self.x - 8,
			self.y + 5,
			self.x - 8 + 15.5 * self.cooldown_ratio,
			self.y + 5,
			self.hfx.hit.f and fg[0] or self.parent.color[-2],
			2
		)
	end
	graphics.pop()

	if state.cooldown_snake then
		if table.any(non_cooldown_characters, function(v)
				return v == self.parent.character
			end) then
			return
		end
		local p = self.parent
		graphics.push(p.x, p.y, 0, self.hfx.hit.x, self.hfx.hit.y)
		if not p.dead then
			graphics.line(p.x - 4, p.y + 8, p.x - 4 + 8, p.y + 8, self.hfx.hit.f and fg[0] or bg[-2], 2)
			graphics.line(
				p.x - 4,
				p.y + 8,
				p.x - 4 + 8 * self.cooldown_ratio,
				p.y + 8,
				self.hfx.hit.f and fg[0] or self.parent.color[-2],
				2
			)
		end
		graphics.pop()
	end
end

function CharacterHP:change_hp()
	self.hfx:use("hit", 0.5)
end
