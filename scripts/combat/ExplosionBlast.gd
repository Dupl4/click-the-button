# Efecto visual y de area para impactos magicos
class_name ExplosionBlast
extends Node2D


signal explosion_finished

@export var max_radius: float = 80.0
@export var damage: float = 35.0
@export var blast_color: Color = Color(0.85, 0.45, 1.0, 1.0)
@export var duration: float = 0.28

var _current_radius: float = 0.0
var _current_alpha: float = 1.0
var _hit_enemies: Array[Node] = []


func setup(impact_pos: Vector2, radius_val: float, dmg_val: float, col_val: Color = Color(0.85, 0.45, 1.0)) -> void:
	global_position = impact_pos
	max_radius = radius_val
	damage = dmg_val
	blast_color = col_val

	# Aplicar daño AoE simultáneo
	_apply_blast_damage()

	# Reproducir sonido de explosión si AudioManager está disponible
	var audio_mgr: Node = get_tree().current_scene.find_child("AudioManager", true, false)
	if audio_mgr != null and audio_mgr.has_method("play_explosion"):
		audio_mgr.call("play_explosion")

	# Animación de onda expansiva
	var tween: Tween = create_tween()
	tween.tween_method(_animate_blast, 0.0, 1.0, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_tween_finished)


func _animate_blast(t: float) -> void:
	_current_radius = lerpf(8.0, max_radius, t)
	_current_alpha = 1.0 - pow(t, 1.5)
	queue_redraw()


func _draw() -> void:
	if _current_radius <= 0.0 or _current_alpha <= 0.0:
		return

	# Disco translúcido interior
	var fill_col: Color = blast_color
	fill_col.a = _current_alpha * 0.35
	draw_circle(Vector2.ZERO, _current_radius, fill_col)

	# Anillo de choque exterior luminoso
	var ring_col: Color = blast_color
	ring_col.a = _current_alpha * 0.95
	draw_arc(Vector2.ZERO, _current_radius, 0.0, TAU, 36, ring_col, 4.0, true)

	# Destello blanco en el núcleo inicial
	if _current_alpha > 0.4:
		var core_col: Color = Color.WHITE
		core_col.a = (_current_alpha - 0.4) * 1.5
		draw_circle(Vector2.ZERO, _current_radius * 0.3, core_col)


func _apply_blast_damage() -> void:
	var enemies: Array[Node] = []
	enemies.append_array(get_tree().get_nodes_in_group(&"enemy"))
	enemies.append_array(get_tree().get_nodes_in_group(&"enemies"))

	for enemy_node in enemies:
		if enemy_node is EnemyBase and is_instance_valid(enemy_node):
			var enemy: EnemyBase = enemy_node as EnemyBase
			if _hit_enemies.has(enemy):
				continue

			var dist: float = global_position.distance_to(enemy.global_position)
			if dist <= max_radius:
				_hit_enemies.append(enemy)
				if enemy.health_component != null:
					enemy.health_component.apply_damage(damage, self)


func _on_tween_finished() -> void:
	explosion_finished.emit()
	queue_free()
