extends Control


@export_group("References")
@export var player: PlayerRunner
@export var petal_count: Label


func _ready() -> void:
	if player != null:
		player.petal_collected.connect(_update_petal_count)
		_update_petal_count(player.get_petals())


func _update_petal_count(amount: int) -> void:
	petal_count.text = str(amount)


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
