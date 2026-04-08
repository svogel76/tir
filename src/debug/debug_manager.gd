extends Node

const OVERLAY_SCENE: PackedScene = preload("res://src/debug/debug_overlay.tscn")
const CONSOLE_SCENE: PackedScene = preload("res://src/debug/debug_console.tscn")
const MAX_LOG_LINES: int = 24

var overlay_enabled: bool = false
var console_open: bool = false
var debug_time_of_day: float = 0.5
var debug_season: int = 0
var suppress_warnings_for_tests: bool = false

var _commands: Dictionary = {}
var _log_lines: PackedStringArray = PackedStringArray()
var _overlay: Node = null
var _console: Node = null
var _defaults_registered: bool = false


func _init() -> void:
	_register_default_commands()


func _ready() -> void:
	_resolve_ui()
	_apply_overlay_visibility()


func _process(_delta: float) -> void:
	if not overlay_enabled:
		return
	_update_overlay_text()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			toggle_overlay()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F1:
			toggle_console()
			get_viewport().set_input_as_handled()
			return


func register_command(command_name: String, command_callable: Callable, description: String) -> bool:
	var key: String = command_name.strip_edges().to_lower()
	if key.is_empty():
		_warn("[TirDebug] Leerer Command-Name wurde ignoriert.")
		return false
	if _commands.has(key):
		_warn("[TirDebug] Command bereits registriert: %s" % key)
		return false
	_commands[key] = {
		"callable": command_callable,
		"description": description.strip_edges()
	}
	return true


func has_command(command_name: String) -> bool:
	return _commands.has(command_name.strip_edges().to_lower())


func unregister_command(command_name: String) -> void:
	var key: String = command_name.strip_edges().to_lower()
	if _commands.has(key):
		_commands.erase(key)


func execute_command_line(command_line: String) -> String:
	var line: String = command_line.strip_edges()
	if line.is_empty():
		return "Leerer Befehl."

	var tokens: PackedStringArray = PackedStringArray(line.split(" ", false))
	var command_name: String = String(tokens[0]).to_lower()
	var args: PackedStringArray = PackedStringArray()
	for i in range(1, tokens.size()):
		args.append(tokens[i])
	return execute_command(command_name, args)


func execute_command(command_name: String, args: PackedStringArray = PackedStringArray()) -> String:
	var key: String = command_name.strip_edges().to_lower()
	if not _commands.has(key):
		return "Unbekannter Befehl: %s. Nutze 'help'." % key
	var command_data: Dictionary = _commands[key]
	var callable: Callable = command_data.get("callable", Callable())
	if not callable.is_valid():
		return "Command '%s' ist ungültig." % key
	return String(callable.call(args))


func get_log_lines() -> PackedStringArray:
	return _log_lines


func toggle_overlay() -> void:
	overlay_enabled = not overlay_enabled
	_apply_overlay_visibility()


func toggle_console() -> void:
	if console_open:
		_close_console()
	else:
		_open_console()


func set_time_of_day(value: float) -> void:
	debug_time_of_day = clampf(value, 0.0, 1.0)


func set_season(value: int) -> void:
	debug_season = clampi(value, 0, 3)


func _open_console() -> void:
	_resolve_ui()
	console_open = true
	overlay_enabled = true
	_apply_overlay_visibility()
	if _console != null:
		_console.call("open_console")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_player_input_paused(true)


func _close_console() -> void:
	console_open = false
	if _console != null:
		_console.call("close_console")
		_console.call("clear_input")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_set_player_input_paused(false)


func _apply_overlay_visibility() -> void:
	if _overlay != null:
		_overlay.set("visible", overlay_enabled)


func _resolve_ui() -> void:
	if get_tree() == null:
		return

	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return

	if _overlay == null:
		_overlay = scene_root.get_node_or_null("DebugOverlay")
	if _overlay == null:
		_overlay = OVERLAY_SCENE.instantiate()
		scene_root.add_child(_overlay)

	if _console == null:
		_console = scene_root.get_node_or_null("DebugConsole")
	if _console == null:
		_console = CONSOLE_SCENE.instantiate()
		scene_root.add_child(_console)

	if _console.has_signal("command_submitted") and not _console.is_connected("command_submitted", Callable(self, "_on_console_submitted")):
		_console.connect("command_submitted", Callable(self, "_on_console_submitted"))
	if _console.has_signal("close_requested") and not _console.is_connected("close_requested", Callable(self, "_on_console_close_requested")):
		_console.connect("close_requested", Callable(self, "_on_console_close_requested"))
	if _console.has_method("set_log_lines"):
		_console.call_deferred("set_log_lines", _log_lines)


func _update_overlay_text() -> void:
	if _overlay == null:
		return

	var fps: int = roundi(Engine.get_frames_per_second())
	var player: Node3D = _get_player_node()
	var position_text: String = "N/A"
	var state_text: String = "N/A"
	if player != null:
		var p: Vector3 = player.global_position
		position_text = "(%d, %d, %d)" % [roundi(p.x), roundi(p.y), roundi(p.z)]
		state_text = _resolve_player_state_text(player)

	var readable_time: String = "%.2f" % debug_time_of_day
	var season_value: int = debug_season
	var day_night: Node = _get_day_night_node()
	if day_night != null:
		if day_night.has_method("get_time_string"):
			readable_time = String(day_night.call("get_time_string"))
		if day_night.has_method("get_current_season"):
			season_value = int(day_night.call("get_current_season"))

	var text := "DEBUG MODE\nFPS: %d\nPos: %s\nState: %s\nTime: %s\nSeason: %d" % [
		fps,
		position_text,
		state_text,
		readable_time,
		season_value
	]
	_overlay.call("set_overlay_text", text)


func _resolve_player_state_text(player: Node) -> String:
	var raw_state: Variant = player.get("movement_state")
	if typeof(raw_state) != TYPE_INT:
		return "UNKNOWN"
	match int(raw_state):
		0: return "STANDING"
		1: return "WALKING"
		2: return "RUNNING"
		3: return "CROUCHING"
		4: return "JUMPING"
		5: return "AIRBORNE"
		_: return "UNKNOWN"


func _get_player_node() -> Node3D:
	if get_tree() == null:
		return null
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node3D


func _get_day_night_node() -> Node:
	if not is_inside_tree():
		return null
	if get_tree() == null:
		return null
	var nodes: Array[Node] = get_tree().get_nodes_in_group("day_night_cycle")
	if nodes.is_empty():
		return null
	return nodes[0]


func _set_player_input_paused(paused: bool) -> void:
	if get_tree() == null:
		return
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.has_method("set_input_enabled"):
			player.call("set_input_enabled", not paused)


func _on_console_submitted(command_line: String) -> void:
	var clean: String = command_line.strip_edges()
	if clean.is_empty():
		return
	_push_log("> " + clean)
	var result: String = execute_command_line(clean)
	_push_log(result)
	if _console != null:
		_console.call("clear_input")
		_console.call("set_log_lines", _log_lines)


func _on_console_close_requested() -> void:
	_close_console()


func _push_log(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > MAX_LOG_LINES:
		_log_lines.remove_at(0)


func _warn(message: String) -> void:
	if suppress_warnings_for_tests:
		return
	push_warning(message)


func _register_default_commands() -> void:
	if _defaults_registered:
		return
	_defaults_registered = true

	register_command("help", _cmd_help, "Zeigt alle verfugbaren Befehle")
	register_command("tp", _cmd_tp, "Teleportiert den Spieler: tp X Y Z")
	register_command("timescale", _cmd_timescale, "Setzt Engine.time_scale: timescale N")
	register_command("time", _cmd_time, "Setzt Debug-Tageszeit 0.0-1.0")
	register_command("season", _cmd_season, "Setzt Debug-Jahreszeit 0-3")
	register_command("fps", _cmd_fps, "Zeigt die aktuellen FPS")


func _cmd_help(_args: PackedStringArray) -> String:
	var keys: Array = _commands.keys()
	keys.sort()
	var lines: PackedStringArray = PackedStringArray()
	for key in keys:
		var data: Dictionary = _commands[key]
		lines.append("%s - %s" % [key, String(data.get("description", ""))])
	return "\n".join(lines)


func _cmd_tp(args: PackedStringArray) -> String:
	if args.size() < 3:
		return "Fehler: tp erwartet 3 numerische Werte (X Y Z)."
	var x_parse: Dictionary = _parse_float_arg(args, 0, "X")
	if not x_parse.get("ok", false):
		return x_parse.get("error", "Fehler")
	var y_parse: Dictionary = _parse_float_arg(args, 1, "Y")
	if not y_parse.get("ok", false):
		return y_parse.get("error", "Fehler")
	var z_parse: Dictionary = _parse_float_arg(args, 2, "Z")
	if not z_parse.get("ok", false):
		return z_parse.get("error", "Fehler")

	var player: Node3D = _get_player_node()
	if player == null:
		return "Fehler: Kein Spieler in Gruppe 'player' gefunden."
	var x: float = float(x_parse.get("value", 0.0))
	var y: float = float(y_parse.get("value", 0.0))
	var z: float = float(z_parse.get("value", 0.0))
	player.global_position = Vector3(x, y, z)
	return "Teleportiert zu (%.2f, %.2f, %.2f)." % [x, y, z]


func _cmd_timescale(args: PackedStringArray) -> String:
	if args.size() < 1:
		return "Fehler: timescale erwartet 1 numerischen Wert."
	var parse: Dictionary = _parse_float_arg(args, 0, "N")
	if not parse.get("ok", false):
		return parse.get("error", "Fehler")
	var value: float = max(0.01, float(parse.get("value", 1.0)))
	var day_night: Node = _get_day_night_node()
	if day_night != null and day_night.has_method("set_day_speed_scale"):
		day_night.call("set_day_speed_scale", value)
		return "Tagesgeschwindigkeit = %.3f" % value
	Engine.time_scale = value
	return "Engine.time_scale = %.3f" % value


func _cmd_time(args: PackedStringArray) -> String:
	if args.size() < 1:
		return "Fehler: time erwartet 1 numerischen Wert (0.0-1.0)."
	var parse: Dictionary = _parse_float_arg(args, 0, "N")
	if not parse.get("ok", false):
		return parse.get("error", "Fehler")
	var value: float = float(parse.get("value", 0.5))
	var day_night: Node = _get_day_night_node()
	if day_night != null and day_night.has_method("set_time_of_day"):
		day_night.call("set_time_of_day", value)
		if day_night.has_method("get_time_string"):
			return "Tageszeit gesetzt: %s (%.2f)" % [String(day_night.call("get_time_string")), value]
		return "Tageszeit gesetzt auf %.2f" % value
	set_time_of_day(value)
	return "Tageszeit gesetzt auf %.2f" % debug_time_of_day


func _cmd_season(args: PackedStringArray) -> String:
	if args.size() < 1:
		return "Fehler: season erwartet 1 Ganzzahl (0-3)."
	if not String(args[0]).is_valid_int():
		return "Fehler: season erwartet eine Ganzzahl (0-3)."
	set_season(int(args[0]))
	return "Jahreszeit gesetzt auf %d" % debug_season


func _cmd_fps(_args: PackedStringArray) -> String:
	return "FPS: %d" % Engine.get_frames_per_second()


func _parse_float_arg(args: PackedStringArray, index: int, label: String) -> Dictionary:
	if index >= args.size():
		return {"ok": false, "error": "Fehler: Fehlendes Argument %s." % label}
	var raw: String = String(args[index])
	if not raw.is_valid_float():
		return {"ok": false, "error": "Fehler: %s muss numerisch sein." % label}
	return {"ok": true, "value": float(raw)}
