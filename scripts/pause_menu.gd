extends CanvasLayer

var _player: CharacterBody2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_player = get_parent().get_node_or_null("Player")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if visible:
			_resume()
		elif _player == null or not _player.input_blocked:
			_show_pause()

func _show_pause() -> void:
	visible = true
	get_tree().paused = true

func _resume() -> void:
	visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	_resume()

func _on_main_menu_pressed() -> void:
	pass
