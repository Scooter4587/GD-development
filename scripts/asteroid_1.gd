## Skript na prepnutie asteroidu po "navŕtaní"
extends Node2D

@onready var sprite_normal = $asteroid1        # Obrázok nepoškodeného asteroidu
@onready var sprite_mined = $asteroid1_mine          # Obrázok po vyvŕtaní

var is_mined = false

func _ready():
	sprite_mined.visible = false  # Zobrazí sa až po kontakte s vrtákom

### Trigger ak sa dotkne vrták
func _on_MineArea_area_entered(area: Area2D) -> void:
	if area.name == "DrillTip" and not is_mined:
		print("Drilling started!")  # Debug info
		is_mined = true
		sprite_normal.visible = false
		sprite_mined.visible = true
