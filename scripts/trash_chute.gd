extends StaticBody2D

func can_interact(player: CharacterBody2D) -> bool:
	return player.has_item("dead_guest")

func on_player_interact(player: CharacterBody2D) -> void:
	player.take_item("dead_guest")
