class_name PoiEntry
extends Resource

# A single row in the POI catalog. The scatter algorithm reads `zone_weights`
# given a zone tag to decide how often this POI shows up. A zone tag missing
# from `zone_weights` means "this POI never appears in that zone."
@export var scene: PackedScene
@export var zone_weights: Dictionary = {}
@export var min_distance_to_other_poi: float = 30.0
