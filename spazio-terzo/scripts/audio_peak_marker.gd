extends Node2D

@export var marker_height: float = 140.0
@export var marker_color: Color = Color(1.0, 0.22, 0.12, 0.9)


func _draw() -> void:
	draw_line(Vector2.ZERO, Vector2(0.0, -marker_height), marker_color, 4.0, true)
	draw_circle(Vector2(0.0, -marker_height), 11.0, marker_color)
