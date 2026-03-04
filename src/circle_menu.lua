Circle_Menu = Object:extend()
Circle_Menu:implement(GameObject)
function Circle_Menu:init(args)
	self:init_game_object(args)
	self.visible_size = 0
	self.shape = Circle(self.x, self.y, self.visible_size)
	self.interact_with_mouse = true
	self.expanded = false

	self.options = args.options or {}
	self.rotation = args.rotation or 0

	self.hovered_index = nil
	self.inner_deadzone = 0.5 -- center safe zone (percent of radius)

	self.slices = {}
	local full_circle = math.pi * 2

	local defined_space = 0
	local undefined_count = 0

	for _, option in ipairs(self.options) do
		if option.space then
			defined_space = defined_space + option.space
		else
			undefined_count = undefined_count + 1
		end
	end

	defined_space = math.min(defined_space, 1)

	local remaining_space = 1 - defined_space
	local default_space = (undefined_count > 0) and (remaining_space / undefined_count) or 0

	local cumulative_angle = 0

	for i, option in ipairs(self.options) do
		local percent = option.space or default_space
		local angle_size = percent * full_circle

		local start_angle = cumulative_angle
		local end_angle = start_angle + angle_size

		option.start_angle = start_angle
		option.end_angle = end_angle

		cumulative_angle = cumulative_angle + angle_size
	end
end

function Circle_Menu:update(dt)
	self:update_game_object(dt)

	if not self.expanded then
		self.hovered_index = nil
		return
	end

	local mx, my = main.current.main:get_mouse_position()
	local dx = mx - self.x
	local dy = my - self.y
	local dist = math.sqrt(dx * dx + dy * dy)

	self.hovered_index = nil
	if --[[ dist > self.visible_size or ]]
		dist < self.visible_size * self.inner_deadzone
	then
		if input.select.released then
			self:expand(false)
		end
		return
	end

	self.mouse_angle = math.atan2(dy, dx)
	local angle = (math.pi * 2 + self.mouse_angle + self.rotation) % (math.pi * 2)

	for i, option in ipairs(self.options) do
		if angle >= option.start_angle and angle < option.end_angle then
			self.hovered_index = i
			break
		end
	end

	if self.hovered_index and input.select.released then
		local option = self.options[self.hovered_index]
		if option and option.action then
			option.action()
		end
		self:expand(false)
	end
end

function Circle_Menu:expand(grow)
	local size = grow and self.size or 0
	self.expanded = grow
	self.shape.rs = size
	trigger:tween(0.4, self, { visible_size = size }, math.expo_out)
end

function Circle_Menu:draw()
	if self.visible_size <= 0 then
		return
	end
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)

	-- self.shape:draw(white[0], 2)
	graphics.circle(self.x, self.y, self.visible_size, purple[0])

	local slice_count = #self.options
	if slice_count == 0 then
		return
	end

	local r = self.visible_size
	local selected_slice_scale = 1.1

	for i, option in ipairs(self.options) do
		local start_angle = option.start_angle - self.rotation
		local end_angle = option.end_angle - self.rotation

		local is_hovered = (i == self.hovered_index)

		local radius = is_hovered and r * selected_slice_scale or r

		local fill_color = is_hovered and option.color or option.color:clone():darken(0.2)
		local line_color = white[0]

		graphics.arc("pie", self.x, self.y, radius, start_angle, end_angle, fill_color)
		if self.expanded then
			graphics.arc("open", self.x, self.y, radius, start_angle, end_angle, line_color, 2)
		end
	end

	if self.hovered_index then
		graphics.line(
			self.x,
			self.y, --
			self.x + math.cos(self.mouse_angle) * r * selected_slice_scale,
			self.y + math.sin(self.mouse_angle) * r * selected_slice_scale,
			white[0],
			5
		)
	end

	graphics.circle(self.x, self.y, r * self.inner_deadzone, black[0])
	graphics.pop()
end

function Circle_Menu:on_mouse_exit()
	-- self:expand(false)
	return true
end
