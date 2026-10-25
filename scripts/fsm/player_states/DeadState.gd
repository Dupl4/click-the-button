class_name DeadState
extends State


func enter() -> void:
	if actor is PlayerCharacter:
		var player: PlayerCharacter = actor as PlayerCharacter
		player.velocity = Vector2.ZERO
		if player.hurtbox_component != null:
			player.hurtbox_component.is_invulnerable = true
		if player.targeting_component != null:
			player.targeting_component.set_physics_process(false)
