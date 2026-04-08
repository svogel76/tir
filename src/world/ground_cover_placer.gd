extends Node3D

const _FLOWER_SHADER: Shader = preload("res://assets/shaders/flower_cel.gdshader")

@export_node_path("VoxelLodTerrain") var terrain_path: NodePath
@export var placement_center: Vector3 = Vector3.ZERO
@export_range(30.0, 380.0, 1.0) var region_radius: float = 118.0

## Wiesen-Patch-Zentren (nur für Blumen-Streuung; Gras liegt beim VoxelInstancer).
@export_range(20, 320, 1) var grass_cluster_count: int = 175
@export_range(8.0, 38.0, 0.5) var grass_max_slope_deg: float = 28.0
@export_range(2.8, 14.0, 0.5) var tree_clear_grass: float = 5.5

@export_range(0.0, 1.0, 0.02) var flower_near_grass_chance: float = 0.58
@export_range(0, 80, 1) var standalone_flower_clusters: int = 22
@export_range(4.0, 18.0, 0.5) var flower_max_slope_deg: float = 9.0
@export_range(3.0, 16.0, 0.5) var tree_clear_flower: float = 6.8
@export_range(0.42, 0.55, 0.01) var flower_yellow_weight: float = 0.5

@export var placement_random_seed: int = 48211
@export_range(6, 90, 1) var physics_frames_wait: int = 16
@export_range(0, 50, 1) var extra_frames_if_no_trees: int = 10

var _terrain: Node = null


func _ready() -> void:
	call_deferred("_run_placement")


func _run_placement() -> void:
	for i in physics_frames_wait:
		await get_tree().physics_frame
	if get_tree().get_nodes_in_group("tree").is_empty() and extra_frames_if_no_trees > 0:
		for j in extra_frames_if_no_trees:
			await get_tree().physics_frame
	_place_flowers_only()


func _resolve_terrain() -> void:
	if _terrain != null:
		return
	if not terrain_path.is_empty():
		_terrain = get_node_or_null(terrain_path)
	if _terrain == null:
		var scene: Node = get_tree().current_scene
		if scene:
			_terrain = scene.get_node_or_null("Terrain")


func _place_flowers_only() -> void:
	_resolve_terrain()
	if _terrain == null:
		push_warning("GroundCoverPlacer: Kein VoxelLodTerrain gefunden.")
		return
	var gen: Variant = _terrain.get("generator")
	if gen == null or not gen.has_method("sample_height_at_world") or not gen.has_method("sample_surface_normal_at_world"):
		push_warning("GroundCoverPlacer: Generator ohne sample_height / sample_surface_normal.")
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = placement_random_seed

	var flower_mesh: ArrayMesh = TirGroundCoverMeshes.build_flower_mesh()
	var mat_flower_y: ShaderMaterial = _mat_flower_yellow()
	var mat_flower_w: ShaderMaterial = _mat_flower_white()

	var fy_xf: Array[Transform3D] = []
	var fw_xf: Array[Transform3D] = []
	var meadow_centers: Array[Vector3] = []

	var tree_g_sq: float = tree_clear_grass * tree_clear_grass
	var tree_f_sq: float = tree_clear_flower * tree_clear_flower

	var attempts: int = grass_cluster_count * 55
	var patches_made: int = 0
	while patches_made < grass_cluster_count and attempts > 0:
		attempts -= 1
		var ang: float = rng.randf() * TAU
		var rad: float = sqrt(rng.randf()) * region_radius
		var cx: float = placement_center.x + cos(ang) * rad
		var cz: float = placement_center.z + sin(ang) * rad
		var nrm: Vector3 = gen.sample_surface_normal_at_world(cx, cz)
		var slope: float = rad_to_deg(acos(clampf(nrm.y, -1.0, 1.0)))
		if slope > grass_max_slope_deg:
			continue
		if _min_tree_dist_sq(Vector2(cx, cz)) < tree_g_sq:
			continue
		var cy: float = gen.sample_height_at_world(cx, cz)
		meadow_centers.append(Vector3(cx, cy, cz))
		patches_made += 1

	for gc in meadow_centers:
		if rng.randf() > flower_near_grass_chance:
			continue
		var fo: Vector3 = Vector3(rng.randf_range(-1.15, 1.15), 0.0, rng.randf_range(-1.15, 1.15))
		var fcx: float = gc.x + fo.x
		var fcz: float = gc.z + fo.z
		var fn: Vector3 = gen.sample_surface_normal_at_world(fcx, fcz)
		var fslope: float = rad_to_deg(acos(clampf(fn.y, -1.0, 1.0)))
		if fslope > flower_max_slope_deg:
			continue
		if _min_tree_dist_sq(Vector2(fcx, fcz)) < tree_f_sq:
			continue
		var fr: float = rng.randf_range(0.48, 2.2)
		var nf: int = rng.randi_range(14, 30)
		for fi in nf:
			var rx: float = rng.randf_range(-fr, fr)
			var rz: float = rng.randf_range(-fr, fr)
			if rx * rx + rz * rz > fr * fr:
				continue
			var qx: float = fcx + rx
			var qz: float = fcz + rz
			var qn: Vector3 = gen.sample_surface_normal_at_world(qx, qz)
			var qslope: float = rad_to_deg(acos(clampf(qn.y, -1.0, 1.0)))
			if qslope > flower_max_slope_deg:
				continue
			if _min_tree_dist_sq(Vector2(qx, qz)) < tree_f_sq:
				continue
			var qy: float = gen.sample_height_at_world(qx, qz) + 0.028
			var basis_f: Basis = _basis_y_axis(qn)
			var tilt_x: float = deg_to_rad(rng.randf_range(-20.0, 20.0))
			var tilt_z: float = deg_to_rad(rng.randf_range(-20.0, 20.0))
			basis_f = basis_f * Basis.from_euler(Vector3(tilt_x, rng.randf() * TAU * 0.12, tilt_z))
			var yellow: bool = rng.randf() < flower_yellow_weight
			var hf: float = rng.randf_range(0.6, 0.9)
			var xf: Transform3D = Transform3D(basis_f.scaled(Vector3(hf, hf, hf)), Vector3(qx, qy, qz))
			if yellow:
				fy_xf.append(xf)
			else:
				fw_xf.append(xf)

	for si in standalone_flower_clusters:
		var sang: float = rng.randf() * TAU
		var srd: float = sqrt(rng.randf()) * region_radius
		var scx: float = placement_center.x + cos(sang) * srd
		var scz: float = placement_center.z + sin(sang) * srd
		var sn: Vector3 = gen.sample_surface_normal_at_world(scx, scz)
		if rad_to_deg(acos(clampf(sn.y, -1.0, 1.0))) > flower_max_slope_deg:
			continue
		if _min_tree_dist_sq(Vector2(scx, scz)) < tree_f_sq:
			continue
		var sfr: float = rng.randf_range(0.52, 2.0)
		var sfn: int = rng.randi_range(10, 24)
		for sfj in sfn:
			var sx: float = rng.randf_range(-sfr, sfr)
			var sz: float = rng.randf_range(-sfr, sfr)
			if sx * sx + sz * sz > sfr * sfr:
				continue
			var px: float = scx + sx
			var pz: float = scz + sz
			var pn2: Vector3 = gen.sample_surface_normal_at_world(px, pz)
			if rad_to_deg(acos(clampf(pn2.y, -1.0, 1.0))) > flower_max_slope_deg:
				continue
			if _min_tree_dist_sq(Vector2(px, pz)) < tree_f_sq:
				continue
			var py: float = gen.sample_height_at_world(px, pz) + 0.028
			var b2: Basis = _basis_y_axis(pn2)
			b2 = b2 * Basis.from_euler(Vector3(deg_to_rad(rng.randf_range(-20.0, 20.0)), rng.randf() * 0.15 * TAU, deg_to_rad(rng.randf_range(-20.0, 20.0))))
			var yel: bool = rng.randf() < flower_yellow_weight
			var hs: float = rng.randf_range(0.6, 0.9)
			var txf: Transform3D = Transform3D(b2.scaled(Vector3(hs, hs, hs)), Vector3(px, py, pz))
			if yel:
				fy_xf.append(txf)
			else:
				fw_xf.append(txf)

	_spawn_multimesh("flowers_yellow", flower_mesh, mat_flower_y, fy_xf)
	_spawn_multimesh("flowers_white", flower_mesh, mat_flower_w, fw_xf)


func _spawn_multimesh(node_name: String, mesh: ArrayMesh, mat: Material, xforms: Array) -> void:
	var n: int = xforms.size()
	if n <= 0:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = n
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	add_child(mmi)
	for i in n:
		mm.set_instance_transform(i, xforms[i])


func _min_tree_dist_sq(xz: Vector2) -> float:
	var best: float = INF
	for node in get_tree().get_nodes_in_group("tree"):
		if not (node is Node3D):
			continue
		var g: Vector3 = (node as Node3D).global_position
		var d: float = xz.distance_squared_to(Vector2(g.x, g.z))
		if d < best:
			best = d
	return best


func _basis_y_axis(axis_y: Vector3) -> Basis:
	var y := axis_y.normalized()
	var x := Vector3.UP.cross(y)
	if x.length_squared() < 1e-7:
		x = Vector3.RIGHT.cross(y)
	x = x.normalized()
	var z := x.cross(y).normalized()
	x = y.cross(z).normalized()
	return Basis(x, y, z)


func _mat_flower_yellow() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _FLOWER_SHADER
	m.set_shader_parameter("flower_color", Color(0.960784, 0.772549, 0.258824))
	m.set_shader_parameter("stem_color", Color(0.176471, 0.329412, 0.14902))
	return m


func _mat_flower_white() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _FLOWER_SHADER
	m.set_shader_parameter("flower_color", Color(0.960784, 0.941176, 0.909804))
	m.set_shader_parameter("stem_color", Color(0.176471, 0.329412, 0.14902))
	return m
