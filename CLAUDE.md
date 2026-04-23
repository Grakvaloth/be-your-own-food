# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Engine & Stack

- **Godot 4.6** with GDScript
- Physics: Jolt Physics
- Renderer: Forward Plus / Direct3D 12 (Windows)
- Viewport: 1920×1080

## Running the Project

```bash
godot --run project.godot
# or open project.godot in the Godot editor and press F5
```

There is no separate build, lint, or test step — Godot handles everything through the editor.

---

## Architecture

```
scenes/Main.tscn          ← Hauptszene (run/main_scene)
├── Player                ← scenes/Player.tscn
├── Fridge                ← inline StaticBody2D mit scripts/fridge.gd
├── Stove1 + StoveSlots   ← scenes/Stove.tscn / scenes/Counter.tscn
├── WarmingPlate1 + Slots ← scenes/WarmingPlate.tscn
├── CashRegister          ← scenes/CashRegister.tscn
├── Trash                 ← scenes/Trash.tscn
├── UpgradeComputer       ← scenes/UpgradeComputer.tscn
├── StorageTable1/2       ← scenes/StorageTable.tscn  (Hinterraum)
├── MeatGrinder1          ← scenes/MeatGrinder.tscn   (Hinterraum)
├── TrashChute1           ← scenes/TrashChute.tscn    (Hinterraum)
├── Table1–3              ← scenes/Table.tscn
├── HUD                   ← CanvasLayer mit ScoreLabel
└── PauseMenu             ← scenes/PauseMenu.tscn
```

**Gäste** werden dynamisch per Script gespawnt (`main.gd → _spawn_guest()`).

---

## Spielmechanik-Überblick

### Spieler (`scripts/player.gd`, `scenes/Player.tscn`)
- WASD-Bewegung, Shift = schneller (SPEED=600, BOOST=1.5×)
- 4 Inventarslots (1–4 / Mausrad), aktiver Slot hervorgehoben
- Animierter Sprite: idle/walk/attack in 4 Richtungen (`assets/chef/chef_frames.tres`, 92×92 px, scale 2×)
- **Angriff**: Leertaste → `attack_[dir]`-Animation, Schaden auf Frames 2–3 via `AttackArea`
- **Interaktion**: E = `on_player_interact`, Q = `on_player_interact_alt`, F = `on_player_open`
- `input_blocked = true` während ein Menü offen ist (Kühlschrank, PC)

### Gäste (`scripts/guest.gd`, `scenes/Guest.tscn`)
- States: `ENTERING → QUEUEING → WAITING → WALKING_TO_TABLE → EATING → DINING → LEAVING`
- HP = 1 (ein Treffer → `DEAD`)
- Animierter Sprite: idle/walk in 4 Richtungen (`assets/guest_sprite/guest_frames.tres`, 92×92 px, scale 2×)
- **Tod**: 90° rotiert (liegend), grau → braun wenn nicht mehr frisch
- **Frischheit**: 300 s Timer, nur im DEAD-State aktiv; Spieler kann aufheben (`dead_guest`-Item)
- **OrderBubble** zeigt Bestellung (Burger), **TimerBar** zeigt Warte-Timer, **FreshnessBar** zeigt Frische

### Koch-Kette
1. Kühlschrank → Fleisch (food_raw) entnehmen
2. Herd → food_raw ablegen → kocht → food_cooked
3. Herd oder Wärmeplatte → bun + food_cooked kombinieren → burger
4. Gast bedienen (E, wenn warm genug: temp ≥ 1/3)

### Kühlschrank (`scripts/fridge.gd`)
- F öffnet Tab-Menü (A/D: Register „Fleisch" / „Brot", E: entnehmen)
- Startet mit 5 Fleisch, 10 Brötchen
- `add_meat(n)` / `add_buns(n)` nutzen statt direkter `meat_count`/`bun_count`-Mutation

### PC / Upgrade-Computer (`scripts/upgrade_computer.gd`, `scenes/UpgradeComputer.tscn`)
- F öffnet Tab-Menü (A/D: „Upgrades" / „Einkauf", W/S: Auswahl, E: kaufen)
- Upgrades: Herd-Slots (500/1000/1500/2000 Münzen), Wärmer-Slots (1000/2000/3000/4000)
- Einkauf: 1 Brötchen = 10 Münzen, 10 Brötchen = 80 Münzen

### Hinterraum (Kühlkammer, nördlich rechts)
- Zugang über Tür in Nordwand bei x=1150–1350
- **StorageTable**: lagert toten Gast, Frischheits-Timer läuft weiter
- **MeatGrinder**: frischen toten Gast einlegen → 60 s → +5 Fleisch im Kühlschrank
- **TrashChute**: toten Gast (frisch oder verfault) entsorgen

### Menüsystem (`scripts/computer_menu.gd`, `scenes/ComputerMenu.tscn`)
- Wiederverwendbar für PC und Kühlschrank
- `open(items_by_tab, tab_names)` öffnet Panel; `item_selected`-Signal bei Bestätigung
- A/D-Hinweis steht oben im Panel

### Pause (`scripts/pause_menu.gd`, `scenes/PauseMenu.tscn`)
- Escape öffnet/schließt Pausemenü (`process_mode = ALWAYS`)
- Buttons: **Weiter** (setzt fort), **Hauptmenü** (noch ohne Funktion)

---

## Kollisionsebenen

| Layer | Bedeutung |
|-------|-----------|
| 1 | Spieler |
| 2 | Interagierbare Objekte (Herd, Kühlschrank, etc.) |
| 4 | Wände + lebende Gäste |
| 8 | Leichen (tote Gäste, nicht-blockierend) |

Player `collision_mask = 6` (Wände + Interaktables — Leichen blocken nicht).  
Player `InteractArea.collision_mask = 14` (zusätzlich Leichen, damit aufhebbar).  
AttackArea `collision_mask = 4` (trifft nur lebende Gäste — Leichen auf Layer 8 werden nicht erneut angegriffen).

---

## Input Actions (`project.godot`)

| Action | Taste |
|--------|-------|
| move_up/down/left/right | W/S/A/D + Pfeiltasten |
| attack | Leertaste |
| interact | E |
| interact_alt | Q |
| open_fridge | F |
| slot_1–4 | 1–4 |
| scroll_up/down | Mausrad |
| menu_up/down/left/right | W/S/A/D |
| ui_cancel | Escape (Godot-Standard) |

---

## Asset-Quellen

| Asset | Pfad | Format |
|-------|------|--------|
| Spieler-Sprite | `assets/chef/` | 92×92 px PNG, 4 Richtungen |
| Gast-Sprite | `assets/guest_sprite/` | 92×92 px PNG, 4 Richtungen |
| SpriteFrames (Chef) | `assets/chef/chef_frames.tres` | idle/walk/attack × 4 Richtungen |
| SpriteFrames (Gast) | `assets/guest_sprite/guest_frames.tres` | idle/walk × 4 Richtungen |

---

## Wichtige Konventionen

- `$`-Kurzform nur auf `self` — auf getypten `Node`-Variablen stattdessen `get_node()` oder Hilfsmethoden
- Rückgabewerte aus generischen `Node`-Methoden explizit tipen: `var x: int = node.get_value()`
- `add_theme_font_size_override("font_size", n)` statt `theme_override_font_sizes["font_size"] = n` auf neu erstellten Nodes
- Wände/Böden: `collision_layer=4, collision_mask=0`
- Interagierbare Objekte: `collision_layer=2`
- `.godot/` nie manuell bearbeiten

### Kern-Abstraktionen
- `scripts/items.gd` (`class_name Items`): Zentrale Item-Konstanten (`Items.FOOD_RAW` etc.), Kühl-/Heizraten, `Items.temp_color()`, `Items.get_texture()`. Keine Magic Strings im Code.
- `scripts/interactable.gd` (`class_name Interactable extends StaticBody2D`): Basisklasse für alle Interactables. Virtuelle `can_interact`/`on_player_interact`/`can_interact_alt`/`can_open`/`on_player_open`.
- `scripts/temp_surface.gd` (`class_name TempSurface extends Interactable`): Gemeinsame Basis für Counter (heat=false) und Wärmeplatte (heat=true).
- `scripts/event_bus.gd` (Autoload `EventBus`): Signals `score_changed`, `guest_served`, `guest_left_early`, `guest_died`, `upgrade_purchased`, `item_picked_up`.
- `Player.take_item(name) -> Dictionary` liefert `{name, temp}`. Kein `last_taken_temp` mehr.

---

## TODO

### Features
- [ ] **Sound**: Kein Audio implementiert — AudioManager-Autoload + erste Effekte (Kochen, Angriff, Gast-Events, Kasse)
- [ ] **Spielende / Score-Screen**: Kein Game-Over oder Highscore
- [ ] **Speichern**: Kein Savegame-System (`ResourceSaver` oder JSON)
- [ ] **Hauptmenü**: `_on_main_menu_pressed()` in `pause_menu.gd` — Szene wechseln zu einem Hauptmenü-Screen
- [ ] **Optionen-Menü**: Pausemenü-Button „Optionen" noch ohne Funktion
- [ ] **Verschiedene Gäste**: Unterschiedliche HP, Aussehen, Bestellungen (aktuell immer Burger, HP=1)

### Polishing
- [ ] **Gast-Sitzanimation**: Kein eigenes „Sitzen"-Sprite vorhanden — Idle wird verwendet
- [ ] **Upgrades visuell prüfen**: Freigeschaltete Herde/Wärmer erscheinen korrekt an Slot-Positionen (technisch implementiert in `upgrade_computer.gd`)
- [ ] **InteractArea cachen**: `_update_hint()` iteriert `get_overlapping_bodies()` jeden Frame — besser via `area_entered/exited`-Signals

### Bekannt / korrekt (kein TODO)
- NavPolygon deckt nur Gästebereich ab; Hinterraum hat keinen — Gäste sollen dort nicht hin (korrekt)
- StorageTable-Frischetimer läuft im `_process` weiter (implementiert in `storage_table.gd`)
