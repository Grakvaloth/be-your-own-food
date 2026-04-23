extends Interactable

func can_interact(player: CharacterBody2D) -> bool:
	return player.has_item(Items.DEAD_GUEST)

func on_player_interact(player: CharacterBody2D) -> void:
	player.take_item(Items.DEAD_GUEST)
