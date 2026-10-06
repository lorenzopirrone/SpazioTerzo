extends TextureRect

@export var beat_speed: float = 2.0
@export var beat_strength: float = 0.12

var _base_scale: Vector2

func _ready() -> void:
	_base_scale = scale

func _process(delta: float) -> void:
	var pulse := (sin(Time.get_ticks_msec() * 0.001 * beat_speed * TAU) + 1.0) * 0.5
	
	scale = _base_scale * (1.0 + pulse * beat_strength)
