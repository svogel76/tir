extends TirBaseResourceRegistry
class_name TirSeasonRegistry


func get_registry_name() -> String:
	return "SeasonRegistry"


func get_expected_resource_class() -> StringName:
	return &"TirSeasonDefinition"


func get_expected_script_path() -> String:
	return "res://data/definitions/season_definition.gd"


func get_typed_by_id(id: StringName) -> TirSeasonDefinition:
	return super.get_by_id(id) as TirSeasonDefinition


func get_all_typed() -> Array[TirSeasonDefinition]:
	var out: Array[TirSeasonDefinition] = []
	for resource in super.get_all():
		out.append(resource as TirSeasonDefinition)
	return out
