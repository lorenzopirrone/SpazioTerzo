extends Area2D

@export var parallasse_zona_1: Node2D
@export var parallasse_zona_2: Node2D


func _ready() -> void:
	parallasse_zona_1.show()
	parallasse_zona_2.hide()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	parallasse_zona_1.hide()
	parallasse_zona_2.show()
	monitoring = false
