Unit = Object:extend()
Unit:implement(GameObject)
function Unit:init(args)
	self:init_game_object(args)

	self.hp = self.type.hp or random:int(2, 6)
	self.speed = self.type.speed or random:int(1, 3)
	self.sprites = self.type.sprites()
	self.color = random:color():lighten(0.2)

	self.base_x = self.x
	self.base_y = self.y

	self.width = self.w * self.cell_size
	self.height = self.h * self.cell_size

	self.border = 0
	self.text = Text2({
		x = self.x,
		y = self.y,
		lines = { { text = self.type.name, font = small_pixul_font } },
	})
end

function Unit:update(dt)
	self:update_game_object(dt)

	local new_x = self.base_x + (self.tile_x - 1) * self.cell_size + self.width / 2
	local new_y = self.base_y + (self.tile_y - 1) * self.cell_size + self.height / 2
	if not self.moving and (self.x ~= new_x or self.y ~= new_y) then
		-- self.x = new_x
		-- self.y = new_y
		self.moving = true
		trigger:tween(0.05, self, { x = new_x, y = new_y }, math.cubic_in_out, function()
			self.moving = false
		end)
	end

	self.text.x = self.x
	self.text.y = self.y
	self.text:update(dt)
end

function Unit:highlight(on)
	self.border = on
	if self.border then
		self.beats_count = #self.timeline
		self.border_color = self.border == 1 and Color(0, 1, 0, 1) --
			or self.border == 2 and Color(0.5, 0, 1, 1)
			or Color(0, 0, 0, 1)
		self.text:set_text({
			{ text = "[bg]" .. self.type.name,             font = small_pixul_font },
			{ text = "[bg]" .. tostring(self.beats_count), font = pixul_font },
		})
	end
end

function Unit:beats_remaining(beats)
	self.text:set_text({
		{ text = "[bg]" .. self.type.name,      font = small_pixul_font },
		{ text = "[bg]" .. tostring(beats + 1), font = pixul_font },
	})
end

function Unit:get_projectile_type()
	return Projectile_Type.A
end

-- local target, range, axis_distance = args.unit:choose_move_target(self:get_all_alive_units(), self:get_all_interactible_entities())
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
	return { action = self.type.timeline[self.beat_index] }
end

function Unit:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)

	if self.visible then
		local x = self.x --+ (self.tile_x - 1) * self.cell_size + width / 2
		local y = self.y --+ (self.tile_y - 1) * self.cell_size + height / 2

		local visual_shrink = 20
		local border_size = 10
		local border_color = self.border_color

		if self.border > 0 then
			graphics.rectangle(x, y, self.width - visual_shrink + border_size, self.height - visual_shrink + border_size,
				2, 2, border_color)
		end

		graphics.rectangle(x, y, self.width - visual_shrink, self.height - visual_shrink, 2, 2, self.color)

		self.text:draw()
	end

	graphics.pop()
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
		timeline = { Timings.Beat, Timings.Hold, Timings.Hold },
		color = Color(1, 0, 0, 1),
		sprites = function()
			return nil
		end,
	},

	B = {
		name = "bap",
		speed = 4,
		attacks = { ShootAttack },
		timeline = { Timings.Beat, Timings.Beat, Timings.Beat },
		color = Color(1, 1, 0, 1),
		sprites = function()
			return nil
		end,
	},

	C = {
		name = "cap",
		speed = 6,
		attacks = { ShootAttack },
		timeline = { Timings.Beat, Timings.Hold, Timings.Beat },
		color = Color(1, 0, 1, 1),
		sprites = function()
			return nil
		end,
	},
}
