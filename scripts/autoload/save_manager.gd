extends Node

signal save_completed()
signal load_completed()

const SAVE_PATH: String = "user://ironhaul_save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"version": 1,
		"player_name": GameState.player_name,
		"loadout": GameState.current_loadout,
		"materials": GameState.materials_inventory,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot open save file for write")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	save_completed.emit()


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot open save file for read")
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: save file malformed")
		return false
	var data: Dictionary = parsed
	GameState.player_name = data.get("player_name", GameState.player_name)
	GameState.set_loadout(data.get("loadout", GameState.current_loadout))
	GameState.materials_inventory = data.get("materials", GameState.materials_inventory)
	load_completed.emit()
	return true
