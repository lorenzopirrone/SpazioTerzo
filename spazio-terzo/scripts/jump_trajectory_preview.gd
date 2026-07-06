@tool
extends Node2D

@export var preview_time: float = 0.95:
	set(value):
		preview_time = value
		queue_redraw()
@export var step_time: float = 0.06:
	set(value):
		step_time = value
		queue_redraw()
@export var line_color: Color = Color(1.0, 0.85, 0.2, 0.85):
	set(value):
		line_color = value
		queue_redraw()
@export var point_radius: float = 4.0:
	set(value):
		point_radius = value
		queue_redraw()


func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()
		set_process(false)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var player := get_parent()
	if player == null:
		return

	var run_speed := float(player.get("run_speed"))
	var jump_velocity := float(player.get("jump_velocity"))
	var gravity := float(player.get("gravity"))
	var max_fall_speed := float(player.get("max_fall_speed"))
	var points: PackedVector2Array = []
	var t := 0.0
	var position := Vector2.ZERO
	var velocity := Vector2(0.0, jump_velocity)

	while t <= preview_time:
		points.append(position)
		var delta := maxf(step_time, 0.01)
		velocity.x = run_speed
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
		position += velocity * delta
		t += maxf(step_time, 0.01)

	if points.size() < 2:
		return

	draw_polyline(points, line_color, 3.0, true)
	for point in points:
		draw_circle(point, point_radius, line_color)
