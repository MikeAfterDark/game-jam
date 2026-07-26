ScoreBubble = Object:extend()
ScoreBubble:implement(GameObject)
function ScoreBubble:init(args)
    self:init_game_object(args)
    self.duration = 1
    self.color = white[0]
    self.text = Text({
        { --
            text = "[green]" .. self.score,
            font = pixul_font,
            alignment = "center",
        },
    }, global_text_tags)
    self.rs = math.max(self.text.w, self.text.h) - 8

    self.planet:add_score(self.score)
    self.scale = 1

    sfx.boop:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
    self.t:tween(self.duration, self, { x = self.planet.x, y = self.planet.y }, math.expo_out)
    self.t:after(self.duration * 0.5, function()
        self.t:tween(self.duration * 0.2, self, { scale = 0 }, math.back_in, function()
            -- sfx.tick:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
            self.dead = true
        end)
    end, "die")

    return self
end

function ScoreBubble:update(dt)
    self:update_game_object(dt)
end

function ScoreBubble:draw()
    -- graphics.circle(self.x, self.y, self.rs * self.scale * 1.1, black[0])
    graphics.circle(self.x, self.y, self.rs * self.scale, black[0])

    self.text:draw(self.x + 1, self.y + 3, 0, self.scale, self.scale)
end
