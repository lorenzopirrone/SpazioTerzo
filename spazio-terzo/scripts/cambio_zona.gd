extends Area2D

@export_group("Background")
##Inserire SKYBOX
@export var parallasse_zona_1: Node2D
##Inserire SKYBOX
@export var parallasse_zona_2: Node2D
@export var durata_dissolvenza: float = 0.7
@export var durata_transizione: float = 0.7
@export var distanza_ascensore: float = 1080.0
@export var dissolvenza: bool = true

@export_group("Sun")
@export var sun_controller: Node2D
@export_range(0, 2, 1) var active_sun: int = 0
@export var sun_stop_index: int = 0
@export var sun_move_duration: float = 1.0

var _cambio_in_corso := false
var _posizione_zona_1: Vector2
var _posizione_zona_2: Vector2


func _ready() -> void:
	parallasse_zona_1.show()
	parallasse_zona_1.modulate.a = 1.0

	parallasse_zona_2.hide()
	parallasse_zona_2.modulate.a = 0.0
	
	_posizione_zona_1 = parallasse_zona_1.position
	_posizione_zona_2 = parallasse_zona_2.position


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _cambio_in_corso:
		return

	_cambio_in_corso = true
	set_deferred("monitoring", false)

	# Avvia il movimento del Sole
	if sun_controller != null:
		if sun_controller.has_method("set_active_sun"):
			sun_controller.set_active_sun(active_sun)

		if sun_controller.has_method("move_to_stop"):
			sun_controller.move_to_stop(
				sun_stop_index,
				sun_move_duration
			)

	# Avvia il cambio di fondale
	parallasse_zona_2.show()

# La nuova zona parte dal basso.
	parallasse_zona_2.position = _posizione_zona_2 + Vector2(0.0, distanza_ascensore)
	parallasse_zona_2.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

# Zona vecchia: sale.
	tween.tween_property(
		parallasse_zona_1,
		"position",
		_posizione_zona_1 - Vector2(0.0, distanza_ascensore),
		durata_transizione
	)

# Zona nuova: sale dal basso nella posizione corretta.
	tween.tween_property(
		parallasse_zona_2,
		"position",
		_posizione_zona_2,
		durata_transizione
	)

# Dissolvenza opzionale.
	if dissolvenza:
		tween.tween_property(
			parallasse_zona_1,
			"modulate:a",
			0.0,
			durata_transizione
		)

	tween.tween_property(
		parallasse_zona_2,
		"modulate:a",
		1.0,
		durata_transizione
	)

	await tween.finished

	parallasse_zona_1.hide()
