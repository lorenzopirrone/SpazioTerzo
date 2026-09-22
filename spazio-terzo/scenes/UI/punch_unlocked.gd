extends Node2D


@export_group("References")
@export var player: PlayerRunner
@export var animation_player: AnimationPlayer
@export var flames: AnimatedSprite2D
@export var Flower: Sprite2D




var _punch_unlocked: bool = false


func _ready() -> void:
	visible = false

	if player != null:
		player.petal_collected.connect(_update_punch_unlock)
		_update_punch_unlock(player.get_petals())


func _update_punch_unlock(petals: int) -> void:
	var should_be_unlocked := petals >= player.punch_unlock_petals

	if should_be_unlocked == _punch_unlocked:
		return

	_punch_unlocked = should_be_unlocked

	if _punch_unlocked:
		_activate_punch_unlock()
	else:
		_deactivate_punch_unlock()


func _activate_punch_unlock() -> void:
	visible = true

	if flames != null:
		flames.play()

	if animation_player != null:
		animation_player.play("Explosion animation")


func _deactivate_punch_unlock() -> void:
	visible = false

	if flames != null:
		flames.stop()
