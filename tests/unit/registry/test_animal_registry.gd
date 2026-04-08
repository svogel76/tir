extends "res://addons/gut/test.gd"


func _make_temp_dir(prefix: String) -> String:
	var root := "user://tir_tests_%s_%s" % [prefix, Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(root.path_join("animals"))
	return root


func _save_animal(path: String, id_value: StringName, display_name: String) -> void:
	var animal := TirAnimalDefinition.new()
	animal.id = id_value
	animal.display_name = display_name
	animal.behavior = TirAnimalDefinition.BehaviorType.PASSIVE
	animal.is_predator = false
	animal.is_passive = true
	var result := ResourceSaver.save(animal, path)
	assert_eq(result, OK)


func test_animal_registry_basic_lookup() -> void:
	var root := _make_temp_dir("animal_registry_basic")
	_save_animal(root.path_join("animals/deer.tres"), &"deer", "Hirsch")
	_save_animal(root.path_join("animals/boar.tres"), &"boar", "Wildschwein")

	var registry := TirAnimalRegistry.new()
	registry.configure(root.path_join("animals"))
	registry.reload()

	assert_true(registry.has_id(&"deer"))
	assert_false(registry.has_id(&"wolf"))
	assert_eq(registry.get_all().size(), 2)
	assert_eq(registry.get_by_id(&"boar").display_name, "Wildschwein")
