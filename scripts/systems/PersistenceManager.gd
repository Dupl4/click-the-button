extends Node

# Gestor de guardado y persistencia de datos (partidas, estadísticas y desbloqueables)

signal save_completed(success: bool)
signal save_loaded(data: Dictionary)
signal save_corrupted(reason: String)
signal subclass_unlocked(subclass_id: String)

const SAVE_PATH: String = "user://savegame.json"
const SAVE_BACKUP_PATH: String = "user://savegame.bak"
const CURRENT_SCHEMA_VERSION: int = 2
const CHECKSUM_SALT: String = "ClicklikeSaveKey2026"
const MAX_RUN_HISTORY_ENTRIES: int = 50

var data: Dictionary = {}

func _ready() -> void:
	load_game()

# Genera la estructura de datos por defecto
func get_default_save_data() -> Dictionary:
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"timestamp_created": Time.get_datetime_string_from_system(),
		"timestamp_last_saved": Time.get_datetime_string_from_system(),
		"meta_currency": 0,
		"unlocked_classes": ["WARRIOR"],
		"unlocked_subclasses": [],
		"active_run": {
			"class_id": "WARRIOR",
			"subclass_id": "",
			"level_reached": 1,
			"is_active": false
		},
		"class_career_stats": {
			"WARRIOR": {
				"runs_played": 0,
				"runs_won": 0,
				"total_kills": 0,
				"total_gold": 0,
				"highest_level": 0,
				"longest_survival_time": 0.0,
				"subclasses_unlocked": []
			}
		},
		"run_history": [],
		"unlocked_talents": [],
		"talent_levels": {
			"vitality": 0,
			"might": 0,
			"haste": 0,
			"greed": 0
		},
		"career_stats": {
			"runs_played": 0,
			"runs_won": 0,
			"total_kills": 0,
			"total_damage_dealt": 0.0,
			"total_gold_collected": 0,
			"longest_survival_time": 0.0
		},
		"settings": {
			"master_volume": 1.0,
			"sfx_volume": 0.8,
			"music_volume": 0.7,
			"screen_shake": 1.0,
			"damage_numbers": true
		}
	}

# Carga los datos guardados desde el archivo local
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[PersistenceManager] No savegame found. Initializing with defaults.")
		data = get_default_save_data()
		save_game()
		save_loaded.emit(data)
		return true

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[PersistenceManager] Failed to open savegame file. Error: %d" % FileAccess.get_open_error())
		_attempt_backup_restore()
		return false

	var raw_content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(raw_content)
	if parse_result != OK:
		push_error("[PersistenceManager] JSON parse error: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		save_corrupted.emit("JSON parse error")
		_attempt_backup_restore()
		return false

	var loaded_dict: Variant = json.data
	if not (loaded_dict is Dictionary):
		save_corrupted.emit("Malformed root object")
		_attempt_backup_restore()
		return false

	# Verify Checksum
	if not _verify_checksum(loaded_dict):
		push_warning("[PersistenceManager] Checksum mismatch detected! Save may have been modified or corrupted.")
		save_corrupted.emit("Checksum verification failure")
		if not _attempt_backup_restore():
			print("[PersistenceManager] Accepting corrupted file as fallback with sanity repair.")
			data = _repair_and_fill_defaults(loaded_dict)
		return false

	# Schema Migration
	var version: int = loaded_dict.get("schema_version", 0)
	if version < CURRENT_SCHEMA_VERSION:
		loaded_dict = _migrate_schema(loaded_dict, version, CURRENT_SCHEMA_VERSION)

	data = _repair_and_fill_defaults(loaded_dict)
	print("[PersistenceManager] Savegame successfully loaded and validated. Version: %d" % data["schema_version"])
	save_loaded.emit(data)
	return true

# Guarda los datos de la partida en disco
func save_game() -> bool:
	data["timestamp_last_saved"] = Time.get_datetime_string_from_system()
	data["schema_version"] = CURRENT_SCHEMA_VERSION

	# Calculate and embed SHA-256 checksum with normalized JSON types
	var normalized_dict: Dictionary = JSON.parse_string(JSON.stringify(data))
	var content_to_hash := _serialize_dict_for_checksum(normalized_dict)
	var checksum: String = (content_to_hash + CHECKSUM_SALT).sha256_text()
	data["_checksum"] = checksum

	var serialized_json := JSON.stringify(data, "\t")
	var temp_path := SAVE_PATH + ".tmp"

	# 1. Write to temporary file
	var temp_file := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		push_error("[PersistenceManager] Could not open temp file for writing: %s" % temp_path)
		save_completed.emit(false)
		return false

	temp_file.store_string(serialized_json)
	temp_file.close()

	# 2. Maintain backup copy of existing savegame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, SAVE_BACKUP_PATH)

	# 3. Rename temp file to destination (Atomic swap)
	var dir := DirAccess.open("user://")
	if dir != null:
		var err := dir.rename(temp_path.get_file(), SAVE_PATH.get_file())
		if err != OK:
			push_error("[PersistenceManager] Failed to rename temp save to final target: %d" % err)
			save_completed.emit(false)
			return false
	else:
		push_error("[PersistenceManager] Failed opening user:// directory")
		save_completed.emit(false)
		return false

	print("[PersistenceManager] Savegame saved successfully with checksum: %s" % checksum.substr(0, 8))
	save_completed.emit(true)
	return true

# Sets the class selected for the current active run
func set_active_run_class(class_id: String) -> void:
	if not data.has("active_run"):
		data["active_run"] = {}
	data["active_run"]["class_id"] = class_id
	data["active_run"]["subclass_id"] = ""
	data["active_run"]["level_reached"] = 1
	data["active_run"]["is_active"] = true
	
	# Ensure class exists in class_career_stats
	_ensure_class_career_entry(class_id)
	save_game()

# Sets the evolved subclass for the current active run
func set_active_run_subclass(subclass_id: String, level: int = 1) -> void:
	if not data.has("active_run"):
		data["active_run"] = {}
	data["active_run"]["subclass_id"] = subclass_id
	data["active_run"]["level_reached"] = max(data["active_run"].get("level_reached", 1), level)
	
	unlock_subclass(subclass_id)
	save_game()

# Unlocks a subclass globally and for the active class
func unlock_subclass(subclass_id: String) -> void:
	if subclass_id.is_empty():
		return

	var unlocked_list: Array = data.get("unlocked_subclasses", [])
	if not unlocked_list.has(subclass_id):
		unlocked_list.push_back(subclass_id)
		data["unlocked_subclasses"] = unlocked_list
		subclass_unlocked.emit(subclass_id)
		print("[PersistenceManager] Subclass unlocked globally: %s" % subclass_id)

	# Also record in class-specific stats if an active class is defined
	var active_class: String = data.get("active_run", {}).get("class_id", "")
	if not active_class.is_empty():
		_ensure_class_career_entry(active_class)
		var class_subclasses: Array = data["class_career_stats"][active_class].get("subclasses_unlocked", [])
		if not class_subclasses.has(subclass_id):
			class_subclasses.push_back(subclass_id)
			data["class_career_stats"][active_class]["subclasses_unlocked"] = class_subclasses

# Checks if a subclass is unlocked
func is_subclass_unlocked(subclass_id: String) -> bool:
	var unlocked_list: Array = data.get("unlocked_subclasses", [])
	return unlocked_list.has(subclass_id)

# Returns stats for a given class
func get_class_stats(class_id: String) -> Dictionary:
	_ensure_class_career_entry(class_id)
	return data["class_career_stats"].get(class_id, {}).duplicate(true)

# Returns recent run history
func get_run_history() -> Array:
	return data.get("run_history", []).duplicate(true)

# Updates career stats, per-class stats, and run history from a finished run
func record_run_completion(run_data: Dictionary) -> void:
	var class_id: String = run_data.get("class_id", data.get("active_run", {}).get("class_id", "WARRIOR"))
	if class_id.is_empty():
		class_id = "WARRIOR"

	var subclass_id: String = run_data.get("subclass_id", data.get("active_run", {}).get("subclass_id", ""))
	var level_reached: int = run_data.get("level_reached", data.get("active_run", {}).get("level_reached", 1))
	var kills: int = run_data.get("kills", 0)
	var gold: int = run_data.get("gold_collected", 0)
	var survival_time: float = run_data.get("survival_time", 0.0)
	var is_victory: bool = run_data.get("is_victory", false)

	# 1. Update Global Career Stats
	var career: Dictionary = data.get("career_stats", {})
	career["runs_played"] = career.get("runs_played", 0) + 1
	if is_victory:
		career["runs_won"] = career.get("runs_won", 0) + 1
	career["total_kills"] = career.get("total_kills", 0) + kills
	career["total_damage_dealt"] = career.get("total_damage_dealt", 0.0) + run_data.get("damage_dealt", 0.0)
	career["total_gold_collected"] = career.get("total_gold_collected", 0) + gold
	if survival_time > career.get("longest_survival_time", 0.0):
		career["longest_survival_time"] = survival_time
	data["career_stats"] = career

	# 2. Update Per-Class Career Stats
	_ensure_class_career_entry(class_id)
	var class_stat: Dictionary = data["class_career_stats"][class_id]
	class_stat["runs_played"] = class_stat.get("runs_played", 0) + 1
	if is_victory:
		class_stat["runs_won"] = class_stat.get("runs_won", 0) + 1
	class_stat["total_kills"] = class_stat.get("total_kills", 0) + kills
	class_stat["total_gold"] = class_stat.get("total_gold", 0) + gold
	if level_reached > class_stat.get("highest_level", 0):
		class_stat["highest_level"] = level_reached
	if survival_time > class_stat.get("longest_survival_time", 0.0):
		class_stat["longest_survival_time"] = survival_time

	if not subclass_id.is_empty():
		var class_subclasses: Array = class_stat.get("subclasses_unlocked", [])
		if not class_subclasses.has(subclass_id):
			class_subclasses.push_back(subclass_id)
			class_stat["subclasses_unlocked"] = class_subclasses
		unlock_subclass(subclass_id)

	data["class_career_stats"][class_id] = class_stat

	# 3. Append to Run History
	var history: Array = data.get("run_history", [])
	var history_entry := {
		"timestamp": Time.get_datetime_string_from_system(),
		"class_id": class_id,
		"subclass_id": subclass_id,
		"level_reached": level_reached,
		"kills": kills,
		"gold": gold,
		"duration_sec": survival_time,
		"is_victory": is_victory
	}
	history.push_front(history_entry)
	if history.size() > MAX_RUN_HISTORY_ENTRIES:
		history.resize(MAX_RUN_HISTORY_ENTRIES)
	data["run_history"] = history

	# 4. Meta currency & Active Run Reset
	data["meta_currency"] = data.get("meta_currency", 0) + gold
	if data.has("active_run"):
		data["active_run"]["is_active"] = false

	save_game()
	print("[PersistenceManager] Run stats recorded for class '%s' (Subclass: '%s', Level: %d, Kills: %d, Gold: %d)" % [
		class_id, subclass_id, level_reached, kills, gold
	])

func _ensure_class_career_entry(class_id: String) -> void:
	if not data.has("class_career_stats"):
		data["class_career_stats"] = {}
	if not data["class_career_stats"].has(class_id):
		data["class_career_stats"][class_id] = {
			"runs_played": 0,
			"runs_won": 0,
			"total_kills": 0,
			"total_gold": 0,
			"highest_level": 0,
			"longest_survival_time": 0.0,
			"subclasses_unlocked": []
		}

func _verify_checksum(save_dict: Dictionary) -> bool:
	if not save_dict.has("_checksum"):
		return false
	var recorded_checksum: String = save_dict["_checksum"]
	var content_to_hash := _serialize_dict_for_checksum(save_dict)
	var expected_checksum := (content_to_hash + CHECKSUM_SALT).sha256_text()
	return recorded_checksum == expected_checksum

func _serialize_dict_for_checksum(d: Dictionary) -> String:
	var clean := d.duplicate(true)
	clean.erase("_checksum")
	return _canonical_json(clean)

func _canonical_json(value: Variant) -> String:
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort()
		var parts: Array[String] = []
		for k in keys:
			var key_str := JSON.stringify(String(k))
			var val_str := _canonical_json(value[k])
			parts.push_back("%s:%s" % [key_str, val_str])
		return "{" + ",".join(parts) + "}"
	elif value is Array:
		var parts: Array[String] = []
		for item in value:
			parts.push_back(_canonical_json(item))
		return "[" + ",".join(parts) + "]"
	else:
		return JSON.stringify(value)

func _attempt_backup_restore() -> bool:
	if FileAccess.file_exists(SAVE_BACKUP_PATH):
		print("[PersistenceManager] Attempting restoration from backup file...")
		var dir := DirAccess.open("user://")
		if dir != null and dir.copy(SAVE_BACKUP_PATH, SAVE_PATH) == OK:
			return load_game()
	print("[PersistenceManager] Backup unavailable. Resetting to defaults.")
	data = get_default_save_data()
	save_game()
	return false

func _migrate_schema(old_data: Dictionary, from_ver: int, to_ver: int) -> Dictionary:
	print("[PersistenceManager] Migrating schema from v%d to v%d" % [from_ver, to_ver])
	var migrated := old_data.duplicate(true)

	if from_ver == 0 and to_ver >= 1:
		if not migrated.has("talent_levels"):
			migrated["talent_levels"] = {"vitality": 0, "might": 0, "haste": 0, "greed": 0}
		if not migrated.has("unlocked_talents"):
			migrated["unlocked_talents"] = []

	if from_ver <= 1 and to_ver >= 2:
		# Estructura para clases y subclases desbloqueadas
		if not migrated.has("unlocked_subclasses"):
			migrated["unlocked_subclasses"] = []
		if not migrated.has("active_run"):
			migrated["active_run"] = {
				"class_id": "WARRIOR",
				"subclass_id": "",
				"level_reached": 1,
				"is_active": false
			}
		if not migrated.has("class_career_stats"):
			migrated["class_career_stats"] = {
				"WARRIOR": {
					"runs_played": migrated.get("career_stats", {}).get("runs_played", 0),
					"runs_won": migrated.get("career_stats", {}).get("runs_won", 0),
					"total_kills": migrated.get("career_stats", {}).get("total_kills", 0),
					"total_gold": migrated.get("career_stats", {}).get("total_gold_collected", 0),
					"highest_level": 1,
					"longest_survival_time": migrated.get("career_stats", {}).get("longest_survival_time", 0.0),
					"subclasses_unlocked": []
				}
			}
		if not migrated.has("run_history"):
			migrated["run_history"] = []

	migrated["schema_version"] = to_ver
	return migrated

func _repair_and_fill_defaults(loaded: Dictionary) -> Dictionary:
	var defaults := get_default_save_data()
	for key in defaults:
		if not loaded.has(key):
			loaded[key] = defaults[key]
		elif defaults[key] is Dictionary and loaded[key] is Dictionary:
			for sub_key in defaults[key]:
				if not loaded[key].has(sub_key):
					loaded[key][sub_key] = defaults[key][sub_key]
	return loaded
