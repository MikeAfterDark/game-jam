require("station")
require("rail")

Game = Object:extend()
Game:implement(State)
Game:implement(GameObject)
function Game:init(name)
	self:init_state(name)
	self:init_game_object()
end

function Game:on_enter(from, args) -- level, num_players, player_inputs)
	self.hfx:add("condition1", 1)
	self.hfx:add("condition2", 1)
	self.level = args.level or 1
	self.start_time = 4
	self.t:every(1, function()
		if self.start_time > -1 then
			self.start_time = self.start_time - 1
		end
	end)

	main.ui_layer_stack:push({
		layer = ui_interaction_layer.Main,
		layer_has_music = false,
		ui_elements = self.game_ui_elements,
	})
	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0

	self.floor = Group()
	self.main = Group():set_as_physics_world(
		32 * global_game_scale,
		0,
		0,
		-- { "player", "boss", "projectile", "boss_projectile" } -- "force_field", "longboss" }
		{ "station", "train", "rail" }
	)
	self.post_main = Group()
	self.effects = Group()
	self.ui = Group():no_camera()
	self.paused_ui = Group():no_camera()
	self.options_ui = Group():no_camera()
	self.keybinding_ui = Group():no_camera()
	self.credits = Group():no_camera()

	self.main:disable_collision_between("train", "train")
	self.main:disable_collision_between("train", "station")
	self.main:disable_collision_between("train", "rail")

	self.main:disable_collision_between("station", "station")
	self.main:disable_collision_between("station", "rail")

	self.main:disable_collision_between("rail", "rail")

	self.main:enable_trigger_between("train", "train")
	self.main:enable_trigger_between("train", "station")
	self.main:enable_trigger_between("station", "rail")
	self.main:enable_trigger_between("rail", "rail")

	self.main_slow_amount = 1

	-- Spawn solids and player
	self.x1, self.y1 = 0, 0
	self.x2, self.y2 = gw, gh
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1

	self.stations = {}
	self.rails = {}
	self.trains = {}
	self.current_rail = nil

	self.timer_text = Text({
		{
			text = "[fg]60.00",
			font = mystery_font,
			alignment = "left",
		},
	}, global_text_tags)
	self.wasnt_timed_mode = true

	-- NOTE: GAME DESIGN TOOLS:
	self.time_per_round = 60
	self.min_distance_between_stations = 120
	self.absolute_min_distance_between_stations = 65

	self.timer = self.time_per_round
	self.tutorial_elements = {}
	if state.tutorial then
		if main.current.transitioning then
			return
		end
		self.t:after(1.5, function()
			if main.current.transitioning then
				return
			end
			collect_into(
				self.tutorial_elements,
				Text2({
					group = self.ui,
					x = gw / 2,
					y = gh / 2 - 70 * global_game_scale,
					force_update = true,
					lines = {
						{
							text = "[wavy, cbyc]Goal:",
							font = pixul_font,
							alignment = "center",
						},
					},
				})
			)
			self.t:after(1.4, function()
				if main.current.transitioning then
					return
				end
				collect_into(
					self.tutorial_elements,
					Text2({
						group = self.ui,
						x = gw / 2,
						y = gh / 2 - 40 * global_game_scale,
						force_update = true,
						lines = {
							{
								text = "[wavy, green]connect [fg]all the [wavy, red]disconnected [fg]orbs based on their [wavy]ne[wavy, green]eds",
								font = pixul_font,
								alignment = "center",
							},
						},
					})
				)
				self.t:after(5, function()
					if main.current.transitioning then
						return
					end
					buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
					camera:shake(3, 0.075)
					collect_into(
						self.tutorial_elements,
						Text2({
							group = self.ui,
							x = gw / 2,
							y = gh / 2 - 15 * global_game_scale,
							force_update = true,
							lines = {
								{
									text = "[wavy, bg5]BLACK [fg] connections can be connected [wavy]transitively",
									font = pixul_font,
									alignment = "center",
								},
								{
									text = "[wavy, green]GREEN [fg] connections [wavy fg]MUST [fg] be connected [wavy, green]directly",
									font = pixul_font,
									alignment = "center",
								},
								{
									text = (
										state.timed_mode and "[green]connect [wavy, fg]ALL [fg]of the orbs to reset the [wavy, fg]CLOCK"
										or "try 'timed mode' for a challenge"
									),
									font = pixul_font,
									alignment = "center",
								},
							},
						})
					)
					self.t:after(7, function()
						if main.current.transitioning then
							return
						end
						buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.35 })
						camera:shake(3, 0.075)
						collect_into(
							self.tutorial_elements,
							Text2({
								group = self.ui,
								x = gw / 2,
								y = gh / 2 + 25 * global_game_scale,
								force_update = true,
								lines = {
									{
										text = "[fg]it's simple... [cbyc]for now...",
										font = pixul_font,
										alignment = "center",
									},
								},
							})
						)
					end)
				end)
			end)
		end)
	end

	self.t:after(state.tutorial and 20 or 1, function()
		if state.tutorial then
			self:spawn_new_stations(2, { gw * 0.2, gh * 0.6, gw * 0.7, gh * 0.8 })
		else
			self:spawn_new_stations(2)
		end

		self.t:every(1, function()
			local all_connected = self:all_stations_connected()
			if all_connected and state.timed_mode then
				self.tutorial_finished = true
				state.tutorial = false
				self.timer = self.time_per_round
				success:play({ pitch = random:float(1.95, 3.05), volume = 0.5 })
			end

			if not self.no_space_left_for_stations and all_connected then
				local attempts = 0
				repeat
					self.failed_spawn_new_station = false
					attempts = attempts + 1
					self:spawn_new_stations(1)
				until not self.failed_spawn_new_station or self.no_space_left_for_stations and attempts < 10

				if attempts >= 10 then
					self.no_space_left_for_stations = true
				end
			elseif all_connected and self.no_space_left_for_stations then
				self.win = true
				self:quit() -- victory!
			elseif not all_connected and state.timed_mode and self.timer <= 0 then
				self.loss = true -- for stopping the damn clock
				self:die() -- loss on 'timer' mode
			end
		end)
	end)
end

function Game:all_stations_connected()
	if not self.stations then
		return false
	end

	for _, station in ipairs(self.stations) do
		if #station.missing_connections > 0 then
			return false
		end
	end
	return true
end

function Game:pick_random_stations(num, exclude)
	local exclude_set = {}
	for _, ex in ipairs(exclude or {}) do
		exclude_set[ex] = true
	end

	local filtered = {}
	for _, station in ipairs(self.stations) do
		if not exclude_set[station] then
			table.insert(filtered, station)
		end
	end

	-- Shuffle the filtered list
	for i = #filtered, 2, -1 do
		local j = math.random(i)
		filtered[i], filtered[j] = filtered[j], filtered[i]
	end

	local result = {}
	for i = 1, math.min(num or 1, #filtered) do
		table.insert(result, filtered[i])
	end

	return result
end

local function new_station_is_far_enough(x, y, stations, min_dist)
	for _, s in ipairs(stations) do
		local dx = s.x - x
		local dy = s.y - y
		local dist_sq = dx * dx + dy * dy
		if dist_sq < min_dist * min_dist then
			return false
		end
	end
	return true
end

function Game:spawn_new_stations(num, args)
	local max_attempts = 100

	local min_x_border = gw * 0.05
	local max_x_border = gw - min_x_border

	local min_y_border = gh * 0.09
	local max_y_border = gh - min_y_border

	for i = 1, num do
		local x, y
		local attempts = 0

		if not args then
			repeat
				x = random:int(min_x_border, max_x_border)
				y = random:int(min_y_border, max_y_border)
				attempts = attempts + 1
			until new_station_is_far_enough(x, y, self.stations, self.min_distance_between_stations) or attempts > max_attempts

			if attempts > max_attempts then
				-- print(
				-- 	"Failed to place station after "
				-- 		.. max_attempts
				-- 		.. " attempts. no space after "
				-- 		.. #self.stations
				-- 		.. " stations @ dist: "
				-- 		.. self.min_distance_between_stations
				-- )
				if self.min_distance_between_stations < self.absolute_min_distance_between_stations then
					self.no_space_left_for_stations = true
				else
					self.min_distance_between_stations = self.min_distance_between_stations - 5
					self.failed_spawn_new_station = true
				end
				return
			end
		else
			x = args[(i - 1) * 2 + 1]
			y = args[(i - 1) * 2 + 2]
		end

		local new_station = Station({
			group = self.main,
			name = string.char(48 + #self.stations),
			x = x,
			y = y,
			size = 15,
			color = fg[0],
			highlight_color = yellow[-2],
		})
		-- camera:shake(3, 0.075)

		local all_rails = self.main:get_objects_by_class(Rail)
		for _, rail in ipairs(all_rails) do
			if rail:is_mouse_over(new_station.x, new_station.y, new_station.size + 4) then
				rail:destroy()
			end
		end

		new_station.require_connections = self:pick_random_stations(1)
		new_station.require_direct_connections = (random:float(0, 1) < 0.5) and self:pick_random_stations(1, new_station.require_connections) or {}

		table.insert(self.stations, new_station)

		-- Update old stations to be aware of the new one
		for _, s in ipairs(new_station.require_connections) do
			if random:float(0, 1) < 0.5 then
				table.insert(s.require_connections, new_station)
			end
		end
		for _, s in ipairs(new_station.require_direct_connections) do
			if random:float(0, 1) < 0.5 then
				table.insert(s.require_direct_connections, new_station)
			else
				table.insert(s.require_connections, new_station)
			end
		end
	end
end

function Game:on_exit()
	self.main:destroy()
	self.post_main:destroy()
	self.effects:destroy()
	self.ui:destroy()
	self.paused_ui:destroy()
	self.options_ui:destroy()
	self.keybinding_ui:destroy()
	self.main = nil
	self.post_main = nil
	self.effects = nil
	self.ui = nil
	self.paused_ui = nil
	self.options_ui = nil
	self.keybinding_ui = nil
	self.credits = nil
	self.passives = nil
	self.flashes = nil
	self.bosses = nil
	self.players = nil
	self.hfx = nil
end

function Game:update(dt)
	play_music({ volume = 0.3 })

	if not self.paused and not self.stuck and not self.won then
		run_time = run_time + dt
		if state.timed_mode and self.tutorial_finished then
			if self.wasnt_timed_mode then
				self.timer = self.time_per_round
				self.wasnt_timed_mode = false
			end
			self.timer = self.timer and self.timer - (dt * slow_amount) or 60
			if self.timer < 0 then
				self.timer = 0
			end

			if not self.loss then
				self.timer_text:set_text({
					{
						text = (self.timer > 10 and "[fg]" or "[red]") .. string.format("%.2f", self.timer),
						font = pixul_font,
						alignment = "left",
					},
				})
				self.timer_text:update(dt * slow_amount)
			end
		else
			state.wasnt_timed_mode = true
		end
	end

	if self.tutorial_finished then
		for _, element in ipairs(self.tutorial_elements) do
			if element then
				element.dead = true
				element = nil
			end
		end
	end

	if input.cancel_rail.pressed then
		if self.current_rail then
			self.current_rail:destroy()
			self.current_rail = nil
		end
	elseif input.draw_rail.down or (self.current_rail and not self.current_rail.connected) then
		local max_angle = math.rad(30)
		local min_dist = 40

		local mx, my = self.main:get_mouse_position()
		local mouse = Vector(mx, my)

		if not self.current_rail and input.draw_rail.pressed and self.hovered_station then
			self.current_rail = Rail({
				group = self.main,
				source_station = self.hovered_station,
				color = fg[0],
				highlight_color = yellow[-2],
				connected_color = green[0],
			})
		elseif self.current_rail then
			local pts = self.current_rail.points
			local np = #pts
			local line_end = Vector(pts[np - 1], pts[np])
			local move_vec = mouse:clone():sub(line_end)

			local clamped_dir
			if np >= 4 then
				local prev = Vector(pts[np - 3], pts[np - 2])
				local last_dir = line_end:clone():sub(prev):normalize()
				local curr_dir = move_vec:clone():normalize()

				local dot = math.max(-1, math.min(1, last_dir:dot(curr_dir)))
				local angle = math.acos(dot)

				if angle > max_angle then
					local sign = last_dir:cross(curr_dir) < 0 and -1 or 1
					clamped_dir = last_dir:clone():rotate(Vector(0, 0), sign * max_angle)
				else
					clamped_dir = curr_dir
				end
			else
				clamped_dir = move_vec:clone():normalize()
			end

			local proj_len = move_vec:dot(clamped_dir)

			if proj_len >= min_dist then
				local new_point = line_end:clone():add(clamped_dir:clone():scale(min_dist))
				self.current_rail:add_point(new_point.x, new_point.y)
				self.current_rail:temp_point(nil, nil)
			elseif proj_len > 0 then
				local temp = line_end:clone():add(clamped_dir:clone():scale(proj_len))
				self.current_rail:temp_point(temp.x, temp.y)
			else
				self.current_rail:temp_point(nil, nil)
			end
		end
	end

	if
		-- not input.draw_rail.down
		-- or (self.current_rail and not self.current_rail.connected) then
		-- and
		self.current_rail
	then
		if
			self.hovered_station
			and self.hovered_station ~= self.current_rail.source_station
			and self.current_rail.temp_x
			and self.current_rail.temp_y
			and self.hovered_station.shape:is_colliding_with_point(self.current_rail.temp_x, self.current_rail.temp_y)
		then
			self.current_rail:destination(self.hovered_station)

			local mx, my = self.main:get_mouse_position()
			self.current_rail:add_temp_point_permanently()
			self.current_rail = nil
		end
	end

	if input.escape.pressed and not self.transitioning and not self.in_credits then
		if not self.paused and not self.died and not self.won then
			pause_game(self)
		elseif self.in_options and not self.died and not self.won then
			if self.in_keybinding then
				close_keybinding(self)
			else
				close_options(self)
			end
		else
			self.transitioning = true
			ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

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
		for _, object in ipairs(self.credits.objects) do
			object.dead = true
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
	self.paused_ui:update(dt * slow_amount)
	self.options_ui:update(dt * slow_amount)

	if self.in_keybinding then
		update_keybind_button_display(self)
	end
	self.keybinding_ui:update(dt * slow_amount)
	self.credits:update(dt * slow_amount)

	-- if input.m2.pressed then
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
	-- 					text = tostring(main.debug),
	-- 					-- text = tostring(self.counter),
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
	-- 	-- self.counter = self.counter + 1
	-- end
end

function Game:quit()
	if self.died then
		return
	end

	self.quitting = true
	-- if self.level < 5 then
	-- 	if not self.arena_clear_text then
	-- 		self.arena_clear_text = Text2({
	-- 			group = self.ui,
	-- 			x = gw / 2,
	-- 			y = gh / 2 - 48,
	-- 			lines = {
	-- 				{
	-- 					text = "[wavy_mid, fg] Level [green]" .. self.level .. "[red]/5[wavy_mid, fg] beat",
	-- 					font = fat_font,
	-- 					alignment = "center",
	-- 				},
	-- 			},
	-- 		})
	-- 	end
	-- 	self.t:after(2, function()
	-- 		self.slow_transitioning = true
	-- 		self.t:tween(0.7, self, { main_slow_amount = 0 }, math.linear, function()
	-- 			self.main_slow_amount = 0
	-- 		end)
	-- 	end)
	-- 	self.t:after(3, function()
	-- 		self.transitioning = true
	-- 		ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 		ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	-- 		ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	--
	-- 		slow_amount = 1
	-- 		music_slow_amount = 1
	-- 		locked_state = nil
	-- 		local next_level = self.level + 1 -- new var for clarity
	-- 		scene_transition(self, gw / 2, gh / 2, Game("game"), { destination = "game", args = { level = next_level, num_players = #self.players } }, {
	-- 			text = " level " .. ((self.level + 1) == 5 and "[red]" .. (self.level + 1) or tostring(self.level + 1)) .. "[red]/5",
	-- 			font = pixul_font,
	-- 			alignment = "center",
	-- 		})
	-- 	end) elseif
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
		trigger:tween(4, camera, { x = gw / 2, y = gh / 2, r = 0 }, math.linear, function()
			camera.x, camera.y, camera.r = gw / 2, gh / 2, 0
		end)

		ui_layer = ui_interaction_layer.Win
		local ui_group = self.ui
		self.win_ui_elements = {}
		main.ui_layer_stack:push({
			layer = ui_layer,
			-- music = self.options_menu_song_instance,
			layer_has_music = false,
			ui_elements = self.win_ui_elements,
		})

		self.win_text = Text2({
			group = self.ui,
			x = gw / 2,
			y = gh / 2 - 40 * global_game_scale,
			force_update = true,
			lines = { { text = "[wavy_mid, cbyc2]congratulations!", font = fat_font, alignment = "center" } },
		})
		trigger:after(2.5, function()
			self.win_text2 = collect_into(
				self.win_ui_elements,
				Text2({
					group = self.ui,
					x = gw / 2,
					y = gh / 2,
					force_update = true,
					lines = {
						{
							text = "[fg]you've beaten the game!",
							font = pixul_font,
							alignment = "center",
							height_multiplier = 1.24,
						},
						{ text = "[wavy_mid, yellow]thanks for playing!", font = pixul_font, alignment = "center" },
						-- {
						-- 	text = "[wavy_mid, yellow]victory PCB: [wavy_mid, green]#",
						-- 	font = pixul_font,
						-- 	alignment = "center",
						-- },
					},
				})
			)
			self.credits_button = collect_into(
				self.win_ui_elements,
				Button({
					group = self.ui,
					x = gw / 2,
					y = gh / 2 + 35 * global_game_scale,
					force_update = true,
					button_text = "credits",
					fg_color = "bg10",
					bg_color = "bg",
					action = function()
						open_credits(self)
					end,
				})
			)

			for _, v in pairs(self.win_ui_elements) do
				v.group = ui_group
				ui_group:add(v)

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

	self.main:draw_class(Rail)
	-- self.main:draw_class(Train)
	self.main:draw_class(Station)
	if self.hovered_station then
		self.hovered_station:draw()
	end

	self.post_main:draw()
	self.effects:draw()

	graphics.draw_with_mask(function()
		star_canvas:draw(0, 0, 0, 1, 1)
	end, function()
		camera:attach()
		graphics.rectangle(gw / 2, gh / 2, self.w, self.h, nil, nil, fg[0])
		camera:detach()
	end, true)

	camera:attach()
	-- if self.start_time and self.start_time > 0 and not self.choosing_passives then
	-- 	graphics.push(gw / 2, gh / 2 - 48, 0, self.hfx.condition1.x, self.hfx.condition1.x)
	-- 	graphics.print_centered(tostring(self.start_time), fat_font, gw / 2, gh / 2 - 48, 0, 1, 1, nil, nil, self.hfx.condition1.f and fg[0] or red[0])
	-- 	graphics.pop()
	-- end

	if self.win_condition then
		if self.win_condition == "wave" then
			if self.start_time <= 0 then
				graphics.push(self.x2 - 50, self.y1 - 10, 0, self.hfx.condition2.x, self.hfx.condition2.x)
				graphics.print_centered("wave:", fat_font, self.x2 - 50, self.y1 - 10, 0, 0.6, 0.6, nil, nil, fg[0])
				graphics.pop()
				local wave = self.wave
				if wave > self.max_waves then
					wave = self.max_waves
				end
				graphics.push(
					self.x2 - 25 + fat_font:get_text_width(wave .. "/" .. self.max_waves) / 2,
					self.y1 - 8,
					0,
					self.hfx.condition1.x,
					self.hfx.condition1.x
				)
				graphics.print(
					wave .. "/" .. self.max_waves,
					fat_font,
					self.x2 - 25,
					self.y1 - 8,
					0,
					0.75,
					0.75,
					nil,
					fat_font.h / 2,
					self.hfx.condition1.f and fg[0] or yellow[0]
				)
				graphics.pop()
			end
		end
	end
	-- end

	if state.timed_mode then
		self.timer_text:draw(gw / 2, gh * 0.05)
	end
	camera:detach()

	if self.level == 20 and self.trailer then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	if self.choosing_passives or self.won or self.paused or self.died then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end

	if self.paused then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.ui:draw()

	if self.shop_text then
		self.shop_text:draw(gw - 40, gh - 17)
	end

	if self.paused then
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

function Game:close_die_ui()
	main.current.in_death = false
	pop_ui_layer(self)
end

function Game:die()
	if not self.died_text then
		input:set_mouse_visible(true)
		self.died = true
		locked_state = nil
		system.save_run()

		-- trigger:tween(1, _G, { slow_amount = 0 }, math.linear, function()
		-- 	slow_amount = 0
		-- end, "slow_amount")
		-- trigger:tween(1, _G, { music_slow_amount = 0 }, math.linear, function()
		-- 	music_slow_amount = 0
		-- end, "music_slow_amount")

		self.t:tween(2, self, { main_slow_amount = 0 }, math.linear, function()
			self.main_slow_amount = 0
		end)
		self.t:tween(2, _G, { music_slow_amount = 0 }, math.linear, function()
			music_slow_amount = 0
		end)

		-- main.current.in_death = true
		-- local ui_layer = ui_interaction_layer.GameLoss
		-- local ui_group = self.game_loss_ui
		-- self.game_loss_ui_elements = {}
		-- main.ui_layer_stack:push({
		-- 	layer = ui_layer,
		-- 	layer_has_music = false,
		-- 	ui_elements = self.game_loss_ui_elements,
		-- })
		--
		-- self.died_text = collect_into( -- TODO: stopped here, gotta make this ui group, responsive
		-- 	self.options_ui_elements,
		self.died_text = Text2({
			group = self.ui,
			x = gw / 2,
			y = gh / 2 - 32 * global_game_scale,
			force_update = true,
			lines = {
				{
					text = "[wavy_mid, cbyc]ran outta time...",
					font = fat_font,
					alignment = "center",
					height_multiplier = 1.25,
				},
			},
		})
		-- )

		self.t:after(2.2, function()
			self.died_text2 = Text2({
				group = self.ui,
				force_update = true,
				x = gw / 2,
				y = gh / 2,
				lines = {
					{
						text = "[wavy_mid, cbyc2]try again?",
						font = fat_font,
						alignment = "center",
						height_multiplier = 1.25,
					},
				},
			})

			ui_layer = ui_interaction_layer.Loss
			local ui_group = self.ui
			self.loss_ui_elements = {}
			main.ui_layer_stack:push({
				layer = ui_layer,
				-- music = self.options_menu_song_instance,
				layer_has_music = false,
				ui_elements = self.loss_ui_elements,
			})
			self.died_restart_button = collect_into(
				self.loss_ui_elements,
				Button({
					group = self.ui,
					layer = ui_layer,
					x = gw / 2,
					y = gh / 2 + 20,
					force_update = true,
					button_text = "restart",
					fg_color = "bg",
					bg_color = "green",
					action = function(b)
						if not self.transitioning then
							self.transitioning = true
							ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
							ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
							ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })

							slow_amount = 1
							music_slow_amount = 1
							locked_state = nil
							scene_transition(self, gw / 2, gh / 2, Game("game"), { destination = "game", args = { level = 1, num_players = 1 } }, {
								text = "chill mode will pause the timer [wavy]forever",
								font = pixul_font,
								alignment = "center",
							})
						end
					end,
				})
			)
		end)
		trigger:tween(2, camera, { x = gw / 2, y = gh / 2, r = 0 }, math.linear, function()
			camera.x, camera.y, camera.r = gw / 2, gh / 2, 0
		end)
	end
	return true
end

--
-- function Game:new_longboss(length)
-- 	local boss = LongBoss({
-- 		group = self.main,
-- 		x = 0,
-- 		y = random:int(0, gh),
-- 		leader = true,
-- 		ii = 1,
-- 	})
-- 	for i = 2, length - 1 do
-- 		boss:add_follower(LongBoss({
-- 			group = self.main,
-- 			ii = i,
-- 		}))
-- 	end
--
-- 	local units = boss:get_all_units()
-- 	for _, unit in ipairs(units) do
-- 		local chp = CharacterHP({
-- 			group = self.effects,
-- 			x = self.x1 + 8 + (unit.ii - 1) * 22,
-- 			y = self.y2 + 14,
-- 			parent = unit,
-- 		})
-- 		unit.character_hp = chp
-- 	end
-- 	return boss
-- end
--
-- function Game:get_random_player()
-- 	return self.players[math.random(#self.players)]
-- end
--
-- --
-- --
-- --
-- --
-- CharacterHP = Object:extend()
-- CharacterHP:implement(GameObject)
-- function CharacterHP:init(args)
-- 	self:init_game_object(args)
-- 	self.hfx:add("hit", 1)
-- 	self.cooldown_ratio = 0
-- end
--
-- function CharacterHP:update(dt)
-- 	self:update_game_object(dt)
-- 	local t, d = self.parent.t:get_timer_and_delay("shoot")
-- 	if t and d then
-- 		local m = self.parent.t:get_every_multiplier("shoot")
-- 		self.cooldown_ratio = math.min(t / (d * m), 1)
-- 	end
-- 	local t, d = self.parent.t:get_timer_and_delay("attack")
-- 	if t and d then
-- 		local m = self.parent.t:get_every_multiplier("attack")
-- 		self.cooldown_ratio = math.min(t / (d * m), 1)
-- 	end
-- 	local t, d = self.parent.t:get_timer_and_delay("heal")
-- 	if t and d then
-- 		self.cooldown_ratio = math.min(t / d, 1)
-- 	end
-- 	local t, d = self.parent.t:get_timer_and_delay("buff")
-- 	if t and d then
-- 		self.cooldown_ratio = math.min(t / d, 1)
-- 	end
-- 	local t, d = self.parent.t:get_timer_and_delay("spawn")
-- 	if t and d then
-- 		self.cooldown_ratio = math.min(t / d, 1)
-- 	end
-- end
--
-- function CharacterHP:draw()
-- 	graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
-- 	graphics.rectangle(self.x, self.y - 2, 14, 4, 2, 2, self.parent.dead and bg[5] or (self.hfx.hit.f and fg[0] or self.parent.color[-2]), 2)
-- 	if self.parent.hp > 0 then
-- 		graphics.rectangle2(
-- 			self.x - 7,
-- 			self.y - 4,
-- 			14 * (self.parent.hp / self.parent.max_hp),
-- 			4,
-- 			nil,
-- 			nil,
-- 			self.parent.dead and bg[5] or (self.hfx.hit.f and fg[0] or self.parent.color[-2])
-- 		)
-- 	end
-- 	if not self.parent.dead then
-- 		graphics.line(self.x - 8, self.y + 5, self.x - 8 + 15.5 * self.cooldown_ratio, self.y + 5, self.hfx.hit.f and fg[0] or self.parent.color[-2], 2)
-- 	end
-- 	graphics.pop()
--
-- 	if state.cooldown_snake then
-- 		if table.any(non_cooldown_characters, function(v)
-- 			return v == self.parent.character
-- 		end) then
-- 			return
-- 		end
-- 		local p = self.parent
-- 		graphics.push(p.x, p.y, 0, self.hfx.hit.x, self.hfx.hit.y)
-- 		if not p.dead then
-- 			graphics.line(p.x - 4, p.y + 8, p.x - 4 + 8, p.y + 8, self.hfx.hit.f and fg[0] or bg[-2], 2)
-- 			graphics.line(p.x - 4, p.y + 8, p.x - 4 + 8 * self.cooldown_ratio, p.y + 8, self.hfx.hit.f and fg[0] or self.parent.color[-2], 2)
-- 		end
-- 		graphics.pop()
-- 	end
-- end
--
-- function CharacterHP:change_hp()
-- 	self.hfx:use("hit", 0.5)
-- end
