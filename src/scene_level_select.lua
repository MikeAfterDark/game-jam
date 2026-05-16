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

	local cols = 3

	local scale = gw * 0.08
	local spacing = scale * 1.1
	local x_center = gw / 2
	local y_start = scale

	for i, level in ipairs(self.levels) do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)

		local total_width = (cols - 1) * spacing

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
										return self:load_level(tostring(i))
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
	end

	self.calibration_button = collect_into(
		self.ui_elements,
		Button({
			group = self.main,
			layer = ui_interaction_layer.Level_Select,
			x = gw * 0.9,
			y = gh * 0.84,
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
							player_units = {
								{
									type = Unit_Type.Calibration,
									timeline = {
										{ Timings.Empty },
										{ Timings.Beat },

										{ Timings.Empty },
										{ Timings.Beat },

										{ Timings.Empty },
										{ Timings.Beat },

										{ Timings.Empty },
										{ Timings.Beat },
									},
								},
							},
							layer_has_music = true,
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
end

function Level_Select:update(dt)
	self:update_game_object(dt * slow_amount)
	self.main:update(dt)
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

	-- calibration = Sound("temp/jim_combs-the-80s-called-they-want-their-synths-back-140535.ogg", music_tag),

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

function Level_Select:load_levels()
	return {
		{ name = "1" },
		{ name = "2" },
		{ name = "3" },
		-- { name = "4" },
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
