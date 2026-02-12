Intro = Object:extend()
Intro:implement(State)
Intro:implement(GameObject)
function Intro:init(name)
	self:init_state(name)
	self:init_game_object()
end

function Intro:on_enter(from, args)
	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0

	self.main = Group()

	self.main_slow_amount = 1
	slow_amount = 1

	-- TODO: clean up (note the tweens that the logo relies on: self.text.y)
	self.text = Text2({
		group = self.main,
		x = gw / 2,
		y = gh,
		lines = {
			-- {
			-- 	text = "[wavy_rainbow]Electroacoustic",
			-- 	font = fat_title_font,
			-- 	alignment = "center",
			-- },
			-- {
			-- 	text = "[wavy_title, blue]Invaders",
			-- 	font = mystery_font,
			-- 	alignment = "center",
			-- },
		},
	})

	-- play the intro
	self.opacity = 1
	self.intro_song_volume = 1
	self.intro_song_volume_uid = random:uid()

	intro_song:play({ volume = 0.2 })

	trigger:tween(4.5, self.text, { y = gh / 2 }, math.cubic_in_out)     -- positioning title text to center at the start
	trigger:after(2.9, function()
		trigger:tween(0.2, self, { opacity = 0 }, math.quad_in_out, function() -- lowering foreground opactiy
			trigger:after(2, function()
				trigger:tween(2, self.text, { y = 0 }, math.cubic_in_out) -- moving title text up at the end
			end)
		end)
		if not self.transitioning then
			trigger:tween(4, self, { intro_song_volume = 0 }, math.quad_out, function() end, self.intro_song_volume_uid) -- fading the audio
		end
	end)

	trigger:after(5.8, function()
		self.intro_complete = true
	end)
end

function Intro:on_exit()
	self.main:destroy()
	self.main = nil
end

function Intro:update(dt)
	run_time = run_time + dt
	intro.volume = self.intro_song_volume

	if (self.intro_complete or input.escape.pressed) and not self.transitioning then
		trigger:tween(0.5, self, { intro_song_volume = 0 }, math.quad_out, function()
			intro_song:stop()
		end, self.intro_song_volume_uid) -- fading/stopping the audio

		scene_transition(self, {
			x = gw / 2,
			y = gh / 2,
			type = "fade",
			target = {
				scene = MainMenu,
				name = "main_menu",
				args = { clear_music = true, fast_load = true },
			},
		})
		return
	end

	self.main:update(dt * slow_amount * self.main_slow_amount)
end

function Intro:draw()
	graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, Color(0, 0, 0, 1)) -- black background
	self.main:draw()
	logo:draw(gw / 2, self.text.y, 0, 3, 3, 0, 0, Color(1, 1, 1, 1))
	-- function Image:draw(x, y, r, sx, sy, ox, oy, color)
	graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, Color(0, 0, 0, self.opacity)) -- fade foreground
end
