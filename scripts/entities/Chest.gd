class_name Chest
extends Area2D

signal chest_opened(loot: Dictionary)

@export var economy_manager: EconomyManager
@export var despawn_duration: float = 12.0

var _is_collected: bool = false
var _lifespan_timer: Timer


func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	_setup_lifespan_timer()


func _process(_delta: float) -> void:
	if _is_collected:
		return
	var mouse_pos: Vector2 = get_global_mouse_position()
	if global_position.distance_to(mouse_pos) <= 32.0:
		_collect()


func _setup_lifespan_timer() -> void:
	_lifespan_timer = Timer.new()
	_lifespan_timer.one_shot = true
	_lifespan_timer.wait_time = despawn_duration
	_lifespan_timer.timeout.connect(_on_lifespan_timeout)
	add_child(_lifespan_timer)
	_lifespan_timer.start()


func _on_mouse_entered() -> void:
	if _is_collected:
		return

	_collect()


func _collect() -> void:
	_is_collected = true
	_lifespan_timer.stop()

	var loot: Dictionary = {}
	if economy_manager != null:
		loot = economy_manager.evaluate_chest_loot()
	else:
		loot = {"gold": 25, "gems": 0}

	chest_opened.emit(loot)

	# Animación de recogida con Tween antes de liberar el nodo
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.3, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.finished.connect(queue_free)


func _on_lifespan_timeout() -> void:
	if not _is_collected:
		queue_free()
