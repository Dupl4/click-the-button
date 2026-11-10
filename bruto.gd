extends CharacterBody3D

@export var rapidez: float = 1.5
@export var vida_maxima: float = 220.0
@export var dano_ataque: float = 22.0
@export var cadencia_ataque: float = 1.8
@export var rango_ataque: float = 1.8

var vida: float = 220.0
var jugador: Node3D = null
var _reloj_ataque: float = 0.0
var _escala_base: Vector3 = Vector3(3.8, 3.8, 3.8)

@onready var anim = $Modelo/AnimationPlayer
@onready var modelo = $Modelo

func _ready():
	add_to_group("enemigos")
	vida = vida_maxima
	_escala_base = modelo.scale
	jugador = get_tree().get_first_node_in_group("jugador")

func _physics_process(delta):
	velocity += get_gravity() * delta
	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
	
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
		move_and_slide()
		return
		
	var d = distancia_a(jugador.global_position)
	if d <= rango_ataque:
		frenar()
		if anim != null and anim.has_animation("attack-melee-right"):
			anim.play("attack-melee-right")
		if _reloj_ataque <= 0.001:
			_reloj_ataque = cadencia_ataque
			_golpe_contundente()
	else:
		ir_a(jugador.global_position)
		
	move_and_slide()

func ir_a(destino: Vector3):
	var hacia = destino - global_position
	hacia.y = 0.0
	if hacia.length_squared() > 0.01:
		var dir = hacia.normalized()
		velocity.x = dir.x * rapidez
		velocity.z = dir.z * rapidez
		basis = Basis.looking_at(dir)
		if anim != null and anim.has_animation("walk"):
			anim.play("walk")

func frenar():
	velocity.x = 0.0
	velocity.z = 0.0
	if anim != null and anim.has_animation("idle"):
		anim.play("idle")

func distancia_a(p: Vector3) -> float:
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()

func _golpe_contundente():
	if jugador != null:
		if jugador.has_node("Salud"):
			jugador.get_node("Salud").recibir_golpe(int(dano_ataque))
		if jugador.has_method("recibir_dano"):
			jugador.recibir_dano(dano_ataque)

func recibir_dano(cantidad: float, es_critico: bool = false):
	vida -= cantidad
	
	# Shudder de impacto pesado
	if modelo != null:
		var tw = create_tween()
		tw.tween_property(modelo, "scale", _escala_base * 1.1, 0.05)
		tw.tween_property(modelo, "scale", _escala_base, 0.08)
		
	# Spawn Damage Number 3D
	_spawn_damage_number(cantidad, es_critico)
	
	if vida <= 0.0:
		morir()

func _spawn_damage_number(cantidad: float, es_critico: bool):
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var num = escena.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.3, 0.3), 2.8, randf_range(-0.3, 0.3))
		get_parent().add_child(num)
		num.global_position = pos_num
		num.iniciar(cantidad, es_critico, false)

func morir():
	# El Bruto arroja un cofre o múltiples recompensas de alto valor
	var drop_escena = load("res://drop_item.tscn")
	if drop_escena != null:
		for i in range(3):
			var drop = drop_escena.instantiate()
			var angulo = randf() * TAU
			var pos_drop = global_position + Vector3(cos(angulo) * 0.8, 0.4, sin(angulo) * 0.8)
			get_parent().add_child(drop)
			drop.global_position = pos_drop
			
	if jugador != null and jugador.has_method("registrar_baja"):
		jugador.registrar_baja()
	queue_free()
