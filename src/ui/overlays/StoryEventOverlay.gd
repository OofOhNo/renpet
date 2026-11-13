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
	var title: String = str(ev.get("title", "Evento de Historia"))
	var body_txt: String = str(ev.get("body", ""))
	var choices: Array = ev.get("choices", [])

	set_panel_width(980)
	rebuild(func() -> void:
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

		content.add_child(AstralTheme.label("Tu respuesta ante el destino:", "SubLabel", AstralTheme.GOLD_PALE))
		for ch in choices:
			var d: Dictionary = ch
			var b := AstralTheme.button(str(d.get("label", "Decidir")), "PrimaryButton" if is_twist else "")
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.custom_minimum_size.y = 62
			b.pressed.connect(func() -> void: _on_choose(d, title, is_twist))
			content.add_child(b))
	show_overlay()

func _on_choose(choice: Dictionary, title: String, is_twist: bool) -> void:
	var summary_effects: String = ExplorationCombat.apply_story_event_choice(_act_id, choice)
	var outcome: String = str(choice.get("outcome", ""))

	rebuild(func() -> void:
		content.add_child(AstralTheme.label(title, "HeadingLabel", AstralTheme.ROSE if is_twist else AstralTheme.GOLD, true))
		content.add_child(AstralTheme.separator())
		content.add_child(AstralTheme.rich("[font_size=21]%s[/font_size]" % outcome, 90))
		if summary_effects != "":
			content.add_child(AstralTheme.label("Consecuencias: %s" % summary_effects, "SubLabel", AstralTheme.GOOD, true))
		var b := AstralTheme.button("Continuar  ▶", "PrimaryButton")
		b.custom_minimum_size.y = 54
		b.pressed.connect(func() -> void:
			hide_overlay()
			story_resolved.emit(_act_id))
		content.add_child(b))
