extends Area2D

@export var new_run_speed: float = 600.0

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.run_speed = new_run_speed
