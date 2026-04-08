extends Node

const GUT_LOADER_PATH := "res://addons/gut/gut_loader.gd"
const GUT_RUNNER_SCENE_PATH := "res://addons/gut/gui/GutRunner.tscn"
const GUT_CONFIG_PATH := "res://addons/gut/gut_config.gd"


func _ready() -> void:
	# Ensure GUT classes/singletons are initialized before GutRunner loads.
	var _loader: Script = load(GUT_LOADER_PATH)
	var runner_scene: PackedScene = load(GUT_RUNNER_SCENE_PATH)
	var runner = runner_scene.instantiate()
	add_child(runner)

	var gut_config_script: Script = load(GUT_CONFIG_PATH)
	var config = gut_config_script.new()
	config.options.dirs = PackedStringArray(["res://tests/unit"])
	config.options.include_subdirs = true
	config.options.should_exit = false
	config.options.should_exit_on_success = false
	config.options.junit_xml_file = "user://gut-junit.xml"
	config.options.junit_xml_timestamp = true
	config.options.gut_on_top = false
	config.options.log_level = 1
	print("[TirTests] GUT report target: user://gut-junit.xml")

	runner.set_gut_config(config)
	runner.run_tests(true)
