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
				shop = self,
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
		slot:clear_building(building)
	end
end

function Shop:reroll()
	local delay = 0
	local speed = 0.05
	for i, slot in ipairs(self.slots) do
		delay = slot:new_building(delay, speed)
	end
end

function Shop:reset()
	for i, slot in ipairs(self.slots) do
		if slot.locked == false then
			trigger:after(i * 0.05, function()
				local cleared = slot:clear()

				if cleared then
					slot.spring:pull(0.25, 400, 32)

					local pitch = 0.6 - i * 0.08 + random:float(0, 0.2)
					sfx.shop_reroll:play({ pitch = pitch, volume = 0.5 })
				end
			end)
		else
			slot.unlock_menu:expand(false)
		end
	end
end

--
--
--

Slot = Object:extend()
Slot:implement(GameObject)
function Slot:init(args)
	self:init_game_object(args)
	self.shape = Circle(self.x, self.y, self.size - 1)
	self.interact_with_mouse = true
	self.selected = false

	self.unlock_menu = Circle_Menu({
		group = main.current.ui,
		layer = self.laye,
		x = self.x,
		y = self.y,
		size = self.size * 5,
		rotation = 5 * math.pi / 4,
		no_selection = {
			text = "[red]cancel unlock",
			-- sprite = big_red_x_sprite,
		},
		options = {
			{
				color = yellow[-5],
				text = { requirement = "[yellow]3g", result = "lvl 1 unlock" },
				action = function()
					self:unlock(1)
				end,
				space = 0.75,
			},
			{
				color = red[-5],
				text = { requirement = "[red]10g", result = "lvl 2" },
				action = function()
					self:unlock(2)
				end,
				space = 0.1,
			},
			{
				color = green[-5],
				text = { requirement = "[green]25g", result = "level 3 unlock" },
				action = function()
					self:unlock(3)
				end,
			},
		},
	})
end

function Slot:update(dt)
	self:update_game_object(dt)

	if self.locked and self.selected and not game_mouse.holding and (input.select.pressed or input.modify.pressed) then
		self.unlock_menu:expand(true)
	end
end

function Slot:unlock(num)
	print("unlocked shop slot with option: " .. num)
	self.unlock_menu:expand(false)
	self.shop.open_slots = self.shop.open_slots + 1 -- TODO: save run?
	sfx.extra:play({ pitch = 1.4, volume = 0.5 })
	trigger:after(0.5, function()
		self.locked = false -- lock breaking animation?
		self:new_building(0, 0.05)
	end)
end

function Slot:draw()
	local color = Color(1, 0.5, 1, 1)
	local lock_color = white[0]
	local scale = self.size * 0.04

	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	shop_sprites.shop_slot[1]:draw(self.x, self.y, 0, scale, scale, 0, 0, color)
	if self.locked then
		shop_sprites.lock[1]:draw(self.x, self.y, 0, scale, sclae, 0, 0, lock_color)
	end

	graphics.pop()
	-- self.shape:draw(color, 2)
end

function Slot:clear_building(building)
	if building == self.building then
		-- self.building:demolish()
		self.building = nil
	end
end

function Slot:clear()
	if self.building then
		self.building:demolish()
		self.building = nil
		return true
	end
	return false
end

function Slot:new_building(delay, speed)
	if
		self.locked --[[ or self.building ~= nil ]]
	then
		return delay
	end

	trigger:after(delay, function()
		if self.building then
			if game_mouse.holding == self.building then
				game_mouse.holding = nil
			end
			self.building:demolish()
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
			shop = self,
		})
	end)
	return delay + speed
end

function Slot:on_mouse_enter()
	if not on_current_ui_layer(self) then
		return false
	end
	self.selected = true

	if not main.current.players_turn or self.unlock_menu.expanded then
		return true
	end

	-- [SFX]
	if self.building or self.locked then
		sfx.tile_mouse_enter:play({ pitch = random:float(0.95, 1.05), volume = 0.1 })
	end
	-- self.spring:pull(0.15, 400, 32)
	self.spring:pull(0.25, 400, 32)
	return true
end

function Slot:on_mouse_exit()
	-- if self.unlock_menu.expanded then
	-- 	return
	-- end

	self.selected = false
	return true
end
