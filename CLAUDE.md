# CLAUDE.md – Tír

## Tech Stack
- Godot 4.6.1 (custom build with godot_voxel module) · GDScript only, never C#
- Terrain: godot_voxel (Transvoxel, built into custom Godot build)
- OS: Fedora Linux – paths are case-sensitive
- GPU: AMD Radeon RX 7800 XT (Vulkan Forward+)

## Folder Structure
```
src/
  player/     player.gd, player.tscn, first_person_controller.gd,
              axe_controller.gd, crafting_system.gd, inventory.gd
  systems/    audio_manager.gd, day_night_cycle.gd, warmth_system.gd
  world/      tree_placer.gd, biome_decorator.gd, weather.gd
  entities/   campfire.gd
  ui/         hud.gd
  debug/      debug_console.gd
data/         ItemDefinition resources (.tres)
scenes/       Packed scenes (tree.tscn etc.)
assets/
  shaders/    terrain.gdshader, grass.gdshader
  audio/
  models/
  textures/
```

## Hard Rules

**GDScript only.** No C#, ever.

**Case-sensitive paths.** `res://world/` ≠ `res://World/`

**@onready for node references:**
```gdscript
@onready var _camera: Camera3D = $Camera3D
```

**@export for inspector parameters:**
```gdscript
@export var grass_density: float = 0.5
```

**Autoloads must be registered** in Project Settings → Autoload.
AudioManager and other singletons are accessed as global names, not via `get_node()`.

**GlobalClass resources require full Godot restart** to appear in resource picker.

**No RigidBody through voxel terrain** – chunk collider timing unreliable.
Use raycasts (`PhysicsRayQueryParameters3D`) for ground detection.

**Separate AudioStreamPlayer instance per sound** – reusing interrupts playback.

**world.tscn inspector values override GDScript field defaults** – tune via .tscn, not code defaults.

**Trees must be in group `"tree"`** for grass clearing around bases to work.

## Naming Conventions
| Type | Convention | Example |
|---|---|---|
| Classes / Nodes | PascalCase | `BiomeDecorator` |
| Functions | snake_case | `generate_grass()` |
| Variables / Export params | snake_case | `grass_density` |
| Private (convention) | `_snake_case` | `_grass_instance` |
| Constants | SCREAMING_SNAKE | `MAX_TREES` |
| Shader parameters | snake_case | `wind_strength` |
| Node groups | lowercase | `"tree"`, `"player"` |

## Design Constraints
- **Darkness is a mechanic** – never add ambient light at night for visibility
- **Fire is the only night light source** – respect this when adding any light
- **No UI menus** – crafting is context-driven via `[E]` prompts only
- **No numeric values shown to player** – visual/audio feedback only
- **Diegetic audio only** – all sounds from world positions, never UI layer
- **Silence = warning signal** – Otherworld transition removes sounds, never adds them
