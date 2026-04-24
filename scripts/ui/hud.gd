extends CanvasLayer

var player: Mech
var health_bar: ProgressBar
var heat_bar: ProgressBar
var status_label: Label
var materials_label: Label
var hint_label: Label
var crosshair: Control


func _ready() -> void:
	_build_ui()
	_find_and_connect_player()
	GameState.materials_changed.connect(_on_materials_changed)
	_on_materials_changed(GameState.materials_inventory)


func _build_ui() -> void:
	crosshair = CrosshairControl.new()
	crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crosshair)

	var panel := Control.new()
	panel.position = Vector2(24, 24)
	add_child(panel)

	health_bar = ProgressBar.new()
	health_bar.size = Vector2(260, 20)
	health_bar.position = Vector2(0, 0)
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.show_percentage = false
	panel.add_child(health_bar)

	heat_bar = ProgressBar.new()
	heat_bar.size = Vector2(260, 20)
	heat_bar.position = Vector2(0, 28)
	heat_bar.min_value = 0
	heat_bar.max_value = 100
	heat_bar.show_percentage = false
	panel.add_child(heat_bar)

	status_label = Label.new()
	status_label.position = Vector2(0, 56)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.25))
	panel.add_child(status_label)

	materials_label = Label.new()
	materials_label.position = Vector2(0, 84)
	panel.add_child(materials_label)

	hint_label = Label.new()
	hint_label.position = Vector2(0, 112)
	hint_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.85))
	hint_label.text = "WASD move  ·  SPACE thrust  ·  SHIFT dodge  ·  LMB/RMB fire  ·  E interact  ·  ESC free mouse"
	panel.add_child(hint_label)


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
	player.overheated.connect(_on_overheated)
	player.cooled.connect(_on_cooled)
	player.died.connect(_on_died)
	_on_health_changed(player.current_health, player.max_health)
	_on_heat_changed(player.current_heat, player.max_heat)


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current


func _on_heat_changed(current: float, max_value: float) -> void:
	heat_bar.max_value = max_value
	heat_bar.value = current


func _on_overheated() -> void:
	status_label.text = "OVERHEATED"


func _on_cooled() -> void:
	status_label.text = ""


func _on_died() -> void:
	status_label.text = "DESTROYED"


func _on_materials_changed(inventory: Dictionary) -> void:
	materials_label.text = "Scrap: %d    Ore: %d" % [
		inventory.get("scrap", 0),
		inventory.get("ore", 0),
	]


class CrosshairControl extends Control:
	func _draw() -> void:
		var center := size / 2
		var color := Color(0.4, 0.9, 0.85, 0.85)
		draw_line(center - Vector2(7, 0), center + Vector2(7, 0), color, 2.0)
		draw_line(center - Vector2(0, 7), center + Vector2(0, 7), color, 2.0)
		draw_circle(center, 1.5, color)
