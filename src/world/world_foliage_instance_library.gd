extends RefCounted
class_name WorldFoliageInstanceLibrary

const _ROCK_SHADER: Shader = preload("res://assets/shaders/grass_cel.gdshader")

## Baut die VoxelInstanceLibrary (Gras: bis zu 8 Texturen, aktiv nur [grass_variant_count]; 4 Fels-Meshes).
## Parameter entsprechen den @export-Werten auf VoxelFoliageInstancer, wenn zur Laufzeit gebaut wird.
##
## Hinweis zu snap_to_generator_sdf: Laut Voxel-Tools-Doku braucht das eine Generator-„Series“-Abfrage.
## VoxelGeneratorScript (wie TirTerrainGenerator) unterstützt das i. d. R. nicht — Snap kann dann wirkungslos bleiben.
## Sinnvoll u. a. mit VoxelGeneratorGraph. Gegen „Schweben“ auf LOD-Meshes hilft meist negatives offset_along_normal.
static func build(
		grass_density: float = 0.3,
		rock_density: float = 0.05,
		grass_lod_index: int = 1,
		rock_lod_index: int = 1,
		grass_min_scale: float = 0.5,
		grass_max_scale: float = 0.8,
		grass_variant_count: int = 4,
		grass_offset_along_normal: float = -0.06,
		rock_offset_along_normal: float = -0.12,
		snap_to_generator_sdf: bool = false,
		snap_sample_count: int = 3,
		snap_search_distance: float = 1.2) -> Resource:
	if not ClassDB.class_exists(&"VoxelInstanceLibrary"):
		push_error("WorldFoliageInstanceLibrary: VoxelInstanceLibrary nicht verfügbar (godot_voxel?).")
		return null
	var variants: int = clampi(grass_variant_count, 1, 8)
	var lib = ClassDB.instantiate("VoxelInstanceLibrary")
	var grass_mesh: ArrayMesh = TirGroundCoverMeshes.build_grass_voxel_quad_mesh()
	var next_id: int = 0
	for i in variants:
		var tex := load("res://assets/textures/vegetation/grass_tuft_%d.png" % (i + 1)) as Texture2D
		if tex == null:
			push_error("WorldFoliageInstanceLibrary: grass_tuft_%d.png konnte nicht geladen werden." % (i + 1))
			return null
		var item = ClassDB.instantiate("VoxelInstanceLibraryMultiMeshItem")
		item.mesh = grass_mesh
		item.material_override = _mat_grass_billboard(tex)
		item.lod_index = grass_lod_index
		item.generator = _make_grass_generator(
				grass_density, grass_min_scale, grass_max_scale, grass_offset_along_normal,
				snap_to_generator_sdf, snap_sample_count, snap_search_distance)
		lib.add_item(next_id, item)
		next_id += 1
	for ri in 4:
		var rock_mesh: ArrayMesh = TirGroundCoverMeshes.build_rock_mesh(48211 * 17 + ri * 997)
		var ritem = ClassDB.instantiate("VoxelInstanceLibraryMultiMeshItem")
		ritem.mesh = rock_mesh
		ritem.material_override = _mat_rock()
		ritem.lod_index = rock_lod_index
		ritem.generator = _make_rock_generator(
				rock_density, rock_offset_along_normal,
				snap_to_generator_sdf, snap_sample_count, snap_search_distance)
		lib.add_item(next_id, ritem)
		next_id += 1
	return lib


static func _mat_grass_billboard(tex: Texture2D) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.1
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.albedo_texture = tex
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


static func _mat_rock() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _ROCK_SHADER
	m.set_shader_parameter("cover_kind", 2)
	m.set_shader_parameter("rock_moss", Color(0.290, 0.478, 0.239))
	m.set_shader_parameter("rock_side", Color(0.478, 0.419, 0.333))
	return m


static func _apply_sdf_snap(g: Object, enabled: bool, sample_count: int, search_distance: float) -> void:
	g.snap_to_generator_sdf_enabled = enabled
	if enabled:
		g.snap_to_generator_sdf_sample_count = clampi(sample_count, 1, 8)
		g.snap_to_generator_sdf_search_distance = maxf(0.1, search_distance)


static func _make_grass_generator(
		density: float, min_s: float, max_s: float, offset_along_normal: float,
		snap_sdf: bool, snap_samples: int, snap_dist: float):
	var g = ClassDB.instantiate("VoxelInstanceGenerator")
	g.density = density
	g.emit_mode = VoxelInstanceGenerator.EMIT_FROM_FACES_FAST
	g.min_slope_degrees = 0.0
	g.max_slope_degrees = 30.0
	g.random_rotation = true
	g.random_vertical_flip = false
	g.vertical_alignment = 1.0
	g.offset_along_normal = offset_along_normal
	var lo: float = min(min_s, max_s)
	var hi: float = max(min_s, max_s)
	g.min_scale = lo
	g.max_scale = hi
	_apply_sdf_snap(g, snap_sdf, snap_samples, snap_dist)
	return g


static func _make_rock_generator(
		density: float, offset_along_normal: float,
		snap_sdf: bool, snap_samples: int, snap_dist: float):
	var g = ClassDB.instantiate("VoxelInstanceGenerator")
	g.density = density
	g.emit_mode = VoxelInstanceGenerator.EMIT_FROM_FACES_FAST
	g.min_slope_degrees = 0.0
	g.max_slope_degrees = 60.0
	g.random_rotation = true
	g.random_vertical_flip = false
	g.vertical_alignment = 0.0
	g.offset_along_normal = offset_along_normal
	g.min_scale = 0.46
	g.max_scale = 1.12
	_apply_sdf_snap(g, snap_sdf, snap_samples, snap_dist)
	return g
