extends CanvasLayer

@export var grid_manager: Node2D
@export var player_controller: Node

func _ready():
	# We removed the auto-assignment here so it starts completely blank!
	pass

# --- State Toggle Buttons ---
func _on_walk_button_pressed():
	player_controller.set_state(player_controller.State.WALK)

func _on_build_button_pressed():
	player_controller.set_state(player_controller.State.BUILD)

func _on_dismantle_button_pressed():
	player_controller.set_state(player_controller.State.DISMANTLE)
