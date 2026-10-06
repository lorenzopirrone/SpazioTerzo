extends Node2D


@export_group("Movement")
@export var float_distance: float = 40.0
@export var float_duration: float = 0.7

@export_group("Fade")
@export var fade_duration: float = 0.2

@export_group("Scale")
@export var start_scale: float = 0.7
@export var peak_scale: float = 1.15
@export var final_scale: float = 1.0
@export_group("References")
@export var label: Label


func _ready() -> void:
	if label == null:
		return

	label.text = "TEST"
	label.modulate = Color.WHITE
	label.visible = true
	label.position = Vector2.ZERO

	print("LABEL SIZE: ", label.size)
	print("LABEL POSITION: ", label.position)


func show_score(value: int) -> void:
	print("FLOATING TEXT: show_score ricevuto: ", value)
	print("FLOATING TEXT: label = ", label)

	if label == null:
		return

	label.text = "+" + str(value)
	label.modulate.a = 1.0
	
	print("FLOATING TEXT: testo impostato: ", label.text)
	print("FLOATING TEXT: posizione: ", global_position)
	print("FLOATING TEXT: visible: ", visible)

	var start_position: Vector2 = global_position
	var target_position: Vector2 = start_position + Vector2.UP * float_distance

	var tween := create_tween()
	tween.set_parallel(true)

	# Comparsa
	tween.tween_property(
		label,
		"modulate:a",
		1.0,
		0.1
	)

	# Piccolo pop
	tween.tween_property(
		self,
		"scale",
		Vector2.ONE * peak_scale,
		0.1
	)

	tween.chain().tween_property(
		self,
		"scale",
		Vector2.ONE * final_scale,
		0.1
	)

	# Movimento verso l'alto
	tween.tween_property(
		self,
		"global_position",
		target_position,
		float_duration
	)

	# Attesa prima del fade
	tween.chain().tween_interval(
		float_duration - fade_duration
	)

	# Fade finale
	tween.chain().tween_property(
		label,
		"modulate:a",
		0.0,
		fade_duration
	)

	await tween.finished
	queue_free()
