class_name SubclassData
extends Resource

@export var subclass_id: StringName = &"paladin"
@export var title: String = "Paladín"
@export var description: String = "+60 HP, +10 Daño. Refleja daño como aura sacra."
@export var delta_max_health: float = 60.0
@export var delta_attack_power: float = 10.0
@export var delta_cooldown: float = -0.10
@export var delta_range: float = 30.0
@export var delta_speed: float = -10.0
@export var delta_click_multiplier: float = 0.0
@export var tint_color: Color = Color(1.0, 0.85, 0.3) # Resplandor dorado
@export var trait_description: String = "Aura Sacra: 15% de daño reflejado en radio de 200px."
