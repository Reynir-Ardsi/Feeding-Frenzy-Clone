extends Node

var is_active = true # Set to true to start spawning
var spawn_timer = 0.0
var spawn_interval = 1.5 # Adjusted for better flow
var max_total_fish = 30

# Define scenes manually for easier indexing
var fish_basic_scenes = []
var bomb_scene = preload("res://scenes/bombfish.tscn")
var eel_scene = preload("res://scenes/eel.tscn")
var jelly_scene = preload("res://scenes/jellyfish.tscn")
var sword_scene = preload("res://scenes/swordfish.tscn")

func _ready() -> void:
	randomize()
	# Group the basic fish together
	fish_basic_scenes = [
		preload("res://scenes/fish.tscn"),
		preload("res://scenes/fish2.tscn"),
		preload("res://scenes/fish3.tscn"),
		preload("res://scenes/fish4.tscn"),
		preload("res://scenes/fish5.tscn")
	]

func _process(delta: float) -> void:
	if is_active:
		spawn_timer -= delta
		if spawn_timer <= 0:
			try_spawn()
			spawn_timer = spawn_interval

func try_spawn():
	# 1. Check Global Limit
	if get_tree().get_nodes_in_group("all_fish").size() >= max_total_fish:
		return

	# 2. Pick a random category to attempt to spawn
	# We use a weight-based list to decide what to try spawning
	var categories = ["basic", "bomb", "eel", "jelly", "sword"]
	var choice = categories[randi() % categories.size()]
	
	match choice:
		"sword":
			if get_tree().get_nodes_in_group("swordfish").size() < 2:
				spawn_fish(sword_scene, "swordfish")
		"eel":
			if get_tree().get_nodes_in_group("eel").size() < 5:
				spawn_fish(eel_scene, "eel")
		"jelly":
			if get_tree().get_nodes_in_group("jellyfish").size() < 5:
				spawn_fish(jelly_scene, "jellyfish")
		"bomb":
			if get_tree().get_nodes_in_group("bombfish").size() < 4:
				spawn_fish(bomb_scene, "bombfish")
		"basic":
			if get_tree().get_nodes_in_group("basic_fish").size() < 20:
				var random_basic = fish_basic_scenes[randi() % fish_basic_scenes.size()]
				spawn_fish(random_basic, "basic_fish")

func spawn_fish(scene: PackedScene, group_name: String):
	var fish = scene.instantiate()
	
	# Add to specific group and a general group for total count
	fish.add_to_group(group_name)
	fish.add_to_group("all_fish")
	
	var viewport_size = get_viewport().get_visible_rect().size
	var side = randi() % 2
	var spawn_pos = Vector2.ZERO
	
	if side == 0: # Left
		spawn_pos = Vector2(-50, randf_range(50, viewport_size.y - 50))
	else: # Right
		spawn_pos = Vector2(viewport_size.x + 50, randf_range(50, viewport_size.y - 50))
	
	fish.position = spawn_pos
	add_child(fish)
