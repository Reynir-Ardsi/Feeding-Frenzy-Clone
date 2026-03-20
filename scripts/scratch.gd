extends CharacterBody2D

@export var speed: float = 280
@export var rotation_speed: float = 5.0
@export var max_tilt_angle: float = 45.0  # Max tilt in degrees

var anim_sprite: AnimatedSprite2D
var facing_right: bool = true

func _ready() -> void:
	anim_sprite = $AnimatedSprite2D

func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position)
	var distance = direction.length()

	# Move towards cursor if far enough
	if distance > 5:
		direction = direction.normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Horizontal flip using flip_h
	if velocity.x > 0.1:
		anim_sprite.flip_h = true
		facing_right = true
	elif velocity.x < -0.1:
		anim_sprite.flip_h = false 
		facing_right = false

# Tilt the sprite based on whether it's facing right
	if velocity.length() > 0.1:
		var tilt_angle = velocity.angle()
		# Invert rotation if facing left
		if not facing_right:
			rotation = lerp_angle(-rotation, -tilt_angle, -rotation_speed * delta)
		# Clamp tilt to avoid excessive rotation
		tilt_angle = clamp(tilt_angle, deg_to_rad(-max_tilt_angle), deg_to_rad(max_tilt_angle))
		rotation = lerp_angle(rotation, tilt_angle, rotation_speed * delta)
	else:
		rotation = lerp_angle(rotation, 0, rotation_speed * delta)

	# Animation
	anim_sprite.animation = "idle" if velocity.length() < 0.1 else "swim"
	anim_sprite.play()
