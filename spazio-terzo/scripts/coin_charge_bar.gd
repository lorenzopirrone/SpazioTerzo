extends Control


@export_group("References")
@export var fill: ColorRect
@export var ghost_fill: ColorRect
@export var player: PlayerRunner


@export_group("Bar Settings")
@export var bar_width: float = 200.0
@export var ghost_speed: float = 100.0


var current_petals: int = 0
var _ghost_width: float = 0.0


func _ready() -> void:
	if player != null:
		player.petal_collected.connect(set_petals)
		set_petals(player.get_petals())
	
	_ghost_width = fill.size.x


func set_petals(amount: int) -> void:
	if player == null:
		return

	var new_petals := clampi(amount, 0, player.max_petals)

	var progress := float(new_petals) / float(max(player.max_petals, 1))
	progress = clampf(progress, 0.0, 1.0)

	var new_width := bar_width * progress

	# La barra reale si aggiorna immediatamente.
	fill.size.x = new_width

	# Se abbiamo perso petali, la ghost bar rimane al valore precedente.
	if new_width >= _ghost_width:
		_ghost_width = new_width

func _process(delta: float) -> void:
	if ghost_fill == null:
		return

	_ghost_width = move_toward(
		_ghost_width,
		fill.size.x,
		ghost_speed * delta
	)

	ghost_fill.size.x = _ghost_width
