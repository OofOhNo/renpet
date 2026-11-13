extends BaseWindow
class_name AstralCrucible

## Crisol Astral (Fase 5): vaso alquímico animado, inventario cósmico, vista previa, bazar, destilación y purificación.

class _CrucibleCanvas extends Control:
	var sat_ratio: float = 0.0
	var preview_active: bool = false
	var _t: float = 0.0
	var _flash: float = 0.0
	var _flash_col := Color(0.95, 0.80, 0.42, 1.0)
	var _bubbles: Array[Dictionary] = []
	var _sparks: Array[Dictionary] = []
	var _rng := RandomNumberGenerator.new()

	func _init() -> void:
		custom_minimum_size = Vector2(142, 134)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rng.randomize()
		for i in range(14):
			_bubbles.append({
				"x": _rng.randf_range(-0.65, 0.65),
				"y": _rng.randf(),
				"spd": _rng.randf_range(0.22, 0.55),
				"r": _rng.randf_range(1.6, 3.6)
			})

	func trigger_reaction(col: Color, sparks_n: int = 14) -> void:
		_flash = 1.0
		_flash_col = col
		for i in range(sparks_n):
			var a: float = _rng.randf() * TAU
			var spd: float = _rng.randf_range(35.0, 95.0)
			_sparks.append({
				"pos": size * 0.5,
				"vel": Vector2.from_angle(a) * spd,
				"life": _rng.randf_range(0.35, 0.72),
				"max": 0.72,
				"col": col
			})

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		if _flash > 0.0:
			_flash = maxf(0.0, _flash - delta * 2.1)
		var spd_mult: float = 1.0 + sat_ratio * 1.8
		for b in _bubbles:
			b["y"] = float(b["y"]) - float(b["spd"]) * delta * spd_mult
			if float(b["y"]) < 0.08:
				b["y"] = 0.92
				b["x"] = _rng.randf_range(-0.65, 0.65)
		for i in range(_sparks.size() - 1, -1, -1):
			var sp: Dictionary = _sparks[i]
			sp["life"] = float(sp["life"]) - delta
			if float(sp["life"]) <= 0.0:
				_sparks.remove_at(i)
			else:
				sp["pos"] = (sp["pos"] as Vector2) + (sp["vel"] as Vector2) * delta
		queue_redraw()

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var vessel_r: float = minf(size.x, size.y) * 0.36
		var ring_r: float = vessel_r + 12.0
		var liq_col: Color = Color(0.95, 0.78, 0.38, 0.78) if sat_ratio < 0.6 else (Color(0.94, 0.52, 0.24, 0.84) if sat_ratio < 0.85 else Color(0.84, 0.32, 0.64, 0.90))

		# Anillo exterior rúnico en rotación
		var rot: float = _t * (0.4 + sat_ratio * 1.6)
		draw_arc(c, ring_r, 0.0, TAU, 44, Color(0.84, 0.69, 0.36, 0.36), 1.6, true)
		for i in range(6):
			var a: float = rot + float(i) * (TAU / 6.0)
			var p: Vector2 = c + Vector2.from_angle(a) * ring_r
			draw_circle(p, 2.8 if (i % 2 == 0) else 2.0, Color(0.95, 0.84, 0.50, 0.75))

		# Vasija de cristal
		draw_circle(c, vessel_r, Color(0.04, 0.06, 0.16, 0.86))
		var fill_h: float = lerpf(0.18, 0.88, sat_ratio)
		for s in range(9):
			var ry: float = vessel_r * (1.0 - 2.0 * fill_h * float(s) / 8.0)
			var half_w: float = sqrt(maxf(0.0, vessel_r * vessel_r - ry * ry)) * 0.92
			if half_w > 4.0:
				var wy: float = c.y + ry + sin(_t * 4.0 + float(s)) * 1.2
				draw_line(Vector2(c.x - half_w, wy), Vector2(c.x + half_w, wy), Color(liq_col.r, liq_col.g, liq_col.b, 0.32), 4.0, true)
		for b in _bubbles:
			var by: float = (c.y - vessel_r * 0.72) + float(b["y"]) * (vessel_r * 1.44)
			var dy: float = by - c.y
			var max_dx: float = sqrt(maxf(4.0, vessel_r * vessel_r - dy * dy)) * 0.72
			var bx: float = c.x + float(b["x"]) * max_dx
			if by >= c.y + vessel_r * (1.0 - 2.0 * fill_h):
				draw_circle(Vector2(bx, by), float(b["r"]), Color(1.0, 0.94, 0.75, 0.55))

		if sat_ratio >= 0.82:
			for k in range(3):
				var la: float = _t * 3.5 + float(k) * 2.1
				draw_line(c + Vector2.from_angle(la) * (vessel_r * 0.35), c + Vector2.from_angle(la + 0.5) * (vessel_r * 0.92), Color(0.95, 0.65, 1.0, 0.65), 1.6, true)

		if preview_active:
			var p_orb: Vector2 = c + Vector2.from_angle(-_t * 2.4) * (ring_r + 3.0)
			draw_circle(p_orb, 6.0, Color(0.32, 0.84, 0.78, 0.35))
			draw_circle(p_orb, 3.2, Color(0.75, 0.98, 0.95, 0.95))

		draw_arc(c, vessel_r, 0.0, TAU, 48, Color(0.92, 0.80, 0.46, 0.82), 2.4, true)
		if _flash > 0.0:
			draw_arc(c, lerpf(vessel_r * 0.6, ring_r + 14.0, 1.0 - _flash), 0.0, TAU, 40, Color(_flash_col.r, _flash_col.g, _flash_col.b, _flash * 0.85), 3.2, true)
		for sp in _sparks:
			var a: float = clampf(float(sp["life"]) / float(sp["max"]), 0.0, 1.0)
			var sc: Color = sp["col"]
			draw_circle(sp["pos"], 3.0 * a, Color(sc.r, sc.g, sc.b, a))

var _sat_bar: StatBar
var _sat_note: Label
var _crucible_fx: _CrucibleCanvas
var _inv_box: VBoxContainer
var _detail_box: VBoxContainer
var _shop_box: VBoxContainer
var _mut_chips: HFlowContainer
var _selected: String = ""
var _confirm: ConfirmationDialog

func _ready() -> void:
	setup("Crisol Astral — Horno de Fusión")
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Sobrecarga Astral"
	_confirm.ok_button_text = "Fundir de todos modos"
	_confirm.cancel_button_text = "Cancelar"
	_confirm.theme = AstralTheme.get_theme()
	add_child(_confirm)

func build() -> void:
	var top := AstralTheme.panel("GlowPanel")
	var top_h := AstralTheme.hbox(14)
	top.add_child(top_h)
	_crucible_fx = _CrucibleCanvas.new()
	top_h.add_child(_crucible_fx)
	var tv := AstralTheme.vbox(6)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_h.add_child(tv)
	_sat_bar = StatBar.new()
	_sat_bar.setup("Saturación Astral", "astral_saturation", 0, 100, AstralTheme.STAT_COLORS["astral_saturation"], str(AstralTheme.STAT_TOOLTIPS["astral_saturation"]), 190)
	tv.add_child(_sat_bar)
	_sat_note = AstralTheme.label("", "CaptionLabel", AstralTheme.MUTED, true)
	tv.add_child(_sat_note)
	_mut_chips = HFlowContainer.new()
	_mut_chips.add_theme_constant_override("h_separation", 6)
	_mut_chips.add_theme_constant_override("v_separation", 4)
	tv.add_child(_mut_chips)
	body.add_child(top)

	var cols := AstralTheme.hbox(16)
	body.add_child(cols)
	var left := AstralTheme.vbox(8)
	left.custom_minimum_size.x = 380
	cols.add_child(left)
	left.add_child(AstralTheme.label("Inventario cósmico", "HeadingLabel"))
	_inv_box = AstralTheme.vbox(8)
	left.add_child(_inv_box)

	_detail_box = AstralTheme.vbox(10)
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(_detail_box)

	body.add_child(AstralTheme.separator())
	body.add_child(AstralTheme.label("Alquimia Doméstica del Crisol", "HeadingLabel"))
	_shop_box = AstralTheme.vbox(8)
	body.add_child(_shop_box)

func refresh() -> void:
	if _sat_bar == null:
		return
	_sat_bar.set_value(GameState.astral_saturation)
	if _crucible_fx != null:
		_crucible_fx.sat_ratio = clampf(float(GameState.astral_saturation) / 100.0, 0.0, 1.0)
		_crucible_fx.preview_active = (_selected != "")
	var eff: float = CrucibleManager.get_efficiency()
	var seal_lbl: String = GameState.get_stat_label("seal_integrity")
	if GameState.astral_saturation >= CrucibleManager.SATURATION_HARD_LIMIT:
		_sat_note.text = "Crítica: absorbes solo el 40%% y %s sufre daño extra." % seal_lbl
		_sat_note.add_theme_color_override("font_color", AstralTheme.BAD)
	elif GameState.astral_saturation >= CrucibleManager.SATURATION_SOFT_LIMIT:
		_sat_note.text = "Alta: absorbes solo el 70% de los atributos."
		_sat_note.add_theme_color_override("font_color", AstralTheme.EMBER)
	else:
		_sat_note.text = "Estable: el cuerpo absorbe el 100%% de las reliquias. Sobre 60 el rendimiento cae. Nivel del Crisol: %d." % CrucibleManager.get_crucible_level()
		_sat_note.add_theme_color_override("font_color", AstralTheme.MUTED)
	clear(_mut_chips)
	if GameState.active_mutations.is_empty():
		_mut_chips.add_child(AstralTheme.chip("Sin mutaciones activas", AstralTheme.MUTED, null, 12))
	else:
		for m in GameState.active_mutations:
			var mut_d: Dictionary = CatalogDB.get_mutation(m)
			var mc := AstralTheme.chip("%s %s" % [AstralTheme.G_BOLT, CatalogDB.get_mutation_name(m)], AstralTheme.AMETHYST, null, 12)
			mc.tooltip_text = str(mut_d.get("desc", ""))
			_mut_chips.add_child(mc)
	_refresh_inventory()
	_refresh_detail()
	_refresh_shop()

func _refresh_inventory() -> void:
	clear(_inv_box)
	var any: bool = false
	for m in CatalogDB.COSMIC_MATERIALS:
		var count: int = int(GameState.materials_inventory.get(m["id"], 0))
		var b := AstralTheme.button("", "TabLikeButton")
		b.toggle_mode = true
		b.button_pressed = (_selected == m["id"])
		b.custom_minimum_size.y = 50
		b.disabled = count <= 0
		b.tooltip_text = "%s\nDónde conseguirlo: %s." % [str(m.get("origin", "")), "Bazar de Medianoche o Destilación" if int(m.get("exclusive_rep", 0)) == 0 else "Bazar con Reputación Paterna >= %d" % int(m.get("exclusive_rep", 0))]
		var mg := MarginContainer.new()
		mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mg.add_theme_constant_override("margin_left", 8)
		mg.add_theme_constant_override("margin_right", 8)
		mg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(mg)
		var row_h := AstralTheme.hbox(8)
		row_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mg.add_child(row_h)
		var ibox := AstralTheme.vignette_card(CatalogDB.get_relic_icon(str(m["id"])), Vector2(44, 42), AstralTheme.AMETHYST if count > 0 else Color(0.5, 0.5, 0.55, 0.35))
		ibox.modulate = Color.WHITE if count > 0 else Color(0.7, 0.72, 0.80, 0.45)
		ibox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_h.add_child(ibox)
		var nm := AstralTheme.label(str(m["name"]), "", AstralTheme.IVORY if count > 0 else AstralTheme.MUTED)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_h.add_child(nm)
		var qty := AstralTheme.chip("×%d" % count, AstralTheme.GOLD_PALE if count > 0 else AstralTheme.MUTED, null, 13)
		qty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_h.add_child(qty)
		var mid: String = m["id"]
		b.pressed.connect(func() -> void:
			AstralAudio.play_ui()
			_selected = mid
			refresh())
		_inv_box.add_child(b)
		if count > 0:
			any = true
	if not any:
		_inv_box.add_child(AstralTheme.chip("Inventario vacío · Compra en Acueductos o destila abajo", AstralTheme.MUTED, null, 13))
	if _selected != "" and int(GameState.materials_inventory.get(_selected, 0)) <= 0:
		_selected = ""

func _refresh_detail() -> void:
	clear(_detail_box)
	if _selected == "":
		var card := AstralTheme.panel("SunkenPanel")
		var ch := AstralTheme.hbox(12)
		card.add_child(ch)
		ch.add_child(AstralTheme.vignette_card("res://assets/ui/relic_goddess_tear.png", Vector2(54, 54), AstralTheme.AMETHYST))
		var lbl := AstralTheme.label("Selecciona una reliquia a la izquierda para examinar su aura y asimilarla.", "", AstralTheme.MUTED, true)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ch.add_child(lbl)
		_detail_box.add_child(card)
		return
	var p: Dictionary = CrucibleManager.preview(_selected)
	if not p.get("ok", false):
		return
	var mat: Dictionary = p["material"]
	var card := AstralTheme.panel("CardPanel")
	var v := AstralTheme.vbox(10)
	card.add_child(v)
	var head_h := AstralTheme.hbox(12)
	v.add_child(head_h)
	head_h.add_child(AstralTheme.vignette_card(CatalogDB.get_relic_icon(_selected), Vector2(74, 74), AstralTheme.AMETHYST))
	var hv := AstralTheme.vbox(3)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head_h.add_child(hv)
	hv.add_child(AstralTheme.label(str(mat["name"]), "HeadingLabel"))
	hv.add_child(AstralTheme.chip(str(mat["origin"]), AstralTheme.MUTED, null, 12))

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 6)
	v.add_child(flow)
	for sk in p["stat_deltas"].keys():
		var dv: int = int(p["stat_deltas"][sk])
		var col: Color = AstralTheme.STAT_COLORS.get(sk, AstralTheme.GOOD)
		flow.add_child(AstralTheme.chip("%s %s" % [GameState.get_stat_label(sk), AstralTheme.signed(dv)], AstralTheme.GOOD, col, 13))
	var sd: int = int(p["seal_delta"])
	var seal_lbl: String = GameState.get_stat_label("seal_integrity")
	flow.add_child(AstralTheme.chip("%s %s%% (%d%%→%d%%)" % [seal_lbl, AstralTheme.signed(sd), GameState.seal_integrity, int(p["seal_after"])], AstralTheme.GOOD if sd >= 0 else AstralTheme.BAD, null, 13))
	flow.add_child(AstralTheme.chip("Saturación %s (%d→%d)" % [AstralTheme.signed(int(p["sat_gain"])), GameState.astral_saturation, int(p["sat_after"])], AstralTheme.EMBER if int(p["sat_gain"]) > 0 else AstralTheme.GOOD, null, 13))

	var mut_p := AstralTheme.panel("SunkenPanel")
	var mh := AstralTheme.hbox(10)
	mut_p.add_child(mh)
	mh.add_child(AstralTheme.vignette_card(CatalogDB.get_relic_icon(_selected), Vector2(46, 46), AstralTheme.AMETHYST))
	var mv := AstralTheme.vbox(2)
	mv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mh.add_child(mv)
	var mut_top := AstralTheme.hbox(8)
	mv.add_child(mut_top)
	mut_top.add_child(AstralTheme.label("Mutación: %s" % str(p["mutation_name"]), "SubLabel", AstralTheme.AMETHYST))
	mut_top.add_child(AstralTheme.chip("NUEVA" if bool(p["new_mutation"]) else "Activa", AstralTheme.GOLD_PALE if bool(p["new_mutation"]) else AstralTheme.MUTED, null, 11))
	mv.add_child(AstralTheme.label(str(CatalogDB.get_mutation(str(p["mutation_id"])).get("desc", "")), "CaptionLabel", AstralTheme.IVORY, true))
	v.add_child(mut_p)

	if not (p["warnings"] as Array).is_empty():
		var w_flow := HFlowContainer.new()
		w_flow.add_theme_constant_override("h_separation", 8)
		v.add_child(w_flow)
		for w in p["warnings"]:
			w_flow.add_child(AstralTheme.chip(AstralTheme.G_BOLT + " " + str(w), AstralTheme.BAD if bool(p["overload"]) else AstralTheme.EMBER, null, 13))
	var go := AstralTheme.button("%s  ASIMILAR EN EL HORNO" % AstralTheme.G_FLASK, "PrimaryButton")
	go.custom_minimum_size.y = 54
	var mid: String = _selected
	go.pressed.connect(func() -> void: _try_assimilate(mid, false))
	v.add_child(go)
	_detail_box.add_child(card)

func _try_assimilate(mid: String, confirmed: bool) -> void:
	var res: Dictionary = CrucibleManager.assimilate(mid, confirmed)
	if res.get("needs_confirm", false):
		_confirm.dialog_text = str(res["msg"]) + "\n\nSufrirá: -15%% %s, +20 Estrés, +10 %s y +8 Entropía." % [
			GameState.get_stat_label("seal_integrity"), GameState.get_stat_label("abyssal_sync")
		]
		for c in _confirm.confirmed.get_connections():
			_confirm.confirmed.disconnect(c["callable"])
		_confirm.confirmed.connect(func() -> void: _try_assimilate(mid, true))
		_confirm.popup_centered(Vector2i(560, 220))
		return
	if not res.get("ok", false):
		AstralAudio.play_warn()
		toast.emit(str(res.get("msg", "No se pudo asimilar.")), "warn")
		return
	var text: String = "Asimilaste %s. %s" % [res["name"], ", ".join(res["gains"])]
	if res["new_mutation"]:
		text += "  ¡Mutación despertada: %s!" % res["mutation_name"]
	if res["overload"]:
		text = "¡SOBRECARGA ASTRAL! " + text
		AstralAudio.play_warn()
		if _crucible_fx != null and DisplayServer.get_name() != "headless":
			_crucible_fx.trigger_reaction(AstralTheme.BAD, 20)
	else:
		AstralAudio.play_triumph() if res["new_mutation"] else AstralAudio.play_confirm()
		if _crucible_fx != null and DisplayServer.get_name() != "headless":
			_crucible_fx.trigger_reaction(AstralTheme.AMETHYST if res["new_mutation"] else AstralTheme.GOLD, 16)
	speak.emit("Horno Astral", text)
	toast.emit(text, "bad" if res["overload"] else "good")
	refresh()

func _refresh_shop() -> void:
	clear(_shop_box)
	var bazar_open: bool = TimeManager.is_bazaar_open()
	var bazar_hint: String = "%s Zahir acampa en los Acueductos este bimestre" % AstralTheme.G_STAR if bazar_open else "Bazar de Zahir: disponible en los Acueductos en bimestres pares"
	_shop_box.add_child(AstralTheme.chip(bazar_hint, AstralTheme.TURQ if bazar_open else AstralTheme.MUTED, null, 13))

	var row := AstralTheme.hbox(12)
	_shop_box.add_child(row)
	var dist := AstralTheme.button("%s  Destilar reliquia (%d G)" % [AstralTheme.G_HOURGLASS, CrucibleManager.get_distill_cost()], "TabLikeButton",
		"Condensa luz de la esfera armilar en una reliquia al azar (determinista). Una vez por bimestre; +8 Resonancia.")
	dist.custom_minimum_size.y = 56
	dist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dist.disabled = CrucibleManager.distilled_this_bimester or GameState.gold < CrucibleManager.get_distill_cost()
	dist.pressed.connect(func() -> void:
		var r: Dictionary = CrucibleManager.distill_relic()
		AstralAudio.play_triumph() if r.get("ok", false) else AstralAudio.play_warn()
		if r.get("ok", false) and _crucible_fx != null and DisplayServer.get_name() != "headless":
			_crucible_fx.trigger_reaction(AstralTheme.TURQ, 14)
		speak.emit("Horno Astral", str(r.get("msg", "")))
		toast.emit(str(r.get("msg", "")), "good" if r.get("ok", false) else "warn")
		refresh())
	row.add_child(dist)
	var pur := AstralTheme.button("%s  Purificar Saturación (%d G)" % [AstralTheme.G_FLOWER, CrucibleManager.get_purify_cost()], "TabLikeButton",
		"-25 Saturación, +3%% %s, -10 Estrés." % GameState.get_stat_label("seal_integrity"))
	pur.custom_minimum_size.y = 56
	pur.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pur.disabled = GameState.astral_saturation <= 0 or GameState.gold < CrucibleManager.get_purify_cost()
	pur.pressed.connect(func() -> void:
		var r: Dictionary = CrucibleManager.purify_saturation()
		AstralAudio.play_confirm() if r.get("ok", false) else AstralAudio.play_warn()
		if r.get("ok", false) and _crucible_fx != null and DisplayServer.get_name() != "headless":
			_crucible_fx.trigger_reaction(AstralTheme.GOOD, 14)
		speak.emit("Termas de Alabastro", str(r.get("msg", "")))
		toast.emit(str(r.get("msg", "")), "good" if r.get("ok", false) else "warn")
		refresh())
	row.add_child(pur)
