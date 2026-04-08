extends CanvasLayer
class_name TirDebugConsole

signal command_submitted(command_line: String)
signal close_requested

@export_range(5, 100, 1) var max_lines: int = 18

@onready var _log: RichTextLabel = $MarginContainer/PanelContainer/VBoxContainer/Log
@onready var _input: LineEdit = $MarginContainer/PanelContainer/VBoxContainer/Input


func _ready() -> void:
	_input.text_submitted.connect(_on_text_submitted)
	visible = false


func open_console() -> void:
	visible = true
	_input.editable = true
	_input.grab_focus()


func close_console() -> void:
	visible = false
	_input.release_focus()


func clear_input() -> void:
	_input.text = ""


func append_log(line: String) -> void:
	if line.is_empty():
		return
	_log.append_text(line + "\n")


func set_log_lines(lines: PackedStringArray) -> void:
	if _log == null:
		return
	_log.clear()
	var start: int = max(0, lines.size() - max_lines)
	for i in range(start, lines.size()):
		_log.append_text(lines[i] + "\n")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_requested.emit()
		get_viewport().set_input_as_handled()


func _on_text_submitted(new_text: String) -> void:
	command_submitted.emit(new_text)
