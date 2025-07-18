# 📂 File: main.gd
extends Node2D

@onready var speed_label = $CanvasLayer/SpeedLabel	# 📌 Prepojenie s HUD labelom na rýchlosť
@onready var ship = $Ship	# 🛸 Odkaz na loď
@onready var background = $ParallaxBackground/ParallaxLayer/Background	# 🪐 Pozadie vesmíru (Parallax efekt)
@onready var camera = $Ship/Camera2D	# 🎥 Kamera nasledujúca loď
@onready var MineItems = preload("res://scripts/mine_items.gd").new()	# 🧱 Dátový kontajner pre definície ťažiteľných surovín (náhrada za Autoload)


# --- 🧱 ASTEROIDY ---
var asteroid_tilemap_layer: TileMapLayer

# --- 💎 RESOURCES ---
var resource_tilemap_layer: TileMapLayer
var resource_crystal := 0
var resource_fuel := 0
var resource_titanium := 0

func _process(_delta):
	# 🧮 Získanie aktuálnej rýchlosti lode
	var speed = 0.0
	if ship.has_method("get_velocity"):
		speed = ship.get_velocity().length()
	elif "velocity" in ship:
		speed = ship.velocity.length()
	
	# 💬 Zobrazenie rýchlosti v HUD
	speed_label.text = "Speed: " + str(snapped(speed, 0.1)) + " m/s"

# 🔍 Získa názov suroviny podľa tile_id
func get_resource_name_from_tile(tile_id: int) -> String:
	if MineItems.tile_data.has(tile_id):
		return MineItems.tile_data[tile_id]
	return ""

# 📊 Získa všetky atribúty (napr. hardness, drillable) pre daný tile_id
func get_resource_properties(tile_id: int) -> Dictionary:
	var resource_name = get_resource_name_from_tile(tile_id)
	if resource_name != "" and MineItems.resources.has(resource_name):
		return MineItems.resources[resource_name]
	return {}

# ✅ Zistí, či je daný tile drillovateľný
func is_tile_drillable(tile_id: int) -> bool:
	var props = get_resource_properties(tile_id)
	return props.get("drillable", false)

func _ready():
	asteroid_tilemap_layer = $Asteroid1/Asteroid
	resource_tilemap_layer = $ResourcesManager/ResourceLayer

func add_resource(resource_type: String):
	match resource_type:
		"crystal":
			resource_crystal += 1
		"fuel":
			resource_fuel += 1
		"titanium":
			resource_titanium += 1
		_:
			print("❓ Unknown resource type:", resource_type)
