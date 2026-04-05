extends Node2D

signal button_pressed

@onready var player = get_parent().get_node("Player")
@onready var hp_bar = $HPBar
@onready var hunger_bar = $HUNGERBar
@onready var start_button = find_start_button()

func _ready() -> void:
	hp_bar.max_value = 100
	hp_bar.value = player.hp
	hunger_bar.max_value = 100
	hunger_bar.value = 100

	if start_button:
		start_button.text = "Start"
		start_button.disabled = false

func _process(delta: float) -> void:
	hp_bar.value = player.hp
	hunger_bar.value = player.hunger

# --------------------
#       SIGNALS
# --------------------

func _on_button_pressed() -> void:
	emit_signal("button_pressed")

func set_start_button_text(text: String) -> void:
	if start_button:
		start_button.text = text

func set_start_button_enabled(enabled: bool) -> void:
	if start_button:
		start_button.disabled = not enabled
	
func find_start_button() -> Button:
	var	btn = get_node_or_null("Button")
	if btn:
		return btn
	return find_child("Button", true, false)
	
func hide_stats() -> void:
	$HPBar.hide()
	$HUNGERBar.hide()
	$Time.hide()
	
func show_stats() -> void:
	$HPBar.show()
	$HUNGERBar.show()
	$Time.show()

func hide_labels() -> void:
	$Button.hide()
	$Title.hide()
	$Score.hide()
	
func show_labels() -> void:
	$Button.show()
	$Score.show()
