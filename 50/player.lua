require("objects")

Player = Object:extend()
Player:implement(GameObject)
Player:implement(Physics)
Player:implement(Unit)
function Player:init(args)
	self:init_game_object(args)
	self:init_unit()

	self.color = args.color or yellow[0]
	self.color_text = args.color_text or "yellow"
	self:set_as_rectangle(9, 9, "dynamic", "player")
	self.visual_shape = "rectangle"
	self.damage_dealt = 0
	self.thrust = 0
	self.dmg = 1
	self.def = 0
	self.hp = 5
	self.max_hp = 5

	self.firing = nil
	self.fireDelayCounter = 1

	self:calculate_stats(true)

	self.mouse_control_v_buffer = {}
	self.id = args.id

	if main.current:is(MainMenu) then
		self.r = random:table({ -math.pi / 4, math.pi / 4, 3 * math.pi / 4, -3 * math.pi / 4 })
		self:set_angle(self.r)
	end

	if args.tutorial then
		self.tutorial_player_indicator_text = Text2({
			group = main.current.tutorial_ui,
			x = self.x,
			y = self.y + 20,
			lines = { { text = "[" .. self.color_text .. "]player " .. tostring(self.id), font = pixul_font } },
		})
	end
end

function Player:update(dt)
	self:update_game_object(dt)

	if not main.current:is(MainMenu) then
		local x_dir, y_dir = 0, 0

		local function action(name)
			return input["p" .. self.id .. "_" .. name]
		end

		-- Get directional input
		if action("move_left").down then
			x_dir = x_dir - 1
		end
		if action("move_right").down then
			x_dir = x_dir + 1
		end
		if action("move_up").down then
			y_dir = y_dir - 1
		end
		if action("move_down").down then
			y_dir = y_dir + 1
		end

		-- Move this outside the block
		local function cross(ax, ay, bx, by)
			return ax * by - ay * bx
		end

		if x_dir ~= 0 or y_dir ~= 0 then
			-- local turn_rate = smooth_turn_speed * math.pi -- TODO: smooth turning option?
			--
			-- local function signed_angle_diff(a, b)
			-- 	local diff = a - b
			-- 	return math.atan2(math.sin(diff), math.cos(diff))
			-- end
			--
			-- local function sign(x)
			-- 	return x < 0 and -1 or 1
			-- end
			--
			local target_angle = math.atan2(y_dir, x_dir)
			-- local delta = signed_angle_diff(target_angle, self.r)
			--
			-- local max_turn = turn_rate * dt
			-- if math.abs(delta) < max_turn then
			-- 	self.r = target_angle
			-- else
			-- 	self.r = self.r + sign(delta) * max_turn
			-- end
			self.r = target_angle
		end

		if action("move_forward").pressed then
			self.thrust = 0.1
		end
		if action("move_forward").released then
			self.thrust = 0
		end
		if action("shoot").pressed then
			self.firing = love.timer.getTime()
		end
		if action("shoot").released then
			self.firing = nil
			self.fireDelayCounter = 1
		end

		-- if input.move_left.pressed and not self.move_right_pressed then
		-- 	self.move_left_pressed = love.timer.getTime()
		-- end
		-- if input.move_right.pressed and not self.move_left_pressed then
		-- 	self.move_right_pressed = love.timer.getTime()
		-- end
		-- if input.move_left.released then
		-- 	self.move_left_pressed = nil
		-- end
		-- if input.move_right.released then
		-- 	self.move_right_pressed = nil
		-- end

		-- if state.mouse_control then
		-- 	self.mouse_control_v = Vector(math.cos(self.r), math.sin(self.r))
		-- 		:perpendicular()
		-- 		:dot(Vector(math.cos(self:angle_to_mouse()), math.sin(self:angle_to_mouse())))
		--
		-- 	if math.abs(self.mouse_control_v) > 0.1 then
		-- 		self.r = self.r + math.sign(self.mouse_control_v) * turnRate * math.pi * dt
		-- 	end
		-- 	-- table.insert(self.mouse_control_v_buffer, 1, self.mouse_control_v)
		-- 	-- if #self.mouse_control_v_buffer > 64 then
		-- 	-- 	self.mouse_control_v_buffer[65] = nil
		-- 	-- end
		-- else
		-- 	if input.move_left.down then
		-- 		self.r = self.r - turnRate * math.pi * dt
		-- 	end
		-- 	if input.move_right.down then
		-- 		self.r = self.r + turnRate * math.pi * dt
		-- 	end
		-- end

		-- if input.move_forward.pressed then
		-- 	self.thrust = 0.1
		-- end
		-- if input.move_forward.released then
		-- 	self.thrust = 0
		-- end
		-- if input.shoot.pressed then
		-- 	self.firing = love.timer.getTime()
		-- end
		-- if input.shoot.released then
		-- 	self.firing = nil
		-- 	self.fireDelayCounter = 1
		-- end
		-- if input.shield.pressed then -- TODO: forcefield
		-- 	self.shielded = love.timer.getTime()
		-- end
		-- if input.shield.released then
		-- 	self.shielded = nil
		-- end
	end

	local friction = 0.974
	local total_v = self.thrust * self.max_v
	self.total_v = total_v

	local vx, vy = self:get_velocity()
	vx = vx * friction + total_v * math.cos(self.r)
	vy = vy * friction + total_v * math.sin(self.r)

	self:set_velocity(vx, vy)

	local fireDelay = { -0.0001, 0.08, 0.08, 0.15, 0.3 }
	self.fireDelayCounter = self.fireDelayCounter or 1

	if
		not main.current.won
		and not main.current.died
		and not main.current.choosing_passives
		and not main.current.paused
		and not main.current.transitioning
	then
		if self.firing ~= nil and self.firing <= love.timer.getTime() - fireDelay[self.fireDelayCounter] then
			self:shoot(self.r, {})
			self.firing = self.firing + fireDelay[self.fireDelayCounter]
			self.fireDelayCounter = self.fireDelayCounter < #fireDelay - 1 and self.fireDelayCounter + 1 or #fireDelay
		end
		if not state.no_screen_movement and false then
			local vx, vy = self:get_velocity()
			local hd = math.remap(math.abs(self.x - gw / 2), 0, 192, 1, 0)
			local vd = math.remap(math.abs(self.y - gh / 2), 0, 108, 1, 0)
			camera.x = camera.x + math.remap(vx, -100, 100, -24 * hd, 24 * hd) * dt
			camera.y = camera.y + math.remap(vy, -100, 100, -8 * vd, 8 * vd) * dt
			-- if input.move_right.down then
			-- 	camera.r = math.lerp_angle_dt(0.01, dt, camera.r, math.pi / 256)
			-- elseif input.move_left.down then
			-- 	camera.r = math.lerp_angle_dt(0.01, dt, camera.r, -math.pi / 256)
			--[[
        elseif input.move_down.down then camera.r = math.lerp_angle_dt(0.01, dt, camera.r, math.pi/256)
        elseif input.move_up.down then camera.r = math.lerp_angle_dt(0.01, dt, camera.r, -math.pi/256)
        ]]
			--
			-- else
			camera.r = math.lerp_angle_dt(0.005, dt, camera.r, 0)
			-- end
		end
	end

	self:set_angle(self.r)

	if self.tutorial_player_indicator_text ~= nil then
		self.tutorial_player_indicator_text.x = self.x
		self.tutorial_player_indicator_text.y = self.y + 16
	end
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

	local crit = 0.25
	HitCircle({
		group = main.current.effects,
		x = self.x + 0.8 * self.shape.w * math.cos(r),
		y = self.y + 0.8 * self.shape.w * math.sin(r),
		rs = 6,
	})
	local t = {
		group = main.current.main,
		x = self.x + 1.6 * self.shape.w * math.cos(r),
		y = self.y + 1.6 * self.shape.w * math.sin(r),
		v = 250,
		r = r,
		color = self.color,
		dmg = self.dmg,
		crit = crit,
		character = self.character,
		parent = self,
		level = self.level,
	}
	Projectile(table.merge(t, mods or {}))
	shoot1:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
end

function Player:on_collision_enter(other, contact)
	local x, y = contact:getPositions()

	if other:is(Wall) then
		self.hfx:use("hit", 0.15, 200, 10, 0.1)
		-- self:bounce(contact:getNormal())
	elseif table.any(main.current.enemies, function(v)
		return other:is(v)
	end) then
		other:push(random:float(25, 35) * (self.knockback_m or 1), self:angle_to_object(other))
		self:push(random:float(25, 35) * (self.knockback_m or 1), self:angle_to_object(other) + math.pi)
		-- other:hit(self.dmg)
		if other.headbutting then
			self:hit(2 * other.dmg)
			other.headbutting = false
		else
			self:hit(other.dmg)
		end
		HitCircle({ group = main.current.effects, x = x, y = y, rs = 6, color = fg[0], duration = 0.1 })
		for i = 1, 2 do
			HitParticle({ group = main.current.effects, x = x, y = y, color = self.color })
		end
		for i = 1, 2 do
			HitParticle({ group = main.current.effects, x = x, y = y, color = other.color })
		end
	end
end

function Player:push(f, r, push_invulnerable)
	local n = 1
	if self.tank then
		n = 0.7
	end
	if self.boss then
		n = 0.2
	end
	if self.level % 25 == 0 and self.boss then
		n = 0.7
	end
	self.push_invulnerable = push_invulnerable
	self.push_force = n * f
	self.being_pushed = true
	self.steering_enabled = false
	self:apply_impulse(n * f * math.cos(r), n * f * math.sin(r))
	self:apply_angular_impulse(
		random:table({ random:float(-12 * math.pi, -4 * math.pi), random:float(4 * math.pi, 12 * math.pi) })
	)
	self:set_damping(1.5 * (1 / n))
	self:set_angular_damping(1.5 * (1 / n))
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
end

function Player:hit(damage, from_undead)
	if self.dead then
		return
	end
	self.hfx:use("hit", 0.25, 200, 10)
	self:show_hp()

	local actual_damage = math.max(self:calculate_damage(damage), 0)
	self.hp = self.hp - self.max_hp / 5 --actual_damage
	_G[random:table({ "player_hit1", "player_hit2" })]:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	camera:shake(4, 0.5)
	-- main.current.damage_taken = main.current.damage_taken + actual_damage
	self.character_hp:change_hp()

	if self.hp <= 0 then
		hit4:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
		slow(0.25, 1)
		for i = 1, random:int(4, 6) do
			HitParticle({ group = main.current.effects, x = self.x, y = self.y, color = self.color })
		end
		HitCircle({ group = main.current.effects, x = self.x, y = self.y, rs = 12 })
			:scale_down(0.3)
			:change_color(0.5, self.color)
		if main.current:die() then
			self.dead = true
		end
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
	self.dmg = args.dmg
end

function Projectile:update(dt)
	self:update_game_object(dt)
	self:set_angle(self.r)
	self:move_along_angle(self.v, self.r + (self.orbit_r or 0))
	if self.x < 0 or self.x > gw or self.y < 0 or self.y > gh then
		self:die(x, y, r, 0)
	end
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
	ui_switch2:play({ pitch = random:float(0.9, 1.1), volume = 0.2 })
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
end

function Projectile:on_trigger_enter(other, contact)
	if table.any(main.current.enemies, function(v)
		return other:is(v)
	end) then
		if not (other.leader and #other.followers > 0) then
			hit1:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
		end
		if self.pierce <= 0 and self.chain <= 0 then
			self:die(self.x, self.y, nil, random:int(2, 3))
		end

		HitCircle({ group = main.current.effects, x = self.x, y = self.y, rs = 6, color = fg[0], duration = 0.1 })
		HitParticle({ group = main.current.effects, x = self.x, y = self.y, color = self.color })
		HitParticle({ group = main.current.effects, x = self.x, y = self.y, color = other.color })

		if self.knockback then
			other:push(self.knockback * (self.knockback_m or 1), self.r)
		end

		other:hit(self.dmg, self)
	end
end

function math.sign(x)
	return x > 0 and 1 or (x < 0 and -1 or 0)
end
