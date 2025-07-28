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
var _time_since_bounce: float = 1e6
var _bounce_count: int = 0

# --- 🔁 Stav vrtáka ---
var is_drilling: bool       = false
var drill_lock_timer: float = 0.0

func _ready() -> void:
	drill_tool.connect("drill_started", Callable(self, "_on_drill_started"))
	drill_tool.connect("drill_ended",   Callable(self, "_on_drill_ended"))

func _physics_process(delta: float) -> void:
	# 0) Update timers for invulnerability, drill-lock, bounce-reset
	if _invuln_time > 0.0:
		_invuln_time = max(_invuln_time - delta, 0.0)
	if drill_lock_timer > 0.0:
		drill_lock_timer = max(drill_lock_timer - delta, 0.0)
	_time_since_bounce += delta

	# 1) Handle player input
	handle_input()

	# 2) Movement or full-stop logic
	if Input.is_action_pressed("full_stop"):
		is_accelerating = false
		var br = cfg.brake_speed if cfg.require_rotation_alignment else cfg.arc_brake_speed
		velocity = velocity.move_toward(Vector2.ZERO, br * delta)
		if not cfg.require_rotation_alignment and input_buffer != Vector2.ZERO:
			rotation = lerp_angle(rotation, input_buffer.angle(), cfg.arc_rotation_speed * delta)
		elif cfg.require_rotation_alignment:
			handle_rotation(delta)
	else:
		if not cfg.require_rotation_alignment:
			_arcade_movement(delta)
		else:
			handle_rotation(delta)
			handle_realistic_movement(delta)

	# 3) Drill-speed lock logic
	if Input.is_action_pressed("full_stop"):
		is_accelerating = false
		var br2 = cfg.brake_speed if cfg.require_rotation_alignment else cfg.arc_brake_speed
		velocity = velocity.move_toward(Vector2.ZERO, br2 * delta)
		if not cfg.require_rotation_alignment and input_buffer != Vector2.ZERO:
			rotation = lerp_angle(rotation, input_buffer.angle(), cfg.arc_rotation_speed * delta)
		elif cfg.require_rotation_alignment:
			handle_rotation(delta)
	elif is_drilling or drill_lock_timer > 0.0:
		is_accelerating = false
		var dir = velocity.normalized() if velocity.length() > 0.0 else input_buffer
		var target_vel = dir * cfg.drill.drill_speed_limit
		velocity = velocity.move_toward(target_vel, acceleration * delta)

	# 4) Update thrust sprite
	update_thrust_sprite()

	# 5) Save previous velocity for collision responses
	var prev_vel = velocity

	# 6) Move
	move_and_slide()

	# 7) Slide-bounce
	var hit = get_slide_collision_count() > 0
	if hit and not _collided_last_frame and _invuln_time <= 0.0:
		var speed = prev_vel.length()
		if speed >= cfg.hull.damage_threshold and not is_drilling:
			stats.apply_hull_damage(speed)
		if not is_drilling:
			# reset alebo inkrement bounce-count
			if _time_since_bounce <= cfg.bounce_reset_time:
				_bounce_count += 1
			else:
				_bounce_count = 1
			_time_since_bounce = 0
			# vyber base multiplier podľa rýchlosti
			var base_mult = cfg.bounce_impulse_multiplier_high if speed >= cfg.bounce_speed_threshold else cfg.bounce_impulse_multiplier_low
			# aplikuj decay pre sekundárne odbitia
			var final_mult = base_mult * pow(cfg.bounce_decay, _bounce_count - 1)
			# odraz a nastavenie invuln
			var normal = get_slide_collision(0).get_normal()
			velocity = prev_vel.bounce(normal) * final_mult
			_invuln_time = cfg.hull.invulnerability_duration
	_collided_last_frame = hit

	# 8) Axis-aligned probe bounce (fallback)
	if not hit \
	   and input_buffer != Vector2.ZERO \
	   and prev_vel.length() > cfg.hull.damage_threshold \
	   and _invuln_time <= 0.0:

		var from = global_position
		var to = from + prev_vel * delta
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.new()
		query.from = from
		query.to = to
		query.exclude = [self]
		query.collision_mask = collision_layer
		query.collide_with_areas = false

		var col = space_state.intersect_ray(query)
		if col:
			var speed = prev_vel.length()
			if speed >= cfg.hull.damage_threshold:
				stats.apply_hull_damage(speed)
			# reset alebo inkrement bounce-count
			if _time_since_bounce <= cfg.bounce_reset_time:
				_bounce_count += 1
			else:
				_bounce_count = 1
			_time_since_bounce = 0
			# vyber multiplikátor podľa rýchlosti
			var base_mult = cfg.bounce_impulse_multiplier_high if speed >= cfg.bounce_speed_threshold else cfg.bounce_impulse_multiplier_low
			var final_mult = base_mult * pow(cfg.bounce_decay, _bounce_count - 1)
			velocity = prev_vel.bounce(col.normal) * final_mult
			_invuln_time = cfg.hull.invulnerability_duration
			_collided_last_frame = true
		
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
