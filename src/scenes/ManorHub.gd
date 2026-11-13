extends Control

## ManorHub - Observatorio de la Mansión Solar (centro de mando de las Fases 3 a 6).
## Solo orquesta la interfaz: toda la lógica de juego vive en los autoloads (TurnExecutor, CrucibleManager,
## RelationshipManager, RivalMirror...). El diseño usa contenedores y anclas, así que se adapta a cualquier
## proporción de ventana (16:9, 16:10, 21:9...).

const NAV_ITEMS: Array[Dictionary] = [
	{"id": "schedule", "title": "I. Libro del Bimestre", "sub": "Agenda de 60 días, clases, trabajos y tareas del Padre", "icon": "res://assets/art/illus_study_astrolabe.png", "key": KEY_1},
	{"id": "status", "title": "II. Ficha de Renpet", "sub": "Atributos, temperamento, rasgos y cartas equipadas", "icon": "res://assets/ui/seal_medallion_intact.png", "key": KEY_2},
	{"id": "hearth", "title": "III. Chimenea y Hogar", "sub": "Charlas junto al fuego, mesa familiar y mejoras", "icon": "res://assets/art/bg_hearth_night.png", "key": KEY_3},
	{"id": "crucible", "title": "IV. El Crisol Astral", "sub": "Alquimia del hogar y objetos encontrados", "icon": "res://assets/ui/relic_comet_dust.png", "key": KEY_4}
]

# --- Efectos visuales interactivos del escenario ---
class _StageFX extends Control:
	const COL_GOLD := Color(0.95, 0.80, 0.42, 1.0)
	const COL_TURQ := Color(0.35, 0.84, 0.80, 1.0)
	var motes_enabled: bool = true
	var prefer_calm_motes: bool = false
	var mutations_flags: Array = []
	var seal_cracks_ratio: float = 0.0
	var exhausted_mode: bool = false
	var season_index: int = 1
	var sync_ratio: float = 0.0
	var _t_fx: float = 0.0
	var _dust: Array[Dictionary] = []
	var _motes: Array[Dictionary] = []
	var _bursts: Array[Dictionary] = []
	var _spawn_timer: float = 1.8
	var _rng := RandomNumberGenerator.new()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_rng.randomize()
		for i in range(22):
			_dust.append({
				"x": _rng.randf(),
				"y": _rng.randf(),
				"spd": _rng.randf_range(0.015, 0.042),
				"sz": _rng.randf_range(1.2, 2.8),
				"phase": _rng.randf() * TAU,
				"gold": (i % 3) != 0
			})

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t_fx += delta
		for d in _dust:
			d["y"] = float(d["y"]) - float(d["spd"]) * delta
			d["phase"] = float(d["phase"]) + delta * 1.8
			if float(d["y"]) < 0.0:
				d["y"] = 1.0
				d["x"] = _rng.randf()
		for i in range(_bursts.size() - 1, -1, -1):
			var b: Dictionary = _bursts[i]
			b["life"] = float(b["life"]) - delta
			if float(b["life"]) <= 0.0:
				_bursts.remove_at(i)
			else:
				b["pos"] = (b["pos"] as Vector2) + (b["vel"] as Vector2) * delta
				b["vel"] = (b["vel"] as Vector2) * 0.92
		if motes_enabled and size.x > 120.0 and size.y > 180.0:
			for i in range(_motes.size() - 1, -1, -1):
				var m: Dictionary = _motes[i]
				m["phase"] = float(m["phase"]) + delta * 2.8
				m["life"] = float(m["life"]) - delta
				if float(m["life"]) <= 0.0:
					_motes.remove_at(i)
			_spawn_timer -= delta
			if _spawn_timer <= 0.0 and _motes.size() < 2:
				_spawn_timer = _rng.randf_range(4.5, 8.0)
				var left_side: bool = (_rng.randi() % 2) == 0
				var px: float = _rng.randf_range(38.0, size.x * 0.28) if left_side else _rng.randf_range(size.x * 0.72, size.x - 38.0)
				var py: float = _rng.randf_range(76.0, size.y - 120.0)
				_motes.append({
					"pos": Vector2(px, py),
					"kind": "calm" if prefer_calm_motes and (_rng.randi() % 2) == 0 else "gold",
					"phase": _rng.randf() * TAU,
					"life": 14.0
				})
		queue_redraw()

	func try_collect_mote(click_pos: Vector2) -> Dictionary:
		for i in range(_motes.size()):
			var m: Dictionary = _motes[i]
			var bob: Vector2 = (m["pos"] as Vector2) + Vector2(0.0, sin(float(m["phase"])) * 7.0)
			if click_pos.distance_to(bob) <= 30.0:
				var kind: String = str(m["kind"])
				_motes.remove_at(i)
				var col: Color = COL_TURQ if kind == "calm" else COL_GOLD
				spawn_burst(bob, col, 16)
				return {"hit": true, "pos": bob, "kind": kind, "color": col}
		return {"hit": false}

	func spawn_burst(pos: Vector2, col: Color, count: int) -> void:
		if DisplayServer.get_name() == "headless":
			return
		for i in range(count):
			var a: float = _rng.randf() * TAU
			var spd: float = _rng.randf_range(38.0, 145.0)
			_bursts.append({
				"pos": pos,
				"vel": Vector2.from_angle(a) * spd,
				"life": _rng.randf_range(0.35, 0.78),
				"max": 0.78,
				"col": col,
				"sz": _rng.randf_range(2.2, 4.6)
			})

	func _draw() -> void:
		if size.x <= 4.0 or size.y <= 4.0:
			return
		var cx: float = size.x * 0.5
		var cy: float = size.y * 0.48
		# Halo astral suave detrás del retrato y su astrolabio según estación y sincronía
		var aura_center := Vector2(cx, cy - 26.0)
		var base_aura: Color = Color(0.28, 0.82, 0.80).lerp(Color(0.68, 0.42, 0.96), sync_ratio)
		var aura_pulse: float = 1.0 + 0.05 * sin(_t_fx * 1.4)
		draw_circle(aura_center, 190.0 * aura_pulse, Color(base_aura.r, base_aura.g, base_aura.b, 0.07))
		draw_circle(aura_center, 125.0 * aura_pulse, Color(0.96, 0.82, 0.46, 0.055))

		for d in _dust:
			var px: float = float(d["x"]) * size.x + sin(float(d["phase"])) * 10.0
			var py: float = float(d["y"]) * size.y
			var a: float = 0.22 + 0.20 * sin(float(d["phase"]) * 1.3)
			var c: Color
			if season_index == 2:
				c = Color(0.98, 0.72, 0.84, a) if bool(d["gold"]) else Color(0.95, 0.86, 0.54, a)
			elif season_index == 4:
				c = Color(0.96, 0.64, 0.28, a) if bool(d["gold"]) else Color(0.94, 0.84, 0.44, a)
			elif season_index >= 5:
				c = Color(0.78, 0.92, 1.0, a * 1.15) if bool(d["gold"]) else Color(0.58, 0.76, 0.98, a)
			else:
				c = Color(0.95, 0.82, 0.44, a) if bool(d["gold"]) else Color(0.38, 0.86, 0.82, a)
			var pt := Vector2(px, py)
			var sz_d: float = float(d["sz"])
			draw_circle(pt, sz_d, c)
			if season_index >= 5 and sz_d >= 2.0:
				draw_line(pt - Vector2(sz_d * 1.6, 0.0), pt + Vector2(sz_d * 1.6, 0.0), Color(c.r, c.g, c.b, a * 0.7), 1.0)
				draw_line(pt - Vector2(0.0, sz_d * 1.6), pt + Vector2(0.0, sz_d * 1.6), Color(c.r, c.g, c.b, a * 0.7), 1.0)
		for m in _motes:
			var pos: Vector2 = (m["pos"] as Vector2) + Vector2(0.0, sin(float(m["phase"])) * 7.0)
			var is_calm: bool = str(m["kind"]) == "calm"
			var col: Color = COL_TURQ if is_calm else COL_GOLD
			var r_p: float = 12.0 + sin(float(m["phase"]) * 2.0) * 3.5
			draw_circle(pos, r_p + 5.0, Color(col.r, col.g, col.b, 0.18))
			draw_arc(pos, r_p, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.72), 1.6, true)
			draw_line(pos + Vector2(-11.0, 0.0), pos + Vector2(11.0, 0.0), Color(1.0, 0.98, 0.86, 0.9), 2.0, true)
			draw_line(pos + Vector2(0.0, -11.0), pos + Vector2(0.0, 11.0), Color(1.0, 0.98, 0.86, 0.9), 2.0, true)
			draw_circle(pos, 4.5, Color(1.0, 0.98, 0.92, 1.0))
		for b in _bursts:
			var ratio: float = clampf(float(b["life"]) / float(b["max"]), 0.0, 1.0)
			var bc: Color = b["col"]
			draw_circle(b["pos"], float(b["sz"]) * ratio, Color(bc.r, bc.g, bc.b, ratio))

		# Capas visuales de Mutaciones, Agotamiento y Fisuras del Sello sobre el retrato
		if seal_cracks_ratio > 0.01:
			var cr_a: float = 0.35 + seal_cracks_ratio * 0.48 + 0.10 * sin(_t_fx * 3.1)
			var cr_col := Color(0.96, 0.32, 0.48, clampf(cr_a, 0.0, 0.95))
			for k in range(5):
				var ang: float = -1.2 + float(k) * 0.62
				var p0 := Vector2(cx + cos(ang) * 72.0, cy + sin(ang) * 90.0)
				var p1 := p0 + Vector2(cos(ang + 0.35) * 44.0, sin(ang - 0.25) * 44.0)
				var p2 := p1 + Vector2(cos(ang - 0.2) * 30.0, sin(ang + 0.3) * 30.0)
				draw_polyline([p0, p1, p2], cr_col, 2.2, true)
		if mutations_flags.has("voz_del_prisionero"):
			var eye_pos := Vector2(cx + 22.0, cy - 58.0)
			var eg_r: float = 9.0 + sin(_t_fx * 3.4) * 2.5
			draw_circle(eye_pos, eg_r + 5.0, Color(0.68, 0.35, 0.98, 0.22))
			draw_circle(eye_pos, eg_r * 0.55, Color(0.86, 0.58, 1.0, 0.65))
		if mutations_flags.has("pulso_cristalino"):
			for i in range(4):
				var a: float = _t_fx * 0.7 + float(i) * (TAU * 0.25)
				var cp := Vector2(cx + cos(a) * 145.0, cy + sin(a) * 185.0)
				draw_polygon([cp + Vector2(0, -7), cp + Vector2(5, 0), cp + Vector2(0, 7), cp + Vector2(-5, 0)], [Color(0.55, 0.92, 0.98, 0.75)])
		if mutations_flags.has("sangre_pesada"):
			draw_arc(Vector2(cx, cy + 36.0), 118.0, 0.2, PI - 0.2, 24, Color(0.92, 0.56, 0.28, 0.42), 2.5, true)
		if mutations_flags.has("paradoja_menor"):
			draw_arc(Vector2(cx, cy - 22.0), 152.0, _t_fx, _t_fx + 1.8, 20, Color(0.82, 0.88, 1.0, 0.46), 1.8, true)
		if mutations_flags.has("paso_de_luz"):
			var lp := Vector2(cx - 125.0, cy - 95.0 + sin(_t_fx * 2.0) * 12.0)
			draw_line(lp, lp + Vector2(46.0, -34.0), Color(0.58, 0.95, 1.0, 0.50), 2.0, true)
		if mutations_flags.has("bendicion_del_tiempo"):
			var ba: float = _t_fx * 0.9
			draw_circle(Vector2(cx + cos(ba) * 165.0, cy + sin(ba) * 165.0), 4.0, Color(0.98, 0.86, 0.42, 0.85))
		if exhausted_mode:
			draw_arc(Vector2(cx, cy), 148.0, 0.0, TAU, 36, Color(0.75, 0.35, 0.45, 0.32 + 0.14 * sin(_t_fx * 4.0)), 4.0, true)

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
var _nav_badges: Dictionary = {}
var _status_nav_title: Label
var _lbl_goal: Label
var _bar_goal: ProgressBar
var _lbl_mood_chip: Label
var _lbl_susp_chip: Label
var _bg_rect: TextureRect
var _bg_shade: ColorRect
var _fade_curtain: ColorRect
var _city_btn: Button
var _city_badge: Label
var _btn_talk: Button
var _audio_btn: Button
var _center: Control
var _windows: Dictionary = {}
var _current_window: String = ""
var _stage: Control
var _ring_outer: TextureRect
var _ring_inner: TextureRect
var _portrait: TextureRect
var _nameplate: Label
var _portrait_base_y: float = 0.0
var _stage_fx: _StageFX
var _ritual_btn: Button
var _lbl_speaker: Label
var _lbl_dialogue: RichTextLabel
var _dlg_medallion: TextureRect
var _typing: Tween
var _toast_box: VBoxContainer
var _show_ui_btn: Button
var _anim_time: float = 0.0
var _stage_tip_idx: int = 0

# --- Overlays ---
var _prologue: PrologueOverlay
var _report: TurnReportOverlay
var _letter: LetterOverlay
var _bond: BondEventOverlay
var _combat: CombatOverlay
var _story: StoryEventOverlay
var _menu: MenuOverlay
var _ending: EndingOverlay
var _exec: ExecutionOverlay
var _ritual: AstrolabeRitualOverlay
var _school_mg: TrainingMinigameOverlay
var _city_map: CityMapOverlay
var _tutorial: TutorialOverlay

var _mg_context: String = ""   # "" | "festival" | "practice" | "practical_turn"
var _practical_act_pending: String = ""

var _refresh_queued: bool = false
var _busy: bool = false   # evita doble ejecución del turno
var _wants_report: bool = false

func _ready() -> void:
	theme = AstralTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_layout()
	_build_overlays()
	_fade_curtain = ColorRect.new()
	_fade_curtain.color = Color(0.01, 0.02, 0.06, 0.0 if DisplayServer.get_name() == "headless" else 1.0)
	_fade_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_curtain)
	if DisplayServer.get_name() != "headless":
		var ftw := create_tween()
		ftw.tween_property(_fade_curtain, "color:a", 0.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	GameState.stats_updated.connect(_queue_refresh)
	GameState.gold_changed.connect(func(_g: int) -> void: _queue_refresh())
	GameState.seal_state_changed.connect(func(_a: int, _b: int, _c: int) -> void: _queue_refresh())
	TurnExecutor.plan_changed.connect(_queue_refresh)

	_start_session()

func _process(delta: float) -> void:
	_anim_time += delta
	if _ring_outer != null:
		var spd: float = 0.24 if GameState.seal_integrity < 45 else 0.14
		_ring_outer.rotation = _anim_time * spd
		_ring_inner.rotation = -_anim_time * (spd * 1.75)
		_portrait.position.y = _portrait_base_y + sin(_anim_time * 1.8) * 5.0
		_portrait.scale = _portrait.scale.lerp(Vector2.ONE, minf(1.0, delta * 9.0))
	if _stage_fx != null:
		_stage_fx.motes_enabled = (_current_window == "" and not _any_overlay_visible() and _ui_root.visible)
		_stage_fx.prefer_calm_motes = GameState.stress >= 20

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
	if GameState.story_ng_echo_used:
		GameState.modify_stat("seal_investigation", 12)
		Chronicle.record_event("ng_echo_start", "Eco del Solsticio (NG+)", "Despiertas recordando ecos de la advertencia celeste (+12% Investigación).", "lore", 4)
	GameState.prologue_completed = true
	Chronicle.record_event("hero_created", "El Héroe elige su leyenda", "%s se presentó como %s." % [father, GameState.get_archetype_title()], "lore", 4)
	if not ng_boons.is_empty():
		Chronicle.record_event("ng_plus_boons", "Bendiciones del Tapiz", "Ventajas heredadas activadas: %s." % ", ".join(ng_boons), "lore", 4)
	SaveManager.autosave()
	_refresh_all()
	say("%s — Mansión Solar" % GameState.daughter_name, GameState.get_dynamic_manor_greeting())
	toast("Comienza la crónica de %s%s" % [daughter, " (NG+)" if not ng_boons.is_empty() else ""], "good")
	if not SettingsManager.tutorial_completed and DisplayServer.get_name() != "headless" and _tutorial != null:
		_tutorial.open_tutorial(0)

# ------------------------------------------------------------------------------
# CONSTRUCCIÓN DE LA INTERFAZ
# ------------------------------------------------------------------------------
func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = AstralTheme.load_tex("res://assets/art/bg_manor_observatory.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_rect = bg
	add_child(bg)

	# Velo de lapislázuli + viñeta progresiva por Acto para que el texto siempre se lea
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.1, 0.38)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_shade = shade
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
	_center.visible = false
	mid.add_child(_center)
	_build_windows()

	_stage = _build_stage()
	mid.add_child(_stage)
	v.add_child(_build_dialogue_bar())

	_show_ui_btn = AstralTheme.button(AstralTheme.G_STAR + "  Mostrar interfaz", "PrimaryButton")
	_show_ui_btn.visible = false
	_show_ui_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_show_ui_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_show_ui_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_show_ui_btn.offset_left = -246
	_show_ui_btn.offset_top = -66
	_show_ui_btn.offset_right = -24
	_show_ui_btn.offset_bottom = -20
	_show_ui_btn.pressed.connect(func() -> void: _set_ui_visible(true))
	add_child(_show_ui_btn)

func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.theme_type_variation = "BarPanel"
	var h := AstralTheme.hbox(10)
	bar.add_child(h)
	var ftex: Texture2D = AstralTheme.load_tex("res://assets/art/father_portrait.png")
	if ftex != null:
		var frect := TextureRect.new()
		frect.texture = ftex
		frect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frect.custom_minimum_size = Vector2(36, 46)
		frect.tooltip_text = "Retrato del Héroe (Padre)"
		h.add_child(frect)
	var left := AstralTheme.vbox(0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(left)
	_lbl_date = AstralTheme.label("", "HeadingLabel")
	left.add_child(_lbl_date)
	_lbl_era = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ)
	_lbl_era.clip_text = true
	_lbl_era.mouse_filter = Control.MOUSE_FILTER_STOP
	left.add_child(_lbl_era)

	_pill_gold = _make_pill(h, AstralTheme.GOLD, "Oro de la casa")
	_pill_energy = _make_pill(h, AstralTheme.TURQ, "Energía Paternal: puntos libres este bimestre para las tareas del Padre")
	_pill_stress = _make_pill(h, AstralTheme.BAD, str(AstralTheme.STAT_TOOLTIPS["stress"]))
	_pill_affection = _make_pill(h, AstralTheme.ROSE, str(AstralTheme.STAT_TOOLTIPS["affection"]))
	_audio_btn = AstralTheme.button(AstralTheme.G_STAR2 + "  Audio: ON", "", "Activar o silenciar los sonidos del observatorio")
	_audio_btn.custom_minimum_size = Vector2(124, 42)
	_audio_btn.pressed.connect(func() -> void: AstralAudio.toggle_mute())
	AstralAudio.mute_changed.connect(_sync_audio_btn)
	_sync_audio_btn(AstralAudio.muted)
	h.add_child(_audio_btn)
	var menu_btn := AstralTheme.button(AstralTheme.G_ORNAMENT + "  Menú", "", "Menú del observatorio (Esc)")
	menu_btn.custom_minimum_size = Vector2(108, 42)
	menu_btn.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		_menu.open_pause(GameState.prologue_completed))
	h.add_child(menu_btn)
	return bar

func _sync_audio_btn(is_muted: bool) -> void:
	if _audio_btn != null:
		_audio_btn.text = "%s  Audio: OFF" % AstralTheme.G_CROSS if is_muted else "%s  Audio: ON" % AstralTheme.G_STAR2

func _make_pill(parent: Control, color: Color, tip: String) -> Label:
	var p := PanelContainer.new()
	p.theme_type_variation = "PillPanel"
	p.tooltip_text = tip
	var l := AstralTheme.label("0", "", color)
	l.custom_minimum_size.x = 104
	l.add_theme_font_size_override("font_size", 19)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(l)
	parent.add_child(p)
	return l

func _build_dock() -> Control:
	var dock := PanelContainer.new()
	dock.theme_type_variation = "BarPanel"
	dock.custom_minimum_size.x = 304
	var v := AstralTheme.vbox(6)
	dock.add_child(v)

	var head := AstralTheme.hbox(10)
	v.add_child(head)
	_dock_medallion = TextureRect.new()
	_dock_medallion.custom_minimum_size = Vector2(58, 58)
	_dock_medallion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dock_medallion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(_dock_medallion)
	var hv := AstralTheme.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	_lbl_seal_heading = AstralTheme.label("ARMONÍA DE RENPET", "HeadingLabel")
	_lbl_seal_heading.add_theme_font_size_override("font_size", 22)
	hv.add_child(_lbl_seal_heading)
	_lbl_seal_title = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ, true)
	hv.add_child(_lbl_seal_title)

	_bar_anchor = StatBar.new().setup(GameState.get_stat_label("human_anchor"), "human_anchor", 0, 100, AstralTheme.STAT_COLORS["human_anchor"], str(AstralTheme.STAT_TOOLTIPS["human_anchor"]), 130)
	_bar_seal = StatBar.new().setup(GameState.get_stat_label("seal_integrity"), "seal_integrity", 0, 100, AstralTheme.STAT_COLORS["seal_integrity"], str(AstralTheme.STAT_TOOLTIPS["seal_integrity"]), 130)
	_bar_sync = StatBar.new().setup(GameState.get_stat_label("abyssal_sync"), "abyssal_sync", 0, 100, AstralTheme.STAT_COLORS["abyssal_sync"], str(AstralTheme.STAT_TOOLTIPS["abyssal_sync"]), 130)
	for b in [_bar_anchor, _bar_seal, _bar_sync]:
		(b as StatBar).custom_minimum_size.y = 22
		v.add_child(b)

	var status_row := AstralTheme.hbox(6)
	v.add_child(status_row)
	var mood_pill := AstralTheme.panel("SunkenPanel")
	mood_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_mood_chip = AstralTheme.label("Serena", "CaptionLabel", AstralTheme.GOLD_PALE)
	_lbl_mood_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_mood_chip.mouse_filter = Control.MOUSE_FILTER_PASS
	mood_pill.add_child(_lbl_mood_chip)
	status_row.add_child(mood_pill)

	var susp_pill := AstralTheme.panel("SunkenPanel")
	susp_pill.custom_minimum_size.x = 96
	_lbl_susp_chip = AstralTheme.label("⚖ 0%", "CaptionLabel", AstralTheme.MUTED)
	_lbl_susp_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_susp_chip.mouse_filter = Control.MOUSE_FILTER_PASS
	susp_pill.add_child(_lbl_susp_chip)
	status_row.add_child(susp_pill)

	var goal_box := AstralTheme.panel("SunkenPanel")
	v.add_child(goal_box)
	var gv := AstralTheme.vbox(3)
	goal_box.add_child(gv)
	_lbl_goal = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ, true)
	_lbl_goal.mouse_filter = Control.MOUSE_FILTER_PASS
	gv.add_child(_lbl_goal)
	_bar_goal = AstralTheme.mini_bar(0.0, 1.0, AstralTheme.GOLD, 8.0)
	gv.add_child(_bar_goal)

	v.add_child(AstralTheme.separator())
	v.add_child(AstralTheme.label("OBSERVATORIO", "SubLabel"))

	for i in range(NAV_ITEMS.size()):
		var item: Dictionary = NAV_ITEMS[i]
		var btn := Button.new()
		btn.theme_type_variation = "NavButton"
		btn.toggle_mode = true
		btn.custom_minimum_size.y = 50
		btn.focus_mode = Control.FOCUS_ALL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = "%s\nAtajo: tecla %d" % [str(item["sub"]), i + 1]
		var row := AstralTheme.hbox(10)
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_right = -10
		row.offset_top = 4
		row.offset_bottom = -4
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(row)
		var icon_w := AstralTheme.vignette_card(str(item["icon"]), Vector2(52, 36), AstralTheme.GOLD_DARK)
		icon_w.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_w)
		var tv := AstralTheme.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tv)
		var t1 := AstralTheme.label(str(item["title"]), "", AstralTheme.GOLD_PALE)
		t1.add_theme_font_override("font", AstralTheme.font("Bold"))
		t1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(t1)
		if item["id"] == "status":
			_status_nav_title = t1
		var wid: String = item["id"]
		var bdg := AstralTheme.label("", "CaptionLabel", AstralTheme.GOLD)
		bdg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bdg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bdg)
		_nav_badges[wid] = bdg
		btn.pressed.connect(func() -> void: _toggle_window(wid))
		v.add_child(btn)
		_nav_buttons[wid] = btn

	v.add_child(AstralTheme.separator())
	_city_btn = Button.new()
	_city_btn.theme_type_variation = "PrimaryButton"
	_city_btn.custom_minimum_size.y = 54
	_city_btn.focus_mode = Control.FOCUS_ALL
	_city_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_city_btn.tooltip_text = "Sal de la mansión al mapa de Aethelgard: distritos, tiendas, vínculos, expediciones y festival.\nAtajo: tecla 5"
	var crow := AstralTheme.hbox(10)
	crow.set_anchors_preset(Control.PRESET_FULL_RECT)
	crow.offset_left = 10
	crow.offset_right = -10
	crow.offset_top = 4
	crow.offset_bottom = -4
	crow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_city_btn.add_child(crow)
	var cicon := AstralTheme.vignette_card("res://assets/art/bg_town_map.png", Vector2(52, 36), AstralTheme.GOLD)
	cicon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cicon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crow.add_child(cicon)
	var clbl := AstralTheme.label("✦ Salir a Aethelgard", "", AstralTheme.IVORY)
	clbl.add_theme_font_override("font", AstralTheme.font("Bold"))
	clbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crow.add_child(clbl)
	_city_badge = AstralTheme.label("", "CaptionLabel", AstralTheme.GOLD)
	_city_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crow.add_child(_city_badge)
	_city_btn.pressed.connect(func() -> void: _open_city_map(""))
	v.add_child(_city_btn)

	v.add_child(AstralTheme.spacer())
	var clear_btn := AstralTheme.button("%s  Contemplar el observatorio" % AstralTheme.G_STAR2, "TabLikeButton", "Oculta la interfaz para ver el fondo.")
	clear_btn.pressed.connect(func() -> void: _set_ui_visible(false))
	v.add_child(clear_btn)
	return dock

func _build_windows() -> void:
	var defs: Dictionary = {
		"schedule": SchedulePlanner.new(), "status": StatusSheet.new(),
		"hearth": HearthWindow.new(), "crucible": AstralCrucible.new()
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
	(_windows["hearth"] as HearthWindow).vacation_taken.connect(func(_vid: String) -> void: _refresh_all())
	(_windows["hearth"] as HearthWindow).crisis_requested.connect(_open_pending_crisis)

func _build_stage() -> Control:
	var s := Control.new()
	s.custom_minimum_size.x = 460
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	s.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	s.tooltip_text = "Haz clic para hablar con tu hija o atrapa chispas brillantes del cielo (+8 G / -2 Estrés)"
	s.gui_input.connect(_on_stage_input)

	_ring_outer = _stage_tex("res://assets/ui/astrolabe_ring_outer.png", Color(1.0, 0.95, 0.8, 0.85))
	_ring_inner = _stage_tex("res://assets/ui/astrolabe_ring_inner.png", Color(0.75, 0.95, 1.0, 0.9))
	_portrait = _stage_tex("res://assets/art/renpet_portrait.png", Color.WHITE)
	s.add_child(_ring_outer)
	s.add_child(_ring_inner)
	s.add_child(_portrait)

	_stage_fx = _StageFX.new()
	s.add_child(_stage_fx)

	_ritual_btn = AstralTheme.button("%s  Sintonizar Astrolabio" % AstralTheme.G_ANKH, "TabLikeButton",
		"Minijuego visual (1 vez por bimestre): alinea las 3 órbitas con el cenit para ganar Luminiscencia, Resonancia y reducir Estrés.")
	_ritual_btn.anchor_left = 0.5
	_ritual_btn.anchor_right = 0.5
	_ritual_btn.anchor_top = 0.0
	_ritual_btn.anchor_bottom = 0.0
	_ritual_btn.offset_left = -132
	_ritual_btn.offset_right = 132
	_ritual_btn.offset_top = 4
	_ritual_btn.offset_bottom = 42
	_ritual_btn.pressed.connect(_open_ritual)
	s.add_child(_ritual_btn)

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
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nameplate = AstralTheme.label("", "", AstralTheme.GOLD_PALE, true)
	_nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(_nameplate)
	s.add_child(plate)
	s.resized.connect(_layout_stage)
	return s

func _on_stage_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _current_window != "" or _any_overlay_visible():
			return
		var me: InputEventMouseButton = event
		if _stage_fx != null:
			var mote_hit: Dictionary = _stage_fx.try_collect_mote(me.position)
			if bool(mote_hit.get("hit", false)):
				if str(mote_hit.get("kind", "gold")) == "calm":
					var d_s: int = GameState.modify_stat("stress", -2)
					_spawn_stage_float(me.position, "%s Estrés %s" % [AstralTheme.G_STAR2, AstralTheme.signed(d_s if d_s != 0 else -2)], AstralTheme.TURQ)
					toast("Chispa serena capturada: Estrés %s" % AstralTheme.signed(d_s if d_s != 0 else -2), "good")
				else:
					GameState.modify_gold(8)
					_spawn_stage_float(me.position, "%s +8 Oro" % AstralTheme.G_SUN, AstralTheme.GOLD)
					toast("Chispa áurea capturada: +8 Oro", "good")
				AstralAudio.play_confirm()
				_refresh_all()
				return
		_portrait.scale = Vector2(1.045, 1.045)
		if _stage_fx != null:
			_stage_fx.spawn_burst(me.position, AstralTheme.GOLD_PALE, 10)
			_spawn_stage_float(me.position, AstralTheme.G_HEART if GameState.affection >= 70 else AstralTheme.G_STAR2, AstralTheme.GOLD_PALE)
		AstralAudio.play_ui()
		_say_stage_reaction()

func _spawn_stage_float(pos: Vector2, txt: String, col: Color) -> void:
	if _stage_fx == null or DisplayServer.get_name() == "headless":
		return
	var l := AstralTheme.label(txt, "SubLabel", col)
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.1, 0.95))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos + Vector2(-46.0, -18.0)
	_stage_fx.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 42.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.85).set_delay(0.18)
	tw.chain().tween_callback(l.queue_free)

func _open_ritual() -> void:
	if _busy or _any_overlay_visible() or TurnExecutor.astrolabe_tuned_this_bimester:
		return
	_close_windows()
	_ritual.open_ritual()

func _on_ritual_completed(summary: String, kind: String) -> void:
	toast(summary, kind)
	say("%s — Astrolabio Celeste" % GameState.daughter_name, "\"¡Siento los anillos del observatorio resonar en armonía, Padre! (%s)\"" % summary)
	_refresh_all()

func _say_stage_reaction() -> void:
	var pool: Array[String] = []
	if GameState.stress >= 75:
		pool.append("\"Me duele un poco la cabeza de tanto estudiar, Padre... ¿podemos descansar un decano pronto?\"")
	if TimeManager.is_festival_bimester():
		pool.append("\"¡Las banderas del Festival de Otoño ya ondean en el Anfiteatro! Cuando quieras competir, salgamos a Aethelgard.\"")
	if GameState.affection >= 75:
		pool.append("\"Cuando giro la cabeza y te veo en el observatorio, cualquier tormenta del cielo parece más fácil.\"")
	if not GameState.active_traits.is_empty():
		pool.append("\"Siento que últimamente me dicen mucho «%s»... Supongo que los astros notan en qué me convierto.\"" % GameState.active_traits[0])
	if GameState.get_secret_tier() >= 2:
		pool.append("\"Ya no le temo al reloj que late en mi pecho, Padre. Sea cual sea el Solsticio, caminaremos juntos.\"")
	elif GameState.get_secret_tier() == 1:
		pool.append("\"A veces veo jeroglíficos dorados en el rabillo del ojo cuando miro las estrellas... ¿tú también los sientes?\"")
	var voc: Dictionary = EndingEvaluator.get_projected_vocation()
	pool.append("\"Con todo lo que estoy aprendiendo, me imagino algún día sirviendo como %s.\"" % str(voc.get("name", "Hija de la Estrella")))
	pool.append(GameState.get_dynamic_manor_greeting())
	_stage_tip_idx = (_stage_tip_idx + 1) % pool.size()
	say("%s — Mansión Solar" % GameState.daughter_name, pool[_stage_tip_idx])

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
	_portrait.pivot_offset = _portrait.size * 0.5
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
	bar.custom_minimum_size.y = 94
	bar.gui_input.connect(_on_dialogue_input)
	var h := AstralTheme.hbox(14)
	bar.add_child(h)
	_dlg_medallion = TextureRect.new()
	_dlg_medallion.custom_minimum_size = Vector2(64, 64)
	_dlg_medallion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dlg_medallion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dlg_medallion.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_dlg_medallion)
	var mid := AstralTheme.vbox(2)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(mid)
	_lbl_speaker = AstralTheme.label("", "SubLabel", AstralTheme.GOLD)
	mid.add_child(_lbl_speaker)
	_lbl_dialogue = AstralTheme.rich("")
	_lbl_dialogue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lbl_dialogue.fit_content = false
	_lbl_dialogue.scroll_active = true
	_lbl_dialogue.custom_minimum_size.y = 50
	mid.add_child(_lbl_dialogue)
	var side := AstralTheme.vbox(6)
	side.custom_minimum_size.x = 232
	h.add_child(side)
	_btn_talk = AstralTheme.button(AstralTheme.G_FLOWER + "  Conversar con %s" % GameState.daughter_name, "", "Abre la Chimenea y Hogar")
	_btn_talk.custom_minimum_size.y = 38
	_btn_talk.pressed.connect(func() -> void: _open_window("hearth"))
	side.add_child(_btn_talk)
	var b2 := AstralTheme.button(AstralTheme.G_STAR + "  Libro del Bimestre", "PrimaryButton")
	b2.custom_minimum_size.y = 40
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
	_exec = ExecutionOverlay.new()
	_ritual = AstrolabeRitualOverlay.new()
	_school_mg = TrainingMinigameOverlay.new()
	_city_map = CityMapOverlay.new()
	_tutorial = TutorialOverlay.new()
	for o in [_exec, _city_map, _report, _letter, _bond, _combat, _story, _ritual, _school_mg, _tutorial, _menu, _ending, _prologue]:
		add_child(o)
	_prologue.finished.connect(_on_prologue_finished)
	_ritual.ritual_completed.connect(_on_ritual_completed)
	_school_mg.challenge_completed.connect(_on_minigame_challenge_completed)
	_school_mg.minigame_finished.connect(func(sum: String) -> void:
		if _mg_context == "":
			toast(sum, "good")
			say("%s — Entrenamiento" % GameState.daughter_name, sum)
		_refresh_all())
	_city_map.closed.connect(_on_city_map_closed)
	_city_map.speak.connect(say)
	_city_map.toast.connect(toast)
	_city_map.state_changed.connect(_queue_refresh)
	_city_map.bond_event_requested.connect(func(npc: String) -> void: _bond.play(npc))
	_city_map.expedition_requested.connect(func(zidx: int, cid: String, cname: String) -> void:
		var r: Dictionary = ExplorationCombat.start_expedition(zidx, cid, cname)
		if bool(r.get("ok", false)):
			_combat.open_combat()
		else:
			toast(str(r.get("msg", "No se pudo iniciar la expedición.")), "warn"))
	_city_map.festival_minigame_requested.connect(func(mode: String, title_text: String) -> void:
		var is_fest: bool = ("FESTIVAL" in title_text)
		_mg_context = "festival" if is_fest else "practice"
		_school_mg.open_minigame(mode, true, title_text, not is_fest))
	_exec.report_requested.connect(func(_r: Dictionary) -> void: _wants_report = true)
	_bond.resolved.connect(func(_npc: String) -> void:
		toast("Escena completada", "good")
		SaveManager.autosave()
		if _city_map != null and _city_map.visible:
			_city_map.refresh()
		_refresh_all())
	_combat.expedition_ended.connect(_on_expedition_ended)
	_menu.save_done.connect(func(slot: int) -> void: toast("Partida guardada en la ranura %d" % slot, "good"))
	_menu.load_requested.connect(_load_slot)
	_menu.title_requested.connect(_go_title)
	_menu.tutorial_requested.connect(func() -> void: _tutorial.open_tutorial(0))
	_tutorial.finished.connect(func() -> void: toast("Guía completada. ¡Comienza tu primer bimestre!", "good"))
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
# VENTANAS Y CIUDAD DE AETHELGARD
# ------------------------------------------------------------------------------
func _open_city_map(district_id: String = "") -> void:
	if _busy:
		return
	AstralAudio.play_ui()
	_close_windows()
	_set_ui_visible(true)
	if _ui_root != null:
		_ui_root.visible = false
	if _stage_fx != null:
		_stage_fx.motes_enabled = false
	_city_map.open_city(district_id)

func _on_city_map_closed() -> void:
	if _ui_root != null:
		_ui_root.visible = true
	if _stage != null:
		_stage.visible = (_current_window == "")
	if _center != null:
		_center.visible = (_current_window != "")
	if _stage_fx != null:
		_stage_fx.motes_enabled = (_current_window == "" and not _any_overlay_visible())
	_refresh_all()

func _toggle_window(id: String) -> void:
	if _current_window == id:
		(_windows[id] as BaseWindow).close()
	else:
		_open_window(id)

func _open_window(id: String) -> void:
	if id == "town":
		_open_city_map("")
		return
	if id == "explore":
		_open_city_map("patio")
		return
	if id == "festival":
		_open_city_map("anfiteatro")
		return
	if not _windows.has(id):
		return
	AstralAudio.play_ui()
	if _current_window != "" and _current_window != id:
		var prev: BaseWindow = _windows[_current_window]
		prev.visible = false
	_current_window = id
	for k in _nav_buttons.keys():
		(_nav_buttons[k] as Button).set_pressed_no_signal(k == id)
	if _stage != null:
		_stage.visible = false
	if _center != null:
		_center.visible = true
	if _stage_fx != null:
		_stage_fx.motes_enabled = false
	var w: BaseWindow = _windows[id]
	w.modulate.a = 0.0 if DisplayServer.get_name() != "headless" else 1.0
	w.open()
	if DisplayServer.get_name() != "headless":
		var wtw := w.create_tween()
		wtw.tween_property(w, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_window_closed(id: String) -> void:
	if _current_window == id:
		_current_window = ""
	if _nav_buttons.has(id):
		(_nav_buttons[id] as Button).set_pressed_no_signal(false)
	if _stage != null and _current_window == "":
		_stage.visible = true
	if _center != null and _current_window == "":
		_center.visible = false
	if _stage_fx != null:
		_stage_fx.motes_enabled = (_current_window == "" and not _any_overlay_visible())
	_queue_refresh()

func _close_windows() -> void:
	for id in _windows.keys():
		(_windows[id] as BaseWindow).visible = false
	for k in _nav_buttons.keys():
		(_nav_buttons[k] as Button).set_pressed_no_signal(false)
	_current_window = ""
	if _stage != null:
		_stage.visible = true
	if _center != null:
		_center.visible = false

func _any_overlay_visible() -> bool:
	for o in [_prologue, _exec, _city_map, _report, _letter, _bond, _combat, _story, _ritual, _school_mg, _tutorial, _menu, _ending]:
		if o != null and (o as Control).visible:
			return true
	return false

func _set_ui_visible(v: bool) -> void:
	if _city_map != null and _city_map.visible:
		return
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
			elif _tutorial != null and _tutorial.visible:
				_tutorial._finish()
				get_viewport().set_input_as_handled()
			elif _school_mg != null and _school_mg.visible:
				_school_mg._cancel_or_close()
				get_viewport().set_input_as_handled()
			elif _exec != null and _exec.visible:
				_exec._finish_sequence()
				get_viewport().set_input_as_handled()
			elif _ritual != null and _ritual.visible:
				_ritual.hide_overlay()
				get_viewport().set_input_as_handled()
			elif _menu.visible or _letter.visible:
				(_menu if _menu.visible else _letter).hide_overlay()
				get_viewport().set_input_as_handled()
			elif _city_map != null and _city_map.visible and not (_bond.visible or _combat.visible or _story.visible):
				_city_map.close_overlay()
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
	if k.keycode == KEY_5:
		_open_city_map("")
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
func _open_pending_crisis() -> void:
	var ev: Dictionary = ExplorationCombat.check_pending_main_story_event()
	if bool(ev.get("has_event", false)):
		_close_windows()
		_story.show_story_event(ev)

func _execute_turn() -> void:
	if _busy:
		return
	if TurnExecutor.agenda.size() < 3 or TurnExecutor.agenda.any(func(s: Variant) -> bool: return str(s) == ""):
		toast("Asigna los 3 decanos de Renpet antes de ejecutar.", "warn")
		return
	_busy = true
	var chal: Dictionary = TurnExecutor.find_practical_challenge()
	if not chal.is_empty() and DisplayServer.get_name() != "headless":
		_close_windows()
		_practical_act_pending = str(chal.get("act_id", ""))
		_mg_context = "practical_turn"
		_school_mg.open_minigame(str(chal.get("mode", "fencing")), true, str(chal.get("title", "")), false)
		return
	_run_turn_resolution()

func _on_minigame_challenge_completed(mode: String, score: int, _max_score: int, pct: float) -> void:
	var ctx: String = _mg_context
	_mg_context = ""
	if ctx == "festival" or ctx == "practice":
		if _city_map != null and _city_map.visible:
			_city_map.notify_minigame_finished(mode, score, pct)
	elif ctx == "practical_turn":
		TurnExecutor.pending_practical_act = _practical_act_pending
		TurnExecutor.pending_practical_bonus = 0.35 if pct >= 0.80 else (0.20 if pct >= 0.50 else 0.10)
		_practical_act_pending = ""
		if _school_mg.visible:
			await _school_mg.hidden
		_run_turn_resolution()

func _run_turn_resolution() -> void:
	_wants_report = false
	var rep: Dictionary = TurnExecutor.resolve_bimester()
	if not rep.get("ok", false):
		toast(str(rep.get("msg", "No se puede ejecutar el bimestre.")), "bad")
		_busy = false
		return
	_close_windows()
	_refresh_all()
	if DisplayServer.get_name() != "headless":
		_exec.play_bimester(rep)
		await _exec.sequence_finished
		if _wants_report or not SettingsManager.unified_turn_end:
			_report.show_report(rep)
			await _report.closed
	else:
		AstralAudio.play_turn_end()
		if not SettingsManager.unified_turn_end:
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
		AstralAudio.set_music_mood("ending")
		_ending.show_ending()
		_busy = false
		return
	say("%s — Mansión Solar" % GameState.daughter_name, GameState.get_dynamic_manor_greeting())
	if TimeManager.is_festival_bimester():
		AstralAudio.play_confirm()
		toast("✦ ¡Festival de Otoño abierto! Sal a Aethelgard → Anfiteatro para competir.", "good")
	else:
		toast("Autoguardado — %s" % TimeManager.get_bimester_info()["name"], "good")
	_busy = false

func _on_expedition_ended(victory: bool, _summary: String) -> void:
	SaveManager.autosave()
	_refresh_all()
	if victory:
		AstralAudio.play_triumph()
		toast("Expedición completada con éxito", "good")
		say(GameState.daughter_name, "\"¡Volvimos sanos y salvos al observatorio, Padre! Traemos reliquias y nuevos recuerdos del cielo.\"")
	else:
		AstralAudio.play_warn()
		toast("Retirada de la expedición", "warn")
		var seal_word: String = "el Sello" if GameState.get_secret_tier() >= 2 else "su estrella"
		say(GameState.daughter_name, "\"Tuvimos que retroceder antes de que %s sufriera más... Descansaré un poco.\"" % seal_word)
	if _city_map != null and _city_map.visible:
		_city_map.refresh()

func _on_festival_completed(res: Dictionary) -> void:
	SaveManager.autosave()
	_refresh_all()
	if bool(res.get("won", false)):
		AstralAudio.play_triumph()
		say(GameState.daughter_name, "\"¡Lo logramos, Padre! ¡Toda la capital coreó nuestro nombre en el Coliseo de las Constelaciones!\"")
	else:
		AstralAudio.play_confirm()
		say(GameState.daughter_name, "\"El rival estuvo muy fuerte esta vez, Padre, pero aprendí muchísimo en el escenario imperial.\"")

func _load_slot(slot: int) -> void:
	var res: Dictionary = SaveManager.load_game(slot)
	if res.get("ok", false):
		if _city_map != null and _city_map.visible:
			_city_map.visible = false
		if _ui_root != null:
			_ui_root.visible = true
		_close_windows()
		_refresh_all()
		say("%s — Mansión Solar" % GameState.daughter_name, GameState.get_dynamic_manor_greeting())
		toast("Partida cargada", "good")
	else:
		toast(str(res.get("msg", "No se pudo cargar.")), "bad")

func _go_title() -> void:
	if _fade_curtain != null and DisplayServer.get_name() != "headless":
		var ftw := create_tween()
		ftw.tween_property(_fade_curtain, "color:a", 1.0, 0.25)
		await ftw.finished
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
	if GameState.prologue_completed:
		var g_prog: Dictionary = GameState.check_annual_goal_progress()
		if bool(g_prog.get("completed_now", false)):
			AstralAudio.play_triumph()
			toast("✦ Objetivo Anual cumplido: %s (+100 G, +8 Afecto)" % str(g_prog.get("title", "")), "good")
		AstralAudio.set_music_mood("tension" if (TimeManager.get_act_number() >= 2 or GameState.court_suspicion >= 60) else "manor")
	var bim: Dictionary = TimeManager.get_bimester_info()
	_lbl_date.text = "Edad %d  ·  %s" % [GameState.age, bim["name"]]
	var phen: String = str(bim.get("phenomenon", "")).get_slice(":", 0)
	_lbl_era.text = "Acto %d  ·  Turno %d/%d  ·  %s" % [TimeManager.get_act_number(), TimeManager.current_total_turn, TimeManager.TOTAL_TURNS, phen]
	_lbl_era.tooltip_text = "%s\n%s" % [TimeManager.get_era_title(), str(bim.get("phenomenon", ""))]
	_pill_gold.text = "%s %d G" % [AstralTheme.G_SUN, GameState.gold]
	var free: int = GameState.father_energy - TurnExecutor.get_father_energy_used()
	_pill_energy.text = "%s %d/%d" % [AstralTheme.G_ANKH, free, GameState.father_max_energy]
	_pill_stress.text = ("%s %d%%!" % [AstralTheme.G_BOLT, GameState.stress]) if GameState.exhausted_sick else ("%s %d%%" % [AstralTheme.G_MOON, GameState.stress])
	_pill_stress.add_theme_color_override("font_color", AstralTheme.BAD if (GameState.exhausted_sick or GameState.stress >= 80) else (AstralTheme.EMBER if GameState.stress >= 60 else AstralTheme.GOOD))
	_pill_affection.text = "%s %d%%" % [AstralTheme.G_HEART, GameState.affection]
	_bar_anchor.set_value(GameState.human_anchor)
	_bar_anchor.set_tooltip(GameState.get_stat_tooltip("human_anchor"))
	_bar_seal.set_title(GameState.get_stat_label("seal_integrity"))
	_bar_seal.set_value(GameState.seal_integrity)
	_bar_seal.set_tooltip(GameState.get_stat_tooltip("seal_integrity"))
	_bar_sync.set_title(GameState.get_stat_label("abyssal_sync"))
	_bar_sync.set_value(GameState.abyssal_sync)
	_bar_sync.set_tooltip(GameState.get_stat_tooltip("abyssal_sync"))
	if _lbl_mood_chip != null:
		var msum: Dictionary = GameState.get_mood_summary()
		_lbl_mood_chip.text = "%s %s" % [AstralTheme.G_FLOWER, str(msum["short_tag"])]
		_lbl_mood_chip.tooltip_text = "Temperamento actual: %s (+20%% aulas afines, -15%% opuestas)" % str(msum["short_tag"])
	if _lbl_susp_chip != null:
		_lbl_susp_chip.text = "%s %d%%" % [AstralTheme.G_SCALES, GameState.court_suspicion]
		_lbl_susp_chip.add_theme_color_override("font_color", AstralTheme.BAD if GameState.court_suspicion >= 65 else (AstralTheme.EMBER if GameState.court_suspicion >= 35 else AstralTheme.MUTED))
		_lbl_susp_chip.tooltip_text = GameState.get_stat_tooltip("court_suspicion")
	if _lbl_goal != null:
		var gst: Dictionary = GameState.get_annual_goal_status()
		var g_cur: int = int(gst.get("current", 0))
		var g_tgt: int = maxi(1, int(gst.get("target", 1)))
		var g_done: bool = bool(gst.get("completed", false))
		_lbl_goal.text = "%s %s" % [AstralTheme.G_CHECK, str(gst.get("title", "Meta"))] if g_done else "Meta (%d/%d): %s" % [g_cur, g_tgt, str(gst.get("title", ""))]
		_lbl_goal.add_theme_color_override("font_color", AstralTheme.GOOD if g_done else AstralTheme.TURQ)
		_lbl_goal.tooltip_text = "Meta anual (+100 G y +8 Afecto al completarla)"
		if _bar_goal != null:
			_bar_goal.max_value = float(g_tgt)
			_bar_goal.value = float(g_tgt if g_done else mini(g_cur, g_tgt))
			AstralTheme.style_bar(_bar_goal, AstralTheme.GOOD if g_done else AstralTheme.GOLD)
	var tier: int = GameState.get_secret_tier()
	_lbl_seal_heading.text = "ESTADO DEL SELLO" if tier >= 2 else ("RESGUARDO ESTELAR" if tier == 1 else "ARMONÍA DE RENPET")
	var cracked: bool = (tier >= 2 and GameState.seal_integrity < 50)
	var med_path: String = "res://assets/ui/seal_medallion_cracked.png" if cracked else "res://assets/ui/seal_medallion_intact.png"
	_dock_medallion.texture = load(med_path)
	_dlg_medallion.texture = _dock_medallion.texture
	_lbl_seal_title.text = GameState.get_metaphysical_state_title()
	if _status_nav_title != null:
		_status_nav_title.text = "II. Ficha de %s" % GameState.daughter_name
	if _btn_talk != null:
		_btn_talk.text = "%s  Conversar con %s" % [AstralTheme.G_FLOWER, GameState.daughter_name]
	if _ritual_btn != null:
		var tuned: bool = TurnExecutor.astrolabe_tuned_this_bimester
		_ritual_btn.disabled = tuned
		_ritual_btn.text = "%s  Astrolabio Sintonizado" % AstralTheme.G_CHECK if tuned else "%s  Sintonizar Astrolabio" % AstralTheme.G_ANKH
	if _bg_rect != null:
		var want_bg: String = GameState.active_vacation_bg if GameState.active_vacation_bg != "" else "res://assets/art/bg_manor_observatory.png"
		var btex: Texture2D = AstralTheme.load_tex(want_bg, "res://assets/art/bg_manor_observatory.png")
		if btex != null:
			_bg_rect.texture = btex
	if _bg_shade != null:
		var act_n: int = TimeManager.get_act_number()
		var veil_a: float = 0.22 if GameState.active_vacation_bg != "" else (0.38 if act_n <= 1 else (0.45 if act_n == 2 else 0.52))
		_bg_shade.color = Color(0.02, 0.03, 0.10, veil_a)
	var ptex: Texture2D = AstralTheme.load_tex(GameState.get_active_portrait_path(), "res://assets/art/renpet_portrait.png")
	if ptex != null:
		_portrait.texture = ptex
	if _stage_fx != null:
		_stage_fx.motes_enabled = (_current_window == "" and not _any_overlay_visible())
		_stage_fx.mutations_flags = GameState.active_mutations.duplicate()
		_stage_fx.seal_cracks_ratio = clampf(float(55 - GameState.seal_integrity) / 55.0, 0.0, 1.0) if GameState.seal_integrity < 55 else 0.0
		_stage_fx.exhausted_mode = GameState.exhausted_sick
		_stage_fx.season_index = TimeManager.current_bimester
		_stage_fx.sync_ratio = clampf(float(GameState.abyssal_sync) / 100.0, 0.0, 1.0)
	_refresh_nav_badges()
	var voc_proj: Dictionary = EndingEvaluator.get_projected_vocation()
	_nameplate.text = "%s — %s  %s  %s" % [
		GameState.daughter_name,
		GameState.get_metaphysical_state_title().get_slice(":", 0),
		AstralTheme.G_STAR2,
		str(voc_proj.get("name", ""))
	]
	if GameState.exhausted_sick:
		_portrait.modulate = Color(0.76, 0.78, 0.92)
	elif GameState.abyssal_sync >= 50:
		_portrait.modulate = Color(0.92, 0.86, 1.0)
	elif GameState.mood_calm >= 20:
		_portrait.modulate = Color(1.0, 0.98, 0.92)
	else:
		_portrait.modulate = Color.WHITE
	if GameState.seal_integrity < 45 or GameState.entropia >= 70:
		_ring_outer.modulate = Color(1.0, 0.58, 0.78, 0.90)
		_ring_inner.modulate = Color(0.92, 0.56, 1.0, 0.94)
	elif GameState.abyssal_sync >= 55:
		_ring_outer.modulate = Color(0.86, 0.78, 1.0, 0.90)
		_ring_inner.modulate = Color(0.65, 0.92, 1.0, 0.92)
	elif GameState.human_anchor >= 75:
		_ring_outer.modulate = Color(1.0, 0.94, 0.72, 0.92)
		_ring_inner.modulate = Color(0.95, 0.98, 0.82, 0.92)
	else:
		_ring_outer.modulate = Color(1.0, 0.95, 0.8, 0.85)
		_ring_inner.modulate = Color(0.75, 0.95, 1.0, 0.9)
	if _current_window != "" and (_windows[_current_window] as BaseWindow).visible:
		(_windows[_current_window] as BaseWindow).refresh()

func _refresh_nav_badges() -> void:
	if _nav_badges.has("schedule"):
		(_nav_badges["schedule"] as Label).text = AstralTheme.G_BOLT if GameState.exhausted_sick else ""
	if _nav_badges.has("hearth"):
		var vac_ok: bool = (not CatalogDB.get_vacation_for_bimester(TimeManager.current_bimester).is_empty()) and (not GameState.vacation_used_years.has(TimeManager.current_year))
		(_nav_badges["hearth"] as Label).text = AstralTheme.G_BOLT if GameState.exhausted_sick else ("✦" if (not Chronicle.chatted_this_bimester or vac_ok) else "")
	if _nav_badges.has("crucible"):
		var has_mat: bool = false
		for mv in GameState.materials_inventory.values():
			if int(mv) > 0:
				has_mat = true
				break
		(_nav_badges["crucible"] as Label).text = "✦" if has_mat else ""
	if _city_badge != null:
		var fest_open: bool = TimeManager.is_festival_bimester() and not ExplorationCombat.festival_entered_this_year
		var has_ev: bool = false
		for nid in RelationshipManager.NPC_ORDER:
			if RelationshipManager.is_available(nid) and bool(RelationshipManager.get_next_bond_event(nid).get("ok", false)):
				has_ev = true
				break
		var sp_s: String = "%d PS" % RelationshipManager.social_points_left
		if fest_open:
			_city_badge.text = "★ Fest · " + sp_s
		elif GameState.court_suspicion >= 65:
			_city_badge.text = "⚖ " + sp_s
		elif has_ev:
			_city_badge.text = "✉ " + sp_s
		else:
			_city_badge.text = sp_s

# ------------------------------------------------------------------------------
# DIÁLOGO Y AVISOS
# ------------------------------------------------------------------------------
func say(speaker: String, text: String) -> void:
	_lbl_speaker.text = speaker
	_lbl_dialogue.text = text
	if _typing != null and _typing.is_valid():
		_typing.kill()
	var dur: float = SettingsManager.get_typewriter_duration(text.length())
	if dur <= 0.01:
		_lbl_dialogue.visible_ratio = 1.0
		return
	_lbl_dialogue.visible_ratio = 0.0
	var secs: float = clampf(dur * 0.65, 0.25, 2.4)
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

func debug_open_city(dist_id: String = "") -> void:
	_open_city_map(dist_id)

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
	RelationshipManager.state["soren"]["known"] = true
	RelationshipManager.state["soren"]["affection"] = 52
	RelationshipManager.state["soren"]["stage"] = 2
	RelationshipManager.state["vespera"]["known"] = true
	RelationshipManager.state["vespera"]["affection"] = -50
	RelationshipManager.state["vespera"]["stage"] = 2
	RelationshipManager.state["mirari"]["known"] = true
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
	SettingsManager.toggle_fullscreen()
