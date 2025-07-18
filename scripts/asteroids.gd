extends Node2D

@onready var asteroid_layer: TileMapLayer = $Asteroid
@onready var mined_sprite: Sprite2D = $MinedSprite

@export var asteroid_type: String = "asteroid_1"

var asteroid_data: Dictionary = {}

func _ready() -> void:
	asteroid_data = AsteroidData.get_properties(asteroid_type)

# 🔍 Dá sa tento asteroid vôbec ťažiť?
func is_drillable() -> bool:
	return asteroid_data.get("minable", false)

# ⛏️ Vŕtanie na svetovej pozícii; _drill_power je zatiaľ nepoužitý
func drill_at(world_pos: Vector2, _drill_power: int) -> void:
	if not is_drillable():
		print("❌ Tento asteroid sa nedá ťažiť!")
		return

	var local_pos: Vector2 = asteroid_layer.to_local(world_pos)
	var coords: Vector2i = asteroid_layer.local_to_map(local_pos)

	var tile_id: int = asteroid_layer.get_cell_source_id(coords)
	if tile_id == -1:
		return

	asteroid_layer.erase_cell(coords)
	mined_sprite.visible = true
