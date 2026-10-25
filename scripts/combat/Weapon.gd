class_name Weapon
extends Node2D

signal weapon_fired(target: CharacterBody2D)
signal melee_slashed(target: CharacterBody2D)

enum WeaponMode {
	MELEE_SLASH,
	PROJECTILE_MAGIC,
	PROJECTILE_ARROW,
	SNIPER_BEAM
}

@export var weapon_name: StringName = &"BaseWeapon"
@export var damage: float = 15.0
@export var attack_range: float = 250.0
@export var cooldown_time: float = 0.8
@export var projectile_scene: PackedScene

# Modalidad de combate
@export var weapon_mode: WeaponMode = WeaponMode.MELEE_SLASH

# Parámetros avanzados de proyectil / tajo
@export var projectile_speed: float = 450.0
@export var projectile_pierce: int = 1
@export var projectile_aoe_radius: float = 0.0
@export var projectile_count: int = 1
@export var spread_angle_deg: float = 0.0
@export var weapon_color: Color = Color(0.4, 0.75, 1.0)

# Parámetros específicos de cuerpo a cuerpo
@export var melee_cone_deg: float = 120.0
@export var is_double_slash: bool = false

var _can_fire: bool = true
var _cooldown_timer: Timer


func _ready() -> void:
	_setup_timer()


func _setup_timer() -> void:
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.wait_time = cooldown_time
	_cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(_cooldown_timer)


func configure_from_class(class_data: ClassData) -> void:
	if class_data == null:
		return

	weapon_name = class_data.class_id
	damage = class_data.base_attack_power
	attack_range = class_data.base_range
	cooldown_time = class_data.base_cooldown
	projectile_speed = class_data.projectile_speed
	projectile_pierce = class_data.projectile_pierce
	projectile_aoe_radius = class_data.projectile_aoe_radius
	projectile_count = class_data.projectile_count
	spread_angle_deg = class_data.projectile_spread_deg
	weapon_color = class_data.projectile_color

	# Determinar modalidad por ID de clase
	match class_data.class_id:
		&"warrior":
			weapon_mode = WeaponMode.MELEE_SLASH
			attack_range = 130.0 # Rango estricto cuerpo a cuerpo
			is_double_slash = false
		&"mage":
			weapon_mode = WeaponMode.PROJECTILE_MAGIC
			projectile_aoe_radius = maxf(80.0, class_data.projectile_aoe_radius)
		&"archer":
			weapon_mode = WeaponMode.PROJECTILE_ARROW
			projectile_pierce = 2
			projectile_speed = 520.0

	if _cooldown_timer != null:
		_cooldown_timer.wait_time = cooldown_time


func try_fire(target: CharacterBody2D) -> bool:
	if not _can_fire or target == null or not is_instance_valid(target):
		return false

	var dist: float = global_position.distance_to(target.global_position)
	if dist > attack_range:
		return false

	_fire(target)
	return true


func _fire(target: CharacterBody2D) -> void:
	_can_fire = false
	_cooldown_timer.start(cooldown_time)

	match weapon_mode:
		WeaponMode.MELEE_SLASH:
			_perform_melee_slash(target)
		WeaponMode.PROJECTILE_MAGIC:
			_fire_projectiles(target, Projectile.ProjectileVisualType.MAGIC_ORB)
		WeaponMode.PROJECTILE_ARROW:
			_fire_projectiles(target, Projectile.ProjectileVisualType.ARROW)
		WeaponMode.SNIPER_BEAM:
			_fire_projectiles(target, Projectile.ProjectileVisualType.SNIPER_BEAM)

	weapon_fired.emit(target)


func _perform_melee_slash(target: CharacterBody2D) -> void:
	var swing_dir: Vector2 = (target.global_position - global_position).normalized()
	_spawn_single_slash(swing_dir)

	# Rasgo Berserker: segundo tajo consecutivo rápido en abanico
	if is_double_slash:
		var second_timer: SceneTreeTimer = get_tree().create_timer(0.08)
		second_timer.timeout.connect(func():
			if is_instance_valid(self) and is_inside_tree():
				var alt_dir: Vector2 = swing_dir.rotated(deg_to_rad(-15.0))
				_spawn_single_slash(alt_dir)
		)

	melee_slashed.emit(target)


func _spawn_single_slash(dir: Vector2) -> void:
	var slash: MeleeSlash = MeleeSlash.new()
	get_tree().current_scene.add_child(slash)
	slash.setup(global_position, dir, damage, attack_range, weapon_color)


func _fire_projectiles(target: CharacterBody2D, vtype: Projectile.ProjectileVisualType) -> void:
	if projectile_scene == null:
		return

	var base_dir: Vector2 = (target.global_position - global_position).normalized()
	var count: int = maxi(1, projectile_count)

	if count == 1:
		_spawn_projectile(base_dir, vtype)
	else:
		var half_spread: float = deg_to_rad(spread_angle_deg * 0.5)
		var angle_step: float = deg_to_rad(spread_angle_deg) / float(count - 1)
		var base_angle: float = base_dir.angle() - half_spread

		for i in range(count):
			var cur_angle: float = base_angle + (angle_step * float(i))
			var shot_dir: Vector2 = Vector2.from_angle(cur_angle)
			_spawn_projectile(shot_dir, vtype)


func _spawn_projectile(shot_dir: Vector2, vtype: Projectile.ProjectileVisualType) -> void:
	var proj_inst: Node = projectile_scene.instantiate()
	if proj_inst is Projectile:
		get_tree().current_scene.add_child(proj_inst)
		(proj_inst as Projectile).setup_advanced(
			global_position,
			shot_dir,
			damage,
			projectile_speed,
			projectile_pierce,
			projectile_aoe_radius,
			weapon_color,
			vtype
		)


func _on_cooldown_finished() -> void:
	_can_fire = true


func set_cooldown(new_cooldown: float) -> void:
	cooldown_time = maxf(0.05, new_cooldown)
	if _cooldown_timer != null:
		_cooldown_timer.wait_time = cooldown_time
