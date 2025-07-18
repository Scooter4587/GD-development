extends Node

# 🌐 Globálne nastavenia kolízií
const COLLISION_LAYER: int = 2
const COLLISION_MASK: int = 1

# 📦 Definície typov asteroidov (bez hardness, volatile, density)
@export var asteroid_types: Dictionary[String, Dictionary] = {
	"asteroid_1": {
		"name": "Basic Rock",
		"key": "rock",
		"minable": true,
		"collision_layer": COLLISION_LAYER,
		"collision_mask": COLLISION_MASK
	}
	# → sem môžeš pridávať ďalšie typy
}

# 🔍 Vracia dáta pre daný typ (alebo prázdny dict, ak kľúč neexistuje)
func get_properties(type_key: String) -> Dictionary:
	return asteroid_types.get(type_key, {})
