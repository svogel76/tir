extends Node

const MAX_FADE_DB: float = -60.0

@export_range(0.1, 30.0, 0.1) var volume_lerp_speed: float = 8.0
@export var ambient_default_bus: StringName = &"Master"
@export var position_default_bus: StringName = &"Master"

var otherworld_fade: float = 0.0
var time_of_day: float = 0.5
var season: int = 0
var muted: bool = false

var _ambient_players: Dictionary = {}
var _entity_players: Dictionary = {}
var _positional_players: Array[AudioStreamPlayer3D] = []
var _sound_by_player_id: Dictionary = {}
var _debug_manager_override: Node = null


func _ready() -> void:
	_register_debug_commands()


func _process(delta: float) -> void:
	_update_volumes(delta)
	_cleanup_positional_players()


func play_ambient(sound_definition: TirSoundDefinition) -> AudioStreamPlayer:
	if sound_definition == null:
		return null
	if not _is_sound_active(sound_definition):
		return null

	var key: String = String(sound_definition.id)
	if key.is_empty():
		key = "ambient_%d" % sound_definition.get_instance_id()

	var player: AudioStreamPlayer = _ambient_players.get(key, null) as AudioStreamPlayer
	if player == null:
		player = AudioStreamPlayer.new()
		player.name = "Ambient_%s" % key
		_attach_player(player)
		_ambient_players[key] = player

	_apply_sound_to_player(player, sound_definition, false)
	player.autoplay = false
	player.play()
	_sound_by_player_id[player.get_instance_id()] = sound_definition
	return player


func play_at_position(sound_definition: TirSoundDefinition, position: Vector3) -> AudioStreamPlayer3D:
	if sound_definition == null:
		return null
	if not _is_sound_active(sound_definition):
		return null

	var player := AudioStreamPlayer3D.new()
	player.name = "WorldSound_%s" % String(sound_definition.id)
	player.position = position
	_apply_sound_to_player(player, sound_definition, true)
	player.autoplay = false
	player.finished.connect(player.queue_free)
	_attach_player(player)
	player.play()

	_positional_players.append(player)
	_sound_by_player_id[player.get_instance_id()] = sound_definition
	return player


func register_entity_sound(entity_id: String, player: AudioStreamPlayer3D) -> void:
	if entity_id.is_empty() or player == null:
		return
	_entity_players[entity_id] = player


func unregister_entity_sound(entity_id: String) -> void:
	if _entity_players.has(entity_id):
		var player: AudioStreamPlayer3D = _entity_players[entity_id] as AudioStreamPlayer3D
		if player != null:
			_sound_by_player_id.erase(player.get_instance_id())
		_entity_players.erase(entity_id)


func set_otherworld_fade(factor: float) -> void:
	otherworld_fade = clampf(factor, 0.0, 1.0)


func set_time_of_day(value: float) -> void:
	time_of_day = wrapf(value, 0.0, 1.0)


func set_season(value: int) -> void:
	season = clampi(value, 0, 3)


func has_entity_sound(entity_id: String) -> bool:
	return _entity_players.has(entity_id)


func has_debug_commands_registered() -> bool:
	var debug_manager: Node = _get_debug_manager()
	if debug_manager == null:
		return false
	return bool(debug_manager.call("has_command", "audio_fade")) and bool(debug_manager.call("has_command", "audio_mute"))


func set_debug_manager_for_tests(node: Node) -> void:
	_debug_manager_override = node


func _update_volumes(delta: float) -> void:
	for player: AudioStreamPlayer in _ambient_players.values():
		_update_player_volume(player, delta)
	for player: AudioStreamPlayer3D in _entity_players.values():
		_update_player_volume(player, delta)
	for player in _positional_players:
		_update_player_volume(player, delta)


func _update_player_volume(player: Node, delta: float) -> void:
	if player == null:
		return
	var sound_definition: TirSoundDefinition = _sound_by_player_id.get(player.get_instance_id(), null) as TirSoundDefinition
	var base_volume: float = 0.0 if sound_definition == null else sound_definition.volume_db
	var target_volume: float = base_volume + _calculate_fade_db(sound_definition)
	var current_volume: float = float(player.get("volume_db"))
	player.set("volume_db", lerpf(current_volume, target_volume, clampf(delta * volume_lerp_speed, 0.0, 1.0)))


func _calculate_fade_db(sound_definition: TirSoundDefinition) -> float:
	if muted:
		return MAX_FADE_DB
	if sound_definition != null and not _is_sound_active(sound_definition):
		return MAX_FADE_DB

	var fade_factor: float = otherworld_fade
	if sound_definition != null:
		var layer_factor: float = 1.0 - float(clampi(sound_definition.otherworld_layer, 0, 3)) * 0.22
		layer_factor = clampf(layer_factor, 0.2, 1.0)
		fade_factor *= layer_factor
		if not sound_definition.fades_near_otherworld:
			fade_factor *= 0.5
	return lerpf(0.0, MAX_FADE_DB, clampf(fade_factor, 0.0, 1.0))


func _is_sound_active(sound_definition: TirSoundDefinition) -> bool:
	if sound_definition == null:
		return false
	if sound_definition.active_seasons.size() > 0 and not sound_definition.active_seasons.has(season):
		return false

	var start: float = sound_definition.active_time_start
	var ending: float = sound_definition.active_time_end
	if is_equal_approx(start, ending):
		return true
	if start < ending:
		return time_of_day >= start and time_of_day <= ending
	return time_of_day >= start or time_of_day <= ending


func _apply_sound_to_player(player: Node, sound_definition: TirSoundDefinition, positional: bool) -> void:
	if player == null or sound_definition == null:
		return
	player.set("stream", sound_definition.stream)
	player.set("bus", sound_definition.bus if not sound_definition.bus.is_empty() else (position_default_bus if positional else ambient_default_bus))
	player.set("volume_db", sound_definition.volume_db)
	player.set("pitch_scale", _resolve_pitch(sound_definition))

	if player is AudioStreamPlayer3D:
		var player_3d: AudioStreamPlayer3D = player as AudioStreamPlayer3D
		player_3d.max_distance = sound_definition.max_distance
		player_3d.attenuation_filter_cutoff_hz = 5000.0
		player_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE


func _resolve_pitch(sound_definition: TirSoundDefinition) -> float:
	if sound_definition.pitch_randomness <= 0.0:
		return sound_definition.pitch_scale
	var random_offset: float = randf_range(-sound_definition.pitch_randomness, sound_definition.pitch_randomness)
	return max(0.01, sound_definition.pitch_scale + random_offset)


func _cleanup_positional_players() -> void:
	var still_alive: Array[AudioStreamPlayer3D] = []
	for player in _positional_players:
		if is_instance_valid(player):
			still_alive.append(player)
		else:
			_sound_by_player_id.erase(player.get_instance_id())
	_positional_players = still_alive


func _attach_player(player: Node) -> void:
	if is_inside_tree():
		add_child(player)


func _register_debug_commands() -> void:
	var debug_manager: Node = _get_debug_manager()
	if debug_manager == null:
		return
	if debug_manager.has_method("unregister_command"):
		debug_manager.call("unregister_command", "audio_fade")
		debug_manager.call("unregister_command", "audio_mute")
	debug_manager.call("register_command", "audio_fade", Callable(self, "_cmd_audio_fade"), "Setzt Anderswelt-Audiofade 0.0-1.0")
	debug_manager.call("register_command", "audio_mute", Callable(self, "_cmd_audio_mute"), "Schaltet Audio stumm/laut")


func _get_debug_manager() -> Node:
	if _debug_manager_override != null:
		return _debug_manager_override
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/DebugManager")


func _cmd_audio_fade(args: PackedStringArray) -> String:
	if args.size() < 1:
		return "Fehler: audio_fade erwartet 1 numerischen Wert."
	var raw: String = String(args[0])
	if not raw.is_valid_float():
		return "Fehler: N muss numerisch sein."
	set_otherworld_fade(float(raw))
	return "Audio-Fade = %.2f" % otherworld_fade


func _cmd_audio_mute(_args: PackedStringArray) -> String:
	muted = not muted
	return "Audio %s" % ("stumm" if muted else "aktiv")
