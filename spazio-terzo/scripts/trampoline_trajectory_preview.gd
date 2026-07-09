@tool
extends Node2D

## Velocità orizzontale assunta per calcolare la traiettoria.
@export var run_speed: float = 260.0:
	set(value):
		run_speed = value
		queue_redraw()
## Spinta verticale usata nella previsione del trampolino.
@export var launch_velocity: float = -920.0:
	set(value):
		launch_velocity = value
		queue_redraw()
## Gravità usata nella previsione del trampolino.
@export var gravity: float = 1500.0:
	set(value):
		gravity = value
		queue_redraw()
## Durata totale della previsione del salto.
@export var preview_time: float = 1.25:
	set(value):
		preview_time = value
		queue_redraw()
## Intervallo tra i punti della previsione.
@export var step_time: float = 0.06:
	set(value):
		step_time = value
		queue_redraw()
## Colore della linea di previsione del trampolino.
@export var line_color: Color = Color(0.15, 0.95, 0.55, 0.88):
	set(value):
		line_color = value
		queue_redraw()


func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()
		set_process(false)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		var trampoline := get_parent()
		if trampoline:
			launch_velocity = float(trampoline.get("launch_velocity"))
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var points: PackedVector2Array = []
	var t := 0.0
	while t <= preview_time:
		points.append(Vector2(run_speed * t, launch_velocity * t + 0.5 * gravity * t * t))
		t += maxf(step_time, 0.01)

	if points.size() < 2:
		return

	draw_polyline(points, line_color, 3.0, true)
	for point in points:
		draw_circle(point, 4.0, line_color)
