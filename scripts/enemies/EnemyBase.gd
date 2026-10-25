class_name EnemyBase
extends CharacterBody2D

signal enemy_defeated(xp_reward: float)

@export var move_speed: float = 80.0
@export var xp_value: float = 15.0
@export var is_elite: bool = false
@export var is_boss: bool = false

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent

var target_player: CharacterBody2D = null


func _ready() -> void:
	add_to_group(&"enemies")
	if health_component != null:
		health_component.health_depleted.connect(_on_health_depleted)
		health_component.damage_taken.connect(_on_damage_taken)


func _physics_process(_delta: float) -> void:
	if target_player == null or not is_instance_valid(target_player):
		velocity = Vector2.ZERO
		return

	var direction: Vector2 = (target_player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()


func _on_damage_taken(_amount: float, _source: Node2D) -> void:
	if has_node("Visual"):
		var visual: CanvasItem = get_node("Visual") as CanvasItem
		visual.modulate = Color(3.0, 3.0, 3.0) # Hit flash
		var tween: Tween = create_tween()
		tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0), 0.08)


func _on_health_depleted() -> void:
	enemy_defeated.emit(xp_value)
	# Desactivar colisiones para evitar dobles golpes al morir
	set_physics_process(false)
	if has_node("CollisionShape2D"):
		($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)
	if hurtbox_component != null:
		hurtbox_component.set_deferred("monitoring", false)
		hurtbox_component.set_deferred("monitorable", false)

	# Animación de disolución/encogimiento
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.finished.connect(queue_free)
