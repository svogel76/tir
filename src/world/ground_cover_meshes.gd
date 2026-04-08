extends RefCounted
class_name TirGroundCoverMeshes

const GRASS_BLADE_SEGMENTS: int = 8
const GRASS_TUFT_BLADE_COUNT: int = 8
## Referenzlänge pro Büschel (Placer skaliert 0.25–0.45 world).
const GRASS_LENGTH_UNIT: float = 0.38
const GRASS_LEAN_MAX: float = 0.32


static func build_grass_tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var angles: PackedFloat32Array = PackedFloat32Array([
		0.0, 0.74, 1.48, 2.23, 2.97, 3.71, 4.45, 5.2
	])
	for b in GRASS_TUFT_BLADE_COUNT:
		_append_blade_ribbon(st, angles[b], float(b))
	st.generate_normals()
	return st.commit()


static func _blade_width_at(t: float) -> float:
	if t < 0.18:
		return lerpf(0.018, 0.048, t / 0.18)
	if t < 0.52:
		return lerpf(0.048, 0.10, (t - 0.18) / 0.34)
	return lerpf(0.10, 0.014, clampf((t - 0.52) / 0.48, 0.0, 1.0))


## Blatt in der Ebene (Radial, Hoch): Mitte der Kante wandert entlang +rad_flat vom Stamm weg.
static func _append_blade_ribbon(st: SurfaceTool, y_rot: float, blade_id: float) -> void:
	var len: float = GRASS_LENGTH_UNIT
	var segs: int = GRASS_BLADE_SEGMENTS
	var rad_flat := Vector3(cos(y_rot), 0.0, sin(y_rot))
	var bitan := Vector3.UP.cross(rad_flat)
	if bitan.length_squared() < 1e-8:
		bitan = Vector3.FORWARD
	bitan = bitan.normalized()
	var prev_l: Vector3
	var prev_r: Vector3
	var prev_uv_l: Vector2
	var prev_uv_r: Vector2
	var has_prev := false
	for s in segs + 1:
		var t: float = float(s) / float(segs)
		var ease_out: float = 1.0 - cos(t * PI * 0.5)
		var h: float = t * len
		var lean: float = GRASS_LEAN_MAX * ease_out
		var uplift: float = 0.035 * sin(t * PI)
		var center := rad_flat * lean + Vector3(0.0, h + uplift, 0.0)
		var w: float = _blade_width_at(t)
		var lp_l := center + bitan * (w * 0.5)
		var lp_r := center - bitan * (w * 0.5)
		var uv_y: float = clampf(h / maxf(len, 0.001), 0.0, 1.0)
		var uv_l := Vector2(blade_id * 0.001, uv_y)
		var uv_r := Vector2(blade_id * 0.001 + 0.0002, uv_y)
		if has_prev:
			st.set_uv(prev_uv_l)
			st.add_vertex(prev_l)
			st.set_uv(uv_l)
			st.add_vertex(lp_l)
			st.set_uv(prev_uv_r)
			st.add_vertex(prev_r)
			st.set_uv(prev_uv_r)
			st.add_vertex(prev_r)
			st.set_uv(uv_l)
			st.add_vertex(lp_l)
			st.set_uv(uv_r)
			st.add_vertex(lp_r)
		prev_l = lp_l
		prev_r = lp_r
		prev_uv_l = uv_l
		prev_uv_r = uv_r
		has_prev = true


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
	var tr := b * Vector3(half_w, h, 0.0)
	st.set_uv(Vector2(0.5, 0.0))
	st.add_vertex(bl)
	st.set_uv(Vector2(0.5, 0.0))
	st.add_vertex(br)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(tl)
	st.set_uv(Vector2(0.5, 0.0))
	st.add_vertex(br)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(tr)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(tl)


static func build_rock_mesh(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
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
