class_name State
extends Node

@warning_ignore("unused_signal")
signal transitioned(next_state_name: StringName)

var actor: CharacterBody2D


func enter() -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
