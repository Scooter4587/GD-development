extends Node2D

@onready var speed_label = $CanvasLayer/SpeedLabel
@onready var ship = $Ship
@onready var background = $ParallaxBackground/ParallaxLayer/Background
@onready var camera = $Ship/Camera2D

func _process(_delta):
	# ochrana proti chýbajúcemu velocity
	var speed = 0.0
	if ship.has_method("get_velocity"):
		speed = ship.get_velocity().length()
	elif "velocity" in ship:
		speed = ship.velocity.length()

	speed_label.text = "Speed: " + str(snapped(speed, 0.1)) + " m/s"
