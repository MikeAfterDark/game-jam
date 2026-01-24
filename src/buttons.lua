ButtonBase = Object:extend()
ButtonBase:implement(GameObject)
function ButtonBase:init(args)
	self:init_game_object(args)
	self.interact_with_mouse = true
	self.selected = false
end

function ButtonBase:update(dt)
	self:update_game_object(dt)
	if not on_current_ui_layer(self) then
		return
	end

	if
		on_current_ui_layer(self)
		and not (main.current.button_restriction and main.current:button_restriction())
		and not self.selected
		and self.colliding_with_mouse
	then
		self:on_mouse_enter()
	end

	if self.hold_button then
		if self.selected and input.m1.pressed then
			self.press_time = love.timer.getTime()
			self.spring:pull(0.2, 200, 10)
		end
		if self.press_time then
			if input.m1.down and love.timer.getTime() - self.press_time > self.hold_button then
				self:action()
				self.press_time = nil
				self.spring:pull(0.1, 200, 10)
			end
		end
		if input.m1.released then
			self.press_time = nil
			self.spring:pull(0.1, 200, 10)
		end
	else
		if self.selected and input.m1.pressed then
			if self.action then
				-- random:table(ui_click):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
				self:action()
			end
		end
		if self.selected and input.m2.pressed then
			if self.action_2 then
				-- random:table(ui_click):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
				self:action_2()
			end
		end
	end
end

function ButtonBase:on_mouse_enter()
	if not on_current_ui_layer(self) or (main.current.button_restriction and main.current:button_restriction()) or self.invis then
		return false
	end

	if self.enter_sfx then
		-- random:table(self.enter_sfx):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	else
		-- random:table(ui_hover):play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	end

	-- buttonHover:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	-- buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	self.selected = true
	-- debug.traceback()
	-- print("BASE mouse_enter", self, debug.traceback())
	return true
end

function ButtonBase:on_mouse_exit()
	-- if not on_current_ui_layer(self) then
	-- 	return
	-- end

	self.selected = false
	return true
end

--
--
-- Text button
--
--
Button = ButtonBase:extend()
function Button:init(args)
	ButtonBase.init(self, args)
	self.shape = Rectangle(self.x, self.y, args.w or (pixul_font:get_text_width(self.button_text) + 8), pixul_font.h + 4)
	self.text = Text({ { text = "[" .. self.fg_color .. "]" .. self.button_text, font = pixul_font, alignment = "center" } }, global_text_tags)
end

function Button:update(dt)
	ButtonBase.update(self, dt)
	self.text:update(dt)
end

function Button:draw()
	if self.y > gh and self.invis then
		return
	end
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	if self.hold_button and self.press_time then
		graphics.set_line_width(5)
		graphics.set_color(fg[-5])
		graphics.arc(
			"open",
			self.x,
			self.y,
			0.6 * self.shape.w,
			0,
			math.remap(love.timer.getTime() - self.press_time, 0, self.hold_button, 0, 1) * 2 * math.pi
		)
		graphics.set_line_width(1)
	end

	graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, _G[self.bg_color][0])
	self.text:draw(self.x, self.y + 5, 0, 1, 1)
	graphics.pop()
end

function Button:on_mouse_enter()
	if not ButtonBase.on_mouse_enter(self) then
		return
	end
	self.text:set_text({
		{
			text = "[fgm10]" .. self.button_text,
			font = pixul_font,
			alignment = "center",
		},
	})
	self.spring:pull(0.2, 200, 10)
end

function Button:on_mouse_exit()
	if not ButtonBase.on_mouse_exit(self) then
		return
	end

	self.text:set_text({
		{ text = "[" .. self.fg_color .. "]" .. self.button_text, font = pixul_font, alignment = "center" },
	})
end

function Button:set_text(text)
	self.button_text = text
	self.text:set_text({
		{ text = "[" .. self.fg_color .. "]" .. self.button_text, font = pixul_font, alignment = "center" },
	})
	self.spring:pull(0.2, 200, 10)
end

--
--
-- Input button: for options menu stuffs
--
--
InputButton = ButtonBase:extend()
function InputButton:init(args)
	ButtonBase.init(self, args)

	self.shape = Rectangle(self.x, self.y, args.w or (pixul_font:get_text_width(self.button_text) + 8), pixul_font.h + 4)
	self.action_text = Text({ { text = "[" .. self.fg_color .. "]" .. self.description_text, font = pixul_font, alignment = "center" } }, global_text_tags)
	self.input_text = Text({ { text = "[" .. self.fg_color .. "]" .. self.button_text, font = pixul_font, alignment = "center" } }, global_text_tags)
end

function InputButton:update(dt)
	ButtonBase.update(self, dt)
end

function InputButton:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	if self.hold_button and self.press_time then
		graphics.set_line_width(5)
		graphics.set_color(fg[-5])
		graphics.arc(
			"open",
			self.x,
			self.y,
			0.6 * self.shape.w,
			0,
			math.remap(love.timer.getTime() - self.press_time, 0, self.hold_button, 0, 1) * 2 * math.pi
		)
		graphics.set_line_width(1)
	end

	local text_distance_apart = self.shape.w / 3
	self.action_text:draw(self.x - text_distance_apart, self.y + 0, 0, 1, 1)
	self.input_text:draw(self.x + text_distance_apart, self.y + 0, 0, 1, 1)
	graphics.pop()

	local halfway = self.separator_length
	local separator_height = self.y + 8
	graphics.dashed_line(self.x - halfway, separator_height, self.x + halfway, separator_height, 4, 1, _G[self.bg_color][0], 1)
end

function InputButton:on_mouse_enter()
	if not ButtonBase.on_mouse_enter(self) then
		return
	end

	self.input_text:set_text({
		{
			text = "[fgm10]" .. self.button_text,
			font = pixul_font,
			alignment = "center",
		},
	})
	self.spring:pull(0.2, 200, 10)
end

function InputButton:on_mouse_exit()
	if not ButtonBase.on_mouse_exit(self) then
		return
	end

	self.input_text:set_text({
		{ text = "[" .. self.fg_color .. "]" .. self.button_text, font = pixul_font, alignment = "center" },
	})
end

function InputButton:set_text(text)
	self.button_text = text
	self.input_text:set_text({
		{ text = "[" .. self.fg_color .. "]" .. self.button_text, font = pixul_font, alignment = "center" },
	})
	self.spring:pull(0.2, 200, 10)
end

--
--
-- Rectangle-Image button: for menu selection stuffs
--
--
RectangleButton = ButtonBase:extend()
function RectangleButton:init(args)
	ButtonBase.init(self, args)
	self.color = self.color or _G[self.bg_color][0]
	self.shape = Rectangle(self.x, self.y, self.w, self.h)
	if self.title_text then
		self.text = --Text({ { text = "[" .. self.fg_color .. "]" .. self.title_text, font = pixul_font, alignment = "center" } }, global_text_tags)
			Text2({
				x = self.x,
				y = self.y,
				lines = {
					{
						text = "[" .. self.fg_color .. "]" .. self.title_text,
						font = pixul_font,
						wrap = self.wrap and self.w * 1.5 or nil,
					},
				},
			})
	end

	if not self.no_image then
		self.image = love.filesystem.getInfo(self.image_path) and Image(self.image_path, true) or nil
	end

	if self.level then
		self.level_name = self.level.name
		if not state[self.level_name] then
			state[self.level_name] = -1
		end

		self.pb_text = Text({
			{
				text = "[yellow]" .. ((state[self.level_name] > 0) and string.format("%.2f", state[self.level_name]) or ""),
				font = pixul_font,
				alignment = "center",
			},
		}, global_text_tags)
	end
end

function RectangleButton:update(dt)
	ButtonBase.update(self, dt)

	if self.text then
		self.text:update(dt)
	end

	if self.pb_text then
		self.pb_text:set_text({
			{
				text = "[yellow]" .. ((state[self.level_name] > 0) and string.format("%.2f", state[self.level_name]) or ""),
				font = pixul_font,
				alignment = "center",
			},
		})
	end
end

function RectangleButton:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)

	graphics.rectangle(
		self.x,
		self.y,
		self.shape.w,
		self.shape.h,
		4,
		4,
		--[[ self.selected and fg[0] or ]]
		self.color
	)
	local scale = 1
	local color = _G["white"][0]
	if self.image then
		self.image:draw(self.x, self.y, 0, scale, scale, 0, 0, color)
	end

	if self.hold_button and self.press_time then
		graphics.set_line_width(5)
		graphics.set_color(fg[-5])
		graphics.arc(
			"open",
			self.x,
			self.y,
			0.6 * self.shape.w,
			0,
			math.remap(love.timer.getTime() - self.press_time, 0, self.hold_button, 0, 1) * 2 * math.pi
		)
		graphics.set_line_width(1)
	end

	if self.text then
		self.text:draw(self.x, self.y + 5, 0, 1, 1)
	end
	if self.pb_text then
		self.pb_text:draw(self.x + self.w * 0.4, self.y - self.h * 0.4, math.pi / 4, self.spring.x, self.spring.y)
	end
	graphics.pop()
end

function RectangleButton:on_mouse_enter()
	if not ButtonBase.on_mouse_enter(self) then
		return
	end

	-- self.text:set_text({
	-- 	{
	-- 		text = "[fgm10]" .. self.title_text,
	-- 		font = pixul_font,
	-- 		alignment = "center",
	-- 	},
	-- })
	self.spring:pull(0.2, 200, 10)

	-- debug.traceback()
	-- print("RECT mouse_enter", self, debug.traceback())
end

function RectangleButton:on_mouse_exit()
	if not ButtonBase.on_mouse_exit(self) then
		return
	end
	-- self.text:set_text({
	-- 	{ text = "[" .. self.fg_color .. "]" .. self.title_text, font = pixul_font, alignment = "center" },
	-- })
end

function RectangleButton:set_text(text)
	self.title_text = text
	self.text:set_text({
		{ text = "[" .. self.fg_color .. "]" .. self.title_text, font = pixul_font, alignment = "center" },
	})
	self.spring:pull(0.2, 200, 10)
end
