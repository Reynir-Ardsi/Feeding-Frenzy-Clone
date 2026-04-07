extends CharacterBody2D

signal died

@export var speed: float = 400
@export var dash_speed: float = 900
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

var hp: float
var hunger: float = 100.0
var hunger_depletion_rate: float = 6.0
var health_drain_rate: float = 3.0
var is_dead: bool = false
var game_active: bool = false

enum {IDLE, SWIM, DEAD, SWIMUP, SWIMDOWN, HURT}
var state: int = IDLE
var state_timer: float 

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var can_dash: bool = true
@onready var sfx: AudioStreamPlayer = $SFX

var dash_sounds = [
	preload("res://assets/sfx/dash1.wav"),
	preload("res://assets/sfx/dash2.wav"),
	preload("res://assets/sfx/dash3.wav"),
	preload("res://assets/sfx/dash4.wav")
]
func play_dash_sound():
	var random_dash_sound = dash_sounds.pick_random()
	sfx.stream = random_dash_sound
	sfx.play()


var eat_sounds = [
	preload("res://assets/sfx/eat1.wav"),
	preload("res://assets/sfx/eat2.mp3")
]
func play_eat_sound():
	var random_eat_sound = eat_sounds.pick_random()
	sfx.stream = random_eat_sound
	sfx.play()

var hit_sounds = [
	preload("res://assets/sfx/hit1.mp3"),
	preload("res://assets/sfx/hit2.mp3")
]
func play_hit_sound():
	var random_hit_sound = hit_sounds.pick_random()
	sfx.stream = random_hit_sound
	sfx.play()

var death_sound = preload("res://assets/sfx/death.mp3")
func play_death_sound():
	sfx.stream = death_sound
	sfx.play()
	
func _ready() -> void:
	hp = 100.0
	hunger = 100.0
	var screen_size = get_viewport_rect().size
	global_position = screen_size / 2
	change_state(IDLE)
	game_active = false
	$AnimatedSprite2D.hide()

func _process(delta: float) -> void:
	# Decrease state timer every frame
	if state_timer > 0:
		state_timer -= delta

	# If game is not active, stop movement
	if not game_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Handle DEAD state
	if state == DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		flip_check()
		return

	# Handle HURT state (lock movement & dash)
	if state == HURT and state_timer > 0:
		move_and_slide()  # keep knockback if set
		flip_check()
		return
	elif state == HURT and state_timer <= 0:
		# Once hurt timer is done, return to normal movement
		change_state(IDLE)

	# Hunger drains over time
	hunger = max(hunger - hunger_depletion_rate * delta, 0.0)
	if hunger <= 0.0:
		can_dash = false
		hp = max(hp - health_drain_rate * delta, 0.0)
		if hp <= 0:
			die()
	else:
		can_dash = true

	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position)
	var distance = direction.length()

	# Update dash timers
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Dash input (Space or Right Mouse)
	if not is_dashing and dash_cooldown_timer <= 0 and can_dash:
		if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if distance > 5:
				play_dash_sound()
				hunger -= 2.5
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

			# Choose animation based on vertical movement
			if velocity.y < -150:
				change_state(SWIMUP)
			elif velocity.y > 150:
				change_state(SWIMDOWN)
			else:
				change_state(SWIM)
		else:
			velocity = Vector2.ZERO
			change_state(IDLE)

	# Apply movement & flip
	move_and_slide()
	flip_check()

# State handling
func change_state(new_state: int) -> void:
	#if state == DEAD: return
	state = new_state
	match state:
		IDLE:
			$AnimatedSprite2D.play("idle")
		SWIM:
			$AnimatedSprite2D.play("swim")
		SWIMUP:
			$AnimatedSprite2D.play("swim-up")
		SWIMDOWN:
			$AnimatedSprite2D.play("swim-down")
		DEAD:
			$AnimatedSprite2D.play("dead")
			die()
		HURT:
			$AnimatedSprite2D.play("hurt")
			
			

# Flip logic
func flip_check():
	if velocity.x < -0.1:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x > 0.1:
		$AnimatedSprite2D.flip_h = true

func take_damage(amount: float) -> void:
	if state == DEAD or state == HURT:
		return
	
	play_hit_sound()
	hp = max(hp - amount, 0.0)
	
	if hp > 0:
		# Set HURT state with a timer to lock animation
		state_timer = 0.5  # match your hurt animation length
		velocity = Vector2.ZERO  # optional: add knockback if needed
		change_state(HURT)
	else:
		# Set DEAD state with optional delay for animation
		state_timer = 0.5
		change_state(DEAD)

func apply_nutrition(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	
	play_eat_sound()
	
	# if hp is full, eating will replenish hunger
	if hp >= 100.0:
		hunger = min(hunger + (amount * 2), 100.0)
		return
	
	# otherwise, will replenish hp 
	var heal_amount = min(amount, 100.0 - hp)
	hp += heal_amount
	amount -= heal_amount
	
	if amount > 0.0:
		hunger = min(hunger + amount, 100.0)

func die() -> void:
	play_death_sound()
	if is_dead:
		return
	is_dead = true
	game_active = false
	velocity = Vector2.ZERO
	change_state(DEAD)
	emit_signal("died")

func start_game() -> void:
	# Reset core gameplay state
	is_dead = false
	game_active = true
	hp = 100.0
	hunger = 100.0
	state = IDLE
	state_timer = 0.0
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	can_dash = true
	velocity = Vector2.ZERO

	# Reset sprite
	$AnimatedSprite2D.show()
	change_state(IDLE)

	# Optionally, center player
	var screen_size = get_viewport_rect().size
	global_position = screen_size / 2

func reset() -> void:
	hp = 100.0
	hunger = 100.0
	is_dead = false
	game_active = true
	velocity = Vector2.ZERO
	change_state(IDLE)
	var screen_size = get_viewport_rect().size
	global_position = screen_size / 2
