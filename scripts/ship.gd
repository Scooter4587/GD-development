extends CharacterBody2D

@onready var stats      = get_node("/root/ShipStats")
@onready var cfg        = ShipConfig
@onready var sprite_base: Sprite2D   = $SpriteBase
@onready var sprite_thrust: Sprite2D = $SpriteThrust
@onready var drill_tool: Node        = $DrillTool

signal drill_locked
signal drill_unlocked

# --- 🚀 Interné premenné pohybu ---
var acceleration: float        = 200.0
var input_buffer: Vector2      = Vector2.ZERO
var desired_direction: Vector2 = Vector2.ZERO
var is_accelerating: bool      = false
var _collided_last_frame: bool = false
var _invuln_time: float        = 0.0

# --- 🔁 Stav vrtáka ---
var is_drilling: bool       = false
var drill_lock_timer: float = 0.0

func _ready() -> void:
	drill_tool.connect("drill_started", Callable(self, "_on_drill_started"))
	drill_tool.connect("drill_ended",   Callable(self, "_on_drill_ended"))

func _physics_process(delta: float) -> void:
	# invulnerability frames
	if _invuln_time > 0.0:
		_invuln_time = max(_invuln_time - delta, 0.0)
	# drill lock-timer (držanie nízkej rýchlosti po každom tile)
	if drill_lock_timer > 0.0:
		drill_lock_timer = max(drill_lock_timer - delta, 0.0)

	# vstup
	handle_input()

	# full stop (C)
	if Input.is_action_pressed("full_stop"):
		is_accelerating = false
		var br = cfg.brake_speed if cfg.require_rotation_alignment else cfg.arc_brake_speed
		velocity = velocity.move_toward(Vector2.ZERO, br * delta)
		if not cfg.require_rotation_alignment:
			if input_buffer != Vector2.ZERO:
				var targ = input_buffer.angle()
				rotation = lerp_angle(rotation, targ, cfg.arc_rotation_speed * delta)
		else:
			handle_rotation(delta)
	else:
		# bežný pohyb
		if not cfg.require_rotation_alignment:
			_arcade_movement(delta)
		else:
			handle_rotation(delta)
			handle_realistic_movement(delta)

		# drill-speed a full-stop logika
	if Input.is_action_pressed("full_stop"):
		# Full-stop (C) má vždy prioritu
		is_accelerating = false
		var br = cfg.brake_speed if cfg.require_rotation_alignment else cfg.arc_brake_speed
		velocity = velocity.move_toward(Vector2.ZERO, br * delta)
		if not cfg.require_rotation_alignment and input_buffer != Vector2.ZERO:
			rotation = lerp_angle(input_buffer.angle(), rotation, cfg.arc_rotation_speed * delta)
		elif cfg.require_rotation_alignment:
			handle_rotation(delta)

	elif is_drilling or drill_lock_timer > 0.0:
		is_accelerating = false

		# Určenie smeru: ak máme nejakú rýchlosť, držíme tento smer,
		# inak použijeme vstupný smer hráča
		var dir = Vector2.ZERO
		if velocity.length() > 0.0:
			dir = velocity.normalized()
		else:
			dir = input_buffer

		var target_vel = dir * cfg.drill.drill_speed_limit
		# Použijeme acceleration pre plynulé zrýchlenie aj brzdenie
		velocity = velocity.move_toward(target_vel, acceleration * delta)
	
	# thrust sprite
	update_thrust_sprite()

	# pohyb + kolízie
	move_and_slide()

	# 1) klasický slide‐bounce
	var hit = get_slide_collision_count() > 0
	if hit and not _collided_last_frame and _invuln_time <= 0.0:
		var speed = velocity.length()
		if speed >= cfg.hull.damage_threshold and not is_drilling:
			stats.apply_hull_damage(speed)
		if not is_drilling:
			var normal = get_slide_collision(0).get_normal()
			velocity = velocity.bounce(normal) * cfg.hull.bounce_impulse_multiplier
			_invuln_time = cfg.hull.invulnerability_duration
	_collided_last_frame = hit

	# 2) axis‐aligned probe bounce
	#if not hit and input_buffer != Vector2.ZERO and velocity.length() > cfg.hull.damage_threshold and _invuln_time <= 0.0:
	#	print("[AXIS PROBE] probing… speed=", velocity.length())
	#	var probe = velocity * delta
	#	var col = move_and_collide(probe)
	#	if col:
	#		print("[AXIS PROBE] collision! normal=", col.get_normal())
	#		var speed = velocity.length()
	#		if speed >= cfg.hull.damage_threshold and not is_drilling:
	##			stats.apply_hull_damage(speed)
	#		if not is_drilling:
	#			var normal = col.get_normal()
	#			velocity = velocity.bounce(normal) * cfg.hull.axis_bounce_impulse_multiplier
	#			_invuln_time = cfg.hull.invulnerability_duration
	#		_collided_last_frame = true

	# nakoniec enforce drill‐limit aj po akomkoľvek bounce
	#if is_drilling or drill_lock_timer > 0.0:
	#	velocity = velocity.limit_length(cfg.drill.drill_speed_limit)
		
func handle_input() -> void:
	input_buffer = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()
	if Input.is_action_just_pressed("toggle_movement_mode"):
		# prepni v config
		cfg.require_rotation_alignment = not cfg.require_rotation_alignment
		print("Režim pohybu:",
			  "Realistický" if cfg.require_rotation_alignment else "Arkádový")

func _arcade_movement(delta: float) -> void:
	if input_buffer != Vector2.ZERO:
		var targ = input_buffer.angle()
		rotation = lerp_angle(rotation, targ, cfg.arc_rotation_speed * delta)
		var target_vel = input_buffer * cfg.max_speed
		velocity = velocity.move_toward(target_vel, acceleration * delta)
		is_accelerating = true
	else:
		is_accelerating = false

func handle_rotation(delta: float) -> void:
	if input_buffer != Vector2.ZERO:
		var targ = input_buffer.angle()
		rotation = lerp_angle(rotation, targ, cfg.rotation_speed_real * delta)
		var diff = abs(wrapf(rotation - targ, -PI, PI))
		if diff < 0.1:
			desired_direction = input_buffer
		else:
			desired_direction = Vector2.ZERO if cfg.stop_thrust_on_rotate else desired_direction
	else:
		desired_direction = Vector2.ZERO

func handle_realistic_movement(delta: float) -> void:
	is_accelerating = false
	if desired_direction != Vector2.ZERO:
		velocity += desired_direction * acceleration * delta
		is_accelerating = true
	if velocity.length() > cfg.max_speed:
		velocity = velocity.normalized() * cfg.max_speed

func update_thrust_sprite() -> void:
	if cfg.require_rotation_alignment:
		sprite_thrust.visible = is_accelerating
	else:
		sprite_thrust.visible = input_buffer != Vector2.ZERO and not Input.is_action_pressed("full_stop")
	sprite_base.visible = not sprite_thrust.visible

func _on_drill_started() -> void:
	is_drilling = true
	drill_lock_timer = cfg.drill.drill_lock_duration
	emit_signal("drill_locked")

func _on_drill_ended() -> void:
	is_drilling = false
	drill_lock_timer = cfg.drill.drill_lock_duration
	emit_signal("drill_unlocked")
