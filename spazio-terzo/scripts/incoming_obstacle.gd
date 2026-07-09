extends Node2D

## Velocità con cui l'ostacolo entra da destra verso sinistra.
@export var speed: float = 560.0
## Distanza dalla camera a cui il trigger attiva il warning.
@export var trigger_distance: float = 760.0
## Tempo di preavviso visivo prima che l'ostacolo arrivi.
@export var warning_time: float = 0.75
## Tempo stimato tra warning e impatto effettivo.
@export var travel_time_to_impact: float = 0.95
## Distanza laterale iniziale dello spawn rispetto alla camera.
@export var spawn_offset_from_camera: float = 90.0
## Margine oltre il quale l'ostacolo viene rimosso a sinistra.
@export var despawn_left_margin: float = 260.0
## Consente o meno di colpire l'ostacolo con il cazzotto.
@export var can_be_punched: bool = true
## Distanza dal bordo destro in cui compare il punto esclamativo rosso.
@export var warning_right_margin: float = 56.0
## Offset verticale del warning rispetto alla posizione dell'ostacolo.
@export var warning_vertical_offset: float = -86.0

@onready var trigger_box: Area2D = $TriggerBox
@onready var impact_point: Marker2D = $ImpactPoint
@onready var warning: Label = $Warning
@onready var missile: Area2D = $Missile

var _trigger_x: float
var _lane_y: float
var _state := "waiting"
var _warning_timer: float = 0.0
var _travel_timer: float = 0.0
var _launch_speed: float = 0.0
var _player: Node2D


func _ready() -> void:
	_trigger_x = global_position.x
	_lane_y = global_position.y
	_player = get_tree().get_first_node_in_group("player") as Node2D
	warning.hide()
	trigger_box.body_entered.connect(_on_trigger_box_body_entered)
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
			pass
		"warning":
			_update_warning_position()
			_warning_timer -= delta
			if _warning_timer <= 0.0:
				_launch()
		"launched":
			_travel_timer += delta
			global_position.x -= _launch_speed * delta
			if global_position.x <= impact_point.global_position.x:
				global_position.x = impact_point.global_position.x
				if _travel_timer >= travel_time_to_impact:
					queue_free()


func _start_warning() -> void:
	_state = "warning"
	_warning_timer = warning_time
	global_position.y = _lane_y
	_update_warning_position()
	warning.show()


func _launch() -> void:
	var spawn_x := _get_spawn_x()
	var impact_x := impact_point.global_position.x
	global_position.x = spawn_x
	_launch_speed = absf(spawn_x - impact_x) / maxf(travel_time_to_impact, 0.01)
	_travel_timer = 0.0
	warning.hide()
	missile.show()
	missile.monitoring = true
	_state = "launched"


func _update_warning_position() -> void:
	var camera := get_viewport().get_camera_2d()
	var warning_x := global_position.x
	var warning_y := _lane_y + warning_vertical_offset

	if camera:
		var half_width := get_viewport_rect().size.x * 0.5 / camera.zoom.x
		warning_x = camera.get_screen_center_position().x + half_width - warning_right_margin

	warning.global_position = Vector2(warning_x, warning_y)


func _on_trigger_box_body_entered(body: Node2D) -> void:
	if _state != "waiting":
		return
	if body.has_method("take_hit"):
		_start_warning()


func _get_spawn_x() -> float:
	var camera := get_viewport().get_camera_2d()
	if camera:
		return camera.get_screen_center_position().x + (get_viewport_rect().size.x * 0.5 / camera.zoom.x) + spawn_offset_from_camera
	return _player.global_position.x + trigger_distance


func _on_missile_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()


func _on_missile_area_entered(area: Area2D) -> void:
	if can_be_punched and area.name == "PunchArea":
		queue_free()
