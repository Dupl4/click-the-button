class_name MapManager
extends Node2D

# Gestor de escenarios y límites de la arena de juego

signal biome_loaded(biome_id: String)
signal arena_boundaries_updated(bounds: Rect2)

@export_group("Arena Bounds")
@export var arena_size: Vector2 = Vector2(2560.0, 1440.0)
@export var wall_thickness: float = 64.0

@export_group("Biome Configuration")
@export var active_biome_id: String = "FOREST_ARENA"

# Static boundary physics container
var _boundary_body: StaticBody2D = null
var _obstacles_container: Node2D = null

const BIOME_DATA: Dictionary = {
	"FOREST_ARENA": {
		"name": "Verdant Clearing",
		"bg_color": Color(0.11, 0.16, 0.12),
		"boundary_color": Color(0.24, 0.35, 0.22),
		"obstacle_count": 12,
		"ambient_light": Color(0.85, 0.95, 0.85)
	},
	"DUNGEON_CRYPT": {
		"name": "Forgotten Sepulcher",
		"bg_color": Color(0.08, 0.08, 0.12),
		"boundary_color": Color(0.25, 0.25, 0.35),
		"obstacle_count": 20,
		"ambient_light": Color(0.65, 0.65, 0.85)
	},
	"VOLCANIC_FORGE": {
		"name": "Obsidian Caldera",
		"bg_color": Color(0.15, 0.08, 0.06),
		"boundary_color": Color(0.45, 0.15, 0.1),
		"obstacle_count": 16,
		"ambient_light": Color(1.0, 0.75, 0.6)
	}
}

func _ready() -> void:
	_setup_containers()
	load_biome(active_biome_id)

func _setup_containers() -> void:
	if _boundary_body == null:
		_boundary_body = StaticBody2D.new()
		_boundary_body.name = "ArenaBoundaries"
		_boundary_body.collision_layer = 1
		_boundary_body.collision_mask = 0
		add_child(_boundary_body)

	if _obstacles_container == null:
		_obstacles_container = Node2D.new()
		_obstacles_container.name = "Obstacles"
		add_child(_obstacles_container)

# Loads and sets up an arena for a given biome ID
func load_biome(biome_id: String) -> void:
	if not BIOME_DATA.has(biome_id):
		push_warning("[MapManager] Unknown biome %s, defaulting to FOREST_ARENA" % biome_id)
		biome_id = "FOREST_ARENA"

	active_biome_id = biome_id
	var config: Dictionary = BIOME_DATA[biome_id]

	_build_boundary_walls()
	_generate_obstacles(config.get("obstacle_count", 10))

	var bounds := get_arena_rect()
	arena_boundaries_updated.emit(bounds)
	biome_loaded.emit(biome_id)
	print("[MapManager] Biome loaded: %s (Bounds: %s)" % [config.get("name"), bounds])

# Generates 4 perimeter wall collision shapes
func _build_boundary_walls() -> void:
	# Clear existing boundary shapes
	for child in _boundary_body.get_children():
		child.queue_free()

	var half_w := arena_size.x * 0.5
	var half_h := arena_size.y * 0.5
	var t := wall_thickness

	# Top Wall
	_create_wall_collider(
		Vector2(0.0, -half_h - t * 0.5),
		Vector2(arena_size.x + t * 2.0, t)
	)
	# Bottom Wall
	_create_wall_collider(
		Vector2(0.0, half_h + t * 0.5),
		Vector2(arena_size.x + t * 2.0, t)
	)
	# Left Wall
	_create_wall_collider(
		Vector2(-half_w - t * 0.5, 0.0),
		Vector2(t, arena_size.y + t * 2.0)
	)
	# Right Wall
	_create_wall_collider(
		Vector2(half_w + t * 0.5, 0.0),
		Vector2(t, arena_size.y + t * 2.0)
	)

func _create_wall_collider(pos: Vector2, size: Vector2) -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	_boundary_body.add_child(col)

func _generate_obstacles(count: int) -> void:
	# Clear existing
	for child in _obstacles_container.get_children():
		child.queue_free()

	var bounds := get_arena_rect()
	var padding := 150.0 # Keep center and perimeter clear
	var safe_w := (bounds.size.x * 0.5) - padding
	var safe_h := (bounds.size.y * 0.5) - padding

	# Procedurally place static pillars/rocks
	for i in range(count):
		var pos := Vector2(
			randf_range(-safe_w, safe_w),
			randf_range(-safe_h, safe_h)
		)
		# Avoid placing directly on center spawn (0,0)
		if pos.length() < 200.0:
			continue

		var pillar := StaticBody2D.new()
		pillar.name = "Pillar_%d" % i
		pillar.position = pos
		pillar.collision_layer = 1
		pillar.collision_mask = 0

		var shape_node := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = randf_range(24.0, 48.0)
		shape_node.shape = circle
		pillar.add_child(shape_node)

		_obstacles_container.add_child(pillar)

# Returns the playable arena bounding box in local space
func get_arena_rect() -> Rect2:
	return Rect2(-arena_size * 0.5, arena_size)

# Checks if a point is within legal arena bounds (with optional margin)
func is_position_in_bounds(pos: Vector2, margin: float = 0.0) -> bool:
	var bounds := get_arena_rect()
	if margin != 0.0:
		bounds = bounds.grow(-margin)
	return bounds.has_point(pos)

# Returns a random spawn position just outside the camera viewport but within arena
func get_spawn_point_outside(center: Vector2, min_dist: float, max_dist: float) -> Vector2:
	var attempts := 10
	var bounds := get_arena_rect()

	while attempts > 0:
		var angle := randf() * TAU
		var dist := randf_range(min_dist, max_dist)
		var candidate := center + Vector2(cos(angle), sin(angle)) * dist
		if bounds.has_point(candidate):
			return candidate
		attempts -= 1

	# Fallback clamped
	var fallback_angle := randf() * TAU
	var fallback_candidate := center + Vector2(cos(fallback_angle), sin(fallback_angle)) * min_dist
	return Vector2(
		clampf(fallback_candidate.x, bounds.position.x + 50.0, bounds.end.x - 50.0),
		clampf(fallback_candidate.y, bounds.position.y + 50.0, bounds.end.y - 50.0)
	)
