extends CharacterBody2D

@export var speed: float = 400 #50
@export var rotation_speed: float = 5.0
@export var max_tilt_angle: float = 45.0  # Max tilt in degrees

enum {IDLE, SWIM, BITE, SWIMUP, SWIMDOWN}
var state: int = IDLE

func _ready() -> void:
	change_state(IDLE)

func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position)
	var distance = direction.length()
	
	# Move towards cursor if far enough
	if distance > 5:
		direction = direction.normalized()
		velocity = direction * speed
		if velocity.y < -150:
			change_state(SWIMUP)
		elif velocity.y > 150:
			change_state(SWIMDOWN)
		else:
			change_state(SWIM)
	else:
		velocity = Vector2.ZERO
	
	if velocity.x == 0:
	#if velocity.x >= - 100 and velocity.x <= 300:
		change_state(IDLE )
		
	#debugging stats
	#print(velocity.x)
	print(velocity.y)
	
	move_and_slide()

func change_state(new_state: int) -> void:
	state = new_state
	match state:
		IDLE:
			rotation = 0
			$AnimatedSprite2D.play('idle')
		SWIM:
			$AnimatedSprite2D.play('swim')
			flip_check()
		SWIMUP:
			$AnimatedSprite2D.play('swim-up')
			flip_check()
		SWIMDOWN:
			$AnimatedSprite2D.play('swim-down')
			flip_check()
				
func flip_check():
	if velocity.x < -0.1:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x > 0.1:
		$AnimatedSprite2D.flip_h = true
	
	
