extends Node2D

# --- 📦 Referencie na uzly ---
@onready var ship: CharacterBody2D      = $Ship
@onready var speed_label: Label         = $CanvasLayer/SpeedLabel
@onready var crystal_label: Label       = $CanvasLayer/ResourcePanel/CrystalLabel
@onready var fuel_label: Label          = $CanvasLayer/ResourcePanel/FuelLabel
@onready var titanium_label: Label      = $CanvasLayer/ResourcePanel/TitaniumLabel

func _ready() -> void:
	# Pripojíme sa na signály z lode (DrillTool)
	ship.connect("drill_locked",   Callable(self, "_on_drill_locked"))
	ship.connect("drill_unlocked", Callable(self, "_on_drill_unlocked"))
	# Zobrazíme počiatočné hodnoty
	update_speed_display()
	#update_resource_display()

func _process(_delta: float) -> void:
	update_speed_display()

# --- 📊 Aktualizácia HUD: rýchlosť lode ---
func update_speed_display() -> void:
	var speed: float = ship.velocity.length()
	speed_label.text = "Speed: %.1f m/s" % speed

# --- 📊 Aktualizácia HUD: množstvo surovín ---
#func update_resource_display() -> void:
#    crystal_label.text  = "Crystal: %d"  % ResourceData.get_amount("crystal")
#    fuel_label.text     = "Fuel: %d"     % ResourceData.get_amount("fuel")
#    titanium_label.text = "Titanium: %d" % ResourceData.get_amount("titanium")

# --- 📡 Signálové callbacky zo DrillTool ---
func _on_drill_locked() -> void:
	# Tu môžeme pridať vizuálnu spätnú väzbu pri spustení vŕtania
	pass

#func _on_drill_unlocked() -> void:
#    # Po ukončení vŕtania aktualizujeme suroviny
#    update_resource_display()
