extends ModalOverlay
class_name CombatOverlay

## CombatOverlay - Combate Táctico por Cartas de la Fase 7.
## Incluye Quiebre de Guardia (Stagger), Puntos de Acción (PA), Técnica de Compañero,
## Rebobinado Temporal y el botón tentador "Entreabrir el Sello".

signal expedition_ended(victory: bool, summary: String)

var _zone_lbl: Label
var _enemy_icon: TextureRect
var _enemy_name_lbl: Label
var _enemy_title_lbl: Label
var _enemy_hp_bar: ProgressBar
var _enemy_hp_lbl: Label
var _enemy_stagger_bar: ProgressBar
var _enemy_stagger_lbl: Label

var _player_hp_bar: ProgressBar
var _player_hp_lbl: Label
var _player_shield_lbl: Label
var _player_ap_lbl: Label
var _player_seal_lbl: Label

var _log_rich: RichTextLabel
var _cards_box: Control
var _finish_box: Control
var _finish_lbl: RichTextLabel

var _card_buttons: Dictionary = {}
var _pending_victory: bool = false
var _pending_summary: String = ""

func _ready() -> void:
	set_panel_width(980)
	_max_height_ratio = 0.88
	super._ready()
	_build_ui()
	ExplorationCombat.combat_updated.connect(_refresh_combat)
	ExplorationCombat.combat_finished.connect(_on_combat_finished)

func open_combat() -> void:
	_cards_box.visible = true
	_finish_box.visible = false
	_refresh_combat()
	show_overlay()

func _build_ui() -> void:
	_zone_lbl = AstralTheme.label("", "HeadingLabel", AstralTheme.GOLD)
	_zone_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_zone_lbl)

	# --- ARENA SUPERIOR: ENEMIGO vs RENPET ---
	var arena := AstralTheme.hbox(16)
	content.add_child(arena)

	# Tarjeta Enemigo
	var e_card := PanelContainer.new()
	e_card.theme_type_variation = "CardPanel"
	e_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(e_card)
	var eh := AstralTheme.hbox(14)
	e_card.add_child(eh)
	_enemy_icon = TextureRect.new()
	_enemy_icon.custom_minimum_size = Vector2(92, 92)
	_enemy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_enemy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	eh.add_child(_enemy_icon)
	var ev := AstralTheme.vbox(6)
	ev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eh.add_child(ev)
	_enemy_name_lbl = AstralTheme.label("", "HeadingLabel", AstralTheme.BAD)
	ev.add_child(_enemy_name_lbl)
	_enemy_title_lbl = AstralTheme.label("", "CaptionLabel", AstralTheme.MUTED)
	ev.add_child(_enemy_title_lbl)
	_enemy_hp_bar = _make_bar(AstralTheme.BAD)
	ev.add_child(_enemy_hp_bar)
	_enemy_hp_lbl = AstralTheme.label("", "CaptionLabel", AstralTheme.IVORY)
	ev.add_child(_enemy_hp_lbl)
	_enemy_stagger_bar = _make_bar(AstralTheme.GOLD)
	ev.add_child(_enemy_stagger_bar)
	_enemy_stagger_lbl = AstralTheme.label("", "CaptionLabel", AstralTheme.GOLD_PALE)
	ev.add_child(_enemy_stagger_lbl)

	# Tarjeta Renpet
	var p_card := PanelContainer.new()
	p_card.theme_type_variation = "CardPanel"
	p_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(p_card)
	var pv := AstralTheme.vbox(6)
	p_card.add_child(pv)
	pv.add_child(AstralTheme.label("%s  ESTADO DE RENPET Y EQUIPO" % AstralTheme.G_ANKH, "HeadingLabel", AstralTheme.TURQ))
	_player_hp_bar = _make_bar(AstralTheme.GOOD)
	pv.add_child(_player_hp_bar)
	_player_hp_lbl = AstralTheme.label("", "CaptionLabel", AstralTheme.IVORY)
	pv.add_child(_player_hp_lbl)

	var stats_h := AstralTheme.hbox(14)
	pv.add_child(stats_h)
	_player_shield_lbl = AstralTheme.label("", "SubLabel", AstralTheme.SKY)
	stats_h.add_child(_player_shield_lbl)
	_player_ap_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD_PALE)
	stats_h.add_child(_player_ap_lbl)

	_player_seal_lbl = AstralTheme.label("", "CaptionLabel", AstralTheme.AMETHYST)
	pv.add_child(_player_seal_lbl)

	# --- BITÁCORA DE COMBATE ---
	var log_panel := PanelContainer.new()
	log_panel.theme_type_variation = "BarPanel"
	content.add_child(log_panel)
	_log_rich = AstralTheme.rich("")
	_log_rich.custom_minimum_size = Vector2(0, 140)
	_log_rich.scroll_following = true
	log_panel.add_child(_log_rich)

	# --- MANO DE CARTAS TÁCTICAS ---
	var cards_root := AstralTheme.vbox(10)
	_cards_box = cards_root
	content.add_child(cards_root)

	cards_root.add_child(AstralTheme.label("MANO TÁCTICA DEL ASTROLABIO:", "SubLabel", AstralTheme.GOLD_PALE))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	cards_root.add_child(grid)

	var card_defs: Array[Array] = [
		["solar_slash", "%s Tajo de Horus (1 PA)" % AstralTheme.G_SWORD, "Daño físico y +18 Quiebre", ""],
		["lotus_guard", "%s Égida de Loto (1 PA)" % AstralTheme.G_FLOWER, "+Escudo Astral y curación leve", ""],
		["starlight_ray", "%s Cometa de Sothis (2 PA)" % AstralTheme.G_STAR, "Gran daño astral y +32 Quiebre", ""],
		["chrono_flux", "%s Pulso de Relojería (1 PA)" % AstralTheme.G_HOURGLASS, "Daño temporal +25 Escudo", ""],
		["companion_skill", "%s Técnica de Aliado (1 PA)" % AstralTheme.G_HEART, "Habilidad única del compañero", ""],
		["rewind", "%s Rebobinado Temporal (0 PA)" % AstralTheme.G_MOON, "Restaura 40% HP, +40 Escudo y +2 PA", ""]
	]
	for cd in card_defs:
		var b := AstralTheme.button("%s\n%s" % [cd[1], cd[2]], str(cd[3]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 58
		b.pressed.connect(_on_card_pressed.bind(str(cd[0])))
		grid.add_child(b)
		_card_buttons[str(cd[0])] = b

	# Fila inferior: Botón Tentador ("Entreabrir el Sello") + Terminar Turno + Retirada
	var action_row := AstralTheme.hbox(12)
	cards_root.add_child(action_row)

	var unseal_btn := AstralTheme.button(
		"%s  ENTREABRIR EL SELLO (0 PA  |  -Sello, +Nyx-Aethel, Daño Masivo)" % AstralTheme.G_ANKH,
		"DangerButton",
		"Libera el poder prohibido de Nyx-Aethel: daño devastador, +35% HP y +2 PA, pero erosiona el Sello Estelar."
	)
	unseal_btn.icon = load("res://assets/ui/icon_unseal_power.png")
	unseal_btn.expand_icon = true
	unseal_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unseal_btn.custom_minimum_size.y = 54
	unseal_btn.pressed.connect(_on_card_pressed.bind("unseal"))
	action_row.add_child(unseal_btn)
	_card_buttons["unseal"] = unseal_btn

	var end_btn := AstralTheme.button("%s  Terminar Turno" % AstralTheme.G_BOLT, "PrimaryButton")
	end_btn.custom_minimum_size = Vector2(180, 54)
	end_btn.pressed.connect(_on_end_turn_pressed)
	action_row.add_child(end_btn)

	var retreat_btn := AstralTheme.button("Retirarse", "TabLikeButton", "Abandona la expedición de forma segura (+8 Estrés).")
	retreat_btn.custom_minimum_size = Vector2(120, 54)
	retreat_btn.pressed.connect(_on_retreat_pressed)
	action_row.add_child(retreat_btn)

	# --- PANEL DE RESULTADO FINAL ---
	var fin_v := AstralTheme.vbox(12)
	fin_v.visible = false
	_finish_box = fin_v
	content.add_child(fin_v)

	_finish_lbl = AstralTheme.rich("")
	_finish_lbl.custom_minimum_size = Vector2(0, 90)
	fin_v.add_child(_finish_lbl)

	var ok_btn := AstralTheme.button("%s  Volver al Observatorio" % AstralTheme.G_STAR, "PrimaryButton")
	ok_btn.custom_minimum_size = Vector2(260, 48)
	ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok_btn.pressed.connect(_on_close_after_finish)
	fin_v.add_child(ok_btn)

func _make_bar(col: Color) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size.y = 14
	var sbf := StyleBoxFlat.new()
	sbf.bg_color = col
	sbf.set_corner_radius_all(5)
	pb.add_theme_stylebox_override("fill", sbf)
	return pb

func _refresh_combat() -> void:
	if not is_inside_tree():
		return
	var z: Dictionary = ExplorationCombat.current_zone
	_zone_lbl.text = "%s  %s  (Compañero: %s)" % [
		AstralTheme.G_SWORD, str(z.get("name", "Expedición")), ExplorationCombat.companion_name
	]

	if ExplorationCombat.enemy_icon != "" and ResourceLoader.exists(ExplorationCombat.enemy_icon):
		_enemy_icon.texture = load(ExplorationCombat.enemy_icon)
	_enemy_name_lbl.text = ExplorationCombat.enemy_name
	_enemy_title_lbl.text = ExplorationCombat.enemy_title

	_enemy_hp_bar.max_value = maxi(1, ExplorationCombat.enemy_max_hp)
	_enemy_hp_bar.value = ExplorationCombat.enemy_hp
	_enemy_hp_lbl.text = "HP Enemigo: %d / %d   |   Ataque: %d" % [
		ExplorationCombat.enemy_hp, ExplorationCombat.enemy_max_hp, ExplorationCombat.enemy_atk
	]

	_enemy_stagger_bar.max_value = maxi(1, ExplorationCombat.enemy_max_stagger)
	_enemy_stagger_bar.value = ExplorationCombat.enemy_stagger
	_enemy_stagger_lbl.text = "ATURDIDO (Daño x1.5 y pierde su turno)" if ExplorationCombat.enemy_staggered else (
		"Quiebre de Guardia: %d / %d" % [ExplorationCombat.enemy_stagger, ExplorationCombat.enemy_max_stagger]
	)

	_player_hp_bar.max_value = maxi(1, ExplorationCombat.player_max_hp)
	_player_hp_bar.value = ExplorationCombat.player_hp
	_player_hp_lbl.text = "HP de %s: %d / %d" % [
		GameState.daughter_name, ExplorationCombat.player_hp, ExplorationCombat.player_max_hp
	]
	_player_shield_lbl.text = "Escudo Astral: %d" % ExplorationCombat.player_shield
	_player_ap_lbl.text = "PA: %d / %d   |   Rebobinados: %d" % [
		ExplorationCombat.player_ap, ExplorationCombat.player_max_ap, ExplorationCombat.rewind_charges
	]
	_player_seal_lbl.text = "%s Sello Estelar: %d%%   |   Sincronía Zephyr: %d%%" % [
		AstralTheme.G_ANKH, GameState.seal_integrity, GameState.abyssal_sync
	]

	_log_rich.text = "\n".join(ExplorationCombat.combat_log)

	# Actualizar disponibilidad de cartas según PA y cargas
	var ap: int = ExplorationCombat.player_ap
	for cid in ["solar_slash", "lotus_guard", "chrono_flux", "companion_skill"]:
		(_card_buttons[cid] as Button).disabled = (ap < 1)
	(_card_buttons["starlight_ray"] as Button).disabled = (ap < 2)
	(_card_buttons["rewind"] as Button).disabled = (ExplorationCombat.rewind_charges <= 0)
	_fit()

func _on_card_pressed(card_id: String) -> void:
	ExplorationCombat.play_combat_card(card_id)

func _on_end_turn_pressed() -> void:
	ExplorationCombat.end_player_turn()

func _on_retreat_pressed() -> void:
	ExplorationCombat.retreat_from_combat()

func _on_combat_finished(victory: bool, summary: String) -> void:
	_pending_victory = victory
	_pending_summary = summary
	_cards_box.visible = false
	_finish_box.visible = true
	var col: String = "#86e3a6" if victory else "#ff7f7f"
	_finish_lbl.text = "[color=%s][b]%s[/b][/color]\n\n%s" % [
		col,
		"✦ EXPEDICIÓN COMPLETADA CON ÉXITO ✦" if victory else "✕ RETIRADA DE LA EXPEDICIÓN",
		summary
	]
	_log_rich.text = "\n".join(ExplorationCombat.combat_log)
	_fit()

func _on_close_after_finish() -> void:
	hide_overlay()
	expedition_ended.emit(_pending_victory, _pending_summary)
