# new-interactable

Creates a new interactable object for the Be Your Own Food project — a `StaticBody2D` scene that extends the project's `Interactable` base class (`scripts/interactable.gd`).

## Usage

```
/new-interactable <name> [type]
```

**Arguments:**
- `name` — PascalCase name, e.g. `CookingPot`, `ServingHatch`
- `type` — (optional) interaction type:
  - `interact` — single action (E key), overrides `can_interact` / `on_player_interact` (default)
  - `both` — E + Q, overrides `can_interact` + `can_interact_alt`
  - `open` — opens a menu (F key), overrides `can_open` / `on_player_open`
  - `surface` — heat or cool surface for items (extends `TempSurface`, see below)

**Example:**
```
/new-interactable CookingPot interact
```

---

## What this skill does

1. Create `scenes/<Name>.tscn` with this node structure:
```
<Name> (StaticBody2D)
  collision_layer = 2
  collision_mask = 0
  script = res://scripts/<snake_name>.gd
  ├── Sprite2D  (placeholder, texture = first matching SVG in assets/ or leave empty)
  └── CollisionShape2D (RectangleShape2D, size 64×64)
```

2. Create `scripts/<snake_name>.gd` with the appropriate pattern. All interactables extend `Interactable` (which itself extends `StaticBody2D`) — this gives default no-op implementations for every virtual method, so the subclass only overrides what it needs.

**type = interact:**
```gdscript
extends Interactable

func can_interact(player: CharacterBody2D) -> bool:
    return true  # TODO: add condition

func on_player_interact(player: CharacterBody2D) -> void:
    pass  # TODO: implement
```

**type = both:**
```gdscript
extends Interactable

func can_interact(player: CharacterBody2D) -> bool:
    return true  # TODO: add condition

func on_player_interact(player: CharacterBody2D) -> void:
    pass  # TODO: implement

func can_interact_alt(player: CharacterBody2D) -> bool:
    return true  # TODO: add condition

func on_player_interact_alt(player: CharacterBody2D) -> void:
    pass  # TODO: implement
```

**type = open:**
```gdscript
extends Interactable

var _open := false
var _player: CharacterBody2D = null

func _ready() -> void:
    $ComputerMenu.item_selected.connect(_on_menu_item_selected)

func can_open(_player: CharacterBody2D) -> bool:
    return true

func on_player_open(player: CharacterBody2D) -> void:
    _player = player
    if _open:
        _close_menu()
    else:
        _open_menu()

func _open_menu() -> void:
    _open = true
    if _player:
        _player.input_blocked = true
    var items: Array = [
        {"label": "Option 1", "cost": 0, "available": true},
    ]
    $ComputerMenu.open([items], ["Register 1"])

func _close_menu() -> void:
    _open = false
    $ComputerMenu.close()
    if _player:
        _player.input_blocked = false
        _player = null

func _process(_delta: float) -> void:
    if not _open:
        return
    for action in ["menu_left", "menu_right", "menu_up", "menu_down"]:
        if Input.is_action_just_pressed(action):
            $ComputerMenu.handle_input(action)
    if Input.is_action_just_pressed("interact"):
        $ComputerMenu.handle_input("menu_confirm")
    if Input.is_action_just_pressed("open_fridge") and _player != null:
        _close_menu()

func _on_menu_item_selected(tab: int, index: int) -> void:
    pass  # TODO: implement
```

For `type = open`, also add a ComputerMenu child node to the .tscn:
```
[node name="ComputerMenu" parent="." instance=ExtResource("...ComputerMenu.tscn")]
```

**type = surface** — heat or cool surface, extends `TempSurface` (not `Interactable` directly):
```gdscript
extends TempSurface

func _ready() -> void:
    heat = true   # true = Wärmeplatte (heizt), false = Arbeitsfläche (kühlt)
    super()
```

`TempSurface` already implements the full cook-chain logic (item placement, bun+food_cooked → burger, temperature progression via `Items.SURFACE_COOL_RATES` / `Items.SURFACE_HEAT_RATE`). Scene needs an `ItemSprite` (Sprite2D) child.

3. Report the created files and remind the user to:
   - Add the scene to `scenes/Main.tscn` at the correct position
   - Add an ext_resource entry and instantiate the node in Main.tscn
   - Implement the TODO sections in the script
   - Use `Items.FOOD_RAW` / `Items.BUN` etc. from `scripts/items.gd` — **never** magic strings like `"food_raw"`
   - Emit from `EventBus` for cross-system events (e.g. `EventBus.item_picked_up.emit(...)`) instead of reaching into `main.gd` via `get_parent()`

---

## Collision layer conventions

| Layer | Bedeutung |
|-------|-----------|
| 1 | Spieler |
| 2 | Interagierbare Objekte ← dieser Typ |
| 4 | Wände + Gäste |

Player `InteractArea` has `collision_mask = 6` — it detects layer 2 objects automatically.

---

## Notes

- `snake_name` = PascalCase → snake_case conversion of `name` argument
- The interaction is detected by `player.gd` via `$InteractArea.get_overlapping_bodies()` — no extra setup needed as long as `collision_layer = 2`
- For `open`-type objects: always set `player.input_blocked = true` on open and `false` on close — otherwise the player can move while the menu is open
- Never use the same input action as a close-trigger in both `player._physics_process` AND the object's `_process` — causes same-frame open/close conflict
- When picking up items, use `Player.take_item(name)` which returns `{"name": String, "temp": float}` — no `last_taken_temp` instance variable exists anymore
