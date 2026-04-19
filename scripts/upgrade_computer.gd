extends StaticBody2D

var _menu_open := false
var _player: CharacterBody2D = null

func _ready() -> void:
	$ComputerMenu.item_selected.connect(_on_menu_item_selected)

func can_open(_player: CharacterBody2D) -> bool:
	return true

func on_player_open(player: CharacterBody2D) -> void:
	_player = player
	if _menu_open:
		_close_menu()
	else:
		_open_menu()

func _open_menu() -> void:
	_menu_open = true
	if _player:
		_player.input_blocked = true
	var main := get_parent()
	var sc: int = main.get_stove_upgrade_cost()
	var wc: int = main.get_warmer_upgrade_cost()
	var coins: int = main.score

	var upgrade_items: Array = []
	if sc >= 0:
		upgrade_items.append({"label": "Herd freischalten  –  " + str(sc), "cost": sc, "available": coins >= sc})
	else:
		upgrade_items.append({"label": "Herd: MAX", "cost": 0, "available": false})
	if wc >= 0:
		upgrade_items.append({"label": "Wärmer freischalten  –  " + str(wc), "cost": wc, "available": coins >= wc})
	else:
		upgrade_items.append({"label": "Wärmer: MAX", "cost": 0, "available": false})

	var shop_items: Array = [
		{"label": "1 Brötchen  –  10 Münzen", "cost": 10, "available": coins >= 10},
		{"label": "10 Brötchen  –  80 Münzen", "cost": 80, "available": coins >= 80},
	]

	$ComputerMenu.open([upgrade_items, shop_items], ["Upgrades", "Einkauf"])

func _close_menu() -> void:
	_menu_open = false
	$ComputerMenu.close()
	if _player:
		_player.input_blocked = false
		_player = null

func _process(_delta: float) -> void:
	if not _menu_open:
		return
	for action in ["menu_left", "menu_right", "menu_up", "menu_down"]:
		if Input.is_action_just_pressed(action):
			$ComputerMenu.handle_input(action)
	if Input.is_action_just_pressed("interact"):
		$ComputerMenu.handle_input("menu_confirm")

func _on_menu_item_selected(tab: int, index: int) -> void:
	var main := get_parent()
	if tab == 0:
		if index == 0:
			main.buy_stove_upgrade()
		elif index == 1:
			main.buy_warmer_upgrade()
		_open_menu()
	elif tab == 1:
		var coins: int = main.score
		if index == 0 and coins >= 10:
			main.score -= 10
			main.add_fridge_buns(1)
			main._update_hud()
		elif index == 1 and coins >= 80:
			main.score -= 80
			main.add_fridge_buns(10)
			main._update_hud()
		_open_menu()
