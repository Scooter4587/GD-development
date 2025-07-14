extends Node2D

@onready var asteroid_layer = $Asteroid
@onready var mined_layer = $AsteroidMined

var is_tile_drilled := {}

func drill_at_tile(world_pos: Vector2) -> void:
	var local_pos = asteroid_layer.to_local(world_pos)
	var tile_coords = asteroid_layer.local_to_map(local_pos)
	print("📍 Drill world_pos:", world_pos)
	print("📍 Converted to tile coords:", tile_coords)

	var tile_id = asteroid_layer.get_cell_source_id(0, tile_coords)
	print("🔍 Tile ID na pozícii:", tile_id)

	if tile_id == -1:
		print("⛔ No asteroid tile at:", tile_coords)
		return

	if is_tile_drilled.get(tile_coords, false):
		print("🪨 Tile already drilled:", tile_coords)
		return

	# Vymaž tile
	asteroid_layer.set_cell(0, tile_coords, -1)
	is_tile_drilled[tile_coords] = true
	print("✅ Tile mined at:", tile_coords)
