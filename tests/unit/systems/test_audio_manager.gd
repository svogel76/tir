extends "res://addons/gut/test.gd"


class DebugManagerStub:
	extends Node
	var commands: Dictionary = {}

	func register_command(command_name: String, command_callable: Callable, description: String) -> bool:
		commands[command_name] = {"callable": command_callable, "description": description}
		return true

	func unregister_command(command_name: String) -> void:
		commands.erase(command_name)

	func has_command(command_name: String) -> bool:
		return commands.has(command_name)


var _audio_manager: Node = null


func before_each() -> void:
	_audio_manager = load("res://src/systems/audio_manager.gd").new()


func after_each() -> void:
	if _audio_manager != null:
		_audio_manager.free()
		_audio_manager = null
	var debug_node: Node = get_tree().root.get_node_or_null("DebugManager")
	if debug_node != null:
		debug_node.queue_free()


func _make_sound() -> TirSoundDefinition:
	var sound := TirSoundDefinition.new()
	sound.id = &"test_sound"
	sound.stream = null
	sound.active_seasons = PackedInt32Array([0, 1, 2, 3])
	return sound


func test_set_otherworld_fade_clamps_to_range() -> void:
	_audio_manager.set_otherworld_fade(-3.0)
	assert_eq(_audio_manager.otherworld_fade, 0.0)
	_audio_manager.set_otherworld_fade(2.5)
	assert_eq(_audio_manager.otherworld_fade, 1.0)


func test_register_and_unregister_entity_sound() -> void:
	var player := AudioStreamPlayer3D.new()
	_audio_manager.register_entity_sound("deer_01", player)
	assert_true(_audio_manager.has_entity_sound("deer_01"))
	_audio_manager.unregister_entity_sound("deer_01")
	assert_false(_audio_manager.has_entity_sound("deer_01"))
	player.free()


func test_play_at_position_creates_player3d() -> void:
	_audio_manager.set_season(0)
	_audio_manager.set_time_of_day(0.5)
	var sound := _make_sound()
	var player: Variant = _audio_manager.play_at_position(sound, Vector3(1.0, 2.0, 3.0))
	assert_not_null(player)
	assert_true(player is AudioStreamPlayer3D)
	assert_eq(player.position, Vector3(1.0, 2.0, 3.0))
	player.free()


func test_debug_commands_are_registered() -> void:
	var debug_stub := DebugManagerStub.new()
	_audio_manager.set_debug_manager_for_tests(debug_stub)
	_audio_manager._register_debug_commands()
	assert_true(debug_stub.has_command("audio_fade"))
	assert_true(debug_stub.has_command("audio_mute"))
	debug_stub.free()


func test_sounds_outside_active_season_are_not_played() -> void:
	_audio_manager.set_season(0)
	_audio_manager.set_time_of_day(0.5)
	var sound := _make_sound()
	sound.active_seasons = PackedInt32Array([1, 2])
	var player: Variant = _audio_manager.play_at_position(sound, Vector3.ZERO)
	assert_null(player)
