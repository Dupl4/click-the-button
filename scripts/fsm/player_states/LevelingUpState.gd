class_name LevelingUpState
extends State

signal draft_screen_opened


func enter() -> void:
	if actor is PlayerCharacter:
		(actor as PlayerCharacter).velocity = Vector2.ZERO
	draft_screen_opened.emit()


func exit() -> void:
	pass
