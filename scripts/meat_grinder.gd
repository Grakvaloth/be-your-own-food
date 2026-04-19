extends StaticBody2D

var _timer: float = 0.0
var _running := false
const GRIND_TIME := 60.0

@onready var _bar: Node2D = $TimerBar

func _ready() -> void:
	_bar.visible = false

func _process(delta: float) -> void:
	if _running:
		_timer -= delta
		var col := Color(0.2, 0.6, 1.0).lerp(Color(1.0, 0.3, 0.0), 1.0 - (_timer / GRIND_TIME))
		_bar.update_bar(_timer, col, GRIND_TIME)
		if _timer <= 0.0:
			_running = false
			_bar.visible = false
			get_parent().add_fridge_meat(5)

func can_interact(player: CharacterBody2D) -> bool:
	return not _running and player.has_item("dead_guest") \
		and player.get_item_temp("dead_guest") > 0.0

func on_player_interact(player: CharacterBody2D) -> void:
	if not _running and player.has_item("dead_guest") and player.get_item_temp("dead_guest") > 0.0:
		player.take_item("dead_guest")
		_running = true
		_timer = GRIND_TIME
		_bar.visible = true
