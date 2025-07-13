require("objects")

LongBoss = Object:extend()
LongBoss:implement(GameObject)
LongBoss:implement(Physics)
LongBoss:implement(Unit)
function LongBoss:init(args)
	self:init_game_object(args)
	self:init_unit()

	self.color = args.color or blue[5]
	self:set_as_rectangle(14, 14, "dynamic", "boss")
	self.visual_shape = "rectangle"
	self.damage_dealt = 0
	self.dmg = 1
	self.def = 0
	self.max_hp = 1
	self.hp = 1
	self.go = false

	if self.leader then
		self.pattern = "chase"
		self.target = main.current:get_random_player()

		self.rand_angle = 0
		self.invulnerable = true
		self.color = self.target.color
		self.previous_positions = {}
		self.followers = {}
		self.t:every(0.01, function()
			table.insert(self.previous_positions, 1, { x = self.x, y = self.y, r = self.r })
			if #self.previous_positions > 2528 then
				self.previous_positions[2529] = nil
			end
		end)
		self.t:every(3, function()
			self.pattern = random:table({
				"chase",
				"predict",
			})
			self.target = main.current:get_random_player()
			-- self.pattern = "predict"
		end)
	end

	self.mouse_control_v_buffer = {}
end

function LongBoss:add_follower(unit)
	table.insert(self.followers, unit)
	unit.parent = self
	unit.follower_index = #self.followers
end

function LongBoss:update(dt)
	-- if true then
	-- 	return
	-- end

	self:update_game_object(dt)
	if self.leader then
		if main.current.start_time > 0 then
			return
		end

		self.total_v = math.max(math.min(self:distance_to_object(self.target) + 20, 140), 100)

		--
		if self.pattern == "chase" then
			self:set_colors(blue[5])
			local rotation_speed = 0.4
			local target_angle = self:angle_to_object(self.target)
			local angle_diff = (target_angle - self.r + math.pi) % (2 * math.pi) - math.pi
			self.r = self.r + math.sign(angle_diff) * rotation_speed * math.pi * dt
		elseif self.pattern == "predict" then
			self:set_colors(purple[5])
			self.rand_angle = math.max(
				-math.pi / 2,
				math.min(math.pi / 2, self.rand_angle + ((random:bool(50) and 1 or -1) * math.pi * dt * 1.2))
			)
			self.r = self:angle_to_object(self.target) + self.rand_angle
		end

		if not main.current:is(MainMenu) and not main.current.transitioning then
			self:set_velocity(self.total_v * math.cos(self.r), self.total_v * math.sin(self.r))
			self:set_angle(self.r)
		end
	else
		local target_distance = 10.4 * (self.follower_index or 0)
		local distance_sum = 0
		local p
		local previous = self.parent
		for i, point in ipairs(self.parent.previous_positions) do
			local distance_to_previous = math.distance(previous.x, previous.y, point.x, point.y)
			distance_sum = distance_sum + distance_to_previous
			if distance_sum >= target_distance then
				p = self.parent.previous_positions[i - 1]
				break
			end
			previous = point
		end

		if p then
			self:set_position(p.x, p.y)
			self.r = p.r
			if not self.following then
				for i = 1, random:int(3, 4) do
					HitParticle({ group = main.current.effects, x = self.x, y = self.y, color = self.color })
				end
				HitCircle({ group = main.current.effects, x = self.x, y = self.y, rs = 10, color = fg[0] })
					:scale_down(0.3)
					:change_color(0.5, self.color)
				self.following = true
			end
		else
			self.r = self:get_angle()
		end
	end
end

function LongBoss:on_collision_enter(other, contact)
	-- local x, y = contact:getPositions()

	if other:is(Wall) then
		self.hfx:use("hit", 0.15, 200, 10, 0.1)
		self:bounce(contact:getNormal())
	end
end

function LongBoss:draw()
	graphics.push(self.x, self.y, self.r, self.hfx.hit.x * self.hfx.shoot.x, self.hfx.hit.x * self.hfx.shoot.x)
	if self.visual_shape == "rectangle" then
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
	graphics.pop()
end

function LongBoss:hit(damage, projectile, dot, from_enemy)
	if self.dead or (self.leader and #self.followers > 0) then
		return
	end
	self.hfx:use("hit", 0.25, 200, 10)
	if self.push_invulnerable then
		return
	end
	self:show_hp()

	local actual_damage = math.max(self:calculate_damage(damage) * (self.stun_dmg_m or 1), 0)
	if self.vulnerable then
		actual_damage = actual_damage * self.vulnerable
	end
	self.hp = self.hp - actual_damage
	if self.hp > self.max_hp then
		self.hp = self.max_hp
	end
	-- main.current.damage_dealt = main.current.damage_dealt + actual_damage

	if self.hp <= 0 then
		for i = 1, random:int(4, 6) do
			HitParticle({ group = main.current.effects, x = self.x, y = self.y, color = self.color })
		end
		HitCircle({ group = main.current.effects, x = self.x, y = self.y, rs = 12 })
			:scale_down(0.3)
			:change_color(0.5, self.color)

		if self.leader and #self.followers == 0 then
			self.dead = true
			slow(0.25, 1)
			_G[random:table({ "enemy_die1", "enemy_die2" })]:play({ pitch = random:float(0.9, 1.1), volume = 0.5 })
		else
			_G[random:table({ "enemy_die1", "enemy_die2" })]:play({ pitch = random:float(0.9, 1.1), volume = 0.5 })
			self.dead = true
			if self.leader then
				self:recalculate_followers()
			else
				self.parent:recalculate_followers()
			end
		end
	end
end

function LongBoss:push(f, r, push_invulnerable)
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

function LongBoss:get_all_units()
	local followers
	local leader = (self.leader and self) or self.parent
	if self.leader then
		followers = self.followers
	else
		followers = self.parent.followers
	end
	return { leader, unpack(followers) }
end

function LongBoss:set_colors(follower_color)
	local units = self:get_all_units()
	units[1].color = self.target.color --leader_color
	for i = 2, #units do
		units[i].color = follower_color
	end
end

function LongBoss:recalculate_followers()
	if self.dead then
		local new_leader = table.remove(self.followers, 1)
		new_leader.leader = true
		new_leader.previous_positions = {}
		new_leader.followers = self.followers
		new_leader.t:every(0.01, function()
			table.insert(new_leader.previous_positions, 1, { x = new_leader.x, y = new_leader.y, r = new_leader.r })
			if #new_leader.previous_positions > 256 then
				new_leader.previous_positions[257] = nil
			end
		end)
		main.current.activeBosses[1] = new_leader
		for i, follower in ipairs(self.followers) do
			follower.parent = new_leader
			follower.follower_index = i
		end
	else
		for i = #self.followers, 1, -1 do
			if self.followers[i].dead then
				table.remove(self.followers, i)
				break
			end
		end
		for i, follower in ipairs(self.followers) do
			follower.follower_index = i
		end
	end
end
