class_name HUDController
extends CanvasLayer

signal click_button_pressed
signal class_selected(class_data: ClassData)
signal subclass_selected(subclass_data: SubclassData)

@onready var class_badge: Label = $TopBar/MarginContainer/HBoxContainer/ClassBadge
@onready var level_label: Label = $TopBar/MarginContainer/HBoxContainer/LevelLabel
@onready var xp_bar: ProgressBar = $TopBar/MarginContainer/HBoxContainer/XPBar
@onready var stats_label: Label = $TopBar/MarginContainer/HBoxContainer/StatsLabel
@onready var click_button: Button = $ClickButton

@onready var class_modal: Control = $ClassModal
@onready var classes_container: HBoxContainer = $ClassModal/CenterContainer/VBoxContainer/ClassesContainer

@onready var draft_modal: Control = $DraftModal
@onready var cards_container: HBoxContainer = $DraftModal/CenterContainer/VBoxContainer/CardsContainer

@onready var evolution_modal: Control = $EvolutionModal
@onready var evolution_container: HBoxContainer = $EvolutionModal/CenterContainer/VBoxContainer/EvolutionContainer

var _leveling_manager: LevelingManager = null
var _player: PlayerCharacter = null
var _audio_manager: AudioManager = null
var _total_gold: int = 0
var _total_kills: int = 0
var _consecutive_clicks: int = 0


var _click_tween: Tween = null


func _ready() -> void:
	class_modal.visible = false
	draft_modal.visible = false
	evolution_modal.visible = false
	click_button.pressed.connect(_on_click_button_pressed)


func initialize(click_mgr: ClickManager, level_mgr: LevelingManager, player: PlayerCharacter, audio_mgr: AudioManager = null) -> void:
	_leveling_manager = level_mgr
	_player = player
	_audio_manager = audio_mgr

	if click_mgr != null:
		click_mgr.click_processed.connect(_on_click_processed)

	if level_mgr != null:
		level_mgr.xp_gained.connect(_on_xp_gained)
		level_mgr.level_up.connect(_on_level_up)
		level_mgr.draft_opened.connect(_on_draft_opened)
		level_mgr.draft_closed.connect(_on_draft_closed)
		level_mgr.evolution_opened.connect(_on_evolution_opened)
		level_mgr.evolution_closed.connect(_on_evolution_closed)
		_update_xp_display(level_mgr.current_xp, level_mgr.required_xp)
		level_label.text = "NIVEL %d" % level_mgr.current_level


func show_class_selection(classes: Array[ClassData]) -> void:
	get_tree().paused = true
	class_modal.visible = true

	for child in classes_container.get_children():
		child.queue_free()

	for cls in classes:
		var card: PanelContainer = _create_class_card_ui(cls)
		classes_container.add_child(card)


func _create_class_card_ui(cls: ClassData) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 380)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.96)
	style.border_color = cls.primary_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(cls.primary_color.r, cls.primary_color.g, cls.primary_color.b, 0.28)
	style.shadow_size = 8
	panel.add_theme_stylebox_override(&"panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 18)
	margin.add_theme_constant_override(&"margin_top", 18)
	margin.add_theme_constant_override(&"margin_right", 18)
	margin.add_theme_constant_override(&"margin_bottom", 18)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 12)
	margin.add_child(vbox)

	# Título de clase con color
	var title: Label = Label.new()
	title.text = cls.class_name_str.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override(&"font_color", cls.primary_color)
	title.add_theme_font_size_override(&"font_size", 22)
	vbox.add_child(title)

	# Descripción de rol
	var desc: Label = Label.new()
	desc.text = cls.role_description
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override(&"font_size", 14)
	vbox.add_child(desc)

	# Stats clave y estilo de arma
	var attack_type_str: String = ""
	match cls.class_id:
		&"warrior": attack_type_str = "⚔ Tajo Melee (Cleave 120°)"
		&"mage": attack_type_str = "✦ Orbe Arcano (AoE %dpx)" % int(cls.projectile_aoe_radius)
		&"archer": attack_type_str = "🏹 Flecha Perforante (Pierce %d)" % cls.projectile_pierce

	var stats: Label = Label.new()
	stats.text = "%s\nHP: %d | Poder: %d | Cad: %.2fs\nRango: %d px | Vel: %d px/s" % [
		attack_type_str,
		int(cls.base_health), int(cls.base_attack_power), cls.base_cooldown,
		int(cls.base_range), int(cls.base_move_speed)
	]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_color_override(&"font_color", Color(0.85, 0.9, 0.95))
	stats.add_theme_font_size_override(&"font_size", 13)
	vbox.add_child(stats)

	var btn: Button = Button.new()
	btn.text = "SELECCIONAR"
	btn.custom_minimum_size = Vector2(0, 46)
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(cls.primary_color.r * 0.25, cls.primary_color.g * 0.25, cls.primary_color.b * 0.25, 0.9)
	btn_style.border_color = cls.primary_color
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override(&"normal", btn_style)
	btn.pressed.connect(func(): _select_class(cls))
	vbox.add_child(btn)

	return panel


func _select_class(cls: ClassData) -> void:
	class_modal.visible = false
	get_tree().paused = false
	class_badge.text = "[%s]" % cls.class_name_str.to_upper()
	class_badge.add_theme_color_override(&"font_color", cls.primary_color)

	if _audio_manager != null:
		_audio_manager.play_level_up()

	class_selected.emit(cls)


func _on_evolution_opened(subclasses: Array[SubclassData]) -> void:
	get_tree().paused = true
	evolution_modal.visible = true

	if _audio_manager != null:
		_audio_manager.play_evolution()

	for child in evolution_container.get_children():
		child.queue_free()

	for sub in subclasses:
		var card: PanelContainer = _create_subclass_card_ui(sub)
		evolution_container.add_child(card)


func _create_subclass_card_ui(sub: SubclassData) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 420)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.05, 0.14, 0.96)
	style.border_color = sub.tint_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(sub.tint_color.r, sub.tint_color.g, sub.tint_color.b, 0.35)
	style.shadow_size = 12
	panel.add_theme_stylebox_override(&"panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 22)
	margin.add_theme_constant_override(&"margin_top", 22)
	margin.add_theme_constant_override(&"margin_right", 22)
	margin.add_theme_constant_override(&"margin_bottom", 22)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 14)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = sub.title.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override(&"font_color", sub.tint_color)
	title.add_theme_font_size_override(&"font_size", 22)
	vbox.add_child(title)

	var desc: Label = Label.new()
	desc.text = sub.description
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override(&"font_size", 14)
	vbox.add_child(desc)

	# Desglose numérico claro
	var stats_box: Label = Label.new()
	stats_box.text = "Modificadores:\nHP: %+d | Daño: %+d\nCadencia: %+.2fs | Rango: %+d px" % [
		int(sub.delta_max_health), int(sub.delta_attack_power),
		sub.delta_cooldown, int(sub.delta_range)
	]
	stats_box.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_box.add_theme_color_override(&"font_color", Color(0.85, 0.92, 0.95))
	stats_box.add_theme_font_size_override(&"font_size", 13)
	vbox.add_child(stats_box)

	var trait_lbl: Label = Label.new()
	trait_lbl.text = "✦ Rasgo Exclusivo:\n" + sub.trait_description
	trait_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trait_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	trait_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	trait_lbl.add_theme_color_override(&"font_color", Color(1.0, 0.9, 0.5))
	trait_lbl.add_theme_font_size_override(&"font_size", 13)
	vbox.add_child(trait_lbl)

	var btn: Button = Button.new()
	btn.text = "EVOLUCIONAR AHORA"
	btn.custom_minimum_size = Vector2(0, 50)
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(sub.tint_color.r * 0.35, sub.tint_color.g * 0.35, sub.tint_color.b * 0.35, 0.95)
	btn_style.border_color = sub.tint_color
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override(&"normal", btn_style)
	btn.pressed.connect(func(): _select_subclass(sub))
	vbox.add_child(btn)

	return panel


func _select_subclass(sub: SubclassData) -> void:
	if _leveling_manager != null and _player != null:
		_leveling_manager.select_subclass(sub, _player)

	var base_name: String = _player.current_class.class_name_str if _player.current_class != null else "HEROE"
	class_badge.text = "[%s → %s]" % [base_name.to_upper(), sub.title.to_upper()]
	class_badge.add_theme_color_override(&"font_color", sub.tint_color)

	if _audio_manager != null:
		_audio_manager.play_evolution()

	subclass_selected.emit(sub)


func _on_evolution_closed() -> void:
	evolution_modal.visible = false
	get_tree().paused = false
	if _player != null:
		_player.resume_combat()


func _on_click_button_pressed() -> void:
	_consecutive_clicks += 1
	var pitch: float = minf(1.6, 1.0 + float(_consecutive_clicks % 10) * 0.05)

	if _audio_manager != null:
		_audio_manager.play_click(pitch)

	if _click_tween and _click_tween.is_valid():
		_click_tween.kill()
	click_button.scale = Vector2.ONE

	_click_tween = create_tween()
	_click_tween.tween_property(click_button, "scale", Vector2(0.92, 0.92), 0.05).set_trans(Tween.TRANS_QUAD)
	_click_tween.tween_property(click_button, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	click_button_pressed.emit()


func _on_click_processed(_xp: float) -> void:
	_update_stats_display()


func _on_xp_gained(_amount: float, cur_xp: float, req_xp: float) -> void:
	_update_xp_display(cur_xp, req_xp)


func _on_level_up(new_lvl: int) -> void:
	level_label.text = "NIVEL %d" % new_lvl
	if _audio_manager != null:
		_audio_manager.play_level_up()


func _update_xp_display(cur_xp: float, req_xp: float) -> void:
	xp_bar.max_value = req_xp
	xp_bar.value = cur_xp


func add_gold(amount: int) -> void:
	_total_gold += amount
	_update_stats_display()
	if _audio_manager != null:
		_audio_manager.play_chest()


func add_kill() -> void:
	_total_kills += 1
	_update_stats_display()
	if _audio_manager != null:
		_audio_manager.play_death()


func _update_stats_display() -> void:
	stats_label.text = "ORO: %d | KILLS: %d" % [_total_gold, _total_kills]


func _on_draft_opened(cards: Array[SkillCardData]) -> void:
	get_tree().paused = true
	draft_modal.visible = true

	if _audio_manager != null:
		_audio_manager.play_level_up()

	for child in cards_container.get_children():
		child.queue_free()

	for card in cards:
		var card_panel: PanelContainer = _create_card_ui(card)
		cards_container.add_child(card_panel)


func _create_card_ui(card: SkillCardData) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 300)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 16)
	margin.add_theme_constant_override(&"margin_top", 16)
	margin.add_theme_constant_override(&"margin_right", 16)
	margin.add_theme_constant_override(&"margin_bottom", 16)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 14)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = card.title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_color_override(&"font_color", Color(1.0, 0.722, 0.0))
	title.add_theme_font_size_override(&"font_size", 18)
	vbox.add_child(title)

	var desc: Label = Label.new()
	desc.text = card.description
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override(&"font_size", 14)
	vbox.add_child(desc)

	var btn: Button = Button.new()
	btn.text = "ELEGIR"
	btn.custom_minimum_size = Vector2(0, 48)
	btn.pressed.connect(func(): _select_card(card))
	vbox.add_child(btn)

	return panel


func _select_card(card: SkillCardData) -> void:
	if _leveling_manager != null and _player != null:
		_leveling_manager.select_card(card, _player)


func _on_draft_closed() -> void:
	draft_modal.visible = false
	get_tree().paused = false
	if _player != null:
		_player.resume_combat()
