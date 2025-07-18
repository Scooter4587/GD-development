# 📂 File: mine_items.gd
# Tento skript spravuje definície a inventár surovín.

extends Node

# 🔢 Mapa tile_id → názov resource (exportované pre ľahké rozšírenie v editore)
@export var tile_data: Dictionary[int, String] = {
	0: "titanium",
	1: "fuel",
	2: "crystal"
}

# 🧱 Definície vlastností jednotlivých surovín (exportované pre úpravy v editore)
@export var resource_defs: Dictionary[String, Dictionary] = {
	"titanium": {
		"name": "Titanium",
		"drillable": true,
		"value": 1
	},
	"fuel": {
		"name": "Fuel",
		"drillable": true,
		"value": 1
	},
	"crystal": {
		"name": "Crystal",
		"drillable": true,
		"value": 1
	}
}

# 📦 Inventár – mapuje názov resource → množstvo
var inventory: Dictionary[String, int] = {}

func _ready() -> void:
	# Inicializujeme inventár so všemožnými typmi surovín na 0
	for res_name in resource_defs.keys():
		inventory[res_name] = 0

# 🔍 Vráti názov resource pre dané tile_id (alebo prázdny string)
func get_resource_name(tile_id: int) -> String:
	return tile_data.get(tile_id, "")

# 🔍 Získa vlastnosti resource podľa tile_id (alebo prázdny dict)
func get_resource_properties(tile_id: int) -> Dictionary:
	var res_name: String = get_resource_name(tile_id)
	return resource_defs.get(res_name, {})

# 🔍 Overí, či sa tile s daným ID dá vyvŕtať
func is_drillable(tile_id: int) -> bool:
	var props = get_resource_properties(tile_id)
	return props.get("drillable", false)

# ➕ Pridá množstvo do inventáru (varuje pri neznámom type)
func add_resource(res_type: String, amount: int = 1) -> void:
	if inventory.has(res_type):
		inventory[res_type] += amount
	else:
		push_warning("Unknown resource type: " + res_type)

# 📊 Vráti aktuálne množstvo v inventári (0, ak neexistuje)
func get_amount(res_type: String) -> int:
	return inventory.get(res_type, 0)


#var titanium := 0
#var fuel := 0
#var crystal := 0

#func add_resource(resource_type: String, amount: int = 1):
#	match resource_type:
#		"titanium": titanium += amount
#		"fuel": fuel += amount
#		"crystal": crystal += amount
#	print("Collected ", resource_type, " → Total: ", get(resource_type))

#func get_amount(resource_type: String) -> int:
#	match resource_type:
#		"titanium":
#			return titanium
#		"fuel":
#			return fuel
#		"crystal":
#			return crystal
#		_:
#			return 0
