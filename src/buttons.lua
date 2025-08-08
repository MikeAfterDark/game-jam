-- Text button
Button = Object:extend()
Button:implement(GameObject)
function Button:init(args)
	self:init_game_object(args)
	self.shape = Rectangle(self.x, self.y, args.w or (pixul_font:get_text_width(self.button_text) + 8), pixul_font.h + 4)
	self.interact_with_mouse = true
	self.selected = false
	self.text = Text({ { text = "[" .. self.fg_color .. "]" .. self.button_text, font = pixul_font, alignment = "center" } }, global_text_tags)

	if controller_mode then
		self.t:every(0.7, function()
			if self.selected then
				self.spring:pull(0.1, 200, 10)
			end
		end)
	end
end

function Button:update(dt)
	self:update_game_object(dt)
	if main.current.in_credits and not self.credits_button then
		return
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
				self:action()
			end
		end
		if self.selected and input.m2.pressed then
			if self.action_2 then
				self:action_2()
			end
		end
	end

	if controller_mode then
		if self.selected then
			if
				input.selection.pressed
				or input.selection_up.pressed
				or input.selection_down.pressed
				or input.selection_left.pressed
				or input.selection_right.pressed
			then
				buttonHover:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
				buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
			end

			if input.selection.pressed then
				self:action()
				self.spring:pull(0.1, 200, 10)
			elseif input.selection_up.pressed and self.button_up then
				self.selected = false
				input.selection_up.pressed = false
				self.button_up.selected = true
				self.button_up.spring:pull(0.3, 200, 10)
			elseif input.selection_down.pressed and self.button_down then
				self.selected = false
				input.selection_down.pressed = false
				self.button_down.selected = true
				self.button_down.spring:pull(0.3, 200, 10)
			elseif input.selection_left.pressed and self.button_left then
				self.selected = false
				input.selection_left.pressed = false
				self.button_left.selected = true
				self.button_left.spring:pull(0.3, 200, 10)
			elseif input.selection_right.pressed and self.button_right then
				self.selected = false
				input.selection_right.pressed = false
				self.button_right.selected = true
				self.button_right.spring:pull(0.3, 200, 10)
			end
		end
	end
end

function Button:draw()
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
	if controller_mode then
		if self.selected then
			local border_size = 10
			graphics.rectangle(
				self.x,
				self.y,
				self.shape.w + border_size,
				self.shape.h + border_size,
				4,
				4,
				fg[0] -- haisudo
			)

			local border_thickness = border_size - 4
			graphics.rectangle(self.x, self.y, self.shape.w + border_thickness, self.shape.h + border_thickness, 4, 4, black[0])
		end
	end

	graphics.rectangle(
		self.x,
		self.y,
		self.shape.w,
		self.shape.h,
		4,
		4,
		--[[ self.selected and fg[0] or ]]
		_G[self.bg_color][0]
	)
	self.text:draw(self.x, self.y + 1, 0, 1, 1)
	graphics.pop()
end

function Button:on_mouse_enter()
	if main.current.in_credits and not self.credits_button or controller_mode then
		return
	end
	buttonHover:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	self.selected = true
	self.text:set_text({ { text = "[fgm10]" .. self.button_text, font = pixul_font, alignment = "center" } })
	self.spring:pull(0.2, 200, 10)
	if self.mouse_enter then
		self:mouse_enter()
	end
end

function Button:on_mouse_exit()
	if main.current.in_credits and not self.credits_button or controller_mode then
		return
	end
	self.text:set_text({
		{ text = "[" .. self.fg_color .. "]" .. self.button_text, font = pixul_font, alignment = "center" },
	})
	self.selected = false
	if self.mouse_exit then
		self:mouse_exit()
	end
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
--
--
-- Image Button
ImageButton = Object:extend()
ImageButton:implement(GameObject)
function ImageButton:init(args)
	self:init_game_object(args)
	self.shape = Rectangle(self.x, self.y, args.w or (pixul_font:get_text_width(self.button_text) + 8), pixul_font.h + 4)
	self.interact_with_mouse = true
	self.image = Image(args.img_name) -- TODO: IMPLEMENT THIS AND SETUP LEVEL SELECT
	self.text = Text({ { text = "[" .. self.fg_color .. "]" .. self.button_text, font = pixul_font, alignment = "center" } }, global_text_tags)
end

function ImageButton:update(dt)
	self:update_game_object(dt)
	if main.current.in_credits and not self.credits_button then
		return
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
				self:action()
			end
		end
		if self.selected and input.m2.pressed then
			if self.action_2 then
				self:action_2()
			end
		end
	end
end

function ImageButton:draw()
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
	graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.selected and fg[0] or _G[self.bg_color][0])
	self.text:draw(self.x, self.y + 1, 0, 1, 1)
	graphics.pop()
end

function ImageButton:on_mouse_enter()
	if main.current.in_credits and not self.credits_button then
		return
	end
	buttonHover:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	self.selected = true
	self.text:set_text({ { text = "[fgm5]" .. self.button_text, font = pixul_font, alignment = "center" } })
	self.spring:pull(0.2, 200, 10)
	if self.mouse_enter then
		self:mouse_enter()
	end
end

function ImageButton:on_mouse_exit()
	if main.current.in_credits and not self.credits_button then
		return
	end
	self.text:set_text({
		{ text = "[" .. self.fg_color .. "]" .. self.button_text, font = pixul_font, alignment = "center" },
	})
	self.selected = false
	if self.mouse_exit then
		self:mouse_exit()
	end
end

function ImageButton:set_text(text)
	self.button_text = text
	self.text:set_text({
		{ text = "[" .. self.fg_color .. "]" .. self.button_text, font = pixul_font, alignment = "center" },
	})
	self.spring:pull(0.2, 200, 10)
end
