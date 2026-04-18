extends Node2D

const SPAWN_INTERVAL := 30.0
const MAX_GUESTS := 2
const POINTS_PER_GUEST := 10

var score := 0
var _guests: Array = []
var _free_tables: Array = []
var _spawn_timer := 5.0

func _ready() -> void:
	_free_tables = [$Table1, $Table2]
	$HUD/ScoreLabel.text = "Score: 0"

func _process(delta: float) -> void:
	if _guests.size() < MAX_GUESTS and _free_tables.size() > 0:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_guest()
			_spawn_timer = SPAWN_INTERVAL

func _spawn_guest() -> void:
	var g: CharacterBody2D = preload("res://scenes/Guest.tscn").instantiate()
	g.assigned_table = _free_tables.pop_front()
	g.global_position = Vector2(-50, 360)
	add_child(g)
	_guests.append(g)

func guest_served(guest: CharacterBody2D) -> void:
	score += POINTS_PER_GUEST
	$HUD/ScoreLabel.text = "Score: " + str(score)
	if guest.assigned_table != null:
		_free_tables.append(guest.assigned_table)
	_guests.erase(guest)
	guest.queue_free()
