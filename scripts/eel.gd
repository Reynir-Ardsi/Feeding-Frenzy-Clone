extends CharacterBody2D

@export var speed: float = 100
@export var flee_speed: float = 100
@export var attack_range: float = 150
@export var max_hp: int = 3
@export var attack_duration: float
@export var knockback_strength: float = 200
@export var knockback_duration: float = 0.2
@export var attack_interval: float = 2.0
@export var vertical_margin: float = 300.0
@export var is_fleeing: bool

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
var last_attacker: Node = null
const FOOD_PER_HP: float = 20.0

func get_food_value() -> float:
	return float(max_hp) * FOOD_PER_HP

func feed_player(body: Node) -> void:
	if body and body.has_method("apply_nutrition"):
		body.apply_nutrition(get_food_value())

func mark_attacker(body: Node) -> void:
	if body and (body.name == "Player" or body.is_in_group("player")):
		last_attacker = body

func _ready() -> void:
	randomize()
	attack_duration = randf_range(0.8, 3.0)
	var viewport_size = get_viewport().get_visible_rect().size
	target_x = viewport_size.x if global_position.x < viewport_size.x / 2 else 0
	hp = max_hp
	attack_cooldown_timer = randf_range(0.0, attack_interval)
	change_state(IDLE)

func _process(delta: float) -> void:
	# 1. RUN THE STATE LOGIC (Animations/Timers)
	match state:
		IDLE: state_idle(delta)
		SWIM: state_swim(delta)
		ATTACKING: state_attacking(delta)
		HURT: state_hurt(delta)
		DEAD: return

	# 2. CALCULATE DIRECTION & VELOCITY
	if knockback_timer > 0:
		# Knockback takes priority over everything
		velocity = knockback_vector
		knockback_timer -= delta
	else:
		# Determine direction
		if is_fleeing and player:
			direction = (global_position - player.global_position).normalized()
			velocity = direction * flee_speed
		else:
			# Normal state-based speed (IDLE/SWIM)
			velocity = direction * speed

	# 3. PHYSICS & BOUNDARIES
	move_and_slide()
	flip_check()
	keep_in_vertical_bounds()
	check_boundaries()

	# 4. ATTACK COOLDOWN
	# We removed "FLEEING" from the list so it can attack while running!
	if state not in [DEAD, ATTACKING, HURT]:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			change_state(ATTACKING)
			attack_cooldown_timer = attack_interval

# --------------------
# STATE FUNCTIONS
# --------------------

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
			if last_attacker:
				feed_player(last_attacker)
			await get_tree().create_timer(0.5).timeout
			queue_free()

# --------------------
# HELPERS
# --------------------

func current_action():
	if state != ATTACKING:
		take_damage(1)
	#else:
		#$Player.hit(stun)

func set_random_direction():
	var target_pos = Vector2(target_x, global_position.y + randf_range(-50, 50))
	direction = (target_pos - global_position).normalized()
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
	if global_position.x < -200 or global_position.x > v_size.x + 200:
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
		is_fleeing = true

func _on_flee_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_fleeing = false

func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		mark_attacker(body)
		current_action()
