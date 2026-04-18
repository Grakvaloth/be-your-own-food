extends StaticBody2D

var _open := false

func can_open(_player: CharacterBody2D) -> bool:
	return true

func on_player_open(_player: CharacterBody2D) -> void:
	_open = not _open

func can_interact(player: CharacterBody2D) -> bool:
	return _open and not player.inventory_full()

func on_player_interact(player: CharacterBody2D) -> void:
	if _open and not player.inventory_full():
		player.pick_up("food_raw")
		_open = false

func can_interact_alt(player: CharacterBody2D) -> bool:
	return _open and not player.inventory_full()

func on_player_interact_alt(player: CharacterBody2D) -> void:
	if _open and not player.inventory_full():
		player.pick_up("bun")
		_open = false
