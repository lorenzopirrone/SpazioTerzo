extends Area2D

## Indica se l'ostacolo può essere distrutto dal cazzotto del player.
@export var can_be_punched: bool = true


@export_group("Destroy Effect")
## Tutte le parti grafiche che compongono l'ostacolo.
@export var parts: Array[Sprite2D] = []

## Durata dell'effetto di distruzione.
@export var effect_duration: float = 0.35

## Quanto diventano grandi le parti prima di sparire.
@export var effect_scale: float = 2.0

## Quanto si allontanano le parti.
@export var effect_distance: float = 120.0

## Quanti gradi ruotano durante l'effetto.
@export var effect_rotation: float = 180.0


var _destroying: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()


func _on_area_entered(area: Area2D) -> void:
	if can_be_punched and area.name == "PunchArea" and not _destroying:
		_destroying = true

		$CollisionShape2D.set_deferred("disabled", true)

		_play_destroy_effect()
func destroy_obstacle() -> void:
	# Per ora solo test
	print("OSTACOLO DISTRUTTO")
	
	
func _play_destroy_effect() -> void:
	if parts.is_empty():
		queue_free()
		return

	var tween := create_tween()
	tween.set_parallel()

	for i in parts.size():
		var part := parts[i]

		if part == null:
			continue

		var direction := Vector2.from_angle(
			lerpf(
				-PI * 0.85,
				-PI * 0.15,
				float(i) / max(parts.size() - 1, 1)
			)
		)

		var target_position := part.position + direction * effect_distance
		var target_scale := part.scale * effect_scale
		var target_rotation := part.rotation + deg_to_rad(effect_rotation)

		tween.tween_property(
			part,
			"position",
			target_position,
			effect_duration
		)

		tween.tween_property(
			part,
			"scale",
			target_scale,
			effect_duration
		)

		tween.tween_property(
			part,
			"rotation",
			target_rotation,
			effect_duration
		)

		tween.tween_property(
			part,
			"modulate:a",
			0.0,
			effect_duration
		)

	tween.set_parallel(false)
	tween.tween_callback(queue_free)
