extends Node

@export var ambient_definitions_path: String = "res://data/instances/sounds/ambient"


func _ready() -> void:
	_start_ambient_layer()


func _start_ambient_layer() -> void:
	if not has_node("/root/AudioManager"):
		return
	var audio_manager: Node = get_node("/root/AudioManager")
	var definitions: Array[TirSoundDefinition] = _load_ambient_definitions()
	for definition in definitions:
		audio_manager.call("play_ambient", definition)


func _load_ambient_definitions() -> Array[TirSoundDefinition]:
	var results: Array[TirSoundDefinition] = []
	if not DirAccess.dir_exists_absolute(ambient_definitions_path):
		return results

	var dir: DirAccess = DirAccess.open(ambient_definitions_path)
	if dir == null:
		return results

	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".tres"):
			continue
		var full_path: String = ambient_definitions_path.path_join(file_name)
		var resource: Resource = load(full_path)
		if resource is TirSoundDefinition:
			results.append(resource as TirSoundDefinition)
	dir.list_dir_end()
	return results
