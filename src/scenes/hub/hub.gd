extends Node3D

const MECH_SCENE := preload("res://src/mech/mech.tscn")
const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")

var player: Mech
var player_in_terminal: bool = false

@onready var prompt_label: Label3D = %PromptLabel
@onready var player_spawn: Marker3D = %PlayerSpawn


func _ready() -> void:
	_spawn_player()
	_spawn_hud()


func _process(_delta: float) -> void:
	if player_in_terminal and Input.is_action_just_pressed("interact"):
		SaveManager.save_game()
		SceneManager.go_to_zone()


func _spawn_player() -> void:
	player = MECH_SCENE.instantiate()
	player.is_enemy = false
	player.position = player_spawn.position
	add_child(player)


func _spawn_hud() -> void:
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	add_child(hud)


func _on_terminal_enter(body: Node) -> void:
	if body is Mech and not (body as Mech).is_enemy:
		player_in_terminal = true
		prompt_label.visible = true


func _on_terminal_exit(body: Node) -> void:
	if body is Mech and not (body as Mech).is_enemy:
		player_in_terminal = false
		prompt_label.visible = false
