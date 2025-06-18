Unit = Object:extend()
function Unit:init_unit()
	self.level = self.level or 1
	self.hfx:add("hit", 1)
	self.hfx:add("shoot", 1)
	self.hp_bar = HPBar({ group = main.current.effects, parent = self })
	self.effect_bar = EffectBar({ group = main.current.effects, parent = self })
end

function Unit:bounce(nx, ny)
	local vx, vy = self:get_velocity()
	if nx == 0 then
		self:set_velocity(vx, -vy)
		self.r = 2 * math.pi - self.r
	end
	if ny == 0 then
		self:set_velocity(-vx, vy)
		self.r = math.pi - self.r
	end
	return self.r
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

function Unit:show_infused(n)
	self.effect_bar.hidden = false
	self.effect_bar.color = blue[0]
	self.t:after(n or 4, function()
		self.effect_bar.hidden = true
	end, "effect_bar")
end

function Unit:calculate_damage(dmg)
	if self.def >= 0 then
		dmg = dmg * (100 / (100 + self.def))
	else
		dmg = dmg * (2 - 100 / (100 + self.def))
	end
	return dmg
end

function Unit:calculate_stats(first_run)
	if self:is(Player) then
		self.base_hp = 100 * math.pow(2, self.level - 1)
		self.base_dmg = 10 * math.pow(2, self.level - 1)
		self.base_mvspd = 75
	elseif self:is(EnemyCritter) or self:is(Critter) then
		local x = self.level
		local y = { 0, 1, 3, 3, 4, 6, 5, 6, 9, 7, 8, 12, 10, 11, 15, 12, 13, 18, 16, 17, 21, 17, 20, 24, 25 }
		local k = 1.2
		for i = 26, 5000 do
			local n = i % 25
			if n == 0 then
				n = 25
				k = k + 0.2
			end
			y[i] = y[n] * k
		end
		self.base_hp = 25 + 30 * (y[x] or 1)
		self.base_dmg = 10 + 3 * (y[x] or 1)
		self.base_mvspd = 60 + 3 * (y[x] or 1)
	elseif self:is(Overlord) then
		self.base_hp = 50 * math.pow(2, self.level - 1)
		self.base_dmg = 10 * math.pow(2, self.level - 1)
		self.base_mvspd = 40
	end
	self.base_aspd_m = 1
	self.base_area_dmg_m = 1
	self.base_area_size_m = 1
	self.base_def = 25
	self.class_hp_a = 0
	self.class_dmg_a = 0
	self.class_def_a = 0
	self.class_mvspd_a = 0
	self.class_hp_m = 1
	self.class_dmg_m = 1
	self.class_aspd_m = 1
	self.class_area_dmg_m = 1
	self.class_area_size_m = 1
	self.class_def_m = 1
	self.class_mvspd_m = 1
	if first_run then
		self.buff_hp_a = 0
		self.buff_dmg_a = 0
		self.buff_def_a = 0
		self.buff_mvspd_a = 0
		self.buff_hp_m = 1
		self.buff_dmg_m = 1
		self.buff_aspd_m = 1
		self.buff_area_dmg_m = 1
		self.buff_area_size_m = 1
		self.buff_def_m = 1
		self.buff_mvspd_m = 1
	end

	self.max_hp = (self.base_hp + self.class_hp_a + self.buff_hp_a) * self.class_hp_m * self.buff_hp_m
	self.hp = self.max_hp
	self.dmg = (self.base_dmg + self.class_dmg_a + self.buff_dmg_a) * self.class_dmg_m * self.buff_dmg_m
	self.aspd_m = 1 / (self.base_aspd_m * self.class_aspd_m * self.buff_aspd_m)
	self.area_dmg_m = self.base_area_dmg_m * self.class_area_dmg_m * self.buff_area_dmg_m
	self.area_size_m = self.base_area_size_m * self.class_area_size_m * self.buff_area_size_m
	self.def = (self.base_def + self.class_def_a + self.buff_def_a) * self.class_def_m * self.buff_def_m
	self.max_v = (self.base_mvspd + self.class_mvspd_a + self.buff_mvspd_a) * self.class_mvspd_m * self.buff_mvspd_m
	self.v = (self.base_mvspd + self.class_mvspd_a + self.buff_mvspd_a) * self.class_mvspd_m * self.buff_mvspd_m
end

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
	graphics.push(p.x, p.y, 0, p.hfx.hit.x, p.hfx.hit.x)
	graphics.line(p.x - 0.5 * p.shape.w, p.y - p.shape.h, p.x + 0.5 * p.shape.w, p.y - p.shape.h, bg[-3], 2)
	local n = math.remap(p.hp, 0, p.max_hp, 0, 1)
	graphics.line(
		p.x - 0.5 * p.shape.w,
		p.y - p.shape.h,
		p.x - 0.5 * p.shape.w + n * p.shape.w,
		p.y - p.shape.h,
		p.hfx.hit.f and fg[0]
			or (
				(p:is(Player) and green[0])
				or (table.any(main.current.enemies, function(v)
					return p:is(v)
				end) and red[0])
			),
		2
	)
	graphics.pop()
end
