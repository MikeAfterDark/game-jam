require("engine")
require("mainmenu")
require("game")
require("renderer")

require("player")
require("wall")

-- on linux, state is at: ~/.local/share/{love, project_name}/state.txt
function init()
	renderer_init()

	new_keys = {} -- init for rebinding options
	if not state.input then
		state.input = {}
	end
	controls = {
		jump = { text = "Jump", default = { "z" }, input = state.input.jump },
		reset = { text = "Reset", default = { "x" }, input = state.input.reset },
		up = { text = "Up", default = { "up", "w" }, input = state.input.up },
		down = { text = "Down", default = { "down", "s" }, input = state.input.down },
		left = { text = "Left", default = { "left", "a" }, input = state.input.left },
		right = { text = "Right", default = { "right", "d" }, input = state.input.right },
	}
	for action, key in pairs(controls) do
		input:bind(action, key.input or key.default)
	end

	-- load sounds:
	-- TODO: move all sounds and music data to some data file and load *that*
	local s = { tags = { sfx } }
	buttonHover = Sound("buttonHover.ogg", s)
	buttonPop = Sound("buttonPop.ogg", s)

	ui_switch1 = Sound("ui_switch1.ogg", s)
	ui_switch2 = Sound("ui_switch2.ogg", s)
	ui_transition2 = Sound("ui_transition2.ogg", s)

	shoot1 = Sound("pew.ogg", s)
	hit1 = Sound("hit.ogg", s)
	hit4 = Sound("hit4.ogg", s)

	enemy_die1 = Sound("enemy_die1.ogg", s)
	enemy_die2 = Sound("enemy_die2.ogg", s)

	proj_hit_wall1 = Sound("proj_hit_wall1.ogg", s)

	player_hit1 = Sound("player_hit1.ogg", s)
	player_hit2 = Sound("player_hit2.ogg", s)

	success = Sound("success.ogg", s)

	-- load songs
	-- song1 = Sound("neon-rush-retro-synthwave-uplifting-daily-vlog-fast-cuts-sv201-360195.mp3", { tags = { music } })
	-- song2 = Sound("8-bit-gaming-background-music-358443.mp3", { tags = { music } })
	-- song3 = Sound("edm003-retro-edm-_-gamepixel-racer-358045.mp3", { tags = { music } })
	-- song4 = Sound("pixel-fantasia-355123.mp3", { tags = { music } })
	-- song5 = Sound("pixel-fight-8-bit-arcade-music-background-music-for-video-208775.mp3", { tags = { music } })

	song1 = Sound("funk-smooth-party-stylish-379509.mp3", { tags = { music } })
	song2 = Sound("groovy-ambient-funk-201745.mp3", { tags = { music } })
	song3 = Sound("drunk-on-funk-273910.mp3", { tags = { music } })
	song4 = Sound("midnight-quirk-255361.mp3", { tags = { music } })
	song5 = Sound("funky_main-187356.mp3", { tags = { music } })

	pause_song1 = Sound("jazzy-slow-background-music-244598.mp3", { tags = { music } })
	pause_song2 = Sound("glass-of-wine-143532.mp3", { tags = { music } })
	pause_song3 = Sound("for-elevator-jazz-music-124005.mp3", { tags = { music } })

	music_songs = {
		main = { "song1", "song2", "song3", "song4", "song5" },
		paused = { "pause_song1", "pause_song2", "pause_song3" },
		options = { "pause_song1", "pause_song2", "pause_song3" },
		credits = { "pause_song1", "pause_song2", "pause_song3" },
	}

	-- load images:
	wall_arrow_particle = Image("wall_arrow_particle")
	-- wall_arrow_particle = Image("icon")

	-- set logic init
	-- main_song_instance = _G[random:table({ "song1", "song2", "song3", "song4", "song5" })]:play({ volume = 0.3 })
	slow_amount = 1
	music_slow_amount = 1
	run_time = 0

	ui_interaction_layer = {
		Main = 0,
		Options = 1,
		Credits = 2,
		Paused = 3,
		KeyBinding = 4,
		Win = 5,
		Loss = 6,

		Test = 10,
	}

	main = Main()

	main.ui_layer_stack = Stack:new()
	main.ui_layer_stack:push({
		-- layer = ui_interaction_layer.Main,
		-- music = main.main_song_instance,
		layer_has_music = true,
		music_type = "main",
		-- ui_elements = self.main_ui_elements,
	})

	main.current_music_type = "silence"
	play_music({ type = "main", volume = 0.3 })

	start_countdown = 2.5

	main:add(MainMenu("mainmenu"))
	main:go_to("mainmenu", {})
	-- main:add(Game("game")) -- TODO: TEMP
	-- main:go_to("game", { level = 1, num_players = 1 })

	-- set sane defaults:
	state.screen_flashes = true
	state.tutorial = true

	-- smooth_turn_speed = 0
end

function update(dt)
	main:update(dt)
end

function draw()
	renderer_draw(function()
		main:draw()
	end)
end

function love.run()
	web = love.system.getOS() == "Web"

	global_game_scale = 4
	global_game_width = 480 * global_game_scale
	global_game_height = 270 * global_game_scale

	return engine_run({
		game_name = "Bob",
		window_width = "max",
		window_height = "max",
	})
end

function collect_into(target, element)
	table.insert(target, element)
	return element
end

function open_options(self)
	main.current.in_options = true
	input.m1.pressed = false
	input:set_mouse_visible(true)
	local ui_layer = ui_interaction_layer.Options
	local ui_group = self.options_ui
	self.options_ui_elements = {}
	main.ui_layer_stack:push({
		layer = ui_layer,
		layer_has_music = not main.current.in_pause,
		music_type = "options",
		ui_elements = self.options_ui_elements,
	})

	local column_x = { gw / 4, gw / 2, 3 * gw / 4 }

	local button_offset = -gh * 0.2
	local button_distance = gh * 0.06

	local column = 1
	self.dark_mode_button = collect_into(
		self.options_ui_elements,
		Button({
			x = column_x[column],
			y = gh / 2 + button_offset,
			w = 65 * global_game_scale,
			button_text = tostring(state.dark and " dark" or "light") .. " mode",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.dark = not state.dark
				b:set_text(tostring(state.dark and " dark" or "light") .. " mode")
			end,
		})
	)
	button_offset = button_offset + button_distance

	local slider_length = 100 * global_game_scale
	local slider_spacing = 2 * global_game_scale
	self.sfx_slider = collect_into(
		self.options_ui_elements,
		Slider({
			group = ui_group,
			x = column_x[column] - gw * 0.04,
			y = gh / 2 + 55 * global_game_scale,
			length = slider_length,
			thickness = gw * 0.05,
			fg_color = "fg",
			bg_color = "bg",
			rotation = 3 * math.pi / 2,
			max_sections = 20, -- recommend factors of length that are < length/2
			spacing = slider_spacing,
			value = state.sfx_volume or 0.1,
			action = function(b)
				sfx.volume = b.value
				state.sfx_volume = sfx.volume
			end,
		})
	)
	self.sfx_text = collect_into(
		self.options_ui_elements,
		Text2({
			group = ui_group,
			x = self.sfx_slider.x,
			y = self.sfx_slider.y + 57 * global_game_scale,
			lines = { { text = "[fg]SFX", font = pixul_font } },
		})
	)

	self.music_slider = collect_into(
		self.options_ui_elements,
		Slider({
			group = ui_group,
			x = column_x[column] + gw * 0.04,
			y = gh / 2 + 55 * global_game_scale,
			length = slider_length,
			thickness = gw * 0.05,
			fg_color = "fg",
			bg_color = "bg",
			rotation = 3 * math.pi / 2,
			max_sections = 20, -- recommend factors of length that are < length/2
			spacing = slider_spacing,
			value = state.music_volume or 0.1,
			action = function(b)
				music.volume = b.value
				state.music_volume = music.volume
			end,
		})
	)
	self.music_text = collect_into(
		self.options_ui_elements,
		Text2({
			group = ui_group,
			x = self.music_slider.x,
			y = self.music_slider.y + 57 * global_game_scale,
			lines = { { text = "[fg]Music", font = pixul_font } },
		})
	)

	self.fullscreen_button = collect_into(
		self.options_ui_elements,
		Button({
			x = column_x[column],
			y = gh / 2 + button_offset,
			w = 65 * global_game_scale,
			button_text = tostring(state.fullscreen and "fullscreen" or "windowed"),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				state.fullscreen = not state.fullscreen

				b:set_text(tostring(state.fullscreen and "fullscreen" or "windowed"))
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

				local screen_width, screen_height = 960, 540
				if state.fullscreen then
					local _, _, flags = love.window.getMode()
					screen_width, screen_height = love.window.getDesktopDimensions(flags.display)
				end

				ww, wh = screen_width, screen_height
				sx, sy = screen_width / global_game_width, screen_height / global_game_height
				state.sx, state.sy = sx, sy
				setWindow({ width = screen_width, height = screen_height })
			end,
		})
	)
	button_offset = button_offset + button_distance

	self.vsync_button = collect_into(
		self.options_ui_elements,
		Button({
			x = column_x[column],
			y = gh / 2 + button_offset,
			w = 65 * global_game_scale,
			button_text = tostring(state.vsync and "vsync" or "no vsync"),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				state.vsync = not state.vsync
				b:set_text(tostring(state.vsync and "vsync" or "no vsync"))
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				setWindow({ vsync = state.vsync })
			end,
		})
	)
	button_offset = button_offset + button_distance

	self.screen_shake_button = collect_into(
		self.options_ui_elements,
		Button({
			x = column_x[column],
			y = gh / 2 + button_offset,
			w = 65 * global_game_scale,
			button_text = tostring(state.no_screen_shake and "no shake" or "yes shake"),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.no_screen_shake = not state.no_screen_shake
				b:set_text(tostring(state.no_screen_shake and "no shake" or "cam shake"))
			end,
		})
	)
	button_offset = button_offset + button_distance

	--
	-- next column: Controls
	--
	column = 2
	button_offset = -gh * 0.2
	button_distance = gh * 0.06

	self.controls_text = collect_into(
		self.options_ui_elements,
		Text2({
			group = ui_group,
			x = column_x[column],
			y = gh / 2 + button_offset,
			lines = { { text = "[fg]Controls:", font = pixul_font } },
		})
	)
	button_offset = button_offset + button_distance

	for action, key in pairs(controls) do
		local keys = key.input or key.default
		local keys_string = table.concat(keys, ", ")

		self["input_" .. action] = collect_into(
			self.options_ui_elements,
			InputButton({
				x = column_x[column],
				y = gh / 2 + button_offset,
				w = 85 * global_game_scale,
				separator_length = 50 * global_game_scale,
				description_text = key.text,
				button_text = string.upper(keys_string),
				fg_color = "fg",
				bg_color = "bg",
				action = function(b)
					set_action_keybind(self, action, key)
					local updated_keys = controls[action].input or key.default
					b:set_text(string.upper(table.concat(updated_keys, ", ")))
				end,
			})
		)
		button_offset = button_offset + button_distance -
		3                                             --for some reason this is needed for the last button to work (for 4 controls)
	end

	--
	-- next column: Game-specific options
	--
	column = 3
	button_offset = -gh * 0.2
	button_distance = gh * 0.06

	self.games_options_text = collect_into(
		self.options_ui_elements,
		Text2({
			group = ui_group,
			x = column_x[column],
			y = gh / 2 + button_offset,
			lines = { { text = "[fg]Game:", font = pixul_font } },
		})
	)
	button_offset = button_offset + button_distance

	self.screen_flashes_button = collect_into(
		self.options_ui_elements,
		Button({
			x = column_x[column],
			y = gh / 2 + button_offset,
			w = gw * 0.20,
			button_text = tostring(state.screen_flashes and "screen flashes" or "no flashes"),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.screen_flashes = not state.screen_flashes
				b:set_text(tostring(state.screen_flashes and "sreen flashes" or "no flashes"))
			end,
		})
	)

	-- button_offset = button_offset + button_distance
	-- self.tutorial_button = collect_into(
	-- 	self.options_ui_elements,
	-- 	Button({
	-- 		x = column_x[column],
	-- 		y = gh / 2 + button_offset,
	-- 		w = gw * 0.20,
	-- 		button_text = tostring(state.tutorial and "  tutorial  " or "no tutorial"),
	-- 		fg_color = "bg",
	-- 		bg_color = "fg",
	-- 		action = function(b)
	-- 			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 			state.tutorial = not state.tutorial
	-- 			b:set_text(tostring(state.tutorial and "  tutorial  " or "no tutorial"))
	-- 		end,
	-- 	})
	-- )

	-- button_offset = button_offset + button_distance
	for _, v in pairs(self.options_ui_elements) do
		v.group = ui_group
		ui_group:add(v)

		v.layer = ui_layer
		v.force_update = true
	end

	-- end, "pause")
end

function update_keybind_button_display(self)
	if input.last_key_pressed and not ((self.confirm.selected or self.clear.selected) and input.last_key_pressed == "m1") then
		for _, key in ipairs(new_keys) do
			if key == input.last_key_pressed then
				return
			end
		end
		table.insert(new_keys, input.last_key_pressed)
		self.current_key:set_text({
			{ text = string.upper(table.concat(new_keys, ",")), font = fat_font, alignment = "center" },
		})
	end
end

function close_keybinding(self)
	main.current.in_keybinding = false
	pop_ui_layer(self)
end

function set_action_keybind(self, action, key)
	input.last_key_pressed = nil

	main.current.in_keybinding = true
	local ui_layer = ui_interaction_layer.KeyBinding
	local ui_group = self.keybinding_ui
	self.key_binding_ui_elements = {}
	main.ui_layer_stack:push({
		layer = ui_layer,
		layer_has_music = false,
		ui_elements = self.key_binding_ui_elements,
	})

	self.action_text = collect_into(
		self.key_binding_ui_elements,
		Text2({
			group = ui_group,
			x = gw / 2,
			y = gh / 2 - 30 * global_game_scale,
			lines = { { text = "[wavy_mid2, yellow] Bind '" .. controls[action].text .. "' (press any keys)", font = pixul_font, alignment = "center" } },
		})
	)

	local keys = controls[action].input or controls[action].default
	local keys_string = string.upper(table.concat(keys, ", "))

	self.current_key = collect_into(
		self.key_binding_ui_elements,
		Text2({
			group = ui_group,
			x = gw / 2,
			y = gh / 2,
			lines = {
				{
					text = "[fg]" .. keys_string,
					font = fat_font,
					alignment = "center",
				},
			},
		})
	)

	local button_y_offset = 20 * global_game_scale
	local button_x_offset = 50 * global_game_scale
	self.cancel = collect_into(
		self.key_binding_ui_elements,
		Button({
			group = ui_group,
			x = gw / 2 - button_x_offset,
			y = gh / 2 + button_y_offset,
			button_text = "cancel",
			fg_color = "bg",
			bg_color = "red",
			action = function(b)
				close_keybinding(self)
			end,
		})
	)
	self.clear = collect_into(
		self.key_binding_ui_elements,
		Button({
			group = ui_group,
			x = gw / 2,
			y = gh / 2 + button_y_offset,
			button_text = "clear",
			fg_color = "bg",
			bg_color = "orange",
			action = function(b)
				new_keys = {}
				state.input[action] = {}
				controls[action].input = {}
				input:bind(action, {})
				system.save_state()

				self["input_" .. action]:set_text("")
				self.current_key:set_text({ text = "", font = fat_font })
			end,
		})
	)

	self.confirm = collect_into(
		self.key_binding_ui_elements,
		Button({
			group = ui_group,
			x = gw / 2 + button_x_offset,
			y = gh / 2 + button_y_offset,
			button_text = "confirm",
			fg_color = "bg",
			bg_color = "green",
			action = function(b)
				main.current.in_keybinding = false
				if #new_keys > 0 then
					-- clear any controls that already use new_key
					for other_action, control in pairs(controls) do
						if other_action ~= action then
							local current = control.input or {}
							local new_controls = {}

							for _, key in ipairs(current) do
								local found = false
								for _, new_key in ipairs(new_keys) do
									if key == new_key then
										found = true
										break
									end
								end
								if not found then
									table.insert(new_controls, key)
								end
							end

							-- If any keys were removed, update bindings
							if #new_controls ~= #current then
								controls[other_action].input = new_controls
								state.input[other_action] = { unpack(new_controls) }
								input:bind(other_action, new_controls)
							end
						end
					end
					state.input[action] = { unpack(new_keys) }
					controls[action].input = { unpack(new_keys) }
					input:bind(action, controls[action].input)

					-- Clear new_keys in-place to preserve references
					for i = #new_keys, 1, -1 do
						new_keys[i] = nil
					end

					system.save_state()

					-- Update UI display for each input action
					for input_action, _ in pairs(controls) do
						local a_keys = controls[input_action].input or controls[input_action].default or {}
						local a_keys_string = string.upper(table.concat(a_keys, ", "))
						local label = self["input_" .. input_action]

						if label and label.set_text then
							label:set_text(a_keys_string)
						else
							print("Warning: Missing label for input_" .. input_action)
						end
					end
				end
				pop_ui_layer(self)
			end,
		})
	)

	for _, v in pairs(self.key_binding_ui_elements) do
		v.layer = ui_layer
		v.force_update = true
	end
end

function close_options(self)
	main.current.in_options = false
	pop_ui_layer(self)

	system.save_state()
	if self:is(MainMenu) then
		input:set_mouse_visible(true)
	elseif self:is(Game) then
		input:set_mouse_visible(true)
	end
end

function pause_game(self)
	input.m1.pressed = false
	input:set_mouse_visible(true)
	local ui_layer = ui_interaction_layer.Paused
	local ui_group = self.paused_ui
	self.paused_ui_elements = {}
	main.ui_layer_stack:push({
		layer = ui_layer,
		layer_has_music = true,
		music_type = "paused",
		ui_elements = self.paused_ui_elements,
	})

	trigger:tween(0.25, _G, { slow_amount = 0 }, math.linear, function()
		slow_amount = 0
		self.in_pause = true

		self.paused_menu_title_text = collect_into(
			self.paused_ui_elements,
			Text2({
				group = ui_group,
				x = gw / 2,
				y = gh / 2 - 40 * global_game_scale,
				lines = {
					{
						text = "[wavy_smooth, green]Paused",
						font = fat_font,
						alignment = "center",
					},
				},
			})
		)

		self.continue_button = collect_into(
			self.paused_ui_elements,
			Button({
				group = ui_group,
				x = gw / 2, --- 35 * global_game_scale,
				y = gh / 2,
				force_update = true,
				button_text = "continue",
				fg_color = "bg",
				bg_color = "green",
				action = function(b)
					unpause_game(self)
				end,
			})
		)

		self.options_button = collect_into(
			self.paused_ui_elements,
			Button({
				group = ui_group,
				x = gw / 2, --+ 35 * global_game_scale,
				y = gh / 2 + 20 * global_game_scale,
				force_update = true,
				button_text = "options",
				fg_color = "bg",
				bg_color = "fg",
				action = function(b)
					open_options(self)
					b.selected = true
				end,
			})
		)

		self.credits_button = collect_into(
			self.paused_ui_elements,
			Button({
				group = ui_group,
				x = gw / 2, --+ 35 * global_game_scale,
				y = gh / 2 + 40 * global_game_scale,
				force_update = true,
				button_text = "credits",
				fg_color = "bg",
				bg_color = "yellow",
				action = function(b)
					open_credits(self)
					b.selected = true
				end,
			})
		)

		self.creator_button = collect_into(
			self.paused_ui_elements,
			Button({
				group = ui_group,
				x = gw / 2,
				y = gh / 2 + 60 * global_game_scale,
				force_update = true,
				button_text = "creator",
				fg_color = "bg",
				bg_color = "green",
				action = function()
					play_level(self,
						{ creator_mode = true, level_path = main.current:is(Game) and main.current.level_path or "" })
				end,
			})
		)

		-- self.restart_button = collect_into(
		-- 	self.paused_ui_elements,
		-- 	Button({
		-- 		group = ui_group,
		-- 		x = gw / 2,
		-- 		y = gh / 2 + 80 * global_game_scale,
		-- 		force_update = true,
		-- 		button_text = "restart",
		-- 		fg_color = "bg",
		-- 		bg_color = "orange",
		-- 		action = function()
		-- 			play_level(self)
		-- 		end,
		-- 	})
		-- )

		for _, v in pairs(self.paused_ui_elements) do
			-- v.group = ui_group
			-- ui_group:add(v)

			v.layer = ui_layer
			v.force_update = true
		end
	end, "pause")
end

function play_level(self, args)
	scene_transition(self, gw / 2, gh / 2, Game("game"), {
		destination = "game",
		args = args,
	}, { text = "todo text", font = pixul_font, alignment = "center" })
end

function unpause_game(self)
	trigger:tween(0.25, _G, { slow_amount = 1 }, math.linear, function()
		slow_amount = 1
		self.in_pause = false

		pop_ui_layer(self)
	end)
end

function close_credits(self)
	self.in_credits = false
	pop_ui_layer(self)
end

function pop_ui_layer(self)
	stop_current_music(self)
	local popped_layer = main.ui_layer_stack:pop()

	if popped_layer.ui_elements ~= nil then
		for _, item in pairs(popped_layer.ui_elements) do
			if item then
				item.dead = true
				item = nil
			end
		end
	end
end

function open_credits(self)
	local ui_layer = ui_interaction_layer.Credits
	local ui_group = self.credits
	self.credits_ui_elements = {}
	main.ui_layer_stack:push({
		layer = ui_layer,
		-- music = self.credits_menu_song_instance,
		layer_has_music = not main.current.in_pause,
		music_type = "credits",
		ui_elements = self.credits_ui_elements,
	})
	self.in_credits = true

	local open_url = function(b, url)
		ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		b.spring:pull(0.2, 200, 10)
		b.selected = true
		ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		system.open_url(url)
	end

	local yOffset = gh * 0.3
	local y_dist = gh * 0.08
	local columns = { gw / 4, 2 * gw / 3 }
	self.dev_section = collect_into(
		self.credits_ui_elements,
		Text2({ group = ui_group, x = columns[1], y = yOffset, lines = { { text = "[fg]dev: ", font = pixul_font } } })
	)
	self.dev_button = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
			x = columns[2],
			y = yOffset,
			button_text = "Mikey",
			fg_color = "bg",
			bg_color = "fg",
			credits_button = true,
			action = function(b)
				open_url(b, "https://gusakm.itch.io/")
			end,
		})
	)

	yOffset = yOffset + y_dist
	self.artist_section = collect_into(
		self.credits_ui_elements,
		Text2({
			group = ui_group,
			x = columns[1],
			y = yOffset,
			lines = { { text = "[fg]artist: ", font = pixul_font } },
		})
	)
	self.artist_button = collect_into(
		self.credits_ui_elements,
		Button({
			group = self.credits,
			x = columns[2],
			y = yOffset,
			w = gw * 0.1,
			button_text = "[wavy_rainbow]Teirue",
			fg_color = "bg",
			bg_color = "black",
			credits_button = true,
			action = function(b)
				open_url(b, "https://www.instagram.com/teirue.byte/")
			end,
		})
	)

	yOffset = yOffset + y_dist
	self.code_basis_section = collect_into(
		self.credits_ui_elements,
		Text2({
			group = ui_group,
			x = columns[1],
			y = yOffset,
			lines = { { text = "[fg]code based off: ", font = pixul_font } },
		})
	)
	self.code_basis_button = collect_into(
		self.credits_ui_elements,
		Button({
			group = self.credits,
			x = columns[2],
			y = yOffset,
			button_text = "SNKRX",
			fg_color = "bg",
			bg_color = "fg",
			credits_button = true,
			action = function(b)
				open_url(b, "https://store.steampowered.com/app/915310/SNKRX/")
			end,
		})
	)

	yOffset = yOffset + y_dist
	self.libraries_section = collect_into(
		self.credits_ui_elements,
		Text2({ group = ui_group, x = columns[1], y = yOffset, lines = { { text = "[blue]libraries: ", font = pixul_font } } })
	)

	local x_offset = -gw * 0.2
	local x_dist = gw * 0.143
	local x_width = gw * 0.134
	self.libraries_button1 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
			x = columns[2] + x_offset,
			y = yOffset,
			w = x_width,
			button_text = "love2d",
			fg_color = "bg",
			bg_color = "blue",
			credits_button = true,
			action = function(b)
				open_url(b, "https://love2d.org")
			end,
		})
	)
	x_offset = x_offset + x_dist

	self.libraries_button2 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
			x = columns[2] + x_offset,
			y = yOffset,
			w = x_width,
			button_text = "bakpakin",
			fg_color = "bg",
			bg_color = "blue",
			credits_button = true,
			action = function(b)
				open_url(b, "https://github.com/bakpakin/binser")
			end,
		})
	)
	x_offset = x_offset + x_dist
	self.libraries_button3 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
			x = columns[2] + x_offset,
			y = yOffset,
			w = x_width,
			button_text = "davisdude",
			fg_color = "bg",
			bg_color = "blue",
			credits_button = true,
			action = function(b)
				open_url(b, "https://github.com/davisdude/mlib")
			end,
		})
	)
	x_offset = x_offset + x_dist
	self.libraries_button4 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
			x = columns[2] + x_offset,
			y = yOffset,
			w = x_width,
			button_text = "tesselode",
			fg_color = "bg",
			bg_color = "blue",
			credits_button = true,
			action = function(b)
				open_url(b, "https://github.com/tesselode/ripple")
			end,
		})
	)

	yOffset = yOffset + y_dist
	self.music_section = collect_into(
		self.credits_ui_elements,
		Text2({ group = ui_group, x = columns[1], y = yOffset, lines = { { text = "[green]music:", font = pixul_font } } })
	)
	self.music_button1 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
			x = columns[2],
			y = yOffset,
			button_text = "archive.org",
			fg_color = "bg",
			bg_color = "green",
			credits_button = true,
			action = function(b)
				open_url(b, "https://archive.org")
			end,
		})
	)

	yOffset = yOffset + y_dist
	self.sound_section = collect_into(
		self.credits_ui_elements,
		Text2({ group = ui_group, x = columns[1], y = yOffset, lines = { { text = "[yellow]sounds:", font = pixul_font } } })
	)
	self.sound_button1 = collect_into(
		self.credits_ui_elements,
		Button({
			group = self.credits,
			x = columns[2],
			y = yOffset,
			button_text = "BlueYeti Snowball + Audacity + Mikey's Mouth",
			fg_color = "bg",
			bg_color = "yellow",
			credits_button = true,
		})
	)
	for _, v in pairs(self.credits_ui_elements) do
		-- v.group = ui_group
		-- ui_group:add(v)

		v.layer = ui_layer
		v.force_update = true
	end
end

function restart_level_with_X_players(self, num_players)
	slow_amount = 1
	music_slow_amount = 1
	run_time = 0
	locked_state = nil

	scene_transition(self, gw / 2, gh / 2, Game("game"),
		{ destination = "game", args = { level = main.current.level, num_players = num_players } }, {
		text = "stay hydrated!",
		font = pixul_font,
		alignment = "center",
	})
end

function scene_transition(self, x_pos, y_pos, addition, go_to, text_args)
	ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

	while main.ui_layer_stack:size() > 1 do
		pop_ui_layer(self)
	end
	self.transitioning = true
	TransitionEffect({
		group = main.transitions,
		x = x_pos,
		y = y_pos,
		color = state.dark and bg[-2] or fg[0],
		transition_action = function()
			-- slow_amount = 1
			system.save_state()
			main:add(addition)
			main:go_to(go_to.destination, go_to.args)
		end,
		text = Text({
			{
				text = "[wavy, " .. tostring(state.dark and "fg" or "bg") .. "]" .. text_args.text,
				font = text_args.font,
				alignment = text_args.alignment,
			},
		}, global_text_tags),
	})
end

function play_music(args)
	if true then
		return
	end
	--[[
	Overview:
	1. Check the topmost layer with music (layer_has_music == true)
	2. If no music is playing, or the music type changed, play or switch music
	3. Avoid flipping music unnecessarily if already correct
	]]

	if main.ui_layer_stack:is_empty() then
		return
	end

	local index = 0
	local top_music_layer = nil
	while index < main.ui_layer_stack:size() do
		local layer = main.ui_layer_stack:peek(index)
		if layer and layer.layer_has_music then
			top_music_layer = layer
			break
		end
		index = index + 1
	end

	if not top_music_layer then
		return
	end

	local current_playing_music = nil
	index = 0
	while index < main.ui_layer_stack:size() and not current_playing_music do
		local layer = main.ui_layer_stack:peek(index)
		if layer and layer.music and not layer.music:isStopped() then
			current_playing_music = layer.music
		end
		index = index + 1
	end

	local target_type = top_music_layer.music_type
	local volume = args.volume or (music and music.volume or state.music_volume or 0.1)

	if not current_playing_music or current_playing_music:isStopped() or (top_music_layer.music and top_music_layer.music:isStopped()) then
		top_music_layer.music = _G[random:table(music_songs[target_type])]:play({ volume = volume })
		main.current_music_type = target_type
	elseif main.current_music_type ~= target_type then
		current_playing_music:pause()
		if top_music_layer.music then
			top_music_layer.music:resume()
		else
			top_music_layer.music = _G[random:table(music_songs[target_type])]:play({ volume = volume })
		end
		main.current_music_type = target_type
	end
end

function stop_current_music()
	if true then
		return
	end
	if main.ui_layer_stack:peek().music ~= nil then
		main.ui_layer_stack:peek().music:stop()
	end
end

function on_current_ui_layer(self)
	return not main.ui_layer_stack:is_empty() and main.ui_layer_stack:peek().layer == self.layer
end
