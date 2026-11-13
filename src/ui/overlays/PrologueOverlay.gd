extends ModalOverlay
class_name PrologueOverlay

## Prólogo narrativo (descenso de la estrella) + creación del héroe (Fase 3.2 y 3.3).
## Emite finished(nombre_hija, nombre_padre, arquetipo) al comenzar la historia.

signal finished(daughter: String, father: String, archetype: int)

const PAGES: Array[String] = [
	"Hace doce años quebraste las cadenas del templo donde la Diosa Renpet-Neheh, Señora del Tiempo, estuvo cautiva por siglos.\n\nEn gratitud, la Diosa desprendió una estrella blanca del firmamento, le dio forma de niña humana y la puso en tus brazos.",
	"Todos en Aethelgard celebran a la pequeña como una bendición divina del firmamento.\n\nSin embargo, en la quietud de las noches sin luna, has percibido una marca dorada en su pecho y un segundo latido oculto en su interior, como el pulso de un reloj antiguo.",
	"Ahora tu hija cumple doce años en tu observatorio de Aethelgard.\n\nTienes ocho años por delante, hasta el Solsticio de sus veinte, para criarla, protegerla y descubrir qué secreto duerme realmente dentro de su luz."
]

const ARCHETYPES: Array[Dictionary] = [
	{
		"id": 0, "name": "El Filo del Vértice", "tag": "Marcial",
		"icon": "res://assets/art/illus_martial_courtyard.png", "col": AstralTheme.EMBER,
		"desc": "Campeón del mandoble ancestral.",
		"chips": ["+30 Temple", "+25 Destreza", "+15 Rep."]
	},
	{
		"id": 1, "name": "El Archimago del Velo", "tag": "Sabio",
		"icon": "res://assets/art/bg_district_torre.png", "col": AstralTheme.SKY,
		"desc": "Erudito de archivos celestes.",
		"chips": ["+35 Erudición", "+25 Resonancia", "+10% Indag."]
	},
	{
		"id": 2, "name": "El Infiltrador del Silencio", "tag": "Sombras",
		"icon": "res://assets/art/bg_district_acueductos.png", "col": AstralTheme.AMETHYST,
		"desc": "Contactos en los canales.",
		"chips": ["+400 Oro", "+20 Destreza", "+20 Magnetismo"]
	},
	{
		"id": 3, "name": "El Custodio del Altar", "tag": "Devoto",
		"icon": "res://assets/art/bg_district_espejo.png", "col": AstralTheme.GOOD,
		"desc": "Guardián del Santuario Caído.",
		"chips": ["+15 Anclaje", "+20 Devoción", "-10 Estrés"]
	}
]

var _bg: TextureRect
var _page: int = 0
var _text: RichTextLabel
var _typing: Tween
var _daughter_edit: LineEdit
var _father_edit: LineEdit
var _chosen: int = 0
var _arch_buttons: Array[Button] = []
var _start_btn: Button
var _error: Label
var _ng_echo_chk: CheckBox

func _ready() -> void:
	set_panel_width(1100)
	_align_bottom = true
	super._ready()
	_dim.color = Color(0.01, 0.015, 0.06, 0.55)
	_bg = TextureRect.new()
	_bg.texture = load("res://assets/art/bg_prologue_goddess.png")
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	move_child(_bg, 0)

func begin() -> void:
	_page = 0
	_show_story_page()
	show_overlay()

func _show_story_page() -> void:
	rebuild(func() -> void:
		content.add_child(AstralTheme.label("%s  PRÓLOGO: EL REGALO DE LA SEÑORA DE LA ETERNIDAD  %s" % [AstralTheme.G_ANKH, AstralTheme.G_ANKH], "HeadingLabel", AstralTheme.GOLD, true))
		content.add_child(AstralTheme.separator())
		_text = AstralTheme.rich("[font_size=25]%s[/font_size]" % PAGES[_page])
		_text.custom_minimum_size.y = 190
		content.add_child(_text)
		var row := AstralTheme.hbox(10)
		content.add_child(row)
		row.add_child(AstralTheme.label("%d / %d" % [_page + 1, PAGES.size()], "CaptionLabel", AstralTheme.MUTED))
		row.add_child(AstralTheme.spacer())
		var skip := AstralTheme.button("Saltar", "TabLikeButton")
		skip.pressed.connect(_show_creation)
		row.add_child(skip)
		var nxt := AstralTheme.button("Continuar  ▶" if _page < PAGES.size() - 1 else "Crear al Héroe  ▶", "PrimaryButton")
		nxt.custom_minimum_size = Vector2(220, 52)
		nxt.pressed.connect(_next_page)
		row.add_child(nxt))
	_text.visible_ratio = 0.0
	if _typing != null and _typing.is_valid():
		_typing.kill()
	var dur: float = SettingsManager.get_typewriter_duration(PAGES[_page].length())
	if dur <= 0.01:
		_text.visible_ratio = 1.0
	else:
		_typing = create_tween()
		_typing.tween_property(_text, "visible_ratio", 1.0, dur)

func _next_page() -> void:
	AstralAudio.play_ui()
	if _text != null and _text.visible_ratio < 1.0:
		if _typing != null and _typing.is_valid():
			_typing.kill()
		_text.visible_ratio = 1.0
		return
	_page += 1
	if _page >= PAGES.size():
		_show_creation()
	else:
		_show_story_page()

func _show_creation() -> void:
	if _typing != null and _typing.is_valid():
		_typing.kill()
	_arch_buttons.clear()
	rebuild(func() -> void:
		content.add_child(AstralTheme.label("%s  CREACIÓN DEL HÉROE  %s" % [AstralTheme.G_STAR, AstralTheme.G_STAR], "HeadingLabel", AstralTheme.GOLD, true))
		content.add_child(AstralTheme.separator())
		var names := AstralTheme.hbox(16)
		content.add_child(names)
		var c1 := AstralTheme.vbox(4)
		c1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c1.add_child(AstralTheme.label("Nombre de la Niña Estrella", "CaptionLabel", AstralTheme.GOLD))
		_daughter_edit = LineEdit.new()
		_daughter_edit.text = GameState.daughter_name
		_daughter_edit.max_length = 16
		_daughter_edit.placeholder_text = "Renpet"
		c1.add_child(_daughter_edit)
		names.add_child(c1)
		var c2 := AstralTheme.vbox(4)
		c2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c2.add_child(AstralTheme.label("Nombre del Héroe (Padre)", "CaptionLabel", AstralTheme.TURQ))
		_father_edit = LineEdit.new()
		_father_edit.text = GameState.father_name
		_father_edit.max_length = 16
		_father_edit.placeholder_text = "Aurelius"
		c2.add_child(_father_edit)
		names.add_child(c2)

		content.add_child(AstralTheme.label("Elige tu leyenda heroica al liberar a la Diosa:", "SubLabel"))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		content.add_child(grid)
		for a in ARCHETYPES:
			var b := Button.new()
			b.toggle_mode = true
			b.theme_type_variation = "TabLikeButton"
			b.custom_minimum_size = Vector2(0, 114)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.tooltip_text = "%s — %s" % [str(a["name"]), str(a["desc"])]
			var row := AstralTheme.hbox(10)
			row.set_anchors_preset(Control.PRESET_FULL_RECT)
			row.offset_left = 10
			row.offset_right = -10
			row.offset_top = 8
			row.offset_bottom = -8
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(row)
			var col: Color = a["col"]
			var ib := AstralTheme.vignette_card(str(a["icon"]), Vector2(86, 56), col)
			ib.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			ib.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(ib)
			var av := AstralTheme.vbox(4)
			av.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			av.alignment = BoxContainer.ALIGNMENT_CENTER
			av.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(av)
			var th := AstralTheme.hbox(8)
			th.mouse_filter = Control.MOUSE_FILTER_IGNORE
			av.add_child(th)
			var ttl := AstralTheme.label(str(a["name"]), "SubLabel", AstralTheme.GOLD_PALE)
			ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ttl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			th.add_child(ttl)
			var tag_chip := AstralTheme.chip(str(a["tag"]), col, col, 13)
			tag_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			th.add_child(tag_chip)
			var dl := AstralTheme.label(str(a["desc"]), "CaptionLabel", AstralTheme.MUTED, true)
			dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			av.add_child(dl)
			var chips := HFlowContainer.new()
			chips.add_theme_constant_override("h_separation", 6)
			chips.add_theme_constant_override("v_separation", 4)
			chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for ch_s in a["chips"]:
				var cp := AstralTheme.chip(str(ch_s), AstralTheme.IVORY, Color(col, 0.5), 13)
				cp.mouse_filter = Control.MOUSE_FILTER_IGNORE
				chips.add_child(cp)
			av.add_child(chips)
			var aid: int = int(a["id"])
			b.pressed.connect(func() -> void: _choose(aid))
			grid.add_child(b)
			_arch_buttons.append(b)
		_error = AstralTheme.label("", "CaptionLabel", AstralTheme.BAD, true)
		content.add_child(_error)
		var boon_names: Array[String] = ConstellationTapestry.get_active_boon_names()
		if not boon_names.is_empty():
			content.add_child(AstralTheme.label(
				"%s  Bendiciones del Tapiz (NG+) activas: %s" % [AstralTheme.G_STAR, ", ".join(boon_names)],
				"CaptionLabel", AstralTheme.GOOD, true
			))
		_ng_echo_chk = null
		if ConstellationTapestry.discovered_branches.size() >= 1:
			_ng_echo_chk = CheckBox.new()
			_ng_echo_chk.text = "✦ Eco del Solsticio (NG+): Despertar con recuerdos del otro ciclo (+12% Investigación inicial)"
			_ng_echo_chk.add_theme_color_override("font_color", AstralTheme.TURQ)
			_ng_echo_chk.button_pressed = GameState.story_ng_echo_used
			content.add_child(_ng_echo_chk)
		_start_btn = AstralTheme.button("%s  COMENZAR LA HISTORIA  %s" % [AstralTheme.G_STAR, AstralTheme.G_STAR], "PrimaryButton")
		_start_btn.custom_minimum_size.y = 60
		_start_btn.pressed.connect(_confirm)
		content.add_child(_start_btn))
	_choose(_chosen)

func _choose(idx: int) -> void:
	_chosen = idx
	for i in range(_arch_buttons.size()):
		_arch_buttons[i].button_pressed = (i == idx)

func _confirm() -> void:
	var d: String = _daughter_edit.text.strip_edges()
	var f: String = _father_edit.text.strip_edges()
	if d == "" or f == "":
		_error.text = "Ambos nombres deben tener al menos una letra."
		return
	var use_echo: bool = _ng_echo_chk != null and _ng_echo_chk.button_pressed
	GameState.story_ng_echo_used = use_echo
	hide_overlay()
	finished.emit(d, f, _chosen)
