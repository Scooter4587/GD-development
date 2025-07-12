extends Node2D

# odkaz na label
@onready var speed_label = $CanvasLayer/SpeedLabel

# odkaz na loď
@onready var ship = $Ship  # ak tvoja loď sa volá inak alebo je v podnode, uprav cestu

@onready var background = $BackgroundSprite
@onready var camera = $Ship/Camera2D  # uprav podľa tvojej štruktúry


### Frame aktualizácia pozadia a UI
# Aktualizuje rýchlosť v HUD a posúva pozadie podľa pozície kamery

func _process(_delta):
	# rýchlosť = veľkosť velocity vektora
	var speed = ship.velocity.length()
	speed_label.text = "Speed: " + str(snapped(speed, 0.1)) + " m/s"
	background.global_position = camera.global_position
	
