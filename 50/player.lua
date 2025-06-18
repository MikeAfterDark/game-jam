require("objects")

Player = Object:extend()
Player:implement(GameObject)
Player:implement(Physics)
Player:implement(Unit)
function Player:init(args)
	self:init_game_object(args)
	self:init_unit()

	self.color = yellow[0]
	self:set_as_rectangle(9, 9, "dynamic", "player")
	self.visual_shape = "rectangle"
	self.damage_dealt = 0

	self:calculate_stats(true)

	self.mouse_control_v_buffer = {}

	if main.current:is(MainMenu) then
		self.r = random:table({ -math.pi / 4, math.pi / 4, 3 * math.pi / 4, -3 * math.pi / 4 })
		self:set_angle(self.r)
	end
end

function Player:update(dt)
	self:update_game_object(dt)

	if self.haste then
		if self.hasted then
			self.haste_mvspd_m = math.clamp(math.remap(love.timer.getTime() - self.hasted, 0, 4, 1.5, 1), 1, 1.5)
		else
			self.haste_mvspd_m = 1
		end
	end

	if not main.current:is(MainMenu) then
		if input.move_left.pressed and not self.move_right_pressed then
			self.move_left_pressed = love.timer.getTime()
		end
		if input.move_right.pressed and not self.move_left_pressed then
			self.move_right_pressed = love.timer.getTime()
		end
		if input.move_left.released then
			self.move_left_pressed = nil
		end
		if input.move_right.released then
			self.move_right_pressed = nil
		end

		if state.mouse_control then
			self.mouse_control_v = Vector(math.cos(self.r), math.sin(self.r))
				:perpendicular()
				:dot(Vector(math.cos(self:angle_to_mouse()), math.sin(self:angle_to_mouse())))
			self.r = self.r + math.sign(self.mouse_control_v) * 1.66 * math.pi * dt
			table.insert(self.mouse_control_v_buffer, 1, self.mouse_control_v)
			if #self.mouse_control_v_buffer > 64 then
				self.mouse_control_v_buffer[65] = nil
			end
		else
			if input.move_left.down then
				self.r = self.r - 1.66 * math.pi * dt
			end
			if input.move_right.down then
				self.r = self.r + 1.66 * math.pi * dt
			end
		end
	end

	local total_v = self.max_v
	self.total_v = total_v
	self:set_velocity(total_v * math.cos(self.r), total_v * math.sin(self.r))

	if not main.current.won and not main.current.choosing_passives then
		if not state.no_screen_movement then
			local vx, vy = self:get_velocity()
			local hd = math.remap(math.abs(self.x - gw / 2), 0, 192, 1, 0)
			local vd = math.remap(math.abs(self.y - gh / 2), 0, 108, 1, 0)
			camera.x = camera.x + math.remap(vx, -100, 100, -24 * hd, 24 * hd) * dt
			camera.y = camera.y + math.remap(vy, -100, 100, -8 * vd, 8 * vd) * dt
			if input.move_right.down then
				camera.r = math.lerp_angle_dt(0.01, dt, camera.r, math.pi / 256)
			elseif input.move_left.down then
				camera.r = math.lerp_angle_dt(0.01, dt, camera.r, -math.pi / 256)
				--[[
        elseif input.move_down.down then camera.r = math.lerp_angle_dt(0.01, dt, camera.r, math.pi/256)
        elseif input.move_up.down then camera.r = math.lerp_angle_dt(0.01, dt, camera.r, -math.pi/256)
        ]]
				--
			else
				camera.r = math.lerp_angle_dt(0.005, dt, camera.r, 0)
			end
		end
	end

	self:set_angle(self.r)
end

function Player:draw()
	graphics.push(self.x, self.y, self.r, self.hfx.hit.x * self.hfx.shoot.x, self.hfx.hit.x * self.hfx.shoot.x)
	if self.visual_shape == "rectangle" then
		if self.shielded then
			graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, blue_transparent)
		else
			graphics.rectangle(
				self.x,
				self.y,
				self.shape.w,
				self.shape.h,
				3,
				3,
				(self.hfx.hit.f or self.hfx.shoot.f) and fg[0] or self.color
			)
		end

		if state.arrow_snake then
			local x, y = self.x + 0.9 * self.shape.w, self.y
			graphics.line(x + 3, y, x, y - 3, self.color, 1)
			graphics.line(x + 3, y, x, y + 3, self.color, 1)
		end
	end
	graphics.pop()
end

function Player:shoot(r, mods)
	mods = mods or {}
	camera:spring_shake(2, r)
	self.hfx:use("shoot", 0.25)
end

function Player:attack(area, mods)
	mods = mods or {}
	camera:shake(2, 0.5)
	self.hfx:use("shoot", 0.25)
	local t = {
		group = main.current.effects,
		x = mods.x or self.x,
		y = mods.y or self.y,
		r = self.r,
		w = self.area_size_m * (area or 64),
		color = self.color,
		dmg = self.area_dmg_m * self.dmg,
		character = self.character,
		level = self.level,
		parent = self,
	}
	Area(table.merge(t, mods))

	if
		self.character == "swordsman"
		or self.character == "barbarian"
		or self.character == "juggernaut"
		or self.character == "highlander"
	then
		_G[random:table({ "swordsman1", "swordsman2" })]:play({ pitch = random:float(0.9, 1.1), volume = 0.75 })
	elseif self.character == "elementor" then
		elementor1:play({ pitch = random:float(0.9, 1.1), volume = 0.5 })
	elseif self.character == "psychic" then
		psychic1:play({ pitch = random:float(0.9, 1.1), volume = 0.4 })
	elseif self.character == "launcher" then
		buff1:play({ pitch == random:float(0.9, 1.1), volume = 0.5 })
	end

	if self.character == "juggernaut" then
		elementor1:play({ pitch = random:float(0.9, 1.1), volume = 0.5 })
	end
end

--
--
--
--
Projectile = Object:extend()
Projectile:implement(GameObject)
Projectile:implement(Physics)
function Projectile:init(args)
	self:init_game_object(args)
	if not self.group.world then
		self.dead = true
		return
	end
	if tostring(self.x) == tostring(0 / 0) or tostring(self.y) == tostring(0 / 0) then
		self.dead = true
		return
	end
	self.hfx:add("hit", 1)
	self:set_as_rectangle(10, 4, "dynamic", "projectile")
	self.pierce = args.pierce or 0
	self.chain = args.chain or 0
	self.ricochet = args.ricochet or 0
	self.chain_enemies_hit = {}
	self.infused_enemies_hit = {}

	self.distance_travelled = 0
	self.distance_dmg_m = 1
end

function Projectile:update(dt)
	self:update_game_object(dt)
end

function Projectile:draw()
	graphics.push(self.x, self.y, self.r + (self.orbit_r or 0))
	graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.color)
	graphics.pop()
end

function Projectile:die(x, y, r, n)
	if self.dead then
		return
	end
	x = x or self.x
	y = y or self.y
	n = n or random:int(3, 4)
	for i = 1, n do
		HitParticle({
			group = main.current.effects,
			x = x,
			y = y,
			r = random:float(0, 2 * math.pi),
			color = self.color,
		})
	end
	HitCircle({ group = main.current.effects, x = x, y = y }):scale_down()
	self.dead = true
end

function Projectile:on_collision_enter(other, contact)
	local x, y = contact:getPositions()
	local nx, ny = contact:getNormal()
	local r = 0
	if nx == 0 and ny == -1 then
		r = -math.pi / 2
	elseif nx == 0 and ny == 1 then
		r = math.pi / 2
	elseif nx == -1 and ny == 0 then
		r = math.pi
	else
		r = 0
	end

	if other:is(Wall) then
		self:die(x, y, r, random:int(2, 3))
		proj_hit_wall1:play({ pitch = random:float(0.9, 1.1), volume = 0.2 })
	end
	-- TODO: else if outside of bounds
end
