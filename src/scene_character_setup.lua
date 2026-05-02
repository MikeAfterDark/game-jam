Character_Setup = Object:extend()
Character_Setup:implement(State)
Character_Setup:implement(GameObject)
function Character_Setup:init(name)
	self:init_state(name)
	self:init_game_object()
end

function Character_Setup:on_enter(from, args)
	self.hfx:add("condition1", 1)
	self.hfx:add("condition2", 1)

	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0

	self.main = Group()
	self.edit = Group()

	self.main_slow_amount = 1
	slow_amount = 1

	self.edit_ui_elements = {}
	self.ui_elements = {}
	main.ui_layer_stack:push({
		layer = ui_interaction_layer.Character_Setup,
		layer_has_music = false,
		ui_elements = self.ui_elements,
	})

	self.Stages = {
		Group_Selection = 1,
		Character_Editing = 2,
	}
	self.stage = self.Stages.Group_Selection
	self.level = self.level or { name = "default level", lead_in_beats = 4 }

	self.group = {}
	self.characters = self:load_characters()

	self.edit_tab = { x = 0, y = gh * 1 }

	local cols = 4

	local scale = gw * 0.08
	local spacing = scale * 1.4
	local x_center = gw / 2
	local y_start = scale

	for i, character in ipairs(self.characters) do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)

		local total_width = (cols - 1) * spacing

		collect_into(
			self.ui_elements,
			RectangleButton({
				group = self.main,
				layer = ui_interaction_layer.Character_Setup,
				x = x_center - total_width / 2 + col * spacing,
				y = y_start + row * spacing,
				w = scale,
				h = scale,
				force_update = true,
				no_image = true,
				color = Color:random(),
				title_text = character.type.name,
				fg_color = "bg",
				action = function(b)
					local active = b:toggle_outline()

					if active then
						table.insert(self.group, character)
					else
						table.delete(self.group, character)
					end
				end,
			})
		)
	end

	self.group_text = collect_into(
		self.ui_elements,
		Text2({
			group = self.main,
			x = gw * 0.9,
			y = gh * 0.5,
			lines = { { text = "", font = pixul_font } },
		})
	)

	collect_into(
		self.ui_elements,
		Button({
			group = self.main,
			x = gw * 0.9,
			y = gh * 0.84,
			button_text = "planning",
			fg_color = "bg",
			bg_color = "fg",
			update_action = function(b)
				b.locked = #self.group == 0 or self.stage == self.Stages.Character_Editing
			end,
			action = function(b)
				self:set_stage(self.Stages.Character_Editing)
			end,
		})
	)

	for _, v in pairs(self.ui_elements) do
		v.layer = v.layer or ui_interaction_layer.Character_Setup
		v.force_update = true
	end
end

function Character_Setup:update(dt)
	self:update_game_object(dt * slow_amount)
	self.main:update(dt)
	self.edit:update(dt)

	for _, v in pairs(self.ui_elements) do
		if v.update_action then
			v:update_action()
		end
	end

	for _, v in pairs(self.edit_ui_elements) do
		local y = v.base_y + self.edit_tab.y
		v.y = y
		if v.shape then
			v.shape:move_to(v.x, y)
		end

		if v.update_action then
			v:update_action()
		end
	end

	local characters = {
		{ text = "Group:", font = pixul_font },
	}
	for i, character in ipairs(self.group) do
		table.insert(characters, { text = character.type.name, font = pixul_font })
	end
	self.group_text:set_text(characters)
end

function Character_Setup:set_stage(stage)
	self.stage = stage

	if stage == self.Stages.Group_Selection then
		main.ui_layer_stack:pop()
		trigger:tween(0.5, self.edit_tab, { y = gh * 1 }, math.circ_in, function()
			for _, v in pairs(self.edit_ui_elements) do
				v.dead = true
				v = nil
			end
			self.edit_ui_elements = {}
			self.edit_tab.y = gh * 1 -- without setting it goes to y = 0 for some reason
		end)
	elseif stage == self.Stages.Character_Editing then
		self.edit_ui_elements = {}
		main.ui_layer_stack:push({
			layer = ui_interaction_layer.Group_Selection,
			layer_has_music = false,
			ui_elements = self.edit_ui_elements,
		})
		-- get/setup timelines/actions of characters,
		-- setup in order of group selection (temp to avoid implementing reordering)
		-- 'go' button

		collect_into(
			self.edit_ui_elements,
			RectangleCover({
				group = self.edit,
				x = gw * 0.5,
				base_y = gh * 0.5,
				w = gw,
				h = gh,
				color = Color(0.1, 0.1, 0.1, 0.96),
			})
		)

		self.timing_line = collect_into(
			self.edit_ui_elements,
			Timing_Line({
				group = self.edit,
				x = gw * 0.5,
				base_y = gh * 0.55,
				w = gw * 0.8,
				max_beats = 8,
				timings = {},
			})
		)

		local x_offset = gw / (#self.group + 1)
		for i, character in ipairs(self.group) do
			collect_into(
				self.edit_ui_elements,
				Button({
					group = self.edit,
					layer = ui_interaction_layer.Group_Selection,
					x = i * x_offset,
					base_y = gh * 0.8,
					w = gw * 0.05,
					button_text = character.type.name,
					fg_color = "bg",
					bg_color = "fg",
					update_action = function(b)
						b.locked = self.loaded_character == character
					end,
					action = function(b)
						self:load_character_timings(character)
					end,
				})
			)
		end
		self:load_character_timings(self.group[1])

		collect_into(
			self.edit_ui_elements,
			Button({
				group = self.edit,
				layer = ui_interaction_layer.Group_Selection,
				x = gw * 0.9,
				base_y = gh * 0.90,
				button_text = "group select",
				fg_color = "bg",
				bg_color = "fg",
				update_action = function(b)
					b.locked = self.stage == self.Stages.Group_Selection
				end,
				action = function(b)
					self:set_stage(self.Stages.Group_Selection)
				end,
			})
		)

		collect_into(
			self.edit_ui_elements,
			Button({
				group = self.edit,
				layer = ui_interaction_layer.Group_Selection,
				x = gw * 0.9,
				base_y = gh * 0.96,
				button_text = "GO",
				fg_color = "bg",
				bg_color = "fg",
				update_action = function(b)
					b.locked = self.stage == self.Stages.Group_Selection
				end,
				action = function(b)
					scene_transition(self, {
						x = gw / 2,
						y = gh / 2,
						type = "fade",
						speed = 1,
						target = {
							scene = Game,
							name = "game",
							args = {
								clear_music = true,
								level = self.level,
								player_units = self.group,
								has_music = true,
								music_type = "main",
							},
						},
						display = {
							text = "loading level: " .. self.level.name,
							font = pixul_font,
							alignment = "center",
						},
					})
				end,
			})
		)

		for _, v in pairs(self.edit_ui_elements) do
			v.layer = v.layer or ui_interaction_layer.Group_Selection
			v.force_update = true
		end

		trigger:tween(0.7, self.edit_tab, { y = gh * 0 }, math.bounce_out)
	end
end

Input_Type = {
	Direction = 1,
	Arix = 2,
	Myon = 3,
}

Timings = {
	Empty = {
		id = "Empty",
		name = "empty",
		color = Color(0, 0, 0, 1),
	},

	Beat = {
		id = "Beat",
		name = "beat",
		color = Color(0, 1, 0, 1),
		input_type = Input_Type.Direction,
	},

	Hold = {
		id = "Hold",
		name = "hold",
		color = Color(1, 0, 0, 1),
		input_type = Input_Type.Direction,
	},

	-- NOTE: duration == num beats at whatever beat_resolution
	Myon = {
		id = "Myon",
		duration = 4,
		name = "myon",
		color = Color(1, 1, 0, 1),
		input_type = Input_Type.Myon,
	},

	-- NOTE: duration == num beats at whatever beat_resolution
	Arix = {
		id = "Arix",
		duration = 3,
		name = "arix",
		color = Color(0, 1, 1, 1),
		input_type = Input_Type.Arix,
	},
}

function Character_Setup:load_characters()
	return {
		{
			type = Unit_Type.A,
			timeline = {
				{ Timings.Empty },
				{ Timings.Empty },

				{ Timings.Beat },
				{ Timings.Empty },

				{ Timings.Empty },
				{ Timings.Empty },

				{ Timings.Hold },
				{ Timings.Empty },
			},
		},
		{
			type = Unit_Type.B,
			timeline = {
				{ Timings.Beat },
				{ Timings.Empty },

				{ Timings.Beat },
				{ Timings.Empty },

				{ Timings.Hold },
				{ Timings.Empty },

				{ Timings.Beat },
				{ Timings.Empty },
			},
		},
		{
			type = Unit_Type.C,
			timeline = {
				{ Timings.Empty },
				{ Timings.Empty },

				{ Timings.Beat },
				{ Timings.Beat },

				{ Timings.Empty },
				{ Timings.Empty },

				{ Timings.Beat },
				{ Timings.Beat },
			},
		},
		{
			type = Unit_Type.D,
			timeline = {
				{ Timings.Empty },
				{ Timings.Beat },

				{ Timings.Beat },
				{ Timings.Beat },

				{ Timings.Empty },
				{ Timings.Beat },

				{ Timings.Beat },
				{ Timings.Beat },
			},
		},
		{
			type = Unit_Type.E,
			timeline = {
				{ Timings.Beat },
				{ Timings.Empty },

				{ Timings.Beat, Timings.Myon },
				{ Timings.Empty },

				{ Timings.Beat, Timings.Arix },
				{ Timings.Empty },

				{ Timings.Beat },
				{ Timings.Empty },
			},
		},
	}
end

function Character_Setup:load_character_timings(character)
	self.loaded_character = character
	self.timing_line.timings = character.timeline
end

function Character_Setup:draw()
	self.main:draw()
	self.edit:draw()
end

function Character_Setup:on_exit()
	self.main:destroy()
	self.edit:destroy()
	self.edit = nil
	self.main = nil
end
