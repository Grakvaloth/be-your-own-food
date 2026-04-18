extends CharacterBody2D

enum State { ENTERING, WAITING, WALKING_TO_TABLE, EATING, LEAVING }

const SPEED := 120.0

var state := State.ENTERING
var current_order := "food_cooked"
var assigned_table: Node = null

func _ready() -> void:
	_walk_target = Vector2(150, 360)

var _walk_target := Vector2.ZERO

func _physics_process(_delta: float) -> void:
	match state:
		State.ENTERING, State.WALKING_TO_TABLE, State.LEAVING:
			_step_toward(_walk_target)
		State.WAITING, State.EATING:
			velocity = Vector2.ZERO
			move_and_slide()

func _step_toward(pos: Vector2) -> void:
	var diff := pos - global_position
	if diff.length() < 8.0:
		velocity = Vector2.ZERO
		move_and_slide()
		_on_reached()
	else:
		velocity = diff.normalized() * SPEED
		move_and_slide()

func _on_reached() -> void:
	match state:
		State.ENTERING:
			state = State.WAITING
		State.WALKING_TO_TABLE:
			state = State.EATING
		State.LEAVING:
			get_parent().guest_served(self)

func on_player_interact(player: CharacterBody2D) -> void:
	match state:
		State.WAITING:
			if assigned_table != null:
				_walk_target = assigned_table.get_node("SeatPoint").global_position
				state = State.WALKING_TO_TABLE
		State.EATING:
			if player.carried_item == current_order:
				player.drop()
				state = State.LEAVING
				_walk_target = Vector2(-80, 360)
