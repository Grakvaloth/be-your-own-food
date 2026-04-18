extends StaticBody2D

func on_player_interact(player: CharacterBody2D) -> void:
	player.pick_up("food_raw")
