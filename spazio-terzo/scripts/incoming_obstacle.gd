extends Node2D

@export var speed: float = 560.0
@export var trigger_distance: float = 760.0
@export var warning_time: float = 0.75
@export var spawn_offset_from_camera: float = 90.0
@export var despawn_left_margin: float = 260.0
@export var can_be_punched: bool = true

@onready var warning: Label = $Warning
@onready var missile: Area2D = $Missile

var _trigger_x: float
var _lane_y: float
var _state := "waiting"
var _warning_timer: float = 0.0
var _player: Node2D


func _ready() -> void:
	_trigger_x = global_position.x
	_lane_y = global_position.y
	_player = get_tree().get_first_node_in_group("player") as Node2D
	warning.hide()
	missile.hide()
	missile.monitoring = false
	missile.body_entered.connect(_on_missile_body_entered)
	missile.area_entered.connect(_on_missile_area_entered)


func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return

	match _state:
		"waiting":
			if _player.global_position.x >= _trigger_x - trigger_distance:
				_start_warning()
		"warning":
			_follow_camera_edge()
			_warning_timer -= delta
			if _warning_timer <= 0.0:
				_launch()
		"launched":
			global_position.x -= speed * delta
			var camera := get_viewport().get_camera_2d()
			var left_edge := _player.global_position.x - despawn_left_margin
			if camera:
				left_edge = camera.get_screen_center_position().x - (get_viewport_rect().size.x * 0.5 / camera.zoom.x) - despawn_left_margin
			if global_position.x < left_edge:
				queue_free()


func _start_warning() -> void:
	_state = "warning"
	_warning_timer = warning_time
	global_position.y = _lane_y
	_follow_camera_edge()
	warning.show()


func _follow_camera_edge() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera:
		global_position.x = camera.get_screen_center_position().x + (get_viewport_rect().size.x * 0.5 / camera.zoom.x) - 72.0
	else:
		global_position.x = _player.global_position.x + trigger_distance


func _launch() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera:
		global_position.x = camera.get_screen_center_position().x + (get_viewport_rect().size.x * 0.5 / camera.zoom.x) + spawn_offset_from_camera
	else:
		global_position.x = _player.global_position.x + trigger_distance

	warning.hide()
	missile.show()
	missile.monitoring = true
	_state = "launched"


func _on_missile_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()


func _on_missile_area_entered(area: Area2D) -> void:
	if can_be_punched and area.name == "PunchArea":
		queue_free()
