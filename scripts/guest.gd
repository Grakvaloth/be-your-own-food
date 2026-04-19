extends CharacterBody2D

enum State { ENTERING, QUEUEING, WAITING, WALKING_TO_TABLE, EATING, DINING, LEAVING, DEAD }

const SPEED := 120.0
const EAT_DURATION := 10.0
const ORDER_WAIT := 30.0
const FOOD_WAIT := 60.0
const AISLE_X := 600.0
const FRESHNESS_DURATION := 300.0

var state := State.ENTERING
var current_order := "burger"
var assigned_seat: Node = null
var queue_index := 0
var hp: int = 1
var _walk_target := Vector2.ZERO
var _eat_timer := 0.0
var _wait_timer := 0.0
var _freshness := FRESHNESS_DURATION
var _served := false
var _at_aisle := false

func _ready() -> void:
	$OrderBubble.visible = false
	$FoodSprite.visible = false
	$TimerBar.visible = false

func _physics_process(delta: float) -> void:
	match state:
		State.ENTERING, State.QUEUEING, State.WALKING_TO_TABLE, State.LEAVING:
			_step_toward(_walk_target)
		State.WAITING:
			velocity = Vector2.ZERO
			move_and_slide()
			if queue_index == 0:
				_wait_timer -= delta
				_update_timer_bar()
				if _wait_timer <= 0.0:
					_leave_early()
		State.EATING:
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
				_walk_target = Vector2(-160, 880)
		State.DEAD:
			velocity = Vector2.ZERO
			move_and_slide()
			if _freshness > 0:
				_freshness -= delta
				_update_freshness_bar()

func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	if hp <= 0:
		_die()

func _die() -> void:
	if assigned_seat != null:
		get_parent().return_seat(assigned_seat)
		assigned_seat = null
	if state in [State.ENTERING, State.QUEUEING, State.WAITING]:
		get_parent().guest_left_early(self)
	$OrderBubble.visible = false
	$FoodSprite.visible = false
	$TimerBar.visible = false
	$Sprite2D.modulate = Color(0.4, 0.4, 0.4)
	$FreshnessBar.visible = true
	$FreshnessBar.update_bar(FRESHNESS_DURATION, Color(0.3, 0.8, 0.3), FRESHNESS_DURATION)
	state = State.DEAD

func _update_freshness_bar() -> void:
	var ratio := clampf(_freshness / FRESHNESS_DURATION, 0.0, 1.0)
	var col := Color(0.8, 0.2, 0.0).lerp(Color(0.3, 0.8, 0.3), ratio)
	$FreshnessBar.update_bar(_freshness, col, FRESHNESS_DURATION)
	if _freshness <= 0:
		$Sprite2D.modulate = Color(0.5, 0.25, 0.0)

func can_interact(player: CharacterBody2D) -> bool:
	if state == State.DEAD:
		return not player.inventory_full()
	if state == State.EATING:
		return player.has_item(current_order) and player.get_item_temp(current_order) >= 1.0 / 3.0
	return false

func on_player_interact(player: CharacterBody2D) -> void:
	if state == State.DEAD:
		var freshness_ratio := clampf(_freshness / FRESHNESS_DURATION, 0.0, 1.0)
		if player.pick_up("dead_guest", freshness_ratio):
			queue_free()
		return
	if state == State.EATING:
		if player.has_item(current_order) and player.get_item_temp(current_order) >= 1.0 / 3.0:
			player.take_item(current_order)
			_place_food_toward_table()
			$FoodSprite.visible = true
			$TimerBar.visible = false
			_eat_timer = EAT_DURATION
			_served = true
			state = State.DINING

func walk_to_queue(pos: Vector2) -> void:
	_walk_target = pos
	$OrderBubble.visible = false
	$TimerBar.visible = false
	if state == State.WAITING:
		state = State.QUEUEING

func seat_assigned(seat: Node) -> void:
	if seat == null:
		return
	assigned_seat = seat
	$OrderBubble.visible = false
	$TimerBar.visible = false
	_at_aisle = false
	_walk_target = Vector2(AISLE_X, assigned_seat.global_position.y)
	state = State.WALKING_TO_TABLE

func _step_toward(pos: Vector2) -> void:
	if global_position.distance_to(pos) < 16.0:
		velocity = Vector2.ZERO
		move_and_slide()
		_on_reached()
		return
	velocity = (pos - global_position).normalized() * SPEED
	move_and_slide()

func _on_reached() -> void:
	match state:
		State.ENTERING, State.QUEUEING:
			state = State.WAITING
			if queue_index == 0:
				_wait_timer = ORDER_WAIT
				$OrderBubble.visible = true
				$TimerBar.max_value = ORDER_WAIT
				$TimerBar.visible = true
				_update_timer_bar()
		State.WALKING_TO_TABLE:
			if not _at_aisle:
				_at_aisle = true
				_walk_target = assigned_seat.global_position
			else:
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
	var max_v := ORDER_WAIT if (state == State.WAITING) else FOOD_WAIT
	var ratio := clampf(_wait_timer / max_v, 0.0, 1.0)
	var col := Color(0.9, 0.1, 0.1).lerp(Color(0.2, 0.8, 0.2), ratio)
	$TimerBar.update_bar(_wait_timer, col)

func _leave_early() -> void:
	$OrderBubble.visible = false
	$TimerBar.visible = false
	get_parent().guest_left_early(self)
	state = State.LEAVING
	_walk_target = Vector2(-160, 880)

func _place_food_toward_table() -> void:
	if assigned_seat != null and assigned_seat.position.y < 0:
		$FoodSprite.position = Vector2(0, 32)
	else:
		$FoodSprite.position = Vector2(0, -32)
