class_name StateMachine
extends Node

signal transitioned(state_name)

export var initial_state = NodePath()
onready var state: State = get_node(initial_state)


func _ready() -> void:
	yield(owner, "ready")
	for child in get_children():
		child.state_machine = self
	state.enter()
	
func _unhandled_input(event):
	state.handle_input(event)

func _process(delta):
	state.update(delta)
	
func _physics_process(delta):
	state.physics_update(delta)
	
func transition_to(target_state_name: String, message: Dictionary = {}):
	if not has_node(target_state_name):
		return # erro pois não possui o estado requisitado
	state.exit()
	state = get_node(target_state_name)
	state.enter(message)
	emit_signal("transitioned", state.name)
