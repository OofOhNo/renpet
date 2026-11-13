extends BaseWindow
class_name HearthWindow

## Chimenea y Hogar (Fase 3.4 y 3.5+): charla nocturna con Renpet, sanatorio familiar, retiro estacional, dieta y mejoras.

signal vacation_taken(vac_id: String)
signal crisis_requested()

const FACILITIES: Array[Dictionary] = [
	{"id": "library", "name": "Bóveda Estelar", "desc": "Sala de estudio. +4 por nivel a las ganancias principales de la Torre del Astrolabio."},
	{"id": "armory", "name": "Patio de Lanzas", "desc": "Campo de práctica. +4 por nivel en la Academia de Armas y la Escolta de Caravanas."},
	{"id": "conservatory", "name": "Salón de Lotos y Música", "desc": "+4 por nivel en Conservatorio, Anfiteatro y reposo en casa, y alivia 3 de Estrés por nivel cada bimestre."},
	{"id": "crucible", "name": "Cámara del Crisol", "desc": "Taller del Horno Astral. Cada nivel reduce 2 la Saturación generada, acelera su disipación, abarata la purificación y suma +4 en la Relojería Real."},
	{"id": "sanctum", "name": "Jardín Botánico-Sanatorio", "desc": "Invernadero curativo. +4% en Sanatorio y Reposo, +6 PV máx., -2 Estrés, disipa +1% Saturación y refuerza el Anclaje Humano cada bimestre."},
	{"id": "treasury", "name": "Salón Diplomático", "desc": "Despacho de finanzas y Corte. Cada nivel rinde +18 G bimestrales, reduce -1 Sospecha de Corte y aporta +3% en Conservatorio y Anfiteatro."}
]
class _EmberFX extends Control:
	var _embers: Array[Dictionary] = []
	var _rng := RandomNumberGenerator.new()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rng.randomize()
		for i in range(18):
			_embers.append({
				"x": _rng.randf(),
				"y": _rng.randf(),
				"spd": _rng.randf_range(0.14, 0.36),
				"r": _rng.randf_range(1.4, 3.2),
				"phase": _rng.randf() * TAU,
				"col": Color(1.0, _rng.randf_range(0.48, 0.82), 0.24, 0.72)
			})

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		for e in _embers:
			e["phase"] = float(e["phase"]) + delta * 3.2
			e["y"] = float(e["y"]) - float(e["spd"]) * delta
			if float(e["y"]) < -0.05:
				e["y"] = 1.04
				e["x"] = _rng.randf()
		queue_redraw()

	func _draw() -> void:
		if size.x <= 4.0 or size.y <= 4.0:
			return
		for e in _embers:
			var px: float = clampf(float(e["x"]) + sin(float(e["phase"])) * 0.03, 0.0, 1.0) * size.x
			var py: float = float(e["y"]) * size.y
			var r: float = float(e["r"])
			var c: Color = e["col"]
			var a: float = clampf(sin(clampf(float(e["y"]), 0.0, 1.0) * PI), 0.0, 1.0) * c.a
			draw_circle(Vector2(px, py), r * 2.4, Color(c.r, c.g, c.b, a * 0.28))
			draw_circle(Vector2(px, py), r, Color(1.0, 0.90, 0.62, a))

const MAX_LEVEL: int = 8
const UPGRADE_BASE_COST: int = 300

static func get_upgrade_cost(lvl: int) -> int:
	return UPGRADE_BASE_COST * lvl + maxi(0, lvl - 4) * 350

const ATTITUDE_ORDER: Array[String] = ["warm", "strict", "curious", "protective"]
const ATTITUDE_HINT: Dictionary = {
	"warm": "Consuela y fortalece el vínculo.",
	"strict": "Disciplina y templanza.",
	"curious": "Investiga y profundiza.",
	"protective": "Cuida y pone límites."
}

var _tabs: TabContainer
var _chat_box: VBoxContainer
var _diet_box: VBoxContainer
var _estate_box: VBoxContainer
var _selected_topic: String = ""
var _last_result: String = ""

func _ready() -> void:
	setup("Chimenea y Hogar", false)

func build() -> void:
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_tabs)
	_chat_box = add_tab(_tabs, "  Charla en la Chimenea  ")
	_diet_box = add_tab(_tabs, "  Mesa y Dieta  ")
	_estate_box = add_tab(_tabs, "  Mejoras de la Mansión  ")

func refresh() -> void:
	if _tabs == null:
		return
	_refresh_chat()
	_refresh_diet()
	_refresh_estate()

# ------------------------------------------------------------------------------
# CHARLA
# ------------------------------------------------------------------------------
func _attitude_visual(att: String) -> Array:
	match att:
		"warm":
			return [AstralTheme.G_HEART, AstralTheme.ROSE]
		"strict":
			return [AstralTheme.G_SWORD, AstralTheme.GOLD]
		"curious":
			return [AstralTheme.G_STAR, AstralTheme.TURQ]
		_:
			return [AstralTheme.G_ANKH, AstralTheme.GOOD]

func _facility_icon(fid: String) -> String:
	match fid:
		"library":
			return "res://assets/art/illus_study_astrolabe.png"
		"armory":
			return "res://assets/art/illus_martial_courtyard.png"
		"conservatory":
			return "res://assets/art/illus_conservatory_harp.png"
		"sanctum":
			return "res://assets/art/illus_sanatorium_garden.png"
		"treasury":
			return "res://assets/art/bg_district_palacio.png"
		_:
			return "res://assets/ui/relic_comet_dust.png"

func _refresh_chat() -> void:
	clear(_chat_box)
	var ban_wrap := PanelContainer.new()
	ban_wrap.theme_type_variation = "GlowPanel"
	ban_wrap.clip_contents = true
	ban_wrap.custom_minimum_size = Vector2(0, 96)
	var bg_tex: Texture2D = AstralTheme.load_tex("res://assets/art/bg_hearth_night.png")
	if bg_tex != null:
		var ban := TextureRect.new()
		ban.texture = bg_tex
		ban.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ban.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		ban.modulate = Color(1, 1, 1, 0.56)
		ban.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ban_wrap.add_child(ban)
	var embers := _EmberFX.new()
	embers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ban_wrap.add_child(embers)
	var gh := AstralTheme.hbox(12)
	ban_wrap.add_child(gh)
	gh.add_child(AstralTheme.icon_box(GameState.get_active_portrait_path(), Vector2(56, 68), Color.WHITE, "CardPanel"))
	var gv := AstralTheme.vbox(4)
	gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gh.add_child(gv)
	var g_head := AstralTheme.hbox(8)
	gv.add_child(g_head)
	g_head.add_child(AstralTheme.label("%s junto al fuego" % GameState.daughter_name, "SubLabel", AstralTheme.GOLD_PALE))
	g_head.add_child(AstralTheme.chip(str(GameState.get_mood_summary()["short_tag"]), AstralTheme.AMETHYST, null, 12))
	gv.add_child(AstralTheme.label(GameState.get_dynamic_manor_greeting(), "", AstralTheme.IVORY, true))
	_chat_box.add_child(ban_wrap)

	if GameState.exhausted_sick:
		var sick_p := AstralTheme.panel("CardPanel")
		var sv := AstralTheme.vbox(6)
		sick_p.add_child(sv)
		sv.add_child(AstralTheme.label("%s AGOTAMIENTO CRÍTICO: %s necesita descanso" % [AstralTheme.G_BOLT, GameState.daughter_name], "SubLabel", AstralTheme.BAD, true))
		sv.add_child(AstralTheme.label("El estrés bloquea las clases. Cuídala en casa o ve al Boticario en los Acueductos.", "CaptionLabel", AstralTheme.IVORY, true))
		var b_care := AstralTheme.button("%s Cuidados Paternos (-20 Energía, -24 Estrés)" % AstralTheme.G_HEART, "PrimaryButton")
		b_care.disabled = GameState.father_energy < 20
		b_care.pressed.connect(func() -> void: _heal_exhaustion(false))
		sv.add_child(b_care)
		_chat_box.add_child(sick_p)

	if GameState.pending_astral_crisis:
		var cp := AstralTheme.panel("CardPanel")
		var cv := AstralTheme.vbox(6)
		cp.add_child(cv)
		var tier: int = GameState.get_secret_tier()
		cv.add_child(AstralTheme.label("☠ HAMBRE ESTELAR EN EL CRISOL" if tier < 2 else "☠ CRISIS DE APETITO ESTELAR ACTIVA", "SubLabel", AstralTheme.AMETHYST))
		var cb_txt: String = "Calmar el eco astral junto al fuego ▶" if tier < 2 else "Atender el eco de Nyx-Aethel junto al fuego ▶"
		var cb := AstralTheme.button(cb_txt, "DangerButton")
		cb.pressed.connect(func() -> void: crisis_requested.emit())
		cv.add_child(cb)
		_chat_box.add_child(cp)

	var vac: Dictionary = CatalogDB.get_vacation_for_bimester(TimeManager.current_bimester)
	if not vac.is_empty() and not GameState.vacation_used_years.has(TimeManager.current_year):
		var vp := AstralTheme.panel("GlowPanel")
		var vh := AstralTheme.hbox(12)
		vp.add_child(vh)
		var vtex: Texture2D = AstralTheme.load_tex(str(vac["bg"]))
		if vtex != null:
			var vr := TextureRect.new()
			vr.texture = vtex
			vr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			vr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			vr.custom_minimum_size = Vector2(128, 76)
			vh.add_child(vr)
		var vv := AstralTheme.vbox(3)
		vv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vh.add_child(vv)
		vv.add_child(AstralTheme.label("%s  Retiro: %s" % [AstralTheme.G_SUN, str(vac["name"])], "SubLabel", AstralTheme.GOLD))
		vv.add_child(AstralTheme.label(str(vac["desc"]), "CaptionLabel", AstralTheme.IVORY, true))
		var vcost: int = int(vac.get("cost", 130))
		var ven: int = int(vac.get("energy", 35))
		var vb := AstralTheme.button("Viajar (-%d G, -%d E)" % [vcost, ven], "PrimaryButton")
		vb.custom_minimum_size = Vector2(168, 46)
		vb.disabled = GameState.gold < vcost or GameState.father_energy < ven
		vb.pressed.connect(func() -> void: _take_vacation(vac))
		vh.add_child(vb)
		_chat_box.add_child(vp)

	if _last_result != "":
		var res := AstralTheme.panel("CardPanel")
		res.add_child(AstralTheme.rich(_last_result))
		_chat_box.add_child(res)

	if Chronicle.chatted_this_bimester:
		_chat_box.add_child(AstralTheme.chip("Velada completada este bimestre · Próxima charla el siguiente turno", AstralTheme.MUTED, null, 13))
		return

	if _selected_topic == "":
		_chat_box.add_child(AstralTheme.label("Tema de conversación (1 por bimestre):", "HeadingLabel", AstralTheme.GOLD, true))
		var t_grid := GridContainer.new()
		t_grid.columns = 2
		t_grid.add_theme_constant_override("h_separation", 10)
		t_grid.add_theme_constant_override("v_separation", 8)
		_chat_box.add_child(t_grid)
		for t in Chronicle.get_fireplace_topics():
			var b := AstralTheme.button("%s  %s" % [AstralTheme.G_FLOWER, t["title"]], "")
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size.y = 52
			b.tooltip_text = str(t.get("prompt", ""))
			var tid: String = t["id"]
			b.pressed.connect(func() -> void:
				_selected_topic = tid
				_last_result = ""
				_refresh_chat())
			t_grid.add_child(b)
		return

	var topic: Dictionary = FireplaceTopics.get_topic(_selected_topic)
	var tc := AstralTheme.panel("CardPanel")
	var tv := AstralTheme.vbox(4)
	tc.add_child(tv)
	tv.add_child(AstralTheme.label(str(topic["title"]), "SubLabel", AstralTheme.GOLD_PALE))
	tv.add_child(AstralTheme.label(str(topic["prompt"]), "", AstralTheme.IVORY, true))
	_chat_box.add_child(tc)
	_chat_box.add_child(AstralTheme.label("Elige tu actitud:", "HeadingLabel", AstralTheme.GOLD, true))
	var s_grid := GridContainer.new()
	s_grid.columns = 2
	s_grid.add_theme_constant_override("h_separation", 10)
	s_grid.add_theme_constant_override("v_separation", 8)
	_chat_box.add_child(s_grid)
	for att in ATTITUDE_ORDER:
		var st: Dictionary = topic["stances"][att]
		var avis: Array = _attitude_visual(att)
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 76)
		b.tooltip_text = "%s\n%s" % [str(ATTITUDE_HINT[att]), str(st["father"])]
		var mg := MarginContainer.new()
		mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mg.add_theme_constant_override("margin_left", 12)
		mg.add_theme_constant_override("margin_right", 12)
		mg.add_theme_constant_override("margin_top", 8)
		mg.add_theme_constant_override("margin_bottom", 8)
		mg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(mg)
		var bv := AstralTheme.vbox(4)
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mg.add_child(bv)
		var top_h := AstralTheme.hbox(8)
		top_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(top_h)
		var ico_lbl := AstralTheme.label("%s  %s" % [avis[0], FireplaceTopics.ATTITUDES[att]], "SubLabel", avis[1])
		ico_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_h.add_child(ico_lbl)
		var hint_lbl := AstralTheme.label(str(ATTITUDE_HINT[att]), "CaptionLabel", AstralTheme.MUTED, true)
		hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_h.add_child(hint_lbl)
		var eff_flow := HFlowContainer.new()
		eff_flow.add_theme_constant_override("h_separation", 6)
		eff_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(eff_flow)
		for k in st["effects"].keys():
			var val: int = int(st["effects"][k])
			if val == 0:
				continue
			var good: bool = (val > 0) != (k == "stress" or k == "entropia")
			var ch := AstralTheme.chip("%s %s" % [GameState.get_stat_label(k), AstralTheme.signed(val)], AstralTheme.GOOD if good else AstralTheme.BAD, null, 12)
			ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			eff_flow.add_child(ch)
		var a_key: String = att
		b.pressed.connect(func() -> void: _apply_stance(topic, a_key))
		s_grid.add_child(b)
	var back := AstralTheme.button("◀ Elegir otro tema", "TabLikeButton")
	back.pressed.connect(func() -> void:
		_selected_topic = ""
		_refresh_chat())
	_chat_box.add_child(back)

func _apply_stance(topic: Dictionary, att: String) -> void:
	var st: Dictionary = topic["stances"][att]
	var labels: Array[String] = []
	GameState.begin_batch()
	for k in st["effects"].keys():
		var applied: int = GameState.modify_stat(k, int(st["effects"][k]))
		if applied != 0:
			labels.append(AstralTheme.colored("%s %s" % [GameState.get_stat_label(k), AstralTheme.signed(applied)], AstralTheme.GOOD if (applied > 0) != (k == "stress" or k == "entropia") else AstralTheme.BAD))
	GameState.end_batch()
	Chronicle.chatted_this_bimester = true
	Chronicle.record_event("chat_" + str(topic["id"]), "Charla en la chimenea: " + str(topic["title"]), str(st["father"]), "family", 2)
	_last_result = "[b]%s[/b] (%s):\n%s\n\n[b]%s[/b]:\n%s\n\n%s" % [
		GameState.father_name, FireplaceTopics.ATTITUDES[att], AstralTheme.colored(str(st["father"]), AstralTheme.GOLD_PALE),
		GameState.daughter_name, AstralTheme.colored(str(st["reply"]), AstralTheme.IVORY), "  ·  ".join(labels)]
	_selected_topic = ""
	speak.emit("%s — junto a la chimenea" % GameState.daughter_name, str(st["reply"]))
	AstralAudio.play_confirm()
	toast.emit("Charla compartida con %s" % GameState.daughter_name, "good")
	refresh()

# ------------------------------------------------------------------------------
# DIETA
# ------------------------------------------------------------------------------
func _refresh_diet() -> void:
	clear(_diet_box)
	_diet_box.add_child(AstralTheme.chip("El régimen se cobra al cerrar cada bimestre · Si falta oro cae a Dieta Austera", AstralTheme.MUTED, null, 13))
	for d in CatalogDB.DIETS:
		var selected: bool = int(GameState.current_diet) == int(d["id"])
		var card := AstralTheme.panel("GlowPanel" if selected else "CardPanel")
		var h := AstralTheme.hbox(14)
		card.add_child(h)
		var icon_f := AstralTheme.panel("SunkenPanel")
		icon_f.custom_minimum_size = Vector2(54, 54)
		var icon := AstralTheme.label(str(d["icon"]), "TitleLabel", AstralTheme.GOLD)
		icon.add_theme_font_size_override("font_size", 32)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_f.add_child(icon)
		h.add_child(icon_f)
		var mid := AstralTheme.vbox(3)
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(mid)
		var top_d := AstralTheme.hbox(8)
		mid.add_child(top_d)
		top_d.add_child(AstralTheme.label(str(d["name"]), "SubLabel"))
		top_d.add_child(AstralTheme.chip("%d G / bim" % int(d["cost"]), AstralTheme.GOLD_PALE if int(d["cost"]) > 0 else AstralTheme.GOOD, AstralTheme.GOLD, 12))
		mid.add_child(AstralTheme.label(str(d["desc"]), "CaptionLabel", AstralTheme.IVORY, true))
		var btn := AstralTheme.button((AstralTheme.G_CHECK + " En uso") if selected else "Elegir", "TabLikeButton")
		btn.custom_minimum_size = Vector2(132, 44)
		btn.disabled = selected
		var did: int = int(d["id"])
		btn.pressed.connect(func() -> void:
			GameState.current_diet = did as GameState.DietPlan
			GameState.stats_updated.emit()
			AstralAudio.play_confirm()
			speak.emit("Mesa familiar", "Nuevo régimen: %s." % CatalogDB.get_diet(did)["name"])
			refresh())
		h.add_child(btn)
		_diet_box.add_child(card)

# ------------------------------------------------------------------------------
# MANSIÓN
# ------------------------------------------------------------------------------
func _refresh_estate() -> void:
	clear(_estate_box)
	_estate_box.add_child(AstralTheme.chip("Costo progresivo (máx. nv.%d  |  nv.5+ gran obra)  ·  Oro disponible: %d G" % [MAX_LEVEL, GameState.gold], AstralTheme.GOLD_PALE, AstralTheme.GOLD, 13))
	for f in FACILITIES:
		var lvl: int = int(GameState.estate_levels.get(f["id"], 1))
		var card := AstralTheme.panel("CardPanel")
		card.tooltip_text = str(f["desc"])
		var h := AstralTheme.hbox(14)
		card.add_child(h)
		var fvign := AstralTheme.vignette_card(_facility_icon(str(f["id"])), Vector2(96, 56), AstralTheme.GOLD_DARK)
		fvign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(fvign)
		var mid := AstralTheme.vbox(4)
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(mid)
		var title_row := AstralTheme.hbox(8)
		mid.add_child(title_row)
		title_row.add_child(AstralTheme.label(str(f["name"]), "SubLabel"))
		title_row.add_child(AstralTheme.chip("Nv. %d / %d" % [lvl, MAX_LEVEL], AstralTheme.TURQ, null, 12))
		mid.add_child(AstralTheme.label(str(f["desc"]), "CaptionLabel", AstralTheme.IVORY, true))
		var pips := AstralTheme.hbox(5)
		for i in range(MAX_LEVEL):
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(24, 8)
			pip.color = AstralTheme.GOLD if i < lvl else Color(1, 1, 1, 0.12)
			pips.add_child(pip)
		mid.add_child(pips)
		var cost: int = get_upgrade_cost(lvl)
		var btn := AstralTheme.button("Mejorar\n%d G" % cost if lvl < MAX_LEVEL else "Máximo", "TabLikeButton")
		btn.custom_minimum_size = Vector2(142, 58)
		btn.disabled = lvl >= MAX_LEVEL or GameState.gold < cost
		if lvl < MAX_LEVEL and GameState.gold < cost:
			btn.tooltip_text = "Necesitas %d G." % cost
		var fid: String = f["id"]
		btn.pressed.connect(func() -> void: _upgrade(fid))
		h.add_child(btn)
		_estate_box.add_child(card)

func _upgrade(fid: String) -> void:
	var lvl: int = int(GameState.estate_levels.get(fid, 1))
	var cost: int = get_upgrade_cost(lvl)
	if lvl >= MAX_LEVEL or not GameState.modify_gold(-cost):
		AstralAudio.play_warn()
		toast.emit("No alcanza el oro para la mejora.", "warn")
		return
	GameState.estate_levels[fid] = lvl + 1
	GameState.recalculate_derived_stats()
	var fname: String = ""
	for f in FACILITIES:
		if f["id"] == fid:
			fname = f["name"]
	Chronicle.record_event("estate_" + fid, "Mejora de la mansión: " + fname, "%s subió al nivel %d." % [fname, lvl + 1], "family", 2)
	GameState.stats_updated.emit()
	AstralAudio.play_triumph()
	speak.emit("Mansión Solar", "%s ahora es de nivel %d." % [fname, lvl + 1])
	toast.emit("%s → nivel %d" % [fname, lvl + 1], "good")
	refresh()

func _heal_exhaustion(by_gold: bool) -> void:
	if by_gold:
		if not GameState.modify_gold(-80):
			return
		GameState.modify_stat("stress", -28)
	else:
		if GameState.father_energy < 20:
			return
		GameState.modify_stat("father_energy", -20)
		GameState.modify_stat("stress", -24)
	GameState.exhausted_sick = false
	GameState.sick_dialogue_pending = false
	GameState.modify_stat("affection", 6)
	GameState.modify_stat("human_anchor", 3)
	Chronicle.record_event("heal_exhaustion_%d" % TimeManager.current_total_turn, "Cuidados en el hogar", "El reposo junto al fuego devolvió el color al rostro de %s." % GameState.daughter_name, "family", 3)
	_last_result = "[b]%s[/b]:\n%s" % [
		GameState.daughter_name,
		AstralTheme.colored("«Gracias por quedarte conmigo hasta que bajó la fiebre, Padre. Ya vuelvo a sentir fuerzas.»", AstralTheme.GOLD_PALE)
	]
	AstralAudio.play_confirm()
	speak.emit(GameState.daughter_name, "Ya me siento recuperada, Padre. Prometo cuidar mi ritmo.")
	toast.emit("¡%s se recuperó del Agotamiento!" % GameState.daughter_name, "good")
	refresh()

func _take_vacation(vac: Dictionary) -> void:
	var cost_g: int = int(vac.get("cost", 130))
	var cost_e: int = int(vac.get("energy", 35))
	if GameState.vacation_used_years.has(TimeManager.current_year) or GameState.gold < cost_g or GameState.father_energy < cost_e:
		AstralAudio.play_warn()
		return
	GameState.modify_gold(-cost_g)
	GameState.modify_stat("father_energy", -cost_e)
	GameState.vacation_used_years.append(TimeManager.current_year)
	GameState.active_vacation_bg = str(vac.get("bg", ""))
	GameState.begin_batch()
	for k in ["stress", "human_anchor", "affection", "mood_calm", "mood_pride"]:
		if vac.has(k):
			GameState.modify_stat(k, int(vac[k]))
	if vac.has("stat_key") and vac.has("stat_val"):
		GameState.modify_stat(str(vac["stat_key"]), int(vac["stat_val"]))
	if vac.has("seal_delta"):
		GameState.modify_stat("seal_integrity", int(vac["seal_delta"]))
	GameState.end_batch()
	if GameState.exhausted_sick:
		GameState.exhausted_sick = false
	Chronicle.record_event("vacation_%d" % TimeManager.current_year, "Retiro: %s" % str(vac["name"]), str(vac["desc"]), "family", 4)
	_last_result = "[b]Retiro Estacional — %s[/b]:\n%s" % [
		str(vac["name"]),
		AstralTheme.colored("Compartieron días lejos de las obligaciones de Aethelgard. El paisaje renovó el espíritu de ambos.", AstralTheme.TURQ)
	]
	AstralAudio.play_triumph()
	vacation_taken.emit(str(vac["id"]))
	speak.emit(GameState.daughter_name, "¡Qué vistas tan hermosas en %s! No olvidaré este viaje, Padre." % str(vac["name"]))
	toast.emit("Retiro completado: %s" % str(vac["name"]), "good")
	refresh()

func reset_view() -> void:
	_selected_topic = ""
	_last_result = ""
