require("objects")

runner_types = {
	knight = {
		name = "knight",
		load_sprites = function(self)
			self.animations = {
				idle = Animation({ sheet = knight_sprites, type = "idle" }),
				run = Animation({ sheet = knight_sprites, type = "run" }),
				jump = Animation({ sheet = knight_sprites, type = "jump" }),
				dead = Animation({ sheet = knight_sprites, type = "dead", stop_on_finish = true }),
			}

			self.w = knight_sprites.hitbox_width * self.size
			self.h = knight_sprites.hitbox_height * self.size
		end,
	},
}

Runner_State = {
	Idle = "idle",
	Run = "run",
	Jump = "jump",
	Slide = "slide",
	Dead = "dead",
}

Runner = Object:extend()
Runner:implement(GameObject)
Runner:implement(Physics)
Runner:implement(Unit)
function Runner:init(args)
	self:init_game_object(args)
	counter = counter and (counter + 1) or 0
	self.count = counter
	self.init_x = self.x
	self.init_y = self.y

	self.type = runner_types[self.type]
	self.state = Runner_State.Run
	self.type.load_sprites(self)
	self:set_as_rectangle(self.w, self.h, "dynamic", "runner")
	self:set_fixed_rotation(true) -- stop the damn hitbox from spinning
	self:set_restitution(0.1)
	self:set_damping(0)
	self:set_friction(0)

	self.dir = self.direction == "right" and 1 or -1
	self.max_uphill_angle = 50 --degrees

	self.color = _G["white"][0]
	self.color_text = "red"
	self.sfx = {}

	-- self.label_y_offset = 50 * self.size
	-- self.runner_label = Text2({
	-- 	x = self.x,
	-- 	y = self.y + self.label_y_offset,
	-- 	lines = { { text = "[" .. self.color_text .. "]A", font = pixul_font } },
	-- })
end

function Runner:reset()
	self.state = Runner_State.Run
	self.dir = self.direction == "right" and 1 or -1

	self:set_position(self.init_x, self.init_y)
end

function Runner:update(dt)
	self:update_game_object(dt)

	local vx, vy = self:get_velocity()
	local gx, gy = main.current.main.world:getGravity() -- NOTE: maybe only if not falling?

	local vel = 0
	if self.state == Runner_State.Slide then
		-- self:set_friction(0)
		-- self.dir = vx ~= 0 and math.sign(vx) or 1
		-- vel = math.abs(self.icy_velocity / 2) * self.dir
		--
		-- if self.grounded then
		-- 	-- self.icy_speed = math.max(math.min(self.icy_speed * self.ground_normal, max_speed), -max_speed)
		-- 	-- vel = math.max(math.min(vel * self.icy_speed, max_vel), -max_vel)
		-- 	if self.ground_normal.y >= 0.99 then
		-- 		self:set_velocity(vel + gx * dt, vy + gy * dt)
		-- 	elseif self.ground_normal.x > 0.1 then
		-- 		self:apply_force(vel, 0)
		-- 	end
		-- end
	elseif self.state ~= Runner_State.Idle and self.state ~= Runner_State.Dead and self.grounded then
		vel = self.speed * self.dir
		if self.grounded then
			self:set_velocity(vel * math.min(1, self.size / 1.6) + gx * dt, vy + gy * dt)

			if not self.sfx.run or self.sfx.run:isStopped() then
				-- self.sfx.run = random:table(invader_footsteps):play({
				-- 	pitch = random:float(0.9, 1.2),
				-- 	volume = 0.5,
				-- })
			end
		end
	elseif self.state == Runner_State.Dead then
		self:set_velocity(vx * 0.98, vy) -- fake friction/drag cuz physics shenanigans (friction at enter_contact is all that matters)
	end

	if self.grounded then
		self.temp_color = red[0]
	else
		self.temp_color = blue[0]
	end

	local animation = self.animations[self.state]
	if animation then
		animation.x = self.x
		animation.y = self.y
		animation:update(dt)
	end

	self.grounded = false
	self.ground_normal = nil
end

function Runner:on_collision_post(other, contact, nx, ny, normal_impulse, tangent_impulse)
	if ny > 0.6 then
		self.grounded = true
		self.ground_normal = { x = nx, y = ny }
	elseif math.abs(nx) > 0.6 then
		if nx < 0 then
			self.dir = 1
		else
			self.dir = -1
		end
	end
end

function Runner:draw()
	-- self:draw_physics(self.temp_color or white[0])
	-- self.runner_label:draw()

	local color = Color(1, 1, 1, 1)
	local anim = self.animations[self.state]
	if anim then
		anim:draw(self.x, self.y, 0, self.size * self.dir, self.size, 0, 0, color)
	else
		self.animations[Runner_State.Idle]:draw(self.x, self.y, 0, self.size * self.dir, self.size, 0, 0, color)
	end
end

function Runner:set_state(new_state)
	if self.state ~= Runner_State.Dead then
		self.state = new_state
	end
end

function Runner:on_collision_enter(other, contact) end
