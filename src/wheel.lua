Pocket_Type = {
	Normal = 1,
	Jackpot = 2,
	Void = 3,
}

WheelCenter = Object:extend()
WheelCenter:implement(GameObject)
WheelCenter:implement(Physics)
function WheelCenter:init(args)
	self:init_game_object(args)
	self:set_as_circle(self.rs, "static", "wheel")
	self:set_position(self.x, self.y)

	self:set_restitution(0.8)
	self:set_friction(0)
end

function WheelCenter:update(dt)
	self:update_game_object(dt)
	self:update_physics(dt)
end

function WheelCenter:draw() end

Wheel = Object:extend()
Wheel:implement(GameObject)
Wheel:implement(Physics)
function Wheel:init(args)
	self:init_game_object(args)

	self.center = WheelCenter({
		group = self.group,
		x = self.x,
		y = self.y,
		rs = self.rs * 0.1,
	})

	local segments = 64
	local vertices = {}

	for i = 0, segments - 1 do
		local a = (i / segments) * math.pi * 2

		table.insert(vertices, math.cos(a) * self.rs)
		table.insert(vertices, math.sin(a) * self.rs)
	end

	self:set_as_chain(true, vertices, "static", "wheel")
	self:set_position(self.x, self.y)

	self:set_restitution(0.8)
	self:set_friction(0)

	local total_size = 0
	for _, pocket in ipairs(self.pockets) do
		total_size = total_size + pocket.size
	end

	local unit = 2 * math.pi / total_size

	local angle = 0
	for _, pocket in ipairs(self.pockets) do
		pocket.start_angle = angle
		pocket.end_angle = angle + unit * pocket.size
		angle = pocket.end_angle
	end

	self.spinrate = 0
end

function Wheel:update(dt)
	self:update_game_object(dt)
	self:update_physics(dt)

	self.r = self.r - dt * self.spinrate

	if self.spinning then
		for _, ball in ipairs(self.balls) do
			local bx, by = ball:get_position()
			local dx = self.x - bx
			local dy = self.y - by

			local dist = math.sqrt(dx * dx + dy * dy)

			if dist > 0 then
				local fx = -dy / dist + 0.1 * dy / dist
				local fy = dx / dist

				local strength = -self.spinrate * 1 * dist / self.r
				ball:apply_force(fx * strength, fy * strength)
			end
		end
	end
end

function Wheel:spin(speed)
	self.spinning = true
	trigger:tween(2, self, { spinrate = speed }, math.linear)
end

function Wheel:stop()
	self.spinning = false
	trigger:tween(5, self, { spinrate = 0 }, math.cubic_out)
end

-- function Wheel:results()
-- 	self.balls = table.map(self.balls, function(ball)
-- 		local angle = Vector(ball.x, ball.y):angle_to(self)
-- 		ball.angle = (angle + (2 * math.pi)) % (2 * math.pi)
-- 		return ball
-- 	end)
--
-- 	local ordered_balls = table.sort(self.balls, function(a, b)
-- 		return a.angle < b.angle
-- 	end)
--
-- 	local results = table.map(self.balls, function(ball)
-- 		for _, pocket in ipairs(self.pockets) do
-- 			local pocket_start = (math.pi + self.r + pocket.start_angle) % (2 * math.pi)
-- 			local pocket_end = (math.pi + self.r + pocket.end_angle) % (2 * math.pi)
-- 			if ball.angle > pocket_start and ball.angle < pocket_end then
-- 				ball.pocket = pocket
-- 				print(ball.angle, pocket_start, pocket_end)
-- 				break
-- 			end
-- 		end
--
-- 		if not ball.pocket then
-- 			print("no pocket for ball at ", ball.angle)
-- 		end
--
-- 		return ball
-- 	end)
--
-- 	return results
-- end

function Wheel:results()
	self.balls = table.map(self.balls, function(ball)
		local angle = Vector(ball.x, ball.y):angle_to(self)
		ball.angle = (angle - math.pi - self.r) % (2 * math.pi)
		return ball
	end)

	table.sort(self.balls, function(a, b)
		return a.angle > b.angle
	end)

	local results = table.map(self.balls, function(ball)
		ball.pocket = nil

		for _, pocket in ipairs(self.pockets) do
			if ball.angle >= pocket.start_angle and ball.angle < pocket.end_angle then
				ball.pocket = pocket
				break
			end
		end

		if not ball.pocket then
			print("no pocket for ball at", ball.angle)
		end

		return ball
	end)

	return results
end

function Wheel:draw()
	graphics.push(self.x, self.y, self.r, 1, 1)

	for i, pocket in ipairs(self.pockets) do
		graphics.arc("pie", self.x, self.y, self.rs, pocket.start_angle, pocket.end_angle, pocket.color)
	end
	graphics.circle(self.x, self.y, self.rs * 0.1, brown1[0])
	self:draw_physics()

	graphics.pop()
end
