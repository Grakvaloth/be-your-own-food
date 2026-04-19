extends Node2D

const SPAWN_INTERVAL := 10.0
const MAX_GUESTS := 6
const POINTS_PER_GUEST := 100
const QUEUE_POSITIONS := [
	Vector2(900, 880),
	Vector2(720, 880),
	Vector2(540, 880),
	Vector2(360, 880),
	Vector2(180, 880),
]

var score := 0
var _guests: Array = []
var _queue: Array = []
var _free_seats: Array = []
var _spawn_timer := 3.0

var _stove_upgrade_slots: Array = []
var _warmer_upgrade_slots: Array = []
var _stoves_purchased := 0
var _warmers_purchased := 0

func _ready() -> void:
	_free_seats = [
		$Table1/SeatPoint_Top,
		$Table1/SeatPoint_Bottom,
		$Table2/SeatPoint_Top,
		$Table2/SeatPoint_Bottom,
		$Table3/SeatPoint_Top,
		$Table3/SeatPoint_Bottom,
	]
	_stove_upgrade_slots = [$StoveSlot1, $StoveSlot2, $StoveSlot3, $StoveSlot4]
	_warmer_upgrade_slots = [$WarmerSlot1, $WarmerSlot2, $WarmerSlot3, $WarmerSlot4]
	_update_hud()

func _process(delta: float) -> void:
	var queue_full := _queue.size() >= QUEUE_POSITIONS.size()
	if _guests.size() < MAX_GUESTS and not queue_full:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_guest()
			_spawn_timer = SPAWN_INTERVAL

func _spawn_guest() -> void:
	if _queue.size() >= QUEUE_POSITIONS.size():
		return
	var g: CharacterBody2D = preload("res://scenes/Guest.tscn").instantiate()
	var queue_pos := _queue.size()
	g.global_position = Vector2(-160, 880)
	g.queue_index = queue_pos
	add_child(g)
	_guests.append(g)
	_queue.append(g)
	g.walk_to_queue(QUEUE_POSITIONS[queue_pos])

func queue_front() -> CharacterBody2D:
	if _queue.size() == 0:
		return null
	return _queue[0]

func pop_queue_front() -> Node:
	if _queue.size() == 0 or _free_seats.size() == 0:
		return null
	var seat: Node = _free_seats.pop_front()
	_queue.pop_front()
	_advance_queue()
	return seat

func _advance_queue() -> void:
	for i in _queue.size():
		_queue[i].queue_index = i
		_queue[i].walk_to_queue(QUEUE_POSITIONS[i])

func guest_served(guest: CharacterBody2D) -> void:
	score += POINTS_PER_GUEST
	if guest.assigned_seat != null:
		_free_seats.append(guest.assigned_seat)
	_guests.erase(guest)
	guest.queue_free()
	_update_hud()

func guest_left_early(guest: CharacterBody2D) -> void:
	if _queue.has(guest):
		_queue.erase(guest)
		_advance_queue()
	_guests.erase(guest)

func guest_done(guest: CharacterBody2D) -> void:
	if guest.assigned_seat != null:
		_free_seats.append(guest.assigned_seat)
	_guests.erase(guest)
	guest.queue_free()

func return_seat(seat: Node) -> void:
	if not _free_seats.has(seat):
		_free_seats.append(seat)

func add_fridge_meat(amount: int) -> void:
	$Fridge.meat_count += amount
	$Fridge._update_labels()

func get_stove_upgrade_cost() -> int:
	if _stoves_purchased >= _stove_upgrade_slots.size():
		return -1
	return (_stoves_purchased + 1) * 500

func get_warmer_upgrade_cost() -> int:
	if _warmers_purchased >= _warmer_upgrade_slots.size():
		return -1
	return (_warmers_purchased + 1) * 1000

func buy_stove_upgrade() -> bool:
	var cost := get_stove_upgrade_cost()
	if cost < 0 or score < cost:
		return false
	score -= cost
	var slot: Node = _stove_upgrade_slots[_stoves_purchased]
	_replace_with_stove(slot)
	_stoves_purchased += 1
	_update_hud()
	return true

func buy_warmer_upgrade() -> bool:
	var cost := get_warmer_upgrade_cost()
	if cost < 0 or score < cost:
		return false
	score -= cost
	var slot: Node = _warmer_upgrade_slots[_warmers_purchased]
	_replace_with_warmer(slot)
	_warmers_purchased += 1
	_update_hud()
	return true

func _replace_with_stove(slot: Node) -> void:
	var pos: Vector2 = (slot as Node2D).global_position
	slot.queue_free()
	var stove: Node = preload("res://scenes/Stove.tscn").instantiate()
	stove.scale = Vector2(2, 2)
	add_child(stove)
	stove.global_position = pos

func _replace_with_warmer(slot: Node) -> void:
	var pos: Vector2 = (slot as Node2D).global_position
	slot.queue_free()
	var warmer: Node = preload("res://scenes/WarmingPlate.tscn").instantiate()
	warmer.scale = Vector2(2, 2)
	add_child(warmer)
	warmer.global_position = pos

func _update_hud() -> void:
	$HUD/ScoreLabel.text = "Münzen: " + str(score)
