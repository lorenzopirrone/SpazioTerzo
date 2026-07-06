class_name PlayerRunner
extends CharacterBody2D

signal died
signal punch_started(power: float)
signal punch_finished
signal coin_collected(total_coins: int)

@export_group("Movement")
@export var run_speed: float = 260.0
@export var jump_velocity: float = -560.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 1100.0

@export_group("Punch")
@export var min_charge_time: float = 0.18
@export var max_charge_time: float = 1.0
@export var punch_duration: float = 0.18
@export var punch_reach: float = 86.0
@export var punch_min_power: float = 0.35

@export_group("Runner Feel")
@export var coyote_time: float = 0.08
@export var jump_buffer_time: float = 0.12
@export var punch_screen_split: float = 0.5
@export var start_coins: int = 0

@onready var punch_area: Area2D = $PunchArea
@onready var punch_collision: CollisionShape2D = $PunchArea/CollisionShape2D
@onready var punch_shape: RectangleShape2D = punch_collision.shape as RectangleShape2D
@onready var charge_bar: Node2D = $ChargeBar

var _charge_time: float = 0.0
var _is_charging: bool = false
var _punch_timer: float = 0.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _punch_touch_index: int = -1
var _dead: bool = false
var _coins: int = 0


func _ready() -> void:
	_coins = start_coins
	_set_punch_active(false)
	_update_charge_bar(0.0)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	velocity.x = run_speed

	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta
		if _coyote_timer > 0.0:
			_jump()

	if _is_charging:
		_charge_time = minf(_charge_time + delta, max_charge_time)
		_update_charge_bar(_charge_time / max_charge_time)

	if _punch_timer > 0.0:
		_punch_timer -= delta
		if _punch_timer <= 0.0:
			_set_punch_active(false)
			punch_finished.emit()

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_button(event)
	elif event.is_action_pressed("runner_jump"):
		_buffer_jump()
	elif event.is_action_pressed("runner_punch"):
		_begin_punch_charge()
	elif event.is_action_released("runner_punch"):
		_release_punch()


func take_hit() -> void:
	if _dead:
		return

	_dead = true
	velocity = Vector2.ZERO
	died.emit()


func apply_jump_impulse(vertical_velocity: float, horizontal_boost: float = 0.0) -> void:
	if _dead:
		return

	velocity.y = vertical_velocity
	velocity.x = maxf(velocity.x, run_speed + horizontal_boost)
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


func collect_coin(value: int = 1) -> void:
	if _dead:
		return

	_coins += max(value, 0)
	coin_collected.emit(_coins)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if event.position.x < get_viewport_rect().size.x * punch_screen_split:
			_buffer_jump()
		elif _punch_touch_index == -1:
			_punch_touch_index = event.index
			_begin_punch_charge()
	elif event.index == _punch_touch_index:
		_punch_touch_index = -1
		_release_punch()
	elif event.position.x >= get_viewport_rect().size.x * punch_screen_split:
		_release_punch()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.position.x < get_viewport_rect().size.x * punch_screen_split:
		if event.pressed:
			_buffer_jump()
	else:
		if event.pressed:
			_punch_touch_index = -1
			_begin_punch_charge()
		else:
			_release_punch()


func _buffer_jump() -> void:
	if _dead:
		return

	_jump_buffer_timer = jump_buffer_time


func _begin_punch_charge() -> void:
	if _dead:
		return

	_is_charging = true
	_charge_time = 0.0
	_update_charge_bar(0.0)


func _release_punch() -> void:
	if not _is_charging or _dead:
		return

	_is_charging = false
	var power := clampf(_charge_time / max_charge_time, punch_min_power, 1.0)
	_update_charge_bar(0.0)

	if _charge_time >= min_charge_time:
		_start_punch(power)


func _jump() -> void:
	velocity.y = jump_velocity
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


func _start_punch(power: float) -> void:
	punch_shape.size.x = punch_reach * power
	punch_collision.position.x = 24.0 + (punch_shape.size.x * 0.5)
	_punch_timer = punch_duration
	_set_punch_active(true)
	punch_started.emit(power)


func _set_punch_active(active: bool) -> void:
	punch_area.monitoring = active
	punch_area.visible = active
	punch_collision.disabled = not active


func _update_charge_bar(amount: float) -> void:
	charge_bar.scale.x = clampf(amount, 0.0, 1.0)
