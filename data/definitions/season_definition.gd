extends Resource
class_name TirSeasonDefinition

enum PrecipitationType {
	NONE,
	RAIN,
	SNOW,
	MIXED
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_range(1.0, 24.0, 0.1, "suffix:h") var daylight_hours: float = 12.0
@export_range(-60.0, 60.0, 0.1, "suffix:C") var temperature_min_c: float = 0.0
@export_range(-60.0, 60.0, 0.1, "suffix:C") var temperature_max_c: float = 15.0

@export var light_tint: Color = Color(1.0, 0.97, 0.9, 1.0)
@export var precipitation_type: PrecipitationType = PrecipitationType.RAIN
@export_range(0.0, 1.0, 0.01) var precipitation_intensity: float = 0.3
@export_range(0.0, 1.0, 0.01) var atmosphere_density: float = 0.3

@export var celtic_festivals: PackedStringArray = PackedStringArray()
@export_range(0.0, 1.0, 0.01) var otherworld_strength: float = 0.0
