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

	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0

	self.floor = Group()
	self.main = Group():set_as_physics_world(
		8 * global_game_scale,
		0,
		1000, --
		{ "player", "transparent", "opaque", "runner", "pill" }
	)
	self.post_main = Group()
	self.effects = Group()
	self.ui = Group():no_camera()
	self.end_ui = Group() --:no_camera()
	self.paused_ui = Group():no_camera()
	self.options_ui = Group():no_camera()
	self.keybinding_ui = Group():no_camera()
	self.credits = Group():no_camera()

	self.main:disable_collision_between("runner", "runner")
	self.main:disable_collision_between("runner", "transparent")
	self.main:disable_collision_between("runner", "pill")
	--
	--
	--
	--
	--
	self.main:enable_trigger_between("player", "transparent")
	self.main:enable_trigger_between("transparent", "player")

	self.main:enable_trigger_between("runner", "transparent")
	self.main:enable_trigger_between("transparent", "runner")

	self.main:enable_trigger_between("runner", "pill")
	self.main:enable_trigger_between("pill", "runner")
	-- self.main:enable_trigger_between("wall", "player")

	self.main_slow_amount = 1
	slow_amount = 1

	self.x1, self.y1 = 0, 0
	self.x2, self.y2 = gw, gh
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1

	-- NOTE: constants:
	grid_size = 32
	self.countdown = 3
	self.countdown_audio_timer = 3
	self.coundown_audio_index = 1
	self.countdown_audio = random:bool(50) and level_countdown_g or level_countdown_c
	self.countdown_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)
	self.level_timer_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)
	self.creator_mode_selection_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)

	-- NOTE: inits:
	checkpoint_counter = 0
	num_checkpoints = 0
	num_player_walls = 0
	self.map_builder = { runners = {}, walls = {}, pills = {} }
	self.level_folder = args.level_folder
	self.level_path = (args.pack and args.level_folder) and args.pack.path .. args.level_folder or ""
	self.creator_mode = args.creator_mode or false
	self.level = args.level or 0
	self.pack = args.pack or {}
	self.runners = {}
	self.song_info_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)

	if self.creator_mode then
		-- creator setup if any
		-- self:load_map("map.lua") -- NOTE: if load map, also add it to map_builder to avoid nil errors
	else
		-- print("Loading level: folder:", self.level_folder, ", path: ", self.level_path)
		self:load_map(self.level_path)
		-- if self.music then
		-- 	random:table(self.music):play({ volume = 0.5 })
		-- end
	end
	self.level_timer = self.level_timer or 60
	self.init_level_timer = self.level_timer

	Wall({ -- border wall, it'll "keep all the illegals out" /s
		group = self.main,
		type = wall_type.Death,
		loop = false,
		vertices = { 0, 0, gw, 0, gw, gh, 0, gh, 0, 0 },
	})

	self.in_pause = false
	self.stuck = false
	self.won = false

	-- if layer underneath this one has layer_type == "game" and the same music type then dont push
	local layer = main.ui_layer_stack:peek()
	if layer and layer.music_type ~= self.music_type then
		if layer.game then
			pop_ui_layer(self)
		end

		main.ui_layer_stack:push({
			layer = ui_interaction_layer.Game,
			layer_has_music = self.has_music,
			game = true,
			music_type = self.music_type,
			ui_elements = self.game_ui_elements,
		})
	end
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
	if self.song_info_text then
		self.song_info_text:update(dt)
	end

	if not self.in_pause and not self.stuck and not self.won then
		run_time = run_time + dt

		if self.countdown <= self.countdown_audio_timer and self.coundown_audio_index <= #self.countdown_audio then
			self.countdown_audio_timer = self.countdown_audio_timer - 1
			self.countdown_audio[self.coundown_audio_index]:play({
				pitch = 1, --[[ random:float(0.9, 1.2), ]]
				volume = 0.5,
			})
			self.coundown_audio_index = self.coundown_audio_index + 1
		end
		self.countdown = self.countdown - 1.7 * dt

		if self.countdown <= 0 and not self.died then
			self.level_timer = self.level_timer - dt
		end
	end

	if input.reset.pressed then
		if self.creator_mode then
			for _, runner in ipairs(self.runners) do
				runner:reset()
			end
		else
			play_level(self, {
				creator_mode = self.creator_mode,
				level = self.level,
				pack = self.pack,
				level_folder = self.level_folder,
			})
		end
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

			random:table(menu_loading):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
			scene_transition(
				self, --
				gw / 2,
				gh / 2,
				MainMenu("main_menu"),
				{ destination = "main_menu", args = { clear_music = true } },
				{
					text = "loading main menu...",
					font = pixul_font,
					alignment = "center",
				}
			)
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
	self.post_main:update(dt * slow_amount)
	self.effects:update(dt * slow_amount)
	self.ui:update(dt * slow_amount)
	self.end_ui:update(dt * slow_amount)
	self.paused_ui:update(dt * slow_amount)
	self.options_ui:update(dt * slow_amount)
	if self.in_keybinding then
		update_keybind_button_display(self)
	end
	self.keybinding_ui:update(dt * slow_amount)
	self.credits:update(dt * slow_amount)

	if self.level_timer > 0 then
		self.level_timer_text:set_text({
			{
				text = "[red]" .. math.floor(self.level_timer),
				font = pixul_font,
				alignment = "center",
			},
		})
	end
	if self.countdown > 0 then
		self.countdown_text:set_text({
			{
				text = "[red]" .. math.floor(self.countdown + 1),
				font = fat_font,
				alignment = "center",
			},
		})
		return
	end

	self.main:update(dt * slow_amount * self.main_slow_amount)

	local dead_runners = 0
	for _, runner in ipairs(self.runners) do
		if runner.state == Runner_State.Dead then
			dead_runners = dead_runners + 1
		end
	end

	if not self.creator_mode then
		if dead_runners == #self.runners then
			self.win = true
			self:quit()
		elseif num_checkpoints > 0 and checkpoint_counter == num_checkpoints then
			self.reason_for_loss = "they know too much"
			self:die()
		elseif self.level_timer < 0 then
			self.reason_for_loss = "the squad survived"
			self:die()
		end
	end

	if self.creator_mode then -- map creator mode
		local previous_selection = self.selection or -1

		local wheel_input = (input.wheel_up.pressed and -1 or 0) + (input.wheel_down.pressed and 1 or 0)
		self.selection = ((self.selection or 0) + wheel_input) % (#wall_type_order + 1)

		self.mouse_x, self.mouse_y = self.main:get_mouse_position()
		self.mouse_x = math.floor(self.mouse_x / grid_size) * grid_size
		self.mouse_y = math.floor(self.mouse_y / grid_size) * grid_size

		-- now you can use snapped_x, snapped_y to place objects or draw highlights
		if previous_selection ~= self.selection or not self.hovered then -- new selection
			if self.hovered then
				self.hovered = nil
			end

			local selection_text = ""
			local selection_color = ""
			if self.selection == 0 then -- player
				local sprite = knight_sprites
				self.hovered = Circle(self.mouse_x, self.mouse_y, sprite.hitbox_width)
				self.hovered.size = 1
				self.hovered.color = red[0]
				selection_text = "runner"
				selection_color = "red"
			elseif self.selection == #wall_type_order then -- pill
				self.hovered = Circle(self.mouse_x, self.mouse_y, 10)
				self.hovered.size = 10
				self.hovered.color = green[0]
				selection_text = "jump pill"
				selection_color = "green"
			else
				self.hovered = Chain(false, { self.mouse_x, self.mouse_y })
				self.hovered.color = _G[wall_type[wall_type_order[self.selection]].color][0]
				selection_text = wall_type_order[self.selection]
				selection_color = wall_type[wall_type_order[self.selection]].color
			end

			self.creator_mode_selection_text:set_text({
				{
					text = "[" .. selection_color .. "]" .. selection_text,
					font = pixul_font,
					alignment = "center",
				},
			})
		else
			if self.selection == 0 then
				self.hovered:move_to(self.mouse_x, self.mouse_y)
			elseif self.selection == #wall_type_order and not self.hovered.pill_data then
				self.hovered:move_to(self.mouse_x, self.mouse_y)
			elseif self.selection < #wall_type_order then
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
				table.insert(
					self.runners,
					Runner({
						group = self.main,
						x = runner_data.x,
						y = runner_data.y,
						size = runner_data.size,
						type = runner_data.type,
						direction = runner_data.direction,
						speed = runner_data.speed,
					})
				)
				self.hovered = nil
			elseif self.selection < #wall_type_order then
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
						elseif type.name == "Player" then
							num_player_walls = num_player_walls + 1
							data = { index = num_player_walls }
						end
						local wall_data = {
							type = type.name, -- NOTE: type.name here**
							loop = false,
							vertices = self.hovered.vertices,
							data = data,
						}

						table.insert(self.map_builder.walls, wall_data)
						Wall({
							group = self.main,
							type = type, -- NOTE: just type here**
							loop = wall_data.loop,
							vertices = wall_data.vertices,
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

		if self.selection == #wall_type_order then
			if input.m1.pressed then
				self.hovered.pill_data = {
					x = self.hovered.x,
					y = self.hovered.y,
					rs = self.hovered.size,
					boost_x = 0,
					boost_y = 0,
				}
			end

			if input.m1.down then
				local xi = self.hovered.pill_data.x - self.mouse_x
				local yi = self.hovered.pill_data.y - self.mouse_y
				self.hovered.pill_data.boost_x = xi
				self.hovered.pill_data.boost_y = yi
			end

			if input.m1.released then
				table.insert(self.map_builder.pills, self.hovered.pill_data)
				Pill({
					group = self.main,
					x = self.hovered.pill_data.x,
					y = self.hovered.pill_data.y,
					rs = self.hovered.pill_data.rs,
					boost_x = self.hovered.pill_data.boost_x,
					boost_y = self.hovered.pill_data.boost_y,
				})
				self.hovered = nil
			end
		end

		if input.space.pressed and self.hovered and #self.hovered.vertices > 4 then
			table.remove(self.hovered.vertices) -- remove duplicate starting point at end of list
			table.remove(self.hovered.vertices)

			local type = wall_type[wall_type_order[self.selection]]

			local data = nil
			if type.name == "Checkpoint" then
				num_checkpoints = num_checkpoints + 1
				data = { order = num_checkpoints }
			elseif type.name == "Player" then
				num_player_walls = num_player_walls + 1
				data = { index = num_player_walls }
			end
			local wall_data = {
				type = type.name, -- NOTE: type.name here**
				loop = false,
				vertices = self.hovered.vertices,
				data = data,
			}

			table.insert(self.map_builder.walls, wall_data)
			Wall({
				group = self.main,
				type = type, -- NOTE: just type here**
				loop = wall_data.loop,
				vertices = wall_data.vertices,
				data = wall_data.data,
			})
			self.hovered = nil
		end

		if input.s.pressed then
			print("saving map")
			self.map_builder.level_timer = 30
			self:save_map(self.map_builder)
		end
	end
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
		pills = Pill,
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

	self.level_timer = data["level_timer"]
	self.music_type = data["music_type"] or ""
	self.has_music = data["music_type"] ~= nil
end

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
	-- NOTE: lua/C jank: https://stackoverflow.com/questions/1340230/check-if-directory-exists-in-lua
	local function dir_exists(path)
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
			else
				print("Failed to write:", err)
			end
		end
	end
end

function Game:quit()
	if self.died then
		return
	end

	self.quitting = true
	if not self.win_text and not self.win_text2 and self.win and not self.won then
		local level_name = self.pack.levels[self.level].name
		local old_pb = state[level_name]
		state[level_name] = old_pb > self.level_timer and old_pb or self.level_timer
		system.save_state()
		random:table(level_victory):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
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

		ui_layer = ui_interaction_layer.Win
		self.win_ui_elements = {}
		main.ui_layer_stack:push({
			layer = ui_layer,
			layer_has_music = false,
			ui_elements = self.win_ui_elements,
		})

		trigger:after(0.5, function()
			local win_msg = random:table({
				"Knights down",
				"that'll show 'em",
				"good shit",
				"a win is a win",
				"nothin' but death",
				"area secure",
				"just a few more",
			})
			if #self.pack.levels == self.level then
				win_msg = "congrats! the dungeon is safe"
			end
			self.win_text = collect_into(
				self.win_ui_elements,
				Text2({
					group = self.end_ui,
					x = gw / 2,
					y = gh / 2 - 40 * global_game_scale,
					force_update = true,
					lines = { { text = "[wavy_mid, cbyc2]" .. win_msg, font = fat_font, alignment = "center" } },
				})
			)

			trigger:after(0.5, function()
				self.win_time_text = collect_into(
					self.win_ui_elements,
					Text2({
						group = self.end_ui,
						x = gw / 2,
						y = gh / 2 - 12 * global_game_scale,
						force_update = true,
						lines = {
							{
								text = "[wavy_mid, cbyc2]Time: " --
									.. string.format("%.2f", self.level_timer)
									.. "/"
									.. self.init_level_timer,
								font = pixul_font,
								alignment = "center",
							},
						},
					})
				)
				if old_pb and old_pb < self.level_timer then
					trigger:after(1.5, function()
						self.pb_notif_text = collect_into(
							self.win_ui_elements,
							Text2({
								group = self.end_ui,
								x = gw / 2 + 70 * global_game_scale,
								y = gh / 2 - 15 * global_game_scale,
								r = math.pi / 4,
								force_update = true,
								lines = {
									{
										text = "PB! " --
											.. (old_pb > 0 and ("(" .. string.format("%.2f", old_pb) .. ")") or ""),
										font = pixul_font,
										alignment = "center",
									},
								},
							})
						)
					end)
				end
			end)

			self.retry = collect_into(
				self.win_ui_elements,
				Button({
					group = self.end_ui,
					x = gw / 2 - 30 * global_game_scale,
					y = gh / 2 + 5 * global_game_scale,
					w = gw * 0.07,
					force_update = true,
					button_text = "[orange]redo",
					fg_color = "fg",
					bg_color = "bg_alt",
					action = function()
						play_level(self, {
							creator_mode = self.creator_mode,
							level = self.level,
							pack = self.pack,
							level_folder = self.level_folder,
						})
					end,
				})
			)

			local next_step_text = "next level"
			local next_step_function = function()
				local next_level = self.level + 1
				play_level(self, {
					creator_mode = self.creator_mode,
					level = next_level,
					pack = self.pack,
					level_folder = self.pack.levels[next_level].path,
				})
			end
			if #self.pack.levels == self.level then
				next_step_text = "main menu"
				next_step_function = function()
					print("no more levels, going back to pack", self.pack.path)

					random:table(menu_loading):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
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
			end
			self.next_step = collect_into(
				self.win_ui_elements,
				Button({
					group = self.end_ui,
					x = gw / 2 + 30 * global_game_scale,
					y = gh / 2 + 5 * global_game_scale,
					w = gw * 0.16,
					force_update = true,
					button_text = "[green]" .. next_step_text,
					fg_color = "fg",
					bg_color = "bg_alt",
					action = next_step_function,
				})
			)

			self.credits_button = collect_into(
				self.win_ui_elements,
				Button({
					group = self.end_ui,
					x = gw / 2,
					y = gh / 2 + 25 * global_game_scale,
					w = gw * 0.12,
					force_update = true,
					button_text = "[yellow]credits",
					fg_color = "fg",
					bg_color = "bg_alt",
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

	if self.countdown_text and self.countdown > 0 then
		self.countdown_text:draw(gw / 2, gh * 0.3)
	end

	if self.level_timer_text then
		self.level_timer_text:draw(gh * 0.05, gh * 0.05)
	end

	if self.creator_mode_selection_text then
		self.creator_mode_selection_text:draw(gw * 0.7, gh * 0.95)
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

	if self.song_info_text then
		local x_pos, y_pos = gw * 0.275, gh * 0.95
		graphics.rectangle(x_pos, y_pos - 5, self.song_info_text.w, self.song_info_text.h, nil, nil, modal_transparent)
		self.song_info_text:draw(x_pos, y_pos, 0, 1, 1)
	end
end

function Game:die()
	if not self.died_text and not self.won then
		random:table(level_failure):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
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
				y = gh / 2,
				force_update = true,
				lines = {
					{
						text = "[wavy_mid, cbyc_fast]" .. self.reason_for_loss,
						font = fat_font,
						alignment = "center",
					},
				},
			})
		)

		self.t:after(0.8, function()
			play_level(self, {
				fast_load = true,
				creator_mode = self.creator_mode,
				level = self.level,
				pack = self.pack,
				level_folder = self.level_folder,
			})

			-- self.died_restart_button = collect_into(
			-- 	self.game_loss_ui_elements,
			-- 	Button({
			-- 		group = ui_group,
			-- 		layer = ui_layer,
			-- 		x = gw / 2,
			-- 		y = gh / 2 + 20,
			-- 		force_update = true,
			-- 		button_text = "run it back",
			-- 		fg_color = "bg",
			-- 		bg_color = "green",
			-- 		action = function(b)
			-- 			play_level(self, {
			-- 				fast_load = true,
			-- 				creator_mode = self.creator_mode,
			-- 				level = self.level,
			-- 				pack = self.pack,
			-- 				level_folder = self.level_folder,
			-- 			})
			-- 		end,
			-- 	})
			-- )
		end)
		-- trigger:tween(2, camera, { x = gw / 2, y = gh / 2, r = 0 }, math.linear, function()
		-- 	camera.x, camera.y, camera.r = gw / 2, gh / 2, 0
		-- end)
	end
	return true
end
