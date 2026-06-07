class_name LevelRoot
extends Node2D

signal level_completed
signal player_died

@export var player_path: NodePath = ^"Player"
@export var death_y: float = 760.0

var player: Node2D


func _ready() -> void:
	player = get_node_or_null(player_path) as Node2D
	if player:
		player.connect("died", _on_player_died)


func _physics_process(_delta: float) -> void:
	if player and player.global_position.y > death_y and player.has_method("take_hit"):
		player.take_hit()


func complete_level() -> void:
	level_completed.emit()


func _on_player_died() -> void:
	player_died.emit()
