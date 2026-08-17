extends Node2D


func _ready() -> void:
	var rail := $GrindRail as Node2D
	var path := rail.get_node("Path") as Path2D
	var curve := Curve2D.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(140, 0))
	curve.add_point(Vector2(240, -34))
	curve.add_point(Vector2(340, 0))
	curve.add_point(Vector2(440, 28))
	curve.add_point(Vector2(560, 0))
	path.curve = curve
