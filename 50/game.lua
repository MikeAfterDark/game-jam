Game = Object:extend()
Game:implement(State)
Game:implement(GameObject)
function Game:init(name)
	self:init_state(name)
	self:init_game_object()
end

function Game:on_enter(from)
	self.hfx:add("condition1", 1)
	self.hfx:add("condition2", 1)
	self.level = level or 1

	if not state.mouse_control then
		input:set_mouse_visible(false)
	end

	trigger:tween(2, main_song_instance, { volume = 0.5, pitch = 1 }, math.linear)

	self.floor = Group()
	self.main = Group():set_as_physics_world(
		32,
		0,
		0,
		{ "player", "enemy", "projectile", "enemy_projectile", "force_field", "ghost" }
	)
	self.post_main = Group()
	self.effects = Group()
	self.ui = Group()
	self.credits = Group()

	self.main_slow_amount = 1

	-- Spawn solids and player
	self.x1, self.y1 = gw / 2 - 0.8 * gw / 2, gh / 2 - 0.8 * gh / 2
	self.x2, self.y2 = gw / 2 + 0.8 * gw / 2, gh / 2 + 0.8 * gh / 2
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1

	self.player = Player({
		group = self.main,
		x = gw / 2,
		y = gh / 2 + 16,
	})
	-- Wall({ group = self.main, vertices = math.to_rectangle_vertices(-40, -40, self.x1, gh + 40), color = bg[-1] })
	-- Wall({ group = self.main, vertices = math.to_rectangle_vertices(self.x2, -40, gw + 40, gh + 40), color = bg[-1] })
	-- Wall({ group = self.main, vertices = math.to_rectangle_vertices(self.x1, -40, self.x2, self.y1), color = bg[-1] })
	-- Wall({
	-- 	group = self.main,
	-- 	vertices = math.to_rectangle_vertices(self.x1, self.y2, self.x2, gh + 40),
	-- 	color = bg[-1],
	-- })
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
end

function Game:on_exit()
	self.main:destroy()
	self.post_main:destroy()
	self.effects:destroy()
	self.ui:destroy()
	self.main = nil
	self.post_main = nil
	self.effects = nil
	self.ui = nil
	self.credits = nil
	self.passives = nil
	self.flashes = nil
	self.hfx = nil
end

function Game:update(dt)
	if main_song_instance:isStopped() then
		main_song_instance = _G[random:table({ "song1", "song2", "song3", "song4", "song5" })]:play({ volume = 0.3 })
	end

	if not self.paused and not self.stuck and not self.won then
		run_time = run_time + dt
	end

	-- if self.shop_text then
	-- 	self.shop_text:update(dt)
	-- end

	if input.escape.pressed and not self.transitioning and not self.in_credits then
		if not self.paused then
			open_options(self)
		else
			close_options(self)
		end
	end

	if --[[ self.paused or self.died or self.won and ]]
		not self.transitioning
	then
		if input.r.pressed then
			self.transitioning = true
			ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			TransitionEffect({
				group = main.transitions,
				x = gw / 2,
				y = gh / 2,
				color = state.dark_transitions and bg[-2] or fg[0],
				transition_action = function()
					slow_amount = 1
					music_slow_amount = 1
					main_song_instance:stop()
					locked_state = nil
					system.save_run()
					main:add(Game("game"))
					main:go_to("game")
				end,
				text = Text({
					{
						text = "[wavy, " .. tostring(state.dark_transitions and "fg" or "bg") .. "]restarting...",
						font = pixul_font,
						alignment = "center",
					},
				}, global_text_tags),
			})
		end

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
	self.credits:update(dt)
end

function Game:quit()
	if self.died then
		return
	end

	self.quitting = true
	if self.level % 25 == 0 then
		self:gain_gold()
		if not self.win_text and not self.win_text2 then
			input:set_mouse_visible(true)
			self.won = true
			locked_state = nil
		end
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

	self.close_button = Button({
		group = self.credits,
		x = gw - 20,
		y = 20,
		button_text = "x",
		bg_color = "bg",
		fg_color = "bg10",
		credits_button = true,
		action = function()
			trigger:after(0.01, function()
				self.in_credits = false
				if self.credits_button then
					self.credits_button:on_mouse_exit()
				end
				for _, object in ipairs(self.credits.objects) do
					object.dead = true
				end
				self.credits:update(0)
			end)
		end,
	})

	self.in_credits = true
	Text2({ group = self.credits, x = 60, y = 20, lines = { { text = "[bg10]main dev: ", font = pixul_font } } })
	Button({
		group = self.credits,
		x = 117,
		y = 20,
		button_text = "a327ex",
		fg_color = "bg10",
		bg_color = "bg",
		credits_button = true,
		action = function(b)
			open_url(b, "https://store.steampowered.com/dev/a327ex/")
		end,
	})
	Text2({ group = self.credits, x = 60, y = 50, lines = { { text = "[bg10]mobile: ", font = pixul_font } } })
	Button({
		group = self.credits,
		x = 144,
		y = 50,
		button_text = "David Khachaturov",
		fg_color = "bg10",
		bg_color = "bg",
		credits_button = true,
		action = function(b)
			open_url(b, "https://davidobot.net/")
		end,
	})
	Text2({ group = self.credits, x = 60, y = 80, lines = { { text = "[blue]libraries: ", font = pixul_font } } })
	Button({
		group = self.credits,
		x = 113,
		y = 80,
		button_text = "love2d",
		fg_color = "bluem5",
		bg_color = "blue",
		credits_button = true,
		action = function(b)
			open_url(b, "https://love2d.org")
		end,
	})
	Button({
		group = self.credits,
		x = 170,
		y = 80,
		button_text = "bakpakin",
		fg_color = "bluem5",
		bg_color = "blue",
		credits_button = true,
		action = function(b)
			open_url(b, "https://github.com/bakpakin/binser")
		end,
	})
	Button({
		group = self.credits,
		x = 237,
		y = 80,
		button_text = "davisdude",
		fg_color = "bluem5",
		bg_color = "blue",
		credits_button = true,
		action = function(b)
			open_url(b, "https://github.com/davisdude/mlib")
		end,
	})
	Button({
		group = self.credits,
		x = 306,
		y = 80,
		button_text = "tesselode",
		fg_color = "bluem5",
		bg_color = "blue",
		credits_button = true,
		action = function(b)
			open_url(b, "https://github.com/tesselode/ripple")
		end,
	})
	Text2({ group = self.credits, x = 60, y = 110, lines = { { text = "[green]music: ", font = pixul_font } } })
	Button({
		group = self.credits,
		x = 100,
		y = 110,
		button_text = "kubbi",
		fg_color = "greenm5",
		bg_color = "green",
		credits_button = true,
		action = function(b)
			open_url(b, "https://kubbimusic.com/album/ember")
		end,
	})
	Text2({ group = self.credits, x = 60, y = 140, lines = { { text = "[yellow]sounds: ", font = pixul_font } } })
	Button({
		group = self.credits,
		x = 135,
		y = 140,
		button_text = "sidearm studios",
		fg_color = "yellowm5",
		bg_color = "yellow",
		credits_button = true,
		action = function(b)
			open_url(b, "https://sidearm-studios.itch.io/ultimate-sound-fx-bundle")
		end,
	})
	Button({
		group = self.credits,
		x = 217,
		y = 140,
		button_text = "justinbw",
		fg_color = "yellowm5",
		bg_color = "yellow",
		credits_button = true,
		action = function(b)
			open_url(b, "https://freesound.org/people/JustinBW/sounds/80921/")
		end,
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

	-- if self.boss_level then
	-- 	if self.start_time <= 0 then
	-- 		graphics.push(self.x2 - 106, self.y1 - 10, 0, self.hfx.condition2.x, self.hfx.condition2.x)
	-- 		graphics.print_centered(
	-- 			"kill the elite",
	-- 			fat_font,
	-- 			self.x2 - 106,
	-- 			self.y1 - 10,
	-- 			0,
	-- 			0.6,
	-- 			0.6,
	-- 			nil,
	-- 			nil,
	-- 			fg[0]
	-- 		)
	-- 		graphics.pop()
	-- 	end
	-- else
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
	self.ui:draw()

	if self.shop_text then
		self.shop_text:draw(gw - 40, gh - 17)
	end

	if self.in_credits then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
	end
	self.credits:draw()
end
