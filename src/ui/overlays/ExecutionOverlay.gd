extends ModalOverlay
class_name ExecutionOverlay

## ExecutionOverlay - Secuencia animada de paso de tiempo (60 días / 3 Decanos) al ejecutar un bimestre.
## Visualiza el giro del astrolabio, el avance de los días y las ganancias de cada Decano sin paredes de texto.

signal sequence_finished()
signal report_requested(report: Dictionary)

class _DialCanvas extends Control:
	var progress: float = 0.0
	var active_decano: int = -1
	var pulse_time: float = 0.0
	var flare: float = 0.0
	var comet_trail: Array[Vector2] = []

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		pulse_time += delta
		if flare > 0.0:
			flare = maxf(0.0, flare - delta * 2.4)
		queue_redraw()

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var r_out: float = minf(size.x, size.y) * 0.44
		var r_mid: float = r_out * 0.74
		var r_in: float = r_out * 0.44

		# Resplandor de fondo
		draw_circle(c, r_out * 1.08, Color(0.08, 0.14, 0.30, 0.36))
		draw_circle(c, r_in * (1.1 + flare * 0.18), Color(0.24, 0.68, 0.66, 0.12 + flare * 0.18))

		# Arcos de los 3 Decanos
		var sector_span: float = TAU / 3.0
		for d in range(3):
			var a0: float = -PI * 0.5 + float(d) * sector_span + 0.06
			var a1: float = -PI * 0.5 + float(d + 1) * sector_span - 0.06
			var lit: bool = d <= active_decano
			var cur: bool = d == active_decano
			var col: Color = Color(0.95, 0.80, 0.40, 0.92) if cur else (Color(0.32, 0.78, 0.72, 0.62) if lit else Color(0.55, 0.62, 0.80, 0.20))
			draw_arc(c, r_out, a0, a1, 28, col, 6.0 if cur else 3.5, true)

		# Anillo interior e hitos de calendario (12 divisiones)
		draw_arc(c, r_mid, 0.0, TAU, 48, Color(0.84, 0.69, 0.36, 0.28), 1.5, true)
		draw_arc(c, r_in, 0.0, TAU, 36, Color(0.32, 0.72, 0.68, 0.36), 2.0, true)
		for i in range(12):
			var ang: float = -PI * 0.5 + float(i) * (TAU / 12.0)
			var major: bool = (i % 4) == 0
			var p0: Vector2 = c + Vector2.from_angle(ang) * (r_mid - (10.0 if major else 5.0))
			var p1: Vector2 = c + Vector2.from_angle(ang) * (r_mid + (8.0 if major else 4.0))
			draw_line(p0, p1, Color(0.94, 0.82, 0.48, 0.75 if major else 0.32), 2.4 if major else 1.2, true)

		# Arco activo barrido por el sol/luna
		var sweep: float = clampf(progress, 0.0, 1.0) * TAU
		if sweep > 0.02:
			draw_arc(c, r_mid, -PI * 0.5, -PI * 0.5 + sweep, 48, Color(0.98, 0.84, 0.44, 0.88), 4.0, true)

		# Orbe celeste en movimiento y estela
		var orb_ang: float = -PI * 0.5 + sweep
		var orb_pos: Vector2 = c + Vector2.from_angle(orb_ang) * r_mid
		for t_i in range(comet_trail.size()):
			var ratio: float = float(t_i + 1) / float(maxi(1, comet_trail.size()))
			draw_circle(comet_trail[t_i], 2.0 + ratio * 3.0, Color(0.98, 0.82, 0.42, ratio * 0.38))
		draw_line(c, orb_pos, Color(0.94, 0.80, 0.42, 0.30), 1.5, true)
		draw_circle(orb_pos, 11.0 + flare * 4.0, Color(0.98, 0.85, 0.46, 0.35))
		draw_circle(orb_pos, 6.2, Color(1.0, 0.95, 0.76, 1.0))

		# Destello radial y chispas al completar cada Decano
		if flare > 0.02:
			for k in range(12):
				var fa: float = float(k) * (TAU / 12.0) + pulse_time * 0.9
				var r0: float = r_in * 1.15
				var r1: float = r_out * (1.02 + flare * 0.22)
				draw_line(c + Vector2.from_angle(fa) * r0, c + Vector2.from_angle(fa) * r1, Color(1.0, 0.88, 0.50, flare * 0.48), 2.0, true)

		# Núcleo del observatorio
		var core_r: float = 9.0 + sin(pulse_time * 4.0) * 1.5
		draw_circle(c, core_r + 5.0, Color(0.32, 0.78, 0.74, 0.25))
		draw_circle(c, core_r, Color(0.92, 0.78, 0.44, 0.92))

var _title_lbl: Label
var _day_lbl: Label
var _dial: _DialCanvas
var _ring_outer: TextureRect
var _ring_inner: TextureRect
var _father_row: HBoxContainer
var _cards_row: HBoxContainer
var _cards: Array[PanelContainer] = []
var _skip_btn: Button
var _details_btn: Button
var _continue_btn: Button
var _summary_flow: HFlowContainer
var _last_report: Dictionary = {}
var _tween: Tween
var _active_anim: bool = false
var _finished_once: bool = false
var _last_trail_p: float = -1.0

func _ready() -> void:
	set_panel_width(920)
	_max_height_ratio = 0.86
	super._ready()
	_build_ui()

func _build_ui() -> void:
	content.add_theme_constant_override("separation", 12)

	var top := AstralTheme.hbox(12)
	content.add_child(top)
	_title_lbl = AstralTheme.label("%s  TRANSCURSO DEL BIMESTRE" % AstralTheme.G_HOURGLASS, "HeadingLabel", AstralTheme.GOLD)
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title_lbl)
	_day_lbl = AstralTheme.label("Día 0 / 60", "HeadingLabel", AstralTheme.TURQ)
	top.add_child(_day_lbl)

	# Escenario visual del astrolabio
	var stage_wrap := Control.new()
	stage_wrap.custom_minimum_size = Vector2(0, 236)
	stage_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(stage_wrap)

	_ring_outer = _make_ring("res://assets/ui/astrolabe_ring_outer.png", Color(0.92, 0.78, 0.42, 0.34), 220.0)
	_ring_inner = _make_ring("res://assets/ui/astrolabe_ring_inner.png", Color(0.35, 0.82, 0.78, 0.38), 156.0)
	stage_wrap.add_child(_ring_outer)
	stage_wrap.add_child(_ring_inner)

	_dial = _DialCanvas.new()
	_dial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_wrap.add_child(_dial)
	stage_wrap.resized.connect(func() -> void: _center_rings(stage_wrap))

	_father_row = AstralTheme.hbox(8)
	_father_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(_father_row)

	_cards_row = AstralTheme.hbox(12)
	content.add_child(_cards_row)

	_summary_flow = HFlowContainer.new()
	_summary_flow.add_theme_constant_override("h_separation", 8)
	_summary_flow.add_theme_constant_override("v_separation", 6)
	_summary_flow.visible = false
	content.add_child(_summary_flow)

	var foot := AstralTheme.hbox(10)
	foot.alignment = BoxContainer.ALIGNMENT_END
	content.add_child(foot)
	_skip_btn = AstralTheme.button("Saltar animación  →", "TabLikeButton")
	_skip_btn.custom_minimum_size = Vector2(210, 44)
	_skip_btn.pressed.connect(_skip_to_summary)
	foot.add_child(_skip_btn)
	_details_btn = AstralTheme.button("Ver Crónica Detallada", "")
	_details_btn.custom_minimum_size = Vector2(220, 46)
	_details_btn.visible = false
	_details_btn.pressed.connect(_open_detailed_report)
	foot.add_child(_details_btn)
	_continue_btn = AstralTheme.button("Continuar  ▶", "PrimaryButton")
	_continue_btn.custom_minimum_size = Vector2(210, 46)
	_continue_btn.visible = false
	_continue_btn.pressed.connect(_finish_sequence)
	foot.add_child(_continue_btn)

func _make_ring(path: String, tint: Color, sz: float) -> TextureRect:
	var t := TextureRect.new()
	if ResourceLoader.exists(path):
		t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.modulate = tint
	t.size = Vector2(sz, sz)
	t.pivot_offset = Vector2(sz * 0.5, sz * 0.5)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func _center_rings(wrap: Control) -> void:
	var c: Vector2 = wrap.size * 0.5
	for r in [_ring_outer, _ring_inner]:
		if r != null:
			r.pivot_offset = r.size * 0.5
			r.position = c - r.size * 0.5

func _process(delta: float) -> void:
	if not visible or not _active_anim:
		return
	if _ring_outer != null:
		_ring_outer.rotation += delta * 0.65
	if _ring_inner != null:
		_ring_inner.rotation -= delta * 1.05
	if _dial != null and absf(_dial.progress - _last_trail_p) >= 0.025:
		_last_trail_p = _dial.progress
		var c: Vector2 = _dial.size * 0.5
		var r_mid: float = minf(_dial.size.x, _dial.size.y) * 0.44 * 0.74
		var orb_pos: Vector2 = c + Vector2.from_angle(-PI * 0.5 + _dial.progress * TAU) * r_mid
		_dial.comet_trail.append(orb_pos)
		if _dial.comet_trail.size() > 14:
			_dial.comet_trail.pop_front()

func play_bimester(rep: Dictionary) -> void:
	_last_report = rep
	if DisplayServer.get_name() == "headless":
		hide_overlay()
		call_deferred("emit_signal", "sequence_finished")
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_finished_once = false
	_active_anim = true
	_last_trail_p = -1.0
	_dial.progress = 0.0
	_dial.active_decano = -1
	_dial.flare = 0.0
	_dial.comet_trail.clear()

	_title_lbl.text = "%s  Año %d  —  %s (60 Días)" % [
		AstralTheme.G_HOURGLASS, int(rep.get("year", 1)), str(rep.get("bimester_name", "Bimestre"))
	]
	_day_lbl.text = "Día 1 / 60"
	_build_father_chips(rep.get("father", []))
	_build_decano_cards(rep.get("blocks", []))
	_build_summary_chips(rep)
	_summary_flow.visible = false
	_skip_btn.visible = true
	_details_btn.visible = false
	_continue_btn.visible = false

	show_overlay()
	_fit()
	_center_rings(_dial.get_parent() as Control)
	AstralAudio.play_turn_end()

	var step_sec: float = 0.24 if SettingsManager.short_turn_anim else 0.56
	var gap_sec: float = 0.05 if SettingsManager.short_turn_anim else 0.14
	var end_sec: float = 0.12 if SettingsManager.short_turn_anim else 0.30

	_tween = create_tween()
	var blocks: Array = rep.get("blocks", [])
	for i in range(3):
		var target_p: float = float(i + 1) / 3.0
		var idx: int = i
		var block_data: Dictionary = blocks[i] if i < blocks.size() else {}
		_tween.tween_callback(func() -> void: _activate_decano(idx, block_data))
		_tween.tween_method(func(v: float) -> void:
			_dial.progress = v
			var day: int = clampi(int(round(v * 60.0)), 1, 60)
			_day_lbl.text = "Día %d / 60   ·   Decano %d" % [day, idx + 1]
		, float(i) / 3.0, target_p, step_sec).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_interval(gap_sec)
	_tween.tween_callback(func() -> void:
		_dial.flare = 1.0
		AstralAudio.play_confirm())
	_tween.tween_interval(end_sec)
	_tween.tween_callback(_on_anim_complete)

func _build_father_chips(father_items: Array) -> void:
	for c in _father_row.get_children():
		c.queue_free()
	if father_items.is_empty():
		_father_row.visible = false
		return
	_father_row.visible = true
	for f in father_items:
		var chip := AstralTheme.panel("PillPanel")
		var h := AstralTheme.hbox(6)
		chip.add_child(h)
		h.add_child(AstralTheme.label("%s  %s:" % [AstralTheme.G_ANKH, str(f.get("name", ""))], "CaptionLabel", AstralTheme.GOLD_PALE))
		h.add_child(AstralTheme.label(str(f.get("text", "")), "CaptionLabel", AstralTheme.TURQ))
		_father_row.add_child(chip)

func _build_decano_cards(blocks: Array) -> void:
	for c in _cards_row.get_children():
		c.queue_free()
	_cards.clear()
	var ranges: Array[String] = ["Días 1–20", "Días 21–40", "Días 41–60"]
	for i in range(3):
		var b: Dictionary = blocks[i] if i < blocks.size() else {}
		var card := AstralTheme.panel("CardPanel")
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(240, 178)
		card.modulate = Color(1, 1, 1, 0.24)
		var v := AstralTheme.vbox(6)
		card.add_child(v)
		var aid: String = str(b.get("activity_id", ""))
		var act_cat: String = str(CatalogDB.get_activity(aid).get("category", "class"))
		v.add_child(AstralTheme.scenic_banner(CatalogDB.get_activity_illustration(aid, act_cat), 68.0, Color(1, 1, 1, 0.92)))
		v.add_child(AstralTheme.label("DECANO %d  (%s)" % [i + 1, ranges[i]], "CaptionLabel", AstralTheme.MUTED))
		v.add_child(AstralTheme.label(str(b.get("name", "Actividad")), "SubLabel", AstralTheme.GOLD_PALE, true))
		v.add_child(AstralTheme.separator())

		# Fichas de estadísticas concisas (sin párrafos)
		var chips := HFlowContainer.new()
		chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chips.add_theme_constant_override("h_separation", 8)
		chips.add_theme_constant_override("v_separation", 4)
		v.add_child(chips)

		var g_gold: int = int(b.get("gold", 0))
		if g_gold != 0:
			chips.add_child(_delta_badge("%s %s G" % [AstralTheme.G_SUN, AstralTheme.signed(g_gold)], AstralTheme.GOLD if g_gold > 0 else AstralTheme.EMBER))
		for g in b.get("gains", []):
			var dv: int = int(g.get("delta", 0))
			if dv != 0:
				chips.add_child(_delta_badge("%s %s" % [str(g.get("label", "")), AstralTheme.signed(dv)], AstralTheme.GOOD if dv > 0 else AstralTheme.BAD))
		var sd: int = int(b.get("stress_delta", 0))
		if sd != 0:
			chips.add_child(_delta_badge("Estrés %s" % AstralTheme.signed(sd), AstralTheme.GOOD if sd < 0 else AstralTheme.EMBER))
		var seald: int = int(b.get("seal_delta", 0))
		if seald != 0:
			chips.add_child(_delta_badge("%s %s%%" % [GameState.get_stat_label("seal_integrity"), AstralTheme.signed(seald)], AstralTheme.GOOD if seald > 0 else AstralTheme.BAD))

		if b.has("clash"):
			var cl: Dictionary = b["clash"]
			var won: bool = str(cl.get("status", "")) == "inspired"
			v.add_child(AstralTheme.label("%s  Duelo escolar (%s)" % [AstralTheme.G_SWORD, "¡Inspirada!" if won else "Desafiada"], "CaptionLabel", AstralTheme.TURQ if won else AstralTheme.EMBER, true))
		if b.has("event"):
			var ev: Dictionary = b["event"]
			v.add_child(AstralTheme.label("%s  %s" % [AstralTheme.G_BOLT, str(ev.get("title", "Suceso"))], "CaptionLabel", AstralTheme.AMETHYST, true))
		for n in b.get("notes", []):
			if str(n).begins_with("Hallazgo:") or str(n).begins_with("Colapso"):
				v.add_child(AstralTheme.label("%s  %s" % [AstralTheme.G_STAR2, str(n)], "CaptionLabel", AstralTheme.GOOD if str(n).begins_with("Hallazgo:") else AstralTheme.BAD, true))

		_cards_row.add_child(card)
		_cards.append(card)

func _delta_badge(txt: String, col: Color) -> PanelContainer:
	var p := AstralTheme.panel("PillPanel")
	var l := AstralTheme.label(txt, "CaptionLabel", col)
	p.add_child(l)
	return p

func _activate_decano(idx: int, _block_data: Dictionary) -> void:
	_dial.active_decano = idx
	_dial.flare = 0.85
	AstralAudio.play_ui()
	if idx >= 0 and idx < _cards.size():
		var card: PanelContainer = _cards[idx]
		card.theme_type_variation = "GlowPanel"
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(1.04, 1.04)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(card, "modulate", Color.WHITE, 0.24)
		tw.tween_property(card, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK)
		for prev_i in range(idx):
			_cards[prev_i].theme_type_variation = "CardPanel"

func _build_summary_chips(rep: Dictionary) -> void:
	for c in _summary_flow.get_children():
		c.queue_free()
	var syn: Array = rep.get("synergies", [])
	for s in syn:
		_summary_flow.add_child(_delta_badge("%s Sinergia: %s" % [AstralTheme.G_FLEUR, str(s.get("title", ""))], AstralTheme.GOLD))
	for s in rep.get("summary", []):
		var d: int = int(s.get("delta", 0))
		if d == 0:
			continue
		var sk: String = str(s.get("stat", ""))
		var bad_up: bool = (sk == "stress" or sk == "entropia" or sk == "astral_saturation" or sk == "court_suspicion")
		var good: bool = (d > 0) != bad_up
		_summary_flow.add_child(_delta_badge("%s %s" % [str(s.get("label", sk)), AstralTheme.signed(d)], AstralTheme.GOOD if good else AstralTheme.BAD))
	var g_st: Dictionary = GameState.get_annual_goal_status()
	if not g_st.is_empty():
		var g_lbl: String = "Meta Anual ✓ %s" % str(g_st["title"]) if bool(g_st["completed"]) else "Meta Anual: %s (%d/%d)" % [str(g_st["title"]), int(g_st["current"]), int(g_st["target"])]
		_summary_flow.add_child(_delta_badge(g_lbl, AstralTheme.GOOD if bool(g_st["completed"]) else AstralTheme.TURQ))

func _skip_to_summary() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_dial.progress = 1.0
	_dial.active_decano = 2
	_dial.flare = 0.8
	_day_lbl.text = "Día 60 / 60   ·   Completado"
	for c in _cards:
		c.modulate = Color.WHITE
		c.theme_type_variation = "CardPanel"
	if not _cards.is_empty():
		_cards[_cards.size() - 1].theme_type_variation = "GlowPanel"
	_on_anim_complete()

func _on_anim_complete() -> void:
	_active_anim = false
	_day_lbl.text = "Día 60 / 60   ·   Balance del Bimestre"
	if not SettingsManager.unified_turn_end:
		_finish_sequence()
		report_requested.emit(_last_report)
		return
	_skip_btn.visible = false
	_summary_flow.visible = _summary_flow.get_child_count() > 0
	_details_btn.visible = true
	_continue_btn.visible = true
	_fit()

func _open_detailed_report() -> void:
	var r: Dictionary = _last_report
	_finish_sequence()
	report_requested.emit(r)

func _finish_sequence() -> void:
	if _finished_once:
		return
	_finished_once = true
	_active_anim = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	hide_overlay()
	sequence_finished.emit()
