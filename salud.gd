extends Node

signal cambio(vida)
signal sin_vida

@export var vida = 120
@export var invulnerable = 0.5
@export var reapariciones = 1
@export var espera_reaparecer = 2.0

var reloj = 0.0
var vida_inicial = 0
var punto = Vector3.ZERO

@onready var pj = get_parent()

func _ready():
	sin_vida.connect(_al_quedar_sin_vida)
	vida_inicial = vida
	if pj != null and pj is Node3D:
		punto = pj.global_position

func _physics_process(delta):
	reloj = maxf(reloj - delta, 0.0)

func recibir_golpe(danio):
	if reloj > 0.001 or vida == 0:
		return
	vida = maxi(vida - danio, 0)
	reloj = invulnerable
	cambio.emit(vida)
	if vida == 0:
		sin_vida.emit()

func _al_quedar_sin_vida():
	if reapariciones > 0:
		reapariciones -= 1
		vida = vida_inicial
		if pj != null and pj is Node3D:
			pj.global_position = punto
		reloj = espera_reaparecer
		cambio.emit(vida)
		print("reaparece cuadro ", Engine.get_physics_frames())
		return
		
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		partida.perder("sin vida")
