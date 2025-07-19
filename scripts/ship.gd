extends CharacterBody2D  # Základná trieda pre pohyblivý 2D objekt

signal drill_locked    # Signál pri zamknutí vrtáka
signal drill_unlocked  # Signál pri odblokovaní vrtáka

# --- 🔧 Konštanty ---
const MAX_SPEED: float           = 300.0  # Maximálna rýchlosť lode (jednotky/s)
const DRILL_SPEED_LIMIT: float   = 50.0   # Limit rýchlosti pri aktívnom alebo zamknutom vrtaní

# --- ⚙️ Exportované premenné ---
@export var require_rotation_alignment: bool = true   # Režim: True = realistický (nutné natočenie), False = arkádový
@export var drill_lock_duration: float     = 1.5     # Trvanie zamknutia vrtáka (sekundy)
@export var max_speed: float               = 300.0   # Dynamicky upraviteľná maximálna rýchlosť
@export var brake_speed: float             = 50.0    # Rýchlosť brzdenia v realistickom režime (full_stop)
@export var arc_brake_speed: float         = 150.0   # Rýchlosť brzdenia v arkádovom režime (full_stop)
@export var arc_rotation_speed: float      = 2.0     # Rýchlosť otočenia v arkádovom režime (radiány/s)
@export var rotation_speed_real: float     = 2.0     # Rýchlosť otočenia v realistickom režime (radiány/s)
@export var stop_thrust_on_rotate: bool    = true    # Ak true, realistický režim rotácia vypne thrust

# --- 🚀 Interné premenné pohybu ---
var acceleration: float      = 200.0         # Sila ťahu (jednotky/s²) a zároveň rýchlosť zmeny velocity v arkádovom móde
var input_buffer: Vector2    = Vector2.ZERO  # Aktuálny vstup hráča (smer)
var desired_direction: Vector2 = Vector2.ZERO# Cieľový smer pre realistický režim po natočení
var is_accelerating: bool    = false         # Indikátor akcelerácie (pre thrust sprite)

# --- 🔁 Stav vrtáka ---
var is_drilling: bool        = false         # Indikuje, či prebieha vrtanie
var drill_lock_timer: float  = 0.0           # Časovač pre brzdenie pri vrtaní

# --- 📦 Referencie na uzly ---
@onready var sprite_base: Sprite2D   = $SpriteBase   # Základný sprite lode
@onready var sprite_thrust: Sprite2D = $SpriteThrust # Sprite pre vizuál ťahu
@onready var drill_tool: Node        = $DrillTool    # Uzol s logikou vrtáka

func _ready() -> void:
	drill_tool.connect("drill_started", Callable(self, "_on_drill_started"))
	drill_tool.connect("drill_ended",   Callable(self, "_on_drill_ended"))

func _physics_process(delta: float) -> void:
	handle_input()

	# Full stop (C): brzdenie a možnosť rotácie bez thrustu
	if Input.is_action_pressed("full_stop"):
		is_accelerating = false
		# brzdenie k nule: odlišné pre režimy
		var brake_rate = brake_speed if require_rotation_alignment else arc_brake_speed
		velocity = velocity.move_toward(Vector2.ZERO, brake_rate * delta)
		# povoliť rotáciu
		if not require_rotation_alignment:
			if input_buffer != Vector2.ZERO:
				var target_angle = input_buffer.angle()
				rotation = lerp_angle(rotation, target_angle, arc_rotation_speed * delta)
		else:
			handle_rotation(delta)
	else:
		# Normálny pohyb podľa režimu
		if not require_rotation_alignment:
			_arcade_movement(delta)
		else:
			handle_rotation(delta)
			handle_realistic_movement(delta)

	apply_drill_speed_limit(delta)
	update_thrust_sprite()
	move_and_slide()

func handle_input() -> void:
	input_buffer = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()
	if Input.is_action_just_pressed("toggle_movement_mode"):
		require_rotation_alignment = not require_rotation_alignment
		print("Režim pohybu: ", "Realistický" if require_rotation_alignment else "Arkádový")

func _arcade_movement(delta: float) -> void:
	# Arkádový režim: drift a jemná rotácia a plynulá zmena velocity
	if input_buffer != Vector2.ZERO:
		var target_angle = input_buffer.angle()
		rotation = lerp_angle(rotation, target_angle, arc_rotation_speed * delta)
		# Plynulá zmena velocity smerom k požiadavke
		var target_vel = input_buffer * max_speed
		velocity = velocity.move_toward(target_vel, acceleration * delta)
		is_accelerating = true
	else:
		is_accelerating = false

func handle_rotation(delta: float) -> void:
	# Realistický režim: otáčanie k smeru vstupu
	if input_buffer != Vector2.ZERO:
		var target_angle = input_buffer.angle()
		rotation = lerp_angle(rotation, target_angle, rotation_speed_real * delta)
		var angle_diff = abs(wrapf(rotation - target_angle, -PI, PI))
		if angle_diff < 0.1:
			desired_direction = input_buffer
		else:
			if stop_thrust_on_rotate:
				desired_direction = Vector2.ZERO
	else:
		desired_direction = Vector2.ZERO

func handle_realistic_movement(delta: float) -> void:
	is_accelerating = false
	if desired_direction != Vector2.ZERO:
		velocity += desired_direction * acceleration * delta
		is_accelerating = true
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

func apply_drill_speed_limit(delta: float) -> void:
	if drill_lock_timer > 0.0:
		drill_lock_timer -= delta
	if drill_lock_timer > 0.0 or is_drilling:
		if velocity.length() > DRILL_SPEED_LIMIT:
			velocity = velocity.normalized() * DRILL_SPEED_LIMIT

func update_thrust_sprite() -> void:
	if require_rotation_alignment:
		sprite_thrust.visible = is_accelerating
	else:
		sprite_thrust.visible = input_buffer != Vector2.ZERO and not Input.is_action_pressed("full_stop")
	sprite_base.visible = not sprite_thrust.visible

func _on_drill_started() -> void:
	is_drilling = true
	drill_lock_timer = drill_lock_duration
	emit_signal("drill_locked")

func _on_drill_ended() -> void:
	is_drilling = false
	emit_signal("drill_unlocked")
