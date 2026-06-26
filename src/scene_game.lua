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
	self.game_ui = Group():no_camera()
	self.effects = Group()
	self.ui = Group()
	self.end_ui = Group():no_camera()

	self.main_slow_amount = 1
	slow_amount = 1

	self.x1, self.y1 = 0, 0
	self.x2, self.y2 = gw, gh
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1
	self.song_info_text = Text({ { text = "", font = pixul_font, alignment = "center" } }, global_text_tags)

	self.won = false
	self.lost = false

	self.game_ui_elements = {}

	-- if layer underneath this one has layer_type == "game" and the same music type then dont push
	local layer = main.ui_layer_stack:peek()
	if layer and layer.music_type ~= self.music_type then
		if layer.game then
			pop_ui_layer(self)
		end

		main.ui_layer_stack:push({
			layer = ui_interaction_layer.Game,
			layer_has_music = args.layer_has_music,
			-- game = true,
			music_type = args.music_type,
			ui_elements = self.game_ui_elements,
		})
	end

	local num_pockets = 36
	local pockets = {}

	local c1 = red[0]:clone()
	c1.a = 0.4

	local c2 = green[0]:clone()
	c2.a = 0.4
	for i = 1, num_pockets do
		table.insert(pockets, {
			color = i % 2 == 0 and c1:clone() or c2:clone(),
			type = i == 1 and Pocket_Type.Jackpot or i == math.floor(num_pockets / 2) and Pocket_Type.Void or Pocket_Type.Normal,
			value = i - 1,
			size = 1,
		})
	end

	local balls = {}
	for i = 1, 10 do
		table.insert(
			balls,
			Ball({
				group = self.main,
				x = gw * 0.5,
				y = gh * 0.5,
				r = gh * 0.009,
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

	self.wheel:spin(5)
	trigger:after(3, function()
		self.wheel:stop()
	end)
end

function Game:update(dt)
	camera:follow_object(self.camera_tracker)

	local paused = main:get("settings").in_pause
	local game_over = self.won or self.lost
	if not paused and not game_over then
		run_time = run_time + dt
	end

	if input.space.pressed then
		self.results = self.wheel:results()

		local time = 0.2
		for i, ball in ipairs(self.results) do
			trigger:after(time * i, function()
				ball.spring:pull(0.2, 500, 10)

				if ball.pocket then
					local prev_color = ball.pocket.color
					ball.pocket.color = blue[0]
					trigger:after(time * 0.9, function()
						ball.pocket.color = prev_color
					end)
				end
			end)
		end
	end

	self:update_game_object(dt * slow_amount)
	star_group:update(dt * slow_amount)
	self.floor:update(dt * slow_amount)
	self.main:update(dt * slow_amount * self.main_slow_amount)
	self.game_ui:update(dt * slow_amount)
	self.effects:update(dt * slow_amount)
	self.ui:update(dt * slow_amount)
	self.end_ui:update(dt * slow_amount)
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
