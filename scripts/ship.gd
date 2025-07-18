extends CharacterBody2D

signal drill_locked
signal drill_unlocked

# --- 🔧 KONSTANTY ---
const MAX_SPEED: float = 500.0
const ROTATION_SPEED: float = 3.0
const DRILL_SPEED_LIMIT: float = 50.0

# --- ⚙️ Exportované premenné ---
@export var require_rotation_alignment: bool = true
@export var drill_lock_duration: float     = 1.5

# --- 🚀 Premenné pohybu ---
var acceleration: float      = 400.0
var deceleration_rate: float = 300.0
var input_buffer: Vector2    = Vector2.ZERO
var desired_direction: Vector2 = Vector2.ZERO

# --- 🔁 Stav vrtáka ---
var is_drilling: bool      = false
var drill_lock_timer: float = 0.0

# --- 📦 Referencie na uzly ---
@onready var sprite_base:   Sprite2D = $SpriteBase
@onready var sprite_thrust: Sprite2D = $SpriteThrust
@onready var drill_tool:    Node     = $DrillTool

func _ready() -> void:
	drill_tool.connect("drill_started", Callable(self, "_on_drill_started"))
	drill_tool.connect("drill_ended",   Callable(self, "_on_drill_ended"))

func _physics_process(delta: float) -> void:
	handle_input()
	handle_rotation(delta)
	handle_movement(delta)
	apply_drill_speed_limit(delta)
	update_thrust_sprite()
	move_and_slide()

func handle_input() -> void:
	input_buffer = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()

	if Input.is_action_just_pressed("full_stop"):
		velocity = Vector2.ZERO

	if Input.is_action_just_pressed("toggle_movement_mode"):
		require_rotation_alignment = not require_rotation_alignment
		print(
			"Režim pohybu: ",
			"Realistický" if require_rotation_alignment else "Arkádový"
		)

func handle_rotation(delta: float) -> void:
	if input_buffer != Vector2.ZERO:
		var target_angle = input_buffer.angle()
		rotation = lerp_angle(rotation, target_angle, ROTATION_SPEED * delta)
		if abs(wrapf(rotation - target_angle, -PI, PI)) < 0.1:
			desired_direction = input_buffer
	else:
		desired_direction = Vector2.ZERO

func handle_movement(delta: float) -> void:
	if desired_direction == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration_rate * delta)
	else:
		var angle_diff = abs(wrapf(rotation - desired_direction.angle(), -PI, PI))
		if not require_rotation_alignment or angle_diff < 0.1:
			velocity += desired_direction * acceleration * delta

func apply_drill_speed_limit(delta: float) -> void:
	if drill_lock_timer > 0.0:
		drill_lock_timer -= delta
	if drill_lock_timer > 0.0 or is_drilling:
		if velocity.length() > DRILL_SPEED_LIMIT:
			velocity = velocity.normalized() * DRILL_SPEED_LIMIT

func update_thrust_sprite() -> void:
	var is_thrusting = velocity.length() > 5.0 and not Input.is_action_pressed("full_stop")
	sprite_thrust.visible = is_thrusting
	sprite_base.visible   = not is_thrusting

func _on_drill_started() -> void:
	is_drilling     = true
	drill_lock_timer = drill_lock_duration
	emit_signal("drill_locked")

func _on_drill_ended() -> void:
	is_drilling = false
	emit_signal("drill_unlocked")
