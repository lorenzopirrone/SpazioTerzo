extends Control

@export_group("References")
@export var player: PlayerRunner
@export var coin_count: Label


func _ready() -> void:
	if player != null:
		player.coin_collected.connect(_update_coin_count)
		_update_coin_count(player.get_coins())


func _update_coin_count(amount: int) -> void:
	coin_count.text = str(amount)


func _on_button_pressed() -> void:
	pass # Replace with function body.


func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	_update_pause_button()


func _update_pause_button() -> void:
	if get_tree().paused:
		$LevelUI/UI/PauseButton.text = "Resume"
	else:
		$LevelUI/UI/PauseButton.text = "Pause"
