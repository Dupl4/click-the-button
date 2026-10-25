class_name WaveController
extends Node

signal mob_spawned(enemy: EnemyBase)
signal elite_wave_spawned(wave_index: int)
signal boss_spawned(boss_instance: EnemyBase)
signal time_tick(elapsed_time: float)

@export var player_target: CharacterBody2D
@export var standard_enemy_scene: PackedScene
@export var elite_enemy_scene: PackedScene
@export var boss_enemy_scene: PackedScene

@export var spawn_radius: float = 650.0
@export var initial_spawn_interval: float = 1.5
@export var min_spawn_interval: float = 0.35
@export var elite_interval_seconds: float = 60.0
@export var boss_trigger_seconds: float = 300.0

var elapsed_game_time: float = 0.0
var _current_spawn_interval: float = 1.5
var _elite_wave_counter: int = 0
var _boss_active: bool = false
var _is_running: bool = false

var _spawn_timer: Timer
var _elite_timer: Timer


func _ready() -> void:
	_current_spawn_interval = initial_spawn_interval
	_setup_timers()
	start_spawning()


func _setup_timers() -> void:
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = _current_spawn_interval
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

	_elite_timer = Timer.new()
	_elite_timer.wait_time = elite_interval_seconds
	_elite_timer.timeout.connect(_on_elite_timer_timeout)
	add_child(_elite_timer)


func start_spawning() -> void:
	_is_running = true
	_spawn_timer.start(_current_spawn_interval)
	_elite_timer.start(elite_interval_seconds)


func stop_spawning() -> void:
	_is_running = false
	_spawn_timer.stop()
	_elite_timer.stop()


func _process(delta: float) -> void:
	if not _is_running:
		return

	elapsed_game_time += delta
	time_tick.emit(elapsed_game_time)

	# Escala progresiva de dificultad en la cadencia de spawn de mobs
	_current_spawn_interval = maxf(min_spawn_interval, initial_spawn_interval - (elapsed_game_time / 300.0))
	_spawn_timer.wait_time = _current_spawn_interval

	# Verificación de encuentro de Boss
	if not _boss_active and elapsed_game_time >= boss_trigger_seconds:
		_trigger_boss_encounter()


func _on_spawn_timer_timeout() -> void:
	if standard_enemy_scene == null:
		return

	var spawn_pos: Vector2 = _calculate_perimeter_spawn_point()
	var enemy: EnemyBase = standard_enemy_scene.instantiate() as EnemyBase
	if enemy != null:
		_configure_and_add_enemy(enemy, spawn_pos)
		mob_spawned.emit(enemy)


func _on_elite_timer_timeout() -> void:
	if _boss_active:
		return

	_elite_wave_counter += 1
	var count: int = 3 + _elite_wave_counter

	for i in range(count):
		var spawn_pos: Vector2 = _calculate_perimeter_spawn_point()
		var scene_to_use: PackedScene = elite_enemy_scene if elite_enemy_scene != null else standard_enemy_scene
		if scene_to_use != null:
			var enemy: EnemyBase = scene_to_use.instantiate() as EnemyBase
			if enemy != null:
				enemy.is_elite = true
				enemy.move_speed *= 1.2
				enemy.xp_value *= 2.5
				_configure_and_add_enemy(enemy, spawn_pos)

	elite_wave_spawned.emit(_elite_wave_counter)


func _trigger_boss_encounter() -> void:
	_boss_active = true
	_spawn_timer.stop() # Pausa de mobs menores durante el duelo de Boss

	if boss_enemy_scene != null:
		var spawn_pos: Vector2 = _calculate_perimeter_spawn_point()
		var boss: EnemyBase = boss_enemy_scene.instantiate() as EnemyBase
		if boss != null:
			boss.is_boss = true
			boss.move_speed *= 0.9
			boss.xp_value *= 10.0
			_configure_and_add_enemy(boss, spawn_pos)
			boss_spawned.emit(boss)


func _configure_and_add_enemy(enemy: EnemyBase, spawn_pos: Vector2) -> void:
	enemy.global_position = spawn_pos
	enemy.target_player = player_target
	get_tree().current_scene.add_child(enemy)


func _calculate_perimeter_spawn_point() -> Vector2:
	var center: Vector2 = player_target.global_position if player_target != null else Vector2.ZERO
	var angle: float = randf_range(0.0, TAU)
	var offset: Vector2 = Vector2(cos(angle), sin(angle)) * spawn_radius
	return center + offset
