extends RefCounted
class_name TirBaseResourceRegistry

var _entries: Dictionary[StringName, Resource] = {}
var _base_path: String = ""
var _override_paths: PackedStringArray = PackedStringArray()


func configure(base_path: String, override_paths: PackedStringArray = PackedStringArray()) -> void:
	_base_path = base_path
	_override_paths = override_paths


func reload() -> void:
	_entries.clear()
	_load_path_recursive(_base_path, false)
	for override_path in _override_paths:
		_load_path_recursive(override_path, true)


func has_id(id: StringName) -> bool:
	return _entries.has(id)


func get_by_id(id: StringName) -> Resource:
	return _entries.get(id, null)


func get_all() -> Array[Resource]:
	var out: Array[Resource] = []
	for resource in _entries.values():
		out.append(resource)
	return out


func get_registry_name() -> String:
	return "BaseRegistry"


func get_expected_resource_class() -> StringName:
	return &"Resource"


func get_expected_script_path() -> String:
	return ""


func validate_structure() -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	var id_counts: Dictionary[StringName, int] = {}
	var search_paths := PackedStringArray([_base_path])
	for override_path in _override_paths:
		search_paths.append(override_path)

	for path in search_paths:
		_scan_validation_path(path, issues, id_counts)

	for id in id_counts.keys():
		if id_counts[id] > 1:
			issues.append({
				"problem": "Doppelte ID gefunden",
				"id": id
			})

	return issues


func _load_path_recursive(path: String, is_override: bool) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue

		var child_path := path.path_join(entry)
		if dir.current_is_dir():
			_load_path_recursive(child_path, is_override)
		elif _is_resource_file(entry):
			_register_from_path(child_path, is_override)

		entry = dir.get_next()
	dir.list_dir_end()


func _register_from_path(path: String, is_override: bool) -> void:
	var resource := ResourceLoader.load(path)
	if resource == null:
		return
	if not resource.has_method("get"):
		return

	var id_value: Variant = resource.get("id")
	if typeof(id_value) != TYPE_STRING_NAME:
		return

	var id := id_value as StringName
	if id == StringName():
		return

	if not is_override and _entries.has(id):
		return

	_entries[id] = resource


func _is_resource_file(file_name: String) -> bool:
	return file_name.ends_with(".tres") or file_name.ends_with(".res")


func _scan_validation_path(path: String, issues: Array[Dictionary], id_counts: Dictionary[StringName, int]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	var expected_class := get_expected_resource_class()
	var expected_script_path := get_expected_script_path()

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue

		var child_path := path.path_join(entry)
		if dir.current_is_dir():
			_scan_validation_path(child_path, issues, id_counts)
		elif _is_resource_file(entry):
			var resource := ResourceLoader.load(child_path)
			if resource == null:
				entry = dir.get_next()
				continue

			var has_valid_type := false
			if expected_script_path != "":
				var script := resource.get_script() as Script
				has_valid_type = script != null and script.resource_path == expected_script_path
			else:
				has_valid_type = resource.is_class(String(expected_class))

			if not has_valid_type:
				issues.append({
					"problem": "Falscher Resource-Typ im Registry-Ordner",
					"id": StringName()
				})
				entry = dir.get_next()
				continue

			var id_value: Variant = resource.get("id")
			if typeof(id_value) != TYPE_STRING_NAME or (id_value as StringName) == StringName():
				issues.append({
					"problem": "Resource ohne gueltige ID",
					"id": StringName()
				})
				entry = dir.get_next()
				continue

			var id := id_value as StringName
			id_counts[id] = id_counts.get(id, 0) + 1

		entry = dir.get_next()
	dir.list_dir_end()
