extends CharacterBody2D

enum State { ENTERING, WAITING, WALKING_TO_TABLE, EATING, DINING, LEAVING }

const SPEED := 120.0
const EAT_DURATION := 10.0
const ORDER_WAIT := 30.0
const FOOD_WAIT := 60.0

var state := State.ENTERING
var current_order := "food_cooked"
var assigned_seat: Node = null

@onready var _nav: NavigationAgent2D = $NavAgent

var _walk_target := Vector2.ZERO
var _eat_timer := 0.0
var _wait_timer := 0.0
var _served := false

func _ready() -> void:
	_walk_target = Vector2(360, 390)
	$OrderBubble.visible = false
	$FoodSprite.visible = false
	$TimerBar.visible = false

func _physics_process(delta: float) -> void:
	match state:
		State.ENTERING, State.WALKING_TO_TABLE, State.LEAVING:
			_step_toward(_walk_target)
		State.WAITING, State.EATING:
			velocity = Vector2.ZERO
			move_and_slide()
			_wait_timer -= delta
			_update_timer_bar()
			if _wait_timer <= 0.0:
				_leave_early()
		State.DINING:
			velocity = Vector2.ZERO
			move_and_slide()
			_eat_timer -= delta
			if _eat_timer <= 0.0:
				$FoodSprite.visible = false
				state = State.LEAVING
				_walk_target = Vector2(-80, 700)

func _step_toward(pos: Vector2) -> void:
	if global_position.distance_to(pos) < 12.0:
		velocity = Vector2.ZERO
		move_and_slide()
		_on_reached()
		return
	if state in [State.ENTERING, State.LEAVING]:
		velocity = (pos - global_position).normalized() * SPEED
	else:
		_nav.target_position = pos
		var next := _nav.get_next_path_position()
		velocity = (next - global_position).normalized() * SPEED
	move_and_slide()

func _on_reached() -> void:
	match state:
		State.ENTERING:
			state = State.WAITING
			_wait_timer = ORDER_WAIT
			$OrderBubble.visible = true
			$TimerBar.max_value = ORDER_WAIT
			$TimerBar.visible = true
		State.WALKING_TO_TABLE:
			state = State.EATING
			_wait_timer = FOOD_WAIT
			$TimerBar.max_value = FOOD_WAIT
			$TimerBar.visible = true
			_update_timer_bar()
		State.LEAVING:
			if _served:
				get_parent().guest_served(self)
			else:
				get_parent().guest_done(self)
			return

func _update_timer_bar() -> void:
	var ratio := clampf(_wait_timer / $TimerBar.max_value, 0.0, 1.0)
	var col := Color(0.9, 0.1, 0.1).lerp(Color(0.2, 0.8, 0.2), ratio)
	$TimerBar.update_bar(_wait_timer, col)

func _leave_early() -> void:
	$OrderBubble.visible = false
	$TimerBar.visible = false
	if assigned_seat != null:
		get_parent().guest_left_early(self)
		assigned_seat = null
	state = State.LEAVING
	_walk_target = Vector2(-80, 700)

func can_interact(player: CharacterBody2D) -> bool:
	match state:
		State.WAITING:
			return assigned_seat != null
		State.EATING:
			return player.has_item(current_order)
	return false

func on_player_interact(player: CharacterBody2D) -> void:
	match state:
		State.WAITING:
			if assigned_seat != null:
				_walk_target = assigned_seat.global_position
				state = State.WALKING_TO_TABLE
				$OrderBubble.visible = false
				$TimerBar.visible = false
		State.EATING:
			if player.has_item(current_order):
				player.take_item(current_order)
				_place_food_toward_table()
				$FoodSprite.visible = true
				$TimerBar.visible = false
				_eat_timer = EAT_DURATION
				_served = true
				state = State.DINING

func _place_food_toward_table() -> void:
	if assigned_seat != null and assigned_seat.position.y < 0:
		$FoodSprite.position = Vector2(0, 32)
	else:
		$FoodSprite.position = Vector2(0, -32)
