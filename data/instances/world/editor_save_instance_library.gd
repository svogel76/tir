@tool
extends EditorScript

const INSTANCE_LIBRARY_PATH: String = "res://data/instances/world/instance_library.tres"

## Im Editor: Script → Datei ausführen — schreibt instance_library.tres (optionaler Export; sonst baut VoxelFoliageInstancer zur Laufzeit).
func _run() -> void:
	var lib: Resource = WorldFoliageInstanceLibrary.build()
	if lib == null:
		push_error("Konnte VoxelInstanceLibrary nicht erzeugen.")
		return
	var err: Error = ResourceSaver.save(lib, INSTANCE_LIBRARY_PATH)
	if err != OK:
		push_error("Speichern fehlgeschlagen: %s (Fehler %d)" % [INSTANCE_LIBRARY_PATH, err])
	else:
		print("OK: ", INSTANCE_LIBRARY_PATH)
