extends Node2D

@onready var ship = $Ship
@onready var hud  = $HUD

func _ready() -> void:
	hud.set_ship(ship)
	#ShipStats.connect("hull_destroyed", Callable(self, "_on_ship_destroyed"))
	ShipStats.restore_full_hull()

#func _on_ship_destroyed(_dmg):
#	# zneaktivni ovládanie lode
#	ship.set_process(false)
#	ship.set_physics_process(false)
#	# zobraz “Game Over” obrazovku
#	$GameOverUI.show()
