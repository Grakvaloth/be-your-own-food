extends Interactable

const TIME_YELLOW := 5.0
const TIME_COOKED := 10.0
const TIME_BURNT := 15.0
const COOK_BAR_RANGE := 5.0

@onready var _food_sprite: Sprite2D = $FoodSprite
@onready var _cook_bar: Node2D = $CookBar
@onready var _raw_tex: Texture2D = preload("res://assets/food_raw.svg")
@onready var _cooked_tex: Texture2D = preload("res://assets/food_cooked.svg")

var _item := ""
var _cook_time := 0.0

func _process(delta: float) -> void:
	if _item == "" or _item == Items.FOOD_BURNT:
		return
	_cook_time += delta
	if _cook_time >= TIME_BURNT:
		if _item != Items.FOOD_BURNT:
			_item = Items.FOOD_BURNT
			_food_sprite.texture = _cooked_tex
			_food_sprite.modulate = Color(0.15, 0.15, 0.15)
	elif _cook_time >= TIME_COOKED:
		if _item != Items.FOOD_COOKED:
			_item = Items.FOOD_COOKED
			_food_sprite.texture = _cooked_tex
			_food_sprite.modulate = Color.WHITE
	elif _cook_time >= TIME_YELLOW:
		_food_sprite.modulate = Color.YELLOW
	_update_bar()

func _update_bar() -> void:
	if _item == Items.FOOD_BURNT:
		_cook_bar.update_bar(0.0, Color(0.2, 0.2, 0.2), COOK_BAR_RANGE)
	elif _item == Items.FOOD_COOKED:
		var remaining := TIME_BURNT - _cook_time
		_cook_bar.update_bar(remaining, Color(1.0, 0.1, 0.1), COOK_BAR_RANGE)
	elif _cook_time >= TIME_YELLOW:
		_cook_bar.update_bar(_cook_time - TIME_YELLOW, Color.YELLOW, COOK_BAR_RANGE)
	else:
		_cook_bar.update_bar(_cook_time, Color(1.0, 0.6, 0.1), COOK_BAR_RANGE)

func can_interact(player: CharacterBody2D) -> bool:
	if _item == "" and player.has_item(Items.FOOD_RAW):
		return true
	if _item == Items.FOOD_COOKED and player.has_item(Items.BUN):
		return true
	if _item in [Items.FOOD_COOKED, Items.FOOD_BURNT] and not player.inventory_full():
		return true
	return false

func on_player_interact(player: CharacterBody2D) -> void:
	if _item == "" and player.has_item(Items.FOOD_RAW):
		player.take_item(Items.FOOD_RAW)
		_item = Items.FOOD_RAW
		_cook_time = 0.0
		_food_sprite.texture = _raw_tex
		_food_sprite.modulate = Color.WHITE
		_food_sprite.visible = true
		_cook_bar.visible = true
		_update_bar()
	elif _item == Items.FOOD_COOKED and player.has_item(Items.BUN):
		player.take_item(Items.BUN)
		player.pick_up(Items.BURGER, 1.0)
		_item = ""
		_cook_time = 0.0
		_food_sprite.visible = false
		_cook_bar.visible = false
	elif _item in [Items.FOOD_COOKED, Items.FOOD_BURNT]:
		if player.pick_up(_item):
			_item = ""
			_cook_time = 0.0
			_food_sprite.visible = false
			_cook_bar.visible = false
