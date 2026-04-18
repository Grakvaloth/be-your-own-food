extends CharacterBody2D

const SPEED := 200.0
const INVENTORY_SIZE := 4

var inventory: Array[String] = ["", "", "", ""]

@onready var _slots: Array[TextureRect] = [
	$InventoryLayer/Slot0/Icon,
	$InventoryLayer/Slot1/Icon,
	$InventoryLayer/Slot2/Icon,
	$InventoryLayer/Slot3/Icon,
]

var _textures: Dictionary = {}

func _ready() -> void:
	_textures = {
		"food_raw": load("res://assets/food_raw.svg"),
		"food_cooked": load("res://assets/food_cooked.svg"),
		"food_burnt": load("res://assets/food_cooked.svg"),
	}
	_update_ui()

func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * SPEED
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		_interact()
	_update_hint()

func pick_up(item_name: String) -> bool:
	for i in INVENTORY_SIZE:
		if inventory[i] == "":
			inventory[i] = item_name
			_update_ui()
			return true
	return false

func has_item(item_name: String) -> bool:
	return inventory.has(item_name)

func take_item(item_name: String) -> String:
	for i in INVENTORY_SIZE:
		if inventory[i] == item_name:
			inventory[i] = ""
			_update_ui()
			return item_name
	return ""

func take_any_item() -> String:
	for i in INVENTORY_SIZE:
		if inventory[i] != "":
			var item := inventory[i]
			inventory[i] = ""
			_update_ui()
			return item
	return ""

func _update_ui() -> void:
	for i in INVENTORY_SIZE:
		var item := inventory[i]
		_slots[i].texture = _textures.get(item, null)
		_slots[i].modulate = Color(0.2, 0.2, 0.2) if item == "food_burnt" else Color.WHITE

func _interact() -> void:
	for body in $InteractArea.get_overlapping_bodies():
		if body != self and body.has_method("on_player_interact"):
			body.on_player_interact(self)
			return
	for area in $InteractArea.get_overlapping_areas():
		if area.has_method("on_player_interact"):
			area.on_player_interact(self)
			return

func _update_hint() -> void:
	var found := false
	for body in $InteractArea.get_overlapping_bodies():
		if body != self and body.has_method("on_player_interact"):
			found = true
			break
	$InteractHint.visible = found
