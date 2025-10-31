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

	-- UI positioning:
	--
	-- [title screen]
	-- [map selection]
	-- [level selection]
	--
	menu = {
		Title = "Title",
		Map_Packs = "Map_Packs",
		Levels = "Levels",
	}

	self.camera_positions = {
		Title = { x = gw / 2, y = gh * 0.5 },
		Map_Packs = { x = gw / 2, y = gh * 1.5 },
		Levels = { x = gw / 2, y = gh * 2.5 },
	}
	self:setup_title_menu()

	if args.menu_mode then
		if args.menu_mode == menu.Map_Packs then
			self:setup_map_pack_menu()
		elseif args.menu_mode == menu.Levels then
			self:setup_level_menu(args.pack)
		end
		self:set_ui_to(args.menu_mode)
	end

	self.current_menu = args.menu_mode or menu.Title
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
	-- if camera.y ~= self.camera_positions[self.current_menu].y and not self.in_menu_transition then
	-- 	counter = counter and (counter + 1) or 0
	-- 	print(counter)
	-- end

	play_music({ volume = 0.3 })

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
	-- if camera.y ~= self.camera_positions[self.current_menu].y and not self.in_menu_transition then
	-- 	local pos = self.camera_positions[self.current_menu]
	-- 	camera.x, camera.y, camera.r = pos.x, pos.y, 0
	-- end
end

function MainMenu:draw()
	graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)

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
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.credits:draw()
end

function MainMenu:setup_title_menu()
	print("setting up title")
	local ui_layer = ui_interaction_layer.Main
	local ui_group = self.main_menu_ui

	self.jam_name = collect_into(
		self.main_ui_elements,
		Text2({
			group = ui_group,
			x = gw / 2,
			y = gh * 0.05,
			lines = {
				{
					text = "[wavy_mid, fg]beep boop",
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
			y = gh / 2,
			lines = {
				{
					text = "[wavy_title, green]title",
					font = fat_title_font,
					alignment = "center",
				},
			},
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
				self:setup_map_pack_menu()
				self:set_ui_to(menu.Map_Packs)
				-- play_level(self)
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
			y = gh * 0.95,
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
	print("setting up map packs")
	local ui_layer = ui_interaction_layer.Main
	local ui_group = self.main_menu_ui
	local ui_elements = self.main_ui_elements
	local menu_id = menu.Map_Packs

	-- check src/maps for 'dev' maps
	-- check ./maps for custom maps
	local map_metadata = self:load_packs_metadata()
	local y_offset = self.camera_positions.Map_Packs.y - gh / 2

	counter = counter and (counter + 1) or 0

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
				title_text = pack.name .. counter,
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

	for _, v in pairs(self.main_ui_elements) do
		-- v.group = ui_group
		-- ui_group:add(v)

		v.layer = ui_layer
		v.force_update = true
	end
end

function MainMenu:setup_level_menu(pack)
	print("setting up levels")
	local ui_layer = ui_interaction_layer.Main
	local ui_group = self.main_menu_ui
	local y_offset = self.camera_positions.Levels.y - gh / 2
	local ui_elements = self.main_ui_elements
	local menu_id = menu.Levels

	for i, level in ipairs(pack.levels) do
		local path = pack.path .. level.path
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
				image_path = path .. "/level_img.png",
				title_text = level.name .. counter,
				fg_color = "bg",
				bg_color = "fg",
				action = function()
					print("loading level: " .. path .. "/path.lua")
					play_level(self, {
						creator_mode = false,
						level = i,
						pack = pack,
						level_path = path .. "/map.lua",
					})
				end,
			})
		)
	end

	if not self.back_to_map_packs_button then
		self.back_to_map_packs_button = collect_into(
			ui_elements,
			Button({
				group = ui_group,
				x = gw / 2,
				y = gh * 0.05 + y_offset,
				force_update = true,
				button_text = "back to packs",
				fg_color = "bg",
				bg_color = "fg",
				action = function()
					self:setup_map_pack_menu() -- NOTE: debatable if this is needed, forces a reload of map packs
					self:set_ui_to(menu.Map_Packs)
				end,
			})
		)
	end

	if not self.new_level_button then
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
					local path = pack.levels[#pack.levels].path .. "1" -- TODO: not this
					self:add_level_to_metadata(pack, level, path)
					play_level(self, {
						creator_mode = true,
						level = level,
						pack = pack,
						level_path = pack.path .. path .. "/map.lua",
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
	local previous_menu = self.current_menu
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

function MainMenu:add_level_to_metadata(pack, name, level_path)
	local metadata_path = pack.path .. "metadata.lua"

	-- Load the metadata file as a Lua chunk
	local chunk, err = love.filesystem.load(metadata_path)
	if not chunk then
		print("Failed to load metadata: " .. tostring(err))
		return
	end

	-- Execute the chunk to get the table
	local ok, metadata = pcall(chunk)
	if not ok or type(metadata) ~= "table" then
		print("Invalid metadata file format at: " .. metadata_path)
		return
	end

	-- Ensure the levels table exists
	metadata.levels = metadata.levels or {}

	-- Add the new level entry
	table.insert(metadata.levels, {
		name = name,
		path = level_path,
	})

	-- Serialize the updated table back to Lua code
	local function serialize_table(tbl, indent)
		indent = indent or ""
		local next_indent = indent .. "\t"
		local parts = { "{\n" }
		for k, v in pairs(tbl) do
			local key_str
			if type(k) == "string" and k:match("^[%a_][%w_]*$") then
				key_str = k .. " = "
			else
				key_str = "[" .. string.format("%q", k) .. "] = "
			end
			if type(v) == "table" then
				table.insert(parts, next_indent .. key_str .. serialize_table(v, next_indent) .. ",\n")
			elseif type(v) == "string" then
				table.insert(parts, next_indent .. key_str .. string.format("%q", v) .. ",\n")
			else
				table.insert(parts, next_indent .. key_str .. tostring(v) .. ",\n")
			end
		end
		table.insert(parts, indent .. "}")
		return table.concat(parts)
	end

	local output = "return " .. serialize_table(metadata)

	-- Write back to file
	local success, message = love.filesystem.write(metadata_path, output)
	if success then
		print("✅ Metadata updated successfully at: " .. metadata_path)
	else
		print("❌ Failed to write metadata at: " .. metadata_path .. " (" .. tostring(message) .. ")")
	end
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
