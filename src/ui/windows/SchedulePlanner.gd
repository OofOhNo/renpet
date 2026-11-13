extends BaseWindow
class_name SchedulePlanner

## Agenda del Bimestre — Libro Iluminado con Tarjetas Icónicas Arrastrables y Folio de 3 Decanos.

signal agenda_executed()
signal execute_requested()

static func activity_icon(act_id: String, cat: String = "class") -> String:
	return CatalogDB.get_activity_illustration(act_id, cat)

static func populate_preview_chips(flow: HFlowContainer, pv: Dictionary, compact: bool = true) -> void:
	for c in flow.get_children():
		c.queue_free()
	var shown: int = 0
	for g in pv.get("gains", []):
		if compact and shown >= 3:
			break
		var v: int = int(g["value"])
		if v == 0:
			continue
		var sk: String = str(g.get("stat", ""))
		var col: Color = AstralTheme.STAT_COLORS.get(sk, AstralTheme.GOOD if v > 0 else AstralTheme.BAD)
		var ch := AstralTheme.chip("%s %s" % [str(g["label"]), AstralTheme.signed(v)], col, Color(col, 0.45), 13)
		ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flow.add_child(ch)
		shown += 1
	var sd: int = int(pv.get("seal_delta", 0))
	if sd != 0:
		var scol: Color = AstralTheme.GOOD if sd > 0 else AstralTheme.BAD
		var sc := AstralTheme.chip("%s %s%%" % [GameState.get_stat_label("seal_integrity"), AstralTheme.signed(sd)], scol, Color(scol, 0.45), 13)
		sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flow.add_child(sc)

class _NoticeCard extends PanelContainer:
	signal card_clicked(act_id: String)

	var act_id: String = ""
	var title_txt: String = ""
	var locked: bool = false
	var accent_col: Color = Color("f7e3a1")

	func _init(p_id: String, p_title: String, p_locked: bool, p_col: Color, p_tooltip: String) -> void:
		act_id = p_id
		title_txt = p_title
		locked = p_locked
		accent_col = p_col
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if locked else Control.CURSOR_DRAG
		tooltip_text = p_tooltip

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.08, 0.16, 0.92) if not locked else Color(0.05, 0.06, 0.10, 0.65)
		sb.border_color = Color(p_col.r, p_col.g, p_col.b, 0.68 if not locked else 0.25)
		sb.set_border_width_all(1)
		sb.border_width_left = 4
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 7
		sb.content_margin_bottom = 7
		add_theme_stylebox_override("panel", sb)

	func _gui_input(event: InputEvent) -> void:
		if locked:
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(act_id)

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if locked:
			return null
		var preview := PanelContainer.new()
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color(0.04, 0.06, 0.16, 0.94)
		psb.border_color = accent_col
		psb.set_border_width_all(1)
		psb.set_corner_radius_all(10)
		psb.content_margin_left = 10
		psb.content_margin_right = 10
		psb.content_margin_top = 4
		psb.content_margin_bottom = 4
		preview.add_theme_stylebox_override("panel", psb)
		var lbl := Label.new()
		lbl.text = "✎  " + title_txt
		lbl.add_theme_color_override("font_color", Color("f7e3a1"))
		lbl.add_theme_font_size_override("font_size", 16)
		preview.add_child(lbl)
		set_drag_preview(preview)
		return {"type": "activity", "act_id": act_id}

class _DecanoDropSlot extends PanelContainer:
	signal slot_selected(slot_idx: int)
	signal activity_dropped(slot_idx: int, act_id: String)

	var slot_idx: int = 0
	var _hdr: Label
	var _focus_badge: Label
	var _icon_rect: TextureRect
	var _act_title: Label
	var _chips: HFlowContainer

	func _init(idx: int) -> void:
		slot_idx = idx
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			slot_selected.emit(slot_idx)

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return typeof(data) == TYPE_DICTIONARY and (data as Dictionary).get("type", "") == "activity"

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if typeof(data) == TYPE_DICTIONARY:
			var aid: String = str((data as Dictionary).get("act_id", ""))
			if aid != "":
				activity_dropped.emit(slot_idx, aid)

var _tabs: TabContainer
var _bim_lbl: Label
var _bim_chip: Label
var _slots: Array[_DecanoDropSlot] = []
var _catalog_box: VBoxContainer
var _filter_btns: Dictionary = {}
var _sort_opt: OptionButton
var _summary_flow: HFlowContainer
var _exec_btn: Button
var _exec_msg: Label
var _energy_lbl: Label
var _energy_bar: ProgressBar
var _father_cards: Dictionary = {}

var _selected_slot: int = 0
var _filter_cat: String = "all"
var _sort_mode: int = 0

func _ready() -> void:
	setup("Libro del Bimestre", false)

func build() -> void:
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_tabs)

	# ------- PESTAÑA 1: AGENDA DEL BIMESTRE -------
	var agenda_v := add_tab(_tabs, "  Agenda de %s  " % GameState.daughter_name)

	var top_p := AstralTheme.panel("GlowPanel")
	var top_h := AstralTheme.hbox(10)
	top_p.add_child(top_h)
	_bim_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD_PALE)
	_bim_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(_bim_lbl)
	_bim_chip = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ)
	top_h.add_child(_bim_chip)
	agenda_v.add_child(top_p)

	# Presets + Ordenador
	var bar := AstralTheme.hbox(8)
	agenda_v.add_child(bar)
	bar.add_child(AstralTheme.label("Rutina:", "CaptionLabel", AstralTheme.MUTED))
	for p in [
		{"id": "balanced", "lbl": "Equilibrada"},
		{"id": "scholar", "lbl": "Erudita"},
		{"id": "martial", "lbl": "Marcial"},
		{"id": "work", "lbl": "Oficios"},
		{"id": "recovery", "lbl": "Reposo"}
	]:
		var b := AstralTheme.button(str(p["lbl"]), "TabLikeButton")
		b.custom_minimum_size.y = 32
		var pid: String = str(p["id"])
		b.pressed.connect(func() -> void:
			AstralAudio.play_ui()
			_apply_preset_local(pid)
			refresh())
		bar.add_child(b)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	bar.add_child(AstralTheme.label("Orden:", "CaptionLabel", AstralTheme.MUTED))
	_sort_opt = OptionButton.new()
	_sort_opt.add_item("Por defecto")
	_sort_opt.add_item("Mayor Oro")
	_sort_opt.add_item("Menor Estrés")
	_sort_opt.add_item("Alfabético")
	_sort_opt.item_selected.connect(func(idx: int) -> void:
		_sort_mode = idx
		refresh())
	bar.add_child(_sort_opt)

	# --- DOBLE PÁGINA DEL LIBRO ---
	var spread := HBoxContainer.new()
	spread.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread.add_theme_constant_override("separation", 12)
	agenda_v.add_child(spread)

	# PÁGINA IZQUIERDA: TABLÓN DE ANUNCIOS VISUALES
	var left_page := AstralTheme.panel("SunkenPanel")
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread.add_child(left_page)

	var lv := AstralTheme.vbox(8)
	lv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_page.add_child(lv)

	var f_row := AstralTheme.hbox(6)
	lv.add_child(f_row)
	f_row.add_child(AstralTheme.label("Tablón:", "CaptionLabel", AstralTheme.GOLD_PALE))
	for f in [
		{"id": "all", "lbl": "Todos"},
		{"id": "class", "lbl": "Clases"},
		{"id": "job", "lbl": "Oficios"},
		{"id": "rest", "lbl": "Reposo"}
	]:
		var fb := AstralTheme.button(str(f["lbl"]), "TabLikeButton")
		fb.custom_minimum_size.y = 30
		fb.toggle_mode = true
		var fid: String = str(f["id"])
		fb.pressed.connect(func() -> void:
			_filter_cat = fid
			refresh())
		_filter_btns[fid] = fb
		f_row.add_child(fb)

	var cat_sc := ScrollContainer.new()
	cat_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cat_sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cat_sc.custom_minimum_size = Vector2(0, 220)
	lv.add_child(cat_sc)

	_catalog_box = AstralTheme.vbox(6)
	_catalog_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_sc.add_child(_catalog_box)

	# PÁGINA DERECHA: FOLIO DE LOS 3 DECANOS
	var right_page := AstralTheme.panel("CardPanel")
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread.add_child(right_page)

	var rv := AstralTheme.vbox(8)
	rv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_page.add_child(rv)
	rv.add_child(AstralTheme.label("Folio del Bimestre (3 × 20 días)", "SubLabel", AstralTheme.GOLD))

	_slots.clear()
	for i in range(TurnExecutor.BLOCKS_PER_BIMESTER):
		var slot := _setup_drop_slot(i)
		slot.slot_selected.connect(func(idx: int) -> void:
			_selected_slot = idx
			AstralAudio.play_ui()
			refresh())
		slot.activity_dropped.connect(_on_assign_activity)
		rv.add_child(slot)
		_slots.append(slot)

	var sum_card := AstralTheme.panel("SunkenPanel")
	_summary_flow = HFlowContainer.new()
	_summary_flow.add_theme_constant_override("h_separation", 8)
	_summary_flow.add_theme_constant_override("v_separation", 6)
	sum_card.add_child(_summary_flow)
	rv.add_child(sum_card)

	var foot := AstralTheme.panel("GlowPanel")
	var fh := AstralTheme.hbox(14)
	foot.add_child(fh)
	_exec_msg = AstralTheme.label("", "CaptionLabel", AstralTheme.BAD, true)
	_exec_msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fh.add_child(_exec_msg)

	_exec_btn = AstralTheme.button("%s  EJECUTAR LOS 60 DÍAS  %s" % [AstralTheme.G_STAR, AstralTheme.G_STAR], "PrimaryButton")
	_exec_btn.custom_minimum_size = Vector2(290, 48)
	_exec_btn.pressed.connect(func() -> void:
		close()
		execute_requested.emit()
		agenda_executed.emit())
	fh.add_child(_exec_btn)
	agenda_v.add_child(foot)

	# ------- PESTAÑA 2: TAREA DEL PADRE -------
	var fv := add_tab(_tabs, "  Tarea del Padre  ")
	var ec := AstralTheme.panel("GlowPanel")
	var ev := AstralTheme.vbox(6)
	ec.add_child(ev)
	_energy_lbl = AstralTheme.label("", "SubLabel", AstralTheme.TURQ)
	ev.add_child(_energy_lbl)
	_energy_bar = ProgressBar.new()
	_energy_bar.custom_minimum_size.y = 18
	AstralTheme.style_bar(_energy_bar, AstralTheme.TURQ)
	ev.add_child(_energy_bar)
	fv.add_child(ec)

	_father_cards.clear()
	for t in CatalogDB.FATHER_TASKS:
		var tid: String = str(t["id"])
		var fc := AstralTheme.panel("CardPanel")
		var fh2 := AstralTheme.hbox(12)
		fc.add_child(fh2)
		var ficon: String = CatalogDB.get_father_task_illustration(tid)
		var fvign := AstralTheme.vignette_card(ficon, Vector2(92, 54), AstralTheme.GOLD_DARK)
		fvign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fh2.add_child(fvign)
		var inf := AstralTheme.vbox(4)
		inf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fh2.add_child(inf)
		var th_r := AstralTheme.hbox(8)
		inf.add_child(th_r)
		var nm := AstralTheme.label(str(t["name"]), "SubLabel", AstralTheme.GOLD_PALE)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		th_r.add_child(nm)
		th_r.add_child(AstralTheme.chip("-%d ☥" % int(t["energy"]), AstralTheme.TURQ, AstralTheme.TURQ, 14))
		inf.add_child(AstralTheme.label(str(t["summary"]), "CaptionLabel", AstralTheme.IVORY, true))
		var note := AstralTheme.label("", "CaptionLabel", AstralTheme.EMBER, true)
		inf.add_child(note)
		var btn := AstralTheme.button("Asignar", "")
		btn.custom_minimum_size = Vector2(146, 46)
		btn.pressed.connect(func() -> void:
			AstralAudio.play_ui()
			TurnExecutor.toggle_father_task(tid)
			refresh())
		fh2.add_child(btn)
		fv.add_child(fc)
		_father_cards[tid] = {"btn": btn, "note": note}

func _apply_preset_local(pid: String) -> void:
	var plan: Array[String] = ["class_armory", "class_astrolabe", "class_conservatory"]
	match pid:
		"scholar": plan = ["class_astrolabe", "class_astrolabe", "rest_manor"]
		"martial": plan = ["class_armory", "class_armory", "rest_manor"]
		"work": plan = ["job_sanatorium", "job_clockwork", "job_amphitheater"]
		"recovery": plan = ["rest_manor", "rest_manor", "rest_manor"]
	for i in range(TurnExecutor.BLOCKS_PER_BIMESTER):
		var aid: String = plan[i % plan.size()]
		var act: Dictionary = CatalogDB.get_activity(aid)
		if GameState.exhausted_sick:
			aid = "rest_manor"
		elif GameState.age < int(act.get("min_age", 12)):
			aid = "job_sanatorium"
		TurnExecutor.set_agenda_slot(i, aid)

func _on_assign_activity(slot_idx: int, act_id: String) -> void:
	AstralAudio.play_confirm()
	TurnExecutor.set_agenda_slot(slot_idx, act_id)
	_selected_slot = (slot_idx + 1) % TurnExecutor.BLOCKS_PER_BIMESTER
	refresh()
	if DisplayServer.get_name() != "headless" and slot_idx >= 0 and slot_idx < _slots.size():
		var sl: _DecanoDropSlot = _slots[slot_idx]
		sl.pivot_offset = sl.size * 0.5
		sl.scale = Vector2(1.03, 1.03)
		sl.modulate = Color(1.18, 1.12, 0.92, 1.0)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(sl, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
		tw.tween_property(sl, "modulate", Color.WHITE, 0.24)

func refresh() -> void:
	if _tabs == null or _slots.size() < TurnExecutor.BLOCKS_PER_BIMESTER:
		return
	var bim: Dictionary = TimeManager.get_bimester_info()
	_bim_lbl.text = "%s  ·  %s" % [str(bim["name"]), str(bim["season"])]
	_bim_chip.text = "%s  Agotamiento activo" % AstralTheme.G_BOLT if GameState.exhausted_sick else str(bim.get("bonus_desc", ""))
	_bim_chip.add_theme_color_override("font_color", AstralTheme.BAD if GameState.exhausted_sick else AstralTheme.TURQ)

	for fk in _filter_btns.keys():
		(_filter_btns[fk] as Button).button_pressed = (fk == _filter_cat)

	clear(_catalog_box)
	var list: Array[Dictionary] = []
	for a in CatalogDB.ACTIVITIES:
		var cat: String = str(a.get("category", "class"))
		if _filter_cat != "all" and cat != _filter_cat:
			continue
		list.append(a)
	list.sort_custom(_sort_activities)

	for a in list:
		var aid: String = str(a["id"])
		var cat: String = str(a.get("category", "class"))
		var min_age: int = int(a.get("min_age", 12))
		if GameState.age < min_age:
			continue
		var locked_sick: bool = GameState.exhausted_sick and (cat == "class" or aid in ["job_caravan", "job_canals"])
		var locked: bool = locked_sick
		var lock_msg: String = "Bloqueada (Agotada)" if locked_sick else ""
		var pv: Dictionary = TurnExecutor.preview_block(aid)
		var col: Color = AstralTheme.TURQ if cat == "class" else (AstralTheme.GOLD if cat == "job" else AstralTheme.AMETHYST)
		var card := _build_notice_card(a, pv, locked, lock_msg, col)
		card.card_clicked.connect(func(chosen_id: String) -> void:
			_on_assign_activity(_selected_slot, chosen_id))
		_catalog_box.add_child(card)

	var romans: Array[String] = ["I", "II", "III"]
	for i in range(TurnExecutor.BLOCKS_PER_BIMESTER):
		_refresh_drop_slot(_slots[i], romans[i], i == _selected_slot, TurnExecutor.agenda[i])

	var chk: Dictionary = TurnExecutor.validate_and_preview()
	_refresh_summary_chips(chk)
	_exec_btn.disabled = not chk["ok"]
	_exec_msg.text = "" if chk["ok"] else str(chk["msg"])

	var used: int = TurnExecutor.get_father_energy_used()
	var total: int = GameState.father_energy
	_energy_bar.max_value = maxf(1.0, float(GameState.father_max_energy))
	_energy_bar.value = used
	_energy_lbl.text = "%s  Energía Paternal: %d usada de %d  (%d libre)" % [AstralTheme.G_ANKH, used, total, total - used]
	for tid in _father_cards.keys():
		var planned: bool = TurnExecutor.is_father_task_planned(tid)
		var btn: Button = _father_cards[tid]["btn"]
		var note: Label = _father_cards[tid]["note"]
		var can: Dictionary = TurnExecutor.can_plan_father_task(tid)
		btn.text = (AstralTheme.G_CHECK + "  Asignada") if planned else "Asignar"
		btn.button_pressed = planned
		btn.toggle_mode = true
		btn.disabled = (not planned) and (not can["ok"])
		note.text = "" if (planned or can["ok"]) else str(can["msg"])
		btn.tooltip_text = "" if can["ok"] else str(can["msg"])

func _refresh_summary_chips(chk: Dictionary) -> void:
	for c in _summary_flow.get_children():
		c.queue_free()
	if not chk["ok"]:
		_summary_flow.add_child(AstralTheme.chip(str(chk["msg"]), AstralTheme.BAD, AstralTheme.BAD, 14))
		return
	var net: int = int(chk["net_gold"])
	_summary_flow.add_child(AstralTheme.chip("Balance: %s G" % AstralTheme.signed(net), AstralTheme.GOLD if net >= 0 else AstralTheme.EMBER, null, 14))
	_summary_flow.add_child(AstralTheme.chip("Final: %d G" % (GameState.gold + net), AstralTheme.IVORY, null, 14))
	var st_d: int = int(chk["stress"])
	_summary_flow.add_child(AstralTheme.chip("Estrés: %s" % AstralTheme.signed(st_d), AstralTheme.BAD if st_d > 0 else AstralTheme.GOOD, null, 14))
	var proj: int = GameState.stress + st_d
	if proj >= TurnExecutor.STRESS_COLLAPSE_THRESHOLD:
		_summary_flow.add_child(AstralTheme.chip("%s Riesgo Colapso (%d)" % [AstralTheme.G_BOLT, proj], AstralTheme.BAD, AstralTheme.BAD, 14))
	elif chk["fatigue_warning"] or proj >= TurnExecutor.STRESS_FATIGUE_THRESHOLD:
		_summary_flow.add_child(AstralTheme.chip("%s Fatiga (-25%%)" % AstralTheme.G_BOLT, AstralTheme.EMBER, AstralTheme.EMBER, 14))
	_summary_flow.add_child(AstralTheme.chip(str(GameState.get_mood_summary()["short_tag"]), AstralTheme.TURQ, null, 14))
	var voc: Dictionary = EndingEvaluator.get_projected_vocation()
	_summary_flow.add_child(AstralTheme.chip("%s %s" % [AstralTheme.G_STAR, str(voc.get("name", ""))], AstralTheme.GOLD_PALE, null, 14))

func _sort_activities(a: Dictionary, b: Dictionary) -> bool:
	match _sort_mode:
		1:
			return int(a.get("cost_or_wage", 0)) > int(b.get("cost_or_wage", 0))
		2:
			return int(a.get("stress", 0)) < int(b.get("stress", 0))
		3:
			return str(a.get("name", "")) < str(b.get("name", ""))
		_:
			return false

func _build_notice_card(a: Dictionary, pv: Dictionary, p_locked: bool, p_lock_msg: String, p_col: Color) -> _NoticeCard:
	var aid: String = str(a["id"])
	var title_txt: String = str(a["name"])
	var cat: String = str(a.get("category", "class"))
	var tip: String = "%s\n%s" % [title_txt, str(a.get("desc", ""))]
	var card := _NoticeCard.new(aid, title_txt, p_locked, p_col, tip)

	var root_h := AstralTheme.hbox(10)
	root_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(root_h)

	var ib := AstralTheme.vignette_card(activity_icon(aid, cat), Vector2(88, 52), Color(0.55, 0.58, 0.72, 0.45) if p_locked else p_col)
	ib.modulate = Color(0.55, 0.58, 0.68, 0.72) if p_locked else Color.WHITE
	ib.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ib.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_h.add_child(ib)

	var vb := AstralTheme.vbox(4)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_h.add_child(vb)

	var top_r := AstralTheme.hbox(6)
	top_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(top_r)

	var t_lbl := AstralTheme.label(title_txt, "", AstralTheme.GOLD_PALE if not p_locked else Color("77809a"))
	t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_lbl.add_theme_font_size_override("font_size", 16)
	t_lbl.clip_text = true
	t_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_r.add_child(t_lbl)

	var g_net: int = int(pv.get("gold", 0))
	var g_txt: String = "Gratis" if g_net == 0 else "%s G" % AstralTheme.signed(g_net)
	var g_col: Color = AstralTheme.GOOD if g_net > 0 else (AstralTheme.GOLD if g_net < 0 else AstralTheme.MUTED)
	var g_ch := AstralTheme.chip(g_txt, g_col, Color(g_col, 0.5), 13)
	g_ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_r.add_child(g_ch)

	var st_net: int = int(pv.get("stress", 0))
	var st_col: Color = AstralTheme.GOOD if st_net < 0 else (AstralTheme.BAD if st_net >= 10 else AstralTheme.EMBER)
	var st_ch := AstralTheme.chip("%s %s" % [AstralTheme.G_MOON, AstralTheme.signed(st_net)], st_col, Color(st_col, 0.45), 13)
	st_ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_r.add_child(st_ch)

	if p_locked:
		var lk := AstralTheme.chip(p_lock_msg, AstralTheme.BAD, AstralTheme.BAD, 13)
		lk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(lk)
	else:
		var chips := HFlowContainer.new()
		chips.add_theme_constant_override("h_separation", 6)
		chips.add_theme_constant_override("v_separation", 4)
		chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		populate_preview_chips(chips, pv, true)
		var rival_id: String = str(a.get("rival_id", ""))
		if rival_id != "":
			var r_ch := AstralTheme.chip("%s %s" % [AstralTheme.G_SWORD, str(RivalMirror.get_data(rival_id).get("name", rival_id))], AstralTheme.ROSE, Color(AstralTheme.ROSE, 0.45), 12)
			r_ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chips.add_child(r_ch)
		vb.add_child(chips)
	return card

func _setup_drop_slot(idx: int) -> _DecanoDropSlot:
	var slot := _DecanoDropSlot.new(idx)
	var vb := AstralTheme.vbox(5)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(vb)

	var top := AstralTheme.hbox(8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(top)

	slot._hdr = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ)
	slot._hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot._hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(slot._hdr)

	slot._focus_badge = AstralTheme.label("", "CaptionLabel", AstralTheme.GOLD_PALE)
	slot._focus_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(slot._focus_badge)

	var body_h := AstralTheme.hbox(10)
	body_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(body_h)

	var ib := AstralTheme.panel("SunkenPanel")
	ib.custom_minimum_size = Vector2(88, 50)
	ib.clip_contents = true
	ib.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot._icon_rect = TextureRect.new()
	slot._icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot._icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	slot._icon_rect.custom_minimum_size = Vector2(82, 44)
	slot._icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ib.add_child(slot._icon_rect)
	body_h.add_child(ib)

	var info_v := AstralTheme.vbox(4)
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_h.add_child(info_v)

	slot._act_title = AstralTheme.label("", "SubLabel", AstralTheme.GOLD_PALE)
	slot._act_title.clip_text = true
	slot._act_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_v.add_child(slot._act_title)

	slot._chips = HFlowContainer.new()
	slot._chips.add_theme_constant_override("h_separation", 6)
	slot._chips.add_theme_constant_override("v_separation", 4)
	slot._chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_v.add_child(slot._chips)
	return slot

func _refresh_drop_slot(slot: _DecanoDropSlot, roman: String, is_focus: bool, act_id: String, drop_hint: bool = false) -> void:
	var d_from: int = slot.slot_idx * 20 + 1
	var d_to: int = (slot.slot_idx + 1) * 20
	slot._hdr.text = "DECANO %s  ·  Días %d–%d" % [roman, d_from, d_to]
	slot._focus_badge.text = "✦ Activo" if is_focus else "Clic / soltar"

	var a: Dictionary = CatalogDB.get_activity(act_id)
	var cat: String = str(a.get("category", "class"))
	slot._icon_rect.texture = AstralTheme.load_tex(activity_icon(act_id, cat))
	if a.is_empty():
		slot._act_title.text = "Sin asignar"
		for c in slot._chips.get_children():
			c.queue_free()
	else:
		slot._act_title.text = str(a["name"])
		slot.tooltip_text = "%s\n%s" % [str(a["name"]), str(a.get("desc", ""))]
		var pv: Dictionary = TurnExecutor.preview_block(act_id)
		populate_preview_chips(slot._chips, pv, true)
		var money: int = int(pv.get("gold", 0))
		if money != 0:
			var g_ch := AstralTheme.chip("%s G" % AstralTheme.signed(money), AstralTheme.GOLD if money > 0 else AstralTheme.EMBER, null, 13)
			g_ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot._chips.add_child(g_ch)
		var st: int = int(pv.get("stress", 0))
		var st_ch := AstralTheme.chip("%s %s" % [AstralTheme.G_MOON, AstralTheme.signed(st)], AstralTheme.BAD if st > 0 else AstralTheme.GOOD, null, 13)
		st_ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot._chips.add_child(st_ch)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.24, 0.94) if (is_focus or drop_hint) else Color(0.05, 0.08, 0.17, 0.88)
	sb.border_color = Color("49d6c8") if drop_hint else (Color("f7e3a1") if is_focus else Color(0.45, 0.50, 0.68, 0.45))
	sb.set_border_width_all(2 if (is_focus or drop_hint) else 1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	slot.add_theme_stylebox_override("panel", sb)

func show_father_tab() -> void:
	if _tabs != null:
		_tabs.current_tab = 1
