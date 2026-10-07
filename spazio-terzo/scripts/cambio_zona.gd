extends Area2D

@export_group("Background")
@export var parallasse_zona_1: Node2D
@export var parallasse_zona_2: Node2D
@export var durata_dissolvenza: float = 0.7

@export_group("Sun")
@export var sun_controller: Node2D
@export var sun_stop_index: int = 0
@export var sun_move_duration: float = 1.0

var _cambio_in_corso := false


func _ready() -> void:
	parallasse_zona_1.show()
	parallasse_zona_1.modulate.a = 1.0

	parallasse_zona_2.hide()
	parallasse_zona_2.modulate.a = 0.0


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _cambio_in_corso:
		return

	_cambio_in_corso = true
	set_deferred("monitoring", false)

	# Avvia il movimento del Sole
	if sun_controller != null:
		if sun_controller.has_method("move_to_stop"):
			sun_controller.move_to_stop(
				sun_stop_index,
				sun_move_duration
			)

	# Avvia il cambio di fondale
	parallasse_zona_2.show()

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		parallasse_zona_1,
		"modulate:a",
		0.0,
		durata_dissolvenza
	)

	tween.tween_property(
		parallasse_zona_2,
		"modulate:a",
		1.0,
		durata_dissolvenza
	)

	await tween.finished

	parallasse_zona_1.hide()
