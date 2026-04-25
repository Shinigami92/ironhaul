@tool
extends Node3D

# `@tool` so the fixed-seed POI scatter renders inside the Godot editor when
# zone.tscn is opened. The static geometry (perimeter walls, ground, lighting,
# return-zone marker, player spawn) is authored directly in zone.tscn.
# Dynamic spawning (player mech, enemies, HUD) is guarded by
# `Engine.is_editor_hint()` so the editor only shows the world, not runtime
# entities.

const ZONE_HALF: float = 250.0  # full zone is 500×500m
const KILL_PLANE_Y: float = -20.0
const PLAYER_RESPAWN_DELAY_SEC: float = 2.0
const GRUNT_RESPAWN_DELAY_SEC: float = 10.0

# POI scattering configuration. `POI_BOUNDS_INSET` keeps scattered POIs away
# from the perimeter walls; the *_CLEAR_RADIUS values keep them off the
# player spawn and the return-zone marker. Editor preview uses a fixed seed
# so the layout doesn't reshuffle on every scene reload.
const ZONE_TAG: StringName = &"smelter"
const POI_COUNT: int = 8
const POI_BOUNDS_INSET: float = 50.0
const POI_SPAWN_CLEAR_RADIUS: float = 30.0
const POI_RETURN_CLEAR_RADIUS: float = 25.0
const POI_EDITOR_PREVIEW_SEED: int = 0
const POI_CATALOG := preload("res://src/poi/poi_catalog.tres")

# Grunt spawn points — one grunt spawns per point on zone load, and the
# corresponding point respawns GRUNT_RESPAWN_DELAY_SEC after each death.
const ENEMY_SPAWN_POINTS: Array[Vector3] = [
	Vector3(0, 0.2, -100),
	Vector3(0, 0.2, 100),
	Vector3(100, 0.2, 0),
	Vector3(-100, 0.2, 0),
	Vector3(80, 0.2, -80),
	Vector3(-80, 0.2, 80),
]

const GRUNT_SCENE := preload("res://src/enemy/grunt/grunt.tscn")
const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")
const MECH_SCENE := preload("res://src/mech/mech.tscn")

var player: Mech
var player_in_return: bool = false

var _player_respawn_triggered: bool = false

@onready var return_area: Area3D = %ReturnArea
@onready var return_label: Label3D = %ReturnLabel
@onready var player_spawn: Marker3D = %PlayerSpawn


func _ready() -> void:
	_scatter_pois()

	if Engine.is_editor_hint():
		return

	_spawn_player()
	player.died.connect(_on_player_died)
	_spawn_initial_grunts()
	_spawn_hud()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if player_in_return and Input.is_action_just_pressed("interact"):
		SaveManager.save_game()
		SceneManager.go_to_hub()
	_check_kill_plane()


func _check_kill_plane() -> void:
	for node in get_tree().get_nodes_in_group("player_mech"):
		_maybe_kill_by_plane(node)
	for node in get_tree().get_nodes_in_group("enemy_mech"):
		_maybe_kill_by_plane(node)


func _maybe_kill_by_plane(node: Node) -> void:
	if not (node is Mech):
		return
	var mech := node as Mech
	if mech.is_dead:
		return
	if mech.global_position.y < KILL_PLANE_Y:
		# Overkill guarantees the died signal fires regardless of max_health tuning.
		mech.take_damage(mech.max_health * 10.0)


func _on_player_died() -> void:
	if _player_respawn_triggered:
		return
	_player_respawn_triggered = true
	await get_tree().create_timer(PLAYER_RESPAWN_DELAY_SEC).timeout
	SceneManager.go_to_hub()


func _spawn_initial_grunts() -> void:
	for i in ENEMY_SPAWN_POINTS.size():
		_spawn_grunt_at(i)


func _spawn_grunt_at(spawn_index: int) -> void:
	var grunt: Grunt = GRUNT_SCENE.instantiate()
	grunt.position = ENEMY_SPAWN_POINTS[spawn_index]
	grunt.died.connect(_on_grunt_died.bind(spawn_index))
	add_child(grunt)


func _on_grunt_died(spawn_index: int) -> void:
	await get_tree().create_timer(GRUNT_RESPAWN_DELAY_SEC).timeout
	if not is_inside_tree():
		return
	_spawn_grunt_at(spawn_index)


func _scatter_pois() -> void:
	var rng := RandomNumberGenerator.new()
	if Engine.is_editor_hint():
		rng.seed = POI_EDITOR_PREVIEW_SEED
	else:
		rng.randomize()
	var inset := POI_BOUNDS_INSET
	var size := (ZONE_HALF - inset) * 2.0
	var bounds := Rect2(-ZONE_HALF + inset, -ZONE_HALF + inset, size, size)
	var placements := PoiScatter.scatter(POI_CATALOG, ZONE_TAG, bounds, POI_COUNT, rng)
	for p in placements:
		# Discard placements that would clip the player spawn or the return
		# marker — better a slightly under-count zone than a POI on top of
		# either landmark.
		if p.position.distance_to(player_spawn.position) < POI_SPAWN_CLEAR_RADIUS:
			continue
		if p.position.distance_to(return_area.position) < POI_RETURN_CLEAR_RADIUS:
			continue
		var instance: Node3D = p.scene.instantiate()
		instance.position = p.position
		instance.rotation.y = p.rotation_y
		add_child(instance)


func _on_return_enter(body: Node) -> void:
	if body is Mech and not (body as Mech).is_enemy:
		player_in_return = true
		return_label.visible = true


func _on_return_exit(body: Node) -> void:
	if body is Mech and not (body as Mech).is_enemy:
		player_in_return = false
		return_label.visible = false


func _spawn_player() -> void:
	player = MECH_SCENE.instantiate()
	player.is_enemy = false
	player.position = player_spawn.position
	add_child(player)


func _spawn_hud() -> void:
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	add_child(hud)
