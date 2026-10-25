class_name PlayerCharacter
extends CharacterBody2D

signal level_up_requested
signal evolution_requested
signal died
signal class_applied(class_data: ClassData)
signal subclass_applied(subclass_data: SubclassData)

@export var move_speed: float = 160.0
@export var attack_range: float = 220.0

@onready var visual: ColorRect = $Visual
@onready var center_core: ColorRect = $Visual/CenterCore
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var targeting_component: TargetingComponent = $TargetingComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var weapon_holder: Node2D = $WeaponHolder
@onready var primary_weapon: Weapon = $WeaponHolder/PrimaryWeapon

var current_target: CharacterBody2D = null
var current_class: ClassData = null
var current_subclass: SubclassData = null


func _ready() -> void:
	_connect_components()
	state_machine.initialize(self)


func _connect_components() -> void:
	if health_component != null:
		health_component.health_depleted.connect(_on_health_depleted)
		health_component.health_changed.connect(_on_health_changed)

	if targeting_component != null:
		targeting_component.target_acquired.connect(_on_target_acquired)
		targeting_component.target_lost.connect(_on_target_lost)


func apply_class(data: ClassData) -> void:
	if data == null:
		return

	current_class = data
	move_speed = data.base_move_speed
	attack_range = data.base_range

	if health_component != null:
		health_component.max_health = data.base_health
		health_component.current_health = data.base_health

	if targeting_component != null:
		targeting_component.acquisition_radius = data.base_range * 1.25

	if visual != null:
		visual.color = data.primary_color
	if center_core != null:
		center_core.color = data.core_color

	if primary_weapon != null:
		primary_weapon.configure_from_class(data)

	class_applied.emit(data)


func apply_subclass(data: SubclassData) -> void:
	if data == null:
		return

	current_subclass = data
	move_speed = maxf(60.0, move_speed + data.delta_speed)
	attack_range = maxf(80.0, attack_range + data.delta_range)

	if health_component != null:
		health_component.max_health += data.delta_max_health
		health_component.apply_heal(maxf(0.0, data.delta_max_health))

	if targeting_component != null:
		targeting_component.acquisition_radius = attack_range * 1.25

	if primary_weapon != null:
		primary_weapon.damage = maxf(5.0, primary_weapon.damage + data.delta_attack_power)
		primary_weapon.set_cooldown(primary_weapon.cooldown_time + data.delta_cooldown)

		# Mecánicas específicas y diferenciadas de subclase
		match data.subclass_id:
			&"paladin":
				primary_weapon.weapon_mode = Weapon.WeaponMode.MELEE_SLASH
				primary_weapon.weapon_color = Color(1.0, 0.85, 0.25)
				primary_weapon.attack_range = 160.0
				primary_weapon.is_double_slash = false
			&"berserker":
				primary_weapon.weapon_mode = Weapon.WeaponMode.MELEE_SLASH
				primary_weapon.weapon_color = Color(1.0, 0.15, 0.15)
				primary_weapon.is_double_slash = true
				primary_weapon.set_cooldown(0.35)
			&"archmage":
				primary_weapon.weapon_mode = Weapon.WeaponMode.PROJECTILE_MAGIC
				primary_weapon.projectile_aoe_radius = 140.0
				primary_weapon.weapon_color = Color(0.85, 0.45, 1.0)
			&"chronomancer":
				primary_weapon.weapon_mode = Weapon.WeaponMode.PROJECTILE_MAGIC
				primary_weapon.projectile_aoe_radius = 50.0
				primary_weapon.projectile_speed = 550.0
				primary_weapon.set_cooldown(0.25)
				primary_weapon.weapon_color = Color(0.2, 0.9, 0.85)
			&"windrunner":
				primary_weapon.weapon_mode = Weapon.WeaponMode.PROJECTILE_ARROW
				primary_weapon.projectile_count = 3
				primary_weapon.spread_angle_deg = 25.0
				primary_weapon.weapon_color = Color(0.3, 1.0, 0.5)
			&"sniper":
				primary_weapon.weapon_mode = Weapon.WeaponMode.SNIPER_BEAM
				primary_weapon.attack_range = 600.0
				primary_weapon.projectile_pierce = 4
				primary_weapon.projectile_speed = 750.0
				primary_weapon.weapon_color = Color(1.0, 0.85, 0.2)

	if center_core != null:
		center_core.color = data.tint_color

	subclass_applied.emit(data)


func _on_target_acquired(target: CharacterBody2D) -> void:
	current_target = target


func _on_target_lost() -> void:
	current_target = null


func _on_health_depleted() -> void:
	died.emit()
	state_machine.transition_to(&"Dead")


func _on_health_changed(cur_hp: float, max_hp: float) -> void:
	# Rasgo Paladín: Reflejo sacro si recibe daño
	if current_subclass != null and current_subclass.subclass_id == &"paladin":
		_trigger_sacred_pulse()


func _trigger_sacred_pulse() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemy")
	for enemy in enemies:
		if enemy is EnemyBase and is_instance_valid(enemy):
			if global_position.distance_to((enemy as EnemyBase).global_position) <= 180.0:
				(enemy as EnemyBase).health_component.apply_damage(12.0, self)


func trigger_level_up() -> void:
	level_up_requested.emit()
	state_machine.transition_to(&"LevelingUp")


func trigger_evolution() -> void:
	evolution_requested.emit()
	state_machine.transition_to(&"Evolving")


func resume_combat() -> void:
	if is_alive():
		state_machine.transition_to(&"Idle")


func is_alive() -> bool:
	return health_component != null and health_component.is_alive()
