Slider = Object:extend()
Slider:implement(GameObject)
Slider:implement(Physics)
function Slider:init(args)
	self:init_game_object(args)

	-- args:
	-- x
	-- y
	-- length
	-- thickness
	-- rotation
	-- max_sections
	-- value (is a value from 0 to 1 representing % full)
	-- layer
	-- TODO: ?? visual_style (string/enum) ??

	self.shape = Rectangle(self.x, self.y, args.length, args.thickness, args.rotation)

	self.max_sections = args.max_sections
	self.value = args.value
	self.spacing = args.spacing

	self.interact_with_mouse = true
	self.selected = false
	self.layer = args.layer

	-- define logic
	local angle = self.shape.r + math.pi
	local dist = self.length / 2

	self.facing_direction = Vector(math.cos(angle), math.sin(angle)):normalize():scale(-1)
	self.zero_x = self.x + math.cos(angle) * dist
	self.zero_y = self.y + math.sin(angle) * dist

	self.section_value_diff = 1 / self.max_sections
	self._last_section = math.floor(self.value * self.max_sections)
end

function Slider:calcualte_mouse_value()
	local mouse_x, mouse_y = self.group:get_mouse_position()
	local mouse_vector = Vector(mouse_x - self.zero_x, mouse_y - self.zero_y)
	local proj = mouse_vector:project_to(self.facing_direction)
	local projected_value = proj:dot(self.facing_direction)

	local t = projected_value / self.length
	return math.clamp(t, 0, 1)
end

function Slider:update(dt)
	self:update_game_object(dt)
	if not on_current_ui_layer(self) then
		return
	end

	if self.hovered and input.m1.pressed then
		self.dragging = true
	elseif input.m1.released then
		self.dragging = false
	end

	if self.dragging then
		local prev_section = self._last_section
		self.value = self:calcualte_mouse_value() + self.section_value_diff / 2

		local current_section = math.floor(self.value * self.max_sections)
		if current_section == 0 then
			self.value = 0
		end

		if current_section ~= prev_section then
			self._last_section = current_section

			local pitch = current_section / self.max_sections + 0.5
			buttonPop:play({ pitch = pitch, volume = 0.5 })

			if self.action then
				self:action(self.value)
			end
		end
	end
end

function Slider:draw()
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

	graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, _G[self.bg_color][0])

	local hovered_segment = 0
	if self.hovered then
		local mouse_value = self:calcualte_mouse_value()
		hovered_segment = math.floor(mouse_value * self.max_sections) + 1

		-- if self.debug_value_display == nil then
		-- 	self.debug_value_display = Text2({
		-- 		group = main.current.main_menu_ui,
		-- 		x = 100,
		-- 		y = 20,
		-- 		force_update = true,
		-- 		lines = {
		-- 			{
		-- 				text = tostring(mouse_value) .. ", " .. tostring(hovered_segment),
		-- 				font = pixul_font,
		-- 				alignment = "center",
		-- 			},
		-- 		},
		-- 	})
		-- end
	end

	local num_sections = math.floor(self.max_sections * self.value)

	if num_sections > 0 then
		local section_length = (self.length - (self.spacing * (self.max_sections + 1))) / self.max_sections
		local step = section_length + self.spacing
		local offset = step / 2 + 1

		local normal = Vector(-self.facing_direction.y, self.facing_direction.x)
		local thickness = self.shape.h > self.shape.w and self.shape.w or self.shape.h
		thickness = thickness - 2

		for i = 1, self.max_sections do
			if i > num_sections then
				break
			end
			local x = self.zero_x + self.facing_direction.x * offset
			local y = self.zero_y + self.facing_direction.y * offset
			local size = i == hovered_segment and 2 or 0 -- TODO: MAGIC

			local w = math.abs(self.facing_direction.x) * section_length + math.abs(normal.x) * thickness
			local h = math.abs(self.facing_direction.y) * section_length + math.abs(normal.y) * thickness

			graphics.rectangle(x, y, w + size, h + size, 0, 0, _G[self.fg_color][0])
			offset = offset + step
		end
	end
	graphics.pop()
end

function Slider:on_mouse_enter()
	if not on_current_ui_layer(self) then
		return
	end
	buttonHover:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.5 })
	self.hovered = true
	self.spring:pull(0.2, 200, 10)
	if self.mouse_enter then
		self:mouse_enter()
	end
end

function Slider:on_mouse_exit()
	if not on_current_ui_layer(self) then
		return
	end

	if self.debug_value_display then
		self.debug_value_display:clear()
		self.debug_value_display = nil
	end

	self.hovered = false
	if self.mouse_exit then
		self:mouse_exit()
	end
end
