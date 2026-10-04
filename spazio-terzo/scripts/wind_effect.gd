extends Node2D


@export_group("References")

## PlayerRunner utilizzato per capire se il giocatore è in Grind.
@export var player: PlayerRunner



@export_group("Wind Effect")

## Numero massimo di linee di vento presenti contemporaneamente.
@export_range(1, 10, 1) var line_count: int = 3

## Lunghezza massima raggiunta da ogni linea.
@export_range(5.0, 200.0, 1.0) var line_length: float = 50.0

## Spessore delle linee di vento.
@export_range(0.5, 10.0, 0.5) var line_width: float = 2.0

## Tempo necessario a una linea per comparire, allungarsi e scomparire.
@export_range(0.05, 2.0, 0.01) var line_duration: float = 0.35

## Tempo minimo tra la creazione di una linea e quella successiva.
@export_range(0.01, 1.0, 0.01) var spawn_interval: float = 0.10

## Distanza massima laterale rispetto alla direzione del movimento.
@export_range(0.0, 100.0, 1.0) var spread: float = 25.0

## Colore delle linee di vento.
@export var line_color: Color = Color.WHITE


@export_group("Grind")

## Numero massimo di linee durante il Grind.
@export_range(1, 10, 1) var grind_line_count: int = 4

## Lunghezza delle linee durante il Grind.
@export_range(5.0, 200.0, 1.0) var grind_line_length: float = 70.0

## Intervallo tra le linee durante il Grind.
@export_range(0.01, 1.0, 0.01) var grind_spawn_interval: float = 0.06


@export_group("Normal")

## Numero massimo di linee durante la corsa normale.
@export_range(1, 10, 1) var normal_line_count: int = 2

## Lunghezza delle linee durante la corsa normale.
@export_range(5.0, 200.0, 1.0) var normal_line_length: float = 25.0

## Intervallo tra le linee durante la corsa normale.
@export_range(0.01, 1.0, 0.01) var normal_spawn_interval: float = 0.20


var _active_lines: int = 0
var _spawn_timer: float = 0.0
var _is_grinding: bool = false



func _process(delta: float) -> void:
	if player == null:
		return

	_is_grinding = player.is_grinding()

	_spawn_timer -= delta

	if _spawn_timer <= 0.0:
		_spawn_timer = _get_current_spawn_interval()
		_spawn_wind_line()


func _get_current_spawn_interval() -> float:
	if _is_grinding:
		return grind_spawn_interval

	return normal_spawn_interval


func _spawn_wind_line() -> void:
	if _active_lines >= _get_current_line_count():
		return

	var line := Line2D.new()

	line.width = line_width
	line.default_color = line_color
	line.antialiased = true
	line.top_level = true

	add_child(line)

	_active_lines += 1

	_animate_wind_line(line)
	
func _animate_wind_line(line: Line2D) -> void:
	var tween := create_tween()

	line.position = Vector2.ZERO
	line.rotation = rotation

	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)

	var direction := Vector2.LEFT.rotated(rotation)

	var random_offset := Vector2(
		randf_range(-spread, spread),
		randf_range(-spread, spread)
	)

	line.global_position = global_position + random_offset

	tween.tween_method(
	func(value: float) -> void:
		line.set_point_position(1, direction * value),
	0.0,
	_get_current_line_length(),
	line_duration * 0.6
)
	tween.parallel().tween_property(
		line,
		"modulate:a",
		0.0,
		line_duration * 0.4
	)

	tween.tween_callback(_finish_wind_line.bind(line))

func _get_current_line_count() -> int:
	if _is_grinding:
		return grind_line_count

	return normal_line_count


func _get_current_line_length() -> float:
	if _is_grinding:
		return grind_line_length

	return normal_line_length


func _finish_wind_line(line: Line2D) -> void:
	line.queue_free()
	_active_lines -= 1
