extends Resource
class_name TirSoundDefinition

@export var id: StringName
@export var stream: AudioStream
@export var bus: StringName = &"Master"

@export_range(-80.0, 24.0, 0.1, "suffix:dB") var volume_db: float = 0.0
@export_range(0.01, 4.0, 0.01) var pitch_scale: float = 1.0
@export_range(0.0, 1.0, 0.01) var pitch_randomness: float = 0.0

@export var is_positional_3d: bool = true
@export_range(0.1, 5000.0, 0.1, "suffix:m") var max_distance: float = 35.0
@export_range(0.0, 10.0, 0.01) var attenuation: float = 1.0

@export var fades_near_otherworld: bool = false
