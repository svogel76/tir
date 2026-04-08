extends Node

@export_range(0.0, 1.0, 0.001) var time_of_day: float = 0.25
@export_range(0.01, 20.0, 0.01) var day_speed_scale: float = 1.0
@export_range(30.0, 3600.0, 1.0, "suffix:s") var day_length_seconds: float = 900.0
@export_range(0, 3, 1) var current_season: int = 0
@export_range(-180.0, 180.0, 0.1) var sun_azimuth_degrees: float = -38.0
@export_range(-180.0, 180.0, 0.1) var sun_elevation_offset_degrees: float = -110.0

@export_node_path("DirectionalLight3D") var sun_light_path: NodePath
@export_node_path("WorldEnvironment") var world_environment_path: NodePath
@export_node_path("VoxelLodTerrain") var terrain_path: NodePath

var sun_light: DirectionalLight3D = null
var world_environment: WorldEnvironment = null
var terrain_node: Node = null

const _SEASON_DAY_LENGTH_MULTIPLIER := [1.00, 1.10, 0.95, 0.80]

@export var night_sun_color: Color = Color(0.34, 0.42, 0.60, 1.0)
@export var dawn_dusk_sun_color: Color = Color(1.00, 0.67, 0.44, 1.0)
@export var noon_sun_color: Color = Color(1.00, 0.95, 0.85, 1.0)

@export var sky_night_top: Color = Color(0.02, 0.04, 0.08, 1.0)
@export var sky_night_horizon: Color = Color(0.06, 0.08, 0.13, 1.0)
@export var sky_dawn_top: Color = Color(0.24, 0.22, 0.30, 1.0)
@export var sky_dawn_horizon: Color = Color(0.94, 0.48, 0.30, 1.0)
@export var sky_day_top: Color = Color(0.32, 0.66, 0.72, 1.0)
@export var sky_day_horizon: Color = Color(0.67, 0.86, 0.80, 1.0)

@export var ground_day_horizon: Color = Color(0.47, 0.52, 0.46, 1.0)
@export var ground_night_horizon: Color = Color(0.08, 0.10, 0.12, 1.0)
@export var ground_day_bottom: Color = Color(0.24, 0.28, 0.24, 1.0)
@export var ground_night_bottom: Color = Color(0.04, 0.05, 0.06, 1.0)

@export_range(0.0, 1.5, 0.001) var ambient_day_energy: float = 0.085
@export_range(0.0, 0.05, 0.0001) var ambient_night_energy: float = 0.0012
@export_range(0.0, 3.0, 0.01) var sun_day_energy: float = 1.45
@export_range(0.0, 0.2, 0.0001) var sun_night_energy: float = 0.0
@export_range(0.0, 0.25, 0.001) var horizon_haze_day: float = 0.12
@export_range(0.0, 0.25, 0.001) var horizon_haze_night: float = 0.03

@export_group("Moon Fill")
@export_range(0.0, 0.4, 0.001) var moonlight_max_strength: float = 0.08
@export var moonlight_color: Color = Color(0.58, 0.67, 0.82, 1.0)
@export var moonlight_direction: Vector3 = Vector3(-0.4, 0.85, 0.35)


func _ready() -> void:
	add_to_group("day_night_cycle")
	_resolve_scene_references()
	_register_debug_commands()
	_apply_lighting()


func _process(delta: float) -> void:
	var season_multiplier: float = _SEASON_DAY_LENGTH_MULTIPLIER[clampi(current_season, 0, 3)]
	var effective_day_length: float = max(10.0, day_length_seconds / max(season_multiplier, 0.01))
	var cycle_speed: float = (day_speed_scale / effective_day_length) * delta
	time_of_day = wrapf(time_of_day + cycle_speed, 0.0, 1.0)
	_sync_audio_state()
	_apply_lighting()


func set_time_of_day(value: float) -> void:
	time_of_day = clampf(value, 0.0, 1.0)
	_sync_audio_state()
	_apply_lighting()


func set_day_speed_scale(value: float) -> void:
	day_speed_scale = max(0.01, value)


func get_time_of_day() -> float:
	return time_of_day


func get_time_string() -> String:
	var total_minutes: int = int(floor(time_of_day * 24.0 * 60.0)) % (24 * 60)
	var hours: int = int(floor(float(total_minutes) / 60.0))
	var minutes: int = total_minutes % 60
	return "%02d:%02d" % [hours, minutes]


func get_current_season() -> int:
	return current_season


func _register_debug_commands() -> void:
	if not has_node("/root/DebugManager"):
		return
	var debug_manager: Node = get_node("/root/DebugManager")
	if debug_manager.has_method("unregister_command"):
		debug_manager.call("unregister_command", "time")
		debug_manager.call("unregister_command", "timescale")
	debug_manager.call("register_command", "time", Callable(self, "_cmd_time"), "Setzt Tageszeit 0.0-1.0")
	debug_manager.call("register_command", "timescale", Callable(self, "_cmd_timescale"), "Setzt Tagesgeschwindigkeit")


func _cmd_time(args: PackedStringArray) -> String:
	if args.size() < 1:
		return "Fehler: time erwartet 1 numerischen Wert (0.0-1.0)."
	var raw: String = String(args[0])
	if not raw.is_valid_float():
		return "Fehler: N muss numerisch sein."
	set_time_of_day(float(raw))
	return "Tageszeit gesetzt: %s (%.2f)" % [get_time_string(), time_of_day]


func _cmd_timescale(args: PackedStringArray) -> String:
	if args.size() < 1:
		return "Fehler: timescale erwartet 1 numerischen Wert."
	var raw: String = String(args[0])
	if not raw.is_valid_float():
		return "Fehler: N muss numerisch sein."
	set_day_speed_scale(float(raw))
	return "Tagesgeschwindigkeit = %.2f" % day_speed_scale


func _apply_lighting() -> void:
	_apply_sun()
	_apply_environment()


func _sync_audio_state() -> void:
	if not has_node("/root/AudioManager"):
		return
	var audio_manager: Node = get_node("/root/AudioManager")
	if audio_manager.has_method("set_time_of_day"):
		audio_manager.call("set_time_of_day", time_of_day)
	if audio_manager.has_method("set_season"):
		audio_manager.call("set_season", current_season)


func _resolve_scene_references() -> void:
	if not is_inside_tree():
		return
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return

	if sun_light == null and not sun_light_path.is_empty():
		sun_light = get_node_or_null(sun_light_path) as DirectionalLight3D
	if world_environment == null and not world_environment_path.is_empty():
		world_environment = get_node_or_null(world_environment_path) as WorldEnvironment
	if terrain_node == null and not terrain_path.is_empty():
		terrain_node = get_node_or_null(terrain_path)

	# Fallback for misconfigured exports in scene instances.
	if sun_light == null:
		sun_light = scene_root.get_node_or_null("Sun") as DirectionalLight3D
	if world_environment == null:
		world_environment = scene_root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if terrain_node == null:
		terrain_node = scene_root.get_node_or_null("Terrain")


func _apply_sun() -> void:
	if sun_light == null:
		return
	var t: float = time_of_day
	var sun_elevation: float = sin((t - 0.25) * TAU)
	var daylight: float = smoothstep(-0.14, 0.18, sun_elevation)
	var dawn_dusk: float = max(
		_circular_peak(t, 0.25, 0.10),
		_circular_peak(t, 0.75, 0.10)
	)

	sun_light.rotation_degrees.x = sun_elevation_offset_degrees + t * 360.0
	sun_light.rotation_degrees.y = sun_azimuth_degrees
	sun_light.light_energy = lerpf(sun_night_energy, sun_day_energy, daylight)
	var color: Color = night_sun_color.lerp(noon_sun_color, daylight)
	color = color.lerp(dawn_dusk_sun_color, dawn_dusk)
	sun_light.light_color = color


func _apply_environment() -> void:
	if world_environment == null or world_environment.environment == null:
		return
	var env: Environment = world_environment.environment
	var t: float = time_of_day
	var sun_elevation: float = sin((t - 0.25) * TAU)
	var daylight: float = smoothstep(-0.14, 0.18, sun_elevation)
	var dawn_dusk: float = max(
		_circular_peak(t, 0.25, 0.12),
		_circular_peak(t, 0.75, 0.12)
	)

	env.ambient_light_energy = lerpf(ambient_night_energy, ambient_day_energy, daylight)
	env.fog_light_color = sky_night_horizon.lerp(sky_day_horizon, daylight)
	env.fog_aerial_perspective = lerpf(horizon_haze_night, horizon_haze_day, daylight)

	if env.sky == null:
		return
	var sky_material: Resource = env.sky.sky_material
	if sky_material == null or not (sky_material is ProceduralSkyMaterial):
		return
	var sky: ProceduralSkyMaterial = sky_material as ProceduralSkyMaterial

	var top: Color = sky_night_top.lerp(sky_day_top, daylight)
	var horizon: Color = sky_night_horizon.lerp(sky_day_horizon, daylight)
	horizon = horizon.lerp(sky_dawn_horizon, dawn_dusk)
	top = top.lerp(sky_dawn_top, dawn_dusk * 0.55)

	sky.sky_top_color = top
	sky.sky_horizon_color = horizon
	sky.ground_horizon_color = ground_night_horizon.lerp(ground_day_horizon, daylight)
	sky.ground_bottom_color = ground_night_bottom.lerp(ground_day_bottom, daylight)
	sky.emit_changed()
	env.sky.emit_changed()
	env.emit_changed()
	_apply_shader_day_night(daylight)


func _apply_shader_day_night(daylight: float) -> void:
	if terrain_node == null:
		return
	var mat_variant: Variant = terrain_node.get("material")
	if not (mat_variant is ShaderMaterial):
		return
	var shader_mat: ShaderMaterial = mat_variant as ShaderMaterial
	var night_factor: float = 1.0 - daylight
	var moon_strength: float = moonlight_max_strength * pow(night_factor, 1.7)
	shader_mat.set_shader_parameter("moonlight_strength", moon_strength)
	shader_mat.set_shader_parameter("moonlight_color", moonlight_color)
	shader_mat.set_shader_parameter("moonlight_direction", moonlight_direction.normalized())


func _circular_peak(t: float, center: float, width: float) -> float:
	var d: float = absf(t - center)
	d = minf(d, 1.0 - d)
	return clampf(1.0 - d / maxf(width, 0.0001), 0.0, 1.0)
