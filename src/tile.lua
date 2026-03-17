Tile_Type = {
	Grass = {
		name = "grass",
		traits = {
			"solid",
			"biology",
			"dry",
			"oxygen",
		},
		sprites = function()
			return tile_sprites.grass
		end,
	},
	Blue_Grass = {
		name = "blue grass",
		traits = {
			"solid",
			"biology",
			"wet",
			"oxygen",
		},
		sprites = function()
			return tile_sprites.blue_grass
		end,
	},
	Stone = {
		name = "stone",
		traits = {
			"solid",
			"rock",
			"dry",
		},
		sprites = function()
			return tile_sprites.stone
		end,
	},
	Sand = {
		name = "sand",
		traits = {
			"solid",
			"dry",
		},
		sprites = function()
			return tile_sprites.sand
		end,
	},
	Water = {
		name = "water",
		traits = {
			"water",
			"liquid",
			"wet",
			"biology",
			"cold",
		},
		sprites = function()
			return tile_sprites.water
		end,
	},
	Lava = {
		name = "lava",
		traits = {
			"lava",
			"liquid",
			"hot",
		},
		sprites = function()
			return tile_sprites.lava
		end,
	},
	Snow = {
		name = "snow",
		traits = {
			"solid",
			"cold",
		},
		sprites = function()
			return tile_sprites.snow
		end,
	},
	Asteroid = {
		name = "asteroid",
		traits = {
			"solid",
		},
		sprites = function()
			return tile_sprites.asteroid
		end,
	},
	Sun = {
		name = "sun",
		traits = {
			"plasma",
		},
		sprites = function()
			return tile_sprites.sun
		end,
	},
}

-- Forest = "forest",
-- Water = "water",
-- Lava = "lava",
-- Stone = "stone",

Tile = Object:extend()
Tile:implement(GameObject)
function Tile:init(args)
	self:init_game_object(args)
	-- self.color = random:color()
	self.opacity = 1
	self.shape = Diamond(self.x, self.y - (self.size * 0.1), self.size * 1.25, self.size * 1.08) -- for mouse interaction
	self.interact_with_mouse = true
	self.selected = false
	self.event_ids = {}
	self.type = self.type or Tile_Type.Default

	self.base_y = self.y -- for tile:bounce() to not drift
end

function Tile:update(dt)
	self:update_game_object(dt)
	if self.type.sprites()[1]:is(Animation) then
		self.type.sprites()[1]:update(dt)
	end

	if not self.selected and self.colliding_with_mouse then
		self:on_mouse_enter()
	end

	if self.holding and self.clearing then
		self.holding.y = self.y
		self.holding.opacity = self.opacity
	end
end

function Tile:hold(building)
	self.holding = building -- a reference to whatevers on top, in case something happens to the tile
end

function Tile:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	local scale = self.size * 0.02

	local sprite_color = self.type.sprites()[2] and self.type.sprites()[2]:clone() or white[0]:clone()
	sprite_color.a = self.opacity

	self.type.sprites()[1]:draw(self.x, self.y, 0, scale, scale, 0, 0, sprite_color)

	if self.selected then
		local color = Color(0.5, 1, 0.5, 0.5)
		tile_sprites.cover[1]:draw(self.x, self.y, 0, scale, scale, 0, 0, color)
	end

	if #self.event_ids > 0 then
		local color = Color(1.0, 0.3, 0.1, 0.8)
		tile_sprites.large_cover[1]:draw(self.x, self.y - 6, 0, scale, scale, 0, 0, color)
	end

	-- self.shape:draw(self.color)
	graphics.pop()
end

function Tile:set_type(args)
	self.type = args.target
	if self.holding and not self.holding:can_survive({ tile = self, effects = args.effects }) then
		self.holding:demolish()
		self.holding = nil
	end
end

function Tile:convert_tile(args)
	if table.pop_item(self.event_ids, args.event_id) then
		-- trigger:after(random:float() * 0.5, function()
		sfx.earthquake:play({ pitch = random:float(0.95, 1.05), volume = 0.1 })
		self:set_type(args)
		-- end)
	end
end

function Tile:prep_clearing()
	self.clearing = true
	if self.holding then
		self.holding:prep_demolish()
	end
end

function Tile:on_mouse_enter()
	if not on_current_ui_layer(self) or not main.current.players_turn then
		return false
	end
	-- [SFX]
	sfx.tile_mouse_enter:play({ pitch = random:float(0.95, 1.05), volume = 0.1 })
	self.selected = true
	game_mouse.tile_hovered = self
	-- self.spring:pull(0.15, 400, 32)
	return true
end

function Tile:on_mouse_exit()
	self.selected = false
	return true
end

function Tile:bounce(amount, total_duration)
	if not self.bouncing then
		self.bouncing = true
		local duration = total_duration / 2
		local base_y = self.base_y

		trigger:tween(duration, self, { y = base_y - amount }, math.quad_out, function()
			trigger:tween(duration, self, { y = base_y }, math.bounce_out, function()
				self.y = base_y -- force exact reset
				self.bouncing = false
			end)
		end)
	end
end

function Tile:move_to(args)
	trigger:tween(args.duration, self, { x = args.x, y = args.y }, args.easing, function()
		self.shape:move_to(args.x, args.y)
		self.base_y = args.y -- for tile:bounce() to not drift
	end)
end
