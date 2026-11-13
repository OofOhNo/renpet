extends ModalOverlay
class_name LetterOverlay

## Carta manuscrita anual de Renpet (Fase 1.4), sobre pergamino.

func show_letter(letter: Dictionary) -> void:
	AstralAudio.play_confirm()
	set_panel_width(860)
	var parchment := AstralTheme.box(Color("e9dcc0"), Color("8b6a2b"), 4, 10, 30, true)
	panel.add_theme_stylebox_override("panel", parchment)
	var ink := Color("3b2a14")
	rebuild(func() -> void:
		content.add_child(AstralTheme.label("%s  MANUSCRITO SOLAR DEL SOLSTICIO  %s" % [AstralTheme.G_ANKH, AstralTheme.G_ANKH], "CaptionLabel", Color("8b6a2b")))
		var t := AstralTheme.label("%s  %s" % [AstralTheme.G_ENVELOPE, letter["title"]], "HeadingLabel", Color("7a4f12"), true)
		content.add_child(t)
		var sep := HSeparator.new()
		var sep_style := StyleBoxLine.new()
		sep_style.color = Color(0.545, 0.416, 0.169, 0.55)
		sep_style.thickness = 2
		sep.add_theme_stylebox_override("separator", sep_style)
		content.add_child(sep)
		var r := RichTextLabel.new()
		r.bbcode_enabled = false
		r.fit_content = true
		r.scroll_active = false
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_theme_color_override("default_color", ink)
		r.add_theme_font_override("normal_font", AstralTheme.font("Italic"))
		r.add_theme_font_size_override("normal_font_size", 23)
		r.text = str(letter["content"])
		content.add_child(r)
		var b := AstralTheme.button("Guardar la carta  " + AstralTheme.G_CHECK, "PrimaryButton")
		b.custom_minimum_size.y = 54
		b.pressed.connect(hide_overlay)
		content.add_child(b))
	show_overlay()
