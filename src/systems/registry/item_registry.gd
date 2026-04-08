extends TirBaseResourceRegistry
class_name TirItemRegistry


func get_registry_name() -> String:
	return "ItemRegistry"


func get_expected_resource_class() -> StringName:
	return &"TirItemDefinition"


func get_expected_script_path() -> String:
	return "res://data/definitions/item_definition.gd"


func get_typed_by_id(id: StringName) -> TirItemDefinition:
	return super.get_by_id(id) as TirItemDefinition


func get_all_typed() -> Array[TirItemDefinition]:
	var out: Array[TirItemDefinition] = []
	for resource in super.get_all():
		out.append(resource as TirItemDefinition)
	return out
