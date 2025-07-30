extends CharacterBody2D

const CargoHold = preload("res://scripts/CargoHold.gd")
var cargo_hold: CargoHold

@onready var stats      = get_node("/root/ShipStats")
@onready var cfg        = ShipConfig
@onready var sprite_base: Sprite2D   = $SpriteBase
@onready var sprite_thrust: Sprite2D = $SpriteThrust
@onready var drill_tool: Node        = $DrillTool

signal drill_locked
signal drill_unlocked
signal fuel_low
signal energy_low

# --- 🚀 Interné premenné pohybu ---
var acceleration: float        = 200.0
var input_buffer: Vector2      = Vector2.ZERO
var desired_direction: Vector2 = Vector2.ZERO
var is_accelerating: bool      = false
var _collided_last_frame: bool = false
var _invuln_time: float        = 0.0
var _time_since_bounce: float  = 1e6
var _bounce_count: int         = 0
var post_shutdown_lock: bool = false

# --- 🔋 Fuel systém ---
var fuel_current: float        = 0.0  # nastavíme v _ready()

# --- 🔁 Stav vrtáka ---
var is_drilling: bool       = false
var drill_lock_timer: float = 0.0


func _ready() -> void:
	# inicializácia fuel
	fuel_current = cfg.fuel.fuel_max
	drill_tool.connect("drill_started", Callable(self, "_on_drill_started"))
	drill_tool.connect("drill_ended",   Callable(self, "_on_drill_ended"))

	# inštanciujeme CargoHold
	cargo_hold = CargoHold.new()
	cargo_hold.max_capacity = cfg.cargo.max_capacity
	add_child(cargo_hold)
	cargo_hold.connect("weight_changed", Callable(self, "_on_cargo_weight_changed"))


func _physics_process(delta: float) -> void:
	# 0) Shutdown Detection & Handling
	if cfg.energy.energy_current <= 0.0 and not cfg.energy.is_shutdown and not post_shutdown_lock:
		cfg.energy.is_shutdown    = true
		cfg.energy.shutdown_timer = cfg.energy.shutdown_duration
		post_shutdown_lock        = true
		if is_drilling:
			is_drilling = false
			_on_drill_ended()

	# 1) Shutdown State: Drift + Collisions, skip regen/consumption/input
	if cfg.energy.is_shutdown:
		cfg.energy.shutdown_timer -= delta
		if cfg.energy.shutdown_timer <= 0.0:
			cfg.energy.is_shutdown = false

		var drift_vel = velocity
		move_and_slide()
		_handle_slide_bounce(drift_vel)
		_handle_axis_bounce(drift_vel, delta)
		return

	# 2) Energy Regeneration & Drill Consumption
	cfg.energy.regenerate(delta)
	if post_shutdown_lock and cfg.energy.energy_current >= cfg.energy.energy_max * cfg.energy.restart_threshold:
		post_shutdown_lock = false
	if is_drilling:
		cfg.energy.consume_drill(delta)
		if cfg.energy.is_low():
			emit_signal("energy_low")
	if _invuln_time > 0.0:
		_invuln_time = max(_invuln_time - delta, 0.0)
	if drill_lock_timer > 0.0:
		drill_lock_timer = max(drill_lock_timer - delta, 0.0)
	_time_since_bounce += delta

	# 3) Fuel Warning
	if fuel_current <= cfg.fuel.fuel_low_threshold * cfg.fuel.fuel_max:
		emit_signal("fuel_low")

	# 4) Compute Cargo Load Ratio (0.0 = empty, 1.0 = full)
	var load_ratio = clamp(cargo_hold.get_current_weight() / cfg.cargo.max_capacity, 0.0, 1.0)

	# 5) Handle Input
	handle_input()

	# 6) Ship Movement or Full-Stop
	if Input.is_action_pressed("full_stop"):
		# Thrusters consumption (adjusted by cargo)
		_consume_thrusters(delta * (1.0 + cfg.cargo.fuel_thruster_load_factor * load_ratio))
		is_accelerating = false
		var br = cfg.brake_speed if cfg.require_rotation_alignment else cfg.arc_brake_speed
		velocity = velocity.move_toward(Vector2.ZERO, br * delta)
		if not cfg.require_rotation_alignment and input_buffer != Vector2.ZERO:
			_consume_thrusters(delta * (1.0 + cfg.cargo.fuel_thruster_load_factor * load_ratio))
			rotation = lerp_angle(rotation, input_buffer.angle(), cfg.arc_rotation_speed * delta)
		elif cfg.require_rotation_alignment:
			handle_rotation(delta)
	else:
		if not cfg.require_rotation_alignment:
			if input_buffer != Vector2.ZERO and fuel_current > 0:
				_consume_main(delta * (1.0 + cfg.cargo.fuel_main_load_factor * load_ratio))
				is_accelerating = true
			else:
				is_accelerating = false
			_arcade_movement(delta)
		else:
			handle_rotation(delta)
			if desired_direction != Vector2.ZERO and fuel_current > 0:
				_consume_main(delta * (1.0 + cfg.cargo.fuel_main_load_factor * load_ratio))
				is_accelerating = true
			else:
				is_accelerating = false
			handle_realistic_movement(delta)

	# 7) Drill-Lock Logic (post full-stop & drill)
	if Input.is_action_pressed("full_stop"):
		_consume_thrusters(delta * (1.0 + cfg.cargo.fuel_thruster_load_factor * load_ratio))
		is_accelerating = false
	elif is_drilling or drill_lock_timer > 0.0:
		is_accelerating = false
		var dir = velocity.normalized() if velocity.length() > 0.0 else input_buffer
		var target_vel = dir * cfg.drill.drill_speed_limit
		velocity = velocity.move_toward(target_vel, acceleration * delta)

	# 8) Update Thrust Sprite Visibility
	update_thrust_sprite()

	# 9) Execute Movement & Handle Collisions
	var prev_vel = velocity
	move_and_slide()
	_handle_slide_bounce(prev_vel)
	_handle_axis_bounce(prev_vel, delta)

	# 10) Post-move Input (if not shutdown)
	if not cfg.energy.is_shutdown:
		handle_input()


# --- Fuel consumption methods ---
func _consume_main(delta: float) -> void:
	var cost = cfg.fuel.fuel_main_engine_per_sec * delta
	fuel_current = max(fuel_current - cost, 0)

func _consume_thrusters(delta: float) -> void:
	var cost = cfg.fuel.fuel_thrusters_per_sec * delta
	fuel_current = max(fuel_current - cost, 0)

# --- Bounce handling ---
func _handle_slide_bounce(prev_vel: Vector2) -> void:
	var hit = get_slide_collision_count() > 0
	if hit and not _collided_last_frame and _invuln_time <= 0.0:
		var speed = prev_vel.length()
		# 1) Apply damage with cargo-based multiplier
		if speed >= cfg.hull.damage_threshold and not is_drilling:
			var base_dmg   = speed
			var load_ratio = clamp(cargo_hold.get_current_weight() / cfg.cargo.max_capacity, 0.0, 1.0)
			var dmg        = lerp(base_dmg, base_dmg * cfg.cargo.collision_damage_multiplier, load_ratio)
			stats.apply_hull_damage(dmg)

		# 2) Handle bounce impulse as before
		if not is_drilling:
			if _time_since_bounce <= cfg.hull.bounce_reset_time:
				_bounce_count += 1
			else:
				_bounce_count = 1
			_time_since_bounce = 0
			var normal    = get_slide_collision(0).get_normal()
			var base_mult = cfg.hull.bounce_impulse_multiplier_high if speed >= cfg.hull.bounce_speed_threshold else cfg.hull.bounce_impulse_multiplier_low
			var final_mult = base_mult * pow(cfg.hull.bounce_decay, _bounce_count - 1)
			velocity = prev_vel.bounce(normal) * final_mult
			_invuln_time = cfg.hull.invulnerability_duration
	_collided_last_frame = hit

func _handle_axis_bounce(prev_vel: Vector2, delta: float) -> void:
	# 1) Early exits
	if get_slide_collision_count() > 0:
		return
	if input_buffer == Vector2.ZERO or prev_vel.length() <= cfg.hull.damage_threshold or _invuln_time > 0.0:
		return

	# 2) Raycast for axis collision
	var from = global_position
	var to   = from + prev_vel * delta
	var query = PhysicsRayQueryParameters2D.new()
	query.from              = from
	query.to                = to
	query.exclude           = [self]
	query.collision_mask    = collision_layer
	query.collide_with_areas = false
	var col = get_world_2d().direct_space_state.intersect_ray(query)

	if col:
		var speed = prev_vel.length()
		# 3) Apply damage with cargo-based multiplier
		if speed >= cfg.hull.damage_threshold:
			var base_dmg   = speed
			var load_ratio = clamp(cargo_hold.get_current_weight() / cfg.cargo.max_capacity, 0.0, 1.0)
			var dmg        = lerp(base_dmg, base_dmg * cfg.cargo.collision_damage_multiplier, load_ratio)
			stats.apply_hull_damage(dmg)

		# 4) Handle bounce impulse as before
		if _time_since_bounce <= cfg.hull.bounce_reset_time:
			_bounce_count += 1
		else:
			_bounce_count = 1
		_time_since_bounce = 0
		var base_mult = cfg.hull.bounce_impulse_multiplier_high if speed >= cfg.hull.bounce_speed_threshold else cfg.hull.bounce_impulse_multiplier_low
		var final_mult = base_mult * pow(cfg.hull.bounce_decay, _bounce_count - 1)
		velocity = prev_vel.bounce(col.normal) * final_mult
		_invuln_time = cfg.hull.invulnerability_duration
		_collided_last_frame = true

func handle_input() -> void:
	# 1) Pohybový vstup
	input_buffer = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()

	# 2) Toggle movement mode vždy
	if Input.is_action_just_pressed("toggle_movement_mode"):
		cfg.require_rotation_alignment = not cfg.require_rotation_alignment
		print("Režim pohybu:", "Realistický" if cfg.require_rotation_alignment else "Arkádový")

	# 3) Drill toggle – iba ak neprechádzame post-shutdown lock
	if Input.is_action_just_pressed("drill") and not post_shutdown_lock:
		is_drilling = not is_drilling

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

func _on_cargo_weight_changed(new_weight: float) -> void:
	print("Cargo váha:", new_weight, "/", cfg.cargo.max_capacity)