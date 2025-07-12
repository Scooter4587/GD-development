extends Node2D

# rýchlosť pohybu
var speed := 200.0

# rýchlosť otáčania (ako rýchlo sa natočí smerom k cieľu)
var rotation_speed := 8.0

func _process(delta):
	# výpočet smeru pohybu
	var movement := Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		movement.y -= 1
	if Input.is_action_pressed("move_down"):
		movement.y += 1
	if Input.is_action_pressed("move_left"):
		movement.x -= 1
	if Input.is_action_pressed("move_right"):
		movement.x += 1

	if movement.length() > 0:
		movement = movement.normalized()

		# vypočítaj cieľový uhol smeru
		var target_angle = movement.angle()

		# postupne natoč loď smerom k cieľu
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

		# aplikuj pohyb podľa aktuálneho smeru
		position += movement * speed * delta
