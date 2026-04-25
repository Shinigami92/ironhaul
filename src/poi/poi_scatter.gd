@tool
class_name PoiScatter

# Up to `count` POIs from `catalog`'s zone-filtered entries placed inside
# `bounds` (treated as the XZ playable area; `bounds.position.y` and
# `bounds.end.y` map to world Z). Pairwise spacing respects the larger of the
# two placements' `min_distance_to_other_poi`. Pure function — caller passes
# the RNG and decides whether to spawn the resulting scenes.
const _MAX_ATTEMPTS_PER_POI: int = 30


static func scatter(
	catalog: PoiCatalog,
	zone: StringName,
	bounds: Rect2,
	count: int,
	rng: RandomNumberGenerator,
) -> Array[ScatterPlacement]:
	var placements: Array[ScatterPlacement] = []
	if count <= 0 or catalog == null:
		return placements
	var entries := catalog.entries_for_zone(zone)
	if entries.is_empty():
		return placements

	var weight_sum := 0.0
	for entry in entries:
		weight_sum += entry.zone_weights.get(zone, 0.0)
	if weight_sum <= 0.0:
		return placements

	for i in count:
		var entry := _pick_weighted(entries, weight_sum, zone, rng)
		var placement := _try_place(entry, bounds, placements, rng)
		if placement != null:
			placements.append(placement)
	return placements


static func _pick_weighted(
	entries: Array[PoiEntry],
	weight_sum: float,
	zone: StringName,
	rng: RandomNumberGenerator,
) -> PoiEntry:
	var roll := rng.randf() * weight_sum
	var acc := 0.0
	for entry in entries:
		acc += entry.zone_weights.get(zone, 0.0)
		if roll <= acc:
			return entry
	return entries[-1]


static func _try_place(
	entry: PoiEntry,
	bounds: Rect2,
	existing: Array[ScatterPlacement],
	rng: RandomNumberGenerator,
) -> ScatterPlacement:
	for _i in _MAX_ATTEMPTS_PER_POI:
		var x := rng.randf_range(bounds.position.x, bounds.end.x)
		var z := rng.randf_range(bounds.position.y, bounds.end.y)
		var pos := Vector3(x, 0.0, z)
		if _is_far_enough(pos, existing, entry.min_distance_to_other_poi):
			# Random Y rotation for visual variety. The distance check above
			# stays axis-aligned-footprint-based; safe so long as the rotated
			# extent of any POI fits inside its `min_distance_to_other_poi`.
			var rot_y := rng.randf() * TAU
			return ScatterPlacement.new(entry.scene, pos, entry.min_distance_to_other_poi, rot_y)
	return null


static func _is_far_enough(
	pos: Vector3,
	existing: Array[ScatterPlacement],
	new_min_distance: float,
) -> bool:
	for p in existing:
		var required := maxf(new_min_distance, p.min_distance)
		if pos.distance_to(p.position) < required:
			return false
	return true
