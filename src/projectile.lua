Projectile = Object:extend()
Projectile:implement(GameObject)
function Projectile:init(args)
    self:init_game_object(args)

    self.speed = self.type.speed or random:int(1, 3)
    -- self.sprites = self.type.sprites()
    self.color = self.type.color

    self.base_x = self.x
    self.base_y = self.y

    self.border = 0
    self.text = Text2({
        x = self.x,
        y = self.y,
        lines = { { text = self.type.name, font = small_pixul_font } },
    })
end

function Projectile:update(dt)
    self:update_game_object(dt)

    self.x = self.base_x + (self.tile_x - 0.5) * self.cell_size
    self.y = self.base_y + (self.tile_y - 0.5) * self.cell_size

    self.text.x = self.x
    self.text.y = self.y
    self.text:update(dt)
end

function Projectile:beat_tracker(time, is_new_beat)
    if is_new_beat then
        -- WARN: its IRL time = 0.2s, smaller beat increments/hit_windows will fuck this over
        trigger:tween(0.2, self,
            { tile_x = self.tile_x + self.dir_x * self.speed, tile_y = self.tile_y + self.dir_y * speed },
            math.cubic_in_out)
        -- self.tile_x = self.tile_x + self.dir_x
        -- self.tile_y = self.tile_y + self.dir_y
    end
end

function Projectile:draw()
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)

    local x = self.x --+ (self.tile_x - 1) * self.cell_size + width / 2
    local y = self.y --+ (self.tile_y - 1) * self.cell_size + height / 2

    local size = self.cell_size * 0.4
    graphics.rectangle(x, y, self.dir_x + size, self.dir_y + size, 2, 2, self.color)

    self.text:draw()

    graphics.pop()
end

Projectile_Type = {
    A = {
        name = "a",
        speed = 10,
        color = Color(1, 0, 0, 1),
        sprites = function()
            return nil
        end,
    },
    B = {
        name = "b",
        speed = 9,
        color = Color(1, 1, 0, 1),
        sprites = function()
            return nil
        end,
    },
    C = {
        name = "c",
        speed = 8,
        color = Color(1, 0, 1, 1),
        sprites = function()
            return nil
        end,
    },
    D = {
        name = "d",
        speed = 7,
        color = Color(0, 1, 0, 1),
        sprites = function()
            return nil
        end,
    },
    E = {
        name = "e",
        speed = 6,
        color = Color(0, 1, 1, 1),
        sprites = function()
            return nil
        end,
    },
}
