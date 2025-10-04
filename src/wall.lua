wall_type = {
    Sticky = {
        color = "green",
        collision_behavior = function(other)
            other:set_velocity(0, 0)
        end,
    },
    Icy = {
        color = "blue",
        collision_behavior = function(other, contact)
            local normal = Vector(contact:getNormal())
            local velocity = Vector(other:get_velocity())
            local speed = velocity:length()

            local dir = velocity:normalize()
            local dot = dir:dot(normal)

            if dot < -0.99 then
                other:set_velocity(0, 0)
                return
            end

            local t1 = Vector(-normal.y, normal.x)
            local t2 = Vector(normal.y, -normal.x)
            local new_dir = (dir:dot(t1) > dir:dot(t2)) and t1 or t2

            new_dir = Vector(math.sign(new_dir.x), math.sign(new_dir.y)):scale(speed)
            other:set_velocity(new_dir:unpack())
        end,
    },
    Empty = {
        color = "black",
        collision_behavior = function() end,
    },
}
wall_type_order = { "Sticky", "Icy", "Empty" } -- NOTE: a shitty way for creator mode to choose a wall

Wall = Object:extend()
Wall:implement(GameObject)
Wall:implement(Physics)
function Wall:init(args)
    self:init_game_object(args)
    self:set_as_rectangle(self.w, self.h, "static", "solid")
    self:set_angle(self.r)

    self.color = self.color or _G[self.type.color][0] or fg[0]
end

function Wall:update(dt)
    self:update_game_object(dt)
end

function Wall:draw()
    self.shape:draw(self.color)
end

function Wall:on_collision_enter(other, contact)
    if other:is(Player) and other.wall ~= self then
        self.type.collision_behavior(other, contact)
    end
end

-- wall_type = {
--     Sticky = 0,
--     Icy = 1,
--     Empty = 100,
-- }
--
-- local wall_defs = {
--     [wall_type.Sticky] = {
--         -- color = green[-4],
--         collision_behavior = function(other)
--             other:set_velocity(0, 0)
--         end,
--     },
--     [wall_type.Icy] = {
--         -- color = blue[5],
--         collision_behavior = function(other, contact)
--             local normal = Vector(contact:getNormal())
--             local velocity = Vector(other:get_velocity())
--             local speed = velocity:length()
--
--             local dir = velocity:normalize()
--             local dot = dir:dot(normal)
--
--             if dot < -0.99 then
--                 -- Moving directly into the wall: stop
--                 other:set_velocity(0, 0)
--                 return
--             end
--
--             local t1 = Vector(-normal.y, normal.x)
--             local t2 = Vector(normal.y, -normal.x)
--             local new_dir = (dir:dot(t1) > dir:dot(t2)) and t1 or t2
--
--             -- Snap to nearest 45° unit vector
--             new_dir = Vector(math.sign(new_dir.x), math.sign(new_dir.y)):scale(speed)
--             other:set_velocity(new_dir:unpack())
--         end,
--     },
--     [wall_type.Empty] = {
--         -- color = black[0],
--         collision_behavior = function() end,
--     },
-- }
