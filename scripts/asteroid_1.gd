extends Node2D

var is_mined := false

func drill():
	if not is_mined:
		$asteroid1.visible = false
		$asteroid1_mine.visible = true
		is_mined = true
		print("✅ Asteroid mined!")
	else:
		print("🪨 Already mined!")

func destroy():
	queue_free()
