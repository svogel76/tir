extends Resource
class_name TirAnimalDefinition

enum BehaviorType {
	PASSIVE,
	FLIGHT,
	AGGRESSIVE
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var behavior: BehaviorType = BehaviorType.PASSIVE
@export var is_predator: bool = false
@export var is_passive: bool = true
@export_range(1.0, 10000.0, 0.1) var max_health: float = 10.0
@export_range(0.0, 100.0, 0.1, "suffix:m/s") var move_speed: float = 4.0
@export_range(0.0, 500.0, 0.1, "suffix:m") var detection_range: float = 20.0
@export_range(0.0, 500.0, 0.1, "suffix:m") var aggression_range: float = 8.0

@export_flags("Dawn", "Day", "Dusk", "Night") var active_day_times: int = 0b1111
@export_flags("Spring", "Summer", "Autumn", "Winter") var active_seasons: int = 0b1111

@export var drops: Array[TirAnimalDropEntry] = []
@export var sound_profile: TirSoundProfileDefinition

@export var otherworld_variant: TirAnimalDefinition
@export_range(0.0, 1.0, 0.01) var otherworld_presence_scale: float = 1.0
