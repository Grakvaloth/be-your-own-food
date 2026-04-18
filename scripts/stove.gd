extends StaticBody2D

const COOK_TIME := 5.0

var _item := ""
var _timer := 0.0

func _process(delta: float) -> void:
	if _item == "food_raw":
		_timer -= delta
		if _timer <= 0.0:
			_item = "food_cooked"

func on_player_interact(player: CharacterBody2D) -> void:
	if _item == "" and player.carried_item == "food_raw":
		_item = player.drop()
		_timer = COOK_TIME
	elif _item == "food_cooked" and player.carried_item == "":
		player.pick_up(_item)
		_item = ""
