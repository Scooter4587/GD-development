# res://scripts/CargoItem.gd
extends Resource

enum CargoType { GENERIC, FUEL, FOOD, MEDICAL }

@export var name: String = ""
@export var type: int = CargoType.GENERIC
@export var weight_per_unit: float = 1.0  # kg na jeden kus
@export var max_stack: int = 100

var quantity: int = 0

func _init(_name: String = "", _type: int = CargoType.GENERIC, _weight_per_unit: float = 1.0, _max_stack: int = 100, _quantity: int = 0) -> void:
    name = _name
    type = _type
    weight_per_unit = _weight_per_unit
    max_stack = _max_stack
    quantity = clamp(_quantity, 0, max_stack)

func get_total_weight() -> float:
    return weight_per_unit * quantity