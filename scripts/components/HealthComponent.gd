class_name HealthComponent
extends Node

signal health_changed(current_health: float, max_health: float)
signal health_depleted
signal damage_taken(amount: float, source: Node2D)
signal healed(amount: float)

@export var max_health: float = 100.0:
	set(value):
		max_health = maxf(1.0, value)
		if current_health > max_health:
			current_health = max_health

var current_health: float = 100.0
var is_invulnerable: bool = false


func _ready() -> void:
	current_health = max_health


func apply_damage(amount: float, source: Node2D = null) -> void:
	if is_invulnerable or current_health <= 0.0 or amount <= 0.0:
		return

	current_health = maxf(0.0, current_health - amount)
	damage_taken.emit(amount, source)
	health_changed.emit(current_health, max_health)

	if current_health == 0.0:
		health_depleted.emit()


func apply_heal(amount: float) -> void:
	if current_health <= 0.0 or amount <= 0.0:
		return

	current_health = minf(max_health, current_health + amount)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)


func is_alive() -> bool:
	return current_health > 0.0
