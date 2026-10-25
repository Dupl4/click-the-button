class_name StateMachine
extends Node

signal state_changed(from_state: StringName, to_state: StringName)

@export var initial_state: State

var current_state: State
var states: Dictionary = {}


func initialize(actor: CharacterBody2D) -> void:
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.actor = actor
			child.transitioned.connect(transition_to)

	if initial_state != null:
		current_state = initial_state
		current_state.enter()


func transition_to(target_state_name: StringName) -> void:
	if not states.has(target_state_name):
		push_warning("StateMachine: Estado '%s' no encontrado." % target_state_name)
		return

	var new_state: State = states[target_state_name]
	if new_state == current_state:
		return

	var old_state_name: StringName = current_state.name if current_state != null else &""
	if current_state != null:
		current_state.exit()

	current_state = new_state
	current_state.enter()
	state_changed.emit(old_state_name, target_state_name)


func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)
