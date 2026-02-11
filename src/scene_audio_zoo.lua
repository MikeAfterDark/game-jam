AudioZoo = Object:extend()
AudioZoo:implement(State)
AudioZoo:implement(GameObject)
function AudioZoo:init(name)
	self:init_state(name)
	self:init_game_object()
end

function AudioZoo:on_enter(from, args)
	local folder = "abc/"

	local slider_sounds = {
		Sound("sound1.mp3", sfx_tag),
		Sound("the-first-note-of-megalovania.mp3", sfx_tag),
	}

	local button_sounds = {                            -- setup for a max of 24
		{ "lizard",          Sound("sound1.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "bad to the bone", Sound("sound2.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "lizard",          Sound("sound1.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "bad to the bone", Sound("sound2.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "lizard",          Sound("sound1.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "bad to the bone", Sound("sound2.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "lizard",          Sound("sound1.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "bad to the bone", Sound("sound2.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "lizard",          Sound("sound1.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "bad to the bone", Sound("sound2.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "lizard",          Sound("sound1.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "bad to the bone", Sound("sound2.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "lizard",          Sound("sound1.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "bad to the bone", Sound("sound2.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "lizard",          Sound("sound1.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "bad to the bone", Sound("sound2.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "lizard",          Sound("sound1.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		{ "bad to the bone", Sound("sound2.mp3", sfx_tag) }, -- assets/sounds/sound1.mp3
		-- {"chips", Sound(folder .. "sound3.mp3", sfx_tag)}, -- assets/sounds/abc/sound2.mp3
		-- {"poutine", Sound("../../sound4.mp3", sfx_tag)}, -- src/sound3.mp3
	}

	self.ui = Group()
	self.audio_text_ui_element = {}
	main.ui_layer_stack:push({
		layer = ui_interaction_layer.AudioZoo,
		layer_has_music = false,
		ui_elements = self.audio_text_ui_element,
	})

	local ui_group = self.ui
	local ui_layer = ui_interaction_layer.AudioZoo
	local ui_elements = self.audio_text_ui_element
	collect_into(
		ui_elements,
		Slider({
			group = ui_group,
			x = gw * 0.2,
			y = gh * 0.9,
			length = gw * 0.3,
			thickness = gw * 0.05,
			fg_color = "fg",
			bg_color = "bg",
			rotation = 0,
			max_sections = 20, -- recommend factors of length that are < length/2
			spacing = 8,
			value = self.slider_value or 0.5,
			increment_sfx = slider_sounds[1],
			action = function(b)
				self.slider_value = b.value
			end,
		})
	)

	collect_into(
		ui_elements,
		Slider({
			group = ui_group,
			x = gw * 0.6,
			y = gh * 0.9,
			length = gw * 0.3,
			thickness = gw * 0.05,
			fg_color = "fg",
			bg_color = "bg",
			rotation = 0,
			max_sections = 20, -- recommend factors of length that are < length/2
			spacing = 8,
			value = self.slider_value or 0.5,
			increment_sfx = slider_sounds[2],
			action = function(b)
				self.slider_value = b.value
			end,
		})
	)

	local rows = 8
	local y_offset = gh * 0.1
	local x_offset = gw * 0.3
	for i, sound in ipairs(button_sounds) do
		local col = math.floor((i - 1) / rows)
		local row = (i - 1) % rows

		local x_pos = gw * 0.2 + col * x_offset
		local y_pos = gh * 0.1 + row * y_offset

		collect_into(
			ui_elements,
			Button({
				group = ui_group,
				x = x_pos,
				y = y_pos,
				w = gw * 0.2,
				button_text = sound[1],
				fg_color = "bg",
				bg_color = "fg",
				enter_sfx = sound[2],
				hold_button = 0.3,
				action = function()
					sound[2]:play({ pitch = random:float(0.99, 1.01), volume = 0.5 })
				end,
			})
		)
	end

	for _, v in pairs(ui_elements) do
		-- v.group = ui_group
		-- ui_group:add(v)

		v.layer = ui_layer
		v.force_update = true
	end

	self.paused_ui = Group():no_camera()
	self.options_ui = Group():no_camera()
	self.keybinding_ui = Group():no_camera()
	self.credits = Group():no_camera()
end

function AudioZoo:on_exit()
	self.ui:destroy()
	self.paused_ui:destroy()
	self.options_ui:destroy()
	self.keybinding_ui:destroy()

	self.ui = nil
	self.paused_ui = nil
	self.options_ui = nil
	self.keybinding_ui = nil
	self.credits = nil
end

function AudioZoo:update(dt)
	play_music({ volume = 0.3 })
	if self.song_info_text then
		self.song_info_text:update(dt)
	end

	if not self.in_pause and not self.stuck and not self.won then
		run_time = run_time + dt
	end

	if input.escape.pressed and not self.transitioning and not self.in_credits then
		if not self.in_pause and not self.died and not self.won then
			pause_game(self)
		elseif self.in_options and not self.died and not self.won then
			if self.in_keybinding then
				close_keybinding(self)
			else
				close_options(self)
			end
		else
			local layer = main.ui_layer_stack:peek()

			scene_transition(self, {
				x = gw / 2,
				y = gh / 2,
				type = "fade",
				target = {
					scene = MainMenu,
					name = "main_menu",
					args = { clear_music = true },
				},
				display = {
					text = "loading main menu...",
					font = pixul_font,
					alignment = "center",
				},
			})
			return
		end
	elseif input.escape.pressed and self.in_credits then
		close_credits(self)
		self.in_credits = false
		if self.credits_button then
			self.credits_button:on_mouse_exit()
		end
		self.credits:update(0)
	end

	self:update_game_object(dt * slow_amount)
	self.ui:update(dt * slow_amount)
	self.paused_ui:update(dt * slow_amount)
	self.options_ui:update(dt * slow_amount)
	if self.in_keybinding then
		update_keybind_button_display(self)
	end
	self.keybinding_ui:update(dt * slow_amount)
	self.credits:update(dt * slow_amount)
end

function AudioZoo:draw()
	-- self.floor:draw()
	-- self.main:draw()
	-- self.post_main:draw()
	-- self.effects:draw()
	self.ui:draw()

	-- graphics.draw_with_mask(function()
	-- 	star_canvas:draw(0, 0, 0, 1, 1)
	-- end, function()
	-- 	camera:attach()
	-- 	graphics.rectangle(gw / 2, gh / 2, self.w, self.h, nil, nil, fg[0])
	-- 	camera:detach()
	-- end, true)

	-- if self.win or self.died then
	-- 	graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	-- end
	-- self.end_ui:draw()

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

	-- if self.song_info_text then
	-- 	local x_pos, y_pos = gw * 0.275, gh * 0.95
	-- 	graphics.rectangle(x_pos, y_pos - 5, self.song_info_text.w, self.song_info_text.h, nil, nil, modal_transparent)
	-- 	self.song_info_text:draw(x_pos, y_pos, 0, 1, 1)
	-- end
end
