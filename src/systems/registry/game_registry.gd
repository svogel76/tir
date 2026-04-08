extends Node
class_name TirGameRegistry

const BASE_ROOT := "res://data/instances"
const MOD_ROOT := "res://mods"

var items: TirItemRegistry = TirItemRegistry.new()
var animals: TirAnimalRegistry = TirAnimalRegistry.new()
var plants: TirPlantRegistry = TirPlantRegistry.new()
var biomes: TirBiomeRegistry = TirBiomeRegistry.new()
var seasons: TirSeasonRegistry = TirSeasonRegistry.new()


func _ready() -> void:
	reload_all()
	if OS.is_debug_build():
		validate_all()


func reload_all(mod_root_path: String = MOD_ROOT, base_root_path: String = BASE_ROOT) -> void:
	items.configure(
		base_root_path.path_join("items"),
		_build_override_paths(mod_root_path, "items")
	)
	items.reload()

	animals.configure(
		base_root_path.path_join("animals"),
		_build_override_paths(mod_root_path, "animals")
	)
	animals.reload()

	plants.configure(
		base_root_path.path_join("plants"),
		_build_override_paths(mod_root_path, "plants")
	)
	plants.reload()

	biomes.configure(
		base_root_path.path_join("biomes"),
		_build_override_paths(mod_root_path, "biomes")
	)
	biomes.reload()

	seasons.configure(
		base_root_path.path_join("seasons"),
		_build_override_paths(mod_root_path, "seasons")
	)
	seasons.reload()


func _build_override_paths(mod_root_path: String, concept_folder: String) -> PackedStringArray:
	var out := PackedStringArray()
	out.append(mod_root_path.path_join("instances").path_join(concept_folder))
	out.append(mod_root_path.path_join(concept_folder))
	return out


func validate_all(force: bool = false) -> void:
	if not force and not OS.is_debug_build():
		return

	_validate_registry_structure(items)
	_validate_registry_structure(animals)
	_validate_registry_structure(plants)
	_validate_registry_structure(biomes)
	_validate_registry_structure(seasons)

	_validate_items()
	_validate_animals()
	_validate_plants()
	_validate_seasons()
	_validate_references()


func _validate_registry_structure(registry: TirBaseResourceRegistry) -> void:
	for issue in registry.validate_structure():
		_warn_validation(
			registry.get_registry_name(),
			String(issue.get("problem", "Unbekanntes Problem")),
			issue.get("id", StringName()) as StringName
		)


func _validate_items() -> void:
	for item_resource in items.get_all():
		var item: TirItemDefinition = item_resource as TirItemDefinition
		if item == null:
			continue
		var has_durability: bool = item.durability_max > 0.0
		var is_tool: bool = item.tool_type != TirItemDefinition.ToolType.NONE

		if has_durability and not is_tool:
			_warn_validation(
				"ItemRegistry",
				"Item hat Durability > 0 ohne gueltigen tool_type",
				item.id
			)
		elif is_tool and not has_durability:
			_warn_validation(
				"ItemRegistry",
				"Item hat tool_type gesetzt aber keine Durability",
				item.id
			)


func _validate_animals() -> void:
	for animal_resource in animals.get_all():
		var animal: TirAnimalDefinition = animal_resource as TirAnimalDefinition
		if animal == null:
			continue
		var predator_flag: Variant = animal.get("is_predator")
		var passive_flag: Variant = animal.get("is_passive")
		if typeof(predator_flag) == TYPE_BOOL and typeof(passive_flag) == TYPE_BOOL:
			if predator_flag and passive_flag:
				_warn_validation(
					"AnimalRegistry",
					"Animal ist gleichzeitig predator und passive",
					animal.id
				)


func _validate_plants() -> void:
	for plant_resource in plants.get_all():
		var plant: TirPlantDefinition = plant_resource as TirPlantDefinition
		if plant == null:
			continue
		var has_positive: bool = false
		var has_negative: bool = false
		for effect in plant.effects:
			if effect == null:
				continue
			if effect.magnitude > 0.0:
				has_positive = true
			elif effect.magnitude < 0.0:
				has_negative = true

		if has_positive and has_negative:
			_warn_validation(
				"PlantRegistry",
				"Pflanze hat positive und negative Effekte auf derselben Instanz",
				plant.id
			)


func _validate_seasons() -> void:
	for season_resource in seasons.get_all():
		var season: TirSeasonDefinition = season_resource as TirSeasonDefinition
		if season == null:
			continue
		if season.otherworld_strength < 0.0 or season.otherworld_strength > 1.0:
			_warn_validation(
				"SeasonRegistry",
				"otherworld_strength liegt ausserhalb von 0.0-1.0",
				season.id
			)


func _validate_references() -> void:
	for animal_resource in animals.get_all():
		var animal: TirAnimalDefinition = animal_resource as TirAnimalDefinition
		if animal == null:
			continue
		if animal.otherworld_variant == null:
			continue

		var variant_id: StringName = animal.otherworld_variant.id
		if variant_id == StringName() or not animals.has_id(variant_id):
			_warn_validation(
				"AnimalRegistry",
				"otherworld_variant verweist auf nicht registriertes Animal",
				animal.id
			)

	for biome_resource in biomes.get_all():
		var biome: TirBiomeDefinition = biome_resource as TirBiomeDefinition
		if biome == null:
			continue
		for pop_entry in biome.animal_population:
			if pop_entry == null or pop_entry.animal == null:
				continue
			var animal_id: StringName = pop_entry.animal.id
			if animal_id == StringName() or not animals.has_id(animal_id):
				_warn_validation(
					"BiomeRegistry",
					"Biome verweist auf nicht registriertes Animal",
					biome.id
				)

		for pop_entry in biome.vegetation:
			if pop_entry == null or pop_entry.plant == null:
				continue
			var plant_id: StringName = pop_entry.plant.id
			if plant_id == StringName() or not plants.has_id(plant_id):
				_warn_validation(
					"BiomeRegistry",
					"Biome verweist auf nicht registrierte Plant",
					biome.id
				)


func _warn_validation(registry_name: String, problem: String, id: StringName) -> void:
	var id_text := String(id)
	if id_text.is_empty():
		id_text = "<missing>"
	push_warning('[TirValidation] %s: %s (id: "%s")' % [registry_name, problem, id_text])
