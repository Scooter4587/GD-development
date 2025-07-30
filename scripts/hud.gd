extends CanvasLayer

# Autoload singletons
@onready var stats        = get_node("/root/ShipStats")
@onready var cfg          = get_node("/root/ShipConfig")

# UI node references
@onready var lbl_speed    = $StatsMargin/SpeedPanel/SpeedValue
@onready var hull_bar     = $StatsMargin/StatusContainer/HullContainer/HullBar
@onready var hull_label   = $StatsMargin/StatusContainer/HullContainer/HullLabel
@onready var fuel_bar     = $StatsMargin/StatusContainer/FuelContainer/FuelBar
@onready var fuel_label   = $StatsMargin/StatusContainer/FuelContainer/FuelLabel
@onready var energy_bar   = $StatsMargin/StatusContainer/EnergyContainer/EnergyBar
@onready var energy_label = $StatsMargin/StatusContainer/EnergyContainer/EnergyLabel
@onready var cargo_bar    = $StatsMargin/StatusContainer/CargoContainer/CargoBar
@onready var cargo_label  = $StatsMargin/StatusContainer/CargoContainer/CargoLabel

# Reference to ship for retrieving data
var ship_ref
var displayed_energy: float = 2.0

func set_ship(ship) -> void:
	ship_ref = ship
	# fuel and energy signals
	if not ship_ref.is_connected("fuel_low", Callable(self, "_on_fuel_low")):
		ship_ref.connect("fuel_low", Callable(self, "_on_fuel_low"))
	if not ship_ref.is_connected("energy_low", Callable(self, "_on_energy_low")):
		ship_ref.connect("energy_low", Callable(self, "_on_energy_low"))
	# cargo weight signal
	if ship_ref.cargo_hold and not ship_ref.cargo_hold.is_connected("weight_changed", Callable(self, "_on_cargo_weight_changed")):
		ship_ref.cargo_hold.connect("weight_changed", Callable(self, "_on_cargo_weight_changed"))

func _ready() -> void:
	# Auto-assign ship_ref if not passed
	if ship_ref == null:
		ship_ref = get_node("/root/Main/Ship")

	# Hull signals
	stats.connect("hull_damaged",   Callable(self, "_on_hull_changed"))
	stats.connect("hull_restored",  Callable(self, "_on_hull_reset"))

	# Initial displays
	_update_speed(0.0)
	_setup_hull_bar()
	_setup_fuel_bar()
	_setup_energy_bar()
	_setup_cargo_bar()

	displayed_energy = ship_ref.cfg.energy.energy_current

func _process(_delta: float) -> void:
	if not ship_ref:
		return	
	
	# —– smooth UI pre energy bar —–
	var target_energy = ship_ref.cfg.energy.energy_current
	# delta*5 znamená, že za ~0.2 s sa displayed_energy priblíži na 99 % k target_energy
	displayed_energy = lerp(displayed_energy, target_energy, clamp(_delta * 5, 0, 1))
	energy_bar.value = cfg.energy.energy_current  
	_update_energy_style()

	# Speed
	_update_speed(ship_ref.velocity.length())
	# Fuel
	fuel_bar.value = ship_ref.fuel_current
	_update_fuel_style()
	# Energy
	#energy_bar.value = cfg.energy.energy_current    # read from ShipConfig energy  # correct path to energy
	#_update_energy_style()

# --- Cargo setup & callback ---
func _setup_cargo_bar() -> void:
	cargo_bar.min_value = 0
	cargo_bar.max_value = cfg.cargo.max_capacity
	var cw = ship_ref.cargo_hold.get_current_weight()
	cargo_bar.value    = cw
	cargo_label.text   = str(cw, " / ", cfg.cargo.max_capacity, " kg")

func _on_cargo_weight_changed(new_weight: float) -> void:
	cargo_bar.value   = new_weight
	cargo_label.text = str(new_weight, " / ", cfg.cargo.max_capacity, " kg")

# --- Speed display ---
func _update_speed(speed: float) -> void:
	lbl_speed.text = "Speed: %.1f m/s" % speed

# --- Hull setup & callbacks ---
func _setup_hull_bar() -> void:
	hull_bar.min_value = 0
	hull_bar.max_value = cfg.hull.hull_max
	hull_bar.value     = stats.hull_current
	hull_label.text    = "HULL"
	_update_hull_style()

func _on_hull_changed(_dmg: float) -> void:
	hull_bar.value = stats.hull_current
	_update_hull_style()

func _on_hull_reset() -> void:
	hull_bar.value = stats.hull_current
	_update_hull_style()

func _update_hull_style() -> void:
	var pct = stats.hull_current / cfg.hull.hull_max * 100
	var c = Color(0,1,0) if pct >= 70 else (Color(1,1,0) if pct >= 30 else Color(1,0,0))
	var sb = StyleBoxFlat.new()
	sb.bg_color = c
	hull_bar.add_theme_stylebox_override("fill", sb)

# --- Fuel setup & style ---
func _setup_fuel_bar() -> void:
	fuel_bar.min_value = 0
	fuel_bar.max_value = cfg.fuel.fuel_max
	fuel_bar.value     = ship_ref.fuel_current
	fuel_label.text    = "FUEL"
	_update_fuel_style()

func _on_fuel_low() -> void:
	fuel_bar.modulate = Color(1,0,0)

func _update_fuel_style() -> void:
	var thr = cfg.fuel.fuel_low_threshold * cfg.fuel.fuel_max
	var c = Color(1,0.5,0) if fuel_bar.value > thr else Color(1,0,0)
	var sb = StyleBoxFlat.new()
	sb.bg_color = c
	fuel_bar.add_theme_stylebox_override("fill", sb)

# --- Energy setup & style ---
func _setup_energy_bar() -> void:
	energy_bar.min_value = 0
	energy_bar.max_value = cfg.energy.energy_max
	energy_label.text    = "ENERGY"

func _on_energy_low() -> void:
	energy_bar.modulate = Color(1,0,0)

func _update_energy_style() -> void:
	# prah pre low‐energy
	var thr = cfg.energy.energy_low_threshold * cfg.energy.energy_max

	# svetlomodrá ak nad prahom, červená pod prahom
	var fill_color: Color = Color(0, 0.8, 1) if energy_bar.value > thr else Color(1, 0, 0)

	# override štýlu “fill” progress baru
	var sb = StyleBoxFlat.new()
	sb.bg_color = fill_color
	energy_bar.add_theme_stylebox_override("fill", sb)

	# reset akýkoľvek predchádzajúci modulate (napr. z flash efek­tu)
	energy_bar.modulate = Color(1, 1, 1)
