extends Resource
class_name TirPlantPopulationEntry

@export var plant: TirPlantDefinition
@export_range(0.0, 100.0, 0.01) var spawn_weight: float = 1.0
@export_range(0.0, 100000.0, 0.1, "suffix:km2") var max_density_per_km2: float = 1.0
