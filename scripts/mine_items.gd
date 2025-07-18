# 📂 File: mine_items.gd
extends Node2D

# 🔢 Mapa tile_id → názov resource (používame v TileMap)
var tile_data = {
	0: "titanium",
	1: "fuel",
	2: "crystal"
}

# 🧊 Definície jednotlivých surovín
var crystal = {
	"name": "Crystal",
	"drillable": true,
	"value": 1,
	"volatile": false,
	"hardness": 2
}

var fuel = {
	"name": "Fuel",
	"drillable": true,
	"value": 1,
	"volatile": true,
	"hardness": 1
}

var titanium = {
	"name": "Titanium",
	"drillable": true,
	"value": 1,
	"volatile": false,
	"hardness": 3
}

# 📦 Kolekcia všetkých surovín (prístup cez string)
var resources = {
	"crystal": crystal,
	"fuel": fuel,
	"titanium": titanium
}

# ⚙️ Voliteľné globálne nastavenia pre všetky suroviny
var resource_settings = {
	"category": "minable",
	"can_be_traded": true,
	"default_drill_speed": 1.0
}
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
