extends CanvasLayer

signal clase_seleccionada(nombre_clase: String)

@onready var btn_guerrero: Button = $Control/Panel/Margin/VBox/HBoxCartas/CardGuerrero/BtnElegirGuerrero
@onready var btn_cazador: Button = $Control/Panel/Margin/VBox/HBoxCartas/CardCazador/BtnElegirCazador
@onready var btn_mago: Button = $Control/Panel/Margin/VBox/HBoxCartas/CardMago/BtnElegirMago

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20 # Por encima de cualquier interfaz normal
	
	btn_guerrero.pressed.connect(func(): _on_seleccionar("Guerrero"))
	btn_cazador.pressed.connect(func(): _on_seleccionar("Cazador"))
	btn_mago.pressed.connect(func(): _on_seleccionar("Mago"))

func _on_seleccionar(clase: String):
	emit_signal("clase_seleccionada", clase)
