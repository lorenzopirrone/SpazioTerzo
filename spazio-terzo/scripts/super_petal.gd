extends Node2D

@export_range(1, 3, 1) var petal_id: int = 1

@export var detection_area: Area2D

var _collected: bool = false


func _ready() -> void:
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return

	if not body.has_method("register_super_petal"):
		return

	body.register_super_petal(petal_id)
	_collected = true
	queue_free()
