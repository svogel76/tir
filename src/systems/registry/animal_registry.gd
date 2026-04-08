extends TirBaseResourceRegistry
class_name TirAnimalRegistry


func get_registry_name() -> String:
	return "AnimalRegistry"


func get_expected_resource_class() -> StringName:
	return &"TirAnimalDefinition"


func get_expected_script_path() -> String:
	return "res://data/definitions/animal_definition.gd"


func get_typed_by_id(id: StringName) -> TirAnimalDefinition:
	return super.get_by_id(id) as TirAnimalDefinition


func get_all_typed() -> Array[TirAnimalDefinition]:
	var out: Array[TirAnimalDefinition] = []
	for resource in super.get_all():
		out.append(resource as TirAnimalDefinition)
	return out
