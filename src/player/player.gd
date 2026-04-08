extends CharacterBody3D
class_name TirPlayerController

signal focus_changed(collider: Object, position: Vector3, normal: Vector3)
signal stamina_state_changed(is_low: bool, is_exhausted: bool)
signal stamina_low
signal stamina_exhausted
signal stamina_recovered

enum MovementState {
	STANDING,
	WALKING,
	RUNNING,
	CROUCHING,
	JUMPING,
	AIRBORNE
}

@export_group("Input")
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var move_forward_action: StringName = &"move_forward"
@export var move_back_action: StringName = &"move_backward"
@export var run_action: StringName = &"run"
@export var crouch_action: StringName = &"crouch"
@export var jump_action: StringName = &"jump"
@export var run_fallback_key: Key = KEY_SHIFT
@export var crouch_fallback_key: Key = KEY_CTRL

@export_group("Look")
@export_range(0.001, 0.02, 0.0005) var mouse_sensitivity: float = 0.004
@export_range(-89.0, -1.0, 0.1) var min_pitch_degrees: float = -80.0
@export_range(1.0, 89.0, 0.1) var max_pitch_degrees: float = 80.0

@export_group("Movement")
@export_range(0.1, 8.0, 0.1, "suffix:m/s") var walk_speed: float = 1.9
@export_range(0.1, 10.0, 0.1, "suffix:m/s") var run_speed: float = 3.1
@export_range(0.1, 5.0, 0.1, "suffix:m/s") var crouch_speed: float = 1.3
@export_range(0.5, 40.0, 0.1) var acceleration: float = 10.0
@export_range(0.5, 40.0, 0.1) var deceleration: float = 14.0
@export_range(0.0, 40.0, 0.1, "suffix:m/s2") var gravity_upward: float = 12.5
@export_range(0.0, 60.0, 0.1, "suffix:m/s2") var gravity_downward: float = 22.0
@export_range(0.0, 8.0, 0.05, "suffix:m/s") var floor_stick_force: float = 2.2
@export_range(0.0, 10.0, 0.1, "suffix:m/s") var jump_velocity: float = 4.3
@export_range(0.0, 100.0, 0.1, "suffix:/jump") var jump_stamina_cost: float = 16.0
@export_range(0.0, 20.0, 0.1) var air_control_acceleration: float = 1.6
@export_range(0.0, 1.0, 0.01) var air_control_factor: float = 0.08

@export_group("Stamina")
@export_range(1.0, 300.0, 0.1) var stamina_max: float = 100.0
@export_range(0.0, 100.0, 0.1, "suffix:/s") var run_stamina_drain_per_second: float = 18.0
@export_range(0.0, 100.0, 0.1, "suffix:/s") var stamina_regen_per_second: float = 14.0
@export_range(0.0, 1.0, 0.01) var low_stamina_threshold_ratio: float = 0.2

@export_group("Camera")
@export_range(0.0, 0.1, 0.001, "suffix:m") var bob_vertical_amplitude: float = 0.038
@export_range(0.0, 0.08, 0.001, "suffix:m") var bob_horizontal_amplitude: float = 0.016
@export_range(0.1, 3.0, 0.01, "suffix:m") var bob_stride_length: float = 1.15
@export_range(1.0, 2.5, 0.01) var run_bob_multiplier: float = 1.35
@export_range(0.2, 2.0, 0.01) var crouch_bob_speed_scale: float = 0.65
@export_range(0.0, 20.0, 0.1) var bob_blend_in_speed: float = 9.0
@export_range(0.0, 20.0, 0.1) var bob_blend_out_speed: float = 6.0
@export_range(0.0, 1.0, 0.01) var camera_smoothing: float = 0.16
@export_range(0.5, 2.5, 0.01, "suffix:m") var standing_camera_height: float = 1.68
@export_range(0.3, 1.6, 0.01, "suffix:m") var crouching_camera_height: float = 1.15
@export_range(0.1, 20.0, 0.1) var crouch_transition_speed: float = 9.0
@export_range(0.0, 0.4, 0.01) var look_lag_strength: float = 0.12
@export_range(1.0, 30.0, 0.1) var look_lag_speed: float = 14.0
@export_range(0.0, 0.35, 0.005, "suffix:m") var landing_impact_max: float = 0.16
@export_range(0.0, 0.2, 0.005, "suffix:m") var jump_landing_bonus: float = 0.05
@export_range(0.0, 2.0, 0.01) var landing_velocity_to_impact: float = 0.045
@export_range(1.0, 60.0, 0.1) var landing_spring_stiffness: float = 26.0
@export_range(0.1, 20.0, 0.1) var landing_spring_damping: float = 8.5

@export_group("Interaction")
@export_range(0.5, 8.0, 0.1, "suffix:m") var interaction_distance: float = 2.4
@export_flags_3d_physics var interaction_mask: int = 1

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D

var movement_state: MovementState = MovementState.STANDING
var stamina_current: float = 100.0

var _pitch_degrees: float = 0.0
var _base_head_position: Vector3
var _last_focus_collider: Object = null
var _is_stamina_low: bool = false
var _is_stamina_exhausted: bool = false
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _current_yaw: float = 0.0
var _current_pitch: float = 0.0
var _gait_phase: float = 0.0
var _bob_blend: float = 0.0
var _landing_offset: float = 0.0
var _landing_velocity: float = 0.0
var _was_on_floor: bool = false
var _was_jumping: bool = false
var _fall_speed_before_landing: float = 0.0
var _input_enabled: bool = true


func _ready() -> void:
	stamina_current = stamina_max
	_base_head_position = _head.position
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_current_yaw = rotation.y
	_target_yaw = _current_yaw
	_current_pitch = _head.rotation.x
	_target_pitch = _current_pitch
	_was_on_floor = is_on_floor()


func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_target_yaw += -event.relative.x * mouse_sensitivity
		_pitch_degrees = clamp(_pitch_degrees - event.relative.y * mouse_sensitivity * 100.0, min_pitch_degrees, max_pitch_degrees)
		_target_pitch = deg_to_rad(_pitch_degrees)


func _physics_process(delta: float) -> void:
	if not _input_enabled:
		_update_vertical_velocity(delta)
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		move_and_slide()
		_update_landing_impact()
		_update_state(false, Vector2.ZERO)
		_update_camera(delta, Vector2.ZERO)
		return

	_update_look(delta)
	_update_vertical_velocity(delta)
	var move_input: Vector2 = _get_move_input()
	var wish_dir: Vector3 = (global_transform.basis * Vector3(move_input.x, 0.0, move_input.y)).normalized()
	var wants_crouch: bool = _is_action_pressed(crouch_action)
	var wants_run: bool = _is_action_pressed(run_action)
	var wants_jump: bool = _is_action_just_pressed(jump_action)

	if wants_jump:
		_try_jump(wants_crouch)

	var target_speed: float = _resolve_target_speed(move_input, wants_crouch, wants_run)
	var target_horizontal_velocity: Vector3 = wish_dir * target_speed
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var blend_rate: float = acceleration if target_speed > horizontal_velocity.length() else deceleration
	if not is_on_floor():
		blend_rate = air_control_acceleration * air_control_factor
	horizontal_velocity = horizontal_velocity.move_toward(target_horizontal_velocity, blend_rate * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	move_and_slide()
	_update_landing_impact()
	_update_stamina(delta, wants_run, wants_crouch, move_input)
	_update_state(wants_crouch, move_input)
	_update_camera(delta, move_input)
	_update_focus_signal()


func _update_vertical_velocity(delta: float) -> void:
	if is_on_floor():
		if movement_state != MovementState.JUMPING:
			velocity.y = -floor_stick_force
		return
	_fall_speed_before_landing = max(_fall_speed_before_landing, -velocity.y)
	var gravity_force: float = gravity_upward if velocity.y > 0.0 else gravity_downward
	velocity.y -= gravity_force * delta


func _resolve_target_speed(move_input: Vector2, wants_crouch: bool, wants_run: bool) -> float:
	if move_input.is_zero_approx():
		return 0.0
	if movement_state == MovementState.JUMPING:
		return walk_speed
	if not is_on_floor():
		return walk_speed
	if wants_crouch:
		return crouch_speed
	if wants_run and not _is_stamina_exhausted:
		return run_speed
	return walk_speed


func _update_state(wants_crouch: bool, move_input: Vector2) -> void:
	if not is_on_floor():
		if movement_state == MovementState.JUMPING and velocity.y <= 0.0:
			movement_state = MovementState.AIRBORNE
			return
		movement_state = MovementState.AIRBORNE
		return
	if wants_crouch:
		movement_state = MovementState.CROUCHING
		return
	if move_input.is_zero_approx():
		movement_state = MovementState.STANDING
	elif velocity.length() > (walk_speed + run_speed) * 0.5:
		movement_state = MovementState.RUNNING
	else:
		movement_state = MovementState.WALKING


func _update_stamina(delta: float, wants_run: bool, wants_crouch: bool, move_input: Vector2) -> void:
	var should_drain: bool = is_on_floor() and not move_input.is_zero_approx() and wants_run and not wants_crouch and movement_state == MovementState.RUNNING
	if should_drain:
		stamina_current = max(0.0, stamina_current - run_stamina_drain_per_second * delta)
	else:
		var should_regen: bool = movement_state == MovementState.STANDING or movement_state == MovementState.WALKING
		if should_regen:
			stamina_current = min(stamina_max, stamina_current + stamina_regen_per_second * delta)

	var low_threshold: float = stamina_max * low_stamina_threshold_ratio
	var now_low: bool = stamina_current <= low_threshold
	var now_exhausted: bool = stamina_current <= 0.0

	if now_exhausted and not _is_stamina_exhausted:
		stamina_exhausted.emit()
	elif not now_exhausted and _is_stamina_exhausted:
		stamina_recovered.emit()

	if now_low and not _is_stamina_low:
		stamina_low.emit()

	if now_low != _is_stamina_low or now_exhausted != _is_stamina_exhausted:
		stamina_state_changed.emit(now_low, now_exhausted)

	_is_stamina_low = now_low
	_is_stamina_exhausted = now_exhausted


func _update_camera(delta: float, move_input: Vector2) -> void:
	var target_height: float = crouching_camera_height if movement_state == MovementState.CROUCHING else standing_camera_height
	var target_pos: Vector3 = _base_head_position
	target_pos.y = target_height

	var is_moving_on_ground: bool = is_on_floor() and not move_input.is_zero_approx()
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var speed_ratio: float = clampf(horizontal_speed / max(run_speed, 0.001), 0.0, 1.0)
	var bob_target_blend: float = 1.0 if is_moving_on_ground else 0.0
	var blend_speed: float = bob_blend_in_speed if bob_target_blend > _bob_blend else bob_blend_out_speed
	_bob_blend = move_toward(_bob_blend, bob_target_blend, blend_speed * delta)
	if _bob_blend > 0.001:
		var step_scale: float = crouch_bob_speed_scale if movement_state == MovementState.CROUCHING else 1.0
		var stride: float = max(0.05, bob_stride_length)
		_gait_phase = fmod(_gait_phase + (horizontal_speed * delta * step_scale) / stride, 1.0)
		var bob_offset: Vector3 = _compute_bob_offset(_gait_phase, speed_ratio, movement_state == MovementState.CROUCHING)
		target_pos += bob_offset * _bob_blend
	target_pos.y -= _landing_offset
	_head.position = _head.position.lerp(target_pos, clamp(camera_smoothing * delta * 60.0, 0.0, 1.0))


func _update_focus_signal() -> void:
	var from: Vector3 = _camera.global_position
	var to: Vector3 = from + (-_camera.global_transform.basis.z) * interaction_distance
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, interaction_mask)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [self]

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var collider: Object = hit.get("collider", null) as Object
	if collider != _last_focus_collider or collider != null:
		var hit_position: Vector3 = hit.get("position", Vector3.ZERO) as Vector3
		var normal: Vector3 = hit.get("normal", Vector3.ZERO) as Vector3
		focus_changed.emit(collider, hit_position, normal)
		_last_focus_collider = collider


func _get_move_input() -> Vector2:
	var x: float = _get_axis_value(move_left_action, move_right_action)
	var y: float = _get_axis_value(move_forward_action, move_back_action)
	return Vector2(x, y).normalized()


func _get_axis_value(negative: StringName, positive: StringName) -> float:
	var neg: float = 0.0
	var pos: float = 0.0
	if InputMap.has_action(negative):
		neg = Input.get_action_strength(negative)
	if InputMap.has_action(positive):
		pos = Input.get_action_strength(positive)
	return pos - neg


func _is_action_pressed(action: StringName) -> bool:
	var pressed: bool = InputMap.has_action(action) and Input.is_action_pressed(action)
	if pressed:
		return true

	# Fallback for modifier keys when InputMap bindings are platform-specific.
	if action == run_action:
		return Input.is_key_pressed(run_fallback_key)
	if action == crouch_action:
		return Input.is_key_pressed(crouch_fallback_key)
	return false


func _is_action_just_pressed(action: StringName) -> bool:
	return InputMap.has_action(action) and Input.is_action_just_pressed(action)


func _update_look(delta: float) -> void:
	var lag_mix: float = clampf(1.0 - look_lag_strength, 0.65, 1.0)
	var follow: float = clampf(look_lag_speed * lag_mix * delta, 0.0, 1.0)
	_current_yaw = lerp_angle(_current_yaw, _target_yaw, follow)
	_current_pitch = lerp(_current_pitch, _target_pitch, follow)
	rotation.y = _current_yaw
	_head.rotation.x = _current_pitch


func _compute_bob_offset(phase: float, speed_ratio: float, is_crouching: bool) -> Vector3:
	var p: float = phase
	var impact_wave: float = 1.0 - abs(p * 2.0 - 1.0)
	impact_wave = impact_wave * impact_wave * (3.0 - 2.0 * impact_wave)
	var lateral_wave: float = sin((p + 0.25) * TAU)
	var crouch_scale: float = 0.7 if is_crouching else 1.0
	var run_scale: float = run_bob_multiplier if movement_state == MovementState.RUNNING else 1.0
	var vertical: float = impact_wave * bob_vertical_amplitude * speed_ratio * crouch_scale * run_scale
	var lateral: float = lateral_wave * bob_horizontal_amplitude * speed_ratio * crouch_scale * run_scale
	return Vector3(lateral, -vertical, 0.0)


func _try_jump(wants_crouch: bool) -> void:
	if wants_crouch:
		return
	if not is_on_floor():
		return
	if _is_stamina_exhausted:
		return
	if stamina_current < jump_stamina_cost:
		return

	stamina_current = max(0.0, stamina_current - jump_stamina_cost)
	velocity.y = jump_velocity
	movement_state = MovementState.JUMPING
	_was_jumping = true
	_fall_speed_before_landing = 0.0


func _update_landing_impact() -> void:
	var on_floor_now: bool = is_on_floor()
	if on_floor_now and not _was_on_floor:
		var impact_strength: float = clampf(_fall_speed_before_landing * landing_velocity_to_impact, 0.0, landing_impact_max)
		if _was_jumping:
			impact_strength = clampf(impact_strength + jump_landing_bonus, 0.0, landing_impact_max)
		_landing_velocity -= impact_strength
		_fall_speed_before_landing = 0.0
		_was_jumping = false
	elif not on_floor_now and _was_on_floor and movement_state != MovementState.JUMPING:
		_fall_speed_before_landing = 0.0

	var spring_force: float = (-_landing_offset * landing_spring_stiffness) - (_landing_velocity * landing_spring_damping)
	_landing_velocity += spring_force * get_physics_process_delta_time()
	_landing_offset += _landing_velocity * get_physics_process_delta_time()
	if absf(_landing_offset) < 0.0002 and absf(_landing_velocity) < 0.0002:
		_landing_offset = 0.0
		_landing_velocity = 0.0

	_was_on_floor = on_floor_now


func set_input_enabled(value: bool) -> void:
	_input_enabled = value
	if not _input_enabled:
		velocity.x = 0.0
		velocity.z = 0.0
