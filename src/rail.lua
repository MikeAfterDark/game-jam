local POINT_HIT_RADIUS = 10

Rail = Object:extend()
Rail:implement(GameObject)
Rail:implement(Physics)

function Rail:init(args)
	self:init_game_object(args)

	self.x = self.source_station.x
	self.y = self.source_station.y
	self.points = { self.x, self.y }

	self.hovered = false
	self.colliding_with_mouse = false
	self.connected = false

	self.connects_text = Text({
		{
			text = "[red]HALLO",
			font = pixul_font,
			alignment = "center",
		},
	}, global_text_tags)

	self.moving_circles = {} -- list of {segment_index, t} where t in [0,1] along the segment
	self.spawn_timer = 0
end

function Rail:destination(station)
	self.destination_station = station
	if self.source_station:connect(self, station) then
		self.connected = true
		self.color = self.connected_color
		self.connects_text:set_text({
			{
				text = "[blue]" .. self.source_station.name .. " to " .. self.destination_station.name,
				font = pixul_font,
				alignment = "center",
			},
		})
	else
		self:destroy()
	end
end

local LOCAL_SPEED = 100
local SPAWN_INTERVAL = 0.5

function Rail:update(dt)
	self:update_game_object(dt)

	if main.current.current_rail ~= self and not main.current.quitting and not main.current.paused and not main.current.died then
		local mx, my = self.group:get_mouse_position()
		local over = self:is_mouse_over(mx, my, POINT_HIT_RADIUS)

		if over and not self.colliding_with_mouse then
			self.colliding_with_mouse = true
			self:on_mouse_enter()
		elseif not over and self.colliding_with_mouse then
			self.colliding_with_mouse = false
			self:on_mouse_exit()
		end

		if input.cancel_rail.pressed and self.hovered then
			self:destroy()
		end
	end

	self.spawn_timer = (self.spawn_timer or 0) + dt
	if self.spawn_timer >= SPAWN_INTERVAL then
		self.spawn_timer = self.spawn_timer - SPAWN_INTERVAL
		table.insert(self.moving_circles, { segment = 1, t = 0 })
	end

	local points = self.points
	local num_segments = (#points / 2) - 1
	local speed = LOCAL_SPEED

	for i = #self.moving_circles, 1, -1 do
		local c = self.moving_circles[i]
		local seg = c.segment
		local t = c.t

		if seg > num_segments then
			table.remove(self.moving_circles, i)
		else
			local x1, y1 = points[seg * 2 - 1], points[seg * 2]
			local x2, y2 = points[seg * 2 + 1], points[seg * 2 + 2]

			local dx, dy = x2 - x1, y2 - y1
			local seg_length = math.sqrt(dx * dx + dy * dy)
			local dist = seg_length * (1 - t)

			local advance = speed * dt
			if advance >= dist then
				advance = advance - dist
				c.segment = seg + 1
				c.t = 0
				while advance > 0 and c.segment <= num_segments do
					local s = c.segment
					local x1, y1 = points[s * 2 - 1], points[s * 2]
					local x2, y2 = points[s * 2 + 1], points[s * 2 + 2]
					local dx, dy = x2 - x1, y2 - y1
					local length = math.sqrt(dx * dx + dy * dy)
					if advance < length then
						c.t = advance / length
						advance = 0
					else
						advance = advance - length
						c.segment = c.segment + 1
						c.t = 0
					end
				end
				if c.segment > num_segments then
					table.remove(self.moving_circles, i)
				end
			else
				c.t = t + advance / seg_length
			end
		end
	end
end

function Rail:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)

	local count = #self.points
	local show_temp = self.temp_x and self.temp_y
	if count >= 4 or (count >= 2 and show_temp) then
		local pts = {}
		for i = 1, count do
			pts[i] = self.points[i]
		end
		if show_temp then
			table.insert(pts, self.temp_x)
			table.insert(pts, self.temp_y)
		end

		if self.highlighted then
			graphics.polyline(self.highlight_color, POINT_HIT_RADIUS, unpack(pts))
		else
			graphics.polyline(self.color, POINT_HIT_RADIUS, unpack(pts))
		end
	end

	-- circles
	for _, c in ipairs(self.moving_circles) do
		local seg = c.segment
		local t = c.t
		local points = self.points

		if seg <= (#points / 2 - 1) then
			local x1, y1 = points[seg * 2 - 1], points[seg * 2]
			local x2, y2 = points[seg * 2 + 1], points[seg * 2 + 2]

			local cx = x1 + (x2 - x1) * t
			local cy = y1 + (y2 - y1) * t

			graphics.circle(cx, cy, POINT_HIT_RADIUS / 2, green[-10])
		end
	end

	graphics.pop()
end

function Rail:destroy()
	self.points = {}
	self.hovered = false
	self.colliding_with_mouse = false
	self.source_station = nil

	if self.destination_station and self.destination_station.highlighted then
		self.destination_station.highlighted = false
	end
	self.destination_station = nil
	self.connected = false

	-- if self.source_station and self.destination_station then
	-- 	for i = #self.source_station.connections, 1, -1 do
	-- 		local conn = self.source_station.connections[i]
	-- 		if conn.rail == self then
	-- 			table.remove(self.source_station.connections, i)
	-- 		end
	-- 	end
	-- end
end

function Rail:on_mouse_enter()
	self.hovered = true
	self.color = red[0]
	if self.mouse_enter then
		self:mouse_enter()
	end
end

function Rail:on_mouse_exit()
	self.hovered = false
	self.color = self.connected_color
	if self.mouse_exit then
		self:mouse_exit()
	end
end

function Rail:add_point(x, y)
	table.insert(self.points, x)
	table.insert(self.points, y)
end

function Rail:add_temp_point_permanently()
	table.insert(self.points, self.temp_x)
	table.insert(self.points, self.temp_y)
end

function Rail:temp_point(x, y)
	self.temp_x = x
	self.temp_y = y
end

function Rail:is_mouse_over(mx, my, threshold)
	threshold = threshold or 8
	for i = 1, #self.points - 2, 2 do
		local x1, y1 = self.points[i], self.points[i + 1]
		local x2, y2 = self.points[i + 2], self.points[i + 3]

		if self:point_segment_distance(mx, my, x1, y1, x2, y2) <= threshold then
			return true
		end
	end
	return false
end

function Rail:point_segment_distance(px, py, x1, y1, x2, y2)
	local dx, dy = x2 - x1, y2 - y1
	if dx == 0 and dy == 0 then
		return math.sqrt((px - x1) ^ 2 + (py - y1) ^ 2)
	end
	local t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
	t = math.max(0, math.min(1, t))
	local cx = x1 + t * dx
	local cy = y1 + t * dy
	return math.sqrt((px - cx) ^ 2 + (py - cy) ^ 2)
end
