extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()

	if body.has_method("enter_triangle_obstacle"):
		body.enter_triangle_obstacle(self)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("exit_triangle_obstacle"):
		body.exit_triangle_obstacle(self)
