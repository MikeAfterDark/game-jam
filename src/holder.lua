Holder = Object:extend()
Holder:implement(GameObject)
function Holder:init(args)
    self:init_game_object(args)

    self.slots = {}
end

function Holder:update(dt)
    self:update_game_object(dt)
end

function Holder:setup(total_slots, open_slots, balls)
    self.slots = {}
    for i = 1, total_slots do
        local ball = #balls >= i and balls[i] or nil
        if ball then
            ball.index = i
            ball.is_enemy = self.is_enemy
        end

        table.insert(self.slots, {
            open = i <= open_slots,
            ball = ball,
        })
    end

    self.w = #self.slots * self.slot_size
end

function Holder:insert(ball)
    self.slots[ball.index].ball = ball
end

function Holder:next_ball()
    for i, slot in ipairs(self.slots) do
        local ball = slot.ball
        if ball then
            slot.ball = nil
            ball:set_damping(0)
            ball:set_velocity(25 * i, 0)
            return ball
        end
    end
end

function Holder:draw()
    graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
    graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, self.color, 3)

    local base_x = self.x - (#self.slots + 1) * self.slot_size / 2
    for i, slot in ipairs(self.slots) do
        local index = self.is_enemy and i or (#self.slots - i + 1)
        local x = base_x + index * self.slot_size

        local color = slot.open and green[0] or red[0]
        graphics.rectangle(x, self.y, self.slot_size, self.slot_size, 2, 2, color, 3)

        local ball = slot.ball
        if ball then
            ball:freeze(x, self.y)
        end
    end

    graphics.pop()
end
