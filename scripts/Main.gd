class_name MainGame
extends Node2D

@export var chest_scene: PackedScene
@export var speed_skill: SkillCardData
@export var health_skill: SkillCardData
@export var range_skill: SkillCardData
@export var haste_skill: SkillCardData

@export var warrior_class: ClassData
@export var mage_class: ClassData
@export var archer_class: ClassData

@onready var player: PlayerCharacter = $Player
@onready var camera: SmoothCamera2D = $SmoothCamera2D
@onready var click_manager: ClickManager = $ClickManager
@onready var leveling_manager: LevelingManager = $LevelingManager
@onready var wave_controller: WaveController = $WaveController
@onready var hud: HUDController = $HUD
@onready var chests_container: Node2D = $ChestsContainer

var audio_manager: AudioManager


func _ready() -> void:
	_setup_audio()
	_setup_skills()
	_setup_camera()
	_setup_connections()
	_init_class_selection()


func _setup_audio() -> void:
	audio_manager = AudioManager.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)


func _setup_skills() -> void:
	var skills: Array[SkillCardData] = []
	if speed_skill != null: skills.append(speed_skill)
	if health_skill != null: skills.append(health_skill)
	if range_skill != null: skills.append(range_skill)
	if haste_skill != null: skills.append(haste_skill)
	leveling_manager.all_available_cards = skills


func _setup_camera() -> void:
	if camera != null and player != null:
		camera.target_node = player
		camera.snap_to_target()


func _setup_connections() -> void:
	hud.initialize(click_manager, leveling_manager, player, audio_manager)
	hud.click_button_pressed.connect(_on_hud_click_button_pressed)
	hud.class_selected.connect(_on_class_selected)
	hud.subclass_selected.connect(_on_subclass_selected)

	click_manager.click_processed.connect(func(xp: float): leveling_manager.add_xp(xp))
	click_manager.chest_spawn_requested.connect(_on_chest_spawn_requested)

	wave_controller.player_target = player
	wave_controller.mob_spawned.connect(_on_mob_spawned)

	if player != null and player.primary_weapon != null:
		player.primary_weapon.melee_slashed.connect(func(_tgt: CharacterBody2D):
			if audio_manager != null:
				audio_manager.play_slash()
		)


func _init_class_selection() -> void:
	# Cargar recursos de clases si no se asignaron en el inspector
	if warrior_class == null:
		warrior_class = load("res://resources/classes/warrior.tres")
	if mage_class == null:
		mage_class = load("res://resources/classes/mage.tres")
	if archer_class == null:
		archer_class = load("res://resources/classes/archer.tres")

	var available_classes: Array[ClassData] = [warrior_class, mage_class, archer_class]
	hud.show_class_selection(available_classes)


func _on_class_selected(cls: ClassData) -> void:
	if player != null:
		player.apply_class(cls)

	if click_manager != null:
		click_manager.set_class_multiplier(cls.click_multiplier)

	if leveling_manager != null:
		leveling_manager.set_evolution_choices(cls.subclasses)


func _on_subclass_selected(sub: SubclassData) -> void:
	if click_manager != null:
		click_manager.set_class_multiplier(click_manager.click_power_multiplier + sub.delta_click_multiplier)


func _on_hud_click_button_pressed() -> void:
	click_manager.register_click()


func _on_chest_spawn_requested(spawn_pos: Vector2) -> void:
	if chest_scene == null:
		return

	var chest_instance: Node = chest_scene.instantiate()
	if chest_instance is Chest:
		(chest_instance as Chest).global_position = spawn_pos
		(chest_instance as Chest).chest_opened.connect(_on_chest_opened)
		chests_container.add_child(chest_instance)


func _on_chest_opened(loot: Dictionary) -> void:
	var gold: int = loot.get("gold", 25)
	var xp: int = loot.get("xp", 35)

	hud.add_gold(gold)
	leveling_manager.add_xp(xp)


func _on_mob_spawned(enemy: EnemyBase) -> void:
	enemy.enemy_defeated.connect(_on_enemy_defeated)
	if enemy.health_component != null:
		enemy.health_component.damage_taken.connect(func(_amt: float, _src: Node2D):
			if audio_manager != null:
				audio_manager.play_hit()
		)


func _on_enemy_defeated(xp_val: float) -> void:
	hud.add_kill()
	leveling_manager.add_xp(xp_val)


func _unhandled_input(event: InputEvent) -> void:
	# Atajo de depuración: Tecla [L] para subir de nivel rápidamente y probar la evolución
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_L:
			leveling_manager.add_xp(leveling_manager.required_xp)
