extends CharacterBody2D

const SPEED := 600.0
const SPEED_BOOST := 1.5
const INVENTORY_SIZE := 4
const TEMP_THRESHOLD := 1.0 / 3.0

const ATTACK_OFFSETS := {
	"south": Vector2(0, 140),
	"north": Vector2(0, -140),
	"east": Vector2(140, 0),
	"west": Vector2(-140, 0),
}

var inventory: Array[String] = ["", "", "", ""]
var _temps: Array[float] = [1.0, 1.0, 1.0, 1.0]
var _active_slot := 0

var _facing := "south"
var _attacking := false
var input_blocked: bool = false

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var _hint_e: Label = $InventoryLayer/InteractHint
@onready var _hint_q: Label = $InventoryLayer/AltHint
@onready var _hint_f: Label = $InventoryLayer/OpenHint

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

func _ready() -> void:
	_update_ui()

func _physics_process(delta: float) -> void:
	if input_blocked:
		velocity = Vector2.ZERO
		move_and_slide()
		_hint_e.visible = false
		_hint_q.visible = false
		_hint_f.visible = false
		if Input.is_action_just_pressed("open_fridge"):
			_interact_open()
		_update_ui()
		return

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var spd := SPEED * (SPEED_BOOST if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0)

	if not _attacking:
		velocity = dir * spd
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	if dir.length() > 0.1:
		if abs(dir.x) >= abs(dir.y):
			_facing = "east" if dir.x > 0 else "west"
		else:
			_facing = "south" if dir.y > 0 else "north"

	_update_animation(dir)

	for i in INVENTORY_SIZE:
		var rate: float = Items.INVENTORY_COOL_RATES.get(inventory[i], 0.0)
		if rate > 0.0:
			_temps[i] = maxf(0.0, _temps[i] - delta * rate)

	if Input.is_action_just_pressed("attack") and not _attacking:
		_start_attack()
	if Input.is_action_just_pressed("open_fridge"):
		_interact_open()
	if Input.is_action_just_pressed("interact"):
		_interact()
	if Input.is_action_just_pressed("interact_alt"):
		_interact_alt()
	for i in INVENTORY_SIZE:
		if Input.is_action_just_pressed("slot_%d" % (i + 1)):
			_set_active_slot(i)
	if Input.is_action_just_pressed("scroll_up"):
		_set_active_slot((_active_slot - 1 + INVENTORY_SIZE) % INVENTORY_SIZE)
	if Input.is_action_just_pressed("scroll_down"):
		_set_active_slot((_active_slot + 1) % INVENTORY_SIZE)
	_update_ui()
	_update_hint()

func _update_animation(dir: Vector2) -> void:
	if _attacking:
		return
	if dir.length() > 0.1:
		_anim.play("walk_" + _facing)
	else:
		_anim.play("idle_" + _facing)

func _start_attack() -> void:
	_attacking = true
	$AttackArea.position = ATTACK_OFFSETS[_facing]
	_anim.play("attack_" + _facing)

func _on_anim_finished() -> void:
	if _attacking:
		_attacking = false
		_attack_shape.disabled = true

func _on_frame_changed() -> void:
	if _attacking:
		_attack_shape.disabled = not (_anim.frame in [2, 3])

func _on_attack_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)

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

func _take_from_slot(slot: int) -> Dictionary:
	var result := {"name": inventory[slot], "temp": _temps[slot]}
	inventory[slot] = ""
	_temps[slot] = 1.0
	_update_ui()
	return result

func take_item(item_name: String) -> Dictionary:
	if inventory[_active_slot] == item_name:
		return _take_from_slot(_active_slot)
	for i in INVENTORY_SIZE:
		if inventory[i] == item_name:
			return _take_from_slot(i)
	return {"name": "", "temp": 0.0}

func take_any_item() -> Dictionary:
	if inventory[_active_slot] != "":
		return _take_from_slot(_active_slot)
	for i in INVENTORY_SIZE:
		if inventory[i] != "":
			return _take_from_slot(i)
	return {"name": "", "temp": 0.0}

func _update_ui() -> void:
	for i in INVENTORY_SIZE:
		var item := inventory[i]
		_slots[i].texture = Items.get_texture(item)
		if Items.is_temp_sensitive(item):
			_slots[i].modulate = Items.temp_color(_temps[i])
		elif item == Items.FOOD_BURNT:
			_slots[i].modulate = Color(0.2, 0.2, 0.2)
		elif item == Items.DEAD_GUEST:
			_slots[i].modulate = Items.freshness_color(_temps[i])
		else:
			_slots[i].modulate = Color.WHITE
		_panels[i].modulate = Color(1.0, 1.0, 0.3) if i == _active_slot else Color.WHITE

func _interact() -> void:
	for body in $InteractArea.get_overlapping_bodies():
		if body != self and body.has_method("can_interact") and body.can_interact(self) and body.has_method("on_player_interact"):
			body.on_player_interact(self)
			return
	for area in $InteractArea.get_overlapping_areas():
		if area.has_method("can_interact") and area.can_interact(self) and area.has_method("on_player_interact"):
			area.on_player_interact(self)
			return

func _interact_alt() -> void:
	for body in $InteractArea.get_overlapping_bodies():
		if body != self and body.has_method("can_interact_alt") and body.can_interact_alt(self) and body.has_method("on_player_interact_alt"):
			body.on_player_interact_alt(self)
			return

func _interact_open() -> void:
	for body in $InteractArea.get_overlapping_bodies():
		if body != self and body.has_method("can_open") and body.can_open(self) and body.has_method("on_player_open"):
			body.on_player_open(self)
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
	_hint_e.visible = found_e
	_hint_q.visible = found_q
	_hint_f.visible = found_f
