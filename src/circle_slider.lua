Circle_Slider = Object:extend()
Circle_Slider:implement(GameObject)
function Circle_Slider:init(args)
	self:init_game_object(args)
	self.visible_size = 0
	self.shape = Circle(self.x, self.y, self.visible_size)
	self.interact_with_mouse = true
	self.expanded = false

	self.rotation = args.rotation or 0
	self.inner_deadzone = 0.5 -- center safe zone (percent of radius)
	self.num_slices = self.max_value - self.min_value + 1
	self.rotation = self.rotation + (math.pi / self.num_slices)

	self.text_offset = 14
	self.description_text = Text2({
		-- group = self.group,
		layer = self.layer,
		x = self.x,
		y = self.y - self.text_offset,
		lines = { { text = self.text.description, font = small_pixul_font } },
	})
	self.value_text = Text2({
		-- group = self.group,
		layer = self.layer,
		x = self.x,
		y = self.y + self.text_offset,
		lines = { { text = tostring(self.value), font = small_pixul_font } },
	})
end

function Circle_Slider:update(dt)
	self:update_game_object(dt)

	if not self.expanded then
		self.hovered_index = nil
		return
	end

	self.description_text.x = self.x
	self.description_text.y = self.y - self.text_offset
	self.value_text.x = self.x
	self.value_text.y = self.y + self.text_offset
	self.description_text:update(dt)
	self.value_text:update(dt)

	local mx, my = main.current.main:get_mouse_position()
	local dx = mx - self.x
	local dy = my - self.y
	local dist = math.sqrt(dx * dx + dy * dy)

	self.hovered_index = nil

	self.mouse_in_deadzone = dist < self.visible_size * self.inner_deadzone
	if self.mouse_in_deadzone then
		if input.select.released or input.modify.released then
			self:expand(false)
		end
		return
	end

	self.mouse_angle = math.atan2(dy, dx)

	local tau = math.pi * 2
	local angle = (self.mouse_angle + self.rotation + tau) % tau

	local slice_angle = tau / self.num_slices
	local index = math.floor(angle / slice_angle) + 1
	index = math.max(1, math.min(self.num_slices, index))

	self.hovered_index = index
	self.value = self.min_value + index - 1

	self.value_text:set_text({
		{ text = tostring(self.value), font = small_pixul_font },
	})

	if input.modify.released then
		if self.action then
			self.action(self.value)
		end
		self:expand(false)
	end
end

function Circle_Slider:expand(grow)
	local size = grow and self.size or 0
	self.expanded = grow
	self.shape.rs = size
	trigger:tween(0.1, self, { visible_size = size }, math.expo_out, function()
		self.visible_size = size
	end)
end

function Circle_Slider:draw()
	if self.visible_size <= 0 or (not self.expanded and self.visible_size < 0.1) then
		return
	end

	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)

	graphics.circle(self.x, self.y, self.visible_size, purple[0])

	local slice_count = self.num_slices
	local r = self.visible_size
	local selected_slice_scale = 1.1

	local tau = math.pi * 2
	local slice_angle = tau / slice_count

	for i = 1, slice_count do
		local start_angle = (i - 1) * slice_angle - self.rotation
		local end_angle = i * slice_angle - self.rotation

		local is_hovered = (i == self.hovered_index)
		local radius = is_hovered and r * selected_slice_scale or r

		local fill = purple[0]:clone():darken((self.num_slices - i) / self.num_slices / 2.5)
		local line = white[0]

		if is_hovered then
			fill = purple[3]
		end

		graphics.arc("pie", self.x, self.y, radius, start_angle, end_angle, fill)

		if self.expanded then
			graphics.arc("open", self.x, self.y, radius, start_angle, end_angle, line, 3)

			-- separator line
			local inner = r * self.inner_deadzone
			local x1 = self.x + math.cos(start_angle) * inner
			local y1 = self.y + math.sin(start_angle) * inner

			local x2 = self.x + math.cos(start_angle) * radius
			local y2 = self.y + math.sin(start_angle) * radius

			graphics.line(x1, y1, x2, y2, white[0], 2)
		end
	end

	if self.expanded and self.mouse_angle then
		-- print(love.timer.getTime(), self.visible_size)
		angle = (self.mouse_in_deadzone and self.hovered_index) and self.hovered_index * slice_angle or self.mouse_angle
		graphics.line(
			self.x,
			self.y,
			self.x + math.cos(angle) * r * selected_slice_scale,
			self.y + math.sin(angle) * r * selected_slice_scale,
			white[0],
			15
		)
	end

	graphics.circle(self.x, self.y, r * self.inner_deadzone, black[0])

	if self.expanded then
		self.description_text:draw()
		self.value_text:draw()
	end

	graphics.pop()
end

function Circle_Slider:on_mouse_exit()
	-- self:expand(false)
	return true
end
