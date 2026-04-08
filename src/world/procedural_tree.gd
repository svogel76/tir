extends Node3D
class_name TirProceduralTree

enum Variant { LARGE, MEDIUM, SMALL }

const _SHADER: Shader = preload("res://assets/shaders/tree_cel.gdshader")

static var _trunk_material: ShaderMaterial
static var _foliage_material: ShaderMaterial

@export var variant: Variant = Variant.MEDIUM
@export var random_seed: int = 0

var _rng := RandomNumberGenerator.new()
var _bend_dir: Vector3 = Vector3.RIGHT


func _ready() -> void:
	_ensure_shared_materials()
	if get_child_count() == 0:
		rebuild()


static func sync_moonlight(strength: float, color: Color, direction: Vector3) -> void:
	_ensure_shared_materials()
	var dirn := direction.normalized()
	_trunk_material.set_shader_parameter("moonlight_strength", strength)
	_trunk_material.set_shader_parameter("moonlight_color", color)
	_trunk_material.set_shader_parameter("moonlight_direction", dirn)
	_foliage_material.set_shader_parameter("moonlight_strength", strength)
	_foliage_material.set_shader_parameter("moonlight_color", color)
	_foliage_material.set_shader_parameter("moonlight_direction", dirn)


static func _ensure_shared_materials() -> void:
	if _trunk_material != null and _foliage_material != null:
		return
	_trunk_material = ShaderMaterial.new()
	_trunk_material.shader = _SHADER
	_trunk_material.set_shader_parameter("base_color", Color(0.46, 0.34, 0.24))
	_trunk_material.set_shader_parameter("lit_tint", Color(0.98, 0.90, 0.78))
	_trunk_material.set_shader_parameter("halfshadow_tint", Color(0.62, 0.52, 0.44))
	_trunk_material.set_shader_parameter("shadow_tint", Color(0.22, 0.16, 0.14))
	_trunk_material.set_shader_parameter("shadow_strength", 0.50)
	_trunk_material.set_shader_parameter("halfshadow_strength", 0.72)
	_trunk_material.set_shader_parameter("band_softness", 0.038)
	_trunk_material.set_shader_parameter("band_1_threshold", 0.32)
	_trunk_material.set_shader_parameter("band_2_threshold", 0.64)
	_trunk_material.set_shader_parameter("rim_strength", 0.045)
	_trunk_material.set_shader_parameter("rim_power", 2.8)
	_trunk_material.set_shader_parameter("relief_strength", 0.28)
	_trunk_material.set_shader_parameter("atmospheric_near", 32.0)
	_trunk_material.set_shader_parameter("atmospheric_far", 170.0)
	_trunk_material.set_shader_parameter("atmospheric_strength", 0.50)
	_trunk_material.set_shader_parameter("distant_tint", Color(0.68, 0.80, 0.78))

	_foliage_material = ShaderMaterial.new()
	_foliage_material.shader = _SHADER
	_foliage_material.set_shader_parameter("base_color", Color(0.36, 0.53, 0.22))
	_foliage_material.set_shader_parameter("lit_tint", Color(0.94, 0.96, 0.62))
	_foliage_material.set_shader_parameter("halfshadow_tint", Color(0.50, 0.62, 0.36))
	_foliage_material.set_shader_parameter("shadow_tint", Color(0.12, 0.28, 0.18))
	_foliage_material.set_shader_parameter("shadow_strength", 0.50)
	_foliage_material.set_shader_parameter("halfshadow_strength", 0.74)
	_foliage_material.set_shader_parameter("band_softness", 0.04)
	_foliage_material.set_shader_parameter("band_1_threshold", 0.33)
	_foliage_material.set_shader_parameter("band_2_threshold", 0.66)
	_foliage_material.set_shader_parameter("rim_strength", 0.075)
	_foliage_material.set_shader_parameter("rim_power", 3.2)
	_foliage_material.set_shader_parameter("relief_strength", 0.10)
	_foliage_material.set_shader_parameter("atmospheric_near", 26.0)
	_foliage_material.set_shader_parameter("atmospheric_far", 160.0)
	_foliage_material.set_shader_parameter("atmospheric_strength", 0.58)
	_foliage_material.set_shader_parameter("distant_tint", Color(0.58, 0.78, 0.76))


func rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_rng.seed = random_seed
	_bend_dir = Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0)).normalized()
	var p := _params_for_variant(variant)
	_build_trunk(p)
	_build_branches(p)
	_build_crown(p)


func _params_for_variant(v: Variant) -> Dictionary:
	match v:
		Variant.LARGE:
			return {
				"trunk_height": _rf(5.2, 6.6),
				"bottom_radius": _rf(0.48, 0.62),
				"top_radius": _rf(0.28, 0.40),
				"twist_turns": _rf(0.35, 0.62),
				"bend": _rf(0.12, 0.28),
				"bark_ripples": _rf(0.22, 0.38),
				"rings": 17,
				"segments": 14,
				"branch_count": _ri(3, 5),
				"branch_len": Vector2(0.75, 1.55),
				"branch_r": Vector2(0.09, 0.19),
				"branch_start_y": 0.12,
				"branch_end_y": 0.52,
				"crown_count": _ri(9, 13),
				"crown_radius": Vector2(1.55, 2.85),
				"crown_lift": _rf(0.15, 0.55),
				"crown_spread": _rf(1.35, 2.15),
			}
		Variant.SMALL:
			return {
				"trunk_height": _rf(2.4, 3.35),
				"bottom_radius": _rf(0.14, 0.22),
				"top_radius": _rf(0.11, 0.18),
				"twist_turns": _rf(0.05, 0.18),
				"bend": _rf(0.02, 0.10),
				"bark_ripples": _rf(0.08, 0.16),
				"rings": 12,
				"segments": 11,
				"branch_count": _ri(2, 4),
				"branch_len": Vector2(0.28, 0.62),
				"branch_r": Vector2(0.045, 0.095),
				"branch_start_y": 0.22,
				"branch_end_y": 0.72,
				"crown_count": _ri(5, 7),
				"crown_radius": Vector2(0.65, 1.15),
				"crown_lift": _rf(0.05, 0.25),
				"crown_spread": _rf(0.55, 0.95),
			}
		_: # MEDIUM
			return {
				"trunk_height": _rf(3.6, 4.6),
				"bottom_radius": _rf(0.26, 0.36),
				"top_radius": _rf(0.17, 0.26),
				"twist_turns": _rf(0.12, 0.28),
				"bend": _rf(0.05, 0.16),
				"bark_ripples": _rf(0.12, 0.24),
				"rings": 14,
				"segments": 12,
				"branch_count": _ri(4, 6),
				"branch_len": Vector2(0.50, 1.05),
				"branch_r": Vector2(0.065, 0.14),
				"branch_start_y": 0.18,
				"branch_end_y": 0.62,
				"crown_count": _ri(7, 9),
				"crown_radius": Vector2(1.05, 1.75),
				"crown_lift": _rf(0.10, 0.38),
				"crown_spread": _rf(0.95, 1.45),
			}


func _rf(a: float, b: float) -> float:
	return _rng.randf_range(a, b)


func _ri(a: int, b: int) -> int:
	return _rng.randi_range(a, b)


func _build_trunk(p: Dictionary) -> void:
	var mesh := _make_twisted_trunk_mesh(p, _bend_dir)
	var mi := MeshInstance3D.new()
	mi.name = "Trunk"
	mi.mesh = mesh
	mi.material_override = _trunk_material
	add_child(mi)


func _trunk_surface(p: Dictionary, bend_dir: Vector3, y: float, ang: float) -> Dictionary:
	var height: float = p["trunk_height"]
	var bottom_r: float = p["bottom_radius"]
	var top_r: float = p["top_radius"]
	var twist_turns: float = p["twist_turns"]
	var bend: float = p["bend"]
	var ripples: float = p["bark_ripples"]
	var t: float = clampf(y / height, 0.0, 1.0)
	y = t * height
	var twist: float = t * twist_turns * TAU
	var rad0: float = lerpf(bottom_r, top_r, t)
	var ang_w: float = ang + twist
	var ripple: float = sin(ang_w * 3.0 + y * 1.7) * ripples + sin(ang_w * 6.0 - y * 2.1) * ripples * 0.45
	var rad: float = rad0 * (1.0 + ripple)
	var cx: float = bend_dir.x * y * bend
	var cz: float = bend_dir.z * y * bend
	var wobble_x: float = sin(y * 0.55) * bend * 0.35
	var wobble_z: float = cos(y * 0.48) * bend * 0.35
	var center := Vector3(cx + wobble_x, y, cz + wobble_z)
	var surf: Vector3 = center + Vector3(cos(ang_w) * rad, 0.0, sin(ang_w) * rad)
	var out_xz := Vector3(cos(ang_w), 0.0, sin(ang_w))
	return {"position": surf, "outward": out_xz}


func _make_twisted_trunk_mesh(p: Dictionary, bend_dir: Vector3) -> ArrayMesh:
	var height: float = p["trunk_height"]
	var bottom_r: float = p["bottom_radius"]
	var top_r: float = p["top_radius"]
	var twist_turns: float = p["twist_turns"]
	var bend: float = p["bend"]
	var ripples: float = p["bark_ripples"]
	var rings: int = p["rings"]
	var segments: int = p["segments"]

	var ring_verts: Array = []
	for ri in rings + 1:
		var t: float = float(ri) / float(rings)
		var y: float = t * height
		var ring: Array = []
		for s in segments + 1:
			var u: float = float(s % segments) / float(segments)
			var ang: float = u * TAU
			var fr := _trunk_surface(p, bend_dir, y, ang)
			ring.append(fr["position"])
		ring_verts.append(ring)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ri in rings:
		for s in segments:
			var v00: Vector3 = ring_verts[ri][s]
			var v01: Vector3 = ring_verts[ri][s + 1]
			var v10: Vector3 = ring_verts[ri + 1][s]
			var v11: Vector3 = ring_verts[ri + 1][s + 1]
			_add_quad(st, v00, v01, v10, v11)
	st.generate_normals()
	return st.commit()


func _add_quad(st: SurfaceTool, v00: Vector3, v01: Vector3, v10: Vector3, v11: Vector3) -> void:
	# Counter-clockwise winding for outside-facing normals.
	st.add_vertex(v00)
	st.add_vertex(v01)
	st.add_vertex(v10)
	st.add_vertex(v01)
	st.add_vertex(v11)
	st.add_vertex(v10)


func _basis_y_axis(axis_y: Vector3) -> Basis:
	var y := axis_y.normalized()
	var x := Vector3.UP.cross(y)
	if x.length_squared() < 1e-7:
		x = Vector3.RIGHT.cross(y)
	x = x.normalized()
	var z := x.cross(y).normalized()
	x = y.cross(z).normalized()
	return Basis(x, y, z)


func _build_branches(p: Dictionary) -> void:
	var height: float = p["trunk_height"]
	var n: int = p["branch_count"]
	var y0: float = p["branch_start_y"] * height
	var y1: float = p["branch_end_y"] * height
	var base_angle: float = _rng.randf() * TAU
	var arc_bias: float = _rf(0.9, 1.65)
	for i in n:
		var y: float = _rf(y0, y1)
		var ang: float
		if _rng.randf() < 0.70:
			ang = base_angle + _rf(-arc_bias, arc_bias)
		else:
			ang = base_angle + PI + _rf(-0.8, 0.8)
		var surf := _trunk_surface(p, _bend_dir, y, ang)
		var out: Vector3 = surf["outward"]
		var branch_tilt_deg: float = _rf(30.0, 60.0)
		var theta: float = deg_to_rad(branch_tilt_deg)
		var tangent := Vector3.UP.cross(out)
		if tangent.length_squared() < 1e-5:
			tangent = Vector3.FORWARD
		tangent = tangent.normalized()
		var up_w: float = cos(theta)
		var out_w: float = sin(theta)
		var tangential_w: float = _rf(-0.18, 0.18)
		var dir: Vector3 = (out * out_w + Vector3.UP * up_w + tangent * tangential_w).normalized()
		var blen: float = _rf(p["branch_len"].x, p["branch_len"].y)
		var brad: float = _rf(p["branch_r"].x, p["branch_r"].y)
		var cyl := CylinderMesh.new()
		cyl.height = blen
		cyl.top_radius = brad * 0.65
		cyl.bottom_radius = brad
		cyl.radial_segments = 10
		cyl.rings = 2
		var mi := MeshInstance3D.new()
		mi.name = "Branch_%d" % i
		mi.mesh = cyl
		mi.material_override = _trunk_material
		var basis := _basis_y_axis(dir)
		var pos: Vector3 = surf["position"] + dir * (blen * 0.5)
		mi.transform = Transform3D(basis, pos)
		add_child(mi)


func _build_crown(p: Dictionary) -> void:
	var height: float = p["trunk_height"]
	var bend: float = p["bend"]
	var lift: float = p["crown_lift"]
	var spread: float = p["crown_spread"]
	var n: int = p["crown_count"]
	var y := height
	var cx: float = _bend_dir.x * y * bend + sin(y * 0.55) * bend * 0.35
	var cz: float = _bend_dir.z * y * bend + cos(y * 0.48) * bend * 0.35
	var trunk_top := Vector3(cx, y, cz)
	var anchor: Vector3 = trunk_top + Vector3(0.0, lift, 0.0)
	for i in n:
		var sph := SphereMesh.new()
		var rscale: float = _rf(p["crown_radius"].x, p["crown_radius"].y)
		sph.radius = rscale
		sph.height = rscale * _rf(1.1, 1.55)
		sph.radial_segments = 10
		sph.rings = 8
		var mi := MeshInstance3D.new()
		mi.name = "Crown_%d" % i
		mi.mesh = sph
		mi.material_override = _foliage_material
		var off := Vector3(_rf(-1.0, 1.0), _rf(-0.35, 0.55), _rf(-1.0, 1.0)) * spread
		mi.position = anchor + off
		mi.scale = Vector3.ONE * _rf(0.85, 1.12)
		mi.rotation = Vector3(_rf(-0.08, 0.08), _rf(0.0, TAU), _rf(-0.08, 0.08))
		add_child(mi)
