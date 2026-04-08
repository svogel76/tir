extends Node3D

@export_node_path("VoxelLodTerrain") var terrain_path: NodePath
@export var placement_center: Vector3 = Vector3.ZERO
@export_range(8.0, 400.0, 1.0) var region_radius: float = 118.0
@export_range(4, 200, 1) var tree_count: int = 48
@export_range(6.0, 40.0, 0.5) var min_spacing: float = 14.0
@export_range(8.0, 45.0, 0.5) var max_slope_degrees: float = 22.0
@export_range(0.85, 1.15, 0.01) var uniform_scale_min: float = 0.92
@export_range(0.9, 1.35, 0.01) var uniform_scale_max: float = 1.12

var _terrain: Node = null
var _placed_positions: PackedVector2Array = []


func _ready() -> void:
	call_deferred("_schedule_placement")


func _schedule_placement() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_place_trees()


func _resolve_terrain() -> void:
	if _terrain != null:
		return
	if not terrain_path.is_empty():
		_terrain = get_node_or_null(terrain_path)
	if _terrain == null:
		var scene: Node = get_tree().current_scene
		if scene:
			_terrain = scene.get_node_or_null("Terrain")


func _place_trees() -> void:
	_resolve_terrain()
	if _terrain == null:
		push_warning("TreePlacer: Kein VoxelLodTerrain gefunden.")
		return
	var gen: Variant = _terrain.get("generator")
	if gen == null or not gen.has_method("sample_height_at_world") or not gen.has_method("sample_surface_normal_at_world"):
		push_warning("TreePlacer: Terrain-Generator unterstützt keine Höhenabfrage.")
		return
	_placed_positions.clear()
	var attempts: int = max(tree_count * 80, 400)
	var created: int = 0
	while created < tree_count and attempts > 0:
		attempts -= 1
		var ang: float = randf() * TAU
		var rad: float = sqrt(randf()) * region_radius
		var wx: float = placement_center.x + cos(ang) * rad
		var wz: float = placement_center.z + sin(ang) * rad
		var normal: Vector3 = gen.sample_surface_normal_at_world(wx, wz)
		var slope_deg: float = rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))
		if slope_deg > max_slope_degrees:
			continue
		var xz := Vector2(wx, wz)
		if not _has_clearance(xz):
			continue
		var jitter_x: float = randf_range(-0.6, 0.6)
		var jitter_z: float = randf_range(-0.6, 0.6)
		var px: float = wx + jitter_x
		var pz: float = wz + jitter_z
		var y: float = gen.sample_height_at_world(px, pz)
		var tree := TirProceduralTree.new()
		tree.random_seed = hash(Vector2i(int(wx * 73.0), int(wz * 91.0))) + created * 1337
		tree.variant = _pick_variant(created)
		# Tree origin is trunk foot (y=0 in generated mesh), so place exactly on surface height.
		tree.position = Vector3(px, y, pz)
		tree.rotation.y = randf() * TAU
		var u: float = randf_range(uniform_scale_min, uniform_scale_max)
		tree.scale = Vector3(u, u, u)
		tree.add_to_group("tree")
		add_child(tree)
		_placed_positions.append(xz)
		created += 1


func _has_clearance(xz: Vector2) -> bool:
	for p in _placed_positions:
		if p.distance_to(xz) < min_spacing:
			return false
	return true


func _pick_variant(i: int) -> TirProceduralTree.Variant:
	var roll: int = (i * 13 + int(placement_center.x) * 3 + int(placement_center.z)) % 10
	if roll < 4:
		return TirProceduralTree.Variant.LARGE
	if roll < 8:
		return TirProceduralTree.Variant.MEDIUM
	return TirProceduralTree.Variant.SMALL
