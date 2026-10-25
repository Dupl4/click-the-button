class_name HurtboxComponent
extends Area2D

signal hit_received(amount: float, source: Node2D)

@export var health_component: HealthComponent
@export var is_invulnerable: bool = false



func receive_hit(amount: float, source: Node2D) -> void:
	if is_invulnerable or amount <= 0.0:
		return

	if health_component != null:
		health_component.apply_damage(amount, source)

	hit_received.emit(amount, source)
