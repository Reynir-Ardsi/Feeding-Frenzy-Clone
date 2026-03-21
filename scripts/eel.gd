extends CharacterBody2D

@export var speed: float = 100
@export var attack_range: float = 150
@export var max_hp: int = 3
@export var attack_duration: float = 0.8
@export var knockback_strength: float = 200
@export var knockback_duration: float = 0.2
@export var attack_interval: float = 2.0  # seconds between automatic attacks

enum {PASSIVE, ATTACKING, HURT, DEAD, SWIM, IDLE}
var state: int = IDLE

var hp: int
var target: Node = null
var state_timer: float = 0.0
var attack_cooldown_timer: float = 0.0
var direction: Vector2 = Vector2.ZERO

# Knockback
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

func _ready() -> void:
	randomize()
	hp = max_hp
	attack_cooldown_timer = randf_range(0.0, attack_interval)
	change_state(IDLE)

func _process(delta: float) -> void:
	match state:
		IDLE:
			state_idle(delta)
		SWIM:
			state_swim(delta)
		PASSIVE:
			state_passive(delta)
		ATTACKING:
			state_attacking(delta)
		HURT:
			state_hurt(delta)
		DEAD:
			return

	flip_check()

	# Apply movement or knockback
	if knockback_timer > 0:
		velocity = knockback_vector
		knockback_timer -= delta
	else:
		# Normal movement always happens unless dead
		if state != DEAD:
			velocity = direction * speed

	move_and_slide()

	# Countdown attack timer and trigger attack if ready
	if state not in [DEAD, ATTACKING, HURT]:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			change_state(ATTACKING)
			attack_cooldown_timer = attack_interval

func flip_check():
	if velocity.x < -0.1:
		$AnimatedSprite2D.flip_h = true
	elif velocity.x > 0.1:
		$AnimatedSprite2D.flip_h = false

# --------------------
# STATE FUNCTIONS
# --------------------
func state_idle(delta: float):
	$AnimatedSprite2D.play("idle")
	state_timer -= delta
	if state_timer <= 0:
		change_state(SWIM)

func state_swim(delta: float):
	$AnimatedSprite2D.play("swim")
	state_timer -= delta
	if state_timer <= 0:
		change_state(IDLE)

func state_passive(delta: float):
	if target:
		var dist = global_position.distance_to(target.global_position)
		if dist <= attack_range:
			change_state(ATTACKING)

func state_attacking(delta: float):
	state_timer -= delta
	if state_timer <= 0:
		change_state(PASSIVE)

func state_hurt(delta: float):
	state_timer -= delta
	if state_timer <= 0:
		change_state(PASSIVE)

# --------------------
# STATE TRANSITIONS
# --------------------
func change_state(new_state: int) -> void:
	state = new_state
	match state:
		IDLE:
			state_timer = randf_range(1.0, 3.0)
			$AnimatedSprite2D.play("idle")
			direction = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
		SWIM:
			state_timer = randf_range(1.0, 3.0)
			direction = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
			$AnimatedSprite2D.play("swim")
		PASSIVE:
			$AnimatedSprite2D.play("swim")
		ATTACKING:
			state_timer = attack_duration
			$AnimatedSprite2D.play("attack")
		HURT:
			if target:
				# Apply knockback
				knockback_vector = (global_position - target.global_position).normalized() * knockback_strength
				knockback_timer = knockback_duration
			state_timer = 0.5
			$AnimatedSprite2D.play("hurt")
		DEAD:
			$AnimatedSprite2D.play("dead")
			await get_tree().create_timer(0.5).timeout
			queue_free()

# --------------------
# DAMAGE HANDLER
# --------------------
func take_damage(amount: int = 1):
	if state == DEAD or state == ATTACKING:
		return
	hp -= amount
	if hp <= 0:
		change_state(DEAD)
	else:
		# Set knockback here
		if target:
			knockback_vector = (global_position - target.global_position).normalized() * knockback_strength
			knockback_timer = knockback_duration
		change_state(HURT)

# --------------------
# COLLISION SIGNAL
# --------------------
func _on_area_2d_body_entered(body: Node2D) -> void:
	if state == DEAD:
		return
	if body.is_in_group("player"):
		take_damage(1)
