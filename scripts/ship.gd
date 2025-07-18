extends CharacterBody2D

# --- 🔧 KONŠTANTY ---
const MAX_SPEED := 500.0             # Maximálna rýchlosť lode (m/s)
const STOP_FORCE := 100.0            # Brzdiaca sila pri full-stop (m/s²)
const ROTATION_SPEED := 3          # Rýchlosť rotácie (rad/s)
const DRILL_SPEED_LIMIT := 50.0      # Rýchlosť pre aktiváciu vrtáka (m/s)

# --- 🚀 PREMENNÉ POHYBU ---
var acceleration: float = 400.0         # Zrýchlenie dopredu
var deceleration_rate: float = 300.0    # Spomalenie (full stop)
var desired_direction: Vector2 = Vector2.ZERO
var input_buffer: Vector2 = Vector2.ZERO
var drill_lock_timer: float = 0.0  # ⏳ čas po vŕtaní, počas ktorého udržiavame max speed

# --- 🔁 ROTÁCIA ---
var rotate_threshold: float = 0.1

# --- ⛔ STAVY ---
var full_stop_enabled: bool = false
var drill_mode: bool = false   # Bude sa riešiť neskôr
var last_drill_input := false

# --- 📦 ODKAZY NA NODY ---
@onready var sprite_base = $SpriteBase
@onready var sprite_thrust = $SpriteThrust

# Režim pohybu: true = realistický (zrýchlenie až po otočení), false = arkádový
@export var require_rotation_alignment := true
@onready var drill_tool := $DrillTool  # Ak sa volá takto
@export var drill_lock_duration := 1.5

# --- 🚀 Hlavný update pohybu ---
func _physics_process(delta):
	handle_input()
	handle_rotation(delta)
	handle_movement(delta)
	handle_drill_lock_input()
	update_thrust_sprite()
	move_and_slide()
	

# --- 🔥 Animácia trysky ---
func update_thrust_sprite():
	var is_thrusting = not full_stop_enabled and desired_direction != Vector2.ZERO and velocity.length() > 5.0
	sprite_thrust.visible = is_thrusting
	sprite_base.visible = not is_thrusting

# --- 🎮 Spracovanie vstupov ---
func handle_input():
	var new_input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

	input_buffer = new_input

	# Prepínač full stopu
	if Input.is_action_just_pressed("full_stop"):
		full_stop_enabled = true
	elif Input.is_action_just_released("full_stop"):
		full_stop_enabled = false

	# Prepínač medzi režimami
	if Input.is_action_just_pressed("toggle_movement_mode"):
		require_rotation_alignment = not require_rotation_alignment
		print("Režim pohybu: ", "Realistický" if require_rotation_alignment else "Arkádový")


# --- 🔁 Rotácia smerom k požadovanému smeru ---
func handle_rotation(delta):
	if input_buffer != Vector2.ZERO:
		var target_angle := input_buffer.angle()
		rotation = lerp_angle(rotation, target_angle, ROTATION_SPEED * delta)

		# Ak sme takmer otočení na požadovaný smer, aktualizuj desired_direction
		var angle_diff: float = abs(wrapf(rotation - target_angle, -PI, PI))
		if angle_diff < rotate_threshold:
			desired_direction = input_buffer
	else:
		# ✅ Resetuj smer keď nie je vstup
		desired_direction = Vector2.ZERO	

# --- 🚗 Fyzika pohybu ---
func handle_movement(delta):
	if full_stop_enabled:
		if velocity.length() > 1:
			velocity = velocity.move_toward(Vector2.ZERO, deceleration_rate * delta)
		else:
			velocity = Vector2.ZERO

	elif desired_direction != Vector2.ZERO:
		var target_angle: float = desired_direction.angle()
		var angle_diff: float = abs(wrapf(rotation - target_angle, -PI, PI))

		if require_rotation_alignment:
			if angle_diff < rotate_threshold:
				velocity += desired_direction * acceleration * delta
		else:
			velocity += desired_direction * acceleration * delta

	# --- 🛠️ Limitovanie rýchlosti počas vŕtania alebo cooldown ---
	var is_drilling := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if drill_lock_timer > 0.0:
		drill_lock_timer -= delta

	if drill_lock_timer > 0.0 or is_drilling:
		if velocity.length() > DRILL_SPEED_LIMIT:
			velocity = velocity.normalized() * DRILL_SPEED_LIMIT

func handle_drill_lock_input():
	var current_input = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if not current_input and last_drill_input:
		# Drill práve prestal byť držaný – spusti cooldown
		drill_lock_timer = drill_lock_duration
		#print("🛑 Drill release → LOCK aktivovaný")

	last_drill_input = current_input

	# --- 🛠️ Automatické udržiavanie rýchlosti počas vŕtania ---
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and drill_tool.drill_ready and drill_tool.is_in_contact_with_asteroid:
	#	var target_speed = DRILL_SPEED_LIMIT
	#	var direction = transform.x.normalized()
	#	var current_speed = velocity.dot(direction)
	#	var speed_diff = target_speed - current_speed
	#
	#	if abs(speed_diff) > 1.0:
	#		var adjustment_force = 400.0  # silnejšie tlačenie dopredu
	#		velocity += direction * speed_diff * adjustment_force * delta
	#
	#	# Prísne obmedzenie maximálnej rýchlosti počas vŕtania
	#	if velocity.length() > target_speed:
	#		velocity = velocity.normalized() * target_speed




#@onready var sprite_base = $SpriteBase
#@onready var sprite_thrust = $SpriteThrust
#@export var drill_speed_limit := 100.0
#@onready var asteroid_node = get_node("/root/Main/Asteroid1")  # uprav podľa tvojej scény
#@onready var resource_manager = get_node("/root/Main/ResourcesManager")

#var acceleration := 400.0
#var rotation_speed := 4.0
#var desired_direction := Vector2.ZERO
#var rotate_threshold := 0.1
#var drill_active := false
#var last_drill_state = false
#var last_asteroid_drilled = null



#func _process(delta):
#	var input_x = 0
#	var input_y = 0
#
#	if Input.is_action_pressed("move_left"):
#		input_x -= 1
#	if Input.is_action_pressed("move_right"):
#		input_x += 1
#	if Input.is_action_pressed("move_up"):
#		input_y -= 1
#	if Input.is_action_pressed("move_down"):
#		input_y += 1

#	var input_dir = Vector2(input_x, input_y)

#	if input_dir != Vector2.ZERO:
#		input_dir = input_dir.normalized()
#		desired_direction = input_dir

#		var target_angle = desired_direction.angle()
#		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

#		var angle_diff = abs(wrapf(rotation - target_angle, -PI, PI))

#		if angle_diff < rotate_threshold:
#			velocity += desired_direction * acceleration * delta
#			sprite_base.visible = false
#			sprite_thrust.visible = true
#		else:
#			sprite_base.visible = true
#			sprite_thrust.visible = false
#	else:
#		sprite_base.visible = true
#		sprite_thrust.visible = false

	# Drill vstup – len pri zmene stavu
#	var current_drill = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
#	if current_drill != last_drill_state:
#		print("🔦 Drill active:", current_drill)
#		last_drill_state = current_drill
#	drill_active = current_drill


#func _physics_process(delta):
#	move_and_slide()
#	check_drill_collision()
#
#	# 🚧 DEBUG: Detekcia kolízie s asteroidom
#	var test_collision = move_and_collide(velocity * delta)
#	if test_collision:
#		var collider = test_collision.get_collider()
#		if collider.name.begins_with("Asteroid"):
#			print("🚨 Kontakt s asteroid tile:", collider.name)
#		else:
#			print("💥 Kolízia s:", collider.name)
#
#	#if Input.is_action_just_pressed("debug"):
#	#	var pos = $DrillDetector.global_position
#	#	print("📍 Drill pos:", pos)
#	#	var tile_coords = get_node("/root/Main/Asteroid1/Asteroid").local_to_map(pos)
#	#	print("🧱 Tile coords:", tile_coords)
#	#	var tile_id = get_node("/root/Main/Asteroid1/Asteroid").get_cell_source_id(0, tile_coords)
#	#	print("🎯 Tile ID:", tile_id)		

#func check_drill_collision():
#	if not drill_active:
#		return
#	
#	var detector = $DrillDetector
#	var offsets = [
#		Vector2(-8, -16), Vector2(0, -16), Vector2(8, -16),
#		Vector2(-8, 0),   Vector2(0, 0),   Vector2(8, 0),
#		Vector2(-8, 16),  Vector2(0, 16),  Vector2(8, 16)
#	]

#	for offset in offsets:
#		var sample_pos = detector.global_position + offset
#		print("⛏️ Skúšam vrtať na pozíciu:", sample_pos)
#		asteroid_node.drill_at_tile(sample_pos)
#		check_and_mine_resource(sample_pos) # ← ✨ PRIDANÉ TU
#

#func check_and_mine_resource(sample_pos: Vector2):
#	var rl = get_node_or_null("/root/Main/ResourcesManager/ResourceLayer")
#	if rl == null or resource_manager == null:
#		print("❌ ResourceLayer alebo resource_manager je null")
#		return
#
#	# Prepočet pozície na tile coordinates
#	var tilemap_global_transform = rl.get_global_transform()
#	var local_pos: Vector2 = tilemap_global_transform.affine_inverse() * sample_pos
#	var coords: Vector2i = rl.local_to_map(local_pos)
#
#	# Over, či coords sú v rámci mapy
#	if not rl.is_valid_cell(coords):
#		print("⚠️ Neplatné súradnice:", coords)
#		return

#	# Over, či tam vôbec je tile
#	var id: int = rl.get_cell_source_id(0, coords)
#	if id == -1 or id == null:
#		print("🕳️ Prázdna bunka, nič na ťaženie:", coords)
#		return

#	# Match podľa ID – podľa tvojej mapy
#	match id:
#		0:
#			resource_manager.add_resource("crystal")
#			print("💎 Získaný crystal!")
#		1:
#			resource_manager.add_resource("fuel")
#			print("⛽ Získaný fuel!")
#		2:
#			resource_manager.add_resource("titanium")
#			print("🔩 Získaný titanium!")
#		_:
#			print("❓ Neznámy tile ID:", id)
#			return
#
#	# Vymazanie tile po ťažbe
#	rl.set_cell(0, coords, -1)
