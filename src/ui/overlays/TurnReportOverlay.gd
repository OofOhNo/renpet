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
			content.add_child(_section("El Padre", [AstralTheme.G_ANKH]))
			for f in father:
				content.add_child(_line_card("%s  %s" % [f["icon"], f["name"]], str(f["text"]), AstralTheme.TURQ))

		for b in report["blocks"]:
			content.add_child(_block_card(b))

		var syn: Array = report["synergies"]
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
	var v := AstralTheme.vbox(6)
	card.add_child(v)
	var days: String = "Días %d a %d" % [(int(b["index"]) - 1) * 20 + 1, int(b["index"]) * 20]
	v.add_child(AstralTheme.label("%s  Decano %d  ·  %s  ·  %s" % [AstralTheme.G_STAR, int(b["index"]), days, b["name"]], "SubLabel", null, true))
	var chips: Array[String] = []
	var money: int = int(b["gold"])
	if money != 0:
		chips.append(AstralTheme.colored("%s G" % AstralTheme.signed(money), AstralTheme.GOLD if money > 0 else AstralTheme.EMBER))
	for g in b["gains"]:
		chips.append(AstralTheme.colored("%s %s" % [g["label"], AstralTheme.signed(int(g["delta"]))], AstralTheme.GOOD if int(g["delta"]) > 0 else AstralTheme.BAD))
	if int(b["seal_delta"]) != 0:
		chips.append(AstralTheme.colored("Sello %s%%" % AstralTheme.signed(int(b["seal_delta"])), AstralTheme.GOOD if int(b["seal_delta"]) > 0 else AstralTheme.BAD))
	var st: int = int(b["stress_delta"])
	chips.append(AstralTheme.colored("Estrés %s" % AstralTheme.signed(st), AstralTheme.BAD if st > 0 else AstralTheme.GOOD))
	v.add_child(AstralTheme.rich("  ·  ".join(chips)))
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
