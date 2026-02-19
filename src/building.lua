Building_Type = {
    Castle = {
        name = "castle",
        sprites = function()
            return building_sprites.castle
        end,
        rules = {
            placement = {
                { type = "on_solid_tile" },
                { type = "on_any_of_tile_type",     values = { "grass", "stone" } },
                { type = "not_on_any_of_tile_type", values = { "sand", "swamp" } },
            },
            bonus = {
                { type = "no_adjacent_buildings" },
                { type = "within_range_of",      values = { tiles = { type = "grass", amount = 5 }, buildings = { type = "farm", amount = 3 } } },
            },
        },
    },
}

RuleLogic = {
    on_solid_tile = function(context, rule)
        local error = context.tile.type.name .. " tile isn't solid"
        return table.contains(context.tile.type.traits, "solid") ~= nil, error
    end,

    on_any_of_tile_type = function(context, rule)
        local error = context.tile.type.name .. " tile is not one of: " .. table.concat(rule.values, ", ")
        return table.contains(rule.values, context.tile.type.name) ~= nil, error
    end,

    not_on_any_of_tile_type = function(context, rule)
        local error = "cannot place on any of: " .. table.concat(rule.values, ", ")
        return table.contains(rule.values, context.tile.type.name) == nil, error
    end,
}

Building = Object:extend()
Building:implement(GameObject)
function Building:init(args)
    self:init_game_object(args)
    self.vertical_offset = -15 -- WARN: HARDCODED OFFSET to make the buildings like like they're sitting 'on' their surface
    self.y = self.y + self.vertical_offset

    self.shape = Circle(self.x, self.y, self.size)
    self.interact_with_mouse = true
    self.selected = false
    self.origin = { x = self.x, y = self.y }

    self.type = self.type or random:table(Building_Type)
    self.spring:pull(0.15, 400, 32)
    -- [SFX]
end

function Building:update(dt)
    self:update_game_object(dt)

    if self.selected and input.select.pressed then
        game_mouse.holding = self
    end
end

function Building:return_to_origin()
    trigger:tween(0.3, self, { x = self.origin.x, y = self.origin.y }, math.cubic_in_out)
end

function Building:place_on(tile)
    local new_x, new_y = tile.x, tile.y + self.vertical_offset
    self.origin = { x = new_x, y = new_y }
    self.shape:move_to(new_x, new_y)
    trigger:tween(0.1, self, { x = new_x, y = new_y }, math.cubic_in_out)

    if self.tile then
        self.tile.holding = nil -- for if moving from tile to tile
    end
    self.tile = tile
end

-- required context:
-- - tile to be placed on
--
-- returns bool, table of errors
function Building:is_valid_placement(context)
    local errors = {}
    for _, rule in ipairs(self.type.rules.placement) do
        local passed, error = RuleLogic[rule.type](context, rule)
        -- print(passed .. "," .. error)
        if not passed then
            table.insert(errors, error)
        end
    end
    return #errors == 0, errors
end

function Building:on_mouse_enter()
    -- if game_mouse.holding ~= nil then
    --     return
    -- end
    -- [SFX]
    self.selected = true
    return true
end

function Building:on_mouse_exit()
    self.selected = false
    return true
end

function Building:draw()
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    local color = white[0]
    local scale = self.size * 0.04
    self.shape:draw()
    self.type.sprites()[1]:draw(self.x, self.y, 0, scale, scale, 0, 0, color)
    graphics.pop()
end
