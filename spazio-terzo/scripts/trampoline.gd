extends Area2D

## Spinta verticale applicata quando il player tocca il trampolino.
@export var launch_velocity: float = -920.0
## Spinta orizzontale extra aggiunta al salto del trampolino.
@export var horizontal_boost: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("apply_jump_impulse"):
		body.apply_jump_impulse(launch_velocity, horizontal_boost)
