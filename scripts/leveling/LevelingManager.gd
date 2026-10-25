class_name LevelingManager
extends Node

signal xp_gained(amount: float, current_xp: float, required_xp: float)
signal level_up(new_level: int)
signal draft_opened(cards: Array[SkillCardData])
signal draft_closed
signal evolution_opened(subclasses: Array[SubclassData])
signal evolution_closed

@export var base_xp_threshold: float = 100.0
@export var xp_growth_factor: float = 1.35
@export var all_available_cards: Array[SkillCardData] = []
@export var cards_per_draft: int = 3
@export var evolution_level_milestone: int = 10

var current_level: int = 1
var current_xp: float = 0.0
var required_xp: float = 100.0
var is_draft_active: bool = false
var is_evolution_active: bool = false
var has_evolved: bool = false

var _pending_subclasses: Array[SubclassData] = []


func _ready() -> void:
	required_xp = base_xp_threshold


func add_xp(amount: float) -> void:
	if amount <= 0.0:
		return

	current_xp += amount
	xp_gained.emit(amount, current_xp, required_xp)

	while current_xp >= required_xp:
		_process_level_up()


func _process_level_up() -> void:
	current_xp -= required_xp
	current_level += 1
	required_xp = base_xp_threshold * pow(xp_growth_factor, float(current_level - 1))

	level_up.emit(current_level)

	if current_level >= evolution_level_milestone and not has_evolved and not _pending_subclasses.is_empty():
		_trigger_evolution()
	else:
		_trigger_draft()


func set_evolution_choices(subclasses: Array) -> void:
	_pending_subclasses.clear()
	for item in subclasses:
		if item is SubclassData:
			_pending_subclasses.append(item as SubclassData)


func _trigger_evolution() -> void:
	is_evolution_active = true
	evolution_opened.emit(_pending_subclasses)


func select_subclass(subclass: SubclassData, player: PlayerCharacter) -> void:
	if not is_evolution_active or subclass == null:
		return

	if player != null:
		player.apply_subclass(subclass)

	has_evolved = true
	is_evolution_active = false
	evolution_closed.emit()


func _trigger_draft() -> void:
	is_draft_active = true
	var selected_cards: Array[SkillCardData] = _roll_draft_cards(cards_per_draft)
	draft_opened.emit(selected_cards)


func _roll_draft_cards(count: int) -> Array[SkillCardData]:
	var result: Array[SkillCardData] = []
	if all_available_cards.is_empty():
		return result

	var pool: Array[SkillCardData] = all_available_cards.duplicate()
	pool.shuffle()

	var actual_count: int = mini(count, pool.size())
	for i in range(actual_count):
		result.append(pool[i])

	return result


func select_card(card: SkillCardData, player: PlayerCharacter) -> void:
	if not is_draft_active or card == null:
		return

	_apply_skill_to_player(card, player)
	is_draft_active = false
	draft_closed.emit()


func _apply_skill_to_player(card: SkillCardData, player: PlayerCharacter) -> void:
	if player == null:
		return

	match card.type:
		SkillCardData.SkillType.PASSIVE:
			_apply_passive(card, player)
		SkillCardData.SkillType.ACTIVE_COOLDOWN:
			_apply_active_cooldown(card, player)
		SkillCardData.SkillType.AURA:
			_apply_aura(card, player)


func _apply_passive(card: SkillCardData, player: PlayerCharacter) -> void:
	match card.stat_modifier_type:
		&"move_speed_multiplier":
			player.move_speed *= (1.0 + card.modifier_value)
		&"max_health_multiplier":
			if player.health_component != null:
				var new_max: float = player.health_component.max_health * (1.0 + card.modifier_value)
				player.health_component.max_health = new_max
				player.health_component.apply_heal(player.health_component.max_health * card.modifier_value)
		&"attack_range_multiplier":
			player.attack_range *= (1.0 + card.modifier_value)
			if player.targeting_component != null:
				player.targeting_component.acquisition_radius = player.attack_range * 1.25


func _apply_active_cooldown(card: SkillCardData, player: PlayerCharacter) -> void:
	for child in player.weapon_holder.get_children():
		if child is Weapon:
			var weapon: Weapon = child as Weapon
			weapon.set_cooldown(weapon.cooldown_time * (1.0 - card.modifier_value))


func _apply_aura(card: SkillCardData, player: PlayerCharacter) -> void:
	if player.targeting_component != null:
		player.targeting_component.acquisition_radius += card.modifier_value
