extends BaseWindow
class_name TownMap

## Ciudad de Aethelgard: Mapa ilustrado de 6 distritos, Boutique de Atuendos, Paseos y Senado.

signal bond_event_requested(npc_id: String)
signal outfit_changed()

class _CityMapCanvas extends Control:
	signal district_clicked(npc_id: String)

	var map_tex: Texture2D
	var pins: Array = []          # [{"npc": String, "title": String, "pos": Vector2, "selected": bool, "event": bool, "avail": bool}]

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				var best_npc: String = ""
				var best_d: float = 42.0
				for p in pins:
					var pt := Vector2(size.x * float(p["px"]), size.y * float(p["py"]))
					var d: float = pt.distance_to(mb.position)
					if d <= best_d:
						best_d = d
						best_npc = str(p["npc"])
				if best_npc != "":
					district_clicked.emit(best_npc)

	func _draw() -> void:
		if map_tex != null:
			draw_texture_rect(map_tex, Rect2(Vector2.ZERO, size), false, Color(0.92, 0.94, 0.98, 0.94))
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.08, 0.16), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.82, 0.68, 0.35, 0.55), false, 2.0)
		var fnt: Font = ThemeDB.fallback_font
		for p in pins:
			var pt := Vector2(size.x * float(p["px"]), size.y * float(p["py"]))
			var sel: bool = bool(p["selected"])
			var has_ev: bool = bool(p["event"])
			var avail: bool = bool(p["avail"])
			var col: Color = Color(0.98, 0.84, 0.38) if sel else (Color(0.38, 0.92, 0.84) if avail else Color(0.55, 0.58, 0.68))
			draw_circle(pt, 22.0 if sel else 17.0, Color(0.04, 0.06, 0.14, 0.78))
			draw_arc(pt, 22.0 if sel else 17.0, 0.0, TAU, 24, col, 3.0 if sel else 2.0, true)
			if has_ev:
				draw_circle(pt + Vector2(14, -14), 6.5, Color(0.96, 0.42, 0.56))
			if fnt != null:
				draw_string(fnt, pt + Vector2(-62, 34), str(p["title"]), HORIZONTAL_ALIGNMENT_CENTER, 124, 13, Color(0.98, 0.96, 0.90))

const DISTRICTS: Array[Dictionary] = [
	{"npc": "mirari", "name": "Torre de Cristal", "px": 0.21, "py": 0.25, "stat": "erudicion", "stroll": "Recorren los salones prismáticos observando lentes antiguos."},
	{"npc": "cassian", "name": "Palacio de Alabastro", "px": 0.49, "py": 0.20, "stat": "gracia", "stroll": "Pasean por las galerías blancas conversando entre estatuas reales."},
	{"npc": "vespera", "name": "Patio Ducal", "px": 0.84, "py": 0.25, "stat": "temple", "stroll": "Cruzan el patio de armas probando empuñaduras bajo el sol tardío."},
	{"npc": "kaelen", "name": "Acueductos", "px": 0.24, "py": 0.68, "stat": "destreza", "stroll": "Caminan junto al agua celeste escuchando los molinos y fraguas."},
	{"npc": "zephyr", "name": "Espejo Astral", "px": 0.52, "py": 0.72, "stat": "resonancia", "stroll": "Contemplan las constelaciones reflejadas en el estanque sagrado."},
	{"npc": "soren", "name": "Anfiteatro", "px": 0.86, "py": 0.76, "stat": "magnetismo", "stroll": "Prueban el eco del escenario vacío entre risas y melodías."}
]

var _tabs: TabContainer
var _npc_box: VBoxContainer
var _boutique_box: VBoxContainer
var _rival_box: VBoxContainer
var _selected_npc: String = "vespera"
var _map_canvas: _CityMapCanvas

func _ready() -> void:
	setup("Ciudad de Aethelgard", false)

func build() -> void:
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_tabs)
	_npc_box = add_tab(_tabs, "  Mapa de Distritos  ")
	_boutique_box = add_tab(_tabs, "  Boutique de Atuendos  ")
	_rival_box = add_tab(_tabs, "  Rivales y Senado  ")

func refresh() -> void:
	if _tabs == null:
		return
	_refresh_npcs()
	_refresh_boutique()
	_refresh_rivals()

# ------------------------------------------------------------------------------
func _refresh_npcs() -> void:
	clear(_npc_box)
	var status := AstralTheme.panel("GlowPanel")
	var sv := AstralTheme.vbox(4)
	status.add_child(sv)
	if RelationshipManager.interacted_this_bimester:
		sv.add_child(AstralTheme.label("%s ya realizó su salida social este bimestre." % GameState.daughter_name, "SubLabel", AstralTheme.EMBER, true))
	else:
		sv.add_child(AstralTheme.label("Selecciona un distrito en el mapa para visitar al candidato o dar un Paseo Padre-Hija.", "SubLabel", null, true))
	var note: String = RelationshipManager.get_romance_locked_note()
	if note != "":
		sv.add_child(AstralTheme.label(note, "CaptionLabel", AstralTheme.MUTED, true))
	_npc_box.add_child(status)

	# Mapa visual ilustrado + barra rápida de distritos
	_map_canvas = _CityMapCanvas.new()
	_map_canvas.map_tex = AstralTheme.load_tex("res://assets/art/bg_town_map.png")
	_map_canvas.custom_minimum_size = Vector2(0, 260)
	_map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pins_meta: Array = []
	for d in DISTRICTS:
		var nid: String = str(d["npc"])
		var ev: bool = bool(RelationshipManager.get_next_bond_event(nid).get("ok", false))
		pins_meta.append({
			"npc": nid,
			"title": str(d["name"]),
			"px": float(d["px"]),
			"py": float(d["py"]),
			"selected": (_selected_npc == nid),
			"event": ev,
			"avail": RelationshipManager.is_available(nid)
		})
	_map_canvas.pins = pins_meta
	_map_canvas.district_clicked.connect(func(nid: String) -> void:
		_selected_npc = nid
		AstralAudio.play_ui()
		_refresh_npcs())
	_npc_box.add_child(_map_canvas)

	var drow := HFlowContainer.new()
	drow.add_theme_constant_override("h_separation", 6)
	drow.add_theme_constant_override("v_separation", 6)
	for d in DISTRICTS:
		var nid: String = str(d["npc"])
		var has_ev: bool = bool(RelationshipManager.get_next_bond_event(nid).get("ok", false))
		var lbl: String = "%s%s" % [str(d["name"]), " ✦" if has_ev else ""]
		var db := AstralTheme.button(lbl, "PrimaryButton" if _selected_npc == nid else "TabLikeButton")
		db.pressed.connect(func() -> void:
			_selected_npc = nid
			AstralAudio.play_ui()
			_refresh_npcs())
		drow.add_child(db)
	_npc_box.add_child(drow)

	# Paseo Padre-Hija por el distrito seleccionado
	var sel_dist: Dictionary = DISTRICTS[0]
	for d in DISTRICTS:
		if str(d["npc"]) == _selected_npc:
			sel_dist = d
			break
	var strolled: bool = RelationshipManager.strolled_this_bimester
	var sbar := AstralTheme.panel("CardPanel")
	var sh := AstralTheme.hbox(10)
	sbar.add_child(sh)
	var slbl := AstralTheme.label("Paseo Padre-Hija por %s: -5 Estrés, +5 Afecto, +3 Anclaje y +5 %s" % [
		str(sel_dist["name"]), GameState.get_stat_label(str(sel_dist["stat"]))
	], "CaptionLabel", AstralTheme.TURQ, true)
	slbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(slbl)
	var sbtn := AstralTheme.button("Paseo hecho ✓" if strolled else "Pasear (-20 Energía)", "PrimaryButton" if not strolled else "")
	sbtn.disabled = strolled or GameState.father_energy < 20
	sbtn.custom_minimum_size = Vector2(180, 40)
	sbtn.pressed.connect(func() -> void: _do_stroll(sel_dist))
	sh.add_child(sbtn)
	_npc_box.add_child(sbar)

	_npc_box.add_child(_npc_card(_selected_npc))

func _npc_card(npc_id: String) -> Control:
	var data: Dictionary = RelationshipManager.get_data(npc_id)
	var st: Dictionary = RelationshipManager.get_state(npc_id)
	var card := AstralTheme.panel("CardPanel")
	var h := AstralTheme.hbox(16)
	card.add_child(h)

	var icon := TextureRect.new()
	icon.texture = load("res://assets/ui/npc_%s.png" % npc_id)
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(icon)

	var mid := AstralTheme.vbox(6)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(mid)
	var avail: bool = RelationshipManager.is_available(npc_id)
	mid.add_child(AstralTheme.label(str(data["name"]) if avail else "??? — Presencia en el Espejo", "HeadingLabel"))
	mid.add_child(AstralTheme.label("%s  ·  %s" % [data["title"], data["location"]] if avail else "Misterio Celestial  ·  Sin manifestarse", "CaptionLabel", AstralTheme.MUTED, true))

	if not avail:
		icon.modulate = Color(0.25, 0.25, 0.35, 0.8)
		mid.add_child(AstralTheme.label(AstralTheme.G_MOON + "  " + RelationshipManager.get_locked_reason(npc_id), "", AstralTheme.EMBER, true))
		return card

	mid.add_child(AstralTheme.label(RelationshipManager.get_relationship_status_title(npc_id), "SubLabel", AstralTheme.GOLD_PALE, true))
	var ba := StatBar.new()
	ba.setup("Afecto", "affection", -100, 100, AstralTheme.ROSE, "Cariño o rencor. Con ±45 se abre la escena del Acto II y con ±80 la del Acto III.", 110)
	mid.add_child(ba)
	ba.set_value(int(st["affection"]), false)
	var br := StatBar.new()
	br.setup("Respeto", "respect", -100, 100, AstralTheme.SKY, "Admiración por su carácter y su fuerza.", 110)
	mid.add_child(br)
	br.set_value(int(st["respect"]), false)
	if RelationshipManager.romance_available(npc_id):
		var bs := StatBar.new()
		bs.setup("Chispa", "spark", 0, 100, AstralTheme.AMETHYST, "Chispa romántica (solo adultos).", 110)
		mid.add_child(bs)
		bs.set_value(int(st["spark"]), false)
	mid.add_child(AstralTheme.label("Etapa %d de 3 · Escenas vividas: %d de 3" % [int(st["stage"]), (st["events_seen"] as Array).size()], "CaptionLabel", AstralTheme.MUTED))
	mid.add_child(AstralTheme.label(str(data["perk_desc"]), "CaptionLabel", AstralTheme.TURQ, true))

	var acts := AstralTheme.vbox(6)
	acts.custom_minimum_size.x = 210
	h.add_child(acts)
	var used: bool = RelationshipManager.interacted_this_bimester
	acts.add_child(_action_btn("%s  Apoyar" % AstralTheme.G_STAR, npc_id, "support", used, "+16 Afecto, +14 Respeto, +5 Anclaje Humano."))
	acts.add_child(_action_btn("%s  Regalar (-%d G)" % [AstralTheme.G_FLOWER, RelationshipManager.SOCIAL_COST_GIFT], npc_id, "gift", used or GameState.gold < RelationshipManager.SOCIAL_COST_GIFT, "+22 Afecto, +10 Respeto."))
	acts.add_child(_action_btn("%s  Provocar" % AstralTheme.G_SWORD, npc_id, "provoke", used, "-30 Afecto y +6 Entropía. Si %s es fuerte, el rival la respeta más." % GameState.daughter_name))
	if RelationshipManager.romance_available(npc_id):
		acts.add_child(_action_btn("%s  Cita romántica" % AstralTheme.G_HEART, npc_id, "romance", used, "+20 Chispa, +12 Afecto, -10 Estrés."))
	var ev: Dictionary = RelationshipManager.get_next_bond_event(npc_id)
	var scene_btn := AstralTheme.button("%s  Escena de historia" % AstralTheme.G_QUILL, "PrimaryButton")
	scene_btn.disabled = not ev.get("ok", false)
	scene_btn.tooltip_text = "Una escena especial con decisiones." if ev.get("ok", false) else str(ev.get("reason", ""))
	scene_btn.custom_minimum_size.y = 46
	scene_btn.pressed.connect(func() -> void: bond_event_requested.emit(npc_id))
	acts.add_child(scene_btn)
	if not ev.get("ok", false) and str(ev.get("reason", "")) != "":
		acts.add_child(AstralTheme.label(str(ev["reason"]), "CaptionLabel", AstralTheme.MUTED, true))
	return card

func _action_btn(text: String, npc_id: String, action: String, disabled: bool, tip: String) -> Button:
	var b := AstralTheme.button(text, "TabLikeButton", tip)
	b.disabled = disabled
	b.custom_minimum_size.y = 42
	b.pressed.connect(func() -> void: _do_action(npc_id, action))
	return b

func _do_action(npc_id: String, action: String) -> void:
	var res: Dictionary = RelationshipManager.interact_with_candidate(npc_id, action)
	if not res.get("ok", false):
		AstralAudio.play_warn()
		toast.emit(str(res.get("msg", "")), "warn")
		return
	if action == "provoke":
		AstralAudio.play_warn()
	else:
		AstralAudio.play_confirm()
	speak.emit(str(res["speaker"]), "%s\n[color=%s]%s[/color]" % [res["reply"], AstralTheme.hex(AstralTheme.GOLD_PALE), res["effects"]])
	refresh()

# ------------------------------------------------------------------------------
func _do_stroll(d: Dictionary) -> void:
	if RelationshipManager.strolled_this_bimester:
		return
	if GameState.father_energy < 20:
		AstralAudio.play_warn()
		toast.emit("No queda suficiente Energía Paterna (requiere 20).", "warn")
		return
	GameState.modify_stat("father_energy", -20)
	RelationshipManager.strolled_this_bimester = true
	GameState.modify_stat("stress", -5)
	GameState.modify_stat("affection", 5)
	GameState.modify_stat("human_anchor", 3)
	var sk: String = str(d.get("stat", "erudicion"))
	GameState.modify_stat(sk, 5)
	AstralAudio.play_confirm()
	speak.emit("Paseo por %s" % str(d["name"]), "%s (-5 Estrés, +5 Afecto, +3 Anclaje, +5 %s)" % [str(d["stroll"]), GameState.get_stat_label(sk)])
	toast.emit("Paseo padre-hija por %s completado" % str(d["name"]), "good")
	refresh()

func _refresh_boutique() -> void:
	if _boutique_box == null:
		return
	clear(_boutique_box)
	_boutique_box.add_child(AstralTheme.label(
		"Boutique Imperial de Aethelgard — Oro disponible: %d G. Cada atuendo altera el retrato y aporta bonos pasivos reales." % GameState.gold,
		"CaptionLabel", AstralTheme.GOLD_PALE, true
	))
	for o in CatalogDB.OUTFITS:
		var oid: String = str(o["id"])
		var owned: bool = GameState.owned_outfits.has(oid)
		var equipped: bool = (GameState.equipped_outfit == oid)
		var card := AstralTheme.panel("GlowPanel" if equipped else "CardPanel")
		var row := AstralTheme.hbox(14)
		card.add_child(row)
		var icon := TextureRect.new()
		var ptex: Texture2D = AstralTheme.load_tex(str(o["portrait"]), "res://assets/art/renpet_portrait.png")
		if ptex != null:
			icon.texture = ptex
		icon.custom_minimum_size = Vector2(68, 88)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var info := AstralTheme.vbox(4)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(AstralTheme.label("%s%s" % [str(o["name"]), "  [Equipado]" if equipped else ""], "HeadingLabel", AstralTheme.GOLD if equipped else AstralTheme.GOLD_PALE))
		info.add_child(AstralTheme.label(str(o.get("bonus_desc", "")), "CaptionLabel", AstralTheme.IVORY, true))
		var cost: int = int(o.get("price", 0))
		var btn_txt: String = "Equipado ✓" if equipped else ("Equipar" if owned else "Comprar (%d G)" % cost)
		var btn := AstralTheme.button(btn_txt, "" if equipped else ("PrimaryButton" if (owned or GameState.gold >= cost) else ""))
		btn.custom_minimum_size = Vector2(160, 48)
		btn.disabled = equipped or ((not owned) and GameState.gold < cost)
		btn.pressed.connect(func() -> void:
			if not owned:
				var buy_res: Dictionary = GameState.buy_outfit(oid)
				if bool(buy_res.get("ok", false)):
					AstralAudio.play_confirm()
					toast.emit("Atuendo adquirido y equipado: %s" % str(o["name"]), "good")
					outfit_changed.emit()
				else:
					AstralAudio.play_warn()
					toast.emit(str(buy_res.get("msg", "Oro insuficiente.")), "warn")
			else:
				GameState.equip_outfit(oid)
				AstralAudio.play_ui()
				toast.emit("Atuendo equipado: %s" % str(o["name"]), "info")
				outfit_changed.emit()
			refresh())
		row.add_child(btn)
		_boutique_box.add_child(card)

func _refresh_rivals() -> void:
	clear(_rival_box)
	# Panel del Senado e Inquisición Solar
	var sen := AstralTheme.panel("GlowPanel" if GameState.court_suspicion >= 60 else "CardPanel")
	var sh := AstralTheme.hbox(12)
	sen.add_child(sh)
	var sv := AstralTheme.vbox(4)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(sv)
	sv.add_child(AstralTheme.label("⚖ Vigilancia del Senado / Inquisición Solar: %d / 100" % GameState.court_suspicion, "SubLabel", AstralTheme.BAD if GameState.court_suspicion >= 60 else AstralTheme.GOLD_PALE))
	sv.add_child(AstralTheme.label("Sube con trabajos ilegales (Canales), múltiples asimilaciones en el Crisol o Sello bajo (<60%). Al llegar a 80 dispara Audiencia Inquisitorial.", "CaptionLabel", AstralTheme.MUTED, true))
	var relief_btn := AstralTheme.button("Presentar Descargos\n(-15 E, -40 G → -25 Sosp.)", "TabLikeButton")
	relief_btn.custom_minimum_size = Vector2(215, 54)
	relief_btn.disabled = (GameState.court_suspicion <= 0) or (GameState.father_energy < 15) or (GameState.gold < 40)
	relief_btn.pressed.connect(func() -> void:
		GameState.modify_stat("father_energy", -15)
		GameState.modify_gold(-40)
		GameState.modify_stat("court_suspicion", -25)
		AstralAudio.play_confirm()
		toast.emit("Descargos diplomáticos aceptados (-25 Sospecha)", "good")
		refresh())
	sh.add_child(relief_btn)
	_rival_box.add_child(sen)

	var info := AstralTheme.panel("GlowPanel")
	info.add_child(AstralTheme.label("Los rivales entrenan en espejo: crecen cada bimestre y entrenan más si te ven en su especialidad. En las aulas compartidas se libran choques de aula; además puedes desafiar a un duelo de prestigio (uno por bimestre).", "", AstralTheme.IVORY, true))
	_rival_box.add_child(info)
	for rid in RivalMirror.RIVAL_ORDER:
		var d: Dictionary = RivalMirror.get_data(rid)
		var s: Dictionary = RivalMirror.get_standing(rid)
		var card := AstralTheme.panel("CardPanel")
		var h := AstralTheme.hbox(16)
		card.add_child(h)
		var mid := AstralTheme.vbox(6)
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(mid)
		mid.add_child(AstralTheme.label(str(d["full_name"]), "HeadingLabel"))
		mid.add_child(AstralTheme.label("Especialidad: %s" % d["domain"], "CaptionLabel", AstralTheme.MUTED))
		var b1 := StatBar.new()
		b1.setup(GameState.daughter_name, "me", 0, 2400, AstralTheme.GOLD, "", 120)
		mid.add_child(b1)
		b1.set_value(int(s["mine"]), false)
		var b2 := StatBar.new()
		b2.setup(str(d["name"]).split(" ")[0] if rid != "caelum" else "Caelum", "rival", 0, 2400, AstralTheme.ROSE, "", 120)
		mid.add_child(b2)
		b2.set_value(int(s["theirs"]), false)
		var diff: int = int(s["diff"])
		mid.add_child(AstralTheme.label("%s  (%s)" % [s["label"], AstralTheme.signed(diff)], "SubLabel", AstralTheme.GOOD if diff >= 0 else AstralTheme.EMBER, true))
		var btn := AstralTheme.button("%s  Desafiar a duelo" % AstralTheme.G_SWORD, "TabLikeButton",
			"Si tu puntaje iguala o supera al suyo: +150 Oro y +14 al atributo principal. Si no, aprendes (+10) pero te estresas.")
		btn.custom_minimum_size = Vector2(210, 52)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.disabled = RivalMirror.challenged_this_bimester
		var r_id: String = rid
		btn.pressed.connect(func() -> void: _duel(r_id))
		h.add_child(btn)
		_rival_box.add_child(card)

func _duel(rid: String) -> void:
	var res: Dictionary = RivalMirror.challenge_rival_duel(rid)
	if not res.get("ok", false):
		AstralAudio.play_warn()
		toast.emit(str(res.get("msg", "")), "warn")
		return
	if res["won"]:
		AstralAudio.play_triumph()
	else:
		AstralAudio.play_warn()
	speak.emit(str(res["speaker"]), "%s\n[color=%s]%s[/color]" % [res["reply"], AstralTheme.hex(AstralTheme.GOLD_PALE), res["effects"]])
	toast.emit("¡Victoria de prestigio!" if res["won"] else "Derrota honorable: a entrenar", "good" if res["won"] else "warn")
	refresh()
