extends CharacterBody2D

## Valore della moneta quando viene raccolta.
@export var value: int = 1
## Gravità applicata mentre la moneta cade.
@export var gravity: float = 1350.0
## Limite massimo della velocità di caduta.
@export var max_fall_speed: float = 980.0
## Velocità di rotazione della moneta mentre si muove.
@export var spin_speed: float = 10.0
## Tempo massimo prima che la moneta scompaia se non viene raccolta.
@export var lifetime: float = 8.0

@onready var pickup_area: Area2D = $PickupArea

var _life_left: float = 0.0
var _pickup_enabled: bool = false
var _settled: bool = false


func _ready() -> void:
	if _life_left <= 0.0:
		_life_left = lifetime
	if pickup_area:
		pickup_area.body_entered.connect(_on_body_entered)


func begin_drop(initial_velocity: Vector2, collector: Node = null, custom_lifetime: float = lifetime) -> void:
	velocity = initial_velocity
	_life_left = custom_lifetime
	if collector is PhysicsBody2D:
		add_collision_exception_with(collector)


func _physics_process(delta: float) -> void:
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()
		return

	if not _settled:
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
		move_and_slide()
		rotation += spin_speed * delta

		if is_on_floor():
			_settled = true
			_pickup_enabled = true
			velocity = Vector2.ZERO
			_try_collect_overlaps()
	else:
		rotation += spin_speed * 0.25 * delta
		velocity = Vector2.ZERO


func _on_body_entered(body: Node2D) -> void:
	if not _pickup_enabled:
		return
	if body.has_method("collect_coin"):
		body.collect_coin(value)
		queue_free()


func _try_collect_overlaps() -> void:
	if pickup_area == null:
		return

	for body in pickup_area.get_overlapping_bodies():
		if body.has_method("collect_coin"):
			body.collect_coin(value)
			queue_free()
			return
