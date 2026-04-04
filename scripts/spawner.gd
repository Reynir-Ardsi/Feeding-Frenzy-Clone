extends Node

var is_active = false
var spawn_timer = 0.0
var spawn_interval = 3.0  # seconds between spawns
var fish_scenes = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	# Preload fish scenes
	fish_scenes = [
		preload("res://scenes/fish.tscn"),
		preload("res://scenes/bombfish.tscn"),
		preload("res://scenes/eel.tscn"),
		preload("res://scenes/jellyfish.tscn"),
		preload("res://scenes/swordfish.tscn"),
		# Add more fish scenes if available
	]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_active:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_fish()
			spawn_timer = spawn_interval

func spawn_fish():
	#number of active fish:
	if get_child_count() >= 20:
		return
	var fish_scene = fish_scenes[randi() % fish_scenes.size()]
	var fish = fish_scene.instantiate()
	# Set random position on left or right side of the viewport
	var viewport_size = get_viewport().get_visible_rect().size
	var side = randi() % 2
	if side == 0:
		fish.position = Vector2(0, randf() * viewport_size.y)
	else:
		fish.position = Vector2(viewport_size.x, randf() * viewport_size.y)
	add_child(fish)
