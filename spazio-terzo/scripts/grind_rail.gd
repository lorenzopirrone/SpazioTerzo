extends Node2D

@export_group("References")
@export var player_path: NodePath
@export var path_path: NodePath
@export var path_follow_path: NodePath
@export var trigger_path: NodePath

@export_group("Grind")
@export var grind_speed: float = 420.0
@export var jump_vertical_velocity: float = -560.0
@export var jump_horizontal_boost: float = 110.0
@export var start_progress: float = 0.0
@export var follow_rotates_with_path: bool = true
@export var auto_generate_demo_curve: bool = true
@export var demo_curve_start: Vector2 = Vector2.ZERO
@export var demo_curve_end: Vector2 = Vector2(360.0, 0.0)

var _player: PlayerRunner
var _path: Path2D
var _path_follow: PathFollow2D
var _trigger: Area2D
var _path_length: float = 0.0
var _grinding: bool = false


func _ready() -> void:
	_player = get_node_or_null(player_path) as PlayerRunner
	_path = get_node_or_null(path_path) as Path2D
	_path_follow = get_node_or_null(path_follow_path) as PathFollow2D
	_trigger = get_node_or_null(trigger_path) as Area2D

	_setup_curve()
	_setup_follow()
	_setup_trigger()


func _physics_process(delta: float) -> void:
	if not _grinding:
		return
	if _player == null or _path_follow == null:
		_stop_grind(false)
		return
	if not _player.is_grinding():
		_stop_grind(false)
		return

	if Input.is_action_just_pressed("runner_jump"):
		_stop_grind(true)
		return

	_path_follow.progress = minf(_path_follow.progress + grind_speed * delta, _path_length)
	_sync_player_to_follow()

	if _path_length > 0.0 and _path_follow.progress >= _path_length - 0.001:
		_stop_grind(false)


func _setup_curve() -> void:
	if _path == null or _path.curve == null:
		return

	if _path.curve.point_count < 2 and auto_generate_demo_curve:
		_path.curve.clear_points()
		_path.curve.add_point(demo_curve_start)
		_path.curve.add_point(demo_curve_end)

	_path_length = _path.curve.get_baked_length()


func _setup_follow() -> void:
	if _path_follow == null:
		return

	_path_follow.loop = false
	_path_follow.rotates = follow_rotates_with_path
	_sync_player_to_follow()


func _setup_trigger() -> void:
	if _trigger == null:
		return

	_trigger.body_entered.connect(_on_trigger_body_entered)


func _on_trigger_body_entered(body: Node2D) -> void:
	if _grinding:
		return
	if body != _player:
		return
	if _player == null or _path_follow == null:
		return

	_grinding = true
	_player.begin_grind()
	_path_follow.progress = clampf(start_progress, 0.0, _path_length)
	_sync_player_to_follow()


func _stop_grind(apply_jump: bool) -> void:
	if not _grinding:
		return

	_grinding = false

	if _player == null:
		return

	if apply_jump:
		_player.launch_from_grind(jump_vertical_velocity, jump_horizontal_boost)
	else:
		_player.end_grind()


func _sync_player_to_follow() -> void:
	if _player == null or _path_follow == null:
		return

	_player.global_position = _path_follow.global_position
	if follow_rotates_with_path:
		_player.global_rotation = _path_follow.global_rotation
