extends Node

signal scene_changing(to_path: String)
signal scene_changed(to_path: String)

const HUB_SCENE: String = "res://scenes/hub/hub.tscn"
const ARENA_SCENE: String = "res://scenes/arena/arena.tscn"

var current_scene_path: String = ""


func go_to_hub() -> void:
	change_scene(HUB_SCENE)


func go_to_arena() -> void:
	change_scene(ARENA_SCENE)


func change_scene(path: String) -> void:
	scene_changing.emit(path)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneManager: failed to change to %s (err %d)" % [path, err])
		return
	current_scene_path = path
	scene_changed.emit(path)
