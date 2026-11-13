extends ModalOverlay
class_name BondEventOverlay

## Escena de historia con un candidato (Fase 6.3): narración, decisiones por ruta y resultado.

signal resolved(npc_id: String)

var _npc_id: String = ""

func play(npc_id: String) -> void:
	_npc_id = npc_id
	var info: Dictionary = RelationshipManager.get_next_bond_event(npc_id)
	if not info.get("ok", false):
		return
	AstralAudio.play_confirm()
	var ev: Dictionary = info["event"]
	var data: Dictionary = RelationshipManager.get_data(npc_id)
	set_panel_width(960)
	rebuild(func() -> void:
		var dist_map: Dictionary = {"soren": "torre", "cassian": "palacio", "vespera": "patio", "kaelen": "acueductos", "zephyr": "espejo", "mirari": "anfiteatro", "lyra": "palacio", "caelum": "patio"}
		var dist_id: String = str(dist_map.get(npc_id, "torre"))
		content.add_child(AstralTheme.scenic_banner(CatalogDB.get_district_backdrop(dist_id), 108.0, Color(1, 1, 1, 0.92)))
		var head := AstralTheme.hbox(14)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/ui/npc_%s.png" % npc_id)
		icon.custom_minimum_size = Vector2(84, 84)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(icon)
		var hv := AstralTheme.vbox(2)
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(hv)
		hv.add_child(AstralTheme.label(str(ev["title"]), "HeadingLabel", AstralTheme.GOLD, true))
		hv.add_child(AstralTheme.label("%s  ·  Acto %d" % [data["name"], int(info["stage"])], "CaptionLabel", AstralTheme.TURQ))
		content.add_child(head)
		content.add_child(AstralTheme.separator())
		var nar := AstralTheme.rich("[font_size=21]%s[/font_size]" % str(ev["narrative"]).replace("\n", "\n"))
		content.add_child(nar)
		content.add_child(AstralTheme.label("¿Qué decides?", "SubLabel"))
		for ch in info["choices"]:
			var glyph: String = AstralTheme.G_STAR
			var variation: String = ""
			match ch["kind"]:
				"rival":
					glyph = AstralTheme.G_SWORD
					variation = "DangerButton"
				"romance":
					glyph = AstralTheme.G_HEART
			var b := AstralTheme.button("%s  %s" % [glyph, ch["label"]], variation)
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.custom_minimum_size.y = 62
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var choice: Dictionary = ch
			b.pressed.connect(func() -> void: _choose(choice))
			content.add_child(b))
	show_overlay()

func _choose(choice: Dictionary) -> void:
	var res: Dictionary = RelationshipManager.apply_bond_event_choice(_npc_id, choice)
	if not res.get("ok", false):
		hide_overlay()
		return
	rebuild(func() -> void:
		content.add_child(AstralTheme.label(str(res["speaker"]), "HeadingLabel", AstralTheme.GOLD, true))
		content.add_child(AstralTheme.separator())
		content.add_child(AstralTheme.rich("[font_size=21]%s[/font_size]" % str(res["outcome"])))
		content.add_child(AstralTheme.label(str(res["effects"]), "", AstralTheme.GOOD, true))
		var b := AstralTheme.button("Continuar  ▶", "PrimaryButton")
		b.custom_minimum_size.y = 54
		b.pressed.connect(func() -> void:
			hide_overlay()
			resolved.emit(_npc_id))
		content.add_child(b))
