class_name Deposit
extends Node3D

# Set at runtime by zone-loading code based on the zone's ore-weight roll.
# Empty StringName means "not yet assigned" — placement code should wait until
# assign() has been called before letting the player deploy a miner here.
@export var ore_type: StringName = &""
@export var yield_amount: float = 100.0


func _ready() -> void:
	add_to_group("deposit")


func assign(type: StringName, yield_value: float) -> void:
	ore_type = type
	yield_amount = yield_value
