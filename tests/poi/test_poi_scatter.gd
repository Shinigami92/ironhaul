extends GutTest

const _REFINERY_SCENE: PackedScene = preload("res://src/poi/refinery/refinery.tscn")
const _COMMS_SCENE: PackedScene = preload("res://src/poi/comms_tower/comms_tower.tscn")


func _make_entry(scene: PackedScene, weight: float, min_dist: float = 30.0) -> PoiEntry:
	var entry := PoiEntry.new()
	entry.scene = scene
	entry.zone_weights = {&"smelter": weight}
	entry.min_distance_to_other_poi = min_dist
	return entry


func _make_catalog(entries: Array[PoiEntry]) -> PoiCatalog:
	var catalog := PoiCatalog.new()
	catalog.entries = entries
	return catalog


func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_empty_catalog_returns_empty() -> void:
	var catalog := PoiCatalog.new()
	var placements := PoiScatter.scatter(
		catalog, &"smelter", Rect2(0, 0, 100, 100), 5, _seeded_rng(1)
	)
	assert_eq(placements.size(), 0)


func test_zone_with_no_entries_returns_empty() -> void:
	var catalog := _make_catalog([_make_entry(_REFINERY_SCENE, 1.0)])
	var placements := PoiScatter.scatter(
		catalog, &"unknown_zone", Rect2(0, 0, 100, 100), 5, _seeded_rng(1)
	)
	assert_eq(placements.size(), 0)


func test_count_zero_returns_empty() -> void:
	var catalog := _make_catalog([_make_entry(_REFINERY_SCENE, 1.0)])
	var placements := PoiScatter.scatter(
		catalog, &"smelter", Rect2(0, 0, 100, 100), 0, _seeded_rng(1)
	)
	assert_eq(placements.size(), 0)


func test_spacious_bounds_places_full_count() -> void:
	var catalog := _make_catalog([_make_entry(_REFINERY_SCENE, 1.0, 20.0)])
	var placements := PoiScatter.scatter(
		catalog, &"smelter", Rect2(-200, -200, 400, 400), 5, _seeded_rng(42)
	)
	assert_eq(placements.size(), 5)


func test_respects_min_distance() -> void:
	var catalog := _make_catalog([_make_entry(_REFINERY_SCENE, 1.0, 25.0)])
	var placements := PoiScatter.scatter(
		catalog, &"smelter", Rect2(-100, -100, 200, 200), 5, _seeded_rng(42)
	)
	for i in placements.size():
		for j in range(i + 1, placements.size()):
			var d: float = placements[i].position.distance_to(placements[j].position)
			var required: float = maxf(placements[i].min_distance, placements[j].min_distance)
			assert_gte(d, required, "pair %d-%d violates min_distance" % [i, j])


func test_tight_bounds_places_fewer() -> void:
	# Bounds smaller than the min-distance — only the first POI fits.
	var catalog := _make_catalog([_make_entry(_REFINERY_SCENE, 1.0, 50.0)])
	var placements := PoiScatter.scatter(
		catalog, &"smelter", Rect2(0, 0, 30, 30), 5, _seeded_rng(42)
	)
	assert_lt(placements.size(), 5)


func test_deterministic_for_same_seed() -> void:
	var entries: Array[PoiEntry] = [
		_make_entry(_REFINERY_SCENE, 1.0),
		_make_entry(_COMMS_SCENE, 0.5, 20.0),
	]
	var catalog := _make_catalog(entries)
	var bounds := Rect2(-200, -200, 400, 400)
	var run1 := PoiScatter.scatter(catalog, &"smelter", bounds, 5, _seeded_rng(99))
	var run2 := PoiScatter.scatter(catalog, &"smelter", bounds, 5, _seeded_rng(99))
	assert_eq(run1.size(), run2.size())
	for i in run1.size():
		assert_eq(run1[i].scene, run2[i].scene)
		assert_eq(run1[i].position, run2[i].position)


func test_uses_real_catalog_with_three_entries() -> void:
	var catalog: PoiCatalog = load("res://src/poi/poi_catalog.tres")
	var placements := PoiScatter.scatter(
		catalog, &"smelter", Rect2(-300, -300, 600, 600), 6, _seeded_rng(7)
	)
	assert_eq(placements.size(), 6)
