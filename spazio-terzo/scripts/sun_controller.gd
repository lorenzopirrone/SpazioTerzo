@tool
extends Node2D

@export_group("References")
@export var sun1: Node2D
@export var sun2: Node2D
@export var sun3: Node2D
@export var ellipse_center: Node2D
@export var player: Node2D

@export_group("Follow")
@export_range(0.0, 1.0, 0.01) var horizontal_follow: float = 1.0

@export_group("Ellipse")
@export var radius_x: float = 500.0
@export var radius_y: float = 300.0

@export_group("Movement")
@export var start_angle: float = 210.0
@export var end_angle: float = 330.0
@export var stop_angles: Array[float] = [240.0, 270.0, 300.0]
@export var default_move_duration: float = 1.0
@export_group("Sun Transition")
@export_range(0.0, 2.0, 0.05) var sun_fade_duration: float = 0.3

var _current_angle: float = 210.0
var _target_angle: float = 210.0
var _movement_start_angle: float = 210.0
var _movement_duration: float = 1.0
var _movement_elapsed: float = 0.0
var _moving: bool = false
var _active_sun: int = 0
var _sun_start_x: float = 0.0
var _player_start_x: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return

	_current_angle = start_angle
	_target_angle = start_angle

	set_active_sun(0)
	_update_sun_position(_current_angle)
	_sun_start_x = ellipse_center.global_position.x
	if player != null:
		_player_start_x = player.global_position.x


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	
	_update_sun_position(_current_angle)

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

	var ellipse_position := ellipse_center.global_position + Vector2(
		cos(angle) * radius_x,
		sin(angle) * radius_y
		)

	var follow_offset_x := 0.0

	if player != null:
		follow_offset_x = (
			player.global_position.x - _player_start_x
		) * horizontal_follow

	active_sun.global_position = Vector2(
		ellipse_position.x + follow_offset_x,
		ellipse_position.y
	)

func set_active_sun(sun_index: int) -> void:
	sun_index = clampi(sun_index, 0, 2)

	var old_sun: Node2D = null
	var new_sun: Node2D = null

	match _active_sun:
		0:
			old_sun = sun1
		1:
			old_sun = sun2
		2:
			old_sun = sun3

	match sun_index:
		0:
			new_sun = sun1
		1:
			new_sun = sun2
		2:
			new_sun = sun3

	_active_sun = sun_index

	if new_sun == null:
		return

	_update_sun_position(_current_angle)

	if old_sun == new_sun:
		return

	if old_sun != null:
		var old_tween := create_tween()
		old_tween.tween_property(
			old_sun,
			"modulate:a",
			0.0,
			sun_fade_duration
		)

	if new_sun != null:
		new_sun.visible = true
		new_sun.modulate.a = 0.0

		var new_tween := create_tween()
		new_tween.tween_property(
			new_sun,
			"modulate:a",
			1.0,
			sun_fade_duration
		)


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
