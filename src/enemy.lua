Enemy = Object:extend()
Enemy:implement(GameObject)
function Enemy:init(args)
    self:init_game_object(args)

    self.speed = 1 --self.type.speed or random:int(1, 3)
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

function Enemy:update(dt)
    self:update_game_object(dt)

    self.x = self.base_x + (self.tile_x - 0.5) * self.cell_size
    self.y = self.base_y + (self.tile_y - 0.5) * self.cell_size

    self.text.x = self.x
    self.text.y = self.y
    self.text:update(dt)
end

function Enemy:beat_tracker(time, is_new_beat)
    if is_new_beat then
        -- WARN: its IRL time = 0.2s, smaller beat increments/hit_windows will fuck this over
        trigger:tween(0.2, self,
            { tile_x = self.tile_x + self.dir_x * self.speed, tile_y = self.tile_y + self.dir_y * self.speed },
            math.cubic_in_out)
        -- self.tile_x = self.tile_x + self.dir_x
        -- self.tile_y = self.tile_y + self.dir_y
    end
end

function Enemy:draw()
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)

    local x = self.x --+ (self.tile_x - 1) * self.cell_size + width / 2
    local y = self.y --+ (self.tile_y - 1) * self.cell_size + height / 2

    local size = self.cell_size * 0.4
    graphics.rectangle(x, y, self.dir_x + size, self.dir_y + size, 2, 2, self.color)

    self.text:draw()

    graphics.pop()
end

-- Timings = {
-- 	Empty = { id = "Empty", name = "empty", color = Color(0, 0, 0, 1) },
-- 	Beat = { id = "Beat", name = "beat", color = Color(0, 1, 0, 1) },
-- 	Hold = { id = "Hold", name = "hold", color = Color(1, 0, 0, 1) },
-- 	Special = { id = "Special", name = "special", color = Color(1, 1, 0, 1) },
-- }

function Character_Setup:load_characters()
    return {
        { type = Unit_Type.A, timeline = { Timings.Beat, Timings.Empty, Timings.Hold, Timings.Beat, Timings.Empty, Timings.Beat } },
        { type = Unit_Type.B, timeline = { Timings.Beat, Timings.Beat, Timings.Empty } },
        { type = Unit_Type.C, timeline = { Timings.Beat, Timings.Beat, Timings.Beat, Timings.Beat, Timings.Beat } },
        { type = Unit_Type.D, timeline = { Timings.Beat, Timings.Hold, Timings.Beat, Timings.Hold, Timings.Beat, Timings.Beat } },
        { type = Unit_Type.E, timeline = { Timings.Beat, Timings.Empty, Timings.Beat, Timings.Beat, Timings.Empty, Timings.Beat } },
    }
end

Enemy_Type = {
    A = {
        name = "a",
        speed = 10,
        timeline = { Timings.Beat, Timings.Empty, Timings.Beat, Timings.Beat, Timings.Empty, Timings.Beat },
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
