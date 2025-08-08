Station = Object:extend()
Station:implement(GameObject)
Station:implement(Physics)
function Station:init(args)
	self:init_game_object(args)
	self:set_as_circle(self.size, "static", "station")
	self.interact_with_mouse = true
	self.color = self.color or fg[0]

	self.connected = false
	self.connections = {}

	self.station_name = Text({
		{
			text = "[bg]" .. self.name,
			font = mystery_font,
			alignment = "center",
		},
	}, global_text_tags)
	self.required_connections_text = Text({
		{
			text = "[bg]B [greenm5]A ",
			font = mystery_font,
			alignment = "center",
		},
	}, global_text_tags)

	buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.5 }) -- TODO: change audio

	self.t:every(0.51, function()
		if self.highlighted then
			self.spring:pull(0.2, 200, 10)
		end
	end)
	self.spring:pull(0.6, 100, 10)
end

function Station:update(dt)
	self:update_game_object(dt)

	-- clean up invalid connections
	local valid_connections = {}
	for _, connection in ipairs(self.connections) do
		if connection.rail and connection.rail.connected and connection.destination then
			table.insert(valid_connections, connection)
		end
	end
	self.connections = valid_connections

	local function build_reachable(station, visited)
		if visited[station] then
			return
		end
		visited[station] = true
		for _, conn in ipairs(station.connections or {}) do
			if conn.destination then
				build_reachable(conn.destination, visited)
			end
		end
	end

	local reachable = {}
	build_reachable(self, reachable)

	self.missing_connections = {}
	self.num_required_connections = 0
	local required_text = "[bg]"

	for _, required in ipairs(self.require_connections) do
		required_text = required_text .. required.name .. ""
		self.num_required_connections = self.num_required_connections + 1
		if not reachable[required] then
			table.insert(self.missing_connections, required)
		end
	end

	required_text = required_text .. "[greenm5]"
	for _, required_direct in ipairs(self.require_direct_connections) do
		required_text = required_text .. required_direct.name .. ""
		self.num_required_connections = self.num_required_connections + 1
		local found = false
		for _, conn in ipairs(self.connections) do
			if conn.destination == required_direct then
				found = true
				break
			end
		end
		if not found then
			table.insert(self.missing_connections, required_direct)
		end
	end

	self.required_connections_text:set_text({
		{
			text = required_text,
			font = mystery_font,
			alignment = "center",
		},
	})

	if #self.missing_connections == 0 then
		self.was_connected = true
	elseif self.was_connected then
		self.spring:pull(0.2, 200, 10)
		self.was_connected = false
	end
end

function Station:connect(rail, destination)
	for _, conn in ipairs(self.connections) do
		if conn.destination == destination then
			conn.rail:destroy()
			conn.rail = rail
			return true
			-- return false -- reject new rail if one already exists
		end
	end

	table.insert(self.connections, { rail = rail, destination = destination })
	return true
end

function Station:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	graphics.circle(self.x, self.y, self.size + 5, black[0])
	if self.highlighted then
		graphics.circle(self.x, self.y, self.size + 4, self.highlight_color)
	elseif #self.missing_connections > 0 then
		graphics.circle(self.x, self.y, self.size + 4, red[0])
	else
		graphics.circle(self.x, self.y, self.size + 4, green[0])
	end
	graphics.circle(self.x, self.y, self.size + 1, black[0])

	if self.hovered and self.num_required_connections > 0 then
		-- local missing_connections = 3
		local width = self.num_required_connections * 18
		local height = 28
		local y_offset = self.y + self.size * 2 + 6

		graphics.rectangle(self.x, y_offset, width, height, 4, 4, fg[0])
		self.required_connections_text:draw(self.x + 1, y_offset + 0, self.r, self.sx, self.sy)
	end
	self.shape:draw(self.color)
	self.station_name:draw(self.x + 1, self.y + 0, self.r, self.sx * self.spring.x, self.sy * self.spring.x)
	graphics.pop()
end

function Station:on_mouse_enter()
	if main.current.quitting or main.current.paused or main.current.died then
		return
	end
	-- buttonHover:play({ pitch = random:float(0.9, 1.2), volume = 0.5 })
	buttonPop:play({ pitch = random:float(0.95, 1.05), volume = 0.5 }) -- TODO: change audio
	self.hovered = true
	main.current.hovered_station = self
	self.station_name:set_text({
		{
			text = "[fgm10]" .. self.name,
			font = mystery_font,
			alignment = "center",
		},
	})

	-- highlight the other stations that this needs to be connected to, set highlighted_color
	for _, connection in ipairs(self.connections) do
		connection.rail.highlighted = true
		connection.destination.highlighted = true
	end

	self.spring:pull(0.2, 200, 10)
	if self.mouse_enter then
		self:mouse_enter()
	end
end

function Station:on_mouse_exit()
	if main.current.quitting or main.current.paused or main.current.died then
		return
	end
	self.station_name:set_text({
		{
			text = "[bg]" .. self.name,
			font = mystery_font,
			alignment = "center",
		},
	})
	self.hovered = false
	main.current.hovered_station = nil

	for _, connection in ipairs(self.connections) do
		connection.rail.highlighted = false
		connection.destination.highlighted = false
	end

	if self.mouse_exit then
		self:mouse_exit()
	end
end
