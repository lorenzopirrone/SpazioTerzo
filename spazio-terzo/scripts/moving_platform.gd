extends AnimatableBody2D

## Spostamento totale della piattaforma durante il suo ciclo.
@export var travel: Vector2 = Vector2(0.0, -96.0)
## Durata completa del ciclo di andata e ritorno.
@export var cycle_time: float = 2.4

var _origin: Vector2


func _ready() -> void:
	_origin = position


func _physics_process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var wave := (sin((t / maxf(cycle_time, 0.01)) * TAU) + 1.0) * 0.5
	position = _origin + travel * wave
