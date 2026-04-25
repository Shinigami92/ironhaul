@tool
class_name ScatterPlacement
extends RefCounted

# A single placement decision returned by `PoiScatter.scatter`. The caller
# decides what to do with these (instantiate, parent into the scene tree, etc).
# `min_distance` travels with the placement so future spacing checks against
# this placement can use `max(other.min_distance, this.min_distance)`.
# `rotation_y` is a Y-axis rotation in radians; the distance algorithm stays
# axis-aligned, so rotation is purely visual variety.
var scene: PackedScene
var position: Vector3
var min_distance: float
var rotation_y: float


func _init(
	p_scene: PackedScene, p_position: Vector3, p_min_distance: float, p_rotation_y: float = 0.0
) -> void:
	scene = p_scene
	position = p_position
	min_distance = p_min_distance
	rotation_y = p_rotation_y
