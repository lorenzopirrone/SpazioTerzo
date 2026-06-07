extends Node

@export var level_paths: Array[String] = [
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
]
@export var restart_delay: float = 0.75
@export var next_level_delay: float = 0.55

var _current_level_index: int = 0
var _current_level: Node


func _ready() -> void:
	_load_level(_current_level_index)


func _load_level(index: int) -> void:
	if _current_level:
		_current_level.queue_free()

	_current_level_index = wrapi(index, 0, level_paths.size())
	var packed := load(level_paths[_current_level_index]) as PackedScene
	_current_level = packed.instantiate()
	add_child(_current_level)
	_current_level.connect("player_died", _restart_level)
	_current_level.connect("level_completed", _next_level)


func _restart_level() -> void:
	await get_tree().create_timer(restart_delay).timeout
	_load_level(_current_level_index)


func _next_level() -> void:
	await get_tree().create_timer(next_level_delay).timeout
	_load_level(_current_level_index + 1)
