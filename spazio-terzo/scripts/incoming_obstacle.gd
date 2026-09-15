extends Node2D

@export_group("Destroy Effect")
## Tutte le parti grafiche che compongono l'ostacolo.
@export var parts: Array[Sprite2D] = []

## Durata dell'effetto di distruzione.
@export var effect_duration: float = 0.35

## Quanto diventano grandi le parti prima di sparire.
@export var effect_scale: float = 2.0

## Quanto si allontanano le parti.
@export var effect_distance: float = 120.0

## Quanti gradi ruotano durante l'effetto.
@export var effect_rotation: float = 180.0

@export var can_be_punched: bool = true
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
var _destroying: bool = false

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
	if area.name == "PunchArea" and not _destroying:
		_destroying = true

		obstacle.get_node("CollisionShape2D").set_deferred("disabled", true)

		_play_destroy_effect()


func _play_destroy_effect() -> void:
	if parts.is_empty():
		queue_free()
		return

	var tween := create_tween()
	tween.set_parallel()

	for i in parts.size():
		var part := parts[i]

		if part == null:
			continue

		var direction := Vector2.from_angle(
			lerpf(
				-PI * 0.85,
				-PI * 0.15,
				float(i) / max(parts.size() - 1, 1)
			)
		)

		var target_position := part.position + direction * effect_distance
		var target_scale := part.scale * effect_scale
		var target_rotation := part.rotation + deg_to_rad(effect_rotation)

		tween.tween_property(
			part,
			"position",
			target_position,
			effect_duration
		)

		tween.tween_property(
			part,
			"scale",
			target_scale,
			effect_duration
		)

		tween.tween_property(
			part,
			"rotation",
			target_rotation,
			effect_duration
		)

		tween.tween_property(
			part,
			"modulate:a",
			0.0,
			effect_duration
		)

	tween.set_parallel(false)
	tween.tween_callback(queue_free)
