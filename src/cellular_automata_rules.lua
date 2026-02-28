function apply_cellular_automata_rules(automata)
	automata:add_rules({
		{
			condition = function(board, tile)
				return automata:has_trait(tile, "lava") and automata:neighbor_has_trait(tile, "water")
			end,
			result = Tile_Type.Stone,
		},
		{
			condition = function(board, tile)
				return automata:has_trait(tile, "water") and automata:count_neighbors_with_trait(tile, "lava") >= 2
			end,
			result = Tile_Type.Stone,
		},
	})
end
