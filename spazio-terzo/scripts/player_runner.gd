class_name PlayerRunner
extends CharacterBody2D

signal died
signal punch_started(power: float)
signal punch_finished
signal coin_collected(total_coins: int)

const COIN_SCENE := preload("res://scenes/environment/coin.tscn")
const RECOVERABLE_COIN_SCENE := preload("res://scenes/environment/recoverable_coin.tscn")

@export_group("Movement")
## Velocità orizzontale costante con cui il player avanza.
@export var run_speed: float = 260.0
## Spinta verticale del salto base: più è negativa, più il salto è alto.
@export var jump_velocity: float = -560.0
## Accelerazione di gravità applicata quando il player è in aria.
@export var gravity: float = 1500.0
## Limite massimo della velocità di caduta.
@export var max_fall_speed: float = 1100.0

@export_group("Punch")
## Tempo minimo necessario per iniziare a caricare il cazzotto.
@export var min_charge_time: float = 0.18
## Tempo massimo di carica prima che il colpo raggiunga il suo pieno potere.
@export var max_charge_time: float = 1.0
## Durata dell'animazione/stato del cazzotto una volta rilasciato.
@export var punch_duration: float = 0.18
## Distanza orizzontale del cazzotto rispetto al player.
@export var punch_reach: float = 86.0
## Potenza minima accettata del cazzotto caricato.
@export var punch_min_power: float = 0.35

@export_group("Runner Feel")
## Finestra di tolleranza dopo aver lasciato una piattaforma per poter ancora saltare.
@export var coyote_time: float = 0.08
## Tempo entro cui un salto premuto poco prima di toccare terra viene eseguito.
@export var jump_buffer_time: float = 0.12
## Percentuale di schermo usata per separare tap salto e hold cazzotto.
@export var punch_screen_split: float = 0.5
## Numero di monete iniziali del player.
@export var start_coins: int = 0

@export_group("Damage")
## Sotto questo numero di monete il colpo uccide il player.
@export var minimum_coins_to_survive: int = 10
## Numero di monete perse quando il player subisce danno.
@export var coins_lost_on_hit: int = 10
## Durata dell'immortalità dopo aver ricevuto danno.
@export var invulnerability_time: float = 2.0
## Frequenza con cui il player lampeggia durante l'immortalità.
@export var invulnerability_flash_interval: float = 0.085
## Velocità iniziale del rimbalzo all'indietro e verso l'alto.
## Distanza orizzontale che il player arretra quando subisce danno.
@export var knockback_distance: float = 96.0
## Spinta verticale iniziale del rimbalzo dopo il danno.
@export var knockback_lift_velocity: float = -460.0
## Tempo entro cui il player raggiunge la posizione di knockback.
@export var knockback_duration: float = 0.32
## Tempo di vita delle monete droppate dopo il danno.
@export var dropped_coin_lifetime: float = 0.65
## Ampiezza laterale della dispersione delle monete perse.
@export var dropped_coin_spread: float = 220.0
## Spinta verticale iniziale delle monete perse.
@export var dropped_coin_upward_boost: float = 360.0
## Percentuale delle monete perse che resta sul pavimento e può essere ripresa.
@export var recoverable_drop_ratio: float = 0.5

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
var _invulnerability_timer: float = 0.0
var _knockback_timer: float = 0.0
var _knockback_start_x: float = 0.0
var _knockback_target_x: float = 0.0
var _flash_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _base_modulate: Color = Color.WHITE


func _ready() -> void:
	_rng.randomize()
	_base_modulate = modulate
	_coins = start_coins
	_set_punch_active(false)
	_update_charge_bar(0.0)
	_update_damage_flash(0.0)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	if _invulnerability_timer > 0.0:
		_invulnerability_timer = maxf(_invulnerability_timer - delta, 0.0)

	if _knockback_timer > 0.0:
		_knockback_timer = maxf(_knockback_timer - delta, 0.0)
		if knockback_duration > 0.0:
			var knockback_progress: float = 1.0 - (_knockback_timer / knockback_duration)
			knockback_progress = clampf(knockback_progress, 0.0, 1.0)
			var eased_progress: float = 1.0 - pow(1.0 - knockback_progress, 2.0)
			var desired_x: float = lerpf(_knockback_start_x, _knockback_target_x, eased_progress)
			velocity.x = (desired_x - global_position.x) / maxf(delta, 0.0001)
		else:
			global_position.x = _knockback_target_x
			velocity.x = 0.0
	else:
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

	_update_damage_flash(delta)
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
	if _dead or _invulnerability_timer > 0.0:
		return

	if _coins < minimum_coins_to_survive:
		_dead = true
		velocity = Vector2.ZERO
		died.emit()
		return

	var coins_to_drop: int = min(_coins, coins_lost_on_hit)
	_coins = max(_coins - coins_to_drop, 0)
	coin_collected.emit(_coins)
	_spawn_dropped_coins(coins_to_drop)
	_invulnerability_timer = invulnerability_time
	_knockback_timer = knockback_duration
	_knockback_start_x = global_position.x
	_knockback_target_x = _knockback_start_x - knockback_distance
	_flash_timer = 0.0
	velocity.x = 0.0
	velocity.y = knockback_lift_velocity


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


func is_knockback_active() -> bool:
	return _knockback_timer > 0.0


func _spawn_dropped_coins(amount: int) -> void:
	if amount <= 0:
		return

	var parent := get_parent()
	if parent == null:
		return

	var recoverable_amount: int = int(floor(amount * recoverable_drop_ratio))
	recoverable_amount = clampi(recoverable_amount, 0, amount)

	for i in range(amount):
		var is_recoverable: bool = i < recoverable_amount
		var coin_instance := (RECOVERABLE_COIN_SCENE if is_recoverable else COIN_SCENE).instantiate()
		parent.add_child(coin_instance)
		coin_instance.global_position = global_position + Vector2(
			_rng.randf_range(-18.0, 18.0),
			_rng.randf_range(-22.0, 6.0)
		)
		if coin_instance.has_method("begin_drop"):
			var direction: float = -1.0 if i < amount / 2 else 1.0
			var launch_velocity := Vector2(
				_rng.randf_range(70.0, dropped_coin_spread) * direction,
				-_rng.randf_range(dropped_coin_upward_boost * 0.65, dropped_coin_upward_boost)
			)
			if is_recoverable:
				coin_instance.begin_drop(launch_velocity, self, dropped_coin_lifetime * 1.75)
			else:
				coin_instance.begin_drop(launch_velocity, dropped_coin_lifetime)


func _update_damage_flash(delta: float) -> void:
	if _invulnerability_timer > 0.0:
		_flash_timer += delta
		var blink_phase := fmod(_flash_timer, invulnerability_flash_interval)
		var alpha := 1.0 if blink_phase < invulnerability_flash_interval * 0.5 else 0.2
		modulate = Color(_base_modulate.r, _base_modulate.g, _base_modulate.b, alpha)
	else:
		modulate = _base_modulate


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

