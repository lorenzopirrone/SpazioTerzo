extends Control


@export_group("References")
@export var player: PlayerRunner
@export var score_count: Label


func _ready() -> void:
	if player != null:
		player.score_changed.connect(_update_score)
		_update_score(player.get_score())


func _update_score(amount: int) -> void:
	score_count.text = str(amount)


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
