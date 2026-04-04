extends Node2D

@onready var player = get_parent().get_node("Player")
@onready var hp_bar = $HPBar
@onready var hunger_bar = $HUNGERBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hp_bar.max_value = 100
	hp_bar.value = player.hp
	hunger_bar.max_value = 100
	hunger_bar.value = 100

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	hp_bar.value = player.hp
	hunger_bar.value = player.hunger
