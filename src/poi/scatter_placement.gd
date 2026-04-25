class_name ScatterPlacement
extends RefCounted

# A single placement decision returned by `PoiScatter.scatter`. The caller
# decides what to do with these (instantiate, parent into the scene tree, etc).
# `min_distance` travels with the placement so future spacing checks against
# this placement can use `max(other.min_distance, this.min_distance)`.
var scene: PackedScene
var position: Vector3
var min_distance: float


func _init(p_scene: PackedScene, p_position: Vector3, p_min_distance: float) -> void:
	scene = p_scene
	position = p_position
	min_distance = p_min_distance
