extends Node2D

@onready var asteroid_layer = $Asteroid
@onready var mined_layer = $AsteroidMined

var is_tile_drilled := {}

func drill_at_tile(world_pos: Vector2) -> void:
	var local_pos = asteroid_layer.to_local(world_pos)
	var tile_coords = asteroid_layer.local_to_map(local_pos)
	print("🗺️ Drill at tile coords:", tile_coords)

	var tile_id = asteroid_layer.get_cell_source_id(0, tile_coords)
	if tile_id == -1:
		print("⛔ No tile to drill at", tile_coords)
		return

	asteroid_layer.set_cell(0, tile_coords, -1)
	print("✅ Drilled tile at:", tile_coords)
