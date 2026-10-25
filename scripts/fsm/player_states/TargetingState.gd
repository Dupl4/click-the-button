class_name TargetingState
extends State


func physics_update(_delta: float) -> void:
	if not (actor is PlayerCharacter):
		return

	var player: PlayerCharacter = actor as PlayerCharacter
	var target: CharacterBody2D = player.current_target

	if target == null or not is_instance_valid(target):
		transitioned.emit(&"Idle")
		return

	var distance: float = player.global_position.distance_to(target.global_position)

	# Si está dentro del rango de ataque, pasa a atacar
	if distance <= player.attack_range:
		player.velocity = Vector2.ZERO
		transitioned.emit(&"Attacking")
		return

	# Si está fuera del rango pero en rango de adquisición, se desplaza hacia el objetivo
	var direction: Vector2 = (target.global_position - player.global_position).normalized()
	player.velocity = direction * player.move_speed
	player.move_and_slide()
