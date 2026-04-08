extends "res://addons/gut/test.gd"


func _make_temp_dir(prefix: String) -> String:
	var root := "user://tir_tests_%s_%s" % [prefix, Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(root.path_join("items"))
	return root


func _save_item(path: String, id_value: StringName, display_name: String) -> void:
	var item := TirItemDefinition.new()
	item.id = id_value
	item.display_name = display_name
	item.category = TirItemDefinition.ItemCategory.RESOURCE
	var result := ResourceSaver.save(item, path)
	assert_eq(result, OK)


func test_get_by_id_and_has_id_and_get_all() -> void:
	var root := _make_temp_dir("item_registry_basic")
	_save_item(root.path_join("items/flint_a.tres"), &"flint", "Feuerstein A")
	_save_item(root.path_join("items/oak_wood.tres"), &"oak_wood", "Eichenholz")

	var registry := TirItemRegistry.new()
	registry.configure(root.path_join("items"))
	registry.reload()

	assert_true(registry.has_id(&"flint"))
	assert_false(registry.has_id(&"unknown"))
	assert_not_null(registry.get_by_id(&"flint"))
	assert_null(registry.get_by_id(&"unknown"))
	assert_eq(registry.get_by_id(&"flint").display_name, "Feuerstein A")
	assert_eq(registry.get_all().size(), 2)


func test_duplicate_ids_are_detected() -> void:
	var root := _make_temp_dir("item_registry_duplicates")
	_save_item(root.path_join("items/flint_a.tres"), &"flint", "Feuerstein A")
	_save_item(root.path_join("items/flint_b.tres"), &"flint", "Feuerstein B")

	var registry := TirItemRegistry.new()
	registry.configure(root.path_join("items"))
	registry.reload()

	var issues := registry.validate_structure()
	var found_duplicate := false
	for issue in issues:
		if String(issue.get("problem", "")).contains("Doppelte ID"):
			found_duplicate = true
			break

	assert_true(found_duplicate)
