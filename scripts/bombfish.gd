extends CharacterBody2D

@export var speed: float = 120
@export var min_state_time: float = 1.0
@export var max_state_time: float = 3.0
@export var explosion_radius: float = 120
@export var vertical_margin: int = 300
@onready var explosion_sfx: AudioStreamPlayer = $Explosion

enum {IDLE, SWIM, DEAD}
var state: int = IDLE

var direction: Vector2 = Vector2.ZERO
var state_timer: float = 0.0
var exploded: bool = false
var target_x: float

func _ready() -> void:
	randomize()
	var viewport_size = get_viewport().get_visible_rect().size
	target_x = viewport_size.x if global_position.x < viewport_size.x / 2 else 0
	change_state(IDLE)

func _process(delta: float) -> void:
	if state == DEAD:
		return

	state_timer -= delta
	if state_timer <= 0:
		# Alternate between IDLE and SWIM
		if state == IDLE:
			change_state(SWIM)
		else:
			change_state(IDLE)

	match state:
		IDLE:
			velocity = Vector2.ZERO
		SWIM:
			velocity = direction * speed
			
			if velocity.x < -0.1:
				$AnimatedSprite2D.flip_h = true
			elif velocity.x > 0.1:
				$AnimatedSprite2D.flip_h = false
				
	keep_in_vertical_bounds()
	move_and_slide()

	# Despawn if outside screen
	var viewport_size = get_viewport().get_visible_rect().size
	if global_position.x < -100 or global_position.x > viewport_size.x + 100:
		queue_free()

# State handler
func change_state(new_state: int) -> void:
	state = new_state
	state_timer = randf_range(min_state_time, max_state_time)

	match state:
		IDLE:
			velocity = Vector2.ZERO
			if has_node("AnimatedSprite2D"):
				$AnimatedSprite2D.play("idle")

		SWIM:
			set_random_direction()
			if has_node("AnimatedSprite2D"):
				$AnimatedSprite2D.play("swim")

		DEAD:
			explode()

# Random movement direction
func set_random_direction():
	var target_pos = Vector2(target_x, global_position.y + randf_range(-50, 50))
	direction = (target_pos - global_position).normalized() + Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
	direction = direction.normalized()

func keep_in_vertical_bounds() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	
	# If too high (near Y=0), force direction to go DOWN (positive Y)
	if global_position.y < vertical_margin:
		direction.y = abs(direction.y) # Make Y positive
	
	# If too low (near bottom), force direction to go UP (negative Y)
	elif global_position.y > viewport_size.y - vertical_margin:
		direction.y = -abs(direction.y) # Make Y negative

# Explosion logic
func explode():
	exploded = true
	velocity = Vector2.ZERO
	explosion_sfx.play()
	
	# Play explosion animation if exists
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("dead")
	# Remove after short delay
	await get_tree().create_timer(0.3).timeout
	queue_free()


func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if exploded:
		return
	
	if body.has_method("take_damage"):
		body.take_damage(20)
		change_state(DEAD)
