extends Node2D

const HOOK_TOP_GROUP: StringName = &"hook_top"
const HOOK_BOTTOM_GROUP: StringName = &"hook_bottom"

@export_group("References")
@export var path_path: NodePath
@export var path_follow_path: NodePath
@export var trigger_path: NodePath

@export_group("Grind")
@export_enum("Upper", "Lower") var hook_side: int = 0
@export_enum("Forward", "Reverse") var grind_direction: int = 0
@export var grind_speed: float = 420.0
@export var jump_vertical_velocity: float = -560.0
@export var jump_horizontal_boost: float = 110.0
@export var start_progress: float = 0.0
@export var follow_rotates_with_path: bool = true
@export var auto_generate_demo_curve: bool = true
@export var demo_curve_points: Array[Vector2] = [
	Vector2.ZERO,
	Vector2(120.0, 0.0),
	Vector2(240.0, -36.0),
	Vector2(360.0, 0.0),
]

var _player: PlayerRunner
var _hook: Node2D
var _path: Path2D
var _path_follow: PathFollow2D
var _trigger: Area2D
var _path_length: float = 0.0
var _grinding: bool = false
var _hook_local_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_path = get_node_or_null(path_path) as Path2D
	_path_follow = get_node_or_null(path_follow_path) as PathFollow2D
	_trigger = get_node_or_null(trigger_path) as Area2D

	_setup_curve()
	_setup_follow()
	_setup_trigger()


func _physics_process(delta: float) -> void:
	if not _grinding:
		return
	if _player == null or _path_follow == null or not _player.is_grinding():
		_stop_grind(false)
		return

	if Input.is_action_just_pressed("runner_jump"):
		_stop_grind(true)
		return

	var direction_sign := 1.0 if grind_direction == 0 else -1.0
	_path_follow.progress = clampf(_path_follow.progress + (grind_speed * delta * direction_sign), 0.0, _path_length)
	_sync_player_to_follow()

	if _path_length > 0.0:
		if grind_direction == 0 and _path_follow.progress >= _path_length - 0.001:
			_stop_grind(false)
		elif grind_direction == 1 and _path_follow.progress <= 0.001:
			_stop_grind(false)


func _setup_curve() -> void:
	if _path == null:
		return

	if _path.curve == null:
		_path.curve = Curve2D.new()

	if _path.curve.point_count < 2 and auto_generate_demo_curve and demo_curve_points.size() >= 2:
		_path.curve.clear_points()
		for point in demo_curve_points:
			_path.curve.add_point(point)

	_path_length = _path.curve.get_baked_length()


func _setup_follow() -> void:
	if _path_follow == null:
		return

	_path_follow.loop = false
	_path_follow.rotates = follow_rotates_with_path


func _setup_trigger() -> void:
	if _trigger == null:
		return

	_trigger.body_entered.connect(_on_trigger_body_entered)


func _on_trigger_body_entered(body: Node2D) -> void:
	if _grinding:
		return

	var player := body as PlayerRunner
	if player == null or _path_follow == null:
		return

	_player = player
	_hook = _resolve_hook(_player)
	if _hook == null:
		return

	_hook_local_offset = _player.to_local(_hook.global_position)
	_grinding = true
	_player.begin_grind()

	var clamped_start := clampf(start_progress, 0.0, _path_length)
	_path_follow.progress = clamped_start if grind_direction == 0 else maxf(_path_length - clamped_start, 0.0)
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

	_player = null
	_hook = null
	_hook_local_offset = Vector2.ZERO


func _sync_player_to_follow() -> void:
	if _player == null or _path_follow == null:
		return

	if follow_rotates_with_path:
		_player.global_rotation = _path_follow.global_rotation

	var hook_world_offset := _player.global_transform * _hook_local_offset
	_player.global_position = _path_follow.global_position - hook_world_offset


func _resolve_hook(player: PlayerRunner) -> Node2D:
	var requested_group: StringName = HOOK_TOP_GROUP if hook_side == 0 else HOOK_BOTTOM_GROUP
	var fallback_group: StringName = HOOK_BOTTOM_GROUP if hook_side == 0 else HOOK_TOP_GROUP

	if player.has_method("get_grind_hook"):
		var hook := player.get_grind_hook(requested_group)
		if hook != null:
			return hook
		hook = player.get_grind_hook(fallback_group)
		if hook != null:
			return hook
		return null

	var found := _find_node_in_group_recursive(player, requested_group)
	if found == null:
		found = _find_node_in_group_recursive(player, fallback_group)
	return found as Node2D


func _find_node_in_group_recursive(root: Node, group_name: StringName) -> Node:
	if root.is_in_group(group_name):
		return root

	for child in root.get_children():
		var found := _find_node_in_group_recursive(child, group_name)
		if found != null:
			return found

	return null
