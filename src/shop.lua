Shop = Object:extend()
Shop:implement(GameObject)
function Shop:init(args)
    self:init_game_object(args)
    -- self.text = Text(args.lines, global_text_tags)
    -- self.w, self.h = args.w or self.text.w, args.h or self.text.h

    local mouse_grace = 20
    self.shape = Rectangle(self.x, self.y, self.w + mouse_grace, self.h + mouse_grace)
    self.interact_with_mouse = true
end

function Shop:update(dt)
    self:update_game_object(dt)
end

-- function Shop:set_text(new_text)
--     new_text = table.map(new_text, function(v)
--         v.wrap = self.w
--         return v
--     end)
--     self.text:set_text(new_text)
-- end

function Shop:on_mouse_enter()
    self.selected = true
end

function Shop:on_mouse_exit()
    self.selected = false
end

function Shop:draw()
    graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)

    local color = self.selected and green[0] or blue[0]
    graphics.rectangle(self.x, self.y, self.w + 10, self.h + 10, 5, 5, color)
    graphics.rectangle(self.x, self.y, self.w + 5, self.h + 5, 5, 5, black[0])
    graphics.pop()
end
