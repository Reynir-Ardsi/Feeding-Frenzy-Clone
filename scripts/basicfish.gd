extends CharacterBody2D

@export var speed: float = 100
@export var swim_change_interval: float = 2.0  # seconds between changing direction

var direction: Vector2 = Vector2.ZERO
var state_timer: float = 0.0

func _ready() -> void:
	randomize()
	# Pick initial random direction
	set_random_direction()
	$AnimatedSprite2D.play("swim")

func _process(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0:
		set_random_direction()

	# Move fish
	velocity = direction * speed
	move_and_slide()

	# Flip sprite based on horizontal direction
	if velocity.x < -0.1:
		$AnimatedSprite2D.flip_h = true
	elif velocity.x > 0.1:
		$AnimatedSprite2D.flip_h = false

func set_random_direction() -> void:
	state_timer = swim_change_interval
	direction = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
