extends Node2D

@onready var player = $Player
@onready var hud = $HUD
@onready var spawner = $Spawner

@onready var bg_music: AudioStreamPlayer

var game_active: bool = false

func _ready() -> void:
	hud.show_labels()
	hud.hide_stats()
	spawner.is_active = false
	game_active = false

	# Create background music player
	bg_music = AudioStreamPlayer.new()
	add_child(bg_music)
	bg_music.stream = load("res://assets/sfx/ingame-bg-music.mp3")
	bg_music.volume_db = -10  # Adjust volume if needed

	if hud:
		hud.button_pressed.connect(_on_hud_button_pressed)
		hud.set_start_button_text("Start")
		hud.set_start_button_enabled(true)
	
	if player:
		player.died.connect(_on_player_died)

func _process(delta: float) -> void:
	pass

func _on_hud_button_pressed() -> void:
	if game_active:
		restart_game()
	elif player.is_dead:
		restart_game()
	else:
		start_game()

func start_game() -> void:
	game_active = true
	spawner.is_active = true
	player.start_game()
	hud.hide_labels()
	hud.show_stats()
	hud.set_start_button_text("Restart")
	hud.set_start_button_enabled(false)
	hud.start_timer()
	
	# Play background music
	if bg_music and not bg_music.playing:
		bg_music.play()

func restart_game() -> void:
	clear_all_fish()
	player.reset()
	start_game()

func _on_player_died() -> void:
	game_active = false
	spawner.is_active = false
	hud.set_start_button_text("Restart")
	hud.set_start_button_enabled(true)
	hud.show_labels()
	hud.show_title()
	hud.stop_timer()
	hud.set_title()
	
	if bg_music and bg_music.playing:
		bg_music.stop()

func clear_all_fish() -> void:
	for fish in get_tree().get_nodes_in_group("all_fish"):
		if fish and fish.is_inside_tree():
			fish.queue_free()
