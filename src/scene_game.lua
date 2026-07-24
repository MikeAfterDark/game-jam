Game = Object:extend()
Game:implement(State)
Game:implement(GameObject)
function Game:init(name)
	self:init_state(name)
	self:init_game_object()
end

Group_Layers = {
	Main = 1,
	Space_Junk = 2,

	Cover = 999,
}

function Game:on_enter(from, args)
	camera.x, camera.y = gw * 0.5, gh * 0.5
	camera.r = 0

	self.floor = Group()
	-- self.main = Group()
	self.main = Group()
	self.obstacle = Group():set_as_physics_world(32, 0, 0, { "obstacle" })
	self.game_ui = Group()
	self.effects = Group()
	self.ui = Group()
	self.end_ui = Group():no_camera()

	-- self.main.layer = Group_Layers.Main
	-- self.obstacle.layer = Group_Layers.Space_Junk
	self.main.layer = Group_Layers.Space_Junk
	self.obstacle.layer = Group_Layers.Main
	self.end_ui.layer = Group_Layers.Cover

	self.main_slow_amount = 1
	slow_amount = 1

	self.x1, self.y1 = 0, 0
	self.x2, self.y2 = gw, gh
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1
	-- self.song_info_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)

	self.won = false
	self.lost = false

	self.game_ui_elements = {}

	-- if layer underneath this one has layer_type == "game" and the same music type then dont push
	local layer = main.ui_layer_stack:peek()
	if layer and (layer.music_type ~= self.music_type) then
		if layer.game then
			pop_ui_layer(self)
		end
	end

	main.ui_layer_stack:push({
		layer = ui_interaction_layer.Game,
		layer_has_music = args.layer_has_music,
		-- game = true,
		music_type = args.music_type,
		ui_elements = self.game_ui_elements,
	})

	self.end_game_cover = RectangleCover({
		group = self.end_ui,
		x = gw * 0.5,
		y = gh * 0.5,
		w = gw,
		h = gh,
		color = Color(0.1, 0.1, 0.1, 0.9),
		update_action = function(cover)
			cover.interact_with_mouse = cover.visible
		end,
		visible = false,
	})

	self.planet = Planet({
		group = self.main,
		x = gw * 0.5,
		y = gh * 0.5,
		rs = gh * 0.20,
		r = 0,
	})

	self.ships = {}
	self.ship_spawn_interval = 0.1
	self.last_ship_spawn_time = run_time + 0.3

	self.obstacles = {}
	self.obstacle_spawn_interval = 5
	self.last_obstacle_spawn_time = run_time + 0.4

	-- planet: art
	-- rocket ships
	--		ship with mouse collider
	--		countdown
	--
	--		if timer == 0 and clicked, launch,
	--		else if timer > 0 and clicked then fail
	--		else if timer < 0 then explode
	--

	self.level_timer = 3 * 60 -- in seconds
	-- self.level_timer = 0.1 * 60 -- in seconds

	self.level_timer_text = Text({
		{
			text = "",
			font = pixul_font,
			alignment = "center",
		},
	}, global_text_tags)
end

function Game:spawn_ship(data)
	-- print("spawning ship")
	local size = gh * 0.07
	table.insert(
		self.ships,
		Ship({
			group = self.main,
			planet = self.planet,
			w = size,
			h = size * 2,
			r = data.angle,
			time = data.time,
		})
	)
end

function Game:spawn_obstacle(data)
	-- print("spawning obstacle")
	local horizontal = random:bool()

	local x, y
	if horizontal then
		x = gw * 0.5 + random:sign() * (gw * 0.5 + data.size)
		y = random:float(0, gh)
	else
		x = random:float(0, gw)
		y = gh * 0.5 + random:sign() * (gh * 0.5 + data.size)
	end

	table.insert(
		self.obstacles,
		Obstacle({
			group = self.obstacle,
			x = x, --gw / 2,
			y = y, --gh / 2,
			rs = data.size,
			time = data.time,
		})
	)
end

function Game:update(dt)
	mouse.group_layer = 0
	camera:follow_object(self.camera_tracker)

	local paused = main:get("settings").in_pause
	local game_over = false --self.won or self.lost
	if not paused and not game_over then
		run_time = run_time + dt
	end

	-- clear the obj tables of dead stuff
	_, self.ships = table.reject(self.ships, function(ship)
		return ship.dead
	end)
	_, self.obstacles = table.reject(self.obstacles, function(obstacle)
		return obstacle.dead
	end)

	--  Spawn new ships timer
	if self.last_ship_spawn_time < run_time and not self.won then
		self.last_ship_spawn_time = run_time + self.ship_spawn_interval

		local angle_spread = math.pi * 0.1
		local attempts = 3
		local open_angle

		repeat
			open_angle = random:float(0, 2 * math.pi)
			attempts = attempts - 1
		until attempts < 0
			or not table.any(self.ships, function(ship)
				local diff = math.abs(ship.r - open_angle)
				diff = math.min(diff, 2 * math.pi - diff) -- shortest angular distance
				return diff < angle_spread
			end)

		if attempts >= 0 then
			self:spawn_ship({
				angle = open_angle,
				time = random:int(4, 4),
			})
		end
	end

	-- Spawn new obstacles
	if self.last_obstacle_spawn_time < run_time and not self.won then
		self.last_obstacle_spawn_time = run_time + self.obstacle_spawn_interval
		self.obstacle_spawn_interval = random:int(4, 9)

		self:spawn_obstacle({

			size = random:float(gh * 0.13, gh * 0.4),
			time = random:int(8, 10),
		})
	end

	self.level_timer = self.level_timer - slow_amount * dt
	self.level_timer_text:set_text({
		{ text = string.format("%d", self.level_timer), font = large_pixul_font, alignment = "center" },
	})
	if self.level_timer < 0 then
		table.foreach(self.ships, function(obj)
			obj.freeze_time = true
		end)
		table.foreach(self.obstacles, function(obj)
			obj.freeze_time = true
		end)

		self:win()
	end

	-- self:update_game_object(dt * slow_amount)
	-- star_group:update(dt * slow_amount)
	-- self.floor:update(dt * slow_amount)
	-- self.main:update(dt * slow_amount * self.main_slow_amount)
	-- self.game_ui:update(dt * slow_amount)
	-- self.effects:update(dt * slow_amount)
	-- self.ui:update(dt * slow_amount)
	-- self.end_ui:update(dt * slow_amount)

	-- reversed order so that mouse + group-interaction layer system works (jank but welp),
	-- top-to-bottom order
	self.end_ui:update(dt * slow_amount)
	self.ui:update(dt * slow_amount)
	self.effects:update(dt * slow_amount)
	self.game_ui:update(dt * slow_amount)
	self.main:update(dt * slow_amount * self.main_slow_amount)
	self.obstacle:update(dt * slow_amount * self.main_slow_amount)
	self.floor:update(dt * slow_amount)
	star_group:update(dt * slow_amount)
	self:update_game_object(dt * slow_amount)
end

function Game:win()
	if not self.won then
		self.won = true
		self.end_game_cover.visible = true
		-- slow_amount = 0
		print("gj, you won")

		self.win_text = Text2({ --
			group = self.end_ui,
			x = gw * 0.5,
			y = gh * 0.4,
			lines = {
				{ text = "[cbyc2]You Win! GG", font = fat_title_font, alignment = "center" },
			},
		}, global_text_tags)

		self:setup_endgame_ui()

		-- if there are more enemies or infinite mode, spawn next enemy
		-- else popup a victory screen to play again or go back to main menu
	end
end

function Game:loss()
	if not self.lost then
		self.lost = true
		self.end_game_cover.visible = true

		self.loss_text = Text2({ --
			group = self.end_ui,
			x = gw * 0.5,
			y = gh * 0.4,
			lines = {
				{ text = "[cbyc]You Lost", font = fat_title_font, alignment = "center" },
			},
		}, global_text_tags)

		self:setup_endgame_ui()
		-- You Lost
		--
		-- play again (reload Game)
		-- credits
		-- back to menu

		print("booo, you lost")
		-- play end game screen, try again or go back to menu
	end
end

function Game:setup_endgame_ui()
	local ui_layer = ui_interaction_layer.End
	local ui_group = self.end_ui
	self.end_ui_elements = {}
	main.ui_layer_stack:push({
		layer = ui_layer,
		layer_has_music = true,
		music_type = "loss",
		ui_elements = self.end_ui_elements,
	})

	self.play_again_button = collect_into(
		self.end_ui_elements,
		Button({
			group = ui_group,
			x = gw * 0.5,
			y = gh * 0.6,
			fg_color = "bg",
			bg_color = "green",
			button_text = "play again",
			action = function(b)
				scene_transition(self, {
					x = gw / 2,
					y = gh / 2,
					type = "circle",
					target = {
						scene = Game,
						name = "game",
						args = { clear_music = true },
					},
					display = {
						text = "loading...",
						font = pixul_font,
						alignment = "center",
					},
				})
			end,
		})
	)

	for _, v in pairs(self.end_ui_elements) do
		v.layer = ui_layer
		v.force_update = true
	end
end

function Game:draw()
	self.floor:draw()
	self.obstacle:draw()

	local scale = 2
	local t = run_time / 8.0

	local x = gw / 2 + gw * 0.12 * math.sin(t * 0.45) + gw * 0.05 * math.sin(t * 1.17 + 1.3) + gw * 0.02 * math.cos(t * 2.41)
	local y = gh / 2 + gh * 0.10 * math.cos(t * 0.38 + 0.8) + gh * 0.06 * math.sin(t * 0.93) + gh * 0.03 * math.cos(t * 1.81 + 2.1)
	local rot = 0.015 * math.sin(t * 0.22) + 0.008 * math.sin(t * 0.81 + 0.7) + 0.004 * math.cos(t * 1.57)

	local opacity = 0.2
	sprite.space_background:draw(x, y, rot, scale, scale, 0, 0, Color(1, 1, 1, opacity))
	-- sprite.space_background:draw(x, x, -2 * rot, scale, scale, 0, 0, Color(1, 1, 1, opacity))
	sprite.space_background:draw(y, x, -rot, scale, scale, 0, 0, Color(1, 1, 1, opacity))
	self.main:draw()
	self.game_ui:draw()
	self.effects:draw()

	if not self.won then
		self.level_timer_text:draw(gw * 0.1, gh * 0.1, 0, 1, 1)
	end
	self.ui:draw()

	-- graphics.draw_with_mask(function()
	-- 	star_canvas:draw(0, 0, 0, 1, 1)
	-- end, function()
	-- 	camera:attach()
	-- 	graphics.rectangle(gw / 2, gh / 2, self.w, self.h, nil, nil, fg[0])
	-- 	camera:detach()
	-- end, true)

	-- if self.won or self.died then -- replaced by self.end_game_cover
	-- 	graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	-- end
	self.end_ui:draw()
end

function Game:on_exit()
	self.main:destroy()
	self.obstacle:destroy()
	self.game_ui:destroy()
	self.effects:destroy()
	self.ui:destroy()
	self.end_ui:destroy()

	self.main = nil
	self.obstacle = nil
	self.game_ui = nil
	self.effects = nil
	self.ui = nil
	self.end_ui = nil
	self.flashes = nil
	self.hfx = nil

	camera.x, camera.y = gw / 2, gh / 2
	camera.sx, camera.sy = 1, 1
	camera.r = 0
	camera:follow_object(nil)
end
