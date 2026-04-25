class_name Poi
extends Node3D

# Identifier used by the catalog, the scanner readout, and objective-template
# binding. Each authored POI scene sets this on the root node.
@export var poi_type: StringName = &""

# Bounding box on the XZ plane in meters. The scatter algorithm uses this to
# space POIs out and validate the terrain underneath. Treat as a generous outer
# bound — actual collision geometry can be tighter.
@export var footprint: Vector2 = Vector2(20.0, 20.0)


func _ready() -> void:
	add_to_group("poi")


func get_deposits() -> Array[Deposit]:
	var result: Array[Deposit] = []
	for child in get_children():
		if child is Deposit:
			result.append(child)
	return result
