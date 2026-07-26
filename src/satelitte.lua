Satellite = Object:extend()
Satellite:implement(GameObject)
function Satellite:init(args)
    self:init_game_object(args)
    self.shape = Circle(self.x, self.y, self.rs)

    self.sprite = sprite.satelitte
    self.interact_with_mouse = true
end

function Satellite:update(dt)
    self:update_game_object(dt)

    self.x = self.planet.x
    self.y = self.planet.y
    self.shape:move_to(self.x, self.y)
end

function Satellite:draw()
    graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)

    local sprite_scale = 1.680
    self.sprite:draw(self.x, self.y, self.r, sprite_scale, sprite_scale, 1, 1)
    graphics.pop()
    self.shape:draw()
end
