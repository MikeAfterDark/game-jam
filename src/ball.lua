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
		self:set_position((self.frozen_x or self.x), (self.frozen_y or self.y))
		self:set_velocity(0, 0)
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
	if holding_handle then
		return
	end
	self.spring:pull(0.2, 500, 10)
	sfx.boop:play({ pitch = random:float(0.94, 1.14), volume = 0.5 })
	self.selected = true

	if self.mode == Ball_Interaction_Mode.Shop_Drawer then
		self.frozen_x = self.x
		self.frozen_y = self.y
	end
end

function Ball:on_mouse_stay()
	if holding_handle then
		return
	end
	self.selected = true
end

function Ball:on_mouse_exit()
	sfx.tick:play({ pitch = random:float(0.94, 1.14), volume = 0.5 })
	self.selected = false

	if self.mode == Ball_Interaction_Mode.Shop_Drawer then
		self.t:after(0.05, function()
			if not self.selected then
				self:move_towards_mouse(-200)
			end
		end)
	end
end

function Ball:trigger(events, ...)
	local results = {}
	for _, event in ipairs(#events > 0 and events or Ball_Event_Order) do
		local fn = self.type[event.id] or Ball_Defaults[event.id]
		local value = fn and (fn(self, ...) or 0) or 0
		results[#results + 1] = {
			event = event,
			value = value,
		}
	end
	return results
end

function Ball:buy_price()
	return self.type.rarity.value * (self.type.cost_mult or 1)
end

function Ball:sell_price()
	return self.type.rarity.value * (self.type.sell_mult or 1)
end

function Ball:freeze(x, y)
	self:set_velocity(0, 0)
	self:set_position(x or self.x, y or self.y)
end

function Ball:resize(new_radius)
	if not self.dead then
		local radius = new_radius * self.type.size
		self:change_circle_radius(radius)
		self.rs = radius
	end
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
		local color = self.selected and green[0] or self.is_enemy and red[0] or blue[0]

		for i = 0, sections - 1 do
			local start_angle = i * (arc_size + spacing) + math.sin(love.timer.getTime())
			local end_angle = start_angle + arc_size

			graphics.arc("open", self.x, self.y, radius, start_angle, end_angle, color, line_width)
		end
	end
	graphics.circle(self.x, self.y, self.rs, self.is_enemy and red[0] or black[0])

	if self.animation then
		local scale = 1
		self.animation:draw(self.x, self.y, self.r, scale, scale, 0, 0)
	else
		graphics.circle(self.x, self.y, self.rs * 0.80, self.color)
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
	self.t:tween(self.duration * 0.3, self, { x = x, y = y }, math.cubic_out, function()
		self.t:tween(
			self.duration * 0.6,
			self,
			{
				x = self.target.x,
				y = self.target.y,
				r = 4 * math.pi,
			},
			math.cubic_in,
			function()
				self.text.dead = true
				self.text = nil

				self.dead = true
			end
		)
	end)
end

function Text_Bubble:update(dt)
	self:update_game_object(dt)
end

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
		value = 0,
		name = "",
	},
	Common = {
		shop_odds = 1,
		value = 1,
		name = "Average",
	},
	Uncommon = {
		-- shop_odds = 0.5,
		value = 2,
		name = "Unusual",
	},
	Rare = {
		-- shop_odds = 0.25,
		value = 3,
		name = "Shiny",
	},
	Legendary = {
		-- shop_odds = 0.125,
		value = 4,
		name = "Steel",
	},
	Unique = {
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
	On_Sale = { id = "on_sale", color = "yellow" },
	On_Buy = { id = "on_buy", color = "green" },
	On_Use = { id = "on_use", color = "bg" },
	On_Consume = { id = "on_consume", color = "purple1" },
	On_Nullify_Next_Trigger = { id = "on_nullify_next_trigger", color = "bg" },
}

Ball_Event_Order = {
	Ball_Event.On_Use,
	Ball_Event.On_Score,
	Ball_Event.On_Health,
	Ball_Event.On_Armour,
	Ball_Event.On_Damage,
	Ball_Event.On_Sale,
	Ball_Event.On_Buy,
	-- Ball_Event.On_Consume, -- must be externally triggered
}
---------

Ball_Defaults = {
	on_consume = function(ball)
		ball.dead = true -- TODO: make sure this also removes references elsewere
	end,
	on_use = function(ball)
		ball.uses = ball.uses - 1
	end,
	on_score = function(ball)
		return ball.pocket.value
	end,
	on_buy = function(ball)
		return 0
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
			return 1 + math.ceil(self.pocket.value / 15)
		end,
		sprite = function() end,
	},

	-- null_ball = {
	-- 	id = "null ball",
	-- 	name = "Nulliball",
	-- 	description = "nullifies the next ball's trigger in this pocket when triggered",
	-- 	rarity = Rarity.Uncommon,
	-- 	size = 1,
	-- 	uses = 2,
	-- 	cost_mult = 2.3,
	-- 	sell_mult = 0.8,
	-- 	on_nullify_next_trigger = function(self)
	-- 		self.pocket.null_next_trigger = true -- TODO: implement this (but better)
	-- 		return 1
	-- 	end,
	-- 	sprite = function() end,
	-- },
}
