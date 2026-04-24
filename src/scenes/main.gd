extends Node


func _ready() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	SceneManager.go_to_hub()
