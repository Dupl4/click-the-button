extends Node3D

@export var guardia_escena: PackedScene = preload("res://guardia.tscn")
@export var espectro_escena: PackedScene = preload("res://espectro.tscn")
@export var bruto_escena: PackedScene = preload("res://bruto.tscn")

@export var intervalo_oleada: float = 22.0
@export var radio_spawn: float = 26.0

var _reloj_oleada: float = 22.0
var oleada_actual: int = 1
var hud: Node = null

func _ready():
	hud = get_parent().get_node_or_null("ClickHUD")
	# Generar una primera horda inicial de calentamiento
	call_deferred("_generar_oleada", 1)

func _process(delta):
	_reloj_oleada -= delta
	if _reloj_oleada <= 0.0:
		_reloj_oleada = intervalo_oleada
		oleada_actual += 1
		if hud != null:
			hud.oleada = oleada_actual
		_generar_oleada(oleada_actual)

func _generar_oleada(num: int):
	print("--- INICIANDO OLEADA ", num, " EN ARENA 60x60 ---")
	
	if num <= 2:
		# Fase 1: Enjambres rápidos de espectros (4 a 6)
		var cant = 4 + (num * 2)
		for i in range(cant):
			_spawn_enemigo(espectro_escena, 0.0)
	elif num <= 4:
		# Fase 2: Mezcla de infantería gladiador y enjambres
		for i in range(3):
			_spawn_enemigo(guardia_escena, (num - 2) * 5.0)
		for i in range(5):
			_spawn_enemigo(espectro_escena, (num - 2) * 3.0)
	else:
		# Fase 3+: Aparición de Bruto Ancestral + Escolta
		_spawn_enemigo(bruto_escena, (num - 5) * 20.0)
		for i in range(3):
			_spawn_enemigo(guardia_escena, (num - 4) * 6.0)
		for i in range(6):
			_spawn_enemigo(espectro_escena, (num - 4) * 4.0)

func _spawn_enemigo(escena: PackedScene, vida_extra: float):
	if escena == null:
		return
	var angulo = randf() * TAU
	var pos = Vector3(cos(angulo) * radio_spawn, 0.0, sin(angulo) * radio_spawn)
	# Mantener dentro de los muros de la arena 60x60
	pos.x = clampf(pos.x, -27.0, 27.0)
	pos.z = clampf(pos.z, -27.0, 27.0)
	
	var enemigo = escena.instantiate()
	get_parent().add_child(enemigo)
	enemigo.global_position = pos
	if "vida_maxima" in enemigo:
		enemigo.vida_maxima += vida_extra
		enemigo.vida = enemigo.vida_maxima
