extends Interactable

func can_interact(player: CharacterBody2D) -> bool:
	var main := get_parent()
	if not main.has_method("queue_front"):
		return false
	var guest: CharacterBody2D = main.queue_front()
	return guest != null and guest.state == guest.State.WAITING

func on_player_interact(player: CharacterBody2D) -> void:
	var main := get_parent()
	var guest: CharacterBody2D = main.queue_front()
	if guest == null or guest.state != guest.State.WAITING:
		return
	guest.seat_assigned(main.pop_queue_front())
