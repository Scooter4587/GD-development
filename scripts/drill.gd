extends Area2D

# --- 🧠 Signály pre začiatok/koniec vŕtania ---
signal drill_started
signal drill_ended

# --- 🔧 Exportované vlastnosti vrtáka ---
@export var drill_power: int           = 2      # koľko jednotiek suroviny naťaháme
@export var drill_speed_limit: float   = 50.0   # max. rýchlosť lode pri vŕtaní
@export var cooldown_time: float       = 0.2    # pauza medzi ťahmi (s)
@export var drill_radius: float        = 50.0   # vzdialenosť špičky vrtáka od stredu lode (px)
@export var drill_offset_factor: float = 0.35   # posun špičky vrtáka pozdĺž osi lode (0–1)
@export var tile_size: float           = 16.0   # veľkosť jednej dlaždice (px)

# --- 📦 Referencie na loď a vrstvy dlaždíc ---
@onready var ship: Node = get_parent()
@onready var drill_layers: Array[TileMapLayer] = [
	get_node("/root/Main/Asteroid1/Asteroid"),
	get_node("/root/Main/ResourcesManager/ResourceLayer"),
]

# --- 🔁 Interné premenné stavu ---
var drill_ready: bool   = true
var is_in_contact: bool = false

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited",  Callable(self, "_on_body_exited"))

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("drill") and drill_ready:
		var speed = ship.velocity.length()
		if speed <= drill_speed_limit:
			drill_ready = false
			emit_signal("drill_started")
			_perform_drill()
			await get_tree().create_timer(cooldown_time).timeout
			emit_signal("drill_ended")
			drill_ready = true

# ⛏️ Na jeden ťah zničiť oblasť 4×3 dlaždíc okolo špičky vrtáka
func _perform_drill() -> void:
	# center = presná špička vrtáka z Transform > Position
	var center  = to_global(Vector2.ZERO)
	# forward = lokálna X-osa v svetových súradniciach
	var forward = global_transform.x.normalized()
	# right = pravostranný vektor
	var right   = Vector2(-forward.y, forward.x)

	var w = 6
	var h = 3

	for layer in drill_layers:
		for i in range(w):
			var side_offset  = (i - (w - 1) / 2.0) * tile_size
			for j in range(h):
				var front_offset = j * tile_size
				var world_pos    = center + right * side_offset + forward * front_offset

				var cell    = layer.local_to_map(layer.to_local(world_pos))
				var tile_id = layer.get_cell_source_id(cell)
				if tile_id != -1:
					layer.erase_cell(cell)
					var res_name = ResourceData.get_resource_name(tile_id)
					if res_name != "":
						ResourceData.add_resource(res_name, drill_power)

func _on_body_entered(body: Node) -> void:
	if body is TileMapLayer:
		is_in_contact = true

func _on_body_exited(body: Node) -> void:
	if body is TileMapLayer:
		is_in_contact = false
