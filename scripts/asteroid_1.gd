extends Node2D

@onready var asteroid_layer = $Asteroid
@onready var mined_layer = $AsteroidMined

var is_tile_drilled := {}

func drill_at_tile(global_position: Vector2) -> void:
	var local_position = asteroid_layer.to_local(global_position)
	var tile_coords = asteroid_layer.local_to_map(local_position)

	# Over, či už bol tile navŕtaný
	if is_tile_drilled.get(tile_coords, false):
		print("🪨 Tile already drilled:", tile_coords)
		return

	# Over, či existuje tile na tomto mieste
	var tile_id = asteroid_layer.get_cell_source_id(0, tile_coords)
	if tile_id == -1:
		print("⛔ No asteroid tile at:", tile_coords)
		return

	# Vymaž tile zo "viditeľnej" vrstvy
	asteroid_layer.set_cell(0, tile_coords, -1)

	# Poznač ako navŕtaný
	is_tile_drilled[tile_coords] = true

	print("✅ Tile mined at:", tile_coords)

	# Neskôr môžeme tu zobraziť aj mined_layer vizuálne, ak budeš chcieť
