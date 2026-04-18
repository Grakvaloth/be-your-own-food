extends StaticBody2D

@onready var _food_sprite: Sprite2D = $FoodSprite
@onready var _raw_tex: Texture2D = preload("res://assets/food_raw.svg")
@onready var _cooked_tex: Texture2D = preload("res://assets/food_cooked.svg")

var _item := ""
var _cook_time := 0.0

func _process(delta: float) -> void:
	if _item == "" or _item == "food_burnt":
		return
	_cook_time += delta
	if _cook_time >= 15.0:
		if _item != "food_burnt":
			_item = "food_burnt"
			_food_sprite.texture = _cooked_tex
			_food_sprite.modulate = Color(0.15, 0.15, 0.15)
	elif _cook_time >= 10.0:
		if _item != "food_cooked":
			_item = "food_cooked"
			_food_sprite.texture = _cooked_tex
			_food_sprite.modulate = Color.WHITE
	elif _cook_time >= 5.0:
		_food_sprite.modulate = Color.YELLOW

func on_player_interact(player: CharacterBody2D) -> void:
	if _item == "" and player.has_item("food_raw"):
		player.take_item("food_raw")
		_item = "food_raw"
		_cook_time = 0.0
		_food_sprite.texture = _raw_tex
		_food_sprite.modulate = Color.WHITE
		_food_sprite.visible = true
	elif _item in ["food_cooked", "food_burnt"]:
		if player.pick_up(_item):
			_item = ""
			_cook_time = 0.0
			_food_sprite.visible = false
