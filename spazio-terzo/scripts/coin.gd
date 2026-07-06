extends Area2D

@export var value: int = 1
@export var spin_speed: float = 3.0
@export var bob_amount: float = 4.0
@export var bob_speed: float = 4.0

var _base_y: float
var _time: float = 0.0


func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	rotation += spin_speed * delta
	position.y = _base_y + sin(_time * bob_speed) * bob_amount


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_coin"):
		body.collect_coin(value)
		queue_free()
