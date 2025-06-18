require("engine")
require("mainmenu")
require("levelselect")
require("game")
-- require("shared")
require("renderer")
-- require("arena")
-- require("objects")
-- require("player")
-- require("media")

function init()
	renderer_init()

	input:bind("move_left", { "a", "left", "dpleft", "m1" })
	input:bind("move_right", { "d", "right", "dpright", "m2" })
	input:bind("move_forward", { "w", "up", "dpup", "m3" })
	input:bind("enter", { "space", "return", "fleft", "fdown", "fright" })

	local s = { tags = { sfx } }
	-- load sounds:
	-- explosion1 = Sound('Explosion Grenade_04.ogg', s)
	buttonHover = Sound("buttonHover.ogg", s)
	buttonPop = Sound("buttonPop.ogg", s)

	ui_switch1 = Sound("ui_switch1.ogg", s)
	ui_switch2 = Sound("ui_switch2.ogg", s)
	ui_transition2 = Sound("ui_transition2.ogg", s)

	-- load songs
	song1 = Sound("neon-rush-retro-synthwave-uplifting-daily-vlog-fast-cuts-sv201-360195.mp3", { tags = { music } })
	song2 = Sound("8-bit-gaming-background-music-358443.mp3", { tags = { music } })
	song3 = Sound("edm003-retro-edm-_-gamepixel-racer-358045.mp3", { tags = { music } })
	song4 = Sound("pixel-fantasia-355123.mp3", { tags = { music } })
	song5 = Sound("pixel-fight-8-bit-arcade-music-background-music-for-video-208775.mp3", { tags = { music } })

	-- load images:
	-- image1 = Image('name')

	-- set logic init
	main_song_instance = _G[random:table({ "song1", "song2", "song3", "song4", "song5" })]:play({ volume = 0.3 })
	slow_amount = 1
	music_slow_amount = 1
	run_time = 0

	main = Main()
	main:add(MainMenu("mainmenu"))
	-- main:add(LevelSelect("level_select")) -- TODO:
	main:go_to("mainmenu")
end

function update(dt)
	main:update(dt)

	-- update window max sizing
	if input.k.pressed then
		if sx > 1 and sy > 1 then
			sx, sy = sx - 0.5, sy - 0.5
			love.window.setMode(480 * sx, 270 * sy)
			state.sx, state.sy = sx, sy
			state.fullscreen = false
		end
	end

	if input.l.pressed then
		sx, sy = sx + 0.5, sy + 0.5
		love.window.setMode(480 * sx, 270 * sy)
		state.sx, state.sy = sx, sy
		state.fullscreen = false
	end
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

function open_options(self)
	input:set_mouse_visible(true)
	trigger:tween(0.25, _G, { slow_amount = 0 }, math.linear, function()
		slow_amount = 0
		self.paused = true

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

		self.resume_button = Button({
			group = self.ui,
			x = gw / 2,
			y = gh - 225,
			force_update = true,
			button_text = self:is(MainMenu) and "main menu (esc)" or "resume (esc)",
			fg_color = "bg",
			bg_color = "green",
			action = function(b)
				trigger:tween(0.25, _G, { slow_amount = 1 }, math.linear, function()
					slow_amount = 1
					self.paused = false
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
					if self.quit_button then
						self.quit_button.dead = true
						self.quit_button = nil
					end
					if self.screen_shake_button then
						self.screen_shake_button.dead = true
						self.screen_shake_button = nil
					end
					if self.screen_movement_button then
						self.screen_movement_button.dead = true
						self.screen_movement_button = nil
					end
					if self.main_menu_button then
						self.main_menu_button.dead = true
						self.main_menu_button = nil
					end
					system.save_state()
					if self:is(MainMenu) or self:is(BuyScreen) then
						input:set_mouse_visible(true)
					elseif self:is(Game) then
						input:set_mouse_visible(state.mouse_control or false)
					end
				end, "pause")
			end,
		})

		if not self:is(MainMenu) then
			self.restart_button = Button({
				group = self.ui,
				x = gw / 2,
				y = gh - 200,
				force_update = true,
				button_text = "restart level (r)",
				fg_color = "bg",
				bg_color = "orange",
				action = function(b)
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
							run_time = 0
							main_song_instance:stop()
							main:add(Game("game"))
							locked_state = nil
							system.save_run()
							main:go_to(Game("game"), 1)
						end,
						text = Text({
							{
								text = "[wavy, "
									.. tostring(state.dark_transitions and "fg" or "bg")
									.. "]restarting...",
								font = pixul_font,
								alignment = "center",
							},
						}, global_text_tags),
					})
				end,
			})
		end

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

		self.dark_transition_button = Button({
			group = self.ui,
			x = gw / 2 + 13,
			y = gh - 150,
			force_update = true,
			button_text = "dark transitions: " .. tostring(state.dark_transitions and "yes" or "no"),
			fg_color = "bg10",
			bg_color = "bg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.dark_transitions = not state.dark_transitions
				b:set_text("dark transitions: " .. tostring(state.dark_transitions and "yes" or "no"))
			end,
		})

		self.run_timer_button = Button({
			group = self.ui,
			x = gw / 2 + 138,
			y = gh - 150,
			force_update = true,
			button_text = "speedrun timer: " .. tostring(state.run_timer and "yes" or "no"),
			fg_color = "bg10",
			bg_color = "bg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.run_timer = not state.run_timer
				b:set_text("speedrun timer: " .. tostring(state.run_timer and "yes" or "no"))
			end,
		})

		self.sfx_button = Button({
			group = self.ui,
			x = gw / 2 - 46,
			y = gh - 175,
			force_update = true,
			button_text = "sfx volume: " .. tostring((state.sfx_volume or 0.5) * 10),
			fg_color = "bg10",
			bg_color = "bg",
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

		self.music_button = Button({
			group = self.ui,
			x = gw / 2 + 48,
			y = gh - 175,
			force_update = true,
			button_text = "music volume: " .. tostring((state.music_volume or 0.5) * 10),
			fg_color = "bg10",
			bg_color = "bg",
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

		self.video_button_1 = Button({
			group = self.ui,
			x = gw / 2 - 136,
			y = gh - 125,
			force_update = true,
			button_text = "window size-",
			fg_color = "bg10",
			bg_color = "bg",
			action = function()
				if sx > 1 and sy > 1 then
					ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
					sx, sy = sx - 0.5, sy - 0.5
					love.window.setMode(480 * sx, 270 * sy)
					state.sx, state.sy = sx, sy
					state.fullscreen = false
				end
			end,
		})

		self.video_button_2 = Button({
			group = self.ui,
			x = gw / 2 - 50,
			y = gh - 125,
			force_update = true,
			button_text = "window size+",
			fg_color = "bg10",
			bg_color = "bg",
			action = function()
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				sx, sy = sx + 0.5, sy + 0.5
				love.window.setMode(480 * sx, 270 * sy)
				state.sx, state.sy = sx, sy
				state.fullscreen = false
			end,
		})

		self.video_button_3 = Button({
			group = self.ui,
			x = gw / 2 + 29,
			y = gh - 125,
			force_update = true,
			button_text = "fullscreen",
			fg_color = "bg10",
			bg_color = "bg",
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

		self.video_button_4 = Button({
			group = self.ui,
			x = gw / 2 + 129,
			y = gh - 125,
			force_update = true,
			button_text = "reset video settings",
			fg_color = "bg10",
			bg_color = "bg",
			action = function()
				local _, _, flags = love.window.getMode()
				local window_width, window_height = love.window.getDesktopDimensions(flags.display)
				sx, sy = window_width / 480, window_height / 270
				ww, wh = window_width, window_height
				state.sx, state.sy = sx, sy
				state.fullscreen = false
				ww, wh = window_width, window_height
				love.window.setMode(window_width, window_height)
			end,
		})

		self.screen_shake_button = Button({
			group = self.ui,
			x = gw / 2 - 57,
			y = gh - 100,
			w = 110,
			force_update = true,
			button_text = "[bg10]screen shake: " .. tostring(state.no_screen_shake and "no" or "yes"),
			fg_color = "bg10",
			bg_color = "bg",
			action = function(b)
				ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				state.no_screen_shake = not state.no_screen_shake
				b:set_text("screen shake: " .. tostring(state.no_screen_shake and "no" or "yes"))
			end,
		})

		self.screen_movement_button = Button({
			group = self.ui,
			x = gw / 2 - 69,
			y = gh - 75,
			w = 135,
			force_update = true,
			button_text = "[bg10]screen movement: " .. tostring(state.no_screen_movement and "no" or "yes"),
			fg_color = "bg10",
			bg_color = "bg",
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

		if not self:is(MainMenu) then
			self.main_menu_button = Button({
				group = self.ui,
				x = gw / 2,
				y = gh - 50,
				force_update = true,
				button_text = "main menu",
				fg_color = "bg",
				bg_color = "orange",
				action = function(b)
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
							main:add(MainMenu("main_menu"))
							main:go_to("main_menu")
						end,
						text = Text({
							{
								text = "[wavy, " .. tostring(state.dark_transitions and "fg" or "bg") .. "]..",
								font = pixul_font,
								alignment = "center",
							},
						}, global_text_tags),
					})
				end,
			})
		end

		self.quit_button = Button({
			group = self.ui,
			x = gw / 2,
			y = gh - 25,
			force_update = true,
			button_text = "quit",
			fg_color = "bg",
			bg_color = "red",
			action = function()
				system.save_state()
				love.event.quit()
			end,
		})
	end, "pause")
end

function close_options(self)
	trigger:tween(0.25, _G, { slow_amount = 1 }, math.linear, function()
		slow_amount = 1
		self.paused = false
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
		-- if self.mouse_button then
		-- 	self.mouse_button.dead = true
		-- 	self.mouse_button = nil
		-- end
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
		if self.quit_button then
			self.quit_button.dead = true
			self.quit_button = nil
		end
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
	end, "pause")
end
