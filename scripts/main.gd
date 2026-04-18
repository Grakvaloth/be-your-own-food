extends Node2D

const SPAWN_INTERVAL := 10.0
const MAX_GUESTS := 6
const POINTS_PER_GUEST := 100
const QUEUE_POSITIONS := [
	Vector2(1440, 440),
	Vector2(1260, 440),
	Vector2(1080, 440),
	Vector2(900, 440),
	Vector2(720, 440),
]

var score := 0
var _guests: Array = []
var _queue: Array = []
var _free_seats: Array = []
var _spawn_timer := 3.0

func _ready() -> void:
	_free_seats = [
		$Table1/SeatPoint_Top,
		$Table1/SeatPoint_Bottom,
		$Table2/SeatPoint_Top,
		$Table2/SeatPoint_Bottom,
		$Table3/SeatPoint_Top,
		$Table3/SeatPoint_Bottom,
	]
	$HUD/ScoreLabel.text = "Münzen: 0"

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
	g.global_position = Vector2(-80, 440)
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
	$HUD/ScoreLabel.text = "Münzen: " + str(score)
	if guest.assigned_seat != null:
		_free_seats.append(guest.assigned_seat)
	_guests.erase(guest)
	guest.queue_free()

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
