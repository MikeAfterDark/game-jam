Game = Object:extend()
Game:implement(State)
Game:implement(GameObject)
function Game:init(name)
	self:init_state(name)
	self:init_game_object()
end

function Game:on_enter(from, args)
	camera.x, camera.y = gw * 0.5, gh * 0.5
	camera.r = 0

	self.floor = Group()
	-- self.main = Group()
	self.main = Group():set_as_physics_world(32, 0, 0, { "wheel", "ball" })
	self.shop_group = Group():set_as_physics_world(32, 0, 0, { "drawer", "ball" })
	self.game_ui = Group()
	self.effects = Group()
	self.ui = Group()
	self.end_ui = Group():no_camera()

	self.main_slow_amount = 1
	slow_amount = 1

	self.x1, self.y1 = 0, 0
	self.x2, self.y2 = gw, gh
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1
	-- self.song_info_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)

	self.won = false
	self.lost = false

	self.game_ui_elements = {}

	local num_pockets = 36
	local pockets = {}

	local c1 = red[0]:clone()
	c1.a = 0.4

	local c2 = green[0]:clone()
	c2.a = 0.4
	for i = 1, num_pockets do
		table.insert(pockets, {
			color = i % 2 == 0 and c1:clone() or c2:clone(),
			type = i == 1 --
					and Pocket_Type.Jackpot
				or i == math.floor(num_pockets / 2) and Pocket_Type.Void
				or Pocket_Type.Normal,
			value = i - 1,
			size = 1,
		})
	end

	local balls = {}
	local ball_radius = gh * 0.02
	for i = 1, 0 do
		table.insert(
			balls,
			Ball({
				group = self.main,
				x = gw * 0.5,
				y = gh * 0.5,
				r = ball_radius,
				type = random:table(Ball_Type),
			})
		)
	end

	self.wheel = Wheel({
		group = self.main,
		x = gw * 0.5,
		y = gh * 0.5,
		rs = gh * 0.4,
		pockets = pockets,
		balls = balls,
	})
	self.results = {}

	self.player_holder = Holder({
		group = self.main,
		x = gw * 0.5,
		y = gh * 0.96,
		w = 0,
		h = gh * 0.05,
		slot_size = gh * 0.04,
		color = blue[0],
	})

	self.enemy_holder = Holder({
		group = self.main,
		is_enemy = true,
		x = gw * 0.5,
		y = gh * 0.04,
		w = 0,
		h = gh * 0.05,
		slot_size = gh * 0.04,
		color = red[0],
	})

	self.player_holder:setup(9, 4, {
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			r = ball_radius,
			type = random:table(Ball_Type),
		}),
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			r = ball_radius,
			type = random:table(Ball_Type),
		}),
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			r = ball_radius,
			type = random:table(Ball_Type),
		}),
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			r = ball_radius,
			type = random:table(Ball_Type),
		}),
	})
	self.enemy_holder:setup(3, 2, {
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			r = ball_radius,
			type = random:table(Ball_Type),
		}),
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			r = ball_radius,
			type = random:table(Ball_Type),
		}),
	})

	self.enemy = Character({
		group = self.main,
		x = gw * 0.75,
		y = gh * 0.2,
		money = 2,
		damage = 0,
		max_hp = 4,
		portrait = {
			name = "[red]Angry [p_blue1]Bob",
			background = {
				color = Color("#063000"),
			},
			animation = Animation(
				0.4, --
				AnimationFrames(sprite.alien1, 16, 32, { { 1, 1 }, { 2, 1 }, { 3, 1 }, { 4, 1 }, { 5, 1 }, { 6, 1 } }),
				"loop",
				{}
			),
			x = gw * 0.87,
			y = gh * 0.2,
			draw_size = 7,
		},
	})

	self.player = Character({
		group = self.main,
		x = gw * 0.85,
		y = gh * 0.9,
		money = 5,
		damage = 0,
		max_hp = 10,
	})

	local y = self.player.y
	local x_offset = gw * 0.08
	local size = gh * 0.13
	local w = size
	local h = size * 0.4
	self.attack_button = collect_into(
		self.game_ui_elements,
		RectangleButton({
			group = self.game_ui,
			x = self.player.x - x_offset,
			y = self.player.y - gh * 0.13,
			w = w,
			h = h,
			fg_color = "black",
			bg_color = "red",
			title_text = "ATK",
			action = function(b)
				b.spring:pull(0.2, 200, 10)
				local damage = self.player:get_damage()
				self.enemy:take_damage(damage)
			end,
		})
	)

	self.armour_button = collect_into(
		self.game_ui_elements,
		RectangleButton({
			group = self.game_ui,
			x = self.player.x,
			y = self.player.y - gh * 0.13,
			w = w,
			h = h,
			fg_color = "black",
			bg_color = "blue",
			title_text = "ARMR",
			action = function(b)
				b.spring:pull(0.2, 200, 10)

				local armour = 1
				self.player:armour_up(armour)
			end,
		})
	)
	self.heal_button = collect_into(
		self.game_ui_elements,
		RectangleButton({
			group = self.game_ui,
			x = self.player.x + x_offset,
			y = self.player.y - gh * 0.13,
			w = w,
			h = h,
			fg_color = "black",
			bg_color = "green",
			title_text = "HEAL",
			action = function(b)
				b.spring:pull(0.2, 200, 10)

				local health = 1
				self.player:heal_up(health)
			end,
		})
	)

	-- self.armour_button = collect_into(self.game_ui_elements, Button({}))
	-- self.heal_button = collect_into(self.game_ui_elements, Button({}))

	for _, v in pairs(self.game_ui_elements) do
		-- v.group = ui_group
		-- ui_group:add(v)

		v.layer = ui_interaction_layer.Game
		v.force_update = true
	end

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
end

function Game:update(dt)
	camera:follow_object(self.camera_tracker)

	local paused = main:get("settings").in_pause
	local game_over = self.won or self.lost
	if not paused and not game_over then
		run_time = run_time + dt
	end

	if
		self.try_get_results --
		and self.wheel:all_balls_stopped()
		and #self.results == 0
	then
		self.try_get_results = false
		self.results = self.wheel:results()
		self.results_time = 0.4
	end

	if input.z.pressed then
		self.wheel:spin(5)
	end

	if self.wheel.is_spun_up then
		self.wheel.is_spun_up = false
		self.send_balls_to_wheel = true
		self.results_time = 0.1
	end

	if self.send_balls_to_wheel and not self.loading_ball then
		self.loading_ball = true

		if self.results_time > 0.1 then
			self.results_time = self.results_time * 0.9
		end

		local ball = self.player_holder:next_ball()
		if ball then
			self.wheel:new_ball(ball)
		else
			ball = self.enemy_holder:next_ball()
			if ball then
				self.wheel:new_ball(ball, true)
			else
				self.send_balls_to_wheel = false
			end
		end

		local t = self.results_time / 0.5
		if ball then
			sfx.boop:play({ pitch = 1.3 - (0.7 * t), volume = 0.35 })

			trigger:after(self.results_time, function()
				self.loading_ball = false
			end)
		else
			self.loading_ball = false
			trigger:after(2, function()
				self.wheel:stop()
				self.try_get_results = true
			end)
		end
	end

	-- Processing results after wheel:results()
	if
		#self.results > 0 and not self.processing_result --[[ and not self.waiting_on_ball ]]
	then
		self.processing_result = true

		if self.results_time > 0.1 then
			self.results_time = self.results_time * 0.9
		end
		local ball = table.shift(self.results)

		-- ball.spring:pull(0.2, 500, 10)

		local t = self.results_time / 0.5
		-- sfx.boop:play({ pitch = 1.3 - (0.7 * t), volume = 0.35 })

		self.prev_pocket_color = ball.pocket.color
		-- ball.pocket.color = ball.pocket.color:clone():lighten(0.3)

		local ball_results = ball:trigger()

		local time_per_result = 0.2
		local result_counter = 0
		local elapsed_time = 0
		for i, result in ipairs(ball_results) do
			if result.value ~= 0 then
				trigger:after(elapsed_time, function()
					ball.spring:pull(0.2, 500, 10)
					sfx.boop:play({ pitch = 1.3 - (0.7 * t), volume = 0.35 })

					ball.pocket.color = ball.pocket.color:clone():lighten(0.3)
					trigger:after(time_per_result * 0.7, function()
						ball.pocket.color = self.prev_pocket_color
					end)

					local animation_duration = 1.4
					self:play_animation(result, ball, animation_duration, i) -- animation unrelated to the 'logic'
					trigger:after(animation_duration * 0.9, function()
						local target = ball.is_enemy and self.enemy or self.player
						if result.event == "on_score" then
							target.money = target.money + result.value
						elseif result.event == "on_damage" then
							target.damage = target.damage + result.value
						elseif result.event == "on_health" then
							target.hp = target.hp + result.value
						elseif result.event == "on_armour" then
							target.armour = target.armour + result.value
						end
					end)
				end)
				result_counter = result_counter + 1
				elapsed_time = elapsed_time + time_per_result + (result.duration or 0)
			end
		end

		trigger:after(result_counter * time_per_result, function()
			self.processing_result = false

			if #self.results == 0 then
				-- just proceesed the last ball, return the balls to their respective holders
				trigger:after(0.5, function()
					sfx.boop:play({ pitch = 1.3, volume = 0.35 })
					for _, ball in ipairs(self.wheel.balls) do
						if ball.is_enemy then
							self.enemy_holder:insert(ball)
						else
							self.player_holder:insert(ball)
						end
					end

					self.wheel.balls = {}
				end)
			end
		end)
		-- self.waiting_on_ball = ball
	end

	-- if self.waiting_on_ball and self.waiting_on_ball:is_done() then
	-- 	self.waiting_on_ball.pocket.color = self.prev_pocket_color
	-- 	self.processing_result = false
	--
	-- 	if #self.results == 0 then
	-- 		-- just proceesed the last ball, return the balls to their respective holders
	-- 		trigger:after(0.5, function()
	-- 			sfx.boop:play({ pitch = 1.3, volume = 0.35 })
	-- 			for _, ball in ipairs(self.wheel.balls) do
	-- 				if ball.is_enemy then
	-- 					self.enemy_holder:insert(ball)
	-- 				else
	-- 					self.player_holder:insert(ball)
	-- 				end
	-- 			end
	--
	-- 			self.wheel.balls = {}
	-- 		end)
	-- 	end
	-- 	self.waiting_on_ball = nil
	-- end

	self:update_game_object(dt * slow_amount)
	star_group:update(dt * slow_amount)
	self.floor:update(dt * slow_amount)
	self.main:update(dt * slow_amount * self.main_slow_amount)
	self.game_ui:update(dt * slow_amount)
	self.effects:update(dt * slow_amount)
	self.ui:update(dt * slow_amount)
	self.end_ui:update(dt * slow_amount)
end

function Game:play_animation(ball_result, ball, duration, iteration)
	Text_Bubble({
		group = self.ui,
		x = ball.x,
		y = ball.y,
		target = ball.is_enemy and self.enemy or self.player,
		result = ball_result,
		duration = duration,
		iteration = iteration,
	})
end

function Game:win()
	self.won = true
	print("gj, you won")

	if self.song then
		self.song:stop()
	end

	scene_transition(self, {
		x = gw / 2,
		y = gh / 2,
		type = "circle",
		target = {
			scene = Level_Select,
			name = "level_select",
			args = {
				clear_music = true,
			},
		},
		display = {
			text = "gg wp! loading...",
			font = pixul_font,
			alignment = "center",
		},
	})
end

function Game:loss()
	self.lost = true
	print("booo, you lost")

	if self.song then
		self.song:stop()
	end

	scene_transition(self, {
		x = gw / 2,
		y = gh / 2,
		type = "circle",
		target = {
			scene = MainMenu,
			name = "mainmenu",
			args = {
				clear_music = true,
			},
		},
		display = {
			text = "ripperonis, you lost. loading...",
			font = pixul_font,
			alignment = "center",
		},
	})
end

function Game:draw()
	self.floor:draw()
	self.main:draw()
	self.game_ui:draw()
	self.effects:draw()
	self.ui:draw()

	graphics.draw_with_mask(function()
		star_canvas:draw(0, 0, 0, 1, 1)
	end, function()
		camera:attach()
		graphics.rectangle(gw / 2, gh / 2, self.w, self.h, nil, nil, fg[0])
		camera:detach()
	end, true)

	if self.won or self.died then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.end_ui:draw()
end

function Game:on_exit()
	self.main:destroy()
	self.game_ui:destroy()
	self.effects:destroy()
	self.ui:destroy()
	self.end_ui:destroy()

	self.main = nil
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
