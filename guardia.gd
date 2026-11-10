extends CharacterBody3D

enum Estado { PATRULLAR, ESPERAR, PERSEGUIR, ATACAR, BUSCAR }

@export var rapidez = 2.0
@export var espera = 1.0
@export var rango_vision = 7.0
@export var rango_ataque = 1.2
@export var rango_perder = 10.0
@export var tiempo_busqueda = 3.0
# Desplazamientos desde donde se colocó el NPC, no posiciones absolutas.
@export var ruta: Array[Vector3] = [Vector3.ZERO, Vector3(0, 0, -6)]

@export var vida_maxima: float = 25.0
@export var dano_ataque: float = 8.0
@export var cadencia_ataque: float = 1.0

var estado = Estado.PATRULLAR
var puntos: Array[Vector3] = []
var indice = 0
var reloj = 0.0
var jugador = null
var ultimo_visto = Vector3.ZERO
var busca = 0.0
var vida: float = 25.0
var _reloj_ataque: float = 0.0

@onready var anim = $Modelo/AnimationPlayer
@onready var vision = $Vision

var _escala_base: Vector3 = Vector3(-2.6, 2.6, -2.6)

func _ready():
	add_to_group("enemigos")
	vida = vida_maxima
	if has_node("Modelo"):
		_escala_base = $Modelo.scale
	jugador = get_tree().get_first_node_in_group("jugador")
	for d in ruta:
		puntos.append(global_position + d)

func _physics_process(delta):
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)
	busca = maxf(busca - delta, 0.0)
	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
	
	# 1. MEDIR
	var d = distancia_a(jugador.global_position)
	var ve = lo_ve()
	if ve:
		ultimo_visto = jugador.global_position
		
	# 2. DECIDIR
	var nuevo = decidir(d, ve)
	if nuevo != estado:
		estado = nuevo
		print(name, " -> ", Estado.keys()[estado], " cuadro ",
			Engine.get_physics_frames(), " a ", snappedf(d, 0.01), " m")
			
	# 3. ACTUAR
	match estado:
		Estado.PATRULLAR:
			patrullar()
		Estado.ESPERAR:
			frenar()
		Estado.PERSEGUIR:
			ir_a(jugador.global_position)
		Estado.ATACAR:
			frenar()
			anim.play("attack-melee-right")
			if _reloj_ataque <= 0.001 and d <= rango_ataque + 0.3:
				_reloj_ataque = cadencia_ataque
				if jugador != null:
					if jugador.has_node("Salud"):
						jugador.get_node("Salud").recibir_golpe(int(dano_ataque))
					if jugador.has_method("recibir_dano"):
						jugador.recibir_dano(dano_ataque)
		Estado.BUSCAR:
			if distancia_a(ultimo_visto) > 0.1:
				ir_a(ultimo_visto)
			else:
				frenar()
				
	move_and_slide()

# El orden ES la regla: el primer if que se cumple gana.
func decidir(d, ve):
	var alerta = estado == Estado.PERSEGUIR or estado == Estado.ATACAR
	# Ya alerta, necesita más distancia para soltarlo: histéresis.
	var limite = rango_perder if alerta else rango_vision
	
	if ve and d <= rango_ataque:
		return Estado.ATACAR
	if ve and d <= limite:
		return Estado.PERSEGUIR
	if alerta:
		busca = tiempo_busqueda
		return Estado.BUSCAR
	if busca > 0.001:
		return Estado.BUSCAR
	if reloj > 0.001:
		return Estado.ESPERAR
	return Estado.PATRULLAR

func lo_ve():
	# Se apunta al pecho: el origen del jugador está en los pies.
	var pecho = jugador.global_position + Vector3(0, 0.9, 0)
	vision.target_position = vision.to_local(pecho)
	vision.force_raycast_update()
	if vision.is_colliding():
		return vision.get_collider() == jugador
	return true

func patrullar():
	var destino = puntos[indice]
	if distancia_a(destino) < 0.1:
		indice = (indice + 1) % puntos.size()
		reloj = espera
		frenar()
		return
	ir_a(destino)

func ir_a(destino):
	var hacia = destino - global_position
	hacia.y = 0.0
	var dir = hacia.normalized()
	velocity.x = dir.x * rapidez
	velocity.z = dir.z * rapidez
	basis = Basis.looking_at(dir)
	anim.play("walk")

func frenar():
	velocity.x = 0.0
	velocity.z = 0.0
	anim.play("idle")

func distancia_a(p):
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()

func recibir_dano(cantidad: float, es_critico: bool = false):
	vida -= cantidad
	
	if has_node("Modelo"):
		var tw = create_tween()
		tw.tween_property($Modelo, "scale", _escala_base * 1.15, 0.05)
		tw.tween_property($Modelo, "scale", _escala_base, 0.08)
		
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var num = escena.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.25, 0.25), 1.8, randf_range(-0.25, 0.25))
		get_parent().add_child(num)
		num.global_position = pos_num
		num.iniciar(cantidad, es_critico, false)
		
	if vida <= 0:
		morir()

func morir():
	var drop_escena = load("res://drop_item.tscn")
	if drop_escena != null:
		var drop = drop_escena.instantiate()
		var pos_drop = global_position + Vector3(0, 0.4, 0)
		get_parent().add_child(drop)
		drop.global_position = pos_drop
	if jugador != null and jugador.has_method("registrar_baja"):
		jugador.registrar_baja()
	queue_free()
