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
