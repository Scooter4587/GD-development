extends TileMapLayer

# --- 🔨 Vŕtanie dlaždice ---
func drill_at_tile(world_pos: Vector2) -> void:
	# Prevedieme globálnu pozíciu do lokálnych súradníc TileMapLayer
	var local_pos: Vector2 = to_local(world_pos)
	# Získame súradnice dlaždice
	var coords: Vector2i = local_to_map(local_pos)
	# Zistíme ID dlaždice; ak je -1, bunka neexistuje alebo je prázdna
	var tile_id: int = get_cell_source_id(coords)
	if tile_id != -1:
		# Odstránime dlaždicu
		erase_cell(coords)
