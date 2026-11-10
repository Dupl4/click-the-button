extends Area3D

enum TipoDrop { ORO, EXP, CORAZON }

@export var tipo: TipoDrop = TipoDrop.ORO
@export var valor: int = 5
@export var velocidad_iman: float = 7.0
@export var radio_atraccion: float = 3.5

var jugador: Node3D = null
var recogido = false

func _ready():
	body_entered.connect(_on_body_entered)
	jugador = get_tree().get_first_node_in_group("jugador")

func _process(delta):
	# Rotación continua
	rotate_y(2.5 * delta)
	
	if recogido:
		return
		
	if jugador != null:
		var d = global_position.distance_to(jugador.global_position)
		if d < radio_atraccion:
			var dir = (jugador.global_position + Vector3(0, 0.8, 0) - global_position).normalized()
			global_position += dir * velocidad_iman * delta

func _on_body_entered(body):
	if recogido:
		return
	if body.is_in_group("jugador"):
		recogido = true
		if body.has_method("recoger_drop"):
			body.recoger_drop(tipo, valor)
		queue_free()
