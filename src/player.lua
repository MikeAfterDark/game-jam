require("objects")

Player = Object:extend()
Player:implement(GameObject)
Player:implement(Physics)
Player:implement(Unit)
function Player:init(args)
    self:init_game_object(args)
    self:init_unit()

    self.color = self.color or yellow[0]
    self.color_text = self.color_text or "yellow"
    self:set_as_circle(9, "dynamic", "player")
    self.ready = true -- TODO: check if we're on a wall and not moving
    self.wall = {}
    self.wall.normal = Vector:zero()

    -- if main.current:is(MainMenu) then
    --     self.r = random:table({ -math.pi / 4, math.pi / 4, 3 * math.pi / 4, -3 * math.pi / 4 })
    --     self:set_angle(self.r)
    -- end

    if args.tutorial then
        self.tutorial_player_indicator_text = Text2({
            group = main.current.tutorial_ui,
            x = self.x,
            y = self.y + 20,
            lines = { { text = "[" .. self.color_text .. "]player", font = pixul_font } },
        })
    end
end

function Player:update(dt)
    self:update_game_object(dt)

    if
        not main.current.won
        and not main.current.died
        and not main.current.choosing_passives
        and not main.current.paused
        and not main.current.transitioning
    then
        if self.collided then
            self.collided = false

            local dist = 10
            self:set_position(self.x + self.wall.normal.x * dist, self.y + self.wall.normal.y * dist)
            if self.wall.normal.theta then
                self.r = self.wall.normal.theta
                self:set_angle(self.wall.normal.theta)
            end
        end

        local x, y = 0, 0

        if input.left.down and self.wall.normal.x <= 0 then
            x = x - 1
        end
        if input.right.down and self.wall.normal.x >= 0 then
            x = x + 1
        end
        if input.up.down and self.wall.normal.y <= 0 then
            y = y - 1
        end
        if input.down.down and self.wall.normal.y >= 0 then
            y = y + 1
        end

        if x ~= 0 or y ~= 0 then
            self.r = math.atan2(y, x)
            self:set_angle(self.r)
        else
        end

        self.ready = true -- NOTE: temp
        if self.ready and input.jump.pressed then
            self:move_along_angle(self.speed, self.r)
            self.wall.normal = Vector:zero() -- NOTE: temp
            self.ready = false
        end
    end

    if self.tutorial_player_indicator_text ~= nil then
        self.tutorial_player_indicator_text.x = self.x
        self.tutorial_player_indicator_text.y = self.y + 16
    end
end

function Player:draw()
    -- graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3,
    --     (self.hfx.hit.f or self.hfx.shoot.f) and fg[0] or self.color)
    graphics.circle(self.x, self.y, self.size, self.color)
    self.tutorial_player_indicator_text:draw()

    if self.ready then
        graphics.push(self.x, self.y, self.r, self.hfx.hit.x * self.hfx.shoot.x, self.hfx.hit.x * self.hfx.shoot.x)
        local x, y = self.x + 0.9 * self.shape.w * global_game_scale, self.y
        local size = 3 * global_game_scale
        graphics.polyline(self.color, size, x + size, y, x, y - size, x, y + size, x + size, y)

        graphics.pop()
    end

    if self.wall and self.wall.normal and self.wall.normal.theta then
        local scale = math.max(0.01, self.hfx.hit.x * self.hfx.shoot.x)

        graphics.push(self.x, self.y, self.wall.normal.theta, scale, scale)
        local x, y = self.x + 0.9 * self.shape.w * global_game_scale, self.y
        local length = 7 * global_game_scale
        local thickness = 1.5 * global_game_scale
        local color = yellow[0]
        graphics.line(x + length, y, x, y - length, color, thickness)
        graphics.line(x + length, y, x, y + length, color, thickness)
        graphics.pop()
    end
end

function Player:on_collision_enter(other, contact)
    if other:is(Wall) then
        self.hfx:use("hit", 0.15, 200, 10, 0.1)
        self.ready = true
        self.collided = true
        self.wall = other
        self.wall.normal = Vector(contact:getNormal())
        self.wall.normal.theta = self.wall.normal:angle()
    end
end
