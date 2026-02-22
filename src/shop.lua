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
				layer = self.layer,
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
	local delay = 0
	local speed = 0.05
	for i, slot in ipairs(self.slots) do
		delay = slot:new_building(delay, speed)
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

function Slot:new_building(delay, speed)
	if
		self.locked --[[ or self.building ~= nil ]]
	then
		return delay
	end

	trigger:after(delay, function()
		if self.building then
			self.building.dead = true
			self.building = nil
		end

		self.spring:pull(0.25, 400, 32)

		local pitch = 0.6 + delay * 1.7 + random:float(0, 0.2)
		sfx.shop_reroll:play({ pitch = pitch, volume = 0.5 })
		self.building = Building({
			group = self.group,
			layer = self.layer,
			x = self.x,
			y = self.y,
			size = self.size,
		})
	end)
	return delay + speed
end

function Slot:on_mouse_enter()
	if not on_current_ui_layer(self) then
		return false
	end
	-- [SFX]
	sfx.tile_mouse_enter:play({ pitch = random:float(0.95, 1.05), volume = 0.1 })
	self.selected = true
	-- self.spring:pull(0.15, 400, 32)
	return true
end

function Slot:on_mouse_exit()
	self.selected = false
	return true
end
