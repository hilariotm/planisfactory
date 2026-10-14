extends Node

# Define our three core states
enum State { WALK, BUILD, DISMANTLE }

# The player defaults to Walk mode
var current_state: State = State.WALK

# A signal so other UI elements can react when the state changes
signal state_changed(new_state)

func set_state(new_state: State):
	current_state = new_state
	state_changed.emit(new_state)
