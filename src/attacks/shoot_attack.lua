ShootAttack = function(args)
	local source = args.source
	local targets = args.targets
	local map = args.map

	local target = table.random(targets) -- TODO: smarter selection, maybe base off distance?

	local dx = target.tile_x - source.tile_x
	local dy = target.tile_y - source.tile_y

	local axis = math.abs(dx) > math.abs(dy)
	local dir_x = (dx ~= 0 and axis) and (dx / math.abs(dx)) or 0
	local dir_y = (dy ~= 0 and not axis) and (dy / math.abs(dy)) or 0

	if dir_x == 0 and dir_y == 0 then
		print("zero: ", target.tile_x, target.tile_y, " vs ", source.tile_x, source.tile_y)
	end

	local projectile_type = source:get_projectile_type()

	local projectile = Projectile({
		group = map.group,
		x = source.base_x,
		y = source.base_y,
		tile_x = source.tile_x,
		tile_y = source.tile_y,
		dir_x = dir_x,
		dir_y = dir_y,
		cell_size = map.cell_size,
		type = projectile_type,
		source = source,
		target = target,
	})

	return projectile
end

return ShootAttack
