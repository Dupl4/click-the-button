class_name NodePool
extends Node

# Pool de objetos para optimizar el rendimiento y reutilizar nodos (proyectiles, enemigos)

signal object_spawned(instance: Node)
signal object_despawned(instance: Node)

@export var scene_to_pool: PackedScene
@export var initial_size: int = 64
@export var max_size: int = 512
@export var auto_expand: bool = true

# Fast FIFO/LIFO stack of idle nodes
var _available_pool: Array[Node] = []
# Set of currently active nodes (for O(1) double-free protection)
var _active_nodes: Dictionary = {}

static var _registry: Dictionary = {}

# Registers pool globally under a unique pool_id
static func register_pool(pool_id: String, pool_instance: NodePool) -> void:
	_registry[pool_id] = pool_instance

# Unregisters pool from registry
static func unregister_pool(pool_id: String) -> void:
	_registry.erase(pool_id)

# Global access to registered pools
static func get_pool(pool_id: String) -> NodePool:
	return _registry.get(pool_id, null)

# Convenient safe recycle: returns to its origin pool if pooled, else queue_free()
static func recycle(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.has_meta("pool_origin"):
		var origin = node.get_meta("pool_origin")
		if is_instance_valid(origin) and origin is NodePool:
			origin.release(node)
			return
	node.queue_free()

func _ready() -> void:
	if scene_to_pool != null:
		_prewarm_pool(initial_size)

# Pre-allocates instances into the pool
func _prewarm_pool(count: int) -> void:
	for i in range(count):
		var inst := _instantiate_fresh()
		if inst != null:
			_deactivate_node(inst)
			_available_pool.push_back(inst)

# Acquires an instance from the pool.
# If parent is null, node remains child of this pool node or caller adds it.
func acquire(parent: Node = null) -> Node:
	var instance: Node = null

	if not _available_pool.is_empty():
		instance = _available_pool.pop_back()
	elif auto_expand and (_active_nodes.size() + _available_pool.size()) < max_size:
		instance = _instantiate_fresh()
	else:
		push_warning("[NodePool] Exhausted pool for scene: %s (Max: %d)" % [
			scene_to_pool.resource_path if scene_to_pool else "null",
			max_size
		])
		return null

	_active_nodes[instance] = true
	instance.set_meta("pool_origin", self)

	if parent != null and instance.get_parent() != parent:
		if instance.get_parent() != null:
			instance.get_parent().remove_child(instance)
		parent.add_child(instance)
	elif instance.get_parent() == null:
		add_child(instance)

	_activate_node(instance)
	object_spawned.emit(instance)
	return instance

# Returns an instance back to the pool
func release(instance: Node) -> void:
	if instance == null:
		return

	if not _active_nodes.has(instance):
		# Prevent double release or releasing foreign node
		push_warning("[NodePool] Attempted to release node not tracked by this pool: %s" % instance.name)
		return

	_active_nodes.erase(instance)
	_deactivate_node(instance)

	# Keep child of pool container while dormant
	if instance.get_parent() != self:
		if instance.get_parent() != null:
			instance.get_parent().remove_child(instance)
		add_child(instance)

	_available_pool.push_back(instance)
	object_despawned.emit(instance)

# Cleans up all active and idle nodes
func clear_all() -> void:
	for inst in _active_nodes.keys():
		if is_instance_valid(inst):
			inst.queue_free()
	_active_nodes.clear()

	for inst in _available_pool:
		if is_instance_valid(inst):
			inst.queue_free()
	_available_pool.clear()

func get_active_count() -> int:
	return _active_nodes.size()

func get_available_count() -> int:
	return _available_pool.size()

func _instantiate_fresh() -> Node:
	if scene_to_pool == null:
		push_error("[NodePool] scene_to_pool is not assigned!")
		return null
	var inst := scene_to_pool.instantiate()
	add_child(inst)
	return inst

func _activate_node(inst: Node) -> void:
	inst.process_mode = Node.PROCESS_MODE_INHERIT
	if inst is CanvasItem:
		inst.visible = true
	if inst is CollisionObject2D:
		inst.set_deferred("collision_layer", 1)
		inst.set_deferred("collision_mask", 1)

	# Execute custom pool lifecycle hook if implemented on node script
	if inst.has_method("on_pool_spawn"):
		inst.call("on_pool_spawn")

func _deactivate_node(inst: Node) -> void:
	inst.process_mode = Node.PROCESS_MODE_DISABLED
	if inst is CanvasItem:
		inst.visible = false
	if inst is CollisionObject2D:
		inst.set_deferred("collision_layer", 0)
		inst.set_deferred("collision_mask", 0)

	# Execute custom pool reset hook if implemented on node script
	if inst.has_method("on_pool_despawn"):
		inst.call("on_pool_despawn")
