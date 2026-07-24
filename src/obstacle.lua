Obstacle = Object:extend()
Obstacle:implement(GameObject)
Obstacle:implement(Physics)
function Obstacle:init(args)
	self:init_game_object(args)

	self.r = random:float(0, 2 * math.pi)
	self:set_as_circle(self.rs, "dynamic", "obstacle")

	local target_x = gw * random:float(0.4, 0.6)
	local target_y = gh * random:float(0.4, 0.6)

	local strength = 5
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
end

function Obstacle:update(dt)
	self:update_game_object(dt)
	self:update_physics(dt)
	self.animation:update(dt)

	if self.selected and input.select.pressed then
		self.time = self.time - 1
		self.hit = run_time
		self.spring:pull(0.05, 500, 10)
		camera:shake(2, 0.3, 120)
		self.mouse_x, self.mouse_y = self.group:get_mouse_position()
		sfx.obj.asteroid_destroy:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	end

	self.time = self.freeze_time and self.time or (self.time - dt)
	if self.time < 1 then
		self.dead = true
		sfx.obj.asteroid_destroy:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	end

	self.text:set_text({
		{ text = string.format("[black]%d", self.time), font = huge_pixul_font, alignment = "center" },
	})
	self.text:update(dt)
end

function Obstacle:on_mouse_enter()
	self.selected = true
	random:table(sfx.ui.hover):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	self.spring:pull(0.05, 500, 10)
end

function Obstacle:on_mouse_stay()
	self.selected = true
end

function Obstacle:on_mouse_exit()
	self.selected = false
end

function Obstacle:draw()
	graphics.circle(self.x, self.y, self.rs, black[0])

	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
	local sprite_scale = 0.0156 * self.rs
	self.animation:draw(self.x, self.y, self.r, sprite_scale, sprite_scale, 1, 1)

	graphics.circle(self.x, self.y, self.rs, self.selected and red[0] or black[0], self.rs * 0.08)
	graphics.pop()

	self.text:draw(self.x, self.y + self.text.h / 8, 0, 1, 1)

	local hit = self.hit or 0
	local hit_animation_duration = 0.15
	local hit_time = hit + hit_animation_duration
	if run_time < hit_time then
		local t = (hit_time - run_time) / (hit_time - hit)
		local size = self.rs * 0.2 * t
		graphics.circle(self.mouse_x, self.mouse_y, size, Color(1, 1, 1, t))
	end
end
