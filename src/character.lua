Character = Object:extend()
Character:implement(GameObject)
function Character:init(args)
    self:init_game_object(args)

    self.armour = 3
    self.hp = self.max_hp
    self.color = random:color()

    self.hp_text = Text({ { text = "hallo", font = pixul_font, alignment = "center" } }, global_text_tags)
    self.money_text = Text({ { text = "its me", font = pixul_font, alignment = "center" } }, global_text_tags)
    self.damage_text = Text({ { text = "its me", font = pixul_font, alignment = "center" } }, global_text_tags)
end

function Character:update(dt)
    self:update_game_object(dt)

    local armour_text = self.armour > 0 and "[blue]+" .. tostring(self.armour) .. " " or ""
    self.hp_text:set_text({
        {
            text = armour_text .. "[green]" .. tostring(self.hp) .. "/" .. tostring(self.max_hp),
            font = pixul_font,
            alignment = "center",
        },
    })

    self.money_text:set_text({
        {
            text = "[yellow]" .. "$" .. tostring(self.money),
            font = pixul_font,
            alignment = "center",
        },
    })

    self.damage_text:set_text({
        {
            text = "[red]" .. tostring(self.damage),
            font = pixul_font,
            alignment = "center",
        },
    })
end

function Character:draw()
    graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)

    local separation = gh * 0.05
    local box_width = math.max(math.max(self.hp_text.w, self.money_text.w), self.damage_text.w) + 10
    local box_height = 2.3 * self.hp_text.h + separation
    graphics.rectangle(self.x, self.y - separation / 7, box_width + 3, box_height + 3, 3, 3, white[0])
    graphics.rectangle(self.x, self.y - separation / 7, box_width, box_height, 3, 3, black[0])

    self.hp_text:draw(self.x, self.y - separation, self.r, 1, 1)
    self.money_text:draw(self.x, self.y, self.r, 1, 1)
    self.damage_text:draw(self.x, self.y + separation, self.r, 1, 1)
    graphics.pop()
end
