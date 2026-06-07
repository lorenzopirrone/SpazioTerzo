extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		var level := get_tree().get_first_node_in_group("level_root")
		if level and level.has_method("complete_level"):
			level.complete_level()
