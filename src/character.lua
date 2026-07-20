Character = Object:extend()
Character:implement(GameObject)
function Character:init(args)
	self:init_game_object(args)

	self.armour = 3
	self.hp = self.max_hp
	self.color = random:color()
	self.money = self.money or 0

	self.hp_text = Text({ { text = "hallo", font = pixul_font, alignment = "center" } }, global_text_tags)
	self.money_text = Text({ { text = "hallo", font = pixul_font, alignment = "center" } }, global_text_tags)

	self.name_text = Text({ --
		{ text = "", font = pixul_font, alignment = "center" },
	}, global_text_tags)
	self.animations = {}
end

function Character:take_damage(damage)
	local post_armour = self.armour - damage
	self.armour = math.max(0, post_armour)

	if self.animations then
		self.animation = self.animations.hurt
	end

	if post_armour < 0 then
		self.hp = math.max(0, self.hp + post_armour)

		if self.hp == 0 then
			self:die()
		end
	end
end

function Character:armour_up(armour)
	self.armour = self.armour + armour
end

function Character:heal(health)
	self.hp = math.min(self.max_hp, self.hp + health)
end

function Character:die()
	self.animation = self.animations.death
	local time = self.animation and self.animation.duration or 0
	print("waiting for: ", time)
	self.t:after(time, function()
		self.has_died = true
		print("im ded")
	end)
end

function Character:update(dt)
	self:update_game_object(dt)

	if
		self.is_enemy
		and self.animations
		and (self.animation == self.animations.hurt or self.animation == self.animations.spawn)
		and self.animation.animation_logic.dead
	then
		self.animation = self.animations.idle
		self.animation:reset()
	end

	local armour_text = self.armour > 0 and "[blue]+" .. tostring(self.armour) .. " " or ""
	self.hp_text:set_text({
		{
			text = armour_text .. "[green]" .. tostring(self.hp) .. "/" .. tostring(self.max_hp),
			font = pixul_font,
			alignment = "center",
		},
	})

	self.money_text:set_text({
		{
			text = "[yellow]" .. "$" .. tostring(self.money),
			font = pixul_font,
			alignment = "center",
		},
	})

	-- self.damage_text:set_text({
	-- 	{
	-- 		text = "[red]" .. tostring(self.damage),
	-- 		font = pixul_font,
	-- 		alignment = "center",
	-- 	},
	-- })

	if self.animation then
		self.animation:update(dt)
	end
end

function Character:draw()
	graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)

	if self.portrait then
		local width = gw * 0.2
		local height = gh * 0.4 + 15
		graphics.rectangle(self.portrait.x, self.portrait.y, width, height, 3, 3, white[0])
		graphics.rectangle( --
			self.portrait.x,
			self.portrait.y,
			width - 6,
			height - 6,
			3,
			3,
			self.portrait.background.color
		)

		if self.animation then
			self.animation:draw( --
				self.portrait.x,
				self.portrait.y,
				self.r,
				self.portrait.draw_size,
				self.portrait.draw_size
			)
		end
		self.name_text:draw(self.portrait.x, self.portrait.y + gh * 0.24, self.r, 1, 1)
	end

	local separation = gh * 0.05
	local box_width = math.max(self.hp_text.w, self.money_text.w) + 10
	local box_height = 1.3 * self.hp_text.h + separation
	graphics.rectangle(self.x, self.y - separation / 7, box_width + 5, box_height + 5, 3, 3, white[0])
	graphics.rectangle(self.x, self.y - separation / 7, box_width, box_height, 3, 3, black[0])

	self.hp_text:draw(self.x, self.y - separation / 2, self.r, 1, 1)
	self.money_text:draw(self.x, self.y + separation / 2, self.r, 1, 1)
	-- self.damage_text:draw(self.x, self.y + separation, self.r, 1, 1)
	graphics.pop()
end

function Character:load_next_enemy()
	self.enemy_index = self.enemy_index and (self.enemy_index + 1) or 1

	local enemy = Enemies[self.enemy_index]
	if enemy then
		self.has_died = false
		self.portrait = enemy.portrait
		self.portrait.x = gw * 0.87
		self.portrait.y = gh * 0.2
		self.portrait.draw_size = 7

		self.animations = enemy.portrait.animations()
		self.animation = self.animations.spawn
		-- self.animation = enemy.portrait.animation()
		self.max_hp = enemy.max_hp
		self.hp = enemy.max_hp
		self.armour = enemy.armour or 0

		self.name_text:set_text({
			{
				text = self.portrait.name,
				font = pixul_font,
				alignment = "center",
			},
		})

		-- setup balls from ball types
		local balls = {}
		for i, ball_type in ipairs(enemy.balls) do
			table.insert(
				balls,
				Ball({
					group = self.group,
					type = ball_type,
				})
			)
		end
		self.holder:setup(#balls, #balls, balls)
		self.holder:enable_ball_selection()

		self.spring:pull(0.2, 500, 10)
	end

	return enemy ~= nil
end

Enemies = {
	{ -- Angry Bob:
		money = 1,
		max_hp = 10,
		armour = 1,
		balls = {
			Ball_Type.starter_damage_ball,
			Ball_Type.starter_damage_ball,
			Ball_Type.starter_damage_ball,
			Ball_Type.starter_damage_ball,
			Ball_Type.starter_damage_ball,
			Ball_Type.starter_damage_ball,
			Ball_Type.starter_damage_ball,
		},
		portrait = {
			name = "[red]Angry [p_blue1]Bob",
			background = {
				color = Color("#063000"),
			},
			animations = function()
				return {
					idle = Animation(
						0.4,
						AnimationFrames(sprite.alien1, 16, 32, {
							{ 1, 2 },
							{ 2, 2 },
							{ 3, 2 },
							{ 4, 2 },
							{ 5, 2 },
							{ 6, 2 },
						}),
						"loop"
					),

					spawn = Animation(
						0.08,
						AnimationFrames(sprite.alien1, 16, 32, {
							{ 1, 4 },
							{ 2, 4 },
							{ 3, 4 },
							{ 4, 4 },
							{ 5, 4 },
							{ 6, 4 },
						}),
						"once"
					),

					hurt = Animation(
						0.1,
						AnimationFrames(sprite.alien1, 16, 32, {
							{ 1, 3 },
							{ 2, 3 },
							{ 3, 3 },
							{ 4, 3 },
							{ 5, 3 },
							{ 6, 3 },
						}),
						"once"
					),

					death = Animation(
						0.12,
						AnimationFrames(sprite.alien1, 16, 32, {
							{ 1, 1 },
							{ 2, 1 },
							{ 3, 1 },
							{ 4, 1 },
							{ 5, 1 },
							{ 6, 1 },
						}),
						"once"
					),
				}
			end,
		},
	},

	{ -- Angry Bob:
		money = 1,
		max_hp = 20,
		armour = 10,
		balls = {
			Ball_Type.starter_damage_ball,
			Ball_Type.starter_damage_ball,
		},
		portrait = {
			name = "[green]Happy [p_blue1]Bob",
			background = {
				color = Color("#063000"),
			},
			animations = function()
				return {
					idle = Animation(
						0.4,
						AnimationFrames(sprite.alien1, 16, 32, {
							{ 1, 2 },
							{ 2, 2 },
							{ 3, 2 },
							{ 4, 2 },
							{ 5, 2 },
							{ 6, 2 },
						}),
						"loop"
					),

					spawn = Animation(
						0.08,
						AnimationFrames(sprite.alien1, 16, 32, {
							{ 1, 4 },
							{ 2, 4 },
							{ 3, 4 },
							{ 4, 4 },
							{ 5, 4 },
							{ 6, 4 },
						}),
						"once"
					),

					hurt = Animation(
						0.1,
						AnimationFrames(sprite.alien1, 16, 32, {
							{ 1, 3 },
							{ 2, 3 },
							{ 3, 3 },
							{ 4, 3 },
							{ 5, 3 },
							{ 6, 3 },
						}),
						"once"
					),

					death = Animation(
						0.12,
						AnimationFrames(sprite.alien1, 16, 32, {
							{ 1, 1 },
							{ 2, 1 },
							{ 3, 1 },
							{ 4, 1 },
							{ 5, 1 },
							{ 6, 1 },
						}),
						"once"
					),
				}
			end,
		},
	},
}
