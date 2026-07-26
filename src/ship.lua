Ship = Object:extend()
Ship:implement(GameObject)
function Ship:init(args)
	self:init_game_object(args)

	local scale = 1.00
	local size = self.h / 2
	self.x = self.planet.x + (self.planet.rs + size) * math.sin(self.r)
	self.y = self.planet.y - (self.planet.rs + size) * math.cos(self.r)

	self.shape = Rectangle(self.x, self.y, self.w, self.h, self.r + self.planet.r)
	self.text = Text({
		{ --
			text = "",
			font = pixul_font,
			alignment = "center",
		},
	}, global_text_tags)
	self.interact_with_mouse = true

	sfx.obj.rocket_appear:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })

	self.is_golden = random:bool(9)
	self.is_rocket = not self.is_golden and random:bool(15)
	if self.is_rocket then
		self.time = 1
		self.exh_animations = sprite.exhaust.large
	else
		self.exh_animations = random:table({ sprite.exhaust.small, sprite.exhaust.medium })
	end

	self.sprite = self.is_golden and sprite.rocket_nasa
		-- or self.is_rocket and random:table({ sprite.rocket_red, sprite.rocket_orange })
		-- or random:table({ sprite.rocket_green, sprite.rocket_blue })
		or self.is_rocket and random:table({ sprite.rocket_green, sprite.rocket_blue })
		or random:table({ sprite.rocket_red, sprite.rocket_orange })

	self.scale = 0
	self.draw_height = self.h / 2
	self.t:tween(0.4, self, { scale = 1, draw_height = 0 }, math.bounce_out, function() end)
	self.color = white[0] -- self.is_golden and yellow[0] or self.is_rocket and red[0] or white[0] --random:color()
	self.spring:pull(0.05, 500, 10)
end

function Ship:update(dt)
	self:update_game_object(dt)

	if self.exh_animation then
		self.exh_animation:update(dt)

		if self.exh_animation.animation_logic.dead then
			self.exh_animation = self.exh_animations.loop()
		end
	end

	if self.explosion_animation then
		self.explosion_animation:update(dt)
		if self.explosion_animation.animation_logic.dead then
			self.explosion_animation.dead = true
			self.explosion_animation = nil
			self.dead = true
		end
	end

	self.prev_time = self.time
	self.time = self.freeze_time and self.time --
		or self.is_golden and self.time - dt * 1.35
		or self.is_rocket and self.time - dt * 0.5
		or self.time > 1 and (self.time - dt)
		or self.time - dt * 0.5

	if math.ceil(self.prev_time) ~= math.ceil(self.time) then
		self.spring:pull(0.05, 500, 10)
	end

	if self.time < 1 and not self.played_alarm_sfx then
		self.played_alarm_sfx = true
	end

	local text_color = self.time > 3 and "red" or self.time > 2 and "orange" or self.time > 1 and "yellow" or ""
	local text = self.time > 1 and string.format("[" .. text_color .. "]%d", self.time) or self.time > 0 and "[green]GO!" or
	"[purple]Miss"
	self.text:set_text({
		{ text = text, font = pixul_font, alignment = "center" },
	})
	self.text:update(dt)

	if not self.flying then
		local size = self.h / 2
		self.x = self.planet.x + (self.planet.rs + size) * math.sin(self.r + self.planet.r)
		self.y = self.planet.y - (self.planet.rs + size) * math.cos(self.r + self.planet.r)
		self.shape:move_to(self.x, self.y)
		self.shape:get_centroid()
		self.shape:set_rotation(self.r + self.planet.r)
	end

	if self.selected and input.m1.pressed then
		self.hit = run_time
		self.mouse_x, self.mouse_y = self.group:get_mouse_position()

		if self.time >= 1 and not self.is_golden then
			self.new_hit = true

			-- sfx.obj.missile_explode:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
			self.explosion_animation = sprite.explosion()
			camera:shake(7, 0.2, 120)
			self.hide_rocket = true
			self.selected = false
			self.interact_with_mouse = false
			self.bad_hit = true
			sfx.obj.missile_explode:play({ pitch = random:float(0.95, 1.05), volume = 0.2 })
		elseif self.time < 1 and not self.flying then
			self.new_hit = true
			self.flying = not self.is_rocket
			self.selected = false
			self.interact_with_mouse = false
			self.locked_rotation = self.planet.r

			if self.is_rocket then
				sfx.obj.missile_explode:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
				self.explosion_animation = sprite.explosion()

				camera:shake(7, 0.2, 120)
				self.hide_rocket = true
				self.selected = false
				self.interact_with_mouse = false
				self.bad_hit = true
			else
				sfx.obj.rocket_launch:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
				self.exh_animation = self.exh_animations.start()
				local scale = gw
				self.t:tween(
					2,
					self,
					{
						x = self.planet.x + scale * math.sin(self.r + self.locked_rotation),
						y = self.planet.y - scale * math.cos(self.r + self.locked_rotation),
					},
					math.circ_in,
					function()
						self.dead = true
					end
				)
			end
		end
	end

	if self.new_hit and not self.bad_hit then
		print("triggered for ", self.id, " good hit: ", not self.bad_hit)
		self.new_hit = false
		local score = random:int(1, 5)
		local sign = self.bad_hit and "-" or "+"

		ScoreBubble({
			group = self.group,
			x = self.x,
			y = self.y,
			r = self.r,
			planet = self.planet,
			value = score,
			color = black[0], --not self.bad_hit and yellow[0] or red[0],
		})
	end

	if self.time < 0 and not self.flying and not self.dying then
		self.interact_with_mouse = false
		self.selected = false
		self.dying = true

		if self.is_rocket then
			self.flying = true
			self.selected = false
			self.interact_with_mouse = false
			self.exh_animation = self.exh_animations.start()
			self.locked_rotation = self.planet.r

			sfx.obj.rocket_launch:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			local scale = gw
			self.t:tween(
				2,
				self,
				{
					x = self.planet.x + scale * math.sin(self.r + self.locked_rotation),
					y = self.planet.y - scale * math.cos(self.r + self.locked_rotation),
				},
				math.circ_in,
				function()
					self.dead = true
				end
			)

			-- sfx.obj.missile_explode:play({ pitch = random:float(0.95, 1.05), volume = 0.2 })
			-- self.explosion_animation = sprite.explosion()
			-- self.hide_rocket = true
			-- camera:shake(2, 0.3, 120)
		else
			sfx.obj.rocket_disappear:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			self.t:tween(1, self, { scale = 0, w = 0, h = 0 }, math.cubic_in_out, function()
				self.dead = true
			end)
		end
	end
end

function Ship:on_mouse_enter()
	self.selected = true
	sfx.obj.rocket_mouse_hover:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	self.spring:pull(0.05, 500, 10)
end

function Ship:on_mouse_stay()
	self.selected = true
end

function Ship:on_mouse_exit()
	self.selected = false
end

function Ship:draw()
	graphics.push(self.x, self.y, self.r + (self.flying and self.locked_rotation or self.planet.r), self.spring.x,
		self.spring.x)

	if self.selected then
		local rounded = 20
		graphics.rectangle(self.x, self.y, self.w + 4, self.h + 4, rounded, rounded, white[0], 4)
	end

	-- graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, self.color, 4)

	if not self.hide_rocket then
		local scale = 0.6 * self.scale
		local sprite_y = self.y + self.draw_height
		-- self.sprite:draw(self.x, sprite_y, 0, scale * 1.1, scale * 1.1, 0, 0, red[0])
		self.sprite:draw(self.x, sprite_y, 0, scale, scale, 0, 0, self.color)
	end

	if self.exh_animation then
		local exh_scale = 0.5
		-- 1 = 1.3
		-- 0.5 =
		if self.is_golden then
			self.exh_animation:draw(self.x - self.w / 4, self.y + self.h * 1, 0, exh_scale, exh_scale, 0, 0)
			self.exh_animation:draw(self.x + self.w / 4, self.y + self.h * 1, 0, exh_scale, exh_scale, 0, 0)
		else
			self.exh_animation:draw(self.x, self.y + self.h * 1, 0, exh_scale, exh_scale, 0, 0)
		end
	end

	if self.explosion_animation then
		local explosion_scale = self.is_rocket and 1.6 or 0.8
		self.explosion_animation:draw(self.x, self.y, 0, explosion_scale, explosion_scale, 0, 0)
	end

	if not self.flying and not self.hide_rocket then
		if self.time <= 1 and self.time >= 0 then
			local h = (self.time * self.h)
			local w = 5
			-- local color = Color(1 - self.time, self.time, 0, 0.8) -- green to red fade
			local color = Color(0, 1, 0, 0.8)
			local x = self.x + 13
			local y = self.y + self.h / 2 - h / 2
			graphics.rectangle(x, y, w, h, 1, 1, green[0])

			-- local t = scale - (self.time * scale)
			-- self.sprite:draw(self.x, self.y, 0, scale, t, 0, 0, color)
		end

		if not self.is_rocket and not self.hide_rocket then
			graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
			local scale = self.scale * ((self.time < 1 and self.time > 0) and 1.5 or 1)
			self.text:draw(self.x, self.y - self.h * 0.7, 0, scale, scale)
			graphics.pop()
		end
	end

	graphics.pop()
	-- self.shape:draw()

	local hit = self.hit or 0
	local hit_animation_duration = 0.15
	local hit_time = hit + hit_animation_duration
	if run_time < hit_time and not dying and not (self.is_golden and not self.flying) then
		local t = (hit_time - run_time) / (hit_time - hit)
		local size = 20 * t
		local color = (self.bad_hit or self.is_rocket) and red[0]:clone() or self.color:clone()
		color.a = t
		graphics.circle(self.mouse_x, self.mouse_y, size, color)
	end
end
