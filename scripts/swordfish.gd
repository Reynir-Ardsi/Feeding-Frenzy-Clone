extends CharacterBody2D

@export var speed: float = 180
@export var dash_speed: float = 400
@export var dash_duration: float = 0.3
@export var knockback_strength: float = 200
@export var knockback_duration: float = 0.2
@export var chase_time: float = 2.0
@export var max_hp: int = 5

enum {IDLE, SWIM, HURT, ATTACK, DEAD, CHASE, DASH}
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
		CHASE:
			state_chase(delta)
		DASH:
			state_dash(delta)
		HURT:
			state_hurt(delta)
		ATTACK:
			state_attack(delta)
		DEAD:
			return
	
	flip_check()

	# Apply knockback
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

func state_chase(delta):
	if target:
		direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		state_timer -= delta
		if state_timer <= 0:
			change_state(IDLE)

func state_dash(delta):
	if target:
		direction = (target.global_position - global_position).normalized()
		velocity = direction * dash_speed
	state_timer -= delta
	if state_timer <= 0:
		change_state(IDLE)

func state_hurt(delta):
	velocity = Vector2.ZERO
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
			state_timer = randf_range(1.0, 3.0)
			$AnimatedSprite2D.play("idle")

		SWIM:
			state_timer = randf_range(1.0, 3.0)
			#set_random_direction()
			$AnimatedSprite2D.play("swim")
			#flip_check()

		CHASE:
			state_timer = chase_time
			$AnimatedSprite2D.play("swim")
			#flip_check()

		DASH:
			state_timer = dash_duration
			$AnimatedSprite2D.play("attack")

		HURT:
			state_timer = 0.5
			$AnimatedSprite2D.play("hurt")
			if target:
				knockback_vector = (global_position - target.global_position).normalized() * knockback_strength
				knockback_timer = knockback_duration
				# Face player
				if target.global_position.x > global_position.x:
					$AnimatedSprite2D.flip_h = true
				else:
					$AnimatedSprite2D.flip_h = false

		ATTACK:
			state_timer = 0.4
			$AnimatedSprite2D.play("attack")

		DEAD:
			$AnimatedSprite2D.play("dead")
			await get_tree().create_timer(0.3).timeout
			queue_free()

# --------------------
# HELPERS
# --------------------

func flip_check():
	if velocity.x < -0.1:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x > 0.1:
		$AnimatedSprite2D.flip_h = true
#func flip_check():
	#if velocity.x < -0.1:
		#$AnimatedSprite2D.flip_h = false
		#flip_collision_shapes(false)
	#elif velocity.x > 0.1:
		#$AnimatedSprite2D.flip_h = true
		#flip_collision_shapes(true)
#
## Mirror all collision shapes horizontally relative to the parent
#func flip_collision_shapes(flip_h: bool):
	## TailArea, SwordArea, HitDetectionArea, AggroArea
	#var shapes = [$tail, $sword, $hitdetection, $aggro]
	#for shape in shapes:
		#shape.position.x = abs(shape.position.x) if flip_h else -abs(shape.position.x)

#func set_random_direction():
	#direction = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
	#if direction.x < 0:
		#$AnimatedSprite2D.flip_h = false
	#elif direction.x > 0:
		#$AnimatedSprite2D.flip_h = true

func take_damage(amount: int = 1):
	if state == DEAD:
		return
	hp -= amount
	if hp <= 0:
		change_state(DEAD)
	else:
		change_state(HURT)

# --------------------
# COLLISION SIGNALS
# --------------------
func _on_aggro_body_entered(body: Node) -> void:
	if state == DEAD:
		return
	if body.is_in_group("player"):
		target = body
		change_state(CHASE)

func _on_tail_body_entered(body: Node) -> void:
	if state == DEAD:
		return
	if body.is_in_group("player"):
		target = body
		take_damage(1)
		if $AnimatedSprite2D.flip_h == true:
			$AnimatedSprite2D.flip_h = false
		elif $AnimatedSprite2D.flip_h == false:
			$AnimatedSprite2D.flip_h = true
			

func _on_hit_detection_body_entered(body: Node) -> void:
	if state == DEAD:
		return
	if body.is_in_group("player"):
		target = body
		change_state(DASH)

func _on_sword_body_entered(body: Node) -> void:
	pass  # currently does nothing
