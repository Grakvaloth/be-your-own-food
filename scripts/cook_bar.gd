extends Node2D

var value := 0.0
var max_value := 10.0
var bar_color := Color.WHITE

const W := 60.0
const H := 7.0
const OX := -30.0
const OY := 30.0

func _draw() -> void:
	draw_rect(Rect2(OX, OY, W, H), Color(0.15, 0.15, 0.15))
	var fill := W * clampf(value / max_value, 0.0, 1.0)
	if fill > 0.0:
		draw_rect(Rect2(OX, OY, fill, H), bar_color)

func update_bar(v: float, color: Color, max_v: float = -1.0) -> void:
	value = v
	bar_color = color
	if max_v > 0.0:
		max_value = max_v
	queue_redraw()
