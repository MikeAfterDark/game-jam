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

	self.interact_with_mouse = true

	self.balls = {}
end

function Shop:update(dt)
	self:update_game_object(dt)

	if self.selected and input.select.down then
		local mouse_x, mouse_y = self.group:get_mouse_position()
		local x = math.min(self.right_limit, math.max(self.left_limit, self.x + (mouse_x - (self.mouse_x or mouse_x))))
		self.x = x
		self.mouse_x = mouse_x
		local targetX = self.x
		local currentX = self.body:getX()

		local vx = (targetX - currentX) / dt

		-- self.body:setLinearVelocity(vx, 0)
		self:set_velocity(vx, 0)
		-- self:set_position(self.x, self.y)
	end

	if not self.selected or input.select.released or not input.select.down then
		self.mouse_x = nil
		self:set_velocity(0, 0)
	end

	if self.x == self.left_limit and not self.rolled then
		self.rolled = true
		self:roll()
		print("rerolled")
	end

	if self.x ~= self.left_limit and self.rolled then
		self.rolled = false
		print("shopping")
	end
end

function Shop:roll()
	for i, ball in ipairs(self.balls) do
		ball.dead = true
	end
	self.balls = {}

	local sum_of_odds = table.reduce_dict(Rarity, function(memo, v)
		return memo + v.shop_odds
	end, 0)

	local odds = random:float(0, sum_of_odds)
	print(sum_of_odds, odds)
	local sum = 0
	for i = 1, #Rarity_Ranks do
		sum = sum + Rarity_Ranks[i].shop_odds
		print(sum, Rarity_Ranks[i].name)

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

function Shop:on_mouse_enter()
	self.selected = true
end

function Shop:on_mouse_exit()
	self.selected = false
end

function Shop:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)

	local color = self.selected and green[0] or blue[0]
	graphics.rectangle(self.x, self.y, self.w + 10, self.h + 10, 5, 5, color)
	graphics.rectangle(self.x, self.y, self.w + 5, self.h + 5, 5, 5, black[0])
	graphics.pop()
end
