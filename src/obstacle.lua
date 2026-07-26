Obstacle = Object:extend()
Obstacle:implement(GameObject)
Obstacle:implement(Physics)
function Obstacle:init(args)
	self:init_game_object(args)

	self.r = random:float(0, 2 * math.pi)
	self:set_as_circle(self.rs, "dynamic", "obstacle")

	local target_x = gw * random:float(0.4, 0.6)
	local target_y = gh * random:float(0.4, 0.6)

	local strength = 10
	local vel_x = (target_x - self.x) * strength
	local vel_y = (target_y - self.y) * strength

	self:set_restitution(1)
	self:set_damping(0)
	self:set_friction(0)

	self:apply_impulse(vel_x, vel_y)
	self:set_mass(self.rs * self.rs)
	self:set_bullet(true)

	self.interact_with_mouse = true

	self.text = Text({
		{ --
			text = "",
			font = pixul_font,
			alignment = "center",
		},
	}, global_text_tags)
	self.animation = sprite.asteroid
	self.is_background = true
end

function Obstacle:update(dt)
	self:update_game_object(dt)
	self:update_physics(dt)
	self.animation:update(dt)

	if self.selected and input.select.pressed then
		self.time = self.time - 1
		self.spring:pull(0.05, 500, 10)
		camera:shake(2, 0.3, 120)
		self.hit = run_time
		self.mouse_x, self.mouse_y = self.group:get_mouse_position()

		if self.time >= 1 then --avoid playing the same sfx twice
			sfx.obj.asteroid_hit:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
			ScoreBubble({
				group = main.current.main,
				x = self.mouse_x,
				y = self.mouse_y,
				planet = main.current.planet,
				score = math.floor(self.value),
			})
		end
	end

	-- self.time = self.freeze_time and self.time or (self.time - dt)
	if self.time < 1 and not self.explosion_animation then
		-- self.dead = true
		self.explosion_animation = sprite.explosion()
		ScoreBubble({
			group = main.current.main,
			x = self.x,
			y = self.y,
			planet = main.current.planet,
			score = 5 * math.floor(self.value),
		})
		self:set_velocity(0, 0)
		self.fixture:setSensor(true)

		self.selected = false
		self.interact_with_mouse = false
		sfx.obj.asteroid_destroy:play({ pitch = random:float(0.95, 1.05), volume = 0.45 })
		local str = (self.rs / gh)
		camera:shake(2 + 4 * str, 0.3 + str, 120)
	end

	if self.explosion_animation then
		self.explosion_animation:update(dt)
		if self.explosion_animation.animation_logic.dead then
			self.explosion_animation.dead = true
			self.explosion_animation = nil
			self.dead = true
		end
	end

	self.text:set_text({
		{ text = string.format("[black]%d", self.time), font = huge_pixul_font, alignment = "center" },
	})
	self.text:update(dt)
end

function Obstacle:on_mouse_enter()
	self.selected = true
	random:table(sfx.ui.hover):play({ pitch = random:float(0.9, 1.2), volume = 0.45 })
	self.spring:pull(0.05, 500, 10)
end

function Obstacle:on_mouse_stay()
	self.selected = true
end

function Obstacle:on_mouse_exit()
	self.selected = false
end

function Obstacle:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)

	if not self.explosion_animation then
		graphics.circle(self.x, self.y, self.rs, black[0])
		local sprite_scale = 0.0156 * self.rs
		local b = self.is_background and 0.5 or 1
		self.animation:draw(self.x, self.y, self.r, sprite_scale, sprite_scale, 1, 1, Color(b, b, b, 1))

		local outline_color = self.selected and red[0]:clone() or black[0]:clone()
		graphics.circle(self.x, self.y, self.rs, self.is_background and outline_color:darken(0.4) or outline_color,
			self.rs * 0.08)
	else
		local explosion_scale = self.rs * 0.02
		local color = white[0]:clone():darken(0.6)
		local y = self.y
		self.explosion_animation:draw(self.x, y, 0, explosion_scale, explosion_scale, 0, 0, color)
	end
	graphics.pop()

	if not self.explosion_animation then
		self.text:draw(self.x, self.y + self.text.h / 8, 0, 1, 1)
	end

	local hit = self.hit or 0
	local hit_animation_duration = 0.15
	local hit_time = hit + hit_animation_duration
	if run_time < hit_time then
		local t = (hit_time - run_time) / (hit_time - hit)
		local size = self.rs * 0.2 * t
		graphics.circle(self.mouse_x, self.mouse_y, size, Color(1, 1, 1, t))
	end
end
