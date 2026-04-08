extends TirBaseResourceRegistry
class_name TirPlantRegistry


func get_registry_name() -> String:
	return "PlantRegistry"


func get_expected_resource_class() -> StringName:
	return &"TirPlantDefinition"


func get_expected_script_path() -> String:
	return "res://data/definitions/plant_definition.gd"


func get_typed_by_id(id: StringName) -> TirPlantDefinition:
	return super.get_by_id(id) as TirPlantDefinition


func get_all_typed() -> Array[TirPlantDefinition]:
	var out: Array[TirPlantDefinition] = []
	for resource in super.get_all():
		out.append(resource as TirPlantDefinition)
	return out
