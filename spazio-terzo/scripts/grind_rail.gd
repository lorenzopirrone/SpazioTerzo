extends Node2D


@export_group("References")
@export var path_path: NodePath
@export var path_follow_path: NodePath
@export var trigger_path: NodePath
@export var visual_line_path: NodePath

@export_group("Grind")
@export var speed_multiplier: float = 1.0

var _player: PlayerRunner
var _hook: Node2D
var _path: Path2D
var _path_follow: PathFollow2D
var _trigger: Area2D
var _visual_line: Line2D
var _grinding: bool = false
var _hook_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_path = get_node_or_null(path_path) as Path2D
	_path_follow = get_node_or_null(path_follow_path) as PathFollow2D
	_trigger = get_node_or_null(trigger_path) as Area2D
	_visual_line = get_node_or_null(visual_line_path) as Line2D

	if _path_follow:
		_path_follow.loop = false

	_configure_visual_line_from_curve()
	call_deferred("_configure_visual_line_from_curve")

	if _trigger:
		_trigger.body_entered.connect(_on_trigger_body_entered)


func _physics_process(delta: float) -> void:
	if not _grinding:
		return
	if _player == null or not _player.is_grinding():
		_stop_grind(false)
		return
	if _path == null or _path_follow == null or _path.curve == null or _path.curve.point_count < 2:
		_stop_grind(false)
		return

	if Input.is_action_just_pressed("runner_jump"):
		_stop_grind(true)
		return

	var step := _get_current_grind_speed() * delta

	_path_follow.progress = clampf(
	_path_follow.progress + step,
	0.0,
	_path.curve.get_baked_length()
	)

	_sync_player_to_path()

	if _path_follow.progress >= _path.curve.get_baked_length():
		_stop_grind(false)


func _on_trigger_body_entered(body: Node2D) -> void:
	if _grinding:
		return

	var player := body as PlayerRunner
	if player == null or _path == null or _path_follow == null or _path.curve == null or _path.curve.point_count < 2:
		return

	_player = player

	if _player.grind_hook_front == null or _player.grind_hook_back == null:
		return
	_path_follow.progress = _path.curve.get_closest_offset(_path.to_local(_player.global_position))
	_player.begin_grind()
	_grinding = true
	_sync_player_to_path()


func _sync_player_to_path() -> void:
	if _player == null or _path_follow == null:
		return
	if _player.grind_hook_front == null or _player.grind_hook_back == null:
		return

	_player.global_rotation = _path_follow.global_rotation

	var hook_center := (
	_player.grind_hook_front.global_position
	+ _player.grind_hook_back.global_position
) * 0.5

	var center_offset := hook_center - _player.global_position

	_player.global_position = (
		_path_follow.global_position
		- center_offset
)




func _configure_visual_line_from_curve() -> void:
	if _visual_line == null or _path == null or _path.curve == null or _path.curve.point_count < 2:
		return

	var baked_points := _path.curve.get_baked_points()
	if baked_points.is_empty():
		return

	var points := PackedVector2Array()
	points.resize(baked_points.size())
	for index in range(baked_points.size()):
		points[index] = _path.position + (baked_points[index] * _path.scale)

	_visual_line.position = Vector2.ZERO
	_visual_line.points = points





func _get_current_grind_speed() -> float:
	if _player == null:
		return 0.0

	return maxf(_player.run_speed * speed_multiplier, 0.0)


func _stop_grind(launch_jump: bool) -> void:
	print("STOP GRIND chiamato")

	if not _grinding:
		print("STOP: _grinding era false")
		return

	_grinding = false

	if _player == null:
		print("STOP: _player è NULL")
		return

	print("STOP: player trovato, launch_jump = ", launch_jump)

	if launch_jump:
		_player.apply_jump_impulse(_player.jump_velocity)
	else:
		_player.end_grind()

	_player.global_rotation = 0.0


func _resolve_hooks(player: PlayerRunner) -> Array[Node2D]:
	return [
		player.grind_hook_back,
		player.grind_hook_front
	]
