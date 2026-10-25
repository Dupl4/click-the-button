# Efecto visual de corte para ataques cuerpo a cuerpo
class_name MeleeSlash
extends Node2D


signal slash_finished

@export var slash_radius: float = 130.0
@export var cone_angle_deg: float = 120.0
@export var damage: float = 30.0
@export var slash_color: Color = Color(0.4, 0.75, 1.0, 0.95)
@export var duration: float = 0.16

var _direction: Vector2 = Vector2.RIGHT
var _current_radius: float = 0.0
var _current_alpha: float = 1.0
var _progress: float = 0.0
var _hit_enemies: Array[Node] = []


func setup(origin_pos: Vector2, swing_dir: Vector2, dmg_val: float, radius_val: float, color_val: Color) -> void:
	global_position = origin_pos
	_direction = swing_dir.normalized()
	rotation = _direction.angle()
	damage = dmg_val
	slash_radius = radius_val
	slash_color = color_val

	# Ejecutar daño inmediato a todos los enemigos en el cono
	_execute_cleave_damage()

	# Animación visual con Tween
	var tween: Tween = create_tween()
	tween.tween_method(_animate_slash, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_tween_finished)


func _animate_slash(t: float) -> void:
	_progress = t
	_current_radius = lerpf(slash_radius * 0.35, slash_radius, t)
	_current_alpha = 1.0 - pow(t, 2.0)
	queue_redraw()


func _draw() -> void:
	var half_cone: float = deg_to_rad(cone_angle_deg * 0.5)
	var points: PackedVector2Array = PackedVector2Array()
	var inner_points: PackedVector2Array = PackedVector2Array()
	var steps: int = 24

	# Construir arco exterior
	for i in range(steps + 1):
		var ang: float = -half_cone + (float(i) / float(steps)) * (half_cone * 2.0)
		var pt: Vector2 = Vector2(cos(ang), sin(ang)) * _current_radius
		points.append(pt)

	# Arco interior para grosor de la hoja
	var inner_r: float = _current_radius * 0.55
	for i in range(steps, -1, -1):
		var ang: float = -half_cone + (float(i) / float(steps)) * (half_cone * 2.0)
		var pt: Vector2 = Vector2(cos(ang), sin(ang)) * inner_r
		inner_points.append(pt)

	var poly: PackedVector2Array = points
	poly.append_array(inner_points)

	var fill_col: Color = slash_color
	fill_col.a = _current_alpha * 0.75
	draw_colored_polygon(poly, fill_col)

	# Borde filoso brillante
	var edge_col: Color = Color.WHITE
	edge_col.a = _current_alpha
	draw_polyline(points, edge_col, 3.5, true)


func _execute_cleave_damage() -> void:
	var half_cone: float = deg_to_rad(cone_angle_deg * 0.5)
	var enemies: Array[Node] = []
	enemies.append_array(get_tree().get_nodes_in_group(&"enemy"))
	enemies.append_array(get_tree().get_nodes_in_group(&"enemies"))

	for enemy_node in enemies:
		if enemy_node is EnemyBase and is_instance_valid(enemy_node):
			var enemy: EnemyBase = enemy_node as EnemyBase
			if _hit_enemies.has(enemy):
				continue

			var to_enemy: Vector2 = enemy.global_position - global_position
			var dist: float = to_enemy.length()

			if dist <= slash_radius:
				var angle_diff: float = absf(_direction.angle_to(to_enemy))
				if angle_diff <= half_cone:
					_hit_enemies.append(enemy)
					if enemy.health_component != null:
						enemy.health_component.apply_damage(damage, self)


func _on_tween_finished() -> void:
	slash_finished.emit()
	queue_free()
