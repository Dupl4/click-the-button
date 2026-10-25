class_name ClassData
extends Resource

@export var class_id: StringName = &"warrior"
@export var class_name_str: String = "Guerrero"
@export var role_description: String = "Tanque cuerpo a cuerpo con alta resistencia y daño consistente."
@export var base_health: float = 140.0
@export var base_attack_power: float = 30.0
@export var base_cooldown: float = 1.00
@export var base_range: float = 220.0
@export var base_move_speed: float = 160.0
@export var click_multiplier: float = 1.00

# Parámetros del proyectil/arma
@export var projectile_speed: float = 450.0
@export var projectile_pierce: int = 1
@export var projectile_aoe_radius: float = 0.0
@export var projectile_count: int = 1
@export var projectile_spread_deg: float = 0.0

# Identidad visual
@export var primary_color: Color = Color(0.29, 0.50, 0.79) # Azul
@export var core_color: Color = Color(0.12, 0.25, 0.48)
@export var projectile_color: Color = Color(0.40, 0.70, 1.00)

# Subclases disponibles al nivel 10
@export var subclasses: Array[SubclassData] = []
