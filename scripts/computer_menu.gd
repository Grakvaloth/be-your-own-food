extends CanvasLayer

signal item_selected(tab: int, index: int)

var _tab := 0
var _selected := 0
var _visible := false
var _items: Array = []
var _tab_names: Array = []

@onready var _panel: Panel = $Panel
@onready var _nav_hint: Label = $Panel/NavHint
@onready var _tab_label: Label = $Panel/TabLabel
@onready var _list: VBoxContainer = $Panel/List
@onready var _cost_label: Label = $Panel/CostLabel
@onready var _hint_label: Label = $Panel/HintLabel

func _ready() -> void:
	_panel.visible = false
	_hint_label.text = "[W/S] Auswahl   [E] Bestätigen   [F] Schließen"

func open(items_by_tab: Array, tab_names: Array = []) -> void:
	_items = items_by_tab
	_tab_names = tab_names if tab_names.size() == items_by_tab.size() else []
	for i in items_by_tab.size():
		if i >= _tab_names.size():
			_tab_names.append("Tab " + str(i + 1))
	_visible = true
	_tab = 0
	_selected = 0
	_panel.visible = true
	_refresh()

func close() -> void:
	_visible = false
	_panel.visible = false

func is_open() -> bool:
	return _visible

func handle_input(action: String) -> void:
	if not _visible:
		return
	match action:
		"menu_left":
			_tab = 0
			_selected = 0
			_refresh()
		"menu_right":
			_tab = 1
			_selected = 0
			_refresh()
		"menu_up":
			var tab_items: Array = _items[_tab]
			_selected = (_selected - 1 + tab_items.size()) % tab_items.size()
			_refresh()
		"menu_down":
			var tab_items: Array = _items[_tab]
			_selected = (_selected + 1) % tab_items.size()
			_refresh()
		"menu_confirm":
			emit_signal("item_selected", _tab, _selected)

func _refresh() -> void:
	var left_name: String = _tab_names[0] if _tab_names.size() > 0 else ""
	var right_name: String = _tab_names[1] if _tab_names.size() > 1 else ""
	_nav_hint.text = "[ A ]  " + left_name + "          " + right_name + "  [ D ]"
	_tab_label.text = _tab_names[_tab] if _tab < _tab_names.size() else ""

	for child in _list.get_children():
		child.queue_free()

	var tab_items: Array = _items[_tab]
	for i in tab_items.size():
		var entry: Dictionary = tab_items[i]
		var row := _build_row(entry, i == _selected)
		if not entry.get("available", true):
			row.modulate = Color(0.5, 0.5, 0.5)
		_list.add_child(row)

	if tab_items.size() > 0:
		var entry: Dictionary = tab_items[_selected]
		var cost: int = entry.get("cost", 0)
		var avail: bool = entry.get("available", true)
		if cost > 0:
			_cost_label.text = "Kosten: " + str(cost) + " Münzen" + ("" if avail else "  [nicht verfügbar]")
		else:
			_cost_label.text = "" if avail else "[nicht verfügbar]"
	else:
		_cost_label.text = ""

func _build_row(entry: Dictionary, selected: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var marker := Label.new()
	marker.text = "►" if selected else "  "
	marker.add_theme_font_size_override("font_size", 20)
	marker.custom_minimum_size = Vector2(24, 0)
	row.add_child(marker)

	if entry.has("icon"):
		var icon_box := Control.new()
		icon_box.custom_minimum_size = Vector2(56, 56)

		var icon := TextureRect.new()
		icon.texture = entry["icon"]
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_box.add_child(icon)

		if entry.has("overlay"):
			var overlay := TextureRect.new()
			overlay.texture = entry["overlay"]
			overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			overlay.scale = Vector2(0.6, 0.6)
			overlay.pivot_offset = Vector2(28, 28)
			icon_box.add_child(overlay)

		row.add_child(icon_box)

		var count_label := Label.new()
		count_label.text = "× " + str(entry.get("count", 0))
		count_label.add_theme_font_size_override("font_size", 22)
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(count_label)
	else:
		var lbl := Label.new()
		lbl.text = entry["label"]
		lbl.add_theme_font_size_override("font_size", 20)
		row.add_child(lbl)

	return row
