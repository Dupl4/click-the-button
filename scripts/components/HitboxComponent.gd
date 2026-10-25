class_name HitboxComponent
extends Area2D

signal hit_registered(target: HurtboxComponent, damage_dealt: float)

@export var damage: float = 10.0
@export var knockback_force: float = 0.0
@export var is_active: bool = true



func register_impact(hurtbox: HurtboxComponent) -> void:
	if not is_active or hurtbox == null:
		return

	var applied_damage: float = damage
	hurtbox.receive_hit(applied_damage, self)
	hit_registered.emit(hurtbox, applied_damage)
