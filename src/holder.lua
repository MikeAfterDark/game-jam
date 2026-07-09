Holder = Object:extend()
Holder:implement(GameObject)
function Holder:init(args)
	self:init_game_object(args)

	self.slots = {}
end

function Holder:update(dt)
	self:update_game_object(dt)
end

function Holder:setup(total_slots, open_slots, balls)
	for i, slot in ipairs(self.slots) do
		if slot.ball then
			slot.ball.dead = true
			slot.ball = nil
		end
	end

	self.slots = {}
	for i = 1, total_slots do
		local ball = #balls >= i and balls[i] or nil
		if ball then
			ball.index = i
			ball.is_enemy = self.is_enemy
		end

		table.insert(self.slots, {
			index = i,
			open = i <= open_slots,
			ball = ball,
		})
	end

	self.w = #self.slots * self.slot_size
end

function Holder:has_room()
	return table.any( --
		self.slots,
		function(slot)
			return (slot.open and slot.ball == nil)
		end
	) or false
end

function Holder:insert(ball)
	local ball_radius = gh * 0.02
	ball:resize(ball_radius)
	ball.mode = Ball_Interaction_Mode.Ball_Holder

	-- local slot = nil
	-- if ball.index then
	-- 	self.slots[ball.index].ball = ball
	-- else if not ball.index
	local slot = table.select(self.slots, function(slot)
		return slot.open and slot.ball == nil
	end)[1]

	if slot then
		slot.ball = ball
	else
		ball:trigger({ Ball_Event.On_Consume })
	end
	-- end
end

function Holder:disable_ball_selection()
	for i, slot in ipairs(self.slots) do
		if slot.ball then
			slot.ball:deactivate_mouse()
		end
	end
end

function Holder:enable_ball_selection()
	for i, slot in ipairs(self.slots) do
		if slot.ball then
			slot.ball:activate_mouse(self, Ball_Interaction_Mode.Ball_Holder)
		end
	end
end

function Holder:next_ball()
	for i, slot in ipairs(self.slots) do
		local ball = slot.ball
		if ball then
			slot.ball = nil
			ball:set_damping(0)
			ball:set_velocity(25 * i, 0)
			return ball
		end
	end
end

function Holder:remove(ball)
	for i, slot in ipairs(self.slots) do
		if slot.ball == ball then
			slot.ball = nil
		end
	end
end

function Holder:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
	graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, self.color, 3)

	local base_x = self.x - (#self.slots + 1) * self.slot_size / 2
	local count = 0
	for i, slot in ipairs(self.slots) do
		local index = self.is_enemy and i or (#self.slots - i + 1)
		local x = base_x + index * self.slot_size

		local color = slot.open and green[0] or red[0]
		graphics.rectangle(x, self.y, self.slot_size, self.slot_size, 2, 2, color, 3)

		-- this is weird, move to update or better yet, insert
		local ball = slot.ball
		if ball then
			ball:freeze(x, self.y)
			count = count + 1
			-- print(love.timer.getTime(), count, ball.x, ball.y)
		end
	end

	graphics.pop()
end
