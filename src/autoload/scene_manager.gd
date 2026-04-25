extends Node

signal scene_changing(to_path: String)
signal scene_changed(to_path: String)

const HUB_SCENE: String = "res://src/scenes/hub/hub.tscn"
const ZONE_SCENE: String = "res://src/scenes/zone/zone.tscn"

var current_scene_path: String = ""


func go_to_hub() -> void:
	change_scene(HUB_SCENE)


func go_to_zone() -> void:
	change_scene(ZONE_SCENE)


func change_scene(path: String) -> void:
	scene_changing.emit(path)
	# Deferred so it's safe to call from a scene's _ready() or from signal
	# callbacks — the actual swap happens on the next idle frame, when the
	# current scene is no longer in the middle of being added to the tree.
	_do_change_scene.call_deferred(path)


func _do_change_scene(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneManager: failed to change to %s (err %d)" % [path, err])
		return
	current_scene_path = path
	scene_changed.emit(path)
