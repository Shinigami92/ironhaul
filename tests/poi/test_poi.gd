extends GutTest


func test_poi_collects_deposits() -> void:
	var poi := Poi.new()
	add_child_autofree(poi)
	var dep1 := Deposit.new()
	var dep2 := Deposit.new()
	poi.add_child(dep1)
	poi.add_child(dep2)
	var deposits := poi.get_deposits()
	assert_eq(deposits.size(), 2)


func test_poi_ignores_non_deposit_children() -> void:
	var poi := Poi.new()
	add_child_autofree(poi)
	poi.add_child(Node3D.new())
	poi.add_child(Deposit.new())
	assert_eq(poi.get_deposits().size(), 1)


func test_deposit_assign_sets_fields() -> void:
	var dep := Deposit.new()
	add_child_autofree(dep)
	dep.assign(&"structural", 75.0)
	assert_eq(dep.ore_type, &"structural")
	assert_eq(dep.yield_amount, 75.0)


func test_deposit_joins_group_on_ready() -> void:
	var dep := Deposit.new()
	add_child_autofree(dep)
	assert_true(dep.is_in_group("deposit"))


func test_poi_joins_group_on_ready() -> void:
	var poi := Poi.new()
	add_child_autofree(poi)
	assert_true(poi.is_in_group("poi"))


func test_refinery_scene_loads_with_three_deposits() -> void:
	var scene: PackedScene = load("res://src/poi/refinery/refinery.tscn")
	var refinery := scene.instantiate() as Poi
	add_child_autofree(refinery)
	assert_eq(refinery.poi_type, &"refinery")
	assert_eq(refinery.get_deposits().size(), 3)


func test_comms_tower_scene_loads_with_two_deposits() -> void:
	var scene: PackedScene = load("res://src/poi/comms_tower/comms_tower.tscn")
	var tower := scene.instantiate() as Poi
	add_child_autofree(tower)
	assert_eq(tower.poi_type, &"comms_tower")
	assert_eq(tower.get_deposits().size(), 2)


func test_catalog_filters_entries_by_zone() -> void:
	var catalog: PoiCatalog = load("res://src/poi/poi_catalog.tres")
	assert_eq(catalog.entries_for_zone(&"smelter").size(), 2)
	assert_eq(catalog.entries_for_zone(&"nonexistent_zone").size(), 0)
