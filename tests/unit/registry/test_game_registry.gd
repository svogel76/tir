extends "res://addons/gut/test.gd"


func _make_temp_base_root(prefix: String) -> String:
	var root := "user://tir_tests_%s_%s" % [prefix, Time.get_ticks_usec()]
	for folder in ["items", "animals", "plants", "biomes", "seasons"]:
		DirAccess.make_dir_recursive_absolute(root.path_join(folder))
	return root


func _save_minimum_data_set(root: String) -> void:
	var item := TirItemDefinition.new()
	item.id = &"flint"
	item.display_name = "Feuerstein"
	assert_eq(ResourceSaver.save(item, root.path_join("items/flint.tres")), OK)

	var animal := TirAnimalDefinition.new()
	animal.id = &"deer"
	animal.display_name = "Hirsch"
	assert_eq(ResourceSaver.save(animal, root.path_join("animals/deer.tres")), OK)

	var plant := TirPlantDefinition.new()
	plant.id = &"herb"
	plant.display_name = "Kraut"
	assert_eq(ResourceSaver.save(plant, root.path_join("plants/herb.tres")), OK)

	var biome := TirBiomeDefinition.new()
	biome.id = &"meadow"
	biome.display_name = "Wiese"
	assert_eq(ResourceSaver.save(biome, root.path_join("biomes/meadow.tres")), OK)

	var season := TirSeasonDefinition.new()
	season.id = &"spring"
	season.display_name = "Fruehling"
	assert_eq(ResourceSaver.save(season, root.path_join("seasons/spring.tres")), OK)


func test_reload_all_loads_all_sub_registries() -> void:
	var base_root := _make_temp_base_root("game_registry_reload")
	_save_minimum_data_set(base_root)

	var registry := TirGameRegistry.new()
	registry.reload_all("user://tir_tests_missing_mod_path", base_root)

	assert_not_null(registry.items.get_by_id(&"flint"))
	assert_not_null(registry.animals.get_by_id(&"deer"))
	assert_not_null(registry.plants.get_by_id(&"herb"))
	assert_not_null(registry.biomes.get_by_id(&"meadow"))
	assert_not_null(registry.seasons.get_by_id(&"spring"))
	registry.free()


func test_mod_override_replaces_base_resource_and_missing_mod_path_is_safe() -> void:
	var base_root := _make_temp_base_root("game_registry_mod_base")
	var mod_root := "user://tir_tests_mod_root_%s" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(mod_root.path_join("instances/items"))

	var item_base := TirItemDefinition.new()
	item_base.id = &"flint"
	item_base.display_name = "Base Flint"
	assert_eq(ResourceSaver.save(item_base, base_root.path_join("items/flint.tres")), OK)

	var item_mod := TirItemDefinition.new()
	item_mod.id = &"flint"
	item_mod.display_name = "Mod Flint"
	assert_eq(ResourceSaver.save(item_mod, mod_root.path_join("instances/items/flint.tres")), OK)

	var registry := TirGameRegistry.new()
	registry.reload_all(mod_root, base_root)
	assert_eq(registry.items.get_by_id(&"flint").display_name, "Mod Flint")

	registry.reload_all("user://tir_tests_non_existing_mod_path", base_root)
	assert_eq(registry.items.get_by_id(&"flint").display_name, "Base Flint")
	registry.free()
