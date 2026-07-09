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

var player: Node2D
var _game_over_layer: CanvasLayer
var _game_over_screen: Control
var _restart_button: Button
var _hud_layer: CanvasLayer
var _coin_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_node_or_null(player_path) as Node2D
	if player:
		player.connect("died", _on_player_died)
		if player.has_signal("coin_collected"):
			player.connect("coin_collected", _on_coin_collected)
	_build_game_over_ui()
	_build_hud_ui()
	_setup_audio_sync()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_on_restart_button_pressed()


func _physics_process(_delta: float) -> void:
	if player and player.global_position.y > death_y and player.has_method("take_hit"):
		player.take_hit()


func complete_level() -> void:
	level_completed.emit()


func _on_player_died() -> void:
	player_died.emit()
	get_tree().paused = true
	_game_over_screen.show()


func _on_coin_collected(total_coins: int) -> void:
	if _coin_label:
		_coin_label.text = str(total_coins)


func _build_game_over_ui() -> void:
	_game_over_layer = CanvasLayer.new()
	_game_over_layer.name = "GameOverLayer"
	_game_over_layer.layer = 20
	_game_over_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_game_over_layer)

	_game_over_screen = Control.new()
	_game_over_screen.name = "GameOverScreen"
	_game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	_game_over_screen.visible = false
	_game_over_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_game_over_layer.add_child(_game_over_screen)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	_game_over_screen.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -180.0
	panel.offset_top = -130.0
	panel.offset_right = 180.0
	panel.offset_bottom = 130.0
	_game_over_screen.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.name = "Title"
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	var message := Label.new()
	message.name = "Message"
	message.text = "Hai perso la corsa."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(message)

	_restart_button = Button.new()
	_restart_button.name = "RestartButton"
	_restart_button.text = "Restart"
	_restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	_restart_button.pressed.connect(_on_restart_button_pressed)
	vbox.add_child(_restart_button)

	if has_node("UI"):
		_game_over_layer.raise()


func _build_hud_ui() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HudLayer"
	_hud_layer.layer = 10
	_hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hud_layer)

	var margin := MarginContainer.new()
	margin.name = "CoinHudMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 18)
	_hud_layer.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.name = "CoinHudBox"
	hbox.alignment = BoxContainer.ALIGNMENT_END
	margin.add_child(hbox)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var label_box := PanelContainer.new()
	label_box.name = "CoinHudPanel"
	label_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(label_box)

	var label_margin := MarginContainer.new()
	label_margin.add_theme_constant_override("margin_left", 12)
	label_margin.add_theme_constant_override("margin_top", 8)
	label_margin.add_theme_constant_override("margin_right", 12)
	label_margin.add_theme_constant_override("margin_bottom", 8)
	label_box.add_child(label_margin)

	_coin_label = Label.new()
	_coin_label.name = "CoinCount"
	_coin_label.text = "0"
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_coin_label.add_theme_font_size_override("font_size", 28)
	label_margin.add_child(_coin_label)

	if player and player.has_method("collect_coin"):
		_on_coin_collected(int(player.get("start_coins")))


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


func _get_track_duration() -> float:
	if audio_stream and audio_stream.get_length() > 0.0:
		return audio_stream.get_length()
	return manual_track_duration_seconds
