extends Control

## ManorHub - Observatorio de la Mansión Solar (centro de mando de las Fases 3 a 6).
## Solo orquesta la interfaz: toda la lógica de juego vive en los autoloads (TurnExecutor, CrucibleManager,
## RelationshipManager, RivalMirror...). El diseño usa contenedores y anclas, así que se adapta a cualquier
## proporción de ventana (16:9, 16:10, 21:9...).

const NAV_ITEMS: Array[Dictionary] = [
	{"id": "schedule", "title": "I. Planificar Bimestre", "sub": "Agenda de 60 días y tareas del Padre", "icon": "res://assets/ui/nav_schedule.png", "key": KEY_1},
	{"id": "status", "title": "II. Ficha de Renpet", "sub": "Atributos, rasgos y cartas", "icon": "res://assets/ui/seal_medallion_intact.png", "key": KEY_2},
	{"id": "hearth", "title": "III. Chimenea y Hogar", "sub": "Charlas, dieta y mansión", "icon": "res://assets/ui/nav_fireplace.png", "key": KEY_3},
	{"id": "crucible", "title": "IV. El Crisol Astral", "sub": "Asimilar reliquias y alquimia", "icon": "res://assets/ui/nav_crucible.png", "key": KEY_4},
	{"id": "town", "title": "V. Ciudad y Vínculos", "sub": "Candidatos y rivales", "icon": "res://assets/ui/nav_town.png", "key": KEY_5},
	{"id": "explore", "title": "VI. Expedición y Festival", "sub": "Regiones, combate y certámenes", "icon": "res://assets/ui/nav_expedition.png", "key": KEY_6}
]

# --- Nodos de interfaz ---
var _ui_root: Control
var _lbl_date: Label
var _lbl_era: Label
var _pill_gold: Label
var _pill_energy: Label
var _pill_stress: Label
var _pill_affection: Label
var _bar_anchor: StatBar
var _bar_seal: StatBar
var _bar_sync: StatBar
var _lbl_seal_heading: Label
var _lbl_seal_title: Label
var _dock_medallion: TextureRect
var _nav_buttons: Dictionary = {}
var _center: Control
var _windows: Dictionary = {}
var _current_window: String = ""
var _stage: Control
var _ring_outer: TextureRect
var _ring_inner: TextureRect
var _portrait: TextureRect
var _nameplate: Label
var _portrait_base_y: float = 0.0
var _lbl_speaker: Label
var _lbl_dialogue: RichTextLabel
var _dlg_medallion: TextureRect
var _typing: Tween
var _toast_box: VBoxContainer
var _show_ui_btn: Button
var _anim_time: float = 0.0

# --- Overlays ---
var _prologue: PrologueOverlay
var _report: TurnReportOverlay
var _letter: LetterOverlay
var _bond: BondEventOverlay
var _combat: CombatOverlay
var _story: StoryEventOverlay
var _menu: MenuOverlay
var _ending: EndingOverlay

var _refresh_queued: bool = false
var _busy: bool = false   # evita doble ejecución del turno

func _ready() -> void:
	theme = AstralTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_layout()
	_build_overlays()

	GameState.stats_updated.connect(_queue_refresh)
	GameState.gold_changed.connect(func(_g: int) -> void: _queue_refresh())
	GameState.seal_state_changed.connect(func(_a: int, _b: int, _c: int) -> void: _queue_refresh())
	TurnExecutor.plan_changed.connect(_queue_refresh)

	_start_session()

func _process(delta: float) -> void:
	_anim_time += delta
	if _ring_outer != null:
		_ring_outer.rotation = _anim_time * 0.14
		_ring_inner.rotation = -_anim_time * 0.25
		_portrait.position.y = _portrait_base_y + sin(_anim_time * 1.8) * 5.0

# ------------------------------------------------------------------------------
# INICIO DE SESIÓN: nueva partida o carga desde el título
# ------------------------------------------------------------------------------
func _start_session() -> void:
	var slot: int = SaveManager.pending_load_slot
	SaveManager.pending_load_slot = -1
	if slot >= 0:
		var res: Dictionary = SaveManager.load_game(slot)
		if res.get("ok", false):
			_refresh_all()
			if not GameState.prologue_completed:
				_prologue.begin()
			else:
				say("%s — Mansión Solar" % GameState.daughter_name, GameState.get_dynamic_manor_greeting())
				toast("Partida cargada", "good")
			return
		toast(str(res.get("msg", "No se pudo cargar.")), "bad")
	SaveManager.new_game()
	_refresh_all()
	say("Observatorio de la Mansión Solar", "…")
	_prologue.begin()

func _on_prologue_finished(daughter: String, father: String, archetype: int) -> void:
	GameState.daughter_name = daughter
	GameState.father_name = father
	GameState.apply_archetype_bonuses(archetype as GameState.HeroArchetype)
	var ng_boons: Array[String] = ConstellationTapestry.apply_active_boons_to_new_game()
	GameState.prologue_completed = true
	Chronicle.record_event("hero_created", "El Héroe elige su leyenda", "%s se presentó como %s." % [father, GameState.get_archetype_title()], "lore", 4)
	if not ng_boons.is_empty():
		Chronicle.record_event("ng_plus_boons", "Bendiciones del Tapiz", "Ventajas heredadas activadas: %s." % ", ".join(ng_boons), "lore", 4)
	SaveManager.autosave()
	_refresh_all()
	say("%s — Mansión Solar" % GameState.daughter_name, GameState.get_dynamic_manor_greeting())
	toast("Comienza la crónica de %s%s" % [daughter, " (NG+)" if not ng_boons.is_empty() else ""], "good")

# ------------------------------------------------------------------------------
# CONSTRUCCIÓN DE LA INTERFAZ
# ------------------------------------------------------------------------------
func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/bg_manor_observatory.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Velo de lapislázuli + viñeta para que el texto siempre se lea
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.1, 0.38)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(0.01, 0.02, 0.08, 0.7))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.95)
	var vignette := TextureRect.new()
	vignette.texture = gt
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	add_child(StarField.new())

func _build_layout() -> void:
	_ui_root = MarginContainer.new()
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.add_theme_constant_override("margin_left", 22)
	_ui_root.add_theme_constant_override("margin_right", 22)
	_ui_root.add_theme_constant_override("margin_top", 16)
	_ui_root.add_theme_constant_override("margin_bottom", 16)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui_root)
	var v := AstralTheme.vbox(14)
	_ui_root.add_child(v)

	v.add_child(_build_top_bar())
	var mid := AstralTheme.hbox(16)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(mid)
	mid.add_child(_build_dock())

	_center = Control.new()
	_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(_center)
	_build_windows()

	_stage = _build_stage()
	mid.add_child(_stage)
	v.add_child(_build_dialogue_bar())

	_show_ui_btn = AstralTheme.button(AstralTheme.G_STAR + "  Mostrar interfaz", "PrimaryButton")
	_show_ui_btn.visible = false
	_show_ui_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	_show_ui_btn.pressed.connect(func() -> void: _set_ui_visible(true))
	add_child(_show_ui_btn)

func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.theme_type_variation = "BarPanel"
	var h := AstralTheme.hbox(14)
	bar.add_child(h)
	var left := AstralTheme.vbox(0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(left)
	_lbl_date = AstralTheme.label("", "HeadingLabel")
	left.add_child(_lbl_date)
	_lbl_era = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ)
	_lbl_era.clip_text = true
	left.add_child(_lbl_era)

	_pill_gold = _make_pill(h, AstralTheme.GOLD, "Oro de la casa")
	_pill_energy = _make_pill(h, AstralTheme.TURQ, "Energía Paternal: puntos libres este bimestre para las tareas del Padre")
	_pill_stress = _make_pill(h, AstralTheme.BAD, str(AstralTheme.STAT_TOOLTIPS["stress"]))
	_pill_affection = _make_pill(h, AstralTheme.ROSE, str(AstralTheme.STAT_TOOLTIPS["affection"]))
	var menu_btn := AstralTheme.button(AstralTheme.G_ORNAMENT + "  Menú", "", "Menú del observatorio (Esc)")
	menu_btn.custom_minimum_size = Vector2(120, 46)
	menu_btn.pressed.connect(func() -> void: _menu.open_pause(GameState.prologue_completed))
	h.add_child(menu_btn)
	return bar

func _make_pill(parent: Control, color: Color, tip: String) -> Label:
	var p := PanelContainer.new()
	p.theme_type_variation = "PillPanel"
	p.tooltip_text = tip
	var l := AstralTheme.label("0", "", color)
	l.custom_minimum_size.x = 150
	l.add_theme_font_size_override("font_size", 21)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(l)
	parent.add_child(p)
	return l

func _build_dock() -> Control:
	var dock := PanelContainer.new()
	dock.theme_type_variation = "BarPanel"
	dock.custom_minimum_size.x = 380
	var v := AstralTheme.vbox(6)
	dock.add_child(v)

	var head := AstralTheme.hbox(12)
	v.add_child(head)
	_dock_medallion = TextureRect.new()
	_dock_medallion.custom_minimum_size = Vector2(64, 64)
	_dock_medallion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dock_medallion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(_dock_medallion)
	var hv := AstralTheme.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	_lbl_seal_heading = AstralTheme.label("ESTADO DE LA MARCA", "HeadingLabel")
	hv.add_child(_lbl_seal_heading)
	_lbl_seal_title = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ, true)
	hv.add_child(_lbl_seal_title)

	_bar_anchor = StatBar.new().setup(GameState.get_stat_label("human_anchor"), "human_anchor", 0, 100, AstralTheme.STAT_COLORS["human_anchor"], str(AstralTheme.STAT_TOOLTIPS["human_anchor"]), 138)
	_bar_seal = StatBar.new().setup(GameState.get_stat_label("seal_integrity"), "seal_integrity", 0, 100, AstralTheme.STAT_COLORS["seal_integrity"], str(AstralTheme.STAT_TOOLTIPS["seal_integrity"]), 138)
	_bar_sync = StatBar.new().setup(GameState.get_stat_label("abyssal_sync"), "abyssal_sync", 0, 100, AstralTheme.STAT_COLORS["abyssal_sync"], str(AstralTheme.STAT_TOOLTIPS["abyssal_sync"]), 138)
	for b in [_bar_anchor, _bar_seal, _bar_sync]:
		(b as StatBar).custom_minimum_size.y = 24
		v.add_child(b)
	v.add_child(AstralTheme.separator())
	v.add_child(AstralTheme.label("MENÚ DEL OBSERVATORIO", "SubLabel"))

	for i in range(NAV_ITEMS.size()):
		var item: Dictionary = NAV_ITEMS[i]
		var btn := Button.new()
		btn.theme_type_variation = "NavButton"
		btn.toggle_mode = true
		btn.custom_minimum_size.y = 60
		btn.focus_mode = Control.FOCUS_ALL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = "Atajo: tecla %d" % (i + 1)
		var row := AstralTheme.hbox(12)
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_right = -10
		row.offset_top = 4
		row.offset_bottom = -4
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(row)
		var icon := TextureRect.new()
		icon.texture = load(str(item["icon"]))
		icon.custom_minimum_size = Vector2(40, 50)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var tv := AstralTheme.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tv)
		var t1 := AstralTheme.label(str(item["title"]), "", AstralTheme.GOLD_PALE)
		t1.add_theme_font_override("font", AstralTheme.font("Bold"))
		t1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(t1)
		var t2 := AstralTheme.label(str(item["sub"]), "CaptionLabel", AstralTheme.MUTED)
		t2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t2.clip_text = true
		tv.add_child(t2)
		var wid: String = item["id"]
		btn.pressed.connect(func() -> void: _toggle_window(wid))
		v.add_child(btn)
		_nav_buttons[wid] = btn

	v.add_child(AstralTheme.spacer())
	var clear_btn := AstralTheme.button("%s  Contemplar el observatorio" % AstralTheme.G_STAR2, "TabLikeButton", "Oculta la interfaz para ver el fondo.")
	clear_btn.pressed.connect(func() -> void: _set_ui_visible(false))
	v.add_child(clear_btn)
	return dock

func _build_windows() -> void:
	var defs: Dictionary = {
		"schedule": SchedulePlanner.new(), "status": StatusSheet.new(), "hearth": HearthWindow.new(),
		"crucible": AstralCrucible.new(), "town": TownMap.new(), "explore": ExplorationWindow.new()
	}
	for id in defs.keys():
		var w: BaseWindow = defs[id]
		_center.add_child(w)
		w.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		w.speak.connect(say)
		w.toast.connect(toast)
		var wid: String = id
		w.closed.connect(func() -> void: _on_window_closed(wid))
		_windows[id] = w
	(_windows["schedule"] as SchedulePlanner).execute_requested.connect(_execute_turn)
	(_windows["status"] as StatusSheet).open_letter.connect(func(l: Dictionary) -> void: _letter.show_letter(l))
	(_windows["town"] as TownMap).bond_event_requested.connect(func(npc: String) -> void: _bond.play(npc))
	(_windows["explore"] as ExplorationWindow).expedition_started.connect(func() -> void: _combat.open_combat())
	(_windows["explore"] as ExplorationWindow).festival_completed.connect(_on_festival_completed)

func _build_stage() -> Control:
	var s := Control.new()
	s.custom_minimum_size.x = 560
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_ring_outer = _stage_tex("res://assets/ui/astrolabe_ring_outer.png", Color(1.0, 0.95, 0.8, 0.85))
	_ring_inner = _stage_tex("res://assets/ui/astrolabe_ring_inner.png", Color(0.75, 0.95, 1.0, 0.9))
	_portrait = _stage_tex("res://assets/art/renpet_portrait.png", Color.WHITE)
	s.add_child(_ring_outer)
	s.add_child(_ring_inner)
	s.add_child(_portrait)

	var plate := PanelContainer.new()
	plate.theme_type_variation = "PillPanel"
	plate.anchor_left = 0.0
	plate.anchor_right = 1.0
	plate.anchor_top = 1.0
	plate.anchor_bottom = 1.0
	plate.offset_left = 20
	plate.offset_right = -20
	plate.offset_top = -64
	plate.offset_bottom = 0
	_nameplate = AstralTheme.label("", "", AstralTheme.GOLD_PALE, true)
	_nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(_nameplate)
	s.add_child(plate)
	s.resized.connect(_layout_stage)
	return s

func _stage_tex(path: String, tint: Color) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.modulate = tint
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func _layout_stage() -> void:
	if _stage == null or _portrait == null:
		return
	var sz: Vector2 = _stage.size
	var ph: float = clampf(sz.y - 96.0, 300.0, 640.0)
	var pw: float = ph * 460.0 / 600.0
	if pw > sz.x - 20.0:
		pw = sz.x - 20.0
		ph = pw * 600.0 / 460.0
	_portrait.size = Vector2(pw, ph)
	_portrait.position = Vector2((sz.x - pw) * 0.5, sz.y - 78.0 - ph)
	_portrait_base_y = _portrait.position.y
	var center: Vector2 = Vector2(sz.x * 0.5, _portrait.position.y + ph * 0.40)
	var d_out: float = minf(sz.x - 6.0, ph * 0.98)
	_ring_outer.size = Vector2(d_out, d_out)
	_ring_outer.pivot_offset = _ring_outer.size * 0.5
	_ring_outer.position = center - _ring_outer.size * 0.5
	var d_in: float = d_out * 0.72
	_ring_inner.size = Vector2(d_in, d_in)
	_ring_inner.pivot_offset = _ring_inner.size * 0.5
	_ring_inner.position = center - _ring_inner.size * 0.5

func _build_dialogue_bar() -> Control:
	var bar := PanelContainer.new()
	bar.theme_type_variation = "BarPanel"
	bar.custom_minimum_size.y = 140
	bar.gui_input.connect(_on_dialogue_input)
	var h := AstralTheme.hbox(18)
	bar.add_child(h)
	_dlg_medallion = TextureRect.new()
	_dlg_medallion.custom_minimum_size = Vector2(96, 96)
	_dlg_medallion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dlg_medallion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dlg_medallion.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_dlg_medallion)
	var mid := AstralTheme.vbox(4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(mid)
	_lbl_speaker = AstralTheme.label("", "HeadingLabel")
	mid.add_child(_lbl_speaker)
	_lbl_dialogue = AstralTheme.rich("")
	_lbl_dialogue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lbl_dialogue.fit_content = false
	_lbl_dialogue.scroll_active = true
	_lbl_dialogue.custom_minimum_size.y = 70
	mid.add_child(_lbl_dialogue)
	var side := AstralTheme.vbox(8)
	side.custom_minimum_size.x = 250
	h.add_child(side)
	var b1 := AstralTheme.button(AstralTheme.G_FLOWER + "  Conversar con Renpet", "", "Abre la Chimenea y Hogar")
	b1.pressed.connect(func() -> void: _open_window("hearth"))
	side.add_child(b1)
	var b2 := AstralTheme.button(AstralTheme.G_STAR + "  Abrir agenda del bimestre", "PrimaryButton")
	b2.pressed.connect(func() -> void: _open_window("schedule"))
	side.add_child(b2)
	return bar

func _build_overlays() -> void:
	_prologue = PrologueOverlay.new()
	_report = TurnReportOverlay.new()
	_letter = LetterOverlay.new()
	_bond = BondEventOverlay.new()
	_combat = CombatOverlay.new()
	_story = StoryEventOverlay.new()
	_menu = MenuOverlay.new()
	_ending = EndingOverlay.new()
	for o in [_report, _letter, _bond, _combat, _story, _menu, _ending, _prologue]:
		add_child(o)
	_prologue.finished.connect(_on_prologue_finished)
	_bond.resolved.connect(func(_npc: String) -> void:
		toast("Escena completada", "good")
		SaveManager.autosave()
		_refresh_all())
	_combat.expedition_ended.connect(_on_expedition_ended)
	_menu.save_done.connect(func(slot: int) -> void: toast("Partida guardada en la ranura %d" % slot, "good"))
	_menu.load_requested.connect(_load_slot)
	_menu.title_requested.connect(_go_title)
	_ending.title_requested.connect(_go_title)

	var toast_layer := Control.new()
	toast_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_layer)
	_toast_box = AstralTheme.vbox(8)
	_toast_box.anchor_left = 0.5
	_toast_box.anchor_right = 0.5
	_toast_box.anchor_top = 0.0
	_toast_box.anchor_bottom = 0.0
	_toast_box.offset_left = -270
	_toast_box.offset_right = 270
	_toast_box.offset_top = 92
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_layer.add_child(_toast_box)

# ------------------------------------------------------------------------------
# VENTANAS
# ------------------------------------------------------------------------------
func _toggle_window(id: String) -> void:
	if _current_window == id:
		(_windows[id] as BaseWindow).close()
	else:
		_open_window(id)

func _open_window(id: String) -> void:
	if not _windows.has(id):
		return
	if _current_window != "" and _current_window != id:
		var prev: BaseWindow = _windows[_current_window]
		prev.visible = false
	_current_window = id
	for k in _nav_buttons.keys():
		(_nav_buttons[k] as Button).set_pressed_no_signal(k == id)
	(_windows[id] as BaseWindow).open()

func _on_window_closed(id: String) -> void:
	if _current_window == id:
		_current_window = ""
	if _nav_buttons.has(id):
		(_nav_buttons[id] as Button).set_pressed_no_signal(false)

func _close_windows() -> void:
	for id in _windows.keys():
		(_windows[id] as BaseWindow).visible = false
	for k in _nav_buttons.keys():
		(_nav_buttons[k] as Button).set_pressed_no_signal(false)
	_current_window = ""

func _any_overlay_visible() -> bool:
	for o in [_prologue, _report, _letter, _bond, _combat, _story, _menu, _ending]:
		if (o as Control).visible:
			return true
	return false

func _set_ui_visible(v: bool) -> void:
	_ui_root.visible = v
	_show_ui_btn.visible = not v

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: InputEventKey = event
	if k.keycode == KEY_F11:
		_toggle_fullscreen()
		return
	if _any_overlay_visible():
		if k.keycode == KEY_ESCAPE:
			if _ending != null and _ending._tapestry != null and _ending._tapestry.visible:
				_ending._tapestry.hide_overlay()
				get_viewport().set_input_as_handled()
			elif _menu.visible or _letter.visible:
				(_menu if _menu.visible else _letter).hide_overlay()
				get_viewport().set_input_as_handled()
		return
	if not _ui_root.visible:
		if k.keycode == KEY_ESCAPE:
			_set_ui_visible(true)
		return
	if k.keycode == KEY_ESCAPE:
		if _current_window != "":
			(_windows[_current_window] as BaseWindow).close()
		else:
			_menu.open_pause(GameState.prologue_completed)
		get_viewport().set_input_as_handled()
		return
	for item in NAV_ITEMS:
		if k.keycode == int(item["key"]):
			_toggle_window(str(item["id"]))
			get_viewport().set_input_as_handled()
			return

# ------------------------------------------------------------------------------
# FLUJO DEL TURNO
# ------------------------------------------------------------------------------
func _execute_turn() -> void:
	if _busy:
		return
	_busy = true
	var rep: Dictionary = TurnExecutor.resolve_bimester()
	if not rep.get("ok", false):
		toast(str(rep.get("msg", "No se puede ejecutar el bimestre.")), "bad")
		_busy = false
		return
	_close_windows()
	_refresh_all()
	_report.show_report(rep)
	await _report.closed
	var letter: Dictionary = rep.get("year_end", {})
	if not letter.is_empty():
		_letter.show_letter(letter)
		await _letter.closed
	var story_ev: Dictionary = ExplorationCombat.check_pending_main_story_event()
	if bool(story_ev.get("has_event", false)):
		_story.show_story_event(story_ev)
		await _story.closed
		_refresh_all()
		SaveManager.autosave()
	if rep.get("campaign_finished", false):
		_ending.show_ending()
		_busy = false
		return
	say("%s — Mansión Solar" % GameState.daughter_name, GameState.get_dynamic_manor_greeting())
	if TimeManager.is_festival_bimester():
		toast("✦ ¡Festival de Otoño abierto! Compite en (VI. Expedición y Festival)", "good")
	else:
		toast("Autoguardado — %s" % TimeManager.get_bimester_info()["name"], "good")
	_busy = false

func _on_expedition_ended(victory: bool, _summary: String) -> void:
	SaveManager.autosave()
	_refresh_all()
	if victory:
		toast("Expedición completada con éxito", "good")
		say(GameState.daughter_name, "\"¡Volvimos sanos y salvos al observatorio, Padre! Traemos reliquias y nuevos recuerdos del cielo.\"")
	else:
		toast("Retirada de la expedición", "warn")
		var seal_word: String = "el Sello" if GameState.get_secret_tier() >= 1 else "mi estrella"
		say(GameState.daughter_name, "\"Tuvimos que retroceder antes de que %s sufriera más... Descansaré un poco.\"" % seal_word)

func _on_festival_completed(res: Dictionary) -> void:
	SaveManager.autosave()
	_refresh_all()
	if bool(res.get("won", false)):
		say(GameState.daughter_name, "\"¡Lo logramos, Padre! ¡Toda la capital coreó nuestro nombre en el Coliseo de las Constelaciones!\"")
	else:
		say(GameState.daughter_name, "\"El rival estuvo muy fuerte esta vez, Padre, pero aprendí muchísimo en el escenario imperial.\"")

func _load_slot(slot: int) -> void:
	var res: Dictionary = SaveManager.load_game(slot)
	if res.get("ok", false):
		_close_windows()
		_refresh_all()
		say("%s — Mansión Solar" % GameState.daughter_name, GameState.get_dynamic_manor_greeting())
		toast("Partida cargada", "good")
	else:
		toast(str(res.get("msg", "No se pudo cargar.")), "bad")

func _go_title() -> void:
	get_tree().change_scene_to_file("res://src/scenes/TitleScreen.tscn")

# ------------------------------------------------------------------------------
# ACTUALIZACIÓN DE LA INTERFAZ (se agrupa: muchas modificaciones => una sola actualización)
# ------------------------------------------------------------------------------
func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_do_refresh.call_deferred()

func _refresh_all() -> void:
	_do_refresh()

func _do_refresh() -> void:
	_refresh_queued = false
	var bim: Dictionary = TimeManager.get_bimester_info()
	_lbl_date.text = "Año %d (Edad %d) — %s   [Turno %d/%d]" % [TimeManager.current_year, GameState.age, bim["name"], TimeManager.current_total_turn, TimeManager.TOTAL_TURNS]
	_lbl_era.text = "%s   %s   %s" % [TimeManager.get_era_title(), AstralTheme.G_STAR2, bim["phenomenon"]]
	_pill_gold.text = "%s  %d G" % [AstralTheme.G_SUN, GameState.gold]
	var free: int = GameState.father_energy - TurnExecutor.get_father_energy_used()
	_pill_energy.text = "%s  Padre: %d/%d" % [AstralTheme.G_ANKH, free, GameState.father_max_energy]
	_pill_stress.text = "%s  Estrés: %d%%" % [AstralTheme.G_MOON, GameState.stress]
	_pill_stress.add_theme_color_override("font_color", AstralTheme.BAD if GameState.stress >= 80 else (AstralTheme.EMBER if GameState.stress >= 60 else AstralTheme.GOOD))
	_pill_affection.text = "%s  Afecto: %d%%" % [AstralTheme.G_HEART, GameState.affection]
	_bar_anchor.set_value(GameState.human_anchor)
	_bar_seal.set_title(GameState.get_stat_label("seal_integrity"))
	_bar_seal.set_value(GameState.seal_integrity)
	_bar_sync.set_title(GameState.get_stat_label("abyssal_sync"))
	_bar_sync.set_value(GameState.abyssal_sync)
	var tier: int = GameState.get_secret_tier()
	_lbl_seal_heading.text = "ESTADO DEL SELLO" if tier >= 1 else "ESTADO DE LA MARCA"
	var cracked: bool = GameState.seal_integrity < 50
	var med_path: String = "res://assets/ui/seal_medallion_cracked.png" if cracked else "res://assets/ui/seal_medallion_intact.png"
	_dock_medallion.texture = load(med_path)
	_dlg_medallion.texture = _dock_medallion.texture
	_lbl_seal_title.text = GameState.get_metaphysical_state_title()
	_nameplate.text = "%s — %s" % [GameState.daughter_name, GameState.get_metaphysical_state_title().get_slice(":", 0)]
	_portrait.modulate = Color(0.92, 0.86, 1.0) if GameState.abyssal_sync >= 50 else Color.WHITE
	if _current_window != "" and (_windows[_current_window] as BaseWindow).visible:
		(_windows[_current_window] as BaseWindow).refresh()

# ------------------------------------------------------------------------------
# DIÁLOGO Y AVISOS
# ------------------------------------------------------------------------------
func say(speaker: String, text: String) -> void:
	_lbl_speaker.text = speaker
	_lbl_dialogue.text = text
	_lbl_dialogue.visible_ratio = 0.0
	if _typing != null and _typing.is_valid():
		_typing.kill()
	var secs: float = clampf(float(text.length()) * 0.012, 0.25, 2.4)
	_typing = create_tween()
	_typing.tween_property(_lbl_dialogue, "visible_ratio", 1.0, secs)

func _on_dialogue_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _lbl_dialogue.visible_ratio < 1.0:
		if _typing != null and _typing.is_valid():
			_typing.kill()
		_lbl_dialogue.visible_ratio = 1.0

func toast(text: String, kind: String = "info") -> void:
	var color: Color = AstralTheme.GOLD
	var glyph: String = AstralTheme.G_STAR
	match kind:
		"good":
			color = AstralTheme.GOOD
			glyph = AstralTheme.G_CHECK
		"warn":
			color = AstralTheme.EMBER
			glyph = AstralTheme.G_BOLT
		"bad":
			color = AstralTheme.BAD
			glyph = AstralTheme.G_CROSS
	var p := PanelContainer.new()
	p.theme_type_variation = "PillPanel"
	var l := AstralTheme.label("%s  %s" % [glyph, text], "", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 500
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.modulate.a = 0.0
	_toast_box.add_child(p)
	var tw := create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(3.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)

# ------------------------------------------------------------------------------
# AYUDAS DE DEPURACIÓN (capturas de pantalla automáticas)
# ------------------------------------------------------------------------------
func debug_skip_prologue() -> void:
	_prologue.hide_overlay()
	GameState.prologue_completed = true
	_refresh_all()
	say("%s — Mansión Solar" % GameState.daughter_name, GameState.get_dynamic_manor_greeting())

func debug_open_window(id: String) -> void:
	_open_window(id)

func debug_dump_layout() -> void:
	print("ui_root min: ", _ui_root.get_combined_minimum_size(), " size: ", _ui_root.size)
	var v: Node = _ui_root.get_child(0)
	for c in v.get_children():
		print("  ", c.get_class(), " min=", (c as Control).get_combined_minimum_size(), " size=", (c as Control).size)
	var mid: Node = v.get_child(1)
	for c in mid.get_children():
		print("    mid-child ", c.get_class(), " min=", (c as Control).get_combined_minimum_size(), " size=", (c as Control).size)

## Estado de ejemplo para capturas: edad 18, algo de historia, mutaciones y vínculos.
func debug_demo_state() -> void:
	GameState.begin_batch()
	GameState.age = 18
	TimeManager.current_total_turn = 38
	TimeManager.current_year = 18
	TimeManager.current_bimester = 2
	TimeManager.update_era()
	GameState.gold = 1280
	GameState.stress = 66
	GameState.temple = 480; GameState.destreza = 470; GameState.erudicion = 330; GameState.gracia = 260
	GameState.astral_saturation = 62
	GameState.add_mutation("paso_de_luz")
	GameState.add_mutation("voz_del_prisionero")
	GameState.father_reputation = 82
	GameState.end_batch()
	RelationshipManager.state["soren"]["affection"] = 52
	RelationshipManager.state["soren"]["stage"] = 2
	RelationshipManager.state["vespera"]["affection"] = -50
	RelationshipManager.state["vespera"]["stage"] = 2
	RelationshipManager.state["mirari"]["spark"] = 20
	Chronicle.record_event("demo", "Victoria de prestigio", "Renpet superó a Vespera en el Patio Ducal.", "rivalry", 4)
	Chronicle.assemble_annual_letter(17)
	_refresh_all()

func debug_show_report() -> void:
	debug_skip_prologue()
	debug_demo_state()
	GameState.stress = 40
	TurnExecutor.set_agenda_slot(0, "class_armory")
	TurnExecutor.set_agenda_slot(1, "class_astrolabe")
	TurnExecutor.set_agenda_slot(2, "job_canals")
	TurnExecutor.toggle_father_task("supervise")
	TurnExecutor.toggle_father_task("investigate")
	_report.show_report(TurnExecutor.resolve_bimester())

func debug_show_letter() -> void:
	debug_skip_prologue()
	debug_demo_state()
	_letter.show_letter(Chronicle.letters_archive[0])

func debug_show_bond() -> void:
	debug_skip_prologue()
	debug_demo_state()
	RelationshipManager.reset_bimester_flags()
	_bond.play("soren")

func debug_show_creation() -> void:
	_prologue._show_creation()

func debug_show_menu() -> void:
	debug_skip_prologue()
	_menu.open_pause(true)

func debug_show_ending() -> void:
	debug_skip_prologue()
	debug_demo_state()
	_ending.show_ending()

func _toggle_fullscreen() -> void:
	var full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
