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
	{"id": 0, "name": "I. El Filo del Vértice", "tag": "Marcial", "desc": "Antiguo campeón con un mandoble ancestral.", "bonus": "+30 Temple, +25 Destreza, +15 Reputación"},
	{"id": 1, "name": "II. El Archimago del Velo", "tag": "Sabio", "desc": "Erudito de los archivos secretos del templo.", "bonus": "+35 Erudición, +25 Resonancia, +10% Investigación"},
	{"id": 2, "name": "III. El Infiltrador del Silencio", "tag": "Sombras", "desc": "Con contactos en los canales y ojo para las trampas.", "bonus": "+400 Oro, +20 Destreza, +20 Magnetismo"},
	{"id": 3, "name": "IV. El Custodio del Altar", "tag": "Devoto", "desc": "Sereno guardián del Santuario Caído.", "bonus": "+15 Anclaje Humano, +20 Devoción, -10 Estrés"}
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
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, clampf(PAGES[_page].length() * 0.018, 1.5, 5.0))

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
			b.custom_minimum_size = Vector2(0, 118)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.text = "%s   (%s)\n%s\n%s" % [a["name"], a["tag"], a["desc"], a["bonus"]]
			b.tooltip_text = str(a["bonus"])
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
	hide_overlay()
	finished.emit(d, f, _chosen)
