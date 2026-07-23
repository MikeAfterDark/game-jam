Planet = Object:extend()
Planet:implement(GameObject)
function Planet:init(args)
	self:init_game_object(args)
	self.shape = Circle(self.x, self.y, self.rs)

	self.planet_speed = 0.3
end

function Planet:update(dt)
	self:update_game_object(dt)

	local planet_speed = slow_amount * dt * self.planet_speed
	local planet_rotation_speed = 10
	self.r = self.r + planet_speed / 16
	self.x = self.x + math.sin(self.r * planet_rotation_speed) * planet_rotation_speed * planet_speed
	self.y = self.y + math.cos(self.r * planet_rotation_speed) * planet_rotation_speed * planet_speed
end

function Planet:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
	graphics.circle(self.x, self.y, self.rs, green[0])
	graphics.circle(self.x, self.y, 5, black[0])
	graphics.pop()
end
