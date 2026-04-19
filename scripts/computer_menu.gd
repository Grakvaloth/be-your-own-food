extends CanvasLayer

signal item_selected(tab: int, index: int)

var _tab := 0       # 0 = Upgrades, 1 = Einkauf
var _selected := 0
var _visible := false

var _items: Array = []  # set by upgrade_computer

@onready var _panel: Panel = $Panel
@onready var _tab_label: Label = $Panel/TabLabel
@onready var _list: VBoxContainer = $Panel/List
@onready var _cost_label: Label = $Panel/CostLabel
@onready var _hint_label: Label = $Panel/HintLabel

func _ready() -> void:
	_panel.visible = false
	_hint_label.text = "[W/S] Auswahl  [A/D] Register  [E] Kaufen  [F] Schließen"

func open(items_by_tab: Array) -> void:
	_items = items_by_tab
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
	var tabs := ["Upgrades", "Einkauf"]
	_tab_label.text = "< " + tabs[_tab] + " >"

	for child in _list.get_children():
		child.queue_free()

	var tab_items: Array = _items[_tab]
	for i in tab_items.size():
		var lbl := Label.new()
		var entry: Dictionary = tab_items[i]
		lbl.text = ("► " if i == _selected else "  ") + entry["label"]
		if not entry.get("available", true):
			lbl.modulate = Color(0.5, 0.5, 0.5)
		_list.add_child(lbl)

	if tab_items.size() > 0:
		var entry: Dictionary = tab_items[_selected]
		var cost: int = entry.get("cost", 0)
		var avail: bool = entry.get("available", true)
		_cost_label.text = "Kosten: " + str(cost) + " Münzen" + ("" if avail else "  [nicht verfügbar]")
	else:
		_cost_label.text = ""
