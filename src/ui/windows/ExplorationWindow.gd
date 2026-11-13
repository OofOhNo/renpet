extends BaseWindow
class_name ExplorationWindow

## Ventana VI: Exploración Astral (5 Regiones) y Gran Festival de las Constelaciones de Otoño (Fases 7 y 8).

signal expedition_started()
signal festival_completed(res: Dictionary)

var _tabs: TabContainer
var _comp_opt: OptionButton
var _comp_info: Label
var _zones_box: VBoxContainer
var _shards_lbl: Label

var _fest_banner: PanelContainer
var _fest_banner_lbl: Label
var _fest_result_card: PanelContainer
var _fest_result_lbl: RichTextLabel
var _fest_box: VBoxContainer

func build() -> void:
	setup("%s  EXPEDICIÓN ASTRAL Y FESTIVAL DE OTOÑO" % AstralTheme.G_SWORD, false)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_tabs)

	# --- PESTAÑA 1: EXPLORACIÓN DE LAS 5 REGIONES ---
	var exp_v: VBoxContainer = BaseWindow.add_tab(_tabs, "  Exploración (5 Regiones)  ")

	var intro := AstralTheme.label(
		"Explora ruinas y anomalías fuera de la capital junto a un aliado. Cada región custodia vestigios antiguos de tu origen.",
		"CaptionLabel", AstralTheme.MUTED
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exp_v.add_child(intro)

	var comp_card := PanelContainer.new()
	comp_card.theme_type_variation = "CardPanel"
	exp_v.add_child(comp_card)

	var cv := AstralTheme.vbox(8)
	comp_card.add_child(cv)

	var ch := AstralTheme.hbox(12)
	cv.add_child(ch)
	ch.add_child(AstralTheme.label("%s  Compañero de Expedición:" % AstralTheme.G_ANKH, "SubLabel"))

	_comp_opt = OptionButton.new()
	_comp_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for npc_id in RelationshipManager.NPC_ORDER:
		_comp_opt.add_item("...")
		_comp_opt.set_item_metadata(_comp_opt.item_count - 1, npc_id)
	_comp_opt.selected = 1   # Vespera por defecto
	_refresh_companion_options()
	_comp_opt.item_selected.connect(_on_companion_changed)
	ch.add_child(_comp_opt)

	_comp_info = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ)
	_comp_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cv.add_child(_comp_info)

	_shards_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD_PALE)
	exp_v.add_child(_shards_lbl)
	exp_v.add_child(AstralTheme.separator())

	_zones_box = AstralTheme.vbox(10)
	exp_v.add_child(_zones_box)

	# --- PESTAÑA 2: GRAN FESTIVAL DE LAS CONSTELACIONES DE OTOÑO ---
	var fest_v: VBoxContainer = BaseWindow.add_tab(_tabs, "  Festival de Otoño  ")

	_fest_banner = PanelContainer.new()
	_fest_banner.theme_type_variation = "CardPanel"
	fest_v.add_child(_fest_banner)
	_fest_banner_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD_PALE)
	_fest_banner_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fest_banner.add_child(_fest_banner_lbl)

	_fest_result_card = PanelContainer.new()
	_fest_result_card.theme_type_variation = "CardPanel"
	_fest_result_card.visible = false
	fest_v.add_child(_fest_result_card)
	_fest_result_lbl = AstralTheme.rich()
	_fest_result_card.add_child(_fest_result_lbl)

	_fest_box = AstralTheme.vbox(10)
	fest_v.add_child(_fest_box)

func open_festival_tab() -> void:
	if _tabs != null and _tabs.get_tab_count() > 1:
		_tabs.current_tab = 1

func refresh() -> void:
	_refresh_companion_options()
	_update_companion_info()
	_refresh_exploration_tab()
	_refresh_festival_tab()

class _StarRouteCanvas extends Control:
	var zones_meta: Array = []    # [{"name": String, "unlocked": bool, "shard": bool, "age": int}]

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.14, 0.90), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.75, 0.62, 0.30, 0.40), false, 1.5)
		var count: int = zones_meta.size()
		if count <= 0:
			return
		var pts: Array[Vector2] = []
		for i in range(count):
			var fx: float = 0.10 + (0.80 * float(i) / maxf(1.0, float(count - 1)))
			var fy: float = 0.50 + (-0.18 if i % 2 == 0 else 0.18)
			pts.append(Vector2(size.x * fx, size.y * fy))
		for i in range(count - 1):
			var unlocked_next: bool = bool(zones_meta[i + 1].get("unlocked", false))
			var col: Color = Color(0.35, 0.85, 0.78, 0.65) if unlocked_next else Color(0.35, 0.40, 0.55, 0.30)
			draw_line(pts[i], pts[i + 1], col, 3.0 if unlocked_next else 1.5, true)
		var fnt: Font = ThemeDB.fallback_font
		for i in range(count):
			var zm: Dictionary = zones_meta[i]
			var unl: bool = bool(zm.get("unlocked", false))
			var sh: bool = bool(zm.get("shard", false))
			var col: Color = Color(0.95, 0.82, 0.38) if sh else (Color(0.35, 0.88, 0.82) if unl else Color(0.45, 0.48, 0.58))
			draw_circle(pts[i], 14.0, Color(col.r, col.g, col.b, 0.22))
			draw_circle(pts[i], 7.0, col)
			draw_arc(pts[i], 10.0, 0.0, TAU, 20, col, 1.5, true)
			if fnt != null:
				draw_string(fnt, pts[i] + Vector2(-40, 26), "%d+ %s" % [int(zm.get("age", 12)), "✦" if sh else "·"], HORIZONTAL_ALIGNMENT_CENTER, 80, 12, col)

var _cards_v: VBoxContainer
var _cards_head_lbl: Label
var _cards_list_box: VBoxContainer
var _fest_bg_rect: TextureRect
var _fest_risk_chk: CheckBox
var _route_canvas: _StarRouteCanvas

func _ensure_extra_ui() -> void:
	if _tabs != null and _tabs.get_tab_count() < 3:
		_cards_v = BaseWindow.add_tab(_tabs, "  Mazo de Recuerdos  ")
		_cards_head_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD_PALE, true)
		_cards_v.add_child(_cards_head_lbl)
		var sc := ScrollContainer.new()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_cards_v.add_child(sc)
		_cards_list_box = AstralTheme.vbox(8)
		_cards_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(_cards_list_box)

	if _fest_banner != null and _fest_bg_rect == null:
		var bg_tex: Texture2D = AstralTheme.load_tex("res://assets/art/bg_coliseum_festival.png")
		if bg_tex != null:
			_fest_bg_rect = TextureRect.new()
			_fest_bg_rect.texture = bg_tex
			_fest_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_fest_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			_fest_bg_rect.custom_minimum_size = Vector2(0, 86)
			_fest_bg_rect.modulate = Color(1, 1, 1, 0.72)
			var parent_v := _fest_banner.get_parent()
			if parent_v != null:
				parent_v.add_child(_fest_bg_rect)
				parent_v.move_child(_fest_bg_rect, 0)

func _refresh_companion_options() -> void:
	if _comp_opt == null:
		return
	var prev_id: String = str(_comp_opt.get_item_metadata(_comp_opt.selected)) if (_comp_opt.item_count > 0 and _comp_opt.selected >= 0) else "vespera"
	_comp_opt.clear()
	var sel_idx: int = 0
	for npc_id in RelationshipManager.NPC_ORDER:
		if not RelationshipManager.is_available(npc_id):
			continue
		if not RelationshipManager.is_known(npc_id):
			continue
		var data: Dictionary = RelationshipManager.get_data(npc_id)
		_comp_opt.add_item("%s — %s" % [data["name"], data["title"]])
		var idx: int = _comp_opt.item_count - 1
		_comp_opt.set_item_metadata(idx, npc_id)
		if npc_id == prev_id:
			sel_idx = idx
	if _comp_opt.item_count == 0:
		_comp_opt.add_item("%s — Escolta Solitaria" % GameState.daughter_name)
		_comp_opt.set_item_metadata(0, "solo")
	_comp_opt.selected = sel_idx

func _refresh_exploration_tab() -> void:
	_ensure_extra_ui()
	_refresh_cards_tab()
	var unlocked_zones: Array = []
	for i in range(ExplorationCombat.ZONES.size()):
		var z: Dictionary = ExplorationCombat.ZONES[i]
		if GameState.age >= int(z["min_age"]):
			unlocked_zones.append({"idx": i, "zone": z})

	var inv_lbl: String = GameState.get_stat_label("seal_investigation")
	var rel_lbl: String = "Esquirlas" if GameState.get_secret_tier() >= 2 else "Vestigios"
	_shards_lbl.text = "%s  Rutas de 4 Nodos  |  %s: %d / %d  |  %s: %d%%" % [
		AstralTheme.G_STAR, rel_lbl, ExplorationCombat.memory_shards_found.size(), maxi(1, unlocked_zones.size()), inv_lbl, GameState.seal_investigation_progress
	]

	BaseWindow.clear(_zones_box)
	if _route_canvas == null or not is_instance_valid(_route_canvas):
		_route_canvas = _StarRouteCanvas.new()
		_route_canvas.custom_minimum_size = Vector2(0, 84)
		_route_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var meta: Array = []
	for item in unlocked_zones:
		var z: Dictionary = item["zone"]
		meta.append({
			"name": z["name"],
			"age": int(z["min_age"]),
			"unlocked": true,
			"shard": ExplorationCombat.memory_shards_found.has(z["shard_id"])
		})
	_route_canvas.zones_meta = meta
	_route_canvas.queue_redraw()
	_zones_box.add_child(_route_canvas)

	var sel_npc: String = str(_comp_opt.get_item_metadata(_comp_opt.selected)) if _comp_opt != null and _comp_opt.item_count > 0 else "solo"
	var comp_ok: bool = (sel_npc == "solo") or (RelationshipManager.is_available(sel_npc) and ExplorationCombat.can_recruit_companion(sel_npc))
	for item in unlocked_zones:
		var i: int = int(item["idx"])
		var z: Dictionary = item["zone"]
		var has_shard: bool = ExplorationCombat.memory_shards_found.has(z["shard_id"])

		var card := PanelContainer.new()
		card.theme_type_variation = "CardPanel"
		_zones_box.add_child(card)

		var row := AstralTheme.hbox(14)
		card.add_child(row)

		var icon := TextureRect.new()
		var b_tex: Texture2D = AstralTheme.load_tex(str(z.get("boss_icon", z["enemy_icon"])), str(z["enemy_icon"]))
		icon.texture = b_tex
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

		var info := AstralTheme.vbox(4)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var title_col: Color = AstralTheme.GOLD_PALE
		var relic_word: String = "Esquirla" if GameState.get_secret_tier() >= 2 else "Vestigio"
		var shard_badge: String = "  [%s %s hallado]" % [AstralTheme.G_CHECK, relic_word] if has_shard else "  [%s %s oculto]" % [AstralTheme.G_STAR2, relic_word]
		info.add_child(AstralTheme.label("%s%s" % [z["name"], shard_badge], "HeadingLabel", title_col))

		var desc := AstralTheme.label(str(z["desc"]), "CaptionLabel", AstralTheme.IVORY)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(desc)

		var mat_name: String = str(CatalogDB.get_material(str(z["loot_id"])).get("name", z["loot_id"]))
		info.add_child(AstralTheme.label(
			"4 Nodos  •  Recompensa: +%d Oro, +1 %s  •  Jefe: %s" % [int(z["gold_reward"]), mat_name, z["boss_name"]],
			"CaptionLabel", AstralTheme.TURQ
		))

		var btn_label: String = "Ya explorado" if ExplorationCombat.explored_this_bimester else ("Aliado no disp." if not comp_ok else "%s  Iniciar Ruta" % AstralTheme.G_SWORD)
		var btn := AstralTheme.button(
			btn_label,
			"" if (ExplorationCombat.explored_this_bimester or not comp_ok) else "PrimaryButton"
		)
		btn.custom_minimum_size = Vector2(165, 48)
		btn.disabled = ExplorationCombat.explored_this_bimester or not comp_ok
		if not comp_ok:
			btn.tooltip_text = "El compañero seleccionado tiene un vínculo hostil."
		var z_idx: int = i
		btn.pressed.connect(_on_explore_pressed.bind(z_idx))
		row.add_child(btn)

func _refresh_cards_tab() -> void:
	if _cards_list_box == null:
		return
	var eq_dicts: Array[Dictionary] = GameState.get_equipped_memory_cards()
	var eq_ids: Array[String] = []
	for ed in eq_dicts:
		eq_ids.append(str(ed.get("id", "")))
	var unl: Array[Dictionary] = GameState.get_unlocked_memory_cards()
	if _tabs != null and _tabs.get_tab_count() >= 3:
		_tabs.set_tab_title(2, "  Mazo de Recuerdos (%d/4)  " % eq_ids.size())
	_cards_head_lbl.text = "Cartas equipadas: %d / 4  (Desbloqueadas: %d / %d). Se activan en Combate o Festival." % [
		eq_ids.size(), unl.size(), CatalogDB.MEMORY_CARDS.size()
	]
	BaseWindow.clear(_cards_list_box)
	for c in CatalogDB.MEMORY_CARDS:
		var cid: String = str(c["id"])
		var unlocked: bool = GameState.is_memory_card_unlocked(c)
		var equipped: bool = eq_ids.has(cid)
		var pan := PanelContainer.new()
		pan.theme_type_variation = "GlowPanel" if equipped else "CardPanel"
		_cards_list_box.add_child(pan)
		var row := AstralTheme.hbox(12)
		pan.add_child(row)
		var v := AstralTheme.vbox(3)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(v)
		v.add_child(AstralTheme.label("%s  %s (%d PA)" % [AstralTheme.G_STAR if unlocked else "·", str(c["name"]), int(c.get("ap", 1))], "SubLabel", AstralTheme.GOLD if equipped else (AstralTheme.TURQ if unlocked else AstralTheme.MUTED)))
		v.add_child(AstralTheme.label("Combate: %s  |  Festival: +%d pts" % [str(c.get("desc", "")), int(c.get("fest_bonus", 0))], "CaptionLabel", AstralTheme.IVORY if unlocked else AstralTheme.MUTED, true))
		v.add_child(AstralTheme.label("Origen: %s" % str(c.get("source_label", "")), "CaptionLabel", AstralTheme.GOOD if unlocked else AstralTheme.MUTED, true))
		var btn := AstralTheme.button("Equipada ✓" if equipped else ("Equipar" if unlocked else "Bloqueada"), "PrimaryButton" if equipped else "")
		btn.custom_minimum_size = Vector2(138, 42)
		btn.disabled = (not unlocked) or ((not equipped) and eq_ids.size() >= 4)
		btn.pressed.connect(func() -> void:
			GameState.toggle_equipped_card(cid)
			AstralAudio.play_ui()
			_refresh_cards_tab())
		row.add_child(btn)

func _refresh_festival_tab() -> void:
	_ensure_extra_ui()
	var is_open: bool = TimeManager.is_festival_bimester()
	var entered: bool = ExplorationCombat.festival_entered_this_year
	var wins_count: int = ExplorationCombat.festival_wins.size()
	if not entered and _fest_result_card != null:
		_fest_result_card.visible = false

	if not ExplorationCombat.festival_match.is_empty() and not bool(ExplorationCombat.festival_match.get("finished", false)):
		_fest_banner_lbl.text = "%s  DUELO EN CURSO: %s — Asalto %d / 3" % [
			AstralTheme.G_STAR, str(ExplorationCombat.festival_match["name"]), int(ExplorationCombat.festival_match["round"])
		]
		_fest_banner_lbl.add_theme_color_override("font_color", AstralTheme.GOLD)
		_render_festival_round()
		return

	if not is_open:
		_fest_banner_lbl.text = "%s  El Gran Festival de las Constelaciones abre sus puertas cada 4º Bimestre (Cosecha / Equinoccio de Otoño).\nVictorias acumuladas en campaña: %d. Entrena los atributos clave antes de otoño." % [AstralTheme.G_SUN, wins_count]
		_fest_banner_lbl.add_theme_color_override("font_color", AstralTheme.MUTED)
	elif entered:
		_fest_banner_lbl.text = "%s  %s ya participó en el certamen de este Equinoccio de Otoño.\nVictorias acumuladas en campaña: %d. Regresa el próximo año." % [AstralTheme.G_CHECK, GameState.daughter_name, wins_count]
		_fest_banner_lbl.add_theme_color_override("font_color", AstralTheme.TURQ)
	else:
		_fest_banner_lbl.text = "%s  ¡EL FESTIVAL DE OTOÑO ESTÁ ABIERTO! Elige 1 de los 4 certámenes reales (3 Asaltos interactivos).\nVictorias acumuladas en campaña: %d." % [AstralTheme.G_STAR, wins_count]
		_fest_banner_lbl.add_theme_color_override("font_color", AstralTheme.GOLD_PALE)

	BaseWindow.clear(_fest_box)
	for i in range(ExplorationCombat.FESTIVAL_CONTESTS.size()):
		var c: Dictionary = ExplorationCombat.FESTIVAL_CONTESTS[i]
		var prev: Dictionary = ExplorationCombat.get_festival_preview(i)
		var my_total: int = int(prev["my_total"])
		var target_score: int = int(prev["target_score"])
		var fav: bool = my_total >= target_score

		var card := PanelContainer.new()
		card.theme_type_variation = "CardPanel"
		_fest_box.add_child(card)

		var row := AstralTheme.hbox(14)
		card.add_child(row)

		var info := AstralTheme.vbox(4)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		info.add_child(AstralTheme.label(str(c["name"]), "HeadingLabel", AstralTheme.GOLD_PALE))
		var desc := AstralTheme.label(str(c["desc"]), "CaptionLabel", AstralTheme.IVORY)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(desc)

		var stat_names: Array[String] = []
		for sk in c["stats"]:
			stat_names.append(GameState.get_stat_label(str(sk)))
		var mat_name: String = str(CatalogDB.get_material(str(c["reward_item"])).get("name", c["reward_item"]))

		var score_lbl := AstralTheme.label(
			"Pronóstico: %s %d pts   vs   Meta de %s: %d pts   [%s]" % [
				GameState.daughter_name, my_total, c["rival_name"], target_score,
				"FAVORABLE" if fav else "DESAFÍO DIFÍCIL"
			],
			"SubLabel", AstralTheme.GOOD if fav else AstralTheme.ROSE
		)
		info.add_child(score_lbl)

		info.add_child(AstralTheme.label(
			"Ejes: %s  •  Premio Campeona: +%d Oro, +24 Magnetismo, +10 Afecto, +6 Rep. y +1 %s" % [
				", ".join(stat_names), int(c["reward_gold"]), mat_name
			],
			"CaptionLabel", AstralTheme.TURQ
		))

		var btn := AstralTheme.button(
			"Solo en 4º Bim." if not is_open else ("Ya compitió" if entered else "%s  Competir (3 Asaltos)" % AstralTheme.G_STAR),
			"PrimaryButton" if (is_open and not entered) else ""
		)
		btn.custom_minimum_size = Vector2(180, 52)
		btn.disabled = (not is_open) or entered
		var idx: int = i
		btn.pressed.connect(_on_festival_pressed.bind(idx))
		row.add_child(btn)

func _render_festival_round() -> void:
	BaseWindow.clear(_fest_box)
	var m: Dictionary = ExplorationCombat.festival_match
	var arena := AstralTheme.panel("GlowPanel")
	_fest_box.add_child(arena)
	var v := AstralTheme.vbox(10)
	arena.add_child(v)

	var rnd: int = int(m.get("round", 1))
	var phase_names: Array[String] = ["Asalto 1: Exhibición", "Asalto 2: Contraataque del Rival", "Asalto 3: Remate Final"]
	v.add_child(AstralTheme.label("%s  %s" % [str(m.get("name", "")), phase_names[clampi(rnd - 1, 0, 2)]], "HeadingLabel", AstralTheme.GOLD))
	v.add_child(AstralTheme.label(
		"%s: %d pts   VS   %s: %d pts" % [GameState.daughter_name, int(m.get("player_score", 0)), str(m.get("rival_name", "")), int(m.get("rival_score", 0))],
		"SubLabel", AstralTheme.TURQ
	))

	var log_rich := AstralTheme.rich("\n".join(m.get("log", [])), 100)
	v.add_child(log_rich)

	_fest_risk_chk = CheckBox.new()
	_fest_risk_chk.text = "⚡ Arriesgar energía extra en este asalto (+6 Estrés, gran impulso de puntuación)"
	_fest_risk_chk.add_theme_color_override("font_color", AstralTheme.EMBER)
	v.add_child(_fest_risk_chk)

	var tact_row := AstralTheme.hbox(10)
	v.add_child(tact_row)
	var t_defs: Array[Array] = [
		["precision", "✦ Exhibición Serena", "PrimaryButton"],
		["bravado", "⚔ Gambito Audaz", "DangerButton"],
		["harmony", "❀ Cadencia (-3 Estrés)", "TabLikeButton"]
	]
	for td in t_defs:
		var tid: String = str(td[0])
		var tb := AstralTheme.button(str(td[1]), str(td[2]))
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size.y = 48
		tb.pressed.connect(func() -> void: _play_festival_step(tid, ""))
		tact_row.add_child(tb)

	var eq_dicts: Array[Dictionary] = GameState.get_equipped_memory_cards()
	var avail_cards: Array[Dictionary] = []
	for cd in eq_dicts:
		var cid: String = str(cd.get("id", ""))
		if not m.get("used_cards", []).has(cid):
			avail_cards.append(cd)
	if not avail_cards.is_empty():
		v.add_child(AstralTheme.label("O rematar el asalto con una Carta de Recuerdo (1 uso por certamen):", "CaptionLabel", AstralTheme.AMETHYST))
		var cr := HFlowContainer.new()
		cr.add_theme_constant_override("h_separation", 8)
		for cd in avail_cards:
			var card_k: String = str(cd.get("id", ""))
			var cb := AstralTheme.button("%s %s (+%d pts)" % [AstralTheme.G_STAR, str(cd.get("name", card_k)), int(cd.get("fest_bonus", 30))], "TabLikeButton")
			cb.pressed.connect(func() -> void: _play_festival_step("precision", card_k))
			cr.add_child(cb)
		v.add_child(cr)

func _play_festival_step(tactic: String, card_id: String) -> void:
	var risk: bool = _fest_risk_chk != null and _fest_risk_chk.button_pressed
	var res: Dictionary = ExplorationCombat.play_festival_round(tactic, card_id, risk)
	if not bool(res.get("ok", false)):
		toast.emit(str(res.get("msg", "Error en el certamen.")), "warn")
		return
	AstralAudio.play_ui()
	if bool(res.get("finished", false)):
		AstralAudio.set_music_mood("tension" if (TimeManager.get_act_number() >= 2 or GameState.court_suspicion >= 60) else "manor")
		_fest_result_card.visible = true
		_fest_result_lbl.text = "[color=#f7e3a1][b]%s[/b][/color]\n%s" % [str(res.get("title", "")), str(res.get("summary", ""))]
		if bool(res.get("won", false)):
			AstralAudio.play_triumph()
		_refresh_festival_tab()
		festival_completed.emit(res)
		toast.emit("Resultado del Festival de Otoño registrado", "good" if bool(res.get("won", false)) else "info")
	else:
		_render_festival_round()

func _on_companion_changed(_idx: int) -> void:
	AstralAudio.play_ui()
	_update_companion_info()
	_refresh_exploration_tab()

func _update_companion_info() -> void:
	if _comp_opt == null or _comp_info == null:
		return
	var npc_id: String = str(_comp_opt.get_item_metadata(_comp_opt.selected))
	var data: Dictionary = RelationshipManager.get_data(npc_id)
	var avail: bool = RelationshipManager.is_available(npc_id)
	var status: String = RelationshipManager.get_relationship_status_title(npc_id)
	var bonus: float = ExplorationCombat.get_companion_affinity_bonus(npc_id)
	var can_rec: bool = ExplorationCombat.can_recruit_companion(npc_id) and avail
	var extra_tag: String = ""
	if not avail:
		extra_tag = "  [%s]" % RelationshipManager.get_locked_reason(npc_id)
		_comp_info.text = "??? — Presencia aún oculta%s\nDescubre el origen de este susurro avanzando la historia." % extra_tag
		_comp_info.add_theme_color_override("font_color", AstralTheme.MUTED)
		return
	if not can_rec:
		extra_tag = "  [No disponible: vínculo hostil]"
	elif bonus > 1.0:
		extra_tag = "  [Sinergia de Vínculo: +%d%% eficacia]" % int(round((bonus - 1.0) * 100.0))
	_comp_info.text = "%s — %s%s\n%s" % [data.get("name", ""), status, extra_tag, data.get("perk_desc", "")]
	_comp_info.add_theme_color_override("font_color", AstralTheme.BAD if not can_rec else AstralTheme.TURQ)

func _on_explore_pressed(zone_idx: int) -> void:
	var npc_id: String = str(_comp_opt.get_item_metadata(_comp_opt.selected))
	var data: Dictionary = RelationshipManager.get_data(npc_id)
	var npc_name: String = str(data.get("name", npc_id))
	var res: Dictionary = ExplorationCombat.start_expedition(zone_idx, npc_id, npc_name)
	if not res.get("ok", false):
		toast.emit(str(res.get("msg", "No se pudo iniciar la expedición.")), "warn")
		return
	close()
	expedition_started.emit()

func _on_festival_pressed(contest_idx: int) -> void:
	var res: Dictionary = ExplorationCombat.start_festival_match(contest_idx)
	if not res.get("ok", false):
		toast.emit(str(res.get("msg", "No se pudo participar.")), "warn")
		return
	AstralAudio.set_music_mood("festival")
	AstralAudio.play_confirm()
	_refresh_festival_tab()
