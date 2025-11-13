require("objects")

runner_types = {
	knight = {
		name = "knight",
		load_sprites = function(self)
			-- run, jump
			-- self.sprites = knight_sprites.sprite_sheets

			self.animations = {
				idle = Animation({
					sprite_sheet = knight_sprites.sprite_sheets.idle,
					frame_width = knight_sprites.frame_width,
					frame_height = knight_sprites.frame_height,
					speed = knight_sprites.animation_speed,
					center_x = knight_sprites.hitbox_center_x,
					center_y = knight_sprites.hitbox_center_y,
				}),
				run = Animation({
					sprite_sheet = knight_sprites.sprite_sheets.run,
					frame_width = knight_sprites.frame_width,
					frame_height = knight_sprites.frame_height,
					speed = knight_sprites.animation_speed,
					center_x = knight_sprites.hitbox_center_x,
					center_y = knight_sprites.hitbox_center_y,
				}),
				jump = Animation({
					sprite_sheet = knight_sprites.sprite_sheets.jump,
					frame_width = knight_sprites.frame_width,
					frame_height = knight_sprites.frame_height,
					speed = knight_sprites.animation_speed,
					center_x = knight_sprites.hitbox_center_x,
					center_y = knight_sprites.hitbox_center_y,
				}),
				dead = Animation({
					sprite_sheet = knight_sprites.sprite_sheets.dead,
					frame_width = knight_sprites.frame_width,
					frame_height = knight_sprites.frame_height,
					speed = knight_sprites.animation_speed,
					center_x = knight_sprites.hitbox_center_x,
					center_y = knight_sprites.hitbox_center_y,
					stop_on_finish = true,
				}),
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

	self.type = runner_types[self.type]
	self.state = Runner_State.Run
	self.type.load_sprites(self)
	self:set_as_rectangle(self.w, self.h, "dynamic", "runner")
	self:set_fixed_rotation(true) -- stop the damn hitbox from spinning
	self:set_restitution(0.1)
	self:set_damping(0)

	self.dir = self.direction == "right" and 1 or 0
	self.max_uphill_angle = 50 --degrees

	self.color = _G["white"][0]
	self.color_text = "red"
	self.label_y_offset = 50 * self.size
	self.runner_label = Text2({
		x = self.x,
		y = self.y + self.label_y_offset,
		lines = { { text = "[" .. self.color_text .. "]A", font = pixul_font } },
	})
end

function Runner:update(dt)
	self:update_game_object(dt)

	local vx, vy = self:get_velocity()
	local gx, gy = main.current.main.world:getGravity() -- NOTE: maybe only if not falling?

	local vel = 0
	if self.state == Runner_State.Slide then
		self:set_friction(0)
		self.dir = math.sign(vx)
		vel = math.abs(self.icy_velocity / 2) * self.dir

		if self.grounded then
			local max_speed = 10
			local max_vel = 10
			-- self.icy_speed = math.max(math.min(self.icy_speed * self.ground_normal, max_speed), -max_speed)
			-- vel = math.max(math.min(vel * self.icy_speed, max_vel), -max_vel)
			if self.ground_normal.y >= 0.99 then
				self:set_velocity(vel + gx * dt, vy + gy * dt)
			end
		end
	elseif self.state ~= Runner_State.Idle and self.state ~= Runner_State.Dead and self.grounded then
		self:set_friction(1)
		vel = self.speed * self.dir
		if self.grounded then
			self:set_velocity(vel * self.size + gx * dt, vy + gy * dt)
		end
	end

	if self.grounded then
		self.temp_color = red[0]
	else
		self.temp_color = blue[0]
	end

	self.runner_label.x = self.x
	self.runner_label.y = self.y + self.label_y_offset

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
	-- self.grounded = false
	-- self.ground_normal = nil
	-- self.touching_left = false
	-- self.touching_right = false
	if ny > 0.6 then
		self.grounded = true
		self.ground_normal = { x = nx, y = ny }
	elseif math.abs(nx) > 0.6 then
		if nx < 0 then
			-- self.touching_left = true
			self.dir = 1
			-- print(self.count, "left: nx:", nx, ", ny: ", ny)
		else
			-- self.touching_right = true
			self.dir = -1
			-- print(self.count, "right: nx:", nx, ", ny: ", ny)
		end
	end
end

function Runner:draw()
	-- graphics.rectangle(self.x, self.y, self.w, self.h, 0, 0, self.color)
	self:draw_physics(self.temp_color or white[0])

	self.runner_label:draw()

	local color = Color(1, 1, 1, 0.8)
	local anim = self.animations[self.state]
	if anim then
		anim:draw(self.x, self.y, 0, self.size * self.dir, self.size, 0, 0, color)
	else
		self.animations[Runner_State.Idle]:draw(self.x, self.y, 0, self.size * self.dir, self.size, 0, 0, color)
	end
end

function Runner:on_collision_enter(other, contact)
	-- if other:is(Wall) and other.type.name ~= "Death" then
	-- 	local nx, ny = contact:getNormal()
	--
	-- 	local upx, upy = 0, -1
	--
	-- 	local len = math.sqrt(nx * nx + ny * ny)
	-- 	if len == 0 then
	-- 		return
	-- 	end
	-- 	nx, ny = nx / len, ny / len
	--
	-- 	local dot = nx * upx + ny * upy
	--
	-- 	dot = math.min(1, math.max(-1, dot))
	--
	-- 	local angle = math.acos(dot)
	-- 	local max_uphill_angle = math.rad(60)
	--
	-- 	if angle > max_uphill_angle then
	-- 		self.dir = -self.dir
	-- 	end
	-- end
end
