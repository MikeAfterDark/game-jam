Level_Select = Object:extend()
Level_Select:implement(State)
Level_Select:implement(GameObject)
function Level_Select:init(name)
	self:init_state(name)
	self:init_game_object()
end

function Level_Select:on_enter(from, args)
	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0

	self.main = Group()

	self.main_slow_amount = 1
	slow_amount = 1

	self.ui_elements = {}
	main.ui_layer_stack:push({
		layer = ui_interaction_layer.Level_Select,
		layer_has_music = false,
		ui_elements = self.ui_elements,
	})

	self.levels = self:load_levels()
	self.num_players = args.num_players

	local cols = 4

	local scale = gw * 0.08
	local spacing = scale * 1.1
	local x_center = gw / 2
	local y_start = scale

	local level_buttons = {}
	for i, level in ipairs(self.levels) do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)

		local total_width = (cols - 1) * spacing

		table.insert(
			level_buttons,
			collect_into(
				self.ui_elements,
				RectangleButton({
					group = self.main,
					layer = ui_interaction_layer.Level_Select,
					x = x_center - total_width / 2 + col * spacing,
					y = y_start + row * spacing,
					w = scale,
					h = scale,
					force_update = true,
					no_image = true,
					color = Color(1, 1, 0, 1),
					title_text = level.name,
					fg_color = "bg",
					action = function(b)
						scene_transition(self, {
							x = gw / 2,
							y = gh / 2,
							type = "circle",
							target = {
								scene = Character_Setup,
								name = "character_setup",
								load_functions = {
									{
										result_key = "level",
										action = function()
											return self:load_level(level.filename)
										end,
									},
								},

								args = { clear_music = true },
							},
							display = {
								text = "loading level " .. level.name,
								font = pixul_font,
								alignment = "center",
							},
						})
					end,
				})
			)
		)
	end

	for i, button in ipairs(level_buttons) do
		local cols = cols
		local n = #level_buttons
		local col = (i - 1) % cols

		-- horizontal wrap (same row)
		local row_start = i - col
		local left = row_start + (col - 1) % cols
		local right = row_start + (col + 1) % cols

		-- vertical step
		local up = (i > cols) and (i - cols) or (n - ((n - 1 - col) % cols))
		local down = (i + cols <= n) and (i + cols) or (col + 1)

		button.left = level_buttons[left] or level_buttons[#level_buttons]
		button.right = level_buttons[right] or level_buttons[row_start]
		button.up = level_buttons[up] -- or button
		button.down = level_buttons[down] -- or button
	end

	self.calibration_button = collect_into(
		self.ui_elements,
		Button({
			group = self.main,
			layer = ui_interaction_layer.Level_Select,
			x = level_buttons[1].x - gw * 0.13,
			y = level_buttons[1].y,
			h = gh * 0.1,
			button_text = "calibrate",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				b.locked = true
				scene_transition(self, {
					x = gw / 2,
					y = gh / 2,
					type = "fade",
					speed = 1,
					target = {
						scene = Game,
						name = "game",
						load_functions = {
							{
								result_key = "level",
								action = function()
									return self:load_level("calibration")
								end,
							},
						},
						args = {
							clear_music = true,
							num_players = self.num_players,
							player_units = {
								{
									type = Unit_Type.Calibration,
									player_id = 1,
									timeline = {
										{ Timings.Empty },
									},
								},
							},
							layer_has_music = true,
							max_beats = 8,
						},
					},
					display = {
						text = "loading calibration",
						font = pixul_font,
						alignment = "center",
					},
				})
			end,
		})
	)

	level_buttons[1].left = self.calibration_button
	self.calibration_button.right = level_buttons[1]

	if state.winnitron_mode then
		self.selected_button = self.ui_elements[1] -- TODO: select next level that hasn't been beaten yet
		self.selected_button:toggle_outline()
	end
end

function Level_Select:update(dt)
	self:update_game_object(dt * slow_amount)
	self.main:update(dt)

	local any_button_hovered = false
	for i, button in ipairs(self.ui_elements) do
		if button.selected and button.colliding_with_mouse then
			if button ~= self.selected_button then
				self.selected_button:toggle_outline()
				self.selected_button = button
				self.selected_button:toggle_outline()
			end
			any_button_hovered = true
			break -- WARN: assumes no buttons overlap
		end
	end

	-- TODO: move this up and down the UI layers
	if not any_button_hovered then
		for i = 1, self.num_players do
			for _, dir in ipairs({ "up", "down", "left", "right" }) do
				if input[i .. dir].pressed and self.selected_button[dir] then
					self.selected_button:toggle_outline()
					self.selected_button = self.selected_button[dir]
					self.selected_button:toggle_outline()
					break
				end
			end
		end
	end

	for i = 1, self.num_players do
		if input[i .. "spacebar"].pressed then
			self.selected_button:action()
		end
	end
end

function Level_Select:load_level(name)
	local level_path = level_folder .. "/" .. name .. "/"

	local metadata_chunk, err = love.filesystem.load(level_path .. "metadata.lua")
	if not metadata_chunk then
		error("Failed to load metadata.lua: " .. err)
	end

	local metadata = metadata_chunk()
	if type(metadata) ~= "table" then
		error("metadata.lua must return a table")
	end

	-- Load all PNGs in the folder
	local rooms = {}
	local songs = {}
	local files = love.filesystem.getDirectoryItems(level_path)
	for _, file in ipairs(files) do
		local file_path = level_path .. file
		if file:match("%.png$") then
			local key = file:gsub("%.png$", "")
			rooms[key] = ImageData(file_path)
		elseif file:match("%.ogg") then
			local key = file:gsub("%.ogg$", "")
			songs[key] = Sound(file_path, music_tag, _, true)
		end
	end

	local level = {
		name = name,
		rooms = rooms,
		songs = songs,
	}
	for k, v in pairs(metadata) do
		level[k] = v
	end
	-- print(table.tostring(level))

	return level
end

-- TODO: this should determine level order, by folder name
function Level_Select:load_levels()
	return {
		{ name = "1", filename = "1" },
		{ name = "2", filename = "2" },
		{ name = "3", filename = "3" },
		{ name = "4", filename = "4" },
		-- { name = "5" },
		-- { name = "6" },
		-- { name = "7" },
		-- { name = "8" },
		-- { name = "9" },
		-- { name = "10" },
	}
end

function Level_Select:draw()
	self.main:draw()
end

function Level_Select:on_exit()
	self.main:destroy()
	self.main = nil
end
