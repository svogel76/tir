extends Resource
class_name TirBiomeDefinition

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var vegetation: Array[TirPlantPopulationEntry] = []
@export var animal_population: Array[TirAnimalPopulationEntry] = []

@export var ambient_sounds: Array[TirSoundDefinition] = []
@export var fog_color: Color = Color(0.5, 0.6, 0.7, 1.0)
@export_range(0.0, 1.0, 0.01) var fog_density: float = 0.2
@export_range(0.0, 1.0, 0.01) var otherworld_proximity: float = 0.0
