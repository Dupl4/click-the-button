class_name SmoothCamera2D
extends Camera2D

# Configuración de seguimiento del objetivo
@export_group("Target Tracking")
@export var target_node: Node2D = null
@export var manual_target_position: Vector2 = Vector2.ZERO
@export_range(0.1, 50.0, 0.1) var tracking_responsiveness: float = 12.0
@export var target_offset: Vector2 = Vector2.ZERO

# Configuración de sacudida de pantalla (Screen Shake)
@export_group("Screen Shake")
@export_range(0.0, 1.0) var trauma: float = 0.0
@export var trauma_decay: float = 1.5
@export var max_shake_offset: Vector2 = Vector2(25.0, 20.0)
@export var max_shake_roll: float = 0.05
@export var trauma_power: float = 2.0

var _shake_noise: FastNoiseLite
var _noise_time: float = 0.0


func _init() -> void:
	# Prioridad de proceso después de la física y lógica del jugador
	process_priority = 10


func _ready() -> void:
	_shake_noise = FastNoiseLite.new()
	_shake_noise.seed = randi()
	_shake_noise.frequency = 0.1
	_shake_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	var initial_target := _get_target_pos()
	global_position = initial_target


func _process(delta: float) -> void:
	if delta <= 0.0:
		return

	# Movimiento suave hacia el objetivo
	var desired_pos: Vector2 = _get_target_pos() + target_offset
	var alpha: float = alpha_exponential(tracking_responsiveness, delta)
	global_position = global_position.lerp(desired_pos, alpha)

	# Procesar sacudida si hay trauma activo
	if trauma > 0.0:
		_process_shake(delta)
	else:
		offset = Vector2.ZERO
		rotation = 0.0


static func alpha_exponential(k: float, dt: float) -> float:
	return 1.0 - exp(-k * dt)


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func snap_to_target() -> void:
	global_position = _get_target_pos() + target_offset
	offset = Vector2.ZERO
	rotation = 0.0


func _get_target_pos() -> Vector2:
	if is_instance_valid(target_node):
		return target_node.global_position
	return manual_target_position


func _process_shake(delta: float) -> void:
	trauma = maxf(trauma - trauma_decay * delta, 0.0)
	var shake_intensity: float = pow(trauma, trauma_power)

	_noise_time += delta * 60.0
	var noise_x: float = _shake_noise.get_noise_2d(_noise_time, 0.0)
	var noise_y: float = _shake_noise.get_noise_2d(0.0, _noise_time)
	var noise_r: float = _shake_noise.get_noise_2d(_noise_time, _noise_time)

	offset = Vector2(
		max_shake_offset.x * shake_intensity * noise_x,
		max_shake_offset.y * shake_intensity * noise_y
	)
	rotation = max_shake_roll * shake_intensity * noise_r
