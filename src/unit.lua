Unit = Object:extend()
Unit:implement(GameObject)
function Unit:init(args)
	self:init_game_object(args)

	self.hp = self.type.hp or random:int(2, 6)
	self.speed = self.type.speed or random:int(1, 3)
	self.sprites = self.type.sprites()
	self.color = random:color()

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

	self.x = self.base_x + (self.tile_x - 1) * self.cell_size + self.width / 2
	self.y = self.base_y + (self.tile_y - 1) * self.cell_size + self.height / 2

	self.text.x = self.x
	self.text.y = self.y
	self.text:update(dt)
end

function Unit:highlight(on)
	self.border = on
	if self.border then
		self.beats_count = #self.timeline
		self.border_color = self.border == 1 and Color(0, 1, 0, 1) or self.border == 2 and Color(0.5, 0, 1, 1) or Color(0, 0, 0, 1)
		self.text:set_text({
			{ text = "[fg]" .. self.type.name, font = small_pixul_font },
			{ text = "[fg]" .. tostring(self.beats_count), font = small_pixul_font },
		})
	end
end

function Unit:beats_remaining(beats)
	self.text:set_text({
		{ text = "[fg]" .. self.type.name, font = small_pixul_font },
		{ text = "[fg]" .. tostring(beats), font = small_pixul_font },
	})
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
			graphics.rectangle(x, y, self.width - visual_shrink + border_size, self.height - visual_shrink + border_size, 2, 2, border_color)
		end

		graphics.rectangle(x, y, self.width - visual_shrink, self.height - visual_shrink, 2, 2, self.color)

		self.text:draw()
	end

	graphics.pop()
end

Unit_Type = {
	A = {
		name = "a",
		speed = 10,
		sprites = function()
			return nil
		end,
	},
	B = {
		name = "b",
		speed = 9,
		sprites = function()
			return nil
		end,
	},
	C = {
		name = "c",
		speed = 8,
		sprites = function()
			return nil
		end,
	},
	D = {
		name = "d",
		speed = 7,
		sprites = function()
			return nil
		end,
	},
	E = {
		name = "e",
		speed = 6,
		sprites = function()
			return nil
		end,
	},
}
