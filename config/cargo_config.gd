class_name CargoConfig
extends Node

# maximálna nosnosť CargoHold v kg
@export var max_capacity: float        = 1000.0

# hmotnosť prázdnej lode (bez nákladu) v kg
@export var empty_ship_weight: float   = 500.0

# maximálna multiplikácia spotreby (pri plnom holde)
@export var max_load_factor: float     = 2.0

# O koľko % sa zvýši spotreba main engine pri plnom holde (0.0 = bez vplyvu, 0.1 = +10%)
@export var fuel_main_load_factor: float     = 0.05
# O koľko % sa zvýši spotreba thrusters pri plnom holde
@export var fuel_thruster_load_factor: float = 0.05
# O koľko % spomalí rotáciu pri plnom holde (0.0 = bez vplyvu, 0.1 = –10%)
@export var rotation_load_factor: float      = 0.05
# O koľko % viac HP stratíš pri kolízii, ak máš plný hold (1.0 = bez vplyvu, 1.2 = +20% damage)
@export var collision_damage_multiplier: float = 1.2