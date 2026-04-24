extends Control


func _draw() -> void:
	var center := size / 2
	var color := Color(0.4, 0.9, 0.85, 0.85)
	draw_line(center - Vector2(7, 0), center + Vector2(7, 0), color, 2.0)
	draw_line(center - Vector2(0, 7), center + Vector2(0, 7), color, 2.0)
	draw_circle(center, 1.5, color)
