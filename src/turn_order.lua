Turn_Order = Object:extend()
Turn_Order:implement(GameObject)
function Turn_Order:init(args)
	self:init_game_object(args)

	self.duplicate_speed = 8
	self.turns = {} -- queue

	self.turn_text = Text2({
		group = self.group,
		x = self.x,
		y = self.y,
		top_aligned = true,
		lines = { { text = "", font = pixul_font } },
	})
end

function Turn_Order:update(dt)
	self:update_game_object(dt)

	local units = {
		{ text = "Turn:", font = pixul_font },
	}
	for i, unit in ipairs(self.turns) do
		table.insert(units, {
			text = (unit.type and unit.type.name or "???") .. ": " .. (unit.speed or "###") .. "/" .. self.duplicate_speed,
			font = pixul_font,
		})
	end
	self.turn_text:set_text(units)
end

function Turn_Order:num_turns()
	return #self.turns
end

function Turn_Order:insert(units)
	-- insert units based on 'speed' order, higher is inserted into the front first
	table.sort(units, function(a, b)
		if not a.speed then
			print("[A] doesn't have speed, type: " .. a.type.name)
		end
		if not b.speed then
			print("[B] doesn't have speed, type: " .. b.type.name)
		end
		return a.speed > b.speed
	end)

	local duplicate_speed_threshold = 8
	local turns = {}
	for i, unit in ipairs(units) do
		if unit.speed then
			for j = 1, math.ceil(unit.speed / duplicate_speed_threshold), 1 do
				table.insert(turns, unit)
			end
		else
			print("unit has no speed:", unit.type.name)
		end
	end

	for _, v in ipairs(turns) do
		self.turns[#self.turns + 1] = v
	end
end

function Turn_Order:pop()
	if #self.turns == 0 then
		return nil
	end

	local unit
	unit, self.turns = table.shift(self.turns)

	return unit
end

function Turn_Order:peek()
	if #self.turns == 0 then
		return nil
	end
	return self.turns[1]
	--
	-- local unit
	-- unit, self.turns = table.shift(self.turns)
	--
	-- return unit
end

function Turn_Order:draw()
	graphics.push(self.x, self.y, self.r)
	graphics.pop()
end
