class_name EvolucionManager
extends Node

## EvolucionManager (FSM de Evolución de Clases y Metamorfosis 3D)
## Administra la transición de estados de clase del jugador y el intercambio de mallas 3D en tiempo real.

enum EstadoFSM {
	NOVATO,        # Clase base inicial
	DISPONIBLE,    # Cumplió hito (Nivel 3 o 15 clics), listo para elegir
	METAMORFOSIS,  # Modal activo / proceso de transformación
	EVOLUCIONADO   # Clase definitiva seleccionada
}

signal metamorfosis_disponible()
signal clase_evolucionada(nombre_clase: String, stats: Dictionary)
signal malla_cambiada(nuevo_modelo: Node3D)

const HITO_NIVEL: int = 3
const HITO_CLICS: int = 15

const MALLAS_CLASE = {
	"Novato": "res://personaje/character-male-a.glb",
	"Guerrero": "res://personaje/character-male-d.glb",
	"Cazador": "res://personaje/character-female-e.glb",
	"Mago": "res://personaje/character-female-b.glb"
}

const STATS_CLASE = {
	"Novato": {
		"nombre": "Novato",
		"rol": "Aventurero Base",
		"descripcion": "Combatiente novato que recién ingresa al Coliseo.",
		"vida_maxima": 100.0,
		"dano": 12.0,
		"rango_ataque": 2.8,
		"cadencia_ataque": 0.80,
		"speed_caminar": 3.2,
		"speed_correr": 5.5
	},
	"Guerrero": {
		"nombre": "Guerrero",
		"rol": "Tanque / Melee Colosal",
		"descripcion": "Especialista en combate cuerpo a cuerpo y resistencia extrema.",
		"vida_maxima": 160.0,
		"dano": 22.0,
		"rango_ataque": 3.0,
		"cadencia_ataque": 0.70,
		"speed_caminar": 3.2,
		"speed_correr": 5.6
	},
	"Cazador": {
		"nombre": "Cazador",
		"rol": "Ranger / Ráfaga Veloz",
		"descripcion": "Especialista en disparos continuos a distancia y evasión veloz.",
		"vida_maxima": 100.0,
		"dano": 14.0,
		"rango_ataque": 7.5,
		"cadencia_ataque": 0.45,
		"speed_caminar": 3.8,
		"speed_correr": 6.4
	},
	"Mago": {
		"nombre": "Mago",
		"rol": "Arcanista / Daño Mágico Masivo",
		"descripcion": "Lanza proyectiles arcanos devastadores a media distancia.",
		"vida_maxima": 85.0,
		"dano": 28.0,
		"rango_ataque": 5.5,
		"cadencia_ataque": 0.90,
		"speed_caminar": 3.3,
		"speed_correr": 5.7
	}
}

var estado_actual: EstadoFSM = EstadoFSM.NOVATO
var total_clics_acumulados: int = 0
var personaje_ref: CharacterBody3D = null
var modal_instancia: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if get_parent() is CharacterBody3D:
		configurar_con_personaje(get_parent() as CharacterBody3D)

func configurar_con_personaje(personaje: CharacterBody3D):
	personaje_ref = personaje
	call_deferred("_vincular_eventos_externos")

func _obtener_tree() -> SceneTree:
	if is_inside_tree():
		return get_tree()
	return Engine.get_main_loop() as SceneTree

func _vincular_eventos_externos():
	var tree = _obtener_tree()
	if tree == null:
		return
	var boton = tree.get_first_node_in_group("boton_movil")
	if boton != null and boton.has_signal("click_presionado"):
		if not boton.click_presionado.is_connected(_on_boton_movil_click):
			boton.click_presionado.connect(_on_boton_movil_click)

func _on_boton_movil_click(_total_clicks: int):
	registrar_click()

func registrar_click():
	if estado_actual != EstadoFSM.NOVATO:
		return
	total_clics_acumulados += 1
	_evaluar_hito_evolucion()

func notificar_nivel(_nuevo_nivel: int):
	if estado_actual != EstadoFSM.NOVATO:
		return
	_evaluar_hito_evolucion()

func _evaluar_hito_evolucion():
	if estado_actual != EstadoFSM.NOVATO:
		return
	
	var nivel_actual = personaje_ref.nivel if personaje_ref != null else 1
	if nivel_actual >= HITO_NIVEL or total_clics_acumulados >= HITO_CLICS:
		disparar_metamorfosis()

func disparar_metamorfosis():
	if estado_actual != EstadoFSM.NOVATO:
		return
	
	estado_actual = EstadoFSM.DISPONIBLE
	emit_signal("metamorfosis_disponible")
	print("⚡ [FSM Evolución] ¡Hito alcanzado! (Nivel %d, Clics %d). Metamorfosis disponible." % [
		personaje_ref.nivel if personaje_ref != null else 1,
		total_clics_acumulados
	])
	abrir_modal_evolucion()

func abrir_modal_evolucion():
	if modal_instancia != null and is_instance_valid(modal_instancia):
		return
	
	estado_actual = EstadoFSM.METAMORFOSIS
	var escena_modal = load("res://modal_evolucion.tscn")
	if escena_modal != null:
		modal_instancia = escena_modal.instantiate()
		var tree = _obtener_tree()
		if tree != null and tree.root != null:
			tree.root.add_child(modal_instancia)
			if modal_instancia.has_signal("clase_seleccionada"):
				modal_instancia.clase_seleccionada.connect(_on_clase_elegida_en_modal)
			tree.paused = true
	else:
		push_error("No se encontró la escena res://modal_evolucion.tscn")

func _on_clase_elegida_en_modal(nombre_clase: String):
	if modal_instancia != null and is_instance_valid(modal_instancia):
		modal_instancia.queue_free()
		modal_instancia = null
	var tree = _obtener_tree()
	if tree != null:
		tree.paused = false
	evolucionar_a(nombre_clase)

func evolucionar_a(nombre_clase: String):
	if not STATS_CLASE.has(nombre_clase):
		push_error("Clase desconocida para evolución: " + nombre_clase)
		return
	
	estado_actual = EstadoFSM.EVOLUCIONADO
	var stats = STATS_CLASE[nombre_clase]
	
	if personaje_ref != null:
		# 1. Actualizar atributos
		personaje_ref.clase = nombre_clase
		personaje_ref.vida_maxima = stats["vida_maxima"]
		personaje_ref.vida = stats["vida_maxima"] # Cura completa por metamorfosis
		personaje_ref.dano = stats["dano"]
		personaje_ref.rango_ataque = stats["rango_ataque"]
		personaje_ref.cadencia_ataque = stats["cadencia_ataque"]
		personaje_ref.speed_caminar = stats["speed_caminar"]
		personaje_ref.speed_correr = stats["speed_correr"]
		
		# 2. Intercambio de malla 3D en tiempo real
		var ruta_malla = MALLAS_CLASE.get(nombre_clase, "")
		if ruta_malla != "":
			var nuevo_anim = cambiar_malla_3d(personaje_ref, ruta_malla)
			if nuevo_anim != null:
				personaje_ref.anim = nuevo_anim
				personaje_ref.animar()
		
		# 3. Disparo de feedback visual / popup
		_emitir_feedback_metamorfosis(nombre_clase)
		
		# 4. Notificar actualización de estadísticas
		personaje_ref.emit_signal("stats_actualizadas",
			personaje_ref.vida,
			personaje_ref.vida_maxima,
			personaje_ref.xp,
			personaje_ref.xp_siguiente_nivel,
			personaje_ref.nivel,
			personaje_ref.oro,
			personaje_ref.bajas
		)
	
	emit_signal("clase_evolucionada", nombre_clase, stats)
	print("✨ [FSM Evolución] ¡Metamorfosis completada! Nueva clase activa: %s" % nombre_clase)

func cambiar_malla_3d(personaje: CharacterBody3D, ruta_malla: String) -> AnimationPlayer:
	if not ResourceLoader.exists(ruta_malla):
		push_error("No se encontró recurso de malla: " + ruta_malla)
		return null
	
	var escena_glb = load(ruta_malla)
	if escena_glb == null:
		push_error("Fallo al instanciar modelo .glb: " + ruta_malla)
		return null
	
	var modelo_actual = personaje.get_node_or_null("Modelo")
	var transform_base = Transform3D(Basis(Vector3(-2.6, 0.0, 0.0), Vector3(0.0, 2.6, 0.0), Vector3(0.0, 0.0, -2.6)), Vector3.ZERO)
	
	if modelo_actual != null:
		transform_base = modelo_actual.transform
		modelo_actual.name = "Modelo_Antiguo"
		modelo_actual.queue_free()
	
	var nuevo_modelo = escena_glb.instantiate()
	nuevo_modelo.name = "Modelo"
	nuevo_modelo.transform = transform_base
	personaje.add_child(nuevo_modelo)
	
	var nuevo_anim = nuevo_modelo.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if nuevo_anim == null:
		push_warning("El modelo nuevo %s no contiene nodo AnimationPlayer" % ruta_malla)
	
	emit_signal("malla_cambiada", nuevo_modelo)
	return nuevo_anim

func _emitir_feedback_metamorfosis(nombre_clase: String):
	if personaje_ref == null or not personaje_ref.is_inside_tree():
		return
	
	if personaje_ref.get_parent() != null:
		var escena_num = load("res://damage_number_3d.tscn")
		if escena_num != null:
			var txt = escena_num.instantiate()
			var pos = personaje_ref.global_position + Vector3(0, 2.4, 0)
			personaje_ref.get_parent().add_child(txt)
			txt.global_position = pos
			if txt.has_method("iniciar"):
				txt.iniciar(0.0, false, false)
			var label = txt.get_node_or_null("SubViewport/Label") as Label
			if label != null:
				label.text = "¡EVOLUCIÓN A %s!" % nombre_clase.to_upper()
				label.modulate = Color(1.0, 0.85, 0.1)
	
	var luz = OmniLight3D.new()
	luz.light_color = Color(1.0, 0.9, 0.4)
	luz.light_energy = 3.5
	luz.omni_range = 8.0
	personaje_ref.add_child(luz)
	luz.position = Vector3(0, 1.2, 0)
	
	var tween = personaje_ref.create_tween()
	if tween != null:
		tween.tween_property(luz, "light_energy", 0.0, 0.65)
		tween.tween_callback(luz.queue_free)
	else:
		luz.queue_free()
