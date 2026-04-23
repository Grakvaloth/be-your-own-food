extends Interactable

func can_interact(player: CharacterBody2D) -> bool:
	return player.has_any_item()

func on_player_interact(player: CharacterBody2D) -> void:
	player.take_any_item()
