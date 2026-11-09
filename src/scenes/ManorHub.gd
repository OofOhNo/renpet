extends Control

## ManorHub.gd - Pantalla Principal Despejada ("Spacecore + Fantasy Astronomy + Ancient Egypt")
## Diseño limpio inspirado en Princess Maker 2 y Volcano Princess:
## Vista despejada del Observatorio y de Renpet por defecto, con menú lateral elegante
## y ventanas modales organizadas por pestañas para evitar saturación visual.

const RelationshipManagerScript = preload("res://src/core/RelationshipManager.gd")
var rel_mgr = RelationshipManagerScript.new()

var anim_time: float = 0.0

# Nodos animados del escenario principal (Observatorio y Renpet)
var tex_astrolabe_outer: TextureRect
var tex_astrolabe_inner: TextureRect
var tex_renpet_portrait: TextureRect
var tex_seal_medallion: TextureRect
var tex_vn_seal_icon: TextureRect
var portrait_base_y: float = 95.0

# HUD Superior Limpio
var lbl_date: Label
var lbl_era: Label
var lbl_gold: Label
var lbl_father_energy: Label
var lbl_stress: Label
var lbl_affection: Label

# Columna Izquierda Compacta (Resumen del Sello + 5 Botones de Menú)
var lbl_metaphysical_state: Label
var bar_human_anchor: ProgressBar
var bar_seal_integrity: ProgressBar
var bar_abyssal_sync: ProgressBar

# Ventana Central Flotante (Oculta por defecto para dejar ver el Observatorio y a Renpet)
var center_window_frame: PanelContainer
var active_window_title: Label
var panel_schedule: Control
var panel_status: Control
var panel_fireplace: Control
var panel_crucible: Control
var panel_town: Control

# Sub-pestañas dentro de cada ventana para evitar saturación
var schedule_tab_agenda: Control
var schedule_tab_father: Control
var status_tab_attrs: Control
var status_tab_constellations: Control
var status_tab_chronicle: Control
var home_tab_fireplace: Control
var home_tab_estate: Control

# Controles de Agenda (Ventana 1)
var block_selectors: Array[OptionButton] = []
var lbl_schedule_preview: RichTextLabel
var father_supervised_this_bimester: bool = false
var lbl_father_status_note: Label

# Controles de Ficha de Renpet y Códice (Ventana 2)
var bar_investigation: ProgressBar
var stats_bars_box: VBoxContainer
var lbl_traits: Label
var constellations_box: VBoxContainer
var letters_archive_box: HFlowContainer
var chronicle_list_box: VBoxContainer

# Controles de Chimenea y Mansión (Ventana 3)
var fireplace_topic_selector: OptionButton
var fireplace_topic_card_box: VBoxContainer
var lbl_diet_status: Label
var estate_buttons_box: VBoxContainer

# Controles de Crisol Astral (Ventana 4)
var bar_astral_saturation: ProgressBar
var crucible_box: VBoxContainer

# Controles de Ciudad y Vínculos (Ventana 5 - Selector de 1 Personaje a la vez)
var selected_town_tab: String = "soren"
var town_detail_box: VBoxContainer

# Caja de Diálogo Inferior estilo Visual Novel
var lbl_dialogue_speaker: Label
var lbl_dialogue_text: RichTextLabel

# Modales de Evento a Pantalla Completa
var prologue_overlay: Control
var input_daughter_name: LineEdit
var input_father_name: LineEdit

var execution_overlay: Control
var lbl_execution_title: Label
var lbl_execution_report: RichTextLabel

var letter_overlay: Control
var lbl_letter_title: Label
var lbl_letter_body: RichTextLabel

var bond_event_overlay: Control
var lbl_bond_event_title: Label
var lbl_bond_event_body: RichTextLabel
var bond_event_choices_box: VBoxContainer

func _ready() -> void:
	add_child(rel_mgr)
	_build_full_ui()
	_connect_signals()
	_refresh_all_ui()
	_update_schedule_preview()
	if TimeManager.current_total_turn == 1 and GameState.seal_investigation_progress == 0:
		prologue_overlay.visible = true

func _process(delta: float) -> void:
	anim_time += delta
	if tex_astrolabe_outer != null:
		tex_astrolabe_outer.rotation = anim_time * 0.14
	if tex_astrolabe_inner != null:
		tex_astrolabe_inner.rotation = -anim_time * 0.25
	if tex_renpet_portrait != null:
		tex_renpet_portrait.position.y = portrait_base_y + sin(anim_time * 1.8) * 5.5

func _connect_signals() -> void:
	TimeManager.turn_started.connect(_on_turn_started)
	TimeManager.year_completed.connect(_on_year_completed)
	GameState.stats_updated.connect(_refresh_all_ui)

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

# ==============================================================================
# CONSTRUCCIÓN DEL ESCENARIO VISUAL DESPEJADO
# ==============================================================================
func _build_full_ui() -> void:
	# 1. FONDO ILUSTRADO DEL OBSERVATORIO EGIPCIO-ASTRAL
	var bg_tex := TextureRect.new()
	bg_tex.texture = _load_tex("res://assets/art/bg_manor_observatory.png")
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_tex)
	
	var vignette := ColorRect.new()
	vignette.color = Color(0.02, 0.04, 0.10, 0.22)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	
	# 2. ESCENARIO DE RENPET Y SU ASTROLABIO ROTATORIO (GRANDE Y PROTAGONISTA)
	_build_daughter_stage()
	
	# 3. BARRA SUPERIOR LIMPIA
	_build_top_celestial_bar()
	
	# 4. COLUMNA IZQUIERDA DE MANDO (COMPACTA Y ORDENADA)
	_build_left_command_dock()
	
	# 5. VENTANA MODAL CENTRAL (OCULTA POR DEFECTO PARA NO SATURAR)
	_build_center_floating_window()
	
	# 6. CAJA DE DIÁLOGO INFERIOR ESTILO VISUAL NOVEL
	_build_bottom_vn_bar()
	
	# 7. MODALES CINEMÁTICOS
	_build_prologue_overlay()
	_build_execution_overlay()
	_build_letter_overlay()
	_build_bond_event_overlay()

func _build_daughter_stage() -> void:
	var stage_root := Control.new()
	stage_root.position = Vector2(1260, 75)
	stage_root.size = Vector2(620, 800)
	stage_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage_root)
	
	tex_astrolabe_outer = TextureRect.new()
	tex_astrolabe_outer.texture = _load_tex("res://assets/ui/astrolabe_ring_outer.png")
	tex_astrolabe_outer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_astrolabe_outer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_astrolabe_outer.size = Vector2(520, 520)
	tex_astrolabe_outer.position = Vector2(50, 40)
	tex_astrolabe_outer.pivot_offset = Vector2(260, 260)
	tex_astrolabe_outer.modulate = Color(1.0, 0.95, 0.8, 0.85)
	tex_astrolabe_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_root.add_child(tex_astrolabe_outer)
	
	tex_astrolabe_inner = TextureRect.new()
	tex_astrolabe_inner.texture = _load_tex("res://assets/ui/astrolabe_ring_inner.png")
	tex_astrolabe_inner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_astrolabe_inner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_astrolabe_inner.size = Vector2(370, 370)
	tex_astrolabe_inner.position = Vector2(125, 115)
	tex_astrolabe_inner.pivot_offset = Vector2(185, 185)
	tex_astrolabe_inner.modulate = Color(0.75, 0.95, 1.0, 0.90)
	tex_astrolabe_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_root.add_child(tex_astrolabe_inner)
	
	tex_renpet_portrait = TextureRect.new()
	tex_renpet_portrait.texture = _load_tex("res://assets/art/renpet_portrait.png")
	tex_renpet_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_renpet_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_renpet_portrait.size = Vector2(540, 690)
	tex_renpet_portrait.position = Vector2(40, portrait_base_y)
	tex_renpet_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_root.add_child(tex_renpet_portrait)
	
	var nameplate := _create_egyptian_panel(Color(0.05, 0.08, 0.19, 0.92), Color("#FFD54F"), 2, 14)
	nameplate.position = Vector2(70, 725)
	nameplate.size = Vector2(480, 54)
	stage_root.add_child(nameplate)
	
	lbl_metaphysical_state = _create_label("✦ Estrella Equilibrada", 15, Color("#FFE082"), true)
	lbl_metaphysical_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_metaphysical_state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nameplate.add_child(lbl_metaphysical_state)

func _build_top_celestial_bar() -> void:
	var top_bar := _create_egyptian_panel(Color(0.04, 0.07, 0.17, 0.92), Color("#D4AF37"), 2, 12)
	top_bar.position = Vector2(18, 12)
	top_bar.size = Vector2(1884, 60)
	add_child(top_bar)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	top_bar.add_child(hbox)
	
	lbl_date = _create_label("", 17, Color("#FFE082"), true)
	hbox.add_child(lbl_date)
	
	lbl_era = _create_label("", 13, Color("#80DEEA"), false)
	lbl_era.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl_era)
	
	lbl_gold = _create_stat_pill(hbox, "☀️ 850 G", Color("#FFD54F"))
	lbl_father_energy = _create_stat_pill(hbox, "☥ Padre: 100/100", Color("#80CBC4"))
	lbl_stress = _create_stat_pill(hbox, "🌙 Estrés: 15%", Color("#FF8A80"))
	lbl_affection = _create_stat_pill(hbox, "🪷 Afecto: 75%", Color("#F48FB1"))
	
	var btn_save := _create_gold_button("💾 Guardar", Color("#122238"), Color("#80DEEA"))
	btn_save.pressed.connect(_on_save_pressed)
	hbox.add_child(btn_save)
	
	var btn_load := _create_gold_button("📂 Cargar", Color("#1E1A36"), Color("#CE93D8"))
	btn_load.pressed.connect(_on_load_pressed)
	hbox.add_child(btn_load)

func _build_left_command_dock() -> void:
	var left_panel := _create_egyptian_panel(Color(0.05, 0.08, 0.20, 0.90), Color("#D4AF37"), 2, 16)
	left_panel.position = Vector2(18, 84)
	left_panel.size = Vector2(340, 788)
	add_child(left_panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	left_panel.add_child(vbox)
	
	# Medallón del Sello Estelar y las 3 barras nucleares
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(header_hbox)
	
	tex_seal_medallion = TextureRect.new()
	tex_seal_medallion.texture = _load_tex("res://assets/ui/seal_medallion_intact.png")
	tex_seal_medallion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_seal_medallion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_seal_medallion.custom_minimum_size = Vector2(64, 64)
	header_hbox.add_child(tex_seal_medallion)
	
	var title_v := VBoxContainer.new()
	title_v.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_child(title_v)
	title_v.add_child(_create_label("ESTADO DEL SELLO", 15, Color("#FFE082"), true))
	title_v.add_child(_create_label("Equilibrio Mortal / Astral", 12, Color("#80DEEA"), false))
	
	bar_human_anchor = _create_celestial_bar(vbox, "♥ Anclaje Humano", Color("#FFB74D"), 100)
	bar_seal_integrity = _create_celestial_bar(vbox, "☥ Integridad del Sello", Color("#26C6DA"), 100)
	bar_abyssal_sync = _create_celestial_bar(vbox, "✧ Sincronía con Zephyr", Color("#AB47BC"), 100)
	
	vbox.add_child(HSeparator.new())
	vbox.add_child(_create_label("𓇳 MENÚ DEL OBSERVATORIO", 14, Color("#FFE082"), true))
	
	var menu_items := [
		["schedule", "res://assets/ui/nav_schedule.png", "I. Planificar Bimestre", "Agenda de 60 días y tareas del Padre"],
		["status", "res://assets/ui/seal_medallion_intact.png", "II. Ficha de Renpet", "Atributos, Constelaciones y Cartas"],
		["fireplace", "res://assets/ui/nav_fireplace.png", "III. Chimenea y Hogar", "Charlas nocturnas, Dieta y Mansión"],
		["crucible", "res://assets/ui/nav_crucible.png", "IV. El Crisol Astral", "Asimilar reliquias y Alquimia"],
		["town", "res://assets/ui/nav_town.png", "V. Ciudad y Vínculos", "Visitar a los 6 Candidatos y Rivales"]
	]
	for item in menu_items:
		var m_btn := _create_menu_dock_button(item[1], item[2], item[3])
		m_btn.pressed.connect(_open_center_window.bind(item[0]))
		vbox.add_child(m_btn)
		
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn_clear := _create_gold_button("👁️ Ver Observatorio Despejado", Color("#102030"), Color("#80DEEA"))
	btn_clear.pressed.connect(_close_center_window)
	vbox.add_child(btn_clear)

func _build_center_floating_window() -> void:
	center_window_frame = _create_egyptian_panel(Color(0.05, 0.08, 0.21, 0.94), Color("#FFD54F"), 2, 16)
	center_window_frame.position = Vector2(376, 84)
	center_window_frame.size = Vector2(870, 788)
	center_window_frame.visible = false # Despejado por defecto para ver el Observatorio y a Renpet
	add_child(center_window_frame)
	
	var main_v := VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 10)
	center_window_frame.add_child(main_v)
	
	var header_panel := _create_egyptian_panel(Color(0.09, 0.13, 0.30, 0.98), Color("#D4AF37"), 1, 10)
	main_v.add_child(header_panel)
	
	var header_hbox := HBoxContainer.new()
	header_panel.add_child(header_hbox)
	
	active_window_title = _create_label("𓇳 AGENDA DEL BIMESTRE", 16, Color("#FFE082"), true)
	active_window_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(active_window_title)
	
	var btn_close_win := _create_gold_button("✕ Cerrar Ventana", Color("#3B141A"), Color("#FF8A80"))
	btn_close_win.pressed.connect(_close_center_window)
	header_hbox.add_child(btn_close_win)
	
	var content_holder := Control.new()
	content_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_v.add_child(content_holder)
	
	panel_schedule = _build_panel_schedule(content_holder)
	panel_status = _build_panel_status(content_holder)
	panel_fireplace = _build_panel_fireplace(content_holder)
	panel_crucible = _build_panel_crucible(content_holder)
	panel_town = _build_panel_town(content_holder)

func _build_bottom_vn_bar() -> void:
	var vn_panel := _create_egyptian_panel(Color(0.04, 0.07, 0.18, 0.94), Color("#FFD54F"), 2, 16)
	vn_panel.position = Vector2(18, 884)
	vn_panel.size = Vector2(1884, 180)
	add_child(vn_panel)
	
	var vn_hbox := HBoxContainer.new()
	vn_hbox.add_theme_constant_override("separation", 18)
	vn_panel.add_child(vn_hbox)
	
	tex_vn_seal_icon = TextureRect.new()
	tex_vn_seal_icon.texture = _load_tex("res://assets/ui/seal_medallion_intact.png")
	tex_vn_seal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_vn_seal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_vn_seal_icon.custom_minimum_size = Vector2(124, 124)
	vn_hbox.add_child(tex_vn_seal_icon)
	
	var vn_vbox := VBoxContainer.new()
	vn_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vn_vbox.add_theme_constant_override("separation", 6)
	vn_hbox.add_child(vn_vbox)
	
	var top_speaker_row := HBoxContainer.new()
	vn_vbox.add_child(top_speaker_row)
	
	lbl_dialogue_speaker = _create_label("✦ RENPET — OBSERVATORIO DE LA MANSIÓN SOLAR", 16, Color("#FFE082"), true)
	lbl_dialogue_speaker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_speaker_row.add_child(lbl_dialogue_speaker)
	
	var btn_talk_daughter := _create_gold_button("💬 Conversar con Renpet", Color("#163042"), Color("#80DEEA"))
	btn_talk_daughter.pressed.connect(_on_talk_to_renpet_pressed)
	top_speaker_row.add_child(btn_talk_daughter)
	
	var btn_quick_schedule := _create_gold_button("𓇳 Abrir Agenda del Bimestre", Color("#2B2112"), Color("#FFD54F"))
	btn_quick_schedule.pressed.connect(_open_center_window.bind("schedule"))
	top_speaker_row.add_child(btn_quick_schedule)
	
	lbl_dialogue_text = RichTextLabel.new()
	lbl_dialogue_text.bbcode_enabled = true
	lbl_dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_dialogue_text.add_theme_font_size_override("normal_font_size", 15)
	lbl_dialogue_text.add_theme_color_override("default_color", Color("#E8EAF6"))
	vn_vbox.add_child(lbl_dialogue_text)

func _open_center_window(win_id: String) -> void:
	center_window_frame.visible = true
	panel_schedule.visible = (win_id == "schedule")
	panel_status.visible = (win_id == "status")
	panel_fireplace.visible = (win_id == "fireplace")
	panel_crucible.visible = (win_id == "crucible")
	panel_town.visible = (win_id == "town")
	
	match win_id:
		"schedule":
			active_window_title.text = "𓇳 I. PLANIFICAR BIMESTRE (AGENDA DE 60 DÍAS Y ROL PATERNO)"
		"status":
			active_window_title.text = "📊 II. FICHA DE RENPET — ATRIBUTOS, CONSTELACIONES Y CRÓNICA"
		"fireplace":
			active_window_title.text = "🔥 III. CHIMENEA Y MANSIÓN SOLAR — CHARLAS, DIETA Y MEJORAS"
		"crucible":
			active_window_title.text = "⚗️ IV. EL CRISOL ASTRAL — MUTACIONES Y ALQUIMIA DE RELIQUIAS"
		"town":
			active_window_title.text = "🏛️ V. CIUDAD DE AETHELGARD — VÍNCULOS Y RIVALES"

func _close_center_window() -> void:
	center_window_frame.visible = false

func _on_talk_to_renpet_pressed() -> void:
	var lines: Array[String] = [
		GameState.get_dynamic_manor_greeting(),
		"\"Padre, estuve mirando la esfera armilar del techo... ¿Crees que algún día podremos viajar juntos más allá de las murallas de Aethelgard?\"",
		"\"Hoy repasé mis apuntes y traté de mantener el Sello en calma. Cuando estás cerca, siento que nada malo puede ocurrirme.\"",
		"\"A veces escucho el murmullo de Zephyr cuando cierro los ojos, pero tu voz siempre me guía de vuelta a casa.\""
	]
	_set_dialogue(GameState.daughter_name, lines[randi() % lines.size()])

# ==============================================================================
# VENTANA I: PLANIFICAR BIMESTRE (CON 2 SUB-PESTAÑAS LIMPIAS)
# ==============================================================================
func _build_panel_schedule(parent: Control) -> Control:
	var root_v := VBoxContainer.new()
	root_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_v.add_theme_constant_override("separation", 10)
	parent.add_child(root_v)
	
	# Barra de sub-pestañas
	var tabs_h := HBoxContainer.new()
	tabs_h.add_theme_constant_override("separation", 10)
	root_v.add_child(tabs_h)
	
	var b_tab1 := _create_gold_button("📅 1. Agenda de Renpet (3 Decanos)", Color("#1A365D"), Color("#FFD54F"))
	b_tab1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_tab1.pressed.connect(_switch_schedule_subtab.bind("agenda"))
	tabs_h.add_child(b_tab1)
	
	var b_tab2 := _create_gold_button("☥ 2. Tarea del Padre (Energía Paternal)", Color("#162C3D"), Color("#80CBC4"))
	b_tab2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_tab2.pressed.connect(_switch_schedule_subtab.bind("father"))
	tabs_h.add_child(b_tab2)
	
	# Sub-pestaña 1: Agenda de 60 días
	schedule_tab_agenda = VBoxContainer.new()
	schedule_tab_agenda.size_flags_vertical = Control.SIZE_EXPAND_FILL
	schedule_tab_agenda.add_theme_constant_override("separation", 12)
	root_v.add_child(schedule_tab_agenda)
	
	schedule_tab_agenda.add_child(_create_label("Elige las 3 actividades (20 días cada una) que realizará Renpet en este bimestre:", 14, Color("#B3E5FC"), false))
	
	block_selectors.clear()
	for i in range(3):
		var row_card := _create_egyptian_panel(Color(0.08, 0.12, 0.27, 0.92), Color("#D4AF37"), 1, 10)
		schedule_tab_agenda.add_child(row_card)
		var vbox_b := VBoxContainer.new()
		vbox_b.add_theme_constant_override("separation", 6)
		row_card.add_child(vbox_b)
		
		vbox_b.add_child(_create_label("✦ Decano %d (Días %d al %d):" % [i + 1, i * 20 + 1, (i + 1) * 20], 14, Color("#FFE082"), true))
		
		var opt := OptionButton.new()
		opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for idx in range(CatalogDB.ACTIVITIES.size()):
			var act: Dictionary = CatalogDB.ACTIVITIES[idx]
			var prefix: String = "[Clase] " if act["category"] == "class" else ("[Oficio] " if act["category"] == "job" else "[Reposo] ")
			var gold_tag: String = ("(%+d G)" % act["cost_or_wage"]) if act["cost_or_wage"] != 0 else "(Gratis)"
			opt.add_item("%s%s %s — %s" % [prefix, act["name"], gold_tag, act["desc"]], idx)
		opt.selected = i % 3
		opt.item_selected.connect(_on_schedule_selection_changed)
		vbox_b.add_child(opt)
		block_selectors.append(opt)
		
	var prev_card := _create_egyptian_panel(Color(0.04, 0.06, 0.15, 0.94), Color("#4DD0E1"), 1, 10)
	schedule_tab_agenda.add_child(prev_card)
	lbl_schedule_preview = RichTextLabel.new()
	lbl_schedule_preview.bbcode_enabled = true
	lbl_schedule_preview.custom_minimum_size = Vector2(0, 62)
	prev_card.add_child(lbl_schedule_preview)
	
	var btn_exec := _create_gold_button("𓇳 HACER GIRAR EL ASTROLABIO: EJECUTAR LOS 60 DÍAS 𓇳", Color("#1A3A5C"), Color("#FFD54F"))
	btn_exec.custom_minimum_size = Vector2(0, 52)
	btn_exec.pressed.connect(_execute_bimester_schedule)
	schedule_tab_agenda.add_child(btn_exec)
	
	# Sub-pestaña 2: Tarea del Padre
	schedule_tab_father = VBoxContainer.new()
	schedule_tab_father.size_flags_vertical = Control.SIZE_EXPAND_FILL
	schedule_tab_father.add_theme_constant_override("separation", 12)
	schedule_tab_father.visible = false
	root_v.add_child(schedule_tab_father)
	
	lbl_father_status_note = _create_label("", 14, Color("#80CBC4"), true)
	schedule_tab_father.add_child(lbl_father_status_note)
	
	var f_tasks := [
		["hero_work", "⚔️ Contrato de Antiguo Héroe (-60 Energía)", "Sales de expedición para traer +260 Oro a casa, aunque pasas menos tiempo con Renpet (-4 Afecto).", Color("#2D1E18"), Color("#FFB74D")],
		["supervise", "📖 Tutoría y Supervisión Personal (-40 Energía)", "Acompañas a Renpet en sus estudios y entrenamientos: +35% de eficacia en los 3 bloques y +6 Afecto.", Color("#142C3D"), Color("#4FC3F7")],
		["cook_home", "🍯 Banquete Hogareño y Descanso (-30 Energía)", "Cocinas sus platos favoritos y cuidan el jardín: -22 Estrés, +10 Anclaje Humano y +8 Afecto.", Color("#1B3326"), Color("#81C784")],
		["investigate", "🔍 Descifrar Códice del Sello (-50 Energía)", "Investigas en secreto los archivos del templo sobre la prisión de Nyx-Aethel: +15% Investigación y +18 Resonancia.", Color("#2A1B3D"), Color("#CE93D8")]
	]
	for ft in f_tasks:
		var fc := _create_egyptian_panel(Color(0.07, 0.10, 0.22, 0.92), ft[4], 1, 10)
		schedule_tab_father.add_child(fc)
		var fv := VBoxContainer.new()
		fv.add_theme_constant_override("separation", 6)
		fc.add_child(fv)
		fv.add_child(_create_label(ft[1], 15, ft[4], true))
		var fd := _create_label(ft[2], 13, Color("#E0E6ED"), false)
		fd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fv.add_child(fd)
		var fb := _create_gold_button("Realizar esta tarea paterna", ft[3], ft[4])
		fb.pressed.connect(_execute_father_task.bind(ft[0]))
		fv.add_child(fb)
		
	return root_v

func _switch_schedule_subtab(sub_id: String) -> void:
	schedule_tab_agenda.visible = (sub_id == "agenda")
	schedule_tab_father.visible = (sub_id == "father")

# ==============================================================================
# VENTANA II: FICHA DE RENPET — ATRIBUTOS, CONSTELACIONES Y CRÓNICA
# ==============================================================================
func _build_panel_status(parent: Control) -> Control:
	var root_v := VBoxContainer.new()
	root_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_v.add_theme_constant_override("separation", 10)
	parent.add_child(root_v)
	
	var tabs_h := HBoxContainer.new()
	tabs_h.add_theme_constant_override("separation", 8)
	root_v.add_child(tabs_h)
	
	var b_s1 := _create_gold_button("📊 1. Atributos y Rasgos", Color("#162840"), Color("#FFE082"))
	b_s1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_s1.pressed.connect(_switch_status_subtab.bind("attrs"))
	tabs_h.add_child(b_s1)
	
	var b_s2 := _create_gold_button("🌌 2. Mapa de Constelaciones", Color("#22183C"), Color("#CE93D8"))
	b_s2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_s2.pressed.connect(_switch_status_subtab.bind("constellations"))
	tabs_h.add_child(b_s2)
	
	var b_s3 := _create_gold_button("📜 3. Cartas Anuales y Crónica", Color("#163038"), Color("#80DEEA"))
	b_s3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_s3.pressed.connect(_switch_status_subtab.bind("chronicle"))
	tabs_h.add_child(b_s3)
	
	# Sub-pestaña 1: Atributos y Rasgos
	status_tab_attrs = VBoxContainer.new()
	status_tab_attrs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status_tab_attrs.add_theme_constant_override("separation", 10)
	root_v.add_child(status_tab_attrs)
	
	bar_investigation = _create_celestial_bar(status_tab_attrs, "🔍 Investigación Paterna sobre el Sello Estelar (Desbloquea Rutas del Acto III)", Color("#FFEE58"), 100)
	status_tab_attrs.add_child(HSeparator.new())
	status_tab_attrs.add_child(_create_label("ATRIBUTOS MORTALES Y CÓSMICOS DE RENPET (ESCALA 0 - 1200):", 14, Color("#FFE082"), true))
	
	stats_bars_box = VBoxContainer.new()
	stats_bars_box.add_theme_constant_override("separation", 8)
	status_tab_attrs.add_child(stats_bars_box)
	
	status_tab_attrs.add_child(HSeparator.new())
	status_tab_attrs.add_child(_create_label("PERSONALIDAD Y RASGOS PSICOLÓGICOS ACTIVOS:", 14, Color("#80CBC4"), true))
	var traits_card := _create_egyptian_panel(Color(0.06, 0.09, 0.20, 0.90), Color("#80CBC4"), 1, 10)
	status_tab_attrs.add_child(traits_card)
	lbl_traits = _create_label("", 13, Color("#FFF59D"), false)
	lbl_traits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	traits_card.add_child(lbl_traits)
	
	# Sub-pestaña 2: Constelaciones
	var scroll_c := ScrollContainer.new()
	scroll_c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_c.visible = false
	root_v.add_child(scroll_c)
	status_tab_constellations = scroll_c
	
	constellations_box = VBoxContainer.new()
	constellations_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	constellations_box.add_theme_constant_override("separation", 8)
	scroll_c.add_child(constellations_box)
	
	# Sub-pestaña 3: Crónica y Cartas Anuales
	var scroll_ch := ScrollContainer.new()
	scroll_ch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_ch.visible = false
	root_v.add_child(scroll_ch)
	status_tab_chronicle = scroll_ch
	
	var ch_vbox := VBoxContainer.new()
	ch_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ch_vbox.add_theme_constant_override("separation", 10)
	scroll_ch.add_child(ch_vbox)
	
	ch_vbox.add_child(_create_label("📜 CARTAS MANUSCRITAS DE SOLSTICIO (1 POR AÑO COMPLETADO):", 14, Color("#FFE082"), true))
	letters_archive_box = HFlowContainer.new()
	letters_archive_box.add_theme_constant_override("h_separation", 8)
	letters_archive_box.add_theme_constant_override("v_separation", 8)
	ch_vbox.add_child(letters_archive_box)
	
	ch_vbox.add_child(HSeparator.new())
	ch_vbox.add_child(_create_label("☥ MEMORIA EPISÓDICA DE RENPET (HITOS RECIENTES):", 14, Color("#80DEEA"), true))
	chronicle_list_box = VBoxContainer.new()
	chronicle_list_box.add_theme_constant_override("separation", 6)
	ch_vbox.add_child(chronicle_list_box)
	
	return root_v

func _switch_status_subtab(sub_id: String) -> void:
	status_tab_attrs.visible = (sub_id == "attrs")
	status_tab_constellations.visible = (sub_id == "constellations")
	status_tab_chronicle.visible = (sub_id == "chronicle")

# ==============================================================================
# VENTANA III: CHIMENEA Y MANSIÓN (CON 2 SUB-PESTAÑAS LIMPIAS)
# ==============================================================================
func _build_panel_fireplace(parent: Control) -> Control:
	var root_v := VBoxContainer.new()
	root_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_v.add_theme_constant_override("separation", 10)
	parent.add_child(root_v)
	
	var tabs_h := HBoxContainer.new()
	tabs_h.add_theme_constant_override("separation", 10)
	root_v.add_child(tabs_h)
	
	var b_h1 := _create_gold_button("🔥 1. Charla Nocturna en la Chimenea", Color("#2D1928"), Color("#FFB74D"))
	b_h1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_h1.pressed.connect(_switch_home_subtab.bind("fireplace"))
	tabs_h.add_child(b_h1)
	
	var b_h2 := _create_gold_button("🪷 2. Dieta Familiar y Mejoras de la Mansión", Color("#152A38"), Color("#80DEEA"))
	b_h2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_h2.pressed.connect(_switch_home_subtab.bind("estate"))
	tabs_h.add_child(b_h2)
	
	# Sub-pestaña 1: Chimenea con selector de 1 tema a la vez
	home_tab_fireplace = VBoxContainer.new()
	home_tab_fireplace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	home_tab_fireplace.add_theme_constant_override("separation", 12)
	root_v.add_child(home_tab_fireplace)
	
	home_tab_fireplace.add_child(_create_label("Selecciona el tema sobre el que deseas conversar con Renpet junto al fuego (1 vez por bimestre):", 13, Color("#FFE082"), false))
	
	fireplace_topic_selector = OptionButton.new()
	var topics: Array[Dictionary] = Chronicle.get_fireplace_topics()
	for idx in range(topics.size()):
		fireplace_topic_selector.add_item("🔥 " + str(topics[idx]["title"]), idx)
	fireplace_topic_selector.item_selected.connect(_on_fireplace_topic_selected)
	home_tab_fireplace.add_child(fireplace_topic_selector)
	
	fireplace_topic_card_box = VBoxContainer.new()
	fireplace_topic_card_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fireplace_topic_card_box.add_theme_constant_override("separation", 10)
	home_tab_fireplace.add_child(fireplace_topic_card_box)
	_refresh_selected_fireplace_topic(0)
	
	# Sub-pestaña 2: Dieta y Mejoras de la Finca Solar
	home_tab_estate = VBoxContainer.new()
	home_tab_estate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	home_tab_estate.add_theme_constant_override("separation", 12)
	home_tab_estate.visible = false
	root_v.add_child(home_tab_estate)
	
	home_tab_estate.add_child(_create_label("🪷 RÉGIMEN ALIMENTICIO DE LA CASA (SE APLICA CADA BIMESTRE):", 14, Color("#FFE082"), true))
	lbl_diet_status = _create_label("", 13, Color("#80DEEA"), false)
	home_tab_estate.add_child(lbl_diet_status)
	
	var diets := [
		[GameState.DietPlan.AUSTERE, "🌾 Dieta Austera (30 G/bimestre — Ahorro económico, +4 Estrés)"],
		[GameState.DietPlan.BALANCED, "🍯 Mesa Casera del Héroe (80 G/bimestre — Equilibrada: -5 Estrés, +2 Anclaje Humano)"],
		[GameState.DietPlan.ROYAL_FEAST, "🍷 Banquete Real de Corte (180 G/bimestre — -14 Estrés, +8 Gracia, +5 Temple)"],
		[GameState.DietPlan.ASTRAL_PURGE, "🪷 Infusión de Lirio Estelar (150 G/bimestre — Purifica -15% Saturación y +2% Sello)"]
	]
	for d in diets:
		var bd := _create_gold_button(d[1], Color("#152A38"), Color("#80DEEA"))
		bd.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bd.pressed.connect(_on_diet_selected.bind(d[0], d[1]))
		home_tab_estate.add_child(bd)
		
	home_tab_estate.add_child(HSeparator.new())
	home_tab_estate.add_child(_create_label("🏛️ AMPLIACIONES DE LA MANSIÓN SOLAR (300 ORO POR NIVEL):", 14, Color("#FFB74D"), true))
	estate_buttons_box = VBoxContainer.new()
	estate_buttons_box.add_theme_constant_override("separation", 8)
	home_tab_estate.add_child(estate_buttons_box)
	
	return root_v

func _switch_home_subtab(sub_id: String) -> void:
	home_tab_fireplace.visible = (sub_id == "fireplace")
	home_tab_estate.visible = (sub_id == "estate")

func _on_fireplace_topic_selected(idx: int) -> void:
	_refresh_selected_fireplace_topic(idx)

func _refresh_selected_fireplace_topic(idx: int) -> void:
	if fireplace_topic_card_box == null:
		return
	for ch in fireplace_topic_card_box.get_children():
		ch.queue_free()
	var topics: Array[Dictionary] = Chronicle.get_fireplace_topics()
	if idx < 0 or idx >= topics.size():
		return
	var topic: Dictionary = topics[idx]
	
	var t_card := _create_egyptian_panel(Color(0.11, 0.08, 0.18, 0.94), Color("#FFB74D"), 1, 12)
	fireplace_topic_card_box.add_child(t_card)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 10)
	t_card.add_child(tv)
	
	tv.add_child(_create_label("🔥 " + str(topic["title"]), 16, Color("#FFE082"), true))
	var p_lbl := _create_label(str(topic["prompt"]), 14, Color("#FFF8E1"), false)
	p_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(p_lbl)
	tv.add_child(HSeparator.new())
	tv.add_child(_create_label("Elige tu postura como Padre:", 13, Color("#80DEEA"), true))
	
	var stances: Array = topic["stances"]
	for st in stances:
		var st_dict: Dictionary = st
		var btn_txt: String = "✦ [%s] — %s" % [str(st_dict["stance"]), str(st_dict["father_line"])]
		var sb := _create_gold_button(btn_txt, Color("#241934"), Color("#FFD54F"))
		sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sb.pressed.connect(_on_fireplace_stance_chosen.bind(topic, st_dict))
		tv.add_child(sb)

# ==============================================================================
# VENTANA IV: EL CRISOL ASTRAL — RELIQUIAS Y ALQUIMIA
# ==============================================================================
func _build_panel_crucible(parent: Control) -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(scroll)
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)
	
	bar_astral_saturation = _create_celestial_bar(vbox, "✨ Saturación Astral del Cuerpo Mortal (0% a 100%)", Color("#BA68C8"), 100)
	
	var alch_hbox := HBoxContainer.new()
	alch_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(alch_hbox)
	
	var btn_transmute := _create_gold_button("✨ Destilar Reliquia Aleatoria (-120 G)", Color("#2A1842"), Color("#E1BEE7"))
	btn_transmute.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_transmute.pressed.connect(_on_transmute_relic)
	alch_hbox.add_child(btn_transmute)
	
	var btn_purify := _create_gold_button("🪷 Purificar Saturación (-80 G -> -25% Sat., +3% Sello)", Color("#143338"), Color("#80CBC4"))
	btn_purify.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_purify.pressed.connect(_on_purify_saturation)
	alch_hbox.add_child(btn_purify)
	
	vbox.add_child(HSeparator.new())
	vbox.add_child(_create_label("⚗️ RELIQUIAS CÓSMICAS DISPONIBLES PARA ASIMILAR:", 14, Color("#FFE082"), true))
	
	crucible_box = VBoxContainer.new()
	crucible_box.add_theme_constant_override("separation", 8)
	vbox.add_child(crucible_box)
	return scroll

# ==============================================================================
# VENTANA V: CIUDAD DE AETHELGARD (SELECTOR DE 1 PERSONAJE A LA VEZ)
# ==============================================================================
func _build_panel_town(parent: Control) -> Control:
	var root_v := VBoxContainer.new()
	root_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_v.add_theme_constant_override("separation", 10)
	parent.add_child(root_v)
	
	root_v.add_child(_create_label("Selecciona a quién visitar hoy en la Capital de Aethelgard:", 13, Color("#B3E5FC"), false))
	
	var selector_row := HFlowContainer.new()
	selector_row.add_theme_constant_override("h_separation", 8)
	selector_row.add_theme_constant_override("v_separation", 8)
	root_v.add_child(selector_row)
	
	var tabs := [
		["soren", "🔭 Soren"],
		["vespera", "❄️ Vespera"],
		["kaelen", "🗡️ Kaelen"],
		["cassian", "☀️ Cassian"],
		["mirari", "🎵 Mirari"],
		["zephyr", "🌌 Zephyr"],
		["rivals", "⚔️ Rivales de Academia"]
	]
	for t in tabs:
		var bt := _create_gold_button(t[1], Color("#162440"), Color("#FFD54F"))
		bt.pressed.connect(_on_select_town_tab.bind(t[0]))
		selector_row.add_child(bt)
		
	root_v.add_child(HSeparator.new())
	
	town_detail_box = VBoxContainer.new()
	town_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	town_detail_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	town_detail_box.add_theme_constant_override("separation", 10)
	root_v.add_child(town_detail_box)
	
	return root_v

func _on_select_town_tab(tab_id: String) -> void:
	selected_town_tab = tab_id
	_refresh_town_candidates()

func _refresh_town_candidates() -> void:
	if town_detail_box == null:
		return
	for ch in town_detail_box.get_children():
		ch.queue_free()
		
	if selected_town_tab == "rivals":
		var r_card := _create_egyptian_panel(Color(0.10, 0.08, 0.20, 0.94), Color("#FFB74D"), 1, 12)
		town_detail_box.add_child(r_card)
		var rv := VBoxContainer.new()
		rv.add_theme_constant_override("separation", 12)
		r_card.add_child(rv)
		rv.add_child(_create_label("⚔️ CLASIFICACIÓN DE RIVALES EN ESPEJO (ACADEMIA REAL)", 16, Color("#FFE082"), true))
		rv.add_child(_create_label("Tus rivales entrenan cada bimestre en paralelo a Renpet. Rétalos para medir tu progreso y ganar Oro y Magnetismo:", 13, Color("#E0E6ED"), false))
		
		for riv_id in ["vespera", "soren", "lyra", "caelum"]:
			var r_data: Dictionary = rel_mgr.rivals_mirror[riv_id]
			var my_sc: int = rel_mgr.get_renpet_domain_score(riv_id)
			var riv_sc: int = int(r_data["score"])
			var row_p := _create_egyptian_panel(Color(0.06, 0.09, 0.20, 0.90), Color("#D4AF37"), 1, 8)
			rv.add_child(row_p)
			var rh := HBoxContainer.new()
			row_p.add_child(rh)
			var col_r: Color = Color("#81C784") if my_sc >= riv_sc else Color("#FFCC80")
			var r_lbl := _create_label("%s — %s\nTu Puntaje: %d pts   |   Puntaje Rival: %d pts" % [
				r_data["name"], r_data["domain"], my_sc, riv_sc
			], 13, col_r, true)
			r_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rh.add_child(r_lbl)
			var b_duel := _create_gold_button("⚔️ Retar a Duelo de Prestigio", Color("#3B1922"), Color("#FFB74D"))
			b_duel.pressed.connect(_on_challenge_rival.bind(riv_id))
			rh.add_child(b_duel)
		return
		
	# Mostrar ficha individual limpia del candidato seleccionado
	var npc_id: String = selected_town_tab
	if not rel_mgr.candidates.has(npc_id):
		npc_id = "soren"
	var c: Dictionary = rel_mgr.candidates[npc_id]
	
	var card := _create_egyptian_panel(Color(0.07, 0.10, 0.24, 0.95), Color("#FFD54F"), 2, 14)
	town_detail_box.add_child(card)
	
	var vbox_c := VBoxContainer.new()
	vbox_c.add_theme_constant_override("separation", 14)
	card.add_child(vbox_c)
	
	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 18)
	vbox_c.add_child(top_h)
	
	var med := TextureRect.new()
	med.texture = _load_tex("res://assets/ui/npc_%s.png" % npc_id)
	med.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	med.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	med.custom_minimum_size = Vector2(130, 130)
	top_h.add_child(med)
	
	var bio_v := VBoxContainer.new()
	bio_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bio_v.add_theme_constant_override("separation", 6)
	top_h.add_child(bio_v)
	
	var status_str: String = rel_mgr.get_relationship_status_title(npc_id)
	bio_v.add_child(_create_label("%s — %s" % [c["name"], c["title"]], 18, Color("#FFE082"), true))
	bio_v.add_child(_create_label("Estado del Vínculo: %s   |   📍 %s" % [status_str, c["location"]], 13, Color("#80DEEA"), true))
	
	var bio_lbl := _create_label(str(c["bio"]), 13, Color("#E0E6ED"), false)
	bio_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bio_v.add_child(bio_lbl)
	bio_v.add_child(_create_label("✦ " + str(c["perk_desc"]), 12, Color("#FFF59D"), false))
	
	vbox_c.add_child(HSeparator.new())
	vbox_c.add_child(_create_label("MATRIZ TRIDIMENSIONAL DE RELACIÓN (AMOR / AMISTAD / NÉMESIS):", 13, Color("#FFE082"), true))
	
	var bars_v := VBoxContainer.new()
	bars_v.add_theme_constant_override("separation", 8)
	vbox_c.add_child(bars_v)
	_add_full_3d_bar(bars_v, "🤝 Afecto y Confianza (-100 a +100)", int(c["affection"]), -100, 100, Color("#4DD0E1") if int(c["affection"]) >= 0 else Color("#EF5350"))
	_add_full_3d_bar(bars_v, "👑 Respeto y Admiración (-100 a +100)", int(c["respect"]), -100, 100, Color("#FFD54F"))
	_add_full_3d_bar(bars_v, "♥ Chispa Romántica (0 a 100)", int(c["spark"]), 0, 100, Color("#F48FB1"))
	
	vbox_c.add_child(HSeparator.new())
	vbox_c.add_child(_create_label("ACCIONES SOCIALES EN LA CAPITAL (1 SALIDA POR BIMESTRE):", 13, Color("#80CBC4"), true))
	
	var btn_grid := GridContainer.new()
	btn_grid.columns = 2
	btn_grid.add_theme_constant_override("h_separation", 10)
	btn_grid.add_theme_constant_override("v_separation", 10)
	vbox_c.add_child(btn_grid)
	
	var b_sup := _create_gold_button("🤝 Apoyar y Conversar (+Afecto, +Respeto)", Color("#163038"), Color("#4DD0E1"))
	b_sup.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_sup.pressed.connect(_on_npc_interact.bind(npc_id, "support"))
	btn_grid.add_child(b_sup)
	
	var b_rom := _create_gold_button("♥ Cita Romántica (+Chispa, +Afecto, -Estrés)", Color("#3A1830"), Color("#F48FB1"))
	b_rom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_rom.pressed.connect(_on_npc_interact.bind(npc_id, "romance"))
	btn_grid.add_child(b_rom)
	
	var b_gift := _create_gold_button("🎁 Entregar Regalo Especial (-75 G -> ++Afecto)", Color("#2E2614"), Color("#FFD54F"))
	b_gift.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_gift.pressed.connect(_on_npc_interact.bind(npc_id, "gift"))
	btn_grid.add_child(b_gift)
	
	var b_prov := _create_gold_button("⚔️ Provocar Rivalidad / Némesis (-Afecto, +Entropía)", Color("#3B141A"), Color("#EF5350"))
	b_prov.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_prov.pressed.connect(_on_npc_interact.bind(npc_id, "provoke"))
	btn_grid.add_child(b_prov)
	
	var b_scene := _create_gold_button("✦ VIVIR ESCENA DE HISTORIA CON %s (ACTO %d) ✦" % [c["name"].to_upper(), int(c["stage"])], Color("#2B1A42"), Color("#FFF176"))
	b_scene.custom_minimum_size = Vector2(0, 44)
	b_scene.pressed.connect(_open_bond_event_modal.bind(npc_id))
	vbox_c.add_child(b_scene)

func _add_full_3d_bar(parent: VBoxContainer, label_txt: String, val: int, min_v: int, max_v: int, col: Color) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	parent.add_child(hb)
	var l := _create_label("%s: %+d" % [label_txt, val], 12, col, true)
	l.custom_minimum_size = Vector2(270, 0)
	hb.add_child(l)
	var pb := ProgressBar.new()
	pb.min_value = min_v
	pb.max_value = max_v
	pb.value = val
	pb.show_percentage = false
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.custom_minimum_size = Vector2(0, 16)
	var sbf := StyleBoxFlat.new()
	sbf.bg_color = col
	sbf.set_corner_radius_all(5)
	pb.add_theme_stylebox_override("fill", sbf)
	hb.add_child(pb)

# ==============================================================================
# LÓGICA DE INTERACCIONES, GUARDADO Y ACTUALIZACIÓN
# ==============================================================================
func _on_npc_interact(npc_id: String, action_type: String) -> void:
	var res: Dictionary = rel_mgr.interact_with_candidate(npc_id, action_type)
	if not res.get("ok", false):
		_set_dialogue("Capital de Aethelgard", res.get("msg", ""))
		return
	_set_dialogue(res["speaker"], "%s\n[color=#81C784][%s][/color]" % [res["reply"], res["effects"]])
	_refresh_all_ui()

func _on_challenge_rival(rival_id: String) -> void:
	var res: Dictionary = rel_mgr.challenge_rival_duel(rival_id)
	if not res.get("ok", false):
		_set_dialogue("Academia Real", res.get("msg", ""))
		return
	_set_dialogue(res["speaker"], "%s\n[color=#FFD54F][%s][/color]" % [res["reply"], res["effects"]])
	_refresh_all_ui()

func _open_bond_event_modal(npc_id: String) -> void:
	var c: Dictionary = rel_mgr.candidates.get(npc_id, {})
	if c.is_empty():
		return
	var ev: Dictionary = c["bond_event"]
	lbl_bond_event_title.text = "✦ %s — %s ✦" % [c["name"], ev["title"]]
	lbl_bond_event_body.text = ev["narrative"]
	for ch in bond_event_choices_box.get_children():
		ch.queue_free()
	var choices: Array = ev["choices"]
	for idx in range(choices.size()):
		var ch_data: Dictionary = choices[idx]
		var b_ch := _create_gold_button(ch_data["label"], Color("#1A2642"), Color("#FFE082"))
		b_ch.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b_ch.pressed.connect(_on_bond_event_choice_selected.bind(npc_id, idx))
		bond_event_choices_box.add_child(b_ch)
	bond_event_overlay.visible = true

func _on_bond_event_choice_selected(npc_id: String, choice_idx: int) -> void:
	var res: Dictionary = rel_mgr.apply_bond_event_choice(npc_id, choice_idx)
	bond_event_overlay.visible = false
	if res.get("ok", false):
		_set_dialogue(res["speaker"], "%s\n[color=#81C784][%s][/color]" % [res["outcome"], res["effects"]])
	_refresh_all_ui()

func _on_save_pressed() -> void:
	var extra := {
		"candidates": rel_mgr.candidates,
		"rivals_mirror": rel_mgr.rivals_mirror
	}
	if SaveManager.save_game(1, extra):
		_set_dialogue("Escriba del Templo", "Crónica guardada correctamente en el Papiro Real (Ranura 1).")

func _on_load_pressed() -> void:
	var loaded: Dictionary = SaveManager.load_game(1)
	if loaded.get("ok", false):
		var extra: Dictionary = loaded.get("extra", {})
		if extra.has("candidates") and typeof(extra["candidates"]) == TYPE_DICTIONARY:
			for k in extra["candidates"].keys():
				if rel_mgr.candidates.has(k):
					var saved_c: Dictionary = extra["candidates"][k]
					rel_mgr.candidates[k]["affection"] = int(saved_c.get("affection", 0))
					rel_mgr.candidates[k]["respect"] = int(saved_c.get("respect", 0))
					rel_mgr.candidates[k]["spark"] = int(saved_c.get("spark", 0))
					rel_mgr.candidates[k]["stage"] = int(saved_c.get("stage", 1))
		_refresh_all_ui()
		_set_dialogue("Escriba del Templo", "Crónica restaurada desde el Papiro Real.")

func _on_schedule_selection_changed(_idx: int) -> void:
	_update_schedule_preview()

func _update_schedule_preview() -> void:
	if block_selectors.size() < 3 or lbl_schedule_preview == null:
		return
	var total_gold: int = 0
	var total_stress: int = 0
	var names: Array[String] = []
	for i in range(3):
		var act: Dictionary = CatalogDB.ACTIVITIES[block_selectors[i].selected]
		total_gold += int(act["cost_or_wage"])
		total_stress += int(act["stress"])
		names.append("[b]D%d:[/b] %s" % [i + 1, act["name"]])
	var sup: String = " [color=#81C784](+35% Supervisión Paterna Activa)[/color]" if father_supervised_this_bimester else ""
	lbl_schedule_preview.text = "%s\n[color=#FFD54F]Balance de Actividades: %+d G[/color]   |   [color=#FF8A80]Estrés Estimado: %+d[/color]%s" % [
		"  •  ".join(names), total_gold, total_stress, sup
	]

func _execute_father_task(task_id: String) -> void:
	match task_id:
		"hero_work":
			if GameState.father_energy < 60:
				_set_dialogue("Energía Paternal", "Requiere 60 de Energía Paternal.")
				return
			GameState.father_energy -= 60
			GameState.modify_gold(260)
			GameState.modify_stat("affection", -4)
			TimeManager.father_times_worked_away_this_year += 1
			_set_dialogue("Hazaña del Guardián", "Saliste de expedición como antiguo Héroe (+260 G). Renpet te esperó mirando las estrellas (-4 Afecto).")
		"supervise":
			if GameState.father_energy < 40:
				_set_dialogue("Energía Paternal", "Requiere 40 de Energía Paternal.")
				return
			GameState.father_energy -= 40
			father_supervised_this_bimester = true
			GameState.modify_stat("affection", 6)
			TimeManager.father_times_stayed_home_this_year += 1
			_update_schedule_preview()
			_set_dialogue("Maestro y Padre", "Guiarás personalmente a %s durante los 60 días (+35%% eficacia en los 3 bloques)." % GameState.daughter_name)
		"cook_home":
			if GameState.father_energy < 30:
				_set_dialogue("Energía Paternal", "Requiere 30 de Energía Paternal.")
				return
			GameState.father_energy -= 30
			GameState.modify_stat("stress", -22)
			GameState.modify_stat("human_anchor", 10)
			GameState.modify_stat("affection", 8)
			TimeManager.father_times_stayed_home_this_year += 1
			_set_dialogue("Calor del Brasero", "Preparaste pan de miel y dátiles junto a %s (-22 Estrés, +10 Anclaje Humano)." % GameState.daughter_name)
		"investigate":
			if GameState.father_energy < 50:
				_set_dialogue("Energía Paternal", "Requiere 50 de Energía Paternal.")
				return
			GameState.father_energy -= 50
			GameState.modify_stat("seal_investigation", 15)
			GameState.modify_stat("resonancia", 18)
			_set_dialogue("Cámara de los Relojes Rotos", "Descifraste un cartucho prohibido sobre la prisión de Nyx-Aethel (+15% Investigación del Sello).")
	_refresh_all_ui()

func _execute_bimester_schedule() -> void:
	var req_gold: int = 0
	for i in range(3):
		var act: Dictionary = CatalogDB.ACTIVITIES[block_selectors[i].selected]
		if act["cost_or_wage"] < 0:
			req_gold += abs(int(act["cost_or_wage"]))
	if GameState.gold < req_gold:
		_set_dialogue("Tesorería", "Necesitas %d G para costear estas lecciones y tienes %d G." % [req_gold, GameState.gold])
		return
		
	var report_lines: Array[String] = []
	var b_info: Dictionary = TimeManager.get_bimester_info()
	report_lines.append("[color=#FFE082][b]CRÓNICA DEL ASTROLABIO: %s (Año %d)[/b][/color]\n" % [b_info["name"], TimeManager.current_year])
	
	var sup_mult: float = 1.35 if father_supervised_this_bimester else 1.0
	var is_high_tide: bool = (TimeManager.current_bimester == 3)
	
	for i in range(3):
		var act: Dictionary = CatalogDB.ACTIVITIES[block_selectors[i].selected]
		var cost_wage: int = int(act["cost_or_wage"])
		GameState.modify_gold(cost_wage)
		GameState.modify_stat("stress", int(act["stress"]))
		if act.get("seal_delta", 0) != 0:
			GameState.modify_stat("seal_integrity", int(act["seal_delta"]))
			
		var fac_key: String = act.get("facility_bonus", "")
		var fac_bonus: int = (GameState.estate_levels.get(fac_key, 1) - 1) * 4 if fac_key != "" else 0
		
		var gains: Array[String] = []
		var s_dict: Dictionary = act["stats"]
		for sk in s_dict.keys():
			var final_v: int = int(round((int(s_dict[sk]) + fac_bonus) * sup_mult))
			if is_high_tide and (sk == "luminiscencia" or sk == "gravedad" or sk == "resonancia"):
				final_v = int(round(final_v * 1.25))
			GameState.modify_stat(sk, final_v)
			gains.append("%s %+d" % [sk.capitalize(), final_v])
			
		report_lines.append("[color=#80DEEA][b]• Decano %d (%s):[/b][/color] [color=#81C784]%s[/color] | Oro %+d G" % [
			i + 1, act["name"], ", ".join(gains), cost_wage
		])
		if i == 1 and act.get("rival_id", "") != "":
			report_lines.append("   [color=#FFD54F]★ Encuentro con Rival:[/color] " + _trigger_rival_clash(act["rival_id"], act["name"]))
			
	var new_syns: Array[Dictionary] = CatalogDB.check_and_unlock_synergies()
	for syn in new_syns:
		report_lines.append("\n[color=#FFF176][b]★ CONSTELACIÓN DESPERTADA: %s[/b][/color]" % syn["title"])
		
	father_supervised_this_bimester = false
	Chronicle.chatted_this_bimester = false
	rel_mgr.interacted_this_bimester = false
	rel_mgr.rival_challenged_this_bimester = false
	rel_mgr.advance_rivals_mirror()
	
	var prev_year: int = TimeManager.current_year
	TimeManager.advance_bimester()
	_on_save_pressed()
	_refresh_all_ui()
	_update_schedule_preview()
	
	if TimeManager.current_year == prev_year:
		lbl_execution_title.text = "✦ Giro del Astrolabio Completado (60 Días) ✦"
		lbl_execution_report.text = "\n".join(report_lines)
		execution_overlay.visible = true

func _trigger_rival_clash(rival_id: String, act_name: String) -> String:
	match rival_id:
		"vespera":
			GameState.modify_stat("destreza", 8)
			return "Dama Vespera cruzó lanzas con %s en %s (+8 Destreza)." % [GameState.daughter_name, act_name]
		"soren":
			GameState.modify_stat("erudicion", 8)
			return "Soren debatió cálculos estelares con %s (+8 Erudición)." % GameState.daughter_name
		"lyra":
			GameState.modify_stat("gracia", 8)
			return "Lady Lyra compitió en elegancia contra %s (+8 Gracia)." % GameState.daughter_name
		"caelum":
			GameState.modify_stat("temple", 8)
			return "Caelum disputó la ruta de caza con %s (+8 Temple)." % GameState.daughter_name
	return "Progreso destacado."

func _on_fireplace_stance_chosen(topic: Dictionary, stance_data: Dictionary) -> void:
	if Chronicle.chatted_this_bimester:
		_set_dialogue("Altar del Fuego", "Ya has conversado junto al brasero sagrado este bimestre. Espera al siguiente turno.")
		return
	Chronicle.chatted_this_bimester = true
	var effects: Dictionary = stance_data["effects"]
	var eff_arr: Array[String] = []
	for k in effects.keys():
		GameState.modify_stat(k, int(effects[k]))
		eff_arr.append("%s %+d" % [str(k).capitalize(), int(effects[k])])
	Chronicle.record_event("fireplace_" + str(topic["id"]), "Charla en el Brasero: " + str(topic["title"]), str(stance_data["daughter_reply"]), "family", 3)
	_set_dialogue("Consejo en el Brasero", "[color=#80DEEA][b]%s:[/b] %s[/color]\n[color=#FFE082][b]%s:[/b] %s[/color]  [color=#81C784](%s)[/color]" % [
		GameState.father_name, stance_data["father_line"], GameState.daughter_name, stance_data["daughter_reply"], ", ".join(eff_arr)
	])
	_refresh_all_ui()

func _on_diet_selected(plan: GameState.DietPlan, label_text: String) -> void:
	GameState.current_diet = plan
	_refresh_all_ui()
	_set_dialogue("Mesa de la Mansión", "Régimen familiar establecido en: " + label_text)

func _upgrade_facility(fac_key: String, label_desc: String) -> void:
	var cur_lvl: int = GameState.estate_levels.get(fac_key, 1)
	if cur_lvl >= 5 or not GameState.modify_gold(-300):
		_set_dialogue("Arquitecto Real", "Se requieren 300 G (o la estancia ya está en Nivel máximo 5).")
		return
	GameState.estate_levels[fac_key] = cur_lvl + 1
	_set_dialogue("Obras Sagradas", "¡%s ascendió a Nivel %d!" % [label_desc, cur_lvl + 1])
	_refresh_all_ui()

func _refresh_estate_upgrade_buttons() -> void:
	if estate_buttons_box == null:
		return
	for ch in estate_buttons_box.get_children():
		ch.queue_free()
	var facs := [
		["library", "📚 Bóveda Estelar y Biblioteca", "Bonifica clases de Astrolabio y Erudición (+4 por nivel)."],
		["armory", "⚔️ Patio de Lanzas Solares", "Bonifica Academia de Armas y Escolta (+4 por nivel)."],
		["conservatory", "🪷 Salón de Lotos y Música", "Reduce Estrés pasivamente cada bimestre (-3 por nivel) y bonifica Conservatorio."],
		["crucible", "⚗️ Cámara del Crisol Astral", "Bonifica Taller de Relojería y estabiliza la forja."]
	]
	for f in facs:
		var lvl: int = GameState.estate_levels.get(f[0], 1)
		var row_p := _create_egyptian_panel(Color(0.06, 0.09, 0.20, 0.90), Color("#D4AF37"), 1, 8)
		estate_buttons_box.add_child(row_p)
		var hb := HBoxContainer.new()
		row_p.add_child(hb)
		var lb := _create_label("%s  [Nivel %d/5]\n%s" % [f[1], lvl, f[2]], 12, Color("#E0E6ED"), false)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(lb)
		var b_up := _create_gold_button("Mejorar (300 G)" if lvl < 5 else "Nivel Máximo", Color("#2C2016"), Color("#FFB74D"))
		b_up.disabled = (lvl >= 5)
		b_up.pressed.connect(_upgrade_facility.bind(f[0], f[1]))
		hb.add_child(b_up)

func _refresh_constellations_map() -> void:
	if constellations_box == null:
		return
	for ch in constellations_box.get_children():
		ch.queue_free()
		
	for syn in CatalogDB.PRESTIGE_SYNERGIES:
		var syn_id: String = syn["id"]
		var is_unlocked: bool = GameState.unlocked_synergies.has(syn_id)
		var val_a: int = int(GameState.get(syn["stat_a"]))
		var val_b: int = int(GameState.get(syn["stat_b"]))
		var req_a: int = int(syn["req_a"])
		var req_b: int = int(syn["req_b"])
		
		var border_c: Color = Color("#FFD54F") if is_unlocked else Color("#546E7A")
		var bg_c: Color = Color(0.14, 0.12, 0.28, 0.94) if is_unlocked else Color(0.06, 0.09, 0.18, 0.85)
		var card := _create_egyptian_panel(bg_c, border_c, 1, 8)
		constellations_box.add_child(card)
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		card.add_child(hbox)
		
		var status_badge: String = "✦ DESPERTADA ✦" if is_unlocked else "✧ Latente"
		var badge_col: Color = Color("#FFF176") if is_unlocked else Color("#90A4AE")
		var title_lbl := _create_label("%s  [%s]" % [syn["title"], status_badge], 13, badge_col, true)
		title_lbl.custom_minimum_size = Vector2(260, 0)
		hbox.add_child(title_lbl)
		
		var req_lbl := _create_label("Requisitos: %s %d/%d  |  %s %d/%d\nEfecto: %s" % [
			str(syn["stat_a"]).capitalize(), val_a, req_a,
			str(syn["stat_b"]).capitalize(), val_b, req_b,
			syn["bonus_desc"]
		], 11, Color("#E0E6ED"), false)
		req_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(req_lbl)

func _refresh_chronicle_archives() -> void:
	if letters_archive_box != null:
		for ch in letters_archive_box.get_children():
			ch.queue_free()
		if Chronicle.letters_archive.is_empty():
			letters_archive_box.add_child(_create_label("Aún no se ha completado el primer Solsticio de Invierno (Bimestre 6).", 12, Color("#B0BEC5"), false))
		else:
			for idx in range(Chronicle.letters_archive.size()):
				var let_dict: Dictionary = Chronicle.letters_archive[idx]
				var b_let := _create_gold_button("📜 Leer: " + str(let_dict["title"]), Color("#2E2118"), Color("#FFE082"))
				b_let.pressed.connect(_open_archived_letter.bind(idx))
				letters_archive_box.add_child(b_let)
				
	if chronicle_list_box != null:
		for ch in chronicle_list_box.get_children():
			ch.queue_free()
		var max_items: int = mini(8, Chronicle.events_ledger.size())
		for i in range(max_items):
			var ev: Dictionary = Chronicle.events_ledger[i]
			var row_p := _create_egyptian_panel(Color(0.06, 0.09, 0.20, 0.88), Color("#4FC3F7"), 1, 8)
			chronicle_list_box.add_child(row_p)
			var summary_txt: String = str(ev.get("summary", ev.get("description", "")))
			var l := _create_label("✦ [Año %d, Bim %d] %s — %s" % [
				int(ev.get("year", 12)), int(ev.get("bimester", 1)), str(ev.get("title", "")), summary_txt
			], 12, Color("#E0F7FA"), false)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row_p.add_child(l)

func _open_archived_letter(idx: int) -> void:
	if idx < 0 or idx >= Chronicle.letters_archive.size():
		return
	var letter: Dictionary = Chronicle.letters_archive[idx]
	lbl_letter_title.text = "✦ " + str(letter["title"]) + " ✦"
	lbl_letter_body.text = str(letter["content"])
	letter_overlay.visible = true

func _refresh_crucible_buttons() -> void:
	if crucible_box == null:
		return
	for ch in crucible_box.get_children():
		ch.queue_free()
	for item in CatalogDB.COSMIC_MATERIALS:
		var count: int = GameState.materials_inventory.get(item["id"], 0)
		var card_m := _create_egyptian_panel(Color(0.07, 0.09, 0.22, 0.90), Color("#BA68C8"), 1, 8)
		crucible_box.add_child(card_m)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card_m.add_child(row)
		var l := _create_label("✦ %s (En inventario: %d)\n%s" % [item["name"], count, item["desc"]], 12, Color("#E1BEE7"), false)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var b_buy := _create_gold_button("Comprar (%dG)" % item["price"], Color("#162838"), Color("#4FC3F7"))
		b_buy.pressed.connect(_on_buy_material.bind(item))
		row.add_child(b_buy)
		var b_fuse := _create_gold_button("Asimilar", Color("#311B47"), Color("#BA68C8"))
		b_fuse.disabled = (count <= 0)
		b_fuse.pressed.connect(_on_assimilate_material.bind(item))
		row.add_child(b_fuse)

func _on_buy_material(item: Dictionary) -> void:
	if GameState.modify_gold(-int(item["price"])):
		var id_s: String = item["id"]
		GameState.materials_inventory[id_s] = GameState.materials_inventory.get(id_s, 0) + 1
		_refresh_all_ui()

func _on_assimilate_material(item: Dictionary) -> void:
	var id_s: String = item["id"]
	var cnt: int = GameState.materials_inventory.get(id_s, 0)
	if cnt <= 0:
		return
	GameState.materials_inventory[id_s] = cnt - 1
	var mult: float = 1.30 if GameState.unlocked_synergies.has("eclipse_sovereign") else 1.0
	var s_dict: Dictionary = item["stats"]
	for sk in s_dict.keys():
		var delta_v: int = int(round(int(s_dict[sk]) * mult))
		GameState.modify_stat(sk, delta_v)
	GameState.astral_saturation = clampi(GameState.astral_saturation + 18, 0, 100)
	if not GameState.active_mutations.has(item["mutation"]):
		GameState.active_mutations.append(item["mutation"])
	Chronicle.record_event("crucible_" + id_s, "Asimilación en el Crisol: " + str(item["name"]), "Renpet despertó la mutación %s." % item["mutation"], "cosmic", 4)
	_set_dialogue("Horno de Fusión Astral", "¡%s asimiló [b]%s[/b]! Mutación despertada: [color=#FFD54F]%s[/color] (Saturación %d%%)." % [
		GameState.daughter_name, item["name"], item["mutation"], GameState.astral_saturation
	])
	_refresh_all_ui()

func _on_transmute_relic() -> void:
	var cost: int = 90 if GameState.unlocked_synergies.has("solar_artificer") else 120
	if not GameState.modify_gold(-cost):
		_set_dialogue("Crisol Astral", "Necesitas %d G para destilar una reliquia en el Horno Astral." % cost)
		return
	var rand_idx: int = randi() % CatalogDB.COSMIC_MATERIALS.size()
	var item: Dictionary = CatalogDB.COSMIC_MATERIALS[rand_idx]
	var id_s: String = item["id"]
	GameState.materials_inventory[id_s] = GameState.materials_inventory.get(id_s, 0) + 1
	GameState.modify_stat("resonancia", 8)
	_set_dialogue("Alquimia de Transmutación", "¡Condensaste la luz de la esfera armilar y obtuviste [color=#FFD54F]%s[/color] (+8 Resonancia)!" % item["name"])
	_refresh_all_ui()

func _on_purify_saturation() -> void:
	if not GameState.modify_gold(-80):
		_set_dialogue("Crisol Astral", "Necesitas 80 G en sales de loto para purificar la Saturación Astral.")
		return
	GameState.astral_saturation = clampi(GameState.astral_saturation - 25, 0, 100)
	GameState.modify_stat("seal_integrity", 3)
	GameState.modify_stat("stress", -10)
	_set_dialogue("Purificación de Loto", "El baño de vapor de alabastro redujo -25% la Saturación Astral, restauró +3% del Sello y alivió -10 de Estrés.")
	_refresh_all_ui()

func _on_turn_started(_year: int, _bimester: int, _total_turn: int) -> void:
	_set_dialogue(GameState.daughter_name, GameState.get_dynamic_manor_greeting())

func _on_year_completed(completed_year: int) -> void:
	var letter: Dictionary = Chronicle.assemble_annual_letter(completed_year)
	lbl_letter_title.text = "✦ " + letter["title"] + " ✦"
	lbl_letter_body.text = letter["content"]
	letter_overlay.visible = true
	_refresh_all_ui()

# ==============================================================================
# MODALES ILUSTRADOS (PRÓLOGO, EJECUCIÓN, CARTA ANUAL Y EVENTO DE VÍNCULO)
# ==============================================================================
func _build_prologue_overlay() -> void:
	prologue_overlay = Control.new()
	prologue_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prologue_overlay.visible = false
	add_child(prologue_overlay)
	
	var bg_p := TextureRect.new()
	bg_p.texture = _load_tex("res://assets/art/bg_prologue_goddess.png")
	bg_p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prologue_overlay.add_child(bg_p)
	
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.10, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prologue_overlay.add_child(dim)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prologue_overlay.add_child(center)
	
	var card := _create_egyptian_panel(Color(0.05, 0.08, 0.18, 0.92), Color("#FFD54F"), 3, 18)
	card.custom_minimum_size = Vector2(920, 560)
	center.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)
	
	vbox.add_child(_create_label("𓇳 PRÓLOGO: EL REGALO DE LA SEÑORA DE LA ETERNIDAD 𓇳", 21, Color("#FFE082"), true))
	var lore_lbl := _create_label(
		"Hace doce años quebraste las cadenas del templo donde la Diosa Renpet-Neheh, Señora del Tiempo, estuvo cautiva por siglos. En gratitud, la Diosa desprendió una estrella blanca del firmamento, le dio forma de niña humana y la puso en tus brazos.\n\n" +
		"Pero aquella estrella guardaba un secreto milenario: no era un lucero común, sino el Sarcófago Celestial donde la Diosa encerró a Nyx-Aethel, el espíritu primordial del cambio. Ahora que tu hija cumple 12 años en tu observatorio de Aethelgard, el sello en su pecho comienza a latir...",
		14, Color("#E0E6ED"), false
	)
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lore_lbl)
	vbox.add_child(HSeparator.new())
	
	var names_hbox := HBoxContainer.new()
	names_hbox.add_theme_constant_override("separation", 18)
	vbox.add_child(names_hbox)
	names_hbox.add_child(_create_label("Nombre de la Niña Estrella:", 14, Color("#FFE082"), true))
	input_daughter_name = LineEdit.new()
	input_daughter_name.text = "Renpet"
	input_daughter_name.custom_minimum_size = Vector2(180, 0)
	names_hbox.add_child(input_daughter_name)
	
	names_hbox.add_child(_create_label("Nombre del Héroe (Padre):", 14, Color("#80DEEA"), true))
	input_father_name = LineEdit.new()
	input_father_name.text = "Aurelius"
	input_father_name.custom_minimum_size = Vector2(180, 0)
	names_hbox.add_child(input_father_name)
	
	vbox.add_child(_create_label("☥ Elige tu Leyenda Heroica al Liberar a la Diosa:", 15, Color("#80CBC4"), true))
	var archs := [
		[GameState.HeroArchetype.MARTIAL, "⚔️ I. El Filo del Vértice (Marcial: +30 Temple, +25 Destreza, Mandoble Solar)"],
		[GameState.HeroArchetype.SCHOLAR, "📜 II. El Archimago del Velo (Sabio: +35 Erudición, +25 Resonancia, +10% Investigación)"],
		[GameState.HeroArchetype.ROGUE, "🌙 III. El Infiltrador del Silencio (Sombras: +400 Oro, +20 Destreza, +20 Magnetismo)"],
		[GameState.HeroArchetype.DEVOUT, "🪷 IV. El Custodio del Altar (Devoto: +15 Anclaje Humano, +20 Devoción, -10 Estrés)"]
	]
	for a in archs:
		var ba := _create_gold_button(a[1], Color("#162440"), Color("#FFD54F"))
		ba.pressed.connect(_on_archetype_chosen.bind(a[0]))
		vbox.add_child(ba)

func _on_archetype_chosen(arch: GameState.HeroArchetype) -> void:
	var dn: String = input_daughter_name.text.strip_edges()
	var fn: String = input_father_name.text.strip_edges()
	GameState.daughter_name = dn if dn != "" else "Renpet"
	GameState.father_name = fn if fn != "" else "Aurelius"
	GameState.apply_archetype_bonuses(arch)
	prologue_overlay.visible = false
	_refresh_all_ui()
	_set_dialogue(GameState.daughter_name, GameState.get_dynamic_manor_greeting())

func _build_execution_overlay() -> void:
	execution_overlay = ColorRect.new()
	(execution_overlay as ColorRect).color = Color(0.02, 0.04, 0.10, 0.88)
	execution_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	execution_overlay.visible = false
	add_child(execution_overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	execution_overlay.add_child(center)
	
	var card := _create_egyptian_panel(Color(0.06, 0.10, 0.22, 0.96), Color("#FFD54F"), 3, 16)
	card.custom_minimum_size = Vector2(780, 460)
	center.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)
	lbl_execution_title = _create_label("", 19, Color("#FFE082"), true)
	vbox.add_child(lbl_execution_title)
	lbl_execution_report = RichTextLabel.new()
	lbl_execution_report.bbcode_enabled = true
	lbl_execution_report.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_execution_report.add_theme_font_size_override("normal_font_size", 14)
	vbox.add_child(lbl_execution_report)
	var b_ok := _create_gold_button("✦ Continuar al Siguiente Bimestre ✦", Color("#1A365D"), Color("#FFD54F"))
	b_ok.pressed.connect(_close_execution_overlay)
	vbox.add_child(b_ok)

func _close_execution_overlay() -> void:
	execution_overlay.visible = false
	_set_dialogue(GameState.daughter_name, GameState.get_dynamic_manor_greeting())

func _build_letter_overlay() -> void:
	letter_overlay = ColorRect.new()
	(letter_overlay as ColorRect).color = Color(0.02, 0.03, 0.08, 0.92)
	letter_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	letter_overlay.visible = false
	add_child(letter_overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	letter_overlay.add_child(center)
	
	var card := _create_egyptian_panel(Color("#221912"), Color("#FFD54F"), 3, 16)
	card.custom_minimum_size = Vector2(740, 470)
	center.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)
	lbl_letter_title = _create_label("", 19, Color("#FFE082"), true)
	vbox.add_child(lbl_letter_title)
	lbl_letter_body = RichTextLabel.new()
	lbl_letter_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_letter_body.add_theme_font_size_override("normal_font_size", 15)
	lbl_letter_body.add_theme_color_override("default_color", Color("#F5EEDB"))
	vbox.add_child(lbl_letter_body)
	var b_close := _create_gold_button("Guardar Papiro en el Escritorio del Padre", Color("#3E2723"), Color("#FFD54F"))
	b_close.pressed.connect(_close_letter_overlay)
	vbox.add_child(b_close)

func _close_letter_overlay() -> void:
	letter_overlay.visible = false

func _build_bond_event_overlay() -> void:
	bond_event_overlay = ColorRect.new()
	(bond_event_overlay as ColorRect).color = Color(0.02, 0.04, 0.12, 0.90)
	bond_event_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bond_event_overlay.visible = false
	add_child(bond_event_overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bond_event_overlay.add_child(center)
	
	var card := _create_egyptian_panel(Color(0.07, 0.09, 0.22, 0.96), Color("#FFD54F"), 3, 18)
	card.custom_minimum_size = Vector2(820, 490)
	center.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)
	
	lbl_bond_event_title = _create_label("", 19, Color("#FFE082"), true)
	vbox.add_child(lbl_bond_event_title)
	
	lbl_bond_event_body = RichTextLabel.new()
	lbl_bond_event_body.bbcode_enabled = true
	lbl_bond_event_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_bond_event_body.add_theme_font_size_override("normal_font_size", 15)
	lbl_bond_event_body.add_theme_color_override("default_color", Color("#E8EAF6"))
	vbox.add_child(lbl_bond_event_body)
	
	vbox.add_child(HSeparator.new())
	vbox.add_child(_create_label("Elige la reacción de Renpet en este encuentro:", 13, Color("#80DEEA"), true))
	bond_event_choices_box = VBoxContainer.new()
	bond_event_choices_box.add_theme_constant_override("separation", 8)
	vbox.add_child(bond_event_choices_box)

# ==============================================================================
# REFRESCO GENERAL Y CONSTRUCTOR DE COMPONENTES EGIPCIO-ASTRALES
# ==============================================================================
func _refresh_all_ui() -> void:
	var b_info: Dictionary = TimeManager.get_bimester_info()
	lbl_date.text = "𓇳 Año %d (Edad %d) — %s  [Turno %d/48]" % [
		TimeManager.current_year, GameState.age, b_info["name"], TimeManager.current_total_turn
	]
	lbl_era.text = "%s   •   %s" % [TimeManager.get_era_title(), b_info["phenomenon"]]
	
	lbl_gold.text = "☀️ %d G" % GameState.gold
	lbl_father_energy.text = "☥ Padre: %d/100" % GameState.father_energy
	lbl_stress.text = "🌙 Estrés: %d%%" % GameState.stress
	lbl_affection.text = "🪷 Afecto: %d%%" % GameState.affection
	
	bar_human_anchor.value = GameState.human_anchor
	bar_seal_integrity.value = GameState.seal_integrity
	bar_abyssal_sync.value = GameState.abyssal_sync
	if bar_investigation:
		bar_investigation.value = GameState.seal_investigation_progress
	lbl_metaphysical_state.text = GameState.get_metaphysical_state_title()
	
	if lbl_father_status_note:
		lbl_father_status_note.text = "☥ Energía Paternal Disponible este Bimestre: %d / 100   |   Leyenda: %s" % [
			GameState.father_energy, GameState.get_archetype_title()
		]
		
	var seal_tex_path: String = "res://assets/ui/seal_medallion_intact.png" if GameState.seal_integrity >= 55 else "res://assets/ui/seal_medallion_cracked.png"
	var stex: Texture2D = _load_tex(seal_tex_path)
	if tex_seal_medallion:
		tex_seal_medallion.texture = stex
	if tex_vn_seal_icon:
		tex_vn_seal_icon.texture = stex
		
	if stats_bars_box:
		for ch in stats_bars_box.get_children():
			ch.queue_free()
		var attrs := [
			["⚔️ Temple (Vigor y Salud)", GameState.temple, Color("#81C784")],
			["🏹 Destreza (Agilidad y Técnica)", GameState.destreza, Color("#4FC3F7")],
			["📜 Erudición (Ciencia y Lógica)", GameState.erudicion, Color("#64B5F6")],
			["🪷 Gracia (Elegancia y Arte)", GameState.gracia, Color("#F48FB1")],
			["👑 Magnetismo (Carisma y Liderazgo)", GameState.magnetismo, Color("#FFD54F")],
			["✨ Luminiscencia (Magia de Luz)", GameState.luminiscencia, Color("#FFF176")],
			["🪐 Gravedad (Poder de Impacto)", GameState.gravedad, Color("#FFB74D")],
			["⏳ Resonancia (Pulso del Tiempo)", GameState.resonancia, Color("#BA68C8")]
		]
		for a in attrs:
			_add_attribute_bar_row(stats_bars_box, a[0], a[1], a[2])
			
	if lbl_traits:
		var syn_text: String = ("\n★ Constelaciones Despertadas: " + ", ".join(GameState.unlocked_synergies)) if not GameState.unlocked_synergies.is_empty() else ""
		lbl_traits.text = "• " + "\n• ".join(GameState.active_traits) + syn_text
		
	if lbl_diet_status:
		var d_names := ["Dieta Austera (30G)", "Mesa Casera del Héroe (80G)", "Banquete Real de Corte (180G)", "Infusión de Lirio Estelar (150G)"]
		lbl_diet_status.text = "Régimen Actual: %s   |   Mutaciones Etéricas: %s" % [
			d_names[int(GameState.current_diet)],
			(", ".join(GameState.active_mutations) if not GameState.active_mutations.is_empty() else "Ninguna")
		]
	if bar_astral_saturation:
		bar_astral_saturation.value = GameState.astral_saturation
		
	_refresh_estate_upgrade_buttons()
	_refresh_constellations_map()
	_refresh_crucible_buttons()
	_refresh_town_candidates()
	_refresh_chronicle_archives()

func _add_attribute_bar_row(parent: VBoxContainer, label_name: String, val: int, col: Color) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	parent.add_child(h)
	var l := _create_label(label_name, 13, Color("#E0E6ED"), false)
	l.custom_minimum_size = Vector2(235, 0)
	h.add_child(l)
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = 1200
	pb.value = val
	pb.show_percentage = false
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.custom_minimum_size = Vector2(0, 16)
	var sbf := StyleBoxFlat.new()
	sbf.bg_color = col
	sbf.set_corner_radius_all(5)
	pb.add_theme_stylebox_override("fill", sbf)
	h.add_child(pb)
	var lv := _create_label(str(val), 13, col, true)
	lv.custom_minimum_size = Vector2(52, 0)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(lv)

func _create_menu_dock_button(tex_path: String, title_txt: String, sub_txt: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 68)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.26, 0.94)
	sb.border_color = Color("#D4AF37")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.15, 0.22, 0.42, 0.98)
	sbh.border_color = Color("#FFF176")
	b.add_theme_stylebox_override("hover", sbh)
	
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	
	var tr := TextureRect.new()
	tr.texture = _load_tex(tex_path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(54, 58)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tr)
	
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(vb)
	
	var lt := _create_label(title_txt, 14, Color("#FFE082"), true)
	lt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(lt)
	
	var ls := _create_label(sub_txt, 11, Color("#B0BEC5"), false)
	ls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(ls)
	return b

func _create_stat_pill(parent: HBoxContainer, prefix: String, col: Color) -> Label:
	var pc := _create_egyptian_panel(Color(0.08, 0.12, 0.26, 0.92), col, 1, 16)
	parent.add_child(pc)
	var l := _create_label(prefix, 14, col, true)
	pc.add_child(l)
	return l

func _set_dialogue(speaker: String, text: String) -> void:
	lbl_dialogue_speaker.text = "✦ " + speaker.to_upper()
	lbl_dialogue_text.text = text

func _create_egyptian_panel(bg_col: Color, border_col: Color, border_w: int, radius: int) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	pc.add_theme_stylebox_override("panel", sb)
	return pc

func _create_label(txt: String, fsize: int, col: Color, bold: bool) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	if bold:
		l.add_theme_constant_override("outline_size", 2)
		l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08, 0.9))
	return l

func _create_gold_button(txt: String, bg_col: Color, border_col: Color) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color("#FFF8E1"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = bg_col.lightened(0.20)
	sbh.border_color = Color("#FFE082")
	b.add_theme_stylebox_override("hover", sbh)
	return b

func _create_celestial_bar(parent: VBoxContainer, title: String, fill_col: Color, max_v: int) -> ProgressBar:
	var l := _create_label(title, 11, Color("#CFD8DC"), false)
	parent.add_child(l)
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = max_v
	pb.custom_minimum_size = Vector2(0, 15)
	var sbf := StyleBoxFlat.new()
	sbf.bg_color = fill_col
	sbf.set_corner_radius_all(5)
	pb.add_theme_stylebox_override("fill", sbf)
	parent.add_child(pb)
	return pb
