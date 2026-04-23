class_name Items
extends RefCounted

# Zentrale Item-Konstanten — ersetzt verstreute Magic Strings.
const NONE := ""
const FOOD_RAW := "food_raw"
const FOOD_COOKED := "food_cooked"
const FOOD_BURNT := "food_burnt"
const BUN := "bun"
const BURGER := "burger"
const DEAD_GUEST := "dead_guest"
const PLATE := "plate"

# Kühlraten pro Sekunde im Spieler-Inventar (delta * rate).
const INVENTORY_COOL_RATES := {
	FOOD_COOKED: 1.0 / 6.0,
	BURGER: 1.0 / 9.0,
	DEAD_GUEST: 1.0 / 300.0,
}

# Kühlrate auf der Arbeitsfläche (counter.gd). burger kühlt langsamer.
const SURFACE_COOL_RATES := {
	FOOD_COOKED: 1.0 / 6.0,
	BURGER: 1.0 / 9.0,
}

# Heizrate auf der Wärmeplatte (warming_plate.gd). Einheitlich.
const SURFACE_HEAT_RATE := 1.0 / 12.0

# Items, die ein Temperatur-Farbspiel im Sprite erhalten.
const TEMP_SENSITIVE := [FOOD_COOKED, BURGER]

# Kann mit der "offenen" Hand übergeben werden (Drag-Target auf Surfaces).
const SURFACE_STORABLE := [FOOD_COOKED, BURGER, BUN]

static func get_texture(item: String) -> Texture2D:
	match item:
		FOOD_RAW: return load("res://assets/food_raw.svg")
		FOOD_COOKED, FOOD_BURNT: return load("res://assets/food_cooked.svg")
		BUN: return load("res://assets/bun.svg")
		BURGER: return load("res://assets/burger.svg")
		DEAD_GUEST: return load("res://assets/guest.svg")
	return null

static func is_temp_sensitive(item: String) -> bool:
	return item in TEMP_SENSITIVE

static func temp_color(t: float) -> Color:
	if t < 0.5:
		return Color(0.2, 0.4, 1.0).lerp(Color(1.0, 1.0, 0.0), t * 2.0)
	return Color(1.0, 1.0, 0.0).lerp(Color(1.0, 0.5, 0.0), (t - 0.5) * 2.0)

static func freshness_color(t: float) -> Color:
	if t > 0.0:
		return Color(0.5, 0.5, 0.5)
	return Color(0.5, 0.25, 0.0)

static func can_combine(a: String, b: String) -> bool:
	return (a == BUN and b == FOOD_COOKED) or (a == FOOD_COOKED and b == BUN)
