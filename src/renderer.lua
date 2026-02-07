require("buttons")
require("sliders")

-- Shared functions and classes for projects using JUGGLRX's visual style.
function renderer_init()
	local colors = {
		white = ColorRamp(Color(1, 1, 1, 1), 0.025),
		black = ColorRamp(Color(0, 0, 0, 1), 0.025),
		bg = ColorRamp(Color("#303030"), 0.025),
		bg_alt = ColorRamp(Color("#101010"), 0.025),
		fg = ColorRamp(Color("#dadada"), 0.025),
		fg_alt = ColorRamp(Color("#b0a89f"), 0.025),
		yellow = ColorRamp(Color("#facf00"), 0.025),
		orange = ColorRamp(Color("#f07021"), 0.025),
		blue = ColorRamp(Color("#019bd6"), 0.025),
		green = ColorRamp(Color("#8bbf40"), 0.025),
		red = ColorRamp(Color("#e91d39"), 0.025),
		purple = ColorRamp(Color("#8e559e"), 0.025),
		blue2 = ColorRamp(Color("#4778ba"), 0.025),
		yellow2 = ColorRamp(Color("#f59f10"), 0.025),

		-- pallete: https://colorkit.co/palette/802d2f-ff595e-ff924c-ffca3a-c5ca30-8ac926-52a675-1982c4-4267ac-6a4c93/
		brown1 = ColorRamp(Color("#802d2f"), 0.025),
		red1 = ColorRamp(Color("#ff595e"), 0.025),
		orange1 = ColorRamp(Color("#ff924c"), 0.025),
		yellow1 = ColorRamp(Color("#ffca3a"), 0.025),
		mint1 = ColorRamp(Color("#c5ca30"), 0.025),
		green1 = ColorRamp(Color("#8ac926"), 0.025),
		grass1 = ColorRamp(Color("#52a675"), 0.025),
		blue1 = ColorRamp(Color("#1982c4"), 0.025),
		purple1 = ColorRamp(Color("#4267ac"), 0.025),
		gray1 = ColorRamp(Color("#6a4c93"), 0.025),

		p_blue1 = ColorRamp(Color("#4dd8ff"), 0.025),
	}
	for name, color in pairs(colors) do
		_G[name] = color
		_G[name .. "_transparent"] = Color(color[0].r, color[0].g, color[0].b, 0.5)
		_G[name .. "_transparent_weak"] = Color(color[0].r, color[0].g, color[0].b, 0.25)
	end
	modal_transparent_lite = Color(0.1, 0.1, 0.1, 0.3)
	modal_transparent = Color(0.1, 0.1, 0.1, 0.6)
	modal_transparent_2 = Color(0.1, 0.1, 0.1, 0.9)

	bg_off = Color(46, 46, 46)
	bg_gradient = GradientImage("vertical", Color(128, 128, 128, 0), Color(0, 0, 0, 0.9))

	graphics.set_background_color(bg[0])
	graphics.set_color(fg[0])
	slow_amount = 1
	music_slow_amount = 1

	sfx = SoundTag()
	sfx.volume = state.sfx_volume or 0.5
	music = SoundTag()
	music.volume = state.music_volume or 0.5

	if state.volume_muted then
		sfx.volume = 0
	end
	if state.music_muted then
		music.volume = 0
	end

	fat_font = Font("FatPixelFont", 8 * global_game_scale)
	fat_title_font = Font("FatPixelFont", 12 * global_game_scale)
	pixul_font = Font("PixulBrush", 8 * global_game_scale)
	small_pixul_font = Font("PixulBrush", 4 * global_game_scale)
	mystery_font = Font("BoldPixels", 8 * global_game_scale)
	background_canvas = Canvas(gw, gh)
	main_canvas = Canvas(gw, gh, { stencil = true })
	shadow_canvas = Canvas(gw, gh)
	shadow_shader = Shader(nil, "shadow.frag")
	star_canvas = Canvas(gw, gh, { stencil = true })
	star_group = Group()
	star_positions = {}
	for i = -30, gh + 30, 15 do
		table.insert(star_positions, { x = -40, y = i })
	end
	for i = -30, gw, 15 do
		table.insert(star_positions, { x = i, y = gh + 40 })
	end

	death_flash_alpha = 0
end

function renderer_draw(draw_action, shadow_draw_action)
	star_canvas:draw_to(function()
		star_group:draw()
	end)

	background_canvas:draw_to(function()
		camera:attach()
		if main.current:is(Game) then
			if main.current.creator_mode then
				for i = 1, gw / grid_size do
					for j = 1, gh / grid_size do
						local row = j * grid_size
						local column = i * grid_size

						local gray_val = 0.3
						local color = Color(gray_val, gray_val, gray_val, 1)
						local line_width = 3
						graphics.line(column, 0, column, gh, color, line_width)
						graphics.line(0, row, gw, row, color, line_width)
					end
				end
			end
		elseif main.current:is(MainMenu) then
			if main.current.current_menu == menu.Stim_Screen then
				-- TODO: rainbow background or somethigng
			end
		end

		bg_gradient:draw(gw / 2, gh / 2, global_game_width, global_game_height)
		bg_gradient:draw(gw / 2, gh * 1.5, global_game_width, global_game_height)
		camera:detach()
	end)

	main_canvas:draw_to(function()
		draw_action()
		if state.screen_flashes then
			if death_flash_alpha > 0 then
				graphics.rectangle(gw / 2, gh / 2, gw, gh, nil, nil, Color(0.8, 0, 0, death_flash_alpha))
			end
		end
	end)

	shadow_canvas:draw_to(function()
		-- shadow_draw_action()
		graphics.set_color(white[0])
		shadow_shader:set()
		main_canvas:draw2(0, 0, 0, 1, 1)
		shadow_shader:unset()
	end)

	local x, y = 0, 0
	background_canvas:draw(x, y, 0, sx, sy)

	local shadow_offset = 2.5
	shadow_canvas:draw(x + shadow_offset * sx, y + shadow_offset * sy, 0, sx, sy)
	main_canvas:draw(x, y, 0, sx, sy)
end

ColorRamp = Object:extend()
function ColorRamp:init(color, step)
	self.color = color
	self.step = step
	for i = -10, 10 do
		if i < 0 then
			self[i] = self.color:clone():lighten(i * self.step)
		elseif i > 0 then
			self[i] = self.color:clone():lighten(i * self.step)
		else
			self[i] = self.color:clone()
		end
	end
end

local invisible = Color(1, 1, 1, 0)
global_text_tags = {
	p_blue1 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(p_blue1[0])
		end,
	}),
	red = TextTag({
		draw = function(c, i, text)
			graphics.set_color(red[0])
		end,
	}),
	orange = TextTag({
		draw = function(c, i, text)
			graphics.set_color(orange[0])
		end,
	}),
	yellow = TextTag({
		draw = function(c, i, text)
			graphics.set_color(yellow[0])
		end,
	}),
	yellow2 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(yellow2[0])
		end,
	}),
	green = TextTag({
		draw = function(c, i, text)
			graphics.set_color(green[0])
		end,
	}),
	purple = TextTag({
		draw = function(c, i, text)
			graphics.set_color(purple[0])
		end,
	}),
	blue = TextTag({
		draw = function(c, i, text)
			graphics.set_color(blue[0])
		end,
	}),
	blue2 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(blue2[0])
		end,
	}),
	bg = TextTag({
		draw = function(c, i, text)
			graphics.set_color(bg[0])
		end,
	}),
	bg3 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(bg[3])
		end,
	}),
	bg10 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(bg[10])
		end,
	}),
	bgm2 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(bg[-2])
		end,
	}),
	light_bg = TextTag({
		draw = function(c, i, text)
			graphics.set_color(bg[5])
		end,
	}),
	fg = TextTag({
		draw = function(c, i, text)
			graphics.set_color(fg[0])
		end,
	}),
	fgm1 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(fg[-1])
		end,
	}),
	fgm2 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(fg[-2])
		end,
	}),
	fgm3 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(fg[-3])
		end,
	}),
	fgm4 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(fg[-4])
		end,
	}),
	fgm5 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(fg[-5])
		end,
	}),
	fgm6 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(fg[-6])
		end,
	}),
	fgm7 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(fg[-7])
		end,
	}),
	fgm8 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(fg[-8])
		end,
	}),
	fgm9 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(fg[-9])
		end,
	}),
	fgm10 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(fg[-10])
		end,
	}),
	greenm5 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(green[-5])
		end,
	}),
	green5 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(green[5])
		end,
	}),
	blue5 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(blue[5])
		end,
	}),
	bluem5 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(blue[-5])
		end,
	}),
	blue25 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(blue2[5])
		end,
	}),
	blue2m5 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(blue2[-5])
		end,
	}),
	yellow25 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(yellow2[5])
		end,
	}),
	yellow2m5 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(yellow2[-5])
		end,
	}),
	redm5 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(red[-5])
		end,
	}),
	orangem5 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(orange[-5])
		end,
	}),
	purplem5 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(purple[-5])
		end,
	}),
	yellowm5 = TextTag({
		draw = function(c, i, text)
			graphics.set_color(yellow[-5])
		end,
	}),
	wavy = TextTag({
		update = function(c, dt, i, text)
			c.oy = 2 * math.sin(4 * time + i)
		end,
	}),
	wavy_mid = TextTag({
		update = function(c, dt, i, text)
			c.oy = 0.75 * math.sin(3 * time + i)
		end,
	}),
	wavy_mid2 = TextTag({
		update = function(c, dt, i, text)
			c.oy = 0.5 * math.sin(3 * time + i)
		end,
	}),
	wavy_lower = TextTag({
		update = function(c, dt, i, text)
			c.oy = 0.25 * math.sin(2 * time + i)
		end,
	}),
	wavy_smooth = TextTag({
		update = function(c, dt, i, text)
			c.oy = math.sin(time * 4 + i * 0.4) * 8.5
			-- c.ox = math.cos(time * 2 + i * 0.4) * 0.5
		end,
	}),
	wavy_title = TextTag({
		update = function(c, dt, i, text)
			c.oy = math.sin(time * 4 + i * 0.9) * 10
		end,
	}),
	wavy_rainbow = TextTag({
		init = function(c, i, text)
			c.color = white[0]:clone()
		end,

		update = function(c, dt, i, text)
			c.oy = math.sin(time * 4 + i * 0.9) * 4

			-- Rainbow wave
			local t = time * 1.5 + i * 0.3
			c.color.r = 0.5 + 0.5 * math.cos(t)
			c.color.g = 0.5 + 0.5 * math.cos(t + 2 * math.pi / 3)
			c.color.b = 0.5 + 0.5 * math.cos(t + 4 * math.pi / 3)
		end,

		draw = function(c, i, text)
			graphics.set_color(c.color)
		end,
	}),

	steam_link = TextTag({
		init = function(c, i, text)
			c.color = blue[0]
		end,

		draw = function(c, i, text)
			graphics.set_color(c.color)
			graphics.line(c.x - c.w / 2, c.y + c.h / 2 + c.h / 10, c.x + c.w / 2, c.y + c.h / 2 + c.h / 10)
		end,
	}),

	cbyc = TextTag({
		init = function(c, i, text)
			c.color = invisible
			text.t:after((i - 1) * 0.15, function()
				c.color = red[0]
				camera:shake(3, 0.075)
				-- buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
			end)
		end,
		draw = function(c, i, text)
			graphics.set_color(c.color)
		end,
	}),

	cbyc_fast = TextTag({
		init = function(c, i, text)
			c.color = invisible
			text.t:after((i - 1) * 0.02, function()
				c.color = red[0]
				camera:shake(3, 0.075)
				-- buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
			end)
		end,
		draw = function(c, i, text)
			graphics.set_color(c.color)
		end,
	}),

	cbyc2 = TextTag({
		init = function(c, i, text)
			c.color = invisible
			text.t:after((i - 1) * 0.15, function()
				c.color = yellow[0]
				camera:shake(3, 0.075)
				-- buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
			end)
		end,
		draw = function(c, i, text)
			graphics.set_color(c.color)
		end,
	}),

	cbyc3 = TextTag({
		init = function(c, i, text)
			c.color = invisible
			text.t:after((i - 1) * 0.025, function()
				c.color = bg[10]
			end)
		end,
		draw = function(c, i, text)
			graphics.set_color(c.color)
		end,
	}),

	-- tutorial = TextTag()

	nudge_down = TextTag({
		init = function(c, i, text)
			c.oy = -4
			text.t:tween(0.1, c, { oy = 0 }, math.linear)
		end,
	}),
}

--
--
--
TransitionEffect = Object:extend()
TransitionEffect:implement(GameObject)
function TransitionEffect:init(args)
	self:init_game_object(args)
	self.rs = 0
	self.text_sx, self.text_sy = 0, 0
	local speed = self.fast and 2.5 or 1.5
	self.t:after(0.25 / speed, function()
		self.t:after(0.1 / speed, function()
			self.t:tween(0.1 / speed, self, { text_sx = 1, text_sy = 1 }, math.cubic_in_out)
		end)
		self.t:tween(0.6 / speed, self, { rs = 1.2 * gw }, math.linear, function()
			if self.transition_action then
				self:transition_action(unpack(self.transition_action_args or {}))
			end
			self.t:after(0.3 / speed, function()
				self.x, self.y = gw / 2, gh / 2
				self.t:after(0.6 / speed, function()
					self.t:tween(0.05 / speed, self, { text_sx = 0, text_sy = 0 }, math.cubic_in_out)
				end)
				if not args.dont_tween_out then
					self.t:tween(0.6 / speed, self, { rs = 0 }, math.linear, function()
						self.text = nil
						self.dead = true
					end)
				else
					self.t:after(0.6 / speed, function()
						self.text = nil
						self.dead = true
					end)
				end
			end)
		end)
	end)
end

function TransitionEffect:update(dt)
	self:update_game_object(dt)
	if self.text then
		self.text:update(dt)
	end
end

function TransitionEffect:draw()
	graphics.push(self.x, self.y, 0, self.sx, self.sy)
	graphics.circle(self.x, self.y, self.rs, self.color)
	graphics.pop()
	if self.text then
		self.text:draw(gw / 2, gh / 2, 0, self.text_sx, self.text_sy)
	end
end

--
--
--
--
HitCircle = Object:extend()
HitCircle:implement(GameObject)
function HitCircle:init(args)
	self:init_game_object(args)
	self.rs = self.rs or 8
	self.duration = self.duration or 0.05
	self.color = self.color or fg[0]
	self.t:after(self.duration, function()
		self.dead = true
	end, "die")
	return self
end

function HitCircle:update(dt)
	self:update_game_object(dt)
end

function HitCircle:draw()
	graphics.circle(self.x, self.y, self.rs, self.color)
end

function HitCircle:scale_down(duration)
	duration = duration or 0.2
	self.t:cancel("die")
	self.t:tween(self.duration, self, { rs = 0 }, math.cubic_in_out, function()
		self.dead = true
	end)
	return self
end

function HitCircle:change_color(delay_multiplier, target_color)
	delay_multiplier = delay_multiplier or 0.5
	self.t:after(delay_multiplier * self.duration, function()
		self.color = target_color
	end)
	return self
end

--
--
--
--
HitParticle = Object:extend()
HitParticle:implement(GameObject)
function HitParticle:init(args)
	self:init_game_object(args)
	self.v = self.v or random:float(250, 350)
	self.r = args.r or random:float(0, 2 * math.pi)
	self.vx = self.v * math.cos(self.r)
	self.vy = self.v * math.sin(self.r)

	self.duration = self.duration or random:float(2.4, 5.8)
	self.w = self.w or random:float(3.5, 7)
	self.h = self.h or self.w / 2
	self.color = self.color or fg[0]
	self.curve = self.curve or 15
	self.gravity = self.gravity or 300
	self.t:tween(self.duration, self, { w = 2, h = 2, v = 0 }, math.cubic_in_out, function()
		self.dead = true
	end)
end

function HitParticle:update(dt)
	self:update_game_object(dt)
	self.vy = self.vy + self.gravity * dt

	self.x = self.x + self.vx * dt
	self.y = self.y + self.vy * dt

	self.r = math.atan2(self.vy, self.vx)
end

function HitParticle:draw()
	graphics.push(self.x, self.y, self.r)
	if self.parent and not self.parent.dead then
		graphics.rectangle(
			self.x, --
			self.y,
			self.w,
			self.h,
			self.curve,
			self.curve,
			self.parent.hfx.hit.f and fg[0] or self.color
		)
	else
		graphics.rectangle(self.x, self.y, self.w, self.h, self.curve, self.curve, self.color)
	end
	graphics.pop()
end

function HitParticle:change_color(delay_multiplier, target_color)
	delay_multiplier = delay_multiplier or 0.5
	self.t:after(delay_multiplier * self.duration, function()
		self.color = target_color
	end)
	return self
end

--
--
--
Animation = Object:extend()
Animation:implement(GameObject)
function Animation:init(args)
	self:init_game_object(args)

	-- self.type = args.type
	self.sprite_sheet = args.sheet.sprite_sheets[self.type]

	self.frame_width = args.sheet.frame_width
	self.frame_height = args.sheet.frame_height
	self.animation_speed = args.sheet.animation_speed or 0.1

	self.center_x = args.sheet.hitbox_center_x or 0
	self.center_y = args.sheet.hitbox_center_y or 0

	self.frame_time = 0
	self.frame_counter = 1

	local image_w, image_h = self.sprite_sheet.w, self.sprite_sheet.h
	self.frames = {}

	for y = 0, image_h - self.frame_height, self.frame_height do
		for x = 0, image_w - self.frame_width, self.frame_width do
			local quad = love.graphics.newQuad(x, y, self.frame_width, self.frame_height, image_w, image_h)
			table.insert(self.frames, quad)
		end
	end

	self.num_frames = #self.frames
end

function Animation:update(dt)
	self.frame_time = self.frame_time + dt
	if self.frame_time > self.animation_speed then
		self.frame_time = self.frame_time % self.animation_speed
		self.frame_counter = self.frame_counter + 1
		if self.frame_counter > self.num_frames then
			if self.stop_on_finish then
				self.frame_counter = self.num_frames
			else
				self.frame_counter = 1
			end
		end
	end
end

function Animation:draw(x, y, r, sx, sy, ox, oy, color)
	local frame = self.frames[self.frame_counter]
	local _r, g, b, a
	if color then
		_r, g, b, a = love.graphics.getColor()
		graphics.set_color(color)
	end
	love.graphics.draw(
		self.sprite_sheet.image,
		frame,
		x - self.center_x * sx,
		y - self.center_y * sy,
		r or 0,
		sx or 1,
		sy or sx or 1,
		self.frame_width / 2 + (ox or 0),
		self.frame_height / 2 + (oy or 0)
	)
	if color then
		love.graphics.setColor(_r, g, b, a)
	end
end

Text2 = Object:extend()
Text2:implement(GameObject)

function Text2:init(args)
	self:init_game_object(args)
	self.text = Text(args.lines, global_text_tags)
	self.w, self.h = args.w or self.text.w, args.h or self.text.h

	if self.scroll_box then
		self.max_scroll = math.max(0, self.text.h - self.h + self.text.line_height / 2)
		self.scroll_offset = 0
		self.scroll_velocity = 0
		self.scroll_speed = args.scroll_speed or 300
		self.scroll_damping = args.scroll_damping or 8 -- how quickly it slows down
		self.scroll_ease = args.scroll_ease or math.cubic_out
	end
end

function Text2:update(dt)
	self:update_game_object(dt)
	self.text:update(dt)

	if self.scroll_box then
		local scroll_input = 0

		if input.wheel_up.down or input.wheel_up.pressed then
			scroll_input = scroll_input - 1
		elseif input.wheel_down.down or input.wheel_down.pressed then
			scroll_input = scroll_input + 1
		end

		if scroll_input ~= 0 then
			self.scroll_velocity = self.scroll_velocity + scroll_input * self.scroll_speed
		end

		self.scroll_offset = self.scroll_offset + self.scroll_velocity * dt
		self.scroll_velocity = self.scroll_velocity * math.exp(-self.scroll_damping * dt)
		self.scroll_offset = math.max(0, math.min(self.scroll_offset, self.max_scroll))
	end
end

function Text2:draw()
	graphics.push(self.x, self.y, 0, 1, 1)

	if self.textbox_x and self.textbox_y then
		local draw_y = self.y + self.h / 2 + gh * 0.1 - self.scroll_offset

		love.graphics.setScissor(self.textbox_x, self.textbox_y, self.w, self.h)
		self.text:draw(self.x, draw_y, self.r, self.spring.x * self.sx, self.spring.x * self.sy)
		love.graphics.setScissor()
	else
		self.text:draw(self.x, self.y, self.r, self.spring.x * self.sx, self.spring.x * self.sy)
	end

	if self.scroll_box then
		local x = self.x
		local base_length = 10 * global_game_scale
		local thickness = 1.0 * global_game_scale
		local color = white[0]:clone()

		local y_offset = gh * 0.05

		-- UP arrow
		if self.scroll_offset > 0 then
			local y = self.y + y_offset
			local up_length = base_length * (self.scroll_offset / self.max_scroll)
			graphics.line(x, y - up_length, x - up_length / 2, y - up_length / 2, color, thickness)
			graphics.line(x, y - up_length, x + up_length / 2, y - up_length / 2, color, thickness)
		end

		-- DOWN arrow
		if self.scroll_offset < self.max_scroll then
			local y = self.y + self.h + y_offset
			local down_length = base_length * (1 - (self.scroll_offset / self.max_scroll))
			graphics.line(x, y + down_length, x - down_length / 2, y + down_length / 2, color, thickness)
			graphics.line(x, y + down_length, x + down_length / 2, y + down_length / 2, color, thickness)
		end
		graphics.rectangle(self.x, self.y + self.h / 2 + y_offset, self.w, self.h, 5, 5, color, 5)
	end

	graphics.pop()
end

function Text2:pull(...)
	self.spring:pull(...)
	self.r = random:table({ -math.pi / 24, math.pi / 24 })
	self.t:tween(0.2, self, { r = 0 }, math.linear)
end

function Text2:clear()
	self:set_text({
		{ text = "", font = pixul_font, alignment = "center" },
	})
end

function Text2:set_text(new_text)
	self.text:set_text(new_text)
end

--
-- width, height, world_x, world_y (centered)
-- lines of text
-- scroll_locked
-- scroll direction (vertical, horizontal)
-- require_mouse_hover (to 'select' which textbox to scroll)
-- mouse_drag (so mouse can click and drag it)
-- text_overflow (Clip, Wrap, Elipsis)
--
TextBox = Object:extend()
TextBox:implement(GameObject)
function TextBox:init(args)
	self:init_game_object(args)
	self.text = Text(args.lines, global_text_tags)
	self.w, self.h = args.w or self.text.w, args.h or self.text.h

	if self.scroll_box then
		self.max_scroll = math.max(0, self.text.h - self.h + self.text.line_height / 2)
		self.scroll_offset = 0
		self.scroll_velocity = 0
		self.scroll_speed = args.scroll_speed or 300
		self.scroll_damping = args.scroll_damping or 8 -- how quickly it slows down
		self.scroll_ease = args.scroll_ease or math.cubic_out
	end
end

function TextBox:update(dt)
	self:update_game_object(dt)
	self.text:update(dt)
end

--
--
--
--
-- misc

function slow(amount, duration, tween_method)
	print("slowing")
	amount = amount or 0.5
	duration = duration or 0.5
	tween_method = tween_method or math.cubic_in_out
	slow_amount = amount
	trigger:tween(duration, _G, { slow_amount = 1 }, tween_method, function()
		slow_amount = 1
	end, "slow")
end
