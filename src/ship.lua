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
	self.sprite = sprite.rocket

	self.is_golden = random:bool(9)
	self.is_rocket = not self.is_golden and random:bool(15)
	if self.is_rocket then
		self.time = 1
		sfx.obj.missile_appear:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	end

	self.scale = 1
	self.color = self.is_golden and yellow[0] or self.is_rocket and red[0] or white[0] --random:color()
	self.spring:pull(0.05, 500, 10)
end

function Ship:update(dt)
	self:update_game_object(dt)

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
	local text = self.time > 1 and string.format("[" .. text_color .. "]%d", self.time) or self.time > 0 and "[green]GO!" or "[purple]Miss"
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
		if self.time >= 1 and not self.is_golden then
			self.dead = true -- failed launch

			if self.is_rocket then
				sfx.obj.missile_disappear:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
			else
				sfx.obj.rocket_fail:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			end
		elseif self.time < 1 and not self.flying then
			self.flying = true
			self.selected = false
			self.interact_with_mouse = false
			local scale = gw
			self.locked_rotation = self.planet.r

			if self.is_rocket then
				sfx.obj.missile_explode:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
			else
				sfx.obj.rocket_launch:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			end
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

	if self.time < 0 and not self.flying and not self.dying then
		self.interact_with_mouse = false
		self.dying = true

		if self.is_rocket then
			self.dead = true
			sfx.obj.rocket_fail:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			camera:shake(2, 0.3, 120)
		else
			self.t:tween(1, self, { scale = 0, w = 0, h = 0 }, math.cubic_in_out, function()
				self.dead = true
				-- sfx.obj.ufo:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			end)
		end
	end
end

function Ship:on_mouse_enter()
	self.selected = true
	random:table(sfx.ui.hover):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	self.spring:pull(0.05, 500, 10)
end

function Ship:on_mouse_stay()
	self.selected = true
end

function Ship:on_mouse_exit()
	self.selected = false
end

function Ship:draw()
	graphics.push(self.x, self.y, self.r + (self.flying and self.locked_rotation or self.planet.r), self.spring.x, self.spring.x)

	if self.selected then
		graphics.rectangle(self.x, self.y, self.w + 4, self.h + 4, 3, 3, white[0], 4)
	end

	-- graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, self.color, 4)

	local scale = 0.05 * self.scale
	self.sprite:draw(self.x, self.y, 0, scale, scale, 0, 0, self.color)

	if not self.flying then
		if self.time <= 1 and self.time >= 0 then
			local h = (self.time * self.h)
			local w = 5
			local color = Color(1 - self.time, self.time, 0, 0.8)
			local x = self.x + 13
			local y = self.y + self.h / 2 - h / 2
			graphics.rectangle(x, y, w, h, 1, 1, color)

			local t = scale - (self.time * scale)
			-- self.sprite:draw(self.x, self.y, 0, scale, t, 0, 0, color)
		end

		if
			not self.is_rocket --[[ and not self.dying ]]
		then
			graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
			local scale = self.scale * ((self.time < 1 and self.time > 0) and 1.5 or 1)
			self.text:draw(self.x, self.y - self.h * 0.7, 0, scale, scale)
			graphics.pop()
		end
	end

	graphics.pop()
	-- self.shape:draw()
end
