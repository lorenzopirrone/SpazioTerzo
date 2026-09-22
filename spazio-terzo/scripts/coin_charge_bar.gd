extends Control


@export_group("References")
@export var fill: ColorRect
@export var player: PlayerRunner


@export_group("Bar Settings")
@export var bar_width: float = 200.0


var current_petals: int = 0


func _ready() -> void:
	if player != null:
		player.petal_collected.connect(set_petals)
		set_petals(player.get_petals())


func set_petals(amount: int) -> void:
	if player == null:
		return

	current_petals = clampi(amount, 0, player.max_petals)

	var progress := float(current_petals) / float(max(player.max_petals, 1))
	progress = clampf(progress, 0.0, 1.0)

	fill.size.x = bar_width * progress
