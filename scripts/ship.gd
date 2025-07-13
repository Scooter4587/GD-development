extends CharacterBody2D  # 🔁 opravene z Node2D

@onready var sprite_base = $SpriteBase
@onready var sprite_thrust = $SpriteThrust
@export var drill_speed_limit := 50.0

var acceleration := 400.0
var rotation_speed := 4.0
var desired_direction := Vector2.ZERO
var rotate_threshold := 0.1
var drill_active := false

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

		var target_angle = desired_direction.angle()
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

		var angle_diff = abs(wrapf(rotation - target_angle, -PI, PI))

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

	drill_active = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	position += velocity * delta  # zatiaľ OK, ale neskôr move_and_slide

func _physics_process(delta):
	check_drill_collision()

func check_drill_collision():
	for area in $DrillDetector.get_overlapping_areas():
		var asteroid = area.get_parent()
		if asteroid.is_in_group("asteroid"):
			var speed = velocity.length()
			if drill_active and speed <= drill_speed_limit:
				asteroid.drill()
			else:
				print("💥 Crash! Too fast or drill not active.")
