extends TirBaseResourceRegistry
class_name TirBiomeRegistry


func get_registry_name() -> String:
	return "BiomeRegistry"


func get_expected_resource_class() -> StringName:
	return &"TirBiomeDefinition"


func get_expected_script_path() -> String:
	return "res://data/definitions/biome_definition.gd"


func get_typed_by_id(id: StringName) -> TirBiomeDefinition:
	return super.get_by_id(id) as TirBiomeDefinition


func get_all_typed() -> Array[TirBiomeDefinition]:
	var out: Array[TirBiomeDefinition] = []
	for resource in super.get_all():
		out.append(resource as TirBiomeDefinition)
	return out
