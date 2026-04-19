extends StaticBody2D

var _item: String = ""
var _freshness: float = 1.0

const FRESHNESS_DURATION := 300.0

@onready var _sprite: Sprite2D = $ItemSprite
@onready var _bar: Node2D = $FreshnessBar

func _ready() -> void:
	_sprite.visible = false
	_bar.visible = false

func _process(delta: float) -> void:
	if _item == "dead_guest":
		_freshness -= delta / FRESHNESS_DURATION
		_freshness = maxf(0.0, _freshness)
		var col := Color(0.8, 0.2, 0.0).lerp(Color(0.3, 0.8, 0.3), _freshness)
		_bar.update_bar(_freshness * FRESHNESS_DURATION, col, FRESHNESS_DURATION)
		if _freshness <= 0:
			_sprite.modulate = Color(0.5, 0.25, 0.0)

func can_interact(player: CharacterBody2D) -> bool:
	if _item != "":
		return not player.inventory_full()
	return player.has_item("dead_guest")

func on_player_interact(player: CharacterBody2D) -> void:
	if _item != "":
		player.pick_up(_item, _freshness)
		_item = ""
		_sprite.visible = false
		_bar.visible = false
	elif player.has_item("dead_guest"):
		_freshness = player.last_taken_temp
		player.take_item("dead_guest")
		_item = "dead_guest"
		_sprite.texture = load("res://assets/guest.svg")
		_sprite.modulate = Color(0.4, 0.4, 0.4)
		_sprite.visible = true
		_bar.visible = true
