class_name AttackingState
extends State


func enter() -> void:
	if actor is PlayerCharacter:
		(actor as PlayerCharacter).velocity = Vector2.ZERO


func physics_update(_delta: float) -> void:
	if not (actor is PlayerCharacter):
		return

	var player: PlayerCharacter = actor as PlayerCharacter
	var target: CharacterBody2D = player.current_target

	if target == null or not is_instance_valid(target):
		transitioned.emit(&"Idle")
		return

	var distance: float = player.global_position.distance_to(target.global_position)
	if distance > player.attack_range:
		transitioned.emit(&"Targeting")
		return

	# Delegación de disparo a las armas montadas en WeaponHolder
	for child in player.weapon_holder.get_children():
		if child is Weapon:
			(child as Weapon).try_fire(target)
