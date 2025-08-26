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
	-- trigger:tween(2, main_song_instance, { volume = 0.5, pitch = 1 }, math.linear)

	self.main_menu_ui = Group():no_camera()
	self.options_ui = Group():no_camera()
	self.keybinding_ui = Group():no_camera()
	self.credits = Group()

	main.ui_layer_stack:push({
		layer = ui_interaction_layer.Main,
		-- music = self.main_menu_song_instance,
		layer_has_music = false,
		ui_elements = self.main_ui_elements,
	})

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
		{ text = "posture check!", font = pixul_font, alignment = "center" }
	)
end

function MainMenu:on_exit()
	self.options_ui:destroy()
	self.keybinding_ui:destroy()
	self.main_menu_ui:destroy()
	self.t:destroy()
	self.options_ui = nil
	self.keybinding_ui = nil
	self.t = nil
	self.springs = nil
	self.flashes = nil
	self.hfx = nil
	self.title_text = nil
end

function MainMenu:update(dt)
	play_music({ volume = 0.3 })

	self:update_game_object(dt * slow_amount)
	-- main.ui_layer_stack:peek().music.pitch = math.clamp(slow_amount * music_slow_amount, 0.05, 1)

	if input.escape.pressed then
		if self.in_options then
			if self.in_keybinding then
				close_keybinding(self)
			else
				close_options(self)
			end
		elseif self.in_credits then
			close_credits(self)
		elseif not self.transitioning and not web then
			system.save_state()
			love.event.quit()
		end
	end

	if not self.paused and not self.transitioning then
		self.main_menu_ui:update(dt * slow_amount)
		if self.title_text then
			self.title_text:update(dt)
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

	self.options_ui:update(dt * slow_amount)

	if self.in_keybinding then
		update_keybind_button_display(self)
	end
	self.keybinding_ui:update(dt * slow_amount)
	self.credits:update(dt)

	-- if input.m2.pressed then
	-- 	if not self.counter then
	-- 		self.counter = 1
	-- 	end
	-- 	if not self.debug then
	-- 		self.debug = Text2({
	-- 			group = main.current.main_menu_ui,
	-- 			x = 100,
	-- 			y = 20,
	-- 			force_update = true,
	-- 			lines = {
	-- 				{
	-- 					text = tostring(main.current_music_type),
	-- 					-- text = tostring(self.counter),
	-- 					font = pixul_font,
	-- 					alignment = "center",
	-- 				},
	-- 			},
	-- 		})
	-- 	end
	-- end
	-- if input.m3.pressed and self.debug then
	-- 	self.debug:clear()
	-- 	self.debug = nil
	-- 	-- self.counter = self.counter + 1
	-- end
end

function MainMenu:draw()
	graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)

	self.main_menu_ui:draw()
	self.title_text:draw(gw / 2, gh / 2 - 40)

	if self.in_options then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
	end
	self.options_ui:draw()

	if self.in_keybinding then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
	end
	self.keybinding_ui:draw()

	if self.in_credits then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.credits:draw()
end

function MainMenu:setup_main_menu_ui()
	local ui_layer = ui_interaction_layer.Main
	local ui_group = self.main_menu_ui
	self.main_ui_elements = {}

	-- self.debug = collect_into(
	-- 	self.main_ui_elements,
	-- 	Text({
	-- 		{
	-- 			text = "test",
	-- 			font = pixul_font,
	-- 			alignment = "center",
	-- 		},
	-- 	}, global_text_tags)
	-- )

	self.jam_name = collect_into(
		self.main_ui_elements,
		Text2({
			group = ui_group,
			x = gw / 2,
			y = gh * 0.05,
			lines = {
				{
					text = "[wavy_mid, fg]SLOW JAM 2025!!",
					font = pixul_font,
					alignment = "center",
				},
			},
		})
	)

	self.title_text = collect_into(
		self.main_ui_elements,
		Text({ { text = "[wavy_title, green]CHOMP-CHOMP ROCK", font = fat_title_font, alignment = "center" } }, global_text_tags)
	)

	local button_offset = gh * 0.1
	local button_dist_apart = gh * 0.08
	self.play_button1 = collect_into(
		self.main_ui_elements,
		Button({
			group = ui_group,
			x = gw / 2,
			y = gh / 2 + button_offset,
			button_text = "Play",
			fg_color = "bg",
			bg_color = "green",
			action = function(b)
				self:play(1)
			end,
		})
	)
	button_offset = button_offset + button_dist_apart

	-- self.play_button2 = collect_into(
	-- 	self.main_ui_elements,
	-- 	Button({
	-- 		group = ui_group,
	-- 		x = gw / 2,
	-- 		y = gh / 2 + button_offset,
	-- 		button_text = "2 Players",
	-- 		fg_color = "bg",
	-- 		bg_color = "green",
	-- 		action = function(b)
	-- 			self:play(2)
	-- 		end,
	-- 	})
	-- )
	-- button_offset = button_offset + button_dist_apart
	--
	-- self.play_button3 = collect_into(
	-- 	self.main_ui_elements,
	-- 	Button({
	-- 		group = ui_group,
	-- 		x = gw / 2,
	-- 		y = gh / 2 + button_offset,
	-- 		button_text = "3 Players",
	-- 		fg_color = "bg",
	-- 		bg_color = "green",
	-- 		action = function(b)
	-- 			self:play(3)
	-- 		end,
	-- 	})
	-- )
	-- button_offset = button_offset + button_dist_apart
	--
	-- self.play_button4 = collect_into(
	-- 	self.main_ui_elements,
	-- 	Button({
	-- 		group = ui_group,
	-- 		x = gw / 2,
	-- 		y = gh / 2 + button_offset,
	-- 		button_text = "4 Players",
	-- 		fg_color = "bg",
	-- 		bg_color = "green",
	-- 		action = function(b)
	-- 			self:play(4)
	-- 		end,
	-- 	})
	-- )
	-- button_offset = button_offset + button_dist_apart

	self.options_button = collect_into(
		self.main_ui_elements,
		Button({
			group = ui_group,
			x = gw / 2,
			y = gh / 2 + button_offset,
			button_text = "options",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				if not self.paused then
					open_options(self)
					b.selected = true
				else
					close_options(self)
				end
			end,
		})
	)
	self.credits_button = collect_into(
		self.main_ui_elements,
		Button({
			group = ui_group,
			x = gw / 2,
			y = gh * 0.95,
			button_text = "credits",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				open_credits(self)
				b.selected = true
			end,
		})
	)

	for _, v in pairs(self.main_ui_elements) do
		-- v.group = ui_group
		-- ui_group:add(v)

		v.layer = ui_layer
		v.force_update = true
	end
end
