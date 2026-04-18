extends CharacterBody2D

const SPEED := 200.0
var carried_item := ""

func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * SPEED
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		_interact()

func pick_up(item_name: String) -> void:
	if carried_item == "":
		carried_item = item_name

func drop() -> String:
	var item := carried_item
	carried_item = ""
	return item

func _interact() -> void:
	for body in $InteractArea.get_overlapping_bodies():
		if body != self and body.has_method("on_player_interact"):
			body.on_player_interact(self)
			return
	for area in $InteractArea.get_overlapping_areas():
		if area.has_method("on_player_interact"):
			area.on_player_interact(self)
			return
