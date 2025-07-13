MainMenu = Object:extend()
MainMenu:implement(State)
MainMenu:implement(GameObject)
function MainMenu:init(name)
	self:init_state(name)
	self:init_game_object()
end

function MainMenu:on_enter(from)
	slow_amount = 1
	music_slow_amount = 1
	trigger:tween(2, main_song_instance, { volume = 0.5, pitch = 1 }, math.linear)

	self.main_menu_ui = Group():no_camera()
	self.options_ui = Group():no_camera()
	self.credits = Group()

	self.ui_interaction_layer = ui_interaction_layers.Test

	self:setup_main_menu_ui()
end

function MainMenu:play(num_players)
	ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

	scene_transition(
		self,
		gw / 2,
		gh / 2,
		Game("game"),
		{ destination = "game", args = { level = 1, num_players = num_players } },
		{ text = "Feeding whales...", font = pixul_font, alignment = "center" }
	)
end

function MainMenu:on_exit()
	self.options_ui:destroy()
	self.main_menu_ui:destroy()
	self.t:destroy()
	self.options_ui = nil

	self.t = nil
	self.springs = nil
	self.flashes = nil
	self.hfx = nil
	self.title_text = nil
end

function MainMenu:update(dt)
	play_music(0.3)

	self:update_game_object(dt * slow_amount)
	main_song_instance.pitch = math.clamp(slow_amount * music_slow_amount, 0.05, 1)

	if input.escape.pressed and self.in_options then
		close_options(self)
		self.options_button.selected = true
	elseif input.escape.pressed and not self.transitioning and not self.in_credits and not self.paused then
		system.save_state()
		love.event.quit()
	end

	if not self.paused and not self.transitioning then
		self.main_menu_ui:update(dt * slow_amount)
		if self.title_text then
			self.title_text:update(dt)
		end
		self.options_ui:update(dt * slow_amount)

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
	else
		self.options_ui:update(dt * slow_amount)
	end

	self.credits:update(dt)
end

function MainMenu:draw()
	graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)

	self.main_menu_ui:draw()
	self.title_text:draw(gw / 2, gh / 2 - 40)
	if self.paused or self.in_options then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.options_ui:draw()

	if self.in_credits then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.credits:draw()
end

function MainMenu:create_credits()
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

function MainMenu:setup_main_menu_ui()
	self.jam_name = Text2({
		group = self.main_menu_ui,
		x = gw / 2,
		y = 20,
		force_update = true,
		lines = {
			{
				text = "[wavy_mid, fg]WPG GAME COLLECTIVE!!!",
				font = pixul_font,
				alignment = "center",
			},
		},
	})

	self.slider = Slider({
		group = self.main_menu_ui,
		x = 30,
		y = gh / 2,
		length = 200,
		thickness = 10,
		fg_color = "bg",
		bg_color = "green",
		rotation = math.pi / 2,
		max_sections = 10,
		sections = 4, --(must be 0 <= sections <= max_sections)
		layer = ui_interaction_layers.Test,
		visual_style = "segments", -- (string/enum)
	})

	self.title_text =
		Text({ { text = "[wavy, blue]LONGE WHAL", font = fat_title_font, alignment = "center" } }, global_text_tags)

	local button_offset = -10
	local button_dist_apart = 26
	self.play_button1 = Button({
		group = self.main_menu_ui,
		x = gw / 2,
		y = gh / 2 + button_offset,
		force_update = true,
		button_text = "1 Player",
		fg_color = "bg",
		bg_color = "green",
		action = function(b)
			self:play(1)
		end,
	})

	button_offset = button_offset + button_dist_apart
	self.play_button2 = Button({
		group = self.main_menu_ui,
		x = gw / 2,
		y = gh / 2 + button_offset,
		force_update = true,
		button_text = "2 Players",
		fg_color = "bg",
		bg_color = "green",
		action = function(b)
			self:play(2)
		end,
	})

	button_offset = button_offset + button_dist_apart
	self.play_button3 = Button({
		group = self.main_menu_ui,
		x = gw / 2,
		y = gh / 2 + button_offset,
		force_update = true,
		button_text = "3 Players",
		fg_color = "bg",
		bg_color = "green",
		action = function(b)
			self:play(3)
		end,
	})

	button_offset = button_offset + button_dist_apart
	self.play_button4 = Button({
		group = self.main_menu_ui,
		x = gw / 2,
		y = gh / 2 + button_offset,
		force_update = true,
		button_text = "4 Players",
		fg_color = "bg",
		bg_color = "green",
		action = function(b)
			self:play(4)
		end,
	})

	button_offset = button_offset + button_dist_apart
	self.options_button = Button({
		group = self.main_menu_ui,
		x = gw / 2,
		y = gh / 2 + button_offset,
		force_update = true,
		button_text = "options",
		fg_color = "bg",
		bg_color = "fg",
		action = function(b)
			if not self.paused then
				open_options(self)
				self.options_button.selected = false
			else
				close_options(self)
			end
		end,
	})
	self.credits_button = Button({
		group = self.main_menu_ui,
		x = gw / 2,
		y = gh - 20,
		force_update = true,
		button_text = "credits",
		fg_color = "bg",
		bg_color = "fg",
		action = function()
			self:create_credits()
		end,
	})

	--setup and hookup buttons for controller:
	self.play_button1.selected = true
	self.play_button1.button_up = self.credits_button
	self.play_button1.button_down = self.play_button2

	self.play_button2.button_up = self.play_button1
	self.play_button2.button_down = self.play_button3

	self.play_button3.button_up = self.play_button2
	self.play_button3.button_down = self.play_button4

	self.play_button4.button_up = self.play_button3
	self.play_button4.button_down = self.options_button

	self.options_button.button_up = self.play_button4
	self.options_button.button_down = self.credits_button

	self.credits_button.button_up = self.options_button
	self.credits_button.button_down = self.play_button1

	-- init bounce
	-- self.play_button1.spring:pull(0.1, 200, 10)
	-- self.t:after(0.5, function()
	-- 	self.play_button2.spring:pull(0.1, 200, 10)
	-- end)
	-- self.t:after(1, function()
	-- 	self.play_button3.spring:pull(0.1, 200, 10)
	-- end)
	-- self.t:after(1.5, function()
	-- 	self.play_button4.spring:pull(0.1, 200, 10)
	-- end)
	-- self.quit_button = Button({
	-- 	group = self.main_ui,
	-- 	x = gw / 2,
	-- 	y = gh / 2 + 55,
	-- 	force_update = true,
	-- 	button_text = "quit",
	-- 	fg_color = "bg",
	-- 	bg_color = "red",
	-- 	action = function(b)
	-- 		system.save_state()
	-- 		love.event.quit()
	-- 	end,
	-- })
	-- self.inspiration_button = Button({
	-- 	group = self.main_ui,
	-- 	x = gw / 2,
	-- 	y = gh - 20,
	-- 	force_update = true,
	-- 	button_text = "Check out the inspiration: SNKRX",
	-- 	fg_color = "bg10",
	-- 	bg_color = "bg",
	-- 	action = function(b)
	-- 		ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 		b.spring:pull(0.2, 200, 10)
	-- 		b.selected = true
	-- 		ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 		system.open_url("https://store.steampowered.com/app/915310/SNKRX/")
	-- 	end,
	-- })
	-- self.discord_button = Button({
	-- 	group = self.main_ui,
	-- 	x = gw - 92,
	-- 	y = gh - 17,
	-- 	force_update = true,
	-- 	button_text = "join the community discord!",
	-- 	fg_color = "bg10",
	-- 	bg_color = "bg",
	-- 	action = function(b)
	-- 		ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 		b.spring:pull(0.2, 200, 10)
	-- 		b.selected = true
	-- 		ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 		system.open_url("https://discord.gg/4d6GWmChKY")
	-- 	end,
	-- })
end
