Ball = Object:extend()
Ball:implement(GameObject)
Ball:implement(Physics)
function Ball:init(args)
	self:init_game_object(args)

	self.uses = self.type.uses

	local radius = gh * 0.02
	self.rs = self.rs or self.type.size * radius

	self:set_as_circle(self.rs, "dynamic", "ball")
	self:set_velocity(random:float() * 100, random:float() * 100)

	self:set_restitution(1)
	self:set_damping(0.5)
	self:set_friction(0)

	self:set_mass(1)
	self:set_bullet(true)

	self.color = random:color()
	self.animation = self.type.animation and self.type.animation() or nil
end

function Ball:update(dt)
	self:update_game_object(dt)
	self:update_physics(dt)

	if self.animation then
		self.animation:update(dt)
	end

	if
		self.selected --
		and input.select.pressed
		and not self.is_enemy
		and self.mode == Ball_Interaction_Mode.Wheel_Selection
	then
		self.order = self.activation_source:selected_ball(self)
	end

	if self.selected and self.mode == Ball_Interaction_Mode.Shop_Drawer then
		self:set_position(self.frozen_x, self.frozen_y)
		-- self:set_velocity(0, 0)
		-- self:set_mass(10000)
	end

	if self.selected then
		main.current.hovered_ball = self
	end
end

Ball_Interaction_Mode = {
	Wheel_Selection = 1,
	Ball_Holder = 2,
	Shop_Drawer = 3,
}

function Ball:activate_mouse(source, mode)
	self.mode = mode
	self.activation_source = source
	self.interact_with_mouse = true
	self.selected = false
end

function Ball:deactivate_mouse()
	self.mode = nil
	self.activation_source = nil
	self.order = nil
	self.interact_with_mouse = false
	self.selected = false
end

function Ball:on_mouse_enter()
	self.spring:pull(0.2, 500, 10)
	sfx.boop:play({ pitch = random:float(0.94, 1.14), volume = 0.5 })
	self.selected = true

	if self.mode == Ball_Interaction_Mode.Shop_Drawer then
		self.prev_velocity_x, self.prev_velocity_y = self:get_velocity()
		-- self.prev_mass = self.mass
		self:set_velocity(0, 0)
		-- self.freeze_physics = true
		self.frozen_x = self.x
		self.frozen_y = self.y
	end
end

function Ball:on_mouse_exit()
	sfx.tick:play({ pitch = random:float(0.94, 1.14), volume = 0.5 })
	self.selected = false

	if self.mode == Ball_Interaction_Mode.Shop_Drawer then
		self:set_velocity(self.prev_velocity_x, self.prev_velocity_y)
		-- self.mass = self.prev_mass
		-- self.freeze_physics = false
	end
end

function Ball:trigger(...)
	self.uses = self.uses - 1

	local results = {}
	for _, event in ipairs(Ball_Event_Order) do
		local fn = self.type[event.id] or Ball_Defaults[event.id]
		local value = fn and (fn(self, ...) or 0) or 0
		results[#results + 1] = {
			event = event,
			value = value,
		}
	end
	return results
end

function Ball:freeze(x, y)
	self:set_velocity(0, 0)
	self:set_position(x or self.x, y or self.y)
end

function Ball:resize(new_radius)
	local radius = new_radius * self.type.size
	self:change_circle_radius(radius)
	self.rs = radius
end

function Ball:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
	-- self.shape:draw()

	if self.selected or self.order then
		local sections = self.order or 9
		local spacing = sections == 1 and 0 or self.order and math.rad(20) or math.rad(15)

		local arc_size = (2 * math.pi - sections * spacing) / sections
		local radius = self.rs + gh * 0.02
		local line_width = 6
		local color = self.order and green[0] or self.is_enemy and red[0] or blue[0]

		for i = 0, sections - 1 do
			local start_angle = i * (arc_size + spacing) + math.sin(love.timer.getTime())
			local end_angle = start_angle + arc_size

			graphics.arc("open", self.x, self.y, radius, start_angle, end_angle, color, line_width)
		end
	end
	graphics.circle(self.x, self.y, self.rs, self.is_enemy and red[0] or black[0])
	graphics.circle(self.x, self.y, self.rs * 0.70, self.color)

	if self.animation then
		self.animation:draw(self.x, self.y, self.r, 1, 1, 0, 0)
	end
	graphics.pop()
end

--
--
--
--
--
--
Text_Bubble = Object:extend()
Text_Bubble:implement(GameObject)
function Text_Bubble:init(args)
	self:init_game_object(args)

	local event = self.result.event
	self.color = event.color
	local text = "[black]" .. tostring(self.result.value)
	self.text = Text({
		{ text = text, font = small_pixul_font, alignment = "center" },
	}, global_text_tags)

	local angle = (self.iteration * 2 * math.pi / 5) + (2 * math.pi / 5)
	local initial_pop_distance = gh * 0.04
	local x = self.x + math.sin(angle) * initial_pop_distance
	local y = self.y + math.cos(angle) * initial_pop_distance
	trigger:tween(self.duration * 0.3, self, { x = x, y = y }, math.cubic_out, function()
		trigger:tween(self.duration * 0.6, self, { x = self.target.x, y = self.target.y, r = 4 * math.pi }, math
		.cubic_in, function()
			self.text.dead = true
			self.text = nil

			self.dead = true
		end)
	end)
end

function Text_Bubble:update(dt) end

function Text_Bubble:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)

	local radius = gh * 0.02
	graphics.circle(self.x, self.y, radius, black[0])
	graphics.circle(self.x, self.y, radius * 0.9, _G[self.color][5])
	if self.text then
		self.text:draw(self.x, self.y + self.text.h * 0.2, 0, 1, 1)
	end
	graphics.pop()
end

Rarity = {
	Starter = {
		shop_odds = 0,
		value = 0,
		name = "",
	},
	Common = {
		shop_odds = 1,
		value = 1,
		name = "Average",
	},
	Uncommon = {
		shop_odds = 0.5,
		value = 2,
		name = "Unusual",
	},
	Rare = {
		shop_odds = 0.25,
		value = 3,
		name = "Shiny",
	},
	Legendary = {
		shop_odds = 0.125,
		value = 4,
		name = "Steel",
	},
	Unique = {
		shop_odds = 0,
		value = 5,
		name = "Divine",
	},
}
Rarity_Ranks = {
	Rarity.Unique,
	Rarity.Legendary,
	Rarity.Rare,
	Rarity.Uncommon,
	Rarity.Common,
	Rarity.Starter,
}

--------- if adding any new ball_events make sure to add them to Ball_Event_Order
Ball_Event = {
	On_Score = { id = "on_score", color = "yellow" },
	On_Damage = { id = "on_damage", color = "red" },
	On_Health = { id = "on_health", color = "green" },
	On_Armour = { id = "on_armour", color = "blue" },
	On_Collision = { id = "on_collision", color = "purple" },
	On_Sale = { id = "on_sale", color = "yellow" },
}

Ball_Event_Order = {
	Ball_Event.On_Score,
	Ball_Event.On_Damage,
	Ball_Event.On_Health,
	Ball_Event.On_Armour,
	Ball_Event.On_Collision,
	Ball_Event.On_Sale,
}
---------

Ball_Defaults = {
	on_score = function(ball)
		return ball.pocket.value
	end,
}

Ball_Type = {

	starter_damage_ball = {
		id = "starter damage ball",
		name = "Rock",
		description = "starter rock, deals 1 damage",
		rarity = Rarity.Starter,
		size = 1,
		uses = 10,
		on_damage = function(self)
			return 1
		end,
		animation = function()
			return Animation(
				random:float(0.2, 0.4), --
				AnimationFrames(sprite.starter_rock, 16, 16, { { 1, 1 }, { 2, 1 } }),
				"loop",
				{}
			)
		end,
	},

	damage_stone = {
		id = "damage stone",
		name = "Stone",
		description = "damage stone, deals 1 + ([yellow]pocket[white]/15) damage",
		rarity = Rarity.Common,
		size = 1,
		uses = 3,
		cost_mult = 1.3,
		sell_mult = 0.5,
		on_damage = function(self)
			return 1 + math.floor(self.pocket.value / 15)
		end,
		sprite = function() end,
	},
}
