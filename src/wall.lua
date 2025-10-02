wall_type = {
    Sticky = 0,

    Empty = 100,
}

Wall = Object:extend()
Wall:implement(GameObject)
Wall:implement(Physics)
function Wall:init(args)
    self:init_game_object(args)
    -- self:set_as_chain(true, self.vertices, "static", "solid")
    self:set_as_rectangle(self.w, self.h, "static", "solid")
    self.color = self.color or fg[0]
end

function Wall:update(dt)
    self:update_game_object(dt)
end

function Wall:draw()
    self.shape:draw(self.color)
end

function Wall:on_collision_enter(other, contact)
    local x, y = contact:getPositions()

    if other:is(Player) and other.wall ~= self then
        -- self.hfx:use("hit", 0.15, 200, 10, 0.1)
        -- self.ready = true
        if self.type == wall_type.Sticky then
            other:set_velocity(0, 0)
        elseif self.type == wall_type.Empty then
        end
    end
end
