extends StaticBody2D

var _item: String = ""
var _temp: float = 1.0

const COOL_RATE := 1.0 / 6.0

@onready var _sprite: Sprite2D = $ItemSprite

var _textures: Dictionary = {}

func _ready() -> void:
	_textures = {
		"food_cooked": load("res://assets/food_cooked.svg"),
		"burger": load("res://assets/burger.svg"),
		"bun": load("res://assets/bun.svg"),
	}
	_sprite.visible = false

func _process(delta: float) -> void:
	if _item in ["food_cooked", "burger"]:
		_temp = maxf(0.0, _temp - delta * COOL_RATE)
		_update_sprite()

func _find_combine_item(player: CharacterBody2D) -> String:
	var active: String = player.get_active_item()
	if _can_combine(_item, active):
		return active
	for i in player.INVENTORY_SIZE:
		if _can_combine(_item, player.inventory[i]):
			return player.inventory[i]
	return ""

func can_interact(player: CharacterBody2D) -> bool:
	var active: String = player.get_active_item()
	if _item != "" and _find_combine_item(player) != "":
		return true
	if _item != "":
		return not player.inventory_full()
	return active in ["food_cooked", "bun", "burger"]

func on_player_interact(player: CharacterBody2D) -> void:
	var active: String = player.get_active_item()
	if _item != "":
		var combine: String = _find_combine_item(player)
		if combine != "":
			player.take_item(combine)
			if _item == "bun":
				_temp = player.last_taken_temp
			_item = "burger"
			_update_sprite()
		elif not player.inventory_full():
			player.pick_up(_item, _temp)
			_item = ""
			_temp = 1.0
			_sprite.visible = false
	else:
		if active in ["food_cooked", "bun", "burger"]:
			player.take_item(active)
			_item = active
			_temp = player.last_taken_temp
			_update_sprite()

func _can_combine(a: String, b: String) -> bool:
	return (a == "bun" and b == "food_cooked") or (a == "food_cooked" and b == "bun")

func _update_sprite() -> void:
	_sprite.texture = _textures.get(_item, null)
	_sprite.visible = _item != ""
	if _item in ["food_cooked", "burger"]:
		_sprite.modulate = _temp_color(_temp)
	else:
		_sprite.modulate = Color.WHITE

func _temp_color(t: float) -> Color:
	if t < 0.5:
		return Color(0.2, 0.4, 1.0).lerp(Color(1.0, 1.0, 0.0), t * 2.0)
	return Color(1.0, 1.0, 0.0).lerp(Color(1.0, 0.5, 0.0), (t - 0.5) * 2.0)
