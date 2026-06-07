extends Camera2D

@export var target_path: NodePath
@export var horizontal_lookahead: float = 320.0
@export var vertical_offset: float = -28.0
@export var follow_smoothing: float = 8.0
@export var lock_left_edge: bool = true

var _target: Node2D


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D
	make_current()


func _process(delta: float) -> void:
	if _target == null:
		return

	var desired := _target.global_position + Vector2(horizontal_lookahead, vertical_offset)
	if lock_left_edge:
		desired.x = maxf(desired.x, global_position.x)

	global_position = global_position.lerp(desired, 1.0 - exp(-follow_smoothing * delta))
