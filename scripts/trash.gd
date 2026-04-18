extends StaticBody2D

func on_player_interact(player: CharacterBody2D) -> void:
	player.take_any_item()
