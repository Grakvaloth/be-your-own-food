---
name: godot-lint
description: Project-specific conventions check for Be Your Own Food (Godot 4.6). TRIGGER automatically after editing or creating any .gd file in scripts/ — review the diff for magic item strings, wrong Interactable base class, get_parent() coupling bypassing the EventBus, direct mutation of encapsulated state, $-shorthand on typed variables, and legacy API remnants. SKIP when editing scripts/items.gd, scripts/event_bus.gd, or scripts/interactable.gd themselves (these define the conventions).
---

# godot-lint

Auto-review GDScript edits against project conventions established during the P1–P4 refactor. Report findings as a short bulleted list. Stay out of the way if the edit is clean — **only speak up when there is something real**.

## When to run

After any `Edit`/`Write`/`MultiEdit` to a `.gd` file under `scripts/` (except the three convention-defining files listed above). Run once per user turn — don't re-lint the same file within a turn.

## What to check

### 1. Magic item strings
The canonical item identifiers live in `scripts/items.gd` as constants: `Items.FOOD_RAW`, `Items.FOOD_COOKED`, `Items.FOOD_BURNT`, `Items.BUN`, `Items.BURGER`, `Items.DEAD_GUEST`, `Items.PLATE`, `Items.NONE`.

Flag any of these string literals appearing in a .gd file:
- `"food_raw"`, `"food_cooked"`, `"food_burnt"`, `"bun"`, `"burger"`, `"dead_guest"`, `"plate"`

**Exception:** comparisons against `""` (empty slot) are fine — that's `Items.NONE` territory but the empty-string check is idiomatic.

### 2. Interactable base class
If a new or edited script defines `can_interact`, `on_player_interact`, `can_interact_alt`, `on_player_interact_alt`, `can_open`, or `on_player_open`, its `extends` clause should be `Interactable` (or `TempSurface` for heat/cool surfaces) — **not** `StaticBody2D` directly.

Virtual defaults come from `scripts/interactable.gd`, so the subclass only implements what it needs. `extends StaticBody2D` + these methods = missed abstraction.

### 3. get_parent() coupling
Flag direct `get_parent().<field>` access for state that has a proper API:
- `get_parent().score` / `main.score -= X` → use `main.buy_buns()` or `EventBus.score_changed`
- `$Fridge.meat_count` / `fridge.meat_count += X` → `fridge.add_meat(n)` / `fridge.add_buns(n)`
- `$Fridge._update_labels()` — `_update_labels` no longer exists; `add_meat`/`add_buns` refresh internally

Calling a method on `get_parent()` is fine when it's an intentional public API (e.g. `get_parent().return_seat(seat)` in guest.gd).

### 4. EventBus vs. tight coupling
For cross-system events, `EventBus.<signal>.emit(...)` is preferred over reaching through parents. Relevant signals: `score_changed`, `guest_served`, `guest_left_early`, `guest_died`, `upgrade_purchased`, `item_picked_up`.

Flag new code that would naturally broadcast (e.g. a new purchase, a new guest state) but doesn't.

### 5. Legacy API remnants
- `last_taken_temp` — removed. `Player.take_item(name)` now returns `{"name": String, "temp": float}`. Usage pattern:
  ```gdscript
  var taken: Dictionary = player.take_item(Items.FOOD_COOKED)
  _temp = taken.temp
  ```
- `_update_labels()` on fridge — removed, see check #3.

### 6. $-shorthand on typed variables
`$ChildName` only works reliably on `self`. On a typed `Node` variable (e.g. `var n: Node2D = ...; n.$Child`), it silently returns `null` or parses oddly. Use `n.get_node("Child")` instead.

This is a known past pain point in the project — see the memory file `feedback_gdscript_pitfalls.md`.

### 7. Theme override assignment
`node.theme_override_font_sizes["font_size"] = n` on newly created nodes silently fails. Use `node.add_theme_font_size_override("font_size", n)`.

## Reporting format

If everything is clean, say nothing — the lint is silent on pass. Otherwise emit a single short block:

```
godot-lint: <filename>
- <line or hunk>: <issue> → <fix>
- …
```

Keep entries to one line each. Don't quote the whole hunk — point to the line and state the fix. Do not re-edit the file automatically unless the user asks; surface the findings and let them decide.

## Examples

**Clean edit** — no output.

**Magic string:**
```
godot-lint: scripts/new_dispenser.gd
- line 14: "food_raw" literal → Items.FOOD_RAW
- line 22: player.pick_up("bun", 1.0) → player.pick_up(Items.BUN, 1.0)
```

**Wrong base class:**
```
godot-lint: scripts/sink.gd
- line 1: `extends StaticBody2D` with can_interact/on_player_interact → should be `extends Interactable`
```

**get_parent() coupling:**
```
godot-lint: scripts/tip_jar.gd
- line 18: get_parent().score += 5 → EventBus.score_changed.emit(5) or main public API
```
