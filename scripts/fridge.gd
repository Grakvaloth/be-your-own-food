extends StaticBody2D

func can_interact(player: CharacterBody2D) -> bool:
	return not player.inventory_full()

func on_player_interact(player: CharacterBody2D) -> void:
	player.pick_up("food_raw")
