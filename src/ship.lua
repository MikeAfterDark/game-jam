Ship = Object:extend()
Ship:implement(GameObject)
function Ship:init(args)
	self:init_game_object(args)

	local scale = 1.00
	local size = self.h / 2
	self.x = self.planet.x + (self.planet.rs + size) * math.sin(self.r)
	self.y = self.planet.y - (self.planet.rs + size) * math.cos(self.r)

	self.shape = Rectangle(self.x, self.y, self.w, self.h, self.r)
	self.text = Text({
		{ --
			text = "",
			font = pixul_font,
			alignment = "center",
		},
	}, global_text_tags)
	self.interact_with_mouse = true
	self.color = random:color()
end

function Ship:update(dt)
	self:update_game_object(dt)

	self.time = self.freeze_time --
			and self.time
		or self.time > 1 and (self.time - dt)
		or self.time - dt / 2

	if self.time < 1 and not self.played_alarm_sfx then
		self.played_alarm_sfx = true
		-- sfx.alert.incoming:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	end

	self.text:set_text({
		{ text = string.format("%d", self.time), font = large_pixul_font, alignment = "center" },
	})
	self.text:update(dt)

	if not self.flying then
		local size = self.h / 2
		self.x = self.planet.x + (self.planet.rs + size) * math.sin(self.r + self.planet.r)
		self.y = self.planet.y - (self.planet.rs + size) * math.cos(self.r + self.planet.r)
		self.shape:move_to(self.x, self.y)
	end

	if self.selected and input.m1.pressed then
		if self.time >= 1 then
			self.dead = true -- failed launch
			sfx.obj.rocket_fail:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		elseif not self.flying then
			self.flying = true
			self.selected = false
			self.interact_with_mouse = false
			local scale = gw
			self.locked_rotation = self.planet.r
			sfx.obj.rocket_launch:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
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

	if self.time < 0 and not self.flying then
		print("im ded")
		self.dead = true
		sfx.obj.rocket_fail:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		camera:shake(2, 0.3, 120)
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
	-- self.shape:draw(self.color, 7)
	if self.selected then
		graphics.rectangle(self.x, self.y, self.w + 4, self.h + 4, 3, 3, white[0], 4)
	end
	graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, self.color, 4)

	if not self.flying then
		if self.time <= 1 and self.time >= 0 then
			local h = self.h - (self.time * self.h)
			graphics.rectangle(self.x, self.y, self.w, h, 1, 1, Color(1, 0, 0, 0.6))
		end
		self.text:draw(self.x, self.y - self.h * 0.7, 0, self.sx, self.sy)
	end

	graphics.pop()
end
