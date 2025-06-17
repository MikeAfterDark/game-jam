MainMenu = Object:extend()
MainMenu:implement(State)
MainMenu:implement(GameObject)
function MainMenu:init(name)
	self:init_state(name)
	self:init_game_object()
end

function MainMenu:on_enter(from)
	slow_amount = 1
	-- trigger:tween(2, main_song_instance, { volume = 0.5, pitch = 1 }, math.linear)

	self.floor = Group()
	self.main = Group():set_as_physics_world(
		32,
		0,
		0,
		{ "player", "enemy", "projectile", "enemy_projectile", "force_field", "ghost" }
	)
	self.post_main = Group()
	self.effects = Group()
	self.main_ui = Group():no_camera()
	self.ui = Group():no_camera()

	-- Spawn solids and player
	self.x1, self.y1 = gw / 2 - 0.8 * gw / 2, gh / 2 - 0.8 * gh / 2
	self.x2, self.y2 = gw / 2 + 0.8 * gw / 2, gh / 2 + 0.8 * gh / 2
	self.w, self.h = self.x2 - self.x1, self.y2 - self.y1

	self.title_text =
		Text({ { text = "[wavy_mid, fg]HI MOM", font = fat_font, alignment = "center" } }, global_text_tags)

	self.play = Button({
		group = self.main_ui,
		x = 39,
		y = gh / 2 - 10,
		force_update = true,
		button_text = "play",
		fg_color = "bg10",
		bg_color = "bg",
		action = function(b)
			ui_transition2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			TransitionEffect({
				group = main.transitions,
				x = gw / 2,
				y = gh / 2,
				color = state.dark_transitions and bg[-2] or fg[0],
				transition_action = function()
					self.transitioning = true
					slow_amount = 1
					system.save_state()
					main:go_to("level_select")
				end,
				text = Text({
					{
						text = "[wavy, " .. tostring(state.dark_transitions and "fg" or "bg") .. "]Feeding whales...",
						font = pixul_font,
						alignment = "center",
					},
				}, global_text_tags),
			})
		end,
	})
	self.options_button = Button({
		group = self.main_ui,
		x = 47,
		y = gh / 2 + 12,
		force_update = true,
		button_text = "options",
		fg_color = "bg10",
		bg_color = "bg",
		action = function(b)
			if not self.paused then
				open_options(self)
			else
				close_options(self)
			end
		end,
	})
	self.quit_button = Button({
		group = self.main_ui,
		x = 37,
		y = gh / 2 + 34,
		force_update = true,
		button_text = "quit",
		fg_color = "bg10",
		bg_color = "bg",
		action = function(b)
			system.save_state()
			love.event.quit()
		end,
	})
	self.t:every(2, function()
		self.soundtrack_button.spring:pull(0.025, 200, 10)
	end)
	self.soundtrack_button = Button({
		group = self.main_ui,
		x = gw - 72,
		y = gh - 40,
		force_update = true,
		button_text = "buy the soundtrack!",
		fg_color = "bg10",
		bg_color = "bg",
		action = function(b)
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			b.spring:pull(0.2, 200, 10)
			b.selected = true
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			system.open_url("https://kubbimusic.com/album/ember")
		end,
	})
	self.discord_button = Button({
		group = self.main_ui,
		x = gw - 92,
		y = gh - 17,
		force_update = true,
		button_text = "join the community discord!",
		fg_color = "bg10",
		bg_color = "bg",
		action = function(b)
			ui_switch2:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			b.spring:pull(0.2, 200, 10)
			b.selected = true
			ui_switch1:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			system.open_url("https://discord.gg/4d6GWmChKY")
		end,
	})
end

function MainMenu:on_exit()
	self.floor:destroy()
	self.main:destroy()
	self.post_main:destroy()
	self.effects:destroy()
	self.ui:destroy()
	self.main_ui:destroy()
	self.t:destroy()
	self.floor = nil
	self.main = nil
	self.post_main = nil
	self.effects = nil
	self.ui = nil
	self.units = nil
	self.player = nil
	self.t = nil
	self.springs = nil
	self.flashes = nil
	self.hfx = nil
	self.title_text = nil
end

function MainMenu:update(dt)
	-- if main_song_instance:isStopped() then
	-- main_song_instance = _G[random:table({ "song1", "song2", "song3", "song4", "song5" })]:play({ volume = 0.5 })
	-- end

	self:update_game_object(dt * slow_amount)

	if not self.paused and not self.transitioning then
		-- star_group:update(dt * slow_amount)
		self.floor:update(dt * slow_amount)
		self.main:update(dt * slow_amount)
		self.post_main:update(dt * slow_amount)
		self.effects:update(dt * slow_amount)
		self.main_ui:update(dt * slow_amount)
		if self.title_text then
			self.title_text:update(dt)
		end
		self.ui:update(dt * slow_amount)
	else
		self.ui:update(dt * slow_amount)
	end
end

function MainMenu:draw()
	self.floor:draw()
	self.main:draw()
	self.post_main:draw()
	self.effects:draw()
	graphics.draw_with_mask(function()
		star_canvas:draw(0, 0, 0, 1, 1)
	end, function()
		camera:attach()
		graphics.rectangle(gw / 2, gh / 2, self.w, self.h, nil, nil, fg[0])
		camera:detach()
	end, true)
	graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)

	self.main_ui:draw()
	self.title_text:draw(60, gh / 2 - 40)
	if self.paused then
		graphics.rectangle(gw / 2, gh / 2, 2 * gw, 2 * gh, nil, nil, modal_transparent)
	end
	self.ui:draw()
end
