extends Node

@onready var cfg = ShipConfig

# Signály pre HUD / iné systémy
signal hull_damaged(damage_amount: float)
signal hull_destroyed(damage_amount: float)
signal hull_restored 

var is_repairing: bool = false

# Runtime premenné
var hull_current: float
var fuel_current: float
var energy_current: float
var cargo_weight_current: float
var heat_current: float

func _ready() -> void:
	# Počkám na kompletne pripravený strom pred resetom,
	# aby cfg.hull určite nebol null.
	call_deferred("reset")

func _process(delta: float) -> void:
	# (voliteľné) Auto-repair
	if cfg.hull.auto_repair_rate > 0.0 and hull_current < cfg.hull.hull_max:
		repair_hull(cfg.hull.auto_repair_rate * delta)

	# Pasívna oprava na stanici
	if is_repairing:
		# dock_repair_rate je percento z hull_max za sekundu
		var amount = cfg.hull.dock_repair_rate / 100.0 * cfg.hull.hull_max * delta
		repair_hull(amount)

func reset() -> void:
	hull_current       = cfg.hull.hull_max
	fuel_current       = cfg.fuel.fuel_max
	energy_current     = cfg.energy.energy_max
	cargo_weight_current = 0
	heat_current       = 0
	

## Aplikuje poškodenie trupu
func apply_hull_damage(amount: float) -> void:
	var dmg = amount * cfg.hull.collision_damage_multiplier
	hull_current = max(hull_current - dmg, 0)
	emit_signal("hull_damaged", dmg)
	if hull_current <= 0:
		emit_signal("hull_destroyed", dmg)

## Opraví trup o zadanú hodnotu
func repair_hull(amount: float) -> void:
	hull_current = min(hull_current + amount, cfg.hull.hull_max)

func start_repair() -> void:
	is_repairing = true

func stop_repair() -> void:
	is_repairing = false

func restore_full_hull() -> void:
	hull_current = cfg.hull.hull_max
	emit_signal("hull_restored")
