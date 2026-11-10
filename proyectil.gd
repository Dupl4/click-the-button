extends Area3D

@export var rapidez: float = 12.0
@export var dano: float = 10.0
@export var tiempo_vida: float = 2.5
@export var perforaciones: int = 1

var direccion: Vector3 = Vector3.FORWARD
var _tiempo: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func iniciar(origen: Vector3, dir: Vector3, dano_in: float, rapidez_in: float = 12.0):
	global_position = origen
	direccion = dir.normalized()
	dano = dano_in
	rapidez = rapidez_in
	look_at(global_position + direccion, Vector3.UP)

func _physics_process(delta):
	global_position += direccion * rapidez * delta
	_tiempo += delta
	if _tiempo >= tiempo_vida:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemigos"):
		if body.has_method("recibir_dano"):
			body.recibir_dano(dano)
		perforaciones -= 1
		if perforaciones <= 0:
			queue_free()
	elif body is StaticBody3D:
		queue_free()
