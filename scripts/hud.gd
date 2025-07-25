extends CanvasLayer

# Autoload singletons
@onready var stats      = get_node("/root/ShipStats")
@onready var config     = get_node("/root/ShipConfig")

# Cesty k premenovaným Labelom
@onready var lbl_speed    = $StatsMargin/SpeedPanel/SpeedValue
@onready var lbl_crystal  = $ResourceMargin/ResourcePanel/CrystalRow/CrystalValue
@onready var lbl_fuel     = $ResourceMargin/ResourcePanel/FuelRow/FuelValue
@onready var lbl_titanium = $ResourceMargin/ResourcePanel/TitaniumRow/TitaniumValue

# Nový HullBar v spodnej strede
@onready var hull_bar     = $StatsMargin/StatusContainer/HullContainer/HullBar

var ship_ref: CharacterBody2D

# Nastaví referenciu na loď z Main-scény
func set_ship(ship: CharacterBody2D) -> void:
	ship_ref = ship

func _ready() -> void:

	# Nastavíme referenciu na loď
	# hud.set_ship(ship)  # ak to tu ešte nemáš

	# Pripojíme sa na zmeny inventára
	ResourceData.connect("inventory_changed", Callable(self, "_on_inventory_changed"))

	 # Signály pre hull
	stats.connect("hull_damaged",   Callable(self, "_on_hull_changed"))
	stats.connect("hull_destroyed", Callable(self, "_on_hull_changed"))
	stats.connect("hull_restored",  Callable(self, "_on_hull_reset"))

	# Inicializujeme speed a resources
	_update_speed(0.0)
	_update_resources({
		"crystal": 0,
		"fuel": 0,
		"titanium": 0
	})

	# --- Inicializácia HullBar ---
	hull_bar.min_value = 0
	hull_bar.max_value = config.hull.hull_max
	hull_bar.value     = stats.hull_current

	# Nastavíme počiatočnú farbu
	_update_hull_bar_color()

func _process(_delta: float) -> void:
	# Speed update
	if ship_ref:
		_update_speed(ship_ref.velocity.length())

# Inventár
func _on_inventory_changed(counts: Dictionary) -> void:
	_update_resources(counts)

func _update_speed(speed: float) -> void:
	lbl_speed.text = "Speed: %.1f m/s" % speed

func _update_resources(counts: Dictionary) -> void:
	lbl_crystal.text  = str(counts.get("crystal", 0))
	lbl_fuel.text     = str(counts.get("fuel", 0))
	lbl_titanium.text = str(counts.get("titanium", 0))

# Hull handlers
func _on_hull_changed(_dmg: float) -> void:
	# Aktualizujeme hodnotu aj farbu
	hull_bar.value = stats.hull_current
	_update_hull_bar_color()
	# Bliknutie pre upozornenie (voliteľné)
	hull_bar.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.2).timeout
	hull_bar.modulate = Color(1, 1, 1)

func _on_hull_reset() -> void:
	hull_bar.value = stats.hull_current
	_update_hull_bar_color()

	# Funkcia, ktorá sprehľadní výpočet a override štýlu
func _update_hull_bar_color() -> void:
	var pct = stats.hull_current / config.hull.hull_max * 100
	var color: Color
	if pct >= 70.0:
		color = Color(0, 1, 0)       # zelená
	elif pct >= 30.0:
		color = Color(1, 1, 0)       # žltá
	else:
		color = Color(1, 0, 0)       # červená

	# Vytvoríme nový StyleBoxFlat a prepíšeme „fill“ štýl
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	hull_bar.add_theme_stylebox_override("fill", sb)
