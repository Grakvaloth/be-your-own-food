extends CharacterBody2D

enum State { ENTERING, QUEUEING, WAITING, WALKING_TO_TABLE, EATING, DINING, LEAVING, DEAD }

const SPEED := 120.0
const EAT_DURATION := 10.0
const ORDER_WAIT := 30.0
const FOOD_WAIT := 60.0
const AISLE_X := 600.0
const FRESHNESS_DURATION := 300.0
const EXIT_POS := Vector2(-160, 880)
const REACH_THRESHOLD := 16.0
const SERVE_TEMP_MIN := 1.0 / 3.0

var state := State.ENTERING
var current_order := Items.BURGER
var assigned_seat: Node = null
var queue_index := 0
var hp: int = 1
var _walk_target := Vector2.ZERO
var _eat_timer := 0.0
var _order_timer := 0.0
var _food_timer := 0.0
var _freshness := FRESHNESS_DURATION
var _served := false
var _at_aisle := false
var _facing := "south"

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	$OrderBubble.visible = false
	$FoodSprite.visible = false
	$TimerBar.visible = false

func _physics_process(delta: float) -> void:
	match state:
		State.ENTERING, State.QUEUEING, State.WALKING_TO_TABLE, State.LEAVING:
			_step_toward(_walk_target)
		State.WAITING:
			_handle_waiting(delta)
		State.EATING:
			_handle_eating(delta)
		State.DINING:
			_handle_dining(delta)
		State.DEAD:
			_handle_dead(delta)

func _handle_waiting(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_update_animation(false)
	if queue_index == 0:
		_order_timer -= delta
		_update_timer_bar(_order_timer, ORDER_WAIT)
		if _order_timer <= 0.0:
			call_deferred("_leave_early")

func _handle_eating(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_update_animation(false)
	_food_timer -= delta
	_update_timer_bar(_food_timer, FOOD_WAIT)
	if _food_timer <= 0.0:
		call_deferred("_leave_early")

func _handle_dining(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_update_animation(false)
	_eat_timer -= delta
	if _eat_timer <= 0.0:
		$FoodSprite.visible = false
		state = State.LEAVING
		_walk_target = EXIT_POS

func _handle_dead(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if _freshness > 0:
		_freshness -= delta
		_update_freshness_bar()

func _update_animation(moving: bool) -> void:
	if state == State.DEAD:
		return
	_anim.play(("walk_" if moving else "idle_") + _facing)

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
	_anim.play("idle_" + _facing)
	_anim.rotation = PI * 1.5
	_anim.modulate = Color(0.4, 0.4, 0.4)
	$FreshnessBar.visible = true
	$FreshnessBar.update_bar(FRESHNESS_DURATION, Color(0.3, 0.8, 0.3), FRESHNESS_DURATION)
	collision_layer = 8
	state = State.DEAD
	EventBus.guest_died.emit(self)

func _update_freshness_bar() -> void:
	var ratio := clampf(_freshness / FRESHNESS_DURATION, 0.0, 1.0)
	var col := Color(0.8, 0.2, 0.0).lerp(Color(0.3, 0.8, 0.3), ratio)
	$FreshnessBar.update_bar(_freshness, col, FRESHNESS_DURATION)
	if _freshness <= 0:
		_anim.modulate = Color(0.5, 0.25, 0.0)

func can_interact(player: CharacterBody2D) -> bool:
	if state == State.DEAD:
		return not player.inventory_full()
	if state == State.EATING:
		return player.has_item(current_order) and player.get_item_temp(current_order) >= SERVE_TEMP_MIN
	return false

func on_player_interact(player: CharacterBody2D) -> void:
	if state == State.DEAD:
		var freshness_ratio := clampf(_freshness / FRESHNESS_DURATION, 0.0, 1.0)
		if player.pick_up(Items.DEAD_GUEST, freshness_ratio):
			queue_free()
		return
	if state == State.EATING:
		if player.has_item(current_order) and player.get_item_temp(current_order) >= SERVE_TEMP_MIN:
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
	var dir := (pos - global_position).normalized()
	if abs(dir.x) >= abs(dir.y):
		_facing = "east" if dir.x > 0 else "west"
	else:
		_facing = "south" if dir.y > 0 else "north"

	if global_position.distance_to(pos) < REACH_THRESHOLD:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(false)
		_on_reached()
		return
	velocity = dir * SPEED
	move_and_slide()
	_update_animation(true)

func _on_reached() -> void:
	match state:
		State.ENTERING, State.QUEUEING:
			state = State.WAITING
			if queue_index == 0:
				_order_timer = ORDER_WAIT
				$OrderBubble.visible = true
				$TimerBar.max_value = ORDER_WAIT
				$TimerBar.visible = true
				_update_timer_bar(_order_timer, ORDER_WAIT)
		State.WALKING_TO_TABLE:
			if not _at_aisle:
				_at_aisle = true
				_walk_target = assigned_seat.global_position
			else:
				state = State.EATING
				_food_timer = FOOD_WAIT
				$TimerBar.max_value = FOOD_WAIT
				$TimerBar.visible = true
				_update_timer_bar(_food_timer, FOOD_WAIT)
		State.LEAVING:
			if _served:
				get_parent().guest_served(self)
			else:
				get_parent().guest_done(self)
			return

func _update_timer_bar(value: float, max_v: float) -> void:
	var ratio := clampf(value / max_v, 0.0, 1.0)
	var col := Color(0.9, 0.1, 0.1).lerp(Color(0.2, 0.8, 0.2), ratio)
	$TimerBar.update_bar(value, col)

func _leave_early() -> void:
	if state in [State.LEAVING, State.DEAD, State.DINING]:
		return
	$OrderBubble.visible = false
	$TimerBar.visible = false
	get_parent().guest_left_early(self)
	state = State.LEAVING
	_walk_target = EXIT_POS

func _place_food_toward_table() -> void:
	if assigned_seat != null and assigned_seat.position.y < 0:
		$FoodSprite.position = Vector2(0, 32)
	else:
		$FoodSprite.position = Vector2(0, -32)
