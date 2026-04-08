extends Resource
class_name TirItemDefinition

enum ItemCategory {
	GENERIC,
	RESOURCE,
	CONSUMABLE,
	TOOL,
	WEAPON,
	ARMOR,
	CLOTHING,
	MATERIAL,
	QUEST
}

enum ToolType {
	NONE,
	AXE,
	PICKAXE,
	HAMMER,
	KNIFE,
	SHOVEL,
	SICKLE,
	FISHING_ROD,
	FIRESTARTER
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export var category: ItemCategory = ItemCategory.GENERIC
@export var tool_type: ToolType = ToolType.NONE

@export var stackable: bool = true
@export_range(1, 999, 1) var max_stack_size: int = 1
@export_range(0.0, 999.0, 0.01, "suffix:kg") var weight_kg: float = 0.0

@export_range(0.0, 10000.0, 0.1) var durability_max: float = 0.0
@export_range(0.0, 1000.0, 0.01) var durability_loss_per_use: float = 0.0

@export var is_flammable: bool = false
@export_range(0.0, 72000.0, 1.0, "suffix:s") var fuel_burn_seconds: float = 0.0

@export_range(-100.0, 100.0, 0.1) var food_value: float = 0.0
@export_range(-100.0, 100.0, 0.1) var hydration_value: float = 0.0
@export_range(-100.0, 100.0, 0.1) var warmth_value: float = 0.0

@export var tags: PackedStringArray = PackedStringArray()
