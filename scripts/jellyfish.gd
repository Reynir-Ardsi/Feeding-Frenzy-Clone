extends CharacterBody2D

@export var speed: float = 100
@export var min_state_time: float = 1.0
@export var max_state_time: float = 3.0
@export var knockback_strength: float = 150.0
@export var knockback_duration: float = 0.2
@export var max_hp: int = 2

enum {IDLE, SWIM, HURT, ATTACK, DEAD}
var state: int = IDLE

var hp: int
var direction: Vector2 = Vector2.ZERO
var state_timer: float = 0.0
var target: Node = null
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

func _ready() -> void:
	randomize()
	hp = max_hp
	change_state(IDLE)

func _process(delta: float) -> void:
	match state:
		IDLE:
			state_idle(delta)
		SWIM:
			state_swim(delta)
		HURT:
			state_hurt(delta)
		ATTACK:
			state_attack(delta)
		DEAD:
			return

	# Apply knockback if active
	if knockback_timer > 0:
		velocity = knockback_vector
		knockback_timer -= delta

	move_and_slide()

# --------------------
# STATE FUNCTIONS
# --------------------
func state_idle(delta):
	velocity = Vector2.ZERO
	state_timer -= delta
	
	if state_timer <= 0:
		change_state(SWIM)

func state_swim(delta):
	velocity = direction * speed
	state_timer -= delta
	
	if state_timer <= 0:
		change_state(IDLE)

func state_hurt(delta):
	state_timer -= delta
	
	if state_timer <= 0:
		change_state(IDLE)

func state_attack(delta):
	velocity = Vector2.ZERO
	state_timer -= delta
	
	if state_timer <= 0:
		change_state(IDLE)

# --------------------
# STATE TRANSITIONS
# --------------------
func change_state(new_state: int) -> void:
	state = new_state
	
	match state:
		IDLE:
			state_timer = randf_range(min_state_time, max_state_time)
			$AnimatedSprite2D.play("idle")

		SWIM:
			state_timer = randf_range(min_state_time, max_state_time)
			set_random_direction()
			$AnimatedSprite2D.play("swim")

		HURT:
			if target:
				# Apply knockback
				knockback_vector = (global_position - target.global_position).normalized() * knockback_strength
				knockback_timer = knockback_duration
			state_timer = 0.5
			$AnimatedSprite2D.play("hurt")

		ATTACK:
			state_timer = 0.4
			$AnimatedSprite2D.play("attack")
			if target and target.has_method("take_damage"):
				target.take_damage(1)

		DEAD:
			$AnimatedSprite2D.play("dead")
			await get_tree().create_timer(0.4).timeout
			queue_free()

# --------------------
# HELPERS
# --------------------
func set_random_direction():
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# Optional flip
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = false
	elif direction.x > 0:
		$AnimatedSprite2D.flip_h = true

func take_damage(amount: int = 1):
	hp -= amount
	if hp <= 0:
		change_state(DEAD)
	else:
		change_state(HURT)

# --------------------
# COLLISION HANDLERS
# --------------------
func _on_head_body_entered(body: Node) -> void:
	if state == DEAD:
		return
	
	if body.is_in_group("player"):
		target = body
		take_damage(1)

func _on_tail_body_entered(body: Node) -> void:
	if state == DEAD:
		return
	
	if body.is_in_group("player"):
		target = body
		change_state(ATTACK)
