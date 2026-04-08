extends RefCounted
class_name TirGroundCoverMeshes

## Quad für VoxelInstancer-Gras: 1.0×0.8, UV unten→oben wie Texturen, Normale +Z (eine Fläche).
const GRASS_VOXEL_WIDTH: float = 1.0
const GRASS_VOXEL_HEIGHT: float = 0.8


static func build_grass_voxel_quad_mesh() -> ArrayMesh:
	var hw: float = GRASS_VOXEL_WIDTH * 0.5
	var h: float = GRASS_VOXEL_HEIGHT
	var vertices := PackedVector3Array([
		Vector3(-hw, 0.0, 0.0),
		Vector3(hw, 0.0, 0.0),
		Vector3(hw, h, 0.0),
		Vector3(-hw, h, 0.0),
	])
	var uvs := PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(1.0, 0.0),
		Vector2(0.0, 0.0),
	])
	var n := Vector3(0.0, 0.0, 1.0)
	var normals := PackedVector3Array([n, n, n, n])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Drei vertikale Quads um Y um 0° / 60° / 120°; 0.12 breit, 0.18 hoch; UV.y: unten Stiel, oben Blüte.
static func build_flower_mesh() -> ArrayMesh:
	var half_w: float = 0.06
	var h: float = 0.18
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for deg in [0.0, 60.0, 120.0]:
		_flower_quad_y_rotated(st, half_w, h, deg_to_rad(deg))
	st.generate_normals()
	return st.commit()


static func _flower_quad_y_rotated(st: SurfaceTool, half_w: float, h: float, y_rad: float) -> void:
	var b := Basis.from_euler(Vector3(0.0, y_rad, 0.0))
	var bl := b * Vector3(-half_w, 0.0, 0.0)
	var br := b * Vector3(half_w, 0.0, 0.0)
	var tl := b * Vector3(-half_w, h, 0.0)
	var top_r := b * Vector3(half_w, h, 0.0)
	st.set_uv(Vector2(0.5, 0.0))
	st.add_vertex(bl)
	st.set_uv(Vector2(0.5, 0.0))
	st.add_vertex(br)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(tl)
	st.set_uv(Vector2(0.5, 0.0))
	st.add_vertex(br)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(top_r)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(tl)


static func build_rock_mesh(rock_seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rock_seed
	var min_y: float = -0.42
	var max_y: float = rng.randf_range(0.62, 1.08)
	var sx: float = rng.randf_range(0.46, 0.88)
	var sz: float = rng.randf_range(0.46, 0.88)
	var p: PackedVector3Array = []
	for i in 8:
		var bx: float = -sx if (i & 1) == 0 else sx
		var by: float = min_y if (i & 2) == 0 else max_y
		var bz: float = -sz if (i & 4) == 0 else sz
		var j := Vector3(
			rng.randf_range(-0.11, 0.11),
			rng.randf_range(-0.09, 0.09),
			rng.randf_range(-0.11, 0.11)
		)
		if (i & 2) != 0:
			j.y += rng.randf_range(0.025, 0.095)
		p.append(Vector3(bx, by, bz) + j)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_tri(st, p[0], p[1], p[3])
	_add_tri(st, p[0], p[3], p[2])
	_add_tri(st, p[4], p[5], p[6])
	_add_tri(st, p[5], p[7], p[6])
	_add_tri(st, p[0], p[4], p[6])
	_add_tri(st, p[0], p[6], p[2])
	_add_tri(st, p[1], p[3], p[5])
	_add_tri(st, p[3], p[7], p[5])
	_add_tri(st, p[0], p[1], p[4])
	_add_tri(st, p[1], p[5], p[4])
	_add_tri(st, p[2], p[3], p[6])
	_add_tri(st, p[3], p[7], p[6])
	st.generate_normals()
	return st.commit()


static func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.set_uv(Vector2(0.0, 0.5))
	st.add_vertex(a)
	st.set_uv(Vector2(0.5, 0.5))
	st.add_vertex(b)
	st.set_uv(Vector2(0.25, 1.0))
	st.add_vertex(c)
