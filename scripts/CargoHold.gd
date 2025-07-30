# res://scripts/CargoHold.gd
extends Node

signal weight_changed(new_weight: float)

@export var max_capacity: float = 1000.0

var items: Array = []  # pole CargoItem inštancií

func add_cargo(item: Resource, amount: int) -> int:
    var free_cap = max_capacity - get_current_weight()
    var max_addable = floor(free_cap / item.weight_per_unit)
    var to_add = min(amount, max_addable)
    if to_add <= 0:
        return amount  # nič nepridáme

    # najprv na stacky
    for existing in items:
        if existing.name == item.name:
            var space = existing.max_stack - existing.quantity
            var add_here = min(space, to_add)
            existing.quantity += add_here
            to_add -= add_here
            if to_add <= 0:
                emit_weight_changed()
                return 0

    # potom nové staky
    while to_add > 0:
        var new_stack = item.duplicate()
        new_stack.quantity = min(item.max_stack, to_add)
        items.append(new_stack)
        to_add -= new_stack.quantity

    emit_weight_changed()
    return 0

func remove_cargo(item_name: String, amount: int) -> int:
    var to_remove = amount
    for stack in items.duplicate():
        if stack.name == item_name:
            var removed = min(stack.quantity, to_remove)
            stack.quantity -= removed
            to_remove -= removed
            if stack.quantity == 0:
                items.erase(stack)
            if to_remove <= 0:
                break
    emit_weight_changed()
    return amount - to_remove

func get_current_weight() -> float:
    var w = 0.0
    for stack in items:
        w += stack.weight_per_unit * stack.quantity
    return w

func emit_weight_changed() -> void:
    emit_signal("weight_changed", get_current_weight())