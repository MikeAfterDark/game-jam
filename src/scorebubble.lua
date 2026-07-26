ScoreBubble = Object:extend()
ScoreBubble:implement(GameObject)
function ScoreBubble:init(args)
    self:init_game_object(args)
    self.rs = self.rs or 20
    self.duration = self.duration or 1
    self.color = self.color or fg[0]
    self.text = Text({
        { --
            text = "[yellow]+" .. self.value,
            font = pixul_font,
            alignment = "center",
        },
    }, global_text_tags)

    self.t:tween(self.duration, self, { x = self.planet.x, y = self.planet.y }, math.cubic_out, function()
        self.planet:add_score(self.value)
        self.dead = true
    end, "die")

    return self
end

function ScoreBubble:update(dt)
    self:update_game_object(dt)
end

function ScoreBubble:draw()
    graphics.circle(self.x, self.y, self.rs, self.color)
    self.text:draw(self.x, self.y + 2, 0, 1, 1)
end
