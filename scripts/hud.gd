extends CanvasLayer

# Cesty k premenovaným Labelom
@onready var lbl_speed    = $SpeedMargin/SpeedPanel/SpeedValue
@onready var lbl_crystal  = $ResourceMargin/ResourcePanel/CrystalRow/CrystalValue
@onready var lbl_fuel     = $ResourceMargin/ResourcePanel/FuelRow/FuelValue
@onready var lbl_titanium = $ResourceMargin/ResourcePanel/TitaniumRow/TitaniumValue

var ship_ref: CharacterBody2D

# Nastaví referenciu na loď z Main-scény
func set_ship(ship: CharacterBody2D) -> void:
	ship_ref = ship

func _ready() -> void:
	# Pripojíme sa na zmeny inventára
	ResourceData.connect("inventory_changed", Callable(self, "_on_inventory_changed"))
	# Inicializujeme s počiatočnými hodnotami
	_update_speed(0.0)
	_update_resources({
		"crystal": 0,
		"fuel": 0,
		"titanium": 0
	})

func _process(_delta: float) -> void:
	if ship_ref:
		_update_speed(ship_ref.velocity.length())

func _on_inventory_changed(counts: Dictionary) -> void:
	_update_resources(counts)

func _update_speed(speed: float) -> void:
	lbl_speed.text = "Speed: %.1f m/s" % speed

func _update_resources(counts: Dictionary) -> void:
	lbl_crystal.text  = str(counts.get("crystal", 0))
	lbl_fuel.text     = str(counts.get("fuel",    0))
	lbl_titanium.text = str(counts.get("titanium",0))
