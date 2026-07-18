Shop = Object:extend()
Shop:implement(GameObject)
Shop:implement(Physics)
function Shop:init(args)
	self:init_game_object(args)

	local w = self.w / 2
	local h = self.h / 2
	self:set_as_chain(true, {
		-w,
		-h,

		w,
		-h,

		w,
		h,

		-w,
		h,
	}, "kinematic", "drawer")
	self:set_position(self.x, self.y)
	self:set_restitution(0.9)
	self:set_friction(0)

	self.handle = Handle({
		group = self.group,
		parent = self,
		offset_x = w + gw * 0.038,
		offset_y = 0,
		w = gw * 0.06,
		h = gh * 0.07,
	})

	self.balls = {}
end

function Shop:update(dt)
	self:update_game_object(dt)

	if self.x <= self.left_limit and not self.rolled then
		self.rolled = true
		self:roll()
		self.cost_to_open = (self.cost_to_open or 0) + 1
	end

	if self.x > self.left_limit and self.rolled then
		self.rolled = false
		self.player.money = self.player.money - self.cost_to_open
	end

	local x1, y1, x2, y2 = self.shape:get_bounds()
	local cx, cy = self.shape:get_centroid()
	table.foreach(self.balls, function(ball)
		if ball.x < x1 or ball.x > x2 or ball.y < y1 or ball.y > y2 then
			ball:set_velocity(0, 0) -- stop it from escaping again
			ball:set_position(cx, cy)
		end
	end)
end

function Shop:can_open_shop()
	return self.cost_to_open < self.player.money
end

-- TODO: this
function Shop:close()
	print(self.x)
	self.x = self.left_limit
	print(self.x)
end

function Shop:remove(ball)
	table.delete(self.balls, ball)
end

function Shop:roll()
	for i, ball in ipairs(self.balls) do
		ball.dead = true
	end
	self.balls = {}

	local sum_of_odds = table.reduce_dict(Rarity, function(memo, v)
		return memo + (v.shop_odds or 0)
	end, 0)

	local odds = random:float(0, sum_of_odds)
	local sum = 0
	for i = 1, #Rarity_Ranks do
		sum = sum + (Rarity_Ranks[i].shop_odds or 0)

		if odds < sum then
			self.rarity = Rarity_Ranks[i]
			break
		end
	end

	local ball_options = table.select_dict(Ball_Type, function(type)
		return type.rarity == self.rarity
	end)
	local num_balls = 5

	if #ball_options > 0 then
		for i = 1, num_balls do
			local ball = Ball({
				group = self.group,
				x = self.x,
				y = self.y,
				type = random:table(ball_options),
			})

			ball:set_restitution(0.9)
			ball:set_damping(0.1)
			ball:set_friction(0)
			ball:set_mass(1)
			ball:activate_mouse(self, Ball_Interaction_Mode.Shop_Drawer)

			local radius = gh * 0.05
			ball:resize(radius)

			table.insert(self.balls, ball)
		end
	else
		print("didn't find any balls with rarity ", self.rarity.name)
	end
end

function Shop:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)

	local color = self.selected and green[0] or blue[0]
	graphics.rectangle(self.x, self.y, self.w + 10, self.h + 10, 5, 5, color)
	graphics.rectangle(self.x, self.y, self.w + 5, self.h + 5, 5, 5, bg[0])
	graphics.pop()
end

---
---
---
---
---

Handle = Object:extend()
Handle:implement(GameObject)
function Handle:init(args)
	self:init_game_object(args)

	self.parent = args.parent
	self.w = args.w
	self.h = args.h
	self.shape = Rectangle(self.parent.x + self.offset_x, self.parent.y + self.offset_y, self.w, self.h)
	self.text = Text({
		{ text = "", font = pixul_font, alignment = "center" },
	}, global_text_tags)

	self.interact_with_mouse = true
end

function Handle:update(dt)
	self:update_game_object(dt)

	self.x = self.parent.x + self.offset_x
	self.y = self.parent.y + self.offset_y
	self.shape:move_to(self.x, self.y)

	local can_open = self.parent:can_open_shop()
	local text_color = can_open and "yellow" or "red"
	self.text:set_text({
		{
			text = "[" .. text_color .. "]$" .. self.parent.cost_to_open,
			font = pixul_font,
			alignment = "center",
		},
	})

	if self.selected and input.select.down then
		if can_open or not self.parent.rolled then
			holding_handle = true

			local mouse_x = self.group:get_mouse_position()
			if not self.mouse_x then
				self.mouse_x = mouse_x
			end

			local dx = mouse_x - self.mouse_x
			self.mouse_x = mouse_x

			self.parent.x = math.min(self.parent.right_limit, math.max(self.parent.left_limit, self.parent.x + dx))

			local targetX = self.parent.x
			local currentX = self.parent.body:getX()
			local vx = (targetX - currentX) / dt

			self.parent:set_velocity(vx, 0)
		elseif not can_open then
			self.selected = false
			holding_handle = false
			self.parent:set_velocity(0, 0)
			if input.select.pressed then
				self.spring:pull(0.2, 500, 10)
				sfx.tick:play({ pitch = random:float(0.95, 1.05), volume = 0.3 })
			end
		end
	elseif holding_handle then
		holding_handle = false
		self.mouse_x = nil
		self.parent:set_velocity(0, 0)
	end

	if not input.select.down and self.mouse_left then
		self.selected = false
	end
end

function Handle:on_mouse_enter()
	self.selected = true
	self.mouse_left = false
end

function Handle:on_mouse_exit()
	if not input.select.down then
		self.selected = false
	end
	self.mouse_left = true
end

function Handle:on_mouse_stay()
	self.selected = true
end

function Handle:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)

	local color = self.selected and green[0] or blue[0]

	graphics.rectangle(self.x, self.y, self.w + 10, self.h + 10, 5, 5, color)
	graphics.rectangle(self.x, self.y, self.w + 5, self.h + 5, 5, 5, bg[0])

	if self.parent.rolled then
		self.text:draw(self.x, self.y, self.r, 1, 1)
	end

	graphics.pop()
end

---
---
---
---

Shelf = Object:extend()
Shelf:implement(GameObject)
function Shelf:init(args)
	self:init_game_object(args)
	self.shape = Rectangle(self.x, self.y, self.w, self.h)
	self.interact_with_mouse = true -- stop mouse collisions under it
end

function Shelf:update(dt)
	self:update_game_object(dt)
end

function Shelf:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
	graphics.rectangle(self.x, self.y, self.w, self.h, 5, 5, self.color)
	graphics.pop()
end
