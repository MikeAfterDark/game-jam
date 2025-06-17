require("engine")
require("mainmenu")
require("levelselect")
-- require("shared")
require("renderer")
-- require("arena")
-- require("objects")
-- require("player")
-- require("media")

function init()
	renderer_init()

	input:bind("move_left", { "a", "left", "dpleft", "m1" })
	input:bind("move_right", { "d", "right", "dpright", "m2" })
	input:bind("move_forward", { "w", "up", "dpup", "m3" })
	input:bind("enter", { "space", "return", "fleft", "fdown", "fright" })

	local s = { tags = { sfx } }
	-- load sounds:
	-- explosion1 = Sound('Explosion Grenade_04.ogg', s)
	buttonHover = Sound("buttonHover.ogg", s)
	buttonPop = Sound("buttonPop.ogg", s)

	ui_switch1 = Sound("ui_switch1.ogg", s)
	ui_switch2 = Sound("ui_switch2.ogg", s)
	ui_transition2 = Sound("ui_transition2.ogg", s)

	-- load songs
	-- song1 = Sound("Kubbi - Ember - 01 Pathfinder.ogg", { tags = { music } })
	-- song2 = Sound("Kubbi - Ember - 02 Ember.ogg", { tags = { music } })
	-- song3 = Sound("Kubbi - Ember - 03 Firelight.ogg", { tags = { music } })
	-- song4 = Sound("Kubbi - Ember - 04 Cascade.ogg", { tags = { music } })
	-- song5 = Sound("Kubbi - Ember - 05 Compass.ogg", { tags = { music } })

	-- load images:
	-- image1 = Image('name')

	-- set logic init
	-- main_song_instance = _G[random:table({ "song1", "song2", "song3", "song4", "song5" })]:play({ volume = 0.5 })

	main = Main()
	main:add(MainMenu("mainmenu"))
	main:add(LevelSelect("level_select"))
	main:go_to("mainmenu")
end

function update(dt)
	main:update(dt)

	-- update window max sizing
	if input.k.pressed then
		if sx > 1 and sy > 1 then
			sx, sy = sx - 0.5, sy - 0.5
			love.window.setMode(480 * sx, 270 * sy)
			state.sx, state.sy = sx, sy
			state.fullscreen = false
		end
	end

	if input.l.pressed then
		sx, sy = sx + 0.5, sy + 0.5
		love.window.setMode(480 * sx, 270 * sy)
		state.sx, state.sy = sx, sy
		state.fullscreen = false
	end
end

function draw()
	renderer_draw(function()
		main:draw()
	end)
end

function love.run()
	return engine_run({
		game_name = "Jame Gam 50",
		window_width = "max",
		window_height = "max",
	})
end
