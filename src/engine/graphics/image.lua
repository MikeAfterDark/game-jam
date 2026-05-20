-- The base Image class.
Image = Object:extend()
function Image:init(asset, is_path)
	self.image = love.graphics.newImage(is_path and asset or ("assets/images/" .. asset .. ".png"))
	self.w = self.image:getWidth()
	self.h = self.image:getHeight()
end

function Image:draw(x, y, r, sx, sy, ox, oy, color)
	local _r, g, b, a
	if color then
		_r, g, b, a = love.graphics.getColor()
		graphics.set_color(color)
	end
	love.graphics.draw(self.image, x, y, r or 0, sx or 1, sy or sx or 1, self.w / 2 + (ox or 0), self.h / 2 + (oy or 0))
	if color then
		love.graphics.setColor(_r, g, b, a)
	end
end

ImageData = Object:extend()
function ImageData:init(path)
	self.data = love.image.newImageData(path)
	self.w = self.data:getWidth()
	self.h = self.data:getHeight()
end

function ImageData:get_pixel(x, y)
	return self.data:getPixel(x, y)
end

-- The base Quad class. Useful for loading pieces of images as independent Image objects. Every function that takes in an Image also takes in a Quad.
Quad = Object:extend()
function Quad:init(image, tile_w, tile_h, tile_coordinates)
	self.image = image
	self.quad = love.graphics.newQuad((tile_coordinates[1] - 1) * tile_w, (tile_coordinates[2] - 1) * tile_h, tile_w, tile_h, self.image.w, self.image.h)
	self.w, self.h = tile_w, tile_h
end

function Quad:draw(x, y, r, sx, sy, ox, oy)
	love.graphics.draw(self.image.image, self.quad, x, y, r or 0, sx or 1, sy or sx or 1, self.w / 2 + (ox or 0), self.h / 2 + (oy or 0))
end

-- A linear gradient image.
-- The first argument is the direction of the gradient and can be either 'horizontal' or 'vertical'.
GradientImage = Object:extend()
function GradientImage:init(direction, ...)
	local colors = { ... }
	local mesh_data = {}

	if direction == "horizontal" then
		for i = 1, #colors do
			local color = colors[i]
			local x = (i - 1) / (#colors - 1)
			table.insert(mesh_data, { x, 1, x, 1, color.r, color.g, color.b, color.a or 1 })
			table.insert(mesh_data, { x, 0, x, 0, color.r, color.g, color.b, color.a or 1 })
		end
	elseif direction == "vertical" then
		for i = 1, #colors do
			local color = colors[i]
			local y = (i - 1) / (#colors - 1)
			table.insert(mesh_data, { 1, y, 1, y, color.r, color.g, color.b, color.a or 1 })
			table.insert(mesh_data, { 0, y, 0, y, color.r, color.g, color.b, color.a or 1 })
		end
	elseif direction == "arc" then
		-- colors:
		-- {
		--     radius = 1,
		--     thickness = 0.15,
		--     segments = 128,
		--     gap_start = 0,
		--     gap_end = math.pi/4,
		--     fade_size = math.pi/32,
		--     color = {r=1,g=1,b=1,a=1}
		-- }

		local settings = colors[1]

		local radius = settings.radius or 1
		local thickness = settings.thickness or 0.1
		local segments = settings.segments or 128

		local gap_start = settings.gap_start or 0
		local gap_end = settings.gap_end or math.pi / 4
		local fade_size = settings.fade_size or math.pi / 32

		local color = settings.color or { r = 1, g = 1, b = 1, a = 1 }

		local inner = radius - thickness * 0.5
		local outer = radius + thickness * 0.5

		local tau = math.pi * 2

		local function alpha_for_angle(a)
			a = a % tau

			-- fully transparent region
			if a >= gap_start + fade_size and a <= gap_end - fade_size then
				return 0
			end

			-- fade out
			if a >= gap_start and a < gap_start + fade_size then
				local t = (a - gap_start) / fade_size
				return 1 - t
			end

			-- fade back in
			if a > gap_end - fade_size and a <= gap_end then
				local t = (a - (gap_end - fade_size)) / fade_size
				return t
			end

			return 1
		end

		for i = 0, segments do
			local a = (i / segments) * tau

			local ca = math.cos(a)
			local sa = math.sin(a)

			local alpha = alpha_for_angle(a)

			local r = color.r
			local g = color.g
			local b = color.b
			local final_a = (color.a or 1) * alpha

			-- outer vertex
			table.insert(mesh_data, {
				0.5 + ca * outer * 0.5,
				0.5 + sa * outer * 0.5,
				0,
				0,
				r,
				g,
				b,
				final_a,
			})

			-- inner vertex
			table.insert(mesh_data, {
				0.5 + ca * inner * 0.5,
				0.5 + sa * inner * 0.5,
				0,
				0,
				r,
				g,
				b,
				final_a,
			})
		end
	end

	self.mesh = love.graphics.newMesh(mesh_data, "strip", "static")
end

-- Draws the gradient image with size w, h centered on x, y.
function GradientImage:draw(x, y, w, h, r, sx, sy, ox, oy)
	graphics.push(x, y, r)
	love.graphics.draw(self.mesh, x - (sx or 1) * (w + (ox or 0)) / 2, y - (sy or 1) * (h + (oy or 0)) / 2, 0, w * (sx or 1), h * (sy or sx or 1))
	graphics.pop()
end
