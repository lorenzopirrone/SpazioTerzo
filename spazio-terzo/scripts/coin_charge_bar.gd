extends Control

@export_group("Coin Settings")
@export var required_coins: int = 10

@export_group("References")
@export var fill: ColorRect
@export var player: PlayerRunner


@export_group("Bar Settings")
@export var bar_width: float = 200.0

var current_coins: int = 0
func _ready() -> void:
	if player != null:
		player.coin_collected.connect(set_coins)
		set_coins(player.get_coins())

func set_coins(amount: int) -> void:
	current_coins = max(amount, 0)

	var progress := float(current_coins) / float(max(required_coins, 1))
	progress = clampf(progress, 0.0, 1.0)

	fill.size.x = bar_width * progress
