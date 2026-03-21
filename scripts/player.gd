extends CharacterBody2D

@export var speed: float = 400
@export var dash_speed: float = 900
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

@export var rotation_speed: float = 5.0
@export var max_tilt_angle: float = 45.0

enum {IDLE, SWIM, BITE, SWIMUP, SWIMDOWN}
var state: int = IDLE

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	var screen_size = get_viewport_rect().size
	global_position = screen_size / 2
	change_state(IDLE)

func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position)
	var distance = direction.length()

	# Update timers
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Dash input (Shift or Right Mouse)
	if not is_dashing and dash_cooldown_timer <= 0:
		if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if distance > 5:
				dash_direction = direction.normalized()
				is_dashing = true
				dash_timer = dash_duration
				dash_cooldown_timer = dash_cooldown

	# Movement
	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		if distance > 5:
			direction = direction.normalized()
			velocity = direction * speed

			if velocity.y < -150:
				change_state(SWIMUP)
			elif velocity.y > 150:
				change_state(SWIMDOWN)
			else:
				change_state(SWIM)
		else:
			velocity = Vector2.ZERO
			change_state(IDLE)

	move_and_slide()

	# Flip
	flip_check()

# State handling
func change_state(new_state: int) -> void:
	state = new_state
	match state:
		IDLE:
			rotation = 0
			$AnimatedSprite2D.play("idle")
		SWIM:
			$AnimatedSprite2D.play("swim")
		SWIMUP:
			$AnimatedSprite2D.play("swim-up")
		SWIMDOWN:
			$AnimatedSprite2D.play("swim-down")

# Flip logic
func flip_check():
	if velocity.x < -0.1:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x > 0.1:
		$AnimatedSprite2D.flip_h = true
