Unit = Object:extend()
Unit:implement(GameObject)
function Unit:init(args)
	self:init_game_object(args)
	self.hfx:add("hit", 1)
	self.hp_bar = HPBar({ group = main.current.effects, parent = self })
	self.effect_bar = EffectBar({ group = main.current.effects, parent = self })

	self.max_hp = self.type.hp or random:int(2, 4)
	self.hp = self.max_hp

	self.speed = self.type.speed or random:int(1, 3)
	self.sprites = self.type.sprites()
	self.color = random:color():lighten(0.2)

	self.base_x = self.x
	self.base_y = self.y

	self.width = self.w * self.cell_size
	self.height = self.h * self.cell_size
	self.shape = Rectangle(self.x, self.y, self.width, self.height)

	self.border = 0
	self.text = Text2({
		x = self.x,
		y = self.y,
		lines = { { text = self.type.name, font = small_pixul_font } },
	})
end

function Unit:update(dt)
	self:update_game_object(dt)

	if self.hp <= 0 then
		if not self.in_death_animation then
			self.in_death_animation = true
			self.hfx:use("hit", 0.45, 200, 10, 0.2)
			self.t:after(0.2, function()
				self.dead = true
			end)
		end
		return
	end

	local new_x = self.base_x + (self.tile_x - 1) * self.cell_size
	local new_y = self.base_y + (self.tile_y - 1) * self.cell_size
	if not self.moving and (self.x ~= new_x or self.y ~= new_y) then
		self.moving = true
		trigger:tween(0.05, self, { x = new_x, y = new_y }, math.cubic_in_out, function()
			self.moving = false
		end)
	end

	self.text.x = self.x
	self.text.y = self.y
	self.text:update(dt)
end

function Unit:take_damage(damage)
	self.hfx:use("hit", 0.15, 200, 10, 0.1)
	self.hp = self.hp - damage
	self:show_hp()
	return true
end

function Unit:highlight(on)
	self.border = on
	if self.border then
		self.beats_count = #self.timeline
		if on == 1 then
			self.border_color = Color(0, 1, 0, 1)
		elseif on == 2 then
			self.border_color = Color(0.3, 0, 1, 1)
		else
			self.border_color = Color(0, 0, 0, 1)
		end
		self.text:set_text({
			{
				text = "[bg]" .. self.type.name, --
				font = small_pixul_font,
			},
			{
				text = "[bg]" .. tostring(self.beats_count), --
				font = pixul_font,
			},
		})
	end
end

function Unit:beats_remaining(beats)
	self.text:set_text({
		{
			text = "[bg]" .. self.type.name, --
			font = small_pixul_font,
		},
		{
			text = "[bg]" .. tostring(beats + 1), --
			font = pixul_font,
		},
	})
end

function Unit:get_projectile_type()
	return Projectile_Type.A
end

-- local target, range, axis_distance =
-- args.unit:choose_move_target(self:get_all_alive_units(), self:get_all_interactible_entities())
function Unit:choose_move_target(units, objects)
	return table.random(table.select(units, function(v)
		return v.is_player
	end)) or {}
end

function Unit:choose_attack_targets(units, objects)
	local targets = {}

	-- current intelligence:
	--  > target all players if possible, else choose from a random subset
	--  > use one random attack
	for i, unit in ipairs(units) do
		if unit.is_player then -- TODO: smarter target selection
			table.insert(targets, unit)
		end
	end

	-- TODO: smarter attack selection, base on range/dmg/aoe, etc
	local attack = table.random(self.type.attacks)

	return targets, attack
end

function Unit:get_next_beat() -- for main.current.enemies_act_every_beat == true
	self.beat_index = self.beat_index or 0
	self.beat_index = (self.beat_index % #self.type.timeline) + 1
	return { action = self.type.timeline[self.beat_index][1] }
end

function Unit:show_hp(n)
	self.hp_bar.hidden = false
	self.hp_bar.color = red[0]
	self.t:after(n or 2, function()
		self.hp_bar.hidden = true
	end, "hp_bar")
end

function Unit:show_heal(n)
	self.effect_bar.hidden = false
	self.effect_bar.color = green[0]
	self.t:after(n or 4, function()
		self.effect_bar.hidden = true
	end, "effect_bar")
end

function Unit:draw()
	-- graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
	graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.y)

	if self.visible then
		local x = self.x --+ (self.tile_x - 1) * self.cell_size + width / 2
		local y = self.y --+ (self.tile_y - 1) * self.cell_size + height / 2

		local visual_shrink = 20
		local border_size = 15
		local border_color = self.is_player and self.border_color or Color(1, 0, 0, 1)

		if self.border > 0 then
			graphics.rectangle(
				x, --
				y,
				self.width - visual_shrink + border_size,
				self.height - visual_shrink + border_size,
				2,
				2,
				border_color
			)
		end

		local black_outline_size = 5
		graphics.rectangle(
			x, --
			y,
			self.width - visual_shrink + black_outline_size,
			self.height - visual_shrink + black_outline_size,
			2,
			2,
			Color(0, 0, 0, 1)
		)
		graphics.rectangle(
			x, --
			y,
			self.width - visual_shrink,
			self.height - visual_shrink,
			2,
			2,
			self.hfx.hit.f and fg[0] or self.color
		)

		self.text:draw()
	end

	graphics.pop()
	-- graphics.pop()
end

Unit_Type = {
	A = {
		name = "a",
		speed = 9,
		sprites = function()
			return nil
		end,
	},

	B = {
		name = "b",
		speed = 7,
		sprites = function()
			return nil
		end,
	},

	C = {
		name = "c",
		speed = 5,
		sprites = function()
			return nil
		end,
	},

	D = {
		name = "d",
		speed = 3,
		sprites = function()
			return nil
		end,
	},

	E = {
		name = "e",
		speed = 8 * 2,
		hp = 50,
		sprites = function()
			return nil
		end,
	},

	Calibration = {
		name = "you",
		speed = 1,
		sprites = function()
			return nil
		end,
	},
}

Enemy_Type = {
	A = {
		name = "aap",
		speed = 2,
		attacks = { ShootAttack },
		timeline = { --
			{ Timings.Beat },
			{ Timings.Empty },

			{ Timings.Hold },
			{ Timings.Empty },

			{ Timings.Hold },
			{ Timings.Empty },
		},
		color = Color(1, 0, 0, 1),
		sprites = function()
			return nil
		end,
	},

	B = {
		name = "bap",
		speed = 4,
		attacks = { ShootAttack },
		timeline = { --
			{ Timings.Beat },
			{ Timings.Empty },

			{ Timings.Beat },
			{ Timings.Empty },

			{ Timings.Beat },
			{ Timings.Empty },
		},
		color = Color(1, 1, 0, 1),
		sprites = function()
			return nil
		end,
	},

	C = {
		name = "cap",
		speed = 6,
		attacks = { ShootAttack },
		timeline = { --
			{ Timings.Beat },
			{ Timings.Empty },

			{ Timings.Hold },
			{ Timings.Empty },

			{ Timings.Beat },
			{ Timings.Empty },
		},
		color = Color(1, 0, 1, 1),
		sprites = function()
			return nil
		end,
	},
}

--
--
--
--
EffectBar = Object:extend()
EffectBar:implement(GameObject)
EffectBar:implement(Parent)
function EffectBar:init(args)
	self:init_game_object(args)
	self.hidden = true
	self.color = fg[0]
end

function EffectBar:update(dt)
	self:update_game_object(dt)
	self:follow_parent_exclusively()
end

function EffectBar:draw()
	if self.hidden then
		return
	end
	--[[
  local p = self.parent
  graphics.push(p.x, p.y, p.r, p.hfx.hit.x, p.hfx.hit.x)
    graphics.rectangle(p.x, p.y, 3, 3, 1, 1, self.color)
  graphics.pop()
  ]]
	--
end

--
--
--
--
HPBar = Object:extend()
HPBar:implement(GameObject)
HPBar:implement(Parent)
function HPBar:init(args)
	self:init_game_object(args)
	self.hidden = true
end

function HPBar:update(dt)
	self:update_game_object(dt)
	self:follow_parent_exclusively()
end

function HPBar:draw()
	if self.hidden then
		return
	end
	local p = self.parent
	local thickness = 14
	graphics.push(p.x, p.y, 0, p.hfx.hit.x, p.hfx.hit.x)
	local y = p.y + p.shape.h * 0.5

	graphics.line(p.x - 0.5 * p.shape.w, y, p.x + 0.5 * p.shape.w, y, bg[-3], thickness)
	local n = math.max(math.remap(p.hp, 0, p.max_hp, 0, 1), 0)
	graphics.line(
		p.x - 0.5 * p.shape.w,
		y,
		p.x - 0.5 * p.shape.w + n * p.shape.w,
		y,
		p.hfx.hit.f and fg[0] or (p.is_player and green[0]) or red[0],
		thickness
	)
	graphics.pop()
end
