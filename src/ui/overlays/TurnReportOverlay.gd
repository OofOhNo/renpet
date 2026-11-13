extends ModalOverlay
class_name TurnReportOverlay

## Informe de resolución del bimestre (Fase 4.2): qué pasó en cada decano, eventos, choques, mantenimiento y balance.

func show_report(report: Dictionary) -> void:
	set_panel_width(1040)
	rebuild(func() -> void:
		content.add_child(AstralTheme.label("%s  INFORME: %s  %s" % [AstralTheme.G_STAR, str(report["bimester_name"]).to_upper(), AstralTheme.G_STAR], "HeadingLabel", AstralTheme.GOLD, true))
		content.add_child(AstralTheme.label("Año %d · Turno %d de %d" % [int(report["year"]), int(report["turn"]), TimeManager.TOTAL_TURNS], "CaptionLabel", AstralTheme.MUTED))
		content.add_child(AstralTheme.separator())

		var father: Array = report["father"]
		if not father.is_empty():
			var fh := AstralTheme.hbox(10)
			var f_tex: Texture2D = AstralTheme.load_tex("res://assets/art/father_portrait.png")
			if f_tex != null:
				var f_rect := TextureRect.new()
				f_rect.texture = f_tex
				f_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				f_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				f_rect.custom_minimum_size = Vector2(44, 56)
				fh.add_child(f_rect)
			fh.add_child(_section("El Padre", [AstralTheme.G_ANKH]))
			content.add_child(fh)
			for f in father:
				content.add_child(_line_card("%s  %s" % [f["icon"], f["name"]], str(f["text"]), AstralTheme.TURQ))

		for b in report["blocks"]:
			content.add_child(_block_card(b))

		var syn: Array = report["synergies"]
		if not syn.is_empty():
			AstralAudio.play_triumph()
		for s in syn:
			var card := AstralTheme.panel("GlowPanel")
			var v := AstralTheme.vbox(2)
			card.add_child(v)
			v.add_child(AstralTheme.label("%s  ¡Sinergia de Prestigio: %s!" % [AstralTheme.G_FLEUR, s["title"]], "SubLabel", AstralTheme.GOLD_PALE, true))
			v.add_child(AstralTheme.label(str(s["desc"]), "", AstralTheme.IVORY, true))
			content.add_child(card)

		var rivals: Array = report["rivals"]
		var upkeep: Array = report["upkeep"]
		if not rivals.is_empty() or not upkeep.is_empty():
			content.add_child(_section("Fin del bimestre", []))
			var card := AstralTheme.panel("SunkenPanel")
			var v := AstralTheme.vbox(4)
			card.add_child(v)
			for r in rivals:
				v.add_child(AstralTheme.label(AstralTheme.G_SWORD + "  " + str(r), "", AstralTheme.ROSE, true))
			for u in upkeep:
				v.add_child(AstralTheme.label(AstralTheme.G_FLOWER + "  " + str(u), "", AstralTheme.MUTED, true))
			content.add_child(card)

		var summary: Array = report["summary"]
		if not summary.is_empty():
			content.add_child(_section("Balance del bimestre", []))
			var flow := HFlowContainer.new()
			flow.add_theme_constant_override("h_separation", 10)
			flow.add_theme_constant_override("v_separation", 8)
			for s in summary:
				var d: int = int(s["delta"])
				var bad_up: bool = (s["stat"] == "stress" or s["stat"] == "entropia" or s["stat"] == "astral_saturation")
				var good: bool = (d > 0) != bad_up
				var chip := AstralTheme.panel("PillPanel")
				chip.add_child(AstralTheme.label("%s %s" % [s["label"], AstralTheme.signed(d)], "", AstralTheme.GOOD if good else AstralTheme.BAD))
				flow.add_child(chip)
			content.add_child(flow)

		var cont := AstralTheme.button("Continuar  ▶", "PrimaryButton")
		cont.custom_minimum_size.y = 56
		cont.pressed.connect(hide_overlay)
		content.add_child(cont))
	show_overlay()

func _section(title: String, _glyphs: Array) -> Control:
	return AstralTheme.label(title, "SubLabel")

func _line_card(title: String, text: String, color: Color) -> Control:
	var card := AstralTheme.panel("CardPanel")
	var v := AstralTheme.vbox(2)
	card.add_child(v)
	v.add_child(AstralTheme.label(title, "SubLabel", color))
	v.add_child(AstralTheme.label(text, "", AstralTheme.IVORY, true))
	return card

func _block_card(b: Dictionary) -> Control:
	var card := AstralTheme.panel("CardPanel")
	var v := AstralTheme.vbox(8)
	card.add_child(v)
	var days: String = "Días %d a %d" % [(int(b["index"]) - 1) * 20 + 1, int(b["index"]) * 20]
	var head_h := AstralTheme.hbox(10)
	v.add_child(head_h)
	var act_id: String = str(b.get("activity_id", ""))
	var act_cat: String = str(CatalogDB.get_activity(act_id).get("category", "class"))
	var bvign := AstralTheme.vignette_card(CatalogDB.get_activity_illustration(act_id, act_cat), Vector2(92, 52), AstralTheme.GOLD_DARK)
	bvign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head_h.add_child(bvign)
	var hv := AstralTheme.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head_h.add_child(hv)
	hv.add_child(AstralTheme.label("Decano %d · %s" % [int(b["index"]), str(b["name"])], "SubLabel", AstralTheme.GOLD_PALE, true))
	hv.add_child(AstralTheme.label(days, "CaptionLabel", AstralTheme.MUTED))

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 6)
	v.add_child(flow)
	var money: int = int(b["gold"])
	if money != 0:
		flow.add_child(AstralTheme.chip("%s G" % AstralTheme.signed(money), AstralTheme.GOLD_PALE if money > 0 else AstralTheme.EMBER, AstralTheme.GOLD if money > 0 else AstralTheme.EMBER, 13))
	for g in b["gains"]:
		var dv: int = int(g["delta"])
		flow.add_child(AstralTheme.chip("%s %s" % [g["label"], AstralTheme.signed(dv)], AstralTheme.GOOD if dv > 0 else AstralTheme.BAD, null, 13))
	if int(b["seal_delta"]) != 0:
		var sd: int = int(b["seal_delta"])
		flow.add_child(AstralTheme.chip("%s %s%%" % [GameState.get_stat_label("seal_integrity"), AstralTheme.signed(sd)], AstralTheme.GOOD if sd > 0 else AstralTheme.BAD, null, 13))
	var st: int = int(b["stress_delta"])
	flow.add_child(AstralTheme.chip("Estrés %s" % AstralTheme.signed(st), AstralTheme.BAD if st > 0 else AstralTheme.GOOD, null, 13))
	for n in b["notes"]:
		v.add_child(AstralTheme.label(AstralTheme.G_STAR2 + "  " + str(n), "CaptionLabel", AstralTheme.GOLD_PALE, true))
	if b.has("clash"):
		var c: Dictionary = b["clash"]
		var inner := AstralTheme.panel("GlowPanel" if c["won"] else "SunkenPanel")
		var iv := AstralTheme.vbox(2)
		inner.add_child(iv)
		iv.add_child(AstralTheme.label("%s  %s" % [AstralTheme.G_SWORD, "Choque de aula: " + str(c["clash_name"])], "SubLabel", AstralTheme.GOOD if c["won"] else AstralTheme.ROSE, true))
		iv.add_child(AstralTheme.label(str(c["text"]), "", AstralTheme.IVORY, true))
		v.add_child(inner)
	if b.has("event"):
		var e: Dictionary = b["event"]
		var inner2 := AstralTheme.panel("SunkenPanel")
		var iv2 := AstralTheme.vbox(2)
		inner2.add_child(iv2)
		iv2.add_child(AstralTheme.label("%s  %s%s" % [AstralTheme.G_QUILL, e["title"], "  (el rasgo marcó la diferencia)" if e["trait"] else ""], "SubLabel", AstralTheme.AMETHYST, true))
		iv2.add_child(AstralTheme.label(str(e["text"]), "", AstralTheme.IVORY, true))
		if str(e["effects"]) != "":
			iv2.add_child(AstralTheme.label(str(e["effects"]), "CaptionLabel", AstralTheme.GOOD, true))
		v.add_child(inner2)
	return card
