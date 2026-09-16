extends Area2D


@export_category("Player Reference")

# Trascina qui il nodo Player completo
@export var player: Node2D

# Nome del figlio Sprite2D del player
@export var sprite_name: String = "Vesprotest"


@export_category("Trigger Action")

@export_enum("Diventa Nero", "Torna Normale")
var action := "Diventa Nero"


@export_category("Black Settings")

@export var black_color: Color = Color.BLACK


@export_category("Restore Settings")

@export var smooth_restore: bool = true
@export var restore_time: float = 1.0


var player_sprite: Sprite2D
var original_color: Color



func _ready():

	body_entered.connect(_on_body_entered)

	# Recupera automaticamente lo sprite del player
	if player:

		player_sprite = player.get_node_or_null(sprite_name)

		if player_sprite:
			original_color = player_sprite.modulate

		else:
			print("Sprite non trovato: ", sprite_name)



func _on_body_entered(body):

	if body.is_in_group("player"):

		# Se non è stato assegnato manualmente,
		# prova a usare il player che ha attivato il trigger
		if player == null:
			player = body
			player_sprite = player.get_node_or_null(sprite_name)

			if player_sprite:
				original_color = player_sprite.modulate


		if player_sprite == null:
			print("Nessuno Sprite2D trovato nel Player")
			return


		if action == "Diventa Nero":

			make_black()


		elif action == "Torna Normale":

			restore_color()



func make_black():

	player_sprite.modulate = black_color



func restore_color():

	if smooth_restore:

		var tween = create_tween()

		tween.tween_property(
			player_sprite,
			"modulate",
			original_color,
			restore_time
		)

	else:

		player_sprite.modulate = original_color
