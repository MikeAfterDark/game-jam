wall_type = {
	Sticky = {
		name = "Sticky",
		color = "green",

		_particle_drip_settings = {
			spawn_rate = 0.5,
			lifetime = 1.1,
			speed_min = 00,
			speed_max = 00,
			spread = 0.0,
			gravity = 50,
			radius_min = 5,
			radius_max = 7,
			color = Color(0, 1, 0, 1),
		},

		_particle_impact_settings = {
			count = 12,
			lifetime = 0.5,
			speed_min = 150,
			speed_max = 200,
			spread = 1,
			gravity = 600,
			radius_min = 6,
			radius_max = 6,
			color = Color(0, 1, 0, 1),
		},

		collision_behavior = function(other, contact, self)
			local normal = Vector(contact:getNormal())
			local pos = Vector(contact:getPositions())

			other:set_velocity(0, 0)

			self._particles = self._particles or {}
			local settings = self.type._particle_impact_settings

			for i = 1, settings.count do
				local angle = normal:angle() + (math.random() - 0.5) * settings.spread
				local speed = math.random(settings.speed_min, settings.speed_max)
				local dx = math.cos(angle) * speed
				local dy = math.sin(angle) * speed

				table.insert(self._particles, {
					pos = pos:clone(),
					dx = dx,
					dy = dy,
					lifetime = settings.lifetime,
					spawn_time = love.timer.getTime(),
					radius = math.random(settings.radius_min, settings.radius_max),
					from_impact = true,
				})
			end
		end,
		draw = function(self)
			self.shape:draw(self.color, 10)

			self._particles = self._particles or {}
			local drip_settings = self.type._particle_drip_settings
			local now = love.timer.getTime()
			local dt = love.timer.getDelta()
			local verts = self.shape.vertices

			-- === SPAWN dripping slime ===
			local spawn_rate = drip_settings.spawn_rate
			for i = 1, #verts - 3, 2 do
				local x1, y1 = verts[i], verts[i + 1]
				local x2, y2 = verts[i + 2], verts[i + 3]

				local dx, dy = x2 - x1, y2 - y1
				local seg_len = math.sqrt(dx * dx + dy * dy)
				local seg_spawn_chance = (spawn_rate * seg_len / 100) * dt

				if math.random() < seg_spawn_chance then
					local t = math.random()
					local sx = x1 + dx * t
					local sy = y1 + dy * t

					local angle = math.pi / 2 + (math.random() - 0.5) * drip_settings.spread
					local speed = math.random(drip_settings.speed_min, drip_settings.speed_max)

					table.insert(self._particles, {
						pos = Vector(sx, sy),
						dx = math.cos(angle) * speed,
						dy = math.sin(angle) * speed,
						radius = math.random(drip_settings.radius_min, drip_settings.radius_max),
						spawn_time = now,
						lifetime = drip_settings.lifetime,
						from_impact = false,
					})
				end
			end

			-- === UPDATE + DRAW particles ===
			for i = #self._particles, 1, -1 do
				local p = self._particles[i]
				local age = now - p.spawn_time
				local settings = p.from_impact and self.type._particle_impact_settings or drip_settings

				if age > p.lifetime then
					table.remove(self._particles, i)
				else
					local t = age / p.lifetime
					local fade_in = math.cubic_out(math.min(t * 2, 1)) -- fade in first 0.5 of life
					local fade_out = math.cubic_out(1 - t)
					local alpha = fade_in * fade_out

					p.dy = p.dy + settings.gravity * dt
					p.pos.x = p.pos.x + p.dx * dt
					p.pos.y = p.pos.y + p.dy * dt

					local color = settings.color:clone()
					color.a = color.a * alpha

					graphics.circle(p.pos.x, p.pos.y, p.radius, color)
				end
			end
		end,
	},
	Icy = {
		name = "Icy",
		color = "blue",
		collision_behavior = function(other, contact)
			local normal = Vector(contact:getNormal())
			local velocity = Vector(other:get_velocity())

			local dir = velocity:normalize()
			local dot = dir:dot(normal)

			if dot < -0.99 then
				other:set_velocity(0, 0)
				return
			end

			local t1 = Vector(-normal.y, normal.x)
			local t2 = Vector(normal.y, -normal.x)
			local new_dir = (dir:dot(t1) > dir:dot(t2)) and t1 or t2
			new_dir = new_dir:scale(other.speed)

			other:set_velocity(new_dir:unpack())
		end,
		draw = function(self)
			self.shape:draw(self.color, 10)

			local verts = self.shape.vertices
			self._snowflakes = self._snowflakes or {}

			local now = love.timer.getTime()

			local spawn_rate = 5 -- flakes per second
			local flake_lifetime = 1 -- seconds
			local flake_radius = 3 -- pixels
			local fall_speed_min = 10 -- px/sec
			local fall_speed_max = 30 -- px/sec
			local jitter = 5 -- horizontal movement range
			local spawn_chance = spawn_rate * love.timer.getDelta()

			for i = 1, #verts - 3, 2 do
				local x1, y1 = verts[i], verts[i + 1]
				local x2, y2 = verts[i + 2], verts[i + 3]

				local dx, dy = x2 - x1, y2 - y1
				local seg_len = math.sqrt(dx * dx + dy * dy)
				local seg_spawn_chance = (spawn_rate * seg_len / 100) * love.timer.getDelta()

				if math.random() < seg_spawn_chance then
					local t = math.random()
					local sx = x1 + (x2 - x1) * t
					local sy = y1 + (y2 - y1) * t

					local flake = {
						x = sx,
						y = sy,
						spawn_time = now,
						lifetime = flake_lifetime,
						speed = math.random(fall_speed_min, fall_speed_max),
						offset = math.random() * math.pi * 2,
					}
					table.insert(self._snowflakes, flake)
				end
			end

			local dt = love.timer.getDelta()
			for i = #self._snowflakes, 1, -1 do
				local f = self._snowflakes[i]
				local age = now - f.spawn_time

				if age > f.lifetime then
					table.remove(self._snowflakes, i)
				else
					local sway = math.sin(now * 2 + f.offset) * jitter
					f.y = f.y + f.speed * dt

					local t = math.quart_in_out(age / f.lifetime)
					local alpha = 1 - t
					graphics.circle(f.x + sway, f.y, flake_radius, Color(1, 1, 1, alpha))
				end
			end
		end,
	},
	Bounce = {
		name = "Bounce",
		color = "purple",
		collision_behavior = function(other, contact, self)
			local normal = Vector(contact:getNormal())
			local velocity = Vector(other:get_velocity()):normalize():scale(other.speed)

			local reflection = velocity:sub(normal:scale(2 * (velocity:dot(normal))))
			other:set_velocity(reflection:unpack())

			self.last_bounce = love.timer.getTime()
			self.bounce_amp = math.min(1 + (self.bounce_amp or 0.5), 1.8)
		end,
		draw = function(self)
			local verts = self.shape.vertices
			local now = love.timer.getTime()

			self.bounce_amp = self.bounce_amp or 0
			self.last_bounce = self.last_bounce or 0

			local bounce_time = now - self.last_bounce
			local decay = math.exp(-bounce_time * 4)
			local amp = self.bounce_amp * decay

			if amp < 0.01 then
				self.bounce_amp = 0
			end

			for i = 1, #verts - 3, 2 do
				local x1, y1 = verts[i], verts[i + 1]
				local x2, y2 = verts[i + 2], verts[i + 3]

				local dx, dy = x2 - x1, y2 - y1
				local len = math.sqrt(dx * dx + dy * dy)
				local nx, ny = -dy / len, dx / len

				local sway_phase = now * 3 + i
				local idle_sway = math.sin(sway_phase) * 5
				local bounce = math.sin(now * 20) * amp * 10
				local offset = idle_sway + bounce

				local ox, oy = nx * offset, ny * offset
				local mx, my = (x1 + x2) / 2 + ox, (y1 + y2) / 2 + oy

				local color = Color(1, 1, 1, 1):lerp(self.color, math.expo_in, decay)
				graphics.line(x1, y1, mx, my, color, 10)
				graphics.line(mx, my, x2, y2, color, 10)
			end
		end,
	},
	Clone = {
		name = "Clone",
		color = "yellow2",
		collision_behavior = function(other, contact, self)
			other:set_velocity(0, 0)
			if self.already_cloned then
				return
			end

			self.already_cloned = true
			self.color = fg_alt[0]
			self.init_color = fg_alt[0]

			local normal = Vector(contact:getNormal())
			local position = Vector(contact:getPositions())
			local x, y = position:sub(normal:scale(other.size + 1)):unpack()

			main.current.spawn = { -- goes to game.lua to be spawned on next update iteration
				x = x, --
				y = y,
				vx = 0,
				vy = 0,
				size = other.size,
				color = other.color,
				speed = other.speed,
				init_wall_normal = Vector(contact:getNormal()):scale(-1),
			}
		end,
		draw = function(self)
			self.shape:draw(self.color, 10)
		end,
	},
	Shrink = {
		name = "Shrink",
		color = "white",
		collision_behavior = function(other, contact, self)
			other:set_velocity(0, 0)
			if other.size <= min_player_size or other.wall_id == self.id then
				return
			end

			local scale = 8
			other.size_change = other.size - scale
			other:set_velocity(0, 0)
		end,
		draw = function(self)
			self.shape:draw(self.color, 10)

			local verts = self.shape.vertices
			self._shrink_particles = self._shrink_particles or {}

			local now = love.timer.getTime()
			local dt = love.timer.getDelta()

			local spawn_rate = 5 -- particles/sec per 100px
			local lifetime = 1.2
			local radius = 6
			local offset_distance = 25 -- distance from wall to spawn
			local min_speed = 20
			local max_speed = 45

			for i = 1, #verts - 3, 2 do
				local x1, y1 = verts[i], verts[i + 1]
				local x2, y2 = verts[i + 2], verts[i + 3]
				local dx, dy = x2 - x1, y2 - y1
				local len = math.sqrt(dx * dx + dy * dy)

				if len > 0 then
					local seg_spawn_chance = (spawn_rate * len / 100) * dt
					if math.random() < seg_spawn_chance then
						local t = math.random()
						local base_x = x1 + dx * t
						local base_y = y1 + dy * t

						local nx, ny = dy / len, -dx / len
						local dir = (math.random() < 0.5) and -1 or 1

						local spawn_x = base_x + nx * dir * offset_distance
						local spawn_y = base_y + ny * dir * offset_distance

						table.insert(self._shrink_particles, {
							x = spawn_x,
							y = spawn_y,
							tx = base_x,
							ty = base_y,
							speed = math.random(min_speed, max_speed),
							spawn_time = now,
							lifetime = lifetime,
						})
					end
				end
			end

			for i = #self._shrink_particles, 1, -1 do
				local p = self._shrink_particles[i]
				local age = now - p.spawn_time

				if age > p.lifetime then
					table.remove(self._shrink_particles, i)
				else
					local t = age / p.lifetime
					local alpha = math.sin(math.pi * t)

					local dx = p.tx - p.x
					local dy = p.ty - p.y
					local x = p.x + dx * (age / p.lifetime)
					local y = p.y + dy * (age / p.lifetime)

					local color = _G["white"][0]:clone()
					color.a = alpha
					graphics.circle(x, y, radius * t, color)
				end
			end
		end,
	},
	Grow = {
		name = "Grow",
		color = "white",
		collision_behavior = function(other, contact, self)
			other:set_velocity(0, 0)
			if other.size >= max_player_size or other.wall_id == self.id then
				return
			end

			local scale = 8
			other.size_change = other.size + scale
			-- other.shape.rs = other.shape.rs + scale
		end,
		draw = function(self)
			self.shape:draw(self.color, 10)

			local verts = self.shape.vertices
			self._grow_particles = self._grow_particles or {}

			local now = love.timer.getTime()
			local dt = love.timer.getDelta()

			local spawn_rate = 5 -- particles/sec per 100px
			local lifetime = 1.2
			local radius = 10
			local jitter = 6
			local min_speed = 20
			local max_speed = 25

			for i = 1, #verts - 3, 2 do
				local x1, y1 = verts[i], verts[i + 1]
				local x2, y2 = verts[i + 2], verts[i + 3]
				local dx, dy = x2 - x1, y2 - y1
				local len = math.sqrt(dx * dx + dy * dy)

				if len > 0 then
					local seg_spawn_chance = (spawn_rate * len / 100) * dt
					if math.random() < seg_spawn_chance then
						local t = math.random()
						local px = x1 + dx * t
						local py = y1 + dy * t

						local nx, ny = dy / len, -dx / len
						local dir = (math.random() < 0.5) and -1 or 1

						table.insert(self._grow_particles, {
							x = px,
							y = py,
							nx = nx * dir,
							ny = ny * dir,
							speed = math.random(min_speed, max_speed),
							spawn_time = now,
							lifetime = lifetime,
						})
					end
				end
			end

			for i = #self._grow_particles, 1, -1 do
				local p = self._grow_particles[i]
				local age = now - p.spawn_time

				if age > p.lifetime then
					table.remove(self._grow_particles, i)
				else
					local t = age / p.lifetime
					local alpha = math.sin(math.pi * t)
					local x = p.x + p.nx * p.speed * age
					local y = p.y + p.ny * p.speed * age

					local color = _G["white"][0]:clone()
					color.a = alpha
					graphics.circle(x, y, radius * (1 - t), color)
				end
			end
		end,
	},

	Death = {
		name = "Death",
		color = "black",
		collision_behavior = function(other)
			death_flash_alpha = 1.00 -- immediate flash value
			trigger:tween(1.4, _G, { death_flash_alpha = 0 }, math.cubic_out, nil, "death_flash")
			enemy_die1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

			other:set_velocity(0, 0)
			other:spawn_player()
		end,
		draw = function(self)
			self.shape:draw(self.color, 10)
		end,
	},
	Goal = {
		name = "Goal",
		color = "yellow",
		collision_behavior = function(other)
			other:set_velocity(0, 0)

			main.current.win = true
		end,
		draw = function(self)
			local verts = self.shape.vertices
			local tile_size = 15 -- how long each checker segment is
			local width = self.max_width or 10
			local color1 = self.color
			local color2 = Color(0, 0, 0, 1)

			for i = 1, #verts - 3, 2 do
				local x1, y1 = verts[i], verts[i + 1]
				local x2, y2 = verts[i + 2], verts[i + 3]

				local dx, dy = x2 - x1, y2 - y1
				local length = math.sqrt(dx * dx + dy * dy)
				local angle = math.atan2(dy, dx)
				local segments = math.floor(length / tile_size)

				for j = 0, segments - 1 do
					local t1 = j / segments
					local t2 = (j + 1) / segments

					local sx1 = x1 + dx * t1
					local sy1 = y1 + dy * t1
					local sx2 = x1 + dx * t2
					local sy2 = y1 + dy * t2

					local mx = sy2 - sy1
					local my = sx1 - sx2
					local mag = math.sqrt(mx * mx + my * my)
					if mag > 0 then
						mx, my = (mx / mag) * width / 2, (my / mag) * width / 2
					end

					local quad = {
						sx1 - mx,
						sy1 - my,
						sx2 - mx,
						sy2 - my,
						sx2 + mx,
						sy2 + my,
						sx1 + mx,
						sy1 + my,
					}

					local color = (j % 2 == 0) and color1 or color2
					graphics.polygon(quad, color)
				end
			end
		end,
	},
	Empty = {
		name = "Empty",
		color = "purple",
		collision_behavior = function() end,
		draw = function(self) end,
	},
}
wall_type_order = { "Sticky", "Icy", "Bounce", "Clone", "Shrink", "Grow", "Death", "Goal", "Empty" } -- NOTE: a shitty way for creator mode to choose a wall

Wall = Object:extend()
Wall:implement(GameObject)
Wall:implement(Physics)
function Wall:init(args)
	self:init_game_object(args)

	self:set_as_chain(self.loop, self.vertices, "static", "wall")
	self.interact_with_mouse = true

	self.color = self.color or _G[self.type.color][0] or fg[0]
	self.init_color = self.color
	self.hovered_color = red[0]

	self.center_x = 0
	self.center_y = 0
	for i = 1, #self.vertices, 2 do
		local x = self.vertices[i]
		local y = self.vertices[i + 1]
		self.center_x = self.center_x + x
		self.center_y = self.center_y + y
	end
	self.center_x = self.center_x / (#self.vertices / 2)
	self.center_y = self.center_y / (#self.vertices / 2)

	local mouse_x, mouse_y = main.current.main:get_mouse_position()
	self.mouse_circle = Circle(mouse_x, mouse_y, 5)
end

function Wall:update(dt)
	self:update_game_object(dt)
	self:check_mouse_collision()

	if main.current.creator_mode and (self.circle_colliding_with_mouse or self.colliding_with_mouse) then
		if input.m2.pressed then
			self.dead = true
		end

		if input.m1.pressed and main.current.selection > 0 then
			self.type = wall_type[wall_type_order[main.current.selection]]
			self.color = _G[self.type.color][0] or fg[0]
			self.init_color = self.color

			self.already_cloned = nil -- NOTE: jank setting for resetting clone-edge
		end
	end
end

function Wall:draw()
	graphics.push(self.center_x, self.center_y, 0, self.spring.x, self.spring.y)
	self.type.draw(self)
	graphics.pop()
end

function Wall:on_collision_enter(other, contact)
	if other:is(Player) then
		self.type.collision_behavior(other, contact, self)
	end
end

--
-- mouse stuffs
--
function Wall:on_mouse_enter()
	if main.current.paused or not main.current.creator_mode then
		return
	end

	-- buttonHover:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

	self.spring:pull(0.01, 200, 10)
	self.init_color = self.color
	self.color = self.hovered_color
end

function Wall:on_mouse_exit()
	self.color = self.init_color
end

function Wall:check_mouse_collision()
	local mouse_x, mouse_y = main.current.main:get_mouse_position()
	self.mouse_circle.x = mouse_x
	self.mouse_circle.y = mouse_y

	local colliding_with_mouse = self.shape:is_colliding_with_circle(self.mouse_circle)
	if colliding_with_mouse and not self.circle_colliding_with_mouse then
		self.circle_colliding_with_mouse = true
		if self.on_mouse_enter then
			self:on_mouse_enter()
		end
	elseif not colliding_with_mouse and self.circle_colliding_with_mouse then
		self.circle_colliding_with_mouse = false
		if self.on_mouse_exit then
			self:on_mouse_exit()
		end
	end
	if self.circle_colliding_with_mouse then
		if self.on_mouse_stay then
			self:on_mouse_stay()
		end
	end
end
