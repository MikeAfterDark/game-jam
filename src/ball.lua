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
end

function Ball:update(dt)
	self:update_game_object(dt)
	self:update_physics(dt)
end

function Ball:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
	self.shape:draw()
	graphics.circle(self.x, self.y, self.r, self.color)
	graphics.pop()
end
