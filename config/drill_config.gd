# res://config/drill_config.gd
extends Resource
class_name DrillConfig

@export var drill_speed_limit: float   = 50.0  # m/s
@export var drill_lock_duration: float = 1   # s medzi tile
@export var cooldown_time: float       = 0.2   # s medzi pokusmi
@export var drill_power: int           = 2
@export var drill_radius: float        = 50.0
@export var drill_offset_factor: float = 0.35
@export var tile_size: float           = 16.0