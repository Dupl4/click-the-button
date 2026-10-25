# Arco de impacto para ataques cuerpo a cuerpo
class_name SlashArc
extends Area2D


@export var lifetime: float = 0.18
@export var sweep_angle_deg: float = 120.0
@export var slash_radius: float = 110.0
@export var slash_color: Color = Color(0.4, 0.7, 1.0, 0.9)

var damage: float = 30.0
var _time_alive: float = 0.0
var _hit_enemies: Array[Node] = []


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func setup_slash(pos: Vector2, target_dir: Vector2, dmg: float, radius_val: float, col: Color) -> void:
	global_position = pos
	rotation = target_dir.angle()
	damage = dmg
	slash_radius = radius_val
	slash_color = col

	# Ajustar el CollisionPolygon2D para coincidir con el arco
	_setup_collision_shape()
	queue_redraw()


func _setup_collision_shape() -> void:
	var col_shape: CollisionPolygon2D = get_node_or_null("CollisionPolygon2D")
	if col_shape == null:
		col_shape = CollisionPolygon2D.new()
		col_shape.name = "CollisionPolygon2D"
		add_child(col_shape)

	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)

	var half_angle: float = deg_to_rad(sweep_angle_deg * 0.5)
	var segments: int = 12
	for i in range(segments + 1):
		var ang: float = -half_angle + (float(i) / float(segments)) * (half_angle * 2.0)
		points.append(Vector2(cos(ang), sin(ang)) * slash_radius)

	col_shape.polygon = points


func _process(delta: float) -> void:
	_time_alive += delta
	queue_redraw()

	if _time_alive >= lifetime:
		queue_free()


func _draw() -> void:
	var progress: float = clampf(_time_alive / lifetime, 0.0, 1.0)
	var alpha: float = (1.0 - progress) * slash_color.a
	var cur_col: Color = slash_color
	cur_col.a = alpha

	var half_angle: float = deg_to_rad(sweep_angle_deg * 0.5)
	var segments: int = 16
	var points: PackedVector2Array = PackedVector2Array()
	var inner_points: PackedVector2Array = PackedVector2Array()

	var inner_radius: float = slash_radius * 0.4

	for i in range(segments + 1):
		var ang: float = -half_angle + (float(i) / float(segments)) * (half_angle * 2.0)
		points.append(Vector2(cos(ang), sin(ang)) * (slash_radius * (0.8 + 0.2 * (1.0 - progress))))
		inner_points.append(Vector2(cos(ang), sin(ang)) * inner_radius)

	# Dibujar arco curvado de espada
	draw_polyline(points, cur_col, 4.0 * (1.0 - progress * 0.5), true)

	# Filo blanco brillante en la cresta del corte
	var edge_col: Color = Color(1.0, 1.0, 1.0, alpha)
	draw_polyline(points, edge_col, 2.0, true)


func _on_area_entered(area: Area2D) -> void:
	if area == null or not is_instance_valid(area):
		return

	var target_entity: Node = area.owner if area.owner != null else area
	if _hit_enemies.has(target_entity):
		return

	if area is HurtboxComponent:
		_hit_enemies.append(target_entity)
		(area as HurtboxComponent).receive_hit(damage, self)
	elif area.owner is EnemyBase and (area.owner as EnemyBase).health_component != null:
		_hit_enemies.append(target_entity)
		(area.owner as EnemyBase).health_component.apply_damage(damage, self)


func _on_body_entered(body: Node2D) -> void:
	if body is EnemyBase and not _hit_enemies.has(body):
		_hit_enemies.append(body)
		if (body as EnemyBase).health_component != null:
			(body as EnemyBase).health_component.apply_damage(damage, self)
