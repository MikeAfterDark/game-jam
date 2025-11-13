Pill = Object:extend()
Pill:implement(GameObject)
Pill:implement(Physics)
Pill:implement(Unit)
function Pill:init(args)
    self:init_game_object(args)

    self.color = green[0]
    self:set_as_circle(self.rs, "static", "pill")

    self.angle = math.atan2(self.boost_y, self.boost_x)
    self.strength = math.sqrt(self.boost_x * self.boost_x + self.boost_y * self.boost_y)
end

function Pill:update(dt)
    self:update_game_object(dt)
end

function Pill:draw()
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    -- self:draw_physics()
    graphics.circle(self.x, self.y, self.rs, self.color)

    local scale = self.strength / 1000
    local arrow_dist = self.rs + scale * 20
    local x = self.x + arrow_dist * math.cos(self.angle)
    local y = self.y + arrow_dist * math.sin(self.angle)
    wall_arrow_particle:draw(x, y, self.angle, scale, scale, 0, 0, self.color)
    graphics.pop()
end

function Pill:on_trigger_enter(other, contact)
    if other:is(Runner) then
        other:apply_impulse(self.boost_x, self.boost_y)
        self.spring:pull(0.2, 200, 10)
    end
end
