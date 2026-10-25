extends Node

# Gestor del ciclo de vida de la partida (Menu, Seleccion de Clase, Partida Activa, Game Over)

signal state_transitioned(old_state: RunState, new_state: RunState)
signal run_started(config: Dictionary)
signal run_paused(is_paused: bool)
signal run_completed(summary: Dictionary)

enum RunState {
	MAIN_MENU,
	CLASS_SELECTION,
	RUN_ACTIVE,
	RUN_GAME_OVER,
	POST_RUN_SHOP
}

const STATE_NAMES = {
	RunState.MAIN_MENU: "MainMenu",
	RunState.CLASS_SELECTION: "ClassSelection",
	RunState.RUN_ACTIVE: "RunActive",
	RunState.RUN_GAME_OVER: "RunGameOver",
	RunState.POST_RUN_SHOP: "PostRunShop"
}

var current_state: RunState = RunState.MAIN_MENU
var is_paused: bool = false

# Active Run Session Context
var active_run_config: Dictionary = {
	"class_id": "",
	"biome_id": "FOREST_ARENA",
	"seed": 0
}

var active_run_summary: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# Request transition to a new lifecycle state with validation.
func change_state(new_state: RunState) -> bool:
	if current_state == new_state:
		return false

	if not _is_transition_allowed(current_state, new_state):
		push_error("[RunManager] Illegal state transition attempted: %s -> %s" % [
			STATE_NAMES[current_state],
			STATE_NAMES[new_state]
		])
		return false

	var old_state := current_state
	_exit_state(old_state)
	current_state = new_state
	_enter_state(new_state)

	state_transitioned.emit(old_state, new_state)
	print("[RunManager] State changed: %s -> %s" % [STATE_NAMES[old_state], STATE_NAMES[new_state]])
	return true

# Start a fresh run with specified class and biome
func start_run(class_id: String, biome_id: String = "FOREST_ARENA") -> void:
	active_run_config = {
		"class_id": class_id,
		"biome_id": biome_id,
		"seed": randi()
	}
	active_run_summary = {}
	
	if current_state != RunState.CLASS_SELECTION:
		change_state(RunState.CLASS_SELECTION)

	change_state(RunState.RUN_ACTIVE)
	run_started.emit(active_run_config)

	if has_node("/root/PersistenceManager"):
		get_node("/root/PersistenceManager").call("set_active_run_class", class_id)

# Sets evolved subclass on active run session
func set_active_subclass(subclass_id: String, level: int = 1) -> void:
	active_run_config["subclass_id"] = subclass_id
	if has_node("/root/PersistenceManager"):
		get_node("/root/PersistenceManager").call("set_active_run_subclass", subclass_id, level)

# Pauses or resumes the active run (without state change)
func toggle_pause() -> void:
	if current_state != RunState.RUN_ACTIVE:
		return
	is_paused = !is_paused
	get_tree().paused = is_paused
	run_paused.emit(is_paused)

func set_pause(paused: bool) -> void:
	if current_state != RunState.RUN_ACTIVE or is_paused == paused:
		return
	is_paused = paused
	get_tree().paused = is_paused
	run_paused.emit(is_paused)

# Ends current run and transitions to GAME_OVER state
func end_run(summary: Dictionary) -> void:
	if current_state != RunState.RUN_ACTIVE:
		return
		
	# Populate class metadata if missing from raw summary
	if not summary.has("class_id") and active_run_config.has("class_id"):
		summary["class_id"] = active_run_config["class_id"]
	if not summary.has("subclass_id") and active_run_config.has("subclass_id"):
		summary["subclass_id"] = active_run_config.get("subclass_id", "")

	active_run_summary = summary
	# Automatically unpause engine if paused
	if is_paused:
		set_pause(false)

	# Feed career stats to PersistenceManager if present
	if has_node("/root/PersistenceManager"):
		get_node("/root/PersistenceManager").call("record_run_completion", summary)

	change_state(RunState.RUN_GAME_OVER)
	run_completed.emit(summary)

# Navigates to meta-progression shop
func go_to_post_run_shop() -> void:
	change_state(RunState.POST_RUN_SHOP)

# Navigates back to Main Menu
func go_to_main_menu() -> void:
	if is_paused:
		set_pause(false)
	change_state(RunState.MAIN_MENU)

# Navigates to Class Selection
func go_to_class_selection() -> void:
	change_state(RunState.CLASS_SELECTION)

func get_state_name() -> String:
	return STATE_NAMES.get(current_state, "Unknown")

func _is_transition_allowed(from_state: RunState, to_state: RunState) -> bool:
	match from_state:
		RunState.MAIN_MENU:
			return to_state in [RunState.CLASS_SELECTION, RunState.POST_RUN_SHOP]
		RunState.CLASS_SELECTION:
			return to_state in [RunState.RUN_ACTIVE, RunState.MAIN_MENU]
		RunState.RUN_ACTIVE:
			return to_state in [RunState.RUN_GAME_OVER, RunState.MAIN_MENU]
		RunState.RUN_GAME_OVER:
			return to_state in [RunState.POST_RUN_SHOP, RunState.MAIN_MENU, RunState.CLASS_SELECTION]
		RunState.POST_RUN_SHOP:
			return to_state in [RunState.CLASS_SELECTION, RunState.MAIN_MENU]
	return false

func _enter_state(state: RunState) -> void:
	match state:
		RunState.MAIN_MENU:
			pass
		RunState.CLASS_SELECTION:
			pass
		RunState.RUN_ACTIVE:
			get_tree().paused = false
			is_paused = false
		RunState.RUN_GAME_OVER:
			pass
		RunState.POST_RUN_SHOP:
			pass

func _exit_state(state: RunState) -> void:
	match state:
		RunState.RUN_ACTIVE:
			pass
