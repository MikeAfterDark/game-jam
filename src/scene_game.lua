Game = Object:extend()
Game:implement(State)
Game:implement(GameObject)
function Game:init(name)
	self:init_state(name)
	self:init_game_object()
end

Group_Layers = {
	Main = 1,
	Shop = 2,
	Shop_UI = 3,
	Shelf = 4,

	Cover = 999,
}

function Game:on_enter(from, args)
	camera.x, camera.y = gw * 0.5, gh * 0.5
	camera.r = 0

	self.floor = Group()
	-- self.main = Group()
	self.main = Group():set_as_physics_world(32, 0, 0, { "wheel", "ball" })
	self.shop = Group():set_as_physics_world(32, 0, 0, { "drawer", "ball" })
	self.game_ui = Group()
	self.effects = Group()
	self.ui = Group()
	self.end_ui = Group():no_camera()

	self.main.layer = Group_Layers.Main
	self.shop.layer = Group_Layers.Shop
	self.game_ui.layer = Group_Layers.Shop_UI
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
				rs = ball_radius,
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
	self.wheel:set_mode({
		mode = WheelCenter_Mode.Spin,
		action = function(b)
			b.spring:pull(0.2, 200, 10)
			self.wheel:spin(5)
			self.player_holder:disable_ball_selection()
			self.enemy_holder:disable_ball_selection()
		end,
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

	self.player_holder:setup(9, 8, {
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			rs = ball_radius,
			type = random:table(Ball_Type),
		}),
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			rs = ball_radius,
			type = random:table(Ball_Type),
		}),
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			rs = ball_radius,
			type = random:table(Ball_Type),
		}),
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			rs = ball_radius,
			type = random:table(Ball_Type),
		}),
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			rs = ball_radius,
			type = random:table(Ball_Type),
		}),
		Ball({
			group = self.main,
			x = gw * 0.5,
			y = gh * 0.5,
			rs = ball_radius,
			type = random:table(Ball_Type),
		}),
	})
	self.player_holder:enable_ball_selection()

	self.enemy = Character({
		group = self.main,
		x = gw * 0.75,
		y = gh * 0.2,
		holder = self.enemy_holder,
	})
	self.enemy:load_next_enemy()

	self.player = Character({
		group = self.main,
		x = gw * 0.85,
		y = gh * 0.9,
		money = 5,
		max_hp = 10,
	})

	self.ball_shop = Shop({
		group = self.shop,
		x = gw * 0.0,
		y = gh * 0.5,
		w = gw * 0.2,
		h = gh * 0.4,
		player = self.player,
		left_limit = 0,
		right_limit = gw * 0.19,
	})

	self.shelf = Shelf({
		group = self.game_ui,
		x = 0,
		y = gh * 0.5,
		w = gw * 0.2,
		h = gh,
		color = bg[4],
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

	local y_dist = gh * 0.03
	-- self.spin_button = collect_into(
	-- 	self.game_ui_elements,
	-- 	Button({
	-- 		group = self.main,
	-- 		x = self.wheel.x,
	-- 		y = self.wheel.y - y_dist,
	-- 		fg_color = "black",
	-- 		bg_color = "green",
	-- 		button_text = "Spin",
	-- 		action = function(b)
	-- 			b.spring:pull(0.2, 200, 10)
	-- 			self.wheel:spin(5)
	-- 			self.player_holder:disable_ball_selection()
	-- 			self.enemy_holder:disable_ball_selection()
	-- 			-- b.locked = true
	-- 		end,
	-- 	})
	-- )

	-- self.select_button = collect_into(
	-- 	self.game_ui_elements,
	-- 	Button({
	-- 		group = self.main,
	-- 		x = self.wheel.x,
	-- 		y = self.wheel.y + y_dist,
	-- 		fg_color = "black",
	-- 		bg_color = "green",
	-- 		button_text = "Select",
	-- 		action = function(b)
	-- 			b.spring:pull(0.2, 200, 10)
	--
	-- 			if
	-- 				self.try_get_results --
	-- 				and self.wheel:all_balls_stopped()
	-- 				-- and self.wheel:all_balls_selected()
	-- 				and self.wheel:any_balls_selected()
	-- 				and #self.results == 0
	-- 			then
	-- 				self.try_get_results = false
	-- 				self.results = self.wheel:results()
	-- 				self.results_time = 0.4
	-- 				-- b.locked = true
	-- 			else
	-- 				sfx.boop:play({ pitch = 0.6, volume = 0.35 })
	-- 			end
	-- 		end,
	-- 	})
	-- )

	local popup_width = gw * 0.2
	self.info_popup = TextBox({
		group = self.main,
		visible = false,
		x = gw * 0.87,
		y = gh * 0.6,
		w = popup_width,
		h = gh * 0.3,
		lines = {
			{
				text = "title",
				font = pixul_font,
				wrap = popup_width,
			},
			{
				text = "description",
				font = small_pixul_font,
				wrap = popup_width,
			},
		},
	})

	self.holder_popup = TextBox({
		group = self.main,
		visible = false,
		hoverable = true,
		x = gw * 0.5,
		y = gh * 0.5,
		w = popup_width,
		h = gh * 0.3,
		lines = {
			{
				text = "title",
				font = pixul_font,
				wrap = popup_width,
			},
			{
				text = "description",
				font = small_pixul_font,
				wrap = popup_width,
			},
		},
		button = collect_into(
			self.game_ui_elements,
			Button({
				visible = false,
				group = self.main,
				x = gh * 0.1,
				y = gh * 0.1,
				fg_color = "black",
				bg_color = "green",
				button_text = "sell $#",
				action = function(b)
					b.spring:pull(0.2, 200, 10)
					self:sell(b.parent.obj)
					-- b.parent:clear_object()
					-- b.locked = true
				end,
			})
		),
	})

	self.shop_popup = TextBox({
		group = self.game_ui,
		visible = false,
		hoverable = true,
		share_selection = true,
		x = gw * 0.5,
		y = gh * 0.5,
		w = popup_width,
		h = gh * 0.3,
		lines = {
			{
				text = "title",
				font = pixul_font,
				wrap = popup_width,
			},
			{
				text = "description",
				font = small_pixul_font,
				wrap = popup_width,
			},
		},
		button = collect_into(
			self.game_ui_elements,
			Button({
				visible = false,
				group = self.game_ui,
				x = gh * 0.1,
				y = gh * 0.1,
				fg_color = "bg",
				bg_color = "green",
				button_text = "buy $#",
				action = function(b)
					b.spring:pull(0.2, 200, 10)
					self:buy(b.parent.obj)
					-- b.parent:clear_object()
					-- b.locked = true
				end,
			})
		),
	})

	for _, v in pairs(self.game_ui_elements) do
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

	self.num_balls_per_selection = 3
end

function Game:next_round()
	local has_enemy = self.enemy:load_next_enemy()
	print(has_enemy)
	-- reset wheel/balls etc
	return has_enemy
end

function Game:update(dt)
	mouse.group_layer = 0
	camera:follow_object(self.camera_tracker)

	local paused = main:get("settings").in_pause
	local game_over = false --self.won or self.lost
	if not paused and not game_over then
		run_time = run_time + dt
	end

	if input.z.pressed then
		self.wheel:spin(5)
	end

	if input.x.pressed then
		self.enemy:die()
	end

	if input.c.pressed then
		self:win()
	end
	if input.v.pressed then
		self:loss()
	end

	if self.wheel.is_spun_up then
		self.ball_shop:close()
		self.wheel.is_spun_up = false
		self.send_balls_to_wheel = true
		self.results_time = 0.1

		self.player_holder:disable_ball_selection()
		self.enemy_holder:disable_ball_selection()
	end

	-- setup the wheel for user input to select what balls they want active
	if self.try_get_results and self.wheel:all_balls_stopped() and not self.balls_enabled then
		self.try_get_results = false

		self.wheel:enable_ball_selection(self.num_balls_per_selection)
		self.wheel:set_mode({
			mode = WheelCenter_Mode.Select,
			action_check = function()
				return not self.wheel:any_balls_selected()
				-- return self.wheel:all_balls_selected()
			end,
			action = function()
				self.results = self.wheel:results()
				self.results_time = 0.4
				self.next_result_time = run_time
				sfx.boop:play({ pitch = 0.6, volume = 0.35 })
			end,
		})
		self.balls_enabled = true
	end

	-- all the info boxes and popups stuffs
	if self.hovered_ball and self.hovered_ball.selected then
		local ball = self.hovered_ball
		if ball.mode == Ball_Interaction_Mode.Wheel_Selection and self.info_popup.obj_id ~= ball.id then
			self.info_popup:set_object(ball)
			--
		elseif ball.mode == Ball_Interaction_Mode.Ball_Holder and self.holder_popup.obj_id ~= ball.id then
			self.holder_popup:set_object(ball)
			self.holder_popup.button.visible = not ball.is_enemy
			self.holder_popup:position_holder_popup()
			self.holder_popup.button:set_text("Sell $" .. self.hovered_ball:sell_price())
			--
		elseif ball.mode == Ball_Interaction_Mode.Shop_Drawer then
			if self.shop_popup.obj_id ~= ball.id then
				self.shop_popup:set_object(ball)
				self.shop_popup.button.visible = true
				self.shop_popup.button:set_text("Buy $" .. self.hovered_ball:buy_price())
				self.shop_popup:position_shop_popup()
			end
			self.shop_popup.button.locked = not self:can_buy_ball(self.hovered_ball)
		end
	elseif not self.hovered_ball or not self.hovered_ball.selected then
		self.info_popup:clear_object()
		self.holder_popup:clear_object()
		self.shop_popup:clear_object()
	end

	-- send the balls from the holders to the wheel, if we aren't already...
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

			self.t:after(self.results_time, function()
				self.loading_ball = false
				self.balls_enabled = false
			end)
		else
			self.loading_ball = false
			self.t:after(2, function()
				self.wheel:stop()
				self.try_get_results = true
			end)
		end
	end

	-- process each ball result one by one, then return the balls to the holders and
	-- reset temp wheel mods
	self.next_result_time = self.next_result_time or 0
	self.ball_results = self.ball_results or {}
	self.num_ball_results = self.num_ball_results or 0
	if (#self.results > 0 or #self.ball_results > 0) and self.next_result_time < run_time then
		local time_per_result = 0.1
		self.next_result_time = run_time + time_per_result

		while #self.ball_results == 0 and #self.results > 0 do
			self.ball_to_process = table.shift(self.results)
			_, self.ball_results = table.reject(self.ball_to_process:trigger({}), function(result)
				return result.value == 0
			end)
			self.num_ball_results = #self.ball_results
			self.prev_pocket_color = self.ball_to_process.pocket.color
		end

		if #self.ball_results > 0 then
			local result = table.shift(self.ball_results)
			local ball = self.ball_to_process

			sfx.boop:play({ pitch = 1.3 - 0.7, volume = 0.35 })
			ball.spring:pull(0.2, 500, 10)
			ball.pocket.color = ball.pocket.color:clone():lighten(0.3)

			self.t:after(time_per_result * 0.7, function()
				ball.pocket.color = self.prev_pocket_color
			end)

			local animation_duration = 1.4
			local iteration = self.num_ball_results - #self.ball_results
			self:play_animation(result, ball, animation_duration, iteration) -- animation unrelated to the 'logic'

			self.t:after(animation_duration * 0.9, function()
				local target = ball.is_enemy and self.enemy or self.player
				local event = result.event

				if event == Ball_Event.On_Score then
					target.money = target.money + result.value
				elseif event == Ball_Event.On_Damage then
					target = ball.is_enemy and self.player or self.enemy -- deal damage to opposite unit
					target:take_damage(result.value)
				elseif event == Ball_Event.On_Heal then
					target:heal(result.value)
				elseif event == Ball_Event.On_Armour then
					target:armour_up(result.value)
				end
			end)
		end

		if #self.ball_results == 0 and #self.results == 0 then
			self.t:after(0.5, function()
				sfx.boop:play({ pitch = 1.3, volume = 0.35 })
				for _, ball in ipairs(self.wheel.balls) do
					if ball.is_enemy then
						self.enemy_holder:insert(ball)
					else
						self.player_holder:insert(ball)
					end
				end

				self.player_holder:enable_ball_selection()
				self.enemy_holder:enable_ball_selection()

				self.wheel:set_mode({
					mode = WheelCenter_Mode.Spin,
					action = function(b)
						b.spring:pull(0.2, 200, 10)
						self.wheel:spin(5)
						self.player_holder:disable_ball_selection()
						self.enemy_holder:disable_ball_selection()
					end,
				})

				self.wheel.balls = {}
			end)
		end
	end

	if not (self.lost or self.won) then
		if self.player.has_died then
			self:loss()
		elseif self.enemy.has_died then
			local can_continue = self:next_round()
			if not can_continue then
				self:win()
			end
		end
	end

	-- self:update_game_object(dt * slow_amount)
	-- star_group:update(dt * slow_amount)
	-- self.floor:update(dt * slow_amount)
	-- self.main:update(dt * slow_amount * self.main_slow_amount)
	-- self.shop:update(dt * slow_amount * self.main_slow_amount)
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
	self.shop:update(dt * slow_amount * self.main_slow_amount)
	self.main:update(dt * slow_amount * self.main_slow_amount)
	self.floor:update(dt * slow_amount)
	star_group:update(dt * slow_amount)
	self:update_game_object(dt * slow_amount)
end

function Game:can_buy_ball(ball)
	return self.player.money >= ball:buy_price() and self.player_holder:has_room()
end

function Game:buy(ball)
	if self:can_buy_ball(ball) then
		self.shop_popup:clear_object(true)
		self.shop_popup.selected = false
		self.ball_shop:remove(ball)
		ball.dead = true
		self.player.money = self.player.money - ball:buy_price()

		-- TODO:
		local new_ball = Ball({
			group = self.main,
			type = ball.type,
		}) -- clone the ball onto the self.main group
		new_ball:trigger({ Ball_Event.On_Buy })

		sfx.boop:play({ pitch = 0.6, volume = 0.35 })
		self.player_holder:insert(new_ball)
	end
end

function Game:sell(ball)
	local sale_price = ball:sell_price()

	local duration = 1
	self:play_animation( --
		{             --
			event = Ball_Event.On_Sale,
			value = sale_price,
		},
		ball,
		duration,
		1
	)
	self.holder_popup:clear_object(true)
	self.player_holder:remove(ball)
	ball.dead = true

	self.t:after(0.8 * duration, function()
		sfx.boop:play({ pitch = 0.6, volume = 0.35 })
		self.player.money = self.player.money + sale_price
	end)
end

function Game:play_animation(ball_result, ball, duration, iteration)
	local target = ball_result.event == Ball_Event.On_Damage --
		and (ball.is_enemy and self.player or self.enemy) --
		or (ball.is_enemy and self.enemy or self.player)
	Text_Bubble({
		group = self.ui,
		x = ball.x,
		y = ball.y,
		target = target,
		result = ball_result,
		duration = duration,
		iteration = iteration,
	})
end

function Game:win()
	if not self.won then
		self.won = true
		self.end_game_cover.visible = true
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

	-- if self.song then
	-- 	self.song:stop()
	-- end
	--
	-- scene_transition(self, {
	-- 	x = gw / 2,
	-- 	y = gh / 2,
	-- 	type = "circle",
	-- 	target = {
	-- 		scene = Level_Select,
	-- 		name = "level_select",
	-- 		args = {
	-- 			clear_music = true,
	-- 		},
	-- 	},
	-- 	display = {
	-- 		text = "gg wp! loading...",
	-- 		font = pixul_font,
	-- 		alignment = "center",
	-- 	},
	-- })
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

	-- if self.song then
	-- 	self.song:stop()
	-- end
	--
	-- scene_transition(self, {
	-- 	x = gw / 2,
	-- 	y = gh / 2,
	-- 	type = "circle",
	-- 	target = {
	-- 		scene = MainMenu,
	-- 		name = "mainmenu",
	-- 		args = {
	-- 			clear_music = true,
	-- 		},
	-- 	},
	-- 	display = {
	-- 		text = "ripperonis, you lost. loading...",
	-- 		font = pixul_font,
	-- 		alignment = "center",
	-- 	},
	-- })
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
	self.main:draw()
	self.shop:draw()
	self.game_ui:draw()
	self.effects:draw()
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
	self.shop:destroy()
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
