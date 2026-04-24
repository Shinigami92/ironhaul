extends CanvasLayer

var player: Mech

@onready var health_bar: ProgressBar = %HealthBar
@onready var heat_bar: ProgressBar = %HeatBar
@onready var thrust_bar: ProgressBar = %ThrustBar
@onready var status_label: Label = %StatusLabel
@onready var materials_label: Label = %MaterialsLabel


func _ready() -> void:
	_find_and_connect_player()
	GameState.materials_changed.connect(_on_materials_changed)
	_on_materials_changed(GameState.materials_inventory)


func _find_and_connect_player() -> void:
	await get_tree().process_frame
	var mechs := get_tree().get_nodes_in_group("player_mech")
	if mechs.is_empty():
		return
	player = mechs[0] as Mech
	if player == null:
		return
	player.health_changed.connect(_on_health_changed)
	player.heat_changed.connect(_on_heat_changed)
	player.thrust_changed.connect(_on_thrust_changed)
	player.overheated.connect(_on_overheated)
	player.cooled.connect(_on_cooled)
	player.died.connect(_on_died)
	_on_health_changed(player.health.current, player.health.maximum)
	_on_heat_changed(player.heat.current, player.heat.maximum)
	_on_thrust_changed(player.thrust.current, player.thrust.maximum)


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current


func _on_heat_changed(current: float, max_value: float) -> void:
	heat_bar.max_value = max_value
	heat_bar.value = current


func _on_thrust_changed(current: float, max_value: float) -> void:
	thrust_bar.max_value = max_value
	thrust_bar.value = current


func _on_overheated() -> void:
	status_label.text = "OVERHEATED"


func _on_cooled() -> void:
	status_label.text = ""


func _on_died() -> void:
	status_label.text = "DESTROYED"


func _on_materials_changed(inventory: Dictionary) -> void:
	materials_label.text = (
		"Scrap: %d    Ore: %d"
		% [
			inventory.get("scrap", 0),
			inventory.get("ore", 0),
		]
	)
