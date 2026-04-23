class_name TempSurface
extends Interactable

# Gemeinsame Basis für Arbeitsfläche (Counter) und Wärmeplatte.
# heat = false: Temperatur fällt gemäß Items.SURFACE_COOL_RATES
# heat = true:  Temperatur steigt gemäß Items.SURFACE_HEAT_RATE

var heat: bool = false

var _item: String = ""
var _temp: float = 1.0

@onready var _sprite: Sprite2D = $ItemSprite

func _ready() -> void:
	_sprite.visible = false

func _process(delta: float) -> void:
	if heat:
		if Items.is_temp_sensitive(_item):
			_temp = minf(1.0, _temp + delta * Items.SURFACE_HEAT_RATE)
			_update_sprite()
	else:
		var rate: float = Items.SURFACE_COOL_RATES.get(_item, 0.0)
		if rate > 0.0:
			_temp = maxf(0.0, _temp - delta * rate)
			_update_sprite()

func can_interact(player: CharacterBody2D) -> bool:
	if _item == Items.BUN and player.has_item(Items.FOOD_COOKED):
		return true
	if _item == Items.FOOD_COOKED and player.has_item(Items.BUN):
		return true
	if _item != "":
		return not player.inventory_full()
	return player.get_active_item() in Items.SURFACE_STORABLE

func on_player_interact(player: CharacterBody2D) -> void:
	if _item == Items.BUN and player.has_item(Items.FOOD_COOKED):
		var taken: Dictionary = player.take_item(Items.FOOD_COOKED)
		_temp = taken.temp
		_item = Items.BURGER
		_update_sprite()
		return
	if _item == Items.FOOD_COOKED and player.has_item(Items.BUN):
		player.take_item(Items.BUN)
		_item = Items.BURGER
		_update_sprite()
		return
	if _item != "":
		player.pick_up(_item, _temp)
		_item = ""
		_temp = 1.0
		_sprite.visible = false
		return
	var active: String = player.get_active_item()
	if active in Items.SURFACE_STORABLE:
		var taken: Dictionary = player.take_item(active)
		_item = active
		_temp = taken.temp
		_update_sprite()

func _update_sprite() -> void:
	_sprite.texture = Items.get_texture(_item)
	_sprite.visible = _item != ""
	_sprite.scale = Vector2(1.05, 1.05) if _item == Items.BURGER else Vector2(0.7, 0.7)
	if Items.is_temp_sensitive(_item):
		_sprite.modulate = Items.temp_color(_temp)
	else:
		_sprite.modulate = Color.WHITE
