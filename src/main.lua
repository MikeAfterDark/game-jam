require("engine")
require("mainmenu")
require("game")
require("player")
require("renderer")
require("boss")

-- on linux, state is at: ~/.local/share/{love, project_name}/state.txt
function init()
	renderer_init()

	if not state.input then
		state.input = {}
	end
	controls = {
		save_recording = {
			text = "Save Recording",
			default = "w",
			input = state.input.save_recording,
		},
		strong_hit = {
			text = "Strong Hit",
			default = "a",
			input = state.input.strong_hit,
		},
		basic_hit = {
			text = "Basic Hit",
			default = "space",
			input = state.input.basic_hit,
		},
	}
	for action, key in pairs(controls) do
		input:bind(action, key.input or key.default)
	end

	-- load sounds:
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
	-- image1 = Image('name')
	bug_crusher = {
		animation_speed = 0.5,
		sprites = {
			Image("bug_open"),
			Image("bug_close"),
		},
	}
	rock_bug = {
		animation_speed = 0,
		sprites = {
			Image("enemy_single"),
		},
	}
	background_image = {
		animation_speed = 0,
		sprites = {
			Image("bg"),
		},
	}

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

	-- main:add(MainMenu("mainmenu"))
	-- main:go_to("mainmenu")
	main:add(Game("game"))
	main:go_to("game", { folder = "U.N.Owen_was_her", countdown = 1.5 })

	-- set sane defaults:
	state.timed_mode = true
	state.tutorial = true

	-- smooth_turn_speed = 0
end

function update(dt)
	main:update(dt)

	-- update window max sizing
	-- if input.k.pressed then
	-- 	if sx > 1 and sy > 1 then
	-- 		sx, sy = sx - 0.5, sy - 0.5
	-- 		love.window.setMode(480 * sx, 270 * sy)
	-- 		state.sx, state.sy = sx, sy
	-- 		state.fullscreen = false
	-- 	end
	-- end
	--
	-- if input.l.pressed then
	-- 	sx, sy = sx + 0.5, sy + 0.5
	-- 	love.window.setMode(480 * sx, 270 * sy)
	-- 	state.sx, state.sy = sx, sy
	-- 	state.fullscreen = false
	-- end
end

function draw()
	renderer_draw(function()
		main:draw()
	end)
end

function love.run()
	web = love.system.getOS() == "Web"
	global_game_scale = 2
	global_game_width = 480 * global_game_scale
	global_game_height = 270 * global_game_scale

	return engine_run({
		game_name = "Slow Jam 2025",
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
		-- music = self.options_menu_song_instance,
		layer_has_music = not main.current.paused,
		music_type = "options",
		ui_elements = self.options_ui_elements,
	})
	-- play_music({
	-- 	type = "pause" --[[ , force = true ]],
	-- })

	-- trigger:tween(0.25, _G, { slow_amount = 0 }, math.linear, function()
	-- 	slow_amount = 0
	-- self.paused = true

	local column_x = { gw / 4, gw / 2, 3 * gw / 4 }

	local button_offset = -125
	local button_distance = 35

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
			x = column_x[column] - 35,
			y = gh / 2 + 55 * global_game_scale,
			length = slider_length,
			thickness = 50,
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
			x = column_x[column] + 35,
			y = gh / 2 + 55 * global_game_scale,
			length = slider_length,
			thickness = 50,
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
	button_offset = -125
	button_distance = 35

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
		self["input_" .. action] = collect_into(
			self.options_ui_elements,
			InputButton({
				x = column_x[column],
				y = gh / 2 + button_offset,
				w = 85 * global_game_scale,
				separator_length = 50 * global_game_scale,
				description_text = key.text,
				button_text = string.upper(key.input or key.default),
				fg_color = "fg",
				bg_color = "bg",
				action = function(b)
					set_action_keybind(self, action, key)
					b:set_text(string.upper(controls[action].input or key.default))
				end,
			})
		)
		button_offset = button_offset + button_distance - 3 --for some reason this is needed for the last button to work (for 4 controls)
	end

	--
	-- next column: Game-specific options
	--
	column = 3
	button_offset = -125
	button_distance = 35

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

	self.timed_mode_button = collect_into(
		self.options_ui_elements,
		Button({
			x = column_x[column],
			y = gh / 2 + button_offset,
			w = 75 * global_game_scale,
			button_text = tostring(state.timed_mode and "timed mode" or "chill mode"),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.timed_mode = not state.timed_mode
				b:set_text(tostring(state.timed_mode and "timed mode" or "chill mode"))
			end,
		})
	)

	button_offset = button_offset + button_distance
	self.tutorial_button = collect_into(
		self.options_ui_elements,
		Button({
			x = column_x[column],
			y = gh / 2 + button_offset,
			w = 75 * global_game_scale,
			button_text = tostring(state.tutorial and "  tutorial  " or "no tutorial"),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.tutorial = not state.tutorial
				b:set_text(tostring(state.tutorial and "  tutorial  " or "no tutorial"))
			end,
		})
	)
	button_offset = button_offset + button_distance

	for _, v in pairs(self.options_ui_elements) do
		v.group = ui_group
		ui_group:add(v)

		v.layer = ui_layer
		v.force_update = true
	end

	-- end, "pause")
end

function update_keybind_button_display(self)
	if input.last_key_pressed and not (self.confirm.selected and input.last_key_pressed == "m1") then
		self.current_key:set_text({
			{ text = input.last_key_pressed, font = fat_font, alignment = "center" },
		})
		new_key = input.last_key_pressed
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
			lines = { { text = "[wavy_mid2, yellow] Bind '" .. controls[action].text .. "' (press any key)", font = pixul_font, alignment = "center" } },
		})
	)

	self.current_key = collect_into(
		self.key_binding_ui_elements,
		Text2({
			group = ui_group,
			x = gw / 2,
			y = gh / 2,
			-- sx = 1.3,
			-- sy = 1.3,
			lines = { { text = "[fg]" .. string.upper(controls[action].input or controls[action].default), font = fat_font, alignment = "center" } },
		})
	)

	local button_y_offset = 20 * global_game_scale
	local button_x_offset = 30 * global_game_scale
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
				if new_key then
					-- clear any controls that already use new_key
					for k, v in pairs(controls) do
						if v.input == new_key then
							state.input[k] = ""
							controls[k].input = ""
						end
					end

					state.input[action] = new_key
					controls[action].input = new_key
					input:bind(action, new_key)
					new_key = nil
					system.save_state()

					for input_action, _ in pairs(controls) do
						self["input_" .. input_action]:set_text(string.upper(controls[input_action].input or ""))
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
	-- trigger:tween(0.25, _G, { slow_amount = 0 }, math.linear, function()
	-- slow_amount = 0

	trigger:tween(0.25, _G, { slow_amount = 0 }, math.linear, function()
		slow_amount = 0
		self.paused = true
		-- play_music({})
		-- self.paused = true

		self.paused_menu_title_text = collect_into(
			self.paused_ui_elements,
			Text2({
				group = ui_group,
				x = gw / 2,
				y = gh / 2 - 40 * global_game_scale,
				lines = {
					{
						text = "[wavy_mid, green] Paused",
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

		self.restart_with_1_player_button = collect_into(
			self.paused_ui_elements,
			Button({
				group = ui_group,
				x = gw / 2,
				y = gh / 2 + 60 * global_game_scale,
				force_update = true,
				button_text = "restart",
				fg_color = "bg",
				bg_color = "orange",
				action = function()
					restart_level_with_X_players(self, 1)
				end,
			})
		)

		for _, v in pairs(self.paused_ui_elements) do
			-- v.group = ui_group
			-- ui_group:add(v)

			v.layer = ui_layer
			v.force_update = true
		end
	end, "pause")
end

function unpause_game(self)
	trigger:tween(0.25, _G, { slow_amount = 1 }, math.linear, function()
		slow_amount = 1
		self.paused = false
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
		layer_has_music = not main.current.paused,
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
	local y_dist = 40
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
	self.inspiration_section = collect_into(
		self.credits_ui_elements,
		Text2({
			group = ui_group,
			x = columns[1],
			y = yOffset,
			lines = { { text = "[fg]inspiration: ", font = pixul_font } },
		})
	)
	self.inspiration_button = collect_into(
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

	local x_offset = -200
	local x_dist = 130
	self.libraries_button1 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
			x = columns[2] + x_offset,
			y = yOffset,
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
		Text2({ group = ui_group, x = columns[1], y = yOffset, lines = { { text = "[green]music: ", font = pixul_font } } })
	)
	self.music_button1 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
			x = columns[2],
			y = yOffset,
			button_text = "pixabay royalty-free",
			fg_color = "bg",
			bg_color = "green",
			credits_button = true,
			action = function(b)
				open_url(b, "https://pixabay.com/music/search/genre/video%20games/")
			end,
		})
	)

	yOffset = yOffset + y_dist
	self.sound_section = collect_into(
		self.credits_ui_elements,
		Text2({ group = ui_group, x = columns[1], y = yOffset, lines = { { text = "[yellow]sounds: ", font = pixul_font } } })
	)
	self.sound_button1 = collect_into(
		self.credits_ui_elements,
		Button({
			group = self.credits,
			x = columns[2],
			y = yOffset,
			button_text = "BlueYeti Snowball + Audacity + My Mouth",
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
	self.transitioning = true
	ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

	slow_amount = 1
	music_slow_amount = 1
	run_time = 0
	locked_state = nil
	scene_transition(self, gw / 2, gh / 2, Game("game"), { destination = "game", args = { level = main.current.level, num_players = num_players } }, {
		text = "stay hydrated!",
		font = pixul_font,
		alignment = "center",
	})
end

function scene_transition(self, x_pos, y_pos, addition, go_to, text_args)
	TransitionEffect({
		group = main.transitions,
		x = x_pos,
		y = y_pos,
		color = state.dark and bg[-2] or fg[0],
		transition_action = function()
			while main.ui_layer_stack:size() > 1 do
				pop_ui_layer(self)
			end
			self.transitioning = true
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
