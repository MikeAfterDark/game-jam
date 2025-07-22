require("engine")
require("mainmenu")
require("game")
require("player")
require("renderer")
require("boss")

-- on linux, state is at: ~/.local/share/{love, project_name}/state.txt
function init()
	renderer_init()

	controller_mode = false

	-- Input bindings per player
	local input_sets = {
		player1 = {
			move_up = { "up" },
			move_down = { "down" },
			move_left = { "left" },
			move_right = { "right" },
			move_forward = { "." },
			shoot = { "/" },
		},
		player2 = {
			move_up = { "w" },
			move_down = { "s" },
			move_left = { "a" },
			move_right = { "d" },
			move_forward = { "`" },
			shoot = { "1" },
		},
		player3 = {
			move_up = { "i" },
			move_down = { "k" },
			move_left = { "j" },
			move_right = { "l" },
			move_forward = { "g" },
			shoot = { "h" },
		},
		player4 = {
			move_up = { "kp8" },
			move_down = { "kp5" },
			move_left = { "kp4" },
			move_right = { "kp6" },
			move_forward = { "kp1" },
			shoot = { "kp2" },
		},
	}

	-- Bind each player's actions with unique names like "p1_move_up"
	for pname, bindings in pairs(input_sets) do
		local pid = pname:match("player(%d)")
		for action, keys in pairs(bindings) do
			local action_name = "p" .. pid .. "_" .. action
			input:bind(action_name, keys)
		end
	end

	-- add selection bindings too
	for selection_action, move_action in pairs({
		selection_up = "move_up",
		selection_down = "move_down",
		selection_left = "move_left",
		selection_right = "move_right",
		selection = "move_forward",
	}) do
		local keys = {}
		for _, p in pairs(input_sets) do
			for _, key in ipairs(p[move_action]) do
				table.insert(keys, key)
			end
		end
		input:bind(selection_action, keys)
	end

	-- new input system
	if not state.input then
		state.input = {}
	end
	controls = {
		left = state.input.left or "a",
		right = state.input.right or "d",
		climb = state.input.climb or "w",
		jump = state.input.jump or "space",
	}
	default_controls = { -- copy controls above
		left = "a",
		right = "d",
		climb = "w",
		jump = "space",
	}
	for action, key in pairs(controls) do
		input:bind(action, key)
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

	-- load songs
	song1 = Sound("neon-rush-retro-synthwave-uplifting-daily-vlog-fast-cuts-sv201-360195.mp3", { tags = { music } })
	song2 = Sound("8-bit-gaming-background-music-358443.mp3", { tags = { music } })
	song3 = Sound("edm003-retro-edm-_-gamepixel-racer-358045.mp3", { tags = { music } })
	song4 = Sound("pixel-fantasia-355123.mp3", { tags = { music } })
	song5 = Sound("pixel-fight-8-bit-arcade-music-background-music-for-video-208775.mp3", { tags = { music } })

	pause_song1 = Sound("jazzy-slow-background-music-244598.mp3", { tags = { music } })
	pause_song2 = Sound("glass-of-wine-143532.mp3", { tags = { music } })
	pause_song3 = Sound("for-elevator-jazz-music-124005.mp3", { tags = { music } })

	music_songs = {
		main = { "song1", "song2", "song3", "song4", "song5" },
		-- pause = { "pause_song1", "pause_song2", "pause_song3" },
		-- cheapout: use the same 'pause music' list for all 3 below
		paused = { "buttonPop" },
		options = { "buttonHover" },
		credits = { "hit1" },
	}

	-- load images:
	-- image1 = Image('name')

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

	main:add(MainMenu("mainmenu"))
	main:go_to("mainmenu")

	-- set sane defaults:
	state.mouse_control = true
	state.arrow_snake = true

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
	return engine_run({
		game_name = "Jame Gam 50",
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
		layer_has_music = true,
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

	local button_offset = -65
	local button_distance = 20

	local column = 1
	self.dark_mode_button = collect_into(
		self.options_ui_elements,
		Button({
			x = column_x[column],
			y = gh / 2 + button_offset,
			w = 65,
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

	local slider_length = 100
	local slider_spacing = 2
	self.sfx_slider = collect_into(
		self.options_ui_elements,
		Slider({
			group = ui_group,
			x = column_x[column] - 15,
			y = gh / 2 + 55,
			length = slider_length,
			thickness = 10,
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
			y = self.sfx_slider.y + 57,
			lines = { { text = "[fg]SFX", font = pixul_font } },
		})
	)

	self.music_slider = collect_into(
		self.options_ui_elements,
		Slider({
			group = ui_group,
			x = column_x[column] + 15,
			y = gh / 2 + 55,
			length = slider_length,
			thickness = 10,
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
			y = self.music_slider.y + 57,
			lines = { { text = "[fg]Music", font = pixul_font } },
		})
	)

	self.fullscreen_button = collect_into(
		self.options_ui_elements,
		Button({
			x = column_x[column],
			y = gh / 2 + button_offset,
			w = 65,
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
				sx, sy = screen_width / 480, screen_height / 270
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
			w = 65,
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
			w = 65,
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
	button_offset = -65
	button_distance = 20

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
				w = 85,
				separator_length = 50,
				description_text = action,
				button_text = string.upper(key),
				fg_color = "fg",
				bg_color = "bg",
				action = function(b)
					set_action_keybind(self, action, key)
					b:set_text(string.upper(controls[action]))
				end,
			})
		)
		button_offset = button_offset + button_distance - 3 --for some reason this is needed for the last button to work (for 4 controls)
	end

	--
	-- next column: Game-specific options
	--
	column = 3
	button_offset = -65
	button_distance = 20

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

	self.game_button = collect_into(
		self.options_ui_elements,
		Button({
			x = column_x[column],
			y = gh / 2 + button_offset,
			w = 65,
			button_text = tostring(state.game_thing and "no thing" or "yes thing"),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.game_thing = not state.game_thing
				b:set_text(tostring(state.game_thing and "no thing" or "yes thing"))
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
			y = gh / 2 - 30,
			lines = { { text = "[wavy_mid2, yellow] Bind '" .. action .. "' (press any key)", font = pixul_font, alignment = "center" } },
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
			lines = { { text = "[fg]" .. key, font = fat_font, alignment = "center" } },
		})
	)

	-- if key ~= default_controls[action] then
	-- 	self.default_key = collect_into(
	-- 		self.key_binding_ui_elements,
	-- 		Text2({
	-- 			group = ui_group,
	-- 			x = gw / 2 + 60,
	-- 			y = gh / 2,
	-- 			sx = 0.6,
	-- 			sy = 0.6,
	-- 			lines = {
	-- 				{ text = "[fg]default: " .. default_controls[action], font = fat_font, alignment = "center" },
	-- 			},
	-- 		})
	-- 	)
	-- end

	local button_y_offset = 20
	local button_x_offset = 30
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
						if v == new_key then
							state.input[k] = ""
							controls[k] = ""
						end
					end

					state.input[action] = new_key -- update config
					controls[action] = state.input[action]
					new_key = nil
					system.save_state()

					for input_action, _ in pairs(controls) do
						self["input_" .. input_action]:set_text(string.upper(controls[input_action]))
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
		input:set_mouse_visible(state.mouse_control or false)
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

		-- text = escape to go back to main menu (lose all progress)
		self.paused_ingame_text = collect_into(
			self.paused_ui_elements,
			Text2({
				group = self.paused_ui,
				x = gw / 2,
				y = 20,
				force_update = true,
				sx = 0.6,
				sy = 0.6,
				lines = { { text = "Back to go to main-menu (lose all progress)", font = fat_font, alignment = "center" } },
			})
		)

		self.continue_button = collect_into(
			self.paused_ui_elements,
			Button({
				group = ui_group,
				x = gw / 2 - 35,
				y = gh / 2 - 10,
				force_update = true,
				button_text = "continue",
				fg_color = "bg",
				bg_color = "yellow",
				action = function(b)
					unpause_game(self)
				end,
			})
		)

		self.options_button = collect_into(
			self.paused_ui_elements,
			Button({
				group = ui_group,
				x = gw / 2 + 35,
				y = gh / 2 - 10,
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

		self.restart_text = collect_into(
			self.paused_ui_elements,
			Text2({
				group = ui_group,
				x = gw / 2,
				y = gh / 2 - 48,
				lines = {
					{
						text = "[wavy_mid, fg] restart level " .. (self.level ~= 5 and "[green]" or "[red]") .. self.level .. "[red]/5[wavy_mid, fg]?",
						font = fat_font,
						alignment = "center",
					},
				},
			})
		)

		self.restart_with_1_player_button = collect_into(
			self.paused_ui_elements,
			Button({
				group = ui_group,
				x = gw / 2,
				y = gh / 2 + 30,
				force_update = true,
				button_text = "1 player",
				fg_color = "bg",
				bg_color = "green",
				action = function()
					restart_level_with_X_players(self, 1)
				end,
			})
		)
		self.restart_with_2_player_button = collect_into(
			self.paused_ui_elements,
			Button({
				group = ui_group,
				x = gw / 2,
				y = gh / 2 + 55,
				force_update = true,
				button_text = "2 players",
				fg_color = "bg",
				bg_color = "green",
				action = function()
					restart_level_with_X_players(self, 2)
				end,
			})
		)
		self.restart_with_3_player_button = collect_into(
			self.paused_ui_elements,
			Button({
				group = ui_group,
				x = gw / 2,
				y = gh / 2 + 80,
				force_update = true,
				button_text = "3 players",
				fg_color = "bg",
				bg_color = "green",
				action = function()
					restart_level_with_X_players(self, 3)
				end,
			})
		)
		self.restart_with_4_player_button = collect_into(
			self.paused_ui_elements,
			Button({
				group = ui_group,
				x = gw / 2,
				y = gh / 2 + 105,
				force_update = true,
				button_text = "4 players",
				fg_color = "bg",
				bg_color = "green",
				action = function()
					restart_level_with_X_players(self, 4)
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
		layer_has_music = true,
		music_type = "credits",
		ui_elements = self.credits_ui_elements,
	})
	-- play_music({ })
	self.in_credits = true

	local open_url = function(b, url)
		ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		b.spring:pull(0.2, 200, 10)
		b.selected = true
		ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		system.open_url(url)
	end

	local yOffset = 20
	self.dev_section =
		collect_into(self.credits_ui_elements, Text2({ group = ui_group, x = 60, y = yOffset, lines = { { text = "[fg]dev: ", font = pixul_font } } }))
	self.dev_button = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
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
	)

	yOffset = yOffset + 30
	self.inspiration_section = collect_into(
		self.credits_ui_elements,
		Text2({
			group = ui_group,
			x = 70,
			y = yOffset,
			lines = { { text = "[fg]inspiration: ", font = pixul_font } },
		})
	)
	self.inspiration_button = collect_into(
		self.credits_ui_elements,
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
	)

	yOffset = yOffset + 30
	self.libraries_section = collect_into(
		self.credits_ui_elements,
		Text2({ group = ui_group, x = 60, y = yOffset, lines = { { text = "[blue]libraries: ", font = pixul_font } } })
	)
	self.libraries_button1 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
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
	)
	self.libraries_button2 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
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
	)
	self.libraries_button3 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
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
	)
	self.libraries_button4 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
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
	)

	yOffset = yOffset + 30
	self.music_section =
		collect_into(self.credits_ui_elements, Text2({ group = ui_group, x = 60, y = yOffset, lines = { { text = "[green]music: ", font = pixul_font } } }))
	self.music_button1 = collect_into(
		self.credits_ui_elements,
		Button({
			group = ui_group,
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
	)

	yOffset = yOffset + 30
	self.sound_section = collect_into(
		self.credits_ui_elements,
		Text2({ group = ui_group, x = 60, y = yOffset, lines = { { text = "[yellow]sounds: ", font = pixul_font } } })
	)
	self.sound_button1 = collect_into(
		self.credits_ui_elements,
		Button({
			group = self.credits,
			x = 215,
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
		text = "level " .. (main.current.level == 5 and "[red]" or "") .. main.current.level .. "[red]/5",
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
	if main.ui_layer_stack:peek().music ~= nil then
		main.ui_layer_stack:peek().music:stop()
	end
end

function on_current_ui_layer(self)
	return not main.ui_layer_stack:is_empty() and main.ui_layer_stack:peek().layer == self.layer
end
