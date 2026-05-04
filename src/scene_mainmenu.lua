MainMenu = Object:extend()
MainMenu:implement(State)
MainMenu:implement(GameObject)
function MainMenu:init(name)
	self:init_state(name)
	self:init_game_object()
end

function MainMenu:on_enter(from, args)
	slow_amount = 1
	music_slow_amount = 1
	-- trigger:tween(2, main_song_instance, { volume = 0.5, pitch = 1 }, math.linear)

	self.main_menu_ui = Group() --:no_camera()
	self.options_ui = Group():no_camera()
	self.keybinding_ui = Group():no_camera()
	self.credits = Group():no_camera()

	main.ui_layer_stack:push({
		layer = ui_interaction_layer.Main,
		-- music = self.main_menu_song_instance,
		layer_has_music = false,
		ui_elements = self.main_ui_elements,
	})

	self.in_menu_transition = false
	self.main_ui_elements = {}

	self.song_info_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)

	-- UI positioning:
	--
	-- [title screen][stim cave]
	--
	menu = {
		Title = "Title",
		Stim_Screen = "Stim_Screen",
	}

	self.camera_positions = {
		Title = { x = gw * 0.5, y = gh * 0.5 },
		Stim_Screen = { x = gw * 1.5, y = gh * 0.5 },
	}
	self:setup_title_menu()
	-- self:setup_stim_screen()
	self:set_ui_to(menu.Title)

	self.current_menu = menu.Title
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
end

function MainMenu:update(dt)
	play_music({ volume = 0.3 })
	if self.song_info_text then
		self.song_info_text:update(dt)
	end

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

	self.main_menu_ui:update(dt * slow_amount)
	self.options_ui:update(dt * slow_amount)

	if self.in_keybinding then
		update_keybind_button_display(self)
	end
	self.keybinding_ui:update(dt * slow_amount)

	self.credits:update(dt)
end

function MainMenu:draw()
	self.main_menu_ui:draw()

	if self.in_options then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
	end
	self.options_ui:draw()

	if self.in_keybinding then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
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

function MainMenu:setup_title_menu()
	-- print("setting up title")
	local ui_layer = ui_interaction_layer.Main
	local ui_group = self.main_menu_ui

	-- self.jam_name = collect_into(
	-- 	self.main_ui_elements,
	-- 	Text2({
	-- 		group = ui_group,
	-- 		x = gw / 2,
	-- 		y = gh * 0.4,
	-- 		lines = {
	-- 			{
	-- 				text = "[wavy_mid, fg]Electroaccoustic Invaders!!!",
	-- 				font = pixul_font,
	-- 				alignment = "center",
	-- 			},
	-- 		},
	-- 	})
	-- )

	self.title_text = collect_into(
		self.main_ui_elements,
		Text2({
			group = ui_group,
			x = gw / 2,
			y = gh * 0.35,
			lines = {
				{
					text = "[wavy_rainbow]Rhythm",
					font = fat_title_font,
					alignment = "center",
				},
			},
		})
	)

	-- self.to_stim_screen_button = collect_into(
	-- 	self.main_ui_elements,
	-- 	Button({
	-- 		group = ui_group,
	-- 		x = gw * 0.91,
	-- 		y = gh * 0.5,
	-- 		w = gw * 0.17,
	-- 		button_text = "[wavy_rainbow]Stim Cave :)",
	-- 		fg_color = "fg",
	-- 		bg_color = "black",
	-- 		action = function(b)
	-- 			main.ui_layer_stack:push({
	-- 				layer = ui_interaction_layer.Main,
	-- 				-- music = self.main_menu_song_instance,
	-- 				layer_has_music = true,
	-- 				music_type = "stim_cave",
	-- 				-- ui_elements = self.main_ui_elements,
	-- 			})
	-- 			self:set_ui_to(menu.Stim_Screen)
	-- 		end,
	-- 	})
	-- )

	local button_offset = gh * 0.1
	local button_dist_apart = gh * 0.08
	local core_ui_x_pos = gw * 0.5
	self.play_button1 = collect_into(
		self.main_ui_elements,
		Button({
			group = ui_group,
			x = core_ui_x_pos,
			y = gh * 0.4 + button_offset,
			button_text = "Play",
			fg_color = "bg",
			bg_color = "green",
			action = function(b)
				scene_transition(self, {
					x = gw / 2,
					y = gh / 2,
					type = "circle",
					target = {
						scene = Level_Select,
						name = "level_select",
						args = { clear_music = true },
					},
					display = {
						text = "loading...",
						font = pixul_font,
						alignment = "center",
					},
				})

				-- local pack = self:get_pack_from_path("dev_maps/levels/")
				-- if not self.levels_setup then
				-- 	self:setup_level_menu(pack)
				-- end
				-- self:set_ui_to(menu.Levels)
			end,
		})
	)
	button_offset = button_offset + button_dist_apart

	self.options_button = collect_into(
		self.main_ui_elements,
		Button({
			group = ui_group,
			x = core_ui_x_pos,
			y = gh * 0.4 + button_offset,
			button_text = "options",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				if not self.in_pause then
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
			x = core_ui_x_pos,
			y = gh * 0.9,
			button_text = "credits",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				open_credits(self)
				b.selected = true
			end,
		})
	)

	local debug_ui_x_pos = gw * 0.1
	local debug_ui_y_pos = gh * 0.1
	local debug_ui_y_offset = gh * 0.06
	for i, scene in ipairs(debug_scenes) do
		collect_into(
			self.main_ui_elements,
			Button({
				group = ui_group,
				x = debug_ui_x_pos,
				y = debug_ui_y_pos + (i - 1) * debug_ui_y_offset,
				button_text = scene.id,
				fg_color = "bg",
				bg_color = "fg",
				action = function()
					scene_transition(self, {
						x = gw / 2,
						y = gh / 2,
						type = "circle",
						target = {
							scene = scene.destination,
							name = scene.id,
							args = { clear_music = true },
						},
						display = {
							text = "loading " .. scene.id .. "...",
							font = pixul_font,
							alignment = "center",
						},
					})
				end,
			})
		)
	end

	for _, v in pairs(self.main_ui_elements) do
		-- v.group = ui_group
		-- ui_group:add(v)

		v.layer = ui_layer
		v.force_update = true
	end
end

function MainMenu:setup_stim_screen()
	local ui_layer = ui_interaction_layer.Main
	local ui_group = self.main_menu_ui
	local x_offset = self.camera_positions.Levels.x + gw / 2
	local ui_elements = self.main_ui_elements

	local scale = gw * 0.03
	local spacing = scale * 1.1
	local x_start = x_offset + scale * 2
	local y_start = scale

	local num_rows = ((gh - y_start) / scale) - 3
	local num_columns = (gw / scale) - 6
	local function hsv_to_rgb(h, s, v)
		local r, g, b

		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p = v * (1 - s)
		local q = v * (1 - f * s)
		local t = v * (1 - (1 - f) * s)

		i = i % 6
		if i == 0 then
			r, g, b = v, t, p
		elseif i == 1 then
			r, g, b = q, v, p
		elseif i == 2 then
			r, g, b = p, v, t
		elseif i == 3 then
			r, g, b = p, q, v
		elseif i == 4 then
			r, g, b = t, p, v
		elseif i == 5 then
			r, g, b = v, p, q
		end

		return r, g, b
	end
	for i = 1, num_columns do
		for j = 1, num_rows do
			local u = (i - 1) / (num_columns - 1)
			local v = (j - 1) / (num_rows - 1)

			local hue = (u + v * 0.5 + 0.25 * math.sin(i * 0.1) + 0.25 * math.cos(j * 0.6)) % 1.0
			local sat = math.min(1, 0.7 + 0.3 * math.sin((i + j * 1.5) / 2))
			local val = math.min(1, 0.8 + 0.4 * math.sin((i * 0.8 - j * 1.2) / 3 + 1))

			local r, g, b = hsv_to_rgb(hue, sat, val)

			collect_into(
				ui_elements,
				RectangleButton({
					group = ui_group,
					x = x_start + i * spacing,
					y = y_start + j * spacing,
					w = scale,
					h = scale,
					force_update = true,
					no_image = true,
					color = Color(r, g, b, 1),
					enter_sfx = stim_cave_sfx,
					action = function(b)
						b.spring:pull(0.2, 200, 10)
						-- buttonBoop:play({ pitch = random:float(0.75, 3.05), volume = 0.5 })
					end,
				})
			)
		end
	end

	self.to_title_from_stim_button = collect_into(
		ui_elements,
		Button({
			group = ui_group,
			x = x_offset + gw * 0.04,
			y = gh / 2,
			w = gw * 0.058,
			force_update = true,
			button_text = "back",
			fg_color = "bg",
			bg_color = "fg",
			action = function()
				pop_ui_layer(self)
				self:set_ui_to(menu.Title)
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

function MainMenu:button_restriction()
	return self.in_menu_transition
end

function MainMenu:set_ui_to(target_menu)
	local pos = self.camera_positions[target_menu]
	if not pos then
		print("Warning: Invalid menu target '" .. tostring(target_menu) .. "'")
		return
	end

	local transition_duration = 0.4
	self.previous_menu = self.current_menu
	self.current_menu = target_menu

	self.in_menu_transition = true

	trigger:tween(transition_duration, camera, { x = pos.x, y = pos.y, r = 0 }, math.circ_in_out, function()
		camera.x, camera.y, camera.r = pos.x, pos.y, 0
		self.in_menu_transition = false

		local to_remove = {}
		for i, v in pairs(self.main_ui_elements) do
			if v.delete_on_menu_change and v.delete_on_menu_change == previous_menu then
				v.dead = true
				to_remove[#to_remove + 1] = i
			end
		end

		for _, i in ipairs(to_remove) do
			self.main_ui_elements[i] = nil
		end
	end)
end
