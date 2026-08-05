extends Node2D

@export var alert_duration: float = 0.85
@export var obstacle_speed: float = 620.0
@export var self_destruct_time: float = 4.0

const WARNING_RIGHT_MARGIN := 56.0
const SPAWN_OFFSCREEN_MARGIN := 96.0

@onready var trigger_box: Area2D = $TriggerBox
@onready var warning: Label = $Warning
@onready var obstacle: Area2D = $Obstacle

var _lane_y: float = 0.0
var _camera: Camera2D
var _state: StringName = &"waiting"
var _alert_timer: float = 0.0
var _life_timer: float = 0.0


func _ready() -> void:
	_lane_y = global_position.y
	_camera = get_viewport().get_camera_2d()

	warning.hide()
	obstacle.hide()
	obstacle.monitoring = false
	obstacle.body_entered.connect(_on_obstacle_body_entered)
	obstacle.area_entered.connect(_on_obstacle_area_entered)
	trigger_box.body_entered.connect(_on_trigger_box_body_entered)


func _process(delta: float) -> void:
	if _camera == null:
		_camera = get_viewport().get_camera_2d()

	match _state:
		&"waiting":
			pass
		&"alert":
			_alert_timer -= delta
			_update_warning_position()
			if _alert_timer <= 0.0:
				_launch_obstacle()
		&"moving":
			_life_timer -= delta
			obstacle.global_position.x -= obstacle_speed * delta
			if _life_timer <= 0.0:
				queue_free()


func _on_trigger_box_body_entered(body: Node2D) -> void:
	if _state != &"waiting":
		return
	if not (body is PlayerRunner):
		return
	_start_alert()


func _start_alert() -> void:
	_state = &"alert"
	_alert_timer = maxf(alert_duration, 0.0)
	global_position.y = _lane_y
	_update_warning_position()
	warning.show()


func _launch_obstacle() -> void:
	var spawn_x := _get_spawn_x()
	obstacle.global_position = Vector2(spawn_x, _lane_y)
	obstacle.show()
	obstacle.monitoring = true
	warning.hide()
	_state = &"moving"
	_life_timer = maxf(self_destruct_time, 0.0)


func _update_warning_position() -> void:
	var warning_x := global_position.x
	var warning_y := _lane_y

	if _camera != null:
		var half_width := get_viewport_rect().size.x * 0.5 / _camera.zoom.x
		warning_x = _camera.get_screen_center_position().x + half_width - WARNING_RIGHT_MARGIN

	warning.global_position = Vector2(warning_x, warning_y)


func _get_spawn_x() -> float:
	if _camera != null:
		var half_width := get_viewport_rect().size.x * 0.5 / _camera.zoom.x
		return _camera.get_screen_center_position().x + half_width + SPAWN_OFFSCREEN_MARGIN
	return global_position.x + SPAWN_OFFSCREEN_MARGIN


func _on_obstacle_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()


func _on_obstacle_area_entered(area: Area2D) -> void:
	if area.name == "PunchArea":
		queue_free()
