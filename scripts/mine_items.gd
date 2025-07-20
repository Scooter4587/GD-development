extends Node 

signal inventory_changed(counts: Dictionary)

# 📂 File: mine_items.gd
# Tento skript spravuje definície a inventár surovín.

# 🔢 Mapa tile_id → názov resource (exportované pre ľahké rozšírenie v editore)
@export var tile_data: Dictionary[int, String] = {
	0: "crystal",
	1: "fuel",
	2: "titanium"
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
	# Inicializujeme inventár so všetkými typmi surovín na 0
	inventory.clear()
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
		# po aktualizácii inventára
		emit_signal("inventory_changed", inventory.duplicate())
	else:
		push_warning("Unknown resource type: %s" % res_type)

# 📊 Vráti aktuálne množstvo v inventári (0, ak neexistuje)
func get_amount(res_type: String) -> int:
	return inventory.get(res_type, 0)

# Vráti mapu resource_type → počet dlaždíc, ktoré by sa dali vŕtať v danej oblasti
func count_resources_in_region(
		layer: TileMapLayer,
		center: Vector2,
		forward: Vector2,
		right: Vector2,
		w: int,
		h: int,
		tile_size: float
	) -> Dictionary:
	var result: Dictionary[String, int] = {}
	for i in range(w):
		var side_offset = (i - (w - 1) / 2.0) * tile_size
		for j in range(h):
			var front_offset = j * tile_size
			var world_pos    = center + right * side_offset + forward * front_offset

			# 1) Prevod na súradnice buniek
			var cell    = layer.local_to_map(layer.to_local(world_pos))
			# 2) Získanie source ID (–1 = prázdna bunka)
			var tile_id = layer.get_cell_source_id(cell)
			# 3) Ak je drillable, zvýšíme počítadlo
			if tile_id != -1 and is_drillable(tile_id):
				var res_name = get_resource_name(tile_id)
				result[res_name] = result.get(res_name, 0) + 1
	return result
