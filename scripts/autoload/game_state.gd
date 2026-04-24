extends Node

signal loadout_changed(loadout: Dictionary)
signal materials_changed(inventory: Dictionary)

var player_name: String = "Hauler"
var current_loadout: Dictionary = {
	"head": "default",
	"core": "default",
	"arms": "default",
	"legs": "default",
	"weapon_primary": "default",
	"weapon_secondary": "default",
}
var materials_inventory: Dictionary = {
	"scrap": 0,
	"ore": 0,
}


func set_loadout(new_loadout: Dictionary) -> void:
	current_loadout = new_loadout.duplicate()
	loadout_changed.emit(current_loadout)


func add_material(kind: String, amount: int) -> void:
	materials_inventory[kind] = materials_inventory.get(kind, 0) + amount
	materials_changed.emit(materials_inventory)


func reset_run_state() -> void:
	pass
