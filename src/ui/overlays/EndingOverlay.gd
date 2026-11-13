extends ModalOverlay
class_name EndingOverlay

## Secuencia Final Completa (Fase 9): Clímax del Solsticio, 4 Vectores (65 Finales),
## Testamento Paternal y registro automático en El Tapiz de las Constelaciones (NG+).

signal title_requested()

var _eval: Dictionary = {}
var _tap_res: Dictionary = {}
var _climax_note: String = ""
var _tapestry: ConstellationOverlay

func _ready() -> void:
	super._ready()
	_tapestry = ConstellationOverlay.new()
	add_child(_tapestry)

func show_ending() -> void:
	_eval = EndingEvaluator.evaluate_campaign()
	_tap_res = ConstellationTapestry.record_campaign_completion(_eval)
	_climax_note = ""
	AstralAudio.play_twist()
	_show_step_climax()
	show_overlay()

func _show_step_climax() -> void:
	var branch: Dictionary = _eval.get("branch", {})
	var branch_id: String = str(_eval.get("branch_id", "branch_mortal"))
	var b_col: Color = Color.html(str(branch.get("color", "#f4c95d")))
	var icon_path: String = "res://assets/ui/seal_medallion_cracked.png" if (branch_id == "branch_eclipse" or branch_id == "branch_deicide") else "res://assets/ui/seal_medallion_intact.png"

	set_panel_width(980)
	rebuild(func() -> void:
		var ban_path: String = "res://assets/art/bg_zone_crater.png" if (branch_id == "branch_eclipse" or branch_id == "branch_deicide") else "res://assets/art/bg_prologue_goddess.png"
		content.add_child(AstralTheme.scenic_banner(ban_path, 116.0, Color(1, 1, 1, 0.94)))
		var head := AstralTheme.hbox(14)
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(78, 78)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(icon)

		var hv := AstralTheme.vbox(3)
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(hv)
		hv.add_child(AstralTheme.label("%s  ACTO FINAL · EL SOLSTICIO DE LOS VEINTE AÑOS" % AstralTheme.G_STAR, "CaptionLabel", b_col))
		hv.add_child(AstralTheme.label(str(branch.get("climax_title", "EL JUICIO FINAL")), "HeadingLabel", AstralTheme.GOLD, true))
		hv.add_child(AstralTheme.label(str(branch.get("name", "")), "SubLabel", b_col, true))
		content.add_child(head)

		content.add_child(AstralTheme.separator())
		content.add_child(AstralTheme.rich("[font_size=21]%s[/font_size]" % str(branch.get("climax_body", "")), 140))
		content.add_child(AstralTheme.label("Última palabra ante la Diosa:", "SubLabel", AstralTheme.GOLD_PALE))

		for ch in branch.get("climax_choices", []):
			var d: Dictionary = ch
			var b := AstralTheme.button(str(d.get("label", "Sellar destino")), "PrimaryButton")
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.custom_minimum_size.y = 60
			b.pressed.connect(func() -> void:
				_climax_note = str(d.get("note", ""))
				_show_step_vectors())
			content.add_child(b))

func _show_step_vectors() -> void:
	var branch: Dictionary = _eval.get("branch", {})
	var voc: Dictionary = _eval.get("vocation", {})
	var bond: Dictionary = _eval.get("bond", {})
	var rivals: Dictionary = _eval.get("rivals", {})
	var politics: Dictionary = _eval.get("politics", {})
	var metrics: Dictionary = _eval.get("metrics", {})
	var b_col: Color = Color.html(str(branch.get("color", "#f4c95d")))

	set_panel_width(1020)
	rebuild(func() -> void:
		content.add_child(AstralTheme.label("%s  EPÍLOGO DE LOS 4 VECTORES  %s" % [AstralTheme.G_ANKH, AstralTheme.G_ANKH], "HeadingLabel", AstralTheme.GOLD, true))
		if _climax_note != "":
			content.add_child(AstralTheme.label(_climax_note, "CaptionLabel", AstralTheme.TURQ, true))
		content.add_child(AstralTheme.separator())

		# Tarjeta principal: Rama x Vocación (Matriz de 65 Finales)
		var main_card := AstralTheme.panel("GlowPanel")
		var mv := AstralTheme.vbox(6)
		main_card.add_child(mv)
		mv.add_child(AstralTheme.label("FINAL ALCANZADO: %s" % str(_eval.get("ending_title", "")), "HeadingLabel", AstralTheme.GOLD_PALE, true))
		mv.add_child(AstralTheme.label("%s   ·   Vocación: %s (%s)" % [
			str(branch.get("short", "")), str(voc.get("name", "")), str(voc.get("tag", ""))
		], "SubLabel", b_col, true))
		mv.add_child(AstralTheme.rich("[font_size=18]%s[/font_size]" % str(_eval.get("ending_summary", ""))))
		content.add_child(main_card)

		# Grid 2 columnas: Vínculos + Política + Rivales
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		content.add_child(grid)

		var c_bond := AstralTheme.panel("CardPanel")
		c_bond.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bv := AstralTheme.vbox(4)
		c_bond.add_child(bv)
		bv.add_child(AstralTheme.label("%s  Vínculos y Corazón" % AstralTheme.G_HEART, "SubLabel", AstralTheme.ROSE))
		bv.add_child(AstralTheme.label("%s — %s" % [str(bond.get("primary_name", "")), str(bond.get("status", ""))], "CaptionLabel", AstralTheme.GOLD_PALE, true))
		bv.add_child(AstralTheme.rich(str(bond.get("text", ""))))
		if str(bond.get("nemesis_text", "")) != "":
			bv.add_child(AstralTheme.rich("[color=#f26b7a]%s[/color]" % str(bond.get("nemesis_text", ""))))
		grid.add_child(c_bond)

		var c_pol := AstralTheme.panel("CardPanel")
		c_pol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pv := AstralTheme.vbox(4)
		c_pol.add_child(pv)
		pv.add_child(AstralTheme.label("%s  Destino de Aethelgard y Rivales" % AstralTheme.G_SUN, "SubLabel", AstralTheme.TURQ))
		pv.add_child(AstralTheme.label(str(politics.get("title", "")), "CaptionLabel", AstralTheme.GOLD_PALE, true))
		pv.add_child(AstralTheme.rich(str(politics.get("text", ""))))
		pv.add_child(AstralTheme.label("Rivales superados: %d / %d  ·  Victorias en Festival: %d" % [
			int(rivals.get("beaten", 0)), int(rivals.get("total", 4)), int(metrics.get("festival_wins", 0))
		], "CaptionLabel", AstralTheme.GOOD, true))
		for rline in rivals.get("lines", []):
			pv.add_child(AstralTheme.label(str(rline), "CaptionLabel", AstralTheme.MUTED, true))
		grid.add_child(c_pol)

		var b_next := AstralTheme.button("Leer el Testamento Paternal  ▶", "PrimaryButton")
		b_next.custom_minimum_size.y = 54
		b_next.pressed.connect(_show_step_testament)
		content.add_child(b_next))

func _show_step_testament() -> void:
	var test: Dictionary = _eval.get("testament", {})
	var m: Dictionary = _eval.get("metrics", {})

	set_panel_width(960)
	rebuild(func() -> void:
		content.add_child(AstralTheme.label("%s  EL TESTAMENTO PATERNAL  %s" % [AstralTheme.G_QUILL, AstralTheme.G_QUILL], "HeadingLabel", AstralTheme.GOLD, true))
		content.add_child(AstralTheme.label("Veredicto de Crianza: %s" % str(test.get("verdict", "")), "SubLabel", AstralTheme.TURQ, true))
		content.add_child(AstralTheme.separator())

		var letter_card := AstralTheme.panel("GlowPanel")
		var lv := AstralTheme.vbox(8)
		letter_card.add_child(lv)
		lv.add_child(AstralTheme.rich("[font_size=21][i]%s[/i][/font_size]" % str(test.get("letter", "")), 120))
		lv.add_child(AstralTheme.label("— Con todo lo vivido, %s" % GameState.daughter_name, "SubLabel", AstralTheme.GOLD_PALE))
		content.add_child(letter_card)

		var stats_card := AstralTheme.panel("SunkenPanel")
		stats_card.add_child(AstralTheme.label(
			"Balance final: %s %d%%  ·  Anclaje %d  ·  %s %d  ·  Afecto %d%%  ·  Esquirlas %d/5  ·  Mutaciones %d  ·  Sinergias %d  ·  Cartas %d" % [
				GameState.get_stat_label("seal_integrity"), GameState.seal_integrity, GameState.human_anchor,
				GameState.get_stat_label("abyssal_sync"), GameState.abyssal_sync, GameState.affection,
				int(m.get("shards", 0)), int(m.get("mutations", 0)), int(m.get("synergies", 0)), int(m.get("letters", 0))
			],
			"CaptionLabel", AstralTheme.MUTED, true
		))
		content.add_child(stats_card)

		var b_next := AstralTheme.button("Grabar en El Tapiz de las Constelaciones  ▶", "PrimaryButton")
		b_next.custom_minimum_size.y = 54
		b_next.pressed.connect(_show_step_tapestry)
		content.add_child(b_next))

func _show_step_tapestry() -> void:
	AstralAudio.play_triumph()
	set_panel_width(920)
	rebuild(func() -> void:
		content.add_child(AstralTheme.label("%s  EL TAPIZ DE LAS CONSTELACIONES (NEW GAME+)  %s" % [AstralTheme.G_STAR, AstralTheme.G_STAR], "HeadingLabel", AstralTheme.GOLD, true))
		content.add_child(AstralTheme.separator())

		var badges: Array[String] = []
		if bool(_tap_res.get("is_new_ending", false)):
			badges.append("✦ ¡NUEVO FINAL DESBLOQUEADO EN LA MATRIZ!")
		if bool(_tap_res.get("is_new_branch", false)):
			badges.append("✦ ¡NUEVA RAMA DEL SOLSTICIO DESCUBIERTA!")
		if bool(_tap_res.get("is_new_bond", false)):
			badges.append("✦ ¡NUEVO EPÍLOGO DE VÍNCULO REGISTRADO!")
		if badges.is_empty():
			badges.append("✦ Constelación confirmada en tu historial eterno.")

		var card := AstralTheme.panel("GlowPanel")
		var cv := AstralTheme.vbox(8)
		card.add_child(cv)
		cv.add_child(AstralTheme.label(str(_eval.get("ending_title", "")), "HeadingLabel", AstralTheme.GOLD_PALE, true))
		cv.add_child(AstralTheme.label("\n".join(badges), "SubLabel", AstralTheme.GOOD, true))
		cv.add_child(AstralTheme.label(
			"Puntos Astrales ganados en esta campaña: +%d ✦   (Total acumulado: %d ✦)\nProgreso global del Tapiz: %d / %d Finales únicos desbloqueados." % [
				int(_tap_res.get("earned_points", 0)),
				int(_tap_res.get("total_points", 0)),
				int(_tap_res.get("unlocked_count", 0)),
				int(_tap_res.get("total_matrix", 65))
			],
			"", AstralTheme.IVORY, true
		))
		content.add_child(card)

		var row := AstralTheme.hbox(12)
		var b_tap := AstralTheme.button("%s  Abrir Tapiz y Comprar Bendiciones NG+" % AstralTheme.G_STAR, "PrimaryButton")
		b_tap.custom_minimum_size.y = 56
		b_tap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_tap.pressed.connect(func() -> void:
			_tapestry.open_tapestry(1)
			_tapestry.move_to_front())
		row.add_child(b_tap)

		var b_title := AstralTheme.button("Volver al Título")
		b_title.custom_minimum_size = Vector2(220, 56)
		b_title.pressed.connect(func() -> void:
			hide_overlay()
			title_requested.emit())
		row.add_child(b_title)
		content.add_child(row))
