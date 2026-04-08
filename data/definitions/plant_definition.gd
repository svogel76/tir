extends Resource
class_name TirPlantDefinition

enum PlantType {
	HERB,
	MUSHROOM,
	BERRY,
	TREE,
	SHRUB,
	FLOWER
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var plant_type: PlantType = PlantType.HERB
@export_flags("Spring", "Summer", "Autumn", "Winter") var growing_seasons: int = 0b1111
@export var allowed_biome_ids: PackedStringArray = PackedStringArray()

@export_range(0.0, 3650.0, 0.1, "suffix:days") var regrow_time_days: float = 3.0
@export var harvest: Array[TirPlantHarvestEntry] = []
@export var effects: Array[TirPlantEffectDefinition] = []
@export var synergies: Array[TirPlantSynergyDefinition] = []
