class_name ClickManager
extends Node

signal click_processed(xp_gained: float)
signal chest_spawn_requested(spawn_position: Vector2)
signal critical_click_triggered(multiplier: float)

@export var base_xp_per_click: float = 12.0
@export var click_power_multiplier: float = 1.0
@export var crit_chance: float = 0.08
@export var crit_multiplier: float = 2.0
@export var chest_spawn_chance: float = 0.08
@export var spawn_radius: float = 180.0

var total_clicks: int = 0
var total_xp_generated: float = 0.0


func register_click(custom_pos: Vector2 = Vector2.INF) -> void:
	total_clicks += 1

	var is_crit: bool = randf() < crit_chance
	var multiplier: float = click_power_multiplier
	if is_crit:
		multiplier *= crit_multiplier
		critical_click_triggered.emit(crit_multiplier)

	var xp_earned: float = base_xp_per_click * multiplier
	total_xp_generated += xp_earned
	click_processed.emit(xp_earned)

	_check_chest_spawn(custom_pos)


func _check_chest_spawn(custom_pos: Vector2) -> void:
	var roll: float = randf()
	if roll <= chest_spawn_chance:
		var target_pos: Vector2 = custom_pos
		if target_pos == Vector2.INF:
			target_pos = _generate_spawn_position()
		chest_spawn_requested.emit(target_pos)


func _generate_spawn_position() -> Vector2:
	var player_node: Node = get_tree().get_first_node_in_group(&"player")
	if player_node is Node2D:
		var angle: float = randf() * TAU
		var dist: float = randf_range(70.0, spawn_radius)
		return (player_node as Node2D).global_position + Vector2.from_angle(angle) * dist

	return Vector2(randf_range(-200.0, 200.0), randf_range(-150.0, 150.0))


func set_class_multiplier(mult: float) -> void:
	click_power_multiplier = maxf(0.1, mult)


func set_multipliers(power_mult: float, chest_mult: float = 1.0) -> void:
	click_power_multiplier = maxf(0.1, power_mult)
	chest_spawn_chance = clampf(chest_spawn_chance * chest_mult, 0.0, 1.0)
