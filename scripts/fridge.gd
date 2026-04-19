extends StaticBody2D

var meat_count: int = 5
var bun_count: int = 10
var _open := false

@onready var _panel: Panel = $FridgeMenu/Panel
@onready var _meat_label: Label = $FridgeMenu/MeatLabel
@onready var _bun_label: Label = $FridgeMenu/BunLabel

func _ready() -> void:
	_panel.visible = false
	_update_labels()

func _update_labels() -> void:
	if _meat_label:
		_meat_label.text = "[E]  ×" + str(meat_count)
	if _bun_label:
		_bun_label.text = "[Q]  ×" + str(bun_count)

func can_open(_player: CharacterBody2D) -> bool:
	return true

func on_player_open(_player: CharacterBody2D) -> void:
	_open = not _open
	_panel.visible = _open

func can_interact(player: CharacterBody2D) -> bool:
	return _open and meat_count > 0 and not player.inventory_full()

func on_player_interact(player: CharacterBody2D) -> void:
	if _open and meat_count > 0 and not player.inventory_full():
		player.pick_up("food_raw")
		meat_count -= 1
		_update_labels()
		_open = false
		_panel.visible = false

func can_interact_alt(player: CharacterBody2D) -> bool:
	return _open and bun_count > 0 and not player.inventory_full()

func on_player_interact_alt(player: CharacterBody2D) -> void:
	if _open and bun_count > 0 and not player.inventory_full():
		player.pick_up("bun")
		bun_count -= 1
		_update_labels()
		_open = false
		_panel.visible = false
