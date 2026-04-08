@tool
extends VoxelInstancer

## Liegt `instance_library.tres` vor und hat Einträge, wird sie geladen — dann gelten die @export-Werte hier nicht.
## Zum Tunen per Inspector: Datei entfernen/leeren oder EditorScript neu speichern mit passenden Parametern.
##
## Hinweis: Du kannst stattdessen eine VoxelInstanceLibrary direkt in „Library“ ziehen (z. B. exportierte .tres).
## Dann bleibt diese Zuweisung erhalten (wenn gespeichert); das Script überschreibt sie nicht.
const INSTANCE_LIBRARY_PATH: String = "res://data/instances/world/instance_library.tres"

@export_group("Gras (Performance)")
@export_range(0.01, 2.0, 0.01) var grass_density: float = 0.3
@export_range(0, 4, 1) var grass_lod_index: int = 1
@export_range(1, 8, 1) var grass_variant_count: int = 4
@export_range(0.2, 2.0, 0.01) var grass_min_scale: float = 0.5
@export_range(0.2, 2.0, 0.01) var grass_max_scale: float = 0.8
## Negativ = entlang Boden-Normale in den Untergrund — mindert „Schweben“ auf groben LOD-Meshes.
@export_range(-0.5, 0.5, 0.005) var grass_offset_along_normal: float = -0.06

@export_group("Felsen")
@export_range(0.001, 0.5, 0.001) var rock_density: float = 0.05
@export_range(0, 4, 1) var rock_lod_index: int = 1
@export_range(-0.5, 0.5, 0.005) var rock_offset_along_normal: float = -0.12

@export_group("SDF-Snap (Doku: nur sinnvoll mit passendem Generator)")
## Braucht laut Doku Series-Support im VoxelGenerator — VoxelGeneratorScript meist nicht. Optional testen (z. B. mit Graph).
@export var snap_to_generator_sdf: bool = false
@export_range(1, 8, 1) var snap_sample_count: int = 3
@export_range(0.2, 8.0, 0.1) var snap_search_distance: float = 1.2


func _enter_tree() -> void:
	call_deferred("_ensure_library")


func _ensure_library() -> void:
	if not is_inside_tree():
		return
	# Bereits gesetzt (z. B. manuell im Inspector oder aus gespeicherter Szene)
	if library != null:
		return
	if ResourceLoader.exists(INSTANCE_LIBRARY_PATH):
		var res: Resource = load(INSTANCE_LIBRARY_PATH)
		if res != null and res.has_method(&"get_all_item_ids"):
			var ids: PackedInt32Array = res.get_all_item_ids()
			if ids.size() > 0:
				library = res
				update_configuration_warnings()
				return
	library = WorldFoliageInstanceLibrary.build(
			grass_density,
			rock_density,
			grass_lod_index,
			rock_lod_index,
			grass_min_scale,
			grass_max_scale,
			grass_variant_count,
			grass_offset_along_normal,
			rock_offset_along_normal,
			snap_to_generator_sdf,
			snap_sample_count,
			snap_search_distance)
	update_configuration_warnings()
