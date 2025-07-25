extends Area2D

signal drill_started
signal drill_ended

@onready var ship: CharacterBody2D       = get_parent()
@onready var cfg_drill: DrillConfig      = ShipConfig.drill
@onready var drill_layers: Array[TileMapLayer] = [
	get_node("/root/Main/Asteroid1/Asteroid"),
	get_node("/root/Main/ResourcesManager/ResourceLayer"),
]

var drill_ready: bool   = true
var is_in_contact: bool = false

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited",  Callable(self, "_on_body_exited"))

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("drill") and drill_ready:
		# Guard: začneme len keď sme pod rýchlostným limitom
		if ship.velocity.length() > cfg_drill.drill_speed_limit:
			return

		drill_ready = false
		emit_signal("drill_started")

		# 1) Spočítame, čo sa bude ťažiť
		var center  = to_global(Vector2.ZERO)
		var forward = global_transform.x.normalized()
		var right   = Vector2(-forward.y, forward.x)
		var counts = ResourceData.count_resources_in_region(
			drill_layers[1],
			center, forward, right,
			6, 3,
			cfg_drill.tile_size
		)

		# 2) Vykonáme samotné drilovanie
		_perform_drill()

		# 3) Pripočítame suroviny (+1 za každý tile)
		for res_type in counts.keys():
			var qty = counts[res_type]
			ResourceData.add_resource(res_type, qty)
			print("[DEBUG] Counted %s ×%d, total now %d"
				  % [res_type, qty, ResourceData.get_amount(res_type)])

		# 4) Cooldown pred ďalším vrtaním
		await get_tree().create_timer(cfg_drill.cooldown_time).timeout
		emit_signal("drill_ended")
		drill_ready = true

func _perform_drill() -> void:
	var center  = to_global(Vector2.ZERO)
	var forward = global_transform.x.normalized()
	var right   = Vector2(-forward.y, forward.x)
	var w = 6
	var h = 3

	for layer in drill_layers:
		for i in range(w):
			var side_offset  = (i - (w - 1) / 2.0) * cfg_drill.tile_size
			for j in range(h):
				var front_offset = j * cfg_drill.tile_size
				var world_pos    = center + right * side_offset + forward * front_offset

				var cell = layer.local_to_map(layer.to_local(world_pos))
				if layer.get_cell_source_id(cell) != -1:
					layer.erase_cell(cell)

func _on_body_entered(body: Node) -> void:
	if body is TileMapLayer:
		is_in_contact = true

func _on_body_exited(body: Node) -> void:
	if body is TileMapLayer:
		is_in_contact = false
