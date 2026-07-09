extends Camera2D

## Nodo target che la camera deve seguire.
@export var target_path: NodePath
## Anticipo orizzontale della camera rispetto al player.
@export var horizontal_lookahead: float = 320.0
## Offset verticale della camera rispetto al player.
@export var vertical_offset: float = -28.0
## Velocità di interpolazione del follow normale.
@export var follow_smoothing: float = 8.0
## Blocca la camera sul bordo sinistro per evitare che torni indietro.
@export var lock_left_edge: bool = true
## Anticipo orizzontale usato mentre il player è in knockback.
@export var damage_horizontal_lookahead: float = 0.0
## Offset verticale usato mentre il player è in knockback.
@export var damage_vertical_offset: float = -20.0
## Velocità di follow usata mentre il player è in knockback.
@export var damage_follow_smoothing: float = 11.0

var _target: Node2D


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D
	make_current()


func _process(delta: float) -> void:
	if _target == null:
		return

	var knockback_active: bool = _target.has_method("is_knockback_active") and _target.is_knockback_active()
	var lookahead := damage_horizontal_lookahead if knockback_active else horizontal_lookahead
	var offset_y := damage_vertical_offset if knockback_active else vertical_offset
	var desired := _target.global_position + Vector2(lookahead, offset_y)

	if lock_left_edge and not knockback_active:
		desired.x = maxf(desired.x, global_position.x)

	var smoothing := damage_follow_smoothing if knockback_active else follow_smoothing
	global_position = global_position.lerp(desired, 1.0 - exp(-smoothing * delta))

