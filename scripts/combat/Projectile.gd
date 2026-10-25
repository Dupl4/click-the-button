class_name Projectile
extends Area2D

signal projectile_despawned

enum ProjectileVisualType {
	GENERIC,
	ARROW,
	MAGIC_ORB,
	SNIPER_BEAM
}

@export var speed: float = 400.0
@export var lifetime: float = 3.0
@export var pierce_count: int = 1
@export var aoe_radius: float = 0.0
@export var visual_type: ProjectileVisualType = ProjectileVisualType.GENERIC

@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var visual: Polygon2D = $Visual

var direction: Vector2 = Vector2.RIGHT
var _current_pierces: int = 0
var _time_alive: float = 0.0
var _hit_targets: Array[Node] = []


func _ready() -> void:
	area_entered.connect(_on_area_hit)
	body_entered.connect(_on_body_hit)
	if hitbox_component != null:
		hitbox_component.area_entered.connect(_on_area_hit)
		hitbox_component.body_entered.connect(_on_body_hit)


func setup(launch_position: Vector2, target_direction: Vector2, damage_val: float) -> void:
	global_position = launch_position
	direction = target_direction.normalized()
	rotation = direction.angle()

	if hitbox_component != null:
		hitbox_component.damage = damage_val


func setup_advanced(
	launch_position: Vector2,
	target_direction: Vector2,
	damage_val: float,
	speed_val: float,
	pierce_val: int,
	aoe_val: float,
	proj_color: Color,
	type_val: ProjectileVisualType = ProjectileVisualType.GENERIC
) -> void:
	setup(launch_position, target_direction, damage_val)
	speed = speed_val
	pierce_count = maxi(1, pierce_val)
	aoe_radius = aoe_val
	visual_type = type_val

	_configure_visual(proj_color)


func _configure_visual(proj_color: Color) -> void:
	if visual == null:
		return

	visual.color = proj_color

	match visual_type:
		ProjectileVisualType.ARROW:
			# Flecha alargada y aerodinámica con punta afilada y muesca posterior
			visual.polygon = PackedVector2Array([
				Vector2(16.0, 0.0),
				Vector2(-10.0, -3.5),
				Vector2(-6.0, 0.0),
				Vector2(-10.0, 3.5)
			])
		ProjectileVisualType.MAGIC_ORB:
			# Orbe mágico circular facetado con mayor tamaño
			var pts: PackedVector2Array = PackedVector2Array()
			var r: float = 9.0
			for i in range(12):
				var ang: float = (float(i) / 12.0) * TAU
				pts.append(Vector2(cos(ang), sin(ang)) * r)
			visual.polygon = pts
		ProjectileVisualType.SNIPER_BEAM:
			# Rayo láser alargado de alta penetración
			visual.polygon = PackedVector2Array([
				Vector2(32.0, -2.5),
				Vector2(32.0, 2.5),
				Vector2(-32.0, 2.5),
				Vector2(-32.0, -2.5)
			])
		_:
			# Visual estándar
			visual.polygon = PackedVector2Array([
				Vector2(8.0, 0.0),
				Vector2(-6.0, -4.0),
				Vector2(-6.0, 4.0)
			])


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	_time_alive += delta
	if _time_alive >= lifetime:
		# Si es un proyectil explosivo y se agota su tiempo de vida, detona en su posición final
		if aoe_radius > 0.0:
			_spawn_explosion(hitbox_component.damage if hitbox_component != null else 35.0)
		_destroy()


func _on_area_hit(area: Area2D) -> void:
	if area == null or not is_instance_valid(area):
		return

	var target_entity: Node = area.owner if area.owner != null else area
	if _hit_targets.has(target_entity):
		return

	var dmg: float = hitbox_component.damage if hitbox_component != null else 25.0
	var registered: bool = false

	if area is HurtboxComponent:
		(area as HurtboxComponent).receive_hit(dmg, self)
		registered = true
	elif area.owner is EnemyBase and (area.owner as EnemyBase).health_component != null:
		(area.owner as EnemyBase).health_component.apply_damage(dmg, self)
		registered = true

	if registered:
		_hit_targets.append(target_entity)
		_handle_impact_effects(dmg)


func _on_body_hit(body: Node2D) -> void:
	if body == null or not is_instance_valid(body) or _hit_targets.has(body):
		return

	if body is EnemyBase:
		_hit_targets.append(body)
		var dmg: float = hitbox_component.damage if hitbox_component != null else 25.0
		if (body as EnemyBase).health_component != null:
			(body as EnemyBase).health_component.apply_damage(dmg, self)
		_handle_impact_effects(dmg)


func _handle_impact_effects(base_damage: float) -> void:
	if aoe_radius > 0.0:
		_spawn_explosion(base_damage)

	_current_pierces += 1
	if _current_pierces >= pierce_count:
		_destroy()


func _spawn_explosion(dmg_val: float) -> void:
	var blast: ExplosionBlast = ExplosionBlast.new()
	var blast_color: Color = visual.color if visual != null else Color(0.85, 0.45, 1.0)
	get_tree().current_scene.add_child(blast)
	blast.setup(global_position, aoe_radius, dmg_val, blast_color)


func _destroy() -> void:
	projectile_despawned.emit()
	queue_free()
