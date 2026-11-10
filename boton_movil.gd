extends Area3D

signal click_presionado(total_clicks: int)

@export var rapidez_base: float = 2.8
@export var rapidez_maxima: float = 7.5
@export var radio_onda_choque: float = 5.0
@export var empuje_onda: float = 7.0
@export var clicks_para_teleport: int = 5

# 6 waypoints a través de la arena 60x60
var ruta: Array[Vector3] = [
	Vector3(0, 0.7, 0),       # Altar Central
	Vector3(18, 0.7, -16),    # Noreste
	Vector3(0, 0.7, -22),     # Norte
	Vector3(-18, 0.7, -16),   # Noroeste
	Vector3(-18, 0.7, 18),    # Suroeste
	Vector3(18, 0.7, 18)      # Sureste
]

var indice_ruta: int = 0
var total_clicks: int = 0
var rapidez_movimiento: float = 2.8
var escala_actual: float = 1.0
var jugador: Node3D = null
var _altura_base: float = 0.7
var _reloj_flotacion: float = 0.0
var _esta_presionado: bool = false
var _en_teletransporte: bool = false

@onready var parte_boton: MeshInstance3D = $Pedestal/BotonPulsable
@onready var anillo_runico: MeshInstance3D = $Pedestal/AnilloRunico
@onready var luz_nucleo: OmniLight3D = $LuzNucleo

func _ready():
	add_to_group("boton_movil")
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	jugador = get_tree().get_first_node_in_group("jugador")
	rapidez_movimiento = rapidez_base
	if ruta.size() > 0:
		global_position = ruta[0]

func _physics_process(delta):
	if _en_teletransporte:
		return
		
	# 1. Movimiento entre waypoints con velocidad dinámica
	if ruta.size() > 0:
		var destino = ruta[indice_ruta]
		var plano_pos = Vector2(global_position.x, global_position.z)
		var plano_dest = Vector2(destino.x, destino.z)
		
		if plano_pos.distance_to(plano_dest) < 0.7:
			indice_ruta = (indice_ruta + 1) % ruta.size()
		else:
			var dir = (destino - global_position).normalized()
			global_position.x += dir.x * rapidez_movimiento * delta
			global_position.z += dir.z * rapidez_movimiento * delta
			
	# 2. Flotación y ondulación suave (bobbing)
	_reloj_flotacion += delta * 3.5
	if not _esta_presionado:
		global_position.y = _altura_base + sin(_reloj_flotacion) * 0.12
		
	# 3. Rotación continua del anillo rúnico (más rápida entre más clicks)
	if anillo_runico != null:
		anillo_runico.rotate_y(delta * (1.8 + total_clicks * 0.1))

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		activar_click()

func _unhandled_input(event):
	# Detección de respaldo con rayo desde la cámara
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cam = get_viewport().get_camera_3d()
		if cam != null:
			var mouse_pos = event.position
			var ray_from = cam.project_ray_origin(mouse_pos)
			var ray_dir = cam.project_ray_normal(mouse_pos)
			var ray_to = ray_from + ray_dir * 150.0
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
			query.collide_with_areas = true
			query.collide_with_bodies = false
			var result = space_state.intersect_ray(query)
			if result and result.collider == self:
				activar_click()

func activar_click():
	if _en_teletransporte:
		return
		
	total_clicks += 1
	_esta_presionado = true
	emit_signal("click_presionado", total_clicks)
	
	# 1. Escalado de Dificultad: Aumento progresivo de velocidad
	rapidez_movimiento = minf(rapidez_maxima, rapidez_base + (total_clicks * 0.22))
	
	# 2. Escalado de Dificultad: Reducción progresiva de tamaño (hitbox más pequeña)
	escala_actual = maxf(0.52, 1.0 - (total_clicks * 0.022))
	var tw_escala = create_tween()
	tw_escala.tween_property(self, "scale", Vector3(escala_actual, escala_actual, escala_actual), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 3. Animación física de pulsación hacia abajo
	if parte_boton != null:
		var tw = create_tween()
		tw.tween_property(parte_boton, "position:y", -0.15, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(parte_boton, "position:y", 0.12, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.finished.connect(func(): _esta_presionado = false)
		
	# 4. Pulso de luz y destello
	if luz_nucleo != null:
		var tw_luz = create_tween()
		tw_luz.tween_property(luz_nucleo, "light_energy", 3.8, 0.05)
		tw_luz.tween_property(luz_nucleo, "light_energy", 1.2, 0.22)

	# 5. Recompensas directas al héroe (más equilibradas)
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
	if jugador != null and jugador.has_method("recoger_drop"):
		jugador.recoger_drop(0, 2) # +2 Oro
		jugador.recoger_drop(1, 2) # +2 XP (curva más exigente)
		
	# 6. Texto flotante 3D sobre el botón
	_spawn_floating_text("¡CLIC! +2💰 +2✨")
	
	# 7. Onda de choque expansiva
	_detonar_onda_choque()
	
	# 8. Escalado de Dificultad: Teletransporte cada 5 clicks
	if total_clicks % clicks_para_teleport == 0:
		_ejecutar_teletransporte()

func _ejecutar_teletransporte():
	_en_teletransporte = true
	_spawn_floating_text("¡TELETRANSPORTE! ⚡")
	
	# Efecto de destello y desvanecimiento
	if luz_nucleo != null:
		luz_nucleo.light_energy = 5.0
		luz_nucleo.light_color = Color(0.2, 0.85, 1.0)
		
	var tw_desaparecer = create_tween()
	tw_desaparecer.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await tw_desaparecer.finished
	
	# Elegir una nueva posición en la arena 60x60 alejada del jugador
	var nueva_pos = Vector3.ZERO
	for intento in range(10):
		var rx = randf_range(-22.0, 22.0)
		var rz = randf_range(-22.0, 22.0)
		var candidato = Vector3(rx, _altura_base, rz)
		if jugador == null or candidato.distance_to(jugador.global_position) > 15.0:
			nueva_pos = candidato
			break
			
	global_position = nueva_pos
	indice_ruta = randi() % ruta.size()
	
	# Reaparecer con efecto pop elástico
	var tw_reaparecer = create_tween()
	tw_reaparecer.tween_property(self, "scale", Vector3(escala_actual, escala_actual, escala_actual), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if luz_nucleo != null:
		var tw_luz = create_tween()
		tw_luz.tween_property(luz_nucleo, "light_energy", 1.2, 0.3)
		tw_luz.parallel().tween_property(luz_nucleo, "light_color", Color(1.0, 0.45, 0.2), 0.3)
		
	# Limpieza con onda de choque en el punto de llegada
	_detonar_onda_choque()
	_en_teletransporte = false

func _spawn_floating_text(txt: String):
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var num = escena.instantiate()
		var pos_num = global_position + Vector3(0, 1.8, 0)
		get_parent().add_child(num)
		num.global_position = pos_num
		num.iniciar(0, true, false, txt)

func _detonar_onda_choque():
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if e is Node3D:
			var dist = global_position.distance_to(e.global_position)
			if dist <= radio_onda_choque:
				if e.has_method("recibir_dano"):
					var dano_onda = 14.0
					if jugador != null and "dano" in jugador:
						dano_onda = jugador.dano * 0.75
					e.recibir_dano(dano_onda, true)
				var dir_empuje = (e.global_position - global_position).normalized()
				dir_empuje.y = 0.0
				if "velocity" in e:
					e.velocity += dir_empuje * empuje_onda
