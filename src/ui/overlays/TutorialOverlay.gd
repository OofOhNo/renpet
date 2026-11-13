extends Control
class_name TutorialOverlay

## Tutorial visual guiado en 4 láminas ilustradas para arrancar sin muros de texto.

signal finished()

const STEPS: Array[Dictionary] = [
	{
		"title": "PASO 1 / 4  ·  CRIAR BAJO LAS ESTRELLAS",
		"badge": "Guía a Renpet de los 12 a los 20 años",
		"hero_img": "res://assets/art/renpet_portrait.png",
		"hero_sub": "Renpet & Aurelius",
		"cards": [
			{"icon": "res://assets/art/illus_martial_courtyard.png", "title": "8 Atributos", "desc": "Mortales y Cósmicos", "col": AstralTheme.GOLD},
			{"icon": "res://assets/art/illus_sanatorium_garden.png", "title": "Estrés < 80", "desc": "A 90+ cae en Agotamiento", "col": AstralTheme.BAD},
			{"icon": "res://assets/art/father_portrait.png", "title": "Anclaje y Meta", "desc": "Cumple metas (+100 G)", "col": AstralTheme.TURQ}
		],
		"tip": "Haz clic en el retrato o atrapa chispas brillantes del observatorio (+Oro / -Estrés)."
	},
	{
		"title": "PASO 2 / 4  ·  EL LIBRO DEL BIMESTRE",
		"badge": "Cada turno dura 60 días (3 Decanos)",
		"hero_img": "res://assets/art/illus_study_astrolabe.png",
		"hero_sub": "Agenda de 3 Decanos",
		"cards": [
			{"icon": "res://assets/art/bg_manor_observatory.png", "title": "1. Tablón", "desc": "Arrastra o clica anuncios", "col": AstralTheme.GOLD_PALE},
			{"icon": "res://assets/art/father_portrait.png", "title": "2. El Padre", "desc": "100 Energía en tareas", "col": AstralTheme.TURQ},
			{"icon": "res://assets/art/bg_district_torre.png", "title": "3. Astrolabio", "desc": "Sintoniza 1 vez / turno", "col": AstralTheme.AMETHYST}
		],
		"tip": "Pulsa «Ejecutar los 60 Días» para ver avanzar el reloj estelar de tu turno."
	},
	{
		"title": "PASO 3 / 4  ·  HOGAR Y CRISOL ASTRAL",
		"badge": "Conversación nocturna, dieta y alquimia",
		"hero_img": "res://assets/art/bg_hearth_night.png",
		"hero_sub": "Vida en la Mansión",
		"cards": [
			{"icon": "res://assets/art/bg_hearth_night.png", "title": "Chimenea", "desc": "Moldea su temperamento", "col": AstralTheme.EMBER},
			{"icon": "res://assets/ui/relic_comet_dust.png", "title": "Crisol Astral", "desc": "Asimila reliquias", "col": AstralTheme.AMETHYST},
			{"icon": "res://assets/art/bg_district_acueductos.png", "title": "Comercio", "desc": "Se compra en Aethelgard", "col": AstralTheme.GOOD}
		],
		"tip": "Vigila la Saturación en el Crisol y cura el Agotamiento junto al fuego o en el Boticario."
	},
	{
		"title": "PASO 4 / 4  ·  SALIR A AETHELGARD",
		"badge": "6 distritos físicos, vínculos y festival",
		"hero_img": "res://assets/art/bg_town_map.png",
		"hero_sub": "Mapa Vivo (3 PS / bimestre)",
		"cards": [
			{"icon": "res://assets/art/bg_district_palacio.png", "title": "Habitantes", "desc": "Preséntate (máx. 2/NPC)", "col": AstralTheme.ROSE},
			{"icon": "res://assets/art/bg_district_patio.png", "title": "Patio Ducal", "desc": "Esgrima y Expediciones", "col": AstralTheme.GOLD},
			{"icon": "res://assets/art/bg_coliseum_festival.png", "title": "Anfiteatro", "desc": "Festival en Bimestre 4", "col": AstralTheme.TURQ}
		],
		"tip": "En el Palacio y los Acueductos encontrarás Boutique de trajes, Obsequios, Bazar y Sanatorio."
	}
]

var _step: int = 0
var _card: PanelContainer
var _step_lbl: Label
var _badge_lbl: Label
var _hero_tex: TextureRect
var _hero_sub: Label
var _cards_grid: GridContainer
var _tip_lbl: Label
var _dots_lbl: Label
var _prev_btn: Button
var _next_btn: Button
var _skip_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.06, 0.80)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_card = AstralTheme.panel("MainPanel")
	_card.custom_minimum_size = Vector2(780, 0)
	center.add_child(_card)

	var v := AstralTheme.vbox(12)
	_card.add_child(v)

	var hdr := AstralTheme.hbox(10)
	v.add_child(hdr)
	_step_lbl = AstralTheme.label("", "HeadingLabel", AstralTheme.GOLD)
	_step_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(_step_lbl)
	_skip_btn = AstralTheme.button("✕ Saltar guía", "TabLikeButton")
	_skip_btn.pressed.connect(_finish)
	hdr.add_child(_skip_btn)

	_badge_lbl = AstralTheme.label("", "SubLabel", AstralTheme.TURQ)
	v.add_child(_badge_lbl)
	v.add_child(AstralTheme.separator())

	# Escena visual + 3 tarjetas icónicas (sin muro de párrafos)
	var mid := AstralTheme.hbox(14)
	v.add_child(mid)

	var art_frame := AstralTheme.panel("GlowPanel")
	art_frame.custom_minimum_size = Vector2(228, 196)
	mid.add_child(art_frame)
	var av := AstralTheme.vbox(6)
	art_frame.add_child(av)
	_hero_tex = TextureRect.new()
	_hero_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero_tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hero_tex.custom_minimum_size = Vector2(196, 142)
	av.add_child(_hero_tex)
	_hero_sub = AstralTheme.label("", "CaptionLabel", AstralTheme.GOLD_PALE)
	_hero_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av.add_child(_hero_sub)

	_cards_grid = GridContainer.new()
	_cards_grid.columns = 1
	_cards_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_grid.add_theme_constant_override("v_separation", 8)
	mid.add_child(_cards_grid)

	var tip_p := AstralTheme.panel("SunkenPanel")
	v.add_child(tip_p)
	_tip_lbl = AstralTheme.label("", "CaptionLabel", AstralTheme.GOLD_PALE, true)
	tip_p.add_child(_tip_lbl)

	var nav := AstralTheme.hbox(10)
	v.add_child(nav)
	_prev_btn = AstralTheme.button("◀ Anterior", "TabLikeButton")
	_prev_btn.custom_minimum_size = Vector2(150, 44)
	_prev_btn.pressed.connect(func() -> void:
		if _step > 0:
			AstralAudio.play_ui()
			_step -= 1
			_render())
	nav.add_child(_prev_btn)

	_dots_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD)
	_dots_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dots_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_child(_dots_lbl)

	_next_btn = AstralTheme.button("Siguiente ▶", "PrimaryButton")
	_next_btn.custom_minimum_size = Vector2(220, 46)
	_next_btn.pressed.connect(func() -> void:
		if _step < STEPS.size() - 1:
			AstralAudio.play_ui()
			_step += 1
			_render()
		else:
			_finish())
	nav.add_child(_next_btn)

func open_tutorial(start_step: int = 0) -> void:
	_step = clampi(start_step, 0, STEPS.size() - 1)
	_render()
	visible = true
	if DisplayServer.get_name() != "headless":
		modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.2)

func _render() -> void:
	var s: Dictionary = STEPS[_step]
	var max_w: float = minf(820.0, get_viewport_rect().size.x - 48.0) if get_viewport() != null else 780.0
	_card.custom_minimum_size.x = maxf(520.0, max_w)
	_step_lbl.text = "%s  %s" % [AstralTheme.G_STAR, str(s["title"])]
	_badge_lbl.text = str(s["badge"])
	_hero_tex.texture = AstralTheme.load_tex(str(s["hero_img"]))
	_hero_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if str(s["hero_img"]).contains("portrait") else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_hero_sub.text = str(s["hero_sub"])
	_tip_lbl.text = "%s  %s" % [AstralTheme.G_STAR2, str(s["tip"])]

	for c in _cards_grid.get_children():
		c.queue_free()
	for ci in s["cards"]:
		var col: Color = ci["col"]
		var p := AstralTheme.panel("CardPanel")
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := AstralTheme.hbox(10)
		p.add_child(h)
		var ipath: String = str(ci["icon"])
		if ipath.contains("portrait"):
			h.add_child(AstralTheme.icon_box(ipath, Vector2(54, 58), Color.WHITE))
		else:
			h.add_child(AstralTheme.vignette_card(ipath, Vector2(88, 52), col))
		var tv := AstralTheme.vbox(1)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(tv)
		tv.add_child(AstralTheme.label(str(ci["title"]), "SubLabel", col))
		tv.add_child(AstralTheme.label(str(ci["desc"]), "CaptionLabel", AstralTheme.IVORY, true))
		_cards_grid.add_child(p)

	var dots: Array[String] = []
	for i in range(STEPS.size()):
		dots.append(AstralTheme.G_STAR if i == _step else AstralTheme.G_STAR2)
	_dots_lbl.text = "  ".join(dots)
	_prev_btn.disabled = (_step == 0)
	_next_btn.text = "✦ Comenzar campaña ▶" if _step == STEPS.size() - 1 else "Siguiente (%d/%d) ▶" % [_step + 1, STEPS.size()]

func _finish() -> void:
	AstralAudio.play_confirm()
	SettingsManager.mark_tutorial_completed()
	visible = false
	finished.emit()
