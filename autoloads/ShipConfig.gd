extends Node
# (nepíš tu class_name, aby sa nešklbalo s autoloadom)

@onready var hull   : HullConfig   = preload("res://config/hull_config.gd").new()
@onready var fuel   : FuelConfig   = preload("res://config/fuel_config.gd").new()
@onready var energy : EnergyConfig = preload("res://config/energy_config.gd").new()
@onready var cargo  : CargoConfig  = preload("res://config/cargo_config.gd").new()
@onready var heat   : HeatConfig   = preload("res://config/heat_config.gd").new()
@onready var drill  : DrillConfig  = preload("res://config/drill_config.gd").new()

# --- pohyb a rotácia ---
@export var max_speed: float            = 300.0   # normálna maximálna rýchlosť
@export var brake_speed: float          = 50.0    # brzdenie v realistickom režime
@export var arc_brake_speed: float      = 150.0   # brzdenie v arkádovom režime
@export var arc_rotation_speed: float   = 2.0     # rotácia v arkádovom režime (rad/s)
@export var rotation_speed_real: float  = 2.0     # rotácia v realistickom režime (rad/s)
@export var require_rotation_alignment: bool = true
@export var stop_thrust_on_rotate: bool      = true


func _ready() -> void:
	print(">> ShipConfig ready: hull_max =", hull.hull_max)
