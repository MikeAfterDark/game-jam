Ball = Object:extend()
Ball:implement(GameObject)
Ball:implement(Physics)
function Ball:init(args)
	self:init_game_object(args)

	self.uses = self.type.uses

	self:set_as_circle(self.r, "dynamic", "ball")
	self:set_velocity(random:float() * 100, random:float() * 100)

	self:set_restitution(1)
	self:set_damping(0.5)
	self:set_friction(0)

	self:set_mass(1)

	self.color = random:color()
	self.animation = self.type.animation and self.type.animation() or nil
end

function Ball:update(dt)
	self:update_game_object(dt)
	self:update_physics(dt)

	if self.animation then
		self.animation:update(dt)
	end
end

function Ball:trigger(...)
	self.uses = self.uses - 1

	local results = {}
	for i, event in ipairs(Ball_Event) do
		local fn = self.type[event] or Ball_Defaults[event]
		local value = fn and (fn(self, ...) or 0) or 0
		table.insert(results, { event = event, value = value })
	end
	return results
end

function Ball:freeze(x, y)
	self:set_velocity(0, 0)
	self:set_position(x or self.x, y or self.y)
end

function Ball:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
	-- self.shape:draw()
	graphics.circle(self.x, self.y, self.r, self.is_enemy and red[0] or black[0])
	graphics.circle(self.x, self.y, self.r * 0.70, self.color)

	if self.animation then
		self.animation:draw(self.x, self.y, self.r, 1, 1, 0, 0)
	end
	graphics.pop()
end

Text_Bubble = Object:extend()
Text_Bubble:implement(GameObject)
function Text_Bubble:init(args)
	self:init_game_object(args)

	local event = self.result.event
	self.color = event == "on_score" and "yellow" --
		or event == "on_damage" and "red"
		or event == "on_health" and "green"
		or event == "on_armour" and "blue"
	local text = "[black]" .. tostring(self.result.value)
	self.text = Text({
		{ text = text, font = small_pixul_font, alignment = "center" },
	}, global_text_tags)

	local angle = (self.iteration * 2 * math.pi / 5) + (2 * math.pi / 5)
	local initial_pop_distance = gh * 0.04
	local x = self.x + math.sin(angle) * initial_pop_distance
	local y = self.y + math.cos(angle) * initial_pop_distance
	trigger:tween(self.duration * 0.3, self, { x = x, y = y }, math.cubic_out, function()
		trigger:tween(self.duration * 0.6, self, { x = self.target.x, y = self.target.y, r = 4 * math.pi }, math.cubic_in, function()
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
	Starter = { value = 0, name = "" },
	Common = { value = 1, name = "" },
	Uncommmon = { value = 2, name = "Unusual" },
	Rare = { value = 3, name = "Shiny" },
	Legendary = { value = 4, name = "Steel" },
	Unique = { value = 5, name = "Divine" },
}

Ball_Event = {
	"on_score",
	"on_damage",
	"on_health",
	"on_armour",
	"on_collision",
}

Ball_Defaults = {
	on_score = function(ball)
		return ball.pocket.value
	end,
}

Ball_Type = {

	starter_damage_ball = {
		id = "starter damage ball",
		name = "Rock",
		description = "starter rock, deals # damage",
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
		description = "damage stone, deals # damage",
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
