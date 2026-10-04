extends Area2D

@export var parallasse_zona_2: Node2D
@export var parallasse_zona_3: Node2D
@export var durata_dissolvenza := 0.7

var _cambio_in_corso := false


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _cambio_in_corso:
		return

	_cambio_in_corso = true
	monitoring = false

	# La nuova zona parte completamente trasparente.
	parallasse_zona_3.modulate.a = 0.0
	parallasse_zona_3.show()

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		parallasse_zona_2,
		"modulate:a",
		0.0,
		durata_dissolvenza
	)

	tween.tween_property(
		parallasse_zona_3,
		"modulate:a",
		1.0,
		durata_dissolvenza
	)

	await tween.finished

	parallasse_zona_2.hide()
	parallasse_zona_2.modulate.a = 1.0
	parallasse_zona_3.modulate.a = 1.0
