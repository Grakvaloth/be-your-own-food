extends Interactable

var meat_count: int = 5
var bun_count: int = 10
var _menu_open := false
var _player: CharacterBody2D = null

func add_meat(amount: int) -> void:
	meat_count += amount
	_refresh_if_open()

func add_buns(amount: int) -> void:
	bun_count += amount
	_refresh_if_open()

func _refresh_if_open() -> void:
	if _menu_open:
		_open_menu()

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
	var full: bool = _player != null and _player.inventory_full()
	var meat_items: Array = [{
		"icon": Items.get_texture(Items.FOOD_RAW),
		"overlay": load("res://assets/guest.svg"),
		"count": meat_count,
		"cost": 0,
		"available": meat_count > 0 and not full
	}]
	var bun_items: Array = [{
		"icon": Items.get_texture(Items.BUN),
		"count": bun_count,
		"cost": 0,
		"available": bun_count > 0 and not full
	}]
	$ComputerMenu.open([meat_items, bun_items], ["Fleisch", "Brötchen"])

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

func _on_menu_item_selected(tab: int, _index: int) -> void:
	if _player == null:
		return
	if tab == 0 and meat_count > 0 and not _player.inventory_full():
		_player.pick_up(Items.FOOD_RAW)
		meat_count -= 1
	elif tab == 1 and bun_count > 0 and not _player.inventory_full():
		_player.pick_up(Items.BUN)
		bun_count -= 1
	_open_menu()

