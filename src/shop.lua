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
		offset_x = w + gw * 0.0125,
		offset_y = 0,
		w = gw * 0.025,
		h = gh * 0.1,
	})

	self.balls = {}
end

function Shop:update(dt)
	self:update_game_object(dt)

	if self.x == self.left_limit and not self.rolled then
		self.rolled = true
		self:roll()
	end

	if self.x ~= self.left_limit and self.rolled then
		self.rolled = false
	end
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

	self.interact_with_mouse = true
end

function Handle:update(dt)
	self:update_game_object(dt)

	self.x = self.parent.x + self.offset_x
	self.y = self.parent.y + self.offset_y
	self.shape:move_to(self.x, self.y)

	if self.selected and input.select.down then
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
	else
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

function Handle:draw()
	graphics.push(self.x, self.y, self.r, self.parent.spring.x, self.parent.spring.x)

	local color = self.selected and green[0] or blue[0]

	graphics.rectangle(self.x, self.y, self.w + 10, self.h + 10, 5, 5, color)
	graphics.rectangle(self.x, self.y, self.w + 5, self.h + 5, 5, 5, bg[0])

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
