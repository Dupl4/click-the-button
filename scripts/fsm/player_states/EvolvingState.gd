class_name EvolvingState
extends State

signal evolution_started
signal evolution_completed

@export var evolution_duration: float = 2.0


func enter() -> void:
	if actor is PlayerCharacter:
		(actor as PlayerCharacter).velocity = Vector2.ZERO

	evolution_started.emit()

	var timer: SceneTreeTimer = actor.get_tree().create_timer(evolution_duration)
	timer.timeout.connect(_on_evolution_timeout)


func _on_evolution_timeout() -> void:
	evolution_completed.emit()
	transitioned.emit(&"Idle")
