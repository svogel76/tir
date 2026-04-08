extends Resource
class_name TirPlantEffectDefinition

enum EffectType {
	HEALING,
	POISON,
	STAMINA,
	WARMTH,
	HUNGER,
	HYDRATION
}

@export var effect_type: EffectType = EffectType.HEALING
@export_range(-100.0, 100.0, 0.1) var magnitude: float = 0.0
@export_range(0.0, 36000.0, 0.1, "suffix:s") var duration_seconds: float = 0.0
