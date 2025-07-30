# 📂 File: mine_items.gd
extends Node 

const CargoItem = preload("res://scripts/CargoItem.gd")

signal inventory_changed(counts: Dictionary)
var _full_hold_warned: bool = false

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
		"value": 1,
		"weight_per_unit": 20.0,
		"max_stack": 100
	},
	"fuel": {
		"name": "Fuel",
		"drillable": true,
		"value": 1,
		"weight_per_unit": 10.0,
		"max_stack": 100
	},
	"crystal": {
		"name": "Crystal",
		"drillable": true,
		"value": 1,
		"weight_per_unit": 5.0,
		"max_stack": 100
	}
}

# 📦 Inventár – mapuje názov resource → množstvo
var inventory: Dictionary[String, int] = {}

func _ready() -> void:
	inventory.clear()
	for res_name in resource_defs.keys():
		inventory[res_name] = 0

func get_resource_name(tile_id: int) -> String:
	return tile_data.get(tile_id, "")

func get_resource_properties(tile_id: int) -> Dictionary:
	var res_name: String = get_resource_name(tile_id)
	return resource_defs.get(res_name, {})

func is_drillable(tile_id: int) -> bool:
	var props = get_resource_properties(tile_id)
	return props.get("drillable", false)

func add_resource(res_type: String, amount: int = 1) -> void:
	if inventory.has(res_type):
		inventory[res_type] += amount
		emit_signal("inventory_changed", inventory.duplicate())
	else:
		push_warning("Unknown resource type: %s" % res_type)

func get_amount(res_type: String) -> int:
	return inventory.get(res_type, 0)

# 🔨 Ťažíme: cargo_hold je povinný, amount je voliteľné
func mine_resource(tile_id: int, cargo_hold: Node, amount: int = 1) -> void:
	var res_name = get_resource_name(tile_id)
	if res_name == "":
		push_warning("Neznámy tile_id: %d" % tile_id)
		return

	var props = get_resource_properties(tile_id)
	var weight = props.get("weight_per_unit", 1.0)
	var max_stack = props.get("max_stack", 100)

	# 1) Vytvor CargoItem s definovanou váhou a stack limitom
	var item_res = CargoItem.new()
	item_res.name = res_name
	item_res.weight_per_unit = weight
	item_res.max_stack = max_stack

	# 2) Pokús sa pridať do CargoHold
	var leftover = cargo_hold.add_cargo(item_res, amount)
	var added = amount - leftover

	# 3) Do inventára len to, čo sa zmestilo
	if added > 0:
		inventory[res_name] += added
		emit_signal("inventory_changed", inventory.duplicate())

	# 4) Upozorni, ak sa niečo nezmestilo
	if leftover > 0:
		push_warning("%d × %s sa nezmestilo – hold je plný" % [leftover, res_name])

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

			var cell    = layer.local_to_map(layer.to_local(world_pos))
			var tile_id = layer.get_cell_source_id(cell)
			if tile_id != -1 and is_drillable(tile_id):
				var res_name = get_resource_name(tile_id)
				result[res_name] = result.get(res_name, 0) + 1
	return result


func mine_resource_by_name(res_name: String, cargo_hold: Node, amount: int = 1) -> void:
				if not inventory.has(res_name):
								push_warning("Neznámy resource type: %s" % res_name)
								return

				var props = resource_defs[res_name]
				var item  = CargoItem.new()
				item.name            = res_name
				item.weight_per_unit = props.weight_per_unit
				item.max_stack       = props.max_stack

				# Pokus o pridanie do CargoHold
				var leftover = cargo_hold.add_cargo(item, amount)
				var added    = amount - leftover

				# Ak sa niečo zmestilo, resetneme debounce flag
				if added > 0:
								inventory[res_name] += added
								emit_signal("inventory_changed", inventory.duplicate())
								_full_hold_warned = false

				# Ak sa niečo nezmestilo a ešte sme neupozornili, tak upozorníme raz
				if leftover > 0 and not _full_hold_warned:
								push_warning("%d × %s sa nezmestilo – hold je plný" % [leftover, res_name])
								_full_hold_warned = true
