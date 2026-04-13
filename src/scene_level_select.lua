Level_Select = Object:extend()
Level_Select:implement(State)
Level_Select:implement(GameObject)
function Level_Select:init(name)
	self:init_state(name)
	self:init_game_object()
end

function Level_Select:on_enter(from, args)
	self.hfx:add("condition1", 1)
	self.hfx:add("condition2", 1)

	camera.x, camera.y = gw / 2, gh / 2
	camera.r = 0

	self.main = Group()

	self.main_slow_amount = 1
	slow_amount = 1

	self.ui_elements = {}
	main.ui_layer_stack:push({
		layer = ui_interaction_layer.Level_Select,
		layer_has_music = false,
		ui_elements = self.ui_elements,
	})

	self.levels = self:load_levels()

	local cols = 3

	local scale = gw * 0.08
	local spacing = scale * 1.1
	local x_center = gw / 2
	local y_start = scale

	for i, level in ipairs(self.levels) do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)

		local total_width = (cols - 1) * spacing

		collect_into(
			self.ui_elements,
			RectangleButton({
				group = self.main,
				layer = ui_interaction_layer.Level_Select,
				x = x_center - total_width / 2 + col * spacing,
				y = y_start + row * spacing,
				w = scale,
				h = scale,
				force_update = true,
				no_image = true,
				color = Color(1, 1, 0, 1),
				title_text = level.name,
				fg_color = "bg",
				action = function(b)
					scene_transition(self, {
						x = gw / 2,
						y = gh / 2,
						type = "circle",
						target = {
							scene = Character_Setup,
							name = "character_setup",
							args = { clear_music = true },
						},
						display = {
							text = "loading level " .. level.name,
							font = pixul_font,
							alignment = "center",
						},
					})
				end,
			})
		)
	end
end

function Level_Select:update(dt)
	self:update_game_object(dt * slow_amount)
	self.main:update(dt)
end

function Level_Select:load_levels()
	return {
		{ name = "1" },
		{ name = "2" },
		{ name = "3" },
		{ name = "4" },
		{ name = "5" },
		{ name = "6" },
		{ name = "7" },
		{ name = "8" },
		{ name = "9" },
		{ name = "10" },
	}
end

function Level_Select:draw()
	self.main:draw()
end

function Level_Select:on_exit()
	self.main:destroy()
	self.main = nil
end
