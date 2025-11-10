Game = Object:extend()
Game:implement(State)
Game:implement(GameObject)
function Game:init(name)
	self:init_state(name)
	self:init_game_object()
end

function Game:on_enter(from, args)
	self.hfx:add("condition1", 1)
	self.hfx:add("condition2", 1)

	main.ui_layer_stack:push({
		layer = ui_interaction_layer.Game,
		layer_has_music = false,
		ui_elements = self.game_ui_elements,
	})
	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0

	self.floor = Group()
	self.main = Group():set_as_physics_world(
		8 * global_game_scale,
		0,
		1000, --
		{ "player", "transparent", "opaque", "runner" }
	)
	self.post_main = Group()
	self.effects = Group()
	self.ui = Group():no_camera()
	self.end_ui = Group() --:no_camera()
	self.paused_ui = Group():no_camera()
	self.options_ui = Group():no_camera()
	self.keybinding_ui = Group():no_camera()
	self.credits = Group():no_camera()

	self.main:disable_collision_between("player", "player")
	self.main:disable_collision_between("player", "transparent")
	self.main:disable_collision_between("runner", "runner")
	--
	self.main:enable_trigger_between("player", "transparent")
	self.main:enable_trigger_between("transparent", "player")
	-- self.main:enable_trigger_between("wall", "player")

	self.main_slow_amount = 1
	slow_amount = 1

	self.x1, self.y1 = 0, 0
	self.x2, self.y2 = gw, gh
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1

	-- NOTE: constants:
	grid_size = 32
	min_player_size = 16
	max_player_size = 64
	self._player_speed = 200 * global_game_scale
	self._player_size = 32

	-- NOTE: inits:
	checkpoint_counter = 0
	num_checkpoints = 0
	self.map_builder = { runners = {}, walls = {}, pills = {} }
	self.level_folder = args.level_folder
	self.level_path = (args.pack and args.level_folder) and args.pack.path .. args.level_folder or ""
	self.creator_mode = args.creator_mode or false
	self.level = args.level or 0
	self.pack = args.pack or {}
	self.runners = {}

	if self.creator_mode then
		-- creator setup if any
		-- self:load_map("map.lua") -- NOTE: if load map, also add it to map_builder to avoid nil errors
	else
		-- print("Loading level: folder:", self.level_folder, ", path: ", self.level_path)
		self:load_map(self.level_path)
	end

	Wall({ -- border wall, it'll "keep all the illegals out" /s
		group = self.main,
		type = wall_type.Death,
		loop = false,
		vertices = { 0, 0, gw, 0, gw, gh, 0, gh, 0, 0 },
	})

	self.in_pause = false
	self.stuck = false
	self.won = false
end

function Game:on_exit()
	self.main:destroy()
	self.post_main:destroy()
	self.effects:destroy()
	self.ui:destroy()
	self.end_ui:destroy()
	self.paused_ui:destroy()
	self.options_ui:destroy()
	self.keybinding_ui:destroy()

	self.main = nil
	self.post_main = nil
	self.effects = nil
	self.ui = nil
	self.end_ui = nil
	self.paused_ui = nil
	self.options_ui = nil
	self.keybinding_ui = nil
	self.credits = nil
	self.flashes = nil
	self.hfx = nil
end

function Game:update(dt)
	play_music({ volume = 0.3 })

	if not self.in_pause and not self.stuck and not self.won then
		run_time = run_time + dt
	end

	if input.reset.pressed then
		play_level(self, {
			creator_mode = self.creator_mode,
			level = self.level,
			pack = self.pack,
			level_folder = self.level_folder,
		})
	end

	if self.win then
		self:quit()
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
			scene_transition(self, gw / 2, gh / 2, MainMenu("main_menu"), { destination = "main_menu", args = {} }, {
				text = "loading main menu...",
				font = pixul_font,
				alignment = "center",
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

	star_group:update(dt * slow_amount)
	self.floor:update(dt * slow_amount)
	self.main:update(dt * slow_amount * self.main_slow_amount)
	self.post_main:update(dt * slow_amount)
	self.effects:update(dt * slow_amount)
	self.ui:update(dt * slow_amount)
	self.end_ui:update(dt * slow_amount)
	self.paused_ui:update(dt * slow_amount)
	self.options_ui:update(dt * slow_amount)

	if self.spawn then
		local a = Player({
			group = self.main, --
			x = self.spawn.x,
			y = self.spawn.y,
			size = self.spawn.size,
			speed = self.spawn.speed,
			color = self.spawn.color,
			color_text = "black",
			init_wall_normal = self.spawn.init_wall_normal,
			tutorial = true,
		})
		a:set_velocity(self.spawn.vx, self.spawn.vy)
		self.spawn = nil
	end

	local dead_runners = 0
	for _, runner in ipairs(self.runners) do
		if runner.state == Runner_State.Dead then
			dead_runners = dead_runners + 1
		end
	end

	local allowed_dead = 3
	if dead_runners > allowed_dead then
		self:die()
	end

	if self.creator_mode then -- map creator mode
		local previous_selection = self.selection or -1

		local wheel_input = (input.wheel_up.pressed and -1 or 0) + (input.wheel_down.pressed and 1 or 0)
		self.selection = ((self.selection or 0) + wheel_input) % #wall_type_order

		self.mouse_x, self.mouse_y = self.main:get_mouse_position()
		self.mouse_x = math.floor(self.mouse_x / grid_size) * grid_size
		self.mouse_y = math.floor(self.mouse_y / grid_size) * grid_size

		-- now you can use snapped_x, snapped_y to place objects or draw highlights
		if previous_selection ~= self.selection or not self.hovered then -- new selection
			if self.hovered then
				self.hovered = nil
			end

			if self.selection == 0 then -- player
				local sprite = knight_sprites
				self.hovered = Circle(self.mouse_x, self.mouse_y, sprite.hitbox_width)
				self.hovered.size = 1
				self.hovered.color = red[0]
			else -- choose a wall
				self.hovered = Chain(false, { self.mouse_x, self.mouse_y }) --Rectangle(mouse_x, mouse_y, gh * 0.1, gh * 0.1)
				self.hovered.color = _G[wall_type[wall_type_order[self.selection]].color][0]
				-- self.hovered.xy_scale = Vector(1, 1)
				-- self.hovered.rotated = 0
			end
		else
			if self.selection == 0 then
				self.hovered:move_to(self.mouse_x, self.mouse_y)
			else
				self.hovered.vertices[#self.hovered.vertices - 1] = self.mouse_x
				self.hovered.vertices[#self.hovered.vertices] = self.mouse_y
			end
		end

		if not self.hovered then
			return
		end

		local fraction = 0.1
		if self.selection == 0 then
			if input.z.pressed and self.hovered.size > 1 then
				self.hovered.rs = self.hovered.rs * (1 - fraction)
				self.hovered.size = self.hovered.size - 1
			end

			if input.x.pressed then
				self.hovered.rs = self.hovered.rs * (1 + fraction)
				self.hovered.size = self.hovered.size + 1
			end
		end

		if input.m1.pressed then
			if self.selection == 0 then
				local runner_data = {
					x = self.hovered.x,
					y = self.hovered.y,
					size = self.hovered.size,
					type = "knight",
					direction = "right",
					speed = 200,
				}

				table.insert(self.map_builder.runners, runner_data)
				Runner({
					group = self.main,
					x = runner_data.x,
					y = runner_data.y,
					size = runner_data.size,
					type = runner_data.type,
					direction = runner_data.direction,
					speed = runner_data.speed,
				})
				self.hovered = nil
			else
				if
					#self.hovered.vertices <= 2
					or self.mouse_x ~= self.hovered.vertices[#self.hovered.vertices - 3]
					or self.mouse_y ~= self.hovered.vertices[#self.hovered.vertices - 2]
				then
					if #self.hovered.vertices >= 8 and self.mouse_x == self.hovered.vertices[1] and self.mouse_y == self.hovered.vertices[2] then
						-- table.remove(self.hovered.vertices) -- remove duplicate starting point at end of list
						-- table.remove(self.hovered.vertices) -- only for loop = true

						local type = wall_type[wall_type_order[self.selection]]

						local data = nil
						if type.name == "Checkpoint" then
							num_checkpoints = num_checkpoints + 1
							data = { order = num_checkpoints }
						end
						local wall_data = {
							type = type.name, -- NOTE: type.name here**
							loop = false,
							vertices = self.hovered.vertices,
							color = self.hovered.color,
							data = data,
						}

						table.insert(self.map_builder.walls, wall_data)
						Wall({
							group = self.main,
							type = type, -- NOTE: just type here**
							loop = wall_data.loop,
							vertices = wall_data.vertices,
							color = wall_data.color,
							data = wall_data.data,
						})
						self.hovered = nil
					end

					if self.hovered then
						table.insert(self.hovered.vertices, self.mouse_x)
						table.insert(self.hovered.vertices, self.mouse_y)
					end
				end
			end
		end

		if input.space.pressed and self.hovered and #self.hovered.vertices >= 4 then
			table.remove(self.hovered.vertices) -- remove duplicate starting point at end of list
			table.remove(self.hovered.vertices)

			local type = wall_type[wall_type_order[self.selection]]

			local data = nil
			if type.name == "Checkpoint" then
				num_checkpoints = num_checkpoints + 1
				data = { order = num_checkpoints }
			end
			local wall_data = {
				type = type.name, -- NOTE: type.name here**
				loop = false,
				vertices = self.hovered.vertices,
				color = self.hovered.color,
				data = data,
			}

			table.insert(self.map_builder.walls, wall_data)
			Wall({
				group = self.main,
				type = type, -- NOTE: just type here**
				loop = wall_data.loop,
				vertices = wall_data.vertices,
				color = wall_data.color,
				data = wall_data.data,
			})
			self.hovered = nil
		end

		if input.s.pressed then
			print("saving map")
			self:save_map(self.map_builder)
		end
	end

	-------------------------------------------------------------
	----------------------- UI MENU STUFF -----------------------
	-------------------------------------------------------------

	if self.in_keybinding then
		update_keybind_button_display(self)
	end
	self.keybinding_ui:update(dt * slow_amount)
	self.credits:update(dt * slow_amount)

	-- if input.m2.pressed then -- NOTE: PLAYTIME DEBUG TEXT
	-- 	if not self.counter then
	-- 		self.counter = 1
	-- 	end
	-- 	if not self.debug then
	-- 		self.debug = Text2({
	-- 			group = self.ui,
	-- 			x = 100,
	-- 			y = 20,
	-- 			force_update = true,
	-- 			lines = {
	-- 				{
	-- 					-- text = tostring(main.current_music_type),
	-- 					-- text = string.format("%.2f", self.map.song_position),
	-- 					text = tostring(num_checkpoints),
	-- 					font = pixul_font,
	-- 					alignment = "center",
	-- 				},
	-- 			},
	-- 		})
	-- 	end
	-- end
	-- if input.m3.pressed and self.debug then
	-- 	self.debug:clear()
	-- 	self.debug = nil
	-- end
end

function Game:load_map(map_path)
	local path = map_path .. "/map.lua"

	local chunk, err = love.filesystem.load(path)
	if not chunk then
		error("Failed to load map for (" .. path .. "): " .. err)
		return
	end

	local data = chunk()
	if not data then
		return
	end

	local object_registry = {
		runners = Runner,
		walls = Wall,
		-- pills = Pill,
	}

	for key, constructor in pairs(object_registry) do
		local objects = data[key]
		if objects then
			for _, obj_data in ipairs(objects) do
				obj_data.group = self.main
				local obj = constructor(obj_data)
				if key == "runners" then
					table.insert(self.runners, obj)
				end
			end
		end
	end
end

-- if data then
-- 	for _, runner in ipairs(data.runners) do
-- 		Runner({
-- 			group = self.main,
-- 			type = runner_type[runner.type],
-- 			direction = runner.direction,
-- 			speed = runner.speed,
-- 			size = runner.size,
-- 			pill_effectiveness = runner.pill_effectiveness,
-- 		})
-- 	end
--
-- 	for _, wall in ipairs(data.walls) do
-- 		Wall({
-- 			group = self.main,
-- 			type = wall_type[wall.type],
-- 			loop = wall.loop,
-- 			vertices = wall.vertices,
-- 			data = wall.data,
-- 		})
-- 	end
--
-- 	for _, pill in ipairs(data.pills) do
-- 		Pill({
-- 			group = self.main,
-- 			type = pill_type[pill.type],
-- 			x = pill.x,
-- 			y = pill.y,
-- 			w = pill.size,
-- 			h = pill.size,
-- 			respawn_time = pill.respawn_time,
-- 			strength = pill.strength,
-- 		})
-- 	end
-- end

function Game:save_map(map)
	-- local player_data = nil
	-- local walls_data = {}
	--
	-- for _, obj in ipairs(map) do
	-- 	if obj.dead ~= true then
	-- 		if obj:is(Player) then
	-- 			player_data = {
	-- 				x = obj.spawn.x,
	-- 				y = obj.spawn.y,
	-- 				size = obj.size,
	-- 				speed = obj.speed,
	-- 			}
	-- 		elseif obj:is(Wall) then
	-- 			table.insert(walls_data, {
	-- 				type = obj.type.name,
	-- 				loop = obj.loop,
	-- 				vertices = obj.vertices,
	-- 				data = obj.data,
	-- 			})
	-- 		end
	-- 	end
	-- end
	--
	-- local function table_to_lua(t, indent)
	-- 	indent = indent or 0
	-- 	local indent_str = string.rep("    ", indent)
	-- 	local result = "{\n"
	--
	-- 	for k, v in pairs(t) do
	-- 		local key = type(k) == "string" and k .. " = " or ""
	-- 		if type(v) == "table" then
	-- 			result = result .. indent_str .. "    " .. key .. table_to_lua(v, indent + 1) .. ",\n"
	-- 		elseif type(v) == "string" then
	-- 			result = result .. indent_str .. "    " .. key .. string.format("%q", v) .. ",\n"
	-- 		else
	-- 			result = result .. indent_str .. "    " .. key .. tostring(v) .. ",\n"
	-- 		end
	-- 	end
	--
	-- 	result = result .. indent_str .. "}"
	-- 	return result
	-- end
	--
	-- local output = "return {\n"
	-- output = output .. "    player = " .. table_to_lua(player_data, 1) .. ",\n"
	-- output = output .. "    walls = " .. table_to_lua(walls_data, 1) .. "\n"
	-- output = output .. "}"
	--

	-- serialize and write back
	local output = "return " .. table.tostring(map)
	-- local f, err = io.open(meta_path, "w")
	-- if f then
	-- 	f:write("return " .. table.tostring(metadata))
	-- 	f:close()
	-- 	-- print("Wrote directly to:", meta_path)
	-- else
	-- 	print("Failed to write:", err)
	-- end

	local dev_mode = love.filesystem.isFused() == false
	local path = self.level_path .. "/map.lua"
	local saved_level = false
	local new_level_folder = false

	---
	--- folder jank ---
	---
	local function dir_exists(path) -- NOTE: lua/C jank: https://stackoverflow.com/questions/1340230/check-if-directory-exists-in-lua
		local ok, err, code = os.rename(path, path)
		return ok or code == 13 -- code 13 = permission denied (means it exists)
	end

	local dir = path:match("^(.*[/\\])")
	if dir then
		if not dir_exists(dir) then
			-- print("creating new dir:", dir)
			new_level_folder = true
			os.execute('mkdir -p "' .. dir .. '"')
		else
			-- print("dir already exists:", dir)
		end
	end

	---
	--- write the file jank ---
	---
	if dev_mode then
		local file = io.open(path, "w")
		if file then
			file:write(output)
			file:close()
			saved_level = true
			print("written to project file successfully at: " .. path)
		else
			print("failed to open project file for writing at: " .. path)
		end
	else
		local success, message = love.filesystem.write(path, output)
		if success then
			saved_level = true
			-- print("written to save directory successfully at: " .. path)
		else
			print("failed to write file: " .. tostring(message))
		end
	end

	if saved_level then
		if new_level_folder then
			-- print("Edit metadata to add level:", self.pack.path)
			local fs = love.filesystem
			local path = self.pack.path
			if not path:match("/$") then
				path = path .. "/"
			end

			local meta_path = path .. "metadata.lua"

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

			-- modify metadata
			metadata.levels = metadata.levels or {}
			table.insert(metadata.levels, { name = "temp", path = self.level_folder })

			-- serialize and write back
			local data = "return " .. table.tostring(metadata)
			local f, err = io.open(meta_path, "w")
			if f then
				f:write("return " .. table.tostring(metadata))
				f:close()
				-- print("Wrote directly to:", meta_path)
			else
				print("Failed to write:", err)
			end
		end
	end
end

function Game:quit()
	-- if self.died then
	-- 	return
	-- end

	self.quitting = true
	if not self.win_text and not self.win_text2 and self.win then
		input:set_mouse_visible(true)
		self.won = true
		locked_state = nil
		system.save_run()
		trigger:tween(1, _G, { slow_amount = 0 }, math.linear, function()
			slow_amount = 0
		end, "slow_amount")
		trigger:tween(1, _G, { music_slow_amount = 0 }, math.linear, function()
			music_slow_amount = 0
		end, "music_slow_amount")
		-- trigger:tween(4, camera, { x = gw / 2, y = gh / 2, r = 0 }, math.linear, function()
		-- 	camera.x, camera.y, camera.r = gw / 2, gh / 2, 0
		-- end)

		ui_layer = ui_interaction_layer.Win
		self.win_ui_elements = {}
		main.ui_layer_stack:push({
			layer = ui_layer,
			layer_has_music = false,
			ui_elements = self.win_ui_elements,
		})

		self.win_text = collect_into(
			self.win_ui_elements,
			Text2({
				group = self.end_ui,
				x = gw / 2,
				y = gh / 2 - 40 * global_game_scale,
				force_update = true,
				lines = { { text = "[wavy_mid, cbyc2]congratulations!", font = fat_font, alignment = "center" } },
			})
		)

		trigger:after(0.5, function()
			if #self.pack.levels > self.level then
				local next_level = self.level + 1
				play_level(self, {
					creator_mode = self.creator_mode,
					level = next_level,
					pack = self.pack,
					level_folder = self.pack.levels[next_level].path,
				})
			else
				print("no more levels, going back to pack", self.pack.path)

				scene_transition(
					self,
					gw / 2,
					gh / 2,
					MainMenu("main_menu"),
					{ destination = "main_menu", args = { menu_mode = menu.Levels, pack = self.pack } },
					{
						text = "loading main menu...",
						font = pixul_font,
						alignment = "center",
					}
				)
			end

			self.win_text2 = collect_into(
				self.win_ui_elements,
				Text2({
					group = self.end_ui,
					x = gw / 2,
					y = gh / 2,
					force_update = true,
					lines = {
						{
							text = "[fg]level beat",
							font = pixul_font,
							alignment = "center",
							height_multiplier = 1.24,
						},
					},
				})
			)
			self.credits_button = collect_into(
				self.win_ui_elements,
				Button({
					group = self.end_ui,
					x = gw / 2,
					y = gh / 2 + 35 * global_game_scale,
					force_update = true,
					button_text = "credits",
					fg_color = "bg",
					bg_color = "fg",
					action = function()
						open_credits(self)
					end,
				})
			)

			for _, v in pairs(self.win_ui_elements) do
				-- v.group = ui_group
				-- ui_group:add(v)

				v.layer = ui_layer
				v.force_update = true
			end
		end)

		self.t:after(2, function()
			self.slow_transitioning = true
			self.t:tween(0.7, self, { main_slow_amount = 0 }, math.linear, function()
				self.main_slow_amount = 0
			end)
			slow_amount = 1
			music_slow_amount = 1
		end)
	end
end

function Game:draw()
	self.floor:draw()
	self.main:draw()
	self.post_main:draw()
	self.effects:draw()

	if self.death_circle then
		self.death_circle:draw(_G["red"][0], 11)
	end

	if self.hovered then
		self.hovered:draw(self.hovered.color, 10)
		graphics.circle(self.mouse_x, self.mouse_y, 10, self.hovered.color, 5)
	end
	self.ui:draw()

	graphics.draw_with_mask(function()
		star_canvas:draw(0, 0, 0, 1, 1)
	end, function()
		camera:attach()
		graphics.rectangle(gw / 2, gh / 2, self.w, self.h, nil, nil, fg[0])
		camera:detach()
	end, true)

	if self.win or self.died then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.end_ui:draw()

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

function Game:die()
	if not self.died_text then
		input:set_mouse_visible(true)
		self.died = true
		locked_state = nil
		system.save_run()

		self.t:tween(2, self, { main_slow_amount = 0 }, math.linear, function()
			self.main_slow_amount = 0
		end)
		self.t:tween(2, _G, { music_slow_amount = 0 }, math.linear, function()
			music_slow_amount = 0
		end)

		main.current.in_death = true
		local ui_layer = ui_interaction_layer.GameLoss
		local ui_group = self.end_ui
		self.game_loss_ui_elements = {}
		main.ui_layer_stack:push({
			layer = ui_layer,
			layer_has_music = false,
			ui_elements = self.game_loss_ui_elements,
		})

		self.died_text = collect_into(
			self.game_loss_ui_elements,
			Text2({
				group = ui_group,
				layer = ui_layer,
				x = gw / 2,
				y = gh / 2 - 32 * global_game_scale,
				force_update = true,
				lines = {
					{
						text = "[wavy_mid, cbyc_fast]The Squad Died",
						font = fat_font,
						alignment = "center",
					},
				},
			})
		)

		self.t:after(0.75, function()
			-- self.died_text2 = collect_into(
			-- 	self.game_loss_ui_elements,
			-- 	Text2({
			-- 		group = ui_group,
			-- 		layer = ui_layer,
			-- 		force_update = true,
			-- 		x = gw / 2,
			-- 		y = gh / 2,
			-- 		lines = {
			-- 			{
			-- 				text = "[wavy_mid, cbyc2]try again?",
			-- 				font = fat_font,
			-- 				alignment = "center",
			-- 			},
			-- 		},
			-- 	})
			-- )

			camera:shake(5, 0.075)
			buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
			self.died_restart_button = collect_into(
				self.game_loss_ui_elements,
				Button({
					group = ui_group,
					layer = ui_layer,
					x = gw / 2,
					y = gh / 2 + 20,
					force_update = true,
					button_text = "run it back",
					fg_color = "bg",
					bg_color = "green",
					action = function(b)
						play_level(self, {
							creator_mode = self.creator_mode,
							level = self.level,
							pack = self.pack,
							level_folder = self.level_folder,
						})
					end,
				})
			)
		end)
		-- trigger:tween(2, camera, { x = gw / 2, y = gh / 2, r = 0 }, math.linear, function()
		-- 	camera.x, camera.y, camera.r = gw / 2, gh / 2, 0
		-- end)
	end
	return true
end
