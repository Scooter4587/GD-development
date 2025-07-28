extends CanvasLayer

# Autoload singletons
@onready var stats  = get_node("/root/ShipStats")
@onready var config = get_node("/root/ShipConfig")

# UI node references
@onready var lbl_speed  = $StatsMargin/SpeedPanel/SpeedValue
@onready var hull_bar   = $StatsMargin/StatusContainer/HullContainer/HullBar
@onready var hull_label = $StatsMargin/StatusContainer/HullContainer/HullLabel
@onready var fuel_bar   = $StatsMargin/StatusContainer/FuelContainer/FuelBar
@onready var fuel_label = $StatsMargin/StatusContainer/FuelContainer/FuelLabel

# Reference to ship for retrieving data
var ship_ref

func set_ship(ship) -> void:
	ship_ref = ship
	if not ship_ref.is_connected("fuel_low", Callable(self, "_on_fuel_low")):
		ship_ref.connect("fuel_low", Callable(self, "_on_fuel_low"))

func _ready() -> void:
	# Auto-assign ship_ref if not set in main scene
	if ship_ref == null:
		ship_ref = get_node("/root/Main/Ship")
		if not ship_ref.is_connected("fuel_low", Callable(self, "_on_fuel_low")):
			ship_ref.connect("fuel_low", Callable(self, "_on_fuel_low"))

	# Hull signal connections
	stats.connect("hull_damaged",   Callable(self, "_on_hull_changed"))
	stats.connect("hull_destroyed", Callable(self, "_on_hull_changed"))
	stats.connect("hull_restored",  Callable(self, "_on_hull_reset"))

	# Initial speed display
	_update_speed(0.0)

	# HullBar setup
	hull_bar.min_value = 0
	hull_bar.max_value = config.hull.hull_max
	hull_bar.value     = stats.hull_current
	hull_label.text    = "HULL"
	_update_hull_bar_color()

	# FuelBar setup
	fuel_bar.min_value = 0
	fuel_bar.max_value = config.fuel.fuel_max
	fuel_bar.value     = ship_ref.fuel_current
	fuel_label.text    = "FUEL"
	_update_fuel_bar_color()

func _process(_delta: float) -> void:
	if ship_ref:
		# Update speed
		_update_speed(ship_ref.velocity.length())
		# Update fuel bar and color
		fuel_bar.value = ship_ref.fuel_current
		_update_fuel_bar_color()

func _update_speed(speed: float) -> void:
	lbl_speed.text = "Speed: %.1f m/s" % speed

# --- Hull callbacks and styling ---
func _on_hull_changed(_dmg: float) -> void:
	hull_bar.value = stats.hull_current
	_update_hull_bar_color()
	# flash red on damage
	hull_bar.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.2).timeout
	hull_bar.modulate = Color(1, 1, 1)

func _on_hull_reset() -> void:
	hull_bar.value = stats.hull_current
	_update_hull_bar_color()

func _update_hull_bar_color() -> void:
	var pct = stats.hull_current / config.hull.hull_max * 100
	var bar_color: Color = Color(0,1,0) if pct >= 70.0 else (Color(1,1,0) if pct >= 30.0 else Color(1,0,0))
	var sb = StyleBoxFlat.new()
	sb.bg_color = bar_color
	hull_bar.add_theme_stylebox_override("fill", sb)

# --- Fuel low indication and styling ---
func _on_fuel_low() -> void:
	fuel_bar.modulate = Color(1, 0, 0)

func _update_fuel_bar_color() -> void:
	var threshold = config.fuel.fuel_low_threshold * config.fuel.fuel_max
	var color: Color = Color(1,0.5,0) if fuel_bar.value > threshold else Color(1,0,0)
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	fuel_bar.add_theme_stylebox_override("fill", sb)
