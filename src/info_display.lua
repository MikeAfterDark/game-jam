Info_Display = Object:extend()
Info_Display:implement(GameObject)
function Info_Display:init(args)
	self:init_game_object(args)

	self.expanded = false

	self.left_button = RectangleButton({
		group = self.group,
		layer = ui_interaction_layer.Game,
		bg_color = "fg",
		x = self.x - self.w / 2,
		y = gh / 2,
		w = gw * 0.01,
		h = gh * 0.1,
		action = function(b)
			self.left_button_action()
		end,
	})
	self.right_button = RectangleButton({
		group = self.group,
		layer = ui_interaction_layer.Game,
		bg_color = "fg",
		x = self.x + self.w / 2,
		y = gh / 2,
		w = gw * 0.01,
		h = gh * 0.1,
		action = function(b)
			self.right_button_action()
		end,
	})

	self.texts = {
		building_name = Text2({
			group = self.group,
			lines = {},
			offset_x = gw * 0.03,
			offset_y = -gh * 0.42, -- top section position
		}),
		tile_name = Text2({
			group = self.group,
			lines = {},
			offset_x = gw * 0.03,
			offset_y = gh * 0.05, -- bottom section position
		}),
	}
end

function Info_Display:update(dt)
	self:update_game_object(dt)

	local building = game_mouse.holding or game_mouse.hovering
	if building and building ~= self.building then
		self.building = building
		self.texts.building_name:set_text({
			{
				text = self.building.type.name,
				font = pixul_font,
				alignment = "center",
			},
		})
	end

	local tile = game_mouse.tile_hovered
	if tile and tile ~= self.tile then
		self.tile = tile
		self.texts.tile_name:set_text({
			{
				text = self.tile.type.name,
				font = pixul_font,
				alignment = "center",
			},
		})
	end

	for _, text in pairs(self.texts) do
		text.x = self.x + (text.offset_x or 0)
		text.y = self.y + (text.offset_y or 0)
		text:update(dt)
	end

	local left_x = self.x - self.w / 2 - self.left_button.w / 2
	local right_x = self.x + self.w / 2 + self.right_button.w / 2
	self.left_button.x = left_x
	self.left_button.shape:move_to(left_x, self.y)
	self.right_button.x = right_x
	self.right_button.shape:move_to(right_x, self.y)
end

function Info_Display:draw()
	graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)

	local corners = 20
	graphics.rectangle(self.x, self.y, self.w, self.h, corners, corners, fg[-2]) -- background

	-- top section
	graphics.rectangle(self.x, self.y / 2 * 1.05, self.w * 0.9, self.h / 2 * 0.95, corners, corners, bg[0])
	if self.building then
		local sprite_scale = 4
		self.building.type.sprites()[1]:draw(self.x - gw * 0.055, self.y - gh * 0.33, 0, sprite_scale, sprite_scale, 0, 0)
	end

	-- bottom section
	graphics.rectangle(self.x, self.y / 2 * 3 * 0.98, self.w * 0.9, self.h / 2 * 0.95, corners, corners, bg[0])
	if game_mouse.tile_hovered then
		local sprite_scale = 2.9
		game_mouse.tile_hovered.type
			.sprites()[1]
			:draw(self.x - gw * 0.055, self.y + gh * 0.1, 0, sprite_scale, sprite_scale, 0, 0, game_mouse.tile_hovered.type.sprites()[2] or white[0])
	end

	graphics.pop()
end
