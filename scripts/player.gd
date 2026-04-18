extends CharacterBody2D

const SPEED := 600.0
const SPEED_BOOST := 1.5
const INVENTORY_SIZE := 4
const TEMP_THRESHOLD := 1.0 / 3.0

var inventory: Array[String] = ["", "", "", ""]
var _temps: Array[float] = [1.0, 1.0, 1.0, 1.0]
var _active_slot := 0
var last_taken_temp: float = 1.0

@onready var _slots: Array[TextureRect] = [
	$InventoryLayer/Slot0/Icon,
	$InventoryLayer/Slot1/Icon,
	$InventoryLayer/Slot2/Icon,
	$InventoryLayer/Slot3/Icon,
]
@onready var _panels: Array[Panel] = [
	$InventoryLayer/Slot0,
	$InventoryLayer/Slot1,
	$InventoryLayer/Slot2,
	$InventoryLayer/Slot3,
]

var _textures: Dictionary = {}

func _ready() -> void:
	_textures = {
		"food_raw": load("res://assets/food_raw.svg"),
		"food_cooked": load("res://assets/food_cooked.svg"),
		"food_burnt": load("res://assets/food_cooked.svg"),
		"bun": load("res://assets/bun.svg"),
		"burger": load("res://assets/burger.svg"),
	}
	_update_ui()

func _physics_process(delta: float) -> void:
	var spd := SPEED * (SPEED_BOOST if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0)
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * spd
	move_and_slide()
	for i in INVENTORY_SIZE:
		if inventory[i] == "food_cooked":
			_temps[i] = maxf(0.0, _temps[i] - delta / 6.0)
		elif inventory[i] == "burger":
			_temps[i] = maxf(0.0, _temps[i] - delta / 9.0)
	if Input.is_action_just_pressed("open_fridge"):
		_interact_open()
	if Input.is_action_just_pressed("interact"):
		_interact()
	if Input.is_action_just_pressed("interact_alt"):
		_interact_alt()
	if Input.is_action_just_pressed("slot_1"):
		_set_active_slot(0)
	if Input.is_action_just_pressed("slot_2"):
		_set_active_slot(1)
	if Input.is_action_just_pressed("slot_3"):
		_set_active_slot(2)
	if Input.is_action_just_pressed("slot_4"):
		_set_active_slot(3)
	if Input.is_action_just_pressed("scroll_up"):
		_set_active_slot((_active_slot - 1 + INVENTORY_SIZE) % INVENTORY_SIZE)
	if Input.is_action_just_pressed("scroll_down"):
		_set_active_slot((_active_slot + 1) % INVENTORY_SIZE)
	_update_ui()
	_update_hint()

func _set_active_slot(idx: int) -> void:
	_active_slot = idx

func get_active_item() -> String:
	return inventory[_active_slot]

func get_item_temp(item_name: String) -> float:
	if inventory[_active_slot] == item_name:
		return _temps[_active_slot]
	for i in INVENTORY_SIZE:
		if inventory[i] == item_name:
			return _temps[i]
	return 0.0

func pick_up(item_name: String, temp: float = 1.0) -> bool:
	if inventory[_active_slot] == "":
		inventory[_active_slot] = item_name
		_temps[_active_slot] = temp
		_update_ui()
		return true
	for i in INVENTORY_SIZE:
		if inventory[i] == "":
			inventory[i] = item_name
			_temps[i] = temp
			_update_ui()
			return true
	return false

func has_item(item_name: String) -> bool:
	return inventory.has(item_name)

func has_any_item() -> bool:
	for item in inventory:
		if item != "":
			return true
	return false

func inventory_full() -> bool:
	return not ("" in inventory)

func take_item(item_name: String) -> String:
	if inventory[_active_slot] == item_name:
		last_taken_temp = _temps[_active_slot]
		inventory[_active_slot] = ""
		_temps[_active_slot] = 1.0
		_update_ui()
		return item_name
	for i in INVENTORY_SIZE:
		if inventory[i] == item_name:
			last_taken_temp = _temps[i]
			inventory[i] = ""
			_temps[i] = 1.0
			_update_ui()
			return item_name
	return ""

func take_any_item() -> String:
	if inventory[_active_slot] != "":
		var item := inventory[_active_slot]
		last_taken_temp = _temps[_active_slot]
		inventory[_active_slot] = ""
		_temps[_active_slot] = 1.0
		_update_ui()
		return item
	for i in INVENTORY_SIZE:
		if inventory[i] != "":
			var item := inventory[i]
			last_taken_temp = _temps[i]
			inventory[i] = ""
			_temps[i] = 1.0
			_update_ui()
			return item
	return ""

func _update_ui() -> void:
	for i in INVENTORY_SIZE:
		var item := inventory[i]
		_slots[i].texture = _textures.get(item, null)
		if item in ["food_cooked", "burger"]:
			_slots[i].modulate = _temp_color(_temps[i])
		elif item == "food_burnt":
			_slots[i].modulate = Color(0.2, 0.2, 0.2)
		else:
			_slots[i].modulate = Color.WHITE
		_panels[i].modulate = Color(1.0, 1.0, 0.3) if i == _active_slot else Color.WHITE

func _temp_color(t: float) -> Color:
	if t < 0.5:
		return Color(0.2, 0.4, 1.0).lerp(Color(1.0, 1.0, 0.0), t * 2.0)
	return Color(1.0, 1.0, 0.0).lerp(Color(1.0, 0.5, 0.0), (t - 0.5) * 2.0)

func _interact() -> void:
	for body in $InteractArea.get_overlapping_bodies():
		if body != self and body.has_method("can_interact") and body.can_interact(self) and body.has_method("on_player_interact"):
			body.on_player_interact(self)
			return
	for area in $InteractArea.get_overlapping_areas():
		if area.has_method("can_interact") and area.can_interact(self) and area.has_method("on_player_interact"):
			area.on_player_interact(self)
			return

func _interact_open() -> void:
	for body in $InteractArea.get_overlapping_bodies():
		if body != self and body.has_method("can_open") and body.can_open(self) and body.has_method("on_player_open"):
			body.on_player_open(self)
			return

func _interact_alt() -> void:
	for body in $InteractArea.get_overlapping_bodies():
		if body != self and body.has_method("can_interact_alt") and body.can_interact_alt(self) and body.has_method("on_player_interact_alt"):
			body.on_player_interact_alt(self)
			return

func _update_hint() -> void:
	var found_e := false
	var found_q := false
	var found_f := false
	for body in $InteractArea.get_overlapping_bodies():
		if body != self:
			if not found_e and body.has_method("can_interact") and body.can_interact(self):
				found_e = true
			if not found_q and body.has_method("can_interact_alt") and body.can_interact_alt(self):
				found_q = true
			if not found_f and body.has_method("can_open") and body.can_open(self):
				found_f = true
	$InteractHint.visible = found_e
	$AltHint.visible = found_q
	$OpenHint.visible = found_f
