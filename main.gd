extends Node2D

@onready var ship = $Ship
@onready var hud  = $HUD

func _ready() -> void:
	hud.set_ship(ship)
