extends Node

@export var level_paths: Array[String] = [
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
]
@export var next_level_delay: float = 0.55

@onready var game_over_screen: Control = $UI/GameOverScreen
@onready var restart_button: Button = $UI/GameOverScreen/Panel/VBox/RestartButton

var _current_level_index: int = 0
var _current_level: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_screen.hide()
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_on_restart_button_pressed)
	_load_level(_current_level_index)


func _load_level(index: int) -> void:
	if _current_level:
		_current_level.queue_free()

	_current_level_index = wrapi(index, 0, level_paths.size())
	var packed := load(level_paths[_current_level_index]) as PackedScene
	_current_level = packed.instantiate()
	add_child(_current_level)
	_current_level.connect("player_died", _on_player_died)
	_current_level.connect("level_completed", _on_level_completed)
	game_over_screen.hide()


func _on_player_died() -> void:
	get_tree().paused = true
	game_over_screen.show()


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	_load_level(_current_level_index)


func _on_level_completed() -> void:
	await get_tree().create_timer(next_level_delay).timeout
	_load_level(_current_level_index + 1)
