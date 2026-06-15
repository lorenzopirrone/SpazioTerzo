class_name LevelRoot
extends Node2D

signal level_completed
signal player_died

@export var player_path: NodePath = ^"Player"
@export var death_y: float = 760.0

@export_group("Audio Sync")
@export var audio_stream: AudioStream
@export var manual_track_duration_seconds: float = 0.0
@export var auto_place_finish_line: bool = true
@export var finish_line_path: NodePath = ^"FinishLine"
@export var finish_padding: float = 0.0
@export var audio_player_path: NodePath = ^"AudioStreamPlayer"
@export var peak_times: Array[float] = []
@export var peak_marker_scene: PackedScene
@export var peak_marker_parent_path: NodePath = ^"AudioPeakMarkers"
@export var peak_marker_y: float = 470.0

var player: Node2D


func _ready() -> void:
	player = get_node_or_null(player_path) as Node2D
	if player:
		player.connect("died", _on_player_died)
	_setup_audio_sync()


func _physics_process(_delta: float) -> void:
	if player and player.global_position.y > death_y and player.has_method("take_hit"):
		player.take_hit()


func complete_level() -> void:
	level_completed.emit()


func _on_player_died() -> void:
	player_died.emit()


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

	_create_peak_markers(start_x, player_speed)


func _get_track_duration() -> float:
	if audio_stream and audio_stream.get_length() > 0.0:
		return audio_stream.get_length()
	return manual_track_duration_seconds


func _create_peak_markers(start_x: float, player_speed: float) -> void:
	if peak_marker_scene == null:
		return

	var parent := get_node_or_null(peak_marker_parent_path) as Node2D
	if parent == null:
		parent = self

	for child in parent.get_children():
		child.queue_free()

	for peak_time in peak_times:
		if peak_time < 0.0:
			continue

		var marker := peak_marker_scene.instantiate() as Node2D
		parent.add_child(marker)
		marker.global_position = Vector2(start_x + player_speed * peak_time, peak_marker_y)
