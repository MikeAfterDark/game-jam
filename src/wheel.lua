Pocket_Type = {
	Normal = 1,
	Jackpot = 2,
	Void = 3,
}

Wheel = Object:extend()
Wheel:implement(GameObject)
Wheel:implement(Physics)
function Wheel:init(args)
	self:init_game_object(args)

	self.center = WheelCenter({
		group = self.group,
		x = self.x,
		y = self.y,
		rs = self.rs * 0.2,
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

		pocket.text = Text({
			{ text = tostring(pocket.value), font = small_pixul_font, alignment = "center" },
		}, global_text_tags)
	end

	self.spinrate = 0
	self.ball_dampening = 0.4

	self.sfx_distance = 0
	self.last_tick_sfx = 0
	self.tick_sfx_interval = 0.2
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

				local strength = -self.spinrate * 10 * dist / self.r
				ball:apply_force(fx * strength, fy * strength)
			end
		end
	end

	for i, ball in ipairs(self.balls) do
		ball:set_damping(self.ball_dampening)
	end

	for _, pocket in ipairs(self.pockets) do
		pocket.text:set_text({
			{
				text = tostring(pocket.value), --
				font = small_pixul_font,
				alignment = "center",
			},
		})
	end

	self.sfx_distance = self.sfx_distance + dt * self.spinrate
	if self.sfx_distance > self.last_tick_sfx + self.tick_sfx_interval then
		self.last_tick_sfx = self.sfx_distance
		sfx.tick:play({ pitch = 0.9 + 0.2 * (self.spinrate / self.spin_max_speed), volume = 0.3 })
	end
end

function Wheel:new_ball(ball, left_side_entrance)
	table.insert(self.balls, ball)

	local dir = (left_side_entrance and -1 or 1)
	local x = self.x + 0.90 * self.rs * dir
	ball:freeze(x, self.y)
	ball:set_restitution(1)
	ball:set_damping(0.5)
	ball:set_friction(0)
	ball:set_mass(1)

	ball:apply_impulse(-dir * 200, 1 * 800) --self.spinrate)
end

function Wheel:all_balls_stopped()
	local ready = true
	for i, ball in ipairs(self.balls) do
		if Vector(ball:get_velocity()):length_squared() > 0.1 then
			ready = false
		end
	end

	return ready
end

function Wheel:selected_ball(ball)
	local function reorder_selected()
		for i, selected_ball in ipairs(self.selected_balls) do
			selected_ball.spring:pull(0.2, 500, 10)
			selected_ball.order = i
		end
	end

	if table.contains(self.selected_balls, ball) then
		self.selected_balls = table.delete(self.selected_balls, ball)
		reorder_selected()
		return
	end

	if #self.selected_balls == self.max_num_selected_balls then
		local old_ball = table.shift(self.selected_balls)
		old_ball.order = nil
		old_ball.spring:pull(0.2, 500, 10)

		reorder_selected()
	end

	if #self.selected_balls < self.max_num_selected_balls then
		table.insert(self.selected_balls, ball)
		return #self.selected_balls
	end
end

function Wheel:enable_ball_selection(num_balls)
	self.max_num_selected_balls = num_balls
	self.selected_balls = {}
	sfx.boop:play({ pitch = 0.6, volume = 0.35 })

	for i, ball in ipairs(self.balls) do
		-- if not ball.is_enemy then
		ball:activate_mouse(self, Ball_Interaction_Mode.Wheel_Selection)
		-- end
	end

	self.t:every_immediate(1.3, function()
		for i, ball in ipairs(self.balls) do
			if not ball.is_enemy then
				ball.spring:pull(0.2, 300, 10)
			end
		end
	end, 0, function() end, "ball_selection_bounce")
end

function Wheel:any_balls_selected()
	return #self.selected_balls > 0
end

function Wheel:all_balls_selected()
	if #self.selected_balls == self.max_num_selected_balls then
		for i, ball in ipairs(self.balls) do
			if not ball.is_enemy then
				ball:deactivate_mouse()
			end
		end
		return true
	end
end

function Wheel:spin(speed)
	self.spinning = true
	self.first_time_balls_stopped = false
	self.last_tick_sfx = self.last_tick_sfx - self.sfx_distance
	self.sfx_distance = 0
	self.spin_max_speed = speed
	self.ball_dampening = 0.4
	trigger:tween(2, self, { spinrate = speed }, math.cubic_in, function()
		self.is_spun_up = true
	end)
end

function Wheel:stop()
	self.spinning = false
	local time_to_stop = 3
	trigger:tween(time_to_stop, self, { spinrate = 0 }, math.cubic_out, function() end)
	trigger:tween(time_to_stop - 0.5, self, { ball_dampening = 3.5 }, math.linear, function() end)
end

function Wheel:results()
	-- play the selected_balls in their selection order then
	-- play the enemy balls based on angle, from low to high
	self.t:cancel("ball_selection_bounce")
	for i, ball in ipairs(self.balls) do
		ball:deactivate_mouse()
	end

	self.balls = table.map(self.balls, function(ball)
		local angle = Vector(ball.x, ball.y):angle_to(self)
		ball.angle = (angle - math.pi - self.r) % (2 * math.pi)
		return ball
	end)

	table.sort(self.balls, function(a, b)
		return a.angle < b.angle
	end)

	for i, ball in ipairs(self.balls) do
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
	end

	local results = table.append(
		self.selected_balls,
		table.select(self.balls, function(ball)
			return ball.is_enemy
		end)
	)
	return results
end

function Wheel:draw()
	graphics.push(self.x, self.y, self.r, 1, 1)

	for i, pocket in ipairs(self.pockets) do
		graphics.arc("pie", self.x, self.y, self.rs, pocket.start_angle, pocket.end_angle, pocket.color)

		local angle = pocket.start_angle + (pocket.end_angle - pocket.start_angle) / 2
		local radius = self.rs * 0.9
		local x = self.x + math.cos(angle) * radius
		local y = self.y + math.sin(angle) * radius

		pocket.text:draw(x, y, angle + math.pi / 2, 1, 1)
	end
	self:draw_physics()

	graphics.pop()
end

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

function WheelCenter:draw()
	graphics.circle(self.x, self.y, self.rs, brown1[0])
end
