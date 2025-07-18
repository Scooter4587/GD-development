extends TileMapLayer

# --- ⚙️ PRIPOJENIE NA ResourceManager ---
@onready var resource_manager := get_node("/root/Main/ResourcesManager")
@onready var resource_layer := resource_manager.get_node_or_null("ResourceLayer")

# --- 🔨 Vŕtanie dlaždice ---
func drill_at_tile(world_pos: Vector2):
	var tilemap = get_parent() # ← Parent je TileMap
	var coords: Vector2i = tilemap.local_to_map(tilemap.to_local(world_pos))
	
	if tilemap.is_valid_cell(coords):
		tilemap.erase_cell(coords)
