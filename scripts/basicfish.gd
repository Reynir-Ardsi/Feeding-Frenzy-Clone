extends CharacterBody2D

@export var speed: float = 100
@export var flee_speed: float = 100 
@export var swim_change_interval: float = 2.0 
@export var vertical_margin: float = 100.0 # How close to the edge before turning back
@export var food_value: float = 20.0

var direction: Vector2 = Vector2.ZERO
var state_timer: float = 0.0
var target_x: float
var is_fleeing: bool = false
var player: Node2D = null 

func feed_player(body: Node) -> void:
	if body and body.has_method("apply_nutrition"):
		body.apply_nutrition(food_value)

func _ready() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	# Aim for 300 pixels PAST the screen edges
	if global_position.x < viewport_size.x / 2:
		target_x = viewport_size.x + 300 # Aim far right
	else:
		target_x = -300 # Aim far left
		
	set_random_direction()
	$AnimatedSprite2D.play("swim")

func _process(delta: float) -> void:
	# 1. HANDLE DIRECTION LOGIC
	if is_fleeing and player:
		direction = (global_position - player.global_position).normalized()
		velocity = direction * flee_speed
	else:
		state_timer -= delta
		if state_timer <= 0:
			set_random_direction()
		velocity = direction * speed

	# 2. SCREEN BOUNDARY CHECK (Vertical)
	keep_in_vertical_bounds()

	# 3. MOVE & VISUALS
	move_and_slide()
	check_horizontal_despawn()
	flip_check()

func keep_in_vertical_bounds() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	
	# If too high (near Y=0), force direction to go DOWN (positive Y)
	if global_position.y < vertical_margin:
		direction.y = abs(direction.y) # Make Y positive
	
	# If too low (near bottom), force direction to go UP (negative Y)
	elif global_position.y > viewport_size.y - vertical_margin:
		direction.y = -abs(direction.y) # Make Y negative

func set_random_direction() -> void:
	state_timer = swim_change_interval
	var target_pos = Vector2(target_x, global_position.y + randf_range(-50, 50))
	direction = (target_pos - global_position).normalized()
	direction += Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
	direction = direction.normalized()

func flip_check() -> void:
	if velocity.x < -0.1:
		$AnimatedSprite2D.flip_h = true
	elif velocity.x > 0.1:
		$AnimatedSprite2D.flip_h = false
		
func check_horizontal_despawn() -> void:
	var screen_width = get_viewport_rect().size.x
	if global_position.x < -250 or global_position.x > screen_width + 250:
		queue_free()

# --- SENSORS ---

func _on_flee_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body	
		is_fleeing = true

func _on_flee_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_fleeing = false
		set_random_direction()

func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		feed_player(body)
		queue_free()
