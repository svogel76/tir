extends "res://addons/gut/test.gd"

var _manager: Node = null


func before_each() -> void:
	_manager = load("res://src/debug/debug_manager.gd").new()


func after_each() -> void:
	Engine.time_scale = 1.0
	if _manager != null:
		_manager.free()
		_manager = null


func test_register_command_and_has_command() -> void:
	var ok: bool = _manager.register_command("echo_cmd", func(args: PackedStringArray) -> String: return "ok %d" % args.size(), "Echo")
	assert_true(ok)
	assert_true(_manager.has_command("echo_cmd"))
	assert_false(_manager.has_command("missing_cmd"))


func test_duplicate_registration_returns_false_and_does_not_override() -> void:
	_manager.suppress_warnings_for_tests = true
	var first: bool = _manager.register_command("dup_cmd", func(_args: PackedStringArray) -> String: return "first", "First")
	var second: bool = _manager.register_command("dup_cmd", func(_args: PackedStringArray) -> String: return "second", "Second")
	var result: String = _manager.execute_command_line("dup_cmd")
	assert_true(first)
	assert_false(second)
	assert_eq(result, "first")


func test_help_returns_non_empty_list() -> void:
	var result: String = _manager.execute_command_line("help")
	assert_false(result.strip_edges().is_empty())
	assert_string_contains(result, "help -")


func test_known_unknown_and_timescale_commands() -> void:
	var known: String = _manager.execute_command_line("fps")
	var unknown: String = _manager.execute_command_line("definitely_unknown")
	var scale_result: String = _manager.execute_command_line("timescale 2.0")
	assert_string_contains(known, "FPS:")
	assert_string_contains(unknown, "Unbekannter Befehl")
	assert_almost_eq(Engine.time_scale, 2.0, 0.001)
	assert_string_contains(scale_result, "Engine.time_scale")


func test_argument_parsing_and_errors() -> void:
	var time_result: String = _manager.execute_command_line("time 0.75")
	var too_few: String = _manager.execute_command_line("timescale")
	var non_numeric: String = _manager.execute_command_line("timescale fast")
	assert_string_contains(time_result, "0.75")
	assert_string_contains(too_few, "erwartet")
	assert_string_contains(non_numeric, "muss numerisch")
