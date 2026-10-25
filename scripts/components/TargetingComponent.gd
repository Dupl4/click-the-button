class_name TargetingComponent
extends Area2D

signal target_acquired(target: CharacterBody2D)
signal target_lost

@export var acquisition_radius: float = 300.0:
	set(value):
		acquisition_radius = maxf(10.0, value)
		_update_collision_shape()

@export var target_group: StringName = &"enemies"

var current_target: CharacterBody2D = null
var _collision_shape: CollisionShape2D


func _ready() -> void:
	_setup_collision()


func _setup_collision() -> void:
	_collision_shape = CollisionShape2D.new()
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = acquisition_radius
	_collision_shape.shape = circle_shape
	add_child(_collision_shape)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _update_collision_shape() -> void:
	if _collision_shape != null and _collision_shape.shape is CircleShape2D:
		(_collision_shape.shape as CircleShape2D).radius = acquisition_radius


func _physics_process(_delta: float) -> void:
	_evaluate_targets()


func _evaluate_targets() -> void:
	if current_target != null:
		if not is_instance_valid(current_target) or not current_target.is_inside_tree():
			_clear_target()
			return

		var dist: float = global_position.distance_to(current_target.global_position)
		if dist > acquisition_radius:
			_clear_target()

	if current_target == null:
		var nearest: CharacterBody2D = find_nearest_target()
		if nearest != null:
			_set_target(nearest)


func find_nearest_target() -> CharacterBody2D:
	var overlapping_bodies: Array[Node2D] = get_overlapping_bodies()
	var nearest_body: CharacterBody2D = null
	var shortest_distance_squared: float = INF
	var origin_position: Vector2 = global_position

	for body in overlapping_bodies:
		if body is CharacterBody2D and body.is_in_group(target_group):
			var dist_sq: float = origin_position.distance_squared_to(body.global_position)
			if dist_sq < shortest_distance_squared:
				shortest_distance_squared = dist_sq
				nearest_body = body

	return nearest_body


func _set_target(new_target: CharacterBody2D) -> void:
	current_target = new_target
	target_acquired.emit(current_target)


func _clear_target() -> void:
	current_target = null
	target_lost.emit()


func _on_body_entered(body: Node2D) -> void:
	if current_target == null and body is CharacterBody2D and body.is_in_group(target_group):
		_set_target(body)


func _on_body_exited(body: Node2D) -> void:
	if body == current_target:
		_clear_target()
