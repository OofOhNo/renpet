extends ModalOverlay
class_name CombatOverlay

## CombatOverlay - Combate Táctico por Cartas de la Fase 7.
## Incluye Quiebre de Guardia (Stagger), Puntos de Acción (PA), Técnica de Compañero,
## Rebobinado Temporal y el botón tentador "Entreabrir el Sello".

signal expedition_ended(victory: bool, summary: String)

var _zone_lbl: Label
var _enemy_card: PanelContainer
var _player_card: PanelContainer
var _enemy_icon: TextureRect
var _enemy_name_lbl: Label
var _enemy_title_lbl: Label
var _enemy_hp_bar: ProgressBar
var _enemy_hp_lbl: Label
var _enemy_stagger_bar: ProgressBar
var _enemy_stagger_lbl: Label
var _enemy_intent_lbl: Label

var _player_head_lbl: Label
var _player_hp_bar: ProgressBar
var _player_hp_lbl: Label
var _player_shield_lbl: Label
var _player_ap_lbl: Label
var _player_seal_lbl: Label
var _player_buffs_lbl: Label

var _log_rich: RichTextLabel
var _cards_box: Control
var _finish_box: Control
var _finish_lbl: RichTextLabel

var _card_buttons: Dictionary = {}
var _unseal_btn: Button
var _fx_layer: Control
var _last_enemy_hp: int = -1
var _last_enemy_stagger: int = -1
var _last_player_hp: int = -1
var _last_player_shield: int = -1
var _was_staggered: bool = false
var _pending_victory: bool = false
var _pending_summary: String = ""

func _ready() -> void:
	set_panel_width(980)
	_max_height_ratio = 0.88
	super._ready()
	_build_ui()
	_fx_layer = Control.new()
	_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx_layer)
	ExplorationCombat.combat_updated.connect(_refresh_combat)
	ExplorationCombat.combat_fx.connect(_on_combat_fx)
	ExplorationCombat.combat_finished.connect(_on_combat_finished)

func open_combat() -> void:
	if _fx_layer != null:
		for c in _fx_layer.get_children():
			c.queue_free()
	_last_enemy_hp = -1
	_last_enemy_stagger = -1
	_last_player_hp = -1
	_last_player_shield = -1
	_was_staggered = false
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
	_enemy_card = PanelContainer.new()
	_enemy_card.theme_type_variation = "CardPanel"
	_enemy_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(_enemy_card)
	var eh := AstralTheme.hbox(14)
	_enemy_card.add_child(eh)
	_enemy_icon = TextureRect.new()
	_enemy_icon.custom_minimum_size = Vector2(92, 92)
	_enemy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_enemy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	eh.add_child(_enemy_icon)
	var ev := AstralTheme.vbox(5)
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
	_enemy_intent_lbl = AstralTheme.label("", "CaptionLabel", AstralTheme.EMBER, true)
	ev.add_child(_enemy_intent_lbl)

	# Tarjeta Renpet
	_player_card = PanelContainer.new()
	_player_card.theme_type_variation = "CardPanel"
	_player_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(_player_card)
	var pv := AstralTheme.vbox(5)
	_player_card.add_child(pv)
	_player_head_lbl = AstralTheme.label("%s  ESTADO DE RENPET Y EQUIPO" % AstralTheme.G_ANKH, "HeadingLabel", AstralTheme.TURQ)
	pv.add_child(_player_head_lbl)
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
	_player_buffs_lbl = AstralTheme.label("", "CaptionLabel", AstralTheme.GOOD, true)
	pv.add_child(_player_buffs_lbl)

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
		["solar_slash", "%s Tajo de Horus (1 PA)" % AstralTheme.G_SWORD, "Daño físico y +18 Quiebre", "", AstralTheme.GOLD],
		["lotus_guard", "%s Égida de Loto (1 PA)" % AstralTheme.G_FLOWER, "+Escudo Astral y curación leve", "", AstralTheme.GOOD],
		["starlight_ray", "%s Cometa de Sothis (2 PA)" % AstralTheme.G_STAR, "Gran daño astral y +32 Quiebre", "", AstralTheme.TURQ],
		["chrono_flux", "%s Pulso de Relojería (1 PA)" % AstralTheme.G_HOURGLASS, "Daño temporal +25 Escudo", "", AstralTheme.AMETHYST],
		["companion_skill", "%s Técnica de Aliado (1 PA)" % AstralTheme.G_HEART, "Habilidad única del compañero", "", AstralTheme.ROSE],
		["rewind", "%s Rebobinado Temporal (0 PA)" % AstralTheme.G_MOON, "Restaura 40% HP, +40 Escudo y +2 PA", "", AstralTheme.SKY]
	]
	for cd in card_defs:
		var b := AstralTheme.button("%s\n%s" % [cd[1], cd[2]], str(cd[3]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 60
		_style_combat_card(b, cd[4])
		b.pressed.connect(_on_card_pressed.bind(str(cd[0])))
		grid.add_child(b)
		_card_buttons[str(cd[0])] = b

	# Fila inferior: Botón Tentador ("Entreabrir el Sello") + Terminar Turno + Retirada
	var action_row := AstralTheme.hbox(12)
	cards_root.add_child(action_row)

	_unseal_btn = AstralTheme.button(
		"%s  DESATAR EL FULGOR OCULTO (0 PA  |  Daño Masivo)" % AstralTheme.G_ANKH,
		"DangerButton",
		"Desata la fuerza dormida bajo su pecho: daño devastador, +35% HP y +2 PA, pero altera su armonía interior."
	)
	_unseal_btn.icon = load("res://assets/ui/icon_unseal_power.png")
	_unseal_btn.expand_icon = true
	_unseal_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_unseal_btn.custom_minimum_size.y = 54
	_unseal_btn.pressed.connect(_on_card_pressed.bind("unseal"))
	action_row.add_child(_unseal_btn)
	_card_buttons["unseal"] = _unseal_btn

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

	var first_paint: bool = (_last_enemy_hp < 0)
	var is_headless: bool = DisplayServer.get_name() == "headless"

	_enemy_hp_bar.max_value = maxi(1, ExplorationCombat.enemy_max_hp)
	_enemy_stagger_bar.max_value = maxi(1, ExplorationCombat.enemy_max_stagger)
	_player_hp_bar.max_value = maxi(1, ExplorationCombat.player_max_hp)

	if first_paint or is_headless:
		_enemy_hp_bar.value = ExplorationCombat.enemy_hp
		_enemy_stagger_bar.value = ExplorationCombat.enemy_stagger
		_player_hp_bar.value = ExplorationCombat.player_hp
	else:
		_tween_bar(_enemy_hp_bar, ExplorationCombat.enemy_hp)
		_tween_bar(_enemy_stagger_bar, ExplorationCombat.enemy_stagger)
		_tween_bar(_player_hp_bar, ExplorationCombat.player_hp)

		var d_ehp: int = ExplorationCombat.enemy_hp - _last_enemy_hp
		if d_ehp < 0:
			_spawn_float_badge(_enemy_card, "%d HP" % d_ehp, AstralTheme.GOLD if ExplorationCombat.enemy_staggered else AstralTheme.BAD, -6.0)
		if ExplorationCombat.enemy_staggered and not _was_staggered:
			_spawn_float_badge(_enemy_card, "%s ATURDIDO" % AstralTheme.G_STAR, AstralTheme.GOLD, -32.0)
		elif ExplorationCombat.enemy_stagger > _last_enemy_stagger:
			_spawn_float_badge(_enemy_card, "+%d Quiebre" % (ExplorationCombat.enemy_stagger - _last_enemy_stagger), AstralTheme.GOLD_PALE, 20.0)

		var d_php: int = ExplorationCombat.player_hp - _last_player_hp
		if d_php < 0:
			_spawn_float_badge(_player_card, "%d HP" % d_php, AstralTheme.BAD, -6.0)
		elif d_php > 0:
			_spawn_float_badge(_player_card, "+%d HP" % d_php, AstralTheme.GOOD, -6.0)
		var d_sh: int = ExplorationCombat.player_shield - _last_player_shield
		if d_sh > 0:
			_spawn_float_badge(_player_card, "+%d Escudo" % d_sh, AstralTheme.TURQ, 20.0)

	_last_enemy_hp = ExplorationCombat.enemy_hp
	_last_enemy_stagger = ExplorationCombat.enemy_stagger
	_last_player_hp = ExplorationCombat.player_hp
	_last_player_shield = ExplorationCombat.player_shield
	_was_staggered = ExplorationCombat.enemy_staggered

	_enemy_hp_lbl.text = "HP Enemigo: %d / %d   |   Ataque: %d" % [
		ExplorationCombat.enemy_hp, ExplorationCombat.enemy_max_hp, ExplorationCombat.enemy_atk
	]

	_enemy_stagger_lbl.text = "ATURDIDO (Daño x1.5 y pierde su turno)" if ExplorationCombat.enemy_staggered else (
		"Quiebre de Guardia: %d / %d" % [ExplorationCombat.enemy_stagger, ExplorationCombat.enemy_max_stagger]
	)
	if ExplorationCombat.enemy_staggered:
		_enemy_intent_lbl.text = "✦ Intención: ATURDIDO — ¡No atacará este turno (aprovecha Daño x1.5)!"
		_enemy_intent_lbl.add_theme_color_override("font_color", AstralTheme.GOOD)
	else:
		var pred_atk: int = maxi(1, int(round(ExplorationCombat.enemy_atk * 0.85))) if GameState.has_mutation("sangre_pesada") else ExplorationCombat.enemy_atk
		var absorbed: int = mini(ExplorationCombat.player_shield, pred_atk)
		var dmg_hp: int = pred_atk - absorbed
		_enemy_intent_lbl.text = "⚡ Intención: Atacará por %d daño (Escudo absorbe %d · recibirías %d HP)" % [pred_atk, absorbed, dmg_hp]
		_enemy_intent_lbl.add_theme_color_override("font_color", AstralTheme.BAD if dmg_hp > 0 else AstralTheme.TURQ)

	if _player_head_lbl != null:
		_player_head_lbl.text = "%s  ESTADO DE %s Y EQUIPO" % [AstralTheme.G_ANKH, GameState.daughter_name.to_upper()]
	_player_hp_lbl.text = "HP de %s: %d / %d" % [
		GameState.daughter_name, ExplorationCombat.player_hp, ExplorationCombat.player_max_hp
	]
	_player_shield_lbl.text = "Escudo Astral: %d" % ExplorationCombat.player_shield
	_player_ap_lbl.text = "PA: %d / %d   |   Rebobinados: %d" % [
		ExplorationCombat.player_ap, ExplorationCombat.player_max_ap, ExplorationCombat.rewind_charges
	]
	_player_seal_lbl.text = "%s %s: %d%%   |   %s: %d%%" % [
		AstralTheme.G_ANKH, GameState.get_stat_label("seal_integrity"), GameState.seal_integrity,
		GameState.get_stat_label("abyssal_sync"), GameState.abyssal_sync
	]
	if _player_buffs_lbl != null:
		var perks: Array[String] = []
		for mid in GameState.active_mutations:
			perks.append(str(CatalogDB.get_mutation(mid).get("name", mid)))
		_player_buffs_lbl.text = "Mutaciones activas: %s" % (", ".join(perks) if not perks.is_empty() else "Ninguna")
		_player_buffs_lbl.add_theme_color_override("font_color", AstralTheme.AMETHYST if not perks.is_empty() else AstralTheme.MUTED)

	_log_rich.text = "\n".join(ExplorationCombat.combat_log)

	# Actualizar disponibilidad y textos dinámicos de cartas según PA, cargas y nivel de secreto
	var ap: int = ExplorationCombat.player_ap
	for cid in ["solar_slash", "lotus_guard", "chrono_flux", "companion_skill"]:
		(_card_buttons[cid] as Button).disabled = (ap < 1)
	(_card_buttons["starlight_ray"] as Button).disabled = (ap < 2)
	(_card_buttons["rewind"] as Button).disabled = (ExplorationCombat.rewind_charges <= 0)
	(_card_buttons["companion_skill"] as Button).text = "%s Técnica de %s (1 PA)\nHabilidad única del compañero" % [
		AstralTheme.G_HEART, ExplorationCombat.companion_name
	]
	(_card_buttons["rewind"] as Button).text = "%s Rebobinado Temporal (0 PA · %d rest.)\nRestaura 40%% HP, +40 Escudo y +2 PA" % [
		AstralTheme.G_MOON, ExplorationCombat.rewind_charges
	]
	if _unseal_btn != null:
		var tier: int = GameState.get_secret_tier()
		_unseal_btn.text = "%s  ENTREABRIR EL SELLO (0 PA  |  Daño Masivo)" % AstralTheme.G_ANKH if tier >= 1 else "%s  DESATAR EL FULGOR OCULTO (0 PA  |  Daño Masivo)" % AstralTheme.G_ANKH
		_unseal_btn.tooltip_text = "Libera brevemente la energía de Nyx-Aethel: daño devastador, +35%% HP y +2 PA, a costa de la integridad del Sello." if tier >= 2 else (
			"Entreabre el Sello interior: daño devastador, +35%% HP y +2 PA, pero reduce el Sello Estelar y sube la Sincronía." if tier == 1 else
			"Desata la fuerza dormida bajo su pecho: daño devastador, +35%% HP y +2 PA, pero erosiona su Armonía Estelar."
		)
	_fit()

func _on_combat_fx(kind: String) -> void:
	AstralAudio.play_combat(kind)
	if not is_visible_in_tree():
		return
	if kind in ["slash", "magic", "stagger", "unseal"] and _enemy_card != null:
		var flash: Color = Color(1.4, 1.25, 0.7) if kind in ["stagger", "unseal"] else Color(1.35, 0.72, 0.72)
		_enemy_card.pivot_offset = _enemy_card.size * 0.5
		_enemy_card.scale = Vector2(1.03, 1.03)
		_enemy_card.modulate = flash
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_enemy_card, "modulate", Color.WHITE, 0.25)
		tw.tween_property(_enemy_card, "scale", Vector2.ONE, 0.20)
	elif kind in ["hit", "shield"] and _player_card != null:
		var flash_p: Color = Color(1.35, 0.68, 0.68) if kind == "hit" else Color(0.75, 1.25, 1.35)
		_player_card.pivot_offset = _player_card.size * 0.5
		_player_card.scale = Vector2(1.025, 1.025)
		_player_card.modulate = flash_p
		var tw2 := create_tween()
		tw2.set_parallel(true)
		tw2.tween_property(_player_card, "modulate", Color.WHITE, 0.25)
		tw2.tween_property(_player_card, "scale", Vector2.ONE, 0.20)

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
	if _fx_layer != null:
		for c in _fx_layer.get_children():
			c.queue_free()
	hide_overlay()
	expedition_ended.emit(_pending_victory, _pending_summary)

func _tween_bar(pb: ProgressBar, target_val: int) -> void:
	var tw := pb.create_tween()
	tw.tween_property(pb, "value", float(target_val), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _spawn_float_badge(card: PanelContainer, text: String, col: Color, y_bias: float) -> void:
	if card == null or _fx_layer == null or not card.is_visible_in_tree():
		return
	var l := AstralTheme.label(text, "HeadingLabel", col)
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.96))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.add_child(l)
	var base_pos: Vector2 = card.global_position + Vector2(card.size.x * 0.56, 18.0 + y_bias)
	l.global_position = base_pos
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position:y", base_pos.y - 38.0, 0.80).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.80).set_delay(0.18)
	tw.chain().tween_callback(l.queue_free)

func _style_combat_card(btn: Button, accent: Color) -> void:
	var norm := StyleBoxFlat.new()
	norm.bg_color = Color(0.06, 0.09, 0.19, 0.92)
	norm.border_color = Color(accent.r, accent.g, accent.b, 0.46)
	norm.border_width_left = 5
	norm.border_width_top = 1
	norm.border_width_right = 1
	norm.border_width_bottom = 2
	norm.set_corner_radius_all(8)
	norm.content_margin_left = 14
	norm.content_margin_right = 12
	norm.content_margin_top = 8
	norm.content_margin_bottom = 8
	var hov := norm.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.10, 0.15, 0.29, 0.98)
	hov.border_color = Color(accent.r, accent.g, accent.b, 0.96)
	hov.border_width_top = 2
	var dis := norm.duplicate() as StyleBoxFlat
	dis.bg_color = Color(0.04, 0.05, 0.11, 0.55)
	dis.border_color = Color(0.45, 0.48, 0.58, 0.22)
	btn.add_theme_stylebox_override("normal", norm)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", hov)
	btn.add_theme_stylebox_override("disabled", dis)
	btn.mouse_entered.connect(func() -> void:
		if btn.disabled or DisplayServer.get_name() == "headless":
			return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.025, 1.025), 0.10))
	btn.mouse_exited.connect(func() -> void:
		if DisplayServer.get_name() == "headless":
			return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.10))
