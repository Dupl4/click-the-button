class_name EconomyManager
extends Node

signal gold_awarded(amount: int)
signal gems_awarded(amount: int)
@warning_ignore("unused_signal")
signal item_unlocked(item_id: StringName)

@export var base_gold_min: int = 10
@export var base_gold_max: int = 50
@export var gem_drop_chance: float = 0.15
@export var gem_amount: int = 1

var total_gold: int = 0
var total_gems: int = 0


func evaluate_chest_loot() -> Dictionary:
	var gold_rolled: int = randi_range(base_gold_min, base_gold_max)
	var gems_rolled: int = 0

	if randf() <= gem_drop_chance:
		gems_rolled = gem_amount

	total_gold += gold_rolled
	total_gems += gems_rolled

	gold_awarded.emit(gold_rolled)
	if gems_rolled > 0:
		gems_awarded.emit(gems_rolled)

	return {
		"gold": gold_rolled,
		"gems": gems_rolled
	}
