extends Resource
class_name EnergyConfig

# --- 🔋 Battery Settings ---
@export var energy_max: float            = 1000.0
@export var energy_low_threshold: float  = 0.15
var energy_current: float                 = energy_max

# --- ⚛ Reactor Settings ---
@export var reactor_output_per_sec: float = 200.0

# --- 🔧 Energy Consumption Rates ---
@export var energy_cost_drill_per_sec: float = 300.0
# @export var energy_cost_sonar_per_sec: float = 0.0
# @export var energy_cost_sonar_per_use: float = 50.0

# --- ⏱️ Shutdown Settings ---
@export var shutdown_duration: float = 3.0    # sekundy, počas ktorých je loď vypnutá
var is_shutdown: bool    = false               # či je aktuálne shutdown
var shutdown_timer: float = 0.0 
@export var restart_threshold: float = 0.5   # 50 %  

# --- 🔋 Energy Settings ---
func _init():
				energy_current = energy_max

func consume_drill(delta: float) -> void:
				energy_current = max(energy_current - energy_cost_drill_per_sec * delta, 0)

func regenerate(delta: float) -> void:
				energy_current = min(energy_current + reactor_output_per_sec * delta, energy_max)

func is_low() -> bool:
				return energy_current <= energy_max * energy_low_threshold