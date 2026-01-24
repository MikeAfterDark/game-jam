require("buttons")

MainMenu = Object:extend()
MainMenu:implement(State)
MainMenu:implement(GameObject)
function MainMenu:init(name)
	self:init_state(name)
	self:init_game_object()
end

function MainMenu:on_enter(from, args)
	slow_amount = 1
	music_slow_amount = 1
	-- trigger:tween(2, main_song_instance, { volume = 0.5, pitch = 1 }, math.linear)

	self.main_menu_ui = Group() --:no_camera()
	self.options_ui = Group():no_camera()
	self.keybinding_ui = Group():no_camera()
	self.credits = Group():no_camera()

	main.ui_layer_stack:push({
		layer = ui_interaction_layer.Main,
		-- music = self.main_menu_song_instance,
		layer_has_music = false,
		ui_elements = self.main_ui_elements,
	})

	self.in_menu_transition = false
	self.main_ui_elements = {}

	self.song_info_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)
	-- UI positioning:
	--
	-- [title screen][stim cave]
	-- [level selection]
	--
	menu = {
		Title = "Title",
		Map_Packs = "Map_Packs",
		Stim_Screen = "Stim_Screen",
		Levels = "Levels",
	}

	self.camera_positions = {
		Title = { x = gw * 0.5, y = gh * 0.5 },
		Stim_Screen = { x = gw * 1.5, y = gh * 0.5 },
		Levels = { x = gw * 0.5, y = gh * 1.5 },
	}
	self:setup_title_menu()
	self:setup_stim_screen()

	if args.menu_mode then
		if args.menu_mode == menu.Map_Packs then
			self:setup_map_pack_menu()
		elseif args.menu_mode == menu.Levels then
			local pack = self:get_pack_from_path(args.pack.path)
			self:setup_level_menu(pack)
		end
		self:set_ui_to(args.menu_mode)
	else
		self:set_ui_to(menu.Title)
	end

	self.current_menu = args.menu_mode or menu.Title
	self.note_y_offset = note_background and gh * 0.6 or 0
end

function MainMenu:on_exit()
	self.options_ui:destroy()
	self.keybinding_ui:destroy()
	self.main_menu_ui:destroy()
	self.t:destroy()
	self.options_ui = nil
	self.keybinding_ui = nil
	self.t = nil
	self.springs = nil
	self.flashes = nil
	self.hfx = nil
end

function MainMenu:update(dt)
	play_music({ volume = 0.3 })
	if self.song_info_text then
		self.song_info_text:update(dt)
	end

	local play_y = gh * 0.615
	self.play_button1.shape:move_to(self.play_button1.x, play_y + self.note_y_offset)
	self.play_button1.y = play_y + self.note_y_offset

	local option_y = play_y + gh * 0.07
	self.options_button.shape:move_to(self.options_button.x, option_y + self.note_y_offset)
	self.options_button.y = option_y + self.note_y_offset

	self.credits_button.shape:move_to(self.credits_button.x, gh * 0.94 + self.note_y_offset)
	self.credits_button.y = gh * 0.94 + self.note_y_offset

	if input.escape.pressed then
		if self.in_options then
			if self.in_keybinding then
				close_keybinding(self)
			else
				close_options(self)
			end
		elseif self.in_credits then
			close_credits(self)
		elseif not self.transitioning and not web then
			system.save_state()
			love.event.quit()
		end
	end

	self.main_menu_ui:update(dt * slow_amount)
	self.options_ui:update(dt * slow_amount)

	if self.in_keybinding then
		update_keybind_button_display(self)
	end
	self.keybinding_ui:update(dt * slow_amount)

	self.credits:update(dt)
end

function MainMenu:draw()
	self.main_menu_ui:draw()

	if self.in_options then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
	end
	self.options_ui:draw()

	if self.in_keybinding then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
	end
	self.keybinding_ui:draw()

	if self.in_credits then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent_2)
	end
	self.credits:draw()
	if self.song_info_text then
		local x_pos, y_pos = gw * 0.275, gh * 0.95
		graphics.rectangle(x_pos, y_pos - 5, self.song_info_text.w, self.song_info_text.h, nil, nil, modal_transparent)
		self.song_info_text:draw(x_pos, y_pos, 0, 1, 1)
	end
end

function MainMenu:setup_title_menu()
	-- print("setting up title")
	local ui_layer = ui_interaction_layer.Main
	local ui_group = self.main_menu_ui

	self.jam_name = collect_into(
		self.main_ui_elements,
		Text2({
			group = ui_group,
			x = gw / 2,
			y = gh * 0.4,
			lines = {
				{
					text = "[wavy_mid, fg]Electroaccoustic Invaders!!!",
					font = pixul_font,
					alignment = "center",
				},
			},
		})
	)

	self.title_text = collect_into(
		self.main_ui_elements,
		Text2({
			group = ui_group,
			x = gw / 2,
			y = gh * 0.35,
			lines = {
				{
					text = "[wavy_title, green]Invaders",
					font = fat_title_font,
					alignment = "center",
				},
			},
		})
	)

	self.to_stim_screen_button = collect_into(
		self.main_ui_elements,
		Button({
			group = ui_group,
			x = gw * 0.91,
			y = gh * 0.5,
			w = gw * 0.17,
			button_text = "[wavy_rainbow]Stim Cave :)",
			fg_color = "fg",
			bg_color = "black",
			action = function(b)
				main.ui_layer_stack:push({
					layer = ui_interaction_layer.Main,
					-- music = self.main_menu_song_instance,
					layer_has_music = true,
					music_type = "stim_cave",
					-- ui_elements = self.main_ui_elements,
				})
				self:set_ui_to(menu.Stim_Screen)
			end,
		})
	)

	local button_offset = gh * 0.1
	local button_dist_apart = gh * 0.08
	self.play_button1 = collect_into(
		self.main_ui_elements,
		Button({
			group = ui_group,
			x = gw / 2,
			y = gh / 2 + button_offset,
			button_text = "Play",
			fg_color = "bg",
			bg_color = "green",
			action = function(b)
				local pack = self:get_pack_from_path("dev_maps/levels/")
				if not self.levels_setup then
					self:setup_level_menu(pack)
				end
				self:set_ui_to(menu.Levels)
			end,
		})
	)
	button_offset = button_offset + button_dist_apart

	self.options_button = collect_into(
		self.main_ui_elements,
		Button({
			group = ui_group,
			x = gw / 2,
			y = gh / 2 + button_offset,
			button_text = "options",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				if not self.in_pause then
					open_options(self)
					b.selected = true
				else
					close_options(self)
				end
			end,
		})
	)
	self.credits_button = collect_into(
		self.main_ui_elements,
		Button({
			group = ui_group,
			x = gw / 2,
			y = gh * 0.3,
			button_text = "credits",
			fg_color = "bg",
			bg_color = "fg",
			action = function(b)
				open_credits(self)
				b.selected = true
			end,
		})
	)

	for _, v in pairs(self.main_ui_elements) do
		-- v.group = ui_group
		-- ui_group:add(v)

		v.layer = ui_layer
		v.force_update = true
	end
end

function MainMenu:setup_map_pack_menu()
	-- print("setting up map packs")
	local ui_layer = ui_interaction_layer.Main
	local ui_group = self.main_menu_ui
	local ui_elements = self.main_ui_elements
	local menu_id = menu.Map_Packs

	-- check src/maps for 'dev' maps
	-- check ./maps for custom maps
	local map_metadata = self:load_packs_metadata()
	local y_offset = self.camera_positions.Map_Packs.y - gh / 2

	for i, pack in ipairs(map_metadata) do
		collect_into(
			ui_elements,
			RectangleButton({
				delete_on_menu_change = menu_id,
				group = ui_group,
				x = gw / 2,
				y = (0.25 * gh * (i + 0)) + y_offset,
				w = gw * 0.1,
				h = gw * 0.1,
				force_update = true,
				image_path = pack.path .. "pack_img.png",
				title_text = pack.name,
				fg_color = "bg",
				bg_color = "fg",
				action = function()
					self:setup_level_menu(pack)
					self:set_ui_to(menu.Levels)
				end,
			})
		)
	end

	if not self.back_to_title then
		self.back_to_title = collect_into(
			ui_elements,
			Button({
				group = ui_group,
				x = gw / 2,
				y = gh * 0.05 + y_offset,
				force_update = true,
				button_text = "back to title",
				fg_color = "bg",
				bg_color = "fg",
				action = function()
					self:set_ui_to(menu.Title)
				end,
			})
		)
	end

	if not self.new_map_pack_button then
		self.new_map_pack_button = collect_into(
			ui_elements,
			Button({
				group = ui_group,
				x = gw * 0.95,
				y = gh * 0.95 + y_offset,
				w = gh * 0.05,
				force_update = true,
				button_text = "+",
				fg_color = "bg",
				bg_color = "fg",
				action = function()
					-- self:create_new_map_pack(File.is_dev_mode())
				end,
			})
		)
	end

	for _, v in pairs(self.main_ui_elements) do
		-- v.group = ui_group
		-- ui_group:add(v)

		v.layer = ui_layer
		v.force_update = true
	end
end

function MainMenu:setup_stim_screen()
	local ui_layer = ui_interaction_layer.Main
	local ui_group = self.main_menu_ui
	local x_offset = self.camera_positions.Levels.x + gw / 2
	local ui_elements = self.main_ui_elements

	local scale = gw * 0.03
	local spacing = scale * 1.1
	local x_start = x_offset + scale * 2
	local y_start = scale

	local num_rows = ((gh - y_start) / scale) - 3
	local num_columns = (gw / scale) - 6
	local function hsv_to_rgb(h, s, v)
		local r, g, b

		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p = v * (1 - s)
		local q = v * (1 - f * s)
		local t = v * (1 - (1 - f) * s)

		i = i % 6
		if i == 0 then
			r, g, b = v, t, p
		elseif i == 1 then
			r, g, b = q, v, p
		elseif i == 2 then
			r, g, b = p, v, t
		elseif i == 3 then
			r, g, b = p, q, v
		elseif i == 4 then
			r, g, b = t, p, v
		elseif i == 5 then
			r, g, b = v, p, q
		end

		return r, g, b
	end
	for i = 1, num_columns do
		for j = 1, num_rows do
			local u = (i - 1) / (num_columns - 1)
			local v = (j - 1) / (num_rows - 1)

			local hue = (u + v * 0.5 + 0.25 * math.sin(i * 0.1) + 0.25 * math.cos(j * 0.6)) % 1.0
			local sat = math.min(1, 0.7 + 0.3 * math.sin((i + j * 1.5) / 2))
			local val = math.min(1, 0.8 + 0.4 * math.sin((i * 0.8 - j * 1.2) / 3 + 1))

			local r, g, b = hsv_to_rgb(hue, sat, val)

			collect_into(
				ui_elements,
				RectangleButton({
					group = ui_group,
					x = x_start + i * spacing,
					y = y_start + j * spacing,
					w = scale,
					h = scale,
					force_update = true,
					no_image = true,
					color = Color(r, g, b, 1),
					enter_sfx = stim_cave,
					action = function(b)
						b.spring:pull(0.2, 200, 10)
						-- buttonBoop:play({ pitch = random:float(0.75, 3.05), volume = 0.5 })
					end,
				})
			)
		end
	end

	self.to_title_from_stim_button = collect_into(
		ui_elements,
		Button({
			group = ui_group,
			x = x_offset + gw * 0.04,
			y = gh / 2,
			w = gw * 0.058,
			force_update = true,
			button_text = "back",
			fg_color = "bg",
			bg_color = "fg",
			action = function()
				pop_ui_layer(self)
				self:set_ui_to(menu.Title)
			end,
		})
	)

	for _, v in pairs(self.main_ui_elements) do
		-- v.group = ui_group
		-- ui_group:add(v)

		v.layer = ui_layer
		v.force_update = true
	end
end

function MainMenu:setup_level_menu(pack)
	-- print("setting up levels, pack:")

	if type(pack.levels) ~= "table" then
		print("pack.levels is not a table! Got: " .. tostring(pack.levels))
		return
	end

	local ui_layer = ui_interaction_layer.Main
	local ui_group = self.main_menu_ui
	local y_offset = self.camera_positions.Levels.y - gh / 2
	local ui_elements = self.main_ui_elements
	local menu_id = menu.Levels

	local grid_x = 6
	local scale = gw * 0.1

	local spacing = scale * 1.2
	local total_width = (grid_x * spacing) - (spacing - scale)
	local x_start = (gw - total_width) / 2 + scale / 2 + gw * 0.125
	local y_start = y_offset + gh * 0.2

	for i, level in ipairs(pack.levels) do
		local path = pack.path .. level.path

		local col = (i - 1) % grid_x
		local row = math.floor((i - 1) / grid_x)

		collect_into(
			ui_elements,
			RectangleButton({
				delete_on_menu_change = menu_id,
				group = ui_group,
				x = x_start + col * spacing,
				y = y_start + row * spacing,
				w = scale,
				h = scale,
				wrap = level.wrap or false,
				force_update = true,
				image_path = path .. "/level_img.png",
				title_text = level.name,
				-- fg_color = "white",
				-- bg_color = "bg",
				fg_color = "white",
				bg_color = "black",
				level = level,
				action = function()
					play_level(self, {
						creator_mode = false,
						level = i,
						pack = pack,
						level_folder = level.path,
					})
				end,
			})
		)
	end

	-- TODO:? check which level is hovered over, and set its title and description + completion tracking in flavour text?
	-- (if tracking also add some indicator on the level button too)
	if not self.flavour_text then
		self.flavour_text = collect_into(
			ui_elements,
			Text2({
				group = ui_group,
				x = gw * 0.14,
				y = gh * 0.05 + y_offset, --world positioning, top-center point

				textbox_x = gw * 0.02, -- screen positioning, topleft corner
				textbox_y = gh * 0.1,

				w = gw * 0.24,
				h = gh * 0.8,
				scroll_box = true,
				-- scroll_speed = 300,
				vertical_alignment = "top",

				lines = {
					{
						text = pack.name,
						font = pixul_font,
						alignment = "center",
						wrap = gw * 0.23,
					},
					{
						text = pack.description,
						font = pixul_font,
						wrap = gw * 0.23,
					},
				},
			})
		)
	end

	if not self.back_button then
		self.back_button = collect_into(
			ui_elements,
			Button({
				group = ui_group,
				x = gw / 2,
				y = gh * 0.05 + y_offset,
				force_update = true,
				button_text = "back to title",
				fg_color = "bg",
				bg_color = "fg",
				action = function()
					self:set_ui_to(menu.Title)
				end,
			})
		)
	end

	if not self.new_level_button and love.filesystem.isFused() == false and not web then
		self.new_level_button = collect_into(
			ui_elements,
			Button({
				group = ui_group,
				x = gw * 0.95,
				y = gh * 0.95 + y_offset,
				w = gh * 0.05,
				force_update = true,
				button_text = "+",
				fg_color = "bg",
				bg_color = "fg",
				action = function()
					local level = #pack.levels + 1
					local path = #pack.levels + 1
					play_level(self, {
						creator_mode = true,
						level = level,
						pack = pack,
						level_folder = path,
					})
				end,
			})
		)
	end

	for _, v in pairs(self.main_ui_elements) do
		-- v.group = ui_group
		-- ui_group:add(v)

		v.layer = ui_layer
		v.force_update = true
	end
	self.levels_setup = true
end

function MainMenu:button_restriction()
	return self.in_menu_transition
end

function MainMenu:set_ui_to(target_menu)
	local pos = self.camera_positions[target_menu]
	if not pos then
		print("Warning: Invalid menu target '" .. tostring(target_menu) .. "'")
		return
	end

	local transition_duration = 0.4
	self.previous_menu = self.current_menu
	self.current_menu = target_menu

	self.in_menu_transition = true

	trigger:tween(transition_duration, camera, { x = pos.x, y = pos.y, r = 0 }, math.circ_in_out, function()
		camera.x, camera.y, camera.r = pos.x, pos.y, 0
		self.in_menu_transition = false

		local to_remove = {}
		for i, v in pairs(self.main_ui_elements) do
			if v.delete_on_menu_change and v.delete_on_menu_change == previous_menu then
				v.dead = true
				to_remove[#to_remove + 1] = i
			end
		end

		for _, i in ipairs(to_remove) do
			self.main_ui_elements[i] = nil
		end
	end)
end

function MainMenu:load_packs_metadata()
	local packs = {}

	for _, p in pairs(self:load_dev_packs()) do
		table.insert(packs, p)
	end
	for _, p in pairs(self:load_custom_packs()) do
		table.insert(packs, p)
	end

	-- print("Loaded Map Packs for:")
	-- for key, pack in pairs(packs) do
	-- 	print(key, pack.path)
	-- end

	return packs
end

function MainMenu:load_dev_packs()
	local packs = {}
	local fs = love.filesystem

	if not fs.getInfo("dev_maps", "directory") then
		print("[Error] 'dev_maps' folder not found.")
		return packs
	end

	for _, dir in ipairs(fs.getDirectoryItems("dev_maps")) do
		local path = "dev_maps/" .. dir .. "/"
		local info = fs.getInfo(path)
		if info and info.type == "directory" then
			local meta_path = path .. "metadata.lua"
			local meta_info = fs.getInfo(meta_path)
			if meta_info and meta_info.type == "file" then
				local ok, chunk = pcall(fs.load, meta_path)
				if ok and chunk then
					local ok2, meta = pcall(chunk)
					if ok2 and type(meta) == "table" then
						meta.path = path
						packs[random:uid()] = meta
						-- print("[OK] Loaded:", dir)
						-- print("meta: ", meta.name)
					else
						print("[Error] Invalid metadata in:", dir, "-", tostring(meta))
					end
				else
					print("[Error] Could not load:", dir, "-", tostring(chunk))
				end
			else
				print("[Warn] No metadata.lua in:", dir)
			end
		end
	end

	-- print("Loaded Dev Maps for:")
	-- for key, pack in pairs(packs) do
	-- 	print(key, pack.path)
	-- end
	return packs
end

function MainMenu:get_pack_from_path(path)
	local fs = love.filesystem
	if not path:match("/$") then
		path = path .. "/"
	end

	local meta_path = path .. "metadata.lua"
	-- print("reloading: ", meta_path)

	-- load metadata
	local chunk, load_err = fs.load(meta_path)
	if not chunk then
		print("Failed to load metadata:", load_err)
		return
	end

	local ok, metadata = pcall(chunk)
	if not ok or type(metadata) ~= "table" then
		print("Failed to execute metadata.lua:", metadata)
		return
	end

	metadata.path = path
	return metadata
end

function MainMenu:create_new_map_pack(is_dev)
	-- print("is dev: ", is_dev)
end

function MainMenu:load_custom_packs()
	local packs = {}
	local path_sep = package.config:sub(1, 1)
	local base_path = "maps"

	local p = io.popen((path_sep == "\\" and "dir /b /ad " or "ls -1 ") .. base_path)
	if not p then
		print("[Error] Failed to open maps folder.")
		return packs
	end

	for dir in p:lines() do
		local path = base_path .. path_sep .. dir .. path_sep
		local meta_path = path .. "metadata.lua"
		local f = io.open(meta_path, "r")
		if f then
			f:close()
			local ok, chunk = pcall(loadfile, meta_path)
			if ok and chunk then
				local ok2, meta = pcall(chunk)
				if ok2 and type(meta) == "table" then
					meta.path = path
					packs[random:uid()] = meta
				else
					print("[Error] Invalid metadata in:", dir)
				end
			else
				print("[Error] Failed to load:", dir)
			end
		end
	end
	p:close()

	-- print("Loaded Custom Maps for:")
	-- for key, pack in pairs(packs) do
	-- 	print(key, pack.path)
	-- end

	return packs
end
