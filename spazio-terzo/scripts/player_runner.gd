class_name PlayerRunner
extends CharacterBody2D

signal died
signal punch_started(power: float)
signal punch_finished
signal petal_collected(total_petals: int)
signal score_changed(new_score: int)


const ANIMATION_RUN: StringName = &"Vespro_Run"
const ANIMATION_JUMP: StringName = &"Vespro Jump"
const ANIMATION_FALL: StringName = &"Vespro_Fall"
const ANIMATION_DAMAGE: StringName = &"Vespro_Damage"
const ANIMATION_PUNCH_START: StringName = &"Punch_Start"
const ANIMATION_PUNCH_CHARGE: StringName = &"Punch_Charge"
const ANIMATION_PUNCH_RELEASE: StringName = &"Punch_Release"

@export_group("Movement")
## Velocità orizzontale costante con cui il player avanza.
@export var run_speed: float = 300.0
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


@export_group("Punch Visuals")
@export var punch_sprite: Sprite2D
@export var punch_charge_sparkle: AnimatedSprite2D
@export var punch_reference: Node2D
@export var punch_charge_reference: Node2D
@export var punch_texture_small: Texture2D
@export var punch_texture_medium: Texture2D
@export var punch_texture_large: Texture2D
@export var punch_release_max_scale: float = 1.5
@export var punch_charge_scale: float = 0.862
var _punch_base_scale: Vector2



@export_group("Punch Rotation")
@export var punch_animation_player: AnimationPlayer
@export var punch_rotation_animation: String = "Punch Rotation"
@export var punch_rotation_min_speed: float = 1.0
@export var punch_rotation_max_speed: float = 5.0

@export var punch_speed_effect: AnimatedSprite2D

@export var effect_min_opacity := 0.0
@export var effect_max_opacity := 1.0
@export var effect_min_speed := 0.5
@export var effect_max_speed := 3.0
@export var effect_color_small: Color = Color.WHITE
@export var effect_color_medium: Color = Color.YELLOW
@export var effect_color_large: Color = Color.RED


@export_group("Runner Feel")
## Finestra di tolleranza dopo aver lasciato una piattaforma per poter ancora saltare.
@export var coyote_time: float = 0.08
## Tempo entro cui un salto premuto poco prima di toccare terra viene eseguito.
@export var jump_buffer_time: float = 0.12
## Percentuale di schermo usata per separare tap salto e hold cazzotto.
@export var punch_screen_split: float = 0.5
## Numero di petali iniziali del player.
@export var start_petals: int = 3


@export_group("Petals / Health")
## Quantità massima di petali che il player può avere.
@export var max_petals: int = 20
## Quantità di petali necessaria per sbloccare i pugni.
@export var punch_unlock_petals: int = 15
## Quantità di petali persa quando il player subisce danno.
@export var damage_petals: int = 3
## Durata dell'immortalità dopo aver ricevuto danno.
@export var invulnerability_time: float = 2.0
## Frequenza con cui il player lampeggia durante l'immortalità.
@export var invulnerability_flash_interval: float = 0.085
## Distanza orizzontale che il player arretra quando subisce danno.
@export var knockback_distance: float = 96.0
## Spinta verticale iniziale del rimbalzo dopo il danno.
@export var knockback_lift_velocity: float = -460.0
## Tempo entro cui il player raggiunge la posizione di knockback.
@export var knockback_duration: float = 0.32


@export_group("Damage Audio")
@export var damage_sounds: Array[AudioStream] = []


@export_group("Score")
@export var distance_score_multiplier: float = 1.0
@export var petal_score_value: int = 100


@onready var punch_area: Area2D = $PunchArea
@onready var punch_collision: CollisionShape2D = $PunchArea/CollisionShape2D
@onready var punch_shape: RectangleShape2D = punch_collision.shape as RectangleShape2D
@onready var charge_bar: Node2D = $ChargeBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var damage_audio: AudioStreamPlayer = $DamageAudio
@onready var music_player: AudioStreamPlayer = $"../Guaglio_Theme"

var _charge_time: float = 0.0
var _is_charging: bool = false
var _punch_timer: float = 0.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _punch_touch_index: int = -1
var _dead: bool = false
var _petals: int = 0
var _invulnerability_timer: float = 0.0
var _knockback_timer: float = 0.0
var _knockback_start_x: float = 0.0
var _knockback_target_x: float = 0.0
var _flash_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _base_modulate: Color = Color.WHITE
var _grind_active: bool = false
var _current_animation: StringName = &""
var _damage_animation_timer: float = 0.0
var _is_punch_releasing: bool = false
var _punch_start_position: Vector2
var _score: int = 0
var _score_distance: float = 0.0
var _last_score_x: float = 0.0
var _last_punch_charge_stage: int = -1

func _ready() -> void:
	_rng.randomize()
	_base_modulate = modulate
	_petals = clampi(start_petals, 0, max_petals)
	_set_punch_active(false)
	_update_charge_bar(0.0)
	_update_damage_flash(0.0)
	_punch_base_scale = punch_sprite.scale
	_last_score_x = global_position.x

	if punch_speed_effect:
		punch_speed_effect.visible = false
		punch_speed_effect.stop()
		punch_speed_effect.modulate.a = 0.0
	
	play_animation(ANIMATION_RUN)

func play_animation(animation_name: StringName) -> void:
	if _current_animation == animation_name:
		return

	if not animation_player.has_animation(animation_name):
		return

	_current_animation = animation_name
	animation_player.play(animation_name)
	_update_animation_speed()

func play_damage_sound() -> void:
	if damage_sounds.is_empty():
		return

	damage_audio.stream = damage_sounds.pick_random()
	damage_audio.play()
	
	
func _process(_delta: float) -> void:
	_update_animation_speed()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	
	if _damage_animation_timer > 0.0:
		_damage_animation_timer = maxf(_damage_animation_timer - delta, 0.0)

	if _invulnerability_timer > 0.0:
		_invulnerability_timer = maxf(_invulnerability_timer - delta, 0.0)

	if _grind_active:
		velocity = Vector2.ZERO
		_update_damage_flash(delta)
		move_and_slide()
		return

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
		_update_punch_rotation()
		_update_punch_texture()

	if _punch_timer > 0.0:
		_punch_timer -= delta

	if punch_reference:
		var punch_progress := 1.0 - (_punch_timer / punch_duration)
		punch_progress = clampf(punch_progress, 0.0, 1.0)



	var punch_progress := 1.0 - (_punch_timer / punch_duration)
	punch_progress = clampf(punch_progress, 0.0, 1.0)

	# Scatto rapido in avanti e ritorno
	var extension_progress: float

	if punch_progress < 0.25:
		extension_progress = punch_progress / 0.25
	elif punch_progress < 0.75:
		extension_progress = 1.0
	else:
		extension_progress = 1.0 - ((punch_progress - 0.75) / 0.25)

	if _punch_timer <= 0.0 and not _is_charging:
		_punch_timer = 0.0
		_set_punch_active(false)
		punch_finished.emit()
		punch_sprite.visible = false


	_update_damage_flash(delta)
	move_and_slide()
	_update_distance_score()
	_update_movement_animation()

func _unhandled_input(event: InputEvent) -> void:
	if _grind_active:
		return
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

	_end_grind()
	
	_is_charging = false
	_charge_time = 0.
	punch_sprite.visible = false
	
	if punch_charge_sparkle:
		punch_charge_sparkle.visible = false
		punch_charge_sparkle.stop()

	if punch_speed_effect:
		punch_speed_effect.visible = false
		punch_speed_effect.stop()
		punch_speed_effect.modulate.a = 0.0


	# Perdiamo i petali in base al danno ricevuto.
	_petals = max(_petals - damage_petals, 0)
	petal_collected.emit(_petals)

	# Se i petali arrivano a zero, il player muore.
	if _petals <= 0:
		_dead = true
		velocity = Vector2.ZERO
		died.emit()
		return

	_invulnerability_timer = invulnerability_time
	_knockback_timer = knockback_duration
	_damage_animation_timer = knockback_duration
	_knockback_start_x = global_position.x
	_knockback_target_x = _knockback_start_x - knockback_distance
	_flash_timer = 0.0
	velocity.x = 0.0
	velocity.y = knockback_lift_velocity

	music_player.stream_paused = true
	play_damage_sound()
	play_animation(ANIMATION_DAMAGE)


func apply_jump_impulse(vertical_velocity: float, horizontal_boost: float = 0.0) -> void:
	if _dead:
		return

	_end_grind()
	velocity.y = vertical_velocity
	velocity.x = maxf(velocity.x, run_speed + horizontal_boost)
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


func collect_petal(value: int = 1) -> void:
	if _dead:
		return

	_petals = clampi(_petals + max(value, 0), 0, max_petals)
	petal_collected.emit(_petals)
	_score += value * petal_score_value
	score_changed.emit(_score)

func get_petals() -> int:
	return _petals


func is_knockback_active() -> bool:
	return _knockback_timer > 0.0


func get_grind_hook(hook_group: StringName) -> Node2D:
	return _find_node_in_group_recursive(self, hook_group) as Node2D


func begin_grind() -> void:
	if _dead:
		return

	_grind_active = true
	velocity = Vector2.ZERO
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


func end_grind() -> void:
	_grind_active = false


func is_grinding() -> bool:
	return _grind_active



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

	if _petals < punch_unlock_petals:
		return

	_is_charging = true
	_is_punch_releasing = false
	_charge_time = 0.0
	_last_punch_charge_stage = -1

	if punch_charge_sparkle:
		punch_charge_sparkle.visible = false
		punch_charge_sparkle.stop()
		punch_charge_sparkle.frame = 0

	if punch_charge_reference:
		punch_sprite.global_position = punch_charge_reference.global_position

	play_animation(ANIMATION_PUNCH_START)

	if punch_charge_reference:
		punch_sprite.global_position = punch_charge_reference.global_position

	punch_sprite.visible = true
	punch_sprite.scale = Vector2.ONE * punch_charge_scale
	punch_animation_player.play(punch_rotation_animation)

	_update_charge_bar(0.0)







	if punch_speed_effect:
		punch_speed_effect.visible = true
		punch_speed_effect.play()


func _release_punch() -> void:
	if not _is_charging or _dead:
		return

	_is_charging = false
	punch_animation_player.stop()

	if punch_speed_effect:
		punch_speed_effect.stop()
		punch_speed_effect.visible = false
		punch_speed_effect.modulate.a = 0.0

	if punch_charge_sparkle:
		punch_charge_sparkle.visible = false
		punch_charge_sparkle.stop()
		punch_charge_sparkle.frame = 0

	# Se la carica è troppo breve, annulliamo il pugno.
	if _charge_time < min_charge_time:
		_charge_time = 0.0
		_update_charge_bar(0.0)
		_is_punch_releasing = false
		punch_sprite.visible = false
		return

	# Da qui in poi il pugno è valido.
	_is_punch_releasing = true

	if punch_reference:
		punch_sprite.global_position = punch_reference.global_position

	play_animation(ANIMATION_PUNCH_RELEASE)

	var power := clampf(_charge_time / max_charge_time, punch_min_power, 1.0)
	_update_charge_bar(0.0)

	_start_punch(power)

	var charge_progress := _charge_time / max_charge_time
	punch_sprite.scale = _punch_base_scale * lerpf(1.0, punch_release_max_scale, charge_progress)

func _jump() -> void:
	velocity.y = jump_velocity
	play_animation(ANIMATION_JUMP)
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


func _start_punch(power: float) -> void:
	# Portata della hitbox proporzionale alla carica
	punch_shape.size.x = punch_reach * power
	punch_collision.position.x = 24.0 + (punch_shape.size.x * 0.5)

	# Il pugno parte dalla posizione normale

	punch_sprite.visible = true

	_punch_timer = punch_duration
	_set_punch_active(true)
	punch_started.emit(power)

	

func _set_punch_active(active: bool) -> void:
	punch_area.monitoring = active
	punch_area.visible = active
	punch_collision.disabled = not active


func _update_charge_bar(amount: float) -> void:
	charge_bar.scale.x = clampf(amount, 0.0, 1.0)


func _update_movement_animation() -> void:
	if _damage_animation_timer > 0.0:
		return

	if _is_punch_releasing:
		return

	if _is_charging:
		if is_on_floor():
			play_animation(ANIMATION_PUNCH_CHARGE)
		elif velocity.y < 0.0:
			play_animation(ANIMATION_JUMP)
		else:
			play_animation(ANIMATION_FALL)
		return

	if is_on_floor():
		play_animation(ANIMATION_RUN)
	elif velocity.y < 0.0:
		play_animation(ANIMATION_JUMP)
	else:
		play_animation(ANIMATION_FALL)

func _update_animation_speed() -> void:
	if _current_animation == ANIMATION_RUN:
		animation_player.speed_scale = run_speed / 300.0
	else:
		animation_player.speed_scale = 1.0


func _get_animation_length(animation_name: StringName) -> float:
	if not animation_player.has_animation(animation_name):
		return 0.0
	return animation_player.get_animation(animation_name).length


func _end_grind() -> void:
	if _grind_active:
		_grind_active = false


func _find_node_in_group_recursive(root: Node, group_name: StringName) -> Node:
	if root.is_in_group(group_name):
		return root

	for child in root.get_children():
		var found := _find_node_in_group_recursive(child, group_name)
		if found != null:
			return found

	return null


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == ANIMATION_DAMAGE:
		music_player.stream_paused = false

	elif anim_name == ANIMATION_PUNCH_START and _is_charging:
		play_animation(ANIMATION_PUNCH_CHARGE)
	elif anim_name == ANIMATION_PUNCH_RELEASE:
		_is_punch_releasing = false

func _update_punch_rotation():
	var charge_ratio := _charge_time / max_charge_time
	charge_ratio = clamp(charge_ratio, 0.0, 1.0)

	# Velocità rotazione del pugno
	var current_speed = lerp(punch_rotation_min_speed, punch_rotation_max_speed, charge_ratio)
	punch_animation_player.speed_scale = current_speed

	# Effetto velocità
	if punch_speed_effect:
		punch_speed_effect.speed_scale = lerp(effect_min_speed, effect_max_speed, charge_ratio)

		var alpha = lerp(effect_min_opacity, effect_max_opacity, charge_ratio)
		punch_speed_effect.modulate.a = alpha

func _update_punch_texture() -> void:
	if not punch_sprite:
		return

	var charge_ratio := _charge_time / max_charge_time
	charge_ratio = clampf(charge_ratio, 0.0, 1.0)

	var current_stage: int

	if charge_ratio < 0.33:
		current_stage = 0
	elif charge_ratio < 0.66:
		current_stage = 1
	else:
		current_stage = 2

	if current_stage != _last_punch_charge_stage:
		_last_punch_charge_stage = current_stage

		if punch_charge_sparkle and current_stage > 0:
			punch_charge_sparkle.visible = true
			punch_charge_sparkle.frame = 0
			punch_charge_sparkle.play()

	if punch_speed_effect:
		if current_stage == 0:
			punch_speed_effect.modulate = effect_color_small
		elif current_stage == 1:
			punch_speed_effect.modulate = effect_color_medium
		else:
			punch_speed_effect.modulate = effect_color_large

	if current_stage == 0:
		punch_sprite.texture = punch_texture_small
	elif current_stage == 1:
		punch_sprite.texture = punch_texture_medium
	else:
		punch_sprite.texture = punch_texture_large

func _update_distance_score() -> void:
	var distance_moved := global_position.x - _last_score_x

	if distance_moved > 0.0:
		_score_distance += distance_moved
		_score += int(distance_moved * distance_score_multiplier)
		score_changed.emit(_score)

	_last_score_x = global_position.x
	
func get_score() -> int:
	return _score


func _on_punch_charge_sparkle_animation_finished() -> void:
	punch_charge_sparkle.visible = false
