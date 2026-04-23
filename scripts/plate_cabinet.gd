extends Interactable

func can_interact(player: CharacterBody2D) -> bool:
	return not player.inventory_full()

func on_player_interact(player: CharacterBody2D) -> void:
	if not player.inventory_full():
		player.pick_up(Items.PLATE)
