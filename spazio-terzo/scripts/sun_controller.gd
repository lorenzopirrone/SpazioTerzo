@tool
extends Node2D

@export_group("References")
@export var sun1: Node2D
@export var sun2: Node2D
@export var sun3: Node2D
@export var ellipse_center: Node2D

@export_group("Ellipse")
@export var radius_x: float = 500.0
@export var radius_y: float = 300.0

@export_group("Movement")
@export var start_angle: float = 210.0
@export var end_angle: float = 330.0
@export var stop_angles: Array[float] = [240.0, 270.0, 300.0]
@export var default_move_duration: float = 1.0

var _current_angle: float = 210.0
var _target_angle: float = 210.0
var _movement_start_angle: float = 210.0
var _movement_duration: float = 1.0
var _movement_elapsed: float = 0.0
var _moving: bool = false
var _active_sun: int = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return

	_current_angle = start_angle
	_target_angle = start_angle

	set_active_sun(0)
	_update_sun_position(_current_angle)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return

	if not _moving:
		return

	_movement_elapsed += delta

	var progress := clampf(
		_movement_elapsed / _movement_duration,
		0.0,
		1.0
	)

	_current_angle = lerpf(
		_movement_start_angle,
		_target_angle,
		progress
	)

	_update_sun_position(_current_angle)

	if progress >= 1.0:
		_current_angle = _target_angle
		_update_sun_position(_current_angle)
		_moving = false


func move_to_stop(stop_index: int, move_duration: float = -1.0) -> void:
	if stop_index < 0 or stop_index >= stop_angles.size():
		return

	_movement_start_angle = _current_angle
	_target_angle = stop_angles[stop_index]

	if move_duration > 0.0:
		_movement_duration = move_duration
	else:
		_movement_duration = default_move_duration

	_movement_elapsed = 0.0
	_moving = true


func move_to_end(move_duration: float = -1.0) -> void:
	_movement_start_angle = _current_angle
	_target_angle = end_angle

	if move_duration > 0.0:
		_movement_duration = move_duration
	else:
		_movement_duration = default_move_duration

	_movement_elapsed = 0.0
	_moving = true


func _update_sun_position(angle_degrees: float) -> void:
	if ellipse_center == null:
		return

	var active_sun: Node2D = null

	match _active_sun:
		0:
			active_sun = sun1
		1:
			active_sun = sun2
		2:
			active_sun = sun3

	if active_sun == null:
		return

	var angle := deg_to_rad(angle_degrees)

	active_sun.global_position = ellipse_center.global_position + Vector2(
		cos(angle) * radius_x,
		sin(angle) * radius_y
	)

func set_active_sun(sun_index: int) -> void:
	_active_sun = clampi(sun_index, 0, 2)

	if sun1 != null:
		sun1.visible = _active_sun == 0

	if sun2 != null:
		sun2.visible = _active_sun == 1

	if sun3 != null:
		sun3.visible = _active_sun == 2

	_update_sun_position(_current_angle)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	if ellipse_center == null:
		return

	var center := to_local(ellipse_center.global_position)

	var points := PackedVector2Array()

	# Arco principale
	for i in range(101):
		var t := float(i) / 100.0
		var angle := deg_to_rad(
			lerpf(start_angle, end_angle, t)
		)

		var point := center + Vector2(
			cos(angle) * radius_x,
			sin(angle) * radius_y
		)

		points.append(point)

	draw_polyline(points, Color.RED, 4.0)

	# Start
	var start_rad := deg_to_rad(start_angle)
	var start_point := center + Vector2(
		cos(start_rad) * radius_x,
		sin(start_rad) * radius_y
	)

	draw_circle(start_point, 10.0, Color.GREEN)

	# End
	var end_rad := deg_to_rad(end_angle)
	var end_point := center + Vector2(
		cos(end_rad) * radius_x,
		sin(end_rad) * radius_y
	)

	draw_circle(end_point, 10.0, Color.RED)

	# Centro
	draw_circle(center, 8.0, Color.YELLOW)

	# Stop
	for stop_angle in stop_angles:
		var stop_rad := deg_to_rad(stop_angle)

		var stop_point := center + Vector2(
			cos(stop_rad) * radius_x,
			sin(stop_rad) * radius_y
		)

		draw_circle(stop_point, 7.0, Color.WHITE)
