Timing_Line = Object:extend()
Timing_Line:implement(GameObject)
function Timing_Line:init(args)
    self:init_game_object(args)
end

function Timing_Line:update(dt)
    self:update_game_object(dt)
end

function Timing_Line:draw()
    graphics.push(self.x, self.y, self.r)
    local line_color = _G["white"][0]
    local bar_height = gh * 0.04
    local line_thickness = 15
    graphics.line( -- base line
        self.x - self.w / 2,
        self.y,
        self.x + self.w / 2,
        self.y,
        line_color,
        line_thickness
    )

    local tick_color = _G["black"][0]
    local gray_line_x = self.x - self.w / 2 +
    ((#self.timings == self.max_beats and #self.timings + 1 or #self.timings) * self.w / (self.max_beats + 1))
    graphics.line(gray_line_x, self.y, self.x + self.w / 2, self.y, tick_color, line_thickness + 3)

    for i = 1, self.max_beats, 1 do
        local x = self.x - self.w / 2 + (i * self.w / (self.max_beats + 1))

        local tick_height = gh * 0.02
        tick_color = i <= #self.timings and (self.timings[i].color or line_color) or _G["black"][0]
        graphics.line(x, self.y - tick_height, x, self.y + tick_height, tick_color, line_thickness)
    end

    graphics.line( -- left end bar
        self.x - self.w / 2,
        self.y - bar_height,
        self.x - self.w / 2,
        self.y + bar_height,
        line_color,
        line_thickness
    )
    graphics.line( -- right end bar
        self.x + self.w / 2,
        self.y - bar_height,
        self.x + self.w / 2,
        self.y + bar_height,
        tick_color,
        line_thickness
    )
    graphics.pop()
end
