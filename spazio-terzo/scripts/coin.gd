extends Area2D

## Valore della moneta quando viene raccolta.
@export var value: int = 1
## Velocità di rotazione della moneta in condizioni normali.
@export var spin_speed: float = 3.0
## Ampiezza del movimento verticale di oscillazione.
@export var bob_amount: float = 4.0
## Velocità dell'oscillazione verticale.
@export var bob_speed: float = 4.0
## Gravità applicata alle monete droppate dal player.
@export var drop_gravity: float = 1350.0
## Velocità di rotazione delle monete droppate.
@export var drop_spin_speed: float = 10.0
## Tempo di vita delle monete droppate prima di sparire.
@export var drop_lifetime: float = 0.65

var _base_y: float
var _time: float = 0.0
var _dropped: bool = false
var _drop_velocity: Vector2 = Vector2.ZERO
var _life_left: float = 0.0


func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _dropped:
		_life_left -= delta
		_drop_velocity.y += drop_gravity * delta
		position += _drop_velocity * delta
		rotation += drop_spin_speed * delta
		if _life_left <= 0.0:
			queue_free()
		return

	_time += delta
	rotation += spin_speed * delta
	position.y = _base_y + sin(_time * bob_speed) * bob_amount


func _on_body_entered(body: Node2D) -> void:
	if _dropped:
		return
	if body.has_method("collect_coin"):
		body.collect_coin(value)
		queue_free()


func begin_drop(initial_velocity: Vector2, lifetime: float = drop_lifetime) -> void:
	_dropped = true
	_drop_velocity = initial_velocity
	_life_left = lifetime
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
