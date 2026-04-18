extends StaticBody2D

func can_interact(player: CharacterBody2D) -> bool:
	var cost := get_parent().get_stove_upgrade_cost()
	return cost >= 0 and get_parent().score >= cost

func on_player_interact(_player: CharacterBody2D) -> void:
	get_parent().buy_stove_upgrade()

func can_interact_alt(player: CharacterBody2D) -> bool:
	var cost := get_parent().get_warmer_upgrade_cost()
	return cost >= 0 and get_parent().score >= cost

func on_player_interact_alt(_player: CharacterBody2D) -> void:
	get_parent().buy_warmer_upgrade()
