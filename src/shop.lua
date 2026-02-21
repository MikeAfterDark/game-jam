Shop = Object:extend()
Shop:implement(GameObject)
function Shop:init(args)
	self:init_game_object(args)

	self.slots = {}
	for i, position in pairs(self.positions) do
		table.insert(
			self.slots,
			Slot({
				group = self.group,
				x = position.x,
				y = position.y,
				size = self.shop_slot_size,
				locked = i > self.open_slots,
			})
		)
	end
end

function Shop:update(dt)
	self:update_game_object(dt)
end

function Shop:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	graphics.pop()
end

function Shop:clear_slot(building)
	for i, slot in ipairs(self.slots) do
		slot:clear(building)
	end
end

function Shop:reroll()
	for i, slot in ipairs(self.slots) do
		slot:new_building()
	end
end

--
--
--

Slot = Object:extend()
Slot:implement(GameObject)
function Slot:init(args)
	self:init_game_object(args)
	self.shape = Circle(self.x, self.y, self.size - 3)
end

function Slot:update(dt)
	self:update_game_object(dt)
end

function Slot:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	local color = Color(1, 0.5, 1, 1)
	local lock_color = white[0]
	local scale = self.size * 0.04

	-- self.shape:draw(color)
	shop_sprites.shop_slot[1]:draw(self.x, self.y, 0, scale, scale, 0, 0, color)
	if self.locked then
		shop_sprites.lock[1]:draw(self.x, self.y, 0, scale, sclae, 0, 0, lock_color)
	end
	graphics.pop()
end

function Slot:clear(building)
	if building == self.building then
		self.building = nil
	end
end

function Slot:new_building()
	if self.locked or self.building ~= nil then
		return
	end

	self.building = Building({
		group = self.group,
		x = self.x,
		y = self.y,
		size = self.size,
	})
end
