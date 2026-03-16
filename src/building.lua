Building_Type = {
	Castle = {
		name = "castle",
		sprites = function()
			return building_sprites.castle
		end,
		rules = {
			placement = {
				{ type = "on_solid_tile" },
				{
					type = "on_any_tile_type",
					values = { "grass", "stone" },
				},
				{ type = "no_adjacent_buildings" },
				{
					type = "not_on_any_of_tile_type",
					values = { "sand", "swamp" },
				},
			},
			bonus = {
				{
					type = "on_solid_tile",
					effects = { gold = 3, people = 1 },
				},
				{
					type = "no_adjacent_buildings",
					effects = { gold = 5 },
				},
			},
			survival = {
				{ type = "on_solid_tile" },
			},
		},
	},
	Dwelling = {
		name = "dwelling",
		sprites = function()
			return building_sprites.dwelling
		end,
		rules = {
			placement = {
				{ type = "on_solid_tile" },
			},
			bonus = {},
			survival = {
				{ type = "on_solid_tile" },
			},
		},
	},
	Farm = {
		name = "farm",
		sprites = function()
			return building_sprites.farm
		end,
		rules = {
			placement = {
				{ type = "on_solid_tile" },
				{ type = "on_any_tile_type", values = { "grass", "blue grass" } },
				-- { type = "on_tile_with_any_trait", values = { "biology", "wet" } },
				-- { type = "on_tile_with_none of_traits", values = { "dry", "cold" } },
			},
			bonus = {},
			survival = {
				{ type = "on_solid_tile" },
			},
		},
	},
	Market = {
		name = "market",
		sprites = function()
			return building_sprites.market
		end,
		rules = {
			placement = {
				{ type = "on_solid_tile" },
			},
			bonus = {},
			survival = {
				{ type = "on_solid_tile" },
			},
		},
	},
	Necromancer = {
		name = "necromancer",
		sprites = function()
			return building_sprites.necromancer
		end,
		rules = {
			placement = {
				{ type = "on_solid_tile" },
			},
			bonus = {},
			survival = {
				{ type = "on_solid_tile" },
			},
		},
	},
	Ship = {
		name = "ship",
		sprites = function()
			return building_sprites.ship
		end,
		rules = {
			placement = {
				{ type = "on_solid_tile" },
			},
			bonus = {},
			survival = {
				{ type = "on_solid_tile" },
			},
		},
	},
	Tent = {
		name = "goblin's tent",
		sprites = function()
			return building_sprites.tent
		end,
		rules = {
			placement = {
				{ type = "on_solid_tile" },
			},
			bonus = {},
			survival = {
				{ type = "on_solid_tile" },
			},
		},
	},
}

-- Legend:
-- "Adjacent": 3x3 tiles excluding the center
RuleLogic = {
	-- { type = "on_solid_tile" },
	on_solid_tile = function(context, rule)
		local error = context.tile.type.name .. " tile isn't solid"
		return table.contains(context.tile.type.traits, "solid") ~= nil, error
	end,

	-- on_tile_with_any_of_trait = function(context, rule)
	-- 	local error = context.tile.type.name ..
	-- 		" tile doesn't have any one trait from: " .. table.concat(rule.values, ", ")
	-- 	return table.contains(context.tile.type.traits,) ~= nil, error
	-- end,

	-- { type = "on_any_of_tile_type",     values = { "grass", "stone" } },
	on_any_tile_type = function(context, rule)
		local error = context.tile.type.name .. " tile is not any one of: " .. table.concat(rule.values, ", ")
		return table.contains(rule.values, context.tile.type.name) ~= nil, error
	end,

	-- { type = "not_on_any_of_tile_type", values = { "sand", "swamp" } },
	not_on_any_of_tile_type = function(context, rule)
		local error = "cannot place on any of: " .. table.concat(rule.values, ", ")
		return table.contains(rule.values, context.tile.type.name) == nil, error
	end,

	-- { type = "no_adjacent_buildings" },
	no_adjacent_buildings = function(context, rule)
		local error = "needs to have no adjacent buildings"
		for _, tile in ipairs(context.adjacent_tiles) do
			if tile.holding and tile.holding ~= context.building then
				return false, error .. ", has a " .. tile.holding.type.name
			end
		end
		return true, error
	end,

	-- { type = "adjacent_to_any_building_of_type", values = { "castle", "farm" } },
	adjacent_to_any_building_of_type = function(context, rule)
		local error = "needs to be adjacent to any building of type: " .. table.concat(rule.values, ", ")
		for _, tile in ipairs(context.adjacent_tiles) do
			if tile.holding and table.contains(rule.values, tile.holding.name) then
				return true, error
			end
		end
		return false, error
	end,

	-- { type = "adjacent_to_building_of_type", values = { "tent", "farm" } },
	adjacent_to_building_of_type = function(context, rule)
		local found = {}
		for _, tile in ipairs(context.adjacent_tiles) do
			if tile.holding then
				found[tile.holding.name] = true
			end
		end

		local missing = {}
		for _, required in ipairs(rule.values) do
			if not found[required] then
				table.insert(missing, required)
			end
		end

		local error = "needs to be adjacent to the building" --
				.. #missing > 1 and "s" .. ": " .. table.concat(missing, ", ")
		return #missing == 0, error
	end,

	-- { type = "adjacent_to_any_tile_of_type", values = { "grass", "swamp" } },
	adjacent_to_any_tile_of_type = function(context, rule)
		local error = "needs to be adjacent to any tile of type: " .. table.concat(rule.values, ", ")
		for _, tile in ipairs(context.adjacent_tiles) do
			if table.contains(rule.values, tile.type.name) then
				return true, error
			end
		end
		return false, error
	end,

	-- { type = "adjacent_to_tile_of_type", values = { "grass", "swamp" } },
	adjacent_to_tile_of_type = function(context, rule)
		local found = {}
		for _, tile in ipairs(context.adjacent_tiles) do
			if tile.holding then
				found[tile.holding.name] = true
			end
		end

		local missing = {}
		for _, required in ipairs(rule.values) do
			if not found[required] then
				table.insert(missing, required)
			end
		end

		local error = "needs to be adjacent to the tile" .. #missing > 1 and "s" .. ": " .. table.concat(missing, ", ")
		return #missing == 0, error
	end,
}

Building = Object:extend()
Building:implement(GameObject)
function Building:init(args)
	self:init_game_object(args)
	self.vertical_offset = 0 -- WARN: HARDCODED OFFSET to make the buildings like like they're sitting 'on' their surface
	self.y = self.y + self.vertical_offset

	self.shape = Circle(self.x, self.y, self.size)
	self.interact_with_mouse = true
	self.selected = false
	self.origin = { x = self.x, y = self.y }

	self.opacity = 1
	self.type = self.type or random:table(Building_Type)
	self.spring:pull(0.15, 400, 32)
	-- [SFX]

	self.people_slider = Circle_Slider({
		-- group = main.current.ui,
		layer = self.layer,
		x = self.x,
		y = self.y,
		size = self.size * 5,
		rotation = math.pi / 2,
		value = 0,
		min_value = 0,
		max_value = 20,
		text = { description = "People:" },
		action = function(p)
			self:assign_people(p)
		end,
	})

	self.people_assigned_text = Text({
		{
			text = "",
			font = small_pixul_font,
		},
	}, global_text_tags)
end

function Building:assign_people(p)
	print("assigned " .. p .. " people")
	self.people = p
	self.people_assigned_text:set_text({ { text = "[green]" .. tostring(self.people), font = small_pixul_font } })
end

function Building:update(dt)
	self:update_game_object(dt)

	if self.selected and input.select.pressed then
		game_mouse.holding = self
	end

	-- self.people_assigned_text:update(dt)
	if self.people_slider then
		self.people_slider.shape:move_to(self.x, self.y)
		self.people_slider.x = self.x
		self.people_slider.y = self.y
		if self.tile and self.selected and input.modify.pressed then
			self.people_slider:expand(true)
		end

		-- if self.opacity < 1 then
		-- 	self.people_slider:expand(false)
		-- end
		self.people_slider:update(dt)
	end
end

function Building:return_to_origin()
	trigger:tween(0.3, self, { x = self.origin.x, y = self.origin.y }, math.cubic_in_out)
end

function Building:place_on(tile)
	local new_x, new_y = tile.x, tile.y + self.vertical_offset
	self.origin = { x = new_x, y = new_y }
	self.shape:move_to(new_x, new_y)
	trigger:tween(0.1, self, { x = new_x, y = new_y }, math.cubic_in_out)

	if self.tile then
		self.tile.holding = nil -- for if moving from tile to tile
	end
	self.tile = tile
end

-- required context:
-- - tile to be placed on
--
-- returns bool, table of errors
function Building:is_valid_placement(context)
	context.building = self

	local errors = {}
	for _, rule in ipairs(self.type.rules.placement) do
		local passed, error = RuleLogic[rule.type](context, rule)
		if not passed then
			table.insert(errors, error)
		end
	end
	return #errors == 0, errors
end

function Building:apply(context, on_complete)
	local results = {}
	if self.type.rules[context.stage] then
		-- print("applying:", context.stage, self.type.name)

		for _, rule in ipairs(self.type.rules[context.stage]) do
			local passed, error = RuleLogic[rule.type](context, rule)
			table.insert(results, { success = passed, error = error, effects = rule.effects })
		end
	end
	return results
end

function Building:can_survive(conditions)
	-- check if can be placed on tile, and if can survive the conditions in effects
	--
	-- { tile = self, effects = args.effects })
	conditions.building = self

	local errors = {}
	for _, rule in ipairs(self.type.rules.survival) do
		local passed, error = RuleLogic[rule.type](conditions, rule)
		if not passed then
			table.insert(errors, error)
		end
	end

	if #errors == 0 or true then
		self:bounce(40, 0.3)
	end
	return true -- #errors == 0, errors
end

function Building:bounce(amount, total_duration)
	if not self.bouncing then
		self.bouncing = true
		local duration = total_duration / 2
		local base_y = self.origin.y

		trigger:tween(duration, self, { y = base_y - amount }, math.quad_out, function()
			trigger:tween(duration, self, { y = base_y }, math.bounce_out, function()
				self.y = base_y -- force exact reset
				self.bouncing = false
			end)
		end)
	end
end

function Building:demolish()
	if self.people_assigned_text then
		-- self.people_assigned_text.dead = true
		self.people_assigned_text = nil
	end

	self.people_slider.dead = true
	self.people_slider = nil
	self.dead = true
end

function Building:on_mouse_enter()
	if not on_current_ui_layer(self) or not main.current.players_turn then
		return false
	end
	-- if game_mouse.holding ~= nil then
	--     return
	-- end
	-- [SFX]

	self.spring:pull(0.15, 400, 32)
	sfx.building_mouse_enter:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	self.selected = true
	game_mouse.hovering = not game_mouse.holding and self or nil
	return true
end

function Building:on_mouse_exit()
	self.selected = false
	return true
end

function Building:prep_demolish()
	self.people_slider:expand(false)
end

function Building:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)

	local color = white[0]
	local flash_interval = 0.4

	if self.tile and self.tile.marked then
		-- time-based flashing
		local t = love.timer.getTime()
		if math.floor(t / flash_interval) % 2 == 0 then
			color = Color(1, 0, 0, 1) -- red
		else
			color = white[0] -- normal color
		end
	end

	color = color:clone()
	color.a = self.opacity

	local scale = self.size * 0.04
	local outline_scale = 0.3
	-- self.shape:draw()
	self.type.sprites()[1]:draw(
		self.x, --
		self.y + outline_scale * self.size / 2,
		0,
		scale + outline_scale,
		scale + outline_scale,
		0,
		0,
		black[0]
	)
	self.type.sprites()[1]:draw(self.x, self.y, 0, scale, scale, 0, 0, color)
	-- self.people_assigned_text:draw()

	local offset = 25
	self.people_assigned_text:draw(self.x + offset, self.y - offset, 0, 1, 1, self.opacity)

	self.people_slider:draw()
	graphics.pop()
end
