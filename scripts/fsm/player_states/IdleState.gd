class_name IdleState
extends State


func enter() -> void:
	if actor is PlayerCharacter:
		(actor as PlayerCharacter).velocity = Vector2.ZERO


func physics_update(_delta: float) -> void:
	if not (actor is PlayerCharacter):
		return

	var player: PlayerCharacter = actor as PlayerCharacter
	if player.current_target != null:
		transitioned.emit(&"Targeting")
