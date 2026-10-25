class_name TelemetryManager
extends Node

# Registra estadisticas y metricas de la partida (daño, oro, enemigos eliminados y tiempo)

# Core Telemetry Signals
signal stats_updated(telemetry_data: Dictionary)
signal milestone_reached(milestone_type: String, value: int)

# Eventos de estadisticas de la partida
signal class_picked(class_id: String)
signal subclass_evolved(subclass_id: String, level: int)
signal run_ended_stats(class_id: String, subclass_id: String, duration_sec: float, kills: int, gold: int)

var is_active: bool = false
var survival_time: float = 0.0

# Class Progression State
var current_class_id: String = ""
var current_subclass_id: String = ""
var current_level_reached: int = 1

# Telemetry Accumulators
var total_clicks: int = 0
var total_kills: int = 0
var total_gold_collected: int = 0
var total_damage_dealt: float = 0.0
var total_damage_taken: float = 0.0

# Granular Kills breakdown
var kills_by_type: Dictionary = {}

# DPS Rolling Window (last 5 seconds)
var _damage_history: Array[Dictionary] = [] # [{ "time": float, "damage": float }]
var _click_history: Array[float] = [] # timestamps of clicks

const DPS_WINDOW_SECONDS: float = 5.0
const APM_WINDOW_SECONDS: float = 10.0

func _ready() -> void:
	# Connect to RunManager lifecycle if present in tree
	if has_node("/root/RunManager"):
		var run_mgr = get_node("/root/RunManager")
		run_mgr.connect("run_started", Callable(self, "_on_run_started"))
		run_mgr.connect("run_completed", Callable(self, "_on_run_ended"))

# Optional binding to ClickManager for automatic input telemetry
func attach_click_manager(click_manager: Node) -> void:
	if click_manager != null and click_manager.has_signal("click_processed"):
		click_manager.connect("click_processed", Callable(self, "_on_click_processed"))

func _on_click_processed(_xp: float) -> void:
	record_click()

# Binds to PlayerCharacter to capture class and subclass events automatically
func attach_player(player: Node) -> void:
	if player == null:
		return
	if player.has_signal("class_applied"):
		player.connect("class_applied", Callable(self, "_on_player_class_applied"))
	if player.has_signal("subclass_applied"):
		player.connect("subclass_applied", Callable(self, "_on_player_subclass_applied"))

# Binds to LevelingManager to capture level progressions automatically
func attach_leveling_manager(leveling_manager: Node) -> void:
	if leveling_manager != null and leveling_manager.has_signal("level_up_reached"):
		leveling_manager.connect("level_up_reached", Callable(self, "_on_level_up_reached"))

func _process(delta: float) -> void:
	if not is_active:
		return

	survival_time += delta
	_prune_rolling_windows(survival_time)

func start_tracking() -> void:
	reset_telemetry()
	is_active = true
	print("[TelemetryManager] Started recording telemetry.")

func stop_tracking() -> void:
	if not is_active:
		return
	is_active = false
	print("[TelemetryManager] Stopped recording telemetry.")
	_emit_run_ended_stats()

func reset_telemetry() -> void:
	survival_time = 0.0
	total_clicks = 0
	total_kills = 0
	total_gold_collected = 0
	total_damage_dealt = 0.0
	total_damage_taken = 0.0
	current_class_id = ""
	current_subclass_id = ""
	current_level_reached = 1
	kills_by_type.clear()
	_damage_history.clear()
	_click_history.clear()

# --- ANALYTICAL EVENT RECORDERS ---

# Records the selection of a class
func record_class_picked(class_id: String) -> void:
	current_class_id = class_id
	class_picked.emit(class_id)
	print("[TelemetryManager] Analytics: Class picked -> %s" % class_id)

	# Relay to PersistenceManager
	if has_node("/root/PersistenceManager"):
		get_node("/root/PersistenceManager").call("set_active_run_class", class_id)

# Records evolution to a subclass
func record_subclass_evolved(subclass_id: String, level: int = 1) -> void:
	current_subclass_id = subclass_id
	current_level_reached = maxi(current_level_reached, level)
	subclass_evolved.emit(subclass_id, level)
	print("[TelemetryManager] Analytics: Subclass evolved -> %s (Level %d)" % [subclass_id, level])

	# Relay to PersistenceManager
	if has_node("/root/PersistenceManager"):
		get_node("/root/PersistenceManager").call("set_active_run_subclass", subclass_id, level)

# Records an upgraded level
func record_level_reached(level: int) -> void:
	current_level_reached = maxi(current_level_reached, level)

# --- CORE EVENT RECORDERS ---

# Call whenever player executes an action/click
func record_click() -> void:
	if not is_active:
		return
	total_clicks += 1
	_click_history.push_back(survival_time)

# Call when damage is inflicted on an enemy
func record_damage_dealt(amount: float) -> void:
	if not is_active or amount <= 0.0:
		return
	total_damage_dealt += amount
	_damage_history.push_back({"time": survival_time, "damage": amount})

# Call when player receives damage
func record_damage_taken(amount: float) -> void:
	if not is_active or amount <= 0.0:
		return
	total_damage_taken += amount

# Call when an enemy is defeated
func record_kill(enemy_type: String = "minion") -> void:
	if not is_active:
		return
	total_kills += 1
	kills_by_type[enemy_type] = kills_by_type.get(enemy_type, 0) + 1

	if total_kills % 100 == 0:
		milestone_reached.emit("kills", total_kills)

# Call when gold / currency is acquired
func record_gold(amount: int) -> void:
	if not is_active or amount <= 0:
		return
	total_gold_collected += amount

	if total_gold_collected % 500 == 0:
		milestone_reached.emit("gold", total_gold_collected)

# Calculates current rolling DPS over DPS_WINDOW_SECONDS
func get_current_dps() -> float:
	if _damage_history.is_empty():
		return 0.0
	var sum: float = 0.0
	for entry in _damage_history:
		sum += entry["damage"]
	return sum / DPS_WINDOW_SECONDS

# Calculates current Actions Per Minute (APM)
func get_current_apm() -> float:
	if _click_history.is_empty():
		return 0.0
	var count: int = _click_history.size()
	return (float(count) / APM_WINDOW_SECONDS) * 60.0

# Exports complete run summary dictionary
func get_run_summary(is_victory: bool = false) -> Dictionary:
	var avg_dps: float = (total_damage_dealt / survival_time) if survival_time > 0.0 else 0.0
	var avg_apm: float = (float(total_clicks) / (survival_time / 60.0)) if survival_time > 0.0 else 0.0

	return {
		"is_victory": is_victory,
		"class_id": current_class_id,
		"subclass_id": current_subclass_id,
		"level_reached": current_level_reached,
		"survival_time": survival_time,
		"survival_time_formatted": _format_time(survival_time),
		"kills": total_kills,
		"kills_by_type": kills_by_type.duplicate(),
		"gold_collected": total_gold_collected,
		"damage_dealt": total_damage_dealt,
		"damage_taken": total_damage_taken,
		"total_actions": total_clicks,
		"average_dps": avg_dps,
		"average_apm": avg_apm
	}

func _emit_run_ended_stats() -> void:
	run_ended_stats.emit(
		current_class_id,
		current_subclass_id,
		survival_time,
		total_kills,
		total_gold_collected
	)
	print("[TelemetryManager] Analytics: run_ended_stats emitted (Class: %s, Subclass: %s, Time: %.2fs, Kills: %d, Gold: %d)" % [
		current_class_id, current_subclass_id, survival_time, total_kills, total_gold_collected
	])

func _prune_rolling_windows(current_time: float) -> void:
	var dps_cutoff := current_time - DPS_WINDOW_SECONDS
	while not _damage_history.is_empty() and _damage_history[0]["time"] < dps_cutoff:
		_damage_history.pop_front()

	var apm_cutoff := current_time - APM_WINDOW_SECONDS
	while not _click_history.is_empty() and _click_history[0] < apm_cutoff:
		_click_history.pop_front()

func _format_time(seconds: float) -> String:
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

# --- SIGNAL CALLBACKS ---

func _on_run_started(config: Dictionary) -> void:
	start_tracking()
	var class_id: String = config.get("class_id", "")
	if not class_id.is_empty():
		record_class_picked(class_id)

func _on_run_ended(_summary: Dictionary) -> void:
	stop_tracking()

func _on_player_class_applied(class_data: Variant) -> void:
	if class_data != null:
		var id: String = ""
		if "class_id" in class_data:
			id = String(class_data.class_id)
		elif "id" in class_data:
			id = String(class_data.id)
		elif "display_name" in class_data:
			id = String(class_data.display_name)
		if not id.is_empty():
			record_class_picked(id)

func _on_player_subclass_applied(subclass_data: Variant) -> void:
	if subclass_data != null:
		var id: String = ""
		if "subclass_id" in subclass_data:
			id = String(subclass_data.subclass_id)
		elif "id" in subclass_data:
			id = String(subclass_data.id)
		elif "display_name" in subclass_data:
			id = String(subclass_data.display_name)
		if not id.is_empty():
			record_subclass_evolved(id, current_level_reached)

func _on_level_up_reached(new_level: int) -> void:
	record_level_reached(new_level)
