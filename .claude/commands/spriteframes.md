# spriteframes

Generates a Godot 4 SpriteFrames `.tres` resource file from a standard sprite pack folder.

## Usage

```
/spriteframes <source_folder> <target_asset_path> [idle_anim_name] [walk_anim_name]
```

**Arguments:**
- `source_folder` — absolute path to the sprite pack (must contain `metadata.json`, `rotations/`, `animations/`)
- `target_asset_path` — destination inside the project, e.g. `assets/my_char` (relative to project root)
- `idle_anim_name` — (optional) animation name for idle, default: `idle`
- `walk_anim_name` — (optional) animation name for walk, default: `walk`

**Example:**
```
/spriteframes F:\KI\BeYouOwnFood\My_new_char assets/new_char
```

---

## What this skill does

1. Read `<source_folder>/metadata.json` to get:
   - sprite size (width/height)
   - available directions (north/south/east/west)
   - animation hash names and frame counts per direction

2. Copy all assets from `source_folder` into `<project_root>/<target_asset_path>/` using `cp -r`

3. Generate `<project_root>/<target_asset_path>/<basename>_frames.tres` where `basename` is the last segment of `target_asset_path`.

4. The `.tres` file follows this exact format (mirror of `assets/chef/chef_frames.tres` and `assets/guest_sprite/guest_frames.tres`):
   - One `[ext_resource]` per PNG texture, numbered from 1
   - Order: rotations south/north/east/west first, then animation frames per direction
   - `[resource]` block with `animations` array
   - idle_south/north/east/west: 1 frame from `rotations/`, loop=true, speed=1.0
   - walk_south/north/east/west (or the named animation): N frames from `animations/<hash>/`, loop=true, speed=8.0
   - If an attack animation exists (5 frames): attack_south/north/east/west, loop=false, speed=10.0
   - `load_steps` = total ext_resource count + 1

5. Report the output path and a summary of animations created.

---

## Godot SpriteFrames .tres format reference

```
[gd_resource type="SpriteFrames" load_steps=N format=3]

[ext_resource type="Texture2D" path="res://assets/char/rotations/south.png" id="1"]
...

[resource]
animations = [{
"frames": [{"duration": 1.0, "texture": ExtResource("1")}],
"loop": true,
"name": &"idle_south",
"speed": 1.0
}, ...]
```

---

## Notes

- Project root is always `F:\KI\BeYouOwnFood\be-your-own-food`
- Godot asset path prefix is always `res://`
- After copying, Godot will auto-generate `.import` files when the project is opened — this is normal
- The `.tres` file must use `&"animation_name"` (StringName syntax) for the `name` field
