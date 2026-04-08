extends "res://addons/gut/test.gd"


class HelperGameRegistry:
	extends TirGameRegistry

	var captured_warnings: Array[String] = []

	func _warn_validation(registry_name: String, problem: String, id: StringName) -> void:
		var id_text := String(id)
		if id_text.is_empty():
			id_text = "<missing>"
		captured_warnings.append('[TirValidation] %s: %s (id: "%s")' % [registry_name, problem, id_text])


func _make_temp_base_root(prefix: String) -> String:
	var root := "user://tir_tests_%s_%s" % [prefix, Time.get_ticks_usec()]
	for folder in ["items", "animals", "plants", "biomes", "seasons"]:
		DirAccess.make_dir_recursive_absolute(root.path_join(folder))
	return root


func _save_item(path: String, id_value: StringName) -> void:
	var item := TirItemDefinition.new()
	item.id = id_value
	assert_eq(ResourceSaver.save(item, path), OK)


func test_validate_all_captures_structural_and_reference_warnings() -> void:
	var base_root := _make_temp_base_root("registry_validation")

	# Duplicate IDs and empty ID in ItemRegistry.
	_save_item(base_root.path_join("items/dup_a.tres"), &"dup_item")
	_save_item(base_root.path_join("items/dup_b.tres"), &"dup_item")
	_save_item(base_root.path_join("items/empty_id.tres"), StringName())

	# One valid animal plus invalid otherworld_variant reference.
	var ghost_animal := TirAnimalDefinition.new()
	ghost_animal.id = &"ghost_animal"

	var deer := TirAnimalDefinition.new()
	deer.id = &"deer"
	deer.otherworld_variant = ghost_animal
	assert_eq(ResourceSaver.save(deer, base_root.path_join("animals/deer.tres")), OK)

	# One valid plant.
	var herb := TirPlantDefinition.new()
	herb.id = &"herb"
	assert_eq(ResourceSaver.save(herb, base_root.path_join("plants/herb.tres")), OK)

	# Biome with invalid references.
	var missing_animal := TirAnimalDefinition.new()
	missing_animal.id = &"missing_animal"
	var animal_pop := TirAnimalPopulationEntry.new()
	animal_pop.animal = missing_animal

	var missing_plant := TirPlantDefinition.new()
	missing_plant.id = &"missing_plant"
	var plant_pop := TirPlantPopulationEntry.new()
	plant_pop.plant = missing_plant

	var biome := TirBiomeDefinition.new()
	biome.id = &"meadow"
	biome.animal_population = [animal_pop]
	biome.vegetation = [plant_pop]
	assert_eq(ResourceSaver.save(biome, base_root.path_join("biomes/meadow.tres")), OK)

	# Keep seasons folder valid.
	var spring := TirSeasonDefinition.new()
	spring.id = &"spring"
	assert_eq(ResourceSaver.save(spring, base_root.path_join("seasons/spring.tres")), OK)

	var registry := HelperGameRegistry.new()
	registry.reload_all("user://tir_tests_non_existing_mod_path", base_root)
	registry.validate_all(true)

	var warnings_text := "\n".join(registry.captured_warnings)
	assert_true(warnings_text.contains("ItemRegistry: Doppelte ID"))
	assert_true(warnings_text.contains("ItemRegistry: Resource ohne gueltige ID"))
	assert_true(warnings_text.contains("AnimalRegistry: otherworld_variant verweist auf nicht registriertes Animal"))
	assert_true(warnings_text.contains("BiomeRegistry: Biome verweist auf nicht registriertes Animal"))
	assert_true(warnings_text.contains("BiomeRegistry: Biome verweist auf nicht registrierte Plant"))
	registry.free()
