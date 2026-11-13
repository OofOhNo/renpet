extends BaseWindow
class_name SchedulePlanner

## Planificador de Doble Agenda (Fase 4.1): 3 decanos de Renpet + Energía Paternal del Padre.

signal execute_requested()

var _tabs: TabContainer
var _bim_info: RichTextLabel
var _option_buttons: Array[OptionButton] = []
var _detail_labels: Array[RichTextLabel] = []
var _summary: RichTextLabel
var _exec_btn: Button
var _exec_msg: Label
var _energy_bar: ProgressBar
var _energy_lbl: Label
var _father_cards: Dictionary = {}   # task_id -> {btn, note}
var _updating: bool = false

const ROMAN: Array[String] = ["I", "II", "III"]

func _ready() -> void:
	setup("Planificar el Bimestre", false)
	TurnExecutor.plan_changed.connect(_on_plan_changed)

func build() -> void:
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_tabs)

	# Pie fijo (siempre visible): resumen del bimestre + botón de ejecución
	var foot := AstralTheme.panel("GlowPanel")
	body.add_child(foot)
	var fh := AstralTheme.hbox(16)
	foot.add_child(fh)
	_summary = AstralTheme.rich()
	_summary.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fh.add_child(_summary)
	var exec_col := AstralTheme.vbox(4)
	exec_col.custom_minimum_size.x = 330
	fh.add_child(exec_col)
	_exec_btn = AstralTheme.button("%s  EJECUTAR LOS 60 DÍAS  %s" % [AstralTheme.G_STAR, AstralTheme.G_STAR], "PrimaryButton", "Hace girar el Astrolabio y resuelve el bimestre")
	_exec_btn.custom_minimum_size.y = 58
	_exec_btn.pressed.connect(func() -> void: execute_requested.emit())
	exec_col.add_child(_exec_btn)
	_exec_msg = AstralTheme.label("", "CaptionLabel", AstralTheme.BAD, true)
	_exec_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exec_col.add_child(_exec_msg)

	var agenda_tab := add_tab(_tabs, "  Agenda de %s  " % GameState.daughter_name)
	_bim_info = AstralTheme.rich()
	var info_card := AstralTheme.panel("GlowPanel")
	info_card.add_child(_bim_info)
	agenda_tab.add_child(info_card)

	var preset_row := AstralTheme.hbox(8)
	var p_lbl := AstralTheme.label("%s  Plantillas rápidas:" % AstralTheme.G_STAR2, "CaptionLabel", AstralTheme.TURQ)
	preset_row.add_child(p_lbl)
	for pid in ["equilibrio", "sabia", "marcial", "corte", "oro_descanso"]:
		var ptitle: String = {"equilibrio": "Equilibrio", "sabia": "Sabia Astral", "marcial": "Marcial", "corte": "Corte y Arte", "oro_descanso": "Oro + Descanso"}[pid]
		var pb := AstralTheme.button(ptitle, "TabLikeButton", "Rellena los 3 decanos automáticamente según esta orientación")
		pb.toggle_mode = false
		pb.custom_minimum_size = Vector2(0, 34)
		var p_key: String = pid
		pb.pressed.connect(func() -> void: _apply_preset(p_key))
		preset_row.add_child(pb)
	agenda_tab.add_child(preset_row)

	for i in range(TurnExecutor.BLOCKS_PER_BIMESTER):
		var card := AstralTheme.panel("CardPanel")
		agenda_tab.add_child(card)
		var h := AstralTheme.hbox(18)
		card.add_child(h)
		var left := AstralTheme.vbox(8)
		left.custom_minimum_size.x = 400
		h.add_child(left)
		left.add_child(AstralTheme.label("%s  Decano %s  ·  Días %d a %d" % [AstralTheme.G_STAR, ROMAN[i], i * 20 + 1, i * 20 + 20], "SubLabel", null, true))
		var ob := OptionButton.new()
		ob.fit_to_longest_item = false
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ob.clip_text = true
		ob.custom_minimum_size.y = 46
		for a in CatalogDB.ACTIVITIES:
			ob.add_item(_option_text(a))
			ob.set_item_metadata(ob.item_count - 1, a["id"])
		var idx: int = i
		ob.item_selected.connect(func(item: int) -> void: _on_activity_selected(idx, item))
		left.add_child(ob)
		_option_buttons.append(ob)
		var det := AstralTheme.rich()
		det.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h.add_child(det)
		_detail_labels.append(det)

	# --- Pestaña del Padre ---
	var father_tab := add_tab(_tabs, "  Tarea del Padre  ")
	var energy_card := AstralTheme.panel("GlowPanel")
	father_tab.add_child(energy_card)
	var ev := AstralTheme.vbox(6)
	energy_card.add_child(ev)
	_energy_lbl = AstralTheme.label("", "SubLabel")
	ev.add_child(_energy_lbl)
	_energy_bar = ProgressBar.new()
	_energy_bar.custom_minimum_size.y = 20
	AstralTheme.style_bar(_energy_bar, AstralTheme.GOLD)
	ev.add_child(_energy_bar)
	ev.add_child(AstralTheme.label("Reparte los puntos de Energía entre tus ocupaciones del bimestre. Las tareas se resuelven antes de los decanos de Renpet.", "CaptionLabel", AstralTheme.MUTED, true))

	for t in CatalogDB.FATHER_TASKS:
		var card := AstralTheme.panel("CardPanel")
		father_tab.add_child(card)
		var h := AstralTheme.hbox(16)
		card.add_child(h)
		var icon := AstralTheme.label(str(t["icon"]), "TitleLabel", AstralTheme.GOLD)
		icon.add_theme_font_size_override("font_size", 40)
		icon.custom_minimum_size.x = 56
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_child(icon)
		var mid := AstralTheme.vbox(4)
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(mid)
		mid.add_child(AstralTheme.label("%s  (%d de Energía)" % [t["name"], int(t["energy"])], "SubLabel"))
		mid.add_child(AstralTheme.label(str(t["summary"]), "", AstralTheme.IVORY, true))
		var note := AstralTheme.label("", "CaptionLabel", AstralTheme.EMBER, true)
		mid.add_child(note)
		var btn := AstralTheme.button("Asignar", "TabLikeButton")
		btn.toggle_mode = false
		btn.custom_minimum_size = Vector2(150, 48)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var tid: String = t["id"]
		btn.pressed.connect(func() -> void: _on_father_pressed(tid))
		h.add_child(btn)
		_father_cards[tid] = {"btn": btn, "note": note}

func _option_text(a: Dictionary) -> String:
	var glyph: String = AstralTheme.G_STAR
	match a["category"]:
		"job": glyph = AstralTheme.G_DIAMOND2
		"rest": glyph = AstralTheme.G_FLOWER
	var money: int = int(a["cost_or_wage"])
	var cost: String = "gratis" if money == 0 else ("%+d G" % money)
	var txt: String = "%s  %s   (%s)" % [glyph, a["name"], cost]
	if int(a.get("min_age", 12)) > 12:
		txt += "   · desde los %d" % int(a["min_age"])
	return txt

func _apply_preset(preset_id: String) -> void:
	var job_mid: String = "job_clockwork" if GameState.age >= 13 else "job_sanatorium"
	var job_phys: String = "job_caravan" if GameState.age >= 13 else "job_sanatorium"
	var slots: Array[String] = ["class_astrolabe", "job_sanatorium", "rest_manor"]
	match preset_id:
		"sabia":
			slots = ["class_astrolabe", "class_sanctuary", job_mid]
		"marcial":
			slots = ["class_armory", job_phys, "rest_manor"]
		"corte":
			slots = ["class_conservatory", "job_amphitheater", "rest_manor"]
		"oro_descanso":
			slots = ["job_sanatorium", "job_amphitheater", "rest_manor"]
	for i in range(TurnExecutor.BLOCKS_PER_BIMESTER):
		TurnExecutor.set_agenda_slot(i, slots[i])
	AstralAudio.play_confirm()
	toast.emit("Plantilla de agenda aplicada a los 3 decanos", "info")

func _on_activity_selected(slot: int, item: int) -> void:
	if _updating:
		return
	AstralAudio.play_ui()
	TurnExecutor.set_agenda_slot(slot, str(_option_buttons[slot].get_item_metadata(item)))

func _on_father_pressed(task_id: String) -> void:
	var res: Dictionary = TurnExecutor.toggle_father_task(task_id)
	if not res["ok"]:
		AstralAudio.play_warn()
		toast.emit(str(res["msg"]), "warn")
	else:
		AstralAudio.play_ui()

func _on_plan_changed() -> void:
	if visible:
		refresh()

func refresh() -> void:
	if not _built_ok():
		return
	_updating = true
	_tabs.set_tab_title(0, "  Agenda de %s  " % GameState.daughter_name)
	var bim: Dictionary = TimeManager.get_bimester_info()
	_bim_info.text = "[b]%s[/b]  —  %s\n%s" % [bim["name"], bim["season"], AstralTheme.colored("Bono del bimestre: " + str(bim["bonus_desc"]), AstralTheme.GOLD_PALE)]

	for i in range(TurnExecutor.BLOCKS_PER_BIMESTER):
		var ob: OptionButton = _option_buttons[i]
		for k in range(ob.item_count):
			var a: Dictionary = CatalogDB.get_activity(str(ob.get_item_metadata(k)))
			var locked: bool = GameState.age < int(a.get("min_age", 12))
			ob.set_item_disabled(k, locked)
			if str(ob.get_item_metadata(k)) == TurnExecutor.agenda[i]:
				ob.select(k)
		_detail_labels[i].text = _detail_text(TurnExecutor.agenda[i])

	var chk: Dictionary = TurnExecutor.validate_and_preview()
	_summary.text = _summary_text(chk)
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
	_updating = false

func _built_ok() -> bool:
	return _tabs != null and _option_buttons.size() == TurnExecutor.BLOCKS_PER_BIMESTER

func _detail_text(act_id: String) -> String:
	var a: Dictionary = CatalogDB.get_activity(act_id)
	if a.is_empty():
		return ""
	var pv: Dictionary = TurnExecutor.preview_block(act_id)
	var lines: Array[String] = []
	var mentor: String = str(a.get("mentor", ""))
	lines.append("[b]%s[/b]%s" % [a["name"], ("  ·  " + AstralTheme.colored(mentor, AstralTheme.TURQ)) if mentor != "" else ""])
	lines.append(AstralTheme.colored(str(a["desc"]), AstralTheme.MUTED))
	var chips: Array[String] = []
	for g in pv["gains"]:
		var v: int = int(g["value"])
		chips.append(AstralTheme.colored("%s %s" % [g["label"], AstralTheme.signed(v)], AstralTheme.GOOD if v > 0 else AstralTheme.BAD))
	if int(pv["seal_delta"]) != 0:
		chips.append(AstralTheme.colored("%s %s%%" % [GameState.get_stat_label("seal_integrity"), AstralTheme.signed(int(pv["seal_delta"]))], AstralTheme.GOOD if int(pv["seal_delta"]) > 0 else AstralTheme.BAD))
	var st: int = int(pv["stress"])
	chips.append(AstralTheme.colored("Estrés %s" % AstralTheme.signed(st), AstralTheme.BAD if st > 0 else AstralTheme.GOOD))
	var money: int = int(pv["gold"])
	if money != 0:
		chips.append(AstralTheme.colored("%s G" % AstralTheme.signed(money), AstralTheme.GOLD if money > 0 else AstralTheme.EMBER))
	lines.append("  ·  ".join(chips))
	var rival: String = str(a.get("rival_id", ""))
	if rival != "":
		lines.append(AstralTheme.colored("%s Rival presente: %s (choque de aula)" % [AstralTheme.G_SWORD, RivalMirror.get_data(rival).get("name", rival)], AstralTheme.ROSE))
	return "\n".join(lines)

func _summary_text(chk: Dictionary) -> String:
	var lines: Array[String] = []
	if not chk["ok"]:
		lines.append(AstralTheme.colored(str(chk["msg"]), AstralTheme.BAD))
		return "\n".join(lines)
	var net: int = int(chk["net_gold"])
	lines.append("Balance de oro: %s    |    Estrés previsto: %s    |    Oro tras el bimestre: %s" % [
		AstralTheme.colored(AstralTheme.signed(net) + " G", AstralTheme.GOLD if net >= 0 else AstralTheme.EMBER),
		AstralTheme.colored(AstralTheme.signed(int(chk["stress"])), AstralTheme.BAD if int(chk["stress"]) > 0 else AstralTheme.GOOD),
		AstralTheme.colored(str(GameState.gold + net) + " G", AstralTheme.IVORY)])
	var proj: int = GameState.stress + int(chk["stress"])
	if proj >= TurnExecutor.STRESS_COLLAPSE_THRESHOLD:
		lines.append(AstralTheme.colored("%s Riesgo de colapso: el estrés podría llegar a %d y %s se desplomaría antes del final." % [AstralTheme.G_BOLT, proj, GameState.daughter_name], AstralTheme.BAD))
	elif chk["fatigue_warning"] or proj >= TurnExecutor.STRESS_FATIGUE_THRESHOLD:
		lines.append(AstralTheme.colored("%s Fatiga: con 80 o más de Estrés, las ganancias bajan un 25%%." % AstralTheme.G_BOLT, AstralTheme.EMBER))
	for n in chk["multiplier_notes"]:
		lines.append(AstralTheme.colored(AstralTheme.G_STAR2 + " " + str(n), AstralTheme.GOLD_PALE))
	return "\n".join(lines)

func show_father_tab() -> void:
	if _tabs != null:
		_tabs.current_tab = 1
