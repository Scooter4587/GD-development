extends Node2D

# 📦 Odkaz na súbor s definíciami asteroidov
@onready var Asteroids = preload("res://scripts/asteroids_data.gd").new()

# 🧱 Vrstva pre tiles asteroidov
@onready var asteroid_layer = $Asteroid
# ⛏️ Vrstva pre už vyťažené tiles
@onready var mined_layer = $AsteroidMined

# 🌑 Typ tohto asteroidu (napr. "asteroid_1", ...)
@export var asteroid_type: String = "asteroid_1"

# 💾 Premenná pre vlastnosti z definícií
var asteroid_data: Dictionary = {}

# ✅ Inicializácia po načítaní scény
func _ready():
	if Asteroids.asteroid_types.has(asteroid_type):
		asteroid_data = Asteroids.asteroid_types[asteroid_type]
	else:
		push_error("Neznámy asteroid_type: " + asteroid_type)
		asteroid_data = {}
	
# 🔍 Získaj vlastnosti tohto asteroidu
func get_properties() -> Dictionary:
	return asteroid_data

# 🔍 Zistí, či sa dá vrtákom ťažiť
func is_drillable() -> bool:
	return asteroid_data.get("hardness", 0) <= 3  # príkladový prah

# 🔍 Poistka v prípade chýbajúch collision rules
func get_collision_layer() -> int:
	return asteroid_data.get("collision_layer", 2)

func get_collision_mask() -> int:
	return asteroid_data.get("collision_mask", 1)

func drill_at(world_pos: Vector2, drill_power: int):
	if asteroid_data.get("hardness", 0) > drill_power:
		print("❌ Tvrdosť asteroidu je príliš vysoká!")
		return

	var coords = asteroid_layer.local_to_map(to_local(world_pos))
	if asteroid_layer.get_cell_source_id(coords) == -1:
		#print("🕳️ Prázdna bunka, nič na vŕtanie")
		return

	#print("✅ Tile zničená na:", coords)
	asteroid_layer.set_cell(coords, -1)
	mined_layer.set_cell(coords, 0)


#@onready var asteroid_layer = $Asteroid
#@onready var mined_layer = $AsteroidMined

#var is_tile_drilled := {}

#func drill_at_tile(world_pos: Vector2) -> void:
#	var tilemap_global_transform = asteroid_layer.get_global_transform()
#	var local_pos: Vector2 = tilemap_global_transform.affine_inverse() * world_pos
#	var center_coords: Vector2i = asteroid_layer.local_to_map(local_pos)
#
#	var offsets = [
#		Vector2i(0, 0),
#		Vector2i(1, 0),
#		Vector2i(-1, 0),
#		Vector2i(0, 1),
#		Vector2i(0, -1),
#		Vector2i(1, 1),
#		Vector2i(-1, -1)
#	]
#
#	for offset in offsets:
#		var tile_coords = center_coords + offset
#		var tile_data = asteroid_layer.get_cell_tile_data(tile_coords)
#		if tile_data != null and not is_tile_drilled.get(tile_coords, false):
#			print("✅ TILE ZNIČENÁ:", tile_coords)
#			asteroid_layer.set_cell(tile_coords, -1)
#			mined_layer.set_cell(tile_coords, 0)
#			is_tile_drilled[tile_coords] = true
#			return
#
#	# Žiadna vhodná tile nebola nájdená – nebudeme viac spamovať
