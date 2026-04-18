extends StaticBody2D

var _item: String = ""
var _temp: float = 1.0

const HEAT_RATE := 1.0 / 12.0

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
		_temp = minf(1.0, _temp + delta * HEAT_RATE)
		_update_sprite()

func _can_combine_with_player(player: CharacterBody2D) -> bool:
	return (_item == "bun" and player.has_item("food_cooked")) or \
		   (_item == "food_cooked" and player.has_item("bun"))

func can_interact(player: CharacterBody2D) -> bool:
	if _can_combine_with_player(player):
		return true
	if _item != "":
		return not player.inventory_full()
	return player.has_item("food_cooked") or player.has_item("burger") or player.has_item("bun")

func on_player_interact(player: CharacterBody2D) -> void:
	if _item == "bun" and player.has_item("food_cooked"):
		player.take_item("food_cooked")
		_item = "burger"
		_temp = player.last_taken_temp
		_update_sprite()
		return
	if _item == "food_cooked" and player.has_item("bun"):
		player.take_item("bun")
		_item = "burger"
		_update_sprite()
		return
	if _item != "":
		player.pick_up(_item, _temp)
		_item = ""
		_temp = 1.0
		_sprite.visible = false
	elif player.has_item("food_cooked"):
		player.take_item("food_cooked")
		_item = "food_cooked"
		_temp = player.last_taken_temp
		_update_sprite()
	elif player.has_item("burger"):
		player.take_item("burger")
		_item = "burger"
		_temp = player.last_taken_temp
		_update_sprite()
	elif player.has_item("bun"):
		player.take_item("bun")
		_item = "bun"
		_temp = 1.0
		_update_sprite()

func _update_sprite() -> void:
	_sprite.texture = _textures.get(_item, null)
	_sprite.visible = _item != ""
	_sprite.scale = Vector2(1.05, 1.05) if _item == "burger" else Vector2(0.7, 0.7)
	if _item in ["food_cooked", "burger"]:
		_sprite.modulate = _temp_color(_temp)
	else:
		_sprite.modulate = Color.WHITE

func _temp_color(t: float) -> Color:
	if t < 0.5:
		return Color(0.2, 0.4, 1.0).lerp(Color(1.0, 1.0, 0.0), t * 2.0)
	return Color(1.0, 1.0, 0.0).lerp(Color(1.0, 0.5, 0.0), (t - 0.5) * 2.0)
