extends CharacterBody2D

@onready var sprite_base = $SpriteBase
@onready var sprite_thrust = $SpriteThrust
@export var drill_speed_limit := 100.0

var acceleration := 400.0
var rotation_speed := 4.0
var desired_direction := Vector2.ZERO
var rotate_threshold := 0.1
var drill_active := false
var last_drill_state = false
var last_asteroid_drilled = null

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

	# Drill vstup – len pri zmene stavu
	var current_drill = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if current_drill != last_drill_state:
		print("🔦 Drill active:", current_drill)
		last_drill_state = current_drill
	drill_active = current_drill


func _physics_process(delta):
	move_and_slide()
	check_drill_collision()


func check_drill_collision():
	var areas = $DrillDetector.get_overlapping_areas()
	for area in areas:
		var asteroid_node = area.get_parent()
		if asteroid_node.name.begins_with("Asteroid"):
			var speed = velocity.length()
			if drill_active and speed <= drill_speed_limit:
				# Získame TileMapLayer s názvom "Asteroid"
				var tilemap_layer = asteroid_node.get_node("Asteroid")

				# Prepočítame pozíciu detektora na tile súradnice
				var tile_pos = tilemap_layer.local_to_map($DrillDetector.global_position)

				# Vymažeme tile v danej pozícii
				tilemap_layer.set_cell(0, tile_pos, -1)  # 0 = layer index, -1 = prázdny tile
