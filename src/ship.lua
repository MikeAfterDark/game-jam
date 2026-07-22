Ship = Object:extend()
Ship:implement(GameObject)
function Ship:init(args)
	self:init_game_object(args)

	local scale = 1.08
	self.x = self.planet.x + self.planet.radius * scale * math.sin(self.r)
	self.y = self.planet.y - self.planet.radius * scale * math.cos(self.r)

	self.shape = Rectangle(self.x, self.y, self.w, self.h, 0)
	self.text = Text({
		{ --
			text = tostring(self.time),
			font = pixul_font,
			alignment = "center",
		},
	}, global_text_tags)
	self.interact_with_mouse = true
	self.color = random:color()
end

function Ship:update(dt)
	self:update_game_object(dt)

	self.time = self.time - dt
	self.text:set_text({
		{ text = string.format("%d", self.time), font = pixul_font, alignment = "center" },
	})
	self.text:update(dt)

	if self.selected and input.m1.pressed then
		print("boop")
		if self.time >= 1 then
			self.dead = true -- failed launch
		else
			self.flying = true
			local scale = 3
			self.t:tween(
				2,
				self,
				{
					x = self.planet.x + self.planet.radius * scale * math.sin(self.r),
					y = self.planet.y - self.planet.radius * scale * math.cos(self.r),
				},
				math.cubic_in,
				function()
					self.dead = true
				end
			)
		end
	end

	if self.time < 0 and not self.flying then
		print("im ded")
		self.dead = true
	end
end

function Ship:on_mouse_enter()
	self.selected = true
end

function Ship:on_mouse_exit()
	self.selected = false
end

function Ship:draw()
	graphics.push(self.x, self.y, self.r, 1, 1)
	-- self.shape:draw(self.color, 7)
	graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, self.color, 4)

	if not self.flying then
		self.text:draw(self.x, self.y - 40, 0, self.sx, self.sy)
	end

	graphics.pop()
end
