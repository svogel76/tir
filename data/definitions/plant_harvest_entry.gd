extends Resource
class_name TirPlantHarvestEntry

@export var item: TirItemDefinition
@export_range(1, 999, 1) var min_amount: int = 1
@export_range(1, 999, 1) var max_amount: int = 1
@export_range(0.0, 1.0, 0.01) var harvest_chance: float = 1.0
