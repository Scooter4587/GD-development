# res://config/hull_config.gd
extends Resource
class_name HullConfig

@export var hull_max: float = 100.0                              # Maximálna integrita trupu (HP)      
@export var collision_damage_multiplier: float = 0.25            # (1.0 = 1 HP škody na jednotku nárazu, 2.0 = dvojnásobná citlivosť) # Násobiteľ poškodenia pri kolízii
@export var auto_repair_rate: float = 0.0                        # (0 = vypnuté, napr. 5.0 znamená 5 HP/s auto-oprava) # Rýchlosť automatickej opravy trupu (HP za sekundu)
@export var repair_cost_per_hp: float = 0.0                      # Náklady na opravu 1 HP (pre budúce ekonomické systémy)
@export var bounce_impulse_multiplier: float = 1                 # Odraz nárazu na asteroid
@export var axis_bounce_impulse_multiplier: float = 0.5          # odrazová sila pri osi‐zarovnaných nárazoch
@export var dock_repair_rate: float = 10.0                       # % hull_max za sekundu

# Treshold
@export var damage_threshold: float = 20.0                       # minimálna rýchlosť (m/s) na to, aby sa aplikuje damage
@export var invulnerability_duration: float = 0.2                # sekúnd, počas ktorých si imúnny po náraze

# --- 🚀 Bounce & kolízie ---
@export var bounce_impulse_multiplier_high: float = 1.0
@export var bounce_impulse_multiplier_low: float  = 0.5
@export var bounce_speed_threshold: float         = 100.0
@export var bounce_decay: float                   = 0.8
@export var bounce_reset_time: float              = 0.2