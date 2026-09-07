extends Node2D

const HOOK_TOP_GROUP: StringName = &"hook_top"
const HOOK_BOTTOM_GROUP: StringName = &"hook_bottom"

@export_group("References")
@export var path_path: NodePath
@export var path_follow_path: NodePath
@export var trigger_path: NodePath
@export var visual_line_path: NodePath

@export_group("Grind")
@export_enum("Upper", "Lower") var hook_side: int = 0
@export_enum("Forward", "Reverse") var grind_direction: int = 0
@export_enum("Match Player", "Fixed Speed", "Fixed Duration") var speed_mode: int = 0
@export var grind_speed: float = 420.0
@export var speed_multiplier: float = 1.0
@export var grind_duration: float = 1.25
@export var trigger_margin: Vector2 = Vector2(56.0, 72.0)

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

	_configure_from_curve()
	call_deferred("_configure_from_curve")

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
	if grind_direction == 1:
		step = -step

	_path_follow.progress = clampf(_path_follow.progress + step, 0.0, _path.curve.get_baked_length())
	_sync_player_to_path()

	if grind_direction == 0 and _path_follow.progress >= _path.curve.get_baked_length():
		_stop_grind(false)
	elif grind_direction == 1 and _path_follow.progress <= 0.0:
		_stop_grind(false)


func _on_trigger_body_entered(body: Node2D) -> void:
	if _grinding:
		return

	var player := body as PlayerRunner
	if player == null or _path == null or _path_follow == null or _path.curve == null or _path.curve.point_count < 2:
		return

	_player = player
	_hook = _resolve_hook(_player)
	if _hook == null:
		return

	_hook_offset = _player.to_local(_hook.global_position)
	_path_follow.progress = _path.curve.get_closest_offset(_path.to_local(_player.global_position))
	_player.begin_grind()
	_grinding = true
	_sync_player_to_path()


func _sync_player_to_path() -> void:
	if _player == null or _path_follow == null:
		return

	_player.global_position = _path_follow.global_position - _hook_offset


func _configure_from_curve() -> void:
	_configure_trigger_from_curve()
	_configure_visual_line_from_curve()


func _configure_trigger_from_curve() -> void:
	if _trigger == null or _path == null or _path.curve == null or _path.curve.point_count < 2:
		return

	var collision := _trigger.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return

	var bounds := _get_curve_bounds(_path.curve)
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision.shape = shape

	var path_scale := _path.scale.abs()
	shape.size = (bounds.size * path_scale) + (trigger_margin * 2.0)
	_trigger.position = _path.position + (bounds.get_center() * _path.scale)
	collision.position = Vector2.ZERO


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


func _get_curve_bounds(curve: Curve2D) -> Rect2:
	var bounds := Rect2(curve.get_point_position(0), Vector2.ZERO)
	for index in range(1, curve.point_count):
		bounds = bounds.expand(curve.get_point_position(index))
	return bounds.abs()


func _get_current_grind_speed() -> float:
	if speed_mode == 1:
		return maxf(grind_speed, 0.0)

	if speed_mode == 2:
		if _path == null or _path.curve == null or grind_duration <= 0.0:
			return maxf(grind_speed, 0.0)
		return _path.curve.get_baked_length() / grind_duration

	if _player == null:
		return maxf(grind_speed, 0.0)

	return maxf(_player.run_speed * speed_multiplier, 0.0)


func _stop_grind(launch_jump: bool) -> void:
	if not _grinding:
		return

	_grinding = false

	if _player == null:
		return

	if launch_jump:
		_player.apply_jump_impulse(_player.jump_velocity)
	else:
		_player.end_grind()

	_player = null
	_hook = null
	_hook_offset = Vector2.ZERO


func _resolve_hook(player: PlayerRunner) -> Node2D:
	var group_name: StringName = HOOK_TOP_GROUP if hook_side == 0 else HOOK_BOTTOM_GROUP
	return player.get_grind_hook(group_name)
