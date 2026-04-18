extends StaticBody2D

var stored_item: String = ""

func can_interact(player: CharacterBody2D) -> bool:
	if stored_item == "":
		return player.has_item("food_cooked")
	return not player.inventory_full()

func on_player_interact(player: CharacterBody2D) -> void:
	if stored_item == "":
		if player.has_item("food_cooked"):
			player.take_item("food_cooked")
			stored_item = "food_cooked"
			$Sprite2D.modulate = Color(1.0, 0.6, 0.2)
	else:
		if not player.inventory_full():
			player.pick_up(stored_item)
			stored_item = ""
			$Sprite2D.modulate = Color(1, 1, 1)
