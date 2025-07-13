extends StaticBody2D

var is_mined := false

@onready var sprite_surface = $asteroid1
@onready var sprite_mined = $asteroid1_mine
@onready var collider = $CollisionPolygon2D  # alebo napr. $CollisionPolygon2D, podľa tvojho stromu

func drill():
	if not is_mined:
		is_mined = true
		sprite_surface.visible = false
		sprite_mined.visible = true
		collider.set_deferred("disabled", true)
		print("⛏️ Asteroid drilled!")
	else:
		print("🪨 Already mined!")
