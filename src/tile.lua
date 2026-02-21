Tile_Type = {
    Default = {
        name = "swamp",
        traits = {
            "solid",
            "liquid",
            "biology",
            "wet",
            "decay",
            "low_oxygen",
        },
        sprites = function()
            return tile_sprites.default
        end,
    },
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
    -- Forest = "forest",
    -- Water = "water",
    -- Lava = "lava",
    -- Stone = "stone",
}

Tile = Object:extend()
Tile:implement(GameObject)
function Tile:init(args)
    self:init_game_object(args)
    self.color = random:color()

    self.shape = Diamond(self.x, self.y - (self.size * 0.1), self.size * 1.153, self.size * 0.988) -- for mouse interaction
    self.interact_with_mouse = true
    self.selected = false
    self.type = self.type or Tile_Type.Default
end

function Tile:update(dt)
    self:update_game_object(dt)

    if not self.selected and self.colliding_with_mouse then
        self:on_mouse_enter()
    end
end

function Tile:hold(building)
    self.holding = building -- a reference to whatevers on top, in case something happens to the tile
end

function Tile:draw()
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    self.shape:draw(self.color)
    local scale = self.size * 0.02
    self.type.sprites()[1]:draw(self.x, self.y, 0, scale, scale, 0, 0, white[0])

    if self.selected then
        local color = Color(0.5, 1, 0.5, 0.5)
        tile_sprites.cover[1]:draw(self.x, self.y, 0, scale, scale, 0, 0, color)
    end

    if self.has_building and false then
        local offset = -self.size * 0.1
        building_sprites.castle[1]:draw(self.x, self.y + offset, 0, scale, scale, 0, 0, Color(1, 1, 1, 1))
    end
    graphics.pop()
end

function Tile:on_mouse_enter()
    -- [SFX]
    self.selected = true
    -- self.spring:pull(0.15, 400, 32)
    return true
end

function Tile:on_mouse_exit()
    self.selected = false
    return true
end
