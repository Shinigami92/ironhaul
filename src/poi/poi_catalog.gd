@tool
class_name PoiCatalog
extends Resource

# The manifest of POIs available for scattering. Loaded once (typically as
# `preload("res://src/poi/poi_catalog.tres")`) by the zone scatter algorithm.
@export var entries: Array[PoiEntry] = []


func entries_for_zone(zone: StringName) -> Array[PoiEntry]:
	var result: Array[PoiEntry] = []
	for entry in entries:
		if entry == null or entry.scene == null:
			continue
		if entry.zone_weights.get(zone, 0.0) > 0.0:
			result.append(entry)
	return result
