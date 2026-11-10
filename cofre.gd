extends Area3D

signal recogido(valor)

@export var valor = 25

func _ready():
	add_to_group("objetivos")
	body_entered.connect(_al_entrar)
	mouse_entered.connect(_on_mouse_entered)

func _al_entrar(cuerpo):
	if not cuerpo.is_in_group("jugador"):
		return
	recolectar()

func _on_mouse_entered():
	recolectar()

func recolectar():
	# queue_free borra al final del cuadro: aquí todavía cuenta.
	var faltan = get_tree().get_nodes_in_group("objetivos").size() - 1
	print(name, " +", valor, " · faltan ", faltan, " · cuadro ",
		Engine.get_physics_frames())
	recogido.emit(valor)
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		partida.avisar_meta()
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj != null and pj.has_method("recoger_drop"):
		pj.recoger_drop(0, valor) # +25 Oro
		pj.recoger_drop(1, 35)    # +35 XP
	queue_free()
