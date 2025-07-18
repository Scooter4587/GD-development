extends Area2D

# --- 🔧 Vlastnosti vŕtačky ---
@export var drill_power := 2                          # Sila vŕtania (koľko damage/tier prerazí)
@export var drill_speed_limit := 50.0                 # Maximálna rýchlosť pre aktívne vŕtanie
@export var cooldown_time := 0.2                      # Čas medzi jednotlivými vŕtaniami
@export var drill_size: Vector2 = Vector2(64, 16)     # definovaná veľkosť vrtáka
@export var tile_size := 16                           # veľkosť jednej dlaždice

#@export var drill_range_tiles := 1.0        # ako ďaleko dopredu vrtáme
#@export var drill_width_tiles := 2.0        # koľko dlaždíc široká oblasť
@export var drill_step_tiles := 0.5         # krok v tiles (0.5 = každá pol dlaždica)
@export var drill_radius := 32.0   # Polomer vrtnej oblasti v pixeloch
@export var drill_offset_factor := 0.35

# --- 🔁 Stav ---
var drill_ready := true                               # Či je vrták pripravený vŕtať
var drill_active := false                             # Či práve aktívne vŕtame
var is_in_contact_with_asteroid := false              # Či sme v kontakte s asteroidom (kolízia)

# --- 🧩 Referencie ---
@onready var ship := get_parent()                     # Loď, ku ktorej vrták patrí
@onready var main := get_node("/root/Main")           # Globálny prístup k Main uzlu (napr. resource systém)


# --- 🔁 Hlavný cyklus vŕtačky (volá sa každý frame) ---
func _physics_process(_delta):
	drill_active = false  # Predvolene vypnuté

	# Ak držíme tlačidlo, vrták je pripravený a sme v kontakte s asteroidom
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and drill_ready and is_in_contact_with_asteroid:
		for body in get_overlapping_bodies():
			var target = body

			# Získaj parent objekt, ak sa stretávame s TileMapLayer
			if body is TileMapLayer:
				target = body.get_parent()

			# Ak cieľ podporuje metódu drill_at (napr. asteroid), pokús sa vŕtať
			if target.has_method("drill_at"):
				var current_speed = ship.velocity.length()
				if current_speed > drill_speed_limit:
					print("💥 NARAZILI SME! Rýchlosť príliš vysoká:", current_speed)
					return

				print("✅ Rýchlosť OK, vŕtame...")
				drill_active = true  # Vŕtanie prebieha

				# Získaj všetky body z oblasti vrtáka a pokús sa ich vyvŕtať
				var affected_points = get_drill_area()
				for point in affected_points:
					target.drill_at(point, drill_power)

				# ➕ Udržíme max rýchlosť ešte chvíľu po vŕtaní
				ship.drill_lock_timer = 0.3

				# Vrták ide do cooldownu
				drill_ready = false
				await get_tree().create_timer(cooldown_time).timeout
				drill_ready = true


# --- 📍 Vráti pole bodov (Vector2), ktoré pokrýva oblasť vrtáka ---
func get_drill_area() -> Array[Vector2]:
	var results: Array[Vector2] = []
	var step: float = tile_size * drill_step_tiles
	var radius_in_tiles: int = int(ceil(drill_radius / tile_size))

	var drill_pos := global_position + Vector2.RIGHT.rotated(rotation) * drill_radius

	# DEBUG zakomentovaný
	# print("DEBUG: drill_radius =", drill_radius)

	for x in range(-radius_in_tiles * tile_size, radius_in_tiles * tile_size + 1, int(step)):
		for y in range(-radius_in_tiles * tile_size, radius_in_tiles * tile_size + 1, int(step)):
			var offset := Vector2(x, y).rotated(rotation)
			if offset.length() <= drill_radius:
				var world_pos := drill_pos + offset
				var snapped_pos := world_pos.snapped(Vector2(tile_size, tile_size))
				results.append(snapped_pos)

	return results

# --- 🔄 Pripravenie signálov na zisťovanie konataktu s asteroidmi ---
func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

	# Debug kruh vrtáka (vizualizácia na scéne)
	debug_draw_circle()

# --- 🛰️ Keď vojdeme do kolízie s TileMapLayer (napr. asteroid), zapne kontakt ---
func _on_body_entered(body):
	if body is TileMapLayer:
		is_in_contact_with_asteroid = true

# --- 🛰️ Keď opustíme kolíziu, vypneme kontakt ---
func _on_body_exited(body):
	if body is TileMapLayer:
		is_in_contact_with_asteroid = false

func debug_draw_circle():
	var circle = CircleShape2D.new()
	circle.radius = drill_radius

	var shape = CollisionShape2D.new()
	shape.shape = circle
	shape.name = "DebugDrillCircle"
	shape.disabled = true  # Len vizuálny debug
	add_child(shape)

	var forward := Vector2.RIGHT.rotated(rotation)
	shape.position = forward * drill_radius * 0.35  # ⬅ rovnaký posun ako v get_drill_area
