extends CharacterBody2D

@export var speed: float = 100
@export var flee_speed: float = 150 # Scared fish are faster
@export var attack_range: float = 150
@export var max_hp: int = 3
@export var attack_duration: float = 0.8
@export var knockback_strength: float = 200
@export var knockback_duration: float = 0.2
@export var attack_interval: float = 2.0
@export var vertical_margin: float = 50.0

# Added FLEEING to the enum
enum {PASSIVE, ATTACKING, HURT, DEAD, SWIM, IDLE, FLEEING}
var state: int = IDLE

var hp: int
var player: Node2D = null # renamed from target for clarity
var state_timer: float = 0.0
var attack_cooldown_timer: float = 0.0
var direction: Vector2 = Vector2.ZERO
var target_x: float

# Knockback
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

func _ready() -> void:
	randomize()
	var viewport_size = get_viewport().get_visible_rect().size
	target_x = viewport_size.x if position.x < viewport_size.x / 2 else 0
	hp = max_hp
	attack_cooldown_timer = randf_range(0.0, attack_interval)
	change_state(IDLE)

func _process(delta: float) -> void:
	match state:
		IDLE:
			state_idle(delta)
		SWIM:
			state_swim(delta)
		FLEEING:
			state_fleeing(delta)
		ATTACKING:
			state_attacking(delta)
		HURT:
			state_hurt(delta)
		DEAD:
			return

	flip_check()
	keep_in_vertical_bounds()

	# Apply movement
	if knockback_timer > 0:
		velocity = knockback_vector
		knockback_timer -= delta
	else:
		if state != DEAD:
			# Use flee_speed if fleeing, otherwise normal speed
			var current_speed = flee_speed if state == FLEEING else speed
			velocity = direction * current_speed

	move_and_slide()
	check_boundaries()

	# Only cooldown attack if NOT fleeing
	if state not in [DEAD, ATTACKING, HURT, FLEEING]:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			change_state(ATTACKING)
			attack_cooldown_timer = attack_interval

# --------------------
# STATE FUNCTIONS
# --------------------

func state_fleeing(delta: float):
	if player:
		# Keep updating direction to move AWAY from player
		direction = (global_position - player.global_position).normalized()
	else:
		change_state(SWIM)

# (Other state functions like idle/swim remain the same)
func state_idle(delta: float):
	state_timer -= delta
	if state_timer <= 0: change_state(SWIM)

func state_swim(delta: float):
	state_timer -= delta
	if state_timer <= 0: change_state(IDLE)

func state_attacking(delta: float):
	state_timer -= delta
	if state_timer <= 0: change_state(SWIM)

func state_hurt(delta: float):
	state_timer -= delta
	if state_timer <= 0: change_state(SWIM)

# --------------------
# STATE TRANSITIONS
# --------------------
func change_state(new_state: int) -> void:
	if state == DEAD: return # Can't change state if dead
	
	state = new_state
	match state:
		IDLE:
			state_timer = randf_range(1.0, 3.0)
			$AnimatedSprite2D.play("idle")
		SWIM:
			state_timer = randf_range(1.0, 3.0)
			set_random_direction()
			$AnimatedSprite2D.play("swim")
		FLEEING:
			$AnimatedSprite2D.play("swim") # Use swim anim for fleeing
		ATTACKING:
			state_timer = attack_duration
			$AnimatedSprite2D.play("attack")
		HURT:
			if player:
				knockback_vector = (global_position - player.global_position).normalized() * knockback_strength
				knockback_timer = knockback_duration
			state_timer = 0.5
			$AnimatedSprite2D.play("hurt")
		DEAD:
			$AnimatedSprite2D.play("dead")
			await get_tree().create_timer(0.5).timeout
			queue_free()

# --------------------
# HELPERS
# --------------------

func set_random_direction():
	var target_pos = Vector2(target_x, position.y + randf_range(-50, 50))
	direction = (target_pos - position).normalized()
	direction += Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
	direction = direction.normalized()

func keep_in_vertical_bounds():
	var v_size = get_viewport().get_visible_rect().size
	if global_position.y < vertical_margin:
		direction.y = abs(direction.y)
	elif global_position.y > v_size.y - vertical_margin:
		direction.y = -abs(direction.y)

func check_boundaries():
	var v_size = get_viewport().get_visible_rect().size
	if position.x < -200 or position.x > v_size.x + 200:
		queue_free()

func flip_check():
	if velocity.x < -0.1: $AnimatedSprite2D.flip_h = true
	elif velocity.x > 0.1: $AnimatedSprite2D.flip_h = false

func take_damage(amount: int = 1):
	if state == DEAD or state == HURT: return
	hp -= amount
	change_state(DEAD if hp <= 0 else HURT)

# --------------------
# SIGNALS
# --------------------

func _on_flee_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		change_state(FLEEING)

func _on_flee_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		change_state(SWIM)

func _on_hit_area_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		take_damage(1)
