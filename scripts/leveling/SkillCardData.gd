class_name SkillCardData
extends Resource

enum SkillType {
	PASSIVE,
	ACTIVE_COOLDOWN,
	AURA
}

@export var id: StringName = &"generic_skill"
@export var title: String = "Habilidad"
@export_multiline var description: String = "+10% de daño"
@export var type: SkillType = SkillType.PASSIVE
@export var stat_modifier_type: StringName = &"damage_multiplier"
@export var modifier_value: float = 0.10
@export var icon: Texture2D
