Board = Object:extend()
Board:implement(GameObject)
function Board:init(args)
    self:init_game_object(args)

    self.tiles = {}

    local screen_vertical_offset = gh * 0.4
    local depth_scale = 0.494
    local horizontal_scale = 0.59

    local x_axis = {
        x = self.tile_size * horizontal_scale,
        y = self.tile_size * depth_scale,
    }

    local y_axis = {
        x = -self.tile_size * horizontal_scale,
        y = self.tile_size * depth_scale,
    }

    -- back to front ordering
    for sum = 2, self.rows + self.columns do
        for row = 1, self.rows do
            local col = sum - row

            if col >= 1 and col <= self.columns then
                local screen_x = self.x + (col - 1) * x_axis.x + (row - 1) * y_axis.x
                local screen_y = self.y + (col - 1) * x_axis.y + (row - 1) * y_axis.y - screen_vertical_offset

                table.insert(
                    self.tiles,
                    Tile({
                        group = self.group,
                        x = screen_x,
                        y = screen_y,
                        size = self.tile_size,
                        angle = math.pi * 0.25,
                        row = row,
                        col = col,
                    })
                )
            end
        end
    end
end

function Board:update(dt)
    self:update_game_object(dt)
end

function Board:draw()
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.pop()
end
