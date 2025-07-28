extends Resource
class_name FuelConfig

# --- 🔋 Fuel systém ---
@export var fuel_max: float                 = 1000.0 # L
@export var fuel_low_threshold: float       = 0.3   # relatívny prah (15%)
@export var fuel_main_engine_per_sec: float = 10.0   # L/s pri hlavnom motore
@export var fuel_thrusters_per_sec: float   = 1.0    # L/s pri thrusteroch
#@export var fuel_warp_per_use: float = 50.0