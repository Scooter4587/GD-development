extends Node2D

# odkazy na sprity
@onready var sprite_base = $SpriteBase
@onready var sprite_thrust = $SpriteThrust

# fyzika
var velocity := Vector2.ZERO
var acceleration := 400.0
var rotation_speed := 4.0
var desired_direction := Vector2.ZERO
var rotate_threshold := 0.1  # v radiánoch – menšie číslo = presnejšia otočka


### Ovládanie lode
# Spracúva vstupy z klávesnice (WASD) a určuje smer akcelerácie

func _process(delta):
	var input_x = 0
	var input_y = 0

	if Input.is_action_pressed("move_left"):
		input_x -= 1
	if Input.is_action_pressed("move_right"):
		input_x += 1
	if Input.is_action_pressed("move_up"):
		input_y -= 1
	if Input.is_action_pressed("move_down"):
		input_y += 1

	var input_dir = Vector2(input_x, input_y)

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		desired_direction = input_dir

		# Zisti uhol do ktorého sa má otočiť
		var target_angle = desired_direction.angle()
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

		# Spoľahlivý rozdiel uhlov s wrapf
		var angle_diff = abs(wrapf(rotation - target_angle, -PI, PI))

		# Debug pre testovanie uhla – môžeš zmazať neskôr
		# print("Angle diff: ", angle_diff)

		if angle_diff < rotate_threshold:
			velocity += desired_direction * acceleration * delta
			sprite_base.visible = false
			sprite_thrust.visible = true
		else:
			sprite_base.visible = true
			sprite_thrust.visible = false
	else:
		sprite_base.visible = true
		sprite_thrust.visible = false

	position += velocity * delta
