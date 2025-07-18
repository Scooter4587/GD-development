extends Node

# 🌐 Globálne nastavenia pre asteroidy
const COLLISION_LAYER := 2
const COLLISION_MASK := 1

# 📦 Definície všetkých typov asteroidov
var asteroid_types = {
	"asteroid_1": {
		"name": "Basic Rock",
		"key": "rock",
		"minable": true,
		"hardness": 2,
		"volatile": false,
		"density": 0.8
	}
	# ďalšie asteroidy sem...
}

func _init():
	for type_key in asteroid_types.keys():
		asteroid_types[type_key]["collision_layer"] = COLLISION_LAYER
		asteroid_types[type_key]["collision_mask"] = COLLISION_MASK
