require("objects")

Player = Object:extend()
Player:implement(GameObject)
Player:implement(Physics)
Player:implement(Unit)
function Player:init(args)
	self:init_game_object(args)
	self:init_unit()

	self:set_as_circle(self.size, "dynamic", "player")

	self.spawn = Vector(self.x, self.y)
	if self.init_wall_normal then
		self.init_wall_normal_theta = self.init_wall_normal:angle()
	end

	self:spawn_player()

	if args.tutorial then
		self.tutorial_player_indicator_text = Text2({
			group = main.current.tutorial_ui,
			x = self.x,
			y = self.y + 20,
			lines = { { text = "[" .. self.color_text .. "]player", font = pixul_font } },
		})
	end
end

function Player:spawn_player()
	self.spawn_flag = true
	self.ready = true -- TODO: check if we're on a wall and not moving

	self.color = self.color or yellow[0]
	self.color_text = self.color_text or "yellow"

	self.wall_normal = self.init_wall_normal or Vector:zero()
	self.wall_normal_theta = self.init_wall_normal_theta or nil
end

function Player:update(dt)
	self:update_game_object(dt)

	if not main.current.won and not main.current.died and not main.current.paused and not main.current.transitioning then
		if self.spawn_flag then
			self.spawn_flag = false

			self:set_position(self.spawn.x, self.spawn.y)
			self.ready = true -- NOTE: check if we're on a wall and not moving
		end

		if self.size_change ~= self.size then -- for grow/shrink
			if not self.size_change then
				self.size_change = self.size
			else
				self.size = self.size_change
				self:change_circle_radius(self.size)
			end
		end

		local vx, vy = self:get_velocity()
		if vx == 0 and vy == 0 then
			self.ready = true
		end

		if self.collided then
			self.collided = false

			local dist = 2
			self:set_position(self.x + self.wall_normal.x * dist, self.y + self.wall_normal.y * dist)
			if self.wall_normal_theta then
				self.r = self.wall_normal_theta
			end
		end

		local x, y = 0, 0
		if input.left.down then
			x = x - 1
		end
		if input.right.down then
			x = x + 1
		end
		if input.up.down then
			y = y - 1
		end
		if input.down.down then
			y = y + 1
		end

		if x ~= 0 or y ~= 0 then
			local input_dir = Vector(x, y)
			local n = self.wall_normal
			local dot = input_dir:dot(n)

			if dot > -0.0001 then
				self.r = math.atan2(y, x)
			elseif dot > -0.99 then
				--- NOTE: QoL: so that 'partly-invalid' directions are corrected to valid ones
				--- but this also has a major impact on 'clone' wall behaviour, so test on and off axis, mostly affects keyboard
				local tangent = Vector(-n.y, n.x)
				if input_dir:dot(tangent) < 0 then
					tangent = tangent:invert()
				end
				self.r = math.atan2(tangent.y, tangent.x)
			end
		end

		if self.ready and input.jump.pressed then
			self:move_along_angle(self.speed, self.r)
			self.ready = false
		end
	end

	if self.tutorial_player_indicator_text ~= nil then
		self.tutorial_player_indicator_text.x = self.x
		self.tutorial_player_indicator_text.y = self.y + 16
	end
end

function Player:draw()
	graphics.circle(self.x, self.y, self.size, self.color)
	self.tutorial_player_indicator_text:draw()

	if self.ready then
		graphics.push(self.x, self.y, self.r, self.hfx.hit.x * self.hfx.shoot.x, self.hfx.hit.x * self.hfx.shoot.x)
		-- NOTE: Facing direction arrow
		local x, y = self.x + 0.9 * self.shape.w / 3 * global_game_scale, self.y
		local size = 3 * global_game_scale
		graphics.polyline(self.color, size, x + size, y, x, y - size, x, y + size, x + size, y)

		graphics.pop()
	end

	if self.wall_normal and self.wall_normal_theta then
		local scale = math.max(0.01, self.hfx.hit.x * self.hfx.shoot.x)

		graphics.push(self.x, self.y, self.wall_normal_theta, scale, scale)
		-- NOTE: Wall normal arrow
		local x, y = self.x + 0.9 * self.shape.w / 3 * global_game_scale, self.y
		local length = 7 * global_game_scale
		local thickness = 1.5 * global_game_scale
		local color = yellow[0]
		graphics.line(x + length, y, x, y - length, color, thickness)
		graphics.line(x + length, y, x, y + length, color, thickness)
		graphics.pop()
	end
end

function Player:on_collision_enter(other, contact)
	if other:is(Wall) and other.type.name ~= "Death" then
		self.hfx:use("hit", 0.15, 200, 10, 0.1)
		self.collided = true
		self.wall_id = other.id

		self.wall_normal = Vector(contact:getNormal())
		self.wall_normal_theta = self.wall_normal:angle()
	end
end
