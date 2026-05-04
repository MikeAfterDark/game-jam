Settings = Object:extend()
Settings:implement(State)
function Settings:init(name)
    self:init_state(name)
end

function Settings:on_enter(from, args)
    self.persistent_update = true
    self.persistent_draw = true

    self.paused_ui = Group():no_camera()
    self.options_ui = Group():no_camera()
    self.keybinding_ui = Group():no_camera()
    self.credits = Group():no_camera()

    self.ui_elements = {}
    main.ui_layer_stack:push({
        layer = ui_interaction_layer.Settings,
        layer_has_music = false,
        ui_elements = self.ui_elements,
    })
end

function Settings:update(dt)
    if main.current:is(MainMenu) then
        return
    end

    if input.escape.pressed and not self.transitioning and not self.in_credits then
        if not self.in_pause and not self.in_credits and not self.in_options then
            pause_game(self)
        elseif self.in_options then
            if self.in_keybinding then
                close_keybinding(self)
            else
                close_options(self)
            end
        elseif self.in_pause then
            close_pause(self)
            return
        end
    elseif input.escape.pressed and self.in_credits then
        close_credits(self)
        if self.credits_button then
            self.credits_button:on_mouse_exit()
        end
        self.credits:update(0)
    end

    self.paused_ui:update(dt * slow_amount)
    self.options_ui:update(dt * slow_amount)
    if self.in_keybinding then
        update_keybind_button_display(self)
    end
    self.keybinding_ui:update(dt * slow_amount)
    self.credits:update(dt * slow_amount)
end

function Settings:draw()
    if self.in_pause then
        graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
    end
    self.paused_ui:draw()

    if self.in_options then
        graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
    end
    self.options_ui:draw()

    if self.in_keybinding then
        graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
    end
    self.keybinding_ui:draw()

    if self.in_credits then
        graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
    end
    self.credits:draw()
end
