extends CharacterBody3D

enum Estado { QUIETO, CAMINAR, CORRER, AIRE }
const RUIDO = [0.0, 2.5, 6.5, 0.0]
const EvolucionManager = preload("res://evolucion_manager.gd")

signal stats_actualizadas(vida, max_vida, xp, xp_sig, nivel, oro, bajas)
signal nivel_subido(nuevo_nivel)

@export var camara: Camera3D
@export var speed_caminar = 3.2
@export var speed_correr = 5.8
@export var tiempo_arranque = 0.20
@onready var anim = $Modelo/AnimationPlayer

# Estadísticas RPG / Autobattler
var clase: String = "Novato"
var vida_maxima: float = 100.0
var vida: float = 100.0
var dano: float = 12.0
var rango_ataque: float = 2.8
var cadencia_ataque: float = 0.80
var oro: int = 0
var xp: int = 0
var xp_siguiente_nivel: int = 60
var nivel: int = 1
var bajas: int = 0

var evolucion_manager: EvolucionManager = null

var _reloj_ataque: float = 0.0
var _reloj_anim_accion: float = 0.0

var multiplicador = 1.0
var empuje = Vector3.ZERO
var accion = ""
var avance = Vector3.ZERO

var estado = Estado.QUIETO
var ruido = 0.0

func _ready():
	add_to_group("jugador")
	if camara == null and get_viewport() != null:
		camara = get_viewport().get_camera_3d()
	
	if anim == null and has_node("Modelo/AnimationPlayer"):
		anim = $Modelo/AnimationPlayer
	
	if has_node("EvolucionManager"):
		evolucion_manager = $EvolucionManager
	else:
		evolucion_manager = EvolucionManager.new()
		evolucion_manager.name = "EvolucionManager"
		add_child(evolucion_manager)
	
	evolucion_manager.configurar_con_personaje(self)
	aplicar_clase("Novato")
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		click_attack()

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)

	var giro_cam = camara.global_rotation.y if camara != null else 0.0
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()

	var corre = Input.is_action_pressed("correr")
	var speed = speed_correr if corre else speed_caminar

	var objetivo = direction * speed * multiplicador
	var paso = speed / tiempo_arranque * delta
	avance = avance.move_toward(objetivo, paso)

	velocity.x = avance.x + empuje.x
	velocity.z = avance.z + empuje.z

	if direction.length() > 0:
		basis = Basis.looking_at(direction)

	move_and_slide()

	var antes = estado
	estado = elegir_estado()
	ruido = RUIDO[estado]
	if estado != antes and prueba != 0:
		print("estado ", Estado.keys()[estado], " · ruido ", ruido, " m")
		
	# Manejo de animación de ataque / acción
	if _reloj_anim_accion > 0.0:
		_reloj_anim_accion -= delta
		if _reloj_anim_accion <= 0.0:
			accion = ""
			
	animar()
	_procesar_autobattler(delta)
	_prueba()

func _procesar_autobattler(delta: float):
	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
	if _reloj_ataque <= 0.001:
		var objetivo = _obtener_enemigo_cercano()
		if objetivo != null:
			var d = global_position.distance_to(objetivo.global_position)
			if d <= rango_ataque:
				_ejecutar_ataque(objetivo)
				_reloj_ataque = cadencia_ataque

func _obtener_enemigo_cercano() -> Node3D:
	if not is_inside_tree() or get_tree() == null:
		return null
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	var mas_cercano: Node3D = null
	var menor_dist = 9999.0
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			var dist = global_position.distance_to(e.global_position)
			if dist < menor_dist:
				menor_dist = dist
				mas_cercano = e
	return mas_cercano

func _ejecutar_ataque(enemigo: Node3D):
	if clase == "Novato" or clase == "Guerrero":
		# Corte melee directo
		accion = "attack-melee-right"
		_reloj_anim_accion = 0.35
		var dir = (enemigo.global_position - global_position).normalized()
		dir.y = 0.0
		if dir.length() > 0.01:
			basis = Basis.looking_at(dir)
		if enemigo.has_method("recibir_dano"):
			enemigo.recibir_dano(dano)
	else:
		# Disparo o hechizo
		accion = "attack-melee-right"
		_reloj_anim_accion = 0.25
		var proyectil_escena = load("res://proyectil.tscn")
		if proyectil_escena != null:
			var p = proyectil_escena.instantiate()
			var origen = global_position + Vector3(0, 0.9, 0)
			var dir = (enemigo.global_position + Vector3(0, 0.9, 0) - origen).normalized()
			get_parent().add_child(p)
			p.iniciar(origen, dir, dano, 15.0 if clase == "Cazador" else 10.0)

func click_attack():
	# Click manual tipo clicker
	var objetivo = _obtener_enemigo_cercano()
	accion = "attack-melee-right"
	_reloj_anim_accion = 0.2
	if objetivo != null and global_position.distance_to(objetivo.global_position) <= rango_ataque + 2.5:
		if objetivo.has_method("recibir_dano"):
			objetivo.recibir_dano(dano * 0.75, true)
	# Bono incremental de click
	oro += 1
	recoger_drop(0, 1) # +1 XP por click
	if evolucion_manager != null:
		evolucion_manager.registrar_click()

func recibir_dano(cantidad: float):
	vida = maxf(vida - cantidad, 0.0)
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var num = escena.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.2, 0.2), 2.0, randf_range(-0.2, 0.2))
		get_parent().add_child(num)
		num.global_position = pos_num
		num.iniciar(cantidad, false, true)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	if vida <= 0.0:
		print("¡Jugador caído! Reiniciando salud...")
		vida = vida_maxima

func recoger_drop(tipo: int, valor: int):
	match tipo:
		0: # ORO
			oro += valor
		1: # EXP
			xp += valor
			if xp >= xp_siguiente_nivel:
				subir_nivel()
		2: # CORAZON
			vida = minf(vida + valor, vida_maxima)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func registrar_baja():
	bajas += 1
	recoger_drop(1, 6) # 6 XP por baja
	recoger_drop(0, 3) # 3 Oro por baja

func subir_nivel():
	xp -= xp_siguiente_nivel
	nivel += 1
	xp_siguiente_nivel = int(xp_siguiente_nivel * 1.55)
	vida = minf(vida + 30.0, vida_maxima) # Cura parcial +30 HP para mayor tension de supervivencia
	emit_signal("nivel_subido", nivel)
	if evolucion_manager != null:
		evolucion_manager.notificar_nivel(nivel)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func aplicar_clase(nombre: String):
	clase = nombre
	match nombre:
		"Novato":
			vida_maxima = 100.0
			vida = 100.0
			dano = 12.0
			rango_ataque = 2.8
			cadencia_ataque = 0.80
			speed_caminar = 3.2
			speed_correr = 5.5
		"Guerrero":
			vida_maxima = 160.0
			vida = 160.0
			dano = 22.0
			rango_ataque = 3.0
			cadencia_ataque = 0.70
			speed_caminar = 3.2
			speed_correr = 5.6
		"Cazador":
			vida_maxima = 100.0
			vida = 100.0
			dano = 14.0
			rango_ataque = 7.5
			cadencia_ataque = 0.45
			speed_caminar = 3.8
			speed_correr = 6.4
		"Mago":
			vida_maxima = 85.0
			vida = 85.0
			dano = 28.0
			rango_ataque = 5.5
			cadencia_ataque = 0.90
			speed_caminar = 3.3
			speed_correr = 5.7
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func aplicar_mejora(tipo_mejora: String):
	match tipo_mejora:
		"dano":
			dano *= 1.25
		"velocidad":
			speed_caminar *= 1.20
			speed_correr *= 1.20
		"vida":
			vida_maxima += 30.0
			vida = minf(vida + 30.0, vida_maxima)
		"cadencia":
			cadencia_ataque = maxf(cadencia_ataque * 0.80, 0.2)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func elegir_estado():
	if not is_on_floor():
		return Estado.AIRE
	var rapidez = Vector2(velocity.x, velocity.z).length()
	if rapidez < 0.1:
		return Estado.QUIETO
	if rapidez > speed_caminar + 0.1:
		return Estado.CORRER
	return Estado.CAMINAR

func animar():
	if accion != "":
		anim.play(accion)
		return
	match estado:
		Estado.QUIETO: anim.play("idle")
		Estado.CAMINAR: anim.play("walk")
		Estado.CORRER: anim.play("sprint")
		Estado.AIRE: anim.play("fall")

@export_enum("Ninguna", "Avanzar 60 cuadros", "Avanzar 60 y soltar", "Avanzar y la accion desde el cuadro 30", "Mantener la accion 2 s", "Avanzar con la accion 60 cuadros", "Diagonal W+D 60 cuadros") var prueba = 0
@export var accion_prueba = "correr"

var _cuadro = 0
var _termino = false

func _prueba():
	if prueba == 0 or _termino:
		return
	_cuadro += 1
	match prueba:
		1:
			if _cuadro == 1: Input.action_press("move_up")
			elif _cuadro == 60:
				var r = Vector2(velocity.x, velocity.z).length()
				print("[prueba] pos: ", global_position.snappedf(0.01), " · vel: ", snappedf(r, 0.01), " · anim: ", anim.current_animation)
				Input.action_release("move_up")
				_termino = true
		2:
			if _cuadro == 1: Input.action_press("move_up")
			elif _cuadro == 60: Input.action_release("move_up")
			if _cuadro >= 60 and _cuadro <= 80:
				var r = Vector2(velocity.x, velocity.z).length()
				print("cuadro ", _cuadro, ": ", snappedf(r, 0.01))
			if _cuadro == 80: _termino = true
		3:
			if _cuadro == 1: Input.action_press("move_up")
			elif _cuadro == 30:
				if InputMap.has_action(accion_prueba): Input.action_press(accion_prueba)
			if _cuadro >= 30 and _cuadro <= 45:
				var r = Vector2(velocity.x, velocity.z).length()
				print("cuadro ", _cuadro, ": ", snappedf(r, 0.01), " · anim: ", anim.current_animation)
			elif _cuadro == 60:
				Input.action_release("move_up")
				if InputMap.has_action(accion_prueba): Input.action_release(accion_prueba)
				_termino = true
