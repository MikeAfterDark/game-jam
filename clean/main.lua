require("engine")
require("mainmenu")
require("game")
require("player")
require("renderer")
require("boss")

function init()
	renderer_init()

	controller_mode = true

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

	-- load images:
	-- image1 = Image('name')

	-- set logic init
	play_music(0.3)
	-- main_song_instance = _G[random:table({ "song1", "song2", "song3", "song4", "song5" })]:play({ volume = 0.3 })
	slow_amount = 1
	music_slow_amount = 1
	run_time = 0

	ui_interaction_layers = {
		Options = 1,
		Credits = 2,
		Pause = 3,

		Test = 10,
	}

	main = Main()

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

function open_options_old(self)
	main.current.in_options = true
	input:set_mouse_visible(true)
	-- trigger:tween(0.25, _G, { slow_amount = 0 }, math.linear, function()
	-- 	slow_amount = 0
	-- self.paused = true

	-- err: 'Text2' is undefined
	-- if self:is(Game) then
	-- 	self.paused_t1 = Text2({
	-- 		group = self.ui,
	-- 		x = gw / 2,
	-- 		y = gh / 2 - 108,
	-- 		sx = 0.6,
	-- 		sy = 0.6,
	-- 		lines = { { text = "[bg10]<-, a or m1       ->, d or m2", font = fat_font, alignment = "center" } },
	-- 	})
	-- 	self.paused_t2 = Text2({
	-- 		group = self.ui,
	-- 		x = gw / 2,
	-- 		y = gh / 2 - 92,
	-- 		lines = {
	-- 			{
	-- 				text = "[bg10]turn left                                            turn right",
	-- 				font = pixul_font,
	-- 				alignment = "center",
	-- 			},
	-- 		},
	-- 	})
	-- end

	-- self.resume_button = Button({
	-- 	group = self.ui,
	-- 	x = gw / 2,
	-- 	y = gh - 225,
	-- 	force_update = true,
	-- 	button_text = self:is(MainMenu) and "main menu (esc)" or "resume (esc)",
	-- 	fg_color = "bg",
	-- 	bg_color = "green",
	-- 	action = function(b)
	-- 		trigger:tween(0.25, _G, { slow_amount = 1 }, math.linear, function()
	-- 			slow_amount = 1
	-- 			self.paused = false
	-- 			if self.paused_t1 then
	-- 				self.paused_t1.dead = true
	-- 				self.paused_t1 = nil
	-- 			end
	-- 			if self.paused_t2 then
	-- 				self.paused_t2.dead = true
	-- 				self.paused_t2 = nil
	-- 			end
	-- 			if self.ng_t then
	-- 				self.ng_t.dead = true
	-- 				self.ng_t = nil
	-- 			end
	-- 			if self.resume_button then
	-- 				self.resume_button.dead = true
	-- 				self.resume_button = nil
	-- 			end
	-- 			if self.restart_button then
	-- 				self.restart_button.dead = true
	-- 				self.restart_button = nil
	-- 			end
	-- 			if self.mouse_button then
	-- 				self.mouse_button.dead = true
	-- 				self.mouse_button = nil
	-- 			end
	-- 			if self.dark_transition_button then
	-- 				self.dark_transition_button.dead = true
	-- 				self.dark_transition_button = nil
	-- 			end
	-- 			if self.run_timer_button then
	-- 				self.run_timer_button.dead = true
	-- 				self.run_timer_button = nil
	-- 			end
	-- 			if self.sfx_button then
	-- 				self.sfx_button.dead = true
	-- 				self.sfx_button = nil
	-- 			end
	-- 			if self.music_button then
	-- 				self.music_button.dead = true
	-- 				self.music_button = nil
	-- 			end
	-- 			if self.video_button_1 then
	-- 				self.video_button_1.dead = true
	-- 				self.video_button_1 = nil
	-- 			end
	-- 			if self.video_button_2 then
	-- 				self.video_button_2.dead = true
	-- 				self.video_button_2 = nil
	-- 			end
	-- 			if self.video_button_3 then
	-- 				self.video_button_3.dead = true
	-- 				self.video_button_3 = nil
	-- 			end
	-- 			if self.video_button_4 then
	-- 				self.video_button_4.dead = true
	-- 				self.video_button_4 = nil
	-- 			end
	-- 			-- if self.quit_button then
	-- 			-- 	self.quit_button.dead = true
	-- 			-- 	self.quit_button = nil
	-- 			-- end
	-- 			if self.screen_shake_button then
	-- 				self.screen_shake_button.dead = true
	-- 				self.screen_shake_button = nil
	-- 			end
	-- 			if self.screen_movement_button then
	-- 				self.screen_movement_button.dead = true
	-- 				self.screen_movement_button = nil
	-- 			end
	-- 			if self.arrow_snake_button then
	-- 				self.arrow_snake_button.dead = true
	-- 				self.arrow_snake_button = nil
	-- 			end
	-- 			if self.main_menu_button then
	-- 				self.main_menu_button.dead = true
	-- 				self.main_menu_button = nil
	-- 			end
	-- 			system.save_state()
	-- 			if self:is(MainMenu) or self:is(BuyScreen) then
	-- 				input:set_mouse_visible(true)
	-- 			elseif self:is(Game) then
	-- 				input:set_mouse_visible(state.mouse_control or false)
	-- 			end
	-- 		end, "pause")
	-- 	end,
	-- })

	-- if not self:is(MainMenu) then
	-- 	self.restart_button = Button({
	-- 		group = self.ui,
	-- 		x = gw / 2,
	-- 		y = gh - 200,
	-- 		force_update = true,
	-- 		button_text = "restart level (r)",
	-- 		fg_color = "bg",
	-- 		bg_color = "orange",
	-- 		action = function(b)
	-- 			self.transitioning = true
	-- 			ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 			TransitionEffect({
	-- 				group = main.transitions,
	-- 				x = gw / 2,
	-- 				y = gh / 2,
	-- 				color = state.dark_transitions and bg[-2] or fg[0],
	-- 				transition_action = function()
	-- 					slow_amount = 1
	-- 					music_slow_amount = 1
	-- 					run_time = 0
	-- 					-- main_song_instance:stop()
	-- 					locked_state = nil
	-- 					system.save_run()
	-- 					main:add(Game("game"))
	-- 					main:go_to("game", main.current.level, #main.current.players)
	-- 				end,
	-- 				text = Text({
	-- 					{
	-- 						text = "[wavy, "
	-- 							.. tostring(state.dark_transitions and "fg" or "bg")
	-- 							.. "] level "
	-- 							.. (main.current.level == 5 and "[red]" or "")
	-- 							.. main.current.level
	-- 							.. "[red]/5",
	-- 						font = pixul_font,
	-- 						alignment = "center",
	-- 					},
	-- 				}, global_text_tags),
	-- 			})
	-- 		end,
	-- 	})
	-- end

	-- self.mouse_button = Button({
	-- 	group = self.ui,
	-- 	x = gw / 2 - 113,
	-- 	y = gh - 150,
	-- 	force_update = true,
	-- 	button_text = "mouse control: " .. tostring(state.mouse_control and "yes" or "no"),
	-- 	fg_color = "bg10",
	-- 	bg_color = "bg",
	-- 	action = function(b)
	-- 		ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 		state.mouse_control = not state.mouse_control
	-- 		b:set_text("mouse control: " .. tostring(state.mouse_control and "yes" or "no"))
	-- 	end,
	-- })

	local button_offset = -30
	local button_distance = 25
	self.dark_transition_button = Button({
		group = self.options_ui,
		x = gw / 2,
		y = gh / 2 + button_offset,
		force_update = true,
		button_text = "dark transitions: " .. tostring(state.dark_transitions and "yes" or "no"),
		fg_color = "bg",
		bg_color = "fg",
		action = function(b)
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			state.dark_transitions = not state.dark_transitions
			b:set_text("dark transitions: " .. tostring(state.dark_transitions and "yes" or "no"))
		end,
	})
	button_offset = button_offset + button_distance

	-- self.run_timer_button = Button({
	-- 	group = self.ui,
	-- 	x = gw / 2 + 138,
	-- 	y = gh - 150,
	-- 	force_update = true,
	-- 	button_text = "speedrun timer: " .. tostring(state.run_timer and "yes" or "no"),
	-- 	fg_color = "bg10",
	-- 	bg_color = "bg",
	-- 	action = function(b)
	-- 		ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 		state.run_timer = not state.run_timer
	-- 		b:set_text("speedrun timer: " .. tostring(state.run_timer and "yes" or "no"))
	-- 	end,
	-- })

	self.sfx_button = Button({
		group = self.options_ui,
		x = gw / 2,
		y = gh / 2 + button_offset,
		force_update = true,
		button_text = "sfx volume: " .. tostring((state.sfx_volume or 0.5) * 10),
		fg_color = "bg",
		bg_color = "fg",
		action = function(b)
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			b.spring:pull(0.2, 200, 10)
			b.selected = true
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			sfx.volume = sfx.volume + 0.1
			if sfx.volume > 1 then
				sfx.volume = 0
			end
			state.sfx_volume = sfx.volume
			b:set_text("sfx volume: " .. tostring((state.sfx_volume or 0.5) * 10))
		end,
		action_2 = function(b)
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			b.spring:pull(0.2, 200, 10)
			b.selected = true
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			sfx.volume = sfx.volume - 0.1
			if math.abs(sfx.volume) < 0.001 and sfx.volume > 0 then
				sfx.volume = 0
			end
			if sfx.volume < 0 then
				sfx.volume = 1
			end
			state.sfx_volume = sfx.volume
			b:set_text("sfx volume: " .. tostring((state.sfx_volume or 0.5) * 10))
		end,
	})
	button_offset = button_offset + button_distance

	self.music_button = Button({
		group = self.options_ui,
		x = gw / 2,
		y = gh / 2 + button_offset,
		force_update = true,
		button_text = "music volume: " .. tostring((state.music_volume or 0.5) * 10),
		fg_color = "bg",
		bg_color = "fg",
		action = function(b)
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			b.spring:pull(0.2, 200, 10)
			b.selected = true
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			music.volume = music.volume + 0.1
			if music.volume > 1 then
				music.volume = 0
			end
			state.music_volume = music.volume
			b:set_text("music volume: " .. tostring((state.music_volume or 0.5) * 10))
		end,
		action_2 = function(b)
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			b.spring:pull(0.2, 200, 10)
			b.selected = true
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			music.volume = music.volume - 0.1
			if math.abs(music.volume) < 0.001 and music.volume > 0 then
				music.volume = 0
			end
			if music.volume < 0 then
				music.volume = 1
			end
			state.music_volume = music.volume
			b:set_text("music volume: " .. tostring((state.music_volume or 0.5) * 10))
		end,
	})
	button_offset = button_offset + button_distance

	-- self.video_button_1 = Button({
	-- 	group = self.ui,
	-- 	x = gw / 2 - 136,
	-- 	y = gh - 125,
	-- 	force_update = true,
	-- 	button_text = "window size-",
	-- 	fg_color = "bg10",
	-- 	bg_color = "bg",
	-- 	action = function()
	-- 		if sx > 1 and sy > 1 then
	-- 			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 			sx, sy = sx - 0.5, sy - 0.5
	-- 			love.window.setMode(480 * sx, 270 * sy)
	-- 			state.sx, state.sy = sx, sy
	-- 			state.fullscreen = false
	-- 		end
	-- 	end,
	-- })
	--
	-- self.video_button_2 = Button({
	-- 	group = self.ui,
	-- 	x = gw / 2 - 50,
	-- 	y = gh - 125,
	-- 	force_update = true,
	-- 	button_text = "window size+",
	-- 	fg_color = "bg10",
	-- 	bg_color = "bg",
	-- 	action = function()
	-- 		ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 		sx, sy = sx + 0.5, sy + 0.5
	-- 		love.window.setMode(480 * sx, 270 * sy)
	-- 		state.sx, state.sy = sx, sy
	-- 		state.fullscreen = false
	-- 	end,
	-- })

	self.video_button_3 = Button({
		group = self.options_ui,
		x = gw / 2,
		y = gh / 2 + button_offset,
		force_update = true,
		button_text = "fullscreen",
		fg_color = "bg",
		bg_color = "fg",
		action = function()
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			local _, _, flags = love.window.getMode()
			local window_width, window_height = love.window.getDesktopDimensions(flags.display)
			sx, sy = window_width / 480, window_height / 270
			state.sx, state.sy = sx, sy
			ww, wh = window_width, window_height
			love.window.setMode(window_width, window_height)
		end,
	})
	button_offset = button_offset + button_distance

	-- self.video_button_4 = Button({
	-- 	group = self.ui,
	-- 	x = gw / 2 + 129,
	-- 	y = gh - 125,
	-- 	force_update = true,
	-- 	button_text = "reset video settings",
	-- 	fg_color = "bg10",
	-- 	bg_color = "bg",
	-- 	action = function()
	-- 		local _, _, flags = love.window.getMode()
	-- 		local window_width, window_height = love.window.getDesktopDimensions(flags.display)
	-- 		sx, sy = window_width / 480, window_height / 270
	-- 		ww, wh = window_width, window_height
	-- 		state.sx, state.sy = sx, sy
	-- 		state.fullscreen = false
	-- 		ww, wh = window_width, window_height
	-- 		love.window.setMode(window_width, window_height)
	-- 	end,
	-- })

	self.screen_shake_button = Button({
		group = self.options_ui,
		x = gw / 2,
		y = gh / 2 + button_offset,
		w = 110,
		force_update = true,
		button_text = "screen shake: " .. tostring(state.no_screen_shake and "no" or "yes"),
		fg_color = "bg",
		bg_color = "fg",
		action = function(b)
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			state.no_screen_shake = not state.no_screen_shake
			b:set_text("screen shake: " .. tostring(state.no_screen_shake and "no" or "yes"))
		end,
	})
	button_offset = button_offset + button_distance

	-- self.arrow_snake_button = Button({
	-- 	group = self.ui,
	-- 	x = gw / 2 + 36,
	-- 	y = gh - 75,
	-- 	w = 70,
	-- 	force_update = true,
	-- 	button_text = "[bg10]arrow: " .. tostring(state.arrow_snake and "yes" or "no"),
	-- 	fg_color = "bg10",
	-- 	bg_color = "bg",
	-- 	action = function(b)
	-- 		ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 		state.arrow_snake = not state.arrow_snake
	-- 		b:set_text("arrow: " .. tostring(state.arrow_snake and "yes" or "no"))
	-- 	end,
	-- })

	self.screen_movement_button = Button({
		group = self.options_ui,
		x = gw / 2,
		y = gh / 2 + button_offset,
		w = 135,
		force_update = true,
		button_text = "screen movement: " .. tostring(state.no_screen_movement and "no" or "yes"),
		fg_color = "bg",
		bg_color = "fg",
		action = function(b)
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			state.no_screen_movement = not state.no_screen_movement
			if state.no_screen_movement then
				camera.x, camera.y = gw / 2, gh / 2
				camera.r = 0
			end
			b:set_text("screen movement: " .. tostring(state.no_screen_movement and "no" or "yes"))
		end,
	})
	button_offset = button_offset + button_distance

	-- if not self:is(MainMenu) then
	-- 	self.main_menu_button = Button({
	-- 		group = self.ui,
	-- 		x = gw / 2,
	-- 		y = gh - 50,
	-- 		force_update = true,
	-- 		button_text = "main menu",
	-- 		fg_color = "bg",
	-- 		bg_color = "orange",
	-- 		action = function(b)
	-- 			self.transitioning = true
	-- 			ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 			TransitionEffect({
	-- 				group = main.transitions,
	-- 				x = gw / 2,
	-- 				y = gh / 2,
	-- 				color = state.dark_transitions and bg[-2] or fg[0],
	-- 				transition_action = function()
	-- 					main:add(MainMenu("main_menu"))
	-- 					main:go_to("main_menu")
	-- 				end,
	-- 				text = Text({
	-- 					{
	-- 						text = "[wavy, "
	-- 							.. tostring(state.dark_transitions and "fg" or "bg")
	-- 							.. "] SPAAAAAAAACE",
	-- 						font = pixul_font,
	-- 						alignment = "center",
	-- 					},
	-- 				}, global_text_tags),
	-- 			})
	-- 		end,
	-- 	})
	-- end

	-- self.quit_button = Button({
	-- 	group = self.ui,
	-- 	x = gw / 2,
	-- 	y = gh - 25,
	-- 	force_update = true,
	-- 	button_text = "quit",
	-- 	fg_color = "bg",
	-- 	bg_color = "red",
	-- 	action = function()
	-- 		system.save_state()
	-- 		love.event.quit()
	-- 	end,
	-- })
	-- end, "pause")
	self.dark_transition_button.selected = true
	input.selection.pressed = false

	self.dark_transition_button.button_up = self.screen_movement_button
	self.dark_transition_button.button_down = self.sfx_button

	self.sfx_button.button_up = self.dark_transition_button
	self.sfx_button.button_down = self.music_button

	self.music_button.button_up = self.sfx_button
	self.music_button.button_down = self.video_button_3

	self.video_button_3.button_up = self.music_button
	self.video_button_3.button_down = self.screen_shake_button

	self.screen_shake_button.button_up = self.video_button_3
	self.screen_shake_button.button_down = self.screen_movement_button

	self.screen_movement_button.button_up = self.screen_shake_button
	self.screen_movement_button.button_down = self.dark_transition_button
end

function close_options_old(self)
	main.current.in_options = false
	-- trigger:tween(0.25, _G, { slow_amount = 1 }, math.linear, function()
	-- slow_amount = 1
	-- self.paused = false
	if self.paused_t1 then
		self.paused_t1.dead = true
		self.paused_t1 = nil
	end
	if self.paused_t2 then
		self.paused_t2.dead = true
		self.paused_t2 = nil
	end
	if self.ng_t then
		self.ng_t.dead = true
		self.ng_t = nil
	end
	if self.resume_button then
		self.resume_button.dead = true
		self.resume_button = nil
	end
	if self.restart_button then
		self.restart_button.dead = true
		self.restart_button = nil
	end
	if self.mouse_button then
		self.mouse_button.dead = true
		self.mouse_button = nil
	end
	if self.dark_transition_button then
		self.dark_transition_button.dead = true
		self.dark_transition_button = nil
	end
	if self.run_timer_button then
		self.run_timer_button.dead = true
		self.run_timer_button = nil
	end
	if self.sfx_button then
		self.sfx_button.dead = true
		self.sfx_button = nil
	end
	if self.music_button then
		self.music_button.dead = true
		self.music_button = nil
	end
	if self.video_button_1 then
		self.video_button_1.dead = true
		self.video_button_1 = nil
	end
	if self.video_button_2 then
		self.video_button_2.dead = true
		self.video_button_2 = nil
	end
	if self.video_button_3 then
		self.video_button_3.dead = true
		self.video_button_3 = nil
	end
	if self.video_button_4 then
		self.video_button_4.dead = true
		self.video_button_4 = nil
	end
	if self.screen_shake_button then
		self.screen_shake_button.dead = true
		self.screen_shake_button = nil
	end
	if self.screen_movement_button then
		self.screen_movement_button.dead = true
		self.screen_movement_button = nil
	end
	if self.cooldown_snake_button then
		self.cooldown_snake_button.dead = true
		self.cooldown_snake_button = nil
	end
	if self.arrow_snake_button then
		self.arrow_snake_button.dead = true
		self.arrow_snake_button = nil
	end
	-- if self.quit_button then
	-- 	self.quit_button.dead = true
	-- 	self.quit_button = nil
	-- end
	if self.ng_plus_plus_button then
		self.ng_plus_plus_button.dead = true
		self.ng_plus_plus_button = nil
	end
	if self.ng_plus_minus_button then
		self.ng_plus_minus_button.dead = true
		self.ng_plus_minus_button = nil
	end
	if self.main_menu_button then
		self.main_menu_button.dead = true
		self.main_menu_button = nil
	end
	system.save_state()
	if self:is(MainMenu) then
		input:set_mouse_visible(true)
	elseif self:is(Game) then
		input:set_mouse_visible(state.mouse_control or false)
	end
	-- end, "pause")
end

function open_options(self)
	input:set_mouse_visible(true) -- WARN: what if no mouse?
	main.current.in_options = true

	local column1_x = gw / 3

	self.options_components = {

		--[[ dark_transition_button = ]]
		Button({
			group = self.options_ui,
			x = gw / 2,
			y = gh / 2,
			force_update = true,
			button_text = "dark transitions: " .. (state.dark_transitions and "yes" or "no"),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.dark_transitions = not state.dark_transitions
				b:set_text("dark transitions: " .. (state.dark_transitions and "yes" or "no"))
			end,
		}),

		--[[ sfx_button = ]]
		Button({
			group = self.options_ui,
			x = gw / 2,
			y = gh / 2,
			force_update = true,
			button_text = "sfx volume: " .. tostring((state.sfx_volume or 0.5) * 10),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				b.spring:pull(0.2, 200, 10)
				b.selected = true
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				sfx.volume = sfx.volume + 0.1
				if sfx.volume > 1 then
					sfx.volume = 0
				end
				state.sfx_volume = sfx.volume
				b:set_text("sfx volume: " .. tostring((state.sfx_volume or 0.5) * 10))
			end,
			action_2 = function(b)
				ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				b.spring:pull(0.2, 200, 10)
				b.selected = true
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				sfx.volume = sfx.volume - 0.1
				if math.abs(sfx.volume) < 0.001 and sfx.volume > 0 then
					sfx.volume = 0
				end
				if sfx.volume < 0 then
					sfx.volume = 1
				end
				state.sfx_volume = sfx.volume
				b:set_text("sfx volume: " .. tostring((state.sfx_volume or 0.5) * 10))
			end,
		}),

		--[[ music_button = ]]
		Button({
			group = self.options_ui,
			x = gw / 2,
			y = gh / 2,
			force_update = true,
			button_text = "music volume: " .. tostring((state.music_volume or 0.5) * 10),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				b.spring:pull(0.2, 200, 10)
				b.selected = true
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				music.volume = music.volume + 0.1
				if music.volume > 1 then
					music.volume = 0
				end
				state.music_volume = music.volume
				b:set_text("music volume: " .. tostring((state.music_volume or 0.5) * 10))
			end,
			action_2 = function(b)
				ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				b.spring:pull(0.2, 200, 10)
				b.selected = true
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				music.volume = music.volume - 0.1
				if math.abs(music.volume) < 0.001 and music.volume > 0 then
					music.volume = 0
				end
				if music.volume < 0 then
					music.volume = 1
				end
				state.music_volume = music.volume
				b:set_text("music volume: " .. tostring((state.music_volume or 0.5) * 10))
			end,
		}),

		--[[ video_button_3 = ]]
		Button({
			group = self.options_ui,
			x = gw / 2,
			y = gh / 2,
			force_update = true,
			button_text = "fullscreen",
			fg_color = "bg",
			bg_color = "fg",
			action = function()
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				local _, _, flags = love.window.getMode()
				local window_width, window_height = love.window.getDesktopDimensions(flags.display)
				sx, sy = window_width / 480, window_height / 270
				state.sx, state.sy = sx, sy
				ww, wh = window_width, window_height
				love.window.setMode(window_width, window_height)
			end,
		}),

		--[[ screen_shake_button = ]]
		Button({
			group = self.options_ui,
			x = gw / 2,
			y = gh / 2,
			w = 110,
			force_update = true,
			button_text = "screen shake: " .. tostring(state.no_screen_shake and "no" or "yes"),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.no_screen_shake = not state.no_screen_shake
				b:set_text("screen shake: " .. tostring(state.no_screen_shake and "no" or "yes"))
			end,
		}),

		--[[ screen_movement_button = ]]
		Button({
			group = self.options_ui,
			x = gw / 2,
			y = gh / 2,
			w = 135,
			force_update = true,
			button_text = "screen movement: " .. tostring(state.no_screen_movement and "no" or "yes"),
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.no_screen_movement = not state.no_screen_movement
				if state.no_screen_movement then
					camera.x, camera.y = gw / 2, gh / 2
					camera.r = 0
				end
				b:set_text("screen movement: " .. tostring(state.no_screen_movement and "no" or "yes"))
			end,
		}),
	}

	local offset = -30
	local distance = 25
	local index = 0
	for i, component in ipairs(self.options_components) do
		component.y = gh / 2 + offset + (distance * (i - 1))
	end

	-- TODO: set the button selections for controller_mode
end

function close_options(self)
	main.current.in_options = false
	for _, component in pairs(self.options_components) do
		if component then
			component.dead = true
		end
	end
	self.options_components = {}
end

function pause_game(self)
	trigger:tween(0.25, _G, { slow_amount = 0 }, math.linear, function()
		slow_amount = 0
		self.paused = true

		-- text = escape to go back to main menu (lose all progress)
		self.paused_ingame_text = Text2({
			group = self.ui,
			x = gw / 2,
			y = 20,
			force_update = true,
			sx = 0.6,
			sy = 0.6,
			lines = { { text = "Back to go to main-menu (lose all progress)", font = fat_font, alignment = "center" } },
		})

		self.continue_button = Button({
			group = self.ui,
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

		self.options_button = Button({
			group = self.ui,
			x = gw / 2 + 35,
			y = gh / 2 - 10,
			force_update = true,
			button_text = "options",
			fg_color = "bg",
			bg_color = "fg",
			action = function()
				open_options(self)
				self.options_button.selected = false
			end,
		})

		self.restart_text = Text2({
			group = self.ui,
			x = gw / 2,
			y = gh / 2 - 48,
			lines = {
				{
					text = "[wavy_mid, fg] restart level "
						.. (self.level ~= 5 and "[green]" or "[red]")
						.. self.level
						.. "[red]/5[wavy_mid, fg]?",
					font = fat_font,
					alignment = "center",
				},
			},
		})

		self.restart_with_1_player_button = Button({
			group = self.ui,
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
		self.restart_with_2_player_button = Button({
			group = self.ui,
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
		self.restart_with_3_player_button = Button({
			group = self.ui,
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
		self.restart_with_4_player_button = Button({
			group = self.ui,
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

		-- self.screen_shake_button = Button({
		-- 	group = self.ui,
		-- 	x = gw / 2 - 57,
		-- 	y = gh - 100,
		-- 	w = 110,
		-- 	force_update = true,
		-- 	button_text = "[bg10]screen shake: " .. tostring(state.no_screen_shake and "no" or "yes"),
		-- 	fg_color = "bg10",
		-- 	bg_color = "bg",
		-- 	action = function(b)
		-- 		ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		-- 		state.no_screen_shake = not state.no_screen_shake
		-- 		b:set_text("screen shake: " .. tostring(state.no_screen_shake and "no" or "yes"))
		-- 	end,
		-- })

		-- button = restart level as 1 player
		-- button = restart level as 2 player
		-- button = restart level as 3 player
		-- button = restart level as 4 player
		--
		self.continue_button.selected = true

		self.continue_button.button_up = self.restart_with_4_player_button
		self.continue_button.button_down = self.restart_with_1_player_button
		self.continue_button.button_left = self.options_button
		self.continue_button.button_right = self.options_button

		self.options_button.button_up = self.restart_with_4_player_button
		self.options_button.button_down = self.restart_with_1_player_button
		self.options_button.button_left = self.continue_button
		self.options_button.button_right = self.continue_button

		self.restart_with_1_player_button.button_up = self.continue_button
		self.restart_with_1_player_button.button_down = self.restart_with_2_player_button

		self.restart_with_2_player_button.button_up = self.restart_with_1_player_button
		self.restart_with_2_player_button.button_down = self.restart_with_3_player_button

		self.restart_with_3_player_button.button_up = self.restart_with_2_player_button
		self.restart_with_3_player_button.button_down = self.restart_with_4_player_button

		self.restart_with_4_player_button.button_up = self.restart_with_3_player_button
		self.restart_with_4_player_button.button_down = self.continue_button
	end, "pause")
end

function unpause_game(self)
	trigger:tween(0.25, _G, { slow_amount = 1 }, math.linear, function()
		slow_amount = 1
		self.paused = false
		if self.paused_ingame_text then
			self.paused_ingame_text.dead = true
			self.paused_ingame_text = nil
		end
		if self.restart_text then
			self.restart_text.dead = true
			self.restart_text = nil
		end
		if self.continue_button then
			self.continue_button.dead = true
			self.continue_button = nil
		end
		if self.options_button then
			self.options_button.dead = true
			self.options_button = nil
		end
		if self.restart_with_1_player_button then
			self.restart_with_1_player_button.dead = true
			self.restart_with_1_player_button = nil
		end
		if self.restart_with_2_player_button then
			self.restart_with_2_player_button.dead = true
			self.restart_with_2_player_button = nil
		end
		if self.restart_with_3_player_button then
			self.restart_with_3_player_button.dead = true
			self.restart_with_3_player_button = nil
		end
		if self.restart_with_4_player_button then
			self.restart_with_4_player_button.dead = true
			self.restart_with_4_player_button = nil
		end
	end)
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
	scene_transition(
		self,
		gw / 2,
		gh / 2,
		Game("game"),
		{ destination = "game", args = { level = main.current.level, num_players = num_players } },
		{
			text = "level " .. (main.current.level == 5 and "[red]" or "") .. main.current.level .. "[red]/5",
			font = pixul_font,
			alignment = "center",
		}
	)
end

function scene_transition(self, x_pos, y_pos, addition, go_to, text_args)
	TransitionEffect({
		group = main.transitions,
		x = x_pos, --gw / 2,
		y = y_pos, -- gh / 2,
		color = state.dark_transitions and bg[-2] or fg[0],
		transition_action = function()
			self.transitioning = true
			-- slow_amount = 1
			system.save_state()
			main:add(addition) --add(Game("game"))
			main:go_to(go_to.destination, go_to.args) --go_to("game", 1, num_players)
		end,
		text = Text({
			{
				text = "[wavy, " .. tostring(state.dark_transitions and "fg" or "bg") .. "]" .. text_args.text, --"Feeding whales...",
				font = text_args.font, --pixul_font,
				alignment = text_args.alignment, --"center",
			},
		}, global_text_tags),
	})
end

function play_music(volume)
	if main_song_instance == nil or main_song_instance:isStopped() then
		main_song_instance = _G[random:table({ "song1", "song2", "song3", "song4", "song5" })]:play({ volume = volume })
	end
end
