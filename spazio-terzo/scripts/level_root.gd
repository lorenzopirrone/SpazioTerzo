class_name LevelRoot
extends Node2D

signal level_completed
signal player_died

## Percorso del nodo player dentro la scena livello.
@export var player_path: NodePath = ^"Player"
## Quota verticale sotto la quale il player viene considerato morto.
@export var death_y: float = 760.0

@export_group("Audio Sync")
## Traccia audio associata al livello corrente.
@export var audio_stream: AudioStream
## Durata manuale da usare se la traccia non è disponibile o non viene letta.
@export var manual_track_duration_seconds: float = 0.0
## Se attivo, la finish line viene piazzata automaticamente in base alla durata audio.
@export var auto_place_finish_line: bool = true
## Nodo della finish line da posizionare automaticamente.
@export var finish_line_path: NodePath = ^"FinishLine"
## Spazio extra aggiunto alla fine del livello rispetto alla traccia audio.
@export var finish_padding: float = 0.0
## Nodo AudioStreamPlayer che riproduce la traccia del livello.
@export var audio_player_path: NodePath = ^"AudioStreamPlayer"

@export_group("UI References")
@export var pause_panel: Panel
@export var guaglio_theme: AudioStreamPlayer
@export_file("*.tscn") var main_menu_scene: String
@export var pause_animation: AnimatedSprite2D
@export var result_screen: Control

@export_group("Result Screen References")
@export var score_value_label: Label
@export var petals_value_label: Label
@export var distance_value_label: Label
@export var multiplier_label: Label
@export var result_title_label: Label
@export var result_restart_button: Button
@export var result_quit_button: Button

var player: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_node_or_null(player_path) as Node2D
	if player:
		_apply_player_spawn_point()
		player.connect("died", _on_player_died)
	_setup_audio_sync()
	if result_restart_button != null:
		result_restart_button.pressed.connect(_on_restart_button_pressed)

	if result_quit_button != null:
		result_quit_button.pressed.connect(_on_quit_button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_on_restart_button_pressed()


func _physics_process(_delta: float) -> void:
	if player and player.global_position.y > death_y and player.has_method("take_hit"):
		player.take_hit()


func complete_level() -> void:
	level_completed.emit()
	_show_final_score()

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused

	if get_tree().paused:
		guaglio_theme.stream_paused = true
	else:
		guaglio_theme.stream_paused = false

	_update_pause_menu()


func _update_pause_menu() -> void:
	pause_panel.visible = get_tree().paused
	
	if get_tree().paused:
		pause_animation.play()
	else:
		pause_animation.stop()

func _on_player_died() -> void:
	player_died.emit()

	get_tree().paused = true

	if result_screen == null or player == null:
		return

	result_title_label.text = "GAME OVER"
	score_value_label.text = str(player.get_score())
	petals_value_label.text = str(player.get_petals())
	distance_value_label.text = str(int(player.get_score_distance()))
	multiplier_label.text = "x" + str(player.get_score_multiplier())

	result_screen.visible = true





func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	call_deferred("_restart_current_scene")


func _restart_current_scene() -> void:
	get_tree().reload_current_scene()


func _setup_audio_sync() -> void:
	var duration := _get_track_duration()
	if duration <= 0.0:
		return

	var player_speed := float(player.get("run_speed"))
	var start_x := player.global_position.x
	if auto_place_finish_line:
		var finish_line := get_node_or_null(finish_line_path) as Node2D
		if finish_line:
			finish_line.global_position.x = start_x + player_speed * duration + finish_padding

	var audio_player := get_node_or_null(audio_player_path) as AudioStreamPlayer
	if audio_player and audio_stream:
		audio_player.stream = audio_stream
		audio_player.play()


func _apply_player_spawn_point() -> void:
	var spawn_points := get_tree().get_nodes_in_group("player_spawn_point")
	if spawn_points.is_empty():
		return

	var spawn_point := spawn_points[0] as Node2D
	if spawn_point:
		player.global_position = spawn_point.global_position
		var camera := get_node_or_null(^"RunnerCamera") as Camera2D
		if camera and camera.has_method("snap_to_target"):
			camera.snap_to_target()


func _get_track_duration() -> float:
	if audio_stream and audio_stream.get_length() > 0.0:
		return audio_stream.get_length()
	return manual_track_duration_seconds


func _on_pause_button_pressed() -> void:
	toggle_pause()
	


func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	guaglio_theme.stream_paused = false
	_update_pause_menu()


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene)


func _show_final_score() -> void:
	if result_screen == null or player == null:
		return

	get_tree().paused = true
	result_screen.visible = true

	result_title_label.text = "LEVEL COMPLETE"
	score_value_label.text = str(player.get_score())
	petals_value_label.text = str(player.get_petals())
	distance_value_label.text = str(int(player.get_score_distance()))
	multiplier_label.text = "x" + str(player.get_score_multiplier())
