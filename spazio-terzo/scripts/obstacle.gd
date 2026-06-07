extends Area2D

@export var can_be_punched: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()


func _on_area_entered(area: Area2D) -> void:
	if can_be_punched and area.name == "PunchArea":
		queue_free()
