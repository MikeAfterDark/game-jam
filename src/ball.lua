Ball_Event = {
	Scoring = 1,
	Collision = 2,
}

Ball = Object:extend()
Ball:implement(GameObject)
Ball:implement(Physics)
function Ball:init(args)
	self:init_game_object(args)

	self:set_as_circle(self.r, "dynamic", "ball")
	self:set_velocity(random:float() * 100, random:float() * 100)

	self:set_restitution(1)
	self:set_damping(0.5)
	self:set_friction(0)

	self:set_mass(1)

	self.color = random:color()
end

function Ball:update(dt)
	self:update_game_object(dt)
	self:update_physics(dt)
end

function Ball:trigger(event)
	self.pocket.value = self.pocket.value * 2

	self.triggering = true
	trigger:after(0.2, function()
		self.triggering = false
	end)
end

function Ball:is_done()
	return not self.triggering
end

function Ball:freeze(x, y)
	self:set_velocity(0, 0)
	self:set_position(x or self.x, y or self.y)
end

function Ball:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
	-- self.shape:draw()
	graphics.circle(self.x, self.y, self.r, self.is_enemy and red[0] or black[0])
	graphics.circle(self.x, self.y, self.r * 0.70, self.color)
	graphics.pop()
end
