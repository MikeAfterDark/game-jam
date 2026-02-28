CellularAutomata = Object:extend()

function CellularAutomata:init(args)
	self.board = args.board
	self.rules = {}
	self.active_events = {}
end

function CellularAutomata:add_rule(rule)
	table.insert(self.rules, rule)
end

function CellularAutomata:add_rules(rules)
	for i, rule in ipairs(rules) do
		table.insert(self.rules, rule)
	end
end

function CellularAutomata:add_event(event)
	table.insert(self.active_events, event)
end

function CellularAutomata:add_events(events)
	for i, event in ipairs(events) do
		table.insert(self.active_events, event)
	end
end

function CellularAutomata:clear_events()
	self.active_events = {}
end

function CellularAutomata:step(count)
	local count = count or 0
	print("--step: " .. count .. "--")

	local changes = {}

	for _, tile in ipairs(self.board.tiles) do
		local new_type = self:evaluate_tile(tile)
		if new_type and new_type ~= tile.type then
			table.insert(changes, { tile = tile, type = new_type })
		end
	end

	for _, change in ipairs(changes) do
		change.tile:set_type({ target = change.type })
	end

	if #changes > 0 then
		self:step(count + 1)
	end
end

function CellularAutomata:evaluate_tile(tile)
	for i = 1, #self.rules do
		local rule = self.rules[i]
		if rule.condition(self.board, tile) then
			if not rule.probability or random:float(0, 1) <= rule.probability then
				return rule.result
			end
		end
	end

	for i = 1, #self.active_events do
		local event = self.active_events[i]
		if event.condition(self.board, tile) then
			return event.result
		end
	end
end

function CellularAutomata:has_trait(tile, trait)
	for i = 1, #tile.type.traits do
		if tile.type.traits[i] == trait then
			return true
		end
	end
end

function CellularAutomata:neighbor_has_trait(tile, trait)
	local neighbors = self.board:get_adjacent_tiles(tile)
	for i = 1, #neighbors do
		if self:has_trait(neighbors[i], trait) then
			return true
		end
	end
end

function CellularAutomata:count_neighbors_with_trait(tile, trait)
	local count = 0
	local neighbors = self.board:get_adjacent_tiles(tile)
	for i = 1, #neighbors do
		if self:has_trait(neighbors[i], trait) then
			count = count + 1
		end
	end
	return count
end
