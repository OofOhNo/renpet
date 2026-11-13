extends ModalOverlay
class_name StoryEventOverlay

## Escenas clave de la Historia Principal — Actos I, II, III y El Gran Giro del Año 17 (Fase 8).

signal story_resolved(act_id: int)

var _act_id: int = 0

func show_story_event(ev: Dictionary) -> void:
	if not bool(ev.get("has_event", false)):
		return
	_act_id = int(ev.get("act_id", 0))
	var is_twist: bool = bool(ev.get("is_twist", false))
	if is_twist:
		AstralAudio.play_twist()
	else:
		AstralAudio.play_confirm()
	var title: String = str(ev.get("title", "Evento de Historia"))
	var body_txt: String = str(ev.get("body", ""))
	var choices: Array = ev.get("choices", [])

	set_panel_width(980)
	rebuild(func() -> void:
		var ban_path: String = "res://assets/art/bg_zone_crater.png" if is_twist else "res://assets/art/bg_manor_observatory.png"
		content.add_child(AstralTheme.scenic_banner(ban_path, 112.0, Color(1, 1, 1, 0.92)))
		var head := AstralTheme.hbox(14)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/ui/seal_medallion_cracked.png" if is_twist else "res://assets/ui/seal_medallion_intact.png")
		icon.custom_minimum_size = Vector2(78, 78)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(icon)

		var hv := AstralTheme.vbox(3)
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(hv)

		var sub_txt: String = "%s  REVELACIÓN DEL FIRMAMENTO  ·  AÑO %d" % [AstralTheme.G_ANKH, TimeManager.current_year] if is_twist else "%s  CRÓNICA DE LA ESTRELLA  ·  EDAD %d" % [AstralTheme.G_STAR, GameState.age]
		var sub_col: Color = AstralTheme.ROSE if is_twist else AstralTheme.TURQ
		hv.add_child(AstralTheme.label(sub_txt, "CaptionLabel", sub_col))
		hv.add_child(AstralTheme.label(title, "HeadingLabel", AstralTheme.GOLD, true))
		content.add_child(head)

		content.add_child(AstralTheme.separator())
		var nar := AstralTheme.rich("[font_size=21]%s[/font_size]" % body_txt, 140)
		content.add_child(nar)

		var head_row := HBoxContainer.new()
		head_row.add_theme_constant_override("separation", 12)
		head_row.add_child(AstralTheme.icon_box("res://assets/art/father_portrait.png", Vector2(58, 70), Color.WHITE, "CardPanel"))
		head_row.add_child(AstralTheme.icon_box(GameState.get_active_portrait_path(), Vector2(58, 70), Color.WHITE, "GlowPanel"))
		var prompt_lbl := AstralTheme.label("Tu respuesta ante el destino:", "SubLabel", AstralTheme.GOLD_PALE)
		prompt_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head_row.add_child(prompt_lbl)
		content.add_child(head_row)

		for ch in choices:
			var d: Dictionary = ch
			var lbl_txt: String = str(d.get("label", "Decidir"))
			var req_s: String = str(d.get("req_stat", ""))
			var vname: String = "PrimaryButton" if (is_twist or bool(d.get("is_ng_echo", false))) else ""
			var b := AstralTheme.button("", vname)
			b.custom_minimum_size.y = 64
			var mg := MarginContainer.new()
			mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			mg.add_theme_constant_override("margin_left", 14)
			mg.add_theme_constant_override("margin_right", 14)
			mg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(mg)
			var ch_h := AstralTheme.hbox(10)
			ch_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mg.add_child(ch_h)
			var main_lbl := AstralTheme.label(lbl_txt, "", AstralTheme.IVORY, true)
			main_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			main_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			main_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ch_h.add_child(main_lbl)
			if req_s != "":
				var req_v: int = int(d.get("req_val", 0))
				var cur_v: int = GameState.get_stat(req_s)
				var sname: String = GameState.get_stat_label(req_s)
				var ok: bool = cur_v >= req_v
				var tag_t: String = "%s %s %d/%d" % [AstralTheme.G_CHECK if ok else AstralTheme.G_CROSS, sname, cur_v, req_v]
				var badge := AstralTheme.chip(tag_t, AstralTheme.GOOD if ok else AstralTheme.EMBER, null, 13)
				badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
				ch_h.add_child(badge)
			b.pressed.connect(func() -> void: _on_choose(d, title, is_twist))
			content.add_child(b))
	show_overlay()

func _on_choose(choice: Dictionary, title: String, is_twist: bool) -> void:
	var req_s: String = str(choice.get("req_stat", ""))
	var req_v: int = int(choice.get("req_val", 0))
	var had_check: bool = req_s != ""
	var passed: bool = true if not had_check else (GameState.get_stat(req_s) >= req_v)
	var summary_effects: String = ExplorationCombat.apply_story_event_choice(_act_id, choice)
	var outcome: String = str(choice.get("outcome", "")) if passed else str(choice.get("outcome_fail", choice.get("outcome", "")))

	rebuild(func() -> void:
		content.add_child(AstralTheme.label(title, "HeadingLabel", AstralTheme.ROSE if is_twist else AstralTheme.GOLD, true))
		content.add_child(AstralTheme.separator())
		if had_check:
			var chk_txt: String = ("✓ PRUEBA DE %s SUPERADA" % GameState.get_stat_label(req_s).to_upper()) if passed else ("✕ PRUEBA DE %s FALLIDA" % GameState.get_stat_label(req_s).to_upper())
			content.add_child(AstralTheme.label(chk_txt, "SubLabel", AstralTheme.GOOD if passed else AstralTheme.EMBER, true))
		content.add_child(AstralTheme.rich("[font_size=21]%s[/font_size]" % outcome, 90))
		if summary_effects != "":
			content.add_child(AstralTheme.label("Consecuencias: %s" % summary_effects, "SubLabel", AstralTheme.GOOD if passed else AstralTheme.EMBER, true))
		var b := AstralTheme.button("Continuar  ▶", "PrimaryButton")
		b.custom_minimum_size.y = 54
		b.pressed.connect(func() -> void:
			hide_overlay()
			story_resolved.emit(_act_id))
		content.add_child(b))
