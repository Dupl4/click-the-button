extends Node3D

@export var energia_base: float = 1.3
@export var rango_luz: float = 8.5
@export var color_fuego: Color = Color(1.0, 0.62, 0.22, 1.0)

@onready var luz: OmniLight3D = $OmniLight3D
@onready var fuego_mesh: MeshInstance3D = $FuegoMesh

var _tiempo: float = 0.0
var _offset_fase: float = 0.0

func _ready():
	_offset_fase = randf() * 100.0
	if luz != null:
		luz.light_color = color_fuego
		luz.omni_range = rango_luz
		luz.shadow_enabled = true
		luz.omni_attenuation = 1.4

func _process(delta):
	_tiempo += delta * 12.0
	# Parpadeo procedural realista de llama de fuego
	var fluctuacion = sin(_tiempo + _offset_fase) * 0.12 + cos(_tiempo * 2.3 + _offset_fase) * 0.08 + randf_range(-0.04, 0.04)
	if luz != null:
		luz.light_energy = maxf(0.6, energia_base + fluctuacion)
	if fuego_mesh != null:
		var s = 1.0 + fluctuacion * 0.25
		fuego_mesh.scale = Vector3(s, s * 1.2, s)
