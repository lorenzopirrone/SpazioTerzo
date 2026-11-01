extends Control

@export var level_to_load: PackedScene


func _on_play_button_pressed() -> void:
	if level_to_load == null:
		push_error("Nessun livello assegnato!")
		return

	get_tree().change_scene_to_packed(level_to_load)
