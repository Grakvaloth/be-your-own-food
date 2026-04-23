# new-character

Creates a new character (CharacterBody2D) scene and script with the standard animation pattern used in this project (4-directional idle/walk, facing tracking).

Run `/spriteframes` first to generate the `*_frames.tres` before using this skill.

## Usage

```
/new-character <name> [type]
```

**Arguments:**
- `name` — PascalCase name, e.g. `Chef`, `VipGuest`, `Bouncer`
- `type` — (optional):
  - `npc` — moving NPC with state machine, HP, idle/walk animations (default)
  - `enemy` — like npc but with attack behaviour placeholder
  - `player` — full player boilerplate with inventory, input, attack

**Example:**
```
/new-character VipGuest npc
```

---

## What this skill does

### 1. Create `scenes/<Name>.tscn`

```
<Name> (CharacterBody2D)
  collision_layer = 4
  collision_mask = 2
  script = res://scripts/<snake_name>.gd
  ├── AnimatedSprite2D
  │     scale = Vector2(2, 2)
  │     sprite_frames = res://assets/<snake_name>/<snake_name>_frames.tres
  │     animation = "idle_south"
  │     autoplay = "idle_south"
  ├── CollisionShape2D (CircleShape2D, radius = 56.0)
  └── NavAgent (NavigationAgent2D, avoidance_enabled = false)
```

### 2. Create `scripts/<snake_name>.gd`

**type = npc:**

Use the `_handle_<state>(delta)` dispatch pattern from `scripts/guest.gd` — one handler per state, `_physics_process` only dispatches. Avoids the monolithic `match`-statement anti-pattern.

```gdscript
extends CharacterBody2D

const SPEED := 120.0

enum State { IDLE, WALKING, DEAD }

var state := State.IDLE
var hp: int = 1
var _walk_target := Vector2.ZERO
var _facing := "south"

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
    match state:
        State.WALKING:
            _handle_walking(delta)
        State.IDLE:
            _handle_idle(delta)
        State.DEAD:
            _handle_dead(delta)

func _handle_idle(_delta: float) -> void:
    velocity = Vector2.ZERO
    move_and_slide()
    _update_animation(false)

func _handle_walking(_delta: float) -> void:
    _step_toward(_walk_target)

func _handle_dead(_delta: float) -> void:
    velocity = Vector2.ZERO
    move_and_slide()

func _update_animation(moving: bool) -> void:
    if state == State.DEAD:
        return
    _anim.play(("walk_" if moving else "idle_") + _facing)

func take_damage(amount: int) -> void:
    if state == State.DEAD:
        return
    hp -= amount
    if hp <= 0:
        _die()

func _die() -> void:
    _anim.play("idle_" + _facing)
    _anim.rotation = PI / 2.0
    _anim.modulate = Color(0.4, 0.4, 0.4)
    state = State.DEAD
    # Optional: EventBus.guest_died.emit(self) — falls andere Systeme reagieren sollen

func walk_to(pos: Vector2) -> void:
    _walk_target = pos
    state = State.WALKING

func _step_toward(pos: Vector2) -> void:
    var dir := (pos - global_position).normalized()
    if abs(dir.x) >= abs(dir.y):
        _facing = "east" if dir.x > 0 else "west"
    else:
        _facing = "south" if dir.y > 0 else "north"
    if global_position.distance_to(pos) < 16.0:
        velocity = Vector2.ZERO
        move_and_slide()
        _update_animation(false)
        state = State.IDLE
        return
    velocity = dir * SPEED
    move_and_slide()
    _update_animation(true)
```

**type = enemy** — same as npc but with additional attack placeholder:
```gdscript
# add to npc base:
const ATTACK_RANGE := 80.0
var _attack_cooldown := 0.0

func _physics_process(delta: float) -> void:
    if _attack_cooldown > 0:
        _attack_cooldown -= delta
    # ... rest of npc logic

func _try_attack(target: Node2D) -> void:
    if _attack_cooldown > 0:
        return
    if global_position.distance_to(target.global_position) <= ATTACK_RANGE:
        if target.has_method("take_damage"):
            target.take_damage(1)
        _attack_cooldown = 1.5
```

**type = player** — refer to existing `scripts/player.gd` as the template; copy and rename.

### 3. Report

After creation, remind the user to:
- Verify the `.tres` path in the `.tscn` matches the output of `/spriteframes`
- Add required animations to the SpriteFrames if the character needs attack or special states
- Instantiate the scene in `scenes/Main.tscn` or spawn via script
- Set HP, speed, and state machine states to match the character's role

---

## Collision layer conventions

| Layer | Bedeutung |
|-------|-----------|
| 1 | Spieler |
| 2 | Interagierbare Objekte |
| 4 | Wände + Gäste/NPCs/Feinde ← dieser Typ |

`collision_mask = 2` means the character collides with interactable objects (counters, walls at layer 4 are separate — add mask 4 if the character should be blocked by walls).

---

## Animation naming convention

All characters in this project use the same animation names:

| Name | Frames | Loop | FPS | Source |
|------|--------|------|-----|--------|
| `idle_south/north/east/west` | 1 | yes | 1 | `rotations/` |
| `walk_south/north/east/west` | 4–6 | yes | 8 | `animations/<hash>/` |
| `attack_south/north/east/west` | 5 | no | 10 | `animations/<hash>/` (if available) |

Use `/spriteframes` to generate the `.tres` — it follows this convention automatically.

---

## Notes

- Scale `Vector2(2, 2)` on AnimatedSprite2D matches the visual size of Player and Guest (both 92×92 px × 2)
- `collision_mask = 2` alone means the NPC walks through walls — add `4` to the mask if it should be blocked by walls
- Dead state: rotate sprite 270° (`_anim.rotation = PI * 1.5`) + grey modulate — no separate death asset needed (liegt auf dem Rücken)
- `_facing` must always be updated in `_step_toward()` before `move_and_slide()` so the last direction is preserved when the character stops
- **Per-state handler pattern**: reference `scripts/guest.gd` (`_handle_waiting`, `_handle_eating`, `_handle_dining`, `_handle_dead`) as the canonical template for anything more complex than 3 states
- **EventBus**: for broadcast events (spawn, death, served, etc.) use `EventBus.<signal>.emit(...)` instead of `get_parent()` calls — signals defined in `scripts/event_bus.gd` (autoload `EventBus`)
- **Deferred state changes**: when a state transition could happen mid-frame alongside player interaction, use `call_deferred("_<method>")` + a guard at the top (`if state in [...]: return`) — see `guest.gd:_leave_early` for the pattern that fixed the serve-at-timeout race
