extends Control

@export_group("References")
@export var fill: ColorRect
@export var player: PlayerRunner
@export var multiplier_text: Label

@export_group("Bar Settings")
@export var bar_width: float = 200.0
@export var slide_duration: float = 0.3
@export var slide_margin: float = 20.0


var _shown_position: Vector2
var _hidden_position: Vector2

var _bar_is_on_screen: bool = false
var _slide_tween: Tween


func _ready() -> void:
	if player == null or fill == null:
		return

	_shown_position = position

	_hidden_position = Vector2(
		_shown_position.x - size.x - slide_margin,
		_shown_position.y
	)

	fill.size.x = bar_width * player.get_multiplier_bar_progress()

	if multiplier_text:
		multiplier_text.text = "x" + str(player.get_score_multiplier())

	player.multiplier_progress_changed.connect(
		_on_multiplier_progress_changed
	)

	player.multiplier_reset.connect(
		_on_multiplier_reset
	)


func _process(_delta: float) -> void:
	if player == null or fill == null:
		return

	fill.size.x = bar_width * player.get_multiplier_bar_progress()

	if multiplier_text:
		multiplier_text.text = "x" + str(player.get_score_multiplier())


func _on_multiplier_progress_changed() -> void:
	if not _bar_is_on_screen:
		_show_bar()


func _on_multiplier_reset() -> void:
	_hide_bar()


func _show_bar() -> void:
	_bar_is_on_screen = true

	if _slide_tween:
		_slide_tween.kill()

	position = _hidden_position

	_slide_tween = create_tween()
	_slide_tween.set_trans(Tween.TRANS_QUAD)
	_slide_tween.set_ease(Tween.EASE_OUT)

	_slide_tween.tween_property(
		self,
		"position",
		_shown_position,
		slide_duration
	)


func _hide_bar() -> void:
	_bar_is_on_screen = false

	if _slide_tween:
		_slide_tween.kill()

	_slide_tween = create_tween()
	_slide_tween.set_trans(Tween.TRANS_QUAD)
	_slide_tween.set_ease(Tween.EASE_IN)

	_slide_tween.tween_property(
		self,
		"position",
		_hidden_position,
		slide_duration
	)
