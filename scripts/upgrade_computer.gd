extends StaticBody2D

var _menu_open := false

func _ready() -> void:
	$ComputerMenu.item_selected.connect(_on_menu_item_selected)

func can_open(_player: CharacterBody2D) -> bool:
	return true

func on_player_open(_player: CharacterBody2D) -> void:
	if _menu_open:
		_close_menu()
	else:
		_open_menu()

func _open_menu() -> void:
	_menu_open = true
	var main := get_parent()
	var sc := main.get_stove_upgrade_cost()
	var wc := main.get_warmer_upgrade_cost()

	var upgrades: Array = []
	for i in 4:
		var cost: int = (i + 1) * 500
		upgrades.append({
			"label": "Herd-Slot " + str(i + 2) + "  –  " + str(cost) + " Münzen",
			"cost": cost,
			"available": i < 4 - main._stoves_purchased and main.score >= cost and i == (4 - main._stove_upgrade_slots.size() + main._stoves_purchased) - (4 - main._stove_upgrade_slots.size()),
		})
	# Simpler: just show next stove + next warmer upgrades
	var upgrade_items: Array = []
	if sc >= 0:
		upgrade_items.append({"label": "Herd freischalten  –  " + str(sc), "cost": sc, "available": main.score >= sc})
	else:
		upgrade_items.append({"label": "Herd: MAX", "cost": 0, "available": false})
	if wc >= 0:
		upgrade_items.append({"label": "Wärmer freischalten  –  " + str(wc), "cost": wc, "available": main.score >= wc})
	else:
		upgrade_items.append({"label": "Wärmer: MAX", "cost": 0, "available": false})

	var shop_items: Array = [
		{"label": "1 Brötchen  –  10 Münzen", "cost": 10, "available": main.score >= 10},
		{"label": "10 Brötchen  –  80 Münzen", "cost": 80, "available": main.score >= 80},
	]

	$ComputerMenu.open([upgrade_items, shop_items])

func _close_menu() -> void:
	_menu_open = false
	$ComputerMenu.close()

func _process(_delta: float) -> void:
	if not _menu_open:
		return
	for action in ["menu_left", "menu_right", "menu_up", "menu_down"]:
		if Input.is_action_just_pressed(action):
			$ComputerMenu.handle_input(action)
	if Input.is_action_just_pressed("interact"):
		$ComputerMenu.handle_input("menu_confirm")
	if Input.is_action_just_pressed("open_fridge"):
		_close_menu()

func _on_menu_item_selected(tab: int, index: int) -> void:
	var main := get_parent()
	if tab == 0:
		if index == 0:
			main.buy_stove_upgrade()
		elif index == 1:
			main.buy_warmer_upgrade()
		_open_menu()  # refresh
	elif tab == 1:
		if index == 0 and main.score >= 10:
			main.score -= 10
			main.$Fridge.bun_count += 1
			main.$Fridge._update_labels()
			main._update_hud()
		elif index == 1 and main.score >= 80:
			main.score -= 80
			main.$Fridge.bun_count += 10
			main.$Fridge._update_labels()
			main._update_hud()
		_open_menu()  # refresh
