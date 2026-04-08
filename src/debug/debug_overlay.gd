extends CanvasLayer
class_name TirDebugOverlay

@onready var _label: Label = $PanelContainer/Label


func set_overlay_text(text: String) -> void:
	_label.text = text

